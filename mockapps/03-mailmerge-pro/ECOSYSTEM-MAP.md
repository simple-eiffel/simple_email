# MailMerge Pro - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| **simple_email** | Core SMTP email delivery | MM_SENDER delivers personalized emails |
| **simple_csv** | CSV data source loading | MM_DATA reads recipient lists from CSV |
| **simple_json** | JSON data and configuration | MM_DATA reads JSON; MM_CONFIG loads settings |
| **simple_template** | Template variable expansion | MM_TEMPLATE renders personalized content |
| **simple_file** | Attachment handling | MM_SENDER resolves and attaches files |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| **simple_validation** | Email/data validation | Enhanced validation beyond basic checks |
| **simple_cli** | Advanced argument parsing | Complex CLI options |
| **simple_datetime** | Date formatting in templates | Date filters in templates |
| **simple_config** | Hierarchical configuration | Environment variable interpolation |

## Integration Patterns

### simple_email Integration

**Purpose:** Deliver personalized emails via SMTP

**Usage:**
```eiffel
class MM_SENDER

feature -- Sending

    send_personalized (a_recipient: MM_RECIPIENT; a_body: STRING; a_subject: STRING; a_attachments: LIST [STRING])
            -- Send personalized email to recipient.
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
            l_msg.set_subject (a_subject)

            if is_html_template then
                l_msg.set_html_body (a_body)
            else
                l_msg.set_text_body (a_body)
            end

            -- Add attachments
            across a_attachments as att loop
                l_msg.attach_file (att)
            end

            if l_email.send (l_msg) then
                tracker.record_success (a_recipient.email, l_msg.message_id)
            else
                tracker.record_failure (a_recipient.email, l_email.last_error)
            end

            l_email.disconnect
        end

feature -- Batch optimization

    send_batch (a_recipients: LIST [MM_RECIPIENT]; a_template: MM_TEMPLATE)
            -- Send to multiple recipients with connection reuse.
        local
            l_email: SIMPLE_EMAIL
            l_body, l_subject: STRING
        do
            create l_email.make
            l_email.set_smtp_server (config.smtp_host, config.smtp_port)
            l_email.set_credentials (config.smtp_user, config.smtp_password)
            l_email.connect
            l_email.start_tls
            l_email.authenticate

            across a_recipients as r loop
                l_body := a_template.expand (r)
                l_subject := a_template.expand_subject (r)

                -- Rate limiting
                throttle.wait_if_needed

                send_single (l_email, r, l_body, l_subject)
                throttle.record_send
            end

            l_email.disconnect
        end

end
```

### simple_csv Integration

**Purpose:** Load recipient data from CSV files

**Usage:**
```eiffel
class MM_DATA

feature -- Loading

    load_csv (a_path: STRING)
            -- Load recipients from CSV file.
        local
            l_csv: SIMPLE_CSV
        do
            create l_csv.make
            l_csv.load (a_path)

            -- Store headers for variable mapping
            headers := l_csv.headers

            -- Build recipient list
            create recipients.make (l_csv.row_count)
            across l_csv.rows as row loop
                recipients.extend (create {MM_RECIPIENT}.make_from_row (row, headers))
            end

            data_format := "csv"
        ensure
            headers_loaded: not headers.is_empty
        end

feature -- Access

    headers: ARRAYED_LIST [STRING]
            -- Column headers (variable names)

    recipients: ARRAYED_LIST [MM_RECIPIENT]
            -- All recipients

    recipient_at (a_index: INTEGER): MM_RECIPIENT
            -- Recipient at given index (1-based).
        require
            valid_index: a_index >= 1 and a_index <= recipients.count
        do
            Result := recipients [a_index]
        end

feature -- Querying

    recipient_by_email (a_email: STRING): detachable MM_RECIPIENT
            -- Find recipient by email address.
        do
            across recipients as r loop
                if r.email.same_string_general (a_email) then
                    Result := r
                end
            end
        end

end
```

### simple_json Integration

**Purpose:** Load JSON data and configuration

**Usage (Data Loading):**
```eiffel
class MM_DATA

feature -- Loading

    load_json (a_path: STRING)
            -- Load recipients from JSON file.
        local
            l_json: SIMPLE_JSON
            l_root: JSON_OBJECT
            l_arr: JSON_ARRAY
        do
            create l_json.make
            l_root := l_json.parse_file (a_path)

            -- Get recipients array
            l_arr := l_root.array_item ("recipients")

            -- Extract headers from first record
            if l_arr.count > 0 then
                headers := extract_keys (l_arr.object_at (1))
            end

            -- Build recipient list
            create recipients.make (l_arr.count)
            across l_arr as item loop
                recipients.extend (create {MM_RECIPIENT}.make_from_json (item, headers))
            end

            data_format := "json"
        end

end
```

**Usage (Configuration):**
```eiffel
class MM_CONFIG

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
            smtp_host := l_root.string_at_path ("mailmerge.smtp.host")
            smtp_port := l_root.integer_at_path ("mailmerge.smtp.port")

            -- Password from environment
            if l_root.has_key_at_path ("mailmerge.smtp.password_env") then
                smtp_password := environment.get (l_root.string_at_path ("mailmerge.smtp.password_env"))
            end

            -- Defaults
            from_address := l_root.string_at_path ("mailmerge.defaults.from_address")
            from_name := l_root.string_at_path ("mailmerge.defaults.from_name")

            -- Throttle settings
            delay_seconds := l_root.integer_at_path_or_default ("mailmerge.throttle.delay_seconds", 0)
            max_per_hour := l_root.integer_at_path_or_default ("mailmerge.throttle.max_per_hour", 0)
        end

end
```

