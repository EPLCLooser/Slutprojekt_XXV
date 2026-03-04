def registrer(user, pwd, pwd_confirm)
  db = SQLite3::Database.new("db/todos.db")
  db.results_as_hash = true
  result = db.execute("SELECT id, password FROM users WHERE username=?", user)
  
  if result.empty?
    return false #wrong password/username
  end
  user_id = result.first["id"]
  pwd_digest = result.first["password"]

  if BCrypt::Password.new(pwd_digest) == pwd
    session[:user_id] = user_id
    session[:logged_in] = true
    return true
  else
    return false
  end
end

def login(user, pwd)

end