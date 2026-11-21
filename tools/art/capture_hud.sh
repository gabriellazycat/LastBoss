#!/usr/bin/env bash
# Fotografa o JOGO de verdade (com HUD) em cada versão das miniaturas pintadas (Settings model_g 0..7).
# ONLY=<cena> refaz só essa cena. Uso: bash tools/art/capture_hud.sh <pasta> [versões 0..7]   (0 = o jogo de antes)
# Fotos: <pasta>/V<n>_<cena>.png (V0 = antes).
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; shift
cd "$(dirname "$0")/../.."
mkdir -p "$OUT"
V=("$@"); [ ${#V[@]} -eq 0 ] && V=(0 1 2 3 4 5 6 7)
SCENES=(
"estrada|7|--autoplay=heuristic --seed=7 --skip=300 --speed=1"
"horda|10|--autoplay=random --seed=3 --stress=70"
"encontro|4|--start=horde --seed=7 --spawn=rat_king,goblin_dynamiter,slime,raised_servant,ogre,werewolf,bat_cloud,ghost,mimic,rat_brute --speed=1"
"oferta|6|--start=horde --seed=7 --offerat=3"
)
for v in "${V[@]}"; do
  for s in "${SCENES[@]}"; do
    IFS='|' read -r name t args <<<"$s"
    [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
    tmp="$OUT/_tmp_${v}_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
    timeout 150 "$GODOT" --position -6000,0 --path . -s res://tools/art/capture_big.gd -- $args --set=model_g:$v --shots=$t --quit=$((t+1)) --out="$tmp" >/dev/null 2>"$tmp/err.txt"
    f=$(ls "$tmp"/*.png 2>/dev/null | head -1)
    [ -n "$f" ] && cp "$f" "$OUT/V${v}_$name.png"
    rm -rf "$tmp"
  done
done
