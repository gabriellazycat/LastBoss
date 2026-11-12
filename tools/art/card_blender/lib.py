"""Design helpers: hand-drawn ink strokes (centerline + pressure) and wash shapes.
Coordinates: art window 278 x 267 units, x right, y down (1 unit = 2 px in the final PNG)."""
import json, math
import numpy as np

W, H = 278.0, 267.0
LIGHT = np.array([-0.6, -0.8])          # light from upper-left (screen coords, y down)
INK_SCALE = 0.72
SHADOW = -LIGHT / np.linalg.norm(LIGHT)


def _rng(seed):
    return np.random.default_rng(seed)


def cr(ctrl, closed=False, n=14):
    """Centripetal Catmull-Rom through control points -> dense polyline."""
    P = np.asarray(ctrl, float)
    if closed:
        P = np.vstack([P[-1], P, P[0], P[1]])
    else:
        P = np.vstack([2 * P[0] - P[1], P, 2 * P[-1] - P[-2]])
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        t0 = 0.0
        t1 = t0 + max(np.linalg.norm(p1 - p0), 1e-3) ** 0.5
        t2 = t1 + max(np.linalg.norm(p2 - p1), 1e-3) ** 0.5
        t3 = t2 + max(np.linalg.norm(p3 - p2), 1e-3) ** 0.5
        for t in np.linspace(t1, t2, n, endpoint=False):
            a1 = (t1 - t) / (t1 - t0) * p0 + (t - t0) / (t1 - t0) * p1
            a2 = (t2 - t) / (t2 - t1) * p1 + (t - t1) / (t2 - t1) * p2
            a3 = (t3 - t) / (t3 - t2) * p2 + (t - t2) / (t3 - t2) * p3
            b1 = (t2 - t) / (t2 - t0) * a1 + (t - t0) / (t2 - t0) * a2
            b2 = (t3 - t) / (t3 - t1) * a2 + (t - t1) / (t3 - t1) * a3
            out.append((t2 - t) / (t2 - t1) * b1 + (t - t1) / (t2 - t1) * b2)
    if closed:
        out.append(out[0])
    else:
        out.append(P[-2])
    return np.array(out)


def resample(pts, step=0.8):
    pts = np.asarray(pts, float)
    d = np.r_[0, np.cumsum(np.linalg.norm(np.diff(pts, axis=0), axis=1))]
    if d[-1] < 1e-6:
        return pts
    s = np.linspace(0, d[-1], max(int(d[-1] / step), 2))
    return np.c_[np.interp(s, d, pts[:, 0]), np.interp(s, d, pts[:, 1])]


def normals(pts):
    t = np.gradient(pts, axis=0)
    t /= np.linalg.norm(t, axis=1, keepdims=True) + 1e-9
    return np.c_[t[:, 1], -t[:, 0]], t


def smooth_noise(n, seed, scale=40.0):
    r = _rng(seed)
    k = max(int(n / scale) + 3, 4)
    v = r.normal(size=k)
    return np.interp(np.linspace(0, k - 1, n), np.arange(k), v)


def wobble(pts, amp=0.5, seed=0, scale=40):
    nrm, _ = normals(pts)
    return pts + nrm * (smooth_noise(len(pts), seed, scale) * amp)[:, None]


