# S05: CONSTRAINTS - simple_email

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## Technical Constraints

### Platform Constraints

| Constraint | Impact | Rationale |
|------------|--------|-----------|
| Windows only | No Linux/macOS | Uses WinSock, SChannel |
| EiffelStudio 25.02+ | Compiler version | Inline C syntax |
| 64-bit preferred | Memory for attachments | Large file support |

### Protocol Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| SMTP only | No POP3/IMAP | Sending focus |
| TLS 1.2 minimum | Security | SChannel default |
| AUTH PLAIN/LOGIN | No OAuth2 | Simplicity |

### Size Constraints

| Constraint | Limit | Rationale |
|------------|-------|-----------|
| Attachment size | ~10MB | Base64 encoding overhead |
| Line length | 998 chars | RFC 5321 |
| Recipients per message | ~100 | Server limits |

## Business Rules

### Email Address Rules

1. **Must contain @:** `address.has ('@')`
2. **No newlines:** Prevents header injection
3. **Non-empty:** Must have content

### Message Validity Rules

1. **Must have From:** `has_from = True`
2. **Must have recipients:** `has_recipients = True`
3. **Body optional:** Can send empty body

### Connection State Rules

1. **Connect before authenticate**
2. **Authenticate before send**
3. **TLS before authenticate** (recommended)

## State Transitions

```
[Disconnected]
      |
      | connect() / connect_tls()
      v
[Connected] -- start_tls() --> [TLS Active]
      |                              |
      | authenticate()               | authenticate()
      v                              v
[Authenticated] <------------------+
      |
      | send()
      v
[Message Sent]
      |
      | disconnect()
      v
[Disconnected]
```

## Error Conditions

| Condition | Error Message | Recovery |
|-----------|---------------|----------|
| Connection refused | "Connection refused" | Check host/port |
| TLS handshake fail | "TLS handshake failed" | Check TLS support |
| Auth failure | "Authentication failed" | Check credentials |
| Recipient rejected | "RCPT TO rejected" | Check address |
| Message rejected | "Message rejected" | Check content |

## Performance Constraints

| Aspect | Constraint | Reason |
|--------|------------|--------|
| Timeout | Default 30s | Network latency |
| Socket buffer | 4KB | Reasonable size |
| Response buffer | 256 bytes | SMTP responses |
| Blocking I/O | Synchronous | Simplicity |
