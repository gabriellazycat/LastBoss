"""soul_storm: acabamento calcado de docs/arte_cartas/lich_3/comp/soul_storm.svg (guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("soul_storm", "lich_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_lapide\d*": 1.0},
    bg_lift=[r"bg_olho\d*", r"bg_olho_centro", r"bg_chao_luz", r"bg_lapide\d_luz"],
    figs={"fig_heroi": dict(w=1.0, rim=dict(dirs=[(0, 1)], color="#7dffb0", alpha=0.7, w=1.5))},
))
