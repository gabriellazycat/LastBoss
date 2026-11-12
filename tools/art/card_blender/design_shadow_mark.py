"""shadow_mark: acabamento calcado de docs/arte_cartas/lich_2/comp/shadow_mark.svg (magia e sombra em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("shadow_mark", "lich_2", dict(
    fx_alpha=0.9, fx_lift=True, holes_open=True,
    ink_bg={r"bg_degrau[12]": 1.0},
    bg_lift=[r"bg_degrau2_luz"],
    figs={"fig_heroi": dict(w=1.0), "fig_marca": dict(w=0.8, lift=["marca_marca"])},
))
