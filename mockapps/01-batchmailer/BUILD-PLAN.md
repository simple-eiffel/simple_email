# BatchMailer - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 5 days | simple_email, simple_csv, simple_json |
| Phase 2 | Full CLI | 4 days | Phase 1, simple_template, simple_file |
| Phase 3 | Polish | 3 days | Phase 2 complete |

---

## Phase 1: MVP

### Objective

Deliver a functional CLI that can:
- Load configuration from JSON
- Load recipients from CSV
- Send basic emails with text body
- Log delivery results

### Deliverables

1. **BM_CLI** - Command-line interface with `send` command
2. **BM_CONFIG** - JSON configuration loader
3. **BM_RECIPIENTS** - CSV recipient loader
4. **BM_ENGINE** - Core send loop (no templates yet)
5. **BM_LOGGER** - Basic JSON logging

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure and ECF | Project compiles with dependencies |
| T1.2 | Implement BM_CONFIG | Loads JSON, extracts SMTP settings |
| T1.3 | Implement BM_RECIPIENTS | Loads CSV, creates recipient list |
| T1.4 | Implement BM_ENGINE (basic) | Sends email to each recipient |
| T1.5 | Implement BM_LOGGER | Writes JSON log file |
| T1.6 | Implement BM_CLI | Parses args, runs send command |
| T1.7 | Create sample config and recipients | Working example files |
| T1.8 | Write MVP tests | All basic flows tested |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Load valid config | Valid JSON file | Config object populated |
| Load invalid config | Missing SMTP host | Config error reported |
| Load valid CSV | 3-row CSV | 3 recipients loaded |
| Load invalid CSV | Empty file | Zero recipients, warning |
| Send single email | 1 recipient, valid SMTP | Email sent, logged |
| Send batch | 5 recipients | 5 emails sent, all logged |
| Handle SMTP error | Invalid credentials | Error logged, non-zero exit |

### MVP Command

```bash
batchmailer send --config config.json --job test-job
```

---

## Phase 2: Full Implementation

### Objective

Add template support, attachment handling, and advanced features:
- Template variable expansion
- File attachments
- Retry logic
- Dry-run mode
- Progress reporting

### Deliverables

1. **BM_TEMPLATE** - Template loading and expansion
2. **BM_ATTACHMENT** - Attachment resolution and validation
3. **BM_ENGINE (enhanced)** - Retry logic, progress callbacks
4. **BM_CLI (enhanced)** - All commands, options

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement BM_TEMPLATE | Loads template, expands variables |
| T2.2 | Implement BM_ATTACHMENT | Resolves paths, validates files |
| T2.3 | Add retry logic to BM_ENGINE | Retries on transient failures |
| T2.4 | Add dry-run mode | Shows what would be sent |
| T2.5 | Add progress reporting | Shows X/Y sent during batch |
| T2.6 | Implement `test` command | Send single test email |
| T2.7 | Implement `validate` command | Validate config without sending |
| T2.8 | Implement `status` command | Show recent job runs |
| T2.9 | Implement `report` command | Generate delivery report |
| T2.10 | Write full test suite | All features tested |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Expand template | Template + data | Variables replaced |
| Missing variable | Template references {{missing}} | Fallback or error |
| Resolve attachment | Pattern with {{date}} | Correct path |
| Missing attachment | Non-existent file | Warning, send continues |
| Retry success | Transient failure, then success | Delivered on retry |
| Retry exhausted | Permanent failure | Logged as failed |
| Dry run | 10 recipients | Shows 10 would be sent, 0 sent |
| Test command | Single email | One email sent |

### Full Commands

```bash
batchmailer send --job daily-report [--dry-run] [--limit N]
batchmailer test --job daily-report --recipient test@example.com
batchmailer validate --config production.json
batchmailer status [--job NAME] [--days N]
batchmailer report --job daily-report --date 2026-01-23
```

---

## Phase 3: Production Polish

### Objective

Harden for production use:
- Comprehensive error messages
- Help documentation
- Performance optimization
- Configuration validation
- Exit codes

### Deliverables

1. **Error messages** - Human-readable, actionable
2. **Help system** - --help for all commands
3. **Exit codes** - Standard codes for scripting
4. **Performance** - Connection reuse, batch optimization
5. **Documentation** - README, CHANGELOG

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement connection reuse | Single SMTP connection per batch |
| T3.2 | Add comprehensive error messages | All errors have clear messages |
| T3.3 | Implement exit codes | 0=success, 1=error, 2=partial |
| T3.4 | Add --help for all commands | Help text for every command |
| T3.5 | Add config validation | Pre-flight checks before send |
| T3.6 | Performance testing | 1000+ emails/hour verified |
| T3.7 | Security review | Credentials handling, TLS |
| T3.8 | Write README.md | Usage, examples, configuration |
| T3.9 | Write CHANGELOG.md | Version history |
| T3.10 | Final test pass | All tests pass, manual QA |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - all emails sent |
| 1 | Error - configuration invalid or fatal error |
| 2 | Partial - some emails sent, some failed |
| 3 | No-op - dry run completed, no emails sent |

---

## ECF Target Structure

```xml
<!-- Library target (reusable) -->
<target name="batchmailer">
    <root all_classes="true"/>
    <cluster name="src" location=".\src\" recursive="true"/>
    <!-- Dependencies -->
</target>

<!-- CLI executable target -->
<target name="batchmailer_cli" extends="batchmailer">
    <root class="BM_CLI" feature="make"/>
    <setting name="executable_name" value="batchmailer"/>
</target>

<!-- Test target -->
<target name="batchmailer_tests" extends="batchmailer">
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
/d/prod/ec.sh -batch -config batchmailer.ecf -target batchmailer_cli -c_compile

# Compile CLI (finalized for release)
/d/prod/ec.sh -batch -config batchmailer.ecf -target batchmailer_cli -finalize -c_compile

# Run tests
/d/prod/ec.sh -batch -config batchmailer.ecf -target batchmailer_tests -c_compile
./EIFGENs/batchmailer_tests/W_code/batchmailer.exe
```

---

## Directory Structure

```
batchmailer/
    batchmailer.ecf
    README.md
    CHANGELOG.md
    LICENSE
    src/
        bm_cli.e
        bm_config.e
        bm_engine.e
        bm_recipients.e
        bm_template.e
        bm_attachment.e
        bm_logger.e
        bm_job.e
        bm_recipient.e
    tests/
        test_app.e
        bm_tests.e
        test_config.e
        test_recipients.e
        test_template.e
        test_engine.e
    examples/
        config.json
        recipients.csv
        templates/
            welcome.html
            report.html
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| CLI works | All commands | Functional |
| Documentation | README complete | Yes |
| Performance | Emails per hour | >1000 |
| Reliability | Success rate | >99% |

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| simple_template not ready | High | Use simple string replacement initially |
| SMTP rate limiting | Medium | Implement configurable delay between sends |
| Large attachment handling | Medium | Test with realistic file sizes early |
| Character encoding issues | Medium | Use simple_encoding for validation |
