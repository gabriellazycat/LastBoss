"""Bau Armadilha (trap_chest): acabamento calcado de docs/arte_cartas/dragao_2/comp/trap_chest.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("trap_chest", "dragao_2", dict(
    fx_alpha=1.35, fx_lift=True, fx_hold=True,
    ink_bg={r"bg_coluna": 1.0, r"bg_capitel": 1.0},
    figs={"fig_bau": dict(w=1.0), "fig_heroi": dict(w=0.9)},
))
