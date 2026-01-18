# INTERFACES: simple_email

## Date: 2026-01-18
## Status: Phase 1 Complete

---

## Public API (SIMPLE_EMAIL Facade)

### Queries (Read-Only)

| Feature | Return Type | Description |
|---------|-------------|-------------|
| smtp_host | STRING | Current SMTP server hostname |
| smtp_port | INTEGER | Current SMTP server port |
| last_error | detachable STRING | Error message if operation failed |
| is_connected | BOOLEAN | True if connected to server |
| is_authenticated | BOOLEAN | True if authenticated |
| is_tls_active | BOOLEAN | True if TLS encryption active |
| has_error | BOOLEAN | True if last operation had error |

### Commands (State-Modifying)

| Feature | Parameters | Description |
|---------|------------|-------------|
| set_smtp_server | (host: STRING; port: INTEGER) | Configure SMTP server |
| set_credentials | (username, password: STRING) | Set auth credentials |
| set_timeout | (seconds: INTEGER) | Set connection timeout |
| connect | () | Connect to SMTP server |
| disconnect | () | Close connection |
| send | (message: SE_MESSAGE): BOOLEAN | Send email, return success |
| create_message | (): SE_MESSAGE | Create new message object |

### Usage Example

```eiffel
local
    l_email: SIMPLE_EMAIL
    l_msg: SE_MESSAGE
do
    create l_email.make
    l_email.set_smtp_server ("smtp.gmail.com", 587)
    l_email.set_credentials ("user@gmail.com", "app_password")

    l_msg := l_email.create_message
    l_msg.set_from ("user@gmail.com")
    l_msg.add_to ("recipient@example.com")
    l_msg.set_subject ("Test Email")
    l_msg.set_text_body ("Hello from simple_email!")

    l_email.connect
    if l_email.is_connected and then l_email.send (l_msg) then
        print ("Email sent!%N")
    else
        print ("Error: " + l_email.last_error + "%N")
    end
    l_email.disconnect
end
```

---

## Message Composition (SE_MESSAGE)

### Queries

| Feature | Return Type | Description |
|---------|-------------|-------------|
| from_address | STRING | Sender email address |
| subject | STRING | Email subject line |
| text_body | STRING | Plain text content |
| html_body | STRING | HTML content |
| recipients | ARRAYED_LIST[STRING] | To recipients |
| cc_recipients | ARRAYED_LIST[STRING] | CC recipients |
| bcc_recipients | ARRAYED_LIST[STRING] | BCC recipients |
| attachments | ARRAYED_LIST[SE_ATTACHMENT] | Attached files |
| recipient_count | INTEGER | Total recipient count |
| attachment_count | INTEGER | Number of attachments |
| is_valid | BOOLEAN | True if message is sendable |
| has_from | BOOLEAN | True if From address set |
| has_recipients | BOOLEAN | True if any recipients set |
| has_body | BOOLEAN | True if any body content set |
| has_attachments | BOOLEAN | True if any attachments |

### Commands

| Feature | Parameters | Description |
|---------|------------|-------------|
| set_from | (address: STRING) | Set sender address |
| add_to | (address: STRING) | Add To recipient |
| add_cc | (address: STRING) | Add CC recipient |
| add_bcc | (address: STRING) | Add BCC recipient |
| clear_recipients | () | Remove all recipients |
| set_subject | (subject: STRING) | Set subject line |
| set_text_body | (text: STRING) | Set plain text body |
| set_html_body | (html: STRING) | Set HTML body |
| attach_file | (path: STRING) | Attach file from path |
| attach_data | (name, type, data: STRING) | Attach raw data |
| clear_attachments | () | Remove all attachments |

---

## Attachment Handling (SE_ATTACHMENT)

### Queries

| Feature | Return Type | Description |
|---------|-------------|-------------|
| name | STRING | Attachment filename |
| content_type | STRING | MIME content type |
| data | STRING | Raw attachment data |
| encoded_data | STRING | Base64 encoded data |
| size | INTEGER | Size in bytes |
| is_valid | BOOLEAN | True if attachment is valid |

### Creation

| Feature | Parameters | Description |
|---------|------------|-------------|
| make | (name, type, data: STRING) | Create from raw data |
| make_from_file | (path: STRING) | Create from file |

---

## Error Handling Pattern

All classes follow the same error pattern:

```eiffel
-- Query to check for error
has_error: BOOLEAN
    do
        Result := last_error /= Void
    end

-- Query to get error details
last_error: detachable STRING

-- After any operation:
if my_object.has_error then
    print ("Error: " + my_object.last_error + "%N")
end
```

---

## Thread Safety (SCOOP)

All public features are SCOOP-safe:

1. **No shared mutable state** between objects
2. **All features are re-entrant** (no static/global variables)
3. **Detachable types** used where Void is possible
4. **Command-Query separation** strictly enforced

For concurrent usage:

```eiffel
local
    l_email: separate SIMPLE_EMAIL
do
    create l_email.make
    send_async (l_email)
end

send_async (a_email: separate SIMPLE_EMAIL)
    do
        a_email.set_smtp_server ("smtp.example.com", 587)
        -- ... rest of operations
    end
```

---

## Feature Categories Summary

| Category | Purpose | Features |
|----------|---------|----------|
| Access (Queries) | Return data | Attributes, calculated values |
| Status (Boolean Queries) | Return state | is_*, has_* features |
| Measurement (Integer Queries) | Return counts | *_count features |
| Settings (Commands) | Configure | set_* features |
| Connection (Commands) | Manage connection | connect, disconnect |
| Recipients (Commands) | Manage recipients | add_*, clear_* |
| Content (Commands) | Set content | set_*_body |
| Attachments (Commands) | Manage files | attach_*, clear_* |

---

**INTERFACES: COMPLETE**
