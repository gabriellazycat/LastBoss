"""Base do gerador do lote comuns_1 (cartas neutras): reaproveita (só leitura) praga_1/2/3, dragao_1/2/3 e lich_1/2.
(lich_3 NÃO entra no sys.path: estava sendo composto em paralelo.)
Pastas por variável de ambiente (para o próximo lote reusar):
  LB_OUT  (padrão: docs/arte_cartas/comuns_1/comp)
  LB_SCR  (padrão: scratchpad/comp_comuns_1)
  LB_FICH (padrão: tools/art/card_blender/fichas)
Este base.py fica primeiro no sys.path. Módulos deste lote têm sufixo _c1 (brutos_c1, gargula_c1, hero_c1, cartas_c1,
fichas_c1, folha_c1) para não colidir com os de outros lotes."""
import os, sys
ROOT = "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas"
P1, P2, P3 = (f"{ROOT}/praga_{i}/comp/_gerador" for i in (1, 2, 3))
D1, D2, D3 = (f"{ROOT}/dragao_{i}/comp/_gerador" for i in (1, 2, 3))
L1, L2 = (f"{ROOT}/lich_{i}/comp/_gerador" for i in (1, 2))
C1 = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
for p in (P1, P2, P3, D1, D2, D3, L1, L2, C1):
    if p in sys.path:
        sys.path.remove(p)
    sys.path.insert(0, p)  # ordem final: C1, L2, L1, D3, D2, D1, P3, P2, P1

OUT = os.environ.get("LB_OUT", f"{ROOT}/comuns_1/comp")
SCR = os.environ.get("LB_SCR", "C:/Users/gabri/AppData/Local/Temp/claude/df0eb8c5d2d2aad7/388ffdb7-a033-4c30-8855-5da64eb88778/scratchpad/comp_comuns_1")
FICH = os.environ.get("LB_FICH", "C:/Users/gabri/Desktop/LastBoss/tools/art/card_blender/fichas")
os.makedirs(SCR, exist_ok=True)
os.environ["LB_OUT"] = OUT; os.environ["LB_SCR"] = SCR

import render  # noqa: E402
render.SCR = SCR
