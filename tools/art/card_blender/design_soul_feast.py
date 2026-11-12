"""soul_feast: acabamento calcado de docs/arte_cartas/lich_3/comp/soul_feast.svg (guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("soul_feast", "lich_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    bg_lift=[r"bg_portal\d*", r"bg_circulo"],
    figs={"fig_heroi": dict(w=1.0)},
))
