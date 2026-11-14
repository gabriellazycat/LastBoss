"""Rodada 4 (13/11/2026): formas largas da A (base = A1 do pincel_grosso_a.py, sem fivela) com guache leve:
tinta lisa e chapada, quase sem marca de pincel, grão do papel aparecendo (referência: recorte da capa roxa do
Rei dos Ratos da rodada minimalista).

python -I guache_leve.py [--denoise 0.62]
Saída: arte_ia/guache_leve/<card>/<v>.png; prancha arte_ia/pranchas/guache_leve.png
"""
import argparse, os, sys, zlib
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as grainmod
import pincel_grosso as pg, pincel_grosso_a as pa
from deck import crop_final, MODEL, W, H, GRAIN

OUT = os.path.join(gen.ROOT, "guache_leve")
MEDIUM = "A light flat gouache painting on rough cold-press paper, scanned from an old sketchbook: "
LIGHT = ("thin smooth layers of matte gouache laid flat and even, soft slightly fuzzy edges, the texture of the "
         "paper showing evenly through every color, muted dusty colors, slightly blurry low-resolution scan.")
VARIANTS = {
    "L1": ("Guache leve",
           "Large simple flat shapes, each object one smooth flat color with one soft shadow tone, faces and eyes as "
           "one small dark dot, " + LIGHT),
    "L2": ("Guache leve + formas maiores",
           "A few very large simple flat shapes like a cut-paper poster, small parts merged into the big shapes, each "
           "figure read by its silhouette and two flat tones, eyes as one small dark dot, " + LIGHT),
    "L3": ("Guache leve + sombra suave",
           "Large simple shapes painted in thin flat gouache with soft gradual shading inside each shape, light from "
           "the upper left, eyes as one small dark dot, " + LIGHT),
}


def make(card, v, denoise, seed=1000):
    base = os.path.join(pa.OUT, card, "A1_raw.png")
    bg, subj = pa.SUBJ[card]
    p = f"{MEDIUM}{subj} A plain flat {gen.BACKGROUNDS[bg]} sky behind. {pa.TONE} {VARIANTS[v][1]}"
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
    ap.add_argument("cards", nargs="*", default=list(pa.SUBJ))
    ap.add_argument("--denoise", type=float, default=0.62)
    a = ap.parse_args()
    for c in a.cards:
        for v in VARIANTS:
            make(c, v, a.denoise)
    rows = [(c, [(f"{pa.NAMES[c]} · A1", os.path.join(pa.OUT, c, "A1.png"))] +
             [(f"{v}. {VARIANTS[v][0]}", os.path.join(OUT, c, f"{v}.png")) for v in VARIANTS]) for c in pa.SUBJ]
    pg.prancha("guache_leve", rows)
