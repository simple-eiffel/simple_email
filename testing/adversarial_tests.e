note
	description: "Adversarial tests for simple_email"
	date: "2026-01-18"

class
	ADVERSARIAL_TESTS

create
	make

feature {NONE} -- Initialization

	make
		do
			passed := 0
			failed := 0
			risk := 0
		end

feature -- Counters

	passed, failed, risk: INTEGER

feature -- Empty Input Tests

	test_empty_email_address
			-- Attempt to set empty email address (should be blocked by precondition)
		local
			l_msg: SE_MESSAGE
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_msg.make
				l_msg.set_from ("")
				-- Should not reach here
				risk := risk + 1
				print ("  RISK: test_empty_email_address - empty string accepted%N")
			end
		rescue
			passed := passed + 1
			print ("  PASS: test_empty_email_address - precondition correctly blocked empty%N")
			l_retried := True
			retry
		end

	test_no_at_in_email
			-- Attempt to set email without @ (should be blocked by precondition)
		local
			l_msg: SE_MESSAGE
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_msg.make
				l_msg.set_from ("invalid-email")
				-- Should not reach here
				risk := risk + 1
				print ("  RISK: test_no_at_in_email - address without @ accepted%N")
			end
		rescue
			passed := passed + 1
			print ("  PASS: test_no_at_in_email - precondition correctly blocked%N")
			l_retried := True
			retry
		end

feature -- Injection Tests

	test_crlf_injection_from
			-- Attempt SMTP injection via CRLF in from address
		local
			l_msg: SE_MESSAGE
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_msg.make
				l_msg.set_from ("attacker@test.com%R%NRCPT TO:<victim@test.com>")
				-- Should not reach here
				risk := risk + 1
				print ("  RISK: test_crlf_injection_from - CRLF injection possible!%N")
			end
		rescue
			passed := passed + 1
			print ("  PASS: test_crlf_injection_from - CRLF injection blocked%N")
			l_retried := True
			retry
		end

	test_crlf_injection_to
			-- Attempt SMTP injection via CRLF in recipient
		local
			l_msg: SE_MESSAGE
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_msg.make
				l_msg.add_to ("victim@test.com%R%NDATA")
				-- Should not reach here
				risk := risk + 1
				print ("  RISK: test_crlf_injection_to - CRLF injection possible!%N")
			end
		rescue
			passed := passed + 1
			print ("  PASS: test_crlf_injection_to - CRLF injection blocked%N")
			l_retried := True
			retry
		end

feature -- Boundary Tests

	test_very_long_email
			-- Test with very long email address
		local
			l_msg: SE_MESSAGE
			l_addr: STRING
		do
			create l_addr.make_filled ('x', 500)
			l_addr.append ("@")
			l_addr.append_string (create {STRING}.make_filled ('y', 500))
			l_addr.append (".com")

			create l_msg.make
			l_msg.set_from (l_addr)
			if l_msg.from_address.count > 1000 then
				passed := passed + 1
				print ("  PASS: test_very_long_email - long address accepted (may need limit)%N")
			else
				failed := failed + 1
				print ("  FAIL: test_very_long_email - address truncated%N")
			end
		rescue
			failed := failed + 1
			print ("  FAIL: test_very_long_email - exception on long address%N")
		end

	test_very_long_subject
			-- Test with very long subject
		local
			l_msg: SE_MESSAGE
			l_subj: STRING
		do
			create l_subj.make_filled ('x', 10000)
			create l_msg.make
			l_msg.set_subject (l_subj)
			if l_msg.subject.count = 10000 then
				passed := passed + 1
				print ("  PASS: test_very_long_subject - 10K subject accepted (may need limit)%N")
			else
				failed := failed + 1
				print ("  FAIL: test_very_long_subject - subject truncated%N")
			end
		rescue
			failed := failed + 1
			print ("  FAIL: test_very_long_subject - exception on long subject%N")
		end

feature -- State Tests

	test_disconnect_when_not_connected
			-- Test disconnect on not-connected client
		local
			l_email: SIMPLE_EMAIL
		do
			create l_email.make
			l_email.set_smtp_server ("smtp.test.com", 587)
			l_email.disconnect
			if not l_email.is_connected and not l_email.has_error then
				passed := passed + 1
				print ("  PASS: test_disconnect_when_not_connected - no error%N")
			else
				failed := failed + 1
				print ("  FAIL: test_disconnect_when_not_connected - unexpected state%N")
			end
		rescue
			failed := failed + 1
			print ("  FAIL: test_disconnect_when_not_connected - exception%N")
		end

	test_multiple_recipients
			-- Test adding many recipients
		local
			l_msg: SE_MESSAGE
			i: INTEGER
		do
			create l_msg.make
			l_msg.set_from ("sender@test.com")
			from i := 1 until i > 100 loop
				l_msg.add_to ("recipient" + i.out + "@test.com")
				i := i + 1
			end
			if l_msg.recipient_count = 100 then
				passed := passed + 1
				print ("  PASS: test_multiple_recipients - 100 recipients added%N")
			else
				failed := failed + 1
				print ("  FAIL: test_multiple_recipients - count mismatch%N")
			end
		rescue
			failed := failed + 1
			print ("  FAIL: test_multiple_recipients - exception%N")
		end

