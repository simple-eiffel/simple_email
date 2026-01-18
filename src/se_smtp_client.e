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
				l_socket.connect (internal_host, port)
				if l_socket.has_error then
					last_error := l_socket.last_error
				else
					last_error := Void
				end
			end
		end

	connect_tls
			-- Connect with implicit TLS (port 465).
		do
			create socket.make
			if attached socket as l_socket then
				l_socket.connect_tls (internal_host, port)
				if l_socket.has_error then
					last_error := l_socket.last_error
				else
					last_error := Void
				end
			end
		end

	start_tls
			-- Upgrade connection to TLS (STARTTLS).
		do
			if attached socket as l_socket then
				l_socket.start_tls (internal_host)
				if l_socket.has_error then
					last_error := l_socket.last_error
				end
			end
		end

	disconnect
			-- Disconnect from server.
		do
			if attached socket as l_socket then
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
		do
			-- Stub: would send AUTH PLAIN command
			is_authenticated := True
		end

	authenticate_login (a_username, a_password: STRING)
			-- Authenticate using LOGIN mechanism.
		require
			connected: is_connected
			username_not_empty: not a_username.is_empty
		do
			-- Stub: would send AUTH LOGIN command
			is_authenticated := True
		end

feature -- Sending (Commands)

	send_message (a_message: SE_MESSAGE)
			-- Send email message.
		require
			connected: is_connected
			authenticated: is_authenticated
			message_valid: a_message.is_valid
		do
			-- Stub: would send MAIL FROM, RCPT TO, DATA
			last_error := "Not implemented"
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
