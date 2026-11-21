#!/usr/bin/env bash
# Capturas do cenário com propósito (21/11/2026): as mesmas cenas dos 3 atos para cada combinação de opções.
# Uso: bash tools/capture_cenario.sh <pasta> "<opções extras, ex.: --cenario=1 --arvores=2>" [nomes-das-cenas]
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
DIR="$1"; EXTRA="$2"; ONLY="$3"
cd "$(dirname "$0")/.."
OUT="docs/cenario_proposito/$DIR"; mkdir -p "$OUT"
SCREENS=(
"ato1_estrada|10|--autoplay=heuristic --phase=6 --seed=7 --skip=250 --speed=1"
"ato1_perto|10|--autoplay=heuristic --phase=6 --seed=11 --skip=300 --speed=1 --camzoom=-14"
"ato2|8|--autoplay=heuristic --phase=6 --seed=7 --skip=act --speed=1"
"ato3|8|--autoplay=heuristic --phase=6 --seed=7 --skip=act1 --speed=1"
)
for s in "${SCREENS[@]}"; do
  IFS='|' read -r name t args <<<"$s"
  if [ -n "$ONLY" ] && ! grep -qw "$name" <<<"$ONLY"; then continue; fi
  tmp="$(mktemp -d)"
  until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
  timeout 200 "$GODOT" --position -6000,0 --path . -- $args $EXTRA --shots=$t --quit=$((t+1)) --out="$tmp/" >"$tmp/out.txt" 2>"$tmp/err.txt"
  rmdir /c/Users/gabri/Desktop/.godot_capture.lock
  f=$(ls "$tmp"/shot_*.png 2>/dev/null | head -1)
  if [ -n "$f" ]; then mv "$f" "$OUT/$name.png"; echo "ok $DIR $name"; else echo "FALHOU $name"; tail -3 "$tmp/err.txt"; fi
  grep -i "SCRIPT ERROR\|Parse Error" "$tmp/err.txt" | sort | uniq -c | head -5
  grep "^cenario:" "$tmp/out.txt"
  rm -rf "$tmp"
done
