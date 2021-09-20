require "pg"
require "dotenv"

Dotenv.load

conn = PG.connect(ENV["DATABASE_URL"])

conn.exec(<<~SQL)
  CREATE TABLE IF NOT EXISTS prefixes (
    bot_id text,
    prefix text,
    guild_id text

    constraint unique_bot unique (bot_id, guild_id)
  )
SQL
conn.exec(<<~SQL)
  CREATE TABLE IF NOT EXISTS nick_formats (
    guild_id text,
    format text

    constraint unique_guild unique (guild_id)
  )
SQL
