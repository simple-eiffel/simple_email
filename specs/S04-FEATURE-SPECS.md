# S04: FEATURE SPECS - simple_email

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## SIMPLE_EMAIL Features

### Queries

| Feature | Signature | Description |
|---------|-----------|-------------|
| smtp_host | `: STRING` | SMTP server hostname |
| smtp_port | `: INTEGER` | SMTP server port |
| last_error | `: detachable STRING` | Last error message |
| is_connected | `: BOOLEAN` | Connection status |
| is_authenticated | `: BOOLEAN` | Auth status |
| is_tls_active | `: BOOLEAN` | TLS encryption active |
| has_error | `: BOOLEAN` | Error occurred |
| has_credentials | `: BOOLEAN` | Credentials configured |

### Commands

| Feature | Signature | Description |
|---------|-----------|-------------|
| set_smtp_server | `(host: STRING; port: INTEGER)` | Configure server |
| set_credentials | `(user, pass: STRING)` | Set auth credentials |
| set_timeout | `(seconds: INTEGER)` | Set timeout |
| connect | `()` | Plain TCP connect |
| connect_tls | `()` | Implicit TLS connect |
| start_tls | `()` | Upgrade to TLS |
| authenticate | `()` | Authenticate |
| disconnect | `()` | Close connection |
| send | `(msg: SE_MESSAGE): BOOLEAN` | Send email |
| create_message | `(): SE_MESSAGE` | Factory method |

---

## SE_MESSAGE Features

### Queries

| Feature | Signature | Description |
|---------|-----------|-------------|
| from_address | `: STRING` | Sender address |
| subject | `: STRING` | Subject line |
| text_body | `: STRING` | Plain text body |
| html_body | `: STRING` | HTML body |
| recipients | `: ARRAYED_LIST [STRING]` | To recipients |
| cc_recipients | `: ARRAYED_LIST [STRING]` | Cc recipients |
| bcc_recipients | `: ARRAYED_LIST [STRING]` | Bcc recipients |
| attachments | `: ARRAYED_LIST [SE_ATTACHMENT]` | Attachments |
| is_valid | `: BOOLEAN` | Message valid for sending |
| has_from | `: BOOLEAN` | Has sender |
| has_recipients | `: BOOLEAN` | Has recipients |
| has_body | `: BOOLEAN` | Has content |
| has_attachments | `: BOOLEAN` | Has attachments |
| recipient_count | `: INTEGER` | Total recipients |
| attachment_count | `: INTEGER` | Total attachments |

### Commands

| Feature | Signature | Description |
|---------|-----------|-------------|
| set_from | `(address: STRING)` | Set sender |
| add_to | `(address: STRING)` | Add To recipient |
| add_cc | `(address: STRING)` | Add Cc recipient |
| add_bcc | `(address: STRING)` | Add Bcc recipient |
| clear_recipients | `()` | Remove all recipients |
| set_subject | `(subject: STRING)` | Set subject |
| set_text_body | `(text: STRING)` | Set plain body |
| set_html_body | `(html: STRING)` | Set HTML body |
| attach_file | `(path: STRING)` | Attach file |
| attach_data | `(name, type, data: STRING)` | Attach raw data |
| clear_attachments | `()` | Remove attachments |

---

## SE_SMTP_CLIENT Features

### Connection Commands

| Feature | Signature | Description |
|---------|-----------|-------------|
| connect | `()` | Plain TCP connect |
| connect_tls | `()` | Implicit TLS |
| start_tls | `()` | STARTTLS upgrade |
| send_ehlo | `()` | SMTP greeting |
| disconnect | `()` | Close connection |

### Authentication Commands

| Feature | Signature | Description |
|---------|-----------|-------------|
| authenticate_plain | `(user, pass: STRING)` | AUTH PLAIN |
| authenticate_login | `(user, pass: STRING)` | AUTH LOGIN |

### Sending Commands

| Feature | Signature | Description |
|---------|-----------|-------------|
| send_message | `(msg: SE_MESSAGE)` | Send complete email |

---

## SE_TLS_SOCKET Features

### Commands

| Feature | Signature | Description |
|---------|-----------|-------------|
| connect | `(host: STRING; port: INTEGER)` | TCP connect |
| connect_tls | `(host: STRING; port: INTEGER)` | TLS connect |
| start_tls | `(host: STRING)` | Upgrade to TLS |
| send | `(data: STRING)` | Send data |
| receive | `(): STRING` | Receive data |
| receive_line | `(): STRING` | Receive until CRLF |
| set_timeout | `(ms: INTEGER)` | Set timeout |
| disconnect | `()` | Close socket |
