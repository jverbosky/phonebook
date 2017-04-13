require 'pg'
load "./local_env.rb" if File.exists?("./local_env.rb")

# Method to open a connection to the PostgreSQL database
def open_db()
  begin
    # connect to the database
    db_params = {
          host: ENV['host'],  # AWS link
          port:ENV['port'],  # AWS port, always 5432
          dbname:ENV['dbname'],
          user:ENV['dbuser'],
          password:ENV['dbpassword']
        }
    conn = PG::Connection.new(db_params)
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  end
end

# Method to return entry hash from PostgreSQL db for specified name
def get_entry(first_name, last_name)
  begin
    conn = open_db()
    conn.prepare('q_statement',
                 "select *
                  from listings
                  where fname = '#{first_name}'
                  and lname = '#{last_name}'")
    user_hash = conn.exec_prepared('q_statement')
    conn.exec("deallocate q_statement")
    return user_hash[0]
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to rearrange names for (top > down) then (left > right) column population
def rotate_names(names)
  quotient = names.count/3  # baseline for number of names per column
  names.count % 3 > 0 ? remainder = 1 : remainder = 0  # remainder to ensure no names dropped
  max_column_count = quotient + remainder  # add quotient & remainder to get max number of names per column
  matrix = names.each_slice(max_column_count).to_a    # names divided into three (inner) arrays
  results = matrix[0].zip(matrix[1], matrix[2]).flatten   # names rearranged (top > bottom) then (left > right) in table
  results.each_index { |name| results[name] ||= "" }  # replace any nils (due to uneven .zip) with ""
end

# Method to return array of sorted/transposed names from db for populating /list_names table
def get_names()
  names = []  # array to hold names
  begin
    conn = open_db()
    conn.prepare('q_statement',
                 "select fname, lname from listings order by lname, fname")
    query = conn.exec_prepared('q_statement')
    conn.exec("deallocate q_statement")
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
  query.each { |pair| names.push(pair["lname"] + ", " + pair["fname"]) }
  names
  sorted = names.count > 3 ? rotate_names(names) : names  # rerrange names if more than 3 names
end

def state_array
  %w(AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY)
end

# Method to validate values prior to committing to database
def check_values(entry_hash)
  flag = 0
  feedback = ""
  detail = ""
  entry_hash.each do |key, value|
     flag = 1 if key == "fname" && value.length < 2
     flag = 2 if key == "lname" && value.length < 2
     flag = 3 if key == "addr" && value.split(" ").length < 3
    (flag = 4; detail = key) if key =~ /fname|lname|addr/ && value.length > 50
    (flag = 4; detail = key) if key == "city" && value.length > 25
     flag = 5 if key == "city" && value.length < 2
     flag = 6 if key == "zip" && value.length != 5
    (flag = 7; detail = key) if key =~ /mobile|home|work/ && value.length != 10
     flag = 8 if key == "state" && (!state_array.include? value.upcase)
     flag = 9 if key =~ /fname|lname/ && value =~ /[^a-zA-Z. ]/
     flag = 10 if key == "city" && value =~ /[^a-zA-Z. ]/
    (flag = 11; detail = key) if key =~ /zip|mobile|home|work/ && value =~ /[^0-9.,]/
  end
  case flag
    when 1 then feedback = "The first name is too short - please enter at least two letters for the first name."
    when 2 then feedback = "The last name is too short - please enter at least two letters for the last name."
    when 3 then feedback = "Please specify a house number and a street name for the address."
    when 4 then feedback = "The value for '#{detail}' is too long - please try again with a shorter value."
    when 5 then feedback = "The city name is too short - please enter at least two letters for the city name."
    when 6 then feedback = "Please enter five digits for the zip code."
    when 7 then feedback = "Please enter ten digits for the #{detail} phone number."
    when 8 then feedback = "Please use a valid two-letter abbreviation for the state name."
    when 9 then feedback = "The name should only contain letters - please try again."
    when 10 then feedback = "The city name should only contain letters - please try again."
    when 11 then feedback = "The value for '#{detail}' should only have numbers - please try again."
  end
  return feedback
end

# Method to capitalize initials (ex: m.b.a > M.B.A.)
def capitalize_initials(item)
  if item.include? "."
    array = item.split(".")
    cap_array = array.each { |word| word.capitalize! }
    capitalized = cap_array.join(".")
  else
    item
  end
end

# Method to capitalize hyphenated names (ex: smith-hayer > Smith-Hayer)
def capitalize_hyphenated_name(item)
  if item.include? "-"
    array = item.split("-")
    cap_array = array.each { |word| word.capitalize! }
    capitalized = cap_array.join("-")
  else
    item
  end
end

# Method to capitalize phonebook entries
def capitalize_items(item)
  cap_array = []
  array = item.split(" ")
  array.each do |word|
    capped = word.capitalize  # use to evaluate case variations (word, Word, WORD)
    if word.include? "."
      cap_array.push(capitalize_initials(word) + ".")
    elsif word.include? "-"
      cap_array.push(capitalize_hyphenated_name(word))
    elsif word =~ /[0-9]/  # don't use .capitalize on numbers (drops them)
      cap_array.push(word)
    elsif capped == nil  # don't use .capitalize on capitalized words (drops them)
      cap_array.push(word)
    else
      cap_array.push(capped)
    end
  end
  capitalized = cap_array.join(" ")
end

# Method to add current entry hash to db
def write_db(entry_hash)
  begin
    conn = open_db() # open database for updating
    max_id = conn.exec("select max(id) from listings")[0]  # determine current max index (id) in details table
    max_id["max"] == nil ? v_id = 1 : v_id = max_id["max"].to_i + 1  # set index variable based on current max index value
    v_fname = capitalize_items(entry_hash["fname"])  # prepare data from entry_hash for database insert
    v_lname = capitalize_items(entry_hash["lname"])
    v_addr = capitalize_items(entry_hash["addr"])
    v_city = capitalize_items(entry_hash["city"])
    v_state = entry_hash["state"].upcase
    v_zip = entry_hash["zip"]
    v_mobile = entry_hash["mobile"]
    v_home = entry_hash["home"]
    v_work = entry_hash["work"]
    conn.prepare('q_statement',
                 "insert into listings (id, fname, lname, addr, city, state, zip, mobile, home, work)
                  values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)")  # bind parameters
    conn.exec_prepared('q_statement', [v_id, v_fname, v_lname, v_addr, v_city, v_state, v_zip, v_mobile, v_home, v_work])
    conn.exec("deallocate q_statement")
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to return array of record hashes associated with specified value and column
def pull_records(search_array)
  value = search_array["value"]
  column = search_array["column"]
  results = []  # array to hold all matching hashes
  begin
    conn = open_db()
    query = "select *
             from listings
             where " + column + " ilike $1
             order by lname, fname"
    conn.prepare('q_statement', query)
    rs = conn.exec_prepared('q_statement', ["%" + value + "%"])
    conn.exec("deallocate q_statement")
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
  rs.each { |result| results.push(result) }
  results == [] ? [{"addr" => "No matching record - please try again."}] : results
end

# Method to update any number of values in any number of tables
# - entry hash needs to contain id of current record that needs to be updated
# - order is not important (the id can be anywhere in the hash)
def update_values(entry_hash)
  id = entry_hash["id"]  # determine the id for the current record
  begin
    conn = open_db() # open database for updating
    entry_hash.each do |column, value|  # iterate through entry_hash for each column/value pair
      unless column == "id"  # we do NOT want to update the id
        value = capitalize_items(value) if column =~ /fname|lname|addr|city/
        value.upcase! if column == "state"
        query = "update listings set " + column + " = $2 where id = $1"  # can't use column name as bind parameter
        conn.prepare('q_statement', query)
        rs = conn.exec_prepared('q_statement', [id, value])
        conn.exec("deallocate q_statement")
      end
    end
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to delete a record from the database
def delete_record(id_hash)
  id = id_hash["id"]  # determine the id for the current record
  begin
    conn = open_db() # open database for updating
    query = "delete from listings where id = $1"
    conn.prepare('q_statement', query)
    rs = conn.exec_prepared('q_statement', [id])
    conn.exec("deallocate q_statement")
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
  return "Record successfully deleted!"
end

#-----------------
# Sandbox testing
#-----------------

# p get_entry("John", "Doe")
# {"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}

# entry_hash = {"fname"=>"Jake", "lname"=>"Roberts", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# write_db(entry_hash)

# p get_names()
# ["Doe, Jen", "Fairbanks, Jim Bob", "Smith, Joy", "Doe, Jill", "Langer, Jeff", "Smith, June", "Doe, Joe", "Scott M.D., Jack", "", "Doe, John", "Smith, Jane", ""]

# hash_1 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# hash_1 = {"fname"=>"Jacob", "lname"=>"Robert", "addr"=>"146 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125558888", "home"=>"4125558349", "work"=>"4125556843", "id"=>"11"}
# hash_1 = {"fname"=>"Jake", "lname"=>"Roberts", "id"=>"11", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}

# update_values(hash_1)

# hash_1 = {"fname"=>"larry", "lname"=>"something", "addr"=>"123 Lane Street", "city"=>"Asdf", "state"=>"PA", "zip"=>"12325", "mobile"=>"6549876540", "home"=>"6549873210", "work"=>"6543216548", "id"=>"15"}
# hash_1 = {"fname"=>"lou", "lname"=>"something", "addr"=>"123 lane street", "city"=>"asdf", "state"=>"pa", "zip"=>"12325", "mobile"=>"6549876540", "home"=>"6549873210", "work"=>"6543216548", "id"=>"15"}

# update_values(hash_1)

# First name too short (1)
# hash_2 = {"id"=>"11", "fname"=>"J", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "The name is too short - please enter at least two letters for the name."

# First name too long (50+)
# hash_3 = {"id"=>"11", "fname"=>"Jakeasdfasdfoiuyasdfoiuyasdfiouyasdfoiuyasdfiouyasdfoiuyasdfoiuyasdfoiuy", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "The value for 'fname' is too long - please try again with a shorter value."

# Last name too short (1)
# hash_4 = {"id"=>"11", "fname"=>"Jake", "lname"=>"R", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "The name is too short - please enter at least two letters for the name."

# Last name too long (50+)
# hash_5 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertsonasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiasdfpoiu", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "The value for 'lname' is too long - please try again with a shorter value."

# Address too short (2 words)
# hash_6 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "Please specify a house number and a street name for the address."

# Address too long (50+)
# hash_7 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Driveasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuy", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "The value for 'addr' is too long - please try again with a shorter value."

# City too long (25+)
# hash_8 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburghasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuy", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "The value for 'city' is too long - please try again with a shorter value."

# State too long (2+)
# hash_9 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"Pennsylvania", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "Please use the two-letter abbreviation for the state name."

# Zip too short (4)
# hash_10 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"1521", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "Please enter five digits for the zip code."

# Zip too long (5+)
# hash_11 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"152136", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "Please enter five digits for the zip code."

# Mobile too short (9)
# hash_12 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"412555590", "home"=>"4125558349", "work"=>"4125556843"}
# "Please enter ten digits for the mobile phone number."

# Work too long (10+)
# hash_13 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"41255568435"}
# "Please enter ten digits for the mobile phone number."

# Non-letters in first name
# hash_14 = {"id"=>"11", "fname"=>"Jake2", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# "Your name should only contain letters - please try again."

# Non-numbers in mobile
# hash_15 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"412-555-7359", "home"=>"4125558349", "work"=>"4125556843"}
# "The value for 'mobile' should only have numbers - please try again."

# p check_values(hash_2)
# p check_values(hash_3)
# p check_values(hash_4)
# p check_values(hash_5)
# p check_values(hash_6)
# p check_values(hash_7)
# p check_values(hash_8)
# p check_values(hash_9)
# p check_values(hash_10)
# p check_values(hash_11)
# p check_values(hash_12)
# p check_values(hash_13)
# p check_values(hash_14)
# p check_values(hash_15)

# p capitalize_initials("m.b.a.")  # M.B.A.

# p capitalize_items("jake")  # Jake
# p capitalize_items("Jake")  # Jake
# p capitalize_items("JAKE")  # Jake
# p capitalize_items("Long City Name")  # Long City Name
# p capitalize_items("long city name")  # Long City Name
# p capitalize_items("LONG CITY NAME")  # Long City Name
# p capitalize_items("D.C.")  # D.C.
# p capitalize_items("d.c.")  # D.C.
# p capitalize_items("D.C. Highway")  # D.C. Highway
# p capitalize_items("d.c. highway")  # D.C. Highway
# p capitalize_items("D.C. HIGHWAY")  # D.C. Highway
# p capitalize_items("Annie D.E. Grant M.B.A")  # Annie D.E. Grant M.B.A
# p capitalize_items("annie d.e. grant m.b.a.")  # Annie D.E. Grant M.B.A
# p capitalize_items("ANNIE D.E. GRANT M.B.A")  # Annie D.E. Grant M.B.A
# p capitalize_items("Dr. Smith")  # Dr. Smith
# p capitalize_items("dr. smith")  # Dr. Smith
# p capitalize_items("DR. SMITH")  # Dr. Smith
# p capitalize_items("103 Sunshine Lane")  # 103 Sunshine Lane
# p capitalize_items("103 sunshine lane")  # 103 Sunshine Lane
# p capitalize_items("103 SUNSHINE LANE")  # 103 Sunshine Lane
# p capitalize_items("jessica c. smith-hayer")  # Jessica C. Smith-Hayer
# p capitalize_items("Jessica C. Smith-Hayer")  # Jessica C. Smith-Hayer
# p capitalize_items("JESSICA C. SMITH-HAYER")  # Jessica C. Smith-Hayer
# p capitalize_items("523 here-you-are st.")  # 523 Here-You-Are St.
# p capitalize_items("523 Here-You-Are St.")  # 523 Here-You-Are St.
# p capitalize_items("523 HERE-YOU-ARE ST.")  # 523 Here-You-Are St.

# search_array = {"value"=>"something", "column"=>"fname"}
# [{"addr"=>"No matching record - please try again."}]

# search_array = {"value"=>"doe", "column"=>"lname"}
# [{"id"=>"6", "fname"=>"Jen", "lname"=>"Doe", "addr"=>"3261 Michigan Avenue", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15222", "mobile"=>"7245550190", "home"=>"7245550624", "work"=>"7245550146"},
#  {"id"=>"4", "fname"=>"Jill", "lname"=>"Doe", "addr"=>"2294 Washington Avenue", "city"=>"Sewickley", "state"=>"PA", "zip"=>"15143", "mobile"=>"7245550136", "home"=>"7245551953", "work"=>"4125550150"},
#  {"id"=>"9", "fname"=>"Joe", "lname"=>"Doe", "addr"=>"2391 Losh Lane", "city"=>"Monroeville", "state"=>"PA", "zip"=>"15146", "mobile"=>"4125550184", "home"=>"4125554784", "work"=>"4125550166"},
#  {"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}]

# search_array = {"value"=>"do", "column"=>"lname"}
# [{"id"=>"6", "fname"=>"Jen", "lname"=>"Doe", "addr"=>"3261 Michigan Avenue", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15222", "mobile"=>"7245550190", "home"=>"7245550624", "work"=>"7245550146"},
#  {"id"=>"4", "fname"=>"Jill", "lname"=>"Doe", "addr"=>"2294 Washington Avenue", "city"=>"Sewickley", "state"=>"PA", "zip"=>"15143", "mobile"=>"7245550136", "home"=>"7245551953", "work"=>"4125550150"},
#  {"id"=>"9", "fname"=>"Joe", "lname"=>"Doe", "addr"=>"2391 Losh Lane", "city"=>"Monroeville", "state"=>"PA", "zip"=>"15146", "mobile"=>"4125550184", "home"=>"4125554784", "work"=>"4125550166"},
#  {"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}]

# p pull_records(search_array)