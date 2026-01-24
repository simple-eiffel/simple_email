# 7S-03: SOLUTIONS - simple_email

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## Existing Solutions Comparison

### Python smtplib
- **Pros:** Built-in, well-documented, cross-platform
- **Cons:** Python-specific, external dependency for Eiffel
- **Approach:** Procedural API, context managers

### Java javax.mail
- **Pros:** Comprehensive, enterprise-ready
- **Cons:** Complex API, heavyweight
- **Approach:** Session-based, many configuration options

### .NET System.Net.Mail
- **Pros:** Modern API, good TLS support
- **Cons:** Windows/.NET only
- **Approach:** SmtpClient class, MailMessage class

### PHP mail() / PHPMailer
- **Pros:** Simple for basic use
- **Cons:** Security concerns with mail(), PHPMailer is complex
- **Approach:** Function-based / OO wrapper

### libcurl with SMTP
- **Pros:** Cross-platform, C library
- **Cons:** Complex setup, callback-heavy
- **Approach:** cURL handle configuration

## simple_email Approach

### Design Philosophy
- Facade pattern for simple API
- Separation of concerns (message vs transport)
- Design by Contract for validation
- Native TLS via Windows SChannel

### Key Differentiators

1. **Eiffel-Native:** Pure Eiffel with inline C for platform calls
2. **DBC Integration:** Contracts validate email addresses, state
3. **Simple API:** Facade hides SMTP complexity
4. **Ecosystem Integration:** Uses simple_base64, simple_encoding

### Architecture

```
SIMPLE_EMAIL (Facade)
    |
    +-- SE_MESSAGE (Email content)
    |       |
    |       +-- SE_ATTACHMENT (File attachments)
    |
    +-- SE_SMTP_CLIENT (Protocol)
            |
            +-- SE_TLS_SOCKET (Transport)
```

### Trade-offs Made

| Decision | Benefit | Cost |
|----------|---------|------|
| Windows SChannel | No external deps | Windows-only |
| Inline C | Single library | Platform coupling |
| Synchronous I/O | Simpler code | Blocking operations |
| No OAuth2 | Simpler auth | Limited providers |
