#!/usr/bin/env bash
# Fotografa as maquetes de docs/ui_propostas/escolher.html (modo ?solo) em 1920x1080 com o Chrome sem janela, uma por vez (em paralelo o servidor local deixava imagens sem carregar).
# Precisa do servidor da raiz do repositório na porta 8766 (.claude/launch.json "ui-propostas").
CHROME="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
OUT="$(cd "$(dirname "$0")/../.." && pwd)/docs/ui_propostas/fotos"
mkdir -p "$OUT"
for d in ${DIRS:-1 2 3 4 5 6}; do
  for t in run arena oferta loja menu; do
    (
      prof="$(cygpath -w "$(mktemp -d)")"
      "$CHROME" --headless=new --disable-gpu --hide-scrollbars --user-data-dir="$prof" --window-size=1920,1080 \
        --virtual-time-budget=9000 --screenshot="$(cygpath -w "$OUT")\d${d}_$t.png" \
        "http://localhost:8766/docs/ui_propostas/escolher.html?solo=$d&tela=$t" >/dev/null 2>&1
      rm -rf "$prof"
    )
  done
done
python -c "
import glob,os
from PIL import Image
for f in glob.glob(r'$(cygpath -w "$OUT")\d*_*.png'):
    Image.open(f).convert('RGB').save(f[:-4]+'.jpg',quality=88); os.remove(f)
print(len(glob.glob(r'$(cygpath -w "$OUT")\*.jpg')),'fotos')"
