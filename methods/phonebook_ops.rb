require 'pg'
# load "./methods/local_env.rb" if File.exists?("./methods/local_env.rb")  # production version
load "../methods/local_env.rb" if File.exists?("../methods/local_env.rb")  # unit test & local version
# load "./local_env.rb" if File.exists?("./local_env.rb")  # local version (if previous doesn't work)

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

# Method to determine if entry is a duplicate or not (same first/last name)
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
    (flag = 8; detail = column) if column =~ /mobile|home|work/ && value.length.to_s !~ /0|10/
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
    unless value == ""
      query = "select *
               from listings
               where " + column + " ilike $1
               order by lname, fname"
      conn.prepare('q_statement', query)
      rs = conn.exec_prepared('q_statement', ["%" + value + "%"])
    else
      query = "select *
               from listings
               where " + column + " = ''"
      conn.prepare('q_statement', query)
      rs = conn.exec_prepared('q_statement')
    end
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

# run after unit tests, use DBeaver/PGAdmin to verify record deletion
# id_hash_1 = {"id"=>"11"}
# delete_record(id_hash_1)

# id_hash_2 = {"id"=>"12"}
# delete_record(id_hash_2)