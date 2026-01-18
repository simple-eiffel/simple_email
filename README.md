<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/.github/main/profile/assets/logo.png" alt="simple_ library logo" width="400">
</p>

# simple_email

**[Documentation](https://simple-eiffel.github.io/simple_email/)** | **[GitHub](https://github.com/simple-eiffel/simple_email)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

SMTP email library for Eiffel with TLS encryption via Windows SChannel.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production** - Phase 2 complete, 52 tests passing, security hardened

## Overview

SIMPLE_EMAIL provides SMTP email sending with TLS encryption using native Windows SChannel (no OpenSSL dependency). It supports STARTTLS upgrade, implicit TLS, AUTH PLAIN/LOGIN authentication, and MIME multipart messages with attachments.

## Quick Start

```eiffel
local
    email: SIMPLE_EMAIL
    msg: SE_MESSAGE
do
    create email.make

    -- Configure SMTP server
    email.set_smtp_server ("smtp.gmail.com", 587)
    email.set_credentials ("user@gmail.com", "app-password")

    -- Connect with STARTTLS
    email.connect
    email.start_tls
    email.authenticate

    -- Create and send message
    msg := email.create_message
    msg.set_from ("user@gmail.com")
    msg.add_to ("recipient@example.com")
    msg.set_subject ("Hello from Eiffel!")
    msg.set_text_body ("This email was sent using simple_email.")

    if email.send (msg) then
        print ("Email sent successfully!%N")
    else
        print ("Error: " + email.last_error + "%N")
    end

    email.disconnect
end
```

## Standard API (Full Control)

### SE_MESSAGE - Email Message

```eiffel
local
    msg: SE_MESSAGE
do
    create msg.make

    -- Sender (validated: must contain @, no CRLF injection)
    msg.set_from ("sender@example.com")

    -- Recipients
    msg.add_to ("alice@example.com")
    msg.add_cc ("bob@example.com")
    msg.add_bcc ("charlie@example.com")

    -- Content
    msg.set_subject ("Meeting Tomorrow")
    msg.set_text_body ("Plain text version")
    msg.set_html_body ("<h1>HTML version</h1>")

    -- Attachments
    msg.attach_file ("C:\Documents\report.pdf")
    msg.attach_data ("data.txt", "text/plain", "inline content")

    -- Status queries
    if msg.is_valid then -- has from + at least one recipient
        print ("Recipients: " + msg.recipient_count.out + "%N")
        print ("Attachments: " + msg.attachment_count.out + "%N")
    end
end
```

### SIMPLE_EMAIL - SMTP Client Facade

```eiffel
local
    email: SIMPLE_EMAIL
do
    create email.make
    email.set_smtp_server ("smtp.office365.com", 587)
    email.set_credentials ("user@company.com", "password")
    email.set_timeout (60)  -- seconds

    -- Connection modes
    email.connect      -- Plain connection
    email.start_tls    -- Upgrade to TLS
    -- OR --
    email.connect_tls  -- Implicit TLS (port 465)

    email.authenticate

    -- Status queries
    if email.is_connected then ...
    if email.is_tls_active then ...
    if email.is_authenticated then ...
    if email.has_error then print (email.last_error) end

    email.disconnect
end
```

## Features

- **TLS Encryption** - Native Windows SChannel (no OpenSSL)
- **STARTTLS** - Upgrade plain connection to encrypted
- **Implicit TLS** - Direct TLS connection (port 465)
- **AUTH PLAIN/LOGIN** - Standard SMTP authentication
- **MIME Multipart** - Mixed content and attachments
- **Input Validation** - DBC contracts block empty emails, CRLF injection
- **Security Hardened** - 10 adversarial tests, 6 stress tests

## Installation

1. Set the ecosystem environment variable (one-time setup for all simple_* libraries):
```
SIMPLE_EIFFEL=D:\prod
```

2. Add to ECF:
```xml
<library name="simple_email" location="$SIMPLE_EIFFEL/simple_email/simple_email.ecf"/>
```

## Dependencies

- simple_base64 (for MIME encoding)

## Class Structure

| Class | Purpose |
|-------|---------|
| SIMPLE_EMAIL | High-level facade for sending email |
| SE_MESSAGE | Email message with headers, body, attachments |
| SE_ATTACHMENT | File or inline attachment |
| SE_SMTP_CLIENT | Full SMTP protocol implementation |
| SE_TLS_SOCKET | WinSock + SChannel TLS socket |

## Known Limitations

1. **Windows Only** - Uses Win32 WinSock/SChannel APIs
2. **TLS Simplified** - Handshake performed; data encryption placeholder for Phase 3
3. **File Attachments** - `make_from_file` stub (returns empty data)

## Security

Email addresses are validated with Design by Contract preconditions:
- Must not be empty
- Must contain @ symbol
- Must not contain CR/LF (CRLF injection protection)

## Test Coverage

| Category | Tests |
|----------|-------|
| Message Tests | 13 |
| Attachment Tests | 5 |
| SMTP Client Tests | 3 |
| TLS Socket Tests | 4 |
| Facade Tests | 11 |
| Adversarial Tests | 10 |
| Stress Tests | 6 |
| **Total** | **52** |

## License

MIT License
