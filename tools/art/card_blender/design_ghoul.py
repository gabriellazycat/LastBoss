"""ghoul: acabamento calcado de docs/arte_cartas/lich_1/comp/ghoul.svg (osso em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("ghoul", "lich_1", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_lapide": 1.0, r"bg_arvore": 1.0},
    bg_lift=[r"bg_lua.*", r"bg_lapide_luz"],
    recolor={r"carnical_olho_[lr]": "#f2c01c"},
    figs={"fig_carnical": dict(w=1.0, lift=["carnical_corpo", "carnical_cabeca"])},
))
