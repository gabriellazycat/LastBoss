"""Rodada 3 (13/11/2026): parte da variante A do pincel_grosso.py e tira o detalhe miúdo (fivela, joias da coroa).

python -I pincel_grosso_a.py [--denoise 0.55]
Saída: arte_ia/pincel_grosso_a/<card>/<v>.png; prancha arte_ia/pranchas/pincel_grosso_a.png
Frases só positivas (o modelo roda sem negativo: "no buckle" puxa a fivela).
"""
import argparse, os, sys, zlib
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as grainmod
import pincel_grosso as pg
from deck import crop_final, MODEL, W, H, GRAIN

OUT = os.path.join(gen.ROOT, "pincel_grosso_a")
A = {"rat_king": 62, "elder_dragon": 62, "ranger": 75}          # denoise usado na A aprovada
SUBJ = {
    "rat_king": ("lilac", "a gaunt old grey rat king seated on a throne of bones and skulls, raising a golden scepter "
                 "that is one plain gold rod. A plain smooth gold crown with three simple points, a tattered purple "
                 "cape with a plain white collar, a crowd of grey rats with pink ears spilling forward at his feet."),
    "elder_dragon": ("teal", "a huge ancient red dragon with a pale yellow belly and two long plain curved horns "
                     "standing in side view, breathing a stream of orange fire, wings raised, its scales painted as "
                     "smooth flat red."),
    "ranger": ("ochre", "a hooded ranger in a plain dark green cloak and a plain brown tunic tied with a plain cloth "
               "sash, drawing a plain wooden longbow, an arrow on the string."),
}
MEDIUM = "A gouache painting on rough cold-press paper, scanned from an old sketchbook: "
PAPER = "paper grain showing through, muted dusty colors, slightly blurry low-resolution scan."
VARIANTS = {
    "A1": ("A + formas lisas",
           "Painted with a very wide flat bristle brush in a few bold heavy strokes, every stroke thick and visible, "
           "each object painted as one smooth flat shape of a single color, faces and eyes reduced to one or two dabs "
           "of dark paint, " + PAPER),
    "A2": ("A + pincel mais largo",
           "Painted with a huge flat house-painting brush, the smallest mark in the picture is one wide brushstroke, "
           "big flat chunks of color, objects merged into the shapes around them, faces as one flat tone with a dark "
           "dab for the eye, " + PAPER),
    "A3": ("A + menos cores",
           "Painted with a very wide flat bristle brush in a few bold heavy strokes, a palette of five flat colors, "
           "large simple shapes like a cut-paper poster, each figure read only by its silhouette and two tones, eyes "
           "as one dark dab, " + PAPER),
}
TONE = "Grounded serious fantasy book illustration with natural proportions."
NAMES = {"rat_king": "Rei dos Ratos", "elder_dragon": "Dragão Ancião", "ranger": "Patrulheiro"}


def make(card, v, denoise, seed=1000):
    base = os.path.join(pg.OUT, card, f"A_d{A[card]}_raw.png")
    bg, subj = SUBJ[card]
    p = f"{MEDIUM}{subj} A plain flat {gen.BACKGROUNDS[bg]} sky behind. {TONE} {VARIANTS[v][1]}"
    g, _ = gen.workflow(MODEL, p, seed, W, H, init_image=gen.upload_image(base), denoise=denoise)
    d = os.path.join(OUT, card)
    os.makedirs(d, exist_ok=True)
    raw = os.path.join(d, f"{v}_raw.png")
    open(raw, "wb").write(gen.run(g))
    gp = raw.replace("_raw", "_grain")
    grainmod.grain(Image.open(raw), seed=zlib.crc32(f"{card}{v}".encode()), strength=GRAIN).save(gp)
    crop_final(gp, os.path.join(d, f"{v}.png"))
    open(os.path.join(d, f"{v}.txt"), "w", encoding="utf-8").write(f"denoise {denoise}\n{p}\n")
    print(card, v, flush=True)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cards", nargs="*", default=list(SUBJ))
    ap.add_argument("--denoise", type=float, default=0.55)
    a = ap.parse_args()
    for c in a.cards:
        for v in VARIANTS:
            make(c, v, a.denoise)
    rows = [(c, [(f"{NAMES[c]} · A", os.path.join(pg.OUT, c, f"A_d{A[c]}.png"))] +
             [(f"{v}. {VARIANTS[v][0]}", os.path.join(OUT, c, f"{v}.png")) for v in VARIANTS]) for c in SUBJ]
    pg.prancha("pincel_grosso_a", rows)
