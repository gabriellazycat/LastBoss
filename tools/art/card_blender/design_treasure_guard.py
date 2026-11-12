"""Guarda do Tesouro (treasure_guard): acabamento calcado de docs/arte_cartas/dragao_2/comp/treasure_guard.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("treasure_guard", "dragao_2", dict(
    fx_alpha=1.35, fx_lift=True,
    ink_bg={},
    bg_lift=[r"bg_halo.*", r"bg_monte_luz", r"bg_monte_moeda_luz", r"bg_taca_luz"],
    figs={"fig_guardiao": dict(w=1.0)},
))
