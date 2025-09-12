#!/bin/bash

# ========================================
# Nexus CLI Node Installer for Ubuntu VPS
# 対象: Ubuntu (Debian系)
# 前提: Web上でアカウント登録済み & ノードID取得済み
# 機能:
#   - CRLF → LF 変換（Windows形式テキスト対応）
#   - Nexus CLI インストール
#   - ノードID設定
#   - systemdでバックグラウンド常駐
# ========================================

set -euo pipefail  # 厳格モード

# === 改行コードの自動修正関数 ===
fix_crlf() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "INFO: CRLF → LF を適用中: $file"
        sed -i 's/\r$//' "$file"
        echo "INFO: $file の改行コードをLFに変換しました。"
    else
        echo "WARN: ファイルが存在しません: $file"
    fi
}

# === 初期化 ===
echo "🚀 Nexus CLI ノード インストーラーを開始します..."

# スクリプト自体のCRLFを修正（コピー貼り付け時の対策）
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
fix_crlf "$SCRIPT_PATH"

# ホームディレクトリ
HOME_DIR="$HOME"
NEXUS_DIR="$HOME_DIR/.nexus"
CREDENTIALS_FILE="$NEXUS_DIR/credentials.json"

# === ノードIDの入力 ===
read -p "🔧 ノードIDを入力してください: " NODE_ID
if [[ -z "$NODE_ID" ]]; then
    echo "❌ ノードIDが空です。終了します。"
    exit 1
fi

# === 必要なツールのインストール ===
echo "📦 必要なパッケージをインストール中..."
sudo apt update
sudo apt install -y curl jq wget systemd

# === Nexus CLI インストール ===
echo "⬇️ Nexus CLI をダウンロードしてインストール中..."

# 公式ドキュメントに基づき、適切なバイナリを取得（例: Linux x86_64）
CLI_VERSION="latest"  # 将来は固定バージョン推奨
BIN_DIR="/usr/local/bin"
NEXUS_BIN="$BIN_DIR/nexus"

# 一時ディレクトリ
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# GitHub リリースから最新の Linux バイナリを取得（ダミーURL、実際のURLは公式確認要）
# 注意: 現在のドキュメントでは直接URLが明記されていないため、仮のもの。後で更新必要。
echo "ℹ️ 実際のバイナリURLは https://docs.nexus.xyz を確認してください。"
echo "⚠️ 本スクリプトは例として動作を想定しています。"

# 【重要】実際のバイナリURLをここに置き換えてください
# 例: https://github.com/nexus-xyz/network-cli/releases/download/vX.X.X/nexus-linux-amd64
DOWNLOAD_URL="https://github.com/nexus-xyz/network-cli/releases/latest/download/nexus-linux-amd64"
wget -qO "$NEXUS_BIN" "$DOWNLOAD_URL" || {
    echo "❌ ダウンロード失敗: $DOWNLOAD_URL"
    echo "💡 正しいURLか、GitHubのリリースページを確認してください。"
    exit 1
}

chmod +x "$NEXUS_BIN"

# バージョン確認
if ! command -v nexus &> /dev/null; then
    echo "❌ nexus コマンドがパスにありません。PATHを確認してください。"
    exit 1
fi

echo "✅ nexus CLI のインストール完了: $(nexus --version)"

# === 設定ディレクトリ作成 ===
mkdir -p "$NEXUS_DIR"

# === credentials.json にノードIDを保存（register-user/register-node相当）===
# ドキュメントでは credentials.json に保存とあるが、フォーマット非公開のため簡易版
cat > "$CREDENTIALS_FILE" <<EOF
{
  "node_id": "$NODE_ID"
}
EOF

echo "🔐 資格情報は $CREDENTIALS_FILE に保存されました。"

# === systemdサービスの作成（バックグラウンド常駐）===
SERVICE_NAME="nexus-node.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

echo "⚙️ systemdサービスを設定中: $SERVICE_NAME"

sudo bash -c "cat > $SERVICE_PATH" <<EOL
[Unit]
Description=Nexus Network CLI Node
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME_DIR
ExecStart=$NEXUS_BIN prove --node-id $NODE_ID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOL

# === サービスの有効化と起動 ===
echo "🔄 systemdデーモンを再読み込み..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# === 状態確認 ===
echo "✅ サービスの状態を確認中..."
sleep 3
sudo systemctl status "$SERVICE_NAME" --no-pager -l

# === 完了メッセージ ===
echo "🎉 セットアップ完了！"
echo ""
echo "📊 状態確認コマンド:"
echo "   sudo systemctl status nexus-node.service"
echo "   journalctl -u nexus-node.service -f"
echo ""
echo "🛑 停止するには: sudo systemctl stop nexus-node.service"
echo "🔁 再起動: sudo systemctl restart nexus-node.service"
echo ""
echo "ℹ️  ノードはバックグラウンドで常駐し、VPS再起動後も自動起動します。"
