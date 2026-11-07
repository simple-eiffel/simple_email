/*
 * se_tls_posix.h - sockets and TLS for simple_email on macOS and Linux.
 *
 * TLS is OpenSSL: at least TLS 1.2, the system's trusted roots, and the
 * certificate checked against the host name. Every byte after the handshake
 * goes through SSL_read and SSL_write.
 *
 * Connection errors answer the Winsock code for the same failure, and a
 * certificate failure the SChannel one, so SE_TLS_SOCKET's messages read the
 * same on every platform.
 *
 * Copyright (c) 2026 Larry Rix - MIT License
 */

#ifndef SE_TLS_POSIX_H
#define SE_TLS_POSIX_H

#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/x509v3.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif

#define SE_INVALID ((void*) (intptr_t) -1)
#define SE_CERTIFICATE_FAILED (-2146893048)

typedef struct {
    SSL_CTX* context;
    SSL* session;
} se_tls;

static int se_fd(void* a_socket) { return (int) (intptr_t) a_socket; }

static int se_code(int a_errno)
{
    switch (a_errno) {
    case ETIMEDOUT: return 10060;
    case ECONNREFUSED: return 10061;
    case EHOSTUNREACH: return 10065;
    default: return 10000 + a_errno;
    }
}

/* Connect within `a_timeout_ms'. 0 on success, else the code. */
static int se_connect(const char* a_host, int a_port, int a_timeout_ms, void** a_socket)
{
    struct addrinfo l_hints, *l_found = NULL, *l_address;
    struct pollfd l_wait;
    struct timeval l_timeout;
    char l_port[16];
    int l_fd = -1, l_error = 10065, l_result, l_so_error, l_flags;
    socklen_t l_length;

    memset(&l_hints, 0, sizeof(l_hints));
    l_hints.ai_family = AF_INET;
    l_hints.ai_socktype = SOCK_STREAM;
    l_hints.ai_protocol = IPPROTO_TCP;
    snprintf(l_port, sizeof(l_port), "%d", a_port);
    if (getaddrinfo(a_host, l_port, &l_hints, &l_found) != 0) return 11001;

    for (l_address = l_found; l_address != NULL; l_address = l_address->ai_next) {
        l_fd = socket(l_address->ai_family, l_address->ai_socktype, l_address->ai_protocol);
        if (l_fd < 0) { l_error = se_code(errno); continue; }
        fcntl(l_fd, F_SETFD, FD_CLOEXEC);
#ifdef SO_NOSIGPIPE
        { int l_on = 1; setsockopt(l_fd, SOL_SOCKET, SO_NOSIGPIPE, &l_on, sizeof(l_on)); }
#endif
        l_flags = fcntl(l_fd, F_GETFL, 0);
        fcntl(l_fd, F_SETFL, l_flags | O_NONBLOCK);
        l_error = 0;
        if (connect(l_fd, l_address->ai_addr, l_address->ai_addrlen) != 0) {
            if (errno == EINPROGRESS) {
                l_wait.fd = l_fd;
                l_wait.events = POLLOUT;
                l_wait.revents = 0;
                do {
                    l_result = poll(&l_wait, 1, a_timeout_ms);
                } while (l_result < 0 && errno == EINTR);
                if (l_result == 0) {
                    l_error = 10060;
                } else if (l_result < 0) {
                    l_error = se_code(errno);
                } else {
                    l_so_error = 0;
                    l_length = sizeof(l_so_error);
                    getsockopt(l_fd, SOL_SOCKET, SO_ERROR, &l_so_error, &l_length);
                    if (l_so_error != 0) l_error = se_code(l_so_error);
                }
            } else {
                l_error = se_code(errno);
            }
        }
        if (l_error == 0) {
            fcntl(l_fd, F_SETFL, l_flags);
            break;
        }
        close(l_fd);
        l_fd = -1;
    }
    freeaddrinfo(l_found);
    if (l_fd < 0) return l_error;

    l_timeout.tv_sec = a_timeout_ms / 1000;
    l_timeout.tv_usec = (a_timeout_ms % 1000) * 1000;
    setsockopt(l_fd, SOL_SOCKET, SO_RCVTIMEO, &l_timeout, sizeof(l_timeout));
    setsockopt(l_fd, SOL_SOCKET, SO_SNDTIMEO, &l_timeout, sizeof(l_timeout));
    *a_socket = (void*) (intptr_t) l_fd;
    return 0;
}

/* Handshake on `a_socket', checking the certificate against `a_host'. 0 on
   success with `*a_context' set; else a code, and nothing is kept. */
