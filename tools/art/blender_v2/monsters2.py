"""Os outros monstros e estruturas do Last Boss na linguagem aprovada (olhos grandes, formas macias, cor com
contraste, silhueta que lê de cima). Partes marcadas por osso (vat.tag) para anims.py."""
import math
import bpy, bmesh
from mathutils import Matrix, Vector, noise
from mk import *
from vat import tag
import chars
from chars import eye, BLACK, WHITE, GOLD, LEATHER, WOOD
from monsters import xform, glow_eye, BONE, BONE_D, RUST, IRON

PURPLE = (0.42, 0.22, 0.62)
PURPLE_D = (0.2, 0.08, 0.32)


def yellow_eye(loc, r, angry=18, sx=1, iris=(1.0, 0.82, 0.25), lidc=(0.25, 0.22, 0.25)):
    out = []
    w = sph(loc, r, (1, 0.6, 1)); setmat(w, mat("eyey_%s" % str(iris), iris, 0.15, coat=1.0)); out.append(w)
    p = sph((loc[0], loc[1] - r * 0.48, loc[2]), r * 0.42, (0.7, 0.5, 1.25)); setmat(p, mat("pupil", BLACK, 0.1, coat=1.0)); out.append(p)
    hl = sph((loc[0] - r * 0.25, loc[1] - r * 0.66, loc[2] + r * 0.35), r * 0.15, (1, 0.5, 1)); setmat(hl, mat("hl", WHITE, 0.3, emit=0.6)); out.append(hl)
    lid = sph((loc[0], loc[1] - 0.004, loc[2] + r * 0.55), r * 1.1, (1.05, 0.65, 0.55), (0, sx * angry, 0)); shade(lid); setmat(lid, mat("lid_%s" % str(lidc), lidc, 0.7)); out.append(lid)
    return out


# ------------------------------------------------------------------ rei rato

def rat_king():
    old = (chars.FUR, chars.FUR_D, chars.BELLY)
    chars.FUR, chars.FUR_D, chars.BELLY = (0.5, 0.36, 0.22), (0.3, 0.19, 0.12), (0.9, 0.78, 0.6)
    try:
        g = chars.rat()
    finally:
        chars.FUR, chars.FUR_D, chars.BELLY = old
    P = list(g.children)
    for o in P:
        o.parent = None
    bpy.data.objects.remove(g)
    gold = mat("gold", GOLD, 0.28, 1.0)
    # coroa torta com joias
    crown = []
    band = cyl((0, -0.5, 0.86), 0.17, 0.08, (12, 0, -8), seg=10, bevel=0.015); hard(band); setmat(band, gold); crown.append(band)
    for k in range(5):
        a = k / 5 * math.tau
        sp = box((math.cos(a) * 0.15, -0.5 + math.sin(a) * 0.15, 0.95), (0.06, 0.04, 0.12), (12, 0, math.degrees(a) + 90), bevel=0.008, taper=(0.15, 0.4)); hard(sp); setmat(sp, gold); crown.append(sp)
        gm = sph((math.cos(a) * 0.17, -0.5 + math.sin(a) * 0.17, 0.87), 0.025); setmat(gm, mat("ruby", (0.95, 0.12, 0.25), 0.2, emit=1.0)); crown.append(gm)
    tag(crown, "head"); P += crown
    # capa vermelha de gola de arminho sobre as costas
    cape = fuse([sph((0, 0.15, 0.55), 1, (0.38, 0.45, 0.14), (-25, 0, 0)), sph((0, 0.45, 0.45), 1, (0.36, 0.25, 0.12), (-40, 0, 0))], "cape", 0.012)
    setmat(cape, mat("velvet", (0.75, 0.1, 0.16), 0.75, bump=0.1, bump_scale=60)); P.append(cape)
    collar = fuse([sph((0, -0.12, 0.66), 1, (0.3, 0.14, 0.1), (-20, 0, 0))], "cape", 0.01); setmat(collar, mat("ermine", (0.97, 0.95, 0.9), 0.8)); P.append(collar)
    for k in range(4):
        d = sph((-0.2 + k * 0.13, -0.24, 0.66 - abs(k - 1.5) * 0.02), 0.022); setmat(d, mat("pupil", BLACK, 0.1)); P.append(d)
    # cetro de osso com gema na pata da frente
    sc = []
    rod = cyl((0.2, -0.5, 0.35), 0.022, 0.6, (0, -20, 0), seg=8, bevel=0.005); hard(rod); setmat(rod, gold); sc.append(rod)
    top = sph((0.31, -0.5, 0.64), 0.06); setmat(top, mat("gemp", (0.8, 0.3, 1.0), 0.2, emit=3.0)); sc.append(top)
    tag(sc, "leg_fl"); P += sc
    return group("rat_king", P)


# ------------------------------------------------------------------ morcego

