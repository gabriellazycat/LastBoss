"""Minimal SVG path sampling (M L C Q Z, absolute + relative l/q/c) and silhouette tools, used to
trace the v2 card art 1:1 (cartas_v2.html geometry) into Grease Pencil control points."""
import re, math
import numpy as np
from PIL import Image, ImageDraw


def sample(d, step=0.6):
    """Return list of polylines (one per subpath) as Nx2 arrays."""
    toks = re.findall(r"[MLCQZmlcqz]|-?\d*\.?\d+(?:e-?\d+)?", d)
    i, cmd, cur, start = 0, None, np.zeros(2), np.zeros(2)
    out, poly = [], []

    def num():
        nonlocal i
        v = float(toks[i]); i += 1
        return v

    while i < len(toks):
        t = toks[i]
        if re.match(r"[A-Za-z]", t):
            cmd = t; i += 1
            if cmd in "Zz":
                if poly:
                    poly.append(start.copy()); out.append(np.array(poly)); poly = []
                cur = start.copy()
                continue
        rel = cmd.islower()
        base = cur if rel else np.zeros(2)
        C = cmd.upper()
        if C == "M":
            if poly:
                out.append(np.array(poly))
            cur = base + [num(), num()]; start = cur.copy(); poly = [cur.copy()]
            cmd = "l" if rel else "L"
        elif C == "L":
            p = base + [num(), num()]
            n = max(int(np.linalg.norm(p - cur) / step), 1)
            for k in range(1, n + 1):
                poly.append(cur + (p - cur) * k / n)
            cur = p
        elif C == "Q":
            c1 = base + [num(), num()]; p = base + [num(), num()]
            L = np.linalg.norm(c1 - cur) + np.linalg.norm(p - c1)
            n = max(int(L / step), 2)
            for k in range(1, n + 1):
                s = k / n
                poly.append((1 - s) ** 2 * cur + 2 * (1 - s) * s * c1 + s * s * p)
            cur = p
        elif C == "C":
            c1 = base + [num(), num()]; c2 = base + [num(), num()]; p = base + [num(), num()]
            L = np.linalg.norm(c1 - cur) + np.linalg.norm(c2 - c1) + np.linalg.norm(p - c2)
            n = max(int(L / step), 2)
            for k in range(1, n + 1):
                s = k / n
                poly.append((1 - s) ** 3 * cur + 3 * (1 - s) ** 2 * s * c1 + 3 * (1 - s) * s * s * c2 + s ** 3 * p)
            cur = p
    if poly:
        out.append(np.array(poly))
    return out


def brush(pts, w0, w1, pw=1.0):
    """Ribbon around a centerline, width w0 -> w1 (like brushD in cartas_v2)."""
    P = np.asarray(pts, float)
    d = np.r_[0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
    t = d / d[-1]
    wv = (w0 + (w1 - w0) * t ** pw) / 2
    tg = np.gradient(P, axis=0); tg /= np.linalg.norm(tg, axis=1, keepdims=True) + 1e-9
    nr = np.c_[tg[:, 1], -tg[:, 0]]
    return np.vstack([P + nr * wv[:, None], (P - nr * wv[:, None])[::-1]])


class Xf:
    """card coords -> art-window coords (frame A window starts at 11,11)."""
    def __init__(self, char=True):
        a = math.radians(-7)
        self.char = char
        self.M = 1.12 * np.array([[math.cos(a), -math.sin(a)], [math.sin(a), math.cos(a)]])

    def __call__(self, P):
        P = np.asarray(P, float)
        if self.char:
            P = (P - [150, 146]) @ self.M.T + [150, 150]
        return P - 11


SC = 4  # raster px/unit for unions


def union_outline(polys, smooth=3, eps=0.3, pad=40):
    """Raster union of polygons (art coords) -> outer contour polyline(s), simplified."""
    import matplotlib
    matplotlib.use("Agg")
    from matplotlib import pyplot as plt
    W, H = int((278 + 2 * pad) * SC), int((267 + 2 * pad) * SC)
    im = Image.new("L", (W, H), 0); dr = ImageDraw.Draw(im)
    for p in polys:
        q = (np.asarray(p) + pad) * SC
        dr.polygon([tuple(x) for x in q], fill=255)
    a = np.asarray(im, float) / 255.0
    fig = plt.figure()
    cs = plt.contour(a, levels=[0.5])
    paths = []
    for seg in cs.allsegs[0]:
        if len(seg) > 20:
            paths.append(seg)
    plt.close(fig)
    res = []
    for seg in sorted(paths, key=len, reverse=True):
        P = seg / SC - pad
        if smooth > 1:
            k = np.ones(smooth) / smooth
            Pp = np.vstack([P[-smooth:], P, P[:smooth]])
            P = np.c_[np.convolve(Pp[:, 0], k, "same"), np.convolve(Pp[:, 1], k, "same")][smooth:-smooth]
        res.append(rdp(P, eps))
    return res


def rdp(P, eps):
    P = np.asarray(P, float)
    if len(P) < 3:
        return P
    a, b = P[0], P[-1]
    ab = b - a
    L = np.linalg.norm(ab)
    if L < 1e-9:
        d = np.linalg.norm(P - a, axis=1)
    else:
        d = np.abs(ab[0] * (P[:, 1] - a[1]) - ab[1] * (P[:, 0] - a[0])) / L
    i = int(np.argmax(d))
    if d[i] > eps:
        l = rdp(P[: i + 1], eps); r = rdp(P[i:], eps)
        return np.vstack([l[:-1], r])
    return np.vstack([a, b])
