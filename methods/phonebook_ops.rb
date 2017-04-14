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
    user_hash.to_a.size > 0 ? (return user_hash[0]) : (return {})
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

# Method to hold state appreviations
def state_array
  %w(AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY)
end

# Method to capitalize initials (ex: m.b.a > M.B.A.)
def capitalize_initials(item)
  array = item.split(".")
  cap_array = array.each { |word| word.capitalize! }
  capitalized = cap_array.join(".")
end

# Method to capitalize hyphenated names (ex: smith-hayer > Smith-Hayer)
def capitalize_hyphenated_name(item)
  array = item.split("-")
  cap_array = array.each { |word| word.capitalize! }
  capitalized = cap_array.join("-")
end

# Method to capitalize phonebook entries
def capitalize_items(item)
  cap_array = []
  array = item.split(" ")
  array.each do |word|
    capped = word.capitalize  # use for case variations (word, Word, WORD) evaluation and transform
    if word.include? "."
      cap_array.push(capitalize_initials(word) + ".")
    elsif word.include? "-"
      cap_array.push(capitalize_hyphenated_name(word))
    elsif word =~ /[0-9]/ || capped == nil  # don't use .capitalize on numbers or capitalized words (drops them)
      cap_array.push(word)
    else
      cap_array.push(capped)
    end
  end
  capitalized = cap_array.join(" ")
end

# Method to format raw entry_hash for duplicate comparison and record creation/updates
def format_hash(entry_hash)
  formatted = {}
  entry_hash.each do |column, value|
    if column =~ /fname|lname|addr|city/
      formatted[column] = capitalize_items(value)
    elsif column == "state"
      formatted[column] = value.upcase
    else
      formatted[column] = value
    end
  end
  return formatted
end

# Method to determine if entry is a duplicate or not (same address)
def duplicate_entry?(entry_hash)
  unless entry_hash.include? "id"  # conditional for record updates
    formatted = format_hash(entry_hash)
    db_hash = get_entry(formatted["fname"], formatted["lname"])
    difference = (formatted.to_a - db_hash.to_a).flatten
    difference.size > 0 ? false : true
  else
    false
  end
end

# Method to validate values prior to committing to database
def check_values(entry_hash)
  flag = 0
  feedback = ""
  detail = ""
  flag = 1 if duplicate_entry?(entry_hash)
  entry_hash.each do |column, value|
     flag = 2 if column == "fname" && value.length < 2
     flag = 3 if column == "lname" && value.length < 2
     flag = 4 if column == "addr" && value.split(" ").length < 3
    (flag = 5; detail = column) if column =~ /fname|lname|addr/ && value.length > 50
    (flag = 5; detail = column) if column == "city" && value.length > 25
     flag = 6 if column == "city" && value.length < 2
     flag = 7 if column == "zip" && value.length != 5
    (flag = 8; detail = column) if column =~ /mobile|home|work/ && value.length != 10
     flag = 9 if column == "state" && (!state_array.include? value.upcase)
     flag = 10 if column =~ /fname|lname/ && value =~ /[^a-zA-Z.\- ]/
     flag = 11 if column == "addr" && value =~ /[^0-9a-zA-z.\- ]/
     flag = 12 if column == "city" && value =~ /[^a-zA-Z.\- ]/
    (flag = 13; detail = column) if column =~ /zip|mobile|home|work/ && value =~ /[^0-9]/
  end
  case flag
    when 1 then feedback = "That entry already exists - please enter details for another entry."
    when 2 then feedback = "The first name is too short - please enter at least two letters for the first name."
    when 3 then feedback = "The last name is too short - please enter at least two letters for the last name."
    when 4 then feedback = "Please specify a house number and a street name for the address."
    when 5 then feedback = "The value for '#{detail}' is too long - please use a shorter value."
    when 6 then feedback = "The city name is too short - please enter at least two letters for the city name."
    when 7 then feedback = "Please enter five digits for the zip code."
    when 8 then feedback = "Please enter ten digits for the #{detail} phone number."
    when 9 then feedback = "Please use a valid two-letter abbreviation for the state name."
    when 10 then feedback = "The name should only contain letters, hyphens or periods."
    when 11 then feedback = "The street address should only contain numbers, letters, hyphens or periods."
    when 12 then feedback = "The city name should only contain letters, hyphens or periods."
    when 13 then feedback = "The value for '#{detail}' should only have numbers."
  end
  return feedback
end

# Method to add current entry hash to db
def write_db(entry_hash)
  formatted = format_hash(entry_hash)
  v_fname = formatted["fname"]  # prepare data from entry_hash for database insert
  v_lname = formatted["lname"]
  v_addr = formatted["addr"]
  v_city = formatted["city"]
  v_state = formatted["state"]
  v_zip = formatted["zip"]
  v_mobile = formatted["mobile"]
  v_home = formatted["home"]
  v_work = formatted["work"]
  begin
    conn = open_db() # open database for updating
    max_id = conn.exec("select max(id) from listings")[0]  # determine current max index (id) in details table
    max_id["max"] == nil ? v_id = 1 : v_id = max_id["max"].to_i + 1  # set index variable based on current max index value
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
  return formatted
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
  formatted = format_hash(entry_hash)
  begin
    conn = open_db() # open database for updating
    formatted.each do |column, value|  # iterate through entry_hash for each column/value pair
      unless column == "id"  # we do NOT want to update the id
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
  return formatted
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

