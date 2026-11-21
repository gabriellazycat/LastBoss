#!/usr/bin/env bash
# Giro/clipe/prancha das estruturas novas na Godot, fora da tela (tools/art/blender_m2/giro_m2.gd).
# Uso: bash tools/art/blender_m2/giro_m2.sh <pasta>/ <ids> <giro|clip|board> [m2=1] [n=12] [w] [h]
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; IDS="$2"; MODE="$3"; M2="${4:-1}"; N="${5:-12}"; W="${6:-960}"; H="${7:-960}"
cd "$(dirname "$0")/../../.."
mkdir -p "$OUT"
until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
timeout 900 "$GODOT" --position -6000,0 --path . res://tools/art/blender_m2/giro_m2.tscn -- --ids=$IDS --out="$OUT" --mode=$MODE --m2=$M2 --n=$N --w=$W --h=$H >"$OUT/_log.txt" 2>"$OUT/_err.txt"
rmdir /c/Users/gabri/Desktop/.godot_capture.lock
grep -i "SCRIPT ERROR\|Parse Error\|ERROR" "$OUT/_err.txt" | sort | uniq -c | head -5
