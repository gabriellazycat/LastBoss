"""Goblin Dinamiteiro (goblin_dynamiter): acabamento calcado de docs/arte_cartas/dragao_1/comp/goblin_dynamiter.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("goblin_dynamiter", "dragao_1", dict(
    ink_bg={r"bg_aldeia": 1.0},
    bg_lift=[r"bg_fogo_aldeiad"],
    enx_w=0.7,
    figs={"fig_goblin": dict(w=1.0), "fig_heroi": dict(detail=False, w=0.8)},
))
