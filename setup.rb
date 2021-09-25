require "pg"
require "dotenv"

Dotenv.load

conn = PG.connect(ENV["DATABASE_URL"])

conn.exec(<<~SQL)
  CREATE TABLE IF NOT EXISTS prefixes (
    bot_id text,
    prefix text,
    guild_id text,

    CONSTRAINT uniq_bot_per_guild UNIQUE (bot_id, guild_id)
  )
SQL

conn.exec(<<~SQL)
  CREATE TABLE IF NOT EXISTS nick_formats (
    guild_id text,
    format text,

    CONSTRAINT uniq_guild_id UNIQUE (guild_id)
  )
SQL

conn.exec(<<~SQL)
  CREATE TABLE IF NOT EXISTS default_prefixes (
    bot_id text,
    prefix text,

    CONSTRAINT uniq_bot_id UNIQUE (bot_id)
  )
SQL
