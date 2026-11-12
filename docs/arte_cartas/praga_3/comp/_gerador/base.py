"""Base do gerador do lote praga_3: reaproveita geom/rat/hero (praga_1) e wolf/bat/fichas_lib/render (praga_2), só leitura.

Pastas de saída e de rascunho por variável de ambiente (para o próximo lote reusar):
  LB_OUT  (padrão: docs/arte_cartas/praga_3/comp)
  LB_SCR  (padrão: scratchpad/comp_praga_3)
"""
import os, sys
P1 = "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/praga_1/comp/_gerador"
P2 = "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/praga_2/comp/_gerador"
P3 = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
for p in (P1, P2, P3):
    if p in sys.path:
        sys.path.remove(p)
    sys.path.insert(0, p)  # ordem final: P3, P2, P1

OUT = os.environ.get("LB_OUT", "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/praga_3/comp")
SCR = os.environ.get("LB_SCR", "C:/Users/gabri/AppData/Local/Temp/claude/df0eb8c5d2d2aad7/388ffdb7-a033-4c30-8855-5da64eb88778/scratchpad/comp_praga_3")
FICH = "C:/Users/gabri/Desktop/LastBoss/tools/art/card_blender/fichas"
os.makedirs(SCR, exist_ok=True)

import render  # noqa: E402  (render do praga_2; o html temporário vai para o NOSSO rascunho)
render.SCR = SCR
