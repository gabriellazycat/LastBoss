# pure-python geometry shared by preview (PIL) and Krita painter
import math, random

def catmull(pts, closed=False, step=3.0):
    """Sample a centripetal-ish Catmull-Rom spline through pts at ~step px."""
    P = list(pts)
    if closed:
        P = [P[-1]] + P + [P[0], P[1]]
    else:
        P = [P[0]] + P + [P[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i-1], P[i], P[i+1], P[i+2]
        d = math.hypot(p2[0]-p1[0], p2[1]-p1[1])
        n = max(2, int(d / step))
        for k in range(n):
            t = k / n; t2 = t*t; t3 = t2*t
            x = 0.5*((2*p1[0]) + (-p0[0]+p2[0])*t + (2*p0[0]-5*p1[0]+4*p2[0]-p3[0])*t2 + (-p0[0]+3*p1[0]-3*p2[0]+p3[0])*t3)
            y = 0.5*((2*p1[1]) + (-p0[1]+p2[1])*t + (2*p0[1]-5*p1[1]+4*p2[1]-p3[1])*t2 + (-p0[1]+3*p1[1]-3*p2[1]+p3[1])*t3)
            out.append((x, y))
    out.append(P[-2] if not closed else P[1])
    return out

def overshoot(samples, amount):
    """extend the last sample a little along its tangent (hand overshoot)."""
    if amount <= 0 or len(samples) < 3: return samples
    (x1, y1), (x2, y2) = samples[-3], samples[-1]
    d = math.hypot(x2-x1, y2-y1) or 1
    return samples + [(x2 + (x2-x1)/d*amount, y2 + (y2-y1)/d*amount)]

def pressures(samples, taper_in=0.12, taper_out=0.18, light=(-0.6, -0.8), shade=0.45,
              lo=0.08, wobble=0.06, seed=1, closed=False, mults=None):
    """pressure per sample: tapered ends, heavier where the outward normal faces
    away from the light (shadow side), small hand wobble."""
    rnd = random.Random(seed)
    n = len(samples)
    # signed area -> orientation, so we know which normal is 'outward'
    area = 0
    for i in range(n - 1):
        area += samples[i][0]*samples[i+1][1] - samples[i+1][0]*samples[i][1]
    sgn = 1 if area > 0 else -1
    lx, ly = light
    out = []
    ph = rnd.random() * 6
    for i, (x, y) in enumerate(samples):
        u = i / max(1, n - 1)
        a = samples[max(0, i-2)]; b = samples[min(n-1, i+2)]
        tx, ty = b[0]-a[0], b[1]-a[1]; d = math.hypot(tx, ty) or 1
        nx, ny = (-ty/d*sgn, tx/d*sgn)  # outward normal for closed-ish shapes
        facing = -(nx*lx + ny*ly)       # >0 when facing away from light
        p = 0.62 + shade * max(0.0, facing) - 0.15 * max(0.0, -facing)
        p *= 1 + wobble * math.sin(ph + u * 23.0)
        t = 1.0
        if taper_in > 0 and u < taper_in: t = min(t, (u / taper_in) ** 0.7)
        if taper_out > 0 and u > 1 - taper_out: t = min(t, ((1 - u) / taper_out) ** 0.8)
        if mults:
            for (u0, u1, m) in mults:
                if u0 <= u <= u1: p *= m
        out.append(max(lo, min(1.0, p * (lo + (1 - lo) * t))))
    return out

def point_in_poly(x, y, poly):
    c = False; n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]; xj, yj = poly[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / ((yj - yi) or 1e-9) + xi):
            c = not c
        j = i
    return c

def scribble(poly, spacing, angle_deg=-35, jitter=6, seed=3, inset=0.0):
    """boustrophedon hatch path filling poly (list of (x,y)), rotated by angle.
    Returns one continuous list of points (for one long brush stroke)."""
    rnd = random.Random(seed)
    a = math.radians(angle_deg); ca, sa = math.cos(a), math.sin(a)
    rot = [(x*ca + y*sa, -x*sa + y*ca) for x, y in poly]
    ys = [p[1] for p in rot]
    y = min(ys) + spacing * 0.5
    rows = []
    while y < max(ys):
        xs = []
        n = len(rot)
        for i in range(n):
            (x1, y1), (x2, y2) = rot[i], rot[(i+1) % n]
            if (y1 <= y < y2) or (y2 <= y < y1):
                xs.append(x1 + (y - y1) * (x2 - x1) / (y2 - y1))
        xs.sort()
        segs = [(xs[i] + inset, xs[i+1] - inset) for i in range(0, len(xs) - 1, 2) if xs[i+1] - xs[i] > 2*inset + 2]
        if segs:
            rows.append((y, segs))
        y += spacing * (0.8 + 0.4 * rnd.random())
    # split into strands so concave polygons / holes are not bridged:
    strands = []  # each: [last_seg, rows]
    for (y, segs) in rows:
        for s in segs:
            best = None
            for st in strands:
                ls = st[0]
                if st[2] == y: continue
                if s[0] < ls[1] and s[1] > ls[0] and st[3] is not None and abs(y - st[3]) < spacing * 2.5:
                    best = st; break
            if best is None:
                best = [s, [], None, None]; strands.append(best)
            best[0] = s; best[1].append((y, s)); best[2] = y; best[3] = y
        for st in strands: st[2] = None
    paths = []
    for st in strands:
        pts = []; flip = False
        for (y, (x0, x1)) in st[1]:
            row = [(x0, y + rnd.uniform(-jitter, jitter)), (x1, y + rnd.uniform(-jitter, jitter))]
            if flip: row.reverse()
            flip = not flip
            pts.extend(row)
        if len(pts) >= 2:
            paths.append([(x*ca - y*sa, x*sa + y*ca) for x, y in pts])
    return paths

def ellipse(cx, cy, rx, ry, n=10, rot=0.0, jit=0.0, seed=0):
    rnd = random.Random(seed)
    r = math.radians(rot)
    out = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x = rx * math.cos(t) * (1 + rnd.uniform(-jit, jit)); y = ry * math.sin(t) * (1 + rnd.uniform(-jit, jit))
        out.append((cx + x*math.cos(r) - y*math.sin(r), cy + x*math.sin(r) + y*math.cos(r)))
    return out

def offset(poly, dx, dy, grow=1.0, seed=0, jit=0.0):
    rnd = random.Random(seed)
    cx = sum(p[0] for p in poly) / len(poly); cy = sum(p[1] for p in poly) / len(poly)
    return [(cx + (x - cx) * grow + dx + rnd.uniform(-jit, jit), cy + (y - cy) * grow + dy + rnd.uniform(-jit, jit)) for x, y in poly]