def bat():
    P = []
    FURB = (0.36, 0.24, 0.44)
    FURB_D = (0.18, 0.1, 0.24)
    body = fuse([sph((0, 0, 0.5), 1, (0.26, 0.24, 0.26)), sph((0, -0.04, 0.82), 1, (0.24, 0.22, 0.2)),
                 sph((0, -0.24, 0.76), 1, (0.08, 0.07, 0.06))], "batbody", 0.01, smooth=0.7, iters=8)
    paint(body, lambda p, n: mix(mix(FURB, FURB_D, smoothstep(0.2, 0.9, n.z) * 0.4), (0.62, 0.48, 0.62), ell_w(p, (0, -0.22, 0.48), (0.16, 0.12, 0.2)) * 0.8))
    setmat(body, mat("batv", vcol=True, rough=0.85, bump=0.2, bump_scale=120)); P.append(body)
    for sx in (-1, 1):
        ear = sph((sx * 0.15, -0.02, 1.08), 1, (0.09, 0.04, 0.2), (0, sx * -15, sx * -18)); shade(ear); setmat(ear, mat("batear", FURB, 0.8)); P.append(ear)
        inn = sph((sx * 0.15, -0.045, 1.07), 1, (0.06, 0.02, 0.15), (0, sx * -15, sx * -18)); shade(inn); setmat(inn, mat("pink_in", (0.95, 0.5, 0.62), 0.5)); P.append(inn)
        P += eye((sx * 0.1, -0.21, 0.87), 0.065)
        fang = box((sx * 0.035, -0.29, 0.69), (0.025, 0.02, 0.06), bevel=0.006, taper=(0.15, 0.4)); hard(fang); setmat(fang, mat("tooth", (1, 0.97, 0.88), 0.3)); P.append(fang)
        foot = sph((sx * 0.08, -0.02, 0.24), 1, (0.05, 0.06, 0.04)); shade(foot); setmat(foot, mat("batfoot", FURB_D, 0.8)); P.append(foot)
    nose = sph((0, -0.31, 0.78), 1, (0.035, 0.025, 0.025)); shade(nose); setmat(nose, mat("nose", (0.95, 0.42, 0.5), 0.3)); P.append(nose)
    tag(P, "body")
    mem = mat("membrane", (0.48, 0.25, 0.55), 0.6, sss=0.2)
    bonem = mat("batbone", FURB_D, 0.7)
    for sx in (-1, 1):
        W = []
        sh = Vector((sx * 0.2, 0.0, 0.62))
        tips = [Vector((sx * 0.95, 0.05, 0.95)), Vector((sx * 1.05, 0.08, 0.55)), Vector((sx * 0.8, 0.1, 0.28))]
        elbow = Vector((sx * 0.5, 0.02, 0.8))
        arm = tube([tuple(sh), tuple(elbow)], 0.03, 0.8, 6); setmat(arm, bonem); W.append(arm)
        for t in tips:
            f = tube([tuple(elbow), tuple((elbow + t) / 2 + Vector((0, 0, 0.04))), tuple(t)], 0.018, 0.4, 8); setmat(f, bonem); W.append(f)
        # membrana: leque de esferas achatadas entre os dedos
        blobs = []
        pts = [sh, elbow] + tips
        for k in range(len(tips)):
            a = elbow; b = tips[k]; c = tips[k + 1] if k + 1 < len(tips) else sh + Vector((0, 0.02, -0.2))
            ctr = (a + b + c) / 3
            size = max((b - a).length, (c - a).length) * 0.5
            blobs.append(sph(tuple(ctr), 1, (size * 0.9, 0.012, size * 0.62), (0, sx * -math.degrees(math.atan2(ctr.z - a.z, abs(ctr.x - a.x))), 0)))
        m = fuse(blobs, "wing", 0.012, smooth=0.4, iters=3); setmat(m, mem); W.append(m)
        tag(W, "wing_l" if sx > 0 else "wing_r"); P += W
    return group("bat", P)


# ------------------------------------------------------------------ espectro (caveira flutuante)

def spectre():
    P = []
    CY = (0.3, 0.95, 0.85)
    wisp = fuse([sph((0, 0.05, 0.62), 1, (0.32, 0.32, 0.3)), sph((0, 0.18, 0.35), 1, (0.2, 0.2, 0.25)), sph((0.05, 0.3, 0.15), 1, (0.1, 0.1, 0.16))], "wisp", 0.012, 0.8, 10)
    paint(wisp, lambda p, n: mix((0.1, 0.55, 0.6), CY, smoothstep(0.1, 0.8, p.z)))
    setmat(wisp, mat("wispv", vcol=True, rough=0.3, emit=1.0)); P.append(wisp)
    skull = fuse([sph((0, -0.05, 0.85), 1, (0.3, 0.28, 0.28)), sph((0, -0.15, 0.7), 1, (0.2, 0.18, 0.12))], "skull", 0.01)
    paint(skull, lambda p, n: mix(BONE, BONE_D, smoothstep(0.4, -0.6, n.z) * 0.5)); setmat(skull, mat("bonev", vcol=True, rough=0.55)); P.append(skull)
    for sx in (-1, 1):
        P += glow_eye((sx * 0.11, -0.28, 0.86), 0.09, CY)
    jaw = fuse([sph((0, -0.2, 0.6), 1, (0.15, 0.12, 0.06))], "jaw", 0.008); setmat(jaw, mat("bone", BONE, 0.6)); P.append(jaw)
    for k in range(4):
        t = box((-0.075 + k * 0.05, -0.31, 0.64), (0.035, 0.02, 0.05), bevel=0.006); hard(t); setmat(t, mat("tooth", (1, 0.97, 0.88), 0.3)); P.append(t)
    nose = box((0, -0.33, 0.76), (0.05, 0.03, 0.05), (0, 45, 0), bevel=0.01); hard(nose); setmat(nose, mat("socket", (0.05, 0.03, 0.06), 0.6)); P.append(nose)
    flame = fuse([sph((0, 0.0, 1.1), 1, (0.12, 0.12, 0.2)), sph((0.06, 0.02, 1.25), 1, (0.06, 0.06, 0.12))], "flame", 0.012)
    setmat(flame, mat("cyflame", CY, 0.4, emit=6.0)); P.append(flame)
    tag(P, "body")
    return group("spectre", P)


