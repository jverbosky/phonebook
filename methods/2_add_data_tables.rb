# Example program to insert data into details and quotes tables

require 'pg'
load "./local_env.rb" if File.exists?("./local_env.rb")

begin

  # user data sets
  entry_1 = ["John", "Doe", "606 Jacobs Street", "Pittsburgh", "PA", 15220, 4125550125, 4125559816, 4125550106]
  entry_2 = ["Jane C.", "Smith", "3974 Riverside Drive", "Monroeville", "PA", 15146, 8785550101, 8785557000, 4125550197]
  entry_3 = ["Jim Bob", "Fairbanks Jr.", "3801 Beechwood Drive", "Wexford", "PA", 15090, 4125550167, 4125553878, 7245550133]
  entry_4 = ["Jill", "Doe", "2294 Washington Avenue", "Sewickley", "PA", 15143, 7245550136, 7245551953, 4125550150]
  entry_5 = ["June", "Smith-Lewis", "3210 North-West Street", "Imperial", "PA", 15126, 4125550163, 4125557989, 4125550198]
  entry_6 = ["Jen", "Doe", "3261 Michigan Avenue", "Pittsburgh", "PA", 15222, 7245550190, 7245550624, 7245550146]
  entry_7 = ["Jeff", "Langer", "2731 Platinum Drive", "Monroeville", "PA", 15140, 8785550195, 8785556851, 4125550172]
  entry_8 = ["Jack", "Scott M.D.", "4168 University Drive", "Mt. Lebanon", "PA", 15216, 4125550107, 4125552529, 4125550113]
  entry_9 = ["Joe", "Doe III", "2391 Losh Lane", "Monroeville", "PA", 15146, 4125550184, 4125554784, 4125550166]
  entry_10 = ["Joy", "Smith", "879 Shinn Avenue", "Imperial", "PA", 15071, 7245550195, 7245551579, 4125550131]

  # aggregate entry data into multi-dimensional array for iteration
  phonebook = []
  phonebook.push(entry_1, entry_2, entry_3, entry_4, entry_5, entry_6, entry_7, entry_8, entry_9, entry_10)

  # connect to the database
  db_params = {
        host: ENV['host'],  # AWS link
        port:ENV['port'],  # AWS port, always 5432
        dbname:ENV['dbname'],
        user:ENV['dbuser'],
        password:ENV['dbpassword']
      }
  conn = PG::Connection.new(db_params)

  # determine current max index (id) in listings table
  max_id = conn.exec("select max(id) from listings")[0]

  # set index variable based on current max index value
  max_id["max"] == nil ? v_id = 1 : v_id = max_id["max"].to_i + 1

  # iterate through multi-dimensional users array for data
  phonebook.each do |entry|

    # initialize variables for SQL insert statements
    v_fname = entry[0]
    v_lname = entry[1]
    v_addr = entry[2]
    v_city = entry[3]
    v_state = entry[4]
    v_zip = entry[5]
    v_mobile = entry[6]
    v_home = entry[7]
    v_work = entry[8]

    # prepare SQL statement to insert entry data into listings table
    conn.prepare('q_statement',
                 "insert into listings (id, fname, lname, addr, city, state, zip, mobile, home, work)
                  values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)")  # bind parameters

    # execute prepared SQL statement
    conn.exec_prepared('q_statement',
                       [v_id, v_fname, v_lname, v_addr, v_city, v_state, v_zip, v_mobile, v_home, v_work])

    # deallocate prepared statement variable (avoid error "prepared statement already exists")
    conn.exec("deallocate q_statement")

    # increment index value for next iteration
    v_id += 1

  end

rescue PG::Error => e

  puts 'Exception occurred'
  puts e.message

ensure

  conn.close if conn

end