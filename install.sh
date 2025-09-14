#!/bin/bash

# Nexus CLIノードセットアップスクリプト（Ubuntu用）
# 使用方法: ./install.sh <ノードID>
# ノードIDは必須で、引数として指定してください。
# 前提: Ubuntu VPS、Nexusサイトでアカウント登録済み、ノードID発行済み
# このスクリプトは依存関係のインストール、Nexus CLIのセットアップを行い、
# ノードをバックグラウンドのscreenセッションで継続的に実行します。
# ログは /root/nexus-node.log に保存されます。
# セッションに接続: screen -r nexus-node
# セッションから離れる: Ctrl+A してから D
# ノード停止: screen -S nexus-node -X quit

set -e  # エラーが発生したら終了

# ノードIDを引数から取得
NODE_ID="$1"

if [ -z "$NODE_ID" ]; then
    echo "エラー: ノードIDが必要です。"
    echo "使用方法: $0 <ノードID>"
    echo "例: $0 abc123xyz"
    echo "1発コマンド: curl -sSL https://raw.githubusercontent.com/mhkls5/nexus_go/main/install.sh | bash -s <ノードID>"
    exit 1
fi

echo "ノードID: $NODE_ID でNexus CLIノードをセットアップします"

# パッケージリストを更新し、依存関係をインストール
echo "依存関係をインストールしています..."
sudo apt update
sudo apt install -y git curl screen

# Nexus CLIをインストール
echo "Nexus CLIをインストールしています..."
curl -sSL https://cli.nexus.xyz/ | bash -s y

# シェル環境を更新
source ~/.bashrc

# ログファイルの準備
LOG_FILE="/root/nexus-node.log"
echo "Nexusノードのログを $LOG_FILE に保存します"

# バックグラウンドで動作するscreenセッションを作成
echo "screenセッション 'nexus-node' でNexusノードをバックグラウンド起動します..."
screen -dmS nexus-node bash -c "
    echo 'Nexusノードを起動中...' | tee -a $LOG_FILE;
    nexus-network start --node-id $NODE_ID 2>&1 | tee -a $LOG_FILE;
    echo 'ノードが起動しました。セッションは継続します。' | tee -a $LOG_FILE;
    exec bash
"

echo "セットアップが完了しました！"
echo "ノードは 'nexus-node' というscreenセッションでバックグラウンドで実行中です。"
echo "ログ確認: cat $LOG_FILE または screen -r nexus-node"
echo "セッションから離れる: Ctrl+A してから D"
echo "セッション一覧: screen -ls"
echo "ノード停止: screen -S nexus-node -X quit"