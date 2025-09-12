#!/bin/bash

# Nexus CLI ノード自動セットアップスクリプト
# 前提: ユーザーは app.nexus.xyz でアカウント作成済み
# 機能: インストール → 登録 → ノードID入力 → screen常駐起動
# 注意: ノードIDは任意。後で app.nexus.xyz から確認・変更可能

set -euo pipefail

SCREEN_NAME="nexus-node"
INSTALL_URL="https://cli.nexus.xyz/"  # ← ここにスペースなし！

echo "========================================"
echo "   Nexus CLI ノード自動セットアップ"
echo "========================================"
echo "🔹 前提: あなたは https://app.nexus.xyz で"
echo "      アカウントを作成済みです。"
echo "🔹 操作: 以下でノードIDを入力してください。"
echo "      （例: mynode01、後でWebから変更可）"
echo "========================================"

# 1. 必要ツールのインストール
if ! command -v curl &> /dev/null; then
    echo "[*] curl をインストール中..."
    apt update && apt install -y curl
fi

if ! command -v screen &> /dev/null; then
    echo "[*] screen をインストール中..."
    apt install -y screen
fi

# 2. CLIのインストール
if ! command -v nexus-network &> /dev/null; then
    echo "[*] Nexus CLI をインストール中..."
    curl -fsSL "$INSTALL_URL" | sh
    echo "[+] CLIのインストール完了"

    # PATHの更新
    source ~/.bashrc || true
    source ~/.zshrc || true
else
    echo "[+] CLIは既にインストール済み"
fi

# 3. 既に登録済みか確認
CREDENTIALS="$HOME/.nexus/credentials.json"
if [ -f "$CREDENTIALS" ]; then
    echo "[*] 既に登録済み: $CREDENTIALS"
    echo "    削除する場合は rm -f $CREDENTIALS"
else
    # 4. register-user でアカウントとリンク
    echo
    echo "[*] NexusアカウントとCLIをリンク中..."
    echo "    （app.nexus.xyzで作成したアカウント）"
    nexus-network register-user

    # 5. register-node でノード登録
    echo
    echo "[*] ノードを登録中..."
    nexus-network register-node
fi

# 6. ノードIDの入力
echo
echo "🔹 CLI起動時のノード名を入力してください"
echo "   （例: mynode01、後でapp.nexus.xyzで変更可）"
read -p "ノードID: " NODE_ID

if [ -z "$NODE_ID" ]; then
    echo "❌ エラー: ノードIDが空です。"
    exit 1
fi

# 7. 既存のscreenセッションを停止
if screen -list | grep -q "$SCREEN_NAME"; then
    echo "[*] 既存のノードを停止: $SCREEN_NAME"
    screen -S "$SCREEN_NAME" -X quit || true
    sleep 2
fi

# 8. 新規起動
echo "[*] ノードを起動中: $NODE_ID"
screen -dmS "$SCREEN_NAME" nexus-network start --node-id "$NODE_ID"

# 9. 完了メッセージ
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
