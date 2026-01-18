# LANDSCAPE ANALYSIS: simple_email

## Date: 2026-01-18
## Library: simple_email

---

## Summary

The email library landscape is mature in mainstream languages (Python, Java, .NET) but non-existent in Eiffel. We must BUILD from scratch using existing simple_* infrastructure (simple_base64, simple_http patterns) and potentially ISE's low-level networking primitives. No viable ADOPT or ADAPT options exist.

---

## Existing Solutions Inventory

| Name | Type | Platform | Maturity | License |
|------|------|----------|----------|---------|
| Python smtplib/imaplib | LIBRARY | Python | MATURE | PSF |
| Simple Java Mail | LIBRARY | Java | MATURE | Apache 2.0 |
| Jakarta Mail (JavaMail) | LIBRARY | Java | MATURE | EPL 2.0 |
| MailKit | LIBRARY | .NET | MATURE | MIT |
| MimeKit | LIBRARY | .NET | MATURE | MIT |
| Apache James | SERVER | Java | MATURE | Apache 2.0 |
| GreenMail | TESTING | Java | MATURE | Apache 2.0 |

---

## Solution Analysis

### Python smtplib/imaplib

**PURPOSE:**
- What it does: Standard library modules for SMTP and IMAP clients
- Problem it solves: Send and receive email from Python applications

**STRENGTHS:**
+ Built into Python - no dependencies
+ Well-documented with extensive examples
+ Battle-tested over 20+ years
+ Low-level access for protocol control

**WEAKNESSES:**
- Low-level API requires manual MIME handling
- Separate modules for sending (smtplib) and receiving (imaplib)
- Email composition requires `email` module separately
- No built-in retry or connection pooling

**FEATURES:**
- Core: SMTP/ESMTP client, IMAP4rev1 client
- Notable: STARTTLS support, authentication mechanisms
- Missing: High-level compose API, attachment helpers

**ARCHITECTURE:**
- Pattern: Thin protocol wrappers
- Key abstractions: SMTP object, IMAP4 object

**API SAMPLE:**
```python
import smtplib
from email.mime.text import MIMEText

msg = MIMEText("Hello")
msg['Subject'] = 'Test'
msg['From'] = 'sender@example.com'
msg['To'] = 'recipient@example.com'

with smtplib.SMTP('smtp.example.com', 587) as server:
    server.starttls()
    server.login('user', 'password')
    server.send_message(msg)
```

**RELEVANCE TO US:**
- Addresses our needs: 70%
- Could adopt: NO (Python)
- Learn from: Protocol handling patterns, API simplicity

---

### Simple Java Mail

**PURPOSE:**
- What it does: High-level email API for Java
- Problem it solves: Make sending email easy without JavaMail complexity

**STRENGTHS:**
+ Simple, fluent API (builder pattern)
+ RFC compliant (16+ years development)
+ DKIM, S/MIME, OAuth2 support
+ Batch sending, clustering support
+ CRLF injection protection

**WEAKNESSES:**
- Depends on Jakarta Mail underneath
- Java-only
- Heavy for simple use cases

**FEATURES:**
- Core: SMTP send, attachments, HTML/text, templates
- Notable: DKIM signing, S/MIME encryption, OAuth2 auth
- Missing: IMAP/POP3 receive capability

**ARCHITECTURE:**
- Pattern: Builder + Facade
- Key abstractions: Email, Mailer, EmailBuilder

**API SAMPLE:**
```java
Email email = EmailBuilder.startingBlank()
    .from("sender@example.com")
    .to("recipient@example.com")
    .withSubject("Hello")
    .withPlainText("World!")
    .buildEmail();

Mailer mailer = MailerBuilder
    .withSMTPServer("smtp.example.com", 587, "user", "pass")
    .withTransportStrategy(TransportStrategy.SMTP_TLS)
    .buildMailer();

mailer.sendMail(email);
```

**RELEVANCE TO US:**
- Addresses our needs: 60% (SMTP only)
- Could adopt: NO (Java)
- Learn from: Builder pattern, RFC compliance focus, security features

