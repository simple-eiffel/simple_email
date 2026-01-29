# AlertStream - Technical Design

## Architecture

### Component Overview

```
+------------------------------------------------------------------+
|                        AlertStream CLI                            |
+------------------------------------------------------------------+
|  CLI Interface Layer                                              |
|    - Argument parsing                                             |
|    - Command routing (ingest, send, digest, status)               |
|    - Output formatting (text/json)                                |
+------------------------------------------------------------------+
|  Alert Processing Layer                                           |
|    - AS_ROUTER: Rule-based alert routing                          |
|    - AS_DEDUPER: Alert deduplication engine                       |
|    - AS_AGGREGATOR: Digest aggregation                            |
|    - AS_ESCALATOR: Escalation chain management                    |
+------------------------------------------------------------------+
|  Data Layer                                                       |
|    - AS_STORE: Alert event storage (SQLite via simple_sql)        |
|    - AS_CONFIG: Rule and config management                        |
|    - AS_LOGGER: Audit logging                                     |
+------------------------------------------------------------------+
|  Delivery Layer                                                   |
|    - AS_SENDER: Email delivery via simple_email                   |
|    - AS_TEMPLATE: Alert email formatting                          |
+------------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| **AS_CLI** | Command-line interface | parse_command, execute, format_output |
| **AS_EVENT** | Single alert event | parse_json, severity, source, message |
| **AS_ROUTER** | Rule-based routing | match_rules, determine_recipients, classify_severity |
| **AS_DEDUPER** | Deduplication engine | is_duplicate, record_event, get_window |
| **AS_AGGREGATOR** | Digest aggregation | collect_events, build_digest, clear_period |
| **AS_ESCALATOR** | Escalation management | should_escalate, get_escalation_level, notify_escalation |
| **AS_STORE** | Event persistence | store_event, query_events, prune_old |
| **AS_CONFIG** | Configuration | load_rules, get_smtp, get_recipients |
| **AS_SENDER** | Email delivery | send_alert, send_digest, send_escalation |
| **AS_TEMPLATE** | Email formatting | format_alert, format_digest, format_escalation |

### Command Structure

```bash
alertstream <command> [options] [arguments]

Commands:
  ingest        Ingest events from stdin or file
  send          Send single alert immediately
  digest        Generate and send digest of accumulated alerts
  status        Show alert statistics and recent events
  rules         List or test routing rules
  prune         Clean up old events from store

Global Options:
  --config FILE    Configuration file (default: alertstream.json)
  --output FORMAT  Output format: text, json (default: text)
  --verbose        Enable verbose output
  --quiet          Suppress non-error output
  --help           Show help

ingest Options:
  --source NAME    Event source identifier
  --format FORMAT  Input format: json, line, prometheus (default: json)
  --no-dedup       Disable deduplication for this batch

send Options:
  --rule NAME      Apply specific rule
  --severity LEVEL Override severity (critical, warning, info)
  --message TEXT   Alert message (or use stdin)

digest Options:
  --period DURATION  Digest period: 1h, 6h, 24h (default: 1h)
  --recipients EMAILS Override recipients
  --dry-run          Show digest without sending

Examples:
  cat events.json | alertstream ingest --source monitoring
  echo "Database connection failed" | alertstream send --severity critical
  alertstream digest --period 6h
  alertstream status --last 24h
  alertstream rules --test '{"event":"disk_full","host":"web01"}'
```

### Data Flow

```
Event Sources                Rule Matching              Delivery
      |                           |                        |
      v                           v                        v
+----------+    +----------+    +----------+    +----------+
| stdin    |    | AS_EVENT |    | AS_ROUTER|    | AS_SENDER|
| file     |--->| parse    |--->| match    |--->| send     |
| webhook* |    | validate |    | route    |    | email    |
+----------+    +----------+    +----------+    +----------+
                     |               |
                     v               v
              +----------+    +----------+
              | AS_STORE |    | AS_DEDUPER|
              | persist  |<---| check dup |
              +----------+    +----------+
                                   |
                                   v
                            +----------+
                            | AS_AGGR  |
                            | collect  |
                            | digest   |
                            +----------+
