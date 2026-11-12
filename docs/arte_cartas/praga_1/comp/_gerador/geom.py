"""Geometria da composição: splines Catmull-Rom -> paths SVG só com M/L/C/Z (o que o svgpath.sample lê)."""
import math, re, sys
import numpy as np

sys.path.insert(0, "C:/Users/gabri/Desktop/LastBoss/tools/art/card_blender")


def fmt(v):
    s = f"{v:.1f}"
    if s.endswith(".0"):
        s = s[:-2]
    return "0" if s in ("-0", "") else s


def A(p):
    return np.asarray(p, float)


# ------------------------------------------------------------------ transformações afins (3x3)
def T(tx=0, ty=0):
    return np.array([[1, 0, tx], [0, 1, ty], [0, 0, 1]], float)


def R(deg):
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]], float)


def S(sx, sy=None):
    sy = sx if sy is None else sy
    return np.array([[sx, 0, 0], [0, sy, 0], [0, 0, 1]], float)


def chain(*Ms):
    M = np.eye(3)
    for m in Ms:
        M = M @ m
    return M


def ap(M, pts):
    P = np.atleast_2d(A(pts))
    Q = (np.c_[P, np.ones(len(P))] @ M.T)[:, :2]
    return Q


def tstr(tx, ty, rot=0, sx=1, sy=None):
    sy = sx if sy is None else sy
    fmt = lambda v: (f"{v:.3f}".rstrip("0").rstrip(".") or "0")
    s = f"translate({fmt(tx)} {fmt(ty)})"
    if rot:
        s += f" rotate({fmt(rot)})"
    if sx != 1 or sy != 1:
        s += f" scale({fmt(sx)} {fmt(sy)})" if sx != sy else f" scale({fmt(sx)})"
    return s


def tmat(tx, ty, rot=0, sx=1, sy=None):
    sy = sx if sy is None else sy
    return chain(T(tx, ty), R(rot), S(sx, sy))


# ------------------------------------------------------------------ paths
def cr_path(pts, closed=True):
    P = [A(p) for p in pts]; n = len(P)
    d = f"M{fmt(P[0][0])} {fmt(P[0][1])}"
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        if closed:
            p0, p1, p2, p3 = P[(i - 1) % n], P[i], P[(i + 1) % n], P[(i + 2) % n]
        else:
            p0, p1, p2, p3 = P[max(0, i - 1)], P[i], P[i + 1], P[min(n - 1, i + 2)]
        c1 = p1 + (p2 - p0) / 6; c2 = p2 - (p3 - p1) / 6
        d += f" C{fmt(c1[0])} {fmt(c1[1])} {fmt(c2[0])} {fmt(c2[1])} {fmt(p2[0])} {fmt(p2[1])}"
    return d + ("Z" if closed else "")


def poly_path(pts, closed=True):
    P = A(pts)
    d = f"M{fmt(P[0][0])} {fmt(P[0][1])}" + "".join(f" L{fmt(x)} {fmt(y)}" for x, y in P[1:])
    return d + ("Z" if closed else "")


def cr_sample(pts, per=6, closed=False):
    P = [A(p) for p in pts]; n = len(P); out = []
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        if closed:
            p0, p1, p2, p3 = P[(i - 1) % n], P[i], P[(i + 1) % n], P[(i + 2) % n]
        else:
            p0, p1, p2, p3 = P[max(0, i - 1)], P[i], P[i + 1], P[min(n - 1, i + 2)]
        for k in range(per):
            t = k / per
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                              + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    if not closed:
        out.append(P[-1])
    return np.array(out)


def tube(spine, wa, wb=None, cap0=0.7, cap1=0.7, per=4, jag=0, jag_range=(0.15, 0.8)):
    """Contorno fechado em volta de uma espinha. wa = espessura do lado 'de cima' (à esquerda do sentido),
    wb = do outro lado. Larguras dadas por ponto da espinha."""
    wb = wa if wb is None else wb
    sp = cr_sample(spine, per)
    n0 = len(spine)
    u = np.linspace(0, n0 - 1, len(sp))
    WA = np.interp(u, range(n0), wa); WB = np.interp(u, range(n0), wb)
    Tg = np.gradient(sp, axis=0); Tg /= np.linalg.norm(Tg, axis=1)[:, None] + 1e-9
    N = np.c_[-Tg[:, 1], Tg[:, 0]]
    a = sp - N * WA[:, None]; b = sp + N * WB[:, None]
    if jag:
        m = len(a)
        for i in range(int(m * jag_range[0]), int(m * jag_range[1])):
            if i % 2 == 0:
                a[i] = a[i] - N[i] * jag
    sel = list(range(0, len(sp), 2))
    if sel[-1] != len(sp) - 1:
        sel.append(len(sp) - 1)
    A_ = a[sel]; B_ = b[sel]
    e = sp[-1] + Tg[-1] * cap1 * (WA[-1] + WB[-1]) / 2
    s = sp[0] - Tg[0] * cap0 * (WA[0] + WB[0]) / 2
    pts = list(A_) + ([e] if cap1 > 0 else []) + list(B_[::-1]) + ([s] if cap0 > 0 else [])
    return pts