---

### MailKit (.NET)

**PURPOSE:**
- What it does: Cross-platform .NET library for IMAP, POP3, SMTP
- Problem it solves: Full email client functionality for .NET

**STRENGTHS:**
+ Complete: SMTP, IMAP, POP3 all in one
+ RFC compliant and well-tested
+ Async-first design with cancellation
+ Extensive protocol extension support
+ Built on MimeKit (robust MIME handling)
+ MIT licensed, .NET Foundation project

**WEAKNESSES:**
- .NET-only
- Large API surface (many extensions)
- Requires MimeKit dependency

**FEATURES:**
- Core: SMTP, IMAP, POP3 with full TLS
- Notable: OAUTH2, NTLM, GSSAPI auth; proxy support; IDLE
- Missing: Nothing significant for email client

**ARCHITECTURE:**
- Pattern: Protocol-specific clients (SmtpClient, ImapClient, Pop3Client)
- Key abstractions: MimeMessage, SmtpClient, ImapClient, Pop3Client

**API SAMPLE:**
```csharp
using var client = new SmtpClient();
await client.ConnectAsync("smtp.example.com", 587, SecureSocketOptions.StartTls);
await client.AuthenticateAsync("user", "password");

var message = new MimeMessage();
message.From.Add(new MailboxAddress("Sender", "sender@example.com"));
message.To.Add(new MailboxAddress("Recipient", "recipient@example.com"));
message.Subject = "Hello";
message.Body = new TextPart("plain") { Text = "World!" };

await client.SendAsync(message);
await client.DisconnectAsync(true);
```

**RELEVANCE TO US:**
- Addresses our needs: 95%
- Could adopt: NO (.NET)
- Learn from: Protocol separation, async design, comprehensive extension support

---

## Pattern Identification

### COMMON PATTERNS

| Pattern | Seen In | Description | Adopt? |
|---------|---------|-------------|--------|
| Builder Pattern | Simple Java Mail | Fluent API for constructing emails | YES |
| Protocol-Specific Clients | MailKit | Separate classes for SMTP/IMAP/POP3 | ADAPT |
| Facade Pattern | All | Single entry point for common operations | YES |
| MIME Abstraction | MailKit, JavaMail | Separate MIME handling from protocol | YES |
| Connection State Machine | All | Connect → Auth → Command → Disconnect | YES |
| TLS Upgrade | All | STARTTLS for secure upgrade | YES |

### ANTI-PATTERNS

| Anti-Pattern | Seen In | Problem | Avoid By |
|--------------|---------|---------|----------|
| Monolithic Client | Early smtplib | One class does everything | Separation of concerns |
| Blocking I/O | Python smtplib | Blocks calling thread | SCOOP compatibility |
| String-Based MIME | Manual approach | Error-prone MIME construction | Typed structures |
| Credentials in Memory | Naive implementations | Security risk | Clear after use |

---

## Comparative Analysis

### Feature Matrix

| Feature | Python smtp/imap | Simple Java Mail | MailKit |
|---------|-----------------|------------------|---------|
| SMTP Send | ✓ | ✓ | ✓ |
| IMAP Receive | ✓ | ✗ | ✓ |
| POP3 Receive | ✗ | ✗ | ✓ |
| TLS/STARTTLS | ✓ | ✓ | ✓ |
| Attachments | Manual | ✓ | ✓ |
| HTML Email | Manual | ✓ | ✓ |
| OAuth2 | Manual | ✓ | ✓ |
| Async | ✗ | ✓ | ✓ |
| Builder API | ✗ | ✓ | ✗ |

### Scores

| Criterion | Python | Simple Java Mail | MailKit |
|-----------|--------|------------------|---------|
| Completeness | 3 | 3 | 5 |
| Ease of use | 2 | 5 | 4 |
| Performance | 3 | 4 | 5 |
| Documentation | 4 | 5 | 5 |
| Maintenance | 5 | 4 | 5 |
| **Total** | **17** | **21** | **24** |

---

## Eiffel Ecosystem

### ISE Libraries

