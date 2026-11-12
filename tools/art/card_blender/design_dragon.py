"""Dragao Anciao (elder_dragon): traced 1:1 from the v2 card art (artDragon in cartas_v2.html).
The v2 geometry is read from its own SVG path data, put through the same character transform
(translate(150 150) rotate(-7) scale(1.12) translate(-150 -146)), merged into one silhouette per
figure (raster union -> contour) and redrawn as Grease Pencil pressure strokes."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import *
from svgpath import sample, brush, Xf, union_outline

S = Scene("elder_dragon")
X = Xf(True)      # character group
B = Xf(False)     # background (no transform)
FIG = []
rng = np.random.default_rng(131)


def sp(d, xf=X):
    return [xf(p) for p in sample(d)]


def one(d, xf=X):
    return sp(d, xf)[0]


def outline(polys, **kw):
    return union_outline(polys, **kw)[0]


# ======================= background =======================
moon = B(ellipse((150, 106), 98, 98, n=48))
Lm = S.layer("moon")
S.line(Lm, [B(polar((150, 106), a, 98)) for a in np.linspace(200, 335, 10)], w=0.5, op=0.4, tin=0.4, tout=0.4)

castle_d = ("M-20 330 L20 330 L20 296 L14 296 L14 286 L22 286 L22 292 L28 292 L28 286 L36 286 L36 296 L30 296 "
            "L30 320 L60 320 L60 270 L52 270 L64 248 L76 270 L68 270 L68 320 L96 320 L96 300 L104 300 L104 306 "
            "L110 306 L110 300 L118 300 L118 330 L190 330 L190 290 L184 290 L196 262 L208 290 L202 290 L202 330 "
            "L232 330 L232 304 L240 304 L240 310 L246 310 L246 304 L254 304 L254 330 L320 330 L320 440 L-20 440Z")
castle = one(castle_d, B)
Lca = S.layer("castle", holdout=castle)
S.wash(castle, "#3a1210", alpha=0.75, z=3, shade=0.2, shadow_color="#1a0606", spill=1.0, mis=0.6)
for (fx_, fy, fs) in [(64, 248, 16), (196, 262, 18), (110, 300, 12), (244, 304, 12), (26, 286, 10)]:
    for k in range(3):
        x = fx_ + (rng.random() - .5) * fs; hh = fs * (1.4 + rng.random() * 1.4)
        d = (f"M{x - fs * .35} {fy} C{x - fs * .4} {fy - hh * .5} {x + fs * .1} {fy - hh * .6} {x + (rng.random() - .5) * 6} {fy - hh} "
             f"C{x + fs * .3} {fy - hh * .5} {x + fs * .45} {fy - hh * .3} {x + fs * .35} {fy} Z")
        S.wash(one(d, B), "#ffc23c", alpha=0.85, z=4, shade=0.45, shadow_color="#e8582a", spill=1.4, edge=1.4, mis=0.6)
    S.wash(B(ellipse((fx_, fy - fs * 3), fs * 1.7, fs * 1.2, n=14)), "#4a1a16", alpha=0.35, z=2.6, shade=0, spill=3, soft=1.5)
FIG_LATE = []   # filled with the figure silhouettes later (same list object)
for y0 in range(150, 260, 26):
    band = one(f"M-30 {y0} Q80 {y0 - 14} 150 {y0 + 4} T330 {y0 - 6} L330 {y0 + 8} Q220 {y0 + 16} 150 {y0 + 14} T-30 {y0 + 12}Z".replace("T330", "Q240 " + str(y0 + 10) + " 330").replace("T-30", "Q60 " + str(y0 + 6) + " -30"), B)
    S.wash(band, "#9a3420" if (y0 // 26) % 2 else "#5a1a16", alpha=0.25, z=2.2, shade=0, spill=2, mis=1.5, soft=0.8, knock=FIG_LATE)

# ======================= wings =======================
def wing(Sx, E, W, F, body, side):
    Sx, E, W, body = map(np.array, (Sx, E, W, body))
    F = [np.array(f) for f in F]
    cx = lambda a, b, t: a + (W - a) * t + (b - a) * .5
    q = [cx(F[0], F[1], .38), cx(F[1], F[2], .36), cx(F[2], F[3], .34), cx(F[3], body, .3)]
    d = (f"M{Sx[0]} {Sx[1]} L{E[0]} {E[1]} L{W[0]} {W[1]} L{F[0][0]} {F[0][1]} Q{q[0][0]} {q[0][1]} {F[1][0]} {F[1][1]} "
         f"Q{q[1][0]} {q[1][1]} {F[2][0]} {F[2][1]} Q{q[2][0]} {q[2][1]} {F[3][0]} {F[3][1]} Q{q[3][0]} {q[3][1]} {body[0]} {body[1]} Z")
    memb = one(d)
    armc = X(sample(f"M{Sx[0]} {Sx[1]} L{E[0]} {E[1]} L{W[0]} {W[1]}")[0])
    arm = brush(cr(armc[::6] if len(armc) > 12 else armc, n=6), 20 * 1.12, 9 * 1.12)
    thumb = one(f"M{W[0]} {W[1]} q{side * -4} -10 {side * 2} -16 q{side * -1} 8 {side * 4} 12Z")
    sil = outline([memb, arm, thumb])
    Lw = S.layer("wing%d" % side, holdout=sil)
    S.contour(Lw, sil, w=1.15, breaks=(0.0, 0.27, 0.52, 0.78), lin=True)
    # the arm bone's inner edge (where the membrane hangs from it)
    nA = len(arm) // 2
    inner = arm[:nA] if side == -1 else arm[nA:][::-1]
    S.stroke(Lw, inner[int(len(inner) * 0.08):int(len(inner) * 0.92)], w=0.8, tin=0.25, tout=0.3, over=1.0)
    bones = []
    for i, f in enumerate(F):
        mx = (W[0] + f[0]) / 2 + side * (i - 1.5) * 4; my = (W[1] + f[1]) / 2
        bp = X(sample(f"M{W[0]} {W[1]} Q{mx} {my} {f[0]} {f[1]}")[0])
        bones.append(bp)
        S.stroke(Lw, bp, w=1.35, tin=0.04, tout=0.6, over=0, shade=0.5)
        # membrane fold toward the shoulder (faint)
        a0 = W * .6 + f * .4; c1 = np.array([mx, my]) * .5 + Sx * .5; a1 = Sx * .7 + f * .3
        S.line(Lw, list(X(np.array([a0, (a0 + c1) / 2 * 0.5 + c1 * 0.5, a1]))), w=0.35, op=0.5, tin=0.3, tout=0.5, over=0)
    # watercolour: light warm membrane, darker toward the wrist and along the bones, paper in places
    S.wash(memb, "#d8482a", alpha=0.72, z=8, shade=0.0, spill=2.2, light_cut=0.3, dry=0.25, bloom=1.2)
    Wa = X(W)
    S.wash(memb, "#7a1410", alpha=0.7, z=8.2, shade=0, spill=1.0, clip=[ellipse(Wa, 130, 130, n=36)], csoft=30, mis=0.8)
    S.wash(memb, "#3a0608", alpha=0.5, z=8.3, shade=0, spill=1.0, clip=[ellipse(Wa, 60, 60, n=30)], csoft=20, mis=0.8)
    for bp in bones:
        S.wash(memb, "#4a0a0a", alpha=0.6, z=8.4, shade=0, spill=0.5, mis=0.6,
               clip=[brush(bp[::4], 16, 3)], csoft=2.5)
    S.wash(arm, "#7a1810", alpha=0.8, z=8.6, shade=0.5, shadow_color="#3a0806", spill=0.8, mis=0.6)
    S.wash(thumb, "#f2e2c0", alpha=0.5, z=8.7, shade=0.3, spill=0.4, mis=0.3)
    FIG.append(sil)

wing([118, 170], [74, 120], [38, 58], [[-8, 10], [-16, 96], [4, 178], [60, 226]], [112, 228], -1)
wing([182, 170], [228, 116], [266, 50], [[314, 4], [320, 92], [300, 180], [244, 228]], [188, 228], 1)

# ======================= tail (behind body) =======================
tl = sample("M172 268 C212 296 254 300 268 330 C282 360 246 384 206 374 C186 368 176 380 170 398")[0]
tailp = brush(tl, 26, 3, 0.7)
spikes = []
d = np.r_[0, np.cumsum(np.linalg.norm(np.diff(tl, axis=0), axis=1))]
for i in range(1, 8):
    t = i / 9; s_ = d[-1] * t; j = int(np.searchsorted(d, s_)); p = tl[j]; p2 = tl[min(j + 3, len(tl) - 1)]
    dx, dy = (p2 - p) / (np.linalg.norm(p2 - p) + 1e-9); nx, ny = dy, -dx
    w_ = (26 - 23 * t ** .7) / 2
    spikes.append(np.array([(p[0] + nx * w_ - dx * 4, p[1] + ny * w_ - dy * 4),
                            (p[0] + nx * (w_ + 9 - 6 * t), p[1] + ny * (w_ + 9 - 6 * t)),
                            (p[0] + nx * w_ + dx * 4, p[1] + ny * w_ + dy * 4)]))
tail_sil = outline([X(tailp)] + [X(s) for s in spikes], smooth=2)
Lt = S.layer("tail", holdout=tail_sil)
S.contour(Lt, tail_sil, w=1.0, breaks=(0.0, 0.5), lin=True)
S.wash(X(tailp), "#7a1810", alpha=0.8, z=9, shade=0.5, shadow_color="#3a0806")
for s_ in spikes:
    S.wash(X(s_), "#d8a04a", alpha=0.7, z=9.2, shade=0, spill=0.5)
FIG.append(tail_sil)

# ======================= body: legs + body + neck + arms as ONE silhouette =======================
D = dict(
    legL="M124 246 C110 262 104 282 108 300 C110 310 122 312 126 302 C128 286 134 270 144 258 Z",
    legR="M178 256 C190 268 196 286 194 302 C192 312 180 314 177 304 C176 288 172 274 164 262 Z",
    body="M104 174 C94 208 104 248 124 274 C140 292 166 292 182 274 C202 248 212 208 200 174 C180 156 124 156 104 174 Z",
    plates="M136 168 C130 200 133 240 145 272 L160 272 C171 240 173 200 167 168 Z",
    neck="M128 172 C120 150 128 126 138 108 L166 108 C176 126 184 150 176 172 Z",
    neckP="M143 168 C139 148 141 128 146 110 L160 110 C164 128 165 148 162 168 Z",
    armL="M122 186 C106 200 96 220 92 240 C90 250 100 256 106 248 C112 232 122 218 136 206 Z",
    armR="M182 186 C198 200 208 220 212 240 C214 250 204 256 198 248 C192 232 182 218 168 206 Z")
P = {k: one(v) for k, v in D.items()}
body_sil = outline([P["legL"], P["legR"], P["body"], P["neck"], P["armL"], P["armR"]])
Lb = S.layer("body", holdout=body_sil)
S.contour(Lb, body_sil, w=1.3, breaks=(0.0, 0.3, 0.55, 0.8), lin=True)
# arms in front of the chest: only their inner edge (open stroke), the outer edge is the silhouette
for k, rng_ in (("armL", (0.45, 0.98)), ("armR", (0.45, 0.98))):
    a = P[k]; n = len(a)
    seg = a[int(n * rng_[0]):int(n * rng_[1])]
    S.stroke(Lb, seg, w=0.95, tin=0.3, tout=0.15, over=1.0)
# plates: the two side edges + a few cross lines (neck and belly)
for k in ("plates", "neckP"):
    pp = P[k]; n = len(pp)
    left = pp[: int(n * 0.36)]; right = pp[int(n * 0.52): int(n * 0.9)]
    S.stroke(Lb, left, w=0.6, tin=0.2, tout=0.2, over=0.5)
    S.stroke(Lb, right, w=0.6, tin=0.2, tout=0.2, over=0.5)
for i in range(0, 9, 2):
    y = 176 + i * 11
    S.line(Lb, list(X(np.array([(136 + i * .6, y), (152, y + 3.5), (167 - i * .3, y)]))), w=0.38, op=0.7, over=0, tin=0.25, tout=0.25)
for i in range(0, 6, 2):
    y = 114 + i * 9
    S.line(Lb, list(X(np.array([(146 - i * .4, y), (153, y + 3), (160 + i * .4, y)]))), w=0.35, op=0.7, over=0, tin=0.25, tout=0.25)
S.line(Lb, list(X(np.array([(126, 250), (136, 262)]))), w=0.5, op=0.8)        # leg/hip fold
S.line(Lb, list(X(np.array([(176, 258), (168, 266)]))), w=0.5, op=0.8)
BODYC = "#a82818"
S.wash(body_sil, BODYC, alpha=0.85, z=12, shade=0.6, shadow_color="#2a0404", light_cut=0.15, knock=[P["plates"], P["neckP"]])
for k in ("armL", "armR", "legL", "legR"):
    S.wash(P[k], "#7a1410", alpha=0.18, z=12.3, shade=0.35, shadow_color="#2a0404", spill=0.4, mis=0.4)
S.wash(P["plates"], "#e6b05a", alpha=0.7, z=13, shade=0.45, shadow_color="#a8702a", spill=1.0)
S.wash(P["neckP"], "#e6b05a", alpha=0.7, z=13, shade=0.45, shadow_color="#a8702a", spill=1.0)
# talons (cream)
TAL = []
for x, y, dx, dy in [(94, 246, -10, 10), (98, 250, -6, 14), (104, 251, 0, 14), (108, 248, 6, 11),
                     (210, 246, 10, 10), (206, 250, 6, 14), (200, 251, 0, 14), (196, 248, -6, 11)]:
    c = sample(f"M{x} {y} q{dx * .6} {dy * .2} {dx} {dy}")[0]
    TAL.append(X(brush(c, 3.4, .3)))
Ltal = S.layer("talons", holdout=TAL)
for t in TAL:
    S.contour(Ltal, t, w=0.55, breaks=(0.0, 0.5), lin=True)
    S.wash(t, "#f2e2c0", alpha=0.45, z=14, shade=0.3, spill=0.3, mis=0.2)
FIG.append(body_sil)

# ======================= head =======================
horns = [one("M138 54 C118 40 104 18 110 -8 C116 14 130 30 150 44 Z"), one("M166 54 C186 40 200 18 194 -8 C188 14 174 30 154 44 Z")]
for i, hp in enumerate(horns):
    Lh = S.layer("horn%d" % i, holdout=hp)
    S.contour(Lh, hp, w=1.0, breaks=(0.05, 0.55), lin=True)
    S.wash(hp, "#efe0c0", alpha=0.55, z=15, shade=0.6, shadow_color="#8a6a48", light_cut=0.3, spill=1.0)
    FIG.append(hp)
Lhr = S.layer("horn_rings")
for d in ("M124 28 L131 26", "M116 14 L123 13", "M180 28 L173 26", "M188 14 L181 13"):
    S.line(Lhr, list(X(sample(d)[0])), w=0.45, op=0.8, over=0.4)
# side spines (swept back), merged per side into one frill silhouette
SP = [[131, 78, 112, 50], [130, 86, 108, 66], [132, 94, 112, 84], [173, 78, 192, 50], [174, 86, 196, 66], [172, 94, 192, 84]]
for side in (0, 1):
    polys = []
    for q in SP[side * 3: side * 3 + 3]:
        c = sample(f"M{q[0]} {q[1]} Q{q[0] - (q[0] - q[2]) * .2} {(q[1] + q[3]) / 2} {q[2]} {q[3]}")[0]
        polys.append(X(brush(c, 11, .6)))
    fr = outline(polys, smooth=2, eps=0.25)
    Lf = S.layer("spines%d" % side, holdout=fr)
    S.contour(Lf, fr, w=0.85, breaks=(0.0, 0.33, 0.66), lin=True)
    S.wash(fr, "#6a140c", alpha=0.8, z=16, shade=0.45, shadow_color="#2a0604", spill=1.0)
    FIG.append(fr)

skull = one("M128 78 C124 60 136 44 152 40 C168 44 180 60 176 78 C174 86 170 92 166 97 L138 97 C134 92 130 86 128 78 Z")
jaw = one("M134 120 C128 142 136 170 152 177 C168 170 176 142 170 120 C168 144 162 162 152 168 C142 162 136 144 134 120 Z")
mouth = one("M136 116 C142 120 148 121 152 121 C156 121 162 120 168 116 C172 138 166 160 152 166 C138 160 132 138 136 116 Z")
snout = one("M133 90 C133 104 139 117 152 121 C165 117 171 104 171 90 C164 94 158 96 152 96 C146 96 140 94 133 90 Z")
head_sil = outline([skull, jaw, mouth, snout], smooth=3, eps=0.25)
Lhd = S.layer("head", holdout=head_sil)
S.contour(Lhd, head_sil, w=1.3, breaks=(0.0, 0.3, 0.55, 0.8), lin=True)
# snout top (where the muzzle meets the skull) and its sides down to the upper lip
S.line(Lhd, list(X(sample("M134 91 C140 94.5 146 96 152 96 C158 96 164 94.5 170 91")[0])), w=0.65, tin=0.45, tout=0.45)
# mouth opening (inner shape) as one contour
S.contour(Lhd, mouth, w=0.9, breaks=(0.1, 0.6), lin=True, shade=0.3)
# brows (heavy, angry) and glowing eyes
BROWS = [one("M124 69 L150 76 L148 83 L127 77 Z"), one("M180 69 L154 76 L156 83 L177 77 Z")]
EYES = [one("M130 79 L146 84 L144 88 L132 84 Z"), one("M174 79 L158 84 L160 88 L172 84 Z")]
for b in BROWS:
    S.contour(Lhd, b, w=0.75, breaks=(0.0, 0.5), lin=True)
for e in EYES:
    S.contour(Lhd, e, w=0.5, breaks=(0.0, 0.5), lin=True, shade=0.2)
for d in ("M139 81 L138.5 87", "M165 81 L165.5 87"):
    S.line(Lhd, list(X(sample(d)[0])), w=0.95, over=0, tin=0.2, tout=0.2)
# nostrils, forehead ridge
for d in ("M143 104 C142 100 147 100 147 104", "M161 104 C162 100 157 100 157 104"):
    S.line(Lhd, list(X(sample(d)[0])), w=0.7, over=0, tin=0.2, tout=0.2)
for d in ("M146 46 C148 56 150 64 150 72", "M158 46 C156 56 154 64 154 72"):
    S.line(Lhd, list(X(sample(d)[0])), w=0.42, op=0.65, tin=0.4, tout=0.4)
# teeth (paper white over the glow)
TEETH = []
for t in [[139, 118, 8], [144, 120, 12], [148, 121, 7], [156, 121, 7], [160, 120, 12], [165, 118, 8],
          [140, 152, -8], [145, 160, -11], [159, 160, -11], [164, 152, -8]]:
    tri = X(np.array([(t[0] - 2, t[1]), (t[0], t[1] + t[2]), (t[0] + 2, t[1])]))
    TEETH.append(tri)
    S.line(Lhd, list(tri), w=0.42, over=0, tin=0.08, tout=0.08, shade=0.2)
# washes: value range from the deep skull to the warmer muzzle, glowing mouth
S.wash(head_sil, "#9a2214", alpha=0.82, z=17, shade=0.6, shadow_color="#260404", light_cut=0.35, knock=[mouth] + EYES)
S.wash(snout, "#c8482a", alpha=0.45, z=17.5, shade=0.3, spill=0.8, mis=0.6, light_cut=0.4)
S.wash(jaw, "#a83020", alpha=0.4, z=17.5, shade=0.3, spill=0.6, mis=0.5)
for b in BROWS:
    S.wash(b, "#3a0806", alpha=0.6, z=18, shade=0, spill=0.5, mis=0.3)
for e in EYES:
    S.wash(e, "#ffd83a", alpha=0.95, z=18.2, shade=0, spill=0.6, mis=0.3, gran=0.2)
S.wash(mouth, "#ffe066", alpha=0.95, z=18.4, shade=0, spill=0.4, mis=0.3, edge=0.3, gran=0.2, knock=TEETH, ksoft=0.8)
S.wash(mouth, "#f2701e", alpha=0.85, z=18.6, shade=0, spill=0.2, mis=0.3, edge=1.2, knock=TEETH + [X(ellipse((152, 136), 13, 13))], ksoft=9)
S.wash(mouth, "#a01a0a", alpha=0.5, z=18.8, shade=0, spill=0.0, mis=0.2, knock=TEETH + [X(ellipse((152, 140), 16, 20))], ksoft=6)
FIG.append(head_sil)
S.fx.append({"t": "glow", "c": list(X((152, 140))), "r": 40, "color": "#ffe9a0", "k": 0.45, "p": 1.8})

FIG_LATE.extend(FIG)
# ======================= sky =======================
win = [(-6, -6), (284, -6), (284, 273), (-6, 273)]
S.wash(win, "#f08030", alpha=0.7, z=0, shade=0, spill=0, mis=0, knock=[moon] + FIG, ksoft=4, bloom=0.5, gran=0.8, edge=0.2)
S.wash(moon, "#f8e0a4", alpha=0.55, z=1, shade=0, spill=2.0, knock=FIG, bloom=0.6, edge=0.9)
S.wash(win, "#b0301c", alpha=0.6, z=1.5, shade=0, spill=0, mis=0, knock=[moon, [(-20, 205), (300, 205), (300, 300), (-20, 300)]] + FIG, ksoft=30, bloom=0.5, gran=0.8, edge=0.1)
S.wash(win, "#3a0a10", alpha=0.6, z=2, shade=0, spill=0, mis=0, knock=[ellipse((139, 210), 190, 175, n=40)] + FIG, ksoft=40, bloom=0.5, gran=0.8, edge=0.1)

# ======================= ember rain (wedges going up-right, as in v2) =======================
streaks, dots = [], []
for i in range(70):
    x, y, l = rng.random() * 320 - 10 - 11, rng.random() * 420 - 11, 6 + rng.random() * 12
    if -5 < x < 283 and -5 < y < 272:
        if i % 3 == 0:
            dots.append((x, y, 0.6 + rng.random() * 0.7))
        else:
            streaks.append((x + l * .38, y - l, x, y, 0.5 + rng.random() * 0.5))
S.fx.append({"t": "lines", "pts": streaks, "color": "#ffc04a", "a": 0.85})
S.fx.append({"t": "dots", "pts": dots, "color": "#ffd87a", "a": 0.9, "light": True})
S.save(sys.argv[1] if len(sys.argv) > 1 else "dragon.json")
