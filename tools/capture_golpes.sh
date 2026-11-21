#!/usr/bin/env bash
# Clipes da frente "Golpes e animações" (rodada visual 20/11/2026), em segundo plano (janela fora da tela, sem
# tela cheia, sem mexer no mouse). Uso: bash tools/capture_golpes.sh <nome> <golpes 0|1> <fim-s> "<args extras>"
# Grava o .avi bruto em $RAW/golpes_<nome>.avi (+ .txt/.err).
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
NAME="$1"; G="$2"; END="$3"; EXTRA="$4"
cd "$(dirname "$0")/.."
RAW="${RAW:-/c/Users/gabri/AppData/Local/Temp/clips_raw}"; mkdir -p "$RAW"
B="$RAW/golpes_${NAME}"
rm -f "$B.avi" "$B.txt" "$B.err"
BASE="--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --herostop=1 --fx=3 --herois=1 --mundo=3 --luz=2 --arena=2"
until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
timeout 900 "$GODOT" --position -6000,0 --path . --write-movie "$B.avi" --fixed-fps 30 -- $BASE $EXTRA --golpes=$G --fxend=$END --quit=400 >"$B.txt" 2>"$B.err"
rmdir /c/Users/gabri/Desktop/.godot_capture.lock
[ -s "$B.avi" ] && echo "ok $B.avi" || echo "FALHOU $B"
grep -i "SCRIPT ERROR\|Parse Error\|SHADER ERROR" "$B.err" "$B.txt" | sort | uniq -c | head -5
