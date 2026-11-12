"""kobold_scavengers: acabamento calcado de docs/arte_cartas/dragao_3/comp/kobold_scavengers.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("kobold_scavengers", "dragao_3", dict(
    enx_w=0.6, fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_barranco": 1.0, r"bg_toca": 0.8},
    figs={"fig_kobold": dict(w=1.0), "fig_heroi": dict(w=0.8, detail=False)},
))
