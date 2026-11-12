"""Esgoto Transbordante (sewer_flood): acabamento calcado de docs/arte_cartas/praga_3/comp/sewer_flood.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("sewer_flood", "praga_3", dict(
    ink_bg={r"bg_boca_anel": 1.1, r"bg_boca": 0.7, r"bg_grade\d": 0.8},
    enx_w=0.75,
))