# ------------------------------------------------------------------ cultistas

def cultists():
    P = []
    ROBE = (0.42, 0.1, 0.32)
    ROBE_D = (0.2, 0.04, 0.16)
    robe = fuse([sph((0, 0.02, 0.45), 1, (0.34, 0.32, 0.45)), sph((0, 0.02, 0.85), 1, (0.27, 0.24, 0.3)), sph((0, 0.04, 0.12), 1, (0.38, 0.36, 0.14))], "robe", 0.012, 0.6, 6)
    paint(robe, lambda p, n: mix(ROBE_D, ROBE, smoothstep(0.0, 0.9, p.z) * 0.6 + smoothstep(-0.3, 0.9, n.z) * 0.3))
    setmat(robe, mat("robev", vcol=True, rough=0.85, bump=0.15, bump_scale=100)); P.append(robe)
    hem = torus((0, 0.04, 0.06), 0.36, 0.035, s=(1, 0.95, 1)); shade(hem); setmat(hem, mat("gold", GOLD, 0.3, 1.0)); P.append(hem)
    sash = torus((0, 0.02, 0.62), 0.29, 0.03, s=(1, 0.88, 1)); shade(sash); setmat(sash, mat("gold", GOLD, 0.3, 1.0)); P.append(sash)
    pend = cyl((0, -0.29, 0.82), 0.06, 0.02, (90, 0, 0), seg=10, bevel=0.005); hard(pend); setmat(pend, mat("gemp", (0.95, 0.35, 0.8), 0.2, emit=3.0)); P.append(pend)
    for sx in (-1, 1):
        f = sph((sx * 0.12, -0.24, 0.04), 1, (0.08, 0.1, 0.05)); shade(f); setmat(f, mat("boot", (0.12, 0.08, 0.1), 0.7)); P.append(f)
    tag(P, "body")
    # capuz pontudo com o rosto na sombra e olhos acesos
    H = []
    hood = fuse([sph((0, 0.02, 1.2), 1, (0.27, 0.27, 0.27)), sph((0, 0.12, 1.45), 1, (0.12, 0.12, 0.2), (-30, 0, 0)), sph((0, 0.25, 1.6), 1, (0.06, 0.06, 0.1), (-60, 0, 0))], "hood", 0.012)
    cut = sph((0, -0.24, 1.17), 1, (0.17, 0.2, 0.19))
    m = hood.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(hood); bpy.data.objects.remove(cut)
    shade(hood); setmat(hood, mat("robec", ROBE, 0.85)); H.append(hood)
    face = sph((0, -0.05, 1.17), 1, (0.17, 0.12, 0.17)); shade(face); setmat(face, mat("shadow", (0.04, 0.02, 0.05), 0.9)); H.append(face)
    for sx in (-1, 1):
        e = sph((sx * 0.07, -0.17, 1.19), 1, (0.04, 0.02, 0.025)); setmat(e, mat("cultglow", (1.0, 0.35, 0.8), 0.4, emit=8.0)); H.append(e)
    tag(H, "head"); P += H
    # mangas largas: uma segura a vela acesa, a outra o livro
    for sx in (-1, 1):
        A = []
        a = fuse(capsule((sx * 0.24, 0.0, 0.9), (sx * 0.34, -0.12, 0.6), 0.09, 0.12), "sleeve", 0.012); setmat(a, mat("robec", ROBE, 0.85)); A.append(a)
        h = sph((sx * 0.35, -0.16, 0.54), 0.06); setmat(h, mat("skinp", (0.75, 0.62, 0.68), 0.6)); A.append(h)
        if sx > 0:
            c = cyl((0.35, -0.2, 0.66), 0.035, 0.18, seg=8, bevel=0.005); hard(c); setmat(c, mat("candle", (0.95, 0.9, 0.78), 0.6)); A.append(c)
            fl = sph((0.35, -0.2, 0.8), 1, (0.03, 0.03, 0.06)); setmat(fl, mat("flame", (1.0, 0.72, 0.35), 0.5, emit=8.0)); A.append(fl)
        else:
            b = box((-0.36, -0.22, 0.56), (0.18, 0.06, 0.22), (0, 0, 20), bevel=0.012); hard(b); setmat(b, mat("book", (0.12, 0.1, 0.12), 0.6)); A.append(b)
            sy = box((-0.36, -0.26, 0.58), (0.06, 0.01, 0.06), (0, 0, 20), bevel=0.003); setmat(sy, mat("gemp", (0.95, 0.35, 0.8), 0.2, emit=3.0)); A.append(sy)
        tag(A, "arm_l" if sx > 0 else "arm_r"); P += A
    return group("cultists", P)


