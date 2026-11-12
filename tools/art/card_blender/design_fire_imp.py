"""Diabretes de Fogo (fire_imp): acabamento calcado de docs/arte_cartas/dragao_1/comp/fire_imp.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("fire_imp", "dragao_1", dict(
    fx_alpha=1.35, fx_lift=True,
    ink_bg={r"bg_torre": 1.0, r"bg_ameias": 0.7},
    figs={"fig_diabrete": dict(w=1.0), "fig_diabrete2": dict(w=0.9, lift=["diabrete2_fogo"])},
))
