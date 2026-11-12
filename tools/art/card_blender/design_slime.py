"""Slime (slime): acabamento calcado de docs/arte_cartas/praga_3/comp/slime.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("slime", "praga_3", dict(
    ink_bg={r"bg_arco": 1.1, r"bg_boca": 0.7},
    enx_w=0.7,
    figs={"fig_slime": dict(w=1.0)},
))
