#!/usr/bin/env bash
# Capturas da rodada de modelos 3D (20/11/2026): as mesmas cenas com --modelos=0 (antes) e --modelos=1 (peças novas).
# Uso: bash tools/capture_modelos.sh <pasta-de-saida> <valor de --modelos> [nomes-das-cenas]
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; VAL="$2"; ONLY="$3"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
BASE="--fx=3 --herois=1 --mundo=3 --luz=2 --arena=2"
SCREENS=(
"taverna|14|--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --offerat=3 --offer=contest:tavern"
"taverna_perto|14|--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --offerat=3 --offer=contest:tavern --camzoom=-9"
"covil_frente|10|--autoplay=heuristic --phase=6 --seed=7 --skip=arena --speed=1 --camlair=2 --camzoom=14"
"covil_costas|10|--autoplay=heuristic --phase=6 --seed=7 --skip=arena --speed=1 --camlair=1 --camzoom=14"
"arena|14|--autoplay=heuristic --phase=6 --seed=7 --skip=arena --speed=1"
"arena0_perto|14|--autoplay=heuristic --phase=6 --seed=7 --skip=arena --speed=1 --camzoom=-10 --arena=0"
"covil_estrada|20|--autoplay=heuristic --phase=6 --seed=7 --skip=1270 --speed=1"
"arena_perto|14|--autoplay=heuristic --phase=6 --seed=7 --skip=arena --speed=1 --camzoom=-10"
)
for s in "${SCREENS[@]}"; do
  IFS='|' read -r name t args <<<"$s"
  if [ -n "$ONLY" ] && ! grep -qw "$name" <<<"$ONLY"; then continue; fi
  tmp="$OUT/_tmp_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
  until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
  timeout 240 "$GODOT" --position -6000,0 --path . -- $BASE $args --modelos=$VAL --shots=$t --quit=$((t+1)) --out="$tmp" >"$tmp/out.txt" 2>"$tmp/err.txt"
  rmdir /c/Users/gabri/Desktop/.godot_capture.lock
  f=$(ls "$tmp"/shot_*.png 2>/dev/null | head -1)
  if [ -n "$f" ]; then mv "$f" "$OUT/$name.png"; echo "ok $OUT $name"; else echo "FALHOU $name"; fi
  grep -i "SCRIPT ERROR\|SHADER ERROR\|Parse Error" "$tmp/err.txt" | head -3
  rm -rf "$tmp"
done
