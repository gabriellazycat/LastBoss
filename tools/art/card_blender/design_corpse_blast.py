"""corpse_blast: acabamento calcado de docs/arte_cartas/lich_1/comp/corpse_blast.svg (osso em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("corpse_blast", "lich_1", dict(
    fx_alpha=1.35, fx_lift=True, fx_hold=True, holes_open=True,
    ink_bg={r"bg_lapide": 1.0},
    bg_lift=[r"bg_clarao2?", r"bg_lapide_luz"],
    figs={"fig_heroi": dict(w=0.9)},
))
