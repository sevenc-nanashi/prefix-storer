module Core::Nickname
  extend Discorb::Extension

  event :prepare_db do
    @client.db.prepare("find_prefix_in_guild", <<~SQL)
      SELECT prefix, bot_id FROM prefixes WHERE guild_id = $1
    SQL
    @client.db.prepare("find_prefix_format", <<~SQL)
      SELECT format FROM nick_formats WHERE guild_id = $1
    SQL

    @client.db.prepare("upsert_format", <<~SQL)
      INSERT INTO nick_formats (guild_id, format) VALUES ($1, $2)
      ON CONFLICT ON CONSTRAINT uniq_guild_id
      DO UPDATE SET format = $2
    SQL
  end

  slash_group "pnick", "ニックネーム変更関連のコマンドです。" do |group|
    group.slash "format", "ニックネームのフォーマットを変更します。", {
      "format" => {
        description: "ニックネームのフォーマットを指定します。プレフィックスは{prefix}、Bot名は{name}で指定して下さい。",
        type: :string,
        required: true,
      },
    } do |interaction, fmt|
      unless interaction.target.permissions.manage_guild?
        interaction.post("`サーバーの管理`権限がありません。", ephemeral: true)
        next
      end

      @client.db.exec_prepared("upsert_format", [interaction.guild.id.to_s, fmt])
      interaction.post("フォーマットを指定しました。\nサンプル：#{format_prefix(fmt, "/", "Prefix Finder")}", ephemeral: true)
      next
    end

    group.slash "change", "Botのニックネームを変更します。", {} do |interaction|
      unless interaction.target.permissions.manage_guild?
        interaction.post("`サーバーの管理`権限がありません。", ephemeral: true)
        next
      end
      interaction.defer_source(ephemeral: true).wait
      nick_format = @client.db.exec_prepared("find_prefix_format", [interaction.guild.id.to_s]).first
      bot_prefixes = @client.db.exec_prepared("find_prefix_in_guild", [interaction.guild.id.to_s])
      if nick_format.nil?
        interaction.post("`nick format`コマンドでフォーマットを設定して下さい。", ephemeral: true).wait
        next
      end
      nick_format = nick_format["format"]
      bots = interaction.guild.members.filter(&:bot?)
      bots_kv = bots.filter_map { |b| (f = bot_prefixes.find { |pr| pr["bot_id"] == b.id }) ? [b, f] : nil }
      interaction.post("#{bots_kv.length}個のBotを変更します。", ephemeral: true).wait

      counter = { success: 0, failure: 0, skipped: 0 }
      bots_kv.each do |b, f|
        bot_format = format_prefix(nick_format, f["prefix"], b.username)
        if b.name == bot_format
          counter[:skipped] += 1
          next
        end
        begin
          if b == @client.user
            interaction.guild.edit_nickname(bot_format)
          else
            b.edit(nick: bot_format).wait
          end
        rescue Discorb::ForbiddenError
          counter[:failure] += 1
        else
          counter[:success] += 1
        end
      end
      interaction.post("#{counter[:success]}個のBotのニックネームを変更しました。\n成功: #{counter[:success]}\n失敗: #{counter[:failure]}\n変更無し: #{counter[:skipped]}", ephemeral: true)
    end
  end

  class << self
    def format_prefix(base, prefix, name)
      base.gsub("{prefix}", prefix).gsub("{name}", name)
    end
  end
end
