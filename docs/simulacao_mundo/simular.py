"""Simula cor (A), escuros (B) e papel (C) sobre capturas do jogo, sem tocar no jogo.
Uso: py -I simular.py <pasta_capturas> <pasta_cartas> <saida>"""
import sys, glob, os, itertools
import numpy as np
from PIL import Image, ImageFilter, ImageDraw, ImageFont
from concurrent.futures import ProcessPoolExecutor

CAP, CARDS, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
# Retângulos da HUD (1920x1080) que ficam como estão
HUD = [(15, 15, 200, 110), (15, 120, 100, 1010), (90, 140, 240, 185), (90, 500, 240, 660),
       (700, 10, 1220, 180), (1695, 10, 1910, 120), (460, 720, 1445, 965), (380, 950, 1540, 1060), (0, 1020, 600, 1080)]

M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
WP = np.array([0.9505, 1.0, 1.089])

def to_lab(rgb):
    a = rgb / 255.0
    a = np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
    xyz = a @ M.T / WP
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)

def from_lab(lab):
    fy = (lab[..., 0] + 16) / 116
    fx = fy + lab[..., 1] / 500
    fz = fy - lab[..., 2] / 200
    f = np.stack([fx, fy, fz], -1)
    xyz = np.where(f ** 3 > 0.008856, f ** 3, (f - 16 / 116) / 7.787) * WP
    lin = xyz @ np.linalg.inv(M).T
    lin = np.clip(lin, 0, 1)
    s = np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)
    return np.clip(s * 255, 0, 255)

def unit_mask(img, lab):
    """1 onde há unidade/objeto pequeno (difere do campo de cor ao redor), 0 no chão."""
    bg = to_lab(np.asarray(img.filter(ImageFilter.GaussianBlur(28))).astype(float))
    d = np.linalg.norm(lab - bg, axis=-1)
    m = np.clip((d - 10) / 10, 0, 1)
    m = np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(3))) / 255.0
    return m

