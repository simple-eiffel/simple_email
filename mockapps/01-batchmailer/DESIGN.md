# BatchMailer - Technical Design

## Architecture

### Component Overview

```
+------------------------------------------------------------------+
|                         BatchMailer CLI                           |
+------------------------------------------------------------------+
|  CLI Interface Layer                                              |
|    - Argument parsing (simple_cli)                                |
|    - Command routing                                              |
|    - Output formatting (text/json)                                |
+------------------------------------------------------------------+
|  Business Logic Layer                                             |
|    - BM_ENGINE: Orchestrates batch sending                        |
|    - BM_TEMPLATE: Template loading and variable expansion         |
|    - BM_RECIPIENTS: Recipient list management                     |
|    - BM_SCHEDULER: Schedule parsing and next-run calculation      |
+------------------------------------------------------------------+
|  Data Layer                                                       |
|    - BM_CONFIG: Configuration management (simple_json)            |
|    - BM_LOGGER: Delivery logging (simple_json)                    |
|    - BM_REPORT: Delivery report generation                        |
+------------------------------------------------------------------+
|  Integration Layer                                                |
|    - simple_email: SMTP sending                                   |
|    - simple_csv: CSV recipient lists                              |
|    - simple_json: Config and logging                              |
|    - simple_template: Email templates                             |
|    - simple_file: Attachment handling                             |
|    - simple_scheduler: Schedule expressions                       |
+------------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| **BM_CLI** | Command-line interface | parse_args, execute_command, format_output |
| **BM_ENGINE** | Core batch orchestration | run_batch, process_recipient, track_delivery |
| **BM_CONFIG** | Configuration management | load_config, validate_config, get_smtp_settings |
| **BM_TEMPLATE** | Template processing | load_template, expand_variables, validate_syntax |
| **BM_RECIPIENTS** | Recipient list handling | load_csv, load_json, validate_addresses |
| **BM_ATTACHMENT** | Attachment management | resolve_paths, validate_files, mime_type |
| **BM_LOGGER** | Delivery logging | log_send, log_error, generate_report |
| **BM_SCHEDULER** | Schedule management | parse_schedule, next_run_time, is_due |

### Command Structure

```bash
batchmailer <command> [options] [arguments]

Commands:
  send          Send emails using a job configuration
  test          Send test email to verify configuration
  validate      Validate job configuration without sending
  list          List configured jobs
  status        Show status of recent job runs
  report        Generate delivery report for a job run

Global Options:
  --config FILE    Configuration file (default: batchmailer.json)
  --output FORMAT  Output format: text, json (default: text)
  --verbose        Enable verbose output
  --quiet          Suppress non-error output
  --help           Show help
  --version        Show version

send Options:
  --job NAME       Job name from configuration
  --dry-run        Process without sending emails
  --limit N        Limit to first N recipients
  --recipient EMAIL  Send to single recipient (for testing)

Examples:
  batchmailer send --job daily-sales-report
  batchmailer send --job weekly-kpi --dry-run
  batchmailer test --job monthly-compliance --recipient admin@company.com
  batchmailer validate --config production.json
  batchmailer report --job daily-sales-report --date 2026-01-23
```

### Data Flow

```
Configuration     Recipients        Template          Attachments
     |                |                |                  |
     v                v                v                  v
+----------+    +-----------+    +------------+    +------------+
| Load     |    | Load CSV/ |    | Load       |    | Resolve    |
| Config   |    | JSON list |    | Template   |    | file paths |
+----------+    +-----------+    +------------+    +------------+
     |                |                |                  |
     v                v                v                  v
+------------------------------------------------------------------+
|                    BM_ENGINE.run_batch                            |
|  +------------------------------------------------------------+  |
|  |  For each recipient:                                        |  |
|  |    1. Expand template with recipient data                   |  |
|  |    2. Attach files (if configured)                          |  |
|  |    3. Send via SMTP (simple_email)                          |  |
|  |    4. Log result (success/failure)                          |  |
|  |    5. Handle retry on transient failure                     |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
     |
     v
