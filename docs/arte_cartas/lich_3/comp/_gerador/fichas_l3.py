"""Fichas novas do lote lich_3: fantasma, golem_sucata.
Uso: python fichas_l3.py [fantasma] [golem_sucata]   (grava em LB_FICH = tools/art/card_blender/fichas/)"""
import base  # noqa: F401
from base import FICH
import sys
from fichas_l1 import svg_wrap, ruler, ground_line
from render import shot


def fantasma():
    import fantasma as f
    return f.ficha(svg_wrap, ruler, ground_line)


def golem_sucata():
    import golem as g
    return g.ficha(svg_wrap, ruler, ground_line)


TODO = dict(fantasma=fantasma, golem_sucata=golem_sucata)

if __name__ == "__main__":
    out = FICH
    if "--out" in sys.argv:
        k = sys.argv.index("--out"); out = sys.argv[k + 1]; del sys.argv[k:k + 2]
    for nm in (sys.argv[1:] or TODO):
        s, wh = TODO[nm]()
        open(f"{out}/{nm}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{out}/{nm}.png", (0, 0) + wh, *wh, guide=True, inkw=2.0)
        print(nm, len(s))
