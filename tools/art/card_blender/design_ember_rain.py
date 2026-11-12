"""Chuva de Brasas (ember_rain): acabamento calcado de docs/arte_cartas/dragao_1/comp/ember_rain.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("ember_rain", "dragao_1", dict(
    fx_alpha=1.35, fx_lift=True,
    ink_bg={},
    figs={"fig_dragao": dict(w=1.0), "fig_heroi": dict(w=0.9)},
))
