/*
 * se_tls_schannel.h - TLS for simple_email on Windows, through SChannel.
 *
 * TLS 1.2, the system's trusted roots, and the certificate checked against the
 * host name on every handshake call. After the handshake every byte goes through
 * EncryptMessage and DecryptMessage. The context is kept per connection.
 *
 * Records arrive whole or in pieces and callers may read one byte at a time, so
 * decrypted bytes wait in `plain' and undecrypted bytes in `in'.
 *
 * Copyright (c) 2026 Larry Rix - MIT License
 */

#ifndef SE_TLS_SCHANNEL_H
#define SE_TLS_SCHANNEL_H

#include "se_tls_defs.h"
#include <stdlib.h>
#include <string.h>

#define SE_TLS_BUFFER 65536

typedef struct {
    SOCKET socket;
    CredHandle cred;
    CtxtHandle ctxt;
    int has_cred;
    int has_ctxt;
    SecPkgContext_StreamSizes sizes;
    char* in;            /* received, not yet decrypted */
    DWORD in_used;
    char* plain;         /* decrypted, not yet handed over */
    DWORD plain_start;
    DWORD plain_left;
} SeTlsContext;

static int se_send_all(SOCKET a_socket, const char* a_data, DWORD a_length)
{
    DWORD sent = 0;
    while (sent < a_length) {
        int n = send(a_socket, a_data + sent, (int) (a_length - sent), 0);
        if (n <= 0) return 0;
        sent += (DWORD) n;
    }
    return 1;
}

static void se_free_context(SeTlsContext* c)
{
    if (!c) return;
    if (c->has_ctxt) DeleteSecurityContext(&c->ctxt);
    if (c->has_cred) FreeCredentialsHandle(&c->cred);
    free(c->in);
    free(c->plain);
    free(c);
}

/* Handshake on `a_socket', checking the certificate against `a_host'. 0 on
   success with the context in `*a_context', else a code for the failure. */
static int se_start_tls(SOCKET a_socket, const char* a_host, void** a_context)
{
    SeTlsContext* c = (SeTlsContext*) calloc(1, sizeof(SeTlsContext));
    SCHANNEL_CRED cred;
    SecBufferDesc in_desc, out_desc;
    SecBuffer in_buffers[2], out_buffers[1];
    SECURITY_STATUS status;
    DWORD flags, out_flags;
    int first = 1, need_read = 0, declined_client_cert = 0, n;

    if (!c) return -1;
    c->socket = a_socket;
    c->in = (char*) malloc(SE_TLS_BUFFER);
    c->plain = (char*) malloc(SE_TLS_BUFFER);
    if (!c->in || !c->plain) { se_free_context(c); return -1; }

    memset(&cred, 0, sizeof(cred));
    cred.dwVersion = SCHANNEL_CRED_VERSION;
    cred.grbitEnabledProtocols = SP_PROT_TLS1_2_CLIENT;
    cred.dwFlags = SCH_CRED_AUTO_CRED_VALIDATION | SCH_CRED_NO_DEFAULT_CREDS;
    status = AcquireCredentialsHandleA(NULL, UNISP_NAME_A, SECPKG_CRED_OUTBOUND,
        NULL, &cred, NULL, NULL, &c->cred, NULL);
    if (status != SEC_E_OK) { se_free_context(c); return (int) status; }
    c->has_cred = 1;

    flags = ISC_REQ_SEQUENCE_DETECT | ISC_REQ_REPLAY_DETECT | ISC_REQ_CONFIDENTIALITY |
            ISC_REQ_ALLOCATE_MEMORY | ISC_REQ_STREAM | ISC_REQ_USE_SUPPLIED_CREDS;

    for (;;) {
        if (need_read) {
            if (c->in_used >= SE_TLS_BUFFER) { se_free_context(c); return -1; }
            n = recv(a_socket, c->in + c->in_used, (int) (SE_TLS_BUFFER - c->in_used), 0);
            if (n <= 0) { se_free_context(c); return -1; }
            c->in_used += (DWORD) n;
            need_read = 0;
        }

        in_buffers[0].BufferType = SECBUFFER_TOKEN;
        in_buffers[0].pvBuffer = c->in;
        in_buffers[0].cbBuffer = c->in_used;
        in_buffers[1].BufferType = SECBUFFER_EMPTY;
        in_buffers[1].pvBuffer = NULL;
        in_buffers[1].cbBuffer = 0;
        in_desc.ulVersion = SECBUFFER_VERSION;
        in_desc.cBuffers = 2;
        in_desc.pBuffers = in_buffers;

        out_buffers[0].BufferType = SECBUFFER_TOKEN;
        out_buffers[0].pvBuffer = NULL;
        out_buffers[0].cbBuffer = 0;
        out_desc.ulVersion = SECBUFFER_VERSION;
        out_desc.cBuffers = 1;
        out_desc.pBuffers = out_buffers;

        status = InitializeSecurityContextA(&c->cred, first ? NULL : &c->ctxt, (SEC_CHAR*) a_host,
            flags, 0, 0, first ? NULL : &in_desc, 0, first ? &c->ctxt : NULL,
            &out_desc, &out_flags, NULL);
        if (first) {
            first = 0;
            if (status == SEC_E_OK || status == SEC_I_CONTINUE_NEEDED) c->has_ctxt = 1;
        }

        if (out_buffers[0].pvBuffer) {
            int sent = out_buffers[0].cbBuffer == 0 ||
                se_send_all(a_socket, (const char*) out_buffers[0].pvBuffer, out_buffers[0].cbBuffer);
            FreeContextBuffer(out_buffers[0].pvBuffer);
            if (!sent) { se_free_context(c); return -1; }
        }

        if (status == SEC_E_INCOMPLETE_MESSAGE) {
            need_read = 1;
            continue;
        }
        /* The server offers client authentication. We have no certificate, so go on
           without one, once; a server that insists will refuse us next. */
        if (status == SEC_I_INCOMPLETE_CREDENTIALS && !declined_client_cert) {
            declined_client_cert = 1;
            continue;
        }
        if (status != SEC_E_OK && status != SEC_I_CONTINUE_NEEDED) {
            se_free_context(c);
            return (int) status;
        }

        /* Keep whatever the server sent past this handshake message. */
        if (in_buffers[1].BufferType == SECBUFFER_EXTRA && in_buffers[1].cbBuffer > 0) {
            memmove(c->in, c->in + c->in_used - in_buffers[1].cbBuffer, in_buffers[1].cbBuffer);
            c->in_used = in_buffers[1].cbBuffer;
        } else {
            c->in_used = 0;
        }
        if (status == SEC_E_OK) break;
        need_read = c->in_used == 0;
    }

    status = QueryContextAttributesA(&c->ctxt, SECPKG_ATTR_STREAM_SIZES, &c->sizes);
    if (status != SEC_E_OK) { se_free_context(c); return (int) status; }
    *a_context = c;
    return 0;
}

