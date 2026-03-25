def register(user, pwd, pwd_confirm)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  result = db.execute("SELECT id FROM users WHERE user=?", user)
  if result.empty? 
    if pwd==pwd_confirm
      pwd_digest=BCrypt::Password.create(pwd)
      db.execute("INSERT INTO users(user, password, admin) VALUES(?,?,?)", [user, pwd_digest,0])
      result = db.execute("SELECT id FROM users WHERE user=?", user)
      session[:user_id] = result.first["id"]
      return true
    else
      session[:error] = "Password and password confirm is not matching"
      return false 
    end
  else
    session[:error] = "There already exist a user with that name"
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
    session[:error] = "There is already an event with the name of #{name}"
    return false
  end
end

def join(code)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  result = db.execute("SELECT events.id, users_events.user_id FROM (users_events INNER JOIN events ON users_events.event_id = events.id) WHERE code=?", code)
  already_joined = false
  for dict in result
    if dict["user_id"] == session[:user_id]
      already_joined = true
    end
  end
  if result.empty? || already_joined
    session[:error] = "There is no event with the code: #{code}"
    return false
  else
    db.execute("INSERT INTO users_events(user_id, event_id, user_owner) VALUES(?,?,?)",[session[:user_id], result.first["id"], 0])
    return true
  end
end

def show_events(type_search)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  if is_admin?()
    admin=1
  end
  owned_events = db.execute("SELECT events.name, events.id, events.code FROM ((users_events INNER JOIN events ON users_events.event_id = events.id) INNER JOIN event_types ON events.event_type_id = event_types.id) WHERE (users_events.user_id=? AND users_events.user_owner=? AND (event_types.id=? OR ? IS NULL)) OR (1=?  AND users_events.user_owner=?)", [session[:user_id], 1, type_search, type_search, admin, 1])
  joined_events = db.execute("SELECT events.name, events.id FROM ((users_events INNER JOIN events ON users_events.event_id = events.id) INNER JOIN event_types ON events.event_type_id = event_types.id) WHERE users_events.user_id=? AND users_events.user_owner=? AND (event_types.id=? OR ? IS NULL)", [session[:user_id], 0, type_search, type_search])
  return [owned_events, joined_events]
end

#Returns a dictionary of the event's information given its id
def get_event(event_id)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  if is_admin?()
    result = db.execute("SELECT * FROM users_events WHERE event_id=?", event_id)
  else
    result = db.execute("SELECT * FROM users_events WHERE user_id=? AND event_id=?", [session[:user_id], event_id])
  end
  if result.empty?
    session[:error] = "You are not an user in this event"
    redirect("/error") #User is not in event
  elsif is_admin?()
    event = db.execute("SELECT event_types.name AS event_type_name, * FROM ((event_types INNER JOIN events ON events.event_type_id = event_types.id) INNER JOIN users_events ON events.id = users_events.event_id) WHERE events.id=?", [event_id,1]).first
  else
    event = db.execute("SELECT event_types.name AS event_type_name, * FROM ((event_types INNER JOIN events ON events.event_type_id = event_types.id) INNER JOIN users_events ON events.id = users_events.event_id) WHERE events.id=? AND users_events.user_id=?", [event_id, session[:user_id]]).first
  end
  return event, event["user_owner"]
end

def edit_event(name, place, info, date, time, event_type_id, id)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  if authorize(id) || is_admin?()
    db.execute("UPDATE events SET name=?, place=?, info=?, date=?, time=?, event_type_id=? WHERE id=? ", [name, place, info, date, time, event_type_id, id])
    result = db.execute("SELECT id FROM events WHERE name=?", name)
    event_id = result.first["id"]
    return true
  else
    session[:error] = "You are not the owner of this event"
    return false
  end
end

def delete_event(event_id)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  if authorize(event_id) || is_admin?()
    db.execute("DELETE FROM events WHERE id=?", event_id)
    db.execute("DELETE FROM users_events WHERE event_id=?", event_id)
    return true
  else
    session[:error] = "You do not have permission to delete this event"
    return false #Do not have permission to delete
  end
end

def authorize(event_id)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  result = db.execute("SELECT user_id FROM users_events WHERE user_owner=1 AND event_id=?", event_id)
  if !result.empty? && result.first["user_id"] == session[:user_id]
    return true
  else
    return false
  end
end

def get_users() #get users from users table and display them for admin and make them deletable.
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  users = db.execute("SELECT id, user, admin FROM users WHERE admin=?", 0)
  return users
end

def is_admin?()
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  admin = db.execute("SELECT admin FROM users WHERE id=?", session[:user_id]).first["admin"]
  if admin == 1
    return true
  else
    return false
  end
end

def delete_user(id)
  if is_admin?()
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    event_ids = db.execute("SELECT event_id FROM users_events WHERE user_id=?", id)
    db.execute("DELETE FROM events WHERE id IN (SELECT event_id FROM users_events WHERE user_id = ?)", id)
    db.execute("DELETE FROM users WHERE id=?", id)
    event_ids.each do |event_id|
      db.execute("DELETE FROM users_events WHERE event_id=?", event_id["event_id"])
    end
    return true
  else
    session[:error] = "You do not have permission to delete another user"
    return false
  end
end