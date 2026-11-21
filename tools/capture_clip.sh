#!/usr/bin/env bash
# Clipe curto de um efeito (rodada visual 20/11/2026): bash tools/capture_clip.sh <frente> <variante-pasta> <flag> <nome> <fxend-s> "<args do jogo>"
#   ex.: bash tools/capture_clip.sh fx v1 --fx=1 fogo 5 "--start=horde ... --fxdemo=torch"
# Grava o .avi bruto em <scratch>/<frente>_<pasta>_<nome>.avi e o log em .txt (quadros do disparo e posição do herói).
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
FRENTE="$1"; DIR="$2"; FLAG="$3"; NAME="$4"; END="$5"; EXTRA="$6"
cd "$(dirname "$0")/.."
RAW="${RAW:-/c/Users/gabri/AppData/Local/Temp/clips_raw}"; mkdir -p "$RAW"
B="$RAW/${FRENTE}_${DIR}_${NAME}"
rm -f "$B.avi" "$B.txt" "$B.err"
until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
timeout 1200 "$GODOT" --position -6000,0 --path . --write-movie "$B.avi" --fixed-fps 30 -- $EXTRA $FLAG --set="fullscreen:true" --fxend=$END --quit=400 >"$B.txt" 2>"$B.err"
rmdir /c/Users/gabri/Desktop/.godot_capture.lock
[ -s "$B.avi" ] && echo "ok $B.avi" || echo "FALHOU $B"
grep -i "SCRIPT ERROR\|Parse Error\|SHADER ERROR" "$B.err" "$B.txt" | sort | uniq -c | head -5