class Scene:
    def __init__(self, name):
        self.name = name
        self.layers = []     # [{name, holdout:[poly...], strokes:[{pts, r, a}]}]
        self.washes = []     # [{poly, color, alpha, z, shade, spill, seed, ...}]
        self.fx = []         # extra raster fx (glows, ember dots) handled by compositor
        self._seed = 1

    def seed(self):
        self._seed += 7
        return self._seed

    def layer(self, name, holdout=None, holes=None):
        L = {"name": name, "holdout": [], "strokes": []}
        if holes:       # opcional: buracos da silhueta (o que esta atras aparece por eles)
            L["holes"] = [np.asarray(x, float) for x in holes]
        if holdout is not None:
            for h in (holdout if isinstance(holdout, list) and holdout and isinstance(holdout[0], np.ndarray) else [holdout]):
                L["holdout"].append(np.asarray(h, float))
        self.layers.append(L)
        return L

    # ---------- ink ----------
    def stroke(self, L, pts, w=1.0, tin=0.18, tout=0.22, over=2.0, shade=0.55,
               jit=0.35, op=0.95, min_r=0.12, swell=0.15, closed=False):
        """One pressure stroke. w = max half-width (units). tin/tout = taper fraction.
        over = overshoot length added past each end (tapered). shade = how much thicker on
        the shadow-facing side (thick-thin by light direction)."""
        pts = resample(pts, 0.6)
        if len(pts) < 2:
            return
        if over > 0 and not closed:
            _, tg = normals(pts)
            a = pts[0] - tg[0] * np.linspace(over, 0, 4)[:, None]
            b = pts[-1] + tg[-1] * np.linspace(0, over, 4)[:, None]
            pts = np.vstack([a[:-1], pts, b[1:]])
            pts = resample(pts, 0.6)
        s = self.seed()
        pts = wobble(pts, jit, s, 50)
        n = len(pts)
        u = np.linspace(0, 1, n)
        L_len = np.sum(np.linalg.norm(np.diff(pts, axis=0), axis=1))
        # taper in absolute-ish length so short strokes still taper
        ti = min(tin, 0.45) if not closed else 0.0
        to = min(tout, 0.45) if not closed else 0.0
        env = np.ones(n)
        if ti > 0:
            env = np.minimum(env, np.clip(u / ti, 0, 1) ** 0.7)
        if to > 0:
            env = np.minimum(env, np.clip((1 - u) / to, 0, 1) ** 0.6)
        nrm, _ = normals(pts)
        facing = nrm @ SHADOW            # +1 where the outward normal faces the shadow
        if np.mean(facing) == np.mean(facing):
            pass
        thick = 1.0 + shade * facing
        press = 1.0 + swell * smooth_noise(n, s + 3, 30)
        r = INK_SCALE * w * np.clip(env * thick * press, 0, None)
        r = np.maximum(r, min_r * w * INK_SCALE)
        a = np.clip(op * (0.8 + 0.2 * env), 0, 1)
        L["strokes"].append({"pts": pts, "r": r, "a": a})

    def contour(self, L, ctrl, w=1.1, breaks=(0.0, 0.37, 0.71), gap=0.012, overlap=0.03,
                shade=0.85, jit=0.4, op=0.95, n=14, orient=None, lin=False):
        """Closed silhouette drawn as a few long strokes that overlap/overshoot at the joins,
        like a hand contour. orient: +1/-1 forces outward normal sign (auto by area)."""
        P = np.vstack([ctrl, ctrl[:1]]) if lin else cr(ctrl, closed=True, n=n)
        P = resample(np.asarray(P, float), 0.6)
        # make outward normals consistent: shoelace sign (y down)
        area = 0.5 * np.sum(P[:-1, 0] * P[1:, 1] - P[1:, 0] * P[:-1, 1])
        if area < 0:
            P = P[::-1]
        m = len(P) - 1
        r = _rng(self.seed())
        bs = sorted(breaks)
        for i, b0 in enumerate(bs):
            b1 = bs[(i + 1) % len(bs)] + (1.0 if i == len(bs) - 1 else 0.0)
            s0 = b0 + gap * r.uniform(-1, 1)
            s1 = b1 + overlap * r.uniform(0.3, 1)
            idx = (np.arange(int(s0 * m), int(s1 * m)) % m)
            seg = P[idx]
            # lift the ends slightly off the path (hand doesn't land exactly on the line)
            off = r.uniform(-0.9, 0.9)
            nrm, _ = normals(seg)
            k = np.linspace(1, 0, len(seg)) ** 6
            seg = seg + nrm * (off * k)[:, None]
            self.stroke(L, seg, w=w, tin=0.08, tout=0.1, over=1.2, shade=shade, jit=jit, op=op)
        return P

    def line(self, L, ctrl, w=0.8, n=12, **kw):
        P = cr(ctrl, n=n) if len(ctrl) > 2 else resample(np.asarray(ctrl, float), 0.6)
        self.stroke(L, P, w=w, **kw)
        return P

    def dot(self, L, c, rad=1.6, op=0.95):
        c = np.asarray(c, float)
        pts = np.array([c + [-rad * 0.3, 0], c + [rad * 0.3, 0.1]])
        L["strokes"].append({"pts": resample(pts, 0.2), "r": np.full(len(resample(pts, 0.2)), rad), "a": np.full(len(resample(pts, 0.2)), op)})

    # ---------- colour ----------
    def wash(self, poly, color, alpha=0.75, z=0, shade=0.45, spill=2.2, seed=None,
             dry=0.0, shadow_color=None, light_cut=0.0, bloom=0.0, gran=1.0, edge=1.0,
             shift=(1.2, 1.0), knock=None, soft=0.0, ksoft=2.5, mis=1.3, clip=None, csoft=1.0, lift=False):
        self.washes.append(dict(li=len(self.layers) - 1, poly=np.asarray(poly, float), color=color, alpha=alpha, z=z,
                                shade=shade, spill=spill, seed=seed or self.seed(), dry=dry,
                                shadow_color=shadow_color, light_cut=light_cut, bloom=bloom,
                                gran=gran, edge=edge, shift=shift, knock=knock, soft=soft, ksoft=ksoft, mis=mis, clip=clip, csoft=csoft, lift=lift))

    def occlude(self):
        """Hide ink that lies behind the silhouettes of later (front) layers: split strokes."""
        from matplotlib.path import Path
        for i, L in enumerate(self.layers):
            fronts = [Path(h) for M in self.layers[i + 1:] for h in M["holdout"]]
            if not fronts:
                continue
            new = []
            for s in L["strokes"]:
                hid = np.zeros(len(s["pts"]), bool)
                for fp in fronts:
                    hid |= fp.contains_points(s["pts"])
                vis = ~hid
                # runs of visible points
                idx = np.flatnonzero(np.diff(np.r_[0, vis.astype(int), 0]))
                for a, b in zip(idx[::2], idx[1::2]):
                    if b - a < 3:
                        continue
                    new.append({"pts": s["pts"][a:b], "r": s["r"][a:b], "a": s["a"][a:b]})
            L["strokes"] = new

    def save(self, path):
        self.occlude()
        def enc(o):
            if isinstance(o, np.ndarray):
                return o.round(3).tolist()
            raise TypeError
        with open(path, "w") as f:
            holds = [L["holdout"] for L in self.layers]
            json.dump({"holds": holds, "name": self.name, "W": W, "H": H, "layers": self.layers,
                       "washes": self.washes, "fx": self.fx}, f, default=enc)


