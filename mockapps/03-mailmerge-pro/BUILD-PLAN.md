# MailMerge Pro - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 4 days | simple_email, simple_csv, simple_json |
| Phase 2 | Full CLI | 5 days | Phase 1, simple_template, simple_file |
| Phase 3 | Polish | 3 days | Phase 2 complete |

---

## Phase 1: MVP

### Objective

Deliver a functional CLI that can:
- Load recipient data from CSV
- Perform basic variable substitution
- Send personalized emails
- Track deliveries

### Deliverables

1. **MM_CLI** - Command-line interface with `send` command
2. **MM_CONFIG** - JSON configuration loader
3. **MM_DATA** - CSV data loader
4. **MM_RECIPIENT** - Recipient data container
5. **MM_ENGINE** - Core send loop
6. **MM_TRACKER** - Basic delivery tracking

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure and ECF | Project compiles with dependencies |
| T1.2 | Implement MM_CONFIG | Loads JSON, extracts SMTP settings |
| T1.3 | Implement MM_DATA (CSV) | Loads CSV, creates recipient list |
| T1.4 | Implement MM_RECIPIENT | Holds recipient data, provides access |
| T1.5 | Implement basic template expansion | Simple {{variable}} replacement |
| T1.6 | Implement MM_ENGINE | Sends to each recipient |
| T1.7 | Implement MM_TRACKER | Logs each delivery |
| T1.8 | Implement MM_CLI | Parses args, runs send |
| T1.9 | Create sample files | Config, CSV, template examples |
| T1.10 | Write MVP tests | Core functionality tested |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Load valid config | Valid JSON | Config populated |
| Load valid CSV | 5-row CSV | 5 recipients |
| Basic expansion | "Hello {{name}}" + {name: "Alice"} | "Hello Alice" |
| Send single | 1 recipient | Email sent, logged |
| Send batch | 5 recipients | 5 emails sent, all logged |
| Invalid email | Malformed address | Skipped, logged |

### MVP Command

```bash
mailmerge send --config config.json --template welcome.txt --data users.csv
```

---

## Phase 2: Full Implementation

### Objective

