# INNOVATIONS: simple_email


**Date**: 2026-01-18

## Date: 2026-01-18
## Library: simple_email

---

## Innovation Summary

| ID | Innovation | Type | Novelty | Value |
|----|------------|------|---------|-------|
| I-001 | DBC-Enforced Email Safety | DESIGN | HIGH (Eiffel) | HIGH |
| I-002 | TLS-First Security Model | APPROACH | MEDIUM | HIGH |
| I-003 | Hybrid ISE Enhancement | COMBINATION | HIGH (Eiffel) | MEDIUM |
| I-004 | SCOOP-Compatible Email | FEATURE | HIGH (Eiffel) | MEDIUM |
| I-005 | Zero External Dependencies | APPROACH | MEDIUM | HIGH |

---

## Value Proposition

**For** Eiffel developers building applications with email functionality
**Who need** a secure, reliable way to send and receive email
**Our solution** simple_email provides a Design-by-Contract email client
**Unlike** Python smtplib (no contracts), Java Mail (complex), ISE net/mail (no TLS)
**Provides** compile-time safety guarantees and runtime contract verification for email operations with modern TLS security

---

## Unique Selling Points

1. **Design by Contract for Email**: Every email operation has preconditions, postconditions, and invariants - catching errors at contract-check time rather than mysterious server rejections
2. **Secure by Default**: TLS required for authentication, preventing accidental plaintext credential transmission
3. **Ecosystem Integration**: Uses existing simple_* libraries (simple_base64), follows simple_* patterns, enhances ISE library

---

## Key Innovations

### I-001: DBC-Enforced Email Safety

**Type**: DESIGN

**Description:**
Email operations are notoriously error-prone: invalid addresses, missing headers, incorrect MIME structure. Unlike other email libraries that fail at runtime with cryptic errors, simple_email uses Eiffel's Design by Contract to verify correctness before sending:

```eiffel
send_email
    require
        has_from: not from_address.is_empty
        has_recipient: not recipients.is_empty
        valid_addresses: across recipients as r all is_valid_email (r.item) end
        connection_ready: is_connected and is_authenticated
    do
        ...
    ensure
        message_sent: is_sent implies last_message_id /= Void
        error_recorded: not is_sent implies last_error /= Void
    end
```

**Problem Solved:**
- Prevents sending emails with missing From/To
- Catches invalid email format before server rejection
- Guarantees connection state is correct
- Documents success/failure contracts explicitly

**Novelty Assessment:**
- New to world: NO (DBC exists)
- New to Eiffel email: YES
- New to Simple ecosystem: YES (first email lib)

**Value:** Catches email errors at development/test time, not in production with user complaints.

---

### I-002: TLS-First Security Model

**Type**: APPROACH

**Description:**
Modern email servers require TLS. The ISE library only supports plaintext SMTP (port 25). simple_email inverts this: TLS is the default, plaintext is the exception.

**Traditional approach:**
```python
# Python smtplib - TLS is optional
smtp = SMTP('server', 587)
smtp.starttls()  # Easy to forget!
smtp.login(user, pass)  # Oops, credentials in clear if starttls omitted
```

**Our approach:**
```eiffel
-- simple_email - TLS required for auth
create email.make_secure ("server", 587)  -- STARTTLS
email.authenticate (user, password)  -- Safe, TLS already active

-- Plaintext only for no-auth scenarios (local relay)
create email.make_relay ("localhost", 25)  -- No auth allowed
```

**Problem Solved:**
- Prevents accidental credential leakage
- Defaults to secure configuration
- Makes insecure choices explicit

**Novelty Assessment:**
- New to world: NO (some libs do this)
- New to Eiffel: YES
- New to Simple ecosystem: YES

**Value:** Security by design, not by discipline.

---

### I-003: Hybrid ISE Enhancement

**Type**: COMBINATION

**Description:**
Rather than building from scratch, we enhance ISE's tested EMAIL and SMTP_PROTOCOL classes with our TLS transport layer. This is a novel combination:

**Combined elements:**
- ISE EMAIL class (message composition, headers, MIME)
- ISE SMTP_PROTOCOL (SMTP command/response handling)
- Our SE_TLS_SOCKET (Win32 SChannel implementation)
- simple_base64 (encoding)

