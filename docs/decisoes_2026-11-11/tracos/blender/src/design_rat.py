import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import *

S = Scene("rat_king")
FIG = []          # figure silhouettes (background washes are reserved around them)

# ---------------- background ----------------
Lbg = S.layer("bg")
S.line(Lbg, [(30, 4), (29, 90), (31, 190)], w=0.7, op=0.55, tin=0.3, tout=0.4)
S.line(Lbg, [(249, 4), (250, 100), (248, 190)], w=0.7, op=0.55, tin=0.3, tout=0.4)
S.line(Lbg, [(10, 70), (28, 69)], w=0.45, op=0.45)
S.line(Lbg, [(4, 130), (27, 132)], w=0.45, op=0.45)
S.line(Lbg, [(252, 60), (274, 62)], w=0.45, op=0.45)
S.line(Lbg, [(253, 140), (276, 139)], w=0.45, op=0.45)
S.line(Lbg, [(0, 241), (58, 243)], w=0.6, op=0.6, tin=0.05)
S.line(Lbg, [(222, 243), (278, 240)], w=0.6, op=0.6, tout=0.05)

# ---------------- fan of bones and swords (throne back) ----------------
C = np.array([139.0, 150.0])
spokes = [(197, "bone", 128), (180, "sword", 130), (162, "bone", 132), (145, "sword", 134),
          (128, "bone", 128), (53, "bone", 128), (36, "sword", 134), (19, "bone", 132),
          (1, "sword", 130), (-16, "bone", 126)]
fan_polys = []
Lfan = S.layer("fan")
for ang, kind, R in spokes:
    r0 = 40
    Lb = R - r0
    if kind == "bone":
        loc = [(0, -3.0), (Lb - 10, -2.6), (Lb - 7, -6.5), (Lb - 2.5, -8.6), (Lb + 2, -6.2), (Lb + 1.2, -2.2),
               (Lb - 0.6, 0), (Lb + 1.2, 2.2), (Lb + 2, 6.2), (Lb - 2.5, 8.6), (Lb - 7, 6.5), (Lb - 10, 2.6), (0, 3.0)]
        P = place(np.array(loc) + [r0, 0], C, ang)
        poly = shape(P, n=8)
        S.contour(Lfan, P, w=0.75, breaks=(0.0, 0.5), n=8, shade=0.7)
        S.wash(poly, "#efe3c6", alpha=0.55, z=3, shade=0.45, shadow_color="#b59a72", spill=1.6)
    else:
        loc = [(0, -2.9), (Lb - 13, -2.6), (Lb, 0), (Lb - 13, 2.6), (0, 2.9)]
        P = place(np.array(loc) + [r0, 0], C, ang)
        poly = shape(P, lin=True)
        S.contour(Lfan, P, w=0.75, breaks=(0.0, 0.5), lin=True, shade=0.7)
        S.line(Lfan, place(np.array([(8, 0), (Lb - 16, 0)]) + [r0, 0], C, ang), w=0.35, op=0.7)
        S.wash(poly, "#a8b8cc", alpha=0.6, z=3, shade=0.5, shadow_color="#6c7c94", spill=1.4)
    fan_polys.append(poly)
Lfan["holdout"] = fan_polys

# ---------------- cape ----------------
cape = [(96, 132), (70, 158), (48, 196), (32, 236), (22, 272), (64, 265), (104, 272), (140, 265),
        (178, 272), (218, 265), (258, 272), (250, 232), (236, 190), (216, 154), (200, 130), (150, 125)]
