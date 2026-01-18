# RECOMMENDATION: simple_email

## Date: 2026-01-18
## Library: simple_email
## Research Completed: 7-Step Deep Research Workflow

---

## Executive Summary

**Recommendation**: PROCEED WITH CONDITIONS

We should build simple_email, an Eiffel email client library providing SMTP/IMAP/POP3 capabilities with Design by Contract and TLS security. The research validates both the need (no Eiffel email library with TLS exists) and the approach (hybrid enhancement of ISE net/mail with SChannel TLS). The critical condition is validating the SChannel TLS implementation through a Phase 0.5 prototype before committing to full development.

---

## Key Findings

1. **ISE Has Untapped Email Infrastructure**: The ISE net/mail library (`EMAIL`, `SMTP_PROTOCOL`) provides tested RFC-compliant message composition and SMTP handling, but lacks TLS - our hybrid approach leverages this existing code.

2. **TLS Is The Gap, Not Email**: The technical challenge is TLS implementation via Win32 SChannel, not email protocol handling. This de-risks the project by separating concerns.

3. **Simple Ecosystem Supports Us**: `simple_base64` already exists for encoding. The inline C pattern from other simple_* libraries provides a proven approach for Win32 API integration.

4. **DBC Email Is Novel**: No email library provides Eiffel's Design by Contract guarantees. This is genuine differentiation, not just "Eiffel version of existing lib."

---

## Key Risks

1. **SChannel Complexity** (Critical): Win32 SChannel API is complex. **Mitigation**: Build prototype first (Phase 0.5); OpenSSL fallback if needed.

2. **Provider Variations** (Major): Gmail/Outlook may have quirks. **Mitigation**: Test against multiple providers; document requirements.

---

## Go/No-Go Score

| Factor | Weight | Score | Weighted |
|--------|--------|-------|----------|
| Problem value | 3 | 4 | 12 |
| Solution viability | 3 | 4 | 12 |
| Competitive advantage | 2 | 5 | 10 |
| Risk level | 3 | 3 | 9 |
| Resource availability | 2 | 4 | 8 |
| Strategic fit | 2 | 5 | 10 |
| **Total** | **15** | | **61/75** |

**Score Interpretation**: 61/75 = **Strong GO** (threshold: 60-75)

---

## Recommendation Details

### What We Should Do

**PROCEED** with simple_email development using the hybrid approach:
1. Wrap ISE `EMAIL` and `SMTP_PROTOCOL` for message handling
2. Implement Win32 SChannel TLS transport layer
3. Create `SIMPLE_EMAIL` facade following ecosystem patterns
4. **CONDITION**: Validate SChannel TLS in Phase 0.5 before full implementation

### Why

1. **Clear Need**: No void-safe, DBC, TLS-enabled email library exists for Eiffel
2. **De-Risked Approach**: ISE provides tested email logic; we only add TLS
3. **Ecosystem Fit**: Follows simple_* patterns; uses simple_base64
4. **Manageable Risk**: TLS complexity can be prototyped independently

### Conditions

Before proceeding to Phase 1:
- [ ] SChannel TLS prototype can establish connection
- [ ] SChannel TLS prototype can complete handshake with Gmail
- [ ] Memory management is clean (no leaks in basic test)
- [ ] ISE EMAIL class works as documented

---

## Roadmap

```
Phase 0.5: TLS Prototype    Phase 1: SMTP Send     Phase 2: Receive
├──────────────────────────┼─────────────────────┼──────────────────┤
|████████                  |█████████████████████|████████████████ |
├──────────────────────────┼─────────────────────┼──────────────────┤
Milestone: TLS Works       Milestone: Send Email  Milestone: IMAP
```

### Phase 0.5: TLS Prototype (CRITICAL PATH)
**Duration**: 3-5 days
**Deliverables:**
- SE_TLS_SOCKET class with inline C SChannel
- Test program connecting to smtp.gmail.com:465
- Memory leak verification

**Key Milestone**: Can send "EHLO" over TLS and receive response

**GO/NO-GO Gate**: If prototype fails, evaluate OpenSSL fallback

---

