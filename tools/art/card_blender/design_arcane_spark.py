"""arcane_spark: acabamento calcado de docs/arte_cartas/lich_2/comp/arcane_spark.svg (magia e sombra em guache sobre noite azulada)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("arcane_spark", "lich_2", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_pilar": 1.0, r"bg_capitel": 1.0},
    bg_lift=[r"bg_pilar_luz"],
    figs={"fig_heroi": dict(w=1.0), "fig_impacto": dict(w=0.8, lift=["impacto_impacto"])},
))
