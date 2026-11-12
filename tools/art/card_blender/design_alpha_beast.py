"""Besta Alfa (alpha_beast): acabamento calcado de docs/arte_cartas/praga_2/comp/alpha_beast.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("alpha_beast", "praga_2", dict(
    ink_bg={r"bg_rocha": 1.1},
    enx_w=0.75,
))
