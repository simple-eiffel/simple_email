# AlertStream - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 5 days | simple_email, simple_json |
| Phase 2 | Full CLI | 5 days | Phase 1, simple_sql, simple_template |
| Phase 3 | Polish | 3 days | Phase 2 complete |

---

## Phase 1: MVP

### Objective

Deliver a functional CLI that can:
- Parse JSON events from stdin
- Apply basic rule matching
- Send immediate alert emails
- Log operations

### Deliverables

1. **AS_CLI** - Command-line interface with `send` and `ingest` commands
2. **AS_EVENT** - Event parsing and validation
3. **AS_CONFIG** - JSON configuration loader (SMTP + rules)
4. **AS_ROUTER** - Basic rule matching
5. **AS_SENDER** - Email delivery (no templates yet)

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure and ECF | Project compiles with dependencies |
| T1.2 | Implement AS_EVENT | Parses JSON, extracts fields |
| T1.3 | Implement AS_CONFIG | Loads JSON config, extracts SMTP/rules |
| T1.4 | Implement AS_ROUTER (basic) | Matches events to rules |
| T1.5 | Implement AS_SENDER (basic) | Sends plain text alerts |
| T1.6 | Implement AS_CLI | Parses args, runs commands |
| T1.7 | Create sample config | Working configuration file |
| T1.8 | Write MVP tests | Core functionality tested |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Parse valid event | Valid JSON | AS_EVENT populated |
| Parse invalid event | Malformed JSON | Error reported |
| Load valid config | Valid JSON file | Config loaded |
| Match rule | Event + rules | Correct rule selected |
| Send alert | Event + SMTP config | Email sent |
| No matching rule | Event, no rules match | Default rule used |

### MVP Commands

```bash
echo '{"source":"test","message":"Hello"}' | alertstream send
alertstream send --message "Test alert" --severity warning
```

---

## Phase 2: Full Implementation

### Objective

Add persistence, deduplication, digests, and templates:
- SQLite event storage
- Deduplication with time windows
- Digest aggregation and delivery
- HTML email templates

### Deliverables

1. **AS_STORE** - SQLite event persistence
2. **AS_DEDUPER** - Deduplication engine
3. **AS_AGGREGATOR** - Digest aggregation
4. **AS_TEMPLATE** - HTML email templates
5. **AS_CLI (enhanced)** - `digest`, `status`, `prune` commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement AS_STORE | SQLite storage working |
| T2.2 | Implement database schema | Tables created correctly |
| T2.3 | Implement AS_DEDUPER | Duplicate detection works |
| T2.4 | Integrate dedup into ingest | Events deduplicated |
| T2.5 | Implement AS_AGGREGATOR | Collects events for digest |
| T2.6 | Implement AS_TEMPLATE | HTML alert and digest templates |
| T2.7 | Implement `digest` command | Sends digest emails |
| T2.8 | Implement `status` command | Shows alert statistics |
| T2.9 | Implement `prune` command | Cleans old events |
| T2.10 | Write full test suite | All features tested |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Store event | AS_EVENT | Event in database |
| Detect duplicate | Same event twice | Second suppressed |
| Dedup window | Event after window | Not duplicate |
| Build digest | 10 events | Digest with 10 events |
| Render alert | AS_EVENT | HTML email body |
| Render digest | List of events | HTML digest body |
| Status query | Last 24h | Statistics returned |
| Prune old | 30 day retention | Old events deleted |

### Full Commands

```bash
alertstream ingest --source prometheus < events.json
alertstream send --severity critical --message "Database down"
alertstream digest --period 6h
alertstream status --last 24h [--json]
alertstream prune --older-than 30d
alertstream rules --list
alertstream rules --test '{"source":"test","event":"disk_full"}'
```

---

## Phase 3: Production Polish

### Objective

Harden for production use:
- Escalation chains
- Comprehensive error handling
- Performance optimization
- Documentation

### Deliverables