cape_poly = shape(cape)
Lcape = S.layer("cape", holdout=cape_poly)
S.contour(Lcape, cape, w=1.15, breaks=(0.02, 0.3, 0.62, 0.86))
S.line(Lcape, [(80, 166), (62, 212), (54, 252)], w=0.75, tin=0.4, tout=0.3)
S.line(Lcape, [(216, 170), (232, 214), (240, 252)], w=0.75, tin=0.4, tout=0.3)
S.line(Lcape, [(44, 236), (40, 264)], w=0.55, tin=0.5)
S.line(Lcape, [(76, 238), (82, 266)], w=0.5, tin=0.5)
S.line(Lcape, [(250, 238), (246, 262)], w=0.55, tin=0.5)
S.wash(cape_poly, "#5b2fa2", alpha=0.85, z=5, shade=0.55, shadow_color="#2c145c", light_cut=0.3, dry=0.12, spill=2.6)
FIG.append(cape_poly)

# ---------------- tail (behind body) ----------------
tl, tr = ribbon_sides([(198, 246), (226, 256), (250, 246), (262, 226), (258, 206), (247, 196)],
                      [4.6, 3.8, 2.8, 1.9, 1.1, 0.35])
tail_poly = np.vstack([tl, tr[::-1]])
Ltail = S.layer("tail", holdout=tail_poly)
S.stroke(Ltail, tl, w=0.85, tin=0.05, tout=0.3, over=0.5)
S.stroke(Ltail, tr, w=0.85, tin=0.05, tout=0.3, over=1.5)
for t in (0.35, 0.55, 0.72):
    i = int(t * (len(tl) - 1))
    S.line(Ltail, [tl[i] * 0.85 + tr[i] * 0.15, tl[i] * 0.2 + tr[i] * 0.8], w=0.3, op=0.7, over=0)
S.wash(tail_poly, "#e09c92", alpha=0.7, z=8, shade=0.4, spill=1.3)
FIG.append(tail_poly)

# ---------------- body ----------------
body = [(104, 140), (96, 160), (90, 190), (90, 220), (98, 242), (112, 256), (132, 262), (160, 263),
        (186, 257), (202, 244), (210, 222), (212, 192), (208, 164), (200, 142), (150, 136)]
body_poly = shape(body)
belly = ellipse((150, 206), 31, 40, 0.06, n=20)
Lbody = S.layer("body", holdout=body_poly)
S.contour(Lbody, body, w=1.25, breaks=(0.05, 0.42, 0.78))
S.line(Lbody, [(176, 178), (181, 205), (177, 232)], w=0.5, tin=0.4, tout=0.4, op=0.8)   # belly side
S.line(Lbody, [(124, 186), (121, 200)], w=0.35, op=0.6)                               # fur tick
S.line(Lbody, [(128, 236), (136, 246)], w=0.35, op=0.6)
S.wash(body_poly, "#9a938b", alpha=0.72, z=10, shade=0.55, shadow_color="#544d48", light_cut=0.3, knock=[belly])
S.wash(belly, "#efe2c8", alpha=0.55, z=11, shade=0.3, spill=1.0)
FIG.append(body_poly)

# feet
for cx in (120, 180):
    ft = ellipse((cx, 262), 14, 5.5, 0.0, n=14)
    Lf = S.layer("foot%d" % cx, holdout=ft)
    S.contour(Lf, ft, w=0.9, breaks=(0.1, 0.6))
    S.line(Lf, [(cx - 6, 258), (cx - 7, 264)], w=0.35, op=0.8)
    S.line(Lf, [(cx + 1, 258), (cx + 1, 265)], w=0.35, op=0.8)
    S.wash(ft, "#e3a197", alpha=0.65, z=12, shade=0.3, spill=1.0)

# ---------------- right arm (hanging, viewer right) ----------------
arm_r = [(198, 146), (212, 156), (222, 176), (228, 194), (236, 202), (241, 210), (238, 216), (231, 217),
         (225, 214), (219, 209), (213, 197), (205, 180), (196, 166)]
arm_r_poly = shape(arm_r)
Lar = S.layer("arm_r", holdout=arm_r_poly)
S.contour(Lar, arm_r, w=1.05, breaks=(0.0, 0.45, 0.8))
S.line(Lar, [(229, 207), (233, 214)], w=0.35, op=0.85, over=0.5)
S.line(Lar, [(224, 206), (226, 213)], w=0.35, op=0.85, over=0.5)
S.wash(arm_r_poly, "#8f8880", alpha=0.75, z=13, shade=0.5, shadow_color="#544d48")
S.wash(ellipse((231, 209), 7, 5), "#e3a197", alpha=0.6, z=14, shade=0, spill=0.8)
FIG.append(arm_r_poly)

