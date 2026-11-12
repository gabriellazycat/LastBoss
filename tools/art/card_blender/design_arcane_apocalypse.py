"""arcane_apocalypse: acabamento calcado de docs/arte_cartas/lich_2/comp/arcane_apocalypse.svg (magia e sombra em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("arcane_apocalypse", "lich_2", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_morro": 1.0, r"bg_torre": 1.0},
    bg_lift=[r"bg_halo.*", r"bg_torre_luz", r"bg_torre_janela"],
    recolor={r"lich_manto": "#120c22", r"lich_olho": "#46d890", r"lich_gema": "#3fcf8c"},
    figs={"fig_lich": dict(w=1.1, lift=["lich_corpo"], solid=["lich_corpo"], rim=dict(dirs=[(1, -0.3), (-1, -0.3), (0, -1)], alpha=0.85, w=2.0))},
))
