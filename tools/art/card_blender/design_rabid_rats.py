"""Ratos Raivosos (rabid_rats): acabamento calcado de docs/arte_cartas/praga_1/comp/rabid_rats.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("rabid_rats", "praga_1", dict(
    ink_bg={r"bg_buraco_borda": 1.0, r"bg_buraco": 0.7, r"bg_rachadura\d": 0.8},
    enx_w=0.75,
))
