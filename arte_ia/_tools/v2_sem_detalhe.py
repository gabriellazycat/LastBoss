"""Rodada 10 (13/11/2026): V2 (a1_variacoes.py, guache leve aguado) sem detalhe pequeno e sem olhos.

Pedir "menos detalhe" só no texto não basta: a repintura copia os risquinhos da base. Então a base é simplificada
antes (mediana grande: some escama, dobra fina, olho), e a IA repinta com o pincel largo da V2.
Regras do designer (13/11): pincel nunca fino o bastante para detalhe; sombra = mancha grande; criaturas sem olhos.

python -I v2_sem_detalhe.py
Saída: arte_ia/v2_sem_detalhe/<card>/<v>.png (grão 0,9); prancha arte_ia/pranchas/v2_sem_detalhe.png
"""
import os, sys, zlib
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as gm
import pincel_grosso as pg, pincel_grosso_a as pa, a1_variacoes as av
from deck import crop_final, MODEL, W, H, GRAIN

OUT = os.path.join(gen.ROOT, "v2_sem_detalhe")
SUBJ = {
    "rat_king": ("lilac", "an eyeless gaunt old grey rat king with a smooth blank face seated on a throne of bones, "
                 "raising a golden scepter that is one plain gold rod. A plain gold crown with three simple points, a "
                 "tattered purple cape, a crowd of eyeless grey rats with pink ears and smooth blank faces spilling "
                 "forward at his feet."),
    "elder_dragon": ("teal", "a huge ancient eyeless red dragon with a smooth blank head, a pale yellow belly and two "
                     "long plain curved horns standing in side view, breathing a stream of orange fire, wings raised. "
                     "Its whole body is smooth red skin painted in a few wide strokes."),
    "ranger": ("ochre", "a hooded ranger with his face hidden in the dark shadow of the hood, in a plain dark green "
               "cloak and a plain brown tunic tied with a plain cloth sash, drawing a plain wooden longbow, an arrow "
               "on the string. His clothes are a few large plain shapes, each with one big soft shadow."),
}
BRUSH = ("Painted only with a very wide flat brush, so every mark is a broad stroke and the smallest shape is as wide "
         "as the brush; smooth unbroken color areas with one big soft shadow shape each. ")
_, MEDIUM, TEXTURE = av.VARIANTS["V2"]
# (nome, mediana na base em px de 768, força da repintura)
VARIANTS = {
    "S1": ("Simplifica pouco", 9, 0.45),
    "S2": ("Simplifica médio", 13, 0.5),
    "S3": ("Simplifica muito", 17, 0.55),
}


def simplificar(img, k):
    im = img.filter(ImageFilter.MedianFilter(k))
    return im.filter(ImageFilter.MedianFilter(k)).filter(ImageFilter.GaussianBlur(1.0))


def make(card, v, seed=1000):
    _, med, den = VARIANTS[v]
    d = os.path.join(OUT, card)
    os.makedirs(d, exist_ok=True)
    base = Image.open(os.path.join(av.OUT, card, "V2_raw.png")).convert("RGB")
    init = os.path.join(d, f"_base_{v}.png")
    simplificar(base, med).save(init)
    bg, subj = SUBJ[card]
    p = f"{MEDIUM}{subj} A plain flat {gen.BACKGROUNDS[bg]} sky behind. {av.TONE} {BRUSH}{TEXTURE}"
    g, _ = gen.workflow(MODEL, p, seed, W, H, init_image=gen.upload_image(init), denoise=den)
    raw = os.path.join(d, f"{v}_raw.png")
    open(raw, "wb").write(gen.run(g))
    gp = raw.replace("_raw", "_grain")
    gm.grain(Image.open(raw), seed=zlib.crc32(f"{card}{v}".encode()), strength=GRAIN).save(gp)
    crop_final(gp, os.path.join(d, f"{v}.png"))
    open(os.path.join(d, f"{v}.txt"), "w", encoding="utf-8").write(f"mediana {med} denoise {den}\n{p}\n")
    print(card, v, flush=True)


if __name__ == "__main__":
    for c in SUBJ:
        for v in VARIANTS:
            make(c, v)
    rows = [(c, [(f"{pa.NAMES[c]} · V2", os.path.join(av.OUT, c, "V2.png"))] +
             [(f"{v}. {VARIANTS[v][0]}", os.path.join(OUT, c, f"{v}.png")) for v in VARIANTS]) for c in SUBJ]
    pg.prancha("v2_sem_detalhe", rows)