```

### Configuration Schema

```json
{
  "alertstream": {
    "version": "1.0",
    "smtp": {
      "host": "smtp.company.com",
      "port": 587,
      "username": "alerts@company.com",
      "password_env": "AS_SMTP_PASSWORD",
      "tls_mode": "starttls",
      "from_address": "alerts@company.com",
      "from_name": "AlertStream"
    },
    "defaults": {
      "recipients": ["oncall@company.com"],
      "severity": "warning",
      "dedup_window_minutes": 30
    },
    "rules": [
      {
        "name": "critical-database",
        "match": {
          "source": "monitoring",
          "message_contains": ["database", "connection", "timeout"]
        },
        "severity": "critical",
        "recipients": ["dba@company.com", "oncall@company.com"],
        "dedup_window_minutes": 5,
        "escalate_after_minutes": 15
      },
      {
        "name": "disk-warnings",
        "match": {
          "event": "disk_usage",
          "threshold_exceeded": true
        },
        "severity": "warning",
        "recipients": ["sysadmin@company.com"],
        "aggregate_digest": true
      },
      {
        "name": "default",
        "match": "*",
        "severity": "info",
        "recipients": ["alerts@company.com"],
        "aggregate_digest": true
      }
    ],
    "escalation": {
      "enabled": true,
      "levels": [
        {"after_minutes": 15, "recipients": ["team-lead@company.com"]},
        {"after_minutes": 30, "recipients": ["manager@company.com"]},
        {"after_minutes": 60, "recipients": ["director@company.com"]}
      ]
    },
    "storage": {
      "database": "alertstream.db",
      "retention_days": 30
    },
    "digest": {
      "schedule": "0 * * * *",
      "min_events": 1,
      "max_events_per_digest": 100
    }
  }
}
```

### Event Format (JSON)

```json
{
  "timestamp": "2026-01-24T10:30:00Z",
  "source": "prometheus",
  "event": "high_cpu",
  "severity": "warning",
  "host": "web-server-01",
  "message": "CPU usage exceeded 90% for 5 minutes",
  "details": {
    "current_value": 94.5,
    "threshold": 90,
    "duration_seconds": 300
  },
  "labels": {
    "environment": "production",
    "service": "api-gateway"
  }
}
```

### Alert Email Template

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    .critical { background-color: #ff4444; color: white; }
    .warning { background-color: #ffaa00; color: black; }
    .info { background-color: #4444ff; color: white; }
  </style>
</head>
<body>
  <div class="{{severity}}">
    <h2>[{{severity | upper}}] {{event}}</h2>
  </div>

  <table>
    <tr><td>Source:</td><td>{{source}}</td></tr>
    <tr><td>Host:</td><td>{{host}}</td></tr>
    <tr><td>Time:</td><td>{{timestamp}}</td></tr>
  </table>

  <h3>Message</h3>
  <p>{{message}}</p>

  {{#if details}}
  <h3>Details</h3>
  <pre>{{details | json}}</pre>
  {{/if}}

  <hr>
  <p style="font-size: 10px;">
    AlertStream | Rule: {{rule_name}} | Event ID: {{event_id}}
  </p>
</body>
</html>
```

### Digest Email Template

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    .summary-table { border-collapse: collapse; }
    .summary-table td, .summary-table th { border: 1px solid #ddd; padding: 8px; }
  </style>
</head>
<body>
  <h1>Alert Digest: {{period}}</h1>
  <p>Generated: {{generated_at}}</p>

  <h2>Summary</h2>
  <table class="summary-table">
    <tr>
      <th>Severity</th>
      <th>Count</th>
    </tr>
    <tr><td style="background:#ff4444;color:white">Critical</td><td>{{critical_count}}</td></tr>
    <tr><td style="background:#ffaa00">Warning</td><td>{{warning_count}}</td></tr>
    <tr><td style="background:#4444ff;color:white">Info</td><td>{{info_count}}</td></tr>
  </table>

  <h2>Events</h2>
  {{#each events}}
  <div style="border-left: 4px solid {{severity_color}}; padding-left: 10px; margin: 10px 0;">
    <strong>{{timestamp}}</strong> - {{source}}<br>
    {{message}}
  </div>
  {{/each}}

  <hr>
  <p style="font-size: 10px;">AlertStream Digest | {{event_count}} events</p>
</body>
</html>
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Invalid event JSON | Skip event, log | "Invalid JSON in event: {error}" |
| No matching rule | Use default rule | "No rule matched, using default" |
| SMTP connection failed | Retry, queue | "SMTP failed, queuing for retry" |
| Duplicate event | Suppress, log | "Duplicate suppressed: {event_id}" |
| Database error | Fail operation | "Database error: {details}" |
| Missing config | Exit with error | "Configuration required: {file}" |

### Database Schema (SQLite)

```sql
CREATE TABLE events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id TEXT UNIQUE NOT NULL,
    timestamp TEXT NOT NULL,
    source TEXT NOT NULL,
    event_type TEXT,
    severity TEXT NOT NULL,
    host TEXT,
    message TEXT NOT NULL,
    details_json TEXT,
    labels_json TEXT,
    rule_matched TEXT,
    status TEXT DEFAULT 'pending',
    dedup_key TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE deliveries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id TEXT NOT NULL,
    delivery_type TEXT NOT NULL,  -- 'immediate', 'digest', 'escalation'
    recipients TEXT NOT NULL,
    sent_at TEXT,
    status TEXT NOT NULL,  -- 'sent', 'failed', 'pending'
    error_message TEXT,
    FOREIGN KEY (event_id) REFERENCES events(event_id)
);

CREATE TABLE escalations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id TEXT NOT NULL,
    level INTEGER NOT NULL,
    escalated_at TEXT NOT NULL,
    acknowledged_at TEXT,
    FOREIGN KEY (event_id) REFERENCES events(event_id)
);

CREATE INDEX idx_events_timestamp ON events(timestamp);
CREATE INDEX idx_events_dedup ON events(dedup_key, timestamp);
CREATE INDEX idx_events_status ON events(status);
```

## GUI/TUI Future Path

**CLI foundation enables:**

- **Shared core:** AS_ROUTER, AS_DEDUPER, AS_AGGREGATOR are UI-agnostic
- **TUI overlay:** simple_tui could provide:
  - Live event stream display
  - Interactive rule editor
  - Alert acknowledgment interface
  - Digest preview
- **GUI overlay:** Future GUI could provide:
  - Dashboard with alert timeline
  - Rule builder with drag-drop
  - Analytics and trending
  - Integration management

**What would change:**
- AS_CLI replaced with event-driven UI handlers
- Real-time event callbacks added to AS_STORE
- Interactive rule testing in AS_ROUTER
- Acknowledgment workflow in AS_ESCALATOR

**Shared components (100% reusable):**
- AS_EVENT
- AS_ROUTER
- AS_DEDUPER
- AS_AGGREGATOR
- AS_STORE
- AS_SENDER
- AS_TEMPLATE
