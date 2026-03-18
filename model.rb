def register(user, pwd, pwd_confirm)
  db = SQLite3::Database.new("db/databas.db")
  result = db.execute("SELECT id FROM users WHERE user=?", user)
  if result.empty? 
    if pwd==pwd_confirm
      pwd_digest=BCrypt::Password.create(pwd)
      db.execute("INSERT INTO users(user, password) VALUES(?,?)", [user, pwd_digest])
      return true
    else
      return false 
    end
  else
    return false
  end
end

def login(user, pwd)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  result = db.execute("SELECT id, password FROM users WHERE user=?", user)
  
  if session[:time] == nil || Time.now.to_i - session[:time] > 10
    session[:time] = Time.now.to_i
    session[:tries] = 0
  elsif session[:tries] >= 10
    session[:ban] = true
  end
  session[:tries] += 1

  if result.empty?
    return false #wrong username
  end
  user_id = result.first["id"]
  pwd_digest = result.first["password"]

  if BCrypt::Password.new(pwd_digest) == pwd && session[:ban] != true
    session[:user_id] = user_id
    return true
  else
    return false
  end
end

def add_event(name, place, info, date, time)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  result = db.execute("SELECT id FROM events WHERE name=?", name)
  if result.empty?
  else
    return false
  end
end