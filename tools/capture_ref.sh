#!/usr/bin/env bash
# Capturas de referência do visual padrão (24/11/2026): as mesmas cenas antes e depois de uma mudança, para comparar.
# Uso: bash tools/capture_ref.sh <pasta-de-saida>   (ex.: capturas/ref_antes). Janela fora da tela, sem mover o mouse.
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="${1:-capturas/ref}"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
SCREENS=(
"1_estrada|10|--autoplay=heuristic --phase=1 --seed=7 --skip=420 --speed=1"
"2_disputa|14|--start=plague --seed=7 --firstparty=guardiao.cleriga.mago.assassino --offerat=3 --offer=contest:tavern"
"3_outro_ato|8|--autoplay=heuristic --phase=1 --seed=7 --skip=act --speed=1"
"4_arena|14|--autoplay=heuristic --phase=1 --seed=7 --skip=arena --speed=1"
)
for s in "${SCREENS[@]}"; do
  IFS='|' read -r name t args <<<"$s"
  tmp="$OUT/_tmp_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
  timeout 240 "$GODOT" --position -6000,0 --path . -- $args --shots=$t --quit=$((t+1)) --out="$tmp" >"$tmp/out.txt" 2>"$tmp/err.txt"
  f=$(ls "$tmp"/shot_*.png 2>/dev/null | head -1)
  if [ -n "$f" ]; then mv "$f" "$OUT/$name.png"; echo "ok $name"; else echo "FALHOU $name"; fi
  grep -iE "SCRIPT ERROR|Parse Error|Failed to load|Cannot open|not found" "$tmp/err.txt" | sort -u | head -5
  cp "$tmp/err.txt" "$OUT/$name.err.txt"; rm -rf "$tmp"
done
mkdir -p "$OUT/menus"
timeout 240 "$GODOT" --position -6000,0 --path . -- --gshots=1 --out="$OUT/menus/" >"$OUT/menus.out.txt" 2>"$OUT/menus.err.txt"
ls "$OUT/menus" | head -20
grep -iE "SCRIPT ERROR|Parse Error|Failed to load" "$OUT/menus.err.txt" | sort -u | head -5
