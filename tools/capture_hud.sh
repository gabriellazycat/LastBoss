#!/usr/bin/env bash
# Capturas das variações da HUD da run (17/11/2026, docs/HUD_2026-11-17.md): cada layout nas mesmas situações e semente.
# Uso: bash tools/capture_hud.sh <pasta de saída> "<layouts>"   (ex.: docs/hud_2026-11-17 "0 1 2 3")
# Uma captura por vez (em paralelo elas disputam a GPU e fotografam o menu).
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"
LAYOUTS="${2:-0 1 2 3}"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
# nome | tempo da foto | argumentos
SCREENS=(
"a_party4_disputa|14|--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --offerat=3 --offer=contest:tavern"
"b_solo_meio|14|--autoplay=heuristic --seed=7 --skip=560 --speed=1"
"c_party2_estrada|14|--autoplay=heuristic --phase=6 --seed=7 --skip=420 --speed=1"
)
# Situações extras (EXTRA=1): arena com corpo do chefe e relíquias, texto mais longo da missão, herói sozinho com missão,
# elixir máximo acima de 10 e a interface ampliada (ui_scale 1.15 = a tela lógica mais estreita).
if [ -n "$EXTRA" ]; then SCREENS+=(
"d_arena|14|--autoplay=heuristic --phase=6 --seed=7 --skip=arena --speed=1"
"e_fonte|14|--autoplay=heuristic --phase=6 --seed=7 --skip=fountain --speed=1"
"f_solo_missao|14|--autoplay=heuristic --seed=7 --skip=tavern --speed=1"
"g_elixir14|14|--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --offerat=3 --offer=contest:tavern --elixirmax=14"
"h_escala115|14|--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --offerat=3 --offer=contest:tavern --set=ui_scale:1.15"
); fi
for L in $LAYOUTS; do
  for s in "${SCREENS[@]}"; do
    IFS='|' read -r name t args <<<"$s"
    # Um --set da situação entra junto com o fullscreen (dois --set: o segundo apagaria o primeiro).
    SETX=""; if [[ "$args" =~ --set=([^ ]+) ]]; then SETX=",${BASH_REMATCH[1]}"; args="${args/--set=${BASH_REMATCH[1]}/}"; fi
    if [ -n "$CAPTURE_ONLY" ] && ! grep -qw "$name" <<<"$CAPTURE_ONLY"; then continue; fi
    tmp="$OUT/_tmp_${L}_$name/"; rm -rf "$tmp"; mkdir -p "$tmp"
    timeout 150 "$GODOT" --path . -- $args --hudlayout=$L --set="fullscreen:true${SETX}" --shots=$t --quit=$((t+1)) --out="$tmp" >"$tmp/out.txt" 2>"$tmp/err.txt"; echo "   $(grep -m1 "hud sobreposicoes" "$tmp/out.txt")"
    f=$(ls "$tmp"/shot_*.png 2>/dev/null | head -1)
    if [ -n "$f" ]; then mv "$f" "$OUT/L${L}_${name}.png"; echo "ok L$L $name"; else echo "FALHOU L$L $name: $(grep -m3 -i error "$tmp/err.txt")"; fi
    grep -i "SCRIPT ERROR\|Parse Error" "$tmp/err.txt" | head -3
    rm -rf "$tmp"
  done
done
