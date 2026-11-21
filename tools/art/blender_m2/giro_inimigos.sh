#!/usr/bin/env bash
# Giro 360° (12 quadros) e clipe .webm (andar + ataque) dos inimigos novos, com o shader e o atlas do jogo
# (tools/art/m2_giro.tscn), Godot fora da tela. Uso: bash tools/art/blender_m2/giro_inimigos.sh <ids separados por vírgula>
# Grava docs/rodada_visual/inimigos/giro/<id>_NN.png e docs/rodada_visual/inimigos/v1/<id>.webm.
GODOT="${GODOT:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
FF="${FF:-/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0.2-full_build/bin/ffmpeg}"
IDS="$1"
cd "$(dirname "$0")/../../.."
D=docs/rodada_visual/inimigos
TMP="$(mktemp -d)"
mkdir -p "$D/giro" "$D/v1"
until mkdir /c/Users/gabri/Desktop/.godot_capture.lock 2>/dev/null; do sleep 5; done
timeout 900 "$GODOT" --position -6000,0 --resolution 720x720 --path . res://tools/art/m2_giro.tscn -- --ids="$IDS" --out="$D/" --clipout="$TMP/" --giro=12 --clip=1 >"$TMP/log.txt" 2>"$TMP/err.txt"
rmdir /c/Users/gabri/Desktop/.godot_capture.lock
grep -i "SCRIPT ERROR\|Parse Error\|sem m2" "$TMP/err.txt" "$TMP/log.txt" | sort | uniq -c | head -5
for i in ${IDS//,/ }; do
  if [ -d "$TMP/clip_$i" ]; then
    "$FF" -y -loglevel error -framerate 30 -i "$TMP/clip_$i/f_%04d.png" -c:v libvpx-vp9 -b:v 0 -crf 34 -pix_fmt yuv420p "$D/v1/$i.webm" && echo "ok $D/v1/$i.webm"
  else
    echo "FALHOU clipe $i"
  fi
done
rm -rf "$TMP"
