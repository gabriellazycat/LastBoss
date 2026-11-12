"""Matilha de Lobos (wolf_pack): acabamento calcado de docs/arte_cartas/praga_2/comp/wolf_pack.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("wolf_pack", "praga_2", dict(
    ink_bg={r"bg_pinheiro\d": 0.8},
    figs={"fig_lobo3": dict(detail=False, w=0.9), "fig_lobo2": dict(w=1.0)},
))
