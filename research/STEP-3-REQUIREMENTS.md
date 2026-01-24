# REQUIREMENTS: simple_email


**Date**: 2026-01-18

## Date: 2026-01-18
## Library: simple_email

---

## Requirements Summary

| Type | MUST | SHOULD | COULD | Total |
|------|------|--------|-------|-------|
| Functional | 12 | 8 | 5 | 25 |
| Non-Functional | 10 | 4 | 0 | 14 |
| Constraints | 8 | 0 | 0 | 8 |

---

## Functional Requirements

### Core (MUST)

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-001 | Create SMTP connection | Test connects to SMTP server on ports 25, 587, 465 |
| FR-002 | SMTP authentication (PLAIN) | Test authenticates with username/password |
| FR-003 | SMTP authentication (LOGIN) | Test authenticates with LOGIN mechanism |
| FR-004 | STARTTLS upgrade | Test upgrades connection on port 587 |
| FR-005 | Implicit TLS (port 465) | Test connects securely to port 465 |
| FR-006 | Send plain text email | Test sends and server receives message |
| FR-007 | Set From address | Test message has correct From header |
| FR-008 | Set To/Cc/Bcc addresses | Test message has correct recipient headers |
| FR-009 | Set Subject | Test message has correct Subject header |
| FR-010 | Disconnect/cleanup | Test releases connection resources |
| FR-011 | Error reporting | Test returns meaningful error on failure |
| FR-012 | Connection timeout | Test times out on unresponsive server |

**FR-001: Create SMTP connection**
- Description: Connect to SMTP server at specified host and port
- Rationale: Foundation for all email sending
- Priority: MUST
- Acceptance criteria:
  - Connects to localhost:25 (testing)
  - Connects to external server:587
  - Connects to external server:465
  - Reports connection failure clearly

**FR-004: STARTTLS upgrade**
- Description: Upgrade plain connection to TLS using STARTTLS command
- Rationale: Required by most modern email servers on port 587
- Priority: MUST
- Acceptance criteria:
  - Sends STARTTLS command
  - Upgrades to TLS 1.2+
  - Continues SMTP conversation encrypted

### Important (SHOULD)

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-013 | Send HTML email | Test sends multipart/alternative with HTML |
| FR-014 | Attach files | Test sends multipart/mixed with attachment |
| FR-015 | Multiple recipients | Test sends to multiple To, Cc, Bcc |
| FR-016 | IMAP connection | Test connects to IMAP server |
| FR-017 | IMAP list mailboxes | Test retrieves mailbox list |
| FR-018 | IMAP select mailbox | Test selects INBOX |
| FR-019 | IMAP fetch message | Test retrieves message content |
| FR-020 | POP3 connection | Test connects to POP3 server |

**FR-014: Attach files**
- Description: Attach one or more files to email
- Rationale: Essential for sending reports, documents
- Priority: SHOULD
- Acceptance criteria:
  - Attaches file from path
  - Sets correct Content-Type
  - Base64 encodes content
  - Sets Content-Disposition: attachment

### Nice to Have (COULD)

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-021 | POP3 list messages | Test retrieves message list |
| FR-022 | POP3 retrieve message | Test downloads message |
| FR-023 | POP3 delete message | Test marks message for deletion |
| FR-024 | Custom headers | Test adds custom X-headers |
| FR-025 | Connection pooling | Test reuses connection |

### Excluded (WON'T)

| ID | Requirement | Reason |
|----|-------------|--------|
| FR-X01 | OAuth2/XOAUTH2 | Requires external token management |
| FR-X02 | S/MIME encryption | Requires certificate infrastructure |
| FR-X03 | DKIM signing | Server-side concern |
| FR-X04 | Full MIME parser | Too complex for MVP |
| FR-X05 | Email server (MTA) | Different project scope |

---

## Non-Functional Requirements

### Performance

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-P-001 | Connection time | Time to connect | < 5 seconds |
| NFR-P-002 | Send time | Time to send 1KB email | < 2 seconds |
| NFR-P-003 | Memory usage | Memory per connection | < 10 MB |

