"""Folha do lote lich_1: preview grande + 150 px de cada carta. Uso: python folha_l1.py [ids...] (pasta: LB_OUT)"""
import base  # noqa: F401
from base import OUT
import sys
from PIL import Image, ImageDraw
ids = sys.argv[1:] or "skeleton_archers bone_legion ghoul raised_servant bone_totem bone_colossus death_knight corpse_blast".split()
cw, ch = 300, 450; cols = 4; rows = (len(ids) + cols - 1) // cols
sh = Image.new("RGB", (cols * cw, rows * ch), "#1c1a22"); d = ImageDraw.Draw(sh)
for k, i in enumerate(ids):
    im = Image.open(f"{OUT}/{i}.png").convert("RGB")
    x = (k % cols) * cw + 11; y = (k // cols) * ch + 10
    sh.paste(im.resize((278, 267), Image.LANCZOS), (x, y))
    sm = im.resize((150, 144), Image.LANCZOS); sh.paste(sm, (x, y + 290))
    d.text((x + 160, y + 300), i, fill="#e8e0d0"); d.text((x + 160, y + 316), "150 px", fill="#a8a0b0")
sh.save(f"{OUT}/folha.png"); print(sh.size)
