"""Isca de Ouro (gold_bait): acabamento calcado de docs/arte_cartas/dragao_2/comp/gold_bait.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("gold_bait", "dragao_2", dict(
    fx_alpha=1.7, fx_lift=True,
    ink_bg={r"bg_placa.*": 1.0, r"bg_estrada": 0.6},
    bg_lift=[r"bg_trilha_luz"],
    figs={"fig_heroi": dict(w=0.9)},
))
