#!/bin/bash

# スクリプトの実行中にエラーが発生した場合、即座に終了する
set -e

echo "🚀 Nexus CLIノードの自動インストールと起動を開始します..."

# --- ノードIDの入力 ---
read -p "ノードIDを入力してください: " NODE_ID

if [ -z "$NODE_ID" ]; then
  echo "❌ ノードIDが入力されていません。スクリプトを終了します。"
  exit 1
fi

echo "✅ ノードID: $NODE_ID を使用します。"

# --- 必要な依存関係のインストール ---
echo "⚙️ 必要な依存関係をインストール中..."
sudo apt-get update
sudo apt-get install -y git curl build-essential

# --- Nexus CLIのダウンロードとビルド ---
echo "📦 Nexus CLIのソースコードをダウンロード中..."
# 最新のリリースバージョンを取得する代わりに、mainブランチを使用します。
# 特定のバージョンを指定する場合は、このURLを変更してください。
if [ -d "nexus" ]; then
    echo "警告: 'nexus' ディレクトリが既に存在します。既存のディレクトリを使用します。"
else
    git clone https://github.com/nexus-xyz/nexus.git
fi
cd nexus

echo "🛠️ Nexus CLIをビルド中..."
./build.sh

# ビルドしたバイナリを$PATHが通っている場所に移動
echo "📁 バイナリを /usr/local/bin/ に移動中..."
sudo cp ./target/release/nexus-cli /usr/local/bin/

echo "✅ Nexus CLIのインストールが完了しました！"
echo ""

# --- ノードのバックグラウンド起動 ---
echo "🚀 Nexus CLIノードをバックグラウンドで起動します..."
echo "ログは '~/nexus_node.log' ファイルに書き込まれます。"

# nohup: ログアウトしてもプロセスを終了させない
# & : プロセスをバックグラウンドで実行
# ノードIDを引数として渡す
nohup nexus-cli run --testnet --node "$NODE_ID" > ~/nexus_node.log 2>&1 &

# プロセスが起動していることを確認
echo "🧐 プロセスの状態を確認中..."
if pgrep -f "nexus-cli run --testnet --node $NODE_ID" > /dev/null
then
    echo "🎉 プロセスが正常に稼働中です。VPSを切断してもプロセスは維持されます。"
    echo "ログファイル: ~/nexus_node.log"
else
    echo "❌ プロセスの起動に失敗したようです。ログファイルを確認してください。"
    exit 1
fi

echo ""
echo "これで、`nexus-cli`コマンドを使ってNexus Testnetノードを操作できます。"
echo "ノードの状態を確認するには、`tail -f ~/nexus_node.log`を実行してください。"