feature -- UTF-8 Validation Tests

	test_valid_utf8_body
			-- Test that valid UTF-8 body passes validation
		local
			l_msg: SE_MESSAGE
		do
			create l_msg.make
			l_msg.set_text_body ("Hello, world!")
			if l_msg.is_body_utf8_valid then
				passed := passed + 1
				print ("  PASS: test_valid_utf8_body - ASCII body is valid UTF-8%N")
			else
				failed := failed + 1
				print ("  FAIL: test_valid_utf8_body - ASCII body rejected%N")
			end
		rescue
			failed := failed + 1
			print ("  FAIL: test_valid_utf8_body - exception%N")
		end

	test_valid_utf8_unicode_body
			-- Test that valid UTF-8 Unicode body passes validation
		local
			l_msg: SE_MESSAGE
			l_body: STRING_8
		do
			create l_msg.make
			-- UTF-8 for "Hëllo" (0xC3 0xAB for ë)
			create l_body.make (10)
			l_body.append ("H")
			l_body.append_character ('%/195/')  -- 0xC3
			l_body.append_character ('%/171/')  -- 0xAB (ë in UTF-8)
			l_body.append ("llo")
			l_msg.set_text_body (l_body)
			if l_msg.is_body_utf8_valid then
				passed := passed + 1
				print ("  PASS: test_valid_utf8_unicode_body - UTF-8 body is valid%N")
			else
				failed := failed + 1
				print ("  FAIL: test_valid_utf8_unicode_body - valid UTF-8 rejected%N")
			end
		rescue
			failed := failed + 1
			print ("  FAIL: test_valid_utf8_unicode_body - exception%N")
		end

	test_invalid_utf8_body
			-- Test that invalid UTF-8 body is detected
		local
			l_msg: SE_MESSAGE
			l_body: STRING_8
		do
			create l_msg.make
			-- Invalid UTF-8: 0x80 is not a valid leading byte
			create l_body.make (10)
			l_body.append ("Hello")
			l_body.append_character ('%/128/')  -- 0x80 (invalid leading byte)
			l_body.append ("world")
			l_msg.set_text_body (l_body)
			if not l_msg.is_body_utf8_valid then
				passed := passed + 1
				print ("  PASS: test_invalid_utf8_body - invalid UTF-8 detected%N")
			else
				failed := failed + 1
				print ("  FAIL: test_invalid_utf8_body - invalid UTF-8 not detected%N")
			end
		rescue
			failed := failed + 1
			print ("  FAIL: test_invalid_utf8_body - exception%N")
		end

feature -- Attachment Tests

	test_empty_attachment_data
			-- Test attachment with empty data
		local
			l_msg: SE_MESSAGE
		do
			create l_msg.make
			l_msg.attach_data ("empty.txt", "text/plain", "")
			if l_msg.has_attachments then
				passed := passed + 1
				print ("  PASS: test_empty_attachment_data - empty attachment allowed%N")
			else
				failed := failed + 1
				print ("  FAIL: test_empty_attachment_data - attachment not added%N")
			end
		rescue
			failed := failed + 1
			print ("  FAIL: test_empty_attachment_data - exception%N")
		end

	test_binary_attachment_data
			-- Test attachment with binary content (null bytes)
		local
			l_msg: SE_MESSAGE
			l_data: STRING
		do
			create l_data.make (10)
			l_data.append_character ('%U')
			l_data.append_character ('X')
			l_data.append_character ('%U')
			l_data.append_character ('Y')
			create l_msg.make
			l_msg.attach_data ("binary.bin", "application/octet-stream", l_data)
			if l_msg.has_attachments then
				passed := passed + 1
				print ("  PASS: test_binary_attachment_data - binary data accepted%N")
			else
				failed := failed + 1
				print ("  FAIL: test_binary_attachment_data - binary rejected%N")
			end
		rescue
			failed := failed + 1
			print ("  FAIL: test_binary_attachment_data - exception on binary%N")
		end

feature -- Run All

	run_all
		do
			print ("%N=== Adversarial Tests ===%N")
			print ("%N-- Empty Input Tests --%N")
			test_empty_email_address
			test_no_at_in_email

			print ("%N-- Injection Tests --%N")
			test_crlf_injection_from
			test_crlf_injection_to

			print ("%N-- Boundary Tests --%N")
			test_very_long_email
			test_very_long_subject

			print ("%N-- State Tests --%N")
			test_disconnect_when_not_connected
			test_multiple_recipients

			print ("%N-- UTF-8 Validation Tests --%N")
			test_valid_utf8_body
			test_valid_utf8_unicode_body
			test_invalid_utf8_body

			print ("%N-- Attachment Tests --%N")
			test_empty_attachment_data
			test_binary_attachment_data

			print ("%N=== Summary: " + passed.out + " pass, " + failed.out + " fail, " + risk.out + " risk ===%N")
		end

end