# p open_db()
# #<PG::Connection:0x1a5f698>

# p get_entry("John", "Doe")
# {"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}

# p get_entry("Jon", "Doe")
# {}

# entry_hash = {"fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
# p duplicate_entry?(entry_hash)
# true

# entry_hash = {"fname"=>"john", "lname"=>"doe", "addr"=>"606 jacobs street", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
# p duplicate_entry?(entry_hash)
# true

# entry_hash = {"fname"=>"Jon", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
# p duplicate_entry?(entry_hash)
# false

# entry_hash = {"fname"=>"John", "lname"=>"Doe", "addr"=>"8606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
# p duplicate_entry?(entry_hash)
# false

# entry_hash = {"fname"=>"jake", "lname"=>"roberts", "addr"=>"328 oakdale drive", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p format_hash(entry_hash)
# {"fname"=>"Jake", "lname"=>"Roberts", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}

# entry_hash = {"fname"=>"jake", "lname"=>"roberts", "addr"=>"328 oakdale drive", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p write_db(entry_hash)
# {"fname"=>"Jake", "lname"=>"Roberts", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}

# p get_names()
# ["Doe, Jen", "Fairbanks Jr., Jim Bob", "Smith, Jane C.", "Doe, Jill", "Langer, Jeff", "Smith, Joy", "Doe, John", "Roberts, Jake", "Smith-Lewis, June", "Doe III, Joe", "Scott M.D., Jack", ""]

# hash_1 = {"id"=>"11", "fname"=>"jake l.", "lname"=>"robertson", "addr"=>"328 oak-dale dr.", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p update_values(hash_1)
# {"fname"=>"Jake L.", "lname"=>"Robertson", "addr"=>"328 Oak-Dale Dr.", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}

# hash_1 = {"fname"=>"jacob", "lname"=>"robert", "addr"=>"146 oakdale drive", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15213", "mobile"=>"4125558888", "home"=>"4125558349", "work"=>"4125556843", "id"=>"11"}
# p update_values(hash_1)
# {"fname"=>"Jacob", "lname"=>"Robert", "addr"=>"146 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125558888", "home"=>"4125558349", "work"=>"4125556843"}

# hash_1 = {"fname"=>"jake", "lname"=>"roberts jr. m.d.", "id"=>"11", "addr"=>"328 oak dale drive", "city"=>"pittsburgh", "state"=>"pa", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p update_values(hash_1)
# {"fname"=>"Jake", "lname"=>"Roberts Jr. M.D.", "addr"=>"328 Oak Dale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}

# New entry, no issues
# hash_2 = {"fname"=>"New", "lname"=>"Entry", "addr"=>"1 A Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125551234", "home"=>"4125552345", "work"=>"4125553456"}
# p check_values(hash_2)
# ""

# Updating existing entry (has id value)
# hash_3 = {"fname"=>"New", "lname"=>"Entry", "id"=>"11", "addr"=>"1 A Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125551234", "home"=>"4125552345", "work"=>"4125553456"}
# p check_values(hash_3)
# ""

# Duplicate entry
# hash_4 = {"fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
# p check_values(hash_4)
# "That entry already exists - please enter details for another entry."

# First name too short (1)
# hash_5 = {"id"=>"11", "fname"=>"J", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_5)
# "The name is too short - please enter at least two letters for the name."

# First name too long (50+)
# hash_6 = {"id"=>"11", "fname"=>"Jakeasdfasdfoiuyasdfoiuyasdfiouyasdfoiuyasdfiouyasdfoiuyasdfoiuyasdfoiuy", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_6)
# "The value for 'fname' is too long - please try again with a shorter value."

# Last name too short (1)
# hash_7 = {"id"=>"11", "fname"=>"Jake", "lname"=>"R", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_7)
# "The name is too short - please enter at least two letters for the name."

# Last name too long (50+)
# hash_8 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertsonasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiasdfpoiu", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_8)
# "The value for 'lname' is too long - please try again with a shorter value."

# Address too short (2 words)
# hash_9 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_9)
# "Please specify a house number and a street name for the address."

# Address too long (50+)
# hash_10 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Driveasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuy", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_10)
# "The value for 'addr' is too long - please try again with a shorter value."

# City too long (25+)
# hash_11 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburghasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuyasdfoiuy", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_11)
# "The value for 'city' is too long - please try again with a shorter value."

# State too long (2+)
# hash_12 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"Pennsylvania", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_12)
# "Please use the two-letter abbreviation for the state name."

# Zip too short (4)
# hash_13 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"1521", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_13)
# "Please enter five digits for the zip code."

# Zip too long (5+)
# hash_14 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"152136", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_14)
# "Please enter five digits for the zip code."

# Mobile too short (9)
# hash_15 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"412555590", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_15)
# "Please enter ten digits for the mobile phone number."

# Work too long (10+)
# hash_16 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"41255568435"}
# p check_values(hash_16)
# "Please enter ten digits for the mobile phone number."

# Non-letters in first name
# hash_17 = {"id"=>"11", "fname"=>"Jake2", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_17)
# "Your name should only contain letters - please try again."

# Non-numbers in mobile
# hash_18 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"412-555-7359", "home"=>"4125558349", "work"=>"4125556843"}
# p check_values(hash_18)
# "The value for 'mobile' should only have numbers - please try again."

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