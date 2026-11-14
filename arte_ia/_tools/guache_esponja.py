"""Rodada 6 (13/11/2026): textura "esponja" das artes antigas (arte_ia/_backup_assets_cards: bat_nest, bone_legion,
profane_ritual) sobre o A1 do pincel_grosso_a.py, sem IA.

Na referência cada cor chapada é quebrada por aglomerados claros orgânicos (ruído fractal de 2 a 12 px no
recorte 556x534, sem direção), ocupando ~40-50% da área; o claro é a própria cor puxada para o papel.

python -I guache_esponja.py
Saída: arte_ia/guache_esponja/<card>/<v>.png; prancha arte_ia/pranchas/guache_esponja.png
"""
import os, sys, zlib
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as gm
import pincel_grosso as pg, pincel_grosso_a as pa, guache_rala as gr
from deck import crop_final

OUT = os.path.join(gen.ROOT, "guache_esponja")
PAPER = np.array([0.95, 0.93, 0.89])
# (nome, quanto o claro puxa para o papel, área coberta pelo claro 0-1, achatar a base antes)
VARIANTS = {
    "E1": ("Esponja leve", 0.22, 0.40),
    "E2": ("Esponja média", 0.32, 0.46),
    "E3": ("Esponja forte", 0.42, 0.52),
}


def esponja(img, seed, lift, area):
    rng = np.random.default_rng(seed)
    a = np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0
    h, w, _ = a.shape
    k = w / 556.0                                            # escala medida no recorte final 556 px
    n = sum(amp * gm.noise(h, w, s * k, rng) for s, amp in ((0.8, 0.35), (1.6, 0.5), (3.2, 0.5), (7, 0.35)))
    n = (n - n.mean()) / (n.std() + 1e-6)
    thr = np.quantile(n, 1 - area)
    m = np.clip((n - thr) * 1.1 + 0.15, 0, 1)                # borda felpuda dos aglomerados
    m = gaussian_filter(m, 0.45 * k)
    light = a + (PAPER - a) * lift                           # a mesma cor, puxada para o papel
    dark = a * 0.94                                          # o vão entre manchas um pouco mais denso
    out = dark * (1 - m[..., None]) + light * m[..., None]
    return Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8))


if __name__ == "__main__":
    rows = []
    for c in pa.SUBJ:
        src = Image.open(os.path.join(pa.OUT, c, "A1_raw.png")).convert("RGB")
        if c == "ranger":
            src = gr.achatar(src)                            # sombreamento mais simples (pedido de 13/11)
        d = os.path.join(OUT, c)
        os.makedirs(d, exist_ok=True)
        cells = [(f"{pa.NAMES[c]} · A1", os.path.join(pa.OUT, c, "A1.png"))]
        for v, (nome, lift, area) in VARIANTS.items():
            full = os.path.join(d, f"{v}_full.png")
            esponja(src, zlib.crc32(f"{c}{v}".encode()), lift, area).save(full)
            crop_final(full, os.path.join(d, f"{v}.png"))
            cells.append((f"{v}. {nome}", os.path.join(d, f"{v}.png")))
        rows.append((c, cells))
    pg.prancha("guache_esponja", rows)
