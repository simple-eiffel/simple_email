# CLASS-HIERARCHY: simple_email

## Date: 2026-01-18
## Status: Phase 1 Complete

---

## Class Overview

| Class | Role | Inheritance |
|-------|------|-------------|
| SIMPLE_EMAIL | Facade | None (top-level) |
| SE_MESSAGE | Value Object | None |
| SE_ATTACHMENT | Value Object | None |
| SE_SMTP_CLIENT | Service | None |
| SE_TLS_SOCKET | Transport | None |

---

## Hierarchy Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                       ANY (Eiffel root)                        │
└────────────────────────────────────────────────────────────────┘
                              │
    ┌─────────────────────────┼─────────────────────────────┐
    │                         │                             │
    ▼                         ▼                             ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  SIMPLE_EMAIL   │   │   SE_MESSAGE    │   │ SE_SMTP_CLIENT  │
│  (Facade)       │   │  (Value Object) │   │   (Service)     │
└─────────────────┘   └────────┬────────┘   └────────┬────────┘
                               │                     │
                               ▼                     ▼
                    ┌─────────────────┐   ┌─────────────────┐
                    │ SE_ATTACHMENT   │   │ SE_TLS_SOCKET   │
                    │ (Value Object)  │   │   (Transport)   │
                    └─────────────────┘   └─────────────────┘
```

---

## Design Rationale

### No Inheritance Used

The current design uses **composition over inheritance**:

1. **Simplicity**: Each class has a single, clear responsibility
2. **Flexibility**: Components can be replaced without affecting others
3. **Testing**: Each class can be tested in isolation
4. **SCOOP**: Separate processors for each component if needed

### Future Extension Points

If inheritance becomes needed:

```
Potential hierarchy for Phase 2:

SE_EMAIL_CLIENT (deferred)
    ├── SE_SMTP_CLIENT (sending)
    ├── SE_IMAP_CLIENT (reading)
    └── SE_POP3_CLIENT (reading)

SE_TRANSPORT (deferred)
    ├── SE_PLAIN_SOCKET (unencrypted)
    └── SE_TLS_SOCKET (encrypted)
```

---

## Class Categories

### Facade Layer
- **SIMPLE_EMAIL**: Entry point for library users

### Domain Layer
- **SE_MESSAGE**: Email message composition
- **SE_ATTACHMENT**: File attachment handling

### Protocol Layer
- **SE_SMTP_CLIENT**: SMTP protocol implementation

### Transport Layer
- **SE_TLS_SOCKET**: TLS-encrypted socket communication

---

## Dependency Direction

```
SIMPLE_EMAIL (High-level)
     │
     ├──▶ SE_MESSAGE (Domain)
     │         │
     │         └──▶ SE_ATTACHMENT (Domain)
     │
     └──▶ SE_SMTP_CLIENT (Protocol)
               │
               └──▶ SE_TLS_SOCKET (Transport)
```

Dependencies flow **downward** from high-level to low-level.
No circular dependencies exist.

---

## SCOOP Considerations

All classes are designed to be SCOOP-compatible:

| Class | Separate? | Reason |
|-------|-----------|--------|
| SIMPLE_EMAIL | No | User interface, synchronous |
| SE_MESSAGE | No | Value object, no I/O |
| SE_ATTACHMENT | No | Value object, no I/O |
| SE_SMTP_CLIENT | Potential | May need separate processor for async |
| SE_TLS_SOCKET | Potential | I/O operations, may block |

---

**CLASS-HIERARCHY: COMPLETE**
