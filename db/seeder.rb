require 'sqlite3'

db = SQLite3::Database.new("databas.db")


def seed!(db)
  puts "Using db file: db/todos.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS users')
  db.execute('DROP TABLE IF EXISTS events')
  db.execute('DROP TABLE IF EXISTS event_types')
end

def create_tables(db)
  db.execute('CREATE TABLE events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              code TEXT NOT NULL,
              name TEXT NOT NULL,
              place TEXT,
              info TEXT,
              date TEXT,
              time TEXT,
              event_type_id INTEGER)')
  db.execute('CREATE TABLE event_types (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL)')
  db.execute('CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL)')
end

def populate_tables(db)
  db.execute('INSERT INTO users (name) VALUES ("LucasNorrflod")')
  db.execute('INSERT INTO users (name) VALUES ("Victor Rosenhall")')
  db.execute('INSERT INTO users (name) VALUES ("Leo Dhal")')
  db.execute('INSERT INTO events (code, name, place, info, date, time, event_type_id) VALUES ("X5D3ddf2", "kalas", "långtifrångatan 2", "Ha på er fina kläder", "21 januari", "15:00", 1)')
  db.execute('INSERT INTO event_types (name) Values ("Party")')
  db.execute('INSERT INTO event_types (name) Values ("Graduation")')
  db.execute('INSERT INTO event_types (name) Values ("Wedding")')
end


seed!(db)





