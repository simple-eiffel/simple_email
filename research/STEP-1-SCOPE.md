# SCOPE DEFINITION: simple_email


**Date**: 2026-01-18

## Date: 2026-01-18
## Library: simple_email
## Purpose: Email client library for SMTP/IMAP/POP3

---

## Problem Statement

**In one sentence:**
The Simple Eiffel ecosystem lacks a native email client library for sending and receiving emails.

**In detail:**
- **What's wrong today:** Eiffel developers who need email functionality must either use external tools, shell out to command-line utilities (like sendmail), or resort to FFI wrappers around C libraries. There is no pure-Eiffel email solution that follows Design by Contract principles.
- **Who experiences this:** Eiffel developers building applications requiring:
  - Automated email notifications
  - Email-based workflows
  - Mail processing systems
  - User-facing email clients
- **How often:** Any application needing email integration faces this gap
- **What's the impact:** Developers must cobble together solutions, lose DBC guarantees, or switch languages for email features

**Problem Validation:**
- Is this a real problem? YES - No simple_* email library exists in the ecosystem (verified via oracle)
- Is it worth solving? YES - Email is fundamental to most business applications
- Has it been solved before? In other languages (Java Mail, Python smtplib/imaplib), but not in Eiffel with DBC

---

## Target Users

| User Type | Needs | Pain Level |
|-----------|-------|------------|
| Eiffel application developers | Send transactional emails (notifications, alerts, reports) | HIGH |
| DevOps/automation engineers | Automated email workflows with Eiffel tools | MEDIUM |
| Integration developers | Email as part of larger Eiffel systems | HIGH |

**Primary Users:**
- Eiffel developers building business applications
- Need: Simple API to send emails with attachments, receive/read emails
- Current solution: Shell commands, external services, or switching languages
- Pain level: HIGH

**Non-Users (explicitly):**
- Users needing a full email server implementation (use Apache James instead)
- Users needing email marketing/bulk sending (specialized services exist)
- Users needing webmail UI (this is a library, not an application)

---

## Success Criteria

| Level | Criterion | Measure |
|-------|-----------|---------|
| MVP | Send plain-text email via SMTP | Test sends email to local test server |
| MVP | Basic TLS/STARTTLS support | Connects securely to port 465/587 |
| MVP | SMTP AUTH (PLAIN, LOGIN) | Authenticates with credentials |
| Full | Send HTML emails with attachments | Test sends multipart MIME message |
| Full | Receive emails via IMAP | Test retrieves messages from server |
| Full | Receive emails via POP3 | Test retrieves messages with delete |
| Stretch | OAuth2 authentication | Authenticates with modern providers |
| Stretch | MIME parsing | Parse incoming email structure |

**Anti-Success (failure criteria):**
- Library crashes on malformed server responses
- Passwords transmitted in clear text without user awareness
- Blocking I/O freezes SCOOP-based applications

---

## Scope

### In Scope (Core Capabilities - MUST)

1. **SMTP Client** (RFC 5321)
   - Connect to SMTP server (port 25, 587, 465)
   - STARTTLS upgrade on port 587
   - Implicit TLS on port 465
   - AUTH PLAIN, AUTH LOGIN
   - MAIL FROM, RCPT TO, DATA commands
   - Send plain text messages

2. **Email Composition**
   - Set From, To, Cc, Bcc, Subject
   - Plain text body
   - HTML body (MIME multipart/alternative)
   - File attachments (MIME multipart/mixed)
   - Proper header encoding (RFC 2047)

3. **Security**
   - TLS 1.2+ support (via simple_ssl or Win32 SChannel)
   - Certificate validation
   - Credential handling (not stored in memory longer than needed)

### In Scope (Extended Capabilities - SHOULD)

4. **IMAP Client** (RFC 3501/9051)
   - Connect to IMAP server (port 143, 993)
   - LIST mailboxes
   - SELECT mailbox
   - FETCH message headers
   - FETCH message body
   - SEARCH messages
   - DELETE/EXPUNGE messages

5. **POP3 Client** (RFC 1939)
   - Connect to POP3 server (port 110, 995)
   - LIST messages
   - RETR message
   - DELE message
   - QUIT (commit deletions)

### Out of Scope

| Excluded | Reason |
|----------|--------|
| Email server (MTA) | Use Apache James or Postfix |
| Spam filtering | Application-level concern |
| Email templating | Use simple_template |
| Bulk sending | Use specialized services (SendGrid, etc.) |
| MIME parsing beyond basics | Extremely complex, defer |
| Calendar invites (iCal) | Separate library potential |

### Deferred to Future

