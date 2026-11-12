"""Lobisomem (werewolf): acabamento calcado de docs/arte_cartas/praga_2/comp/werewolf.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("werewolf", "praga_2", dict(
    figs={"fig_heroi": dict(detail=False, w=0.9)},
))