static int se_start_tls(void* a_socket, const char* a_host, void** a_context)
{
    se_tls* l_tls = (se_tls*) calloc(1, sizeof(se_tls));
    long l_verify;
    int l_result = -1;

    if (!l_tls) return -1;
    l_tls->context = SSL_CTX_new(TLS_client_method());
    if (!l_tls->context) goto fail;
    SSL_CTX_set_min_proto_version(l_tls->context, TLS1_2_VERSION);
    SSL_CTX_set_verify(l_tls->context, SSL_VERIFY_PEER, NULL);
    if (SSL_CTX_set_default_verify_paths(l_tls->context) != 1) goto fail;
    l_tls->session = SSL_new(l_tls->context);
    if (!l_tls->session) goto fail;
    if (SSL_set_tlsext_host_name(l_tls->session, a_host) != 1) goto fail;
    if (SSL_set1_host(l_tls->session, a_host) != 1) goto fail;
    if (SSL_set_fd(l_tls->session, se_fd(a_socket)) != 1) goto fail;
    if (SSL_connect(l_tls->session) != 1) {
        l_verify = SSL_get_verify_result(l_tls->session);
        if (l_verify != X509_V_OK) l_result = SE_CERTIFICATE_FAILED;
        goto fail;
    }
    *a_context = l_tls;
    return 0;

fail:
    if (l_tls->session) SSL_free(l_tls->session);
    if (l_tls->context) SSL_CTX_free(l_tls->context);
    free(l_tls);
    return l_result;
}

#ifdef __linux__
#include <pthread.h>
#include <signal.h>
#include <time.h>

/* OpenSSL writes with plain write(), and Linux has no SO_NOSIGPIPE, so a peer that
   has closed would raise SIGPIPE. Block it around the call and consume it, leaving
   the rest of the program's signal handling alone. */
typedef struct {
    sigset_t old;
    int was_pending;
} se_pipe_guard;

static void se_pipe_block(se_pipe_guard* a_guard)
{
    sigset_t l_pipe, l_pending;
    sigemptyset(&l_pipe);
    sigaddset(&l_pipe, SIGPIPE);
    sigpending(&l_pending);
    a_guard->was_pending = sigismember(&l_pending, SIGPIPE);
    pthread_sigmask(SIG_BLOCK, &l_pipe, &a_guard->old);
}

static void se_pipe_restore(se_pipe_guard* a_guard)
{
    sigset_t l_pipe;
    struct timespec l_zero = {0, 0};
    sigemptyset(&l_pipe);
    sigaddset(&l_pipe, SIGPIPE);
    if (!a_guard->was_pending) {
        while (sigtimedwait(&l_pipe, NULL, &l_zero) > 0) { }
    }
    pthread_sigmask(SIG_SETMASK, &a_guard->old, NULL);
}
#else
typedef int se_pipe_guard;
static void se_pipe_block(se_pipe_guard* a_guard) { (void) a_guard; }
static void se_pipe_restore(se_pipe_guard* a_guard) { (void) a_guard; }
#endif

static void se_shutdown_tls(void* a_context)
{
    se_tls* l_tls = (se_tls*) a_context;
    se_pipe_guard l_guard;
    if (l_tls) {
        se_pipe_block(&l_guard);
        SSL_shutdown(l_tls->session);
        se_pipe_restore(&l_guard);
        SSL_free(l_tls->session);
        SSL_CTX_free(l_tls->context);
        free(l_tls);
    }
}

static int se_send_tls(void* a_context, const void* a_data, int a_length)
{
    se_tls* l_tls = (se_tls*) a_context;
    se_pipe_guard l_guard;
    int l_written;
    if (!l_tls) return -1;
    se_pipe_block(&l_guard);
    l_written = SSL_write(l_tls->session, a_data, a_length);
    se_pipe_restore(&l_guard);
    return l_written > 0 ? l_written : -1;
}

static int se_receive_tls(void* a_context, void* a_buffer, int a_max)
{
    se_tls* l_tls = (se_tls*) a_context;
    int l_read;
    if (!l_tls) return -1;
    l_read = SSL_read(l_tls->session, a_buffer, a_max);
    if (l_read > 0) return l_read;
    return SSL_get_error(l_tls->session, l_read) == SSL_ERROR_ZERO_RETURN ? 0 : -1;
}

static int se_send_plain(void* a_socket, const void* a_data, int a_length)
{
    return (int) send(se_fd(a_socket), a_data, (size_t) a_length, MSG_NOSIGNAL);
}

static int se_receive_plain(void* a_socket, void* a_buffer, int a_max)
{
    return (int) recv(se_fd(a_socket), a_buffer, (size_t) a_max, 0);
}

#endif /* SE_TLS_POSIX_H */
