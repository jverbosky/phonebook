require 'mysql2'
load "./local_env.rb" if File.exists?("./local_env.rb")


begin

    # define connection parameters
    db_params = {
        host: ENV['host'],  # AWS link
        port: ENV['port'],  # AWS port, always 5432
        username: ENV['username'],
        password: ENV['password'],
        database: ENV['database']
    }

    # connect to the database
    client = Mysql2::Client.new(db_params)

    # ------------------- initialize listings data -----------------------------

    # initialize listings data sets
    # - MySQL Note: had to replace "nil" values in arrays with empty strings ("")
    entry_1 = ["John", "Doe", "606 Jacobs Street", "Pittsburgh", "PA", 15220, 4125550125, 4125559816, 4125550106]
    entry_2 = ["Jane C.", "Smith", "3974 Riverside Drive", "Monroeville", "PA", 15146, 8785550101, 8785557000, 4125550197]
    entry_3 = ["Jim Bob", "Fairbanks Jr.", "3801 Beechwood Drive", "Wexford", "PA", 15090, 4125550167, 4125553878, ""]
    entry_4 = ["Jill", "Doe", "2294 Washington Avenue", "Sewickley", "PA", 15143, 7245550136, 7245551953, 4125550150]
    entry_5 = ["June", "Smith-Lewis", "3210 North-West Street", "Imperial", "PA", 15126, 4125550163, 4125557989, 4125550198]
    entry_6 = ["Jen", "Doe", "3261 Michigan Avenue", "Pittsburgh", "PA", 15222, 7245550190, 7245550624, 7245550146]
    entry_7 = ["Jeff", "Langer", "2731 Platinum Drive", "Monroeville", "PA", 15140, 8785550195, 8785556851, 4125550172]
    entry_8 = ["Jack", "Scott M.D.", "4168 University Drive", "Mt. Lebanon", "PA", 15216, 4125550107, 4125552529, 4125550113]
    entry_9 = ["Joe", "Doe III", "2391 Losh Lane", "Monroeville", "PA", 15146, 4125550184, 4125554784, 4125550166]
    entry_10 = ["Joy", "Smith", "879 Shinn Avenue", "Imperial", "PA", 15071, 7245550195, 7245551579, 4125550131]

    # aggregate listings data into multi-dimensional array for iteration
    phonebook = []
    phonebook.push(entry_1, entry_2, entry_3, entry_4, entry_5, entry_6, entry_7, entry_8, entry_9, entry_10)

    # ------------------- load listings data -----------------------------

    # iterate through multi-dimensional phonebook array for data
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

        statement = "insert into listings (fname, lname, addr, city, state, zip, mobile, home, work) 
                     values ('#{v_fname}', '#{v_lname}', '#{v_addr}', '#{v_city}', '#{v_state}', '#{v_zip}', '#{v_mobile}', '#{v_home}', '#{v_work}')"

        client.query(statement)

    end

  rescue Mysql2::Error => e
  
    puts 'Exception occurred'
    puts e.message
  
  ensure
  
    client.close if client
  
  end