### Phase 1: SMTP Send (MVP)
**Duration**: 1-2 weeks (after Phase 0.5)
**Deliverables:**
- SIMPLE_EMAIL facade class
- SE_SMTP_CLIENT wrapping ISE SMTP_PROTOCOL + TLS
- SE_MESSAGE wrapping ISE EMAIL
- Send plain text email
- Send HTML email
- Send with attachments
- AUTH PLAIN/LOGIN over TLS
- 20+ tests

**Key Milestone**: Can send email to Gmail with attachment

---

### Phase 2: Receive (IMAP/POP3)
**Duration**: 2-3 weeks
**Deliverables:**
- SE_IMAP_CLIENT class
- SE_POP3_CLIENT class
- List/select mailboxes
- Fetch messages
- Delete messages
- 20+ additional tests

**Key Milestone**: Can read inbox from Gmail

---

### Phase 3: Polish
**Duration**: 1 week
**Deliverables:**
- Documentation
- Error handling improvements
- Contract refinement
- Edge case tests

**Key Milestone**: Library published to simple-eiffel GitHub

---

## Next Steps

| # | Action | Owner | Deadline | Output |
|---|--------|-------|----------|--------|
| 1 | Create simple_email ECF | Dev | Day 1 | simple_email.ecf |
| 2 | Build SChannel TLS prototype | Dev | Day 5 | SE_TLS_SOCKET.e |
| 3 | Test prototype with Gmail | Dev | Day 5 | Connection verified |
| 4 | GO/NO-GO decision | Larry | Day 6 | Proceed or pivot |
| 5 | Begin Phase 1 if GO | Dev | Day 7+ | SIMPLE_EMAIL facade |

**Decision Required:**
- Decision: Approve Phase 0.5 TLS prototype
- By whom: Larry
- By when: Immediate
- Options: (A) Proceed with SChannel, (B) Start with OpenSSL, (C) Defer project

---

## Resources Required

### People
- **Eiffel Developer**: Inline C expertise, DBC, Win32 API
  - Skills: C, Eiffel, Win32, networking
  - Effort: 4-6 weeks total

### Tools
- EiffelStudio 25.02 (already available)
- Gmail test account with app-specific password
- Local SMTP server for testing (MailHog or similar)

### Dependencies
- ISE net.ecf library (verified exists)
- simple_base64 (verified exists)
- Win32 SDK (standard Windows install)

### Budget
- None required (all tools available)

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Tests passing | 100% | Automated test run |
| Gmail send works | Yes | Manual test |
| Outlook send works | Yes | Manual test |
| Memory leaks | 0 | Valgrind/similar |
| DBC violations in normal use | 0 | Test coverage |
| API simplicity | < 10 methods for basic use | Code review |

### Checkpoints

| Checkpoint | Expected State |
|------------|----------------|
| Day 5 | TLS prototype connects to Gmail |
| Day 10 | Can send plain text email |
| Day 15 | Can send email with attachment |
| Day 20 | IMAP connection works |
| Day 30 | Full Phase 1+2 complete |

---

## Appendix

### Research Documents
- [STEP-1-SCOPE.md](./STEP-1-SCOPE.md) - Problem definition
- [STEP-2-LANDSCAPE.md](./STEP-2-LANDSCAPE.md) - Existing solutions
- [STEP-3-REQUIREMENTS.md](./STEP-3-REQUIREMENTS.md) - Detailed requirements
- [STEP-4-DECISIONS.md](./STEP-4-DECISIONS.md) - Design decisions
- [STEP-5-INNOVATIONS.md](./STEP-5-INNOVATIONS.md) - Novel approaches
- [STEP-6-RISKS.md](./STEP-6-RISKS.md) - Risk analysis

### Key References
- [RFC 5321 - SMTP](https://www.rfc-editor.org/rfc/rfc5321.html)
- [RFC 3501 - IMAP](https://www.rfc-editor.org/rfc/rfc3501)
- [ISE net/mail library](C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\library\net\mail\)
- [Win32 SChannel Documentation](https://docs.microsoft.com/en-us/windows/win32/secauthn/secure-channel)

---

**DEEP RESEARCH COMPLETE**

**7S-07-RECOMMENDATION: COMPLETE**

This research output is ready for:
→ **04_spec-from-research** workflow (R01-R08) to convert research to formal specification
→ **01_project-creation** workflow to begin implementation

---

*Research completed: 2026-01-18*
*Recommendation: PROCEED WITH CONDITIONS*
*Ready for: Spec-from-Research workflow*
