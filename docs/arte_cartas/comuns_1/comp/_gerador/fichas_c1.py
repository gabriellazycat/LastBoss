"""Fichas novas do lote comuns_1: ogro, troll, tita, gargula.
Uso: python fichas_c1.py [--rascunho] [ogro] [troll] [tita] [gargula]   (grava em LB_FICH; --rascunho grava em LB_SCR)"""
import base  # noqa: F401
from base import FICH, SCR
from render_c1 import shot
import sys, importlib

MOD = dict(ogro="ogro_c1", troll="troll_c1", tita="tita_c1", gargula="gargula_c1")

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dst = SCR if "--rascunho" in sys.argv else FICH
    for nm in (args or MOD):
        s, wh = importlib.import_module(MOD[nm]).ficha()
        open(f"{dst}/{nm}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{dst}/{nm}.png", (0, 0) + wh, *wh, guide=True, inkw=2.0)
        print(nm, len(s), dst)
