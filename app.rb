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
    raw_hash = params[:entry]  # assign the entry hash to the entry_hash variable
    feedback = check_values(raw_hash)  # data validation
    if feedback == ""  # if there's no field validation feedback, use the post_entry view
      write_db(raw_hash)  # if not, add entry info to db
      fname = capitalize_items(raw_hash["fname"])
      lname = capitalize_items(raw_hash["lname"])
      entry_hash = get_entry(fname, lname)
      erb :post_entry, locals: {entry_hash: entry_hash}
    else
      # otherwise reload the get_entry view with feedback and user-specified values so they can correct and resubmit
      erb :get_entry, locals: {entry_hash: raw_hash, feedback: feedback}
    end
  end

  get '/list_entries' do
    names = get_names()  # get an array of all of the user names in db
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
    fname = params[:fname]  # get the first name from the url in list_users.erb (url = "/user_info?fname=John&lname=Doe")
    lname = params[:lname]  # get the last name from the url
    entry_hash = get_entry(fname, lname)  # get the hash of info for the specified person
    feedback = ""
    erb :update_user, locals: {entry_hash: entry_hash, feedback: feedback}
  end

  post '/update_info' do
    raw_hash = params[:entry]
    feedback = check_values(raw_hash)  # data validation
    if feedback == ""  # if there's no field validation feedback, use the post_entry view
      update_values(raw_hash)
      fname = capitalize_items(raw_hash["fname"])
      lname = capitalize_items(raw_hash["lname"])
      entry_hash = get_entry(fname, lname)
      erb :post_entry, locals: {entry_hash: entry_hash, feedback: feedback}
    else
      # otherwise reload the get_info view with feedback and user-specified values so they can correct and resubmit
      erb :update_user, locals: {entry_hash: raw_hash, feedback: feedback}
    end
  end

  post '/verify_delete' do
    entry_hash = params[:entry]
    erb :verify_delete, locals: {entry_hash: entry_hash}
  end

  post '/delete_info' do
    id_hash = params[:id]
    feedback = delete_record(id_hash)
    erb :delete_confirm, locals: {feedback: feedback}
  end

end