/* Encrypt and send all of `a_data'. Bytes sent, or -1. */
static int se_send_tls(void* a_context, const void* a_data, int a_length)
{
    SeTlsContext* c = (SeTlsContext*) a_context;
    const char* data = (const char*) a_data;
    DWORD total, done = 0;
    char* record;
    int result;

    if (!c || a_length < 0) return -1;
    total = (DWORD) a_length;
    record = (char*) malloc(c->sizes.cbHeader + c->sizes.cbMaximumMessage + c->sizes.cbTrailer);
    if (!record) return -1;
    result = a_length;
    while (done < total) {
        SecBuffer buffers[4];
        SecBufferDesc desc;
        DWORD part = total - done;
        if (part > c->sizes.cbMaximumMessage) part = c->sizes.cbMaximumMessage;
        memcpy(record + c->sizes.cbHeader, data + done, part);

        buffers[0].BufferType = SECBUFFER_STREAM_HEADER;
        buffers[0].pvBuffer = record;
        buffers[0].cbBuffer = c->sizes.cbHeader;
        buffers[1].BufferType = SECBUFFER_DATA;
        buffers[1].pvBuffer = record + c->sizes.cbHeader;
        buffers[1].cbBuffer = part;
        buffers[2].BufferType = SECBUFFER_STREAM_TRAILER;
        buffers[2].pvBuffer = record + c->sizes.cbHeader + part;
        buffers[2].cbBuffer = c->sizes.cbTrailer;
        buffers[3].BufferType = SECBUFFER_EMPTY;
        buffers[3].pvBuffer = NULL;
        buffers[3].cbBuffer = 0;
        desc.ulVersion = SECBUFFER_VERSION;
        desc.cBuffers = 4;
        desc.pBuffers = buffers;

        if (EncryptMessage(&c->ctxt, 0, &desc, 0) != SEC_E_OK ||
            !se_send_all(c->socket, record, buffers[0].cbBuffer + buffers[1].cbBuffer + buffers[2].cbBuffer)) {
            result = -1;
            break;
        }
        done += part;
    }
    free(record);
    return result;
}

