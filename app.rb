require 'sinatra'
require 'pg'

class PhonebookApp < Sinatra::Base

  load "./local_env.rb" if File.exists?("./local_env.rb")

  db_params = {
    host: ENV['db_host'],
    port: ENV['db_port'],
    dbname: ENV['db_name'],
    user: ENV['db_user'],
    password: ENV['db_password']
  }

  db = PG::Connection.new(db_params)

  get "/" do
    erb :selection
  end

  get "/add" do
    phonebook = db.exec("SELECT fname, lname, addr, city, state, zip, mobile, home, work FROM phonebook");
      erb :addcontacts, :locals => {:phonebook => phonebook}
  end

  post "/collect_data" do
    fname = params[:fname]
    lname = params[:lname]
    addr = params[:addr]
    city = params[:city]
    state = params[:state]
    zip = params[:zip]
    mobile = params[:mobile]
    home = params[:home]
    work = params[:work]

    db.exec("INSERT INTO phonebook(fname, lname, addr, city, state, zip, mobile, home, work) VALUES('#{fname}','#{lname}','#{addr}','#{city}','#{state}','#{zip}','#{mobile}','#{home}','#{work}')");

    redirect "/"

  end

  get "/list" do
      phonelist = db.exec("SELECT fname, lname, addr, city, state, zip, mobile FROM phonebook");

      erb :listcontacts, :locals => {:phonelist => phonelist}
  end

  get "/search" do

    erb :search
  end

  post "/searchresult" do
    findby = params[:findby]
    findcontact = params[:findcontact]
    detail = db.exec("SELECT * FROM phonebook WHERE " + findby + " LIKE \'" + findcontact + "%\'")

    erb :searchmatches, :locals => {:detail => detail}
  end

  get "/modify" do

    
    "Nothing here yet"
  end

  get "/delete" do
    "Nothing here yet"
  end

end