def register(user, pwd, pwd_confirm)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  result = db.execute("SELECT id FROM users WHERE user=?", user)
  if result.empty? 
    if pwd==pwd_confirm
      pwd_digest=BCrypt::Password.create(pwd)
      db.execute("INSERT INTO users(user, password) VALUES(?,?)", [user, pwd_digest])
      result = db.execute("SELECT id FROM users WHERE user=?", user)
      p result
      session[:user_id] = result.first["id"]
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

def add_event(name, place, info, date, time, event_type_id)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  result = db.execute("SELECT id FROM events WHERE name=?", name)
  code = rand(10000..100000)
  code_result = db.execute("SELECT id FROM events WHERE code=?", code)
  while !code_result.empty?
    code += 1
    code_result = db.execute("SELECT id FROM events WHERE code=?", code)
  end
  if result.empty?
    db.execute("INSERT INTO events(code, name, place, info, date, time, event_type_id) VALUES(?,?,?,?,?,?,?)", [code, name, place, info, date, time, event_type_id])
    result = db.execute("SELECT id FROM events WHERE name=?", name)
    event_id = result.first["id"]
    db.execute("INSERT INTO users_events(user_id, event_id, user_owner) VALUES(?,?,?)", [session[:user_id], event_id, 1])
    return true
  else
    return false
  end
end

def join(code)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  result = db.execute("SELECT events.id, users_events.user_id FROM (users_events INNER JOIN events ON users_events.event_id = events.id) WHERE code=?", code)
  if result.first["users_events.user_id"] == nil #FIXA HÄR
    db.execute("INSERT INTO users_events(user_id, event_id, user_owner) VALUES(?,?,?)",[session[:user_id], event_id, 0])
  end
end

def show_events()
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  owned_events = db.execute("SELECT name, id FROM (users_events INNER JOIN events ON users_events.event_id = events.id) WHERE users_events.user_id=? AND users_events.user_owner=?", [session[:user_id], 1])
  joined_events = db.execute("SELECT name, id FROM (users_events INNER JOIN events ON users_events.event_id = events.id) WHERE users_events.user_id=? AND users_events.user_owner=?", [session[:user_id], 0])
  p owned_events
  p joined_events
  return [owned_events, joined_events]
end