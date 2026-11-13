"""Texturas de pincelada em guache (T1 dabs, T2 aguado, T3 pincel seco) x 8 materiais, para projeção triplanar no mundo.

python texturas_pincel.py gerar [T1 T2 T3] [--mat grass ...] [--seed N]   gera (ComfyUI, uma por vez) em arte_ia/texturas_raw/
python texturas_pincel.py pos [T1 ...]       torna tileável + mapa de valor -> assets/textures/paint/<T>/<mat>.png e <mat>_v.png
python texturas_pincel.py prancha            arte_ia/pranchas/texturas_pincel.png (cada tile 2x2)
"""
import argparse, io, os, sys
import numpy as np
from PIL import Image

T = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, T)
import gen
import deck_novo as dn

ROOT = os.path.abspath(os.path.join(T, "..", ".."))
RAW = os.path.join(ROOT, "arte_ia", "texturas_raw")
OUT = os.path.join(ROOT, "assets", "textures", "paint")
SIZE = 512
CROP = 0.8   # fração central usada (ajuste se a IA deixar margem)

STYLES = {
    "T1": "short wide flat strokes of a broad flat brush overlapping each other, thin translucent paint, flat matte color with no thick relief, soft stroke edges",
    "T2": "soft watery washes with gentle wet edges where the colors bleed together, the wash covering the whole sheet of paper with no white margin",
    "T3": "long dragged dry-brush strokes with gaps where the white paper shows through",
}
MATS = {
    "grass": "soft sage green", "dirt": "light sandy ochre tan", "stone": "warm light grey",
    "foliage": "fresh leaf green", "fur": "muted grey-brown", "metal": "smooth light blue-grey steel grey",
    "wood": "warm chestnut brown", "cloth": "neutral pale cream",
}


def prompt(style, mat):
    return (f"Extreme close-up crop of a flat surface fully covered with {MATS[mat]} gouache paint applied as {STYLES[style]}, "
            f"light gouache on rough watercolor paper, a wide flat brush, top-down view, the paint fills the entire frame "
            f"right to all four edges, one even soft color with lighter airy values.")


def gerar(styles, mats, seed):
    for s in styles:
        for m in mats:
            out = os.path.join(RAW, s, f"{m}.png")
            if os.path.exists(out) and not os.environ.get("FORCE"):
                continue
            os.makedirs(os.path.dirname(out), exist_ok=True)
            def f():
                g, _ = gen.workflow(dn.MODEL, prompt(s, m), seed, SIZE, SIZE)
                Image.open(io.BytesIO(gen.run(g))).convert("RGB").save(out)
            dn.com_retentativa(f)
            print(s, m, "ok", flush=True)


def tileable(img):
    a = np.asarray(img, dtype=np.float32)
    h = a.shape[0]
    s = np.roll(a, (h // 2, h // 2), axis=(0, 1))          # costura do original vai para o centro; bordas viram contínuas
    x = np.linspace(0, 1, h)
    tent = np.minimum(x, 1 - x) * 2                        # 0 na borda, 1 no centro
    w = np.clip(1 - tent / 0.5, 0, 1)                      # 1 na borda, 0 a partir de 25% do tile
    w = w * w * (3 - 2 * w)
    ax = w[None, :, None]; ay = w[:, None, None]
    al = 1 - (1 - ax) * (1 - ay)                           # peso de S (contínuo nas bordas)
    # S tem a costura no centro (cruz): al=0 lá; O (original) é limpo no centro
    r = s * al + a * (1 - al)
    return Image.fromarray(np.clip(r, 0, 255).astype(np.uint8))


def valor(img):
    a = np.asarray(img, dtype=np.float32) / 255
    l = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
    v = (l - l.mean()) / (l.std() + 1e-6) * 0.12 + 0.5
    return Image.fromarray((np.clip(v, 0, 1) * 255 + 0.5).astype(np.uint8), "L")


def pos(styles):
    for s in styles:
        for m in MATS:
            p = os.path.join(RAW, s, f"{m}.png")
            if not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGB")
            if CROP < 1:
                k = int(SIZE * CROP); o = (SIZE - k) // 2
                im = im.crop((o, o, o + k, o + k)).resize((SIZE, SIZE), Image.LANCZOS)
            t = tileable(im)
            d = os.path.join(OUT, s); os.makedirs(d, exist_ok=True)
            t.save(os.path.join(d, f"{m}.png")); valor(t).save(os.path.join(d, f"{m}_v.png"))
    print("pos ok")


def prancha():
    c = 256
    P = Image.new("RGB", (len(MATS) * c, 3 * c), "white")
    for i, s in enumerate(STYLES):
        for j, m in enumerate(MATS):
            p = os.path.join(OUT, s, f"{m}.png")
            if not os.path.exists(p):
                continue
            t = Image.open(p).convert("RGB").resize((c // 2, c // 2), Image.LANCZOS)
            for dx in (0, 1):
                for dy in (0, 1):
                    P.paste(t, (j * c + dx * c // 2, i * c + dy * c // 2))
    P.save(os.path.join(ROOT, "arte_ia", "pranchas", "texturas_pincel.png"))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["gerar", "pos", "prancha"])
    ap.add_argument("styles", nargs="*")
    ap.add_argument("--mat", nargs="*")
    ap.add_argument("--seed", type=int, default=1000)
    a = ap.parse_args()
    st = a.styles or list(STYLES)
    if a.cmd == "gerar":
        gerar(st, a.mat or list(MATS), a.seed)
    elif a.cmd == "pos":
        pos(st)
    else:
        prancha()
