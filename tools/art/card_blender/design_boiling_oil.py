"""Oleo Fervente (boiling_oil): acabamento calcado de docs/arte_cartas/dragao_1/comp/boiling_oil.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("boiling_oil", "dragao_1", dict(
    fx_alpha=1.35, fx_lift=True,
    ink_bg={},
    figs={"fig_heroi": dict(w=0.9), "fig_muralha": dict(detail=False, w=1.0), "fig_caldeirao": dict(detail=False, w=1.0)},
))
