# !NOTE!
# - need to use the unit test version of load local_env.rb for unit tests to work

# Tip - to run the test with a specific seed value (i.e. one that is failing):
#   ruby .\test_phonebook_ops.rb --seed 6666

require "minitest/autorun"
require_relative "../methods/phonebook_ops.rb"
load "../methods/1_drop_and_create_tables.rb"  # run the script to drop tables
load "../methods/2_add_data_tables.rb"  # run the script to seed tables

class TestPhonebookOps < Minitest::Test

  def test_1_verify_database_connection
    conn = open_db()
    conn_name = conn.to_s
    result = conn_name.include? "#<PG::Connection:"
    conn.close if conn
    assert_equal(true, result)
  end

  def test_2_verify_empty_hash_if_no_existing_entry
    entry_hash = {}
    result = get_entry("Unknown", "User")
    assert_equal(entry_hash, result)
  end

  def test_3_verify_user_hash_for_existing_entry
    entry_hash = {"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
    result = get_entry("John", "Doe")
    assert_equal(entry_hash, result)
  end

  def test_4_verify_names_rotated_v1_evenly_divisible_by_3
    rotated = ["Doe, Jen", "Doe, Jill", "Doe, John", "Fairbanks Jr., Jim Bob", "Langer, Jeff", "Smith-Lewis, June", "Smith, Jane C.", "Smith, Joy", "Doe III, Joe"]
    names = ["Doe, Jen", "Fairbanks Jr., Jim Bob", "Smith, Jane C.", "Doe, Jill", "Langer, Jeff", "Smith, Joy", "Doe, John", "Smith-Lewis, June", "Doe III, Joe"]
    result = rotate_names(names)
    assert_equal(rotated, result)
  end

  def test_5_verify_names_rotated_v2_remainer_1_after_divided_by_3
    rotated = ["Doe, Jen", "Langer, Jeff", "Doe III, Joe", "Fairbanks Jr., Jim Bob", "Smith, Joy", "Scott M.D., Jack", "Smith, Jane C.", "Doe, John", "", "Doe, Jill", "Smith-Lewis, June", ""]
    names = ["Doe, Jen", "Fairbanks Jr., Jim Bob", "Smith, Jane C.", "Doe, Jill", "Langer, Jeff", "Smith, Joy", "Doe, John", "Smith-Lewis, June", "Doe III, Joe", "Scott M.D., Jack"]
    result = rotate_names(names)
    assert_equal(rotated, result)
  end

  def test_6_verify_names_rotated_v3_remainer_2_after_divided_by_3
    rotated = ["Doe, Jen", "Langer, Jeff", "Smith-Lewis, June", "Fairbanks Jr., Jim Bob", "Smith, Joy", "Doe III, Joe", "Smith, Jane C.", "Doe, John", "Scott M.D., Jack", "Doe, Jill", "Roberts, Jake", ""]
    names = ["Doe, Jen", "Fairbanks Jr., Jim Bob", "Smith, Jane C.", "Doe, Jill", "Langer, Jeff", "Smith, Joy", "Doe, John", "Roberts, Jake", "Smith-Lewis, June", "Doe III, Joe", "Scott M.D., Jack"]
    result = rotate_names(names)
    assert_equal(rotated, result)
  end

  # need to provide array of names at all states (initial seeding, after writing to db, after updating record in db)
  def test_7_verify_get_names_from_db
    user_array = get_names()
    names = [["Doe, Jen", "Fairbanks Jr., Jim Bob", "Smith, Joy", "Doe, Jill", "Langer, Jeff", "Smith-Lewis, June", "Doe, John", "Scott M.D., Jack", "", "Doe III, Joe", "Smith, Jane C.", ""],
             ["Doe, Jen", "Fairbanks Jr., Jim Bob", "Smith, Jane C.", "Doe, Jill", "Langer, Jeff", "Smith, Joy", "Doe, John", "Roberts, Jake", "Smith-Lewis, June", "Doe III, Joe", "Scott M.D., Jack", ""],
             ["Doe, Jen", "Fairbanks Jr., Jim Bob", "Smith, Jane C.", "Doe, Jill", "Langer, Jeff", "Smith, Joy", "Doe, John", "Robertson, Jake", "Smith-Lewis, June", "Doe III, Joe", "Scott M.D., Jack", ""],
             ["Doe, Jen", "Fairbanks Jr., Jim Bob", "Scott M.D., Jack", "Doe, Jill", "Langer, Jeff", "Smith, Jane C.", "Doe, John", "Roberts, Jake", "Smith, Joy", "Doe III, Joe", "Robertson, Jake", "Smith-Lewis, June"]]
    result = names.include? user_array
    assert_equal(true, result)
  end

  def test_8_verify_abbreviated_states_array_contents
    states = ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"]
    result = state_array()
    assert_equal(states, result)
  end

  def test_9_verify_capitalize_initials_v1
    initials = "m.b.a."
    result = capitalize_initials(initials)
    assert_equal("M.B.A", result)
  end

  def test_10_verify_capitalize_initials_v2
    initials = "n.o"
    result = capitalize_initials(initials)
    assert_equal("N.O", result)
  end

  def test_11_verify_capitalize_hyphenated_names_v1
    h_name = "test-name"
    result = capitalize_hyphenated_name(h_name)
    assert_equal("Test-Name", result)
  end

  def test_12_verify_capitalize_hyphenated_names_v2
    h_name = "long-test-name"
    result = capitalize_hyphenated_name(h_name)
    assert_equal("Long-Test-Name", result)
  end

  def test_13_verify_capitalize_items_single_name_v1
    item = "jake"
    result = capitalize_items(item)
    assert_equal("Jake", result)
  end

  def test_14_verify_capitalize_items_single_name_v2
    item = "Jake"
    result = capitalize_items(item)
    assert_equal("Jake", result)
  end

  def test_15_verify_capitalize_items_single_name_v3
    item = "JAKE"
    result = capitalize_items(item)
    assert_equal("Jake", result)
  end

  def test_16_verify_capitalize_items_multiple_names_v1
    item = "long city name"
    result = capitalize_items(item)
    assert_equal("Long City Name", result)
  end

  def test_17_verify_capitalize_items_multiple_names_v1
    item = "Long City Name"
    result = capitalize_items(item)
    assert_equal("Long City Name", result)
  end

  def test_18_verify_capitalize_items_multiple_names_v1
    item = "LONG CITY NAME"
    result = capitalize_items(item)
    assert_equal("Long City Name", result)
  end

  def test_19_verify_capitalize_items_initials_v1
    item = "d.c"
    result = capitalize_items(item)
    assert_equal("D.C.", result)
  end

  def test_20_verify_capitalize_items_initials_v1
    item = "D.C."
    result = capitalize_items(item)
    assert_equal("D.C.", result)
  end

  def test_21_verify_capitalize_items_initials_v3
    item = "D.c"
    result = capitalize_items(item)
    assert_equal("D.C.", result)
  end

  def test_22_verify_capitalize_items_mixed_initials_and_name_v1
    item = "d.c. highway"
    result = capitalize_items(item)
    assert_equal("D.C. Highway", result)
  end

  def test_23_verify_capitalize_items_mixed_initials_and_name_v2
    item = "D.C. Highway"
    result = capitalize_items(item)
    assert_equal("D.C. Highway", result)
  end

  def test_24_verify_capitalize_items_mixed_initials_and_name_v3
    item = "D.C. HIGHWAY"
    result = capitalize_items(item)
    assert_equal("D.C. Highway", result)
  end

  def test_25_verify_capitalize_items_multiple_mixed_initials_and_name_v1
    item = "annie d.e. grant m.b.a."
    result = capitalize_items(item)
    assert_equal("Annie D.E. Grant M.B.A.", result)
  end

  def test_26_verify_capitalize_items_multiple_mixed_initials_and_name_v2
    item = "Annie D.E. Grant M.B.A."
    result = capitalize_items(item)
    assert_equal("Annie D.E. Grant M.B.A.", result)
  end

  def test_27_verify_capitalize_items_multiple_mixed_initials_and_name_v3
    item = "ANNIE D.E. GRANT M.B.A."
    result = capitalize_items(item)
    assert_equal("Annie D.E. Grant M.B.A.", result)
  end

  def test_28_verify_capitalize_items_abbreviation_and_name_v1
    item = "dr. smith"
    result = capitalize_items(item)
    assert_equal("Dr. Smith", result)
  end

  def test_29_verify_capitalize_items_abbreviation_and_name_v2
    item = "Dr. Smith"
    result = capitalize_items(item)
    assert_equal("Dr. Smith", result)
  end

  def test_30_verify_capitalize_items_abbreviation_and_name_v3
    item = "DR. SMITH"
    result = capitalize_items(item)
    assert_equal("Dr. Smith", result)
  end

  def test_31_verify_capitalize_items_street_address_v1
    item = "103 sunshine lane"
    result = capitalize_items(item)
    assert_equal("103 Sunshine Lane", result)
  end

  def test_32_verify_capitalize_items_street_address_v2
    item = "103 Sunshine Lane"
    result = capitalize_items(item)
    assert_equal("103 Sunshine Lane", result)
  end

  def test_33_verify_capitalize_items_street_address_v3
    item = "103 SUNSHINE LANE"
    result = capitalize_items(item)
    assert_equal("103 Sunshine Lane", result)
  end

  def test_34_verify_capitalize_items_abbreviation_and_hyphenated_name_v1
    item = "jessica c. smith-hayer"
    result = capitalize_items(item)
    assert_equal("Jessica C. Smith-Hayer", result)
  end

  def test_35_verify_capitalize_items_abbreviation_and_hyphenated_name_v2
    item = "Jessica C. Smith-Hayer"
    result = capitalize_items(item)
    assert_equal("Jessica C. Smith-Hayer", result)
  end

  def test_36_verify_capitalize_items_abbreviation_and_hyphenated_name_v3
    item = "JESSICA C. SMITH-HAYER"
    result = capitalize_items(item)
    assert_equal("Jessica C. Smith-Hayer", result)
  end

  def test_37_verify_capitalize_items_street_address_abbreviation_and_hyphenated_name_v1
    item = "523 here-you-are st."
    result = capitalize_items(item)
    assert_equal("523 Here-You-Are St.", result)
  end

  def test_38_verify_capitalize_items_street_address_abbreviation_and_hyphenated_name_v2
    item = "523 Here-You-Are St."
    result = capitalize_items(item)
    assert_equal("523 Here-You-Are St.", result)
  end

  def test_39_verify_capitalize_items_street_address_abbreviation_and_hyphenated_name_v3
    item = "523 HERE-YOU-ARE ST."
    result = capitalize_items(item)
    assert_equal("523 Here-You-Are St.", result)
  end

  def test_40_verify_hash_items_capitalized
    formatted = {"fname"=>"Jake L.", "lname"=>"Roberts Jr. M.D.", "addr"=>"328 Oak-Dale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    entry_hash = {"fname"=>"jake l.", "lname"=>"roberts jr. m.d.", "addr"=>"328 oak-dale drive", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = format_hash(entry_hash)
    assert_equal(formatted, result)
  end

  def test_41_verify_duplicate_entry_true_v1
    entry_hash = {"fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
    result = duplicate_entry?(entry_hash)
    assert_equal(true, result)
  end

  def test_42_verify_duplicate_entry_true_v2
    entry_hash = {"fname"=>"john", "lname"=>"doe", "addr"=>"606 jacobs street", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
    result = duplicate_entry?(entry_hash)
    assert_equal(true, result)
  end

  def test_43_verify_duplicate_entry_false_v1
    entry_hash = {"fname"=>"Jon", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
    result = duplicate_entry?(entry_hash)
    assert_equal(false, result)
  end

  def test_44_verify_duplicate_entry_false_v2
    entry_hash = {"fname"=>"John", "lname"=>"Doe", "addr"=>"8606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
    result = duplicate_entry?(entry_hash)
    assert_equal(false, result)
  end

  def test_45_verify_no_feedback_new_entry_no_issues
    feedback = ""
    entry_hash = {"fname"=>"New", "lname"=>"Entry", "addr"=>"1 A Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125551234", "home"=>"4125552345", "work"=>"4125553456"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_46_verify_no_feedback_update_entry_with_id_no_issues
    feedback = ""
    entry_hash = {"fname"=>"Update", "lname"=>"Entry", "id"=>"11", "addr"=>"1 A Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125551234", "home"=>"4125552345", "work"=>"4125553456"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_47_verify_feedback_on_duplicate_new_entry
    feedback = "That entry already exists - please enter details for another entry."
    entry_hash = {"fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_48_verify_feedback_on_first_name_too_short
    feedback = "The first name is too short - please enter at least two letters for the first name."
    entry_hash = {"id"=>"11", "fname"=>"J", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_49_verify_feedback_on_first_name_too_long
    feedback = "The value for 'fname' is too long - please use a shorter value."
    entry_hash = {"id"=>"11", "fname"=>"Jakeasdfasdfoiuyasdfoiuyasdfiouyasdfoiuyasdfiouyasdfoiuyasdfoiuyasdfoiuy", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_50_verify_feedback_on_last_name_too_short
    feedback = "The last name is too short - please enter at least two letters for the last name."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"R", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_51_verify_feedback_on_last_name_too_long
    feedback = "The value for 'lname' is too long - please use a shorter value."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertsonasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiasdfpoiu", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_52_verify_feedback_on_address_too_short
    feedback = "Please specify a house number and a street name for the address."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_53_verify_feedback_on_address_too_long
    feedback = "The value for 'addr' is too long - please use a shorter value."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Driveasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuy", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_54_verify_feedback_on_city_too_long
    feedback = "The value for 'city' is too long - please use a shorter value."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburghasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuy", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_55_verify_feedback_on_state_too_long
    feedback = "Please use a valid two-letter abbreviation for the state name."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"Pennsylvania", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_56_verify_feedback_on_zip_too_short
    feedback = "Please enter five digits for the zip code."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"1521", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_57_verify_feedback_on_zip_too_long
    feedback = "Please enter five digits for the zip code."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"152136", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_58_verify_feedback_on_mobile_phone_number_too_short
    feedback = "Please enter ten digits for the mobile phone number."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"412555590", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_59_verify_feedback_on_work_phone_number_too_long
    feedback = "Please enter ten digits for the work phone number."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"41255568435"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_60_verify_feedback_on_invalid_characters_in_first_name
    feedback = "The name should only contain letters, hyphens or periods."
    entry_hash = {"id"=>"11", "fname"=>"Jake2", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_61_verify_feedback_on_invalid_characters_in_street_address
    feedback = "The street address should only contain numbers, letters, hyphens or periods."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"#328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_62_verify_feedback_on_invalid_characters_in_city
    feedback = "The city name should only contain letters, hyphens or periods."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"P1ttsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_63_verify_feedback_on_invalid_characters_in_zip_code
    feedback = "The value for 'zip' should only have numbers."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15O13", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_64_verify_feedback_on_invalid_characters_in_mobile_phone_number
    feedback = "The value for 'mobile' should only have numbers."
    entry_hash = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"41255a7359", "home"=>"4125558349", "work"=>"4125556843"}
    result = check_values(entry_hash)
    assert_equal(feedback, result)
  end

  def test_65_verify_resulting_hash_for_write_db_empty_work_phone
    formatted = {"fname"=>"Jake", "lname"=>"Roberts", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>""}
    entry_hash = {"fname"=>"jake", "lname"=>"roberts", "addr"=>"328 oakdale drive", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>""}
    result = write_db(entry_hash)
    assert_equal(formatted, result)
  end

  def test_66_verify_pull_record_via_first_name
    db_hash = [{"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}]
    search_array = {"value"=>"joh", "column"=>"fname"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_67_verify_pull_record_via_last_name
    db_hash = [{"id"=>"7", "fname"=>"Jeff", "lname"=>"Langer", "addr"=>"2731 Platinum Drive", "city"=>"Monroeville", "state"=>"PA", "zip"=>"15140", "mobile"=>"8785550195", "home"=>"8785556851", "work"=>"4125550172"}]
    search_array = {"value"=>"lan", "column"=>"lname"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_68_verify_pull_record_via_street_address
    db_hash = [{"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}]
    search_array = {"value"=>"60", "column"=>"addr"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_69_verify_pull_record_via_city
    db_hash = [{"id"=>"8", "fname"=>"Jack", "lname"=>"Scott M.D.", "addr"=>"4168 University Drive", "city"=>"Mt. Lebanon", "state"=>"PA", "zip"=>"15216", "mobile"=>"4125550107", "home"=>"4125552529", "work"=>"4125550113"}]
    search_array = {"value"=>"mt.", "column"=>"city"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_70_verify_pull_record_via_zip
    db_hash = [{"id"=>"4", "fname"=>"Jill", "lname"=>"Doe", "addr"=>"2294 Washington Avenue", "city"=>"Sewickley", "state"=>"PA", "zip"=>"15143", "mobile"=>"7245550136", "home"=>"7245551953", "work"=>"4125550150"}]
    search_array = {"value"=>"143", "column"=>"zip"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_71_verify_pull_two_records_via_mobile_phone_number
    db_hash = [{"id"=>"7", "fname"=>"Jeff", "lname"=>"Langer", "addr"=>"2731 Platinum Drive", "city"=>"Monroeville", "state"=>"PA", "zip"=>"15140", "mobile"=>"8785550195", "home"=>"8785556851", "work"=>"4125550172"},
               {"id"=>"10", "fname"=>"Joy", "lname"=>"Smith", "addr"=>"879 Shinn Avenue", "city"=>"Imperial", "state"=>"PA", "zip"=>"15071", "mobile"=>"7245550195", "home"=>"7245551579", "work"=>"4125550131"}]
    search_array = {"value"=>"195", "column"=>"mobile"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_72_verify_pull_records_via_work_phone_number
    db_hash = [{"id"=>"7", "fname"=>"Jeff", "lname"=>"Langer", "addr"=>"2731 Platinum Drive", "city"=>"Monroeville", "state"=>"PA", "zip"=>"15140", "mobile"=>"8785550195", "home"=>"8785556851", "work"=>"4125550172"}]
    search_array = {"value"=>"172", "column"=>"work"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_73_verify_pull_records_via_empty_work_phone_number
    db_hash = [{"id"=>"3", "fname"=>"Jim Bob", "lname"=>"Fairbanks Jr.", "addr"=>"3801 Beechwood Drive", "city"=>"Wexford", "state"=>"PA", "zip"=>"15090", "mobile"=>"4125550167", "home"=>"4125553878", "work"=>""}]
    search_array = {"value"=>"", "column"=>"work"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_74_verify_feedback_for_empty_search_on_first_name_no_results
    db_hash = [{"addr" => "No matching record - please try again."}]
    search_array = {"value"=>"", "column"=>"fname"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_75_verify_feedback_for_populated_search_on_last_name_no_results
    db_hash = [{"addr" => "No matching record - please try again."}]
    search_array = {"value"=>"Lastname", "column"=>"lname"}
    result = pull_records(search_array)
    assert_equal(db_hash, result)
  end

  def test_76_verify_resulting_hash_for_update_record_empty_mobile
    formatted = {"fname"=>"Jake", "lname"=>"Robertson", "addr"=>"1328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"", "home"=>"4125558349", "work"=>"4125556843"}
    entry_hash = {"fname"=>"jake", "lname"=>"robertson", "addr"=>"1328 oakdale drive", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15213", "mobile"=>"", "home"=>"4125558349", "work"=>"4125556843"}
    result = write_db(entry_hash)
    assert_equal(formatted, result)
  end

  # test delete_record() manually in phonebook_ops.rb sandbox test - breaks other unit tests

end