+----------+
| Delivery |
| Report   |
+----------+
```

### Configuration Schema

```json
{
  "batchmailer": {
    "version": "1.0",
    "smtp": {
      "host": "smtp.company.com",
      "port": 587,
      "username": "reports@company.com",
      "password_env": "BM_SMTP_PASSWORD",
      "tls_mode": "starttls",
      "timeout_seconds": 60
    },
    "defaults": {
      "from_address": "reports@company.com",
      "from_name": "Company Reports",
      "reply_to": "noreply@company.com"
    },
    "jobs": {
      "daily-sales-report": {
        "template": "templates/daily-sales.html",
        "recipients": "recipients/sales-managers.csv",
        "subject": "Daily Sales Report - {{date}}",
        "attachments": [
          "reports/daily-sales-{{date}}.pdf"
        ],
        "schedule": "0 8 * * *",
        "retry": {
          "attempts": 3,
          "delay_seconds": 300
        }
      },
      "weekly-kpi": {
        "template": "templates/weekly-kpi.html",
        "recipients": "recipients/executives.json",
        "subject": "Weekly KPI Dashboard - Week {{week}}",
        "attachments": [
          "reports/kpi-week-{{week}}.xlsx"
        ],
        "schedule": "0 9 * * 1"
      }
    },
    "logging": {
      "directory": "logs/",
      "retention_days": 90,
      "format": "json"
    }
  }
}
```

### Template Format

```html
<!-- templates/daily-sales.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
</head>
<body>
  <h1>Daily Sales Report</h1>
  <p>Hello {{first_name}},</p>

  <p>Please find attached the daily sales report for {{date}}.</p>

  <p>Key highlights for your region ({{region}}):</p>
  <ul>
    <li>Total Sales: {{total_sales}}</li>
    <li>New Customers: {{new_customers}}</li>
    <li>Target Progress: {{target_progress}}%</li>
  </ul>

  <p>Best regards,<br>
  The Reporting Team</p>

  {{#if unsubscribe_link}}
  <p style="font-size: 10px; color: #666;">
    <a href="{{unsubscribe_link}}">Unsubscribe</a>
  </p>
  {{/if}}
</body>
</html>
```

### Recipient List Format (CSV)

```csv
email,first_name,last_name,region,total_sales,new_customers,target_progress
alice@company.com,Alice,Johnson,Northeast,125000,45,112
bob@company.com,Bob,Smith,Southeast,98000,32,89
carol@company.com,Carol,Williams,Midwest,145000,51,105
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| SMTP connection failed | Retry with backoff | "SMTP connection failed: {details}. Retrying in {n} seconds." |
| Authentication failed | Stop job, alert | "SMTP authentication failed. Check credentials." |
| Template not found | Stop job | "Template file not found: {path}" |
| Recipients file invalid | Stop job | "Invalid recipients file: {error}" |
| Attachment not found | Skip recipient, log | "Attachment not found for {email}: {path}" |
| Invalid email address | Skip recipient, log | "Invalid email address skipped: {address}" |
| SMTP send failed | Retry per config | "Send failed for {email}: {error}. Attempt {n}/{max}" |
| Rate limit hit | Pause, retry | "Rate limit reached. Pausing for {n} seconds." |

### Delivery Log Format

```json
{
  "job": "daily-sales-report",
  "run_id": "20260124-080000-abc123",
  "started_at": "2026-01-24T08:00:00Z",
  "completed_at": "2026-01-24T08:02:34Z",
  "status": "completed",
  "summary": {
    "total": 45,
    "sent": 44,
    "failed": 1,
    "skipped": 0
  },
  "recipients": [
    {
      "email": "alice@company.com",
      "status": "sent",
      "sent_at": "2026-01-24T08:00:12Z",
      "message_id": "<abc123@company.com>"
    },
    {
      "email": "invalid@",
      "status": "failed",
      "error": "Invalid email address",
      "attempts": 1
    }
  ]
}
```

## GUI/TUI Future Path

**CLI foundation enables:**

- **Shared core:** BM_ENGINE, BM_TEMPLATE, BM_RECIPIENTS are UI-agnostic
- **TUI overlay:** simple_tui could provide:
  - Interactive job selection
  - Real-time sending progress
  - Template preview with sample data
  - Recipient list browser
- **GUI overlay:** Future simple_gui could provide:
  - Visual template editor with drag-drop
  - Calendar-based schedule configuration
  - Delivery analytics dashboard
  - Recipient segmentation interface

**What would change for TUI/GUI:**
- BM_CLI replaced with TUI/GUI event handlers
- Progress callbacks added to BM_ENGINE
- Template preview mode in BM_TEMPLATE
- Interactive recipient selection in BM_RECIPIENTS

**Shared components (reusable across CLI/TUI/GUI):**
- BM_ENGINE (100% reusable)
- BM_CONFIG (100% reusable)
- BM_TEMPLATE (100% reusable)
- BM_RECIPIENTS (100% reusable)
- BM_LOGGER (100% reusable)
