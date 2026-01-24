# RISK ANALYSIS: simple_email


**Date**: 2026-01-18

## Date: 2026-01-18
## Library: simple_email

---

## Risk Summary

| Level | Count | Examples |
|-------|-------|----------|
| Critical | 1 | R-TECH-001 |
| Major | 2 | R-TECH-002, R-EXT-001 |
| Moderate | 3 | R-SCOPE-001, R-TECH-003, R-INNOV-001 |
| Minor | 2 | R-RES-001, R-SCHED-001 |

**Overall Risk Level**: MEDIUM
**Proceed Recommendation**: YES WITH CAUTION

---

## Risk Matrix

```
                    IMPACT
               LOW     MEDIUM    HIGH
          ┌─────────┬─────────┬─────────┐
     HIGH │         │         │ R-TECH-001 │
          ├─────────┼─────────┼─────────┤
L    MED  │R-RES-001│R-SCOPE-001│R-TECH-002│
          │         │R-INNOV-001│R-EXT-001 │
          ├─────────┼─────────┼─────────┤
     LOW  │R-SCHED-001│R-TECH-003│         │
          └─────────┴─────────┴─────────┘
```

---

## Critical Risks

### R-TECH-001: SChannel TLS Implementation Complexity

| Aspect | Assessment |
|--------|------------|
| Category | TECHNICAL |
| Likelihood | HIGH |
| Impact | HIGH |
| Score | 9 |

**Description:**
Win32 SChannel API is notoriously complex. The SSPI (Security Support Provider Interface) requires careful state management: credential handles, context handles, buffer management, and renegotiation handling. A bug here could cause security vulnerabilities or connection failures.

**Trigger:**
Attempting to implement TLS handshake with SChannel inline C.

**Early Warning Signs:**
- Prototype takes more than 2 days
- Mysterious connection failures with major providers
- Memory corruption or leaks

**Mitigation:**

*Prevention (reduce likelihood):*
- Study existing SChannel implementations (C/C++ examples)
- Build minimal prototype FIRST before integration
- Use SCHANNEL_CRED carefully with proper credential lifetime

*Contingency (reduce impact):*
- Fall back to OpenSSL if SChannel proves too difficult
- Use libcurl for transport layer instead
- Limit MVP to servers with simpler TLS requirements

**Chosen Mitigation:** Prototype SChannel TLS socket FIRST (Phase 0.5) before proceeding with full implementation.

**Owner:** Developer
**Status:** IDENTIFIED

---

## Major Risks

### R-TECH-002: ISE Library Compatibility/Stability

| Aspect | Assessment |
|--------|------------|
| Category | TECHNICAL |
| Likelihood | MEDIUM |
| Impact | HIGH |
| Score | 6 |

**Description:**
Our hybrid approach depends on ISE's net/mail library. If ISE changes internal APIs in future versions, our wrapper may break. Additionally, the ISE library may have undocumented limitations.

**Trigger:**
ISE EiffelStudio update changes net/mail library internals.

**Mitigation:**
- Facade pattern isolates ISE dependencies
- Pin to specific EiffelStudio version for production
- Test against multiple EiffelStudio versions in CI
- Document ISE version requirements

**Owner:** Developer
**Status:** IDENTIFIED

---

### R-EXT-001: Email Provider Protocol Variations

| Aspect | Assessment |
|--------|------------|
| Category | EXTERNAL |
| Likelihood | MEDIUM |
| Impact | HIGH |
| Score | 6 |

**Description:**
Major email providers (Gmail, Outlook, Yahoo) have quirks beyond RFC standards. Gmail requires app-specific passwords or OAuth. Outlook has specific TLS requirements. These variations could cause connection failures.

**Trigger:**
Testing with production email providers fails despite RFC compliance.

**Mitigation:**
- Test against multiple providers during development
- Document provider-specific requirements
- Support app-specific passwords (credential handling)
- Plan OAuth2 for Phase 3

**Owner:** Developer
**Status:** IDENTIFIED

---

## Moderate Risks

### R-SCOPE-001: Feature Creep to Full Email Client

| Aspect | Assessment |
|--------|------------|
| Category | SCOPE |
| Likelihood | MEDIUM |
| Impact | MEDIUM |
| Score | 4 |

**Description:**
Email is a deep domain. Requests for MIME parsing, calendar invites, rich formatting, contact management could expand scope infinitely.

**Trigger:**
User requests for "just one more feature" accumulate.

**Mitigation:**
- Strict phase boundaries (SMTP first, IMAP later, etc.)
- Document explicit non-goals
- Suggest alternatives for out-of-scope features
- Version discipline (1.0 = MVP only)

**Owner:** Developer
**Status:** IDENTIFIED

---

### R-TECH-003: SCOOP Compatibility Issues

| Aspect | Assessment |
|--------|------------|
| Category | TECHNICAL |
| Likelihood | LOW |
| Impact | MEDIUM |
| Score | 3 |

