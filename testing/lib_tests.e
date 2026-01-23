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

end
