"""skeleton_archers: acabamento calcado de docs/arte_cartas/lich_1/comp/skeleton_archers.svg (osso em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("skeleton_archers", "lich_1", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_muro": 1.0},
    bg_lift=[r"bg_lua.*"],
    figs={"fig_arqueiro2": dict(w=0.9, lift=["arqueiro2_corpo", "arqueiro2_cabeca", "arqueiro2_arco"]),
          "fig_arqueiro": dict(w=1.0, lift=["arqueiro_corpo", "arqueiro_cabeca", "arqueiro_arco", "arqueiro_flecha", "arqueiro_aljava"])},
))
