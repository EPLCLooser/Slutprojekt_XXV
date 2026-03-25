require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

@all_routes = ['/', '/events', '/events/:id', '/events_new', '/events/:id/edit']

before(@all_routes) do
  if session[:logged_in] != true || session[:ban]
    redirect('/register')
  end
end

get('/') do
  redirect('/events')
end

get('/events') do 
  type_search = params[:event_type]
  if type_search == ""
    type_search = nil
  end
  @owned_events, @joined_events = show_events(type_search)
  p @owned_events
  slim(:index)
end

get('/error') do
  @error = session[:error]
  slim(:error)
end

get('/events/:id') do 
  @event, @owner = get_event(params[:id].to_i)
  p @event
  slim(:show)
end

get('/events_new') do
  slim(:new)
end

get('/events/:id/edit') do 
  slim(:edit)
end

get('/register') do 
  slim(:register)
end

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

post('/events/:id/delete') do
  event_id = params[:id]
  if delete_event(event_id)
    redirect('/events')
  else
    redirect("/error")
  end
end

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

post('/join') do
  code = params[:code]
  if join(code)
    redirect('/events')
  else
    redirect('/error')
  end
end

post("/log_out") do
  session[:logged_in] = false
  redirect("/events")
end
