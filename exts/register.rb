require "discorb"

module Core::Register
  extend Discorb::Extension

  slash "register", "新しいPrefixを登録します。", {
    "bot" => {
      description: "登録するPrefixのBot。",
      type: :user,
      required: true,
    },
    "prefix" => {
      description: "登録するPrefix。",
      type: :string,
      required: true,
    },
  } do |interaction, bot, prefix|
    unless interaction.target.guild_permissions.manage_guild?
      interaction.post("`サーバーの管理`権限がありません。", ephemeral: true)
      next
    end
    unless bot.bot?
      interaction.post("Bot以外は登録できません。", ephemeral: true)
      next
    end
    @client.db.exec_prepared("insert_prefix", [interaction.guild.id.to_s, bot.id.to_s, prefix.to_s])
    interaction.post("#{bot.mention} のPrefixを `#{prefix}` として登録しました。", ephemeral: true)
  end

  slash "show", "登録しているPrefixを表示します。", {
    "bot" => {
      description: "Prefixを表示するBot。",
      type: :user,
    },
  } do |interaction, bot|
    unless bot.bot?
      interaction.post("Bot以外は表示できません。", ephemeral: true)
      next
    end
    prefix = @client.db.exec_prepared("select_prefix", [interaction.guild.id.to_s, bot.id.to_s]).first
    unless prefix
      interaction.post("#{bot.mention} は登録されていません。", ephemeral: true)
      next
    end
    interaction.post("#{bot.mention} のPrefixは `#{prefix["prefix"]}` です。", ephemeral: true)
    next
  end

  event :prepare_db do
    @client.db.prepare("insert_prefix", <<~SQL)
      INSERT INTO prefixes (guild_id, bot_id, prefix) VALUES ($1, $2, $3)
      ON CONFLICT ON CONSTRAINT uniq_bot_per_guild
      DO UPDATE SET prefix = $3
    SQL
    @client.db.prepare("select_prefix", "SELECT prefix FROM prefixes WHERE guild_id = $1 AND bot_id = $2")
  end
end