1. **AS_ESCALATOR** - Escalation chain management
2. **Error handling** - Comprehensive error messages
3. **Performance** - Connection reuse, batch optimization
4. **Documentation** - README, CHANGELOG

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement AS_ESCALATOR | Escalation chains work |
| T3.2 | Add retry logic | Failed sends retried |
| T3.3 | Implement connection pooling | Single connection per batch |
| T3.4 | Add comprehensive error messages | Clear, actionable messages |
| T3.5 | Add --help for all commands | Help text complete |
| T3.6 | Implement exit codes | Standard exit codes |
| T3.7 | Performance testing | Benchmark throughput |
| T3.8 | Security review | Credential handling, input validation |
| T3.9 | Write README.md | Complete documentation |
| T3.10 | Final test pass | All tests pass |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Configuration error |
| 2 | Delivery failure |
| 3 | Partial success (some alerts sent) |
| 4 | Database error |

---

## ECF Target Structure

```xml
<!-- Library target (reusable) -->
<target name="alertstream">
    <root all_classes="true"/>
    <cluster name="src" location=".\src\" recursive="true"/>
    <!-- Dependencies -->
</target>

<!-- CLI executable target -->
<target name="alertstream_cli" extends="alertstream">
    <root class="AS_CLI" feature="make"/>
    <setting name="executable_name" value="alertstream"/>
</target>

<!-- Test target -->
<target name="alertstream_tests" extends="alertstream">
    <root class="TEST_APP" feature="make"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
    <cluster name="tests" location=".\tests\"/>
</target>
```

---

## Build Commands

```bash
# Set environment
export SIMPLE_EIFFEL=/d/prod

# Compile CLI (workbench for development)
/d/prod/ec.sh -batch -config alertstream.ecf -target alertstream_cli -c_compile

# Compile CLI (finalized for release)
/d/prod/ec.sh -batch -config alertstream.ecf -target alertstream_cli -finalize -c_compile

# Run tests
/d/prod/ec.sh -batch -config alertstream.ecf -target alertstream_tests -c_compile
./EIFGENs/alertstream_tests/W_code/alertstream.exe
```

---

## Directory Structure

```
alertstream/
    alertstream.ecf
    README.md
    CHANGELOG.md
    LICENSE
    src/
        as_cli.e
        as_event.e
        as_config.e
        as_router.e
        as_rule.e
        as_deduper.e
        as_aggregator.e
        as_store.e
        as_sender.e
        as_template.e
        as_escalator.e
    tests/
        test_app.e
        as_tests.e
        test_event.e
        test_router.e
        test_deduper.e
        test_store.e
    templates/
        alert.html
        digest.html
        escalation.html
    examples/
        config.json
        sample-events.json
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| CLI works | All commands | Functional |
| Deduplication | Duplicate reduction | >50% |
| Alert latency | Event to email | <5 seconds |
| Documentation | README complete | Yes |

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| simple_sql not ready | High | Use simple_json for flat file storage |
| High event volume | Medium | Implement batch processing mode |
| SMTP rate limiting | Medium | Add configurable delay between sends |
| Template complexity | Medium | Start with simple HTML, enhance later |

---

## Integration Points

### Prometheus Alertmanager
```bash
# webhook_configs:
#   - url: 'http://localhost:9095/webhook'
# OR pipe to stdin:
curl -s localhost:9093/api/v1/alerts | alertstream ingest --format prometheus
```

### Grafana Alerts
```bash
# Contact point: webhook to alertstream HTTP endpoint
# OR export and pipe:
grafana-cli alerts export | alertstream ingest --format grafana
```

### Custom Scripts
```bash
# Any monitoring script can pipe to alertstream
./check_disk_space.sh | alertstream ingest --source disk-monitor
```

### Cron Integration
```bash
# /etc/cron.d/alertstream-digest
0 * * * * root /usr/local/bin/alertstream digest --period 1h
0 8 * * * root /usr/local/bin/alertstream digest --period 24h --recipients daily@company.com
```
