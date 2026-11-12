"""Erupcao (eruption): acabamento calcado de docs/arte_cartas/dragao_1/comp/eruption.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("eruption", "dragao_1", dict(
    fx_alpha=1.35, fx_lift=True, fx_hold=True,
    ink_bg={r"bg_vulcao": 1.0},
    bg_lift=[r"bg_lava_vulcao", r"bg_coluna_fogo", r"bg_rachad"],
    figs={"fig_heroi": dict(w=0.9)},
))
