#!/usr/bin/env bash
# Capturas da Biblioteca (frente F, 21/11/2026) em segundo plano: capturas/biblioteca/biblioteca_*.png (1920x1080).
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="${1:-capturas/biblioteca}"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
for v in "album:album" "comuns:common" "bloqueada:locked" "zoom_atual_proximo:zoom" "zoom_v:zoomvi" "filtro_custo:filter"; do
  name="${v%%:*}"; view="${v##*:}"
  timeout 90 "$GODOT" --position -6000,0 --path . res://game/library_demo.tscn -- --shot="$OUT/biblioteca_$name.png" --view=$view 2>&1 | grep -i "captura\|error" | head -3
done
