#!/bin/bash

# ========================================
# Nexus CLI Node Installer (Testnet III)
# 完全対応版：公式インストーラー後でもノードID入力可能
# Usage: curl -sL https://... | bash -s
# =========================================
set -euo pipefail

echo "🚀 Nexus CLI ノード インストーラーを開始します..."

# --- Step 0: 標準入力を保存 ---
#    公式インストーラーがstdinを奪うので、事前に確保
exec 3<&0  # fd 3 に標準入力を保存

# --- Step 1: 公式インストーラーでCLIをインストール ---
echo "⬇️ 公式インストーラーから Nexus CLI をインストール中..."
curl -sL https://cli.nexus.xyz/ | sh

# PATHを追加（現在のシェルにも反映）
export PATH="$HOME/.nexus/bin:$PATH"

# --- Step 2: 保存した標準入力からノードIDを入力 ---
echo ""
echo "📌 準備ができました。次に、あなたのノードIDを入力します。"
echo "💡 事前に取得が必要です:"
echo "   https://app.nexus.xyz/nodes でサインイン → Node IDをコピー"
echo ""

# 🔥 ここで fd 3（保存した stdin）を使って入力
read -u 3 -p "🔧 ノードIDを入力してください: " NODE_ID

# --- Step 3: 標準入力クローズ ---
exec 3<&-

if [[ -z "$NODE_ID" ]]; then
    echo "❌ ノードIDが空です。再度実行してください。"
    exit 1
fi

# --- Step 4: systemdサービスの作成 ---
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

# --- Step 5: サービスの起動 ---
echo "🔄 systemdサービスを有効化・起動中..."
sudo systemctl daemon-reload
sudo systemctl enable nexus-node.service
sudo systemctl start nexus-node.service

# --- 完了メッセージ ---
echo ""
echo "🎉 セットアップ完了！ノードはバックグラウンドで稼働中です。"
echo ""
echo "📊 状態確認:"
echo "   sudo systemctl status nexus-node.service"
echo "   journalctl -u nexus-node.service -f"
echo ""
echo "🛑 停止: sudo systemctl stop nexus-node.service"
echo "🔁 再起動: sudo systemctl restart nexus-node.service"
echo ""
echo "ℹ️ VPS再起動後も自動で起動します。"