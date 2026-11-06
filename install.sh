#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════
#  Sonia for Android — 自動インストーラー
#  curl -sL https://raw.githubusercontent.com/yasuhito3/Sonia-for-Android/main/install.sh | bash
# ═══════════════════════════════════════════════════════════
set -e

REPO_RAW="https://raw.githubusercontent.com/yasuhito3/Sonia-for-Android/main"
INSTALL_DIR="$HOME/.musica"
SCRIPT_DST="$INSTALL_DIR/musicaplayer_android.py"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${RESET}"; }
info() { echo -e "${CYAN}…  $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠  $1${RESET}"; }
err()  { echo -e "${RED}❌ $1${RESET}"; exit 1; }
step() { echo -e "\n${BOLD}━━ $1 ━━${RESET}"; }

echo ""
echo "══════════════════════════════════════════════════"
echo "  🎵  Sonia for Android  インストーラー"
echo "══════════════════════════════════════════════════"
sleep 1

# ── 1. 環境チェック ───────────────────────────────────────
step "1/5  環境チェック"
if [ ! -d "/data/data/com.termux" ] && [ -z "$SONIA_TEST" ]; then
    err "Termux が見つかりません。F-Droid 版の Termux で実行してください。"
fi
ok "Termux を確認しました (Android $(getprop ro.build.version.release 2>/dev/null || echo '?'))"

# ── 2. 必要なアプリ ───────────────────────────────────────
step "2/5  必要なプログラムを準備"
info "パッケージ一覧を更新中…（少し時間がかかります）"
yes | pkg update -y >/dev/null 2>&1 || true
for p in python ffmpeg mpv; do
    if command -v "$p" >/dev/null 2>&1; then
        ok "$p は準備済み"
    else
        info "$p をインストール中…"
        pkg install -y "$p" >/dev/null 2>&1 || err "$p のインストールに失敗しました（ネットワークを確認してください）"
        ok "$p をインストールしました"
    fi
done
info "yt-dlp（YouTube/SoundCloud）と mutagen（曲情報）を最新版で準備中…"
pip install -U --quiet yt-dlp mutagen 2>/dev/null || pip install -U yt-dlp mutagen \
    || err "yt-dlp / mutagen のインストールに失敗しました（ネットワークを確認してください）"
ok "yt-dlp と mutagen を準備しました"

# ── 3. 音楽フォルダへのアクセス ───────────────────────────
step "3/5  音楽フォルダへのアクセス許可"
if [ -d "$HOME/storage/music" ]; then
    ok "許可済みです"
else
    info "Android の許可ダイアログが出たら「許可」を押してください"
    termux-setup-storage || true
    sleep 4
    if [ -d "$HOME/storage/music" ]; then
        ok "許可されました"
    else
        warn "あとで Termux に  termux-setup-storage  と入力して許可してください"
    fi
fi

# ── 4. Sonia 本体 ─────────────────────────────────────────
step "4/5  Sonia 本体を配置"
mkdir -p "$INSTALL_DIR"
SELF="${BASH_SOURCE[0]:-}"
SELF_DIR=""
[ -n "$SELF" ] && SELF_DIR="$(cd "$(dirname "$SELF")" 2>/dev/null && pwd)" || true
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/musicaplayer_android.py" ]; then
    info "このフォルダの本体を使います"
    sed 's/\r//' "$SELF_DIR/musicaplayer_android.py" > "$SCRIPT_DST"
else
    info "GitHub から最新版をダウンロード中…"
    curl -fsSL "$REPO_RAW/musicaplayer_android.py" | sed 's/\r//' > "$SCRIPT_DST" \
        || err "ダウンロードに失敗しました。ネットワークを確認してください。"
fi
python -m py_compile "$SCRIPT_DST" 2>/dev/null || err "本体ファイルが壊れています。もう一度実行してください。"
ok "Sonia 本体を配置しました"

