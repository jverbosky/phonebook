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

    # drop listings table if it exists
    client.query("DROP TABLE IF EXISTS listings")
  
    # create the species_details table
    client.query(
        "CREATE TABLE portfoliojv.listings (
            id SMALLINT NOT NULL AUTO_INCREMENT,
            fname varchar(50) NULL,
            lname varchar(50) NULL,
            addr varchar(50) NULL,
            city varchar(25) NULL,
            state varchar(2) NULL,
            zip varchar(5) NULL,
            mobile varchar(10) NULL,
            home varchar(10) NULL,
            work varchar(10) NULL,
            CONSTRAINT PK_species PRIMARY KEY (id)
        )"
    ) 

  rescue Mysql2::Error => e
  
    puts 'Exception occurred'
    puts e.message
  
  ensure
  
    client.close if client
  
  end