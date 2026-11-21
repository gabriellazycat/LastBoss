#!/usr/bin/env bash
# Capturas da consolidação (16/11/2026): todas as telas com as configurações padrão, numa semente só.
# Uso: bash tools/capture_consolidacao.sh <pasta de saída>   (ex.: docs/consolidacao/antes)
# CAPTURE_ONLY="title arena_dragon" limita as telas.
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
# nome | tempo da foto | argumentos
SCREENS=(
"01_menu|5|--menu=title"
"02_vilao|5|--menu=decks"
"03_colecao|5|--menu=collection"
"04_config|5|--tab=video"
"05_estrada_inicio|6|--start=horde --seed=7"
"06_estrada_meio|7|--autoplay=heuristic --seed=7 --skip=560 --speed=1"
"07_disputa_taverna|8|--start=horde --seed=7 --offerat=3 --offer=contest:tavern"
"08_disputa_ritual|8|--start=horde --seed=7 --offerat=3 --offer=contest:ritual"
"09_oferta_queda|6|--start=horde --seed=7 --offerat=3"
"10_oferta_nivel|6|--start=horde --seed=7 --offerat=3 --offer=ritual"
"11_loja|6|--start=horde --seed=7 --offerat=3 --offer=shop"
"12_evento|6|--start=horde --seed=7 --offerat=3 --offer=event"
"13_reliquia|6|--start=horde --seed=7 --offerat=3 --offer=relic"
"14_dica|6|--start=horde --seed=7 --hint=start"
"15_party4|7|--autoplay=heuristic --phase=6 --seed=7 --skip=420 --speed=1"
"16_arena_praga|9|--autoplay=idle --deck=plague --seed=7 --skip=arena --speed=1"
"17_arena_dragao|9|--autoplay=idle --deck=dragon --seed=7 --skip=arena --speed=1"
"18_arena_lich|9|--autoplay=idle --deck=lich --seed=7 --skip=arena --speed=1"
"19_resultado|7|--autoplay=heuristic --seed=7 --skip=99999 --speed=1"
"20_resultado_lich|7|--autoplay=random --deck=lich --phase=3 --seed=7 --skip=99999 --speed=1"
)
for s in "${SCREENS[@]}"; do
  IFS='|' read -r name t args <<<"$s"
  if [ -n "$CAPTURE_ONLY" ] && ! grep -qw "$name" <<<"$CAPTURE_ONLY"; then continue; fi
  tmp="$OUT/_tmp_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
  timeout 150 "$GODOT" --position -6000,0 --path . -- $args --set="fullscreen:true" --shots=$t --quit=$((t+1)) --out="$tmp" >/dev/null 2>"$tmp/err.txt"
  f=$(ls "$tmp"/shot_*.png 2>/dev/null | head -1)
  if [ -n "$f" ]; then mv "$f" "$OUT/${name}.png"; echo "ok $name"; else echo "FALHOU $name: $(grep -m3 -i error "$tmp/err.txt")"; fi
  rm -rf "$tmp"
done
# Mapa da campanha (4 capturas) e a mão/mapa grande pelo teste de entrada real.
if [ -z "$CAPTURE_ONLY" ] || grep -qw campanha <<<"$CAPTURE_ONLY"; then
  tmp="$OUT/_tmp_camp/"; rm -rf "$tmp"; mkdir -p "$tmp"
  timeout 90 "$GODOT" --position -6000,0 --path . -- --campaignshot=1 --set="fullscreen:true" --out="$tmp" > "$tmp/log.txt" 2>&1
  for f in "$tmp"/*.png; do [ -f "$f" ] && mv "$f" "$OUT/00_$(basename "$f")"; done
  echo "campanha: $(grep -m1 'campaignshot' "$tmp/log.txt")"; rm -rf "$tmp"
fi
if [ -z "$CAPTURE_ONLY" ] || grep -qw uitest <<<"$CAPTURE_ONLY"; then
  tmp="$OUT/_tmp_uitest/"; rm -rf "$tmp"; mkdir -p "$tmp"
  timeout 150 "$GODOT" --position -6000,0 --path . -- --uitest=1 --set="fullscreen:true" --out="$tmp" > "$tmp/log.txt" 2>&1
  for k in hover map selected; do [ -f "$tmp/uitest_$k.png" ] && mv "$tmp/uitest_$k.png" "$OUT/21_mao_${k}.png"; done
  echo "uitest: $(grep -m1 'uitest resultado' "$tmp/log.txt")"; rm -rf "$tmp"
fi