| Library | Relevance | Usable? |
|---------|-----------|---------|
| NET_HTTP_CLIENT | HTTP only, not SMTP/IMAP | NO |
| SOCKET | Low-level TCP | MAYBE |
| SSL_CONTEXT | TLS support | MAYBE |

### Simple Eiffel Ecosystem

| Library | Relevance | Usable? |
|---------|-----------|---------|
| simple_base64 | Base64 for AUTH and attachments | YES |
| simple_http | HTTP patterns (not protocol) | PATTERNS |
| simple_encoding | Character encoding | MAYBE |
| simple_websocket | TCP/TLS patterns | PATTERNS |

### GAPS

**Not available in Eiffel:**
- SMTP client library
- IMAP client library
- POP3 client library
- MIME composition library

**Would require:**
- TCP socket with TLS support
- SMTP protocol implementation
- IMAP protocol implementation
- MIME encoding/decoding

---

## Build vs Buy vs Adapt

### OPTION 1: BUILD (Create from scratch)

| Aspect | Assessment |
|--------|------------|
| Effort | HIGH |
| Risk | MEDIUM |
| Benefit | Full control, DBC integration, ecosystem fit |
| Drawback | Significant development time |

### OPTION 2: BUY/ADOPT (Use existing solution)

| Aspect | Assessment |
|--------|------------|
| Candidate | None available for Eiffel |
| Fit | N/A |
| Gaps | N/A |
| Effort | N/A |

### OPTION 3: ADAPT (Modify existing)

| Aspect | Assessment |
|--------|------------|
| Base | None available |
| Changes | N/A |
| Effort | N/A |
| Licensing | N/A |

### INITIAL RECOMMENDATION: BUILD

**Rationale:** No Eiffel email libraries exist. The only viable path is to BUILD from scratch, leveraging:
1. `simple_base64` for encoding
2. Patterns from `simple_http` for API design
3. ISE SOCKET/SSL primitives for networking
4. RFCs for protocol implementation

---

## Lessons Learned

### DO
- Use builder/fluent API pattern (Simple Java Mail)
- Separate MIME handling from protocol handling (MailKit)
- Support multiple authentication mechanisms (MailKit)
- Implement connection state machine properly
- Clear credentials from memory after use
- Support both implicit TLS (port 465/993/995) and STARTTLS
- Make operations cancellable (SCOOP-friendly)

### DON'T
- Mix protocol and composition concerns
- Store passwords in plain text
- Block on I/O without timeout
- Ignore TLS certificate validation
- Assume server compliance (be defensive)
- Hard-code port numbers (make configurable)

### OPEN QUESTIONS
- Q1: Does ISE provide a usable SSL/TLS socket library?
- Q2: Can we use inline C for Win32 WinSock/SChannel?
- Q3: Should MIME be a separate library (simple_mime)?
- Q4: What authentication methods are essential for MVP?

---

## References

### RFC Standards
- [RFC 5321 - SMTP](https://www.rfc-editor.org/rfc/rfc5321.html)
- [RFC 3501 - IMAP4rev1](https://www.rfc-editor.org/rfc/rfc3501)
- [RFC 1939 - POP3](https://www.ietf.org/rfc/rfc1939.txt)
- [RFC 2045-2049 - MIME](https://www.rfc-editor.org/rfc/rfc2045)

### Library Documentation
- [Python smtplib](https://docs.python.org/3/library/smtplib.html)
- [Python imaplib](https://docs.python.org/3/library/imaplib.html)
- [Simple Java Mail](https://www.simplejavamail.org/)
- [MailKit GitHub](https://github.com/jstedfast/MailKit)
- [MailKit Documentation](https://mimekit.net/docs/html/Introduction.htm)

### Tutorials
- [Baeldung - Java Email Attachments](https://www.baeldung.com/java-send-emails-attachments)
- [Mailtrap - Java Send Email](https://mailtrap.io/blog/java-send-email/)

---

**7S-02-LANDSCAPE: COMPLETE**

Next Step: 7S-03-REQUIREMENTS (Define detailed requirements)
