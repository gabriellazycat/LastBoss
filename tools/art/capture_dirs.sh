#!/usr/bin/env bash
# Fotografa cada direção de arte (game/art/art_directions.gd) nas mesmas cenas, em 1920x1080, e mede o FPS.
# Uso: bash tools/art/capture_dirs.sh <pasta> [direções: C A B D E F G antiga] [--fps]
# As fotos ficam em <pasta>/<direção>_<cena>.png; o FPS (500 unidades, 25 s, duas rodadas intercaladas) em <pasta>/fps.txt.
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; shift
cd "$(dirname "$0")/../.."
mkdir -p "$OUT"
declare -A SET=(
  [C]="look_ground:2,look_hero:4,look_enemies:3" [A]="look_ground:5,look_hero:4,look_enemies:3"
  [B]="look_ground:6,look_hero:2,look_enemies:2" [D]="look_ground:7,look_hero:5,look_enemies:5"
  [E]="look_ground:8,look_hero:5,look_enemies:5" [F]="look_ground:9,look_hero:6,look_enemies:6"
  [G]="look_ground:10,look_hero:5,look_enemies:7"
  [antiga]="look_ground:0,look_hero:0,look_enemies:0"
)
DIRS=(); FPS=0
for a in "$@"; do if [ "$a" = --fps ]; then FPS=1; else DIRS+=("$a"); fi; done
[ ${#DIRS[@]} -eq 0 ] && DIRS=(C A B D E F)
# nome | tempo | argumentos
SCENES=(
"estrada|7|--autoplay=heuristic --seed=7 --skip=300 --speed=1"
"horda|10|--autoplay=random --seed=3 --stress=160"
"arena|9|--autoplay=heuristic --seed=7 --skip=arena --speed=1"
"oferta|6|--start=horde --seed=7 --offerat=3"
)
for d in "${DIRS[@]}"; do
  for s in "${SCENES[@]}"; do
    IFS='|' read -r name t args <<<"$s"
    tmp="$OUT/_tmp_${d}_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
    timeout 120 "$GODOT" --path . -s res://tools/art/capture_big.gd -- $args --set="${SET[$d]}" --shots=$t --quit=$((t+1)) --out="$tmp" >/dev/null 2>"$tmp/err.txt"
    f=$(ls "$tmp"/shot_*.png 2>/dev/null | head -1)
    if [ -n "$f" ]; then mv "$f" "$OUT/${d}_${name}.png"; echo "ok $d $name"; else echo "FALHOU $d $name: $(grep -m3 -iE 'error' "$tmp/err.txt")"; fi
    rm -rf "$tmp"
  done
done
if [ $FPS = 1 ]; then
  : > "$OUT/fps.txt"
  for round in 1 2; do
    for d in "${DIRS[@]}"; do
      r=$(timeout 90 "$GODOT" --path . -s res://tools/art/capture_big.gd --disable-vsync -- --autoplay=random --stress=500 --quit=25 --set="${SET[$d]}" 2>&1 | grep "stress:" | tail -1)
      echo "$d rodada$round $r" | tee -a "$OUT/fps.txt"
    done
  done
fi
