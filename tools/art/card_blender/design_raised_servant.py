"""raised_servant: acabamento calcado de docs/arte_cartas/lich_1/comp/raised_servant.svg (osso em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("raised_servant", "lich_1", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_cova_borda": 1.0, r"bg_cruz": 0.9, r"bg_pa": 0.8},
    bg_lift=[r"bg_chao_luz"],
    figs={"fig_servo": dict(w=1.0, lift=["servo_corpo", "servo_cabeca"])},
))
