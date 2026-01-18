note
	description: "SMTP client with TLS support"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SE_SMTP_CLIENT

create
	make

feature {NONE} -- Initialization

	make (a_host: STRING; a_port: INTEGER)
			-- Create SMTP client for server at `a_host' on `a_port'.
		require
			host_not_empty: not a_host.is_empty
			port_positive: a_port > 0
		do
			internal_host := a_host
			port := a_port
			timeout := 30000
		ensure
			host_set: host.same_string (a_host)
			port_set: port = a_port
			not_connected: not is_connected
		end

feature -- Access (Queries)

	host: STRING
			-- Server hostname
		do
			Result := internal_host
		end

	port: INTEGER
			-- Server port

	last_response: detachable STRING
			-- Last server response

	last_error: detachable STRING
			-- Last error message

feature -- Status (Boolean Queries)

	is_connected: BOOLEAN
			-- Is connected to server?
		do
			Result := attached socket as l_socket and then l_socket.is_connected
		end

	is_tls_active: BOOLEAN
			-- Is TLS encryption active?
		do
			Result := attached socket as l_socket and then l_socket.is_tls_active
		end

	is_authenticated: BOOLEAN
			-- Is authenticated?

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		end

feature -- Connection (Commands)

	connect
			-- Connect to server.
		do
			create socket.make
			if attached socket as l_socket then
				l_socket.set_timeout (timeout)
				l_socket.connect (internal_host, port)
				if l_socket.has_error then
					last_error := l_socket.last_error
				else
					last_error := Void
					-- Read greeting
					read_response
					if not response_ok (220) then
						last_error := "Server rejected connection"
						l_socket.disconnect
					end
				end
			end
		end

	connect_tls
			-- Connect with implicit TLS (port 465).
		do
			create socket.make
			if attached socket as l_socket then
				l_socket.set_timeout (timeout)
				l_socket.connect_tls (internal_host, port)
				if l_socket.has_error then
					last_error := l_socket.last_error
				else
					last_error := Void
					-- Read greeting
					read_response
					if not response_ok (220) then
						last_error := "Server rejected connection"
						l_socket.disconnect
					end
				end
			end
		end

	start_tls
			-- Upgrade connection to TLS (STARTTLS).
		do
			if attached socket as l_socket then
				-- Send STARTTLS command
				send_command ("STARTTLS")
				read_response
				if response_ok (220) then
					l_socket.start_tls (internal_host)
					if l_socket.has_error then
						last_error := l_socket.last_error
					end
				else
					last_error := "Server does not support STARTTLS"
				end
			end
		end

	send_ehlo
			-- Send EHLO greeting.
		do
			send_command ("EHLO " + local_hostname)
			read_response
			if not response_ok (250) then
				-- Fall back to HELO
				send_command ("HELO " + local_hostname)
				read_response
				if not response_ok (250) then
					last_error := "Server rejected greeting"
				end
			end
		end

	disconnect
			-- Disconnect from server.
		do
			if attached socket as l_socket and then l_socket.is_connected then
				send_command ("QUIT")
				read_response
				l_socket.disconnect
			end
			socket := Void
			is_authenticated := False
			last_error := Void
		ensure
			not_connected: not is_connected
			not_authenticated: not is_authenticated
			no_error: not has_error
		end

feature -- Authentication (Commands)

	authenticate_plain (a_username, a_password: STRING)
			-- Authenticate using PLAIN mechanism.
		require
			connected: is_connected
			username_not_empty: not a_username.is_empty
		local
			l_credentials: STRING
			l_encoded: STRING
		do
			-- AUTH PLAIN base64(NUL username NUL password)
			create l_credentials.make (a_username.count + a_password.count + 2)
			l_credentials.append_character ('%U')
			l_credentials.append (a_username)
			l_credentials.append_character ('%U')
			l_credentials.append (a_password)
			l_encoded := base64_encode (l_credentials)

			send_command ("AUTH PLAIN " + l_encoded)
			read_response
			if response_ok (235) then
				is_authenticated := True
				last_error := Void
			else
				last_error := "Authentication failed"
			end
		end

	authenticate_login (a_username, a_password: STRING)
			-- Authenticate using LOGIN mechanism.
		require
			connected: is_connected
			username_not_empty: not a_username.is_empty
		do
			send_command ("AUTH LOGIN")
			read_response
			if response_ok (334) then
				-- Send base64 username
				send_command (base64_encode (a_username))
				read_response
				if response_ok (334) then
					-- Send base64 password
					send_command (base64_encode (a_password))
					read_response
					if response_ok (235) then
						is_authenticated := True
						last_error := Void
					else
						last_error := "Password rejected"
					end
				else
					last_error := "Username rejected"
				end
			else
				last_error := "AUTH LOGIN not supported"
			end
		end

