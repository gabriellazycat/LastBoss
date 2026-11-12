"""Mercenario Goblin (gold_merc): acabamento calcado de docs/arte_cartas/dragao_2/comp/gold_merc.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("gold_merc", "dragao_2", dict(
    fx_alpha=1.35, fx_lift=True,
    ink_bg={},
    bg_lift=[r"bg_halo.*"],
    figs={"fig_goblin": dict(w=1.0)},
))
