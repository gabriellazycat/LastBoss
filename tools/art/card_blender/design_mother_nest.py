"""Ninho-Mae (mother_nest): acabamento calcado de docs/arte_cartas/praga_3/comp/mother_nest.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("mother_nest", "praga_3", dict(
    ink_bg={r"bg_ninho": 1.1, r"bg_trapo2?": 0.8, r"bg_osso\d": 0.6, r"bg_toca_borda": 0.9},
    enx_w=0.75,
))
