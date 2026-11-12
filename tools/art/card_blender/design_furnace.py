"""furnace: acabamento calcado de docs/arte_cartas/dragao_3/comp/furnace.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("furnace", "dragao_3", dict(
    fx_alpha=0.4,
    ink_bg={r"bg_chamine": 1.0, r"bg_cupula": 1.0, r"bg_boca_arco": 1.0},
    bg_lift=[r"bg_boca", r"bg_boca_centro", r"bg_chamine_luz", r"bg_cupula_luz"],
    figs={"fig_goblin": dict(w=1.0), "fig_goblin2": dict(w=0.8, detail=False)},
))
