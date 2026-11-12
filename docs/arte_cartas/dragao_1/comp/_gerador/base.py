"""Base do gerador do lote dragao_1: reaproveita (só leitura) geom/rat/hero (praga_1), cartas/render/fichas_lib (praga_2)
e cartas3/piper (praga_3). Pastas por variável de ambiente (para o próximo lote reusar):
  LB_OUT  (padrão: docs/arte_cartas/dragao_1/comp)
  LB_SCR  (padrão: scratchpad/comp_dragao_1)
"""
import os, sys
ROOT = "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas"
P1, P2, P3 = (f"{ROOT}/praga_{i}/comp/_gerador" for i in (1, 2, 3))
D1 = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
for p in (P1, P2, P3, D1):
    if p in sys.path:
        sys.path.remove(p)
    sys.path.insert(0, p)  # ordem final: D1, P3, P2, P1

OUT = os.environ.get("LB_OUT", f"{ROOT}/dragao_1/comp")
SCR = os.environ.get("LB_SCR", "C:/Users/gabri/AppData/Local/Temp/claude/df0eb8c5d2d2aad7/388ffdb7-a033-4c30-8855-5da64eb88778/scratchpad/comp_dragao_1")
FICH = "C:/Users/gabri/Desktop/LastBoss/tools/art/card_blender/fichas"
os.makedirs(SCR, exist_ok=True)
os.environ["LB_OUT"] = OUT; os.environ["LB_SCR"] = SCR  # o base do praga_3 (importado por cartas3) lê daqui

import render  # noqa: E402
render.SCR = SCR