**Novel combination:**
No one has wrapped ISE mail with TLS support before. This gives us:
- Tested RFC compliance from ISE
- Modern security from our TLS layer
- Ecosystem integration from simple_base64

**Synergy:**
Less code to write, more tested code, same security outcome.

---

### I-004: SCOOP-Compatible Email

**Type**: FEATURE

**Description:**
Eiffel's SCOOP (Simple Concurrent Object-Oriented Programming) model requires special handling for I/O operations. simple_email is designed to work correctly in SCOOP applications.

**Problem with other libraries:**
- Blocking I/O freezes processor
- Socket state shared across separate regions = errors

**Our design:**
- Operations are designed for separate semantics
- Timeouts prevent indefinite blocking
- State management respects SCOOP regions

**Not found in:**
- ISE net/mail: Not designed for SCOOP
- Python smtplib: No SCOOP concept
- Java Mail: Different concurrency model

**Value:** Eiffel developers using SCOOP can send email without workarounds.

---

### I-005: Zero External Dependencies

**Type**: APPROACH

**Description:**
Unlike other email solutions requiring OpenSSL, GnuTLS, or other external libraries, simple_email uses only:
- Windows built-in SChannel (for TLS)
- ISE standard libraries
- Simple ecosystem libraries

**Traditional approach:**
```
Java Mail → javax.mail.jar → Many dependencies
Python → pip install secure-smtplib → OpenSSL DLL
.NET MailKit → NuGet package → System.Security.Cryptography
```

**Our approach:**
```
simple_email → simple_base64 → ISE base (that's it)
             → ISE net/mail
             → Win32 SChannel (OS built-in)
```

**Problem Solved:**
- No "DLL hell"
- No version conflicts
- No external build dependencies
- Deployment is just the executable

**Value:** Simpler deployment, fewer moving parts.

---

## Differentiation from Alternatives

| Aspect | Python smtplib | Java Mail | ISE net/mail | simple_email |
|--------|----------------|-----------|--------------|--------------|
| Contracts | None | None | Limited | Full DBC |
| TLS | Optional | Optional | None | Required for auth |
| Complexity | Low-level | High | Medium | Simple facade |
| Dependencies | OpenSSL | JAR files | None | None (OS) |
| Void Safety | N/A | N/A | Partial | Full |
| SCOOP | N/A | N/A | No | Yes |

---

## Eiffel Advantages

### Design by Contract
Email is a domain full of implicit requirements (valid addresses, proper headers, connection state). DBC makes these explicit and verifiable:
- `require` catches bad inputs before sending
- `ensure` guarantees predictable outcomes
- `invariant` maintains connection/state validity

### Void Safety
Email APIs are plagued by null pointer errors (missing attachments, null responses). Eiffel's void safety eliminates this class of bugs entirely.

### SCOOP Compatibility
Modern applications are concurrent. Our design works with Eiffel's native concurrency model without workarounds.

---

## Innovation Risks

| Innovation | Risk | Mitigation |
|------------|------|------------|
| I-001 DBC | Contracts too strict | Iterative refinement based on real usage |
| I-002 TLS-First | Users need plaintext | Provide explicit make_relay for local use |
| I-003 Hybrid | ISE library changes | Facade isolates internals |
| I-004 SCOOP | Performance overhead | Profile and optimize hot paths |
| I-005 Zero-deps | SChannel complexity | Prototype TLS first |

---

## Competitive Moat

**Why can't others copy?**
- Eiffel-specific advantages (DBC, void safety) not available in Python/Java
- Hybrid approach requires intimate knowledge of ISE internals
- Simple ecosystem integration creates network effects

**How long advantage lasts:**
- Permanent for Eiffel ecosystem (no competitors)
- As long as ISE library remains stable

**How to extend advantage:**
- Add IMAP/POP3 with same DBC approach
- Support Linux via OpenSSL backend
- Build higher-level abstractions (email templates, queuing)

---

**7S-05-INNOVATIONS: COMPLETE**

Next Step: 7S-06-RISKS (Identify and analyze risks)