# ---------------- ermine collar ----------------
th = np.linspace(0, 2 * np.pi, 34, endpoint=False)
rr = 1 + 0.07 * np.abs(np.sin(th * 8))
collar = np.c_[156 + 68 * rr * np.cos(th), 139 + 15 * rr * np.sin(th)]
collar = rot(collar, -0.07, np.array([156, 139]))
collar_poly = shape(collar, n=6)
Lcol = S.layer("collar", holdout=collar_poly)
S.contour(Lcol, collar, w=1.0, breaks=(0.1, 0.45, 0.8), n=6)
for x, y in [(104, 143), (126, 150), (182, 149), (204, 142), (219, 134)]:
    S.line(Lcol, [(x - 1.5, y - 2), (x, y + 2.2), (x + 1.6, y - 2)], w=0.55, over=0, tin=0.3, tout=0.3)
gem = ellipse((152, 151), 4.2, 3.4, n=12)
S.contour(Lcol, gem, w=0.55, breaks=(0.0, 0.5), n=6)
S.wash(collar_poly, "#d9d6e4", alpha=0.45, z=15, shade=0.55, shadow_color="#9a96b2", light_cut=0.5, spill=1.6)
S.wash(gem, "#d23a2c", alpha=0.9, z=16, shade=0.4, spill=0.6, gran=0.3)
FIG.append(collar_poly)

# ---------------- ears (behind head) ----------------
ear_far = [(126, 72), (114, 58), (115, 44), (127, 37), (141, 43), (147, 60)]
ear_near = [(176, 70), (176, 52), (186, 38), (202, 35), (214, 45), (215, 62), (205, 76), (190, 82)]
for nm, e, inner in (("ear_far", ear_far, None), ("ear_near", ear_near, [(184, 66), (186, 50), (198, 43), (208, 49), (208, 62)])):
    ep = shape(e)
    Le = S.layer(nm, holdout=ep)
    S.contour(Le, e, w=1.0, breaks=(0.0, 0.55))
    S.wash(ep, "#958e86", alpha=0.7, z=17, shade=0.4, shadow_color="#5a534e", spill=1.4)
    if inner:
        S.line(Le, inner, w=0.5, tin=0.3, tout=0.4)
        S.wash(shape(inner + [(196, 74)]), "#e8a49a", alpha=0.65, z=18, shade=0.3, spill=1.0)
    FIG.append(ep)

# ---------------- head ----------------
head = [(86, 121), (96, 109), (112, 97), (122, 80), (136, 64), (156, 58), (176, 62), (190, 74), (196, 92),
        (192, 112), (182, 126), (164, 136), (140, 138), (118, 134), (100, 130), (90, 127)]
