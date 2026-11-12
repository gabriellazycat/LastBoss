#!/bin/bash
# usage: run.sh design_x.py name [out_dir]
#   design_x.py: caminho do script de acabamento (relativo a esta pasta ou absoluto)
#   out_dir: onde gravar name.json, name_ink.png e name.png (padrão: esta pasta)
HERE="$(cd "$(dirname "$0")" && pwd)"
DESIGN="$(cd "$(dirname "$1")" 2>/dev/null && pwd)/$(basename "$1")"
[ -f "$DESIGN" ] || DESIGN="$HERE/$1"
OUT="${3:-$HERE}"; mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
J="$(cygpath -m "$OUT/$2.json")"; INK="$(cygpath -m "$OUT/$2_ink.png")"; PNG="$(cygpath -m "$OUT/$2.png")"
cd "$HERE"
PYTHONPATH="$(cygpath -m "$HERE")" python "$(cygpath -m "$DESIGN")" "$J" || exit 1
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P "$(cygpath -m "$HERE/gp_render.py")" -- "$J" "$INK" 4 2>&1 | grep -i -E 'error|traceback'
python composite.py "$J" "$INK" "$PNG"
