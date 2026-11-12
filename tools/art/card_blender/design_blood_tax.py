"""blood_tax: acabamento calcado de docs/arte_cartas/dragao_3/comp/blood_tax.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("blood_tax", "dragao_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_altar": 1.0, r"bg_altar_tampo": 0.8, r"bg_taca_pe": 0.9, r"bg_taca": 1.0},
    bg_lift=[r"bg_taca_luz", r"bg_taca_sangue"],
    figs={"fig_heroi": dict(w=0.9)},
))
