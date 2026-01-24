# S02: CLASS CATALOG - simple_email

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## Class Hierarchy

```
ANY
    +-- SIMPLE_EMAIL           # Main facade
    +-- SE_MESSAGE             # Email composition
    +-- SE_SMTP_CLIENT         # SMTP protocol
    +-- SE_ATTACHMENT          # Attachment data
    +-- SE_TLS_SOCKET          # TLS transport
```

## Class Details

### SIMPLE_EMAIL (Facade)

**Purpose:** Simple API for sending emails
**Responsibility:** Coordinate SMTP operations

| Feature Category | Count |
|-----------------|-------|
| Queries | 7 |
| Commands | 8 |
| Internal | 6 |

**Key Features:**
- `connect`, `connect_tls`: Establish connection
- `authenticate`: SMTP auth
- `send`: Send email message
- `create_message`: Factory for SE_MESSAGE

---

### SE_MESSAGE

**Purpose:** Represent email content
**Responsibility:** Store headers, body, attachments

| Feature Category | Count |
|-----------------|-------|
| Queries | 12 |
| Commands | 10 |
| Internal | 4 |

**Key Features:**
- `set_from`, `add_to`, `add_cc`, `add_bcc`: Recipients
- `set_subject`, `set_text_body`, `set_html_body`: Content
- `attach_file`, `attach_data`: Attachments

---

### SE_SMTP_CLIENT

**Purpose:** SMTP protocol implementation
**Responsibility:** Send commands, parse responses

| Feature Category | Count |
|-----------------|-------|
| Queries | 6 |
| Commands | 10 |
| Internal | 15 |

**Key Features:**
- `connect`, `connect_tls`, `start_tls`: Connection
- `send_ehlo`: Protocol handshake
- `authenticate_plain`, `authenticate_login`: Auth
- `send_message`: Transmit email

---

### SE_ATTACHMENT

**Purpose:** File attachment wrapper
**Responsibility:** Store attachment data and metadata

| Feature Category | Count |
|-----------------|-------|
| Queries | 5 |
| Commands | 0 |
| Internal | 3 |

**Key Features:**
- `name`: Filename
- `content_type`: MIME type
- `data`: Raw content
- `encoded_data`: Base64 encoded

---

### SE_TLS_SOCKET

**Purpose:** TLS-capable TCP socket
**Responsibility:** Secure network communication

| Feature Category | Count |
|-----------------|-------|
| Queries | 4 |
| Commands | 6 |
| Internal | 15+ |

**Key Features:**
- `connect`, `connect_tls`: Establish connection
- `start_tls`: Upgrade to TLS
- `send`, `receive`, `receive_line`: I/O
- `disconnect`: Close connection

## Class Dependencies

```
SIMPLE_EMAIL
    |
    +-- SE_SMTP_CLIENT
    |       |
    |       +-- SE_TLS_SOCKET
    |       +-- SIMPLE_BASE64
    |
    +-- SE_MESSAGE
            |
            +-- SE_ATTACHMENT
            +-- SIMPLE_ENCODING_DETECTOR
```
