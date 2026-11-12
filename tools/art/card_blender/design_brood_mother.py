"""Mae da Ninhada (brood_mother): acabamento calcado de docs/arte_cartas/praga_2/comp/brood_mother.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("brood_mother", "praga_2", dict(
    ink_bg={r"bg_ninho": 1.1, r"bg_ninho_trapo2?": 0.8},
    enx_w=0.75,
))