def ui_mask(rgb, lab):
    """1 = HUD/carta (fica como está). Dentro dos retângulos, o que se parece com o chão ao redor é mundo."""
    H, W = lab.shape[:2]
    inr = np.zeros((H, W), bool)
    for x0, y0, x1, y1 in HUD:
        inr[y0:y1, x0:x1] = True
    w = (~inr).astype(float)
    def blur(a, s=90):  # borrão largo: reduz e amplia (bilinear), em float
        im = Image.fromarray(a.astype(np.float32), mode="F")
        sm = im.resize((max(W // (s // 3), 2), max(H // (s // 3), 2)), Image.BOX)
        sm = sm.resize((max(W // s, 2), max(H // s, 2)), Image.BILINEAR)
        return np.asarray(sm.resize((W, H), Image.BICUBIC))
    # cores frequentes do chão (fora dos retângulos), numa grade Lab de 4 unidades
    q = np.floor(lab / 4).astype(int) + np.array([0, 40, 40])
    q = np.clip(q, 0, 79)
    key = q[..., 0] * 6400 + q[..., 1] * 80 + q[..., 2]
    cnt = np.bincount(key[~inr].ravel(), minlength=80 * 6400)
    freq = cnt > (~inr).sum() * 0.0002
    grid = freq.reshape(80, 80, 80)
    from itertools import product
    g2 = grid.copy()
    for dx, dy, dz in product((-1, 0, 1), repeat=3):
        g2 |= np.roll(np.roll(np.roll(grid, dx, 0), dy, 1), dz, 2)
    ground = g2[q[..., 0], q[..., 1], q[..., 2]]
    ui = inr & ~ground
    m = Image.fromarray((ui * 255).astype(np.uint8))
    m = m.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.MinFilter(15))   # fecha buracos dentro das cartas
    m = m.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))   # tira pontinhos soltos
    m = np.asarray(m.filter(ImageFilter.GaussianBlur(1))) / 255.0
    return m * inr

def grain_tile():
    """Grão de papel tirado do céu liso das cartas (passa-alta, média zero)."""
    rows = []
    for f in sorted(glob.glob(os.path.join(CARDS, "*.png")))[:60]:
        im = Image.open(f).convert("L")
        if im.width < 500:
            continue
        top = im.crop((10, 10, 546, 110))
        a = np.asarray(top).astype(float)
        hp = a - np.asarray(top.filter(ImageFilter.GaussianBlur(1.2))).astype(float)   # só o dente do papel
        b6 = np.asarray(top.filter(ImageFilter.GaussianBlur(6))).astype(float)
        if np.abs(b6 - a.mean()).mean() < 3 and b6.std() < 5:  # céu realmente liso, sem formas
            rows.append(np.clip(hp, -14, 14))
    print("céus lisos usados:", len(rows))
    return np.vstack(rows)

def apply(lab, umask, tile, A, B, C):
    L, a, b = lab[..., 0].copy(), lab[..., 1].copy(), lab[..., 2].copy()
    g = 1 - umask  # peso do chão
    if A:
        C0 = np.hypot(a, b); h = (np.degrees(np.arctan2(b, a)) + 360) % 360
        nh = h.copy()
        grass = (h >= 120) & (h <= 230)
        nh[grass] = 118 + (h[grass] - 120) * 0.12       # menta/petróleo -> sálvia
        road = (h >= 15) & (h < 90)
        nh[road] = 65 + (h[road] - 15) * 0.25           # salmão -> ocre/areia
        nC = C0 * 0.62
        h2 = np.where(g > 0, nh, h); C2 = C0 + (nC - C0) * g
        hn = h + ((h2 - h + 180) % 360 - 180) * g
        a = C2 * np.cos(np.radians(hn)); b = C2 * np.sin(np.radians(hn))
    if B:
        p5, p95 = np.percentile(L, 5), np.percentile(L, 95)
        L = 16 + (L - p5) * (82 - 16) / max(p95 - p5, 1)
        sh = np.clip((52 - L) / 22, 0, 1) * g             # sombras frias, lilás
        a = a + 4 * sh; b = b - 7 * sh
    if C:
        H, W = L.shape
        reps = (H // tile.shape[0] + 1, W // tile.shape[1] + 1)
        t = np.tile(tile, reps)[:H, :W]
        t = np.where(t > 0, t * 1.0, t * 0.35)           # clareia mais do que escurece
        L = L + t * (0.45 + 0.3 * g)
    return np.stack([np.clip(L, 0, 100), a, b], -1)

def job(args):
    path, tag, A, B, C = args
    img = Image.open(path).convert("RGB")
    rgb = np.asarray(img).astype(float)
    lab = to_lab(rgb)
    um = unit_mask(img, lab)
    out = from_lab(apply(lab, um, TILE, A, B, C)) if (A or B or C) else rgb
    keep = ui_mask(rgb, lab)[..., None]
    out = out * (1 - keep) + rgb * keep
    res = Image.fromarray(out.astype(np.uint8))
    name = os.path.splitext(os.path.basename(path))[0]
    fn = os.path.join(OUT, f"{name}_{tag}.png")
    res.save(fn)
    return fn

TILE = grain_tile()
VARS = [("0_hoje", 0, 0, 0), ("A_cor", 1, 0, 0), ("B_escuros", 0, 1, 0), ("C_papel", 0, 0, 1),
        ("AB", 1, 1, 0), ("AC", 1, 0, 1), ("BC", 0, 1, 1), ("ABC", 1, 1, 1)]

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    caps = sorted(glob.glob(os.path.join(CAP, "V4_*.png")))
    jobs = [(c, t, A, B, C) for c in caps for (t, A, B, C) in VARS]
    with ProcessPoolExecutor() as ex:
        files = list(ex.map(job, jobs))
    print("\n".join(files))
    # prancha: uma por captura, 2 colunas x 4 linhas, metade do tamanho
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 30)
    except Exception:
        font = ImageFont.load_default()
    labels = {"0_hoje": "Hoje", "A_cor": "A · só cor", "B_escuros": "B · só escuros", "C_papel": "C · só papel",
              "AB": "A+B · cor e escuros", "AC": "A+C · cor e papel", "BC": "B+C · escuros e papel", "ABC": "A+B+C · tudo"}
    for c in caps:
        name = os.path.splitext(os.path.basename(c))[0]
        tiles = [Image.open(os.path.join(OUT, f"{name}_{t}.png")).resize((960, 540), Image.LANCZOS) for t, *_ in VARS]
        board = Image.new("RGB", (960 * 2 + 10, (540 + 44) * 4), (236, 228, 212))
        d = ImageDraw.Draw(board)
        for i, (im, (t, *_)) in enumerate(zip(tiles, VARS)):
            x, y = (i % 2) * 970, (i // 2) * 584
            d.text((x + 8, y + 4), labels[t], fill=(50, 40, 30), font=font)
            board.paste(im, (x, y + 44))
        board.save(os.path.join(OUT, f"prancha_{name}.jpg"), quality=88)
        print("prancha", name)
