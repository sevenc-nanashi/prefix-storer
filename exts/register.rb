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
    unless interaction.target.permissions.manage_guild?
      interaction.post("`サーバーの管理`権限がありません。", ephemeral: true)
      next
    end
    unless bot.bot?
      interaction.post("Bot以外は登録できません。", ephemeral: true)
      next
    end
    interaction.defer_source(ephemeral: true).wait
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
    interaction.defer_source(ephemeral: true).wait
    prefix = @client.db.exec_prepared("select_prefix", [interaction.guild.id.to_s, bot.id.to_s]).first
    unless prefix
      interaction.post("#{bot.mention} は登録されていません。", ephemeral: true)
      next
    end
    interaction.post("#{bot.mention} のPrefixは `#{prefix["prefix"]}` です。", ephemeral: true)
    next
  end

  slash "delete", "Prefixの登録を解除します。", {
    "bot" => {
      description: "Prefixの登録を解除するBot。",
      type: :user,
    },
  } do |interaction, bot|
    unless interaction.target.permissions.manage_guild?
      interaction.post("`サーバーの管理`権限がありません。", ephemeral: true)
      next
    end
    unless bot.bot?
      interaction.post("Bot以外は削除できません。", ephemeral: true)
      next
    end
    interaction.defer_source(ephemeral: true).wait
    result = @client.db.exec_prepared("delete_prefix", [interaction.guild.id.to_s, bot.id.to_s])
    if result.cmd_tuples == 0
      interaction.post("#{bot.mention} は登録されていません。", ephemeral: true)
    else
      interaction.post("#{bot.mention} のPrefixを削除しました。", ephemeral: true)
    end
  end

  slash "search", "他サーバーからPrefixの情報を取得します。", {
    "bot" => {
      description: "Prefixの情報を取得するBot。",
      type: :user,
    },
  } do |interaction, bot|
    unless bot.bot?
      interaction.post("Bot以外は取得できません。", ephemeral: true)
      next
    end
    interaction.defer_source(ephemeral: true).wait
    prefixes = @client.db.exec_prepared("search_prefix_global", [bot.id.to_s])&.map { |row| row["prefix"] }
    if prefixes == [nil]
      interaction.post("#{bot.mention} のPrefixを見つけられませんでした。", ephemeral: true)
      next
    end
    best_prefix = prefixes.max_by { |prefix| prefixes.count(prefix) }
    interaction.post("#{bot.mention} のPrefixは `#{best_prefix}` が最も多く登録されています。", ephemeral: true).wait

    next unless interaction.target.permissions.manage_guild?

    randstr = SecureRandom.hex(8)
    interaction.post("Prefixを登録しますか？", ephemeral: true,
                                       components: [
                                         Discorb::Button.new("はい", :primary, custom_id: "yes:#{randstr}"),
                                         Discorb::Button.new("いいえ", :danger, custom_id: "no:#{randstr}"),
                                       ]).wait
    button_interaction = @client.event_lock(:button_click, 30) { |interaction| interaction.custom_id.end_with?("#{randstr}") }.wait
    if button_interaction.custom_id.start_with?("yes")
      button_interaction.defer_source(ephemeral: true).wait
      @client.db.exec_prepared("insert_prefix", [interaction.guild.id.to_s, bot.id.to_s, best_prefix])
      button_interaction.post("#{bot.mention} のPrefixを `#{best_prefix}` として登録しました。", ephemeral: true)
    else
      button_interaction.post("登録をキャンセルしました。", ephemeral: true)
    end
  end

  slash "import", "他サーバーからPrefixの情報を取得し、一括で適用します。", {
    "override" => {
      description: "登録済みのPrefixを上書きするかどうか。",
      type: :boolean,
    },
  } do |interaction, override|
    unless interaction.target.permissions.manage_guild?
      interaction.post("`サーバーの管理`権限がありません。", ephemeral: true)
      next
    end
    processing_msg = interaction.post("Prefixの情報を取得しています...", ephemeral: true).wait
    raw_prefixes = @client.db.exec(<<~SQL)
      SELECT prefix, bot_id FROM prefixes WHERE bot_id IN (#{interaction.guild.members.filter(&:bot?).map(&:id).map { |id| "'#{id}'" }.join(",")})
    SQL
    prefixes = raw_prefixes.group_by { |prefix| prefix["bot_id"] }.map do |bot_id, prefix|
      [bot_id, prefix.max_by { |prefix| prefix.count(prefix) }["prefix"]]
    end.to_h
    processing_msg.edit("#{prefixes.length}BotのPrefixの情報を取得しました。")
    unless override
      guild_prefixes = @client.db.exec_prepared("search_prefix_guild", [interaction.guild.id.to_s])&.map { |row| [row["bot_id"], row["prefix"]] }&.to_h
      prefixes.merge!(guild_prefixes)
    end
    prefixes.each do |bot_id, prefix|
      @client.db.exec_prepared("insert_prefix", [interaction.guild.id.to_s, bot_id, prefix])
    end
    interaction.post("Prefixを登録しました。", ephemeral: true)
  end

  user_command "Prefixを表示" do |interaction, user|
    unless user.bot?
      interaction.post("Bot以外は表示できません。", ephemeral: true)
      next
    end
    interaction.defer_source(ephemeral: true).wait
    prefix = @client.db.exec_prepared("select_prefix", [interaction.guild.id.to_s, user.id.to_s]).first
    unless prefix
      interaction.post("#{user.mention} は登録されていません。", ephemeral: true)
      next
    end
    interaction.post("#{user.mention} のPrefixは `#{prefix["prefix"]}` です。", ephemeral: true)
    next
  end

  event :prepare_db do
    @client.db.prepare("insert_prefix", <<~SQL)
      INSERT INTO prefixes (guild_id, bot_id, prefix) VALUES ($1, $2, $3)
      ON CONFLICT ON CONSTRAINT uniq_bot_per_guild
      DO UPDATE SET prefix = $3
    SQL

    @client.db.prepare("select_prefix", <<~SQL)
      SELECT prefix FROM prefixes WHERE guild_id = $1 AND bot_id = $2
    SQL

    @client.db.prepare("delete_prefix", <<~SQL)
      DELETE FROM prefixes WHERE guild_id = $1 AND bot_id = $2
    SQL

    @client.db.prepare("search_prefix_global", <<~SQL)
      SELECT prefix FROM prefixes WHERE bot_id = $1
    SQL

    @client.db.prepare("search_prefix_guild", <<~SQL)
      SELECT prefix, bot_id FROM prefixes WHERE guild_id = $1
    SQL
  end
end