# ── 5. 起動コマンドとアイコン ─────────────────────────────
step "5/5  アイコンと起動コマンドを作成"
LAUNCHER="$PREFIX/bin/musica"
cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Sonia ランチャー
#   musica            起動して、ブラウザで開く（ふだんはこれ）
#   musica stop       終了する（別の画面から）
#   musica status     動いているか確認
#   musica update     Sonia と yt-dlp を最新版に更新
#   musica autostart on|off   スマホ起動時に自動で立ち上げる（Termux:Boot が必要）
#   musica log        ログを見る
#   musica start      裏で起動（実験的：機種によってはAndroidに止められます）

DIR="$HOME/.musica"
APP="$DIR/musicaplayer_android.py"
PIDF="$DIR/sonia.pid"
LOG="$DIR/sonia.log"
PORT=8080
URL="http://localhost:$PORT"
REPO_RAW="https://raw.githubusercontent.com/yasuhito3/Sonia-for-Android/main"

is_running() { [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; }
is_up()      { curl -s -o /dev/null --max-time 2 "$URL/api/status"; }

start_server() {
    if is_running; then return 0; fi
    [ -f "$APP" ] || { echo "❌ Sonia が見つかりません。インストーラーをもう一度実行してください。"; return 1; }
    nohup python "$APP" > "$LOG" 2>&1 &
    CHILD=$!
    echo "$CHILD" > "$PIDF"
    disown "$CHILD" 2>/dev/null || true
    printf "🎵 Sonia を起こしています"
    for _ in $(seq 1 60); do
        if is_up; then echo " ✅"; return 0; fi
        if ! kill -0 "$CHILD" 2>/dev/null; then
            echo " ❌"; echo "起動に失敗しました。ログ:"; tail -n 15 "$LOG"; rm -f "$PIDF"; return 1
        fi
        printf "."; sleep 0.5
    done
    echo " （読み込みに時間がかかっています）"
}

open_ui() {
    if command -v termux-open-url >/dev/null 2>&1; then
        termux-open-url "$URL"
    else
        am start -a android.intent.action.VIEW -d "$URL" >/dev/null 2>&1 \
            || echo "ブラウザで $URL を開いてください"
    fi
}

stop_server() {
    if is_running; then
        curl -s -o /dev/null --max-time 3 -X POST -H 'X-Sonia: 1' "$URL/api/shutdown" || true
        for _ in 1 2 3 4 5 6; do is_running || break; sleep 1; done
        is_running && kill -9 "$(cat "$PIDF")" 2>/dev/null
        echo "👋 Sonia を終了しました"
    else
        echo "Sonia は動いていません"
    fi
    rm -f "$PIDF"
    command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock || true
}

case "${1:-open}" in
    open|"")
        if is_running; then
            echo "🎵 Sonia は動いています"
            open_ui
            exit 0
        fi
        [ -f "$APP" ] || { echo "❌ Sonia が見つかりません。インストーラーをもう一度実行してください。"; exit 1; }
        # 起動を待って、ブラウザを自動で開く（Sonia 本体はこの画面の中で動かし続ける）
        ( for _ in $(seq 1 120); do
              if is_up; then open_ui; break; fi
              sleep 0.5
          done ) &
        echo ""
        echo "🎵 Sonia を起動しています。まもなくブラウザが開きます。"
        echo "   ※ この画面は閉じずに、ホームボタンでブラウザへ移ってください。"
        echo "   ※ 終了: Sonia の SET →「⏻ 終了」、またはこの画面で Ctrl+C"
        echo ""
        exec python "$APP" ;;
    start)    start_server ;;
    stop)     stop_server ;;
    restart)  stop_server; start_server ;;
    status)
        if is_running; then
            ip=$(ifconfig 2>/dev/null | grep -Eo 'inet (192|10|172)\.[0-9.]+' | head -n1 | cut -d' ' -f2)
            echo "🎵 Sonia は動いています  → $URL"
            [ -n "$ip" ] && echo "   同じ Wi-Fi の別端末から → http://$ip:$PORT"
        else
            echo "💤 Sonia は止まっています（musica で起動）"
        fi ;;
    log)      tail -n 40 "$LOG" ;;
    fg)       exec python "$APP" ;;
    update)
        echo "⬇  yt-dlp（YouTube対応）を更新しています…"
        if pip install -U --quiet yt-dlp 2>/dev/null; then echo "✅ yt-dlp: $(yt-dlp --version)"; else echo "⚠  yt-dlp の更新に失敗しました"; fi
        echo "⬇  Sonia の最新版を確認しています…"
        TMP="$DIR/new.py"
        if curl -fsSL "$REPO_RAW/musicaplayer_android.py" | sed 's/\r//' > "$TMP" \
           && [ -s "$TMP" ] && python -m py_compile "$TMP" 2>/dev/null; then
            WAS=0; is_running && WAS=1
            [ "$WAS" = 1 ] && stop_server
            mv "$TMP" "$APP"
            echo "✅ 更新しました。起動するには  musica  と入力してください"
        else
            rm -f "$TMP"; echo "❌ 更新に失敗しました（今のバージョンはそのまま使えます）"
        fi ;;
    autostart)
        BOOT="$HOME/.termux/boot/sonia-autostart.sh"
        case "$2" in
            on)  mkdir -p "$HOME/.termux/boot"
                 printf '#!/data/data/com.termux/files/usr/bin/bash\nsleep 15\nmusica start\n' > "$BOOT"
                 chmod +x "$BOOT"
                 echo "✅ 自動起動をオンにしました。"
                 echo "   ※ Termux:Boot アプリ（F-Droid）をインストールして、一度だけ開いてください。" ;;
            off) rm -f "$BOOT"; echo "自動起動をオフにしました" ;;
            *)   [ -f "$BOOT" ] && echo "自動起動: オン" || echo "自動起動: オフ（musica autostart on で有効化）" ;;
        esac ;;
    help|-h|--help)
        sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//' ;;
    *)  echo "使い方: musica [start|stop|status|update|autostart on|off|log|fg|help]" ;;