**Description:**
Socket operations may not work smoothly with SCOOP's separate semantics. Blocking I/O on one processor could affect responsiveness.

**Trigger:**
Using simple_email in SCOOP application causes hangs or errors.

**Mitigation:**
- Test explicitly in SCOOP context
- Use timeouts on all blocking operations
- Document SCOOP usage patterns
- Consider async pattern for Phase 2

**Owner:** Developer
**Status:** IDENTIFIED

---

### R-INNOV-001: DBC Contracts Too Restrictive

| Aspect | Assessment |
|--------|------------|
| Category | INNOVATION |
| Likelihood | MEDIUM |
| Impact | MEDIUM |
| Score | 4 |

**Description:**
Our strict DBC contracts might reject valid use cases. For example, requiring valid email format might fail on internal relay scenarios where addresses aren't standard.

**Trigger:**
User reports precondition violations for legitimate use cases.

**Mitigation:**
- Start with permissive contracts, tighten based on experience
- Provide escape hatches for power users
- Document contract rationale
- Iterate based on real-world feedback

**Owner:** Developer
**Status:** IDENTIFIED

---

## Minor Risks

### R-RES-001: SChannel Documentation Scarcity

| Aspect | Assessment |
|--------|------------|
| Category | RESOURCE |
| Likelihood | MEDIUM |
| Impact | LOW |
| Score | 2 |

**Description:**
Microsoft SChannel documentation is sparse compared to OpenSSL. Finding correct API usage may require trial and error.

**Mitigation:**
- Collect reference implementations (C/C++ examples)
- Use Microsoft samples from MSDN
- Allocate extra time for research

---

### R-SCHED-001: Underestimated Complexity

| Aspect | Assessment |
|--------|------------|
| Category | SCHEDULE |
| Likelihood | LOW |
| Impact | LOW |
| Score | 1 |

**Description:**
SMTP appears simple but has many edge cases (encoding, multipart, server variations).

**Mitigation:**
- Prototype early to validate estimates
- Timeboxed iterations
- MVP first, polish later

---

## Mitigation Plan

| Risk | Action | When | Owner | Status |
|------|--------|------|-------|--------|
| R-TECH-001 | Build SChannel prototype | Phase 0.5 | Dev | PLANNED |
| R-TECH-001 | Evaluate OpenSSL fallback | If prototype fails | Dev | CONTINGENCY |
| R-TECH-002 | Pin EiffelStudio version | Phase 1 | Dev | PLANNED |
| R-EXT-001 | Test with Gmail/Outlook | Phase 1 | Dev | PLANNED |
| R-SCOPE-001 | Document non-goals | Now | Dev | IN_PROGRESS |
| R-INNOV-001 | Review contracts with users | Phase 1+ | Dev | PLANNED |

---

## Contingency Plans

### If R-TECH-001 Materializes (SChannel Too Complex)

**Trigger:** Prototype takes > 1 week or has fundamental issues

**Immediate Actions:**
1. STOP SChannel development
2. Evaluate OpenSSL inline C approach
3. Evaluate cURL for transport layer

**Escalation:** Document decision, update architecture

**Recovery Plan:**
- OpenSSL approach (medium effort, proven)
- cURL approach (low effort, less control)
- Phase 1 delayed but still achievable

### If R-EXT-001 Materializes (Provider Incompatibility)

**Trigger:** Cannot connect to Gmail/Outlook despite correct implementation

**Immediate Actions:**
1. Research provider-specific requirements
2. Implement workarounds if reasonable
3. Document unsupported providers if not feasible

**Recovery Plan:**
- App-specific passwords work for most providers
- OAuth2 in Phase 3 addresses modern requirements
- Local/internal relay always works (fallback)

---

## Monitoring

| Risk | Indicator | Check Frequency | Threshold |
|------|-----------|-----------------|-----------|
| R-TECH-001 | Prototype progress | Daily | 3 days without progress |
| R-TECH-002 | ISE release notes | Per release | Breaking changes |
| R-EXT-001 | Provider test results | Weekly | 2+ providers failing |
| R-SCOPE-001 | Feature request count | Per iteration | 3+ major requests |

---

## Proceed Conditions

The project should proceed if:

1. **SChannel Prototype Succeeds** (or fallback identified)
   - Can establish TLS connection
   - Can send/receive encrypted data
   - No memory leaks in basic test

2. **ISE Library Works As Expected**
   - EMAIL class creates valid messages
   - SMTP_PROTOCOL sends via plain socket
   - Integration path is clear

3. **At Least One Provider Works**
   - Can send email to Gmail or Outlook
   - Authentication succeeds
   - Message delivered

**Recommendation:** Proceed with Phase 0.5 (SChannel prototype) to validate the highest-risk technical decision before committing to full implementation.

---

**7S-06-RISKS: COMPLETE**

Next Step: 7S-07-RECOMMENDATION (Final synthesis and recommendation)
