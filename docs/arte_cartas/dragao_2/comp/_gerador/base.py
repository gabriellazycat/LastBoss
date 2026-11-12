"""Base do gerador do lote dragao_2: reaproveita (só leitura) praga_1/2/3 e dragao_1.
Pastas por variável de ambiente (para o próximo lote reusar):
  LB_OUT  (padrão: docs/arte_cartas/dragao_2/comp)
  LB_SCR  (padrão: scratchpad/comp_dragao_2)
"""
import os, sys
ROOT = "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas"
P1, P2, P3 = (f"{ROOT}/praga_{i}/comp/_gerador" for i in (1, 2, 3))
D1 = f"{ROOT}/dragao_1/comp/_gerador"
D2 = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
for p in (P1, P2, P3, D1, D2):
    if p in sys.path:
        sys.path.remove(p)
    sys.path.insert(0, p)  # ordem final: D2, D1, P3, P2, P1

OUT = os.environ.get("LB_OUT", f"{ROOT}/dragao_2/comp")
SCR = os.environ.get("LB_SCR", "C:/Users/gabri/AppData/Local/Temp/claude/df0eb8c5d2d2aad7/388ffdb7-a033-4c30-8855-5da64eb88778/scratchpad/comp_dragao_2")
FICH = "C:/Users/gabri/Desktop/LastBoss/tools/art/card_blender/fichas"
os.makedirs(SCR, exist_ok=True)
os.environ["LB_OUT"] = OUT; os.environ["LB_SCR"] = SCR

import render  # noqa: E402
render.SCR = SCR
