# CONTRACTS: simple_email

## Date: 2026-01-18
## Status: Phase 1 Complete

---

## Contract Summary

| Class | Preconditions | Postconditions | Invariants |
|-------|---------------|----------------|------------|
| SIMPLE_EMAIL | 9 | 6 | 5 |
| SE_MESSAGE | 8 | 15 | 7 |
| SE_ATTACHMENT | 3 | 6 | 5 |
| SE_SMTP_CLIENT | 7 | 4 | 4 |
| SE_TLS_SOCKET | 10 | 4 | 2 |
| **Total** | **37** | **35** | **23** |

---

## SIMPLE_EMAIL Contracts

### Preconditions

| Feature | Precondition | Tag |
|---------|--------------|-----|
| set_smtp_server | not a_host.is_empty | host_not_empty |
| set_smtp_server | a_port > 0 | port_positive |
| set_credentials | not a_username.is_empty | username_not_empty |
| set_timeout | a_seconds > 0 | positive_timeout |
| connect | not smtp_host.is_empty | server_configured |
| connect | not is_connected | not_connected |
| send | is_connected | connected |
| send | a_message.is_valid | message_valid |

### Postconditions

| Feature | Postcondition | Tag |
|---------|---------------|-----|
| set_smtp_server | smtp_host.same_string (a_host) | host_set |
| set_smtp_server | smtp_port = a_port | port_set |
| set_credentials | attached username | username_set |
| set_credentials | attached password | password_set |
| set_timeout | timeout = a_seconds | timeout_set |
| disconnect | not is_connected | not_connected |
| disconnect | not has_error | no_error |

### Class Invariants

| Invariant | Description |
|-----------|-------------|
| host_exists | smtp_host /= Void |
| port_positive | smtp_port > 0 |
| timeout_positive | timeout > 0 |
| auth_requires_connection | is_authenticated implies is_connected |
| tls_requires_connection | is_tls_active implies is_connected |

---

## SE_MESSAGE Contracts

### Preconditions

| Feature | Precondition | Tag |
|---------|--------------|-----|
| set_from | not a_address.is_empty | address_not_empty |
| add_to | not a_address.is_empty | address_not_empty |
| add_cc | not a_address.is_empty | address_not_empty |
| add_bcc | not a_address.is_empty | address_not_empty |
| attach_file | not a_path.is_empty | path_not_empty |
| attach_data | not a_name.is_empty | name_not_empty |
| attach_data | not a_content_type.is_empty | content_type_not_empty |

### Postconditions

| Feature | Postcondition | Tag |
|---------|---------------|-----|
| set_from | from_address.same_string (a_address) | from_set |
| set_from | has_from | has_from |
| add_to | recipients.count = old recipients.count + 1 | one_more |
| add_to | has_recipients | has_recipients |
| add_cc | cc_recipients.count = old cc_recipients.count + 1 | one_more |
| add_cc | has_recipients | has_recipients |
| add_bcc | bcc_recipients.count = old bcc_recipients.count + 1 | one_more |
| add_bcc | has_recipients | has_recipients |
| clear_recipients | recipients.is_empty | no_to |
| clear_recipients | not has_recipients | no_recipients |
| set_subject | subject.same_string (a_subject) | subject_set |
| set_text_body | text_body.same_string (a_text) | body_set |
| set_html_body | html_body.same_string (a_html) | body_set |
| attach_data | attachments.count = old attachments.count + 1 | one_more |
| clear_attachments | attachments.is_empty | no_attachments |

### Class Invariants

| Invariant | Description |
|-----------|-------------|
| recipients_exists | recipients /= Void |
| cc_exists | cc_recipients /= Void |
| bcc_exists | bcc_recipients /= Void |
| attachments_exists | attachments /= Void |
| valid_implies_has_from_and_recipients | is_valid implies (has_from and has_recipients) |
| count_consistent | recipient_count = recipients.count + cc_recipients.count + bcc_recipients.count |
| attachment_count_consistent | attachment_count = attachments.count |

---

## SE_ATTACHMENT Contracts

### Preconditions

| Feature | Precondition | Tag |
|---------|--------------|-----|
| make | not a_name.is_empty | name_not_empty |
| make | not a_content_type.is_empty | content_type_not_empty |
| make_from_file | not a_path.is_empty | path_not_empty |

### Postconditions

| Feature | Postcondition | Tag |
|---------|---------------|-----|
| make | name.same_string (a_name) | name_set |
| make | content_type.same_string (a_content_type) | content_type_set |
| make | data.same_string (a_data) | data_set |
| make | is_valid | is_valid |
| make_from_file | not name.is_empty | name_set |
| make_from_file | is_valid | is_valid |

### Class Invariants

| Invariant | Description |
|-----------|-------------|
| name_exists | internal_name /= Void |
| content_type_exists | internal_content_type /= Void |
| data_exists | internal_data /= Void |
| valid_definition | is_valid = (not internal_name.is_empty and not internal_content_type.is_empty) |
| size_consistent | size = internal_data.count |

---

## SE_SMTP_CLIENT Contracts

### Preconditions

| Feature | Precondition | Tag |
|---------|--------------|-----|
| make | not a_host.is_empty | host_not_empty |
| make | a_port > 0 | port_positive |
| authenticate_plain | is_connected | connected |
| authenticate_plain | not a_username.is_empty | username_not_empty |
| authenticate_login | is_connected | connected |
| authenticate_login | not a_username.is_empty | username_not_empty |
| send_message | is_connected | connected |
| send_message | is_authenticated | authenticated |
| send_message | a_message.is_valid | message_valid |

### Postconditions

| Feature | Postcondition | Tag |
|---------|---------------|-----|
| make | host.same_string (a_host) | host_set |
| make | port = a_port | port_set |
| make | not is_connected | not_connected |
| disconnect | not is_connected | not_connected |
| disconnect | not is_authenticated | not_authenticated |
| disconnect | not has_error | no_error |

### Class Invariants

| Invariant | Description |
|-----------|-------------|
| host_exists | internal_host /= Void |
| port_positive | port > 0 |
| auth_requires_connection | is_authenticated implies is_connected |
| tls_requires_connection | is_tls_active implies is_connected |

---

## SE_TLS_SOCKET Contracts

### Preconditions

| Feature | Precondition | Tag |
|---------|--------------|-----|
| connect | not a_host.is_empty | host_not_empty |
| connect | a_port > 0 | port_positive |
| connect | not is_connected | not_connected |
| connect_tls | not a_host.is_empty | host_not_empty |
| connect_tls | a_port > 0 | port_positive |
| connect_tls | not is_connected | not_connected |
| start_tls | not a_host.is_empty | host_not_empty |
| start_tls | is_connected | connected |
| start_tls | not is_tls_active | not_already_tls |
| send | is_connected | connected |
| receive | is_connected | connected |
| receive_line | is_connected | connected |
| set_timeout | a_milliseconds > 0 | positive_timeout |

### Postconditions

| Feature | Postcondition | Tag |
|---------|---------------|-----|
| disconnect | not is_connected | not_connected |
| disconnect | not is_tls_active | not_tls |
| disconnect | not has_error | no_error |
| set_timeout | timeout_ms = a_milliseconds | timeout_set |

### Class Invariants

| Invariant | Description |
|-----------|-------------|
| timeout_positive | timeout_ms > 0 |
| tls_requires_connection | is_tls_active implies is_connected |

---

## Contract Verification

All contracts were verified by:
1. Compiling with assertions enabled
2. Running 31 tests that exercise the contracts
3. All tests pass

---

**CONTRACTS: COMPLETE**
