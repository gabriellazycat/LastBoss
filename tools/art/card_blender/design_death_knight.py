"""death_knight: acabamento calcado de docs/arte_cartas/lich_1/comp/death_knight.svg (osso em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("death_knight", "lich_1", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_arco": 1.0},
    bg_lift=[r"bg_lua.*"],
    figs={"fig_cavaleiro": dict(w=1.1, lift=["cavaleiro_espada"])},
))