esac
LAUNCHER_EOF
chmod +x "$LAUNCHER"
ok "起動コマンド「musica」を作成しました"

# ホーム画面ウィジェット用ショートカット（Termux:Widget）
SC="$HOME/.shortcuts"
mkdir -p "$SC/tasks" "$SC/icons"
printf '#!/data/data/com.termux/files/usr/bin/bash\nmusica\n' > "$SC/Sonia"
printf '#!/data/data/com.termux/files/usr/bin/bash\nmusica stop\n' > "$SC/tasks/Sonia-stop"
chmod +x "$SC/Sonia" "$SC/tasks/Sonia-stop"
python "$SCRIPT_DST" --make-icons "$INSTALL_DIR/icons" >/dev/null 2>&1 || true
if [ -f "$INSTALL_DIR/icons/sonia-192.png" ]; then
    cp "$INSTALL_DIR/icons/sonia-192.png" "$SC/icons/Sonia.png"
    cp "$INSTALL_DIR/icons/sonia-192.png" "$SC/icons/Sonia-stop.png"
fi
ok "ホーム画面ショートカット「Sonia」を作成しました"

# 旧バージョンの自動起動設定があれば新方式に置き換え
rm -f "$HOME/.termux/boot/musica-autostart.sh" 2>/dev/null || true

echo ""
echo "══════════════════════════════════════════════════"
echo "  🎉  インストール完了！"
echo "══════════════════════════════════════════════════"
echo ""
echo "  次は、Sonia を起こして、アプリ化します。"
echo "  ※ Sonia は Termux の画面の中で動きます。Termux は閉じないでください。"
echo ""
echo "  1. 音楽ファイルを  /sdcard/Music/  に入れる"
echo "  2. このあと自動で Sonia が開きます"
echo "  3. 画面右上のメニュー（⋮）→「アプリをインストール」"
echo "     （または Sonia の SET タブ →「ホーム画面に追加」）"
echo ""
echo "  これでホーム画面に Sonia アイコンができます 🎵"
echo ""
sleep 3
musica
