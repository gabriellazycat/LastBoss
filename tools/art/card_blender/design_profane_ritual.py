"""profane_ritual: acabamento calcado de docs/arte_cartas/lich_3/comp/profane_ritual.svg (guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("profane_ritual", "lich_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_altar": 1.0, r"bg_altar_topo": 0.8},
    bg_lift=[r"bg_fundo_luz", r"bg_fogo_halo\d*", r"bg_circulo_anel\d*", r"bg_pentagrama"],
    figs={"fig_heroi": dict(w=1.0, rim=dict(dirs=[(1, 0.2)], alpha=0.7, w=1.5)), "fig_sacrificado": dict(w=1.0)},
))
