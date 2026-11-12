"""Base do gerador do lote praga_2: reaproveita geom/rat/hero do lote praga_1 (sem editá-los)."""
import sys
P1 = "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/praga_1/comp/_gerador"
P2 = "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/praga_2/comp/_gerador"
for p in (P2, P1):
    if p not in sys.path:
        sys.path.insert(0 if p == P2 else 1, p)
