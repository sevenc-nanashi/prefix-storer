require "discorb"

class Core::General
  include Discorb::Extension

  slash "help", "ヘルプを表示します。" do |interaction|
    interaction.post <<~EOS, ephemeral: true
                               Botのプレフィックスを保存して、ニックネームを変更するBotです。
                               `/register`でプレフィックスを登録し、
                               `/pnick format`でフォーマットを変更した後に、
                               `/pnick change`でニックネームを変更します。

                               [ソースコード(sevenc-nanashi/prefix-storer)](https://github.com/sevenc-nanashi/prefix-storer)
                               [招待リンク](https://discord.com/api/oauth2/authorize?client_id=889451143216898048&permissions=201326592&scope=bot%20applications.commands)
                               [サポートサーバー](https://discord.gg/3xb8WKUu3h)
                             EOS
  end
end
