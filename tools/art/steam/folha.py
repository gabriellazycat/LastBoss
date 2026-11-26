"""Folhas de conferencia por formato (hero com a area segura 860x380 em verde). python -I folha.py [pasta_de_saida]"""
import os, sys
from PIL import Image, ImageDraw
OUT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "out", "steam"))
DEST = sys.argv[1] if len(sys.argv) > 1 else OUT


def folha(nome, sub, fmt, cols, tw, segura=False):
    ims = []
    for i in range(1, 11):
        im = Image.open(os.path.join(OUT, f"v{i:02d}", sub, fmt + ".png")).convert("RGB")
        if segura:
            W, H = im.size
            ImageDraw.Draw(im).rectangle([(W - 860) // 2, (H - 380) // 2, (W + 860) // 2, (H + 380) // 2], outline=(0, 255, 0), width=8)
        im = im.resize((tw, round(im.height * tw / im.width)), Image.LANCZOS)
        ImageDraw.Draw(im).text((6, 6), f"v{i:02d}", fill=(255, 0, 255))
        ims.append(im)
    th, linhas = ims[0].height, (10 + cols - 1) // cols
    out = Image.new("RGB", (cols * tw + (cols - 1) * 6, linhas * th + (linhas - 1) * 6), (0, 255, 255))
    for k, im in enumerate(ims):
        out.paste(im, ((k % cols) * (tw + 6), (k // cols) * (th + 6)))
    out.save(os.path.join(DEST, nome + ".png"))


if DEST == OUT:
    folha("folha", "com_logo", "main_capsule", 2, 616)
else:
    folha("hero", "sem_logo", "library_hero", 2, 960, True)
    folha("vert", "com_logo", "vertical_capsule", 5, 374)
    folha("libcap", "com_logo", "library_capsule", 5, 300)
    folha("header", "com_logo", "header_capsule", 2, 600)
    folha("main", "com_logo", "main_capsule", 2, 616)
