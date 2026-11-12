"""Faisca (spark): acabamento calcado de docs/arte_cartas/dragao_1/comp/spark.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("spark", "dragao_1", dict(
    fx_alpha=1.35, fx_lift=True,
    ink_bg={r"bg_estaca\d": 0.7, r"bg_travessa2?": 0.7},
    figs={"fig_heroi": dict(w=0.9), "fig_heroi2": dict(w=0.9)},
))
