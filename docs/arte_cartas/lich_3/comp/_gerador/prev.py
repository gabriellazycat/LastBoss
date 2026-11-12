"""Pré-visualização rápida de poses de ficha (rascunho): python prev.py <modulo> <pose> [<pose>...] -> SCR/prev_<modulo>.png"""
import base  # noqa: F401
from base import SCR
import sys, importlib
from geom import *
from fichas_lib import pose_g
from render import shot
mod = importlib.import_module(sys.argv[1]); names = sys.argv[2:]
W = 360 * len(names); H = 420
parts = [pose_g(n, mod.pose(n), (180 + 360 * i, 340, float(getattr(mod, "PREV_S", 1.6))), sys.argv[1], mod.GUIDE.get(n)) for i, n in enumerate(names)]
s = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}"><rect width="{W}" height="{H}" fill="#f6efe0"/>' + "\n".join(parts) + "</svg>"
shot(s, f"{SCR}/prev_{sys.argv[1]}.png", (0, 0, W, H), W, H, guide=True, inkw=2.0)
