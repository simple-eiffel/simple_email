# AlertStream - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| **simple_email** | SMTP email delivery | AS_SENDER sends alerts and digests |
| **simple_json** | Event parsing, configuration | AS_EVENT, AS_CONFIG, AS_STORE |
| **simple_sql** | Event persistence | AS_STORE uses SQLite for event storage |
| **simple_template** | Alert email formatting | AS_TEMPLATE renders HTML emails |
| **simple_scheduler** | Digest scheduling | Digest cron expression parsing |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| **simple_config** | Hierarchical config | Environment variable interpolation |
| **simple_cli** | Advanced argument parsing | Complex CLI options |
| **simple_http** | Webhook receiver | HTTP endpoint for events (future) |
| **simple_datetime** | Time calculations | Dedup windows, digest periods |

## Integration Patterns

### simple_email Integration

**Purpose:** Deliver alert notifications via SMTP

**Usage:**
```eiffel
class AS_SENDER

feature -- Sending

    send_alert (a_event: AS_EVENT; a_recipients: LIST [STRING])
            -- Send immediate alert email.
        local
            l_email: SIMPLE_EMAIL
            l_msg: SE_MESSAGE
            l_body: STRING
        do
            l_body := template.render_alert (a_event)

            create l_email.make
            l_email.set_smtp_server (config.smtp_host, config.smtp_port)
            l_email.set_credentials (config.smtp_user, config.smtp_password)
            l_email.connect
            l_email.start_tls
            l_email.authenticate

            l_msg := l_email.create_message
            l_msg.set_from (config.from_address)
            across a_recipients as r loop
                l_msg.add_to (r)
            end
            l_msg.set_subject (format_subject (a_event))
            l_msg.set_html_body (l_body)

            if l_email.send (l_msg) then
                store.record_delivery (a_event.id, a_recipients, "sent")
            else
                store.record_delivery (a_event.id, a_recipients, "failed")
                queue_for_retry (a_event, a_recipients)
            end

            l_email.disconnect
        end

    send_digest (a_events: LIST [AS_EVENT]; a_period: STRING; a_recipients: LIST [STRING])
            -- Send digest email summarizing multiple events.
        local
            l_email: SIMPLE_EMAIL
            l_msg: SE_MESSAGE
            l_body: STRING
        do
            l_body := template.render_digest (a_events, a_period)

            create l_email.make
            -- ... SMTP setup ...

            l_msg := l_email.create_message
            l_msg.set_from (config.from_address)
            across a_recipients as r loop
                l_msg.add_to (r)
            end
            l_msg.set_subject ("Alert Digest: " + a_events.count.out + " events (" + a_period + ")")
            l_msg.set_html_body (l_body)

            l_email.send (l_msg)
            l_email.disconnect
        end

end
```

### simple_json Integration

**Purpose:** Parse incoming events and manage configuration

**Usage (Event Parsing):**
```eiffel
class AS_EVENT

create
    make_from_json

feature {NONE} -- Initialization

    make_from_json (a_json: STRING)
            -- Parse event from JSON string.
        local
            l_parser: SIMPLE_JSON
            l_obj: JSON_OBJECT
        do
            create l_parser.make
            l_obj := l_parser.parse (a_json)

            timestamp := l_obj.string_item ("timestamp")
            source := l_obj.string_item ("source")
            event_type := l_obj.string_item ("event")
            severity := l_obj.string_item ("severity")
            host := l_obj.string_item_or_default ("host", "unknown")
            message := l_obj.string_item ("message")

            if l_obj.has_key ("details") then
                details := l_obj.object_item ("details")
            end

            -- Generate deduplication key
            dedup_key := generate_dedup_key
        ensure
            has_source: not source.is_empty
            has_message: not message.is_empty
        end

    generate_dedup_key: STRING
            -- Create key for deduplication.
        do
            Result := source + "|" + event_type + "|" + host + "|" + severity
        end

end
```

