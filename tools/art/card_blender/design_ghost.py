"""ghost: acabamento calcado de docs/arte_cartas/lich_3/comp/ghost.svg (guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("ghost", "lich_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    fx_keep_op=[r"fx_onda_parede\d*"],
    ink_bg={r"bg_parede": 1.0, r"bg_junta_.*": 0.35, r"bg_vitral_moldura": 0.8, r"bg_parede_quina": 0.8},
    bg_lift=[r"bg_vitral_halo\d*", r"bg_raio_luz", r"bg_parede_luz", r"bg_chao_luz"],
    figs={"fig_fantasma": dict(w=1.0, lift=["fantasma_corpo", "fantasma_cabeca"])},
))
