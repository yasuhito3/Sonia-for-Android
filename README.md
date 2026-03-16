# 🎵 Musica Player for Android (Termux版)

Android の Termux 上で動作する、ブラウザ経由のモバイル音楽プレイヤーです。  
ffmpeg → mpv パイプによる EQ 処理と、YouTube / SoundCloud のストリーム再生に対応しています。

---

## 主な機能

- `/sdcard/Music` 内の音楽ファイル再生（FLAC / WAV / MP3 / M4A / OGG ほか）
- ffmpeg → mpv パイプによる EQ・ゲイン処理（ミドルウェアなし）
- 10バンド EQ プリセット（クラシック・ジャズ・耳鳴り軽減など）
- 低音・高音スライダー（±12dB）
- ゲインプリセット管理
- **YouTube / SoundCloud ストリーム再生**（yt-dlp 経由・EQ 全適用）
- **ストリームプレイリスト**（＋ボタンで複数曲を選んで連続再生）
- インターネットラジオ再生（Classic FM・Jazz24 など10局）
- ジャケット画像表示（埋め込み・フォルダ内画像・YouTube サムネイル）
- スマホ最適化 Web ブラウザ UI
- 同一 Wi-Fi 内の別端末からもアクセス可能

---

## セットアップ

### 必要パッケージ

```bash
pkg update && pkg upgrade
pkg install python ffmpeg mpv yt-dlp
pip install mutagen
```

### ストレージアクセス権の付与（初回のみ）

```bash
termux-setup-storage
```

### 起動

```bash
python musicaplayer_android.py
```

ブラウザで `http://localhost:8080` を開いてください。  
同じ Wi-Fi 内の別端末からは `http://<TermuxのIP>:8080` でアクセスできます。

---

## 画面構成（タブ）

| タブ | 内容 |
|------|------|
| **NOW** | 再生中の曲情報・コントロール・EQ・ゲイン調整 |
| **MUSIC** | ローカル音楽ライブラリ（リスト表示 / ジャケット表示） |
| **RADIO** | インターネットラジオ局一覧 |
| **STREAM** | YouTube / SoundCloud 検索・ストリーム再生・プレイリスト |
| **SET** | プリセット管理・フォルダ設定・接続情報 |

---

## STREAMタブの使い方

1. `▶ YouTube` または `☁ SoundCloud` を選択
2. 曲名・アーティスト名を入力して「検索」
3. 曲をタップ → 即再生（EQ・ゲイン設定がそのまま適用）
4. **＋ボタン** をタップ → プレイリストに追加（✓ に変わる）
5. 複数曲を追加すると画面下部に「プレイリスト N曲 ▶ 再生」バーが表示
6. バーをタップするとリスト展開（個別削除・全クリア可能）
7. **▶ 再生** で1曲目から順番に連続再生

> **注意**: 再生ボタン押下後、音が出るまで数秒かかります（yt-dlp のURL解決時間）。

---

## 再生エンジン

```
ffmpeg（EQ/ゲイン処理）→ mpv（音声出力）
```

ストリーム再生時も同じパイプラインを通るため、EQ・ゲイン・低音高音スライダーがすべて有効です。

---

## 対応フォーマット

`.wav` `.flac` `.wma` `.aiff` `.aif` `.mp3` `.m4a` `.aac` `.ogg` `.opus`

---

## Xubuntu24版との違い

| 項目 | Android版 | Xubuntu24版 |
|------|-----------|-------------|
| 音声出力 | mpv（自動 BT/有線切替） | aplay / ALSA |
| UI | モバイル Web ブラウザ | curses TUI |
| ジャケット | ブラウザ内表示 | feh |
| 音声認識 | 非対応（将来予定） | vosk |

Xubuntu24版へのステップアップで、さらに高音質・多機能になります。  
→ https://sites.google.com/view/aimusicplayer-sonia/

---

## ライセンス

個人・非商用利用自由。再配布・改変の際はクレジット表記を推奨します。
