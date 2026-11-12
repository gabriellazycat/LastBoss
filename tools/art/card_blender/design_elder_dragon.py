"""elder_dragon: acabamento calcado de docs/arte_cartas/dragao_3/comp/elder_dragon.svg (corpo em vermelho saturado, guache)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("elder_dragon", "dragao_3", dict(
    fx_alpha=1.35, fx_lift=True, holes_open=True,
    ink_bg={r"bg_torre": 1.0, r"bg_ameias": 0.9},
    bg_lift=[r"bg_torre_luz", r"bg_janela"],
    recolor={r"dragao_(tronco|pescoco|cranio|pata_frente_l|pata_frente_l_mao|asa_r_braco)": "#c02a18",
             r"dragao_(cauda|perna_tras.*)": "#9a2014",
             r"dragao_mandibula": "#d63c22", r"dragao_asa_r": "#b02616",
             r"dragao_asa_l(_braco)?": "#4a1010",
             r"dragao_(barriga|pescoco_placas)": "#f0b858",
             r"bg_ceu[0-5]?": "#f08a3c"},
    figs={"fig_dragao": dict(w=1.6, order=["dragao_asa_l", "dragao_corpo", "dragao_asa_r", "dragao_cabeca"],
                             lift=["dragao_corpo", "dragao_cabeca", "dragao_asa_r"])},
))
