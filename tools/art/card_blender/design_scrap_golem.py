"""scrap_golem: acabamento calcado de docs/arte_cartas/lich_3/comp/scrap_golem.svg (guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("scrap_golem", "lich_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_catapulta_.*": 1.0, r"bg_lanca\d*": 0.9},
    bg_lift=[r"bg_nevoa_luz\d*", r"bg_ceu\d*"],
    figs={"fig_golem": dict(w=1.2, rim=dict(dirs=[(-1, -0.3)], alpha=0.6, w=1.5)), "fig_esqueleto": dict(w=0.9, lift=["esqueleto_corpo", "esqueleto_cabeca"])},
))
