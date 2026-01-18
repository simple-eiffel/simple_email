# DOMAIN-MODEL: simple_email

## Date: 2026-01-18
## Status: Phase 1 Complete

---

## Domain Concepts

### Core Entities

| Entity | Description | Responsibility |
|--------|-------------|----------------|
| Email | Complete email message | Holds all message data |
| Attachment | File attached to email | Holds binary content with metadata |
| SMTPClient | SMTP protocol handler | Manages server conversation |
| TLSSocket | Secure transport layer | Handles encrypted I/O |
| EmailFacade | Library entry point | Simple API for users |

### Entity Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                     SIMPLE_EMAIL                             │
│                     (Facade)                                 │
├─────────────────────────────────────────────────────────────┤
│ Creates and manages all other components                     │
└───────────────────────┬─────────────────────────────────────┘
                        │
            ┌───────────┴───────────┐
            ▼                       ▼
┌─────────────────────┐   ┌─────────────────────┐
│    SE_MESSAGE       │   │   SE_SMTP_CLIENT    │
│    (Value Object)   │   │   (Service)         │
├─────────────────────┤   ├─────────────────────┤
│ Holds email content │   │ Sends messages      │
└──────────┬──────────┘   └──────────┬──────────┘
           │                         │
           ▼                         ▼
┌─────────────────────┐   ┌─────────────────────┐
│   SE_ATTACHMENT     │   │   SE_TLS_SOCKET     │
│   (Value Object)    │   │   (Transport)       │
├─────────────────────┤   ├─────────────────────┤
│ File attachment     │   │ TLS encrypted I/O   │
└─────────────────────┘   └─────────────────────┘
```

---

## Domain Behaviors

### Message Composition (SE_MESSAGE)

| Behavior | Input | Output | Constraints |
|----------|-------|--------|-------------|
| set_from | email address | void | address not empty |
| add_to | email address | void | address not empty |
| add_cc | email address | void | address not empty |
| add_bcc | email address | void | address not empty |
| set_subject | text | void | none |
| set_text_body | text | void | none |
| set_html_body | html | void | none |
| attach_file | file path | void | path not empty |
| attach_data | name, type, data | void | name, type not empty |

### Connection Management (SE_SMTP_CLIENT)

| Behavior | Input | Output | Constraints |
|----------|-------|--------|-------------|
| connect | void | void | not connected |
| connect_tls | void | void | not connected |
| start_tls | void | void | connected, not TLS |
| disconnect | void | void | none |
| authenticate_plain | user, pass | void | connected |
| authenticate_login | user, pass | void | connected |
| send_message | message | void | connected, authenticated |

### Transport Layer (SE_TLS_SOCKET)

| Behavior | Input | Output | Constraints |
|----------|-------|--------|-------------|
| connect | host, port | void | not connected |
| connect_tls | host, port | void | not connected |
| start_tls | host | void | connected, not TLS |
| disconnect | void | void | none |
| send | data | void | connected |
| receive | void | data | connected |
| receive_line | void | line | connected |

---

## Domain Rules

### Invariants

1. **Message Validity**: A message is valid iff it has a From address AND at least one recipient
2. **TLS Requirement**: TLS must be established before authentication
3. **Auth Requirement**: Authentication required before sending
4. **Connection State**: TLS can only be active if connected
5. **Auth State**: Authenticated can only be true if connected

### Constraints

| Constraint | Description | Enforcement |
|------------|-------------|-------------|
| C1 | Port numbers must be positive | Preconditions |
| C2 | Host names must not be empty | Preconditions |
| C3 | Timeout values must be positive | Preconditions |
| C4 | Credentials required for auth | Preconditions |
| C5 | Message must be valid for send | Preconditions |

---

## Domain Vocabulary

| Term | Definition |
|------|------------|
| SMTP | Simple Mail Transfer Protocol (RFC 5321) |
| TLS | Transport Layer Security (encryption) |
| STARTTLS | Command to upgrade connection to TLS |
| Implicit TLS | TLS from the start (port 465) |
| PLAIN | Authentication mechanism (base64 encoded) |
| LOGIN | Authentication mechanism (challenge-response) |
| MIME | Multipurpose Internet Mail Extensions |
| Base64 | Binary-to-text encoding scheme |

---

## Phase Scope

### Phase 1 (Current)
- SMTP sending with TLS
- Plain text and HTML bodies
- Attachments
- PLAIN and LOGIN authentication

### Phase 2 (Future)
- IMAP client
- POP3 client
- Connection pooling

---

**DOMAIN-MODEL: COMPLETE**