### simple_template Integration

**Purpose:** Template loading and variable expansion

**Usage:**
```eiffel
class MM_TEMPLATE

feature -- Loading

    load (a_path: STRING)
            -- Load template from file.
        local
            l_template: SIMPLE_TEMPLATE
        do
            create l_template.make
            l_template.load_file (a_path)
            internal_template := l_template

            -- Extract variable names for validation
            variables := l_template.variable_names
        ensure
            template_loaded: internal_template /= Void
        end

feature -- Expansion

    expand (a_recipient: MM_RECIPIENT): STRING
            -- Expand template with recipient data.
        local
            l_vars: HASH_TABLE [ANY, STRING]
        do
            create l_vars.make (a_recipient.field_count)

            -- Add all recipient fields
            across a_recipient.fields as f loop
                l_vars.put (f, f.key)
            end

            -- Add system variables
            l_vars.put (current_date, "today")
            l_vars.put (current_year.out, "year")

            Result := internal_template.render (l_vars)
        end

    expand_subject (a_recipient: MM_RECIPIENT): STRING
            -- Expand subject template with recipient data.
        local
            l_subject_template: SIMPLE_TEMPLATE
            l_vars: HASH_TABLE [ANY, STRING]
        do
            create l_subject_template.make
            l_subject_template.load_string (subject_template)

            create l_vars.make (a_recipient.field_count)
            across a_recipient.fields as f loop
                l_vars.put (f, f.key)
            end

            Result := l_subject_template.render (l_vars)
        end

feature -- Validation

    validate_with_data (a_headers: LIST [STRING]): LIST [STRING]
            -- Validate template against data headers.
            -- Returns list of missing variables.
        local
            l_missing: ARRAYED_LIST [STRING]
        do
            create l_missing.make (5)

            across variables as v loop
                if not a_headers.has (v) and not is_system_variable (v) then
                    l_missing.extend (v)
                end
            end

            Result := l_missing
        end

feature {NONE} -- Implementation

    is_system_variable (a_name: STRING): BOOLEAN
            -- Is this a built-in system variable?
        do
            Result := a_name.same_string ("today") or
                      a_name.same_string ("year") or
                      a_name.same_string ("timestamp")
        end

end
```

### simple_file Integration

**Purpose:** Resolve and validate attachment files

**Usage:**
```eiffel
class MM_ATTACHMENT_RESOLVER

feature -- Resolution

    resolve_attachments (a_patterns: LIST [STRING]; a_recipient: MM_RECIPIENT): LIST [STRING]
            -- Resolve attachment patterns for recipient.
        local
            l_file: SIMPLE_FILE
            l_path: STRING
        do
            create {ARRAYED_LIST [STRING]} Result.make (a_patterns.count)

            across a_patterns as pattern loop
                l_path := expand_pattern (pattern, a_recipient)

                create l_file.make (l_path)
                if l_file.exists then
                    Result.extend (l_path)
                else
                    report_missing_attachment (l_path, a_recipient.email)
                end
            end
        end

    expand_pattern (a_pattern: STRING; a_recipient: MM_RECIPIENT): STRING
            -- Expand variables in attachment path pattern.
        do
            Result := a_pattern.twin

            across a_recipient.fields as f loop
                Result.replace_substring_all ("{{" + f.key + "}}", f.to_string)
            end
        end

feature -- Validation

    validate_base_paths (a_patterns: LIST [STRING]): BOOLEAN
            -- Check that base directories exist.
        local
            l_file: SIMPLE_FILE
            l_dir: STRING
        do
            Result := True

            across a_patterns as pattern loop
                l_dir := extract_directory (pattern)
                create l_file.make (l_dir)
                if not l_file.is_directory then
                    Result := False
                    report_missing_directory (l_dir)
                end
            end
        end

end
```

## Dependency Graph

```
MailMerge Pro
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
    +-- simple_validation (optional)
    |
    +-- simple_datetime (optional)
    |
    +-- ISE base (required via all)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system name="mailmerge" uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0">
    <description>MailMerge Pro - Personalized Campaign Sender</description>

    <!-- Library target (reusable core) -->
    <target name="mailmerge">
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
    </target>

    <!-- CLI executable target -->
    <target name="mailmerge_cli" extends="mailmerge">
        <root class="MM_CLI" feature="make"/>
        <setting name="executable_name" value="mailmerge"/>
        <capability>
            <concurrency support="none"/>
        </capability>
    </target>

    <!-- Test target -->
    <target name="mailmerge_tests" extends="mailmerge">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
        <cluster name="tests" location=".\tests\"/>
    </target>
</system>
```

## Integration Testing Strategy

| Test | Libraries Involved | Verification |
|------|-------------------|--------------|
| Load CSV data | simple_csv | Load sample CSV, verify recipients |
| Load JSON data | simple_json | Load sample JSON, verify recipients |
| Config loading | simple_json | Load config, verify SMTP settings |
| Template expansion | simple_template | Expand with test data, verify output |
| Attachment resolution | simple_file | Resolve patterns, verify paths |
| Full send | simple_email, all | Send test campaign to sandbox |
| Validation | simple_validation | Validate emails, verify results |