feature -- Sending (Commands)

	send_message (a_message: SE_MESSAGE)
			-- Send email message.
		require
			connected: is_connected
			authenticated: is_authenticated
			message_valid: a_message.is_valid
		do
			last_error := Void

			-- MAIL FROM
			send_command ("MAIL FROM:<" + a_message.from_address + ">")
			read_response
			if not response_ok (250) then
				last_error := "MAIL FROM rejected"
			end

			if not has_error then
				-- RCPT TO for each recipient
				across a_message.recipients as l_rcpt loop
					send_command ("RCPT TO:<" + l_rcpt + ">")
					read_response
					if not response_ok (250) and not response_ok (251) then
						last_error := "RCPT TO rejected: " + l_rcpt
					end
				end
				across a_message.cc_recipients as l_rcpt loop
					send_command ("RCPT TO:<" + l_rcpt + ">")
					read_response
					if not response_ok (250) and not response_ok (251) then
						last_error := "RCPT TO rejected: " + l_rcpt
					end
				end
				across a_message.bcc_recipients as l_rcpt loop
					send_command ("RCPT TO:<" + l_rcpt + ">")
					read_response
					if not response_ok (250) and not response_ok (251) then
						last_error := "RCPT TO rejected: " + l_rcpt
					end
				end
			end

			if not has_error then
				-- DATA
				send_command ("DATA")
				read_response
				if response_ok (354) then
					-- Send message content
					send_message_content (a_message)
					-- End with CRLF.CRLF
					send_line (".")
					read_response
					if not response_ok (250) then
						last_error := "Message rejected"
					end
				else
					last_error := "DATA command rejected"
				end
			end
		end

feature {NONE} -- Message Formatting

	send_message_content (a_message: SE_MESSAGE)
			-- Send the message headers and body.
		local
			l_boundary: STRING
		do
			-- Headers
			send_line ("From: " + a_message.from_address)
			if not a_message.recipients.is_empty then
				send_line ("To: " + joined_addresses (a_message.recipients))
			end
			if not a_message.cc_recipients.is_empty then
				send_line ("Cc: " + joined_addresses (a_message.cc_recipients))
			end
			send_line ("Subject: " + a_message.subject)
			send_line ("MIME-Version: 1.0")

			if a_message.has_attachments then
				-- Multipart/mixed for attachments
				l_boundary := generate_boundary
				send_line ("Content-Type: multipart/mixed; boundary=%"" + l_boundary + "%"")
				send_line ("")
				send_line ("--" + l_boundary)
				send_body_part (a_message)
				send_attachments (a_message, l_boundary)
				send_line ("--" + l_boundary + "--")
			elseif not a_message.html_body.is_empty and not a_message.text_body.is_empty then
				-- Multipart/alternative for text+html
				l_boundary := generate_boundary
				send_line ("Content-Type: multipart/alternative; boundary=%"" + l_boundary + "%"")
				send_line ("")
				send_line ("--" + l_boundary)
				send_line ("Content-Type: text/plain; charset=utf-8")
				send_line ("")
				send_line (a_message.text_body)
				send_line ("--" + l_boundary)
				send_line ("Content-Type: text/html; charset=utf-8")
				send_line ("")
				send_line (a_message.html_body)
				send_line ("--" + l_boundary + "--")
			elseif not a_message.html_body.is_empty then
				send_line ("Content-Type: text/html; charset=utf-8")
				send_line ("")
				send_line (a_message.html_body)
			else
				send_line ("Content-Type: text/plain; charset=utf-8")
				send_line ("")
				send_line (a_message.text_body)
			end
		end

	send_body_part (a_message: SE_MESSAGE)
			-- Send body part for multipart message.
		local
			l_boundary: STRING
		do
			if not a_message.html_body.is_empty and not a_message.text_body.is_empty then
				l_boundary := generate_boundary
				send_line ("Content-Type: multipart/alternative; boundary=%"" + l_boundary + "%"")
				send_line ("")
				send_line ("--" + l_boundary)
				send_line ("Content-Type: text/plain; charset=utf-8")
				send_line ("")
				send_line (a_message.text_body)
				send_line ("--" + l_boundary)
				send_line ("Content-Type: text/html; charset=utf-8")
				send_line ("")
				send_line (a_message.html_body)
				send_line ("--" + l_boundary + "--")
			elseif not a_message.html_body.is_empty then
				send_line ("Content-Type: text/html; charset=utf-8")
				send_line ("")
				send_line (a_message.html_body)
			else
				send_line ("Content-Type: text/plain; charset=utf-8")
				send_line ("")
				send_line (a_message.text_body)
			end
		end

	send_attachments (a_message: SE_MESSAGE; a_boundary: STRING)
			-- Send attachments.
		do
			across a_message.attachments as l_att loop
				send_line ("--" + a_boundary)
				send_line ("Content-Type: " + l_att.content_type)
				send_line ("Content-Transfer-Encoding: base64")
				send_line ("Content-Disposition: attachment; filename=%"" + l_att.name + "%"")
				send_line ("")
				send_line (base64_encode (l_att.data))
			end
		end

	joined_addresses (a_list: ARRAYED_LIST [STRING]): STRING
			-- Join addresses with comma.
		do
			create Result.make (a_list.count * 30)
			across a_list as l_addr loop
				if not Result.is_empty then
					Result.append (", ")
				end
				Result.append (l_addr)
			end
		end

	generate_boundary: STRING
			-- Generate MIME boundary string.
		do
			boundary_counter := boundary_counter + 1
			Result := "----=_Part_" + boundary_counter.out + "_" + boundary_counter.hash_code.out
		end

	boundary_counter: INTEGER
			-- Counter for generating unique boundaries

