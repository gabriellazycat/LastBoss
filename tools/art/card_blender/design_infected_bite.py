"""Mordida Infectada (infected_bite): acabamento calcado de docs/arte_cartas/praga_3/comp/infected_bite.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("infected_bite", "praga_3", dict(
    ink_bg={r"bg_arvore": 1.0},
    figs={"fig_heroi": dict(detail=False, w=0.85)},
))
