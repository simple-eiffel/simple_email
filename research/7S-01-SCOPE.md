# 7S-01: SCOPE - simple_email


**Date**: 2026-01-23

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## Problem Domain

Email sending via SMTP protocol with TLS/SSL encryption support. The library addresses the need for programmatic email composition and transmission from Eiffel applications.

## Target Users

- Eiffel developers needing to send emails from applications
- Systems requiring automated email notifications
- Applications with user communication requirements
- Batch processing systems sending reports

## Problem Statement

Eiffel lacks a native, simple-to-use email library. Developers need to:
1. Compose emails with headers, body, and attachments
2. Connect to SMTP servers securely (TLS/STARTTLS)
3. Authenticate with credentials
4. Handle multipart MIME messages

## Boundaries

### In Scope
- SMTP client for sending emails
- TLS/SSL encryption via Windows SChannel
- PLAIN and LOGIN authentication mechanisms
- Multipart MIME message composition
- File attachments
- Text and HTML body support
- To, Cc, Bcc recipients

### Out of Scope
- Email receiving (POP3/IMAP)
- Email storage/parsing
- Advanced authentication (OAuth2)
- Non-Windows platforms
- Bounce handling
- Mailing lists

## Success Criteria

1. Send basic text emails successfully
2. Support TLS encryption on standard ports (465, 587)
3. Handle attachments up to reasonable sizes
4. Proper UTF-8 encoding in headers and body
5. Clear error reporting on failures

## Dependencies

- simple_base64: For attachment encoding and auth credentials
- simple_encoding: For UTF-8 validation
- Windows SChannel: For TLS support
- WinSock2: For TCP sockets
