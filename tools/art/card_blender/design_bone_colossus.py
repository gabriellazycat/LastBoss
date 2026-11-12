"""bone_colossus: acabamento calcado de docs/arte_cartas/lich_1/comp/bone_colossus.svg (osso em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("bone_colossus", "lich_1", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_capela": 1.0, r"bg_capela_torre": 1.0},
    bg_lift=[r"bg_lua.*", r"bg_capela_janela"],
    enx_w=0.6,
    figs={"fig_colosso": dict(w=1.2, lift=["colosso_corpo", "colosso_cabeca"])},
))
