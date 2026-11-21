#!/usr/bin/env bash
# Fotografa as 7 versões da rodada "miniaturas pintadas" (tools/art/board_g.gd) em 1920x1080.
# Uso: bash tools/art/capture_g.sh <pasta> [versões]   (padrão: V1 V2 V3 V4 V5 V6 V7)
# V1 controle (cor por vértice + guache do shader) · V2 dabs · V3 aguado · V4 pincel seco · V5 cor chapada + contorno
# V6 gorducha + dabs · V7 facetada + dabs
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; shift
cd "$(dirname "$0")/../.."
mkdir -p "$OUT"
declare -A SET=([V1]="n vc" [V2]="n dabs" [V3]="n wash" [V4]="n dry" [V5]="n flat" [V6]="c dabs" [V7]="f dabs")
V=("$@"); [ ${#V[@]} -eq 0 ] && V=(V1 V2 V3 V4 V5 V6 V7)
for v in "${V[@]}"; do
  read -r g t <<<"${SET[$v]}"
  tmp="$OUT/_tmp_$v/"; rm -rf "$tmp"; mkdir -p "$tmp"
  timeout 120 "$GODOT" --position -6000,0 --path . -s res://tools/art/capture_big.gd -- --scene=res://tools/art/board_g.tscn --geom=$g --tex=$t --shots=jogo,perto,detalhe,herois,cenario --out="$tmp" >/dev/null 2>"$tmp/err.txt"
  for f in "$tmp"/board_*.png; do [ -f "$f" ] && mv "$f" "$OUT/${v}_$(basename "$f" | sed 's/board_//')"; done
  rm -rf "$tmp"
done
ls "$OUT"
