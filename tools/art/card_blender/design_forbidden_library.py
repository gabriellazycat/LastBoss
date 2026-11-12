"""forbidden_library: acabamento calcado de docs/arte_cartas/lich_2/comp/forbidden_library.svg (magia e sombra em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("forbidden_library", "lich_2", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_arco": 1.0, r"bg_pulpito": 1.0},
    bg_lift=[r"bg_vao_luz", r"bg_pulpito_luz"],
    figs={"fig_cultista": dict(w=1.1, rim=dict(dirs=[(1, 0.3)], alpha=0.6)), "fig_grimorio": dict(w=0.9, lift=["grimorio_livro"]), "fig_livro": dict(w=1.1)},
))