# ------------------------------------------------------------------ lobisomem

def werewolf():
    P = []
    FW = (0.42, 0.36, 0.38)
    FW_D = (0.22, 0.18, 0.22)
    body = fuse([
        sph((0, 0.05, 0.95), 1, (0.38, 0.32, 0.42), (-15, 0, 0)),             # tronco curvado
        sph((0, -0.05, 1.32), 1, (0.48, 0.36, 0.3)),                          # ombros largos
        sph((0, -0.26, 1.48), 1, (0.24, 0.24, 0.22)),                         # cabeça
        sph((0, -0.5, 1.42), 1, (0.12, 0.2, 0.1), (10, 0, 0)),                # focinho
        capsule((0.18, 0.05, 0.62), (0.22, -0.05, 0.32), 0.15, 0.1), capsule((0.22, -0.05, 0.32), (0.22, 0.08, 0.08), 0.1, 0.08),
        capsule((-0.18, 0.05, 0.62), (-0.22, -0.05, 0.32), 0.15, 0.1), capsule((-0.22, -0.05, 0.32), (-0.22, 0.08, 0.08), 0.1, 0.08),
        capsule((0.45, -0.05, 1.32), (0.55, -0.2, 0.95), 0.12, 0.1), capsule((0.55, -0.2, 0.95), (0.55, -0.35, 0.65), 0.1, 0.09),
        capsule((-0.45, -0.05, 1.32), (-0.55, -0.2, 0.95), 0.12, 0.1), capsule((-0.55, -0.2, 0.95), (-0.55, -0.35, 0.65), 0.1, 0.09),
        sph((0.55, -0.38, 0.6), 0.11), sph((-0.55, -0.38, 0.6), 0.11),
    ], "wolf", 0.013, 0.6, 6)

    def fur(p, n):
        c = mix(FW, FW_D, smoothstep(0.2, 0.9, n.z) * 0.5 + smoothstep(1.2, 1.6, p.z) * 0.2)
        c = mix(c, (0.75, 0.68, 0.62), ell_w(p, (0, -0.3, 1.0), (0.25, 0.2, 0.35)) * 0.7)
        c = mix(c, (0.8, 0.74, 0.7), ell_w(p, (0, -0.58, 1.38), (0.1, 0.12, 0.08)) * 0.8)
        return c
    paint(body, fur); setmat(body, mat("wolfv", vcol=True, rough=0.85, bump=0.35, bump_scale=110)); P.append(body)
    # tufos de pelo nos ombros e no peito (silhueta espinhosa de cima)
    for k in range(7):
        a = -0.9 + k * 0.3
        t = box((math.sin(a) * 0.42, 0.12 + abs(math.sin(a)) * 0.05, 1.5 - abs(a) * 0.1), (0.1, 0.14, 0.26), (-35, math.degrees(a) * 0.6, 0), bevel=0.02, taper=(0.1, 0.4))
        hard(t); setmat(t, mat("furd", FW_D, 0.85)); P.append(t)
    for sx in (-1, 1):
        ear = box((sx * 0.14, -0.2, 1.72), (0.12, 0.06, 0.24), (-10, sx * 15, 0), bevel=0.02, taper=(0.1, 0.5)); hard(ear); setmat(ear, mat("furd", FW_D, 0.85)); P.append(ear)
        P += yellow_eye((sx * 0.1, -0.44, 1.55), 0.06, 25, sx, (1.0, 0.75, 0.2), (0.22, 0.18, 0.22))
        for k in range(3):
            cl = box((sx * 0.55 + (k - 1) * 0.05, -0.47, 0.54), (0.025, 0.06, 0.08), (40, 0, 0), bevel=0.006, taper=(0.1, 0.1)); hard(cl); setmat(cl, mat("claw", (0.95, 0.92, 0.85), 0.4)); P.append(cl)
        f = sph((sx * 0.22, -0.02, 0.05), 1, (0.1, 0.17, 0.06)); shade(f); setmat(f, mat("furd", FW_D, 0.85)); P.append(f)
    nose = sph((0, -0.66, 1.45), 1, (0.05, 0.04, 0.04)); shade(nose); setmat(nose, mat("pupil", BLACK, 0.2)); P.append(nose)
    for sx in (-1, 1):
        fang = box((sx * 0.05, -0.6, 1.33), (0.025, 0.02, 0.07), bevel=0.006, taper=(0.15, 0.4)); hard(fang); setmat(fang, mat("tooth", (1, 0.97, 0.88), 0.3)); P.append(fang)
    tail = tube([(0, 0.32, 0.75), (0, 0.55, 0.6), (0.1, 0.72, 0.4)], 0.09, 0.4, 16); paint(tail, lambda p, n: FW_D); setmat(tail, mat("wolfv", vcol=True, rough=0.85, bump=0.35, bump_scale=110)); P.append(tail)
    # coleira rasgada com corrente: foi um aldeão
    col = torus((0, -0.15, 1.3), 0.22, 0.035, (20, 0, 0)); shade(col); setmat(col, mat("leather", LEATHER, 0.6)); P.append(col)
    tag([col], "head")
    return group("werewolf", P)


