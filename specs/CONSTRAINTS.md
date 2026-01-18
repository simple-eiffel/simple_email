# CONSTRAINTS: simple_email

## Date: 2026-01-18
## Status: Phase 1 Complete

---

## System-Wide Constraints

### Technical Constraints

| ID | Constraint | Enforcement | Rationale |
|----|------------|-------------|-----------|
| TC-001 | SCOOP compatible | concurrency=scoop in ECF | Simple ecosystem requirement |
| TC-002 | Void safety | void_safety=all in ECF | Eliminate null pointer errors |
| TC-003 | Inline C only | No separate .c files | Build simplicity |
| TC-004 | Windows primary | Win32 API via inline C | Target platform |
| TC-005 | EiffelStudio 25.02 | Tested compatibility | Compiler version |

### Architectural Constraints

| ID | Constraint | Enforcement | Rationale |
|----|------------|-------------|-----------|
| AC-001 | Single facade | SIMPLE_EMAIL is entry point | API simplicity |
| AC-002 | No global state | Instance variables only | SCOOP safety |
| AC-003 | Composition over inheritance | Flat class structure | Simplicity |
| AC-004 | Command-Query separation | All features follow CQS | OOSC2 principle |

### Security Constraints

| ID | Constraint | Enforcement | Rationale |
|----|------------|-------------|-----------|
| SC-001 | TLS 1.2+ required | SChannel configuration | Data protection |
| SC-002 | Certificate validation | SChannel default | MITM prevention |
| SC-003 | Credential cleanup | Clear after use | Memory safety |
| SC-004 | No credential storage | Detachable attributes | Security |

---

## Class Invariants (Enforced by Runtime)

### SIMPLE_EMAIL

```eiffel
invariant
    host_exists: smtp_host /= Void
    port_positive: smtp_port > 0
    timeout_positive: timeout > 0
    auth_requires_connection: is_authenticated implies is_connected
    tls_requires_connection: is_tls_active implies is_connected
```

### SE_MESSAGE

```eiffel
invariant
    recipients_exists: recipients /= Void
    cc_exists: cc_recipients /= Void
    bcc_exists: bcc_recipients /= Void
    attachments_exists: attachments /= Void
    valid_implies_has_from_and_recipients: is_valid implies (has_from and has_recipients)
    count_consistent: recipient_count = recipients.count + cc_recipients.count + bcc_recipients.count
    attachment_count_consistent: attachment_count = attachments.count
```

### SE_ATTACHMENT

```eiffel
invariant
    name_exists: internal_name /= Void
    content_type_exists: internal_content_type /= Void
    data_exists: internal_data /= Void
    valid_definition: is_valid = (not internal_name.is_empty and not internal_content_type.is_empty)
    size_consistent: size = internal_data.count
```

### SE_SMTP_CLIENT

```eiffel
invariant
    host_exists: internal_host /= Void
    port_positive: port > 0
    auth_requires_connection: is_authenticated implies is_connected
    tls_requires_connection: is_tls_active implies is_connected
```

### SE_TLS_SOCKET

```eiffel
invariant
    timeout_positive: timeout_ms > 0
    tls_requires_connection: is_tls_active implies is_connected
```

---

## State Machine Constraints

### Connection State Machine

```
                  ┌───────────────┐
                  │ DISCONNECTED  │
                  └───────┬───────┘
                          │ connect()
                          ▼
                  ┌───────────────┐
                  │  CONNECTED    │ ◄─────────┐
                  └───────┬───────┘           │
                          │ start_tls()      │
                          ▼                   │
                  ┌───────────────┐           │
                  │  TLS_ACTIVE   │           │
                  └───────┬───────┘           │
                          │ authenticate()    │
                          ▼                   │
                  ┌───────────────┐           │
                  │ AUTHENTICATED │           │
                  └───────┬───────┘           │
                          │ disconnect()      │
                          └───────────────────┘
```

**Constraints:**
- TLS can only activate from CONNECTED state
- Authentication requires TLS_ACTIVE state
- Sending requires AUTHENTICATED state
- disconnect() returns to DISCONNECTED from any state

---

## Data Constraints

### Email Address

| Constraint | Rule | Example |
|------------|------|---------|
| Not empty | address.count > 0 | "user@domain.com" |
| Contains @ | address.has ('@') | Must have @ symbol |
| Valid format | Matches RFC 5322 | user@domain.tld |

### Port Number

| Constraint | Rule | Standard Ports |
|------------|------|----------------|
| Positive | port > 0 | - |
| Standard SMTP | 25, 587, 465 | Plain, STARTTLS, Implicit TLS |

### Timeout

| Constraint | Rule | Defaults |
|------------|------|----------|
| Positive | timeout > 0 | - |
| Reasonable | timeout <= 300 | Max 5 minutes |
| Default | 30 seconds | Connection timeout |

---

## Protocol Constraints (RFC Compliance)

### SMTP (RFC 5321)

| Constraint | Rule |
|------------|------|
| Line length | Max 998 characters (1000 with CRLF) |
| Command format | Command CRLF |
| Response format | 3-digit code + text |
| Message termination | CRLF.CRLF |

### TLS (RFC 8446)

| Constraint | Rule |
|------------|------|
| Minimum version | TLS 1.2 |
| Certificate validation | Required |
| SNI | Send server hostname |

---

## Dependency Constraints

### Library Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| base | ISE standard | Core Eiffel types |
| net | ISE standard | Network primitives |
| simple_base64 | simple_* | Base64 encoding |

### External Dependencies

| Dependency | Source | Purpose |
|------------|--------|---------|
| WinSock2 | Windows SDK | TCP sockets |
| SChannel | Windows SDK | TLS encryption |

---

**CONSTRAINTS: COMPLETE**
