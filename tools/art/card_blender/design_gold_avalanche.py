"""gold_avalanche: acabamento calcado de docs/arte_cartas/dragao_3/comp/gold_avalanche.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("gold_avalanche", "dragao_3", dict(
    fx_alpha=1.35, fx_lift=True, fx_hold=True, holes_open=True,
    ink_bg={r"bg_rocha": 1.0, r"bg_estalactite\d": 0.9},
    figs={"fig_heroi": dict(w=0.9), "fig_ouro": dict(w=1.0, lift=["ouro_massa"])},
))
