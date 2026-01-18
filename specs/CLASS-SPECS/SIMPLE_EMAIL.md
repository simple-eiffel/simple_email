# Class Specification: SIMPLE_EMAIL

## Overview

| Property | Value |
|----------|-------|
| Type | Facade |
| Purpose | Library entry point for email operations |
| File | src/simple_email.e |

---

## Signature

```eiffel
class SIMPLE_EMAIL create make
```

---

## Feature Groups

### Initialization

| Feature | Type | Description |
|---------|------|-------------|
| make | creation | Create email client with defaults |

### Access (Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| smtp_host | STRING | SMTP server hostname |
| smtp_port | INTEGER | SMTP server port |
| last_error | detachable STRING | Error message if failed |

### Status (Boolean Queries)

| Feature | Return | Description |
|---------|--------|-------------|
| is_connected | BOOLEAN | True if connected |
| is_authenticated | BOOLEAN | True if authenticated |
| is_tls_active | BOOLEAN | True if TLS active |
| has_error | BOOLEAN | True if last operation failed |

### Settings (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| set_smtp_server | host: STRING, port: INTEGER | Configure server |
| set_credentials | username, password: STRING | Set auth credentials |
| set_timeout | seconds: INTEGER | Set timeout |

### Connection (Commands)

| Feature | Parameters | Description |
|---------|------------|-------------|
| connect | - | Connect to SMTP server |
| disconnect | - | Close connection |

### Email Operations

| Feature | Parameters | Return | Description |
|---------|------------|--------|-------------|
| send | message: SE_MESSAGE | BOOLEAN | Send email |
| create_message | - | SE_MESSAGE | Factory for messages |

---

## Contracts

### Preconditions

```eiffel
set_smtp_server require
    host_not_empty: not a_host.is_empty
    port_positive: a_port > 0

connect require
    server_configured: not smtp_host.is_empty
    not_connected: not is_connected

send require
    connected: is_connected
    message_valid: a_message.is_valid
```

### Postconditions

```eiffel
set_smtp_server ensure
    host_set: smtp_host.same_string (a_host)
    port_set: smtp_port = a_port

disconnect ensure
    not_connected: not is_connected
    no_error: not has_error
```

### Invariants

```eiffel
invariant
    host_exists: smtp_host /= Void
    port_positive: smtp_port > 0
    timeout_positive: timeout > 0
    auth_requires_connection: is_authenticated implies is_connected
    tls_requires_connection: is_tls_active implies is_connected
```

---

## Usage Example

```eiffel
local
    email: SIMPLE_EMAIL
    msg: SE_MESSAGE
do
    create email.make
    email.set_smtp_server ("smtp.gmail.com", 587)
    email.set_credentials ("user", "password")

    msg := email.create_message
    msg.set_from ("user@gmail.com")
    msg.add_to ("recipient@example.com")
    msg.set_subject ("Hello")
    msg.set_text_body ("Hello World!")

    email.connect
    if email.send (msg) then
        print ("Sent!%N")
    end
    email.disconnect
end
```
