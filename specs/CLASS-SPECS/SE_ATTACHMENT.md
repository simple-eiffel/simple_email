# Class Specification: SE_ATTACHMENT

## Overview

| Property | Value |
|----------|-------|
| Type | Value Object |
| Purpose | File attachment handling |
| File | src/se_attachment.e |

---

## Signature

```eiffel
class SE_ATTACHMENT create make, make_from_file
```

---

## Feature Groups

### Initialization

| Feature | Parameters | Description |
|---------|------------|-------------|
| make | name, content_type, data: STRING | Create from raw data |
| make_from_file | path: STRING | Create from file path |

### Access (Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| name | STRING | Filename |
| content_type | STRING | MIME type |
| data | STRING | Raw data |
| encoded_data | STRING | Base64 encoded |

### Status (Boolean Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| is_valid | BOOLEAN | True if valid |

### Measurement (Integer Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| size | INTEGER | Size in bytes |

---

## Contracts Summary

- **3 preconditions**: Name/path validation
- **6 postconditions**: Property verification
- **5 invariants**: Data consistency

---

## Usage Example

```eiffel
local
    att: SE_ATTACHMENT
do
    -- From raw data
    create att.make ("report.txt", "text/plain", "Report content")
    check att.is_valid end
    check att.size = 14 end

    -- From file
    create att.make_from_file ("C:\docs\report.pdf")
    check att.is_valid end
end
```
