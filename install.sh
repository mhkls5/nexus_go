#!/bin/bash

# ========================================
# Nexus CLI Node Installer (Testnet III)
# For Ubuntu VPS | Fixed & Reliable
# =========================================
set -euo pipefail

echo "🚀 Nexus CLI ノード インストーラーを開始します..."

# --- 必須ツールのインストール ---
sudo apt update -qq
sudo apt install -y curl jq wget systemd

# --- Nexus CLI バイナリのダウンロード ---
NEXUS_BIN="/usr/local/bin/nexus"
# 🔧 重要: URL末尾の不要なスペースを完全削除
CLI_URL="https://github.com/nexus-xyz/network-cli/releases/latest/download/nexus-linux-amd64"

echo "⬇️ Nexus CLI をダウンロード中..."
wget -qO "$NEXUS_BIN" "$CLI_URL" || {
    echo "❌ ダウンロード失敗: $CLI_URL"
    echo "💡 正しいURLは https://docs.nexus.xyz を確認してください。"
    exit 1
}
chmod +x "$NEXUS_BIN"

# --- 設定ディレクトリ作成 ---
NEXUS_DIR="$HOME/.nexus"
mkdir -p "$NEXUS_DIR"

# --- ノードIDの入力 ---
read -p "🔧 ノードIDを入力してください: " NODE_ID
if [[ -z "$NODE_ID" ]]; then
    echo "❌ ノードIDが空です。終了します。"
    exit 1
fi

# --- credentials.json に保存 ---
cat > "$NEXUS_DIR/credentials.json" <<EOF
{
  "node_id": "$NODE_ID"
}
EOF
chmod 600 "$NEXUS_DIR/credentials.json"
echo "🔐 資格情報を $NEXUS_DIR/credentials.json に保存しました。"

# --- register-node 実行 ---
echo "🔄 ノードを登録中..."
nexus register-node || echo "⚠️ 登録スキップ（既に登録済み？）"

# --- systemdサービス登録 ---
SERVICE_FILE="/etc/systemd/system/nexus-node.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=Nexus CLI Proving Node
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
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

# --- 完了メッセージ ---
echo "🎉 セットアップ完了！ノードはバックグラウンドで稼働中です。"

echo ""
echo "📊 状態確認コマンド:"
echo "   sudo systemctl status nexus-node.service"
echo "   journalctl -u nexus-node.service -f"
echo ""
echo "🛑 停止: sudo systemctl stop nexus-node.service"
echo "🔁 再起動: sudo systemctl restart nexus-node.service"