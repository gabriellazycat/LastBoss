#!/usr/bin/env bash
# Capturas da rodada visual (20/11/2026): cada variação de --mundo / --luz nas mesmas cenas, 1920x1080.
# Uso: bash tools/capture_visual.sh <mundo|luz> <pasta-da-variacao> <valor> [nomes-das-cenas]
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
FRENTE="$1"; DIR="$2"; VAL="$3"; ONLY="$4"
cd "$(dirname "$0")/.."
OUT="docs/rodada_visual/$FRENTE/$DIR"; mkdir -p "$OUT"
SCREENS=(
"1_estrada|10|--autoplay=heuristic --phase=6 --seed=7 --skip=420 --speed=1"
"2_disputa|14|--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --offerat=3 --offer=contest:tavern"
"3_outro_ato|8|--autoplay=heuristic --phase=6 --seed=7 --skip=act --speed=1"
"4_arena|14|--autoplay=heuristic --phase=6 --seed=7 --skip=arena --speed=1"
)
for s in "${SCREENS[@]}"; do
  IFS='|' read -r name t args <<<"$s"
  if [ -n "$ONLY" ] && ! grep -qw "$name" <<<"$ONLY"; then continue; fi
  tmp="$OUT/_tmp_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
  until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
  timeout 200 "$GODOT" --position -6000,0 --path . -- $args --$FRENTE=$VAL --set="fullscreen:true" --shots=$t --quit=$((t+1)) --out="$tmp" >"$tmp/out.txt" 2>"$tmp/err.txt"
  rmdir /c/Users/gabri/Desktop/.godot_capture.lock
  f=$(ls "$tmp"/shot_*.png 2>/dev/null | head -1)
  if [ -n "$f" ]; then mv "$f" "$OUT/$name.png"; echo "ok $FRENTE $DIR $name"; else echo "FALHOU $name"; fi
  grep -i "SCRIPT ERROR\|Parse Error" "$tmp/err.txt" | head -3
  rm -rf "$tmp"
done