head_poly = shape(head)
eye_n = ellipse((161, 92), 10, 4.3, -0.05, n=14)
eye_f = ellipse((128, 90), 7, 3.8, 0.05, n=12)
Lh = S.layer("head", holdout=head_poly)
S.contour(Lh, head, w=1.25, breaks=(0.03, 0.4, 0.7))
# eyes: heavy upper lid, light lower lid, slit pupil, lid crease
S.line(Lh, [(150, 92), (156, 87.2), (166, 87), (172.5, 91)], w=1.05, tin=0.2, tout=0.3, shade=0.2)
S.line(Lh, [(152, 95.5), (161, 97.3), (170, 94.5)], w=0.45, tin=0.3, tout=0.3, shade=0.2)
S.line(Lh, [(161.5, 88.6), (161.2, 95.6)], w=0.95, tin=0.3, tout=0.3, over=0)
S.line(Lh, [(151, 85), (161, 81.5), (171, 83.6)], w=0.5, tin=0.4, tout=0.4)
S.line(Lh, [(121, 90), (125, 86.3), (132, 86.2), (136, 89)], w=0.9, tin=0.2, tout=0.3, shade=0.2)
S.line(Lh, [(122, 93), (128.5, 94.2), (135, 92)], w=0.4, tin=0.3, tout=0.3, shade=0.2)
S.line(Lh, [(129.5, 87.4), (129.4, 93)], w=0.85, tin=0.3, tout=0.3, over=0)
S.line(Lh, [(121, 83.5), (128, 81.5), (135, 83)], w=0.45, tin=0.4, tout=0.4)
# nose, mouth, tooth, snout fold, jowl
S.dot(Lh, (87.5, 121.0), 2.6)
S.line(Lh, [(93, 127), (104, 130.2), (116, 129.2), (123, 124.8)], w=0.6, tin=0.15, tout=0.35)
S.line(Lh, [(98, 129.5), (98.5, 135), (103.5, 135), (104, 130)], w=0.4, tin=0.1, tout=0.1, over=0.3)
S.line(Lh, [(140, 103), (126, 108), (113, 113)], w=0.42, tin=0.4, tout=0.4, op=0.8)
S.line(Lh, [(179, 104), (185, 116), (180, 125)], w=0.55, tin=0.4, tout=0.4)
# whiskers (light, long taper)
for ctrl in ([(99, 117), (78, 108), (56, 103)], [(98, 121), (75, 118), (51, 120)], [(99, 124.5), (79, 129), (59, 137)]):
    S.line(Lh, ctrl, w=0.32, tin=0.05, tout=0.7, over=0, op=0.85)
S.wash(head_poly, "#a09890", alpha=0.72, z=19, shade=0.55, shadow_color="#544d48", light_cut=0.3, knock=[eye_n, eye_f])
S.wash(eye_n, "#f2c62e", alpha=0.95, z=20, shade=0.0, spill=0.6, gran=0.3)
S.wash(eye_f, "#f2c62e", alpha=0.95, z=20, shade=0.0, spill=0.6, gran=0.3)
S.wash(ellipse((88, 121), 4, 3.2), "#d97f78", alpha=0.7, z=20, shade=0, spill=0.6)
FIG.append(head_poly)

# ---------------- crown ----------------
crown = [(122, 75), (119, 62), (114, 36), (130, 52), (140, 30), (152, 48), (164, 26), (176, 47), (190, 30),
         (188, 54), (188, 66), (155, 71)]
crown_poly = shape(crown, lin=True)
balls = [ellipse(p, 2.6, 2.6, n=10) for p in ((114, 34), (140, 28), (164, 24), (190, 28))]
gems = [(ellipse((154, 64), 4.0, 3.3, n=12), "#d23a2c"), (ellipse((173, 61), 3.0, 2.8, n=10), "#2f9ad0"),
        (ellipse((136, 66), 3.0, 2.8, n=10), "#9a52d8")]
Lcr = S.layer("crown", holdout=[crown_poly] + balls)
S.contour(Lcr, crown, w=0.95, breaks=(0.0, 0.33, 0.7), lin=True)
S.line(Lcr, [(119, 62), (150, 57.5), (188, 54)], w=0.55, tin=0.2, tout=0.3)
for b in balls:
    S.contour(Lcr, b, w=0.55, breaks=(0.0, 0.5), n=6)
    S.wash(b, "#ecb93c", alpha=0.85, z=22, shade=0.4, spill=0.7)
for g, c in gems:
    S.contour(Lcr, g, w=0.45, breaks=(0.0, 0.5), n=6)
    S.wash(g, c, alpha=0.9, z=23, shade=0.45, spill=0.5, gran=0.3)
S.wash(crown_poly, "#ecb93c", alpha=0.85, z=21, shade=0.5, shadow_color="#ae7618", light_cut=0.45, spill=1.6)
FIG.append(crown_poly)

