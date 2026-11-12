"""Ratazana (rat_brute): acabamento calcado de docs/arte_cartas/praga_1/comp/rat_brute.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("rat_brute", "praga_1", dict(
    ink_bg={r"bg_cano_boca": 1.1, r"bg_lodo": 0.8, r"bg_poca": 0.6},
))
