"""Balde de Oleo (oil_splash): acabamento calcado de docs/arte_cartas/dragao_1/comp/oil_splash.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("oil_splash", "dragao_1", dict(
    fx_alpha=1.35, fx_lift=True,
    ink_bg={r"bg_portao": 1.1, r"bg_tabua\d": 0.5},
    figs={"fig_heroi": dict(w=0.9), "fig_balde": dict(detail=False, w=1.0)},
))
