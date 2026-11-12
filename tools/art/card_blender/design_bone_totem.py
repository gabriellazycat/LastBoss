"""bone_totem: acabamento calcado de docs/arte_cartas/lich_1/comp/bone_totem.svg (osso em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("bone_totem", "lich_1", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_aura": 0.0},
    bg_lift=[r"bg_lua.*", r"bg_aura"],
    figs={"fig_totem": dict(w=1.1, lift=["totem_totem"]),
          "fig_erguido": dict(w=1.0, lift=["erguido_corpo", "erguido_cabeca"]),
          "fig_erguido2": dict(w=0.9, lift=["erguido2_corpo", "erguido2_cabeca"])},
))
