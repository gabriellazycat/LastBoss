#!/usr/bin/env bash
# Uso: bash tools/art/blender_arvores/run.sh <estilo> <pasta de saída>  (gera as 6 malhas e a prancha)
cd "$(dirname "$0")/../../.."
N="$1"; S="$2"; mkdir -p "$S"
timeout 900 "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_arvores/build_arvores.py -- "$S" --estilo=$N --sheet=docs/cenario_proposito/arvores/estilo$N.png > "$S/log.txt" 2>&1
echo rc=$?; grep -E "ARV|FALHOU|Error|PRANCHA|Traceback" "$S/log.txt" | head -30
