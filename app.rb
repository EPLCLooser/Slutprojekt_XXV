require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

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

post('/events') do
  redirect('/events')
end

post('/events/:id/update') do
  redirect('/events')
end

post('/events/:id/delete') do
  redirect('/events')
end