post('/events/login') do
  user = params["user"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]

  db = SQLite3::Database.new("db/todos.db")
  db.results_as_hash = true
  result = db.execute("SELECT id, password FROM users WHERE username=?", user)
  
  if result.empty?
    redirect('/error') #wrong password/username
  end
  user_id = result.first["id"]
  pwd_digest = result.first["password"]

  if BCrypt::Password.new(pwd_digest) == pwd
    session[:user_id] = user_id
    session[:logged_in] = true
    redirect('/')
  else
    redirect("/error")
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