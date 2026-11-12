"""Horda de Ratos (rat_horde): acabamento calcado de docs/arte_cartas/praga_1/comp/rat_horde.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("rat_horde", "praga_1", dict(
    ink_bg={r"bg_tunel_anel": 1.1, r"bg_tunel_boca": 0.7},
    enx_w=0.75,
    figs={"fig_corredor": dict(dark=0.2, dark_color="#2a1a10", detail=False)},
))
