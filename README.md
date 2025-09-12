# Nexus CLI ノード自動セットアップ

このスクリプトを使うと、**たった1つのコマンド**で Nexus CLI ノードをセットアップできます。

- ✅ `app.nexus.xyz` でアカウント作成済みが前提
- ✅ CLIのインストール・登録・起動を自動化
- ✅ ノードIDを入力して、`screen` で常駐起動
- ✅ SSH切断後も動き続ける
- ✅ 後で [app.nexus.xyz](https://app.nexus.xyz) からノード名を編集可能

---

## 🔧 インストール手順

VPS に SSH 接続して、以下の3行を順番に実行するだけ👇


# 1. スクリプトをダウンロード（IPv4限定で安定）
wget --inet4-only https://raw.githubusercontent.com/mhkls5/nexus_go/main/setup-nexus-node.sh

# 2. 実行権限を付ける
chmod +x setup-nexus-node.sh

# 3. 実行（ノードIDを聞かれます）
./setup-nexus-node.sh

## ⚠️ 注意

- このスクリプトは [Nexus XYZ](https://nexus.xyz) の公式ツールではありません。
- [Nexus CLI](https://cli.nexus.xyz/) を簡単にセットアップできるようにするための **コミュニティ作成ツール**です。
- 公式ドキュメント: https://docs.nexus.xyz

