#!/usr/bin/env bash
# Auditoria de folga da interface (game/spacing_audit.gd), SEM janela (headless): para cada tela de tools/ui_screens.sh
# mede a distância entre o texto e a borda desenhada da caixa e acusa texto cortado ou fora da tela.
# Uso: bash tools/space_audit.sh <pasta de saída> [LxA ...]   (padrão: 1920x1080; 1280x720 dá o mesmo layout lógico de 1600x900)
# SPACE_ONLY="title offer" limita as telas; SPACE_JOBS=4 execuções em paralelo.
# Saída: <pasta>/<tela>_<LxA>.txt (uma linha por problema) e <pasta>/_todos.txt. Código de saída = nº de problemas (0 = limpo).
# As capturas com janela (tools/capture_ui.sh) rodam a mesma auditoria e guardam em <pasta>/space/.
# Exceções justificadas ficam no código, no próprio nó: set_meta("no_audit", ...) / set_meta("no_frame_audit", ...).
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; shift
WINS=("$@"); [ ${#WINS[@]} -eq 0 ] && WINS=(1920x1080)
JOBS="${SPACE_JOBS:-4}"
cd "$(dirname "$0")/.."
source "$(dirname "$0")/ui_screens.sh"
mkdir -p "$OUT"; rm -f "$OUT"/*.txt
one() {
  local name="$1" t="$2" args="$3" set="$4" win="$5"
  local tmp="$OUT/_tmp_${name}_${win}/"; rm -rf "$tmp"; mkdir -p "$tmp"
  local sets; sets=$(printf '%s' "$set" | sed 's/^,*//; s/,*$//')
  timeout 120 "$GODOT" --headless --path . -- $args --set="$sets" --quit=$((t+1)) --out="$tmp" \
      --spacetest="${name}_${win}" --spaceat=$t --spacewin="$win" >"$tmp/log.txt" 2>&1
  if [ -f "$tmp/space_${name}_${win}.txt" ]; then mv "$tmp/space_${name}_${win}.txt" "$OUT/${name}_${win}.txt"
  else echo "FALHOU $name $win: $(grep -m3 -i 'error' "$tmp/log.txt")"; fi
  rm -rf "$tmp"
}
n=0
for w in "${WINS[@]}"; do
  for s in "${SCREENS[@]}"; do
    IFS='|' read -r name t args set <<<"$s"
    if [ -n "$SPACE_ONLY" ] && ! grep -qw "$name" <<<"$SPACE_ONLY"; then continue; fi
    one "$name" "$t" "$args" "$set" "$w" &
    n=$((n+1)); [ $((n % JOBS)) -eq 0 ] && wait
  done
done
wait
# Mão, carta ampliada e mapa grande (teste da entrada real; o resultado OK/FALHOU dele não conta aqui, só a auditoria).
if [ -z "$SPACE_ONLY" ] || grep -qw uitest <<<"$SPACE_ONLY"; then
  for w in "${WINS[@]}"; do
    tmp="$OUT/_tmp_uitest/"; rm -rf "$tmp"; mkdir -p "$tmp"
    timeout 200 "$GODOT" --headless --path . -- --uitest=1 --out="$tmp" --spacetest=uitest --spacewin="$w" >"$tmp/log.txt" 2>&1
    for f in "$tmp"/space_hand_*.txt; do [ -f "$f" ] && mv "$f" "$OUT/$(basename "$f" .txt | sed 's/^space_//')_$w.txt"; done
    rm -rf "$tmp"
  done
fi
cat "$OUT"/*.txt > "$OUT/_todos.txt" 2>/dev/null
total=$(grep -c "" "$OUT/_todos.txt")
for f in "$OUT"/*_*.txt; do [ "$(basename "$f")" = "_todos.txt" ] && continue; c=$(grep -c "" "$f"); [ "$c" -gt 0 ] && echo "$c $(basename "$f" .txt)"; done | sort -rn
echo "total de problemas: $total"
exit $(( total > 255 ? 255 : total ))
