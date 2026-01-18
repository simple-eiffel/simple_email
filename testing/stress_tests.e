note
	description: "Stress tests for simple_email"
	date: "2026-01-18"

class
	STRESS_TESTS

create
	make

feature {NONE} -- Initialization

	make
		do
			passed := 0
			failed := 0
		end

feature -- Counters

	passed, failed: INTEGER

feature -- Volume Tests

	test_100_recipients
			-- Test message with 100 recipients.
		local
			l_msg: SE_MESSAGE
			i: INTEGER
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_msg.make
				l_msg.set_from ("sender@test.com")
				from i := 1 until i > 100 loop
					l_msg.add_to ("recipient" + i.out + "@test.com")
					i := i + 1
				end
				if l_msg.recipient_count = 100 then
					passed := passed + 1
					print ("  PASS: test_100_recipients%N")
				else
					failed := failed + 1
					print ("  FAIL: test_100_recipients - wrong count%N")
				end
			end
		rescue
			failed := failed + 1
			print ("  CRASH: test_100_recipients%N")
			l_retried := True
			retry
		end

	test_1000_recipients
			-- Test message with 1000 recipients.
		local
			l_msg: SE_MESSAGE
			i: INTEGER
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_msg.make
				l_msg.set_from ("sender@test.com")
				from i := 1 until i > 1000 loop
					l_msg.add_to ("recipient" + i.out + "@test.com")
					i := i + 1
				end
				if l_msg.recipient_count = 1000 then
					passed := passed + 1
					print ("  PASS: test_1000_recipients%N")
				else
					failed := failed + 1
					print ("  FAIL: test_1000_recipients - wrong count%N")
				end
			end
		rescue
			failed := failed + 1
			print ("  CRASH: test_1000_recipients%N")
			l_retried := True
			retry
		end

	test_100_attachments
			-- Test message with 100 attachments.
		local
			l_msg: SE_MESSAGE
			i: INTEGER
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_msg.make
				l_msg.set_from ("sender@test.com")
				l_msg.add_to ("recipient@test.com")
				from i := 1 until i > 100 loop
					l_msg.attach_data ("file" + i.out + ".txt", "text/plain", "content" + i.out)
					i := i + 1
				end
				if l_msg.attachment_count = 100 then
					passed := passed + 1
					print ("  PASS: test_100_attachments%N")
				else
					failed := failed + 1
					print ("  FAIL: test_100_attachments - wrong count%N")
				end
			end
		rescue
			failed := failed + 1
			print ("  CRASH: test_100_attachments%N")
			l_retried := True
			retry
		end

	test_large_body
			-- Test message with 1MB body.
		local
			l_msg: SE_MESSAGE
			l_body: STRING
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_body.make_filled ('X', 1048576)
				create l_msg.make
				l_msg.set_from ("sender@test.com")
				l_msg.add_to ("recipient@test.com")
				l_msg.set_text_body (l_body)
				if l_msg.text_body.count = 1048576 then
					passed := passed + 1
					print ("  PASS: test_large_body - 1MB body handled%N")
				else
					failed := failed + 1
					print ("  FAIL: test_large_body - count=" + l_msg.text_body.count.out + "%N")
				end
			end
		rescue
			failed := failed + 1
			print ("  CRASH: test_large_body%N")
			l_retried := True
			retry
		end

feature -- Rapid Creation Tests

	test_rapid_message_creation
			-- Create 1000 messages rapidly.
		local
			l_msg: SE_MESSAGE
			i: INTEGER
			l_retried: BOOLEAN
		do
			if not l_retried then
				from i := 1 until i > 1000 loop
					create l_msg.make
					l_msg.set_from ("sender@test.com")
					l_msg.add_to ("recipient@test.com")
					l_msg.set_subject ("Test " + i.out)
					l_msg.set_text_body ("Body " + i.out)
					i := i + 1
				end
				passed := passed + 1
				print ("  PASS: test_rapid_message_creation - 1000 messages created%N")
			end
		rescue
			failed := failed + 1
			print ("  CRASH: test_rapid_message_creation%N")
			l_retried := True
			retry
		end

	test_rapid_client_creation
			-- Create 100 SMTP clients rapidly.
		local
			l_client: SE_SMTP_CLIENT
			i: INTEGER
			l_retried: BOOLEAN
		do
			if not l_retried then
				from i := 1 until i > 100 loop
					create l_client.make ("smtp.test.com", 587)
					l_client.disconnect
					i := i + 1
				end
				passed := passed + 1
				print ("  PASS: test_rapid_client_creation - 100 clients created%N")
			end
		rescue
			failed := failed + 1
			print ("  CRASH: test_rapid_client_creation%N")
			l_retried := True
			retry
		end

feature -- Run All

	run_all
		do
			print ("%N=== Stress Tests ===%N")
			print ("%N-- Volume Tests --%N")
			test_100_recipients
			test_1000_recipients
			test_100_attachments
			test_large_body

			print ("%N-- Rapid Creation Tests --%N")
			test_rapid_message_creation
			test_rapid_client_creation

			print ("%N=== Stress Summary: " + passed.out + " pass, " + failed.out + " fail ===%N")
		end

end
