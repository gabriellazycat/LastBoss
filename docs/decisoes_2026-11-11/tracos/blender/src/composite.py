"""Watercolour compositor: paper + loose glazes (spill, pooling edges, granulation, blooms, form
shadow) under the Grease Pencil ink pass.  usage: python composite.py scene.json ink.png out.png"""
import sys, json, math
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

src, inkp, out = sys.argv[1:4]
D = json.load(open(src))
W, H = D["W"], D["H"]
S = 4                                   # working px per unit
w, h = int(W * S), int(H * S)
rng = np.random.default_rng(7)
PAPER = np.array([251, 246, 234]) / 255.0
INK = np.array([74, 44, 24]) / 255.0


def hexc(c):
    c = c.lstrip("#")
    return np.array([int(c[i:i + 2], 16) for i in (0, 2, 4)]) / 255.0


def fbm(seed, scales=(64, 24, 8, 3), amps=(1, .6, .35, .2)):
    r = np.random.default_rng(seed)
    acc = np.zeros((h, w))
    for s, a in zip(scales, amps):
        g = r.normal(size=(h // s + 2, w // s + 2))
        z = ndi.zoom(g, s, order=3)[:h, :w]
        acc += a * z
    acc -= acc.mean()
    return acc / (acc.std() + 1e-9)


def blur(a, r):
    return ndi.gaussian_filter(a, r) if r > 0 else a


def shift(a, dx, dy):
    return ndi.shift(a, (dy, dx), order=1, mode="constant", cval=0)


def raster(poly, seed, spill):
    """Antialiased polygon, outline perturbed by low-frequency noise (+ outward spill)."""
    P = np.asarray(poly, float)
    if len(P) < 3:
        return np.zeros((h, w))
    # resample the outline then push points outward/inward with smooth noise
    d = np.r_[0, np.cumsum(np.linalg.norm(np.diff(np.vstack([P, P[:1]]), axis=0), axis=1))]
    n = max(int(d[-1] / 1.5), 12)
    s = np.linspace(0, d[-1], n, endpoint=False)
    Q = np.vstack([P, P[:1]])
    X = np.interp(s, d, Q[:, 0]); Y = np.interp(s, d, Q[:, 1])
    cx, cy = X.mean(), Y.mean()
    r = np.random.default_rng(seed)
    k = max(n // 10, 4)
    nz = np.interp(np.arange(n), np.linspace(0, n, k + 1), np.r_[r.normal(size=k), 0][: k + 1])
    nz[-1] = nz[0]
    tx = np.gradient(X); ty = np.gradient(Y)
    L = np.hypot(tx, ty) + 1e-9
    area = 0.5 * np.sum(X * np.roll(Y, -1) - np.roll(X, -1) * Y)
    sg = 1 if area > 0 else -1
    nx, ny = sg * ty / L, -sg * tx / L
    off = spill * (0.55 + 0.6 * nz)
    X = X + nx * off; Y = Y + ny * off
    im = Image.new("L", (w, h), 0)
    ImageDraw.Draw(im).polygon(list(zip(X * S, Y * S)), fill=255)
    return np.asarray(im, float) / 255.0


paper_n = fbm(1, (48, 12, 4, 2), (0.4, 0.5, 0.6, 0.5))
gran_n = np.clip(fbm(2, (8, 4, 2), (1, .7, .5)), -2.5, 2.5)
canvas = np.ones((h, w, 3)) * PAPER[None, None, :]
canvas *= (1 + 0.025 * paper_n)[..., None]

# union of each layer's silhouettes, then "everything in front of layer i"
NL = len(D["holds"])
lay_m = []
for hs in D["holds"]:
    mm = np.zeros((h, w))
    for hp in hs:
        mm = np.maximum(mm, raster(hp, 5, -1.4))
    lay_m.append(mm)
front = [None] * NL
acc = np.zeros((h, w))
for i in range(NL - 1, -1, -1):
    front[i] = blur(acc, 2.0)
    acc = np.maximum(acc, lay_m[i])

for i, wa in enumerate(sorted(D["washes"], key=lambda x: x["z"])):
    seed = wa["seed"]
    m = raster(wa["poly"], seed, wa["spill"])
    if m.max() == 0:
        continue
    rr_ = np.random.default_rng(seed + 99)
    mis = wa.get("mis", 1.3)
    m = shift(m, rr_.normal() * mis * S, rr_.normal() * mis * S)
    m = blur(m, 1.2 + wa.get("soft", 0) * S)
    if wa.get("clip"):
        cm = np.zeros_like(m)
        for cp in wa["clip"]:
            cm = np.maximum(cm, raster(cp, seed + 7, 0))
        m = m * blur(cm, wa.get("csoft", 1.0) * S)
    keep = np.ones_like(m)
    if wa.get("knock"):
        k = np.zeros_like(m)
        for kp in wa["knock"]:
            k = np.maximum(k, raster(kp, seed + 5, -1.6))
        k = blur(k, wa.get("ksoft", 2.5))
        keep = keep * (1 - k)
    if wa["li"] < NL - 1 and wa["z"] >= 3:
        keep = keep * (1 - front[wa["li"]])
    lo = fbm(seed + 11, (90, 40, 16), (1, .7, .4))
    # dry brush: break the wash toward its own edges with noise
    if wa["dry"] > 0:
        near = np.clip(m * (1 - blur(m, 3.5 * S)) * 2.2, 0, 1)
        nz = fbm(seed + 13, (40, 16, 6), (1, .6, .35))
        holes = np.clip((nz - (1.1 - wa["dry"])) * 3, 0, 1) * near
        m = m * (1 - holes)
    area_px = m.sum()
    sz = math.sqrt(max(area_px, 1))
    lx, ly = -0.6, -0.8
    if wa["light_cut"] > 0:
        kk = 0.18 * sz
        lit = m * (1 - blur(shift(m, -lx * kk, -ly * kk), 0.12 * sz))
        lit = np.clip(lit * 1.6 + 0.35 * lo, 0, 1)
        m = m * (1 - wa["light_cut"] * lit)
    # pigment pooling at the wash's own wet edge (not along knocked-out edges)
    pool = np.clip(m - blur(m, 2.2 * S), 0, 1)
    dens = wa["alpha"] * m * (1 + 0.85 * wa["edge"] * pool * 2.2)
    dens *= 1 + 0.12 * wa["bloom"] * lo + 0.04 * lo
    dens *= 1 + 0.10 * wa["gran"] * gran_n * np.clip(m, 0, 1)
    m_own = m.copy()
    m = m * keep
    dens = dens * keep
    dens = np.clip(dens, 0, 1)
    col = hexc(wa["color"])
    canvas *= 1 - dens[..., None] * (1 - col[None, None, :])
    # form shadow: second glaze on the shadow side, its own loose edge
    if wa["shade"] > 0:
        kk = 0.26 * sz
        sh = m_own * (1 - blur(shift(m_own, lx * kk, ly * kk), 0.1 * sz))
        thr = fbm(seed + 17, (60, 24, 8), (1, .4, .15))
        sh = np.clip((sh + 0.14 * thr - 0.15) * 2.2, 0, 1) * np.clip(m_own * 1.5, 0, 1) * keep
        sh = blur(sh, 1.0)
        spool = np.clip(sh - blur(sh, 2.0 * S), 0, 1)
        sd = np.clip(wa["shade"] * sh * (1 + 1.0 * spool) * (1 + 0.1 * gran_n), 0, 1)
        scol = hexc(wa["shadow_color"]) if wa.get("shadow_color") else col * 0.62
        canvas *= 1 - sd[..., None] * (1 - scol[None, None, :])

# raster fx (glows = paper kept light + warm glaze; embers = dots)
for fx in D.get("fx", []):
    if fx["t"] == "glow":
        yy, xx = np.mgrid[0:h, 0:w]
        cx, cy, r = fx["c"][0] * S, fx["c"][1] * S, fx["r"] * S
        g = np.clip(1 - np.hypot(xx - cx, yy - cy) / r, 0, 1) ** fx.get("p", 1.5)
        g = g * (1 + 0.15 * fbm(fx.get("seed", 3), (40, 12), (1, .5)))
        lift = np.clip(g * fx.get("k", 0.6), 0, 1)[..., None]
        canvas = canvas * (1 - lift) + lift * hexc(fx["color"])[None, None, :]
    if fx["t"] == "lines":
        im = Image.new("L", (w, h), 0); dr = ImageDraw.Draw(im)
        for (x0, y0, x1, y1, r) in fx["pts"]:
            n = 8
            for k in range(n):
                t0, t1 = k / n, (k + 1) / n
                rw = r * (1 - t0) + 0.15
                dr.line([((x0 + (x1 - x0) * t0) * S, (y0 + (y1 - y0) * t0) * S),
                         ((x0 + (x1 - x0) * t1) * S, (y0 + (y1 - y0) * t1) * S)], fill=255, width=max(int(rw * 2 * S), 1))
        m = blur(np.asarray(im, float) / 255.0, 1.0)
        d = np.clip(m * fx.get("a", 0.9), 0, 1)
        canvas = canvas * (1 - d[..., None]) + d[..., None] * hexc(fx["color"])
    if fx["t"] == "dots":
        im = Image.new("L", (w, h), 0); dr = ImageDraw.Draw(im)
        for (x, y, r) in fx["pts"]:
            dr.ellipse([(x - r) * S, (y - r) * S, (x + r) * S, (y + r) * S], fill=255)
        m = blur(np.asarray(im, float) / 255.0, 1.0)
        col = hexc(fx["color"])
        d = np.clip(m * fx.get("a", 0.9), 0, 1)
        if fx.get("light"):
            canvas = canvas * (1 - d[..., None]) + d[..., None] * col
        else:
            canvas *= 1 - d[..., None] * (1 - col[None, None, :])

# ink pass from Grease Pencil
ink = np.asarray(Image.open(inkp).convert("RGBA"), float) / 255.0
if ink.shape[:2] != (h, w):
    ink = np.asarray(Image.open(inkp).convert("RGBA").resize((w, h), Image.LANCZOS), float) / 255.0
ia = ink[..., 3] * (1 - ink[..., :3].mean(axis=2) * 0.0)
ia = np.clip(ia * (0.93 + 0.07 * gran_n), 0, 1)
canvas = canvas * (1 - ia[..., None]) + ia[..., None] * INK[None, None, :] * (canvas * 0.35 + 0.65)

canvas = np.clip(canvas, 0, 1)
img = Image.fromarray((canvas * 255).astype(np.uint8))
img = img.resize((int(W * 2), int(H * 2)), Image.LANCZOS)
img.save(out)
print("saved", out, img.size)
