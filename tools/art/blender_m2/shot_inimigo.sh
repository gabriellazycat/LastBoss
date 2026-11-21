#!/usr/bin/env bash
# Foto de um inimigo no jogo (rodada visual 20/11/2026, inimigos novos), Godot em segundo plano (fora da tela).
# Uso: bash tools/art/blender_m2/shot_inimigo.sh <pasta-saída> <id> <modelos 0|1> [n cópias=3] [camzoom=12]
# Os inimigos nascem aos 2 s (arco a 9 m do herói parado) e correm até ele; o tempo de carga varia e eles morrem
# depressa, então tira várias fotos (SHOTS, padrão 3,0 a 4,2 s) em <pasta>/<id>_<k>.png, recortadas em volta do herói,
# para escolher a melhor à mão.
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; ID="$2"; M="$3"; N="${4:-3}"; Z="${5:-12}"; SHOTS="${SHOTS:-3.0,3.3,3.6,3.9,4.2}"
cd "$(dirname "$0")/../../.."
mkdir -p "$OUT"
TMP="$(mktemp -d)"
SP="$ID"; for ((k=1;k<N;k++)); do SP="$SP,$ID"; done
until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
timeout 180 "$GODOT" --position -6000,0 --path . -- --start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --herostop=1 \
  --spawn=$SP --camzoom=-$Z --modelos=$M --fx=0 --bare --shots=$SHOTS --quit=4.8 --out="$TMP/" >"$TMP/log.txt" 2>"$TMP/err.txt"
rmdir /c/Users/gabri/Desktop/.godot_capture.lock
ls "$TMP"/shot_*.png >/dev/null 2>&1 || { echo "FALHOU $ID"; tail -5 "$TMP/err.txt"; rm -rf "$TMP"; exit 1; }
grep -i "SCRIPT ERROR\|Parse Error" "$TMP/err.txt" | sort | uniq -c | head -3
python -I - "$TMP" "$OUT" "$ID" <<'EOF'
import sys, glob, os
from PIL import Image
tmp, out, i = sys.argv[1:4]
fs = sorted(glob.glob(os.path.join(tmp, "shot_*.png")))
for j, f in enumerate(fs):
    sfx = "_%d" % j
    im = Image.open(f); w, h = im.size; k = w / 1920
    im.crop((int(480 * k), int(60 * k), int(1440 * k), int(660 * k))).save(os.path.join(out, i + sfx + ".png"))
    print("ok", os.path.join(out, i + sfx + ".png"))
EOF
rm -rf "$TMP"
