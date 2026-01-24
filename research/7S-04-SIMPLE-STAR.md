# 7S-04: SIMPLE-STAR - simple_email

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## Ecosystem Integration

### Dependencies Used

| Library | Purpose | Usage |
|---------|---------|-------|
| simple_base64 | Encode attachments and auth | SIMPLE_BASE64 in SE_SMTP_CLIENT |
| simple_encoding | UTF-8 validation | SIMPLE_ENCODING_DETECTOR in SE_MESSAGE |

### Potential Integrations

| Library | Potential Use |
|---------|---------------|
| simple_json | Parse SMTP server configs |
| simple_file | Read attachments from disk |
| simple_template | Email template rendering |
| simple_http | Webhook notifications |

## API Consistency

### Naming Conventions
- Classes: SE_* prefix for internal, SIMPLE_EMAIL for facade
- Features: Verb-first for commands (set_, add_, send)
- Queries: is_*, has_* for booleans

### Error Handling Pattern
```eiffel
-- Consistent with ecosystem
has_error: BOOLEAN
last_error: detachable STRING

-- Usage pattern
email.connect
if email.has_error then
    print (email.last_error)
end
```

### Creation Pattern
```eiffel
-- Simple facade
create email.make
email.set_smtp_server ("smtp.example.com", 587)
email.set_credentials ("user", "password")
```

## Ecosystem Patterns Applied

### Facade Pattern
SIMPLE_EMAIL wraps complex SMTP internals behind simple API.

### Design by Contract
- Preconditions validate inputs (non-empty addresses, @ symbol)
- Postconditions ensure state changes
- Invariants maintain object consistency

### Inline C Pattern
SE_TLS_SOCKET uses inline C for Windows API calls (WinSock, SChannel).

### Query/Command Separation
- Queries: is_connected, is_authenticated, has_error
- Commands: connect, authenticate, send, disconnect
