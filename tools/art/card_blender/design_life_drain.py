"""life_drain: acabamento calcado de docs/arte_cartas/lich_3/comp/life_drain.svg (guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("life_drain", "lich_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_coluna": 1.0, r"bg_coluna_junta\d*": 0.7},
    bg_lift=[r"bg_nevoa_luz\d*", r"bg_coluna_luz"],
    figs={"fig_heroi": dict(w=1.0), "fig_carnical": dict(w=1.0)},
))
