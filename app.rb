require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :session

@all_routes = ['/', '/events', '/events/:id', '/events/new', '/events/:id/edit']

before ('/events*') do
  p "här: #{session[:logged_in]}"
  if session[:logged_in] == nil 
    redirect to ('/register')
  end
end

get('/') do
  redirect('/events')
end

get('/events') do 
  slim(:index)
end

get('/events/:id') do 
  slim(:show)
end

get('/events/new') do 
  slim(:new)
end

get('/events/:id/edit') do 
  slim(:edit)
end

get('/register') do 
  slim(:register)
end

post('/events') do
  redirect('/events')
end

post('/events/:id/update') do
  redirect('/events')
end

post('/events/:id/delete') do
  redirect('/events')
end

post('/events/login') do
  user = params["user"]
  pwd = params["pwd"]
  if login(user, pwd)
    session[:logged_in] = true
    redirect('/events')
  else
    redirect('/error')
  end 
end

post('/events/user') do
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