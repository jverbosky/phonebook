# note - some unit tests depend on database contents, so run tests after dropping/seeding tables
# database contents-dependent tests: 7

require "minitest/autorun"
require_relative "../methods/phonebook_ops.rb"
load "../methods/local_env.rb" if File.exists?("../methods/local_env.rb")

class TestPhonebookOps < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!  # this forces the assertions to run in order, only vital for 7

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

  def test_7_verify_get_names
    names = ["Doe, Jen", "Fairbanks Jr., Jim Bob", "Smith, Joy", "Doe, Jill", "Langer, Jeff", "Smith-Lewis, June", "Doe, John", "Scott M.D., Jack", "", "Doe III, Joe", "Smith, Jane C.", ""]
    result = get_names()
    assert_equal(names, result)
  end

  def test_8_verify_abbreviated_states_array
    states = ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"]
    result = state_array()
    assert_equal(states, result)
  end

  def test_9_capitalize_initials_v1
    initials = "m.b.a."
    result = capitalize_initials(initials)
    assert_equal("M.B.A", result)
  end

  def test_10_capitalize_initials_v2
    initials = "n.o"
    result = capitalize_initials(initials)
    assert_equal("N.O", result)
  end

  def test_11_capitalize_hyphenated_names_v1
    h_name = "test-name"
    result = capitalize_hyphenated_name(h_name)
    assert_equal("Test-Name", result)
  end

  def test_12_capitalize_hyphenated_names_v2
    h_name = "long-test-name"
    result = capitalize_hyphenated_name(h_name)
    assert_equal("Long-Test-Name", result)
  end

  def test_13_capitalize_items_single_name_v1
    item = "jake"
    result = capitalize_items(item)
    assert_equal("Jake", result)
  end

  def test_14_capitalize_items_single_name_v2
    item = "Jake"
    result = capitalize_items(item)
    assert_equal("Jake", result)
  end

  def test_15_capitalize_items_single_name_v3
    item = "JAKE"
    result = capitalize_items(item)
    assert_equal("Jake", result)
  end

  def test_16_capitalize_items_multiple_names_v1
    item = "long city name"
    result = capitalize_items(item)
    assert_equal("Long City Name", result)
  end

  def test_17_capitalize_items_multiple_names_v1
    item = "Long City Name"
    result = capitalize_items(item)
    assert_equal("Long City Name", result)
  end

  def test_18_capitalize_items_multiple_names_v1
    item = "LONG CITY NAME"
    result = capitalize_items(item)
    assert_equal("Long City Name", result)
  end

  def test_19_capitalize_items_initials_v1
    item = "d.c"
    result = capitalize_items(item)
    assert_equal("D.C.", result)
  end

  def test_20_capitalize_items_initials_v1
    item = "D.C."
    result = capitalize_items(item)
    assert_equal("D.C.", result)
  end

  def test_21_capitalize_items_initials_v3
    item = "D.c"
    result = capitalize_items(item)
    assert_equal("D.C.", result)
  end

  def test_22_capitalize_items_mixed_initials_and_name_v1
    item = "d.c. highway"
    result = capitalize_items(item)
    assert_equal("D.C. Highway", result)
  end

  def test_23_capitalize_items_mixed_initials_and_name_v2
    item = "D.C. Highway"
    result = capitalize_items(item)
    assert_equal("D.C. Highway", result)
  end

  def test_24_capitalize_items_mixed_initials_and_name_v3
    item = "D.C. HIGHWAY"
    result = capitalize_items(item)
    assert_equal("D.C. Highway", result)
  end

  def test_25_capitalize_items_multiple_mixed_initials_and_name_v1
    item = "annie d.e. grant m.b.a."
    result = capitalize_items(item)
    assert_equal("Annie D.E. Grant M.B.A.", result)
  end

  def test_26_capitalize_items_multiple_mixed_initials_and_name_v2
    item = "Annie D.E. Grant M.B.A."
    result = capitalize_items(item)
    assert_equal("Annie D.E. Grant M.B.A.", result)
  end

  def test_27_capitalize_items_multiple_mixed_initials_and_name_v3
    item = "ANNIE D.E. GRANT M.B.A."
    result = capitalize_items(item)
    assert_equal("Annie D.E. Grant M.B.A.", result)
  end

  def test_28_capitalize_items_abbreviation_and_name_v1
    item = "dr. smith"
    result = capitalize_items(item)
    assert_equal("Dr. Smith", result)
  end

  def test_29_capitalize_items_abbreviation_and_name_v2
    item = "Dr. Smith"
    result = capitalize_items(item)
    assert_equal("Dr. Smith", result)
  end

  def test_30_capitalize_items_abbreviation_and_name_v3
    item = "DR. SMITH"
    result = capitalize_items(item)
    assert_equal("Dr. Smith", result)
  end

  def test_31_capitalize_items_street_address_v1
    item = "103 sunshine lane"
    result = capitalize_items(item)
    assert_equal("103 Sunshine Lane", result)
  end

  def test_32_capitalize_items_street_address_v2
    item = "103 Sunshine Lane"
    result = capitalize_items(item)
    assert_equal("103 Sunshine Lane", result)
  end

  def test_33_capitalize_items_street_address_v3
    item = "103 SUNSHINE LANE"
    result = capitalize_items(item)
    assert_equal("103 Sunshine Lane", result)
  end

  def test_34_capitalize_items_abbreviation_and_hyphenated_name_v1
    item = "jessica c. smith-hayer"
    result = capitalize_items(item)
    assert_equal("Jessica C. Smith-Hayer", result)
  end

  def test_35_capitalize_items_abbreviation_and_hyphenated_name_v2
    item = "Jessica C. Smith-Hayer"
    result = capitalize_items(item)
    assert_equal("Jessica C. Smith-Hayer", result)
  end

  def test_36_capitalize_items_abbreviation_and_hyphenated_name_v3
    item = "JESSICA C. SMITH-HAYER"
    result = capitalize_items(item)
    assert_equal("Jessica C. Smith-Hayer", result)
  end

  def test_37_capitalize_items_street_address_abbreviation_and_hyphenated_name_v1
    item = "523 here-you-are st."
    result = capitalize_items(item)
    assert_equal("523 Here-You-Are St.", result)
  end

  def test_38_capitalize_items_street_address_abbreviation_and_hyphenated_name_v2
    item = "523 Here-You-Are St."
    result = capitalize_items(item)
    assert_equal("523 Here-You-Are St.", result)
  end

  def test_39_capitalize_items_street_address_abbreviation_and_hyphenated_name_v3
    item = "523 HERE-YOU-ARE ST."
    result = capitalize_items(item)
    assert_equal("523 Here-You-Are St.", result)
  end





end