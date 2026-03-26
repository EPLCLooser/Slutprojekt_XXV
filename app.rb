require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

include Model

enable :sessions

@all_routes = ['/', '/events', '/events/:id', '/events_new', '/events/:id/edit']

# A before function that checks if a user is logged in and if not they are redirected to register page
# 
before(@all_routes) do
  if session[:logged_in] != true || session[:ban]
    redirect('/register')
  end
end

# GET /
# Redirects to the events page
#
# @return [Response] redirects to /events
get('/') do
  redirect('/events')
end

# GET /events
# Displays all events that the user has permission to see
#
# @param [Hash] params query parameters, including optional event_type
# @return [String] rendered slim template for index
get('/events') do 
  type_search = params[:event_type]
  if type_search == ""
    type_search = nil
  end
  if is_admin?()
    @admin = true
    @users = get_users()
  end
  @owned_events, @joined_events = show_events(type_search)
  slim(:index)
end

# GET /error
# Displays the error message from the session
#
# @return [String] rendered slim template for error
get('/error') do
  @error = session[:error]
  slim(:error)
end

# GET /events/:id
# Displays details of a specific event
#
# @param [String] id the event ID from the URL
# @return [String] rendered slim template for event show
get('/events/:id') do 
  @event, @owner = get_event(params[:id])
  slim(:"./events/show")
end

# GET /events_new
# Displays the page for creating a new event
#
# @return [String] rendered slim template for new event
get('/events_new') do
  slim(:"./events/new")
end

# GET /events/:id/edit
# Displays the page for editing an event
#
# @param [String] id the event ID from the URL
# @return [String] rendered slim template for event edit
get('/events/:id/edit') do 
  slim(:"./events/edit")
end

# GET /register
# Displays the register and login page
#
# @return [String] rendered slim template for user registration
get('/register') do 
  slim(:"./user/new")
end


# POST /events/create
# Creates a new event with the provided parameters
#
# @param [Hash] params form parameters including name, place, info, date, time, event_type
# @return [Response] redirects to /events on success, /error on failure
post('/events/create') do
  name = params[:name]
  place = params[:place]
  info = params[:info]
  date = params[:date]
  time = params[:time]
  event_type_id = params[:event_type]
  if add_event(name, place, info, date, time, event_type_id)
    redirect('/events')
  else
    redirect('/error')
  end
end

# POST /events/:id/update
# Updates an existing event with new details
#
# @param [String] id the event ID from the URL
# @param [Hash] params form parameters including name, place, info, date, time, event_type
# @return [Response] redirects to /events on success, /error on failure
post('/events/:id/update') do
  id = params[:id]
  name = params[:name]
  place = params[:place]
  info = params[:info]
  date = params[:date]
  time = params[:time]
  event_type_id = params[:event_type]
  if edit_event(name, place, info, date, time, event_type_id, id)
    redirect('/events')
  else
    redirect('/error')
  end
  redirect('/events')
end

# POST /events/:id/delete
# Deletes the specified event
#
# @param [String] id the event ID from the URL
# @return [Response] redirects to /events on success, /error on failure
post('/events/:id/delete') do
  event_id = params[:id]
  if delete_event(event_id)
    redirect('/events')
  else
    redirect("/error")
  end
end

# POST /login
# Logs in a user with the provided credentials
#
# @param [Hash] params form parameters including user and pwd
# @return [Response] redirects to /events on success, /error on failure
post('/login') do
  user = params["user"]
  pwd = params["pwd"]
  if login(user, pwd)
    session[:logged_in] = true
    redirect('/events')
  else
    redirect('/error')
  end 
end

# POST /user
# Registers a new user
#
# @param [Hash] params form parameters including user, pwd, pwd_confirm
# @return [Response] redirects to /events on success, /error on failure
post('/user') do
  user = params["user"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]
  if register(user, pwd, pwd_confirm)
    session[:logged_in] = true
    redirect('/events')
  else
    redirect('/error')
  end
end

# POST /join
# Joins an event using the provided code
#
# @param [Hash] params form parameters including code
# @return [Response] redirects to /events on success, /error on failure
post('/join') do
  code = params[:code]
  if join(code)
    redirect('/events')
  else
    redirect('/error')
  end
end

# POST /log_out
# Logs out the current user
#
# @return [Response] redirects to /events
post("/log_out") do
  session[:logged_in] = false
  redirect("/events")
end

# POST /user/:id/delete
# Deletes the specified user (admin only)
#
# @param [String] id the user ID from the URL
# @return [Response] redirects to /events on success, /error on failure
post("/user/:id/delete") do
  id = params[:id]
  if delete_user(id)
    redirect("/events")
  else
    redirect("/error")
  end
end