# Prefix Viewer

このBotはBotのプレフィックスを保存し、一括でニックネームを変更できるBotです。

[招待](https://discord.com/api/oauth2/authorize?client_id=804818670974402591&permissions=201326592&scope=bot%20applications.commands)

## 使い方

`/register` でBotのプレフィックスを登録します。
`/show` で登録したプレフィックスを表示します。
`/pnick format` でニックネームのフォーマットを変更します。
`/pnick change` でBotのニックネームを変更します。

### フォーマット

| フォーマット | 例 |
| ----------- | --- |
| `[ {prefix} ] {name}` | `[ / ] Prefix Viewer` |
| `<{prefix}> {name}` | `</> Prefix Viewer` |
| `{prefix} ) {name}` | `/ ) Prefix Viewer` |
| `{prefix}> {name}` | `/ > Prefix Viewer` |
| `{name}: {prefix}` | `Prefix Viewer: /` |

## ライセンス

MIT Licenseで公開しています。
