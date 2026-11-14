"""Rodada 5 (13/11/2026): textura de "mão de guache bem leve" sobre o A1 (pincel_grosso_a.py), sem IA.

A tinta vira uma camada rala: o branco do papel aparece em pintinhas (dente do papel) e em manchas maiores onde a
tinta ficou mais fina. Substitui o grain.py nestas provas (aplicar os dois duplicaria o papel).
Opcional: --achatar <card> junta tons vizinhos (sombreamento mais simples) antes da textura.

python -I guache_rala.py
Saída: arte_ia/guache_rala/<card>/<v>.png; prancha arte_ia/pranchas/guache_rala.png
"""
import os, sys, zlib
import numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import gaussian_filter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as gm
import pincel_grosso as pg, pincel_grosso_a as pa
from deck import crop_final

OUT = os.path.join(gen.ROOT, "guache_rala")
PAPER = np.array([0.96, 0.94, 0.90])          # papel quase branco (o da referência é bem claro)

# (nome, cobertura média, limiar das pintinhas (menor = mais branco), manchas ralas)
VARIANTS = {
    "R1": ("Rala leve", 0.97, 1.5, 0.08),
    "R2": ("Rala média", 0.96, 1.1, 0.12),
    "R3": ("Rala forte", 0.95, 0.7, 0.16),
}


def achatar(img, cores=16):
    """Sombreamento mais simples: tira o miúdo (mediana) e reduz para poucas cores, depois amacia a borda."""
    im = img.filter(ImageFilter.MedianFilter(5))
    im = im.quantize(colors=cores, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    return im.filter(ImageFilter.ModeFilter(5)).filter(ImageFilter.GaussianBlur(0.6))


def rala(img, seed, cover, speck, thin):
    rng = np.random.default_rng(seed)
    a = np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0
    h, w, _ = a.shape
    k = w / 1024.0
    tooth = 0.6 * gm.noise(h, w, 4.5 * k, rng) + 0.4 * gm.noise(h, w, 1.8 * k, rng)   # dente do papel
    blot = 0.55 * gm.noise(h, w, 120 * k, rng) + 0.45 * gm.noise(h, w, 30 * k, rng)   # tinta mais fina/grossa
    drag = gaussian_filter(rng.standard_normal((h, w)), (1.0 * k, 10 * k))              # arrasto do pincel
    drag /= drag.std() + 1e-6
    # pintinhas nítidas: só onde o dente do papel passa do limiar `speck` a tinta falha e o branco aparece
    flecks = np.clip((tooth + 0.5 * drag - speck) * 1.6, 0, 1)
    c = cover + thin * 0.5 * blot - 0.75 * flecks
    c = np.clip(c, 0.25, 1.0)[..., None]
    out = PAPER * (1 - c) + a * c
    gy, gx = np.gradient(tooth)                                                          # relevo do papel
    out *= (1.0 + 0.03 * (-(gx + gy) / (np.abs(gx + gy).std() + 1e-6)))[..., None]
    out += rng.standard_normal((h, w, 1)) * 0.012
    return Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8))


if __name__ == "__main__":
    flat = sys.argv[sys.argv.index("--achatar") + 1:] if "--achatar" in sys.argv else ["ranger"]
    rows = []
    for c in pa.SUBJ:
        src = Image.open(os.path.join(pa.OUT, c, "A1_raw.png")).convert("RGB")
        if c in flat:
            src = achatar(src)
        d = os.path.join(OUT, c)
        os.makedirs(d, exist_ok=True)
        cells = [(f"{pa.NAMES[c]} · A1", os.path.join(pa.OUT, c, "A1.png"))]
        for v, (nome, cov, sp, th) in VARIANTS.items():
            raw = os.path.join(d, f"{v}_full.png")
            rala(src, zlib.crc32(f"{c}{v}".encode()), cov, sp, th).save(raw)
            crop_final(raw, os.path.join(d, f"{v}.png"))
            cells.append((f"{v}. {nome}", os.path.join(d, f"{v}.png")))
        rows.append((c, cells))
    pg.prancha("guache_rala", rows)