# ------------------------------------------------------------------ golem de sucata (peças duras chanfradas)

def scrap_golem():
    P = []
    plate = lambda c: mat("plate_%s" % str(c), c, 0.6, 0.7)
    PL = (0.5, 0.45, 0.4)
    PL2 = (0.62, 0.36, 0.22)
    PL3 = (0.36, 0.42, 0.48)
    B = []
    chest = box((0, 0, 1.4), (1.1, 0.75, 0.8), (0, 0, 0), bevel=0.08, seg=2, taper=(1.15, 1.0)); hard(chest); setmat(chest, plate(PL)); B.append(chest)
    belly = box((0, 0.02, 0.9), (0.75, 0.6, 0.45), bevel=0.06); hard(belly); setmat(belly, plate(PL3)); B.append(belly)
    hip = box((0, 0.02, 0.62), (0.9, 0.55, 0.22), bevel=0.05); hard(hip); setmat(hip, plate(PL2)); B.append(hip)
    furn = cyl((0, -0.38, 1.38), 0.22, 0.08, (90, 0, 0), seg=16, bevel=0.02); hard(furn); setmat(furn, mat("ironn", IRON, 0.5, 0.8)); B.append(furn)
    core = cyl((0, -0.42, 1.38), 0.16, 0.04, (90, 0, 0), seg=16, bevel=0.0); setmat(core, mat("furnace", (1.0, 0.5, 0.12), 0.4, emit=8.0)); B.append(core)
    for k in range(3):
        g = box((0, -0.43, 1.31 + k * 0.07), (0.3, 0.03, 0.025), bevel=0.005); hard(g); setmat(g, mat("ironn", IRON, 0.5, 0.8)); B.append(g)
    for x in (-0.45, 0.45):
        for z in (1.1, 1.7):
            r = sph((x, -0.38, z), 0.035); setmat(r, mat("rivet", (0.75, 0.7, 0.6), 0.4, 0.8)); B.append(r)
    pipe = tube([(0.3, 0.38, 1.6), (0.35, 0.5, 1.9), (0.3, 0.45, 2.15)], 0.07, 1.0, 12); setmat(pipe, mat("plate_r", PL2, 0.6, 0.7)); B.append(pipe)
    smoke = sph((0.3, 0.45, 2.25), 1, (0.09, 0.09, 0.05)); setmat(smoke, mat("ember", (1.0, 0.5, 0.12), 0.4, emit=4.0)); B.append(smoke)
    tag(B, "body"); P += B
    Hd = []
    head = box((0, -0.05, 1.98), (0.45, 0.42, 0.32), bevel=0.06, taper=(0.85, 0.9)); hard(head); setmat(head, plate(PL3)); Hd.append(head)
    visor = box((0, -0.27, 1.98), (0.36, 0.05, 0.09), bevel=0.02); hard(visor); setmat(visor, mat("furnace", (1.0, 0.5, 0.12), 0.4, emit=8.0)); Hd.append(visor)
    bolt = cyl((0, -0.05, 2.18), 0.06, 0.1, seg=6, bevel=0.01); hard(bolt); setmat(bolt, mat("ironn", IRON, 0.5, 0.8)); Hd.append(bolt)
    tag(Hd, "head"); P += Hd
    for sx in (-1, 1):
        A = []
        sh = sph((sx * 0.72, 0.0, 1.65), 1, (0.26, 0.26, 0.22)); setmat(sh, plate(PL2)); A.append(sh)
        up = box((sx * 0.78, -0.02, 1.25), (0.26, 0.26, 0.55), (0, sx * -8, 0), bevel=0.05); hard(up); setmat(up, plate(PL)); A.append(up)
        fist = box((sx * 0.85, -0.08, 0.68), (0.42, 0.42, 0.45), (0, 0, sx * 10), bevel=0.08, seg=2); hard(fist); setmat(fist, plate(PL3)); A.append(fist)
        for k in range(3):
            kn = box((sx * 0.85 + (k - 1) * 0.12, -0.3, 0.72), (0.09, 0.06, 0.12), bevel=0.02); hard(kn); setmat(kn, mat("ironn", IRON, 0.5, 0.8)); A.append(kn)
        tag(A, "arm_l" if sx > 0 else "arm_r"); P += A
        L = []
        leg = box((sx * 0.25, 0.02, 0.32), (0.3, 0.32, 0.5), bevel=0.05); hard(leg); setmat(leg, plate(PL)); L.append(leg)
        ft = box((sx * 0.27, -0.06, 0.07), (0.36, 0.48, 0.14), bevel=0.04); hard(ft); setmat(ft, plate(PL2)); L.append(ft)
        tag(L, "leg_l" if sx > 0 else "leg_r"); P += L
    return group("scrap_golem", P)


