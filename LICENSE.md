
---

## 🔧 GitHub リポジトリの作成手順

1. [GitHub にログイン](https://github.com)
2. 「New repository」を作成
   - 名前: `nexus-node-installer-ja`
   - 説明: `One-click installer for Nexus CLI node (Japanese)`
   - Public にして作成
3. 以下のファイルをアップロード：
   - `setup-nexus-node.sh`
   - `README.md`
   - （任意）`LICENSE`

---

## 🌐 公開後の使い方（ユーザー向け）

ユーザーはこれだけを実行：

```bash
wget https://raw.githubusercontent.com/あなたのユーザー名/nexus-node-installer-ja/main/setup-nexus-node.sh
chmod +x setup-nexus-node.sh
./setup-nexus-node.sh