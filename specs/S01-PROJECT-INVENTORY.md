# S01: PROJECT INVENTORY - simple_email

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_email

## Project Structure

```
simple_email/
    +-- src/
    |   +-- simple_email.e       # Facade class
    |   +-- se_message.e         # Email message composition
    |   +-- se_smtp_client.e     # SMTP protocol client
    |   +-- se_attachment.e      # Attachment handling
    |   +-- se_tls_socket.e      # TLS socket (WinSock/SChannel)
    |   +-- se_tls_defs.h        # C header for SChannel
    |
    +-- testing/
    |   +-- test_app.e           # Test runner
    |   +-- lib_tests.e          # Core library tests
    |   +-- stress_tests.e       # Load/stress tests
    |   +-- adversarial_tests.e  # Edge case tests
    |   +-- test_runner.e        # Test execution
    |
    +-- research/
    |   +-- 7S-01-SCOPE.md
    |   +-- 7S-02-STANDARDS.md
    |   +-- 7S-03-SOLUTIONS.md
    |   +-- 7S-04-SIMPLE-STAR.md
    |   +-- 7S-05-SECURITY.md
    |   +-- 7S-06-SIZING.md
    |   +-- 7S-07-RECOMMENDATION.md
    |
    +-- specs/
    |   +-- S01-PROJECT-INVENTORY.md
    |   +-- S02-CLASS-CATALOG.md
    |   +-- S03-CONTRACTS.md
    |   +-- S04-FEATURE-SPECS.md
    |   +-- S05-CONSTRAINTS.md
    |   +-- S06-BOUNDARIES.md
    |   +-- S07-SPEC-SUMMARY.md
    |   +-- S08-VALIDATION-REPORT.md
    |
    +-- simple_email.ecf         # EiffelStudio config
    +-- README.md
    +-- CHANGELOG.md
```

## File Inventory

| File | Lines | Purpose |
|------|-------|---------|
| simple_email.e | 265 | Main facade class |
| se_message.e | 302 | Email message data |
| se_smtp_client.e | 567 | SMTP protocol |
| se_attachment.e | 109 | Attachment wrapper |
| se_tls_socket.e | 531 | TLS transport |

## Dependencies

### Internal (simple_* ecosystem)
- simple_base64
- simple_encoding

### External (System)
- Windows WinSock2
- Windows SChannel
- EiffelBase

## Build Targets

| Target | Purpose |
|--------|---------|
| simple_email | Library |
| simple_email_tests | Test suite |
