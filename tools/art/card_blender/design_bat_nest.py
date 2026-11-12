"""Ninho de Morcegos (bat_nest): acabamento calcado de docs/arte_cartas/praga_2/comp/bat_nest.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("bat_nest", "praga_2", dict(
    ink_bg={r"bg_tronco": 1.1, r"bg_oco_borda": 0.9},
    enx_w=0.75, enx_rim=dict(grow=1.7, color="#f3dcb8", warm="#a8684a"),
))
