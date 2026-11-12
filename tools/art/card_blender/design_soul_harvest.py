"""soul_harvest: acabamento calcado de docs/arte_cartas/lich_3/comp/soul_harvest.svg (guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("soul_harvest", "lich_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_ampulheta_(haste|tampa)\d*": 1.0, r"bg_ampulheta_vidro": 0.8},
    bg_lift=[r"bg_ampulheta_halo\d*", r"bg_ampulheta_vidro", r"bg_ampulheta_areia_.*"],
    figs={"fig_heroi": dict(w=1.0), "fig_esqueleto": dict(w=0.9)},
))
