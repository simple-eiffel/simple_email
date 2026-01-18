# Class Specification: SE_TLS_SOCKET

## Overview

| Property | Value |
|----------|-------|
| Type | Transport |
| Purpose | TLS-encrypted socket communication |
| File | src/se_tls_socket.e |

---

## Signature

```eiffel
class SE_TLS_SOCKET create make
```

---

## Feature Groups

### Initialization

| Feature | Parameters | Description |
|---------|------------|-------------|
| make | - | Create socket with default timeout |

### Access (Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| last_error | detachable STRING | Error message |

### Status (Boolean Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| is_connected | BOOLEAN | True if connected |
| is_tls_active | BOOLEAN | True if TLS active |
| has_error | BOOLEAN | True if error |

### Connection (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| connect | host: STRING, port: INTEGER | Plain TCP connect |
| connect_tls | host: STRING, port: INTEGER | Implicit TLS connect |
| start_tls | host: STRING | Upgrade to TLS |
| disconnect | - | Close connection |

### I/O (Commands)

| Feature | Parameters | Return | Description |
|---------|------------|--------|-------------|
| send | data: STRING | - | Send data |
| receive | - | STRING | Receive data |
| receive_line | - | STRING | Receive until CRLF |

### Settings (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| set_timeout | milliseconds: INTEGER | Set timeout |

---

## Contracts Summary

- **10 preconditions**: Host/port validation, state checks
- **4 postconditions**: State verification
- **2 invariants**: Timeout and TLS consistency

---

## Implementation Notes

- Uses Win32 WinSock2 for TCP
- Uses Win32 SChannel for TLS
- All external calls via inline C
- Default timeout: 30000ms
