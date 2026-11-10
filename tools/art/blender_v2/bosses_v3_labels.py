"""Põe nomes (e a legenda de cores das partes) nas pranchas do bosses_v3.py. Python do sistema com Pillow.
Uso: python tools/art/blender_v2/bosses_v3_labels.py <pasta com chefes_raw.png e chefes_partes_raw.png>"""
import sys, os
from PIL import Image, ImageDraw, ImageFont

d = sys.argv[1]
NAMES = ["Lorde das Trevas (atual)", "Rainha da Praga", "Dragão Avarento", "Lich"]
LEG = [("Membro esquerdo", (30, 82, 242)), ("Membro direito", (235, 30, 26)), ("Cabeça", (250, 217, 20)), ("Núcleo", (38, 199, 64))]


def font(sz):
    for f in ("C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/arialbd.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, sz)
    return ImageFont.load_default()


def run(src, dst, legend):
    im = Image.open(os.path.join(d, src)).convert("RGB")
    W, H = im.size
    bar = 112 if legend else 56
    out = Image.new("RGB", (W, H + bar), (24, 24, 28))
    out.paste(im, (0, 0))
    dr = ImageDraw.Draw(out)
    f = font(34)
    for i, n in enumerate(NAMES):
        cx = int(W * (0.183, 0.396, 0.61, 0.82)[i])   # centros dos chefes na prancha
        w = dr.textlength(n, font=f)
        dr.text((cx - w / 2, H + 8), n, font=f, fill=(240, 240, 240))
    if legend:
        f2 = font(26)
        tot = sum(dr.textlength(t, font=f2) + 70 for t, _ in LEG)
        x = (W - tot) / 2
        for t, c in LEG:
            dr.rectangle([x, H + 66, x + 28, H + 94], fill=c)
            dr.text((x + 38, H + 64), t, font=f2, fill=(230, 230, 230))
            x += dr.textlength(t, font=f2) + 70
    out.save(os.path.join(d, dst))


run("chefes_raw.png", "chefes.png", False)
run("chefes_partes_raw.png", "chefes_partes.png", True)
