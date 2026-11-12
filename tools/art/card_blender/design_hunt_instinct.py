"""Instinto de Caca (hunt_instinct): acabamento calcado de docs/arte_cartas/praga_2/comp/hunt_instinct.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("hunt_instinct", "praga_2", dict(
    figs={"fig_heroi": dict(w=1.0)},
))
