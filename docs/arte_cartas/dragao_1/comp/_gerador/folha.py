"""Folha do lote dragao_1: preview grande + 150 px de cada carta. Uso: python folha.py [ids...] (pasta: LB_OUT)"""
import base  # noqa: F401
from base import OUT
import sys
from PIL import Image, ImageDraw
ids = sys.argv[1:] or "goblin_dynamiter fire_imp boiling_oil oil_splash torch spark ember_rain eruption".split()
cw, ch = 300, 450; cols = 4; rows = (len(ids) + cols - 1) // cols
sh = Image.new("RGB", (cols * cw, rows * ch), "#1c1a22"); d = ImageDraw.Draw(sh)
for k, i in enumerate(ids):
    im = Image.open(f"{OUT}/{i}.png").convert("RGB")
    x = (k % cols) * cw + 11; y = (k // cols) * ch + 10
    sh.paste(im.resize((278, 267), Image.LANCZOS), (x, y))
    sm = im.resize((150, 144), Image.LANCZOS); sh.paste(sm, (x, y + 290))
    d.text((x + 160, y + 300), i, fill="#e8e0d0"); d.text((x + 160, y + 316), "150 px", fill="#a8a0b0")
sh.save(f"{OUT}/folha.png"); print(sh.size)
