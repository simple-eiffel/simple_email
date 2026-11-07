note
	description: "Test application for SIMPLE_EMAIL"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running SIMPLE_EMAIL tests...%N%N")
			passed := 0
			failed := 0

			run_lib_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_lib_tests
		do
			create lib_tests
			run_test (agent lib_tests.test_creation, "test_creation")
			run_test (agent lib_tests.test_refused_connect_reports_refusal_quickly, "test_refused_connect_reports_refusal_quickly")
			create adversarial_tests.make
			run_test (agent adversarial_tests.test_empty_email_address, "test_empty_email_address")
			run_test (agent adversarial_tests.test_no_at_in_email, "test_no_at_in_email")
			run_test (agent adversarial_tests.test_crlf_injection_from, "test_crlf_injection_from")
			run_test (agent adversarial_tests.test_crlf_injection_to, "test_crlf_injection_to")
			run_test (agent adversarial_tests.test_very_long_email, "test_very_long_email")
			run_test (agent adversarial_tests.test_very_long_subject, "test_very_long_subject")
			run_test (agent adversarial_tests.test_disconnect_when_not_connected, "test_disconnect_when_not_connected")
			run_test (agent adversarial_tests.test_multiple_recipients, "test_multiple_recipients")
			run_test (agent adversarial_tests.test_valid_utf8_body, "test_valid_utf8_body")
			run_test (agent adversarial_tests.test_valid_utf8_unicode_body, "test_valid_utf8_unicode_body")
			run_test (agent adversarial_tests.test_invalid_utf8_body, "test_invalid_utf8_body")
			run_test (agent adversarial_tests.test_empty_attachment_data, "test_empty_attachment_data")
			run_test (agent adversarial_tests.test_binary_attachment_data, "test_binary_attachment_data")
			create stress_tests.make
			run_test (agent stress_tests.test_100_recipients, "test_100_recipients")
			run_test (agent stress_tests.test_1000_recipients, "test_1000_recipients")
			run_test (agent stress_tests.test_100_attachments, "test_100_attachments")
			run_test (agent stress_tests.test_large_body, "test_large_body")
			run_test (agent stress_tests.test_rapid_message_creation, "test_rapid_message_creation")
			run_test (agent stress_tests.test_rapid_client_creation, "test_rapid_client_creation")
		end

feature {NONE} -- Implementation

	lib_tests: LIB_TESTS
	adversarial_tests: ADVERSARIAL_TESTS
	stress_tests: STRESS_TESTS
	passed, failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