**Usage (Configuration):**
```eiffel
class AS_CONFIG

feature -- Loading

    load (a_path: STRING)
            -- Load configuration from JSON file.
        local
            l_json: SIMPLE_JSON
            l_root: JSON_OBJECT
        do
            create l_json.make
            l_root := l_json.parse_file (a_path)

            -- SMTP settings
            smtp_host := l_root.string_at_path ("alertstream.smtp.host")
            smtp_port := l_root.integer_at_path ("alertstream.smtp.port")

            -- Load rules
            across l_root.array_at_path ("alertstream.rules") as rule_json loop
                rules.extend (create {AS_RULE}.make_from_json (rule_json))
            end

            -- Escalation settings
            if l_root.has_path ("alertstream.escalation") then
                load_escalation (l_root.object_at_path ("alertstream.escalation"))
            end
        end

end
```

### simple_sql Integration

**Purpose:** Persist events for deduplication, aggregation, and audit

**Usage:**
```eiffel
class AS_STORE

feature -- Initialization

    make (a_db_path: STRING)
            -- Initialize store with SQLite database.
        local
            l_sql: SIMPLE_SQL
        do
            create l_sql.make_sqlite (a_db_path)
            db := l_sql

            -- Ensure schema exists
            if not table_exists ("events") then
                create_schema
            end
        end

feature -- Storage

    store_event (a_event: AS_EVENT)
            -- Store event in database.
        local
            l_stmt: SQL_STATEMENT
        do
            l_stmt := db.prepare ("INSERT INTO events (event_id, timestamp, source, event_type, severity, host, message, details_json, dedup_key) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")
            l_stmt.bind_text (1, a_event.id)
            l_stmt.bind_text (2, a_event.timestamp)
            l_stmt.bind_text (3, a_event.source)
            l_stmt.bind_text (4, a_event.event_type)
            l_stmt.bind_text (5, a_event.severity)
            l_stmt.bind_text (6, a_event.host)
            l_stmt.bind_text (7, a_event.message)
            l_stmt.bind_text (8, a_event.details_as_json)
            l_stmt.bind_text (9, a_event.dedup_key)
            l_stmt.execute
        end

feature -- Querying

    is_duplicate (a_event: AS_EVENT; a_window_minutes: INTEGER): BOOLEAN
            -- Check if similar event exists within window.
        local
            l_stmt: SQL_STATEMENT
            l_cutoff: STRING
        do
            l_cutoff := timestamp_minus_minutes (current_timestamp, a_window_minutes)

            l_stmt := db.prepare ("SELECT COUNT(*) FROM events WHERE dedup_key = ? AND timestamp > ?")
            l_stmt.bind_text (1, a_event.dedup_key)
            l_stmt.bind_text (2, l_cutoff)
            l_stmt.execute

            Result := l_stmt.column_integer (0) > 0
        end

    events_for_digest (a_since: STRING): LIST [AS_EVENT]
            -- Get events since timestamp for digest.
        local
            l_stmt: SQL_STATEMENT
        do
            create {ARRAYED_LIST [AS_EVENT]} Result.make (100)

            l_stmt := db.prepare ("SELECT * FROM events WHERE timestamp > ? AND status = 'pending' ORDER BY timestamp")
            l_stmt.bind_text (1, a_since)

            from l_stmt.execute until l_stmt.done loop
                Result.extend (event_from_row (l_stmt))
                l_stmt.next
            end
        end

end
```

### simple_template Integration

**Purpose:** Format alert and digest emails