Add advanced template features, attachments, and reporting:
- Conditional blocks ({{#if}})
- Loops ({{#each}})
- Filters ({{| upper}})
- Attachments with variable paths
- Preview mode
- Campaign reports

### Deliverables

1. **MM_TEMPLATE** - Full template processor
2. **MM_DATA (JSON)** - JSON data source support
3. **MM_VALIDATOR** - Template and data validation
4. **MM_ATTACHMENT** - Attachment resolution
5. **MM_REPORT** - Campaign report generation
6. **MM_THROTTLE** - Rate limiting
7. **MM_CLI (enhanced)** - All commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement MM_TEMPLATE (conditionals) | {{#if}} works |
| T2.2 | Implement MM_TEMPLATE (loops) | {{#each}} works |
| T2.3 | Implement MM_TEMPLATE (filters) | Filters work |
| T2.4 | Implement MM_DATA (JSON) | JSON loading works |
| T2.5 | Implement MM_VALIDATOR | Validates template vs data |
| T2.6 | Implement MM_ATTACHMENT | Resolves attachment paths |
| T2.7 | Implement MM_THROTTLE | Rate limiting works |
| T2.8 | Implement `preview` command | Shows expanded content |
| T2.9 | Implement `validate` command | Validates without sending |
| T2.10 | Implement MM_REPORT | Generates campaign reports |
| T2.11 | Implement `report` command | Outputs delivery report |
| T2.12 | Add --dry-run mode | Processes without sending |
| T2.13 | Add --limit and --skip | Partial campaign support |
| T2.14 | Write full test suite | All features tested |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Conditional true | {{#if premium}}...{{/if}} + {premium: true} | Content shown |
| Conditional false | {{#if premium}}...{{/if}} + {premium: false} | Content hidden |
| Loop expansion | {{#each items}}{{name}}{{/each}} | Items listed |
| Filter upper | {{name \| upper}} + {name: "alice"} | "ALICE" |
| Filter default | {{default title "Guest"}} + {} | "Guest" |
| JSON data | JSON file | Recipients loaded |
| Validation pass | Matching template/data | No errors |
| Validation fail | Missing variable | Error reported |
| Preview | Recipient + template | Expanded content shown |
| Dry run | Full campaign | 0 emails sent, full log |
| Report | Campaign ID | Formatted report |

### Full Commands

```bash
mailmerge send --template welcome.html --data users.csv [--attach "files/{{id}}.pdf"]
mailmerge preview --template welcome.html --data users.csv --recipient 5
mailmerge validate --template welcome.html --data users.csv --strict
mailmerge report --campaign 20260124-abc123 --format html
```

---

## Phase 3: Production Polish

### Objective

Harden for production use:
- Comprehensive error messages
- Connection reuse optimization
- Resume interrupted campaigns
- Full documentation

### Deliverables

1. **Error handling** - Clear, actionable messages
2. **Performance** - Connection reuse, batch optimization
3. **Resume capability** - Continue interrupted campaigns
4. **Progress display** - Real-time progress bar
5. **Documentation** - README, examples

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement connection reuse | Single connection per batch |
| T3.2 | Add progress display | Shows X/Y during send |
| T3.3 | Implement --resume | Continues from interruption |
| T3.4 | Add comprehensive error messages | Clear, actionable |
| T3.5 | Implement exit codes | Standard codes |
| T3.6 | Add --help for all commands | Help complete |
| T3.7 | Performance testing | Benchmark throughput |
| T3.8 | Security review | Credential handling |
| T3.9 | Write README.md | Usage, examples |
| T3.10 | Create template library | 5+ professional templates |
| T3.11 | Final test pass | All tests pass |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - all emails sent |
| 1 | Configuration error |
| 2 | Data/template error |
| 3 | Partial success - some sent, some failed |
| 4 | Complete failure - no emails sent |

---

## ECF Target Structure

```xml
<!-- Library target (reusable) -->
<target name="mailmerge">
    <root all_classes="true"/>
    <cluster name="src" location=".\src\" recursive="true"/>
    <!-- Dependencies -->
</target>

<!-- CLI executable target -->
<target name="mailmerge_cli" extends="mailmerge">
    <root class="MM_CLI" feature="make"/>
    <setting name="executable_name" value="mailmerge"/>
</target>

<!-- Test target -->
<target name="mailmerge_tests" extends="mailmerge">
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
/d/prod/ec.sh -batch -config mailmerge.ecf -target mailmerge_cli -c_compile

# Compile CLI (finalized for release)
/d/prod/ec.sh -batch -config mailmerge.ecf -target mailmerge_cli -finalize -c_compile

# Run tests
/d/prod/ec.sh -batch -config mailmerge.ecf -target mailmerge_tests -c_compile
./EIFGENs/mailmerge_tests/W_code/mailmerge.exe
```

---

## Directory Structure

```
mailmerge/
    mailmerge.ecf
    README.md
    CHANGELOG.md
    LICENSE
    src/
        mm_cli.e
        mm_config.e
        mm_engine.e
        mm_data.e
        mm_recipient.e
        mm_template.e
        mm_validator.e
        mm_attachment.e
        mm_sender.e
        mm_throttle.e
        mm_tracker.e
        mm_report.e
    tests/
        test_app.e
        mm_tests.e
        test_data.e
        test_template.e
        test_engine.e
    templates/
        welcome.html
        newsletter.html
        notification.html
        receipt.html
        reminder.html
    examples/
        config.json
        sample-recipients.csv
        sample-recipients.json
    campaigns/
        (generated tracking files)
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| CLI works | All commands | Functional |
| Variable expansion | Accuracy | 100% |
| Throughput | Emails per hour | >500 |
| Documentation | README complete | Yes |

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| simple_template limited | High | Implement custom template engine |
| Large CSV files | Medium | Stream processing, not load all |
| SMTP rate limiting | Medium | Implement adaptive throttling |
| Template syntax errors | Medium | Clear error messages with line numbers |

---

## Template Library (Phase 3)

| Template | Use Case | Variables |
|----------|----------|-----------|
| welcome.html | New user onboarding | first_name, company, login_url |
| newsletter.html | Regular updates | title, articles[], unsubscribe_url |
| notification.html | System alerts | event, description, action_url |
| receipt.html | Purchase confirmation | items[], total, order_id |
| reminder.html | Event reminders | event_name, date, location |

---

## Usage Examples

### Basic Campaign
```bash
mailmerge send --template welcome.html --data users.csv
```

### With Throttling
```bash
mailmerge send --template offer.html --data leads.csv --delay 30s
```

### Preview Before Send
```bash
mailmerge preview --template welcome.html --data users.csv --recipient 1
mailmerge send --template welcome.html --data users.csv --dry-run
mailmerge send --template welcome.html --data users.csv
```

### With Attachments
```bash
mailmerge send --template invoice.html --data customers.csv \
               --attach "invoices/{{customer_id}}.pdf"
```

### Partial Campaign
```bash
# Send to first 100
mailmerge send --template promo.html --data all-users.csv --limit 100

# Send to next 100
mailmerge send --template promo.html --data all-users.csv --skip 100 --limit 100
```

### Generate Report
```bash
mailmerge report --campaign 20260124-abc123 --format html --output report.html
```
