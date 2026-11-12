"""Devorar (devour): acabamento calcado de docs/arte_cartas/praga_3/comp/devour.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("devour", "praga_3", dict(
    ink_bg={r"bg_altar": 1.1, r"bg_altar_topo": 0.8, r"bg_osso\d": 0.6},
    enx_w=0.6,
))
