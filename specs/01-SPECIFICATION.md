# 01: Specification Layer - simple_email

## Date: 2026-01-18
## Library: simple_email
## Working Hat: SPECIFICATION

---

## 1. DOMAIN MODEL

### Key Domain Concepts

| Concept | Definition | Relationships |
|---------|------------|---------------|
| Email Message | A structured communication with headers and body | Contains headers, body, attachments |
| SMTP Server | Server accepting email for delivery | Receives messages via SMTP protocol |
| IMAP Server | Server providing mailbox access | Serves messages via IMAP protocol |
| Mailbox | Collection of email messages | Contains messages |
| Attachment | File embedded in email | Belongs to message |
| Header | Metadata field (From, To, Subject, etc.) | Belongs to message |
| Address | Email address (user@domain) | Used in From, To, Cc, Bcc headers |
| Credentials | Authentication data (user/password) | Used for server authentication |

### Domain Rules (ALWAYS)

| Rule | Description |
|------|-------------|
| DR-A1 | Message ALWAYS has From address |
| DR-A2 | Message ALWAYS has at least one recipient (To, Cc, or Bcc) |
| DR-A3 | Connection ALWAYS releases resources on disconnect |
| DR-A4 | TLS ALWAYS used when sending credentials |
| DR-A5 | Attachment ALWAYS base64 encoded |

### Domain Rules (NEVER)

| Rule | Description |
|------|-------------|
| DR-N1 | Credentials NEVER sent over plaintext connection |
| DR-N2 | Empty From address NEVER valid |
| DR-N3 | Empty recipient list NEVER valid |
| DR-N4 | Connection NEVER left open indefinitely (timeout) |

---

## 2. ENTITIES (Potential Classes)

### SIMPLE_EMAIL (Facade)

**Domain meaning:** Primary API for email operations - sending and receiving email messages

**Domain rules:**
- Must provide simple API for common operations
- Must hide protocol complexity from user
- Must support both sending (SMTP) and receiving (IMAP/POP3)

---

### SE_MESSAGE (Email Composition)

**Domain meaning:** Represents an email message with headers, body, and attachments

**Domain rules:**
- Must have valid From address
- Must have at least one recipient
- Body can be text, HTML, or both
- Attachments are optional but must be valid when present

---

### SE_SMTP_CLIENT (SMTP Protocol)

**Domain meaning:** Client for sending email via SMTP protocol

**Domain rules:**
- Must connect before sending
- Must authenticate before sending (if credentials provided)
- Must use TLS for authentication
- Must disconnect after operations complete

---

### SE_IMAP_CLIENT (IMAP Protocol - Phase 2)

**Domain meaning:** Client for reading email via IMAP protocol

**Domain rules:**
- Must connect before operations
- Must select mailbox before fetching messages
- Must support listing mailboxes

---

### SE_TLS_SOCKET (TLS Transport)

**Domain meaning:** Secure socket connection with TLS encryption

**Domain rules:**
- Must complete TLS handshake before data transfer
- Must validate server certificate
- Must support TLS 1.2 or higher

---

### SE_ADDRESS

**Domain meaning:** Email address in format "user@domain" or "Name <user@domain>"

**Domain rules:**
- Must have @ symbol
- Must have non-empty local part (before @)
- Must have non-empty domain part (after @)

---

## 3. ACTIONS (Potential Features)

### SIMPLE_EMAIL Actions

| Action | Domain Meaning | Valid When | Result |
|--------|----------------|------------|--------|
| make | Create email client | Always | New client instance |
| set_smtp_server | Configure SMTP server | Before connect | Server configured |
| set_credentials | Set authentication | Before connect | Credentials stored |
| connect | Establish connection | Server configured | Connected state |
| disconnect | Close connection | Connected | Disconnected state |
| send | Send email message | Connected, authenticated | Message delivered |
| is_connected | Query connection state | Always | Boolean |
| is_authenticated | Query auth state | Always | Boolean |

### SE_MESSAGE Actions

| Action | Domain Meaning | Valid When | Result |
|--------|----------------|------------|--------|
| set_from | Set sender address | Always | From set |
| add_to | Add recipient | Always | Recipient added |
| add_cc | Add CC recipient | Always | CC added |
| add_bcc | Add BCC recipient | Always | BCC added |
| set_subject | Set subject line | Always | Subject set |
| set_text_body | Set plain text body | Always | Text body set |
| set_html_body | Set HTML body | Always | HTML body set |
| attach_file | Attach file | File exists | Attachment added |
| is_valid | Check message validity | Always | Boolean |

### SE_SMTP_CLIENT Actions

| Action | Domain Meaning | Valid When | Result |
|--------|----------------|------------|--------|
| connect | Connect to server | Not connected | Connected |
| authenticate | Authenticate to server | Connected, TLS active | Authenticated |
| send_message | Send message | Connected, authenticated | Message sent |
| disconnect | Close connection | Connected | Disconnected |

---

## 4. CONSTRAINTS (Contract Candidates)

### Precondition Candidates ("cannot X" / "valid when")

