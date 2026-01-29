# MailMerge Pro - Technical Design

## Architecture

### Component Overview

```
+------------------------------------------------------------------+
|                       MailMerge Pro CLI                           |
+------------------------------------------------------------------+
|  CLI Interface Layer                                              |
|    - Argument parsing                                             |
|    - Command routing (send, preview, validate, report)            |
|    - Progress display                                             |
|    - Output formatting (text/json)                                |
+------------------------------------------------------------------+
|  Campaign Processing Layer                                        |
|    - MM_ENGINE: Campaign orchestration                            |
|    - MM_TEMPLATE: Variable expansion with conditionals            |
|    - MM_DATA: Data source loading (CSV/JSON)                      |
|    - MM_VALIDATOR: Data and template validation                   |
+------------------------------------------------------------------+
|  Tracking Layer                                                   |
|    - MM_TRACKER: Delivery tracking                                |
|    - MM_REPORT: Campaign reporting                                |
+------------------------------------------------------------------+
|  Delivery Layer                                                   |
|    - MM_SENDER: Email delivery via simple_email                   |
|    - MM_THROTTLE: Rate limiting and delays                        |
+------------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| **MM_CLI** | Command-line interface | parse_args, execute, show_progress |
| **MM_ENGINE** | Campaign orchestration | run_campaign, process_recipient, handle_errors |
| **MM_CONFIG** | Configuration management | load_config, validate_smtp, get_settings |
| **MM_TEMPLATE** | Template processing | load, expand, validate_syntax, list_variables |
| **MM_DATA** | Data source handling | load_csv, load_json, get_headers, iterate |
| **MM_RECIPIENT** | Single recipient record | fields, get_value, is_valid |
| **MM_VALIDATOR** | Validation engine | validate_data, validate_template, check_required |
| **MM_SENDER** | Email delivery | send_message, handle_bounce |
| **MM_THROTTLE** | Rate control | should_delay, record_send, reset |
| **MM_TRACKER** | Delivery tracking | track_send, track_error, get_summary |
| **MM_REPORT** | Report generation | generate_report, export_csv, export_json |

### Command Structure

```bash
mailmerge <command> [options] [arguments]

Commands:
  send          Send personalized emails
  preview       Preview personalized content for specific recipients
  validate      Validate template and data without sending
  report        Generate campaign delivery report

Global Options:
  --config FILE    Configuration file (default: mailmerge.json)
  --output FORMAT  Output format: text, json (default: text)
  --verbose        Enable verbose output
  --quiet          Suppress non-error output
  --help           Show help
  --version        Show version

send Options:
  --template FILE  Email template file (HTML or text)
  --data FILE      Recipient data file (CSV or JSON)
  --subject TEXT   Email subject (supports variables)
  --from EMAIL     Sender address (overrides config)
  --attach PATTERN File attachment pattern (supports variables)
  --limit N        Send to first N recipients only
  --skip N         Skip first N recipients
  --delay DURATION Delay between sends (e.g., 10s, 1m)
  --dry-run        Process without sending
  --resume ID      Resume from interrupted campaign

preview Options:
  --template FILE  Email template file
  --data FILE      Recipient data file
  --recipient N    Preview for recipient at row N (1-based)
  --email EMAIL    Preview for recipient with this email
  --all            Preview all recipients

validate Options:
  --template FILE  Email template file
  --data FILE      Recipient data file
  --strict         Fail on any warning

report Options:
  --campaign ID    Campaign ID to report on
  --format FORMAT  Report format: text, csv, json, html
  --output FILE    Output file (default: stdout)

Examples:
  mailmerge send --template welcome.html --data new-users.csv
  mailmerge send --template offer.html --data leads.json --delay 30s --limit 100
  mailmerge preview --template welcome.html --data users.csv --recipient 5
  mailmerge validate --template monthly.html --data subscribers.csv --strict
  mailmerge report --campaign 20260124-abc123 --format html --output report.html
