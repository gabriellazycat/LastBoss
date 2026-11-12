"""Chamado do Bando (pack_call): acabamento calcado de docs/arte_cartas/praga_1/comp/pack_call.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("pack_call", "praga_1", dict(
    ink_bg={r"bg_estrada": 0.8},
    enx_w=0.75,
    figs={"fig_heroi": dict(dark=0.5, detail=False, w=0.85)},
))
