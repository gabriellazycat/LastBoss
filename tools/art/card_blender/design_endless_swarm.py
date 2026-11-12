"""Enxame Sem Fim (endless_swarm): acabamento calcado de docs/arte_cartas/praga_3/comp/endless_swarm.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("endless_swarm", "praga_3", dict(
    enx_w=0.7,
    figs={"fig_heroi": dict(detail=False, w=0.7)},
))
