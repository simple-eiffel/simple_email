# Class Specification: SE_MESSAGE

## Overview

| Property | Value |
|----------|-------|
| Type | Value Object |
| Purpose | Email message composition |
| File | src/se_message.e |

---

## Signature

```eiffel
class SE_MESSAGE create make
```

---

## Feature Groups

### Initialization

| Feature | Type | Description |
|---------|------|-------------|
| make | creation | Create empty message |

### Access (Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| from_address | STRING | Sender address |
| subject | STRING | Subject line |
| text_body | STRING | Plain text content |
| html_body | STRING | HTML content |
| recipients | ARRAYED_LIST[STRING] | To recipients |
| cc_recipients | ARRAYED_LIST[STRING] | CC recipients |
| bcc_recipients | ARRAYED_LIST[STRING] | BCC recipients |
| attachments | ARRAYED_LIST[SE_ATTACHMENT] | Attachments |

### Status (Boolean Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| is_valid | BOOLEAN | True if sendable |
| has_from | BOOLEAN | True if From set |
| has_recipients | BOOLEAN | True if any recipients |
| has_body | BOOLEAN | True if body set |
| has_attachments | BOOLEAN | True if attachments |

### Measurement (Integer Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| recipient_count | INTEGER | Total recipients |
| attachment_count | INTEGER | Number of attachments |

### Sender (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| set_from | address: STRING | Set sender |

### Recipients (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| add_to | address: STRING | Add To recipient |
| add_cc | address: STRING | Add CC recipient |
| add_bcc | address: STRING | Add BCC recipient |
| clear_recipients | - | Remove all recipients |

### Content (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| set_subject | subject: STRING | Set subject |
| set_text_body | text: STRING | Set text body |
| set_html_body | html: STRING | Set HTML body |

### Attachments (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| attach_file | path: STRING | Attach from file |
| attach_data | name, type, data: STRING | Attach raw data |
| clear_attachments | - | Remove attachments |

---

## Contracts Summary

- **8 preconditions**: Address/path validation
- **15 postconditions**: State verification
- **7 invariants**: Collection and count consistency

---

## Usage Example

```eiffel
local
    msg: SE_MESSAGE
do
    create msg.make
    msg.set_from ("sender@example.com")
    msg.add_to ("recipient@example.com")
    msg.add_cc ("copy@example.com")
    msg.set_subject ("Test Email")
    msg.set_text_body ("Hello!")
    msg.set_html_body ("<p>Hello!</p>")
    msg.attach_data ("file.txt", "text/plain", "content")

    check msg.is_valid end
end
```