# ---------------- sceptre ----------------
sl, sr = ribbon_sides([(66, 44), (68, 140), (71, 230)], [1.9, 1.9, 2.0])
rod = np.vstack([sl, sr[::-1]])
diamond = [(64, 12), (72, 26), (64, 40), (56, 26)]
ring = ellipse((65.5, 43), 5.2, 2.3, 0.04, n=12)
orb = ellipse((71, 234), 5, 5, n=12)
Lsc = S.layer("sceptre", holdout=[rod, shape(diamond, lin=True), ring, orb])
S.stroke(Lsc, sl, w=0.7, tin=0.05, tout=0.05, over=0)
S.stroke(Lsc, sr, w=0.7, tin=0.05, tout=0.05, over=0)
S.contour(Lsc, diamond, w=0.8, breaks=(0.0, 0.5), lin=True)
S.line(Lsc, [(64, 14), (64, 38)], w=0.35, op=0.7, over=0)
S.contour(Lsc, ring, w=0.6, breaks=(0.0, 0.5), n=6)
S.contour(Lsc, orb, w=0.7, breaks=(0.0, 0.5), n=6)
S.wash(rod, "#e2ad3a", alpha=0.8, z=24, shade=0.3, spill=0.8)
S.wash(shape(diamond, lin=True), "#a868e8", alpha=0.85, z=24, shade=0.5, shadow_color="#5a2aa0", light_cut=0.5, spill=1.2)
S.wash(ring, "#e2ad3a", alpha=0.85, z=25, shade=0.3, spill=0.6)
S.wash(orb, "#e2ad3a", alpha=0.85, z=25, shade=0.5, spill=0.8)
S.fx.append({"t": "glow", "c": [64, 26], "r": 20, "color": "#f4e6ff", "k": 0.5, "p": 2})

# ---------------- left arm (raised, holding the sceptre) ----------------
al, ar = ribbon_sides([(113, 153), (98, 168), (87, 178), (78, 168), (73, 154)], [9.5, 8, 7, 6.5, 5.5])
arm_l_poly = np.vstack([al, ar[::-1]])
fist = [(60, 144), (66, 139), (73, 139), (80, 143), (82, 149), (80, 155), (76, 158), (70, 158.5), (64, 158), (59, 154), (57.5, 149)]
fist_poly = shape(fist)
Lal = S.layer("arm_l", holdout=[arm_l_poly, fist_poly])
cut = int(len(al) * 0.93)
S.stroke(Lal, al[2:cut], w=1.05, tin=0.1, tout=0.08, over=0.6)
S.stroke(Lal, ar[3:cut], w=1.05, tin=0.25, tout=0.08, over=0.6)
S.line(Lal, [(92, 168), (88, 172)], w=0.4, op=0.8)                 # elbow fold
S.wash(arm_l_poly, "#8f8880", alpha=0.75, z=26, shade=0.45, shadow_color="#544d48")
Lfi = S.layer("fist", holdout=fist_poly)
S.contour(Lfi, fist, w=1.0, breaks=(0.05, 0.55))
for y0 in (146.5, 151.0, 155.2):
    S.line(Lfi, [(58.5, y0 + 0.5), (63, y0 - 0.4), (67, y0)], w=0.42, op=0.9, over=0.3, tin=0.1, tout=0.4)
S.line(Lfi, [(66, 141.5), (73, 143), (79, 147.5)], w=0.45, op=0.9, over=0.3)
S.wash(fist_poly, "#e3a197", alpha=0.65, z=27, shade=0.4, spill=1.0)
FIG += [arm_l_poly, fist_poly, rod]

