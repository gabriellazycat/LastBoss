"""burn_village: acabamento calcado de docs/arte_cartas/dragao_3/comp/burn_village.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("burn_village", "dragao_3", dict(
    fx_alpha=1.35, fx_lift=True, fx_hold=True, holes_open=True,
    ink_bg={r"bg_casa1_parede": 0.9, r"bg_casa2_parede": 0.9},
    bg_lift=[r"bg_casa\d_janela"],
    figs={"fig_heroi": dict(w=0.9, dark=0.4)},
))