**Usage:**
```eiffel
class AS_TEMPLATE

feature -- Rendering

    render_alert (a_event: AS_EVENT): STRING
            -- Render single alert email.
        local
            l_template: SIMPLE_TEMPLATE
            l_vars: HASH_TABLE [ANY, STRING]
        do
            create l_template.make
            l_template.load (alert_template_path)

            create l_vars.make (10)
            l_vars.put (a_event.severity, "severity")
            l_vars.put (a_event.source, "source")
            l_vars.put (a_event.host, "host")
            l_vars.put (a_event.timestamp, "timestamp")
            l_vars.put (a_event.message, "message")
            l_vars.put (a_event.event_type, "event")
            l_vars.put (a_event.id, "event_id")

            if attached a_event.details as d then
                l_vars.put (d.to_json, "details")
            end

            Result := l_template.render (l_vars)
        end

    render_digest (a_events: LIST [AS_EVENT]; a_period: STRING): STRING
            -- Render digest email.
        local
            l_template: SIMPLE_TEMPLATE
            l_vars: HASH_TABLE [ANY, STRING]
        do
            create l_template.make
            l_template.load (digest_template_path)

            create l_vars.make (10)
            l_vars.put (a_period, "period")
            l_vars.put (current_timestamp, "generated_at")
            l_vars.put (a_events.count, "event_count")
            l_vars.put (count_by_severity (a_events, "critical"), "critical_count")
            l_vars.put (count_by_severity (a_events, "warning"), "warning_count")
            l_vars.put (count_by_severity (a_events, "info"), "info_count")
            l_vars.put (a_events, "events")

            Result := l_template.render (l_vars)
        end

end
```

### simple_scheduler Integration

**Purpose:** Parse cron expressions for digest scheduling

**Usage:**
```eiffel
class AS_DIGEST_SCHEDULER

feature -- Scheduling

    is_digest_due: BOOLEAN
            -- Check if digest should run now based on schedule.
        local
            l_scheduler: SIMPLE_SCHEDULER
            l_cron: STRING
        do
            l_cron := config.digest_schedule
            create l_scheduler.make

            Result := l_scheduler.matches_now (l_cron)
        end

    next_digest_time: DATE_TIME
            -- Calculate next digest run time.
        local
            l_scheduler: SIMPLE_SCHEDULER
        do
            create l_scheduler.make
            Result := l_scheduler.next_run (config.digest_schedule)
        end

end
```

## Dependency Graph

```
AlertStream
    |
    +-- simple_email (required)
    |       |
    |       +-- simple_base64 (transitive)
    |       +-- simple_encoding (transitive)
    |
    +-- simple_json (required)
    |
    +-- simple_sql (required)
    |       |
    |       +-- SQLite (native)
    |
    +-- simple_template (required)
    |
    +-- simple_scheduler (required)
    |
    +-- simple_datetime (optional)
    |
    +-- simple_http (optional, future)
    |
    +-- ISE base (required via all)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system name="alertstream" uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0">
    <description>AlertStream - System Monitoring Email Gateway</description>

    <!-- Library target (reusable core) -->
    <target name="alertstream">
        <root all_classes="true"/>
        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\.git$</exclude>
        </file_rule>
        <option warning="warning" syntax="provisional" manifest_array_type="mismatch_warning">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <!-- Source -->
        <cluster name="src" location=".\src\" recursive="true"/>

        <!-- ISE Base -->
        <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
        <library name="time" location="$ISE_LIBRARY\library\time\time.ecf"/>

        <!-- simple_* ecosystem -->
        <library name="simple_email" location="$SIMPLE_EIFFEL\simple_email\simple_email.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
        <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
        <library name="simple_template" location="$SIMPLE_EIFFEL\simple_template\simple_template.ecf"/>
        <library name="simple_scheduler" location="$SIMPLE_EIFFEL\simple_scheduler\simple_scheduler.ecf"/>
    </target>

    <!-- CLI executable target -->
    <target name="alertstream_cli" extends="alertstream">
        <root class="AS_CLI" feature="make"/>
        <setting name="executable_name" value="alertstream"/>
        <capability>
            <concurrency support="none"/>
        </capability>
    </target>

    <!-- Test target -->
    <target name="alertstream_tests" extends="alertstream">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
        <cluster name="tests" location=".\tests\"/>
    </target>
</system>
```

## Integration Testing Strategy

| Test | Libraries Involved | Verification |
|------|-------------------|--------------|
| Event parsing | simple_json | Parse sample events, verify fields |
| Config loading | simple_json | Load sample config, verify rules |
| Event storage | simple_sql | Store and retrieve events |
| Deduplication | simple_sql | Verify duplicate detection |
| Alert rendering | simple_template | Render sample alert, verify HTML |
| Digest rendering | simple_template | Render digest, verify summary |
| Email delivery | simple_email | Send test alert to sandbox |
| Schedule matching | simple_scheduler | Verify cron expression parsing |
