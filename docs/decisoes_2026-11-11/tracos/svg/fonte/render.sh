#!/bin/bash
# uso: render.sh <cena> <png de saída>
S="$(cd "$(dirname "$0")" && pwd)"
W="$(cygpath -m "$S")"
C="/c/Program Files/Google/Chrome/Application/chrome.exe"
"$C" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --window-size=556,478 --virtual-time-budget=20000 --screenshot="$(cygpath -w "$2")" "file:///$W/build.html#$1" 2>/dev/null
"$C" --headless=new --disable-gpu --allow-file-access-from-files --virtual-time-budget=20000 --dump-dom "file:///$W/build.html#$1" 2>/dev/null > "$S/dom_$1.html"
