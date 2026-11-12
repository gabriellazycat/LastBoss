"""shadow_echo: acabamento calcado de docs/arte_cartas/lich_2/comp/shadow_echo.svg (magia e sombra em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("shadow_echo", "lich_2", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    fx_keep_op=[r"fx_original_.*"],
    ink_bg={r"bg_lapide": 1.0, r"bg_lapide_cruz2?": 0.8},
    bg_lift=[r"bg_lapide_luz"],
    figs={"fig_heroi": dict(w=1.0)},
))
