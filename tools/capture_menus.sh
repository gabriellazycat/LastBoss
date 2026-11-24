#!/usr/bin/env bash
# Capturas da frente G (menus, escolher vilão, pausa com poderes, fim da run) em segundo plano (21/11/2026):
# capturas/menus/menu_*.png. Janela fora da tela, sem mover o mouse; usa o meta de teste (user://test_meta.save).
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="${1:-capturas/menus}"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
timeout 240 "$GODOT" --position -6000,0 --path . -- --gshots=1 --out="$OUT/" 2>&1 | grep -i "gshots\|error" | head -10
