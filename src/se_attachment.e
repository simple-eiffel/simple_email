note
	description: "Email attachment with file data"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SE_ATTACHMENT

create
	make,
	make_from_file

feature {NONE} -- Initialization

	make (a_name: STRING; a_content_type: STRING; a_data: STRING)
			-- Create attachment with name, content type, and data.
		require
			name_not_empty: not a_name.is_empty
			content_type_not_empty: not a_content_type.is_empty
		do
			internal_name := a_name
			internal_content_type := a_content_type
			internal_data := a_data
		ensure
			name_set: name.same_string (a_name)
			content_type_set: content_type.same_string (a_content_type)
			data_set: data.same_string (a_data)
			is_valid: is_valid
		end

	make_from_file (a_path: STRING)
			-- Create attachment from file at `a_path'.
		require
			path_not_empty: not a_path.is_empty
		do
			-- Extract filename from path
			internal_name := a_path
			internal_content_type := "application/octet-stream"
			internal_data := ""
			-- Actual file reading would happen here
		ensure
			name_set: not name.is_empty
			content_type_set: not content_type.is_empty
			is_valid: is_valid
		end

feature -- Access (Queries)

	name: STRING
			-- Attachment filename
		do
			Result := internal_name
		end

	content_type: STRING
			-- MIME content type
		do
			Result := internal_content_type
		end

	data: STRING
			-- Raw attachment data
		do
			Result := internal_data
		end

	encoded_data: STRING
			-- Base64 encoded data
		do
			-- Would use simple_base64 here
			Result := internal_data
		end

feature -- Status (Boolean Queries)

	is_valid: BOOLEAN
			-- Is attachment valid?
		do
			Result := not internal_name.is_empty and not internal_content_type.is_empty
		end

feature -- Measurement (Integer Queries)

	size: INTEGER
			-- Size in bytes
		do
			Result := internal_data.count
		end

feature {NONE} -- Implementation

	internal_name: STRING
			-- Internal name storage

	internal_content_type: STRING
			-- Internal content type storage

	internal_data: STRING
			-- Internal data storage

invariant
	name_exists: internal_name /= Void
	content_type_exists: internal_content_type /= Void
	data_exists: internal_data /= Void
	valid_definition: is_valid = (not internal_name.is_empty and not internal_content_type.is_empty)
	size_consistent: size = internal_data.count

end
