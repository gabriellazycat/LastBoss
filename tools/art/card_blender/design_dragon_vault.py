"""dragon_vault: acabamento calcado de docs/arte_cartas/dragao_3/comp/dragon_vault.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("dragon_vault", "dragao_3", dict(
    enx_w=0.7, fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_rocha": 1.0, r"bg_aro": 1.0, r"bg_aro_ferro": 1.0},
    bg_lift=[r"bg_monte.*", r"bg_porta_luz"],
    figs={"fig_kobold": dict(w=1.0)},
))
