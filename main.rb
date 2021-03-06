#! /usr/bin/env ruby
# coding: utf-8

require "discorb"
require "dotenv"
require "pg"

Dotenv.load

Encoding.default_internal = __ENCODING__
intents = Discorb::Intents.default
intents.members = true

client = Discorb::Client.new(
  intents: intents,
  fetch_member: true,
)

class << client
  attr_accessor :db
end

client.once :standby do
  puts "Logged in as #{client.user}"

  client.db = PG.connect(ENV["DATABASE_URL"])
  puts "Connected to database"
  client.dispatch(:prepare_db)
end

module Core; end

client.on :load_extension do
  load "./exts/eval.rb"
  load "./exts/register.rb"
  load "./exts/nick.rb"
  load "./exts/status.rb"
  load "./exts/general.rb"

  client.load_extension Core::Evaler
  client.load_extension Core::Register
  client.load_extension Core::Nickname
  client.load_extension Core::Status
  client.load_extension Core::General
end

client.dispatch(:load_extension)

client.run ENV["TOKEN"]  # Starts client