# ------------------------------------------------------------------ mímico

def mimic():
    P = []
    woodm = mat("chestwood", (0.55, 0.32, 0.16), 0.7, bump=0.3, bump_scale=14)
    metal = mat("chestiron", (0.38, 0.36, 0.4), 0.45, 0.8)
    gold = mat("gold", GOLD, 0.3, 1.0)
    B = []
    base = box((0, 0, 0.3), (1.0, 0.7, 0.6), bevel=0.05, seg=2); hard(base); setmat(base, woodm); B.append(base)
    for x in (-0.38, 0.38):
        b = box((x, 0, 0.3), (0.09, 0.74, 0.64), bevel=0.02); hard(b); setmat(b, metal); B.append(b)
    inner = box((0, 0, 0.56), (0.88, 0.58, 0.12), bevel=0.03); hard(inner); setmat(inner, mat("mouthd", (0.35, 0.05, 0.1), 0.5)); B.append(inner)
    tongue = fuse([sph((0, -0.15, 0.62), 1, (0.16, 0.32, 0.06)), sph((0, -0.45, 0.58), 1, (0.12, 0.12, 0.05))], "tongue", 0.01)
    setmat(tongue, mat("tongue", (0.95, 0.38, 0.5), 0.4)); B.append(tongue)
    for k in range(7):
        t = box((-0.42 + k * 0.14, -0.33, 0.66), (0.07, 0.04, 0.12), bevel=0.008, taper=(0.1, 0.5)); hard(t); setmat(t, mat("tooth", (1, 0.97, 0.88), 0.3)); B.append(t)
    for k in range(4):
        c = cyl((-0.2 + k * 0.13, 0.15, 0.62), 0.07, 0.03, (10, 0, 0), seg=10, bevel=0.005); hard(c); setmat(c, gold); B.append(c)
    for sx in (-1, 1):
        f = fuse(capsule((sx * 0.4, -0.2, 0.15), (sx * 0.55, -0.3, 0.02), 0.06, 0.05), "leg", 0.01); setmat(f, mat("tongue", (0.95, 0.38, 0.5), 0.4)); B.append(f)
    tag(B, "body"); P += B
    # tampa (osso "lid", articulada atrás): dentes de cima e um olho grande no meio
    L = []
    lid = box((0, 0.0, 0.73), (1.02, 0.72, 0.24), bevel=0.06, seg=3); hard(lid); setmat(lid, woodm); L.append(lid)
    for x in (-0.38, 0.38):
        b = box((x, 0, 0.74), (0.09, 0.76, 0.26), bevel=0.02); hard(b); setmat(b, metal); L.append(b)
    lock = box((0, -0.38, 0.68), (0.14, 0.05, 0.16), bevel=0.02); hard(lock); setmat(lock, gold); L.append(lock)
    for k in range(7):
        t = box((-0.42 + k * 0.14, -0.33, 0.6), (0.07, 0.04, 0.1), (180, 0, 0), bevel=0.008, taper=(0.1, 0.5)); hard(t); setmat(t, mat("tooth", (1, 0.97, 0.88), 0.3)); L.append(t)
    L += yellow_eye((0, -0.36, 0.83), 0.09, 20, 1, (0.95, 0.3, 0.25), (0.55, 0.32, 0.16))
    tag(L, "lid"); P += L
    return group("mimic", P)


# ------------------------------------------------------------------ totem de ossos