static int se_take_plain(SeTlsContext* c, char* a_out, int a_max)
{
    DWORD n = c->plain_left < (DWORD) a_max ? c->plain_left : (DWORD) a_max;
    memcpy(a_out, c->plain + c->plain_start, n);
    c->plain_start += n;
    c->plain_left -= n;
    return (int) n;
}

/* Decrypted bytes into `a_buffer'. Count, 0 when the peer closed, or -1. */
static int se_receive_tls(void* a_context, void* a_buffer, int a_max)
{
    SeTlsContext* c = (SeTlsContext*) a_context;
    int n;

    if (!c || a_max <= 0) return -1;
    if (c->plain_left > 0) return se_take_plain(c, (char*) a_buffer, a_max);

    for (;;) {
        if (c->in_used > 0) {
            SecBuffer buffers[4];
            SecBufferDesc desc;
            SECURITY_STATUS status;
            SecBuffer* data = NULL;
            SecBuffer* extra = NULL;
            int i;

            buffers[0].BufferType = SECBUFFER_DATA;
            buffers[0].pvBuffer = c->in;
            buffers[0].cbBuffer = c->in_used;
            for (i = 1; i < 4; i++) {
                buffers[i].BufferType = SECBUFFER_EMPTY;
                buffers[i].pvBuffer = NULL;
                buffers[i].cbBuffer = 0;
            }
            desc.ulVersion = SECBUFFER_VERSION;
            desc.cBuffers = 4;
            desc.pBuffers = buffers;

            status = DecryptMessage(&c->ctxt, &desc, 0, NULL);
            if (status == SEC_E_OK || status == SEC_I_CONTEXT_EXPIRED || status == SEC_I_RENEGOTIATE) {
                for (i = 0; i < 4; i++) {
                    if (buffers[i].BufferType == SECBUFFER_DATA) data = &buffers[i];
                    if (buffers[i].BufferType == SECBUFFER_EXTRA) extra = &buffers[i];
                }
                c->plain_start = 0;
                c->plain_left = 0;
                if (data && data->cbBuffer > 0) {
                    memcpy(c->plain, data->pvBuffer, data->cbBuffer);
                    c->plain_left = data->cbBuffer;
                }
                if (extra && extra->cbBuffer > 0) {
                    memmove(c->in, c->in + c->in_used - extra->cbBuffer, extra->cbBuffer);
                    c->in_used = extra->cbBuffer;
                } else {
                    c->in_used = 0;
                }
                if (c->plain_left > 0) return se_take_plain(c, (char*) a_buffer, a_max);
                if (status == SEC_I_CONTEXT_EXPIRED) return 0;
                if (status == SEC_I_RENEGOTIATE) return -1;
                continue;
            }
            if (status != SEC_E_INCOMPLETE_MESSAGE) return -1;
        }
        if (c->in_used >= SE_TLS_BUFFER) return -1;
        n = recv(c->socket, c->in + c->in_used, (int) (SE_TLS_BUFFER - c->in_used), 0);
        if (n == 0) return 0;
        if (n < 0) return -1;
        c->in_used += (DWORD) n;
    }
}

/* Send close_notify, then release everything. */
static void se_shutdown_tls(void* a_context)
{
    SeTlsContext* c = (SeTlsContext*) a_context;
    DWORD token = SCHANNEL_SHUTDOWN;
    SecBuffer buffer;
    SecBufferDesc desc;
    DWORD flags = ISC_REQ_SEQUENCE_DETECT | ISC_REQ_REPLAY_DETECT | ISC_REQ_CONFIDENTIALITY |
                  ISC_REQ_ALLOCATE_MEMORY | ISC_REQ_STREAM;
    DWORD out_flags;

    if (!c) return;
    buffer.BufferType = SECBUFFER_TOKEN;
    buffer.pvBuffer = &token;
    buffer.cbBuffer = sizeof(token);
    desc.ulVersion = SECBUFFER_VERSION;
    desc.cBuffers = 1;
    desc.pBuffers = &buffer;
    if (ApplyControlToken(&c->ctxt, &desc) == SEC_E_OK) {
        buffer.BufferType = SECBUFFER_TOKEN;
        buffer.pvBuffer = NULL;
        buffer.cbBuffer = 0;
        if (InitializeSecurityContextA(&c->cred, &c->ctxt, NULL, flags, 0, 0, NULL, 0, NULL,
                &desc, &out_flags, NULL) == SEC_E_OK && buffer.pvBuffer) {
            if (buffer.cbBuffer > 0) se_send_all(c->socket, (const char*) buffer.pvBuffer, buffer.cbBuffer);
            FreeContextBuffer(buffer.pvBuffer);
        }
    }
    se_free_context(c);
}

#endif /* SE_TLS_SCHANNEL_H */