# ---------- shape helpers ----------
def ribbon(center, widths, n=10, cap_end=True):
    """Closed outline around a centerline with varying half-widths (tail, rod, limbs)."""
    C = resample(cr(center, n=n) if len(center) > 2 else np.asarray(center, float), 1.0)
    wv = np.interp(np.linspace(0, 1, len(C)), np.linspace(0, 1, len(widths)), widths)
    nrm, tg = normals(C)
    left = C + nrm * wv[:, None]
    right = C - nrm * wv[:, None]
    return np.vstack([left, right[::-1]])


def ellipse(c, rx, ry, rot=0.0, n=24):
    t = np.linspace(0, 2 * np.pi, n, endpoint=False)
    x, y = rx * np.cos(t), ry * np.sin(t)
    cr_, sr = math.cos(rot), math.sin(rot)
    return np.c_[c[0] + x * cr_ - y * sr, c[1] + x * sr + y * cr_]


def rot(pts, ang, c):
    pts = np.asarray(pts, float) - c
    ca, sa = math.cos(ang), math.sin(ang)
    return np.c_[pts[:, 0] * ca - pts[:, 1] * sa, pts[:, 0] * sa + pts[:, 1] * ca] + c


def polar(c, ang_deg, r):
    a = math.radians(ang_deg)
    return np.array([c[0] + r * math.cos(a), c[1] - r * math.sin(a)])


def shape(ctrl, lin=False, n=14):
    """The closed path a contour() follows (for holdout + washes)."""
    ctrl = np.asarray(ctrl, float)
    P = np.vstack([ctrl, ctrl[:1]]) if lin else cr(ctrl, closed=True, n=n)
    return resample(P, 1.0)


def ribbon_sides(center, widths, n=10):
    C = resample(cr(center, n=n) if len(center) > 2 else np.asarray(center, float), 0.8)
    wv = np.interp(np.linspace(0, 1, len(C)), np.linspace(0, 1, len(widths)), widths)
    nrm, tg = normals(C)
    return C + nrm * wv[:, None], C - nrm * wv[:, None]


def place(local, c, ang_deg):
    a = math.radians(ang_deg)
    d = np.array([math.cos(a), -math.sin(a)]); p = np.array([math.sin(a), math.cos(a)])
    L = np.asarray(local, float)
    return c + L[:, :1] * d + L[:, 1:2] * p
