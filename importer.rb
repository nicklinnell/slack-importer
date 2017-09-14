#! /usr/bin/env ruby

require 'json'
require 'pg'

json_dir = File.join(File.dirname(__FILE__), 'json')
conn = PG.connect(host: 'db', dbname: 'slack', user: 'postgres')

# users
user_file = File.open(File.join(json_dir, 'users.json'))
user_json = JSON.parse(user_file.read)
user_json.each do |user|
  conn.exec("INSERT INTO users (slack_id, name) VALUES ('#{user['id']}', '#{user['name']}')")
end

# channels
channel_file = File.open(File.join(json_dir, 'channels.json'))
channel_json = JSON.parse(channel_file.read)
channel_json.each do |channel|
  conn.exec("INSERT INTO channels (name) VALUES ('#{channel['name']}')")
end

# messages
Dir.glob(File.join(json_dir, '**')).each do |dir|
  if File.directory?(dir)
    channel = File.basename(dir)
    conn.exec("SELECT id FROM channels WHERE name = '#{channel}' LIMIT 1") do |result|
      @channel_id = result.first['id'] unless result.first.nil?
    end

    Dir.glob(File.join(dir, '*.json')).each do |file|
      file = File.open(file)
      file_json = JSON.parse(file.read)
      file_json.each do |message|
        next if message['text'].nil? || message['text'] == ''

        conn.exec("SELECT id FROM users WHERE slack_id = '#{message['user']}' LIMIT 1") do |result|
          @user_id = result.first['id'] unless result.first.nil?
        end

        conn.exec("INSERT INTO messages (user_id, channel_id, message) VALUES (#{@user_id}, #{@channel_id}, '#{conn.escape_string(message['text'])}')")
      end
    end
  end
end
