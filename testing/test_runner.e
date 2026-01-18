note
	description: "Test runner for simple_email tests"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_RUNNER

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		do
			print ("simple_email test runner%N")
			print ("=============================%N")
			run_all_tests
			print ("%N=============================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed = 0 then
				print ("ALL TESTS PASSED%N")
			end
		end

feature -- Test Execution

	run_all_tests
			-- Run all test suites.
		do
			run_message_tests
			run_attachment_tests
			run_smtp_client_tests
			run_tls_socket_tests
			run_facade_tests
			run_adversarial_tests
			run_stress_tests
		end

	run_adversarial_tests
			-- Run adversarial tests.
		local
			l_adv: ADVERSARIAL_TESTS
		do
			create l_adv.make
			l_adv.run_all
			passed := passed + l_adv.passed
			failed := failed + l_adv.failed
		end

	run_stress_tests
			-- Run stress tests.
		local
			l_stress: STRESS_TESTS
		do
			create l_stress.make
			l_stress.run_all
			passed := passed + l_stress.passed
			failed := failed + l_stress.failed
		end

	run_message_tests
			-- Test SE_MESSAGE class.
		local
			l_msg: SE_MESSAGE
		do
			print ("%N-- Message Tests --%N")

			-- Test make
			create l_msg.make
			if l_msg /= Void and then not l_msg.has_from and then not l_msg.has_recipients then
				report_pass ("test_message_make")
			else
				report_fail ("test_message_make")
			end

			-- Test set_from
			create l_msg.make
			l_msg.set_from ("sender@test.com")
			if l_msg.has_from and then l_msg.from_address.same_string ("sender@test.com") then
				report_pass ("test_message_set_from")
			else
				report_fail ("test_message_set_from")
			end

			-- Test add_to
			create l_msg.make
			l_msg.add_to ("recipient@test.com")
			if l_msg.has_recipients and then l_msg.recipients.count = 1 then
				report_pass ("test_message_add_to")
			else
				report_fail ("test_message_add_to")
			end

			-- Test add_cc
			create l_msg.make
			l_msg.add_cc ("cc@test.com")
			if l_msg.has_recipients and then l_msg.cc_recipients.count = 1 then
				report_pass ("test_message_add_cc")
			else
				report_fail ("test_message_add_cc")
			end

			-- Test add_bcc
			create l_msg.make
			l_msg.add_bcc ("bcc@test.com")
			if l_msg.has_recipients and then l_msg.bcc_recipients.count = 1 then
				report_pass ("test_message_add_bcc")
			else
				report_fail ("test_message_add_bcc")
			end

			-- Test clear_recipients
			create l_msg.make
			l_msg.add_to ("a@test.com")
			l_msg.add_cc ("b@test.com")
			l_msg.clear_recipients
			if not l_msg.has_recipients then
				report_pass ("test_message_clear_recipients")
			else
				report_fail ("test_message_clear_recipients")
			end

			-- Test set_subject
			create l_msg.make
			l_msg.set_subject ("Test Subject")
			if l_msg.subject.same_string ("Test Subject") then
				report_pass ("test_message_set_subject")
			else
				report_fail ("test_message_set_subject")
			end

			-- Test set_text_body
			create l_msg.make
			l_msg.set_text_body ("Hello World")
			if l_msg.has_body and then l_msg.text_body.same_string ("Hello World") then
				report_pass ("test_message_set_text_body")
			else
				report_fail ("test_message_set_text_body")
			end

			-- Test set_html_body
			create l_msg.make
			l_msg.set_html_body ("<p>Hello</p>")
			if l_msg.has_body and then l_msg.html_body.same_string ("<p>Hello</p>") then
				report_pass ("test_message_set_html_body")
			else
				report_fail ("test_message_set_html_body")
			end

			-- Test attach_data
			create l_msg.make
			l_msg.attach_data ("file.txt", "text/plain", "content")
			if l_msg.has_attachments and then l_msg.attachment_count = 1 then
				report_pass ("test_message_attach_data")
			else
				report_fail ("test_message_attach_data")
			end

			-- Test clear_attachments
			create l_msg.make
			l_msg.attach_data ("file.txt", "text/plain", "content")
			l_msg.clear_attachments
			if not l_msg.has_attachments then
				report_pass ("test_message_clear_attachments")
			else
				report_fail ("test_message_clear_attachments")
			end

			-- Test is_valid
			create l_msg.make
			l_msg.set_from ("sender@test.com")
			l_msg.add_to ("recipient@test.com")
			if l_msg.is_valid then
				report_pass ("test_message_is_valid")
			else
				report_fail ("test_message_is_valid")
			end

			-- Test recipient_count
			create l_msg.make
			l_msg.add_to ("a@test.com")
			l_msg.add_cc ("b@test.com")
			l_msg.add_bcc ("c@test.com")
			if l_msg.recipient_count = 3 then
				report_pass ("test_message_recipient_count")
			else
				report_fail ("test_message_recipient_count")
			end
		end

	run_attachment_tests
			-- Test SE_ATTACHMENT class.
		local
			l_att: SE_ATTACHMENT
		do
			print ("%N-- Attachment Tests --%N")

			-- Test make
			create l_att.make ("test.txt", "text/plain", "Hello")
			if l_att /= Void and then l_att.is_valid then
				report_pass ("test_attachment_make")
			else
				report_fail ("test_attachment_make")
			end

			-- Test name
			create l_att.make ("document.pdf", "application/pdf", "data")
			if l_att.name.same_string ("document.pdf") then
				report_pass ("test_attachment_name")
			else
				report_fail ("test_attachment_name")
			end

			-- Test content_type
			create l_att.make ("test.txt", "text/plain", "data")
			if l_att.content_type.same_string ("text/plain") then
				report_pass ("test_attachment_content_type")
			else
				report_fail ("test_attachment_content_type")
			end

			-- Test data
			create l_att.make ("test.txt", "text/plain", "Hello World")
			if l_att.data.same_string ("Hello World") then
				report_pass ("test_attachment_data")
			else
				report_fail ("test_attachment_data")
			end

			-- Test size
			create l_att.make ("test.txt", "text/plain", "12345")
			if l_att.size = 5 then
				report_pass ("test_attachment_size")
			else
				report_fail ("test_attachment_size")
			end

			-- Test make_from_file
			create l_att.make_from_file ("C:\test\file.txt")
			if l_att.is_valid then
				report_pass ("test_attachment_make_from_file")
			else
				report_fail ("test_attachment_make_from_file")
			end
		end

	run_smtp_client_tests
			-- Test SE_SMTP_CLIENT class.
		local
			l_client: SE_SMTP_CLIENT
		do
			print ("%N-- SMTP Client Tests --%N")

			-- Test make
			create l_client.make ("smtp.test.com", 587)
			if l_client.host.same_string ("smtp.test.com") and l_client.port = 587 then
				report_pass ("test_smtp_client_make")
			else
				report_fail ("test_smtp_client_make")
			end

			-- Test not connected initially
			create l_client.make ("smtp.test.com", 587)
			if not l_client.is_connected then
				report_pass ("test_smtp_client_not_connected_initially")
			else
				report_fail ("test_smtp_client_not_connected_initially")
			end

			-- Test disconnect when not connected
			create l_client.make ("smtp.test.com", 587)
			l_client.disconnect
			if not l_client.is_connected and not l_client.has_error then
				report_pass ("test_smtp_client_disconnect")
			else
				report_fail ("test_smtp_client_disconnect")
			end
		end

	run_tls_socket_tests
			-- Test SE_TLS_SOCKET class.
		local
			l_socket: SE_TLS_SOCKET
		do
			print ("%N-- TLS Socket Tests --%N")

			-- Test make
			create l_socket.make
			if l_socket /= Void then
				report_pass ("test_tls_socket_make")
			else
				report_fail ("test_tls_socket_make")
			end

			-- Test not connected initially
			create l_socket.make
			if not l_socket.is_connected then
				report_pass ("test_tls_socket_not_connected_initially")
			else
				report_fail ("test_tls_socket_not_connected_initially")
			end

			-- Test not tls_active initially
			create l_socket.make
			if not l_socket.is_tls_active then
				report_pass ("test_tls_socket_not_tls_initially")
			else
				report_fail ("test_tls_socket_not_tls_initially")
			end

			-- Test disconnect
			create l_socket.make
			l_socket.disconnect
			if not l_socket.is_connected and not l_socket.has_error then
				report_pass ("test_tls_socket_disconnect")
			else
				report_fail ("test_tls_socket_disconnect")
			end
		end

	run_facade_tests
			-- Test SIMPLE_EMAIL facade class.
		local
			l_email: SIMPLE_EMAIL
			l_msg: SE_MESSAGE
		do
			print ("%N-- Facade Tests --%N")

			-- Test make
			create l_email.make
			if l_email /= Void then
				report_pass ("test_facade_make")
			else
				report_fail ("test_facade_make")
			end

			-- Test set_smtp_server
			create l_email.make
			l_email.set_smtp_server ("smtp.test.com", 587)
			if l_email.smtp_host.same_string ("smtp.test.com") and l_email.smtp_port = 587 then
				report_pass ("test_facade_set_smtp_server")
			else
				report_fail ("test_facade_set_smtp_server")
			end

			-- Test create_message
			create l_email.make
			l_msg := l_email.create_message
			if l_msg /= Void then
				report_pass ("test_facade_create_message")
			else
				report_fail ("test_facade_create_message")
			end

			-- Test not connected initially
			create l_email.make
			if not l_email.is_connected then
				report_pass ("test_facade_not_connected_initially")
			else
				report_fail ("test_facade_not_connected_initially")
			end

			-- Test disconnect
			create l_email.make
			l_email.set_smtp_server ("smtp.test.com", 587)
			l_email.disconnect
			if not l_email.is_connected and not l_email.has_error then
				report_pass ("test_facade_disconnect")
			else
				report_fail ("test_facade_disconnect")
			end

			-- Test set_credentials
			create l_email.make
			l_email.set_credentials ("user@test.com", "secret123")
			if l_email.has_credentials then
				report_pass ("test_facade_set_credentials")
			else
				report_fail ("test_facade_set_credentials")
			end

			-- Test has_credentials initially false
			create l_email.make
			if not l_email.has_credentials then
				report_pass ("test_facade_no_credentials_initially")
			else
				report_fail ("test_facade_no_credentials_initially")
			end

			-- Test set_timeout
			create l_email.make
			l_email.set_timeout (60)
			report_pass ("test_facade_set_timeout")

			-- Test not authenticated initially
			create l_email.make
			if not l_email.is_authenticated then
				report_pass ("test_facade_not_authenticated_initially")
			else
				report_fail ("test_facade_not_authenticated_initially")
			end

			-- Test not tls initially
			create l_email.make
			if not l_email.is_tls_active then
				report_pass ("test_facade_not_tls_initially")
			else
				report_fail ("test_facade_not_tls_initially")
			end
		end

feature {NONE} -- Reporting

	passed: INTEGER
	failed: INTEGER

	report_pass (a_name: STRING)
		do
			print ("  PASS: " + a_name + "%N")
			passed := passed + 1
		end

	report_fail (a_name: STRING)
		do
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
		end

end