feature {NONE} -- Protocol Helpers

	send_command (a_command: STRING)
			-- Send SMTP command.
		do
			if attached socket as l_socket then
				l_socket.send (a_command + "%R%N")
			end
		end

	send_line (a_line: STRING)
			-- Send a line of data.
		local
			l_escaped: STRING
		do
			if attached socket as l_socket then
				-- Escape leading dots (dot stuffing)
				if a_line.count > 0 and then a_line.item (1) = '.' then
					l_escaped := "." + a_line
				else
					l_escaped := a_line
				end
				l_socket.send (l_escaped + "%R%N")
			end
		end

	read_response
			-- Read multi-line response.
		local
			l_line: STRING
			l_done: BOOLEAN
		do
			if attached socket as l_socket then
				create last_response.make (256)
				from
					l_done := False
				until
					l_done
				loop
					l_line := l_socket.receive_line
					if l_line.is_empty then
						l_done := True
					else
						if attached last_response as lr then
							if not lr.is_empty then
								lr.append ("%N")
							end
							lr.append (l_line)
						end
						-- Check if continuation (4th char is '-') or final (4th char is space)
						if l_line.count >= 4 then
							l_done := l_line.item (4) /= '-'
						else
							l_done := True
						end
					end
				end
			end
		end

	response_ok (a_code: INTEGER): BOOLEAN
			-- Does response start with given code?
		do
			if attached last_response as lr and then lr.count >= 3 then
				Result := lr.substring (1, 3).is_integer and then
				          lr.substring (1, 3).to_integer = a_code
			end
		end

	response_code: INTEGER
			-- Extract response code from last_response.
		do
			if attached last_response as lr and then lr.count >= 3 and then lr.substring (1, 3).is_integer then
				Result := lr.substring (1, 3).to_integer
			end
		end

	local_hostname: STRING
			-- Get local hostname for EHLO.
		once
			Result := "localhost"
			-- Could use gethostname() here
		end

	base64_encode (a_string: STRING): STRING
			-- Encode string to base64.
		local
			l_encoder: SIMPLE_BASE64
		do
			create l_encoder.make
			Result := l_encoder.encode (a_string)
		end

feature {NONE} -- Implementation

	socket: detachable SE_TLS_SOCKET
			-- TLS socket for communication

	internal_host: STRING
			-- Internal host storage

	timeout: INTEGER
			-- Connection timeout

invariant
	host_exists: internal_host /= Void
	port_positive: port > 0
	auth_requires_connection: is_authenticated implies is_connected
	tls_requires_connection: is_tls_active implies is_connected

end
