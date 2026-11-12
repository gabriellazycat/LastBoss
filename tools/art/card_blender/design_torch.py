"""Tocha (torch): acabamento calcado de docs/arte_cartas/dragao_1/comp/torch.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("torch", "dragao_1", dict(
    fx_alpha=1.35, fx_lift=True,
    ink_bg={r"bg_casa": 1.0, r"bg_telhado": 0.8},
    bg_lift=[r"bg_fogo_casad"],
    figs={"fig_heroi": dict(w=0.9), "fig_tocha": dict(detail=False, w=0.9), "fig_tocha_chama": dict(detail=False, w=0.5, lift=["tocha_chama_chama"])},
))
