# 02: Class Structure - simple_email

## Date: 2026-01-18
## Working Hat: SPECIFICATION

---

## Classes Created

| Class | File | Purpose |
|-------|------|---------|
| SIMPLE_EMAIL | src/simple_email.e | Main facade |
| SE_MESSAGE | src/se_message.e | Email message composition |
| SE_ATTACHMENT | src/se_attachment.e | File attachments |
| SE_SMTP_CLIENT | src/se_smtp_client.e | SMTP protocol client |
| SE_TLS_SOCKET | src/se_tls_socket.e | TLS socket transport |

---

## Class Signatures Summary

### SIMPLE_EMAIL (Facade)
```
Queries: last_error, smtp_host, smtp_port
Status: is_connected, is_authenticated, is_tls_active, has_error
Commands: set_smtp_server, set_credentials, set_timeout, connect, disconnect
Operations: send, create_message
```

### SE_MESSAGE (Email Composition)
```
Queries: from_address, subject, text_body, html_body, recipients, cc_recipients, bcc_recipients, attachments
Status: is_valid, has_from, has_recipients, has_body, has_attachments
Measurement: recipient_count, attachment_count
Commands: set_from, add_to, add_cc, add_bcc, clear_recipients, set_subject, set_text_body, set_html_body, attach_file, attach_data, clear_attachments
```

### SE_ATTACHMENT
```
Queries: name, content_type, data, encoded_data
Status: is_valid
Measurement: size
```

### SE_SMTP_CLIENT
```
Queries: host, port, last_response, last_error
Status: is_connected, is_tls_active, is_authenticated, has_error
Commands: connect, connect_tls, start_tls, disconnect, authenticate_plain, authenticate_login, send_message
```

### SE_TLS_SOCKET
```
Queries: last_error
Status: is_connected, is_tls_active, has_error
Commands: connect, connect_tls, start_tls, disconnect, send, receive, receive_line, set_timeout
```

---

## Command-Query Separation

All classes follow CQS:
- Queries: Return value, no state change
- Commands: Modify state, no return value
- Exception: `send` returns BOOLEAN (command with status return)

---

## Feature Categories

All classes use standard Eiffel feature categories:
- `feature {NONE} -- Initialization`
- `feature -- Access (Queries)`
- `feature -- Status (Boolean Queries)`
- `feature -- Measurement (Integer Queries)`
- `feature -- [Category] (Commands)`
- `feature {NONE} -- Implementation`

---

**02-CLASS-STRUCTURE: COMPLETE**

Next Step: 03-WRITE-PRECONDITIONS (add require clauses)
