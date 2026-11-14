"""Rodada 9 (13/11/2026): 3 estilos novos a partir do A1 (pincel_grosso_a.py).

Diretrizes do designer (13/11): mesma pose e mesma quantidade de elementos do A1; pincel largo; nada de detalhe
miúdo (fivela, joias, enfeites da coroa); Patrulheiro com menos detalhe e sombra simples; guache leve; nunca
cartunesco; sem destoar do resto do jogo.

python -I a1_variacoes.py
Saída: arte_ia/a1_variacoes/<card>/<v>.png (com grão 0,9); prancha arte_ia/pranchas/a1_variacoes.png
"""
import os, sys, zlib
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as gm
import pincel_grosso as pg, pincel_grosso_a as pa, esponja_ia as ei
from deck import crop_final, MODEL, W, H, GRAIN

OUT = os.path.join(gen.ROOT, "a1_variacoes")
DEN = {"rat_king": 0.5, "elder_dragon": 0.5, "ranger": 0.6}     # Patrulheiro: mais força para perder o miúdo
TONE = "Grounded serious fantasy book illustration with natural proportions."
PAPER = "paper texture showing through, muted dusty colors, slightly blurry low-resolution scan."
VARIANTS = {
    "V1": ("Pôster duas tintas",
           "A flat gouache poster painting on rough paper, scanned from an old sketchbook: ",
           "Painted with a wide flat brush, every shape one flat color with a single darker shadow tone, crisp "
           "simple edges between big color areas, small parts merged into the big shapes, eyes as one small dark "
           "dot, " + PAPER),
    "V2": ("Guache leve aguado",
           "A light gouache painting on rough watercolor paper, scanned from an old sketchbook: ",
           "Thin light gouache laid quickly with a wide flat brush, lighter airy values, soft edges where colors "
           "meet, the white of the paper glowing through the thinner strokes, large simple shapes, one soft shadow "
           "tone, eyes as one small dark dot, " + PAPER),
    "V3": ("Contorno solto + chapado",
           "A gouache illustration on rough paper, scanned from an old sketchbook: ",
           "Each figure surrounded by one loose dark brown brush outline of even thickness, filled with flat "
           "gouache laid with a wide flat brush, one flat shadow tone per color, large simple shapes, eyes as one "
           "small dark dot, " + PAPER),
}


def make(card, v, seed=1000):
    _, medium, texture = VARIANTS[v]
    bg, subj = ei.SUBJ[card]
    p = f"{medium}{subj} A plain flat {gen.BACKGROUNDS[bg]} sky behind. {TONE} {texture}"
    init = gen.upload_image(os.path.join(pa.OUT, card, "A1_raw.png"))
    g, _ = gen.workflow(MODEL, p, seed, W, H, init_image=init, denoise=DEN[card])
    d = os.path.join(OUT, card)
    os.makedirs(d, exist_ok=True)
    raw = os.path.join(d, f"{v}_raw.png")
    open(raw, "wb").write(gen.run(g))
    gp = raw.replace("_raw", "_grain")
    gm.grain(Image.open(raw), seed=zlib.crc32(f"{card}{v}".encode()), strength=GRAIN).save(gp)
    crop_final(gp, os.path.join(d, f"{v}.png"))
    open(os.path.join(d, f"{v}.txt"), "w", encoding="utf-8").write(f"denoise {DEN[card]}\n{p}\n")
    print(card, v, flush=True)


if __name__ == "__main__":
    for c in pa.SUBJ:
        for v in VARIANTS:
            make(c, v)
    rows = [(c, [(f"{pa.NAMES[c]} · A1", os.path.join(pa.OUT, c, "A1.png"))] +
             [(f"{v}. {VARIANTS[v][0]}", os.path.join(OUT, c, f"{v}.png")) for v in VARIANTS]) for c in pa.SUBJ]
    pg.prancha("a1_variacoes", rows)
