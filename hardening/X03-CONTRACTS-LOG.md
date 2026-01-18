# CONTRACT ASSAULT REPORT: simple_email

## Date: 2026-01-18

## Compilation Result
```
Eiffel Compilation Manager
Version 25.02.9.8732 - win64

Degree 6: Examining System
Degree 5: Parsing Classes
...
System Recompiled.
```

## Test Run Result
```
Results: 36 passed, 0 failed
ALL TESTS PASSED
```

## Assault Summary
- Contracts deployed: 15
- Contract failures: 0
- Bugs revealed: 0 (existing tests use valid data)

## Contracts Added

### Preconditions

| Class | Feature | Contract | Purpose | Result |
|-------|---------|----------|---------|--------|
| SE_MESSAGE | set_from | address_has_at: a_address.has ('@') | Block invalid emails | PASS |
| SE_MESSAGE | set_from | address_no_newlines: not has CR/LF | Block SMTP injection | PASS |
| SE_MESSAGE | add_to | address_has_at: a_address.has ('@') | Block invalid emails | PASS |
| SE_MESSAGE | add_to | address_no_newlines: not has CR/LF | Block SMTP injection | PASS |
| SE_MESSAGE | add_cc | address_has_at: a_address.has ('@') | Block invalid emails | PASS |
| SE_MESSAGE | add_cc | address_no_newlines: not has CR/LF | Block SMTP injection | PASS |
| SE_MESSAGE | add_bcc | address_has_at: a_address.has ('@') | Block invalid emails | PASS |
| SE_MESSAGE | add_bcc | address_no_newlines: not has CR/LF | Block SMTP injection | PASS |

### Postconditions

| Class | Feature | Contract | Purpose | Result |
|-------|---------|----------|---------|--------|
| SE_MESSAGE | set_from | recipients_unchanged | Detect side effects | PASS |
| SE_MESSAGE | add_to | from_unchanged | Detect side effects | PASS |
| SE_MESSAGE | add_cc | to_unchanged | Detect side effects | PASS |
| SE_MESSAGE | add_bcc | to_unchanged | Detect side effects | PASS |
| SE_MESSAGE | add_bcc | cc_unchanged | Detect side effects | PASS |
| SIMPLE_EMAIL | connect | connected_or_error | Verify state | PASS |
| SIMPLE_EMAIL | connect | port_unchanged | Detect side effects | PASS |

### Invariants

No new invariants added (existing invariants adequate).

## Bugs Exposed

No bugs exposed by existing tests. All tests use valid email addresses (e.g., "sender@test.com") that pass the new preconditions.

However, the contracts will now BLOCK the following previously possible attacks:

1. **SMTP Injection blocked**: Cannot set email address containing CRLF
2. **Invalid addresses blocked**: Cannot set address without @ symbol

## Contracts That Passed (Hardening in Place)

All 15 contracts passed. They are now active hardening that will:
- Reject email addresses without @ symbol
- Reject email addresses containing newlines (CRLF injection)
- Verify no unintended side effects in setter operations

## Analysis

The existing tests all pass because they use valid, well-formed test data. This is expected - the tests were written following good practices. The assault contracts will protect against:

1. Future code changes that might accidentally break invariants
2. Runtime misuse by library consumers
3. SMTP header injection attacks via malformed addresses

## Next Attacks

For X04-ADVERSARIAL-TESTS, write tests that:
1. Try to set email without @ - should trigger precondition violation
2. Try to inject CRLF into email - should trigger precondition violation
3. Try to send empty message - should trigger is_valid precondition
4. Test connect failure postcondition - connect to bad host

## Files Modified

- `src/se_message.e` - Added 8 preconditions, 5 postconditions
- `src/simple_email.e` - Added 3 postconditions

## Next Step

-> X04-ADVERSARIAL-TESTS.md
