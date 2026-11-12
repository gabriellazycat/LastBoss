#!/bin/bash
# usage: run.sh design_x.py name
cd "$(dirname "$0")"
python "$1" "$2.json" || exit 1
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P gp_render.py -- "$2.json" "$2_ink.png" 4 2>&1 | grep -i -E 'error|traceback' 
python composite.py "$2.json" "$2_ink.png" "$2.png"
