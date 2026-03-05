#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
#  Musica Player  自動インストーラー
#  対象: Android + Termux（非技術者向け）
#
#  使い方:
#    Termuxで以下を1行ペーストして実行するだけ：
#    curl -sL https://raw.githubusercontent.com/YOUR/REPO/main/install.sh | bash
#    または
#    bash install.sh
# ═══════════════════════════════════════════════════════════════

set -e  # エラーで即停止

# ── カラー定義 ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}✅ $1${RESET}"; }
info() { echo -e "${CYAN}ℹ  $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠  $1${RESET}"; }
err()  { echo -e "${RED}❌ $1${RESET}"; exit 1; }
step() { echo -e "\n${BOLD}── $1 ──${RESET}"; }

# ── バナー ──
clear
echo -e "${CYAN}"
cat << 'BANNER'
  __  __           _             ____  _
 |  \/  |_   _ ___(_) ___ __ _  |  _ \| | __ _ _   _  ___ _ __
 | |\/| | | | / __| |/ __/ _` | | |_) | |/ _` | | | |/ _ \ '__|
 | |  | | |_| \__ \ | (_| (_| | |  __/| | (_| | |_| |  __/ |
 |_|  |_|\__,_|___/_|\___\__,_| |_|   |_|\__,_|\__, |\___|_|
                                                |___/
  Android版  自動インストーラー
BANNER
echo -e "${RESET}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  インストールを開始します。数分かかる場合があります。"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 1

# ── Termux環境チェック ──
step "環境チェック"

if [ ! -d "/data/data/com.termux" ]; then
    err "Termux環境が見つかりません。F-DroidからTermuxをインストールしてください。"
fi
ok "Termux環境を確認しました"

# Android バージョン確認
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "不明")
info "Android バージョン: ${ANDROID_VER}"

# ── パッケージ更新 ──
step "パッケージリストを更新"
info "時間がかかる場合があります..."

# 非対話的に実行（yes/no を自動で y）
yes | pkg update -y 2>/dev/null || pkg update -y
ok "パッケージリストを更新しました"

# ── 必要パッケージのインストール ──
step "必要なプログラムをインストール"

PKGS="python ffmpeg mpv"
for pkg in $PKGS; do
    if command -v $pkg &>/dev/null; then
        ok "$pkg は既にインストール済み"
    else
        info "$pkg をインストール中..."
        pkg install -y $pkg
        ok "$pkg インストール完了"
    fi
done

# pip パッケージ
info "Python ライブラリ (mutagen) をインストール中..."
pip install --quiet mutagen 2>/dev/null || pip install mutagen
ok "mutagen インストール完了"

# ── ストレージ権限の設定 ──
step "ストレージアクセス権限の設定"

if [ -d "$HOME/storage/music" ]; then
    ok "ストレージアクセス権限は既に設定済みです"
else
    warn "ストレージへのアクセス権限を設定します"
    echo ""
    echo -e "${YELLOW}  ★ 重要 ★${RESET}"
    echo "  次のステップで Android の「許可」ダイアログが表示されます。"
    echo "  必ず「許可」を選択してください。"
    echo ""
    read -p "  準備ができたら Enter を押してください... "
    termux-setup-storage
    sleep 3
    if [ -d "$HOME/storage/music" ]; then
        ok "ストレージアクセス権限を設定しました"
    else
        warn "権限の設定を確認できませんでした。後で手動で実行: termux-setup-storage"
    fi
fi

# ── スクリプト本体の配置 ──
step "Musica Player 本体をインストール"

INSTALL_DIR="$HOME/.musica"
mkdir -p "$INSTALL_DIR"

# スクリプト本体をダウンロードまたはコピー
SCRIPT_SRC="$(dirname "$0")/musicaplayer_android.py"
SCRIPT_DST="$INSTALL_DIR/musicaplayer_android.py"

if [ -f "$SCRIPT_SRC" ]; then
    cp "$SCRIPT_SRC" "$SCRIPT_DST"
    ok "Musica Player 本体をコピーしました"
elif command -v curl &>/dev/null; then
    info "スクリプト本体をダウンロード中..."
    curl -sL "https://raw.githubusercontent.com/yasuhito3/Sonia-for-Android/main/musicaplayer_android.py" \
         -o "$SCRIPT_DST"
    ok "Musica Player 本体をダウンロードしました"
else
    err "musicaplayer_android.py が見つかりません。install.sh と同じフォルダに置いてください。"
fi

# ── 起動コマンドの作成 ──
step "起動コマンド「musica」を作成"

LAUNCHER="$PREFIX/bin/musica"
cat > "$LAUNCHER" << 'LAUNCHEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Musica Player 起動スクリプト
SCRIPT="$HOME/.musica/musicaplayer_android.py"

if [ ! -f "$SCRIPT" ]; then
    echo "❌ Musica Player が見つかりません。再インストールしてください。"
    exit 1
fi

# 既に起動中なら警告
if pgrep -f "musicaplayer_android" > /dev/null 2>&1; then
    echo "⚠  Musica Player はすでに起動しています"
    echo "   ブラウザで http://localhost:8080 を開いてください"
    exit 0
fi

echo ""
echo "🎵 Musica Player を起動しています..."
echo "   ブラウザで以下のURLを開いてください："
echo ""
echo "   → http://localhost:8080"
echo ""
echo "   終了するには Ctrl+C を押してください"
echo ""

python "$SCRIPT"
LAUNCHEOF

chmod +x "$LAUNCHER"
ok "起動コマンド「musica」を作成しました"

# ── Termux:Widget 用ショートカット（あれば） ──
WIDGET_DIR="$HOME/.shortcuts"
if [ -d "$WIDGET_DIR" ] || command -v termux-widget &>/dev/null; then
    mkdir -p "$WIDGET_DIR"
    cat > "$WIDGET_DIR/Musica Player" << 'WIDGETEOF'
#!/data/data/com.termux/files/usr/bin/bash
musica
WIDGETEOF
    chmod +x "$WIDGET_DIR/Musica Player"
    ok "Termux:Widget ショートカットを作成しました"
fi

# ── 自動起動設定（オプション） ──
BOOT_DIR="$HOME/.termux/boot"
if [ -d "$BOOT_DIR" ] || command -v termux-boot &>/dev/null 2>&1; then
    mkdir -p "$BOOT_DIR"
    cat > "$BOOT_DIR/musica-autostart.sh" << 'BOOTEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Android起動時にMusicaPlayerを自動起動（Termux:Boot が必要）
sleep 10
musica &
BOOTEOF
    chmod +x "$BOOT_DIR/musica-autostart.sh"
    info "Termux:Boot が入っていれば Android起動時に自動起動します"
fi

# ── インストール完了 ──
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD}  🎉 インストール完了！${RESET}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo "  【使い方】"
echo ""
echo -e "  1. 音楽ファイルを ${CYAN}/sdcard/Music/${RESET} に入れる"
echo ""
echo -e "  2. Termux で ${BOLD}musica${RESET} と入力して Enter"
echo ""
echo -e "  3. ブラウザで ${CYAN}http://localhost:8080${RESET} を開く"
echo ""
echo "  【ヒント】"
echo "  ・同じWifiの他の端末からも操作できます"
echo "  ・ホーム画面に Termux:Widget を置くとワンタップ起動できます"
echo ""
echo "  楽しい音楽ライフを！🎵"
echo ""

# 今すぐ起動するか確認
read -p "今すぐ Musica Player を起動しますか？ (y/n): " -n 1 LAUNCH
echo ""
if [[ "$LAUNCH" =~ ^[Yy]$ ]]; then
    musica
fi
