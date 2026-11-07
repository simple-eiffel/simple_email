note
	description: "TLS socket. SE_TLS_PRIMITIVES holds the platform calls, one class per platform."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SE_TLS_SOCKET

inherit
	SE_TLS_PRIMITIVES

create
	make

feature {NONE} -- Initialization

	make
			-- Create TLS socket.
		do
			timeout_ms := 30000
			socket_handle := invalid_socket
			create receive_buffer.make_empty
			ensure_winsock_initialized
		end

feature -- Access (Queries)

	last_error: detachable STRING
			-- Last error message

feature -- Status (Boolean Queries)

	is_connected: BOOLEAN
			-- Is socket connected?
		do
			Result := socket_handle /= invalid_socket
		end

	is_tls_active: BOOLEAN
			-- Is TLS handshake complete?
		do
			Result := tls_established
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
		local
			l_host_c: C_STRING
			l_result: INTEGER
		do
			last_error := Void
			create l_host_c.make (a_host)
			l_result := c_connect (l_host_c.item, a_port, timeout_ms, $socket_handle)
			if l_result /= 0 then
				last_error := "Connection failed: " + winsock_error_message (l_result)
				socket_handle := invalid_socket
			end
		end

	connect_tls (a_host: STRING; a_port: INTEGER)
			-- Connect with implicit TLS.
		require
			host_not_empty: not a_host.is_empty
			port_positive: a_port > 0
			not_connected: not is_connected
		do
			connect (a_host, a_port)
			if is_connected and not has_error then
				start_tls (a_host)
			end
		end

	start_tls (a_host: STRING)
			-- Upgrade existing connection to TLS.
		require
			host_not_empty: not a_host.is_empty
			connected: is_connected
			not_already_tls: not is_tls_active
		local
			l_host_c: C_STRING
			l_result: INTEGER
		do
			last_error := Void
			create l_host_c.make (a_host)
			l_result := c_start_tls (socket_handle, l_host_c.item, $ssl_context)
			if l_result /= 0 then
				last_error := "TLS handshake failed: " + schannel_error_message (l_result)
			else
				tls_established := True
			end
		end

	disconnect
			-- Close connection.
		do
			if tls_established then
				c_shutdown_tls (socket_handle, ssl_context)
				tls_established := False
			end
			if socket_handle /= invalid_socket then
				c_close_socket (socket_handle)
				socket_handle := invalid_socket
			end
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
		local
			l_data_c: C_STRING
			l_result: INTEGER
		do
			last_error := Void
			create l_data_c.make (a_data)
			if tls_established then
				l_result := c_send_tls (socket_handle, ssl_context, l_data_c.item, a_data.count)
			else
				l_result := c_send_plain (socket_handle, l_data_c.item, a_data.count)
			end
			if l_result < 0 then
				last_error := "Send failed"
			end
		end

	receive: STRING
			-- Receive data from socket.
		require
			connected: is_connected
		local
			l_buffer: MANAGED_POINTER
			l_received: INTEGER
		do
			last_error := Void
			create l_buffer.make (4096)
			if tls_established then
				l_received := c_receive_tls (socket_handle, ssl_context, l_buffer.item, 4096)
			else
				l_received := c_receive_plain (socket_handle, l_buffer.item, 4096)
			end
			if l_received > 0 then
				create Result.make_from_c_substring (l_buffer.item, 1, l_received)
			elseif l_received < 0 then
				last_error := "Receive failed"
				Result := ""
			else
				Result := ""
			end
		end

	receive_line: STRING
			-- Receive single line (until CRLF).
		require
			connected: is_connected
		local
			l_char: STRING
			l_done: BOOLEAN
		do
			last_error := Void
			create Result.make (256)
			from
				l_done := False
			until
				l_done or has_error
			loop
				l_char := receive_single_char
				if l_char.is_empty then
					l_done := True
				elseif l_char.item (1) = '%N' then
					l_done := True
				elseif l_char.item (1) /= '%R' then
					Result.append (l_char)
				end
			end
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
			-- The platform's TLS session

	tls_established: BOOLEAN
			-- Has TLS handshake completed?

	timeout_ms: INTEGER
			-- Timeout in milliseconds

	receive_buffer: STRING
			-- Buffer for partial receives

	invalid_socket: POINTER
			-- Invalid socket constant
		once
			Result := c_invalid_socket
		end

	receive_single_char: STRING
			-- Receive a single character.
		local
			l_buffer: MANAGED_POINTER
			l_received: INTEGER
		do
			create l_buffer.make (1)
			if tls_established then
				l_received := c_receive_tls (socket_handle, ssl_context, l_buffer.item, 1)
			else
				l_received := c_receive_plain (socket_handle, l_buffer.item, 1)
			end
			if l_received = 1 then
				create Result.make_from_c_substring (l_buffer.item, 1, 1)
			else
				Result := ""
			end
		end

	winsock_error_message (a_code: INTEGER): STRING
			-- Error message for WinSock error code.
		do
			inspect a_code
			when 10060 then Result := "Connection timed out"
			when 10061 then Result := "Connection refused"
			when 10065 then Result := "No route to host"
			when 11001 then Result := "Host not found"
			else
				Result := "Error code " + a_code.out
			end
		end

	schannel_error_message (a_code: INTEGER): STRING
			-- Error message for SChannel error code.
		do
			if a_code = -2146893048 then
				Result := "Certificate validation failed"
			elseif a_code = -2146893022 then
				Result := "Server rejected connection"
			else
				Result := "Error code " + a_code.out
			end
		end

feature {NONE} -- WinSock Initialization

	winsock_initialized: BOOLEAN
			-- Has WinSock been initialized?

	ensure_winsock_initialized
			-- Initialize WinSock if not already done.
		do
			if not winsock_initialized then
				if c_winsock_startup = 0 then
					winsock_initialized := True
				end
			end
		end


invariant
	timeout_positive: timeout_ms > 0
	tls_requires_connection: is_tls_active implies is_connected

end
