# 7S-05: SECURITY - simple_email

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## Security Considerations

### Threat Model

| Threat | Mitigation | Status |
|--------|------------|--------|
| Credential interception | TLS encryption | Implemented |
| Man-in-middle attack | Certificate validation | Via SChannel |
| Email header injection | Newline validation | Implemented |
| Attachment malware | Out of scope | N/A |

### Authentication Security

#### Password Handling
- Passwords stored in memory as STRING
- Base64 encoding for PLAIN auth (not encryption!)
- No persistent storage of credentials
- Credentials cleared on disconnect

#### Recommendations
```eiffel
-- Don't hardcode credentials
email.set_credentials (env.get ("SMTP_USER"), env.get ("SMTP_PASS"))

-- Always use TLS
email.connect
email.start_tls  -- Upgrade to encrypted
email.authenticate
```

### TLS Implementation

#### SChannel Usage
- Windows native TLS via SChannel
- TLS 1.2 protocol enforced
- Server certificate validation enabled
- Hostname verification via SNI

#### Cipher Suites
Delegated to Windows SChannel defaults (secure by default).

### Input Validation

#### Email Address Validation
```eiffel
-- Preconditions prevent injection
require
    address_not_empty: not a_address.is_empty
    address_has_at: a_address.has ('@')
    address_no_newlines: not a_address.has ('%R') and not a_address.has ('%N')
```

#### Header Injection Prevention
- Newline characters rejected in addresses
- Subject line encoded via RFC 2047
- No user input directly in headers

### Data Protection

#### In Transit
- TLS encryption for SMTP session
- STARTTLS or implicit TLS (port 465)

#### At Rest
- No local storage of emails
- Attachments read on-demand
- Memory cleared after send

### Known Limitations

1. **No Certificate Pinning:** Trusts Windows certificate store
2. **Memory Security:** Passwords in regular STRING (not secure memory)
3. **No Rate Limiting:** Could be abused for spam if misused
4. **Single-Threaded:** No concurrent send protection

### Security Recommendations

1. Always use TLS (ports 465 or 587 with STARTTLS)
2. Use environment variables for credentials
3. Validate email content before sending
4. Log send attempts for audit
5. Implement application-level rate limiting