| Feature | Constraint | Precondition |
|---------|------------|--------------|
| send | Cannot send without From | `message.has_from` |
| send | Cannot send without recipients | `message.has_recipients` |
| send | Cannot send when disconnected | `is_connected` |
| authenticate | Cannot auth without TLS | `is_tls_active` |
| attach_file | Cannot attach non-existent file | `file_exists (a_path)` |
| set_from | Cannot use empty address | `not a_address.is_empty` |

### Postcondition Candidates ("must X" / "result")

| Feature | Constraint | Postcondition |
|---------|------------|---------------|
| connect | Must be connected after | `is_connected` |
| disconnect | Must be disconnected after | `not is_connected` |
| authenticate | Must be authenticated after success | `is_authenticated` |
| set_from | From must be set after | `has_from` |
| add_to | Recipient must be added | `recipients.has (a_address)` |
| send | Message must be sent or error set | `is_sent or has_error` |

### Invariant Candidates ("always X")

| Class | Constraint | Invariant |
|-------|------------|-----------|
| SE_MESSAGE | From address format always valid | `has_from implies is_valid_address (from_address)` |
| SE_SMTP_CLIENT | Auth only when connected | `is_authenticated implies is_connected` |
| SE_TLS_SOCKET | Socket valid when connected | `is_connected implies socket_handle /= default_pointer` |
| SIMPLE_EMAIL | Error cleared on new operation | (managed per operation) |

---

## 5. RELATIONSHIPS

| Relationship | Type | Domain Justification |
|--------------|------|---------------------|
| SIMPLE_EMAIL → SE_SMTP_CLIENT | composition | Facade delegates to SMTP client |
| SIMPLE_EMAIL → SE_IMAP_CLIENT | composition | Facade delegates to IMAP client |
| SIMPLE_EMAIL → SE_MESSAGE | uses | Creates and sends messages |
| SE_SMTP_CLIENT → SE_TLS_SOCKET | composition | SMTP uses TLS transport |
| SE_SMTP_CLIENT → ISE SMTP_PROTOCOL | inheritance/delegation | Extends ISE implementation |
| SE_MESSAGE → ISE EMAIL | inheritance/delegation | Extends ISE implementation |
| SE_MESSAGE → SE_ADDRESS | composition | Contains addresses |

---

## 6. QUERIES vs COMMANDS

### Queries (Return value, no state change)

| Feature | Class | Return Type |
|---------|-------|-------------|
| is_connected | SIMPLE_EMAIL, SE_SMTP_CLIENT | BOOLEAN |
| is_authenticated | SIMPLE_EMAIL, SE_SMTP_CLIENT | BOOLEAN |
| is_tls_active | SE_SMTP_CLIENT, SE_TLS_SOCKET | BOOLEAN |
| is_valid | SE_MESSAGE | BOOLEAN |
| has_from | SE_MESSAGE | BOOLEAN |
| has_recipients | SE_MESSAGE | BOOLEAN |
| has_error | SIMPLE_EMAIL | BOOLEAN |
| last_error | SIMPLE_EMAIL | detachable STRING |
| from_address | SE_MESSAGE | STRING |
| subject | SE_MESSAGE | STRING |
| recipients | SE_MESSAGE | LIST [STRING] |

### Commands (Modify state, no return value)

| Feature | Class | Effect |
|---------|-------|--------|
| set_smtp_server | SIMPLE_EMAIL | Sets server config |
| set_credentials | SIMPLE_EMAIL | Sets auth credentials |
| connect | SIMPLE_EMAIL, SE_SMTP_CLIENT | Opens connection |
| disconnect | SIMPLE_EMAIL, SE_SMTP_CLIENT | Closes connection |
| authenticate | SE_SMTP_CLIENT | Authenticates session |
| set_from | SE_MESSAGE | Sets From header |
| add_to | SE_MESSAGE | Adds To recipient |
| add_cc | SE_MESSAGE | Adds Cc recipient |
| add_bcc | SE_MESSAGE | Adds Bcc recipient |
| set_subject | SE_MESSAGE | Sets Subject header |
| set_text_body | SE_MESSAGE | Sets text body |
| set_html_body | SE_MESSAGE | Sets HTML body |
| attach_file | SE_MESSAGE | Adds attachment |

### Command with Status (Modify state, return success)

| Feature | Class | Return | Effect |
|---------|-------|--------|--------|
| send | SIMPLE_EMAIL | BOOLEAN | Sends message, returns success |

---

## 7. SPECIFICATION QUALITY CHECKS

- [x] Every domain concept has clear definition
- [x] Every domain rule captured (ALWAYS/NEVER)
- [x] Every feature has domain meaning
- [x] Ambiguities explicitly flagged (see below)

### UNCLEAR Items (Need Resolution)

| Item | Ambiguity | Default Assumption |
|------|-----------|-------------------|
| UNCLEAR-1 | Should invalid email address raise precondition or return error? | Precondition (fail-fast) |
| UNCLEAR-2 | How to handle server disconnect during send? | Return False, set last_error |
| UNCLEAR-3 | Should attachment be read at attach time or send time? | Read at send time (lazy) |
| UNCLEAR-4 | Maximum attachment size? | No limit enforced by library |

---

**01-SPECIFICATION: COMPLETE**

Next Step: 02-DEFINE-CLASS-STRUCTURE.md
