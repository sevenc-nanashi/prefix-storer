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

  client.dispatch(:prepare_db)
end

load "./exts/eval.rb"
load "./exts/commands.rb"

client.extend Evaler
client.extend Commands

client.run ENV["TOKEN"]  # Starts client
