# Example program to return all data from listings table

require 'pg'
load "./local_env.rb" if File.exists?("./local_env.rb")

def get_data(first_name)

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

    # reference - example query to return all column names from listings table
    # select column_name from information_schema.columns where table_name='listings'

    # prepare SQL statement
    conn.prepare('q_statement',
                 "select *
                  from listings
                  where fname = '#{first_name}'")

    # execute prepared SQL statement
    rs = conn.exec_prepared('q_statement')

    # deallocate prepared statement variable (avoid error "prepared statement already exists")
    conn.exec("deallocate q_statement")

    return rs[0]

    # # iterate through each row for user data and image
    # rs.each do |row|

    #   # output user data to console
    #   puts "First Name: #{row['fname']}"
    #   puts "Last Name: #{row['lname']}"
    #   puts "Address: #{row['addr']}"
    #   puts "City: #{row['city']}"
    #   puts "State: #{row['state']}"
    #   puts "Zip Code: #{row['zip']}"
    #   puts "Mobile: #{row['mobile']}"
    #   puts "Home: #{row['home']}"
    #   puts "Work: #{row['work']}"

    # end

  rescue PG::Error => e

    puts 'Exception occurred'
    puts e.message

  ensure

    conn.close if conn

  end

end

p get_data("John")  # {"id"=>"1", "fname"=>"John", "lname"=>"Doe", "addr"=>"606 Jacobs Street", "city"=>"Pittsburgh", "state"=>"PA", "zip"=>"15220", "mobile"=>"4125550125", "home"=>"4125559816", "work"=>"4125550106"}
