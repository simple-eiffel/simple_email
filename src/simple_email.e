note
	description: "Simple Email - Facade for sending and receiving email"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_EMAIL

create
	make

feature {NONE} -- Initialization

	make
			-- Create email client.
		do
			smtp_host := ""
			smtp_port := Default_smtp_starttls_port
			timeout := Default_timeout_seconds
		end

feature -- Access (Queries)

	last_error: detachable STRING
			-- Last error message if operation failed

	smtp_host: STRING
			-- SMTP server hostname

	smtp_port: INTEGER
			-- SMTP server port

feature -- Status (Boolean Queries)

	is_connected: BOOLEAN
			-- Is client connected to server?
		do
			Result := attached smtp_client as l_client and then l_client.is_connected
		end

	is_authenticated: BOOLEAN
			-- Is client authenticated?
		do
			Result := attached smtp_client as l_client and then l_client.is_authenticated
		end

	is_tls_active: BOOLEAN
			-- Is TLS encryption active?
		do
			Result := attached smtp_client as l_client and then l_client.is_tls_active
		end

	has_error: BOOLEAN
			-- Did last operation have an error?
		do
			Result := last_error /= Void
		end

	has_credentials: BOOLEAN
			-- Are authentication credentials configured?
		do
			Result := attached username as u and then not u.is_empty
		end

feature -- Settings (Commands)

	set_smtp_server (a_host: STRING; a_port: INTEGER)
			-- Set SMTP server to `a_host' on `a_port'.
		require
			host_not_empty: not a_host.is_empty
			port_positive: a_port > 0
		do
			smtp_host := a_host
			smtp_port := a_port
		ensure
			host_set: smtp_host.same_string (a_host)
			port_set: smtp_port = a_port
		end

	set_credentials (a_username, a_password: STRING)
			-- Set authentication credentials.
		require
			username_not_empty: not a_username.is_empty
		do
			username := a_username
			password := a_password
		ensure
			username_set: attached username as u and then u.same_string (a_username)
			password_set: attached password as p and then p.same_string (a_password)
		end

	set_timeout (a_seconds: INTEGER)
			-- Set connection timeout.
		require
			positive_timeout: a_seconds > 0
		do
			timeout := a_seconds
		ensure
			timeout_set: timeout = a_seconds
		end

feature -- Connection (Commands)

	connect
			-- Connect to SMTP server (plain connection, use STARTTLS for encryption).
		require
			server_configured: not smtp_host.is_empty
			not_connected: not is_connected
		do
			last_error := Void
			create smtp_client.make (smtp_host, smtp_port)
			if attached smtp_client as l_client then
				l_client.connect
				if l_client.has_error then
					last_error := l_client.last_error
				else
					-- Send EHLO to start session
					l_client.send_ehlo
					if l_client.has_error then
						last_error := l_client.last_error
					end
				end
			end
		ensure
			connected_or_error: is_connected or has_error
			port_unchanged: smtp_port = old smtp_port
			host_unchanged: smtp_host.same_string (old smtp_host.twin)
		end

	connect_tls
			-- Connect to SMTP server with implicit TLS (port 465).
		require
			server_configured: not smtp_host.is_empty
			not_connected: not is_connected
		do
			last_error := Void
			create smtp_client.make (smtp_host, smtp_port)
			if attached smtp_client as l_client then
				l_client.connect_tls
				if l_client.has_error then
					last_error := l_client.last_error
				else
					-- Send EHLO to start session
					l_client.send_ehlo
					if l_client.has_error then
						last_error := l_client.last_error
					end
				end
			end
		end

	start_tls
			-- Upgrade existing connection to TLS (STARTTLS).
		require
			connected: is_connected
			not_already_tls: not is_tls_active
		do
			last_error := Void
			if attached smtp_client as l_client then
				l_client.start_tls
				if l_client.has_error then
					last_error := l_client.last_error
				else
					-- Re-send EHLO after TLS upgrade
					l_client.send_ehlo
					if l_client.has_error then
						last_error := l_client.last_error
					end
				end
			end
		end

	authenticate
			-- Authenticate with stored credentials.
		require
			connected: is_connected
			credentials_set: has_credentials
		do
			last_error := Void
			if attached smtp_client as l_client then
				if attached username as u and attached password as p then
					l_client.authenticate_plain (u, p)
					if l_client.has_error then
						last_error := l_client.last_error
					end
				end
			end
		end

	disconnect
			-- Disconnect from server.
		do
			if attached smtp_client as l_client then
				l_client.disconnect
			end
			smtp_client := Void
			last_error := Void
		ensure
			not_connected: not is_connected
			no_error: not has_error
		end

feature -- Email Operations

	send (a_message: SE_MESSAGE): BOOLEAN
			-- Send `a_message'. Return True if successful.
		require
			connected: is_connected
			authenticated: is_authenticated
			message_valid: a_message.is_valid
		do
			last_error := Void
			if attached smtp_client as l_client then
				l_client.send_message (a_message)
				if l_client.has_error then
					last_error := l_client.last_error
					Result := False
				else
					Result := True
				end
			else
				Result := False
				last_error := "Not connected"
			end
		ensure
			error_on_failure: not Result implies has_error
		end

	create_message: SE_MESSAGE
			-- Create new email message.
		do
			create Result.make
		end

feature {NONE} -- Implementation

	smtp_client: detachable SE_SMTP_CLIENT
			-- SMTP client for sending

	username: detachable STRING
			-- Authentication username

	password: detachable STRING
			-- Authentication password

	timeout: INTEGER
			-- Connection timeout in seconds

feature {NONE} -- Constants

	Default_smtp_starttls_port: INTEGER = 587
			-- Default SMTP port for STARTTLS connections

	Default_timeout_seconds: INTEGER = 30
			-- Default connection timeout in seconds

invariant
	host_exists: smtp_host /= Void
	port_positive: smtp_port > 0
	timeout_positive: timeout > 0
	auth_requires_connection: is_authenticated implies is_connected
	tls_requires_connection: is_tls_active implies is_connected

end
