"""cultists: acabamento calcado de docs/arte_cartas/lich_2/comp/cultists.svg (magia e sombra em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("cultists", "lich_2", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_menir[012]": 1.0},
    bg_lift=[r"bg_lua.*", r"bg_menir[012]_luz"],
    figs={"fig_cultista": dict(w=1.1, rim=dict(dirs=[(1, 0.2)], alpha=0.7, w=1.5)), "fig_cultista_b": dict(w=0.9, rim=dict(dirs=[(1, 0.2)], alpha=0.7, w=1.5)), "fig_cultista_c": dict(w=0.9, rim=dict(dirs=[(-1, 0.2)], alpha=0.7, w=1.5))},
))
