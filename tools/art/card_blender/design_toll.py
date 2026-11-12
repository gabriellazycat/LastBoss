"""Pedagio (toll): acabamento calcado de docs/arte_cartas/dragao_2/comp/toll.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("toll", "dragao_2", dict(
    fx_alpha=1.7,
    ink_bg={r"bg_poste": 1.0, r"bg_caixa": 1.0, r"bg_caixa_tampa": 0.8, r"bg_cadeado": 0.7},
    figs={"fig_heroi": dict(w=0.9), "fig_cancela": dict(detail=False, w=1.0)},
))
