"""Moedas Amaldicoadas (cursed_coins): acabamento calcado de docs/arte_cartas/dragao_2/comp/cursed_coins.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("cursed_coins", "dragao_2", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_arvore": 1.0, r"bg_galho.*": 0.8},
    bg_lift=[r"bg_moeda_chao_luz"],
    figs={"fig_heroi": dict(w=0.9)},
))
