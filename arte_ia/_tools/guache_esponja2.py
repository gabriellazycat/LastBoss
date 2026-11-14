"""Rodada 7 (13/11/2026): esponja por cor. Nas artes antigas cada cor tem a sua esponja (padrão, tamanho e força
próprios) e o fundo tem esponja maior e mais forte que a figura. Sem IA, sobre o A1 do pincel_grosso_a.py.

1. regiões de cor: a imagem amaciada é reduzida a N cores; cada cor vira uma máscara macia;
2. fundo: as cores que dominam a borda de cima e dos lados (o céu liso do baralho);
3. cada região recebe um ruído fractal com semente, escala e força próprias; fundo × FUNDO, figura × FIGURA.

python -I guache_esponja2.py
Saída: arte_ia/guache_esponja2/<card>/<v>.png; prancha arte_ia/pranchas/guache_esponja2.png
"""
import os, sys, zlib
import numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import gaussian_filter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as gm
import pincel_grosso as pg, pincel_grosso_a as pa, guache_rala as gr
from deck import crop_final

OUT = os.path.join(gen.ROOT, "guache_esponja2")
PAPER = np.array([0.95, 0.93, 0.89])
NCORES = 10
# (nome, força na figura, força no fundo, escala do fundo)
VARIANTS = {
    "F1": ("Figura média, fundo forte", 0.55, 1.15, 1.4),
    "F2": ("Figura fraca, fundo forte", 0.32, 1.15, 1.4),
    "F3": ("Figura fraca, fundo bem forte", 0.32, 1.45, 1.8),
}
LIFT, AREA = 0.34, 0.46          # a E2 da rodada anterior (a mais próxima da referência no zoom)


def regioes(img):
    sm = img.filter(ImageFilter.MedianFilter(7))
    q = sm.quantize(colors=NCORES, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    lab = np.asarray(q)
    h, w = lab.shape
    border = np.r_[lab[:h // 3, :8].ravel(), lab[:h // 3, -8:].ravel(), lab[:6, :].ravel()]
    cnt = np.bincount(border, minlength=NCORES)
    fundo = {i for i in range(NCORES) if cnt[i] > 0.12 * len(border)}
    return lab, fundo


def esponja_regiao(rng, h, w, k, scale):
    n = sum(amp * gm.noise(h, w, s * k * scale, rng) for s, amp in ((0.8, 0.35), (1.6, 0.5), (3.2, 0.5), (7, 0.35)))
    n = (n - n.mean()) / (n.std() + 1e-6)
    m = np.clip((n - np.quantile(n, 1 - AREA)) * 1.1 + 0.15, 0, 1)
    return gaussian_filter(m, 0.45 * k)


def esponja2(img, seed, fig, bg, bg_scale):
    a = np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0
    h, w, _ = a.shape
    k = w / 556.0
    lab, fundo = regioes(img)
    rng = np.random.default_rng(seed)
    mask = np.zeros((h, w))
    lift = np.zeros((h, w))
    wsum = np.zeros((h, w))
    for i in range(NCORES):
        soft = gaussian_filter((lab == i).astype(np.float32), 1.2 * k)
        if soft.max() < 1e-3:
            continue
        is_bg = i in fundo
        sc = bg_scale if is_bg else rng.uniform(0.75, 1.25)          # cada cor com o seu tamanho de mancha
        mi = esponja_regiao(rng, h, w, k, sc)
        li = LIFT * (bg if is_bg else fig) * (1.0 if is_bg else rng.uniform(0.8, 1.2))
        mask += soft * mi
        lift += soft * li
        wsum += soft
    mask /= np.maximum(wsum, 1e-6)
    lift /= np.maximum(wsum, 1e-6)
    light = a + (PAPER - a) * lift[..., None]
    dark = a * (1 - 0.06 * lift / LIFT)[..., None]
    out = dark * (1 - mask[..., None]) + light * mask[..., None]
    return Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)), lab, fundo


if __name__ == "__main__":
    rows = []
    for c in pa.SUBJ:
        src = Image.open(os.path.join(pa.OUT, c, "A1_raw.png")).convert("RGB")
        if c == "ranger":
            src = gr.achatar(src)
        d = os.path.join(OUT, c)
        os.makedirs(d, exist_ok=True)
        cells = [(f"{pa.NAMES[c]} · A1", os.path.join(pa.OUT, c, "A1.png"))]
        for v, (nome, fig, bg, bs) in VARIANTS.items():
            im, lab, fundo = esponja2(src, zlib.crc32(f"{c}{v}".encode()), fig, bg, bs)
            full = os.path.join(d, f"{v}_full.png")
            im.save(full)
            crop_final(full, os.path.join(d, f"{v}.png"))
            cells.append((f"{v}. {nome}", os.path.join(d, f"{v}.png")))
        # máscara do fundo, para conferir a separação
        Image.fromarray((np.isin(lab, list(fundo)) * 255).astype(np.uint8)).save(os.path.join(d, "_fundo.png"))
        rows.append((c, cells))
    pg.prancha("guache_esponja2", rows)
