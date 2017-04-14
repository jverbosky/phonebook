require "minitest/autorun"
require_relative "../methods/phonebook_ops.rb"
load "../methods/local_env.rb" if File.exists?("../methods/local_env.rb")

class TestPhonebookOps < Minitest::Test

  def test_1_verify_database_connection
    conn = open_db()
    conn_name = conn.to_s
    result = conn_name.include? "#<PG::Connection:"
    conn.close if conn
    assert_equal(true, result)
  end

  def test_2_get_existing_entry
    entry_hash = {"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
    db_hash = get_entry("John", "Doe")
    assert_equal(entry_hash, db_hash)
  end



end