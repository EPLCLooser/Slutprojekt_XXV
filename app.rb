require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

@all_routes = ['/', '/events', '/events/:id', '/events_new', '/events/:id/edit']

before(@all_routes) do
  if session[:logged_in] == nil || session[:ban]
    redirect('/register')
  end
end

get('/') do
  redirect('/events')
end

get('/events') do 
  p"inte fisk"
  slim(:index)
end

get('/events/:id') do 
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
  if add_event(name, place, info, date, time)
    redirect('/events')
  else
    redirect('/error')
  end
end

post('/events/:id/update') do
  redirect('/events')
end

post('/events/:id/delete') do
  redirect('/events')
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