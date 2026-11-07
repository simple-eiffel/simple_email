note
	description: "[
		BSD socket and OpenSSL calls behind SE_TLS_SOCKET (macOS and Linux).
		Clib/se_tls_posix.h holds the C. After the handshake every byte is
		encrypted, and the certificate is checked against the host name.
	]"
	author: "Larry Rix"

class
	SE_TLS_PRIMITIVES

feature {NONE} -- C Externals

	c_winsock_startup: INTEGER
			-- Nothing to start here; 0.
		do
			Result := 0
		end

	c_invalid_socket: POINTER
			-- The handle meaning no socket.
		external
			"C inline use %"se_tls_posix.h%""
		alias
			"return (EIF_POINTER) SE_INVALID;"
		end

	c_connect (a_host: POINTER; a_port: INTEGER; a_timeout: INTEGER; a_socket: TYPED_POINTER [POINTER]): INTEGER
			-- Connect to host:port with timeout. Return 0 on success.
		external
			"C inline use %"se_tls_posix.h%""
		alias
			"return (EIF_INTEGER) se_connect ((const char *) $a_host, (int) $a_port, (int) $a_timeout, (void **) $a_socket);"
		end

	c_close_socket (a_socket: POINTER)
			-- Close socket.
		external
			"C inline use %"se_tls_posix.h%""
		alias
			"close (se_fd ((void *) $a_socket));"
		end

	c_send_plain (a_socket: POINTER; a_data: POINTER; a_len: INTEGER): INTEGER
			-- Send data on plain socket.
		external
			"C inline use %"se_tls_posix.h%""
		alias
			"return (EIF_INTEGER) se_send_plain ((void *) $a_socket, (const void *) $a_data, (int) $a_len);"
		end

	c_receive_plain (a_socket: POINTER; a_buffer: POINTER; a_max: INTEGER): INTEGER
			-- Receive data from plain socket.
		external
			"C inline use %"se_tls_posix.h%""
		alias
			"return (EIF_INTEGER) se_receive_plain ((void *) $a_socket, (void *) $a_buffer, (int) $a_max);"
		end

	c_start_tls (a_socket: POINTER; a_host: POINTER; a_context: TYPED_POINTER [POINTER]): INTEGER
			-- TLS handshake, certificate checked against `a_host'. Return 0 on success.
		external
			"C inline use %"se_tls_posix.h%""
		alias
			"return (EIF_INTEGER) se_start_tls ((void *) $a_socket, (const char *) $a_host, (void **) $a_context);"
		end

	c_shutdown_tls (a_socket: POINTER; a_context: POINTER)
			-- Send close_notify and free the session.
		external
			"C inline use %"se_tls_posix.h%""
		alias
			"se_shutdown_tls ((void *) $a_context);"
		end

	c_send_tls (a_socket: POINTER; a_context: POINTER; a_data: POINTER; a_len: INTEGER): INTEGER
			-- Send data over TLS. Return bytes sent or -1 on error.
		external
			"C inline use %"se_tls_posix.h%""
		alias
			"return (EIF_INTEGER) se_send_tls ((void *) $a_context, (const void *) $a_data, (int) $a_len);"
		end

	c_receive_tls (a_socket: POINTER; a_context: POINTER; a_buffer: POINTER; a_max: INTEGER): INTEGER
			-- Receive data over TLS. Return bytes received or -1 on error.
		external
			"C inline use %"se_tls_posix.h%""
		alias
			"return (EIF_INTEGER) se_receive_tls ((void *) $a_context, (void *) $a_buffer, (int) $a_max);"
		end

end
