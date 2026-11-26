"""Confere tamanhos exatos, conjunto completo por pasta e o logo transparente. python -I validar.py"""
import os
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "out", "steam")
EXP = {"main_capsule": (1232, 706), "header_capsule": (920, 430), "small_capsule": (462, 174), "vertical_capsule": (748, 896),
       "page_background": (1438, 810), "library_capsule": (600, 900), "library_header": (920, 430),
       "library_hero": (3840, 1240), "library_logo": (1280, None)}
n, erros = 0, []
for i in range(1, 11):
    for sub in ("com_logo", "sem_logo"):
        for k, (w, h) in EXP.items():
            if k == "library_logo" and sub == "sem_logo":
                continue                          # sem logo nao existe library logo
            p = os.path.join(OUT, f"v{i:02d}", sub, k + ".png")
            if not os.path.exists(p):
                erros.append("FALTA " + p)
                continue
            n += 1
            im = Image.open(p)
            if im.width != w or (h and im.height != h):
                erros.append(f"TAMANHO {p} {im.size}")
            if k == "library_logo":
                if im.mode != "RGBA" or im.getpixel((0, 0))[3] != 0 or im.height > 720:
                    erros.append(f"LOGO {p} {im.mode} {im.size}")
for e in erros:
    print(e)
print(n, "arquivos, erros:", len(erros))
