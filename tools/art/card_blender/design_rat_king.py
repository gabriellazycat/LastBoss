"""Rei dos Ratos (rat_king): acabamento calcado de docs/arte_cartas/praga_1/comp/rat_king.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("rat_king", "praga_1", dict(
    ink_bg={r"bg_osso\d": 0.6, r"bg_assento": 0.9, r"bg_assento_tampo": 0.7, r"bg_caveira\d": 0.6},
    enx_w=0.75,
    figs={"fig_rei": dict(
        split={"rei_gola": ["rei_gola", "rei_broche"], "rei_mao": ["rei_braco_mao", "rei_braco_dedo"]},
        order=["rei_manto", "rei_corpo", "rei_cetro", "rei_mao", "rei_gola", "rei_cabeca", "rei_coroa"],
        solid=["rei_coroa"])},
))
