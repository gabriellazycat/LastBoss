"""Prancha de revisão: python sheet.py <pasta com <id>_v2.png> <saída.png> id1,id2,... [colunas] [largura da célula]"""
import sys, os
from PIL import Image, ImageDraw

src, out, ids = sys.argv[1], sys.argv[2], sys.argv[3].split(",")
cols = int(sys.argv[4]) if len(sys.argv) > 4 else 4
cw = int(sys.argv[5]) if len(sys.argv) > 5 else 360
ch = int(cw * 0.77)
rows = (len(ids) + cols - 1) // cols
sh = Image.new("RGB", (cols * cw, rows * (ch + 18)), (236, 228, 205))
d = ImageDraw.Draw(sh)
for k, i in enumerate(ids):
    p = os.path.join(src, i + "_v2.png")
    x, y = (k % cols) * cw, (k // cols) * (ch + 18)
    d.text((x + 4, y + 3), i, fill=(40, 20, 20))
    if not os.path.exists(p):
        continue
    im = Image.open(p).convert("RGBA"); im.thumbnail((cw - 6, ch - 4))
    sh.paste(im, (x + 3, y + 18), im)
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
sh.save(out)
