"""Toca de Ratos (rat_burrow): acabamento calcado da composição docs/arte_cartas/praga_1/comp/rat_burrow.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("rat_burrow", "praga_1", dict(
    ink_bg={r"bg_monte": 1.1, r"bg_buraco_borda": 0.9, r"bg_tabua2?": 0.7},
    enx_w=0.75,
))
