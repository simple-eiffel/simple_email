# BatchMailer - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| **simple_email** | Core SMTP email sending | BM_ENGINE uses SIMPLE_EMAIL for all mail delivery |
| **simple_csv** | Recipient list loading | BM_RECIPIENTS reads CSV files for recipient data |
| **simple_json** | Configuration and logging | BM_CONFIG loads JSON config; BM_LOGGER writes JSON logs |
| **simple_template** | Email template processing | BM_TEMPLATE expands variables in email content |
| **simple_file** | Attachment file handling | BM_ATTACHMENT reads files, resolves paths |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| **simple_scheduler** | Schedule expression parsing | When using schedule-based job runs |
| **simple_validation** | Email address validation | Enhanced validation beyond DBC contracts |
| **simple_cli** | Argument parsing | If using advanced CLI features |
| **simple_config** | Hierarchical configuration | If config needs env var interpolation |

## Integration Patterns

### simple_email Integration

**Purpose:** Core SMTP email delivery

**Usage:**
```eiffel
class BM_ENGINE

feature -- Sending

    send_email (a_recipient: BM_RECIPIENT; a_content: STRING; a_attachments: LIST [STRING])
            -- Send email to single recipient.
        local
            l_email: SIMPLE_EMAIL
            l_msg: SE_MESSAGE
        do
            create l_email.make
            l_email.set_smtp_server (config.smtp_host, config.smtp_port)
            l_email.set_credentials (config.smtp_user, config.smtp_password)

            l_email.connect
            if config.tls_mode.same_string ("starttls") then
                l_email.start_tls
            end
            l_email.authenticate

            l_msg := l_email.create_message
            l_msg.set_from (config.from_address)
            l_msg.add_to (a_recipient.email)
            l_msg.set_subject (expand_subject (a_recipient))
            l_msg.set_html_body (a_content)

            across a_attachments as att loop
                l_msg.attach_file (att)
            end

            if l_email.send (l_msg) then
                logger.log_success (a_recipient.email)
            else
                logger.log_failure (a_recipient.email, l_email.last_error)
            end

            l_email.disconnect
        end

end
```

**Data flow:** BM_ENGINE creates SIMPLE_EMAIL instance per batch (connection reuse) -> creates SE_MESSAGE per recipient -> calls send -> logs result

### simple_csv Integration

**Purpose:** Load recipient lists from CSV files

**Usage:**
```eiffel
class BM_RECIPIENTS

feature -- Loading

    load_from_csv (a_path: STRING)
            -- Load recipients from CSV file.
        local
            l_csv: SIMPLE_CSV
            l_row: CSV_ROW
        do
            create l_csv.make
            l_csv.load (a_path)

            -- First row is headers
            headers := l_csv.headers

            across l_csv.rows as row loop
                create l_row.make_from_csv_row (row, headers)
                if l_row.is_valid then
                    recipients.extend (l_row)
                else
                    skipped.extend (l_row.email)
                end
            end
        ensure
            recipients_loaded: not recipients.is_empty or not skipped.is_empty
        end

feature {NONE} -- Implementation

    headers: ARRAYED_LIST [STRING]
    recipients: ARRAYED_LIST [BM_RECIPIENT]
    skipped: ARRAYED_LIST [STRING]

end
```

**Data flow:** CSV file path -> SIMPLE_CSV.load -> iterate rows -> validate each -> build BM_RECIPIENT list

### simple_json Integration

**Purpose:** Configuration management and delivery logging

**Usage (Configuration):**
```eiffel
class BM_CONFIG

feature -- Loading

    load (a_path: STRING)
            -- Load configuration from JSON file.
        local
            l_json: SIMPLE_JSON
            l_root: JSON_OBJECT
        do
            create l_json.make
            l_root := l_json.parse_file (a_path)

            smtp_host := l_root.string_at_path ("batchmailer.smtp.host")
            smtp_port := l_root.integer_at_path ("batchmailer.smtp.port")

            -- Load password from environment if specified
            if l_root.has_key ("batchmailer.smtp.password_env") then
                smtp_password := environment.get (l_root.string_at_path ("batchmailer.smtp.password_env"))
            else
                smtp_password := l_root.string_at_path ("batchmailer.smtp.password")
            end

            -- Load jobs
            across l_root.object_at_path ("batchmailer.jobs") as job loop
                jobs.put (create {BM_JOB}.make_from_json (job), job.key)
            end
        end

end
```

