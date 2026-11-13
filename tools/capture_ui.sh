#!/usr/bin/env bash
# Fotografa as telas da interface para a revisão visual (docs/REVISAO_VISUAL.md).
# Uso: bash tools/capture_ui.sh <pasta de saída> [res1 res2 ...]  (padrão: 1920x1080 1280x720)
# "full" captura em tela cheia (1920x1080 num monitor desse tamanho; a janela de 1080 de altura é cortada pela barra).
# CAPTURE_ONLY="title decks" limita as telas; CAPTURE_SET="look_hud:5" acrescenta configurações a todas.
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; shift
RES=("$@"); [ ${#RES[@]} -eq 0 ] && RES=(full 1280x720)
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
# nome | tempo da foto | argumentos
SCREENS=(
"title|5|--menu=title"
"decks|5|--menu=decks"
"collection|5|--menu=collection"
"settings_audio|5|--tab=audio"
"settings_video|5|--tab=video"
"settings_game|5|--tab=game"
"settings_controls|5|--tab=controls"
"settings_looks|5|--tab=looks"
"run_start|6|--start=horde --seed=7"
"run_mid|7|--autoplay=heuristic --seed=7 --skip=560 --speed=1"
"offer|6|--start=horde --seed=7 --offerat=3"
"pause|6|--start=horde --seed=7 --pauseat=3"
"hint|6|--start=horde --seed=7 --hint=start"
"arena|9|--autoplay=heuristic --seed=7 --skip=arena --speed=1"
"result|7|--autoplay=heuristic --seed=7 --skip=99999 --speed=1"
"group|5|--menu=group"
"offer_upgrade|6|--start=horde --seed=7 --offerat=3 --offer=ritual"
"offer_bridge|6|--start=horde --seed=7 --offerat=3 --offer=bridge"
"shop|6|--start=horde --seed=7 --offerat=3 --offer=shop"
"shop_upgrade|6|--start=horde --seed=7 --offerat=3 --offer=shop:upgrade"
"relic|6|--start=horde --seed=7 --offerat=3 --offer=relic"
"event|6|--start=horde --seed=7 --offerat=3 --offer=event"
"contest|8|--start=horde --seed=7 --offerat=3 --offer=contest:tavern"
"swarm|6|--start=horde --seed=7 --spawn=rat_brute,rat_king,rat_horde,cave_troll"
"title_en|5|--menu=title|language:en"
"decks_en|5|--menu=decks|language:en"
"collection_en|5|--menu=collection|language:en"
"run_mid_en|7|--autoplay=heuristic --seed=7 --skip=560 --speed=1|language:en"
"offer_en|6|--start=horde --seed=7 --offerat=3|language:en"
"pause_en|6|--start=horde --seed=7 --pauseat=3|language:en"
)
for r in "${RES[@]}"; do
  for s in "${SCREENS[@]}"; do
    IFS='|' read -r name t args set <<<"$s"
    if [ -n "$CAPTURE_ONLY" ] && ! grep -qw "$name" <<<"$CAPTURE_ONLY"; then continue; fi
    tmp="$OUT/_tmp_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
    sets=$(printf '%s' "$set,$CAPTURE_SET" | sed 's/^,*//; s/,*$//')
    if [ "$r" = full ]; then win=(); sets="fullscreen:true${sets:+,$sets}"; tag=1920x1080; else win=(--resolution "$r" --position 0,0); tag=$r; fi
    timeout 90 "$GODOT" --path . "${win[@]}" -- $args --set="$sets" --shots=$t --quit=$((t+1)) --out="$tmp" >/dev/null 2>"$tmp/err.txt"
    f=$(ls "$tmp"/shot_*.png 2>/dev/null | head -1)
    if [ -n "$f" ]; then mv "$f" "$OUT/${name}_${tag}.png"; echo "ok $name $tag"; else echo "FALHOU $name $tag: $(grep -m3 -i error "$tmp/err.txt")"; fi
    rm -rf "$tmp"
  done
done
# Carta ampliada e mapa grande: o teste da entrada real grava uitest_hover/map/selected.
if [ -z "$CAPTURE_ONLY" ] || grep -qw uitest <<<"$CAPTURE_ONLY"; then
  for r in "${RES[@]}"; do
    if [ "$r" = full ]; then win=(); sets="fullscreen:true"; tag=1920x1080; else win=(--resolution "$r" --position 0,0); sets=""; tag=$r; fi
    tmp="$OUT/_tmp_uitest/"; rm -rf "$tmp"; mkdir -p "$tmp"
    timeout 120 "$GODOT" --path . "${win[@]}" -- --uitest=1 --set="$sets" --out="$tmp" > "$tmp/log.txt" 2>&1
    for k in hover map selected; do [ -f "$tmp/uitest_$k.png" ] && mv "$tmp/uitest_$k.png" "$OUT/hand_${k}_${tag}.png"; done
    echo "uitest $tag: $(grep -m1 "uitest resultado" "$tmp/log.txt")"
    rm -rf "$tmp"
  done
fi
