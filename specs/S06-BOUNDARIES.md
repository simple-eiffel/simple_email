# S06: BOUNDARIES - simple_email

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## System Boundaries

### External Systems

```
+-------------------+
|   Application     |
+-------------------+
         |
         | Eiffel API
         v
+-------------------+
|   simple_email    |
+-------------------+
         |
         | SMTP Protocol
         v
+-------------------+
|   SMTP Server     |
| (Gmail, Exchange) |
+-------------------+
```

### Internal Boundaries

```
+-----------------------------------------------------------+
|                     simple_email                           |
|  +------------+    +--------------+    +---------------+  |
|  |  SIMPLE_   |    |  SE_SMTP_    |    | SE_TLS_       |  |
|  |  EMAIL     |--->|  CLIENT      |--->| SOCKET        |  |
|  | (Facade)   |    | (Protocol)   |    | (Transport)   |  |
|  +------------+    +--------------+    +---------------+  |
|        |                 |                    |           |
|        v                 v                    v           |
|  +------------+    +--------------+    +---------------+  |
|  | SE_MESSAGE |    | simple_base64|    | WinSock/      |  |
|  | (Data)     |    |              |    | SChannel      |  |
|  +------------+    +--------------+    +---------------+  |
+-----------------------------------------------------------+
```

## Interface Boundaries

### Public API (SIMPLE_EMAIL)

```eiffel
-- Connection
connect
connect_tls
start_tls
disconnect

-- Authentication
set_credentials (user, pass)
authenticate

-- Configuration
set_smtp_server (host, port)
set_timeout (seconds)

-- Sending
send (message): BOOLEAN
create_message: SE_MESSAGE
```

### Public API (SE_MESSAGE)

```eiffel
-- Recipients
set_from (address)
add_to (address)
add_cc (address)
add_bcc (address)

-- Content
set_subject (subject)
set_text_body (text)
set_html_body (html)

-- Attachments
attach_file (path)
attach_data (name, type, data)
```

### Internal API (SE_SMTP_CLIENT)

```eiffel
-- Used by SIMPLE_EMAIL only
connect
connect_tls
start_tls
send_ehlo
authenticate_plain
authenticate_login
send_message
disconnect
```

### Internal API (SE_TLS_SOCKET)

```eiffel
-- Used by SE_SMTP_CLIENT only
connect
connect_tls
start_tls
send
receive
receive_line
disconnect
```

## Data Flow Boundaries

### Outbound (Sending Email)

```
Application
    | SE_MESSAGE
    v
SIMPLE_EMAIL
    | SE_MESSAGE
    v
SE_SMTP_CLIENT
    | SMTP commands (text)
    v
SE_TLS_SOCKET
    | Encrypted bytes
    v
Network (SMTP Server)
```

### Inbound (Responses)

```
Network
    | Encrypted bytes
    v
SE_TLS_SOCKET
    | Plain text
    v
SE_SMTP_CLIENT
    | Response codes
    v
SIMPLE_EMAIL
    | BOOLEAN / last_error
    v
Application
```

## Security Boundaries

| Boundary | Protection |
|----------|------------|
| Application <-> Library | Contract validation |
| Library <-> Network | TLS encryption |
| Memory | Credential cleanup on disconnect |
