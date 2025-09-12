#!/bin/bash

# ========================================
# Nexus CLI ノード自動セットアップスクリプト
# ========================================
# 前提: https://app.nexus.xyz でアカウント作成済み
# 機能: CLIインストール → 登録 → ノードID入力 → 常駐起動
# 注意: ノードIDは任意。後でWebから変更可
# ========================================

set -euo pipefail

SCREEN_NAME="nexus-node"
INSTALL_URL="https://cli.nexus.xyz/"

echo "========================================"
echo "   Nexus CLI ノード 自動セットアップ"
echo "========================================"
echo "🔹 必須条件:"
echo "   https://app.nexus.xyz でアカウント作成済み"
echo "🔹 このスクリプトは:"
echo "   CLIインストール → 登録 → 起動 を自動化"
echo "🔹 ノードIDは後でWebから編集可能"
echo "========================================"

# 1. 必要なツールを確認・インストール
for cmd in curl screen; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "[*] $cmd をインストール中..."
        apt update && apt install -y "$cmd"
    fi
done

# 2. Nexus CLI をインストール（初回のみ）
if ! command -v nexus-network &> /dev/null; then
    echo "[*] Nexus CLI をインストール中..."
    curl -fsSL "$INSTALL_URL" | sh
    echo "[+] CLIのインストール完了"

    # PATHを更新
    source ~/.bashrc || true
    source ~/.zshrc || true
else
    echo "[+] CLIは既にインストール済み"
fi

# 3. 資格情報ファイルのパス
CREDENTIALS="$HOME/.nexus/credentials.json"

# 4. register-user と register-node を初回のみ実行
if [ ! -f "$CREDENTIALS" ]; then
    echo
    echo "[*] NexusアカウントとCLIをリンク中..."
    echo "    （app.nexus.xyzで作成したアカウント）"
    nexus-network register-user

    echo
    echo "[*] ノードを登録中..."
    nexus-network register-node
else
    echo "[*] 既に登録済み: $CREDENTIALS"
    echo "    削除するには: rm -f $CREDENTIALS"
fi

# 5. ユーザーにノードIDを入力させる
echo
echo "🔹 CLI起動時のノード名を入力してください"
echo "   （例: mynode01、後でapp.nexus.xyzで変更可）"
read -p "ノードID: " NODE_ID

if [ -z "$NODE_ID" ]; then
    echo "❌ エラー: ノードIDが空です。"
    exit 1
fi

# 6. 既存のscreenセッションがあれば停止
if screen -list | grep -q "$SCREEN_NAME"; then
    echo "[*] 既存のノードを停止: $SCREEN_NAME"
    screen -S "$SCREEN_NAME" -X quit || true
    sleep 2
fi

# 7. 新しいセッションで起動（バックグラウンド）
echo "[*] ノードを起動中: $NODE_ID"
screen -dmS "$SCREEN_NAME" nexus-network start --node-id "$NODE_ID"

# 8. 成功メッセージ
echo
echo "✅ 成功！ノードがバックグラウンドで起動しました"
echo "----------------------------------------"
echo "🔧 状態確認:   screen -r $SCREEN_NAME"
echo "🛑 停止するには: screen -S $SCREEN_NAME -X quit"
echo "📁 資格情報:   $CREDENTIALS"
echo "🌐 ノードID:    $NODE_ID"
echo "💡 SSH切断後も動作し続けます"
echo "🌐 後でノード名を変更するには:"
echo "   https://app.nexus.xyz の [Nodes] から編集"
echo "----------------------------------------"
