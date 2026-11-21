#!/usr/bin/env bash
# Foto de uma estrutura no jogo (rodada visual 20/11/2026, estruturas novas).
# Uso: bash tools/art/blender_m2/shot_m2.sh <pasta-saída> <id> <modelos 0|1> [n cópias=1] [camzoom=-14]
# Grava <pasta>/<id>.png (foto aos 5 s, estrutura nascida aos 2 s, herói parado).
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; ID="$2"; M="$3"; N="${4:-1}"; Z="${5:-14}"
cd "$(dirname "$0")/../../.."
mkdir -p "$OUT"
TMP="$(mktemp -d)"
SP="$ID"; for ((k=1;k<N;k++)); do SP="$SP,$ID"; done
until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
timeout 180 "$GODOT" --position -6000,0 --path . -- --start=horde --seed=7 --firstparty=${PARTY:-guardiao} --herostop=1 \
  --spawn=$SP --camzoom=-$Z --modelos=$M --fx=0 --bare --shots=3.2 --quit=4 --out="$TMP/" >"$TMP/log.txt" 2>"$TMP/err.txt"
rmdir /c/Users/gabri/Desktop/.godot_capture.lock
if [ -f "$TMP/shot_003.png" ]; then mv "$TMP/shot_003.png" "$OUT/$ID.png"; echo "ok $OUT/$ID.png"; else echo "FALHOU $ID"; tail -5 "$TMP/err.txt"; fi
grep -i "SCRIPT ERROR\|Parse Error" "$TMP/err.txt" | sort | uniq -c | head -3
rm -rf "$TMP"
# recorte em volta da estrutura (ela nasce sempre no mesmo ponto: seed 7, herói parado)
[ -f "$OUT/$ID.png" ] && python -I -c "
import sys; from PIL import Image
im=Image.open(sys.argv[1]); w,h=im.size; k=w/1600
im.crop((int(367*k),int(50*k),int(950*k),int(425*k))).resize((1120,720),Image.LANCZOS).save(sys.argv[2])" "$OUT/$ID.png" "$OUT/${ID}_perto.png"
