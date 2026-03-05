#!/data/data/com.termux/files/usr/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}OK  $1${RESET}"; }
info() { echo -e "${CYAN}... $1${RESET}"; }
warn() { echo -e "${YELLOW}!   $1${RESET}"; }
err()  { echo -e "${RED}ERR $1${RESET}"; exit 1; }
step() { echo -e "\n${BOLD}=== $1 ===${RESET}"; }

echo ""
echo "=================================================="
echo "  Musica Player  Android版  自動インストーラー"
echo "=================================================="
echo ""
sleep 1

step "環境チェック"
if [ ! -d "/data/data/com.termux" ]; then
    err "Termux環境が見つかりません"
fi
ok "Termux環境を確認しました"
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "不明")
info "Android バージョン: ${ANDROID_VER}"

step "パッケージリストを更新"
info "時間がかかる場合があります..."
yes | pkg update -y 2>/dev/null || true
ok "パッケージリストを更新しました"

step "必要なプログラムをインストール"
for pkg in python ffmpeg mpv; do
    if command -v $pkg >/dev/null 2>&1; then
        ok "$pkg は既にインストール済み"
    else
        info "$pkg をインストール中..."
        pkg install -y $pkg
        ok "$pkg インストール完了"
    fi
done

info "Python ライブラリ (mutagen) をインストール中..."
pip install --quiet mutagen 2>/dev/null || pip install mutagen
ok "mutagen インストール完了"

step "ストレージアクセス権限の設定"
if [ -d "$HOME/storage/music" ]; then
    ok "ストレージアクセス権限は既に設定済みです"
else
    info "ストレージ権限を設定します（Androidの許可ダイアログが出たら許可してください）"
    termux-setup-storage
    sleep 3
    if [ -d "$HOME/storage/music" ]; then
        ok "ストレージアクセス権限を設定しました"
    else
        warn "後で手動実行してください: termux-setup-storage"
    fi
fi

step "Musica Player 本体をインストール"
INSTALL_DIR="$HOME/.musica"
mkdir -p "$INSTALL_DIR"
SCRIPT_DST="$INSTALL_DIR/musicaplayer_android.py"

info "スクリプト本体をダウンロード中..."
curl -sL "https://raw.githubusercontent.com/yasuhito3/Sonia-for-Android/main/musicaplayer_android.py" \
    | sed 's/\r//' > "$SCRIPT_DST"
if [ -s "$SCRIPT_DST" ]; then
    ok "Musica Player 本体をダウンロードしました"
else
    err "ダウンロードに失敗しました。ネットワークを確認してください。"
fi

step "起動コマンド「musica」を作成"
LAUNCHER="$PREFIX/bin/musica"
printf '#!/data/data/com.termux/files/usr/bin/bash\n' > "$LAUNCHER"
printf 'SCRIPT="$HOME/.musica/musicaplayer_android.py"\n' >> "$LAUNCHER"
printf 'if [ ! -f "$SCRIPT" ]; then\n' >> "$LAUNCHER"
printf '    echo "Musica Player が見つかりません。再インストールしてください。"\n' >> "$LAUNCHER"
printf '    exit 1\n' >> "$LAUNCHER"
printf 'fi\n' >> "$LAUNCHER"
printf 'if pgrep -f "musicaplayer_android" > /dev/null 2>&1; then\n' >> "$LAUNCHER"
printf '    echo "Musica Player はすでに起動しています"\n' >> "$LAUNCHER"
printf '    echo "ブラウザで http://localhost:8080 を開いてください"\n' >> "$LAUNCHER"
printf '    exit 0\n' >> "$LAUNCHER"
printf 'fi\n' >> "$LAUNCHER"
printf 'echo ""\n' >> "$LAUNCHER"
printf 'echo "Musica Player を起動しています..."\n' >> "$LAUNCHER"
printf 'echo "ブラウザで http://localhost:8080 を開いてください"\n' >> "$LAUNCHER"
printf 'echo "終了するには Ctrl+C を押してください"\n' >> "$LAUNCHER"
printf 'echo ""\n' >> "$LAUNCHER"
printf 'python "$SCRIPT"\n' >> "$LAUNCHER"
chmod +x "$LAUNCHER"
ok "起動コマンド「musica」を作成しました"

WIDGET_DIR="$HOME/.shortcuts"
if [ -d "$WIDGET_DIR" ] || command -v termux-widget >/dev/null 2>&1; then
    mkdir -p "$WIDGET_DIR"
    printf '#!/data/data/com.termux/files/usr/bin/bash\nmusica\n' > "$WIDGET_DIR/Musica Player"
    chmod +x "$WIDGET_DIR/Musica Player"
    ok "Termux:Widget ショートカットを作成しました"
fi

BOOT_DIR="$HOME/.termux/boot"
if [ -d "$BOOT_DIR" ] || command -v termux-boot >/dev/null 2>&1; then
    mkdir -p "$BOOT_DIR"
    printf '#!/data/data/com.termux/files/usr/bin/bash\nsleep 10\nmusica &\n' > "$BOOT_DIR/musica-autostart.sh"
    chmod +x "$BOOT_DIR/musica-autostart.sh"
    info "Termux:Boot があれば起動時に自動起動します"
fi

echo ""
echo "=================================================="
echo "  インストール完了！"
echo "=================================================="
echo ""
echo "  使い方:"
echo "  1. 音楽ファイルを /sdcard/Music/ に入れる"
echo "  2. Termux で  musica  と入力して Enter"
echo "  3. ブラウザで http://localhost:8080 を開く"
echo ""
echo "  楽しい音楽ライフを！"
echo ""
info "Musica Player を起動します..."
sleep 2
musica
