# DECISIONS: simple_email

## Date: 2026-01-18
## Library: simple_email

---

## Critical Finding

**ISE EiffelStudio already has an email library at:**
```
$ISE_LIBRARY/library/net/mail/
```

**Contents:**
- `EMAIL` - Email message composition
- `SMTP_PROTOCOL` - SMTP sending protocol
- `MAILER` - Transfer orchestration
- `HEADER` - Email headers
- Various resource classes

**Critical Gap:** The ISE mail library does NOT support TLS/STARTTLS. It uses plain sockets only (port 25). This is a security blocker for production use with modern mail servers.

---

## Decision Summary

| ID | Decision | Option Chosen | Reversibility |
|----|----------|---------------|---------------|
| D-001 | Build vs Adapt | HYBRID - Adapt ISE + Add TLS | HARD |
| D-002 | TLS Implementation | Win32 SChannel via inline C | MEDIUM |
| D-003 | Architecture | Facade wrapping ISE classes | EASY |
| D-004 | Authentication | PLAIN + LOGIN (STARTTLS required) | EASY |
| D-005 | IMAP/POP3 | Defer to Phase 2 | EASY |
| D-006 | Dependencies | ISE net.ecf + simple_base64 | MEDIUM |

---

## Key Decisions

### D-001: Build vs Buy vs Adapt

**Context:**
We discovered ISE already has email classes. Must decide whether to build from scratch, use ISE as-is, or adapt ISE.

**Options Considered:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| A: Build | Create everything from scratch | Full control, optimal API | High effort, duplication |
| B: Adopt ISE | Use ISE net/mail directly | Zero effort | No TLS = unusable for modern servers |
| C: Adapt/Hybrid | Wrap ISE, add TLS transport | Leverage tested code, add security | ISE API constraints |

**Evaluation:**

| Criterion | Weight | Build | Adopt ISE | Hybrid |
|-----------|--------|-------|-----------|--------|
| Effort | 3 | 2 | 5 | 4 |
| Security | 3 | 5 | 1 | 5 |
| Maintainability | 2 | 4 | 3 | 4 |
| API Quality | 2 | 5 | 2 | 3 |
| Risk | 2 | 2 | 5 | 4 |
| **Weighted** | | **39** | **34** | **48** |

**Decision:** HYBRID - Adapt ISE library and add TLS transport

**Rationale:**
1. ISE's EMAIL and SMTP_PROTOCOL are tested and RFC-compliant for message composition
2. We only need to replace/enhance the transport layer with TLS support
3. Reduces effort while achieving security goal
4. Falls back to known-working code for non-TLS parts

**Trade-offs Accepted:**
- API constrained by ISE design (can wrap with facade)
- Dependency on ISE library stability

**Consequences:**
- SIMPLE_EMAIL facade wraps ISE classes
- Custom TLS socket implementation needed
- Must test compatibility with ISE library updates

---

### D-002: TLS Implementation Strategy

**Context:**
Need TLS support for STARTTLS (port 587) and implicit TLS (port 465). ISE library has no TLS.

**Options Considered:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| A: OpenSSL via FFI | Wrap OpenSSL library | Mature, cross-platform | External DLL dependency |
| B: Win32 SChannel | Use Windows Secure Channel | No external deps, Windows native | Windows only |
| C: ISE cURL | Use cURL for SMTP | Has TLS, maintained | cURL wrapper is HTTP-focused |

**Decision:** B - Win32 SChannel via inline C

**Rationale:**
1. Windows is primary platform (matches ecosystem)
2. No external DLL dependencies
3. Follows simple_* inline C pattern
4. SChannel is maintained by Microsoft

**Trade-offs Accepted:**
- Windows-only initially (Linux via OpenSSL can be added later)
- More complex implementation than cURL

**Implementation Notes:**
```eiffel
-- Inline C pattern for SChannel
ssl_connect (a_socket: POINTER; a_host: STRING): POINTER
    external
        "C inline use <windows.h>, <schannel.h>, <security.h>"
    alias
        "[
            // SChannel credential/context setup
            // Returns SSL context handle
        ]"
    end
```

---

### D-003: Architecture Pattern

**Context:**
Need to decide class structure for simple_email.

**Options Considered:**

| Option | Description |
|--------|-------------|
| A: Single Facade | One SIMPLE_EMAIL class does everything |
| B: Protocol Split | SIMPLE_SMTP, SIMPLE_IMAP, SIMPLE_POP3 |
| C: Hybrid | Facade + internal protocol classes |

