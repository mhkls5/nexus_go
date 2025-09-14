#!/bin/bash

# ========================================
# Nexus CLI Node Installer (Testnet III)
# Official Method: curl https://cli.nexus.xyz/ | sh
# =========================================
set -euo pipefail

echo "🚀 Nexus CLI ノード インストーラーを開始します..."

# --- ステップ1: 公式インストールスクリプトを実行 ---
echo "⬇️ 公式インストーラーから Nexus CLI をインストール中..."
curl -sL https://cli.nexus.xyz/ | sh

# --- PATHの設定（現在のシェルにも反映）---
export PATH="$HOME/.nexus/bin:$PATH"

# --- ステップ2: ノードIDの入力 ---
echo ""
read -p "🔧 使用するノードIDを入力してください: " NODE_ID
if [[ -z "$NODE_ID" ]]; then
    echo "❌ ノードIDが空です。終了します。"
    exit 1
fi

# --- ステップ3: systemdサービスの作成 ---
SERVICE_FILE="/etc/systemd/system/nexus-node.service"

sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=Nexus Network CLI Node
After=network.target

[Service]
Type=simple
User=$USER
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.nexus/bin
ExecStart=$HOME/.nexus/bin/nexus-network start --node-id $NODE_ID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

# --- ステップ4: サービスの起動 ---
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
echo ""
echo "ℹ️ 注意: VPS再起動後も自動で起動します。"