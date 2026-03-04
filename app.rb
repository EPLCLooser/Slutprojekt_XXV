require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

@all_routes = ['/', '/events', '/events/:id', '/events/new', '/events/:id/edit']

before ('/events/*') do
  if session[:logged_in] == nil 
    redirect to ('/registrer')
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

get('/registrer') do 
  slim(:registrer)
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
  pwd_confirm = params["pwd_confirm"]
  if registrer(user, pwd, pwd_confirm)
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

  db = SQLite3::Database.new("db/todos.db")
  result = db.execute("SELECT id FROM users WHERE username=?", user)

  if result.empty?
    if pwd==pwd_confirm
      pwd_digest=BCrypt::Password.create(pwd)
      db.execute("INSERT INTO users(username, password) VALUES(?,?)", [user, pwd_digest])
      session[:logged_in] = true
      redirect('/')
    else
      redirect('/error') 
    end
  else
    redirect('/login_page')
  end
end