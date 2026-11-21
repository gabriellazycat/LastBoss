#!/usr/bin/env bash
# Capturas dos efeitos (rodada visual 20/11/2026), uma foto por chamada, tirada pelo próprio jogo (--fxshot, tempo
# de run): bash tools/capture_fx.sh <pasta> <fx> <espera-s> <nome> "<args>"  -> docs/rodada_visual/fx/<pasta>/<nome>.png
# Grava também <nome>.pos (posição do herói na tela, 0..1) para recortar o detalhe.
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
DIR="$1"; VAL="$2"; T="${3:-1.0}"; NAME="$4"; EXTRA="$5"; shift 5; MORE="$*"
cd "$(dirname "$0")/.."
OUT="docs/rodada_visual/fx/$DIR"; mkdir -p "$OUT"
tmp="$OUT/_tmp_$NAME/"; rm -rf "$tmp"; mkdir -p "$tmp"
until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
timeout 200 "$GODOT" --position -6000,0 --path . -- $EXTRA --fx=$VAL $MORE --set="fullscreen:true" --fxshot=$T --quit=90 --out="$tmp" >"$tmp/out.txt" 2>"$tmp/err.txt"
rmdir /c/Users/gabri/Desktop/.godot_capture.lock
if [ -f "$tmp/fx.png" ]; then mv "$tmp/fx.png" "$OUT/$NAME.png"; echo "ok fx $DIR $NAME"; else echo "FALHOU $DIR $NAME"; fi
grep "fxdemo_screen" "$tmp/out.txt" | tail -1 | awk '{print $2, $3}' > "$OUT/$NAME.pos"
grep -i "SCRIPT ERROR\|Parse Error" "$tmp/err.txt" | sort | uniq -c | head -5
rm -rf "$tmp"
