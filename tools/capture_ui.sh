#!/usr/bin/env bash
# Fotografa as telas da interface para a revisão visual (docs/REVISAO_VISUAL.md).
# Uso: bash tools/capture_ui.sh <pasta de saída> [res1 res2 ...]  (padrão: 1920x1080 1280x720)
# "full" captura em tela cheia (1920x1080 num monitor desse tamanho; a janela de 1080 de altura é cortada pela barra).
# CAPTURE_ONLY="title decks" limita as telas; CAPTURE_SET="look_hud:5" acrescenta configurações a todas.
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; shift
# CAPTURE_LOCK=1: cada execução com janela espera a trava da GPU (outros agentes também capturam).
run_locked() {
  if [ -z "$CAPTURE_LOCK" ]; then "$@"; return $?; fi
  until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
  "$@"; local rc=$?
  rmdir /c/Users/gabri/Desktop/.godot_capture.lock
  return $rc
}
RES=("$@"); [ ${#RES[@]} -eq 0 ] && RES=(full 1280x720)
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
source "$(dirname "$0")/ui_screens.sh"
for r in "${RES[@]}"; do
  for s in "${SCREENS[@]}"; do
    IFS='|' read -r name t args set <<<"$s"
    if [ -n "$CAPTURE_ONLY" ] && ! grep -qw "$name" <<<"$CAPTURE_ONLY"; then continue; fi
    tmp="$OUT/_tmp_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
    sets=$(printf '%s' "$set,$CAPTURE_SET" | sed 's/^,*//; s/,*$//')
    if [ "$r" = full ]; then win=(); sets="fullscreen:true${sets:+,$sets}"; tag=1920x1080; else win=(--resolution "$r" --position 0,0); tag=$r; fi
    run_locked timeout 90 "$GODOT" --position -6000,0 --path . "${win[@]}" -- $args --set="$sets" --shots=$t --quit=$((t+1)) --out="$tmp" --spacetest="${name}_${tag}" --spaceat=$t >/dev/null 2>"$tmp/err.txt"
    mkdir -p "$OUT/space"; [ -f "$tmp/space_${name}_${tag}.txt" ] && mv "$tmp/space_${name}_${tag}.txt" "$OUT/space/${name}_${tag}.txt"
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
    run_locked timeout 120 "$GODOT" --position -6000,0 --path . "${win[@]}" -- --uitest=1 --set="$sets" --out="$tmp" --spacetest=uitest > "$tmp/log.txt" 2>&1
    for k in hover map selected; do [ -f "$tmp/uitest_$k.png" ] && mv "$tmp/uitest_$k.png" "$OUT/hand_${k}_${tag}.png"; [ -f "$tmp/space_hand_$k.txt" ] && mkdir -p "$OUT/space" && mv "$tmp/space_hand_$k.txt" "$OUT/space/hand_${k}_${tag}.txt"; done
    echo "uitest $tag: $(grep -m1 "uitest resultado" "$tmp/log.txt")"
    rm -rf "$tmp"
  done
fi