def bone_totem():
    P = []
    post = box((0, 0, 0.9), (0.24, 0.24, 1.8), (0, 0, 8), bevel=0.04); hard(post); setmat(post, mat("woodd", (0.3, 0.2, 0.13), 0.8, bump=0.4, bump_scale=10)); P.append(post)
    base = fuse([sph((0, 0, 0.05), 1, (0.45, 0.45, 0.18))], "mound", 0.03)
    paint(base, lambda p, n: mix((0.3, 0.22, 0.15), (0.38, 0.3, 0.2), smoothstep(0.5, 1.0, n.z))); setmat(base, mat("dirtv", vcol=True, rough=0.9)); P.append(base)
    for z, s, gl in ((1.75, 0.3, (0.55, 1.0, 0.45)), (1.25, 0.24, (0.55, 1.0, 0.45)), (0.85, 0.2, (0.55, 1.0, 0.45))):
        sk = fuse([sph((0, -0.06, z), 1, (s, s * 0.95, s * 0.9)), sph((0, -0.16, z - s * 0.5), 1, (s * 0.7, s * 0.6, s * 0.35))], "skull", 0.01)
        paint(sk, lambda p, n: mix(BONE, BONE_D, smoothstep(0.4, -0.6, n.z) * 0.5)); setmat(sk, mat("bonev", vcol=True, rough=0.6)); P.append(sk)
        for sx in (-1, 1):
            P += glow_eye((sx * s * 0.38, -0.06 - s * 0.8, z + s * 0.05), s * 0.3, gl)
    for a in (35, -35):
        b = capsule((-0.45, -0.1, 1.45 + (0.1 if a > 0 else 0)), (0.45, -0.1, 1.45 - (0.1 if a > 0 else 0)), 0.035)
        b += [sph((-0.47, -0.1, 1.45 + (0.1 if a > 0 else 0)), 0.06), sph((0.47, -0.1, 1.45 - (0.1 if a > 0 else 0)), 0.06)]
        bb = fuse(b, "bone", 0.01); setmat(bb, mat("bone", BONE, 0.6)); P.append(bb)
    for k, c in enumerate(((0.85, 0.2, 0.25), (0.3, 0.6, 0.9), (0.95, 0.8, 0.3))):
        fe = box((0.15 + k * 0.05, 0.05, 2.05 + k * 0.05), (0.06, 0.02, 0.32), (0, 25 - k * 20, 0), bevel=0.01, taper=(0.2, 1.0)); hard(fe); setmat(fe, mat("feather%d" % k, c, 0.7)); P.append(fe)
    rag = fuse([sph((0, 0.13, 1.0), 1, (0.2, 0.03, 0.35))], "rag", 0.01); setmat(rag, mat("rag", (0.32, 0.26, 0.38), 0.9)); P.append(rag)
    tag(P, "body")
    return group("bone_totem", P)


# ------------------------------------------------------------------ ninho de morcegos

def bat_nest():
    """Toco oco de árvore morta (tronco cônico torto, raízes, galhos secos) com a boca escura cheia de olhos
    e morcegos pendurados nos galhos."""
    from scenery import jitter
    P = []
    BK = (0.36, 0.26, 0.24)
    BK_D = (0.16, 0.1, 0.12)

    def bark(p, n):
        k = noise.noise(Vector((p.x * 4, p.y * 4, p.z * 0.7))) * 0.5 + 0.5
        return mix(BK_D, BK, smoothstep(-0.4, 0.8, n.z) * 0.35 + k * 0.65)
    trunk = cyl((0, 0, 1.25), 0.72, 2.5, seg=12, bevel=0.06, r2=0.42); apply_mods(trunk)
    bm = bmesh.new(); bm.from_mesh(trunk.data)
    bmesh.ops.subdivide_edges(bm, edges=[e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 0.5], cuts=6, use_grid_fill=True)
    for v in bm.verts:   # torce e entorta o tronco
        a = v.co.z * 0.35
        x, y = v.co.x, v.co.y
        v.co.x = x * math.cos(a) - y * math.sin(a) + 0.12 * math.sin(v.co.z * 1.3)
        v.co.y = x * math.sin(a) + y * math.cos(a)
    bm.to_mesh(trunk.data); bm.free()
    jitter(trunk, 0.06, 1.2, 31)
    cut = sph((0, -0.62, 1.15), 1, (0.36, 0.4, 0.55))
    m = trunk.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(trunk); bpy.data.objects.remove(cut)
    shade(trunk); paint(trunk, bark); setmat(trunk, mat("barkv", vcol=True, rough=0.85, bump=0.5, bump_scale=8)); P.append(trunk)
    hole = sph((0, -0.32, 1.15), 1, (0.3, 0.2, 0.48)); setmat(hole, mat("shadow", (0.03, 0.02, 0.04), 0.9)); P.append(hole)
    for (x, z) in ((-0.12, 1.35), (0.14, 1.25), (0.0, 1.0), (-0.16, 0.95), (0.18, 1.5)):
        e = sph((x, -0.5, z), 1, (0.05, 0.03, 0.035)); setmat(e, mat("batglow", (1.0, 0.85, 0.3), 0.4, emit=8.0)); P.append(e)
    for a in (0.3, 1.7, 3.1, 4.4, 5.5):
        r = tube([(math.cos(a) * 0.45, math.sin(a) * 0.45, 0.6), (math.cos(a) * 0.85, math.sin(a) * 0.85, 0.22), (math.cos(a + 0.2) * 1.15, math.sin(a + 0.2) * 1.15, 0.04)], 0.24, 0.35, 12)
        paint(r, bark); setmat(r, mat("barkv", vcol=True, rough=0.85)); P.append(r)
    for (a, b, c) in (((0.1, 0, 2.3), (0.6, -0.1, 2.75), (1.05, 0.0, 2.85)), ((-0.1, 0, 2.2), (-0.6, 0.1, 2.6), (-0.95, -0.1, 3.05)),
                      ((0.0, 0.1, 2.45), (0.1, 0.4, 2.9), (0.25, 0.5, 3.25))):
        br = tube([a, b, c], 0.16, 0.3, 12); paint(br, bark); setmat(br, mat("barkv", vcol=True, rough=0.85)); P.append(br)
    # morcegos dormindo de cabeça para baixo nos galhos
    for (x, y, z) in ((0.75, -0.08, 2.62), (-0.68, 0.06, 2.48), (0.98, 0.0, 2.68)):
        b = fuse([sph((x, y, z), 1, (0.1, 0.09, 0.14)), sph((x, y, z - 0.14), 0.08)], "sleeper", 0.008)
        setmat(b, mat("batfur", (0.42, 0.26, 0.5), 0.85)); P.append(b)
        for sx in (-1, 1):
            w = sph((x + sx * 0.08, y, z - 0.02), 1, (0.05, 0.03, 0.12)); setmat(w, mat("membrane", (0.48, 0.25, 0.55), 0.6)); P.append(w)
            e = sph((x + sx * 0.035, y - 0.07, z - 0.16), 0.018); setmat(e, mat("hl", WHITE, 0.3, emit=0.6)); P.append(e)
    mush = []
    for (x, y, s_) in ((0.55, -0.35, 1.0), (0.42, -0.5, 0.7)):
        cap = sph((x, y, 0.55 * s_), 1, (0.13 * s_, 0.13 * s_, 0.07 * s_)); setmat(cap, mat("mcapp", (0.6, 0.3, 0.85), 0.4, emit=1.2)); mush.append(cap)
    P += mush
    tag(P, "body")
    return group("bat_nest", P)


