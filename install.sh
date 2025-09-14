#!/bin/bash

# ========================================
# Nexus CLI Node Installer (Testnet III)
# ✅ 完全対応版：公式インストーラー後でも確実にノードID入力可能
# Usage: curl -sL https://... | bash -s
# =========================================
set -euo pipefail

echo "🚀 Nexus CLI ノード インストーラーを開始します..."

# --- Step 1: ノードIDの入力を「別ファイル」で事前取得 ---
INPUT_SCRIPT="/tmp/nexus-get-nodeid.sh"

cat > "$INPUT_SCRIPT" << 'EOF'
#!/bin/bash
echo ""
echo "📌 準備ができました。次に、あなたのノードIDを入力します。"
echo "💡 事前に取得が必要です:"
echo "   https://app.nexus.xyz/nodes でサインイン → Node IDをコピー"
echo ""

read -p "🔧 ノードIDを入力してください: " NODE_ID

if [[ -z "$NODE_ID" ]]; then
    echo "❌ ノードIDが空です。再度実行してください。"
    exit 1
fi

# 成功したら一時ファイルに出力
echo "export NEXUS_NODE_ID=\"$NODE_ID\"" > /tmp/nexus-node-id.env
echo "✅ 入力を受け付けました。セットアップを再開します..."
EOF

chmod +x "$INPUT_SCRIPT"

# 🔥 別プロセスとして実行（stdinを公式インストーラーから隔離）
echo "⏳ ノードIDの入力を待っています..."
if ! "$INPUT_SCRIPT"; then
    rm -f "$INPUT_SCRIPT"
    exit 1
fi

# 一時ファイルから読み込み
if [[ -f "/tmp/nexus-node-id.env" ]]; then
    source /tmp/nexus-node-id.env
else
    echo "❌ ノードIDの取得に失敗しました。"
    exit 1
fi

# 後片付け
rm -f "$INPUT_SCRIPT" "/tmp/nexus-node-id.env"

# --- Step 2: 公式インストーラーでCLIをインストール ---
echo "⬇️ 公式インストーラーから Nexus CLI をインストール中..."
curl -sL https://cli.nexus.xyz/ | sh

# PATHを追加
export PATH="$HOME/.nexus/bin:$PATH"

# --- Step 3: systemdサービスの作成 ---
SERVICE_FILE="/etc/systemd/system/nexus-node.service"

sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=Nexus Network CLI Node
After=network.target

[Service]
Type=simple
User=$USER
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.nexus/bin
ExecStart=$HOME/.nexus/bin/nexus-network start --node-id $NEXUS_NODE_ID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

# --- Step 4: サービスの起動 ---
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