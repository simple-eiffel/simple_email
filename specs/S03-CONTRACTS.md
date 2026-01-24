# S03: CONTRACTS - simple_email

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## SIMPLE_EMAIL Contracts

### Invariants
```eiffel
invariant
    host_exists: smtp_host /= Void
    port_positive: smtp_port > 0
    timeout_positive: timeout > 0
    auth_requires_connection: is_authenticated implies is_connected
    tls_requires_connection: is_tls_active implies is_connected
```

### Feature Contracts

#### set_smtp_server
```eiffel
require
    host_not_empty: not a_host.is_empty
    port_positive: a_port > 0
ensure
    host_set: smtp_host.same_string (a_host)
    port_set: smtp_port = a_port
```

#### connect
```eiffel
require
    server_configured: not smtp_host.is_empty
    not_connected: not is_connected
ensure
    connected_or_error: is_connected or has_error
    port_unchanged: smtp_port = old smtp_port
    host_unchanged: smtp_host.same_string (old smtp_host.twin)
```

#### send
```eiffel
require
    connected: is_connected
    authenticated: is_authenticated
    message_valid: a_message.is_valid
ensure
    error_on_failure: not Result implies has_error
```

---

## SE_MESSAGE Contracts

### Invariants
```eiffel
invariant
    recipients_exists: recipients /= Void
    cc_exists: cc_recipients /= Void
    bcc_exists: bcc_recipients /= Void
    attachments_exists: attachments /= Void
    valid_implies_has_from_and_recipients: is_valid implies (has_from and has_recipients)
    count_consistent: recipient_count = recipients.count + cc_recipients.count + bcc_recipients.count
    attachment_count_consistent: attachment_count = attachments.count
```

### Feature Contracts

#### set_from
```eiffel
require
    address_not_empty: not a_address.is_empty
    address_has_at: a_address.has ('@')
    address_no_newlines: not a_address.has ('%R') and not a_address.has ('%N')
ensure
    from_set: from_address.same_string (a_address)
    has_from: has_from
    recipients_unchanged: recipients.count = old recipients.count
```

#### add_to
```eiffel
require
    address_not_empty: not a_address.is_empty
    address_has_at: a_address.has ('@')
    address_no_newlines: not a_address.has ('%R') and not a_address.has ('%N')
ensure
    one_more: recipients.count = old recipients.count + 1
    has_recipients: has_recipients
    from_unchanged: from_address.same_string (old from_address.twin)
```

---

## SE_SMTP_CLIENT Contracts

### Invariants
```eiffel
invariant
    host_exists: internal_host /= Void
    port_positive: port > 0
    auth_requires_connection: is_authenticated implies is_connected
    tls_requires_connection: is_tls_active implies is_connected
```

### Feature Contracts

#### send_message
```eiffel
require
    connected: is_connected
    authenticated: is_authenticated
    message_valid: a_message.is_valid
```

#### authenticate_plain
```eiffel
require
    connected: is_connected
    username_not_empty: not a_username.is_empty
```

---

## SE_TLS_SOCKET Contracts

### Invariants
```eiffel
invariant
    timeout_positive: timeout_ms > 0
    tls_requires_connection: is_tls_active implies is_connected
```

### Feature Contracts

#### connect
```eiffel
require
    host_not_empty: not a_host.is_empty
    port_positive: a_port > 0
    not_connected: not is_connected
```

#### start_tls
```eiffel
require
    host_not_empty: not a_host.is_empty
    connected: is_connected
    not_already_tls: not is_tls_active
```

#### disconnect
```eiffel
ensure
    not_connected: not is_connected
    not_tls: not is_tls_active
    no_error: not has_error
```