# ------------------------------------------------------------------ torre da gárgula

def gargoyle_tower():
    P = []
    DS = (0.42, 0.4, 0.46)
    DS_D = (0.26, 0.24, 0.3)
    B = []
    for k in range(5):
        r_ = 0.62 - k * 0.04
        z = 0.25 + k * 0.42
        ring = cyl((0, 0, z), r_, 0.4, (0, 0, k * 13), seg=8, bevel=0.05)
        hard(ring)
        paint(ring, lambda p, n, k=k: mix(DS_D, DS, smoothstep(-0.5, 0.9, n.z) * 0.4 + 0.3 + (k % 2) * 0.1))
        setmat(ring, mat("dsv", vcol=True, rough=0.85)); B.append(ring)
    top = cyl((0, 0, 2.3), 0.62, 0.18, seg=8, bevel=0.04); hard(top); setmat(top, mat("ds", DS, 0.85)); B.append(top)
    for k in range(8):
        a = k / 8 * math.tau
        m_ = box((math.cos(a) * 0.55, math.sin(a) * 0.55, 2.47), (0.2, 0.16, 0.18), (0, 0, math.degrees(a)), bevel=0.03); hard(m_); setmat(m_, mat("ds", DS, 0.85)); B.append(m_)
    win = box((0, -0.55, 1.25), (0.2, 0.12, 0.35), bevel=0.03); hard(win); setmat(win, mat("winp", (1.0, 0.55, 0.95), 0.4, emit=4.0)); B.append(win)
    ivy = tube([(0.5 * math.cos(a / 4 + 1), 0.5 * math.sin(a / 4 + 1), 0.1 + a * 0.15) for a in range(12)], 0.035, 0.6, 30)
    setmat(ivy, mat("vine", (0.25, 0.45, 0.2), 0.8)); B.append(ivy)
    tag(B, "body"); P += B
    # gárgula agachada no topo, olhando para a frente (osso "head": inclina no ataque)
    G = []
    GS = (0.5, 0.5, 0.58)
    gb = fuse([sph((0, 0, 2.75), 1, (0.22, 0.2, 0.25)), sph((0, -0.12, 3.0), 1, (0.17, 0.16, 0.15)),
               capsule((0.12, -0.05, 2.65), (0.14, -0.2, 2.55), 0.07), capsule((-0.12, -0.05, 2.65), (-0.14, -0.2, 2.55), 0.07)], "garg", 0.01)
    paint(gb, lambda p, n: mix((0.3, 0.3, 0.36), GS, smoothstep(-0.4, 0.9, n.z) * 0.7 + 0.2)); setmat(gb, mat("gargv", vcol=True, rough=0.75)); G.append(gb)
    for sx in (-1, 1):
        G += glow_eye((sx * 0.06, -0.26, 3.02), 0.045, (1.0, 0.45, 0.9), socket=False)
        horn = box((sx * 0.08, -0.08, 3.16), (0.05, 0.05, 0.16), (-20, sx * 20, 0), bevel=0.01, taper=(0.1, 0.1)); hard(horn); setmat(horn, mat("hornd", (0.2, 0.18, 0.22), 0.6)); G.append(horn)
        wing = box((sx * 0.32, 0.12, 2.92), (0.42, 0.05, 0.3), (0, sx * -25, sx * 20), bevel=0.02, taper=(0.4, 1.0)); hard(wing); setmat(wing, mat("ds", DS, 0.85)); G.append(wing)
    tag(G, "head"); P += G
    return group("gargoyle_tower", P)
