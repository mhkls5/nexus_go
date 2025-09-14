#!/bin/bash

# ========================================
# Nexus CLI Node Installer & Starter
# Usage: curl -sL https://raw.githubusercontent.com/mhkls5/nexus_go/main/install.sh | bash
# =========================================
set -euo pipefail

echo "🚀 Nexus CLI ノード インストーラーを開始します..."

# 🔧 --- ここにあなたのノードIDを入力してください ---
NODE_ID="YOUR_NODE_ID_HERE"
#    ↑↑↑ ここを編集！例: abc1-def2-ghi3-jkl4
#
# 📌 先にこのファイルを編集してから実行する必要があります。
#    VPS上で直接実行しないでください。
#    1. https://app.nexus.xyz/nodes でNode IDを取得
#    2. このinstall.shの上の行を編集（YOUR_NODE_ID_HERE → 実際のID）
#    3. GitHubに保存
#    4. それからVPSでcurl | bash実行

if [[ "$NODE_ID" == "YOUR_NODE_ID_HERE" ]]; then
    cat >&2 <<'EOF'
❌ エラー：ノードIDが設定されていません！

🔧 解決方法：
1. GitHubでこのファイルを編集:
   https://github.com/mhkls5/nexus_go/edit/main/install.sh
2. 7行目を編集:
     NODE_ID="YOUR_NODE_ID_HERE"
   ↓
     NODE_ID="abc1-def2-ghi3-jkl4"
3. 変更を「Commit changes」で保存
4. その後、VPSで再実行:
   curl -sL https://raw.githubusercontent.com/mhkls5/nexus_go/main/install.sh | bash
EOF
    exit 1
fi

# --- Step 1: 公式インストーラーでCLIをインストール ---
echo "⬇️ 公式インストーラーから Nexus CLI をインストール中..."
curl -sL https://cli.nexus.xyz/ | sh

# --- PATHの反映 ---
export PATH="$HOME/.nexus/bin:$PATH"

# --- Step 2: systemdサービスの作成 ---
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

# --- Step 3: サービスの起動 ---
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