#!/bin/bash

# Nexus CLIノードセットアップスクリプト（Ubuntu用）
# 使用方法: ./setup_nexus_node.sh [ノードID]
# ノードIDを引数として指定しない場合、入力プロンプトが表示されます。
# 前提: Ubuntu VPS、Nexusサイトでアカウント登録済み、ノードID発行済み
# このスクリプトは依存関係のインストール、Nexus CLIのセットアップを行い、
# ノードをバックグラウンドのscreenセッションで継続的に実行します。
# セッションに接続: screen -r nexus-node
# セッションから離れる: Ctrl+A してから D
# ノード停止: screen -S nexus-node -X quit

set -e  # エラーが発生したら終了

# ノードIDを引数またはプロンプトから取得
if [ $# -eq 0 ]; then
    read -p "ノードIDを入力してください: " NODE_ID
else
    NODE_ID="$1"
fi

if [ -z "$NODE_ID" ]; then
    echo "エラー: ノードIDが必要です。"
    exit 1
fi

echo "ノードID: $NODE_ID でNexus CLIノードをセットアップします"

# パッケージリストを更新し、依存関係をインストール
sudo apt update
sudo apt install -y curl screen

# Nexus CLIをインストール
echo "Nexus CLIをインストールしています..."
curl https://cli.nexus.xyz/ | sh

# シェル環境を更新
source ~/.bashrc

# バックグラウンドで動作するscreenセッションを作成
echo "screenセッション 'nexus-node' でNexusノードをバックグラウンド起動します..."
screen -dmS nexus-node bash -c "
    echo 'Nexusノードを起動中...';
    nexus-network start --node-id $NODE_ID;
    echo 'ノードが起動しました。セッションは継続します。';
    exec bash
"

echo "セットアップが完了しました！"
echo "ノードは 'nexus-node' というscreenセッションでバックグラウンドで実行中です。"
echo "ログ確認や操作: screen -r nexus-node"
echo "セッションから離れる: Ctrl+A してから D"
echo "セッション一覧: screen -ls"
echo "ノード停止: screen -S nexus-node -X quit"