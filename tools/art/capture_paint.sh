#!/usr/bin/env bash
# Fotografa as variações do mundo pintado (Settings "paint_look", docs/MUNDO_PINTADO.md) nas mesmas 3 cenas.
# Uso: bash tools/art/capture_paint.sh <pasta> <variações...>   ex.: bash tools/art/capture_paint.sh docs/mundo_pintado/fotos 0 1 2 3
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; shift
cd "$(dirname "$0")/../.."
mkdir -p "$OUT"
SCENES=(
"run|7|--start=horde --seed=7"
"arena|9|--autoplay=heuristic --seed=7 --skip=arena --speed=1"
"mesa|5|--menu=title"
)
for v in "$@"; do
  for s in "${SCENES[@]}"; do
    IFS='|' read -r name t args <<<"$s"
    tmp="$OUT/_tmp_${v}_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
    timeout 120 "$GODOT" --position -6000,0 --path . -s res://tools/art/capture_big.gd -- $args --set=paint_look:$v --shots=$t --quit=$((t+1)) --out="$tmp" >/dev/null 2>"$tmp/err.txt"
    f=$(ls "$tmp"/shot_*.png 2>/dev/null | head -1)
    if [ -n "$f" ]; then mv "$f" "$OUT/v${v}_$name.png"; echo "ok v$v $name"; else echo "FALHOU v$v $name"; fi
    grep -iE "SHADER ERROR|SCRIPT ERROR|Parse Error" -A3 "$tmp/err.txt" | head -6
    rm -rf "$tmp"
  done
done
