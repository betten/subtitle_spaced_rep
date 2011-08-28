#!/usr/bin/env ruby

require 'rubygems'
require 'sqlite3'

INTERVALS = [5, 25, 2*(60), 10*(60), 10*(60), 5*(60*60), 1*(60*60*24), 5*(60*60*24), 25*(60*60*24)]


def get_response
  begin
    system("stty raw -echo")
    str = STDIN.getc
  ensure
    system("stty -raw echo")
  end
  exit if str.chr == 'q'
  str.chr
end

def instructions
  puts "'q' anytime to quit"
  puts "any key to show"
  puts "'j' for correct"
  puts "'k' for wrong"
  puts ""
end

def stats(db, phrase)
  puts "#{db.execute("SELECT * FROM phrases WHERE level IS NOT NULL").count} phrases seen"
  puts "Current phrase on level: #{phrase["level"] || "new"}"
  puts ""
end

def clear
  system("clear")
end

def level_up(db, phrase)
  level = phrase["level"].nil? ? 0 : phrase["level"] + 1
  level = (INTERVALS.count - 1) if level > (INTERVALS.count - 1)
  next_test = Time.now + INTERVALS[level]
  update_level_next_test(db, phrase["id"], level, next_test)
end

def level_down(db, phrase)
  level = 0
  next_test = Time.now + INTERVALS[level]
  update_level_next_test(db, phrase["id"], level, next_test)
end

def update_level_next_test(db, id, level, next_test)
  db.execute("UPDATE phrases SET level = ?, next_test = ? WHERE id = ?", level, next_test.to_i, id)
end


clear

if ARGV.include?("-n")
  puts "new game..."

  name = ARGV[0].eql?("-n") ? 
    "new-game-#{Time.now.to_i}.db" : 
    ARGV[0]
  db = SQLite3::Database.new(name)
  puts "creating game with name '#{name}'..."

  db.execute "
  CREATE TABLE phrases (
    id INTEGER PRIMARY KEY,
    english VARCHAR(255),
    german VARCHAR(255),
    level INTEGER,
    next_test DATETIME
  );
  "

  puts "loading game..."
  data = SQLite3::Database.open("phrases.db")
  data.results_as_hash = true
  data.execute("SELECT * FROM phrases") do |phrase|
    db.execute(
      "INSERT INTO phrases (english, german) VALUES(?, ?)", 
      phrase["english"], phrase["german"]
    )
  end
elsif ARGV[0]
  puts "starting game..."
  db = SQLite3::Database.open(ARGV[0])
else
  "Usage: testphrases [db_name] [-n new game]"
end

clear
instructions

db.results_as_hash = true
while true
  phrase = db.get_first_row("SELECT * FROM phrases WHERE next_test IS NOT NULL ORDER BY next_test LIMIT 1")
  if phrase.nil? || phrase["next_test"] > Time.now.to_i + 5
    new_phrase = db.get_first_row("SELECT * FROM phrases WHERE next_test IS NULL LIMIT 1")
    phrase = new_phrase unless new_phrase.nil?
  end

  stats(db, phrase)

  puts phrase["german"]
  get_response
  puts phrase["english"]

  resp = get_response

  if resp == 'j'
    level_up(db, phrase)
  elsif resp == 'k'
    level_down(db, phrase)
  end

  clear
  instructions
end
