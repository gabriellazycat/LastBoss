"""Javali de Guerra (war_boar): acabamento calcado de docs/arte_cartas/praga_2/comp/war_boar.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("war_boar", "praga_2", dict(
    ink_bg={r"bg_estaca\d": 0.9},
    figs={"fig_heroi": dict(detail=False, w=0.9)},
))
