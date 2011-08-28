#!/usr/bin/env ruby

require 'rubygems'
require 'sqlite3'
require 'iconv'

db = SQLite3::Database.new("phrases.db")

db.execute <<SQL
CREATE TABLE phrases (
  id INTEGER PRIMARY KEY,
  english VARCHAR(255),
  german VARCHAR(255)
);
SQL

de = File.open('south-park-s14e03de.srt', 'r') { |f| f.read }
en = File.open('south-park-s14e03en.srt', 'r') { |f| f.read }

de = Iconv.conv('utf-8', 'ISO-8859-1', de)
en = Iconv.conv('utf-8', 'ISO-8859-1', en)

de = de.split("\r\n\r\n")
en = en.split("\n\n")

# some dummy lines start/end
(6..de.count-2).each do |i|

  german = de[i].split("\r\n")
  english = en[i].split("\n")

  2.times { german.shift }
  2.times { english.shift }

  db.execute("INSERT INTO phrases (english, german) VALUES (?, ?);", english.join(" "), german.join(" "))
  
end
