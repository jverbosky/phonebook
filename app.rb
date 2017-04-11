require 'sinatra'
require 'pg'
require_relative 'phonebook_ops.rb'

class PhonebookApp < Sinatra::Base

  get "/" do
    erb :start
  end

  get "/get_entry" do
    entry_hash = {}  # placeholders in this route to avoid error message
    feedback = ""
    erb :get_entry, locals: {entry_hash: entry_hash, feedback: feedback}
  end

  post '/post_entry' do
    entry_hash = params[:entry]  # assign the entry hash to the entry_hash variable
    feedback = check_values(entry_hash)  # data validation
    if feedback == ""  # if there's no field validation feedback, use the get_more_info view
      write_db(entry_hash)  # if not, add entry info to db
      erb :post_entry, locals: {entry_hash: entry_hash}
    else
      # otherwise reload the get_entry view with feedback and user-specified values so they can correct and resubmit
      erb :get_entry, locals: {entry_hash: entry_hash, feedback: feedback}
    end
  end

  get '/list_entries' do
    names = get_names()  # get an array of all of the user names in PostgreSQL db
    erb :list_entries, locals: {names: names}
  end

  get '/entry_info' do
    fname = params[:fname]  # get the first name from the url in list_users.erb (url = "/user_info?fname=John&lname=Doe")
    lname = params[:lname]  # get the last name from the url
    entry_hash = get_entry(fname, lname)  # get the hash of info for the specified person
    erb :entry_info, locals: {entry_hash: entry_hash}
  end

  get '/get_search' do
    feedback = ""
    erb :search, locals: {feedback: feedback}
  end

  post '/search_results' do
    value = params[:value]
    results = pull_records(value)  # get array of hashes for all matching records
    feedback = results[0]["addr"]
    if feedback == "No matching record - please try again."
      erb :search, locals: {feedback: feedback}
    else
      erb :search_results, locals: {results: results}
    end
  end

  get '/get_update' do
    feedback = ""
    name = params[:name]
    user_hash = get_data(name)
    erb :update_user, locals: {user_hash: user_hash, feedback: feedback}
  end

  post '/update_info' do
    user_hash = params[:user]
    name = user_hash["name"]  # user name from the resulting hash
    feedback = check_values(user_hash)  # data validation
    if feedback == ""  # if there's no feedback on user already being in db, use the get_more_info view
      update_values(user_hash)
      write_image(user_hash)
      age = user_hash["age"]  # user age from the resulting hash
      image = pull_image(name)  # get the image path and name
      n1 = user_hash["n1"]  # favorite number 1 from the resulting hash
      n2 = user_hash["n2"]  # favorite number 2 from the resulting hash
      n3 = user_hash["n3"]  # favorite number 3 from the resulting hash
      total = sum(n1, n2, n3)
      comparison = compare(total, age)
      quote = user_hash["quote"]  # quote from the resulting hash
      erb :get_more_info, locals: {name: name, age: age, n1: n1, n2: n2, n3: n3, total: total, comparison: comparison, quote: quote, image: image}
    else
      user_hash = get_data(name)
      # otherwise reload the get_info view with feedback and user-specified values so they can correct and resubmit
      erb :update_user, locals: {user_hash: user_hash, feedback: feedback}
    end
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