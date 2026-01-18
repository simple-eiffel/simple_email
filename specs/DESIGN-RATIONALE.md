# DESIGN-RATIONALE: simple_email

## Date: 2026-01-18
## Status: Phase 1 Complete

---

## Key Design Decisions

### D1: Hybrid Approach (Wrap ISE + Add TLS)

**Decision:** Use ISE's net/mail library concepts but add our own TLS transport via Win32 SChannel.

**Alternatives Considered:**
1. Pure ISE - No TLS support
2. OpenSSL binding - External dependency, complex build
3. Pure Win32 - Maximum control, maximum effort
4. **SChannel hybrid** - Win32 TLS, simple build ✓

**Rationale:**
- ISE's mail library exists but lacks TLS
- SChannel is built into Windows
- No external dependencies to manage
- Inline C pattern works well with SChannel

### D2: Single Facade (SIMPLE_EMAIL)

**Decision:** One entry point class for all library functionality.

**Alternatives Considered:**
1. Multiple entry points (SMTPClient, IMAPClient, etc.)
2. Factory pattern for creating clients
3. **Single facade class** ✓

**Rationale:**
- Consistent with simple_* ecosystem
- Lower cognitive load for users
- Easier to document and discover
- Can delegate internally as needed

### D3: Composition Over Inheritance

**Decision:** Flat class hierarchy using composition.

**Alternatives Considered:**
1. Deep inheritance hierarchy
2. Mixin-based design
3. **Composition with clear interfaces** ✓

**Rationale:**
- Simpler to understand
- Easier to test in isolation
- Better SCOOP compatibility
- Can refactor to inheritance later if needed

### D4: Separate Value Objects (SE_MESSAGE, SE_ATTACHMENT)

**Decision:** Message composition uses separate value objects.

**Alternatives Considered:**
1. Inline all data in facade
2. Builder pattern returning strings
3. **Rich value objects with validation** ✓

**Rationale:**
- Clear separation of concerns
- Self-validating objects
- Reusable across protocols (SMTP/IMAP)
- Testable independently

### D5: Error Handling via Queries

**Decision:** Use `has_error` and `last_error` pattern.

**Alternatives Considered:**
1. Exceptions
2. Result objects (SE_RESULT)
3. **Query-based error checking** ✓

**Rationale:**
- Consistent with Eiffel idioms
- No exception handling complexity
- Simple to check and handle
- Works well with SCOOP

---

## OOSC2 Principle Application

### Single Responsibility

| Class | Responsibility |
|-------|---------------|
| SIMPLE_EMAIL | Library API facade |
| SE_MESSAGE | Email composition |
| SE_ATTACHMENT | File attachment handling |
| SE_SMTP_CLIENT | SMTP protocol |
| SE_TLS_SOCKET | TLS transport |

Each class does exactly one thing.

### Open/Closed Principle

- Classes are **closed** for modification
- Extension points for future protocols (IMAP, POP3)
- New transports can be added without changing existing code

### Command-Query Separation

All features follow CQS strictly:

| Type | Returns | Modifies State |
|------|---------|----------------|
| Query | Value | Never |
| Command | Void | May |

**Exception:** `send` returns BOOLEAN for convenience.
This is documented and intentional.

### Uniform Access

```eiffel
-- Both look the same to caller:
smtp_host: STRING  -- Could be attribute
smtp_port: INTEGER -- Could be function
```

Internal representation can change without API change.

### Information Hiding

| Visibility | Content |
|------------|---------|
| PUBLIC | API features only |
| {NONE} | All implementation details |
| Feature groups | Organized by purpose |

---

## Feature Group Design

### Standard Ordering

```eiffel
feature {NONE} -- Initialization
    make

feature -- Access (Queries)
    -- Return data

feature -- Status (Boolean Queries)
    -- is_*, has_*

feature -- Measurement (Integer Queries)
    -- *_count

feature -- Settings (Commands)
    -- set_*

feature -- Connection (Commands)
    -- connect, disconnect

feature -- Operations (Commands)
    -- send, receive, etc.

feature {NONE} -- Implementation
    -- Internal attributes

invariant
    -- Class invariants
```

### Naming Conventions

| Pattern | Usage | Example |
|---------|-------|---------|
| is_* | Boolean status | is_connected |
| has_* | Boolean existence | has_error |
| *_count | Integer quantity | recipient_count |
| set_* | Set value | set_timeout |
| add_* | Add to collection | add_to |
| clear_* | Empty collection | clear_recipients |

---

## Contract Design Philosophy

### Preconditions

**Design Principle:** Reject invalid inputs early.

```eiffel
set_from (a_address: STRING)
    require
        address_not_empty: not a_address.is_empty
```

- Fail fast, fail clearly
- Document expectations
- Enable defensive programming

### Postconditions

**Design Principle:** Guarantee results.

```eiffel
set_from (a_address: STRING)
    ensure
        from_set: from_address.same_string (a_address)
        has_from: has_from
```

- Verify side effects
- Enable caller trust
- Support formal verification

### Invariants

**Design Principle:** Maintain consistency.

```eiffel
invariant
    auth_requires_connection: is_authenticated implies is_connected
```

- Express business rules
- Catch invalid states
- Document constraints

---

## Future Extension Plan

### Phase 2: IMAP Client

New class: `SE_IMAP_CLIENT`
- Reuse SE_TLS_SOCKET
- New protocol implementation
- New message parsing

### Phase 3: POP3 Client

New class: `SE_POP3_CLIENT`
- Reuse SE_TLS_SOCKET
- Simpler protocol than IMAP

### Phase 4: Refactoring

Consider abstract base:

```eiffel
deferred class SE_EMAIL_CLIENT

feature
    connect deferred end
    disconnect deferred end
    is_connected: BOOLEAN deferred end
end
```

---

**DESIGN-RATIONALE: COMPLETE**
