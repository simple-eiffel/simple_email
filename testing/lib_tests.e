note
	description: "Test cases for SIMPLE_EMAIL"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Tests

	test_creation
			-- Test basic creation.
		do
			assert ("placeholder", True)
		end

	test_refused_connect_reports_refusal_quickly
			-- A connect to a closed loopback port must report refusal (WSA 10061)
			-- well under the 10 s timeout, not a timeout (WSA 10060).
		local
			l_socket: SE_TLS_SOCKET
			l_start: DATE_TIME
			l_elapsed: REAL_64
		do
			create l_socket.make
			l_socket.set_timeout (10000)
			create l_start.make_now
			l_socket.connect ("127.0.0.1", 1)
			l_elapsed := (create {DATE_TIME}.make_now).relative_duration (l_start).fine_seconds_count
			assert ("not connected", not l_socket.is_connected)
			assert ("has error", l_socket.has_error)
			if attached l_socket.last_error as al_err then
				assert ("reported as refused: " + al_err, al_err.has_substring ("refused"))
				assert ("not reported as timeout: " + al_err, not al_err.has_substring ("timed out"))
			end
			assert ("refusal well under timeout, took " + l_elapsed.out + " s", l_elapsed < 5.0)
		end

end
