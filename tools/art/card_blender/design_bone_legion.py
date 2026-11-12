"""bone_legion: acabamento calcado de docs/arte_cartas/lich_1/comp/bone_legion.svg (osso em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("bone_legion", "lich_1", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_pilar\d": 1.0, r"bg_pilar_topo\d": 0.9, r"bg_grade\d": 0.8, r"bg_grade_trave": 0.8},
    bg_lift=[r"bg_lua.*", r"bg_portal_luz"],
    enx_w=0.6,
    figs={"fig_esqueleto": dict(w=1.0, lift=["esqueleto_corpo", "esqueleto_cabeca", "esqueleto_espada"])},
))
