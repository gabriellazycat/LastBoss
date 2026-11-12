"""Nuvem de Morcegos (bat_cloud): acabamento calcado de docs/arte_cartas/praga_2/comp/bat_cloud.svg."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from praga_common import build

build("bat_cloud", "praga_2", dict(
    ink_bg={r"bg_muralha": 1.0, r"bg_merlao\d": 0.7, r"bg_estaca\d+": 0.8},
    enx_w=0.6,
))
