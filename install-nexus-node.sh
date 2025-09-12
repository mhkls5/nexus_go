#!/bin/bash

# ========================================
# Nexus CLI Node Auto Installer
# GitHub: https://github.com/your-username/nexus-node-installer
# Usage: curl -sL https://git.io/install-nexus | bash
# =========================================

set -euo pipefail

# --- 関数：CRLF → LF 変換 ---
fix_crlf() {
    local file="$1"
    if [[ -f "$file" ]]; then
        sed -i 's/\r$//' "$file"
    fi
}

# --- CRLF自動修正（スクリプト自体）---
SCRIPT_PATH="/tmp/nexus-install-$$.sh"
cat > "$SCRIPT_PATH" << 'EOF'
# SCRIPT_PLACEHOLDER
EOF

fix_crlf "$SCRIPT_PATH"
source "$SCRIPT_PATH"
rm -f "$SCRIPT_PATH"
exit 0

# === 実際のスクリプト内容はここから ===
# （上記の "EOF" の中に挿入される本体）

echo "🚀 Nexus CLI ノード インストーラーを開始します..."

HOME_DIR="$HOME"
NEXUS_DIR="$HOME_DIR/.nexus"
CREDENTIALS_FILE="$NEXUS_DIR/credentials.json"

# --- ノードID入力 ---
read -p "🔧 ノードIDを入力してください: " NODE_ID
if [[ -z "$NODE_ID" ]]; then
    echo "❌ ノードIDが空です。終了します。"
    exit 1
fi

# --- 必須ツールのインストール ---
echo "📦 必要なパッケージをインストール中..."
sudo apt update -qq > /dev/null
sudo apt install -y curl jq wget systemd > /dev/null

# --- Nexus CLI バイナリのダウンロード ---
echo "⬇️ Nexus CLI をダウンロードしています..."

NEXUS_BIN="/usr/local/bin/nexus"
mkdir -p /tmp/nexus-tmp && cd /tmp/nexus-tmp

# 【重要】公式バイナリURL（2025年4月時点での例。最新版はGitHub参照）
CLI_URL="https://github.com/nexus-xyz/network-cli/releases/latest/download/nexus-linux-amd64"
wget -qO "$NEXUS_BIN" "$CLI_URL" || {
    echo "❌ ダウンロード失敗: $CLI_URL"
    echo "💡 正しいURLは https://docs.nexus.xyz を確認してください。"
    exit 1
}
chmod +x "$NEXUS_BIN"

echo "✅ nexus CLI をインストール: $(nexus --version 2>/dev/null || echo 'バージョン不明')"

# --- 設定ディレクトリとcredentials ---
mkdir -p "$NEXUS_DIR"
cat > "$CREDENTIALS_FILE" <<EOF
{
  "node_id": "$NODE_ID"
}
EOF
chmod 600 "$CREDENTIALS_FILE"
echo "🔐 資格情報を $CREDENTIALS_FILE に保存しました。"

# --- register-node 相当の処理（必要に応じて）---
echo "🔄 ノード登録中..."
if ! nexus register-node; then
    echo "⚠️ register-node に失敗しましたが、続行します。"
fi

# --- systemdサービスの作成 ---
SERVICE_FILE="/etc/systemd/system/nexus-node.service"

sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=Nexus CLI Proving Node
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME_DIR
ExecStart=/usr/local/bin/nexus prove
Restart=always
RestartSec=5
Environment=HOME=$HOME_DIR

[Install]
WantedBy=multi-user.target
EOL

# --- サービスの起動 ---
echo "🔄 systemdサービスを有効化・起動中..."
sudo systemctl daemon-reload
sudo systemctl enable nexus-node.service
sudo systemctl start nexus-node.service

# --- 結果表示 ---
echo "🎉 セットアップ完了！ノードはバックグラウンドで稼働中です。"

echo ""
echo "📊 状態確認:"
echo "   sudo systemctl status nexus-node.service"
echo "   journalctl -u nexus-node.service -f"
echo ""
echo "🛑 停止: sudo systemctl stop nexus-node.service"
echo "🔁 再起動: sudo systemctl restart nexus-node.service"