# ---------------- candles + minion skulls ----------------
def candle(name, x0, x1, top, bot, flame_h):
    body_c = [(x0, top), (x1, top), (x1 + 0.6, bot), (x0 - 0.6, bot)]
    cx = (x0 + x1) / 2
    fl = [(cx, top - flame_h), (cx + 3.4, top - flame_h * 0.35), (cx, top - 2.5), (cx - 3.4, top - flame_h * 0.35)]
    bp, fp = shape(body_c, lin=True), shape(fl, n=10)
    Lc = S.layer(name, holdout=[bp, fp])
    S.contour(Lc, body_c, w=0.8, breaks=(0.0, 0.5), lin=True)
    S.contour(Lc, fl, w=0.55, breaks=(0.0, 0.5), n=10)
    S.line(Lc, [(x0 + 2, top), (x0 + 2.5, top + 6), (x0 + 1.5, top + 9)], w=0.35, op=0.8, over=0)
    S.wash(bp, "#efe1bc", alpha=0.6, z=30, shade=0.45, shadow_color="#bea476", spill=1.0)
    S.wash(fp, "#ffc93e", alpha=0.85, z=31, shade=0, spill=1.2, edge=1.6)
    S.fx.append({"t": "glow", "c": [cx, top - flame_h * 0.45], "r": 22, "color": "#fff1c4", "k": 0.45, "p": 2})
    return bp

def skull(name, c, s):
    cx, cy = c
    sk = [(cx - 10 * s, cy + 2 * s), (cx - 10 * s, cy - 6 * s), (cx, cy - 12 * s), (cx + 10 * s, cy - 6 * s),
          (cx + 10 * s, cy + 2 * s), (cx + 6 * s, cy + 6 * s), (cx + 5 * s, cy + 10 * s), (cx - 5 * s, cy + 10 * s), (cx - 6 * s, cy + 6 * s)]
    sp = shape(sk, n=8)
    Ls = S.layer(name, holdout=sp)
    S.contour(Ls, sk, w=0.85, breaks=(0.0, 0.55), n=8)
    S.dot(Ls, (cx - 4.2 * s, cy - 1 * s), 2.5 * s)
    S.dot(Ls, (cx + 4.2 * s, cy - 1 * s), 2.5 * s)
    S.line(Ls, [(cx - 0.8 * s, cy + 3.5 * s), (cx, cy + 2 * s), (cx + 0.8 * s, cy + 3.5 * s)], w=0.4 * s, over=0)
    for dx in (-2.5, 0, 2.5):
        S.line(Ls, [(cx + dx * s, cy + 6.5 * s), (cx + dx * s, cy + 9.6 * s)], w=0.3, over=0, op=0.8)
    S.wash(sp, "#ece1c6", alpha=0.6, z=32, shade=0.5, shadow_color="#a8916a", spill=1.0)
    return sp

FIG.append(candle("candle1", 13, 24, 198, 241, 15))
FIG.append(candle("candle2", 29, 37, 212, 241, 11))
FIG.append(candle("candle3", 251, 261, 194, 238, 15))
FIG.append(skull("skull1", (233, 226), 1.0))
FIG.append(skull("skull2", (50, 236), 0.75))

# ---------------- background washes ----------------
halo = ellipse((152, 92), 74, 70, n=30)
win = [(-6, -6), (284, -6), (284, 273), (-6, 273)]
S.wash(win, "#b3a3c9", alpha=0.55, z=0, shade=0, spill=0, mis=0, ksoft=6, knock=[halo] + FIG + fan_polys, bloom=1.0, gran=1.2, edge=0.4)
S.wash(halo, "#f1c860", alpha=0.55, z=1, shade=0, spill=3.0, knock=FIG, bloom=1.0, edge=1.2)
vign = ellipse((139, 120), 128, 120, n=30)
S.wash(win, "#6a5694", alpha=0.5, z=2, shade=0, spill=0, mis=0, ksoft=40, knock=[vign] + FIG + fan_polys, bloom=1.4, gran=1.4, edge=0.3)
S.wash([(-6, 241), (284, 240), (284, 273), (-6, 273)], "#8f6e52", alpha=0.45, z=2.5, shade=0, spill=1.0, knock=FIG)

S.save(sys.argv[1] if len(sys.argv) > 1 else "rat.json")
