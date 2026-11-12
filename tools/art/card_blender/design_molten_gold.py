"""Ouro Derretido (molten_gold): acabamento calcado de docs/arte_cartas/dragao_2/comp/molten_gold.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("molten_gold", "dragao_2", dict(
    fx_alpha=1.35, fx_lift=True, fx_hold=True,
    ink_bg={r"bg_rocha": 1.0},
    bg_lift=[r"bg_poca_brilho", r"bg_poca_luz", r"bg_rocha_luz"],
    figs={"fig_heroi": dict(w=0.9), "fig_ouro": dict(detail=False, w=1.0)},
))
