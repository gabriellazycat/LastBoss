"""Maré de Ratos (rat_tide): acabamento calcado de docs/arte_cartas/praga_1/comp/rat_tide.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("rat_tide", "praga_1", dict(
    ink_bg={r"bg_muro": 0.8},
    enx_w=0.75, enx_w_by={"enxame_onda": 1.3},
    figs={"fig_heroi": dict(detail=False, w=0.85)},
))
