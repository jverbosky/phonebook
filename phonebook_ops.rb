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

# Method to return entry hash from PostgreSQL db for specified first name
def get_entry(first_name)
  begin
    conn = open_db()
    conn.prepare('q_statement',
                 "select *
                  from listings
                  where listings.fname = '#{first_name}'")
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

# Method to return array of sorted/transposed names from db for populating /list_users table
def get_names()
  begin
    names = []
    conn = open_db()
    conn.prepare('q_statement',
                 "select fname, lname from listings order by lname, fname")
    query = conn.exec_prepared('q_statement')
    conn.exec("deallocate q_statement")
    query.each { |pair| names.push(pair["lname"] + ", " + pair["fname"]) }
    names
    sorted = names.count > 3 ? rotate_names(names) : names  # rerrange names if more than 3 names
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to determine if value is too long or if user in current user hash is already in JSON file
def check_values(user_hash)
  flag = 0
  feedback = ""
  detail = ""
  user_hash.each do |key, value|
    flag = 2 if key == "age" && value.to_i > 120
    (flag = 3; detail = key) if key !~ /quote/ && value.length > 20
    flag = 4 if key == "quote" && value.length > 80
    flag = 5 if key == "name" && value =~ /[^a-zA-Z ]/
    (flag = 6; detail = key) if key =~ /age|n1|n2|n3/ && value =~ /[^0-9.,]/
  end
  # users = get_names()
  # users.each { |user| flag = 1 if user == user_hash["name"]}
  flag = 7 if validate_file(user_hash) == false
  case flag
    # when 1 then feedback = "We already have details for that person - please enter a different person."
    when 2 then feedback = "I don't think you're really that old - please try again."
    when 3 then feedback = "The value for '#{detail}' is too long - please try again with a shorter value."
    when 4 then feedback = "Your quote is too long - please try again with a shorter value."
    when 5 then feedback = "Your name should only contain letters - please try again."
    when 6 then feedback = "The value for '#{detail}' should only have numbers - please try again."
    when 7 then feedback = "Invalid image file - please upload a valid image in BMP, GIF, JPG, PNG or TIFF format."
  end
  return feedback
end

# Method to add current user hash to db
def write_db(entry_hash)
  begin
    conn = open_db() # open database for updating
    max_id = conn.exec("select max(id) from listings")[0]  # determine current max index (id) in details table
    max_id["max"] == nil ? v_id = 1 : v_id = max_id["max"].to_i + 1  # set index variable based on current max index value
    v_fname = entry_hash["fname"]  # prepare data from user_hash for database insert
    v_lname = entry_hash["lname"]
    v_addr = entry_hash["addr"]
    v_city = entry_hash["city"]
    v_state = entry_hash["state"]
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

# Method to identify which column contains specified value
def match_column(value)
  begin
    columns = ["fname", "lname", "city"]
    target = ""
    conn = open_db() # open database for updating
    columns.each do |column|  # determine which column contains the specified value
      query = "select " + column +
              " from listings"
      conn.prepare('q_statement', query)
      rs = conn.exec_prepared('q_statement')
      conn.exec("deallocate q_statement")
      results = rs.values.flatten
      results.each { |e| return column if e =~ /#{value}/i }
    end
    return target
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to return hash of all values for record associated with specified value
def pull_records(value)
  begin
    column = match_column(value)  # determine which column contains the specified value
    unless column == ""
      results = []  # array to hold all matching hashes
      conn = open_db()
      query = "select *
               from listings
               where " + column + " ilike $1
               order by lname, fname"
      conn.prepare('q_statement', query)
      rs = conn.exec_prepared('q_statement', ["%" + value + "%"])
      conn.exec("deallocate q_statement")
      rs.each { |result| results.push(result) }
      return results
    else
      return [{"quote" => "No matching record - please try again."}]
    end
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to update any number of values in any number of tables
# - user hash needs to contain id of current record that needs to be updated
# - order is not important (the id can be anywhere in the hash)
def update_values(entry_hash)
  begin
    id = entry_hash["id"]  # determine the id for the current record
    conn = open_db() # open database for updating
    entry_hash.each do |column, value|  # iterate through entry_hash for each column/value pair
      unless column == "id"  # we do NOT want to update the id
        # workaround for column name used as bind parameter
        query = "update listings set " + column + " = $2 where id = $1"
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

#-----------------
# Sandbox testing
#-----------------

# p get_entry("John")  # {"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}

# entry_hash = {"fname"=>"Jake", "lname"=>"Roberts", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# write_db(entry_hash)

# p get_names()

# hash_1 = {"id"=>"11", "fname"=>"Jake", "lname"=>"Robertson", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}
# hash_1 = {"fname"=>"Jacob", "lname"=>"Robert", "addr"=>"146 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125558888", "home"=>"4125558349", "work"=>"4125556843", "id"=>"11"}
# hash_1 = {"fname"=>"Jake", "lname"=>"Roberts", "id"=>"11", "addr"=>"328 Oakdale Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15213", "mobile"=>"4125557359", "home"=>"4125558349", "work"=>"4125556843"}

# update_values(hash_1)

# p match_column("John")  # "fname"
# p match_column("Smith")  # "lname"
# p match_column("Monroeville")  # "city"
# p match_column("nothing")  #  ""

# p pull_records("John")
# [{"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}]

# p pull_records("Smith")
# [{"id"=>"2", "fname"=>"Jane", "lname"=>"Smith", "addr"=>"3974 Riverside Drive", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15201", "mobile"=>"8785550101", "home"=>"8785557000", "work"=>"4125550197"},
#  {"id"=>"10", "fname"=>"Joy", "lname"=>"Smith", "addr"=>"879 Shinn Avenue", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15201", "mobile"=>"7245550195", "home"=>"7245551579", "work"=>"4125550131"},
#  {"id"=>"5", "fname"=>"June", "lname"=>"Smith", "addr"=>"3210 Stiles Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15201", "mobile"=>"4125550163", "home"=>"4125557989", "work"=>"4125550198"}]

# p pull_records("Monroeville")
# [{"id"=>"9", "fname"=>"Joe", "lname"=>"Doe", "addr"=>"2391 Losh Lane", "city"=>"Monroeville", "state"=>"PA", "zip"=>"15146", "mobile"=>"4125550184", "home"=>"4125554784", "work"=>"4125550166"},
#  {"id"=>"7", "fname"=>"Jeff", "lname"=>"Langer", "addr"=>"2731 Platinum Drive", "city"=>"Monroeville", "state"=>"PA", "zip"=>"15140", "mobile"=>"8785550195", "home"=>"8785556851", "work"=>"4125550172"},
#  {"id"=>"2", "fname"=>"Jane", "lname"=>"Smith", "addr"=>"3974 Riverside Drive", "city"=>"Monroeville", "state"=>"PA", "zip"=>"15146", "mobile"=>"8785550101", "home"=>"8785557000", "work"=>"4125550197"}]

# p pull_records("nothing")
# [{"quote"=>"No matching record - please try again."}]