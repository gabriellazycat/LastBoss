"""open_grave: acabamento calcado de docs/arte_cartas/lich_3/comp/open_grave.svg (guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("open_grave", "lich_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_lapide": 1.0, r"bg_cerca": 0.8, r"bg_cerca_haste\d*": 0.8, r"bg_cova": 1.0},
    bg_lift=[r"bg_nevoa_luz\d*", r"bg_lapide_luz"],
    figs={"fig_heroi": dict(w=1.0), "fig_esqueleto": dict(w=1.1), "fig_esqueleto2": dict(w=0.9)},
))