```

### Data Flow

```
Data Source          Template            Configuration
     |                  |                     |
     v                  v                     v
+----------+      +-----------+         +-----------+
| Load CSV |      | Load      |         | Load      |
| or JSON  |      | Template  |         | Config    |
+----------+      +-----------+         +-----------+
     |                  |                     |
     v                  v                     v
+------------------------------------------------------------------+
|                    MM_ENGINE.run_campaign                         |
|  +------------------------------------------------------------+  |
|  |  For each recipient:                                        |  |
|  |    1. Extract recipient data (MM_RECIPIENT)                 |  |
|  |    2. Expand template with data (MM_TEMPLATE)               |  |
|  |    3. Expand subject with data (MM_TEMPLATE)                |  |
|  |    4. Resolve attachments (if any)                          |  |
|  |    5. Apply throttling (MM_THROTTLE)                        |  |
|  |    6. Send email (MM_SENDER via simple_email)               |  |
|  |    7. Track delivery (MM_TRACKER)                           |  |
|  |    8. Update progress display                               |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
     |
     v
+----------+
| Campaign |
| Report   |
+----------+
```

### Configuration Schema

```json
{
  "mailmerge": {
    "version": "1.0",
    "smtp": {
      "host": "smtp.company.com",
      "port": 587,
      "username": "campaigns@company.com",
      "password_env": "MM_SMTP_PASSWORD",
      "tls_mode": "starttls",
      "timeout_seconds": 60
    },
    "defaults": {
      "from_address": "campaigns@company.com",
      "from_name": "Company Name",
      "reply_to": "support@company.com"
    },
    "throttle": {
      "delay_seconds": 0,
      "max_per_hour": 500,
      "max_per_day": 5000
    },
    "tracking": {
      "directory": "campaigns/",
      "retention_days": 90
    },
    "templates": {
      "directory": "templates/",
      "default_format": "html"
    }
  }
}
```

### Template Format

```html
<!-- templates/welcome.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
</head>
<body>
  <h1>Welcome, {{first_name}}!</h1>

  <p>Thank you for joining {{company_name}}. We're excited to have you!</p>

  {{#if has_promo_code}}
  <div style="background: #f0f0f0; padding: 20px; margin: 20px 0;">
    <h2>Your Welcome Offer</h2>
    <p>Use code <strong>{{promo_code}}</strong> for {{discount}}% off your first order!</p>
  </div>
  {{/if}}

  <h2>What's Next?</h2>
  <ul>
    <li>Complete your profile: <a href="{{profile_url}}">Click here</a></li>
    <li>Browse our products: <a href="{{shop_url}}">Shop now</a></li>
    {{#if assigned_rep}}
    <li>Your account rep: {{assigned_rep}} ({{rep_email}})</li>
    {{/if}}
  </ul>

  {{#each recent_products}}
  <div style="border: 1px solid #ddd; padding: 10px; margin: 10px 0;">
    <strong>{{name}}</strong> - ${{price}}
  </div>
  {{/each}}

  <p>Best regards,<br>
  The {{company_name}} Team</p>

  <hr>
  <p style="font-size: 10px; color: #666;">
    {{unsubscribe_link}}
  </p>
</body>
</html>
```

### Data Format (CSV)

```csv
email,first_name,last_name,company_name,has_promo_code,promo_code,discount,profile_url,shop_url,assigned_rep,rep_email
alice@example.com,Alice,Johnson,Acme Inc,true,WELCOME20,20,https://acme.com/profile/alice,https://acme.com/shop,Bob Smith,bob@acme.com
carol@example.com,Carol,Williams,Acme Inc,false,,,https://acme.com/profile/carol,https://acme.com/shop,,
```

### Data Format (JSON)

```json
{
  "recipients": [
    {
      "email": "alice@example.com",
      "first_name": "Alice",
      "last_name": "Johnson",
      "company_name": "Acme Inc",
      "has_promo_code": true,
      "promo_code": "WELCOME20",
      "discount": 20,
      "profile_url": "https://acme.com/profile/alice",
      "assigned_rep": "Bob Smith",
      "rep_email": "bob@acme.com"
    }
  ]
}
```

### Template Syntax

| Syntax | Description | Example |
|--------|-------------|---------|
| `{{variable}}` | Simple variable | `{{first_name}}` |
| `{{variable \| filter}}` | Variable with filter | `{{name \| upper}}` |
| `{{#if condition}}...{{/if}}` | Conditional block | `{{#if has_discount}}...{{/if}}` |
| `{{#unless condition}}...{{/unless}}` | Negated conditional | `{{#unless unsubscribed}}...{{/unless}}` |
| `{{#each list}}...{{/each}}` | Loop over list | `{{#each products}}...{{/each}}` |
| `{{default variable "fallback"}}` | Default value | `{{default title "Customer"}}` |

### Available Filters

| Filter | Description | Example |
|--------|-------------|---------|
| `upper` | Uppercase | `{{name \| upper}}` -> ALICE |
| `lower` | Lowercase | `{{name \| lower}}` -> alice |
| `title` | Title case | `{{name \| title}}` -> Alice |
| `trim` | Trim whitespace | `{{text \| trim}}` |
| `truncate:N` | Truncate to N chars | `{{desc \| truncate:50}}` |
| `date:FORMAT` | Format date | `{{date \| date:'%Y-%m-%d'}}` |
| `currency` | Format as currency | `{{amount \| currency}}` -> $1,234.56 |

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Template not found | Stop | "Template file not found: {path}" |
| Data file not found | Stop | "Data file not found: {path}" |
| Invalid template syntax | Stop | "Template error at line {n}: {error}" |
| Missing required variable | Skip recipient | "Missing required field '{field}' for {email}" |
| Invalid email address | Skip recipient | "Invalid email address: {address}" |
| SMTP send failed | Retry/skip | "Send failed for {email}: {error}" |
| Rate limit exceeded | Pause | "Rate limit reached, pausing for {n} seconds" |
| Attachment not found | Skip attachment | "Attachment not found: {path}" |

### Campaign Tracking Format

```json
{
  "campaign_id": "20260124-abc123",
  "template": "welcome.html",
  "data_source": "new-users.csv",
  "started_at": "2026-01-24T10:00:00Z",
  "completed_at": "2026-01-24T10:05:23Z",
  "status": "completed",
  "summary": {
    "total": 150,
    "sent": 148,
    "failed": 1,
    "skipped": 1
  },
  "deliveries": [
    {
      "email": "alice@example.com",
      "status": "sent",
      "sent_at": "2026-01-24T10:00:02Z",
      "message_id": "<abc123@company.com>"
    },
    {
      "email": "invalid@",
      "status": "skipped",
      "reason": "Invalid email address"
    },
    {
      "email": "bob@example.com",
      "status": "failed",
      "error": "SMTP timeout",
      "attempts": 3
    }
  ]
}
```

## GUI/TUI Future Path

**CLI foundation enables:**

- **Shared core:** MM_ENGINE, MM_TEMPLATE, MM_DATA are UI-agnostic
- **TUI overlay:** simple_tui could provide:
  - Interactive campaign wizard
  - Real-time send progress
  - Template preview with live data
  - Data browser with filtering
- **GUI overlay:** Future GUI could provide:
  - Visual template editor
  - Drag-drop data source configuration
  - Campaign analytics dashboard
  - A/B testing interface

**What would change:**
- MM_CLI replaced with UI event handlers
- Progress callbacks added to MM_ENGINE
- Preview mode in MM_TEMPLATE
- Pagination in MM_DATA

**Shared components (100% reusable):**
- MM_ENGINE
- MM_TEMPLATE
- MM_DATA
- MM_VALIDATOR
- MM_SENDER
- MM_TRACKER
- MM_REPORT