**Usage (Logging):**
```eiffel
class BM_LOGGER

feature -- Logging

    log_send (a_email: STRING; a_message_id: STRING)
            -- Log successful send.
        local
            l_entry: JSON_OBJECT
        do
            create l_entry.make
            l_entry.put_string ("email", a_email)
            l_entry.put_string ("status", "sent")
            l_entry.put_string ("sent_at", current_timestamp)
            l_entry.put_string ("message_id", a_message_id)

            current_log.recipients.extend (l_entry)
        end

    finalize_log
            -- Write log to file.
        local
            l_json: SIMPLE_JSON
        do
            create l_json.make
            l_json.write_file (log_path, current_log)
        end

end
```

### simple_template Integration

**Purpose:** Email template variable expansion

**Usage:**
```eiffel
class BM_TEMPLATE

feature -- Processing

    expand (a_recipient: BM_RECIPIENT): STRING
            -- Expand template with recipient data.
        local
            l_template: SIMPLE_TEMPLATE
            l_vars: HASH_TABLE [STRING, STRING]
        do
            create l_template.make
            l_template.load (template_path)

            -- Build variable map from recipient
            create l_vars.make (10)
            l_vars.put (a_recipient.email, "email")
            l_vars.put (a_recipient.first_name, "first_name")
            l_vars.put (a_recipient.last_name, "last_name")

            -- Add custom fields
            across a_recipient.custom_fields as field loop
                l_vars.put (field, field.key)
            end

            -- Add system variables
            l_vars.put (current_date_formatted, "date")
            l_vars.put (current_week.out, "week")

            Result := l_template.render (l_vars)
        end

end
```

### simple_file Integration

**Purpose:** Attachment file handling

**Usage:**
```eiffel
class BM_ATTACHMENT

feature -- Resolution

    resolve_attachments (a_patterns: LIST [STRING]; a_recipient: BM_RECIPIENT): LIST [STRING]
            -- Resolve attachment paths with variable expansion.
        local
            l_file: SIMPLE_FILE
            l_path: STRING
        do
            create {ARRAYED_LIST [STRING]} Result.make (a_patterns.count)

            across a_patterns as pattern loop
                l_path := expand_path (pattern, a_recipient)

                create l_file.make (l_path)
                if l_file.exists then
                    Result.extend (l_path)
                else
                    logger.log_warning ("Attachment not found: " + l_path)
                end
            end
        end

    expand_path (a_pattern: STRING; a_recipient: BM_RECIPIENT): STRING
            -- Expand variables in path pattern.
        do
            Result := a_pattern.twin
            Result.replace_substring_all ("{{date}}", current_date_formatted)
            Result.replace_substring_all ("{{week}}", current_week.out)
            Result.replace_substring_all ("{{email}}", a_recipient.email)
        end

end
```

## Dependency Graph

```
BatchMailer
    |
    +-- simple_email (required)
    |       |
    |       +-- simple_base64 (transitive)
    |       +-- simple_encoding (transitive)
    |
    +-- simple_csv (required)
    |
    +-- simple_json (required)
    |
    +-- simple_template (required)
    |
    +-- simple_file (required)
    |
    +-- simple_scheduler (optional)
    |
    +-- simple_validation (optional)
    |
    +-- simple_cli (optional)
    |
    +-- ISE base (required via all)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system name="batchmailer" uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0">
    <description>BatchMailer - Automated Report Distribution System</description>

    <!-- Library target (reusable core) -->
    <target name="batchmailer">
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
        <library name="simple_csv" location="$SIMPLE_EIFFEL\simple_csv\simple_csv.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
        <library name="simple_template" location="$SIMPLE_EIFFEL\simple_template\simple_template.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL\simple_file\simple_file.ecf"/>

        <!-- Optional -->
        <library name="simple_scheduler" location="$SIMPLE_EIFFEL\simple_scheduler\simple_scheduler.ecf"/>
    </target>

    <!-- CLI executable target -->
    <target name="batchmailer_cli" extends="batchmailer">
        <root class="BM_CLI" feature="make"/>
        <setting name="executable_name" value="batchmailer"/>
        <capability>
            <concurrency support="none"/>
        </capability>
    </target>

    <!-- Test target -->
    <target name="batchmailer_tests" extends="batchmailer">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
        <cluster name="tests" location=".\tests\"/>
    </target>
</system>
```

## Integration Testing Strategy

| Test | Libraries Involved | Verification |
|------|-------------------|--------------|
| Config loading | simple_json | Load sample config, verify all fields |
| Recipient loading | simple_csv | Load test CSV, verify row count and fields |
| Template expansion | simple_template | Expand with test data, verify output |
| Attachment resolution | simple_file | Resolve patterns, verify paths |
| Full send | simple_email, all | Send to test mailbox, verify receipt |