def brush(pts, w0, w1, per=4):
    n = len(pts)
    w = list(np.linspace(w0, w1, n) / 2)
    return tube(pts, w, w, cap0=0.6, cap1=0.0, per=per)


def ellipse(cx, cy, rx, ry, rot=0, n=10):
    pts = [(rx * math.cos(2 * math.pi * k / n), ry * math.sin(2 * math.pi * k / n)) for k in range(n)]
    return list(ap(chain(T(cx, cy), R(rot)), pts))


def blob(cx, cy, r, seed, n=9, j=0.22, sy=1.0):
    q = np.random.default_rng(seed)
    pts = []
    for i in range(n):
        a = i / n * 2 * math.pi + q.random() * 0.3
        rr = r * (1 - j + q.random() * 2 * j)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr * sy))
    return pts


def wedge(x1, y1, x2, y2, w):
    dx, dy = x2 - x1, y2 - y1; l = math.hypot(dx, dy) or 1; nx, ny = -dy / l, dx / l
    return [(x1 + nx * w / 2, y1 + ny * w / 2), (x2, y2), (x1 - nx * w / 2, y1 - ny * w / 2)]


# ------------------------------------------------------------------ path cru (M L C Q Z absolutos) transformado
def xform_d(d, M):
    toks = re.findall(r"[MLCQZ]|-?\d*\.?\d+(?:e-?\d+)?", d)
    out = []; i = 0; cmd = None
    need = {"M": 1, "L": 1, "C": 3, "Q": 2}
    while i < len(toks):
        t = toks[i]
        if t.isalpha():
            cmd = t; i += 1
            if cmd == "Z":
                out.append("Z"); continue
        k = need[cmd]
        pts = [(float(toks[i + 2 * j]), float(toks[i + 2 * j + 1])) for j in range(k)]
        i += 2 * k
        q = ap(M, pts)
        out.append(cmd + " ".join(f"{fmt(x)} {fmt(y)}" for x, y in q))
        if cmd == "M":
            cmd = "L"
    return " ".join(out)


def bez_points(d, step=1.0):
    from svgpath import sample
    return sample(d, step)


# ------------------------------------------------------------------ peças
class Pc:
    """Uma peça anatômica (ou de cenário). pts -> spline fechada; d -> path cru."""
    def __init__(self, id, fig, fill, pts=None, d=None, closed=True, cls=None, mode="cr", sw=None, op=None):
        self.id, self.fig, self.fill, self.pts, self.d = id, fig, fill, pts, d
        self.closed, self.cls, self.mode, self.sw, self.op = closed, cls, mode, sw, op

    def moved(self, M):
        if self.pts is not None:
            return Pc(self.id, self.fig, self.fill, pts=list(ap(M, self.pts)), closed=self.closed, cls=self.cls,
                      mode=self.mode, sw=self.sw, op=self.op)
        return Pc(self.id, self.fig, self.fill, d=xform_d(self.d, M), closed=self.closed, cls=self.cls,
                  mode=self.mode, sw=self.sw, op=self.op)

    def dstr(self):
        if self.d is not None:
            return self.d
        return (cr_path if self.mode == "cr" else poly_path)(self.pts, self.closed)

    def svg(self, prefix=None, idp=""):
        fig = f"{prefix}_{self.fig}" if prefix else self.fig
        a = f'<path id="{idp}{self.id}" data-fig="{fig}"'
        if self.cls:
            a += f' class="{self.cls}"'
        if self.closed:
            a += f' fill="{self.fill}"'
        else:
            a += f' fill="none" stroke="{self.fill}" stroke-width="{fmt(self.sw or 1)}" stroke-linecap="round"'
        if self.op is not None:
            a += f' opacity="{self.op}"'
        return a + f' d="{self.dstr()}"/>'


def figure_svg(name, pcs, transform, prefix=None, idp=None):
    prefix = prefix or name
    idp = (idp if idp is not None else name + "_")
    body = "\n    ".join(p.svg(prefix, idp) for p in pcs)
    return f'  <g id="fig_{name}" transform="{transform}">\n    {body}\n  </g>'


def union_poly(pcs, M=None, off=(0, 0)):
    """União das peças (fechadas, não-inner) -> um contorno (para silhuetas de multidão)."""
    from svgpath import union_outline
    polys = []
    for p in pcs:
        if not p.closed or p.cls:
            continue
        q = p.moved(M) if M is not None else p
        for poly in bez_points(q.dstr(), 1.0):
            if len(poly) > 2:
                polys.append(poly + A(off))
    outs = union_outline(polys, smooth=3, eps=0.35)
    return [o - A(off) for o in outs]
