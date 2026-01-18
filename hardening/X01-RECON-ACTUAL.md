# X01: Reconnaissance - simple_email

## Date: 2026-01-18

## Baseline Verification

### Compilation
```
Eiffel Compilation Manager
Version 25.02.9.8732 - win64

Degree 6: Examining System
System Recompiled.
```

### Test Run
```
simple_email test runner
=============================
Results: 36 passed, 0 failed
ALL TESTS PASSED
```

### Baseline Status
- Compiles: YES
- Tests: 36 pass, 0 fail
- Warnings: 0

## Source Files

| File | Class | Lines | Features | Contracts |
|------|-------|-------|----------|-----------|
| se_attachment.e | SE_ATTACHMENT | 109 | 8 public | 4 pre, 7 post, 4 inv |
| se_message.e | SE_MESSAGE | 264 | 25 public | 8 pre, 15 post, 7 inv |
| se_smtp_client.e | SE_SMTP_CLIENT | 513 | 30 public | 10 pre, 5 post, 4 inv |
| se_tls_socket.e | SE_TLS_SOCKET | 531 | 20 public | 10 pre, 5 post, 2 inv |
| simple_email.e | SIMPLE_EMAIL | 243 | 20 public | 8 pre, 5 post, 5 inv |

## Public API Analysis

### SIMPLE_EMAIL (Facade)

| Feature | Type | Params | Pre | Post | Risk |
|---------|------|--------|-----|------|------|
| make | creation | - | 0 | 0 | L |
| set_smtp_server | command | host: STRING, port: INTEGER | 2 | 2 | M |
| set_credentials | command | username, password: STRING | 1 | 2 | M |
| set_timeout | command | seconds: INTEGER | 1 | 1 | L |
| connect | command | - | 2 | 0 | H |
| connect_tls | command | - | 2 | 0 | H |
| start_tls | command | - | 2 | 0 | H |
| authenticate | command | - | 2 | 0 | H |
| disconnect | command | - | 0 | 2 | L |
| send | command | message: SE_MESSAGE | 3 | 1 | H |
| create_message | query | - | 0 | 0 | L |
| is_connected | query | - | 0 | 0 | L |
| is_authenticated | query | - | 0 | 0 | L |
| is_tls_active | query | - | 0 | 0 | L |
| has_error | query | - | 0 | 0 | L |
| has_credentials | query | - | 0 | 0 | L |

### SE_MESSAGE

| Feature | Type | Params | Pre | Post | Risk |
|---------|------|--------|-----|------|------|
| make | creation | - | 0 | 0 | L |
| set_from | command | address: STRING | 1 | 2 | M |
| add_to | command | address: STRING | 1 | 2 | M |
| add_cc | command | address: STRING | 1 | 2 | M |
| add_bcc | command | address: STRING | 1 | 2 | M |
| set_subject | command | subject: STRING | 0 | 1 | M |
| set_text_body | command | text: STRING | 0 | 2 | M |
| set_html_body | command | html: STRING | 0 | 2 | M |
| attach_file | command | path: STRING | 1 | 2 | H |
| attach_data | command | name, type, data: STRING | 2 | 2 | M |
| clear_recipients | command | - | 0 | 4 | L |
| clear_attachments | command | - | 0 | 2 | L |

### SE_SMTP_CLIENT

| Feature | Type | Params | Pre | Post | Risk |
|---------|------|--------|-----|------|------|
| make | creation | host: STRING, port: INTEGER | 2 | 3 | M |
| connect | command | - | 0 | 0 | H |
| connect_tls | command | - | 0 | 0 | H |
| start_tls | command | - | 0 | 0 | H |
| send_ehlo | command | - | 0 | 0 | H |
| disconnect | command | - | 0 | 3 | L |
| authenticate_plain | command | username, password: STRING | 2 | 0 | H |
| authenticate_login | command | username, password: STRING | 2 | 0 | H |
| send_message | command | message: SE_MESSAGE | 3 | 0 | H |

### SE_TLS_SOCKET

| Feature | Type | Params | Pre | Post | Risk |
|---------|------|--------|-----|------|------|
| make | creation | - | 0 | 0 | L |
| connect | command | host: STRING, port: INTEGER | 3 | 0 | H |
| connect_tls | command | host: STRING, port: INTEGER | 3 | 0 | H |
| start_tls | command | host: STRING | 3 | 0 | H |
| disconnect | command | - | 0 | 3 | L |
| send | command | data: STRING | 1 | 0 | H |
| receive | query | - | 1 | 0 | H |
| receive_line | query | - | 1 | 0 | H |
| set_timeout | command | milliseconds: INTEGER | 1 | 1 | L |

## Contract Coverage Summary

| Metric | Count | Percentage |
|--------|-------|------------|
| Total features | 103 | 100% |
| With preconditions | 40 | 39% |
| With postconditions | 37 | 36% |
| Classes with invariants | 5/5 | 100% |

## Attack Surface Priority

### High (Network/Security Operations - Missing Postconditions)
1. `SE_TLS_SOCKET.connect` - No postcondition on success
2. `SE_TLS_SOCKET.start_tls` - No postcondition on success
3. `SE_TLS_SOCKET.send` - No postcondition (bytes sent not verified)
4. `SE_SMTP_CLIENT.connect` - No postcondition on success
5. `SE_SMTP_CLIENT.authenticate_plain` - No postcondition on success
6. `SE_SMTP_CLIENT.send_message` - No postcondition on success
7. `SIMPLE_EMAIL.connect` - No postcondition on success
8. `SIMPLE_EMAIL.authenticate` - No postcondition on success
9. `SIMPLE_EMAIL.send` - Postcondition only checks error_on_failure

### Medium (Input Validation)
1. `SE_MESSAGE.set_subject` - No precondition (accepts any string)
2. `SE_MESSAGE.set_text_body` - No precondition (accepts any string)
3. `SE_MESSAGE.set_html_body` - No precondition (accepts any string)
4. `SE_ATTACHMENT.make_from_file` - File existence not verified

### Low (Protected)
1. `SE_MESSAGE.make` - Well-protected with initialization
2. `SE_ATTACHMENT.make` - Full contracts
3. `SIMPLE_EMAIL.disconnect` - Good postconditions

## Inline C External Analysis

### SE_TLS_SOCKET - C Externals (HIGH RISK)
| External | Risk | Issue |
|----------|------|-------|
| c_connect | HIGH | Network operation, error handling in C |
| c_start_tls | HIGH | TLS handshake, security critical |
| c_send_plain | HIGH | Data transmission |
| c_receive_plain | HIGH | Data reception |
| c_send_tls | HIGH | Encrypted send (simplified impl) |
| c_receive_tls | HIGH | Encrypted receive (simplified impl) |

Note: TLS send/receive are simplified - they bypass actual encryption after handshake.

## VERIFICATION CHECKPOINT

```
Compilation output: YES (System Recompiled)
Test output: 36 passed, 0 failed
Source files read: 5
Attack surfaces listed: 18 high-risk
hardening/X01-RECON-ACTUAL.md: CREATED
```

## Next Step

-> X02-VULNERABILITY-SCAN.md
