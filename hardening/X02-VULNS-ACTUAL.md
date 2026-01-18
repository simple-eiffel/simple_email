# VULNERABILITY SCAN REPORT: simple_email

## Date: 2026-01-18

## Scan Summary
- Total vulnerabilities: 24
- Critical: 2
- High: 8
- Medium: 10
- Low: 4

---

## Critical Findings

### CRIT-01: Socket Handle Leak on Connection Failure
**Location**: SE_TLS_SOCKET.connect (line 60-68)
**Pattern**: Resource not released on error path
**Trigger**: Connect to non-existent host, socket handle allocated but not closed on getaddrinfo failure
**Severity**: CRITICAL
**Code**:
```eiffel
l_result := c_connect (l_host_c.item, a_port, timeout_ms, $socket_handle)
if l_result /= 0 then
    last_error := "Connection failed: " + winsock_error_message (l_result)
    socket_handle := invalid_socket  -- But socket may have been created before getaddrinfo failed
```

### CRIT-02: TLS Context Memory Leak
**Location**: SE_TLS_SOCKET.start_tls (line 95-101)
**Pattern**: Credentials handle not released on handshake failure
**Trigger**: TLS handshake failure leaves AcquireCredentialsHandle resources unfreed
**Severity**: CRITICAL
**Code Analysis**: c_start_tls calls AcquireCredentialsHandle but if InitializeSecurityContext fails after that, the credentials are not always freed in all error paths.

---

## High Findings

### HIGH-01: Email Address Injection
**Location**: SE_SMTP_CLIENT.send_message (line 235, 246)
**Pattern**: String concatenation with user input
**Trigger**: Set from_address to `attacker@test.com>\r\nRCPT TO:<victim@test.com`
**Risk**: SMTP command injection via email headers
**Code**:
```eiffel
send_command ("MAIL FROM:<" + a_message.from_address + ">")
```

### HIGH-02: No Email Address Validation
**Location**: SE_MESSAGE.set_from, add_to, add_cc, add_bcc
**Pattern**: Input accepted without validation
**Trigger**: Set from to any string including malformed addresses
**Risk**: Invalid email addresses silently accepted, SMTP rejection at runtime

### HIGH-03: Missing Connection State Check in send_line
**Location**: SE_SMTP_CLIENT.send_line (line 419-433)
**Pattern**: No precondition on send_line
**Trigger**: Call send_line when socket is detached
**Risk**: Void-safety violation possible (mitigated by `attached socket as l_socket`)

### HIGH-04: Partial Send Not Detected
**Location**: SE_TLS_SOCKET.send (line 124-142)
**Pattern**: Send result not fully validated
**Trigger**: Send large data, socket closes mid-transmission
**Risk**: Partial data sent, caller not aware

### HIGH-05: Receive Buffer Overflow (Theoretical)
**Location**: SE_TLS_SOCKET.receive (line 153-167)
**Pattern**: Fixed 4096 byte buffer
**Trigger**: Server sends response larger than 4096 bytes
**Risk**: Data truncation, message corruption

### HIGH-06: No TLS Certificate Validation Options
**Location**: SE_TLS_SOCKET.c_start_tls
**Pattern**: Hardcoded TLS options
**Trigger**: Cannot disable certificate validation for testing
**Risk**: Testing environments may fail

### HIGH-07: response_ok Uses Substring Without Length Check
**Location**: SE_SMTP_CLIENT.response_ok (line 469-476)
**Pattern**: Boundary assumption
**Trigger**: Server returns empty or 1-2 character response
**Risk**: Although `lr.count >= 3` is checked, substring operations may still fail on edge cases

### HIGH-08: Simplified TLS Send/Receive
**Location**: SE_TLS_SOCKET.c_send_tls, c_receive_tls (lines 508-525)
**Pattern**: TLS encryption bypassed
**Trigger**: After TLS handshake, data sent in plain text
**Risk**: SECURITY VULNERABILITY - data not actually encrypted!
**Code**:
```c
// Simplified: For proper implementation would need to encrypt with EncryptMessage
// For now, send plain (TLS handshake established connection security)
return send((SOCKET)$a_socket, (char*)$a_data, $a_len, 0);
```

---

## Medium Findings

### MED-01: No Subject Length Limit
**Location**: SE_MESSAGE.set_subject
**Pattern**: Unbounded input
**Trigger**: Set subject to 10MB string
**Risk**: Memory exhaustion, SMTP rejection

### MED-02: No Body Size Limit
**Location**: SE_MESSAGE.set_text_body, set_html_body
**Pattern**: Unbounded input
**Trigger**: Set body to 100MB string
**Risk**: Memory exhaustion

### MED-03: Attachment Size Not Limited
**Location**: SE_MESSAGE.attach_data
**Pattern**: Unbounded input
**Trigger**: Attach 1GB of data
**Risk**: Memory exhaustion

