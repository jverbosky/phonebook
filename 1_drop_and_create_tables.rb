# Example program to drop (delete) and create details and quotes tables

require 'pg'
load "./local_env.rb" if File.exists?("./local_env.rb")

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

  # drop listings table if it exists
  conn.exec "drop table if exists listings"

  # create the listings table (longest US city - Rancho Santa Margarita)
  conn.exec "create table listings (
             id int primary key,
             fname varchar(50),
             lname varchar(50),
             addr varchar(50),
             city varchar(25),
             state varchar(2),
             zip varchar(5),
             mobile varchar(10),
             home varchar(10),
             work varchar(10))"

rescue PG::Error => e

  puts 'Exception occurred'
  puts e.message

ensure

  conn.close if conn

end