### Reliability

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-R-001 | Connection retry | Retry on failure | 3 attempts |
| NFR-R-002 | Timeout handling | Graceful timeout | No crash |
| NFR-R-003 | Error recovery | Recoverable errors | 100% handled |

### Security

| ID | Requirement | Threat | Control |
|----|-------------|--------|---------|
| NFR-S-001 | TLS encryption | Eavesdropping | TLS 1.2+ required |
| NFR-S-002 | Certificate validation | MITM attacks | Verify server cert |
| NFR-S-003 | Credential handling | Credential theft | Clear after use |
| NFR-S-004 | Input validation | Injection attacks | Validate all input |

### Compatibility

| ID | Requirement | Must Work With |
|----|-------------|----------------|
| NFR-C-001 | Gmail | smtp.gmail.com, imap.gmail.com |
| NFR-C-002 | Outlook/O365 | smtp.office365.com |
| NFR-C-003 | Generic SMTP | Any RFC 5321 compliant server |
| NFR-C-004 | SCOOP | Concurrent Eiffel applications |

### Maintainability

| ID | Requirement | Standard |
|----|-------------|----------|
| NFR-M-001 | DBC contracts | All features have require/ensure |
| NFR-M-002 | Void safety | All code void-safe |
| NFR-M-003 | Documentation | All public features documented |

---

## Constraints

| ID | Type | Constraint | Impact | Negotiable |
|----|------|------------|--------|------------|
| C-T-001 | Technical | SCOOP compatible | No blocking I/O | NO |
| C-T-002 | Technical | Void safety | All types must be attached/detachable | NO |
| C-T-003 | Technical | Inline C pattern | No separate .c files | NO |
| C-T-004 | Technical | Windows primary | Win32 API available | NO |
| C-T-005 | Technical | EiffelStudio 25.02 | Compiler compatibility | NO |
| C-B-001 | Business | Simple API | Single facade class | NO |
| C-B-002 | Business | Ecosystem fit | Follow simple_* patterns | NO |
| C-R-001 | Regulatory | RFC compliance | Must follow SMTP/IMAP/POP3 RFCs | NO |

---

## Use Cases

### UC-001: Send Simple Email

**Actor:** Application code
**Goal:** Send a plain text notification email

**Preconditions:**
- SMTP server accessible
- Valid credentials

**Postconditions:**
- Email delivered to server
- Connection closed
- Resources released

**Main Success Scenario:**
1. Application creates email object
2. Application sets SMTP server and credentials
3. Application sets From, To, Subject, Body
4. Application calls send
5. System connects to SMTP server
6. System authenticates
7. System sends MAIL FROM, RCPT TO, DATA
8. System receives success response
9. System disconnects
10. send returns True

**Extensions:**
- 5a. Connection fails:
  - System retries up to 3 times
  - If all fail, send returns False with error
- 6a. Authentication fails:
  - System sets last_error
  - send returns False
- 8a. Server rejects:
  - System captures error message
  - send returns False

**Error Conditions:**
- E1: Network unreachable → is_valid = False, last_error set
- E2: Server timeout → is_valid = False, last_error set
- E3: Invalid credentials → is_valid = False, last_error set
- E4: Recipient rejected → is_valid = False, last_error set

**Requirements Satisfied:** FR-001 through FR-012

---

### UC-002: Send Email with Attachment

**Actor:** Reporting system
**Goal:** Email a PDF report

**Preconditions:**
- SMTP server accessible
- File exists and is readable

**Postconditions:**
- Email with attachment delivered
- File content base64 encoded

**Main Success Scenario:**
1. Application creates email object
2. Application sets server, credentials, recipients
3. Application calls attach_file("report.pdf")
4. System reads file content
5. System base64 encodes content
6. Application calls send
7. System constructs multipart/mixed message
8. System sends email
9. send returns True

**Extensions:**
- 4a. File not found:
  - attach_file returns False
  - is_valid = False, last_error = "File not found"

**Requirements Satisfied:** FR-014

---

### UC-003: Check Email via IMAP

**Actor:** Mail processing application
**Goal:** Read emails from inbox

**Preconditions:**
- IMAP server accessible
- Valid credentials
- INBOX exists