| Future Item | Why Later |
|-------------|-----------|
| OAuth2/XOAUTH2 | Requires token management complexity |
| S/MIME encryption | Requires certificate infrastructure |
| DKIM signing | Server-side concern typically |
| Full MIME parser | Very complex, needs dedicated effort |

---

## Constraints

| Type | Constraint |
|------|------------|
| Technical | Must be SCOOP-compatible (concurrency=scoop) |
| Technical | Must use inline C pattern (no separate .c files) |
| Technical | Must work on Windows (primary) and Linux |
| Technical | May use simple_ssl for TLS or Win32 SChannel |
| Technical | May use simple_socket for TCP connections |
| Design | Must follow DBC (require/ensure/invariant) |
| Design | Must be void-safe |
| Design | Single-class facade pattern (SIMPLE_EMAIL) |

---

## High-Level Use Cases

### UC-1: Send Notification Email
**Actor:** Application code
**Goal:** Send a transactional email (password reset, order confirmation)
**Scenario:**
```eiffel
create email.make
email.set_smtp_server ("smtp.example.com", 587)
email.set_credentials ("user@example.com", "password")
email.set_from ("noreply@example.com")
email.set_to ("customer@example.com")
email.set_subject ("Order Confirmation")
email.set_body ("Your order #12345 has shipped.")
if email.send then
    -- success
end
```

### UC-2: Send Email with Attachment
**Actor:** Reporting system
**Goal:** Email a generated PDF report
**Scenario:**
```eiffel
email.attach_file ("report.pdf")
email.send
```

### UC-3: Check Inbox via IMAP
**Actor:** Mail processing application
**Goal:** Read new emails from inbox
**Scenario:**
```eiffel
create inbox.make_imap ("imap.example.com", 993)
inbox.set_credentials ("user@example.com", "password")
inbox.connect
across inbox.messages as msg loop
    print (msg.subject)
end
inbox.disconnect
```

### UC-4: Download and Delete via POP3
**Actor:** Mail archiver
**Goal:** Download emails and remove from server
**Scenario:**
```eiffel
create pop.make_pop3 ("pop.example.com", 995)
pop.connect
across pop.messages as msg loop
    archive (msg)
    msg.delete
end
pop.disconnect -- commits deletions
```

---

## Assumptions

| ID | Assumption | Needs Validation |
|----|------------|------------------|
| A-1 | simple_ssl provides adequate TLS support | YES - check API |
| A-2 | simple_socket provides TCP client capability | YES - check API |
| A-3 | Inline C can call Win32 SChannel if needed | YES - research |
| A-4 | Base64 encoding available (for AUTH, attachments) | YES - check libs |
| A-5 | SCOOP will not block on socket I/O | YES - test |

---

## Research Questions

**About the problem:**
- Q1: What email features do typical Eiffel applications need?
- Q2: What existing Eiffel email code exists (if any)?

**About existing solutions:**
- Q3: How do Simple Java Mail and Python's email libs structure their APIs?
- Q4: What are common pitfalls in email library design?

**About our approach:**
- Q5: Should we use simple_ssl or native Win32 SChannel?
- Q6: How should we handle async operations with SCOOP?

**About feasibility:**
- Q7: Can we implement MIME encoding without external deps?
- Q8: Is Base64 available in existing simple_* libraries?

---

## Stakeholders

| Stakeholder | Interest |
|-------------|----------|
| Larry (Lead Developer) | Primary user, quality bar |
| Eiffel community | Potential library users |
| simple_* ecosystem | Must integrate cleanly |

**Decision Makers:** Larry

**Information Sources:**
- RFC 5321 (SMTP): https://www.rfc-editor.org/rfc/rfc5321.html
- RFC 3501 (IMAP4rev1): https://www.rfc-editor.org/rfc/rfc3501
- RFC 9051 (IMAP4rev2): https://www.rfc-editor.org/rfc/rfc9051
- RFC 1939 (POP3): https://www.ietf.org/rfc/rfc1939.txt
- RFC 2045-2049 (MIME): https://www.rfc-editor.org/rfc/rfc2045
- Simple Java Mail: https://www.simplejavamail.org/

---

## Summary

**simple_email** will provide:
1. SMTP client for sending emails (MVP priority)
2. Email composition with attachments (MVP priority)
3. IMAP client for reading emails (Phase 2)
4. POP3 client for downloading emails (Phase 2)
5. TLS security throughout

Following the simple_* pattern: one facade class, DBC contracts, SCOOP-compatible, void-safe.

---

**7S-01-SCOPE: COMPLETE**

Next Step: 7S-02-LANDSCAPE (Survey existing solutions)
