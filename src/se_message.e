note
	description: "Email message with headers, body, and attachments"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SE_MESSAGE

create
	make

feature {NONE} -- Initialization

	make
			-- Create empty message.
		do
			create recipients.make (5)
			create cc_recipients.make (5)
			create bcc_recipients.make (5)
			create attachments.make (3)
			internal_from := ""
			internal_subject := ""
			internal_text_body := ""
			internal_html_body := ""
		end

feature -- Access (Queries)

	from_address: STRING
			-- Sender email address
		do
			Result := internal_from
		end

	subject: STRING
			-- Email subject line
		do
			Result := internal_subject
		end

	text_body: STRING
			-- Plain text body
		do
			Result := internal_text_body
		end

	html_body: STRING
			-- HTML body
		do
			Result := internal_html_body
		end

	recipients: ARRAYED_LIST [STRING]
			-- All To recipients

	cc_recipients: ARRAYED_LIST [STRING]
			-- All Cc recipients

	bcc_recipients: ARRAYED_LIST [STRING]
			-- All Bcc recipients

	attachments: ARRAYED_LIST [SE_ATTACHMENT]
			-- All attachments

feature -- Status (Boolean Queries)

	is_valid: BOOLEAN
			-- Is message valid for sending?
		do
			Result := has_from and has_recipients
		end

	has_from: BOOLEAN
			-- Is From address set?
		do
			Result := not internal_from.is_empty
		end

	has_recipients: BOOLEAN
			-- Are there any recipients?
		do
			Result := not recipients.is_empty or not cc_recipients.is_empty or not bcc_recipients.is_empty
		end

	has_body: BOOLEAN
			-- Is there any body content?
		do
			Result := not internal_text_body.is_empty or not internal_html_body.is_empty
		end

	has_attachments: BOOLEAN
			-- Are there any attachments?
		do
			Result := not attachments.is_empty
		end

	is_body_utf8_valid: BOOLEAN
			-- Is body content valid UTF-8?
			-- Validates both text_body and html_body if present.
		local
			l_detector: SIMPLE_ENCODING_DETECTOR
		do
			create l_detector.make
			Result := True
			if not internal_text_body.is_empty then
				Result := l_detector.is_valid_utf8 (internal_text_body)
			end
			if Result and not internal_html_body.is_empty then
				Result := l_detector.is_valid_utf8 (internal_html_body)
			end
		end

	is_subject_utf8_valid: BOOLEAN
			-- Is subject valid UTF-8?
		local
			l_detector: SIMPLE_ENCODING_DETECTOR
		do
			create l_detector.make
			Result := internal_subject.is_empty or else l_detector.is_valid_utf8 (internal_subject)
		end

feature -- Measurement (Integer Queries)

	recipient_count: INTEGER
			-- Total number of recipients (To + Cc + Bcc)
		do
			Result := recipients.count + cc_recipients.count + bcc_recipients.count
		end

	attachment_count: INTEGER
			-- Number of attachments
		do
			Result := attachments.count
		end

feature -- Sender (Commands)

	set_from (a_address: STRING)
			-- Set sender address.
		require
			address_not_empty: not a_address.is_empty
			address_has_at: a_address.has ('@')
			address_no_newlines: not a_address.has ('%R') and not a_address.has ('%N')
		do
			internal_from := a_address
		ensure
			from_set: from_address.same_string (a_address)
			has_from: has_from
			recipients_unchanged: recipients.count = old recipients.count
		end

feature -- Recipients (Commands)

	add_to (a_address: STRING)
			-- Add To recipient.
		require
			address_not_empty: not a_address.is_empty
			address_has_at: a_address.has ('@')
			address_no_newlines: not a_address.has ('%R') and not a_address.has ('%N')
		do
			recipients.extend (a_address)
		ensure
			one_more: recipients.count = old recipients.count + 1
			has_recipients: has_recipients
			from_unchanged: from_address.same_string (old from_address.twin)
		end

	add_cc (a_address: STRING)
			-- Add Cc recipient.
		require
			address_not_empty: not a_address.is_empty
			address_has_at: a_address.has ('@')
			address_no_newlines: not a_address.has ('%R') and not a_address.has ('%N')
		do
			cc_recipients.extend (a_address)
		ensure
			one_more: cc_recipients.count = old cc_recipients.count + 1
			has_recipients: has_recipients
			to_unchanged: recipients.count = old recipients.count
		end

	add_bcc (a_address: STRING)
			-- Add Bcc recipient.
		require
			address_not_empty: not a_address.is_empty
			address_has_at: a_address.has ('@')
			address_no_newlines: not a_address.has ('%R') and not a_address.has ('%N')
		do
			bcc_recipients.extend (a_address)
		ensure
			one_more: bcc_recipients.count = old bcc_recipients.count + 1
			has_recipients: has_recipients
			to_unchanged: recipients.count = old recipients.count
			cc_unchanged: cc_recipients.count = old cc_recipients.count + 0
		end

	clear_recipients
			-- Remove all recipients.
		do
			recipients.wipe_out
			cc_recipients.wipe_out
			bcc_recipients.wipe_out
		ensure
			no_to: recipients.is_empty
			no_cc: cc_recipients.is_empty
			no_bcc: bcc_recipients.is_empty
			no_recipients: not has_recipients
		end

feature -- Content (Commands)

	set_subject (a_subject: STRING)
			-- Set subject line.
		do
			internal_subject := a_subject
		ensure
			subject_set: subject.same_string (a_subject)
		end

	set_text_body (a_text: STRING)
			-- Set plain text body.
		do
			internal_text_body := a_text
		ensure
			body_set: text_body.same_string (a_text)
			has_body: has_body or a_text.is_empty
		end

	set_html_body (a_html: STRING)
			-- Set HTML body.
		do
			internal_html_body := a_html
		ensure
			body_set: html_body.same_string (a_html)
			has_body: has_body or a_html.is_empty
		end

feature -- Attachments (Commands)

	attach_file (a_path: STRING)
			-- Attach file at `a_path'.
		require
			path_not_empty: not a_path.is_empty
		local
			l_att: SE_ATTACHMENT
		do
			create l_att.make_from_file (a_path)
			attachments.extend (l_att)
		ensure
			one_more: attachments.count = old attachments.count + 1
			has_attachments: has_attachments
		end

	attach_data (a_name: STRING; a_content_type: STRING; a_data: STRING)
			-- Attach raw data with given name and content type.
		require
			name_not_empty: not a_name.is_empty
			content_type_not_empty: not a_content_type.is_empty
		local
			l_att: SE_ATTACHMENT
		do
			create l_att.make (a_name, a_content_type, a_data)
			attachments.extend (l_att)
		ensure
			one_more: attachments.count = old attachments.count + 1
			has_attachments: has_attachments
		end

	clear_attachments
			-- Remove all attachments.
		do
			attachments.wipe_out
		ensure
			no_attachments: attachments.is_empty
			not_has_attachments: not has_attachments
		end

feature {NONE} -- Implementation

	internal_from: STRING
			-- Internal From storage

	internal_subject: STRING
			-- Internal Subject storage

	internal_text_body: STRING
			-- Internal text body storage

	internal_html_body: STRING
			-- Internal HTML body storage

invariant
	recipients_exists: recipients /= Void
	cc_exists: cc_recipients /= Void
	bcc_exists: bcc_recipients /= Void
	attachments_exists: attachments /= Void
	valid_implies_has_from_and_recipients: is_valid implies (has_from and has_recipients)
	count_consistent: recipient_count = recipients.count + cc_recipients.count + bcc_recipients.count
	attachment_count_consistent: attachment_count = attachments.count

end
