"""shadow_bolt: acabamento calcado de docs/arte_cartas/lich_2/comp/shadow_bolt.svg (magia e sombra em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("shadow_bolt", "lich_2", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_arco": 1.0},
    bg_lift=[r"bg_arco_luz"],
    figs={"fig_heroi": dict(w=1.0), "fig_raio": dict(w=0.8, lift=["raio_raio"])},
))
