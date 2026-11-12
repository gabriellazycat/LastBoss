"""Ratoeira Viva (rat_trap): acabamento calcado de docs/arte_cartas/praga_1/comp/rat_trap.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("rat_trap", "praga_1", dict(
    enx_w=0.75,
    figs={"fig_heroi": dict(dark=0.5, detail=False, w=0.9),
          "fig_ratoeira": dict(w=1.1)},
))
