"""Praga Bubonica (bubonic_plague): acabamento calcado de docs/arte_cartas/praga_3/comp/bubonic_plague.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("bubonic_plague", "praga_3", dict(
    ink_bg={r"bg_porta": 1.1, r"bg_tabua\d": 0.5},
    enx_w=0.75,
    figs={"fig_heroi": dict(detail=False, w=0.9)},
))
