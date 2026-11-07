note
	description: "WinSock and SChannel calls behind SE_TLS_SOCKET (Windows)."
	author: "Larry Rix"

class
	SE_TLS_PRIMITIVES

feature {NONE} -- C Externals

	c_winsock_startup: INTEGER
			-- Initialize WinSock.
		external
			"C inline use <winsock2.h>, <ws2tcpip.h>"
		alias
			"[
				WSADATA wsa;
				return WSAStartup(MAKEWORD(2, 2), &wsa);
			]"
		end

	c_invalid_socket: POINTER
			-- Get INVALID_SOCKET value.
		external
			"C inline use <winsock2.h>"
		alias
			"return (EIF_POINTER)INVALID_SOCKET;"
		end

	c_connect (a_host: POINTER; a_port: INTEGER; a_timeout: INTEGER; a_socket: TYPED_POINTER [POINTER]): INTEGER
			-- Connect to host:port with timeout. Return 0 on success.
		external
			"C inline use <winsock2.h>, <ws2tcpip.h>"
		alias
			"[
				struct addrinfo hints, *result = NULL;
				SOCKET sock = INVALID_SOCKET;
				char port_str[16];
				int res;
				u_long mode;
				fd_set write_fds, except_fds;
				struct timeval tv;

				memset(&hints, 0, sizeof(hints));
				hints.ai_family = AF_INET;
				hints.ai_socktype = SOCK_STREAM;
				hints.ai_protocol = IPPROTO_TCP;

				sprintf(port_str, "%d", (int)$a_port);
				res = getaddrinfo((char*)$a_host, port_str, &hints, &result);
				if (res != 0) return res;

				sock = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
				if (sock == INVALID_SOCKET) {
					freeaddrinfo(result);
					return WSAGetLastError();
				}

				// Set non-blocking for timeout
				mode = 1;
				ioctlsocket(sock, FIONBIO, &mode);

				res = connect(sock, result->ai_addr, (int)result->ai_addrlen);
				freeaddrinfo(result);

				if (res == SOCKET_ERROR) {
					int err = WSAGetLastError();
					if (err != WSAEWOULDBLOCK) {
						closesocket(sock);
						return err;
					}

					// Wait for connection with timeout
					FD_ZERO(&write_fds);
					FD_ZERO(&except_fds);
					FD_SET(sock, &write_fds);
					FD_SET(sock, &except_fds);
					tv.tv_sec = $a_timeout / 1000;
					tv.tv_usec = ($a_timeout % 1000) * 1000;

					res = select(0, NULL, &write_fds, &except_fds, &tv);
					if (res <= 0) {
						closesocket(sock);
						return res == 0 ? 10060 : WSAGetLastError();
					}

					// A refused connect is reported in except_fds (not write_fds)
					{
						int so_err = 0;
						int so_len = (int)sizeof(so_err);
						getsockopt(sock, SOL_SOCKET, SO_ERROR, (char*)&so_err, &so_len);
						if (so_err == 0 && FD_ISSET(sock, &except_fds)) so_err = WSAECONNREFUSED;
						if (so_err != 0) {
							closesocket(sock);
							return so_err;
						}
					}
				}

				// Set back to blocking
				mode = 0;
				ioctlsocket(sock, FIONBIO, &mode);

				*$a_socket = (EIF_POINTER)sock;
				return 0;
			]"
		end

	c_close_socket (a_socket: POINTER)
			-- Close socket.
		external
			"C inline use <winsock2.h>"
		alias
			"closesocket((SOCKET)$a_socket);"
		end

	c_send_plain (a_socket: POINTER; a_data: POINTER; a_len: INTEGER): INTEGER
			-- Send data on plain socket.
		external
			"C inline use <winsock2.h>"
		alias
			"return send((SOCKET)$a_socket, (char*)$a_data, $a_len, 0);"
		end

	c_receive_plain (a_socket: POINTER; a_buffer: POINTER; a_max: INTEGER): INTEGER
			-- Receive data from plain socket.
		external
			"C inline use <winsock2.h>"
		alias
			"return recv((SOCKET)$a_socket, (char*)$a_buffer, $a_max, 0);"
		end

	c_start_tls (a_socket: POINTER; a_host: POINTER; a_context: TYPED_POINTER [POINTER]): INTEGER
			-- Handshake, checking the certificate against `a_host'. Return 0 on success.
		external
			"C inline use %"se_tls_schannel.h%""
		alias
			"return (EIF_INTEGER) se_start_tls ((SOCKET) $a_socket, (const char *) $a_host, (void **) $a_context);"
		end

	c_shutdown_tls (a_socket: POINTER; a_context: POINTER)
			-- Send close_notify and release the context.
		external
			"C inline use %"se_tls_schannel.h%""
		alias
			"se_shutdown_tls ((void *) $a_context);"
		end

	c_send_tls (a_socket: POINTER; a_context: POINTER; a_data: POINTER; a_len: INTEGER): INTEGER
			-- Encrypt and send. Return bytes sent or -1 on error.
		external
			"C inline use %"se_tls_schannel.h%""
		alias
			"return (EIF_INTEGER) se_send_tls ((void *) $a_context, (const void *) $a_data, (int) $a_len);"
		end

	c_receive_tls (a_socket: POINTER; a_context: POINTER; a_buffer: POINTER; a_max: INTEGER): INTEGER
			-- Receive and decrypt. Return bytes received, 0 at close, or -1 on error.
		external
			"C inline use %"se_tls_schannel.h%""
		alias
			"return (EIF_INTEGER) se_receive_tls ((void *) $a_context, (void *) $a_buffer, (int) $a_max);"
		end

end
