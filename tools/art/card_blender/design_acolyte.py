"""acolyte: acabamento calcado de docs/arte_cartas/lich_2/comp/acolyte.svg (magia e sombra em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("acolyte", "lich_2", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_vitral_moldura": 1.0, r"bg_vitral_mainel": 0.8, r"bg_vitral_travessa": 0.8},
    bg_lift=[r"bg_vitral", r"bg_vitral_luz"],
    figs={"fig_acolito": dict(w=1.1), "fig_acolito_b": dict(w=0.9)},
))
