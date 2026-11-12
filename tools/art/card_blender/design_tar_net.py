"""tar_net: acabamento calcado de docs/arte_cartas/dragao_3/comp/tar_net.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("tar_net", "dragao_3", dict(
    holes_open=True, ink_bg={r"bg_toco": 1.0},
    bg_lift=[r"bg_poca_brilho"],
    figs={"fig_heroi": dict(w=0.9), "fig_rede": dict(w=1.1)},
))