### MED-04: make_from_file Doesn't Read File
**Location**: SE_ATTACHMENT.make_from_file (line 32-46)
**Pattern**: Incomplete implementation
**Trigger**: Create attachment from file, file not actually read
**Risk**: Empty attachment sent
**Code**:
```eiffel
internal_data := ""
-- Actual file reading would happen here
```

### MED-05: Boundary Generation Not Cryptographically Random
**Location**: SE_SMTP_CLIENT.generate_boundary (line 396-404)
**Pattern**: Predictable boundary
**Trigger**: Send multipart message
**Risk**: MIME boundary collision if message body contains boundary string

### MED-06: No Timeout on receive_line Loop
**Location**: SE_TLS_SOCKET.receive_line (line 169-193)
**Pattern**: Potential infinite loop
**Trigger**: Server sends data without CRLF terminator
**Risk**: Application hangs forever

### MED-07: SMTP Client State Machine Gaps
**Location**: SE_SMTP_CLIENT
**Pattern**: No state tracking
**Trigger**: Call send_message without connect/ehlo/auth
**Risk**: Preconditions prevent this but underlying socket may be in wrong state

### MED-08: No Response Code Parsing Robustness
**Location**: SE_SMTP_CLIENT.response_code (line 478-484)
**Pattern**: Assumes valid response format
**Trigger**: Malformed server response
**Risk**: Incorrect response code extracted

### MED-09: WinSock Initialization Race
**Location**: SE_TLS_SOCKET.ensure_winsock_initialized (line 279-287)
**Pattern**: Non-atomic check-then-act
**Trigger**: Two threads call ensure_winsock_initialized simultaneously
**Risk**: Double WSAStartup or missed initialization

### MED-10: No SMTP QUIT Response Check
**Location**: SE_SMTP_CLIENT.disconnect (line 147-162)
**Pattern**: Error ignored
**Trigger**: Server rejects QUIT
**Risk**: Minor - disconnect continues anyway

---

## Low Findings

### LOW-01: local_hostname Hardcoded
**Location**: SE_SMTP_CLIENT.local_hostname (line 486-491)
**Pattern**: Hardcoded value
**Trigger**: Any EHLO command
**Risk**: Minor - returns "localhost" always

### LOW-02: Error Message Leaks Connection Details
**Location**: SE_TLS_SOCKET.winsock_error_message
**Pattern**: Information disclosure
**Trigger**: Connection error
**Risk**: Error messages might help attackers

### LOW-03: No Connection Timeout Validation
**Location**: SIMPLE_EMAIL.set_timeout
**Pattern**: Accepts any positive value
**Trigger**: Set timeout to 1 millisecond or 24 hours
**Risk**: Either too short to work or DoS potential

### LOW-04: base64_encode Creates New Encoder Each Time
**Location**: SE_SMTP_CLIENT.base64_encode (line 493-500)
**Pattern**: Inefficiency
**Trigger**: Send message with many attachments
**Risk**: Minor memory churn

---

## Contract Gaps

### GAP-01: SE_MESSAGE.set_subject
- Should have precondition: subject.count <= 998 (RFC 5322 limit)
- Should have postcondition: subject_set implies from_address remains unchanged

### GAP-02: SE_MESSAGE.set_text_body, set_html_body
- Should have precondition: body size limit
- Risk: Memory exhaustion

### GAP-03: SE_SMTP_CLIENT.connect
- Should have postcondition: is_connected or has_error
- Current: No postcondition

### GAP-04: SE_SMTP_CLIENT.authenticate_plain/login
- Should have postcondition: is_authenticated or has_error
- Current: No postcondition

### GAP-05: SE_TLS_SOCKET.send
- Should have postcondition: bytes_sent >= 0 or has_error
- Current: No postcondition

### GAP-06: SIMPLE_EMAIL.send
- Should have postcondition: Result = not has_error
- Current: Only error_on_failure postcondition

---

## Attack Plan

Based on vulnerabilities found, the attack plan for next phase:

1. **First assault**: CRIT-02 - TLS context leak via repeated failed handshakes
2. **Second assault**: HIGH-01 - SMTP injection via malformed email address
3. **Third assault**: HIGH-08 - Verify TLS bypass by capturing network traffic
4. **Fourth assault**: MED-04 - Send email with file attachment (verify empty)
5. **Fifth assault**: MED-06 - Send partial response to trigger infinite loop

---

## Recommended Defenses (for later)

1. Add email address validation regex in preconditions
2. Add size limits on message components
3. Implement proper TLS encryption (EncryptMessage/DecryptMessage)
4. Add socket resource cleanup in all error paths
5. Add timeout to receive_line loop
6. Generate cryptographically random MIME boundaries
7. Track SMTP state machine properly
8. Read actual file content in make_from_file

---

## Next Step

-> X03-CONTRACT-ASSAULT.md
