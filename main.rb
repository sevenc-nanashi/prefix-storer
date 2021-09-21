require "discorb"
require "dotenv"
require "pg"

Dotenv.load

client = Discorb::Client.new(intents: Discorb::Intents.all)

class << client
  attr_accessor :db
end

client.once :ready do
  puts "Logged in as #{client.user}"

  client.db = PG.connect(ENV["DATABASE_URL"])
  puts "Connected to database"
  client.dispatch(:prepare_db)
end

module Core; end

load "./exts/register.rb"
load "./exts/nick.rb"

client.extend Evaler
client.extend Core::Register
client.extend Core::Nickname

client.run ENV["TOKEN"]  # Starts client
