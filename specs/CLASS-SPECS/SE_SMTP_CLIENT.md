# Class Specification: SE_SMTP_CLIENT

## Overview

| Property | Value |
|----------|-------|
| Type | Service |
| Purpose | SMTP protocol implementation |
| File | src/se_smtp_client.e |

---

## Signature

```eiffel
class SE_SMTP_CLIENT create make
```

---

## Feature Groups

### Initialization

| Feature | Parameters | Description |
|---------|------------|-------------|
| make | host: STRING, port: INTEGER | Create client |

### Access (Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| host | STRING | Server hostname |
| port | INTEGER | Server port |
| last_response | detachable STRING | Server response |
| last_error | detachable STRING | Error message |

### Status (Boolean Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| is_connected | BOOLEAN | True if connected |
| is_tls_active | BOOLEAN | True if TLS active |
| is_authenticated | BOOLEAN | True if authenticated |
| has_error | BOOLEAN | True if error |

### Connection (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| connect | - | Plain TCP connect |
| connect_tls | - | Implicit TLS connect |
| start_tls | - | Upgrade to TLS |
| disconnect | - | Close connection |

### Authentication (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| authenticate_plain | username, password: STRING | AUTH PLAIN |
| authenticate_login | username, password: STRING | AUTH LOGIN |

### Sending (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| send_message | message: SE_MESSAGE | Send email |

---

## Contracts Summary

- **7 preconditions**: Host/port validation, state checks
- **4 postconditions**: State verification
- **4 invariants**: State consistency

---

## State Machine

```
DISCONNECTED → connect() → CONNECTED → start_tls() → TLS_ACTIVE
    ↑                                       ↓
    └────────── disconnect() ←── authenticate() ←─── AUTHENTICATED
```
