"""Flautista Corrompido (corrupt_piper): acabamento calcado de docs/arte_cartas/praga_3/comp/corrupt_piper.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("corrupt_piper", "praga_3", dict(
    ink_bg={r"bg_torre": 1.0, r"bg_torre_teto": 0.8, r"bg_arco_portao": 0.9, r"bg_pedra\d": 0.5},
    enx_w=0.75,
))
