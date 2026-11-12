"""Mimico (mimic): acabamento calcado de docs/arte_cartas/dragao_2/comp/mimic.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("mimic", "dragao_2", dict(
    fx_alpha=1.35, fx_lift=True,
    ink_bg={r"bg_pilar": 1.0},
    bg_lift=[r"bg_luz_tocha.*", r"bg_moeda_chao_luz", r"bg_chao_luz", r"bg_pilar_luz"],
    figs={"fig_mimico": dict(w=1.0)},
))