**Postconditions:**
- Messages retrieved
- Connection closed

**Main Success Scenario:**
1. Application creates IMAP client
2. Application connects to server
3. Application authenticates
4. Application selects INBOX
5. Application fetches message list
6. Application iterates messages
7. Application disconnects

**Requirements Satisfied:** FR-016 through FR-019

---

## Data Requirements

### Email Message Entity

**Attributes:**
- from_address: STRING (required)
- to_addresses: LIST[STRING] (at least one)
- cc_addresses: LIST[STRING] (optional)
- bcc_addresses: LIST[STRING] (optional)
- subject: STRING (optional, empty allowed)
- text_body: STRING (optional)
- html_body: STRING (optional)
- attachments: LIST[ATTACHMENT] (optional)
- custom_headers: HASH_TABLE[STRING, STRING] (optional)

**Constraints:**
- from_address must be valid email format
- All recipient addresses must be valid email format
- At least text_body or html_body must be set

### Attachment Entity

**Attributes:**
- filename: STRING (required)
- content_type: STRING (required, e.g., "application/pdf")
- content: ARRAY[NATURAL_8] (required)

**Constraints:**
- filename must not be empty
- content must not be empty

---

## Interface Requirements

### API Interface (Eiffel Classes)

**IR-API-001: Facade Class**
- Consumer: Application code
- Protocol: Eiffel method calls
- Format: Builder/fluent pattern

**IR-API-002: Error Reporting**
- Consumer: Application code
- Protocol: Query features
- Format: is_valid: BOOLEAN, last_error: detachable STRING

### External System Interface

**IR-EXT-001: SMTP Server**
- System: Remote SMTP server
- Integration: TCP socket + TLS
- Ports: 25, 587 (STARTTLS), 465 (implicit TLS)

**IR-EXT-002: IMAP Server**
- System: Remote IMAP server
- Integration: TCP socket + TLS
- Ports: 143 (STARTTLS), 993 (implicit TLS)

**IR-EXT-003: POP3 Server**
- System: Remote POP3 server
- Integration: TCP socket + TLS
- Ports: 110 (STARTTLS), 995 (implicit TLS)

---

## Dependencies

### Requirement Dependencies

```
FR-006 (Send email) depends on:
  ├── FR-001 (Connect)
  ├── FR-002 or FR-003 (Auth)
  └── FR-004 or FR-005 (TLS)

FR-013 (HTML email) depends on:
  └── FR-006 (Send email)

FR-014 (Attachments) depends on:
  └── FR-006 (Send email)

FR-019 (IMAP fetch) depends on:
  ├── FR-016 (IMAP connect)
  └── FR-018 (IMAP select)
```

### Implementation Order

**Phase 1 (MVP - SMTP Send):**
1. FR-001: SMTP connection
2. FR-004, FR-005: TLS support
3. FR-002, FR-003: Authentication
4. FR-006 through FR-012: Send email basics

**Phase 2 (Enhanced SMTP):**
5. FR-013: HTML email
6. FR-014: Attachments
7. FR-015: Multiple recipients

**Phase 3 (IMAP):**
8. FR-016 through FR-019: IMAP client

**Phase 4 (POP3):**
9. FR-020 through FR-023: POP3 client

---

## Open Questions

### Gaps

| ID | Gap | Needs Clarification |
|----|-----|---------------------|
| GAP-001 | TLS implementation | Does ISE provide usable TLS sockets? |
| GAP-002 | SCOOP integration | How to handle blocking I/O in SCOOP? |
| GAP-003 | Win32 SChannel | Can we use WinSock + SChannel inline C? |

### Assumptions

| ID | Assumption | Risk if Wrong |
|----|------------|---------------|
| ASM-001 | ISE SOCKET exists and works | Must implement TCP layer |
| ASM-002 | simple_base64 is sufficient | Must extend for MIME |
| ASM-003 | Inline C can call SChannel | Need alternative TLS |
| ASM-004 | SCOOP can wait on socket | Need async pattern |

---

**7S-03-REQUIREMENTS: COMPLETE**

Next Step: 7S-04-DECISIONS (Make design choices)
