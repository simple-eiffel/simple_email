note
	description: "TLS socket using Win32 SChannel"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SE_TLS_SOCKET

create
	make

feature {NONE} -- Initialization

	make
			-- Create TLS socket.
		do
			timeout_ms := 30000
		end

feature -- Access (Queries)

	last_error: detachable STRING
			-- Last error message

feature -- Status (Boolean Queries)

	is_connected: BOOLEAN
			-- Is socket connected?
		do
			Result := socket_handle /= default_pointer
		end

	is_tls_active: BOOLEAN
			-- Is TLS handshake complete?
		do
			Result := ssl_context /= default_pointer
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		end

feature -- Connection (Commands)

	connect (a_host: STRING; a_port: INTEGER)
			-- Connect to `a_host' on `a_port' (plain TCP).
		require
			host_not_empty: not a_host.is_empty
			port_positive: a_port > 0
			not_connected: not is_connected
		do
			-- Stub: would use WinSock to connect
			last_error := "Not implemented"
		end

	connect_tls (a_host: STRING; a_port: INTEGER)
			-- Connect with implicit TLS.
		require
			host_not_empty: not a_host.is_empty
			port_positive: a_port > 0
			not_connected: not is_connected
		do
			-- Stub: would connect and immediately do TLS handshake
			last_error := "Not implemented"
		end

	start_tls (a_host: STRING)
			-- Upgrade existing connection to TLS.
		require
			host_not_empty: not a_host.is_empty
			connected: is_connected
			not_already_tls: not is_tls_active
		do
			-- Stub: would perform SChannel handshake
			last_error := "Not implemented"
		end

	disconnect
			-- Close connection.
		do
			socket_handle := default_pointer
			ssl_context := default_pointer
			last_error := Void
		ensure
			not_connected: not is_connected
			not_tls: not is_tls_active
			no_error: not has_error
		end

feature -- I/O (Commands)

	send (a_data: STRING)
			-- Send `a_data' over socket.
		require
			connected: is_connected
		do
			-- Stub: would send encrypted data
		end

	receive: STRING
			-- Receive data from socket.
		require
			connected: is_connected
		do
			-- Stub: would receive and decrypt data
			Result := ""
		end

	receive_line: STRING
			-- Receive single line (until CRLF).
		require
			connected: is_connected
		do
			-- Stub: would receive until %R%N
			Result := ""
		end

feature -- Settings (Commands)

	set_timeout (a_milliseconds: INTEGER)
			-- Set socket timeout.
		require
			positive_timeout: a_milliseconds > 0
		do
			timeout_ms := a_milliseconds
		ensure
			timeout_set: timeout_ms = a_milliseconds
		end

feature {NONE} -- Implementation

	socket_handle: POINTER
			-- Native socket handle

	ssl_context: POINTER
			-- SChannel SSL context

	timeout_ms: INTEGER
			-- Timeout in milliseconds

invariant
	timeout_positive: timeout_ms > 0
	tls_requires_connection: is_tls_active implies is_connected

end
