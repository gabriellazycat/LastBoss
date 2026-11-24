#!/usr/bin/env bash
# Converte a saída do build_pinceladas.py (estilo N: 5 carvalho, 6 pinheiro + álamo) para assets/models/arv<N>/<id>_a<ato>.res + .png.
# Uso: bash tools/art/blender_arvores/fazer.sh <estilo> <pasta de saída do build>
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/../../.."
N="$1"; SRC="$2"
TMP=assets/models/_arv_tmp
rm -rf "$TMP"
timeout 300 "$GODOT" --headless --path . -s res://tools/art/import_g.gd -- --src="$SRC" --m2 --out=res://$TMP/ > "$SRC/import.txt" 2>&1
echo "import rc=$?"; grep -E "^g |m2:|ERROR" "$SRC/import.txt"
mkdir -p assets/models/arv$N
for f in "$TMP"/m2_a/*.res; do b=$(basename "$f" .res); mv "$f" assets/models/arv$N/$b.res; mv "$TMP/g_tex/m2/$b.png" assets/models/arv$N/$b.png; done
rm -rf "$TMP"
ls assets/models/arv$N