**Decision:** C - Hybrid (Facade + Protocol classes)

**Rationale:**
- Single entry point (SIMPLE_EMAIL) for simple use cases
- Internal classes for protocol-specific logic
- Extensible for Phase 2 (IMAP/POP3)

**Class Structure:**
```
SIMPLE_EMAIL (Facade)
├── SE_SMTP_CLIENT (Internal - wraps ISE SMTP_PROTOCOL + TLS)
├── SE_IMAP_CLIENT (Internal - Phase 2)
├── SE_POP3_CLIENT (Internal - Phase 2)
├── SE_MESSAGE (Internal - wraps ISE EMAIL)
└── SE_TLS_SOCKET (Internal - Win32 SChannel)
```

---

### D-004: Authentication Mechanisms

**Context:**
SMTP servers require authentication. Which mechanisms to support?

**Options Considered:**

| Mechanism | Description | Modern Support |
|-----------|-------------|----------------|
| PLAIN | Base64 encoded credentials | Universal with TLS |
| LOGIN | Legacy base64 mechanism | Common fallback |
| CRAM-MD5 | Challenge-response | Declining |
| XOAUTH2 | OAuth2 bearer token | Google/Microsoft |

**Decision:** PLAIN + LOGIN (require TLS), defer XOAUTH2

**Rationale:**
1. PLAIN over TLS is the standard modern approach
2. LOGIN provides fallback for older servers
3. XOAUTH2 requires external token management (out of scope for MVP)

**Consequences:**
- Users MUST use TLS for authentication (security)
- Plain port 25 will not support auth (by design)

---

### D-005: Phase 1 Scope

**Context:**
Must decide exact MVP feature set.

**Decision: Phase 1 (MVP):**
- ✅ SMTP send over TLS (port 465)
- ✅ SMTP send over STARTTLS (port 587)
- ✅ Plain text email
- ✅ HTML email
- ✅ File attachments
- ✅ AUTH PLAIN, AUTH LOGIN
- ❌ IMAP (Phase 2)
- ❌ POP3 (Phase 2)
- ❌ OAuth2 (Phase 3)

**Rationale:**
- SMTP send is highest priority (notifications, alerts)
- IMAP/POP3 are read operations - less common for simple_* use cases
- Can add receive capabilities incrementally

---

### D-006: Dependencies

**Context:**
What libraries will simple_email depend on?

**Decision:**

| Dependency | Type | Purpose |
|------------|------|---------|
| ISE net.ecf | External | EMAIL, SMTP_PROTOCOL base classes |
| simple_base64 | Simple Ecosystem | MIME encoding, AUTH encoding |
| ISE base | Standard | Core types |

**Not Including:**
- ISE cURL (HTTP-focused, doesn't help SMTP)
- OpenSSL (external DLL, prefer SChannel)

**Rationale:**
- Minimal dependencies
- Leverage existing tested code
- Follow simple_* patterns

---

## Trade-offs Summary

| Trade-off | Favored | Unfavored | Mitigation |
|-----------|---------|-----------|------------|
| Windows vs Cross-platform | Windows (SChannel) | Linux | Can add OpenSSL backend later |
| ISE dependency vs Pure implementation | Use ISE | Build all | Facade abstracts ISE details |
| TLS required vs Optional | Required for auth | Plain auth allowed | Security over convenience |
| MVP scope vs Complete features | Limited MVP | Full IMAP/POP3 | Phase 2 adds receive |

---

## Deferred Decisions

| ID | Topic | Decide By | Default |
|----|-------|-----------|---------|
| DD-001 | Linux TLS backend | Phase 2 | OpenSSL via inline C |
| DD-002 | OAuth2 implementation | Phase 3 | Not supported |
| DD-003 | Connection pooling | After MVP | Create new connection each time |
| DD-004 | Async API | After MVP | Synchronous only |

---

## Risk Register from Decisions

| Decision | Risk | Likelihood | Mitigation |
|----------|------|------------|------------|
| D-001 Hybrid | ISE API changes | LOW | Facade isolates |
| D-002 SChannel | Complex implementation | MEDIUM | Prototype first |
| D-003 Architecture | Over-engineering | LOW | Keep facade simple |
| D-005 Phase scope | MVP too limited | MEDIUM | User feedback loop |

---

**7S-04-DECISIONS: COMPLETE**

Next Step: 7S-05-INNOVATIONS (Identify novel approaches)
