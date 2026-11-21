"""Inimigos novos (rodada visual 20/11/2026): cartas de monstro que usavam o modelo de outra criatura recolorido
(VARIANTS em game/art/looks.gd) ganham modelo próprio, fiel à arte da carta (assets/cards/<id>.png).
Mesmo kit de tools/art/blender_v2 (mk.py, ossos rígidos por parte, VAT); padrão de creatures_new.py (17/11).
Exportar: tools/art/blender_m2/build_m2.py (wrapper com a exportação da V4 e o ataque no sentido do jogo).
Blender: Z para cima, frente = -Y; +x = lado "l" dos ossos.

Ataque "de impacto" (strike): antecipação (recua) -> golpe rápido com avanço -> segura no impacto -> volta.
Regras de arte: guache como as cartas, pincel largo, nada miúdo; criaturas com olhos estilizados SEM pupila
(material "eyem2_*": o simplify do vat_g mantém, o flatten_eyes não mexe); humanos (o flautista) sem olhos.
Peças pequenas mas importantes (nariz, dentes, garras, moeda) se chamam "keep" (simplify(keep=("keep",)))."""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
V2 = os.path.abspath(os.path.join(HERE, "..", "blender_v2"))
for p in (V2, HERE):
    if p not in sys.path:
        sys.path.insert(0, p)
import bpy, bmesh
from mathutils import Matrix, Vector
from mk import *
from vat import tag, rot_about, tr
import mk, anims

# id -> (altura no jogo em metros, orçamento de triângulos). Altura = modelo base x escala do VARIANTS de hoje
# (bat 0,75; werewolf 1,8x0,8; goblin 1,0x0,7; skeleton 1,25x1,15; rat 0,5x1,55; cultists 1,45x0,95), a Mãe da
# Ninhada um pouco maior que o Rato Bruto (é tanque, 600 de vida).
UNITS_M2 = {
    "rat_brute": (0.8, 2200), "brood_mother": (1.0, 2600), "fire_imp": (0.78, 1900), "ghoul": (1.45, 2600),
    "kobold_scavengers": (0.72, 1500), "raised_servant": (1.45, 2400), "corrupt_piper": (1.4, 2600), "bat_cloud": (0.6, 1400),
}
TAU = math.tau
X = 'X'; Y = 'Y'; Z = 'Z'
R = math.radians


# =============================================================== ajudantes

def ease(x):
    return anims.ease(x)


def ease_out(x):
    x = max(0.0, min(1.0, x))
    return 1.0 - (1.0 - x) ** 3


def strike(t, a=0.26, b=0.4, c=0.68, over=0.12):
    """(wind, hit) do ataque de impacto: wind sobe até 1 (antecipação), cai a 0 no golpe rápido enquanto hit vai a
    1 + over; segura (assenta em 1) e volta a 0."""
    if t < a:
        return ease(t / a), 0.0
    if t < b:
        u = (t - a) / (b - a)
        return 1.0 - ease_out(u * 1.4), ease_out(u) * (1.0 + over)
    if t < c:
        return 0.0, 1.0 + over * (1.0 - ease((t - b) / (c - b)))
    return 0.0, 1.0 - ease((t - c) / (1.0 - c))


def col(name, c, rough=0.7, emit=0.0):
    return mat(name + "_" + str(c), c, rough, emit=emit)


def vc(name, rough=0.7):
    return mat(name, vcol=True, rough=rough)


def eye(loc, s, rot=(0, 0, 0), color=(0.1, 0.085, 0.11), emit=0.0):
    """Olho estilizado de uma cor só (sem pupila, sem reflexo)."""
    e = sph(loc, 1, s, rot, seg=20)
    setmat(e, mat("eyem2_%s" % str(color), color, 0.35, emit=emit))
    return e


def keep(o):
    o.name = "keep"
    return o


def cone(a, b, r1, r2=0.005, seg=14):
    """Cone de a até b (chifre, espinho, garra)."""
    a, b = Vector(a), Vector(b)
    d = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r1, radius2=r2, depth=d.length)
    me = bpy.data.meshes.new("cone"); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("cone", me); bpy.context.scene.collection.objects.link(o)
    o.location = (a + b) / 2
    o.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    shade(o)
    return o


def limb(pts, r1, r2, name="limb", voxel=0.012):
    """Membro: cápsulas encadeadas fundidas numa peça."""
    parts = []
    n = len(pts) - 1
    for i in range(n):
        ra = r1 + (r2 - r1) * i / n
        rb = r1 + (r2 - r1) * (i + 1) / n
        parts += capsule(pts[i], pts[i + 1], ra, rb, seg=20)
    return fuse(parts, name, voxel, 0.6, 4)


def flat_shape(pts2, z_of, thick=0.025, name="flat"):
    """Placa (asa, trapo) a partir de um contorno [(x, y)] com z = z_of(x, y); espessura `thick`."""
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, z_of(x, y))) for x, y in pts2]
    bm.faces.new(vs)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    m = o.modifiers.new("so", 'SOLIDIFY'); m.thickness = thick; m.offset = 0.0
    apply_mods(o)
    # subdivide para a pintura por vértice ter onde variar
    m = o.modifiers.new("ss", 'SUBSURF'); m.levels = 2; m.subdivision_type = 'SIMPLE'
    apply_mods(o)
    shade(o)
    return o


def flame(loc, r, h, tilt=(0, 0, 0), c1=(1.0, 0.42, 0.08), c2=(1.0, 0.68, 0.2)):
    """Língua de fogo: cone achatado emissivo com miolo claro."""
    out = []
    a = cyl((0, 0, h / 2), r, h, seg=10, bevel=0.0, r2=0.008); a.scale = (1.0, 0.55, 1.0); setmat(a, mat("m2flame", c1, 0.4, emit=3.0)); out.append(a)
    b = cyl((0, -r * 0.2, h * 0.32), r * 0.55, h * 0.62, seg=10, bevel=0.0, r2=0.008); b.scale = (1.0, 0.55, 1.0); setmat(b, mat("m2flamek", c2, 0.4, emit=4.0)); out.append(b)
    M = Matrix.Translation(loc) @ Euler_m(tilt)
    bpy.context.view_layer.update()
    for o in out:
        o.matrix_world = M @ o.matrix_world
    return out


def Euler_m(rot):
    from mathutils import Euler
    return Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()


def rat_head(P, c, k, fur, furd, snout, ear, eyec=(0.1, 0.085, 0.11), teeth=False, eye_up=0.0):
    """Cabeça de rato (parte 'head'): crânio + focinho, orelhas grandes, olhos de uma cor, nariz (e dentes)."""
    x, y, z = c
    hd = fuse([sph((x, y, z), 1, (0.24 * k, 0.27 * k, 0.21 * k)), sph((x, y - 0.25 * k, z - 0.06 * k), 1, (0.14 * k, 0.2 * k, 0.12 * k), (10, 0, 0))],
              "rathead", 0.012 * k, 0.6, 5)
    paint(hd, lambda p, n: mix(mix(furd, fur, smoothstep(-0.3, 0.8, n.z)), snout, smoothstep(y - 0.18 * k, y - 0.42 * k, p.y) * 0.85))
    setmat(hd, vc("m2fur")); P.append(hd)
    for sx in (-1, 1):
        e = sph((x + sx * 0.2 * k, y + 0.08 * k, z + 0.22 * k), 1, (0.19 * k, 0.05 * k, 0.21 * k), (10, 0, sx * -30), seg=24)
        paint(e, lambda p, n, sx=sx: mix(ear, (ear[0] * 0.75, ear[1] * 0.6, ear[2] * 0.65), 0.0)); setmat(e, col("m2ear", ear, 0.6)); P.append(e)
        P.append(eye((x + sx * 0.13 * k, y - 0.17 * k, z + 0.07 * k + eye_up), (0.06 * k, 0.035 * k, 0.05 * k), (0, 0, sx * 20), eyec))
    no = keep(sph((x, y - 0.46 * k, z - 0.07 * k), 1, (0.055 * k, 0.05 * k, 0.045 * k))); setmat(no, col("m2nose", ear, 0.5)); P.append(no)
    if teeth:
        t = keep(box((x, y - 0.42 * k, z - 0.17 * k), (0.07 * k, 0.03 * k, 0.09 * k), bevel=0.006)); hard(t); setmat(t, col("m2tooth", (0.95, 0.88, 0.62), 0.4)); P.append(t)
    return P


def quad_walk(h, fl, bl, neck, tail, stride=28, bob=0.04):
    return anims._quad(h, fl, bl, neck, tail, stride=stride, bob=bob)


# =============================================================== Rato Bruto

RB_FUR = (0.58, 0.67, 0.72); RB_FURD = (0.2, 0.22, 0.31); RB_PINK = (0.93, 0.56, 0.58)


def rat_brute():
    P = []
    def bcol(p, n):
        c = mix(RB_FURD, RB_FUR, smoothstep(-0.2, 0.85, n.z))
        return mix(c, (0.62, 0.64, 0.7), smoothstep(-0.3, -0.8, n.z) * 0.6)
    body = fuse([sph((0, 0.05, 0.58), 1, (0.5, 0.78, 0.55), (-8, 0, 0)), sph((0, 0.4, 0.45), 1, (0.46, 0.42, 0.42)),
                 sph((0, -0.5, 0.45), 1, (0.34, 0.32, 0.32))], "rbbody", 0.014, 0.6, 8)
    paint(body, bcol); setmat(body, vc("m2fur")); P.append(body)
    tag(P, "body")
    H = rat_head([], (0, -0.78, 0.44), 1.3, RB_FUR, RB_FURD, (0.68, 0.72, 0.78), RB_PINK, teeth=True)
    tag(H, "head"); P += H
    for key in ("fl", "fr", "bl", "br"):
        sx = 1 if key[1] == "l" else -1
        if key[0] == "f":
            pts = [(sx * 0.3, -0.45, 0.45), (sx * 0.34, -0.55, 0.22), (sx * 0.33, -0.66, 0.05)]
            L = [limb(pts, 0.13, 0.08, "rbleg")]
            paw = sph((sx * 0.33, -0.74, 0.04), 1, (0.1, 0.13, 0.05))
        else:
            pts = [(sx * 0.34, 0.32, 0.45), (sx * 0.4, 0.38, 0.2), (sx * 0.36, 0.22, 0.05)]
            L = [limb(pts, 0.2, 0.09, "rbleg")]
            paw = sph((sx * 0.36, 0.12, 0.04), 1, (0.11, 0.16, 0.05))
        paint(L[0], lambda p, n: mix(RB_PINK, mix(RB_FURD, RB_FUR, smoothstep(-0.2, 0.9, n.z)), smoothstep(0.06, 0.2, p.z)))
        setmat(L[0], vc("m2fur")); setmat(paw, col("m2paw", RB_PINK, 0.6)); L.append(paw)
        tag(L, "leg_" + key); P += L
    tl = tube([(0, 0.8, 0.42), (0.12, 1.15, 0.5), (0.3, 1.38, 0.8), (0.35, 1.45, 1.1)], 0.075, 0.35, 20)
    setmat(tl, col("m2tail", RB_PINK, 0.6)); tag([tl], "tail"); P.append(tl)
    return group("rat_brute", P)


def rat_brute_anim():
    fl, bl = Vector((0.3, -0.45, 0.45)), Vector((0.34, 0.32, 0.45))
    fr, br = Vector((-0.3, -0.45, 0.45)), Vector((-0.34, 0.32, 0.45))
    nk = Vector((0, -0.55, 0.5)); tl = Vector((0, 0.8, 0.42)); mid = Vector((0, -0.05, 0.3))
    walk = quad_walk(1.0, tuple(fl), tuple(bl), tuple(nk), tuple(tl), stride=30, bob=0.035)

    def anim(kind, t):
        if kind == "walk":
            return walk("walk", t)
        w, h = strike(t)
        # investida: encolhe para trás com a cabeça erguida, dispara para a frente com a cabeça baixa (cabeçada)
        B = tr(0, 0.16 * w - 0.5 * h, -0.05 * w + 0.03 * h) @ rot_about(mid, X, R(-10 * w + 12 * h))
        d = {"body": B, "head": B @ rot_about(nk, X, R(-18 * w + 22 * h)), "tail": B @ rot_about(tl, X, R(-25 * w + 30 * h))}
        d["leg_fl"] = B @ rot_about(fl, X, R(25 * w - 40 * h)); d["leg_fr"] = B @ rot_about(fr, X, R(25 * w - 40 * h))
        d["leg_bl"] = B @ rot_about(bl, X, R(-20 * w + 35 * h)); d["leg_br"] = B @ rot_about(br, X, R(-20 * w + 35 * h))
        return d
    return {"anim": anim}


# =============================================================== Mãe da Ninhada

BM_TOP = (0.8, 0.72, 0.62); BM_CREAM = (0.95, 0.91, 0.84); BM_SIDE = (0.47, 0.5, 0.58); BM_PINK = (0.93, 0.58, 0.6)
BABY = (0.55, 0.6, 0.7); BABYD = (0.32, 0.36, 0.46)


def baby_rat(c, yaw, P):
    x, y, z = c
    a = R(yaw)
    def at(dx, dy, dz):
        return (x + dx * math.cos(a) - dy * math.sin(a), y + dx * math.sin(a) + dy * math.cos(a), z + dz)
    b = fuse([sph(at(0, 0, 0), 1, (0.15, 0.2, 0.12)), sph(at(0, -0.19, 0.04), 1, (0.1, 0.11, 0.09))], "baby", 0.01, 0.6, 4)
    paint(b, lambda p, n: mix(BABYD, BABY, smoothstep(-0.3, 0.8, n.z))); setmat(b, vc("m2fur")); P.append(b)
    for sx in (-1, 1):
        e = keep(sph(at(sx * 0.08, -0.15, 0.12), 1, (0.065, 0.025, 0.07), (0, 0, yaw))); setmat(e, col("m2ear", BM_PINK, 0.6)); P.append(e)
    t = tube([at(0, 0.14, -0.02), at(0.08, 0.3, -0.05), at(0.18, 0.38, -0.04)], 0.025, 0.5, 8); t.name = "keep"; setmat(t, col("m2tail", BM_PINK, 0.6)); P.append(t)


def brood_mother():
    P = []
    def bcol(p, n):
        c = mix(BM_SIDE, BM_TOP, smoothstep(-0.35, 0.6, n.z))
        for (x, y, z, s) in ((0.25, 0.05, 1.0, 0.25), (-0.3, 0.45, 0.85, 0.22), (0.05, -0.35, 1.0, 0.2), (0.35, 0.5, 0.7, 0.18)):
            c = mix(c, BM_CREAM, ell_w(p, (x, y, z), (s, s, s)) * 0.8)
        return mix(c, BM_CREAM, ell_w(p, (0, -0.55, 0.45), (0.3, 0.25, 0.3)) * 0.9)
    body = fuse([sph((0, 0.1, 0.64), 1, (0.68, 0.85, 0.64)), sph((0, 0.45, 0.45), 1, (0.58, 0.45, 0.45))],
                "bmbody", 0.016, 0.6, 6)
    paint(body, bcol); setmat(body, vc("m2fur")); P.append(body)
    tag(P, "body")
    H = rat_head([], (0, -0.82, 0.5), 0.95, BM_TOP, BM_SIDE, BM_CREAM, BM_PINK)
    tag(H, "head"); P += H
    for key in ("fl", "fr", "bl", "br"):
        sx = 1 if key[1] == "l" else -1
        if key[0] == "f":
            L = [limb([(sx * 0.3, -0.55, 0.3), (sx * 0.33, -0.66, 0.05)], 0.11, 0.08, "bmleg")]
            paw = sph((sx * 0.33, -0.74, 0.035), 1, (0.1, 0.13, 0.045))
        else:
            L = [limb([(sx * 0.48, 0.45, 0.28), (sx * 0.5, 0.4, 0.05)], 0.16, 0.09, "bmleg")]
            paw = sph((sx * 0.5, 0.28, 0.035), 1, (0.11, 0.16, 0.045))
        paint(L[0], lambda p, n: mix(BM_PINK, BM_SIDE, smoothstep(0.06, 0.2, p.z))); setmat(L[0], vc("m2fur"))
        setmat(paw, col("m2paw", BM_PINK, 0.6)); L.append(paw)
        tag(L, "leg_" + key); P += L
    tl = tube([(0, 0.95, 0.3), (0.35, 1.25, 0.08), (0.8, 1.05, 0.05), (0.95, 0.55, 0.05), (0.85, 0.2, 0.05)], 0.08, 0.3, 24)
    setmat(tl, col("m2tail", BM_PINK, 0.6)); tag([tl], "tail"); P.append(tl)
    B = []
    baby_rat((0.24, 0.12, 1.2), 20, B); baby_rat((-0.24, 0.38, 1.1), -25, B); baby_rat((0.0, -0.3, 1.16), 0, B)
    tag(B, "babies"); P += B
    return group("brood_mother", P)


def brood_mother_anim():
    fl, bl = Vector((0.3, -0.55, 0.3)), Vector((0.48, 0.45, 0.28))
    fr, br = Vector((-0.3, -0.55, 0.3)), Vector((-0.48, 0.45, 0.28))
    nk = Vector((0, -0.62, 0.55)); tl = Vector((0, 0.95, 0.3)); mid = Vector((0, 0.0, 0.0))
    walk = quad_walk(1.2, tuple(fl), tuple(bl), tuple(nk), tuple(tl), stride=20, bob=0.02)

    def anim(kind, t):
        if kind == "walk":
            d = walk("walk", t)
            roll = rot_about(mid, Y, R(4) * math.sin(TAU * t))   # gingado de bicho pesado
            for k in ("body", "head", "tail"):
                d[k] = roll @ d[k]
            d["babies"] = d["body"] @ tr(0, 0, 0.03 * abs(math.sin(TAU * t * 2)))
            d["tail"] = roll
            return d
        w, h = strike(t, 0.3, 0.46, 0.7)
        # salto: agacha (o achatamento vem do deform), pula para a frente e cai por cima com a boca
        air = math.sin(math.pi * min(1.0, h)) * (1.0 if t < 0.46 else 0.0)
        B = tr(0, 0.1 * w - 0.55 * min(h, 1.0), 0.35 * air) @ rot_about(Vector((0, -0.2, 0.3)), X, R(-8 * w + 14 * h))
        d = {"body": B, "head": B @ rot_about(nk, X, R(-15 * w + 25 * h)), "tail": B,
             "babies": B @ tr(0, 0.05 * h, 0.12 * air + 0.06 * w)}
        for k, pv, s in (("leg_fl", fl, -1), ("leg_fr", fr, -1), ("leg_bl", bl, 1), ("leg_br", br, 1)):
            d[k] = B @ rot_about(pv, X, R(s * (-25 * w + 30 * h)))
        return d

    def deform(p, n, bone, t):
        if t <= 1.0:
            return p, n
        u = t - 1.0
        w, h = strike(u, 0.3, 0.46, 0.7)
        land = 1.0 if 0.46 <= u < 0.7 else 0.0
        sq = 0.16 * w + 0.12 * land * (1.0 - ease((u - 0.46) / 0.24))
        sz = 1.0 - sq; sxy = 1.0 + sq * 0.6
        return Vector((p.x * sxy, p.y, p.z * sz)), n
    return {"anim": anim, "deform": deform}


# =============================================================== Diabrete de Fogo

IMP = (0.88, 0.27, 0.16); IMPD = (0.52, 0.1, 0.08); HORN = (0.16, 0.08, 0.09); IMP_EYE = (1.0, 0.92, 0.45)


def fire_imp():
    P = []
    def skin(p, n):
        return mix(IMPD, IMP, smoothstep(-0.5, 0.7, n.z) * 0.8 + 0.2)
    body = fuse([sph((0, 0.02, 0.6), 1, (0.31, 0.35, 0.31), (25, 0, 0)), sph((0, 0.2, 0.45), 1, (0.25, 0.24, 0.23))], "impbody", 0.012, 0.6, 5)
    paint(body, skin); setmat(body, vc("m2skin", 0.6)); P.append(body)
    F = []
    for (x, y, z, r_, h_, tl_) in ((0, -0.05, 0.82, 0.13, 0.42, -35), (0.1, 0.12, 0.74, 0.11, 0.36, -45), (-0.1, 0.12, 0.74, 0.11, 0.36, -45),
                                   (0, 0.25, 0.62, 0.1, 0.3, -60)):
        F += flame((x, y, z), r_, h_, (tl_, x * 60, 0))
    tag(F, "flame_b"); P += F
    tag([body], "body")
    Hd = []
    head = fuse([sph((0, -0.3, 0.88), 1, (0.29, 0.27, 0.26)), sph((0, -0.44, 0.8), 1, (0.19, 0.13, 0.13))], "imphead", 0.011, 0.6, 5)
    paint(head, lambda p, n: mix(IMPD, IMP, smoothstep(-0.6, 0.6, n.z) * 0.8 + 0.2)); setmat(head, vc("m2skin", 0.6)); Hd.append(head)
    for sx in (-1, 1):
        hn = keep(cone((sx * 0.15, -0.24, 1.06), (sx * 0.3, -0.2, 1.34), 0.08, 0.01)); setmat(hn, col("m2horn", HORN, 0.5)); Hd.append(hn)
        Hd.append(eye((sx * 0.11, -0.55, 0.9), (0.085, 0.025, 0.035), (0, 0, sx * -22), IMP_EYE, emit=4.0))
    FH = []
    for (x, z, h_, tl_) in ((0.0, 1.0, 0.36, -25), (0.09, 0.96, 0.26, -35), (-0.09, 0.96, 0.26, -35)):
        FH += flame((x, -0.24, z), 0.09, h_, (tl_, x * 120, 0))
    tag(FH, "flame_h"); tag(Hd, "head"); P += Hd + FH
    for sx, bone in ((1, "arm_l"), (-1, "arm_r")):
        A = [limb([(sx * 0.22, -0.12, 0.7), (sx * 0.34, -0.34, 0.5), (sx * 0.31, -0.54, 0.28)], 0.095, 0.07, "imparm")]
        paint(A[0], lambda p, n: mix(IMP, IMPD, smoothstep(0.55, 0.3, p.z) * 0.7)); setmat(A[0], vc("m2skin", 0.6))
        hand = sph((sx * 0.31, -0.58, 0.26), 1, (0.1, 0.1, 0.075)); setmat(hand, col("m2skin_d", IMPD, 0.6)); A.append(hand)
        for k in (-1, 0, 1):
            c = keep(cone((sx * 0.31 + k * 0.05, -0.64, 0.25), (sx * 0.31 + k * 0.07, -0.8, 0.12), 0.035, 0.004, 8)); setmat(c, col("m2horn", HORN, 0.5)); A.append(c)
        tag(A, bone); P += A
    for sx, bone in ((1, "leg_l"), (-1, "leg_r")):
        L = [limb([(sx * 0.2, 0.22, 0.45), (sx * 0.3, -0.05, 0.3), (sx * 0.26, 0.12, 0.08), (sx * 0.26, -0.04, 0.03)], 0.13, 0.065, "impleg")]
        paint(L[0], lambda p, n: mix(IMP, IMPD, smoothstep(0.35, 0.05, p.z))); setmat(L[0], vc("m2skin", 0.6))
        for k in (-1, 1):
            c = keep(cone((sx * 0.24 + k * 0.04, -0.07, 0.04), (sx * 0.24 + k * 0.05, -0.18, 0.0), 0.03, 0.004, 8)); setmat(c, col("m2horn", HORN, 0.5)); L.append(c)
        tag(L, bone); P += L
    T = [tube([(0, 0.3, 0.45), (0.05, 0.6, 0.5), (0.0, 0.85, 0.75), (-0.1, 0.95, 1.0)], 0.04, 0.55, 18)]
    setmat(T[0], col("m2skin_m", IMP, 0.6))
    tip = keep(cone((-0.12, 0.97, 1.02), (-0.18, 1.02, 1.2), 0.08, 0.005, 4)); setmat(tip, col("m2skin_d", IMPD, 0.6)); T.append(tip)
    tag(T, "tail"); P += T
    return group("fire_imp", P)


def fire_imp_anim():
    shl, shr = Vector((0.2, -0.12, 0.7)), Vector((-0.2, -0.12, 0.7))
    hl, hr = Vector((0.17, 0.2, 0.45)), Vector((-0.17, 0.2, 0.45))
    nk = Vector((0, -0.2, 0.82)); mid = Vector((0, 0.05, 0.55)); tl = Vector((0, 0.3, 0.45))
    fb = Vector((0, 0.1, 0.72)); fh = Vector((0, -0.24, 0.96))

    def flick(t, ph, k=0.18):
        s = 1.0 + k * math.sin(TAU * t * 2 + ph)
        return s

    def scale_at(pv, s):
        return Matrix.Translation(pv) @ Matrix.Diagonal((1.0 + (s - 1) * 0.4, 1.0 + (s - 1) * 0.4, s, 1.0)) @ Matrix.Translation(-pv)

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t; s = math.sin(ph)
            B = tr(0, 0, 0.05 * math.sin(ph + 0.8)) @ rot_about(mid, X, R(4) * math.cos(ph))
            return {"body": B, "head": B @ rot_about(nk, X, R(5) * math.sin(ph + 1.5)),
                    "arm_l": B @ rot_about(shl, X, R(28) * s), "arm_r": B @ rot_about(shr, X, -R(28) * s),
                    "leg_l": B @ rot_about(hl, X, -R(18) * s), "leg_r": B @ rot_about(hr, X, R(18) * s),
                    "tail": B @ rot_about(tl, Z, R(22) * math.sin(ph + 1.0)),
                    "flame_b": B @ scale_at(fb, flick(t, 0.0)), "flame_h": B @ rot_about(nk, X, R(5) * math.sin(ph + 1.5)) @ scale_at(fh, flick(t, 1.7))}
        w, h = strike(t)
        # arranhão duplo: recua e ergue as garras, mergulha para a frente rasgando para baixo; o fogo incha no golpe
        B = tr(0, 0.12 * w - 0.4 * h, 0.06 * w - 0.08 * h) @ rot_about(mid, X, R(-16 * w + 22 * h))
        arm = R(-120 * w + 30 * h)
        return {"body": B, "head": B @ rot_about(nk, X, R(-12 * w + 12 * h)),
                "arm_l": B @ rot_about(shl, X, arm), "arm_r": B @ rot_about(shr, X, R(-120 * w + 40 * h)),
                "leg_l": B @ rot_about(hl, X, R(20 * w - 10 * h)), "leg_r": B @ rot_about(hr, X, R(20 * w - 10 * h)),
                "tail": B @ rot_about(tl, X, R(-20 * w + 25 * h)),
                "flame_b": B @ scale_at(fb, 1.0 + 0.5 * h), "flame_h": B @ rot_about(nk, X, R(-12 * w + 12 * h)) @ scale_at(fh, 1.0 + 0.55 * h)}
    return {"anim": anim}


# =============================================================== Carniçal

GH = (0.74, 0.78, 0.82); GHD = (0.4, 0.46, 0.56); RAG = (0.52, 0.54, 0.53); RAGD = (0.16, 0.16, 0.19); CLAW = (0.12, 0.1, 0.13)


def ghoul():
    P = []
    skin = lambda p, n: mix(GHD, GH, smoothstep(-0.5, 0.75, n.z) * 0.85 + 0.15)
    torso = fuse([sph((0, -0.2, 1.18), 1, (0.27, 0.2, 0.22), (40, 0, 0)), sph((0, -0.05, 0.98), 1, (0.2, 0.16, 0.2), (20, 0, 0)),
                  sph((0, 0.03, 0.83), 1, (0.21, 0.15, 0.13))], "ghtorso", 0.012, 0.6, 5)
    paint(torso, skin); setmat(torso, vc("m2skin", 0.6)); P.append(torso)
    # trapo dos ombros (capuz rasgado) e tanga em tiras
    cape = fuse([sph((0, -0.14, 1.22), 1, (0.3, 0.22, 0.08), (40, 0, 0))], "ghcape", 0.012, 0.5, 3)
    paint(cape, lambda p, n: mix(RAGD, RAG, smoothstep(0.95, 1.3, p.z))); setmat(cape, vc("m2rag", 0.85)); P.append(cape)
    for k in range(7):
        a = -1.2 + k * 0.4
        x = math.sin(a) * 0.27; y = -0.12 + math.cos(a) * 0.12 + 0.08
        s = keep(box((x, y, 1.02 - 0.04 * (k % 2)), (0.11, 0.04, 0.3 + 0.08 * (k % 3)), (25, 0, -a * 30), bevel=0.01, taper=(0.35, 1.0)))
        s.rotation_euler[0] += math.radians(180); hard(s)
        paint(s, lambda p, n: mix(RAGD, RAG, smoothstep(0.85, 1.15, p.z))); setmat(s, vc("m2rag", 0.85)); P.append(s)
    belt = torus((0, 0.02, 0.9), 0.2, 0.035, (10, 0, 0), (1.0, 0.8, 1.0)); setmat(belt, col("m2belt", (0.24, 0.18, 0.15), 0.7)); P.append(belt)
    for k in range(8):
        a = -1.6 + k * 0.45
        x = math.sin(a) * 0.19; y = 0.02 - math.cos(a) * 0.14
        s = keep(box((x, y, 0.72 - 0.05 * (k % 2)), (0.12, 0.04, 0.32 + 0.1 * ((k * 5) % 3)), (8 if y < 0 else -8, 0, -a * 57), bevel=0.01, taper=(0.3, 1.0)))
        s.rotation_euler[0] += math.radians(180); hard(s)
        paint(s, lambda p, n: mix(RAGD, RAG, smoothstep(0.45, 0.8, p.z))); setmat(s, vc("m2rag", 0.85)); P.append(s)
    tag(P, "body")
    Hd = []
    head = fuse([sph((0, -0.44, 1.38), 1, (0.14, 0.17, 0.17), (15, 0, 0)), sph((0, -0.53, 1.27), 1, (0.1, 0.1, 0.07))], "ghhead", 0.01, 0.6, 5)
    paint(head, skin); setmat(head, vc("m2skin", 0.6)); Hd.append(head)
    for sx in (-1, 1):
        er = keep(cone((sx * 0.12, -0.4, 1.42), (sx * 0.27, -0.33, 1.5), 0.05, 0.008, 10)); er.scale = (1, 1, 1); setmat(er, col("m2skin_e", GH, 0.6)); Hd.append(er)
        Hd.append(eye((sx * 0.065, -0.6, 1.41), (0.045, 0.02, 0.02), (0, 0, sx * -18), (0.08, 0.07, 0.1)))
    tag(Hd, "head"); P += Hd
    J = [sph((0, -0.56, 1.22), 1, (0.085, 0.09, 0.045))]
    paint(J[0], skin); setmat(J[0], vc("m2skin", 0.6)); tag(J, "jaw"); P += J
    for sx, bone in ((1, "arm_l"), (-1, "arm_r")):
        A = [limb([(sx * 0.25, -0.28, 1.26), (sx * 0.33, -0.42, 0.9), (sx * 0.3, -0.56, 0.6)], 0.065, 0.045, "gharm")]
        paint(A[0], skin); setmat(A[0], vc("m2skin", 0.6))
        hand = sph((sx * 0.3, -0.6, 0.53), 1, (0.075, 0.06, 0.09)); paint(hand, skin); setmat(hand, vc("m2skin", 0.6)); A.append(hand)
        for k in (-1.5, -0.5, 0.5, 1.5):
            c = keep(cone((sx * 0.3 + k * 0.035, -0.64, 0.5), (sx * 0.3 + k * 0.05, -0.72, 0.3), 0.022, 0.003, 8)); setmat(c, col("m2claw", CLAW, 0.4)); A.append(c)
        tag(A, bone); P += A
    for sx, bone in ((1, "leg_l"), (-1, "leg_r")):
        L = [limb([(sx * 0.12, 0.04, 0.82), (sx * 0.16, -0.16, 0.45), (sx * 0.13, 0.05, 0.08)], 0.075, 0.055, "ghleg")]
        paint(L[0], skin); setmat(L[0], vc("m2skin", 0.6))
        ft = box((sx * 0.13, -0.04, 0.035), (0.11, 0.26, 0.07), bevel=0.03); hard(ft); paint(ft, skin); setmat(ft, vc("m2skin", 0.6)); L.append(ft)
        tag(L, bone); P += L
    return group("ghoul", P)


def ghoul_anim():
    sl, sr = Vector((0.25, -0.28, 1.26)), Vector((-0.25, -0.28, 1.26))
    hl, hr = Vector((0.12, 0.04, 0.82)), Vector((-0.12, 0.04, 0.82))
    nk = Vector((0, -0.34, 1.32)); hip = Vector((0, 0.03, 0.82)); jw = Vector((0, -0.47, 1.27))

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t; s = math.sin(ph)
            B = tr(0, 0, abs(math.cos(ph)) * 0.04) @ rot_about(hip, Y, R(4) * s)
            H = B @ rot_about(nk, X, R(5) * math.sin(2 * ph))
            return {"body": B, "head": H, "jaw": H,
                    "leg_l": rot_about(hl, X, -R(30) * s), "leg_r": rot_about(hr, X, R(30) * s),
                    "arm_l": B @ rot_about(sl, X, R(20) * s), "arm_r": B @ rot_about(sr, X, -R(20) * s)}
        w, h = strike(t)
        # ergue o tronco e as garras, cai para a frente rasgando com as duas e morde
        B = tr(0, 0.1 * w - 0.38 * h, 0.04 * w - 0.05 * h) @ rot_about(hip, X, R(-22 * w + 22 * h))
        H = B @ rot_about(nk, X, R(-20 * w + 18 * h))
        return {"body": B, "head": H, "jaw": H @ rot_about(jw, X, R(28 * w + 10 * max(0.0, 1.0 - h) * w)),
                "leg_l": rot_about(hl, X, R(10 * w - 25 * h)), "leg_r": rot_about(hr, X, R(-8 * w + 15 * h)),
                "arm_l": B @ rot_about(sl, X, R(-150 * w + 20 * h)), "arm_r": B @ rot_about(sr, X, R(-140 * w + 30 * h))}
    return {"anim": anim}


# =============================================================== Kobolds Saqueadores

KB = (0.86, 0.3, 0.26); KBD = (0.55, 0.14, 0.14); KCREAM = (0.95, 0.9, 0.8); LEATHER = (0.5, 0.4, 0.3); LEATHERD = (0.28, 0.2, 0.15)
GOLD = (1.0, 0.78, 0.2)


def kobold_scavengers():
    P = []
    scale = lambda p, n: mix(KBD, KB, smoothstep(-0.5, 0.7, n.z) * 0.8 + 0.2)
    torso = fuse([sph((0, 0.0, 0.5), 1, (0.17, 0.15, 0.21)), sph((0, -0.04, 0.66), 1, (0.14, 0.12, 0.1))], "kbtorso", 0.01, 0.6, 5)
    paint(torso, lambda p, n: mix(scale(p, n), KCREAM, smoothstep(-0.2, -0.75, n.y) * 0.9)); setmat(torso, vc("m2skin", 0.6)); P.append(torso)
    apron = fuse([cyl((0, -0.02, 0.43), 0.19, 0.36, seg=20, bevel=0.0, r2=0.17)], "kbapron", 0.01, 0.4, 2)
    apron.scale = (1.0, 0.9, 1.0)
    paint(apron, lambda p, n: mix(LEATHERD, LEATHER, smoothstep(0.25, 0.6, p.z) * 0.6 + 0.3)); setmat(apron, vc("m2leather", 0.85)); P.append(apron)
    strap = torus((0, -0.01, 0.56), 0.165, 0.025, (0, 35, 0), (1.0, 0.95, 1.4)); setmat(strap, col("m2strap", LEATHERD, 0.7)); P.append(strap)
    T = [tube([(0, 0.12, 0.38), (0, 0.4, 0.2), (0.05, 0.62, 0.07), (0.12, 0.78, 0.05)], 0.1, 0.12, 18)]
    paint(T[0], lambda p, n: mix(KBD, KB, smoothstep(-0.4, 0.8, n.z))); setmat(T[0], vc("m2skin", 0.6))
    tag(T, "tail"); P += T
    tag([torso, apron, strap], "body")
    Hd = []
    head = fuse([sph((0, -0.06, 0.87), 1, (0.155, 0.16, 0.14)), sph((0, -0.22, 0.84), 1, (0.09, 0.13, 0.07), (-6, 0, 0))], "kbhead", 0.009, 0.6, 5)
    paint(head, lambda p, n: mix(scale(p, n), KCREAM, smoothstep(-0.1, -0.7, n.z) * 0.9 * smoothstep(0.84, 0.76, p.z))); setmat(head, vc("m2skin", 0.6)); Hd.append(head)
    for k, (y, z, ln) in enumerate(((-0.02, 0.98, 0.17), (0.07, 0.96, 0.17), (0.14, 0.9, 0.14), (0.18, 0.8, 0.12))):
        sp = keep(cone((0, y, z - 0.03), (0, y + ln * 0.75, z + ln * 0.75), 0.045, 0.005, 8)); setmat(sp, col("m2spike", KBD, 0.6)); Hd.append(sp)
    for sx in (-1, 1):
        sp = keep(cone((sx * 0.09, 0.02, 0.9), (sx * 0.2, 0.14, 0.98), 0.04, 0.005, 8)); setmat(sp, col("m2spike", KBD, 0.6)); Hd.append(sp)
        Hd.append(eye((sx * 0.085, -0.15, 0.93), (0.045, 0.02, 0.02), (0, 0, sx * -15), (0.1, 0.07, 0.07)))
    tag(Hd, "head"); P += Hd
    for sx, bone in ((1, "arm_l"), (-1, "arm_r")):
        hand = (sx * 0.05, -0.2, 0.58) if sx > 0 else (-0.07, -0.19, 0.55)
        A = [limb([(sx * 0.15, -0.04, 0.65), (sx * 0.17, -0.12, 0.52), hand], 0.05, 0.04, "kbarm")]
        paint(A[0], scale); setmat(A[0], vc("m2skin", 0.6))
        hd = sph(hand, 1, (0.05, 0.05, 0.05)); setmat(hd, col("m2skin_d", KBD, 0.6)); A.append(hd)
        if sx > 0:
            coin = keep(cyl((0.02, -0.25, 0.6), 0.075, 0.025, (90, 0, 0), seg=20, bevel=0.005)); setmat(coin, mat("m2gold", GOLD, 0.3, metal=0.6, emit=0.6)); A.append(coin)
        else:
            for k in (-1, 0, 1):
                c = keep(cone((-0.07 + k * 0.025, -0.23, 0.55), (-0.07 + k * 0.03, -0.31, 0.55), 0.018, 0.003, 6)); setmat(c, col("m2claw", (0.95, 0.88, 0.7), 0.4)); A.append(c)
        tag(A, bone); P += A
    for sx, bone in ((1, "leg_l"), (-1, "leg_r")):
        L = [limb([(sx * 0.1, 0.02, 0.36), (sx * 0.13, -0.08, 0.2), (sx * 0.11, 0.05, 0.07)], 0.08, 0.04, "kbleg")]
        paint(L[0], scale); setmat(L[0], vc("m2skin", 0.6))
        ft = box((sx * 0.11, -0.03, 0.025), (0.09, 0.17, 0.05), bevel=0.02); hard(ft); setmat(ft, col("m2skin_d", KBD, 0.6)); L.append(ft)
        tag(L, bone); P += L
    return group("kobold_scavengers", P)


def kobold_anim():
    sl, sr = Vector((0.15, -0.04, 0.65)), Vector((-0.15, -0.04, 0.65))
    hl, hr = Vector((0.1, 0.02, 0.36)), Vector((-0.1, 0.02, 0.36))
    nk = Vector((0, -0.02, 0.76)); hip = Vector((0, 0.0, 0.36)); tl = Vector((0, 0.12, 0.38))

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t; s = math.sin(ph)
            B = tr(0, 0, abs(math.cos(ph)) * 0.04) @ rot_about(hip, Y, R(5) * s)
            return {"body": B, "head": B @ rot_about(nk, X, R(5) * math.sin(2 * ph)), "tail": B @ rot_about(tl, Z, R(18) * math.sin(ph + 1.0)),
                    "leg_l": rot_about(hl, X, -R(34) * s), "leg_r": rot_about(hr, X, R(34) * s),
                    "arm_l": B @ rot_about(sl, X, R(6) * s), "arm_r": B @ rot_about(sr, X, -R(14) * s)}
        w, h = strike(t, 0.24, 0.36, 0.64)
        # cutucão: puxa a garra para trás girando o corpo e estoca para a frente com o corpo todo
        B = tr(0, 0.06 * w - 0.22 * h, 0) @ rot_about(hip, Z, R(-18 * w + 10 * h)) @ rot_about(hip, X, R(-6 * w + 14 * h))
        return {"body": B, "head": B @ rot_about(nk, X, R(-10 * w + 12 * h)), "tail": B @ rot_about(tl, X, R(-20 * w + 15 * h)),
                "leg_l": rot_about(hl, X, R(-10 * w - 25 * h)), "leg_r": rot_about(hr, X, R(10 * w + 20 * h)),
                "arm_l": B @ rot_about(sl, X, R(10 * w)), "arm_r": B @ rot_about(sr, X, R(55 * w - 75 * h))}
    return {"anim": anim}


# =============================================================== Servo Erguido

BONE = (0.9, 0.82, 0.64); BONED = (0.55, 0.45, 0.34); SOCK = (0.14, 0.09, 0.08); SOUL = (0.45, 1.0, 0.62)


def raised_servant():
    P = []
    bone = lambda p, n: mix(BONED, BONE, smoothstep(-0.5, 0.7, n.z) * 0.8 + 0.2)
    def bm(o):
        paint(o, bone); setmat(o, vc("m2bone", 0.6)); return o
    spine = tube([(0, 0.08, 0.86), (0, 0.06, 1.05), (0, -0.04, 1.22), (0, -0.14, 1.36)], 0.05, 0.8, 12); bm(spine); P.append(spine)
    pel = fuse([sph((0, 0.05, 0.84), 1, (0.2, 0.12, 0.1))], "pelvis", 0.01, 0.6, 3); bm(pel); P.append(pel)
    for k, (z, rr) in enumerate(((1.28, 0.2), (1.18, 0.21), (1.08, 0.19), (0.99, 0.15))):
        rb = torus((0, -0.1 + k * 0.03, z), rr, 0.032, (90 - 25, 0, 0), (1.0, 0.7, 1.0)); bm(rb); P.append(rb)
    st = box((0, -0.24, 1.15), (0.06, 0.04, 0.3), (25, 0, 0), bevel=0.015); hard(st); bm(st); P.append(st)
    soul = sph((0, -0.1, 1.15), 1, (0.12, 0.09, 0.12)); setmat(soul, mat("m2soul", SOUL, 0.4, emit=5.0)); P.append(soul)
    for sx in (-1, 1):
        sh = sph((sx * 0.23, -0.12, 1.33), 1, (0.075, 0.075, 0.065)); bm(sh); P.append(sh)
    tag(P, "body")
    Hd = []
    sk = fuse([sph((0, -0.3, 1.52), 1, (0.2, 0.21, 0.2)), sph((0, -0.4, 1.4), 1, (0.13, 0.11, 0.1))], "skull", 0.01, 0.6, 5); bm(sk); Hd.append(sk)
    for sx in (-1, 1):
        Hd.append(eye((sx * 0.085, -0.47, 1.5), (0.065, 0.03, 0.06), (0, 0, sx * 10), SOCK))
    nose = keep(sph((0, -0.52, 1.42), 1, (0.03, 0.02, 0.035))); setmat(nose, col("m2sock", SOCK, 0.6)); Hd.append(nose)
    tag(Hd, "head"); P += Hd
    J = [box((0, -0.44, 1.32), (0.17, 0.12, 0.06), bevel=0.02)]; hard(J[0]); bm(J[0]); tag(J, "jaw"); P += J
    # braço direito (-x) estendido com a garra aberta (como na carta), o esquerdo pendurado
    for sx, bone_, pts, hand in ((-1, "arm_r", [(-0.23, -0.12, 1.33), (-0.36, -0.36, 1.2), (-0.38, -0.62, 1.12)], (-0.38, -0.68, 1.12)),
                                 (1, "arm_l", [(0.23, -0.12, 1.33), (0.32, -0.2, 1.02), (0.33, -0.3, 0.72)], (0.33, -0.33, 0.68))):
        A = [limb(pts, 0.04, 0.032, "sarm")]; bm(A[0])
        for p_ in pts[1:2]:
            kn = sph(p_, 1, (0.055, 0.055, 0.055)); bm(kn); A.append(kn)
        pa = sph(hand, 1, (0.065, 0.05, 0.06)); bm(pa); A.append(pa)
        for k in (-1.5, -0.5, 0.5, 1.5):
            if sx < 0:
                f = keep(limb([(hand[0] + k * 0.035, hand[1] - 0.03, hand[2]), (hand[0] + k * 0.055, hand[1] - 0.15, hand[2] + 0.04), (hand[0] + k * 0.06, hand[1] - 0.22, hand[2] - 0.02)], 0.022, 0.014, "keep", 0.008))
            else:
                f = keep(limb([(hand[0] + k * 0.03, hand[1], hand[2] - 0.03), (hand[0] + k * 0.04, hand[1] - 0.03, hand[2] - 0.15), (hand[0] + k * 0.04, hand[1] - 0.06, hand[2] - 0.22)], 0.02, 0.013, "keep", 0.008))
            bm(f); A.append(f)
        tag(A, bone_); P += A
    for sx, bone_ in ((1, "leg_l"), (-1, "leg_r")):
        pts = [(sx * 0.12, 0.05, 0.82), (sx * 0.15, -0.12, 0.45), (sx * 0.13, 0.04, 0.09)]
        L = [limb(pts, 0.048, 0.038, "sleg")]; bm(L[0])
        kn = sph(pts[1], 1, (0.06, 0.06, 0.06)); bm(kn); L.append(kn)
        ft = box((sx * 0.13, -0.05, 0.04), (0.1, 0.22, 0.07), bevel=0.025); hard(ft); bm(ft); L.append(ft)
        tag(L, bone_); P += L
    return group("raised_servant", P)


def raised_servant_anim():
    sl, sr = Vector((0.23, -0.12, 1.33)), Vector((-0.23, -0.12, 1.33))
    hl, hr = Vector((0.12, 0.05, 0.82)), Vector((-0.12, 0.05, 0.82))
    nk = Vector((0, -0.18, 1.4)); hip = Vector((0, 0.05, 0.84)); jw = Vector((0, -0.36, 1.36))

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t; s = math.sin(ph)
            B = tr(0, 0, abs(math.cos(ph)) * 0.04) @ rot_about(hip, Y, R(4) * s) @ rot_about(hip, Z, R(5) * s)
            H = B @ rot_about(nk, Z, R(6) * math.sin(ph + 0.5))
            return {"body": B, "head": H, "jaw": H @ rot_about(jw, X, R(6) * abs(math.sin(2 * ph))),
                    "leg_l": rot_about(hl, X, -R(28) * s), "leg_r": rot_about(hr, X, R(28) * s),
                    "arm_l": B @ rot_about(sl, X, R(18) * s), "arm_r": B @ rot_about(sr, X, -R(10) * s)}
        w, h = strike(t)
        # golpe de garra: torce o tronco, ergue a garra por cima e desce na diagonal avançando; a mandíbula abre
        B = tr(0, 0.08 * w - 0.32 * h, 0) @ rot_about(hip, Z, R(20 * w - 16 * h)) @ rot_about(hip, X, R(-12 * w + 18 * h))
        H = B @ rot_about(nk, X, R(-12 * w + 10 * h))
        return {"body": B, "head": H, "jaw": H @ rot_about(jw, X, R(25 * w + 12 * h)),
                "leg_l": rot_about(hl, X, R(-22 * h)), "leg_r": rot_about(hr, X, R(10 * w + 18 * h)),
                "arm_l": B @ rot_about(sl, X, R(-30 * w + 10 * h)), "arm_r": B @ rot_about(sr, X, R(-110 * w + 55 * h))}
    return {"anim": anim}


# =============================================================== Flautista Corrompido

COAT = (0.38, 0.52, 0.4); COATD = (0.2, 0.3, 0.24); STAIN = (0.46, 0.36, 0.26); HAT = (0.32, 0.29, 0.28); HATD = (0.18, 0.16, 0.16)
FACE = (0.86, 0.74, 0.64); HAIR = (0.14, 0.11, 0.11); BOOT = (0.28, 0.2, 0.15); WOOD = (0.48, 0.32, 0.2); NOTE = (0.55, 1.0, 0.45)
PRAT = (0.5, 0.55, 0.66); PRATD = (0.28, 0.3, 0.4); PPINK = (0.93, 0.58, 0.6)


def sit_rat(c, yaw, P):
    """Rato sentado de pé (como os da carta), olhando para o flautista."""
    x, y, z = c
    a = R(yaw)
    def at(dx, dy, dz):
        return (x + dx * math.cos(a) - dy * math.sin(a), y + dx * math.sin(a) + dy * math.cos(a), z + dz)
    b = fuse([sph(at(0, 0, 0.13), 1, (0.11, 0.1, 0.14)), sph(at(0, -0.03, 0.29), 1, (0.075, 0.08, 0.08)), sph(at(0, -0.1, 0.27), 1, (0.04, 0.07, 0.04))], "prat", 0.009, 0.6, 4)
    paint(b, lambda p, n: mix(PRATD, PRAT, smoothstep(-0.3, 0.8, n.z))); setmat(b, vc("m2fur")); P.append(b)
    for sx in (-1, 1):
        e = keep(sph(at(sx * 0.06, 0.0, 0.37), 1, (0.05, 0.02, 0.055))); setmat(e, col("m2ear", PPINK, 0.6)); P.append(e)
        P.append(eye(at(sx * 0.04, -0.1, 0.31), (0.018, 0.012, 0.02), (0, 0, 0), (0.1, 0.085, 0.11)))
    t = tube([at(0, 0.08, 0.02), at(0.1, 0.22, 0.01), at(0.25, 0.25, 0.01)], 0.022, 0.5, 8); t.name = "keep"; setmat(t, col("m2tail", PPINK, 0.6)); P.append(t)


def corrupt_piper():
    P = []
    def coat(p, n):
        c = mix(COATD, COAT, smoothstep(-0.5, 0.7, n.z) * 0.5 + smoothstep(-0.6, 0.4, -n.y) * 0.3 + 0.2)
        c = mix(c, STAIN, smoothstep(0.75, 0.2, p.z) * 0.75 * (0.6 + 0.4 * math.sin(p.x * 9 + p.y * 5)))
        return c
    body = fuse([sph((0, 0.0, 1.28), 1, (0.23, 0.16, 0.26)), cyl((0, 0.02, 0.66), 0.31, 1.0, seg=24, bevel=0.0, r2=0.19)], "pcoat", 0.013, 0.5, 4)
    paint(body, coat); setmat(body, vc("m2coat", 0.85)); P.append(body)
    collar = cyl((0, 0.02, 1.47), 0.13, 0.12, seg=18, bevel=0.0, r2=0.15); setmat(collar, col("m2coatd", COATD, 0.85)); P.append(collar)
    tag(P, "body")
    Hd = []
    face = sph((0, -0.03, 1.6), 1, (0.1, 0.11, 0.12)); setmat(face, col("m2face", FACE, 0.7)); Hd.append(face)
    hair = fuse([sph((0, 0.04, 1.6), 1, (0.13, 0.1, 0.13)), sph((0, 0.06, 1.5), 1, (0.13, 0.08, 0.08))], "phair", 0.01, 0.6, 3)
    setmat(hair, col("m2hair", HAIR, 0.8)); Hd.append(hair)
    brim = cyl((0, 0.0, 1.71), 0.36, 0.03, (6, 0, 0), seg=28, bevel=0.012); brim.scale = (1.0, 0.92, 1.0); setmat(brim, col("m2hat", HAT, 0.8)); Hd.append(brim)
    crown = tube([(0, 0.01, 1.7), (0, 0.03, 1.9), (0.03, 0.1, 2.05), (0.09, 0.2, 2.1)], 0.15, 0.08, 16)
    paint(crown, lambda p, n: mix(HATD, HAT, smoothstep(-0.3, 0.8, n.z))); setmat(crown, vc("m2hat", 0.8)); Hd.append(crown)
    tag(Hd, "head"); P += Hd
    # braços dobrados segurando a flauta, que desce da boca para a direita dele (-x)
    F = []
    for sx, pts in ((1, [(0.21, 0.0, 1.38), (0.26, -0.18, 1.18), (0.07, -0.28, 1.38)]), (-1, [(-0.21, 0.0, 1.38), (-0.32, -0.2, 1.12), (-0.24, -0.42, 1.22)])):
        a = limb(pts, 0.075, 0.06, "psleeve"); paint(a, coat); setmat(a, vc("m2coat", 0.85)); F.append(a)
        hd = sph((pts[-1][0], pts[-1][1] - 0.02, pts[-1][2]), 1, (0.05, 0.05, 0.055)); setmat(hd, col("m2face", FACE, 0.7)); F.append(hd)
    fl = tube([(0.02, -0.16, 1.52), (-0.13, -0.33, 1.32), (-0.3, -0.52, 1.14)], 0.032, 0.85, 10); setmat(fl, col("m2wood", WOOD, 0.6)); F.append(fl)
    tag(F, "arms"); P += F
    N = [torus((-0.36, -0.6, 1.08), 0.14, 0.035, (55, 0, -45))]; setmat(N[0], mat("m2note", NOTE, 0.4, emit=5.0)); tag(N, "note"); P += N
    for sx, bone in ((1, "leg_l"), (-1, "leg_r")):
        L = [limb([(sx * 0.1, 0.02, 0.3), (sx * 0.1, 0.0, 0.08)], 0.08, 0.075, "pboot")]
        ft = box((sx * 0.1, -0.06, 0.04), (0.12, 0.22, 0.08), bevel=0.03); hard(ft); L.append(ft)
        for o in L:
            setmat(o, col("m2boot", BOOT, 0.7))
        tag(L, bone); P += L
    RT = []
    sit_rat((0.42, -0.2, 0.0), -35, RT); sit_rat((-0.4, -0.3, 0.0), 30, RT)
    tag(RT, "rats"); P += RT
    return group("corrupt_piper", P)


def corrupt_piper_anim():
    hl, hr = Vector((0.1, 0.02, 0.3)), Vector((-0.1, 0.02, 0.3))
    hip = Vector((0, 0.0, 0.25)); sh = Vector((0, 0.0, 1.38)); nk = Vector((0, 0.0, 1.5))
    ring = Vector((-0.36, -0.6, 1.08)); flute_end = Vector((-0.3, -0.52, 1.14))

    def ring_m(s, fwd):
        return tr(0, -fwd, 0) @ Matrix.Translation(ring) @ Matrix.Scale(max(s, 0.02), 4) @ Matrix.Translation(-ring)

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t; s = math.sin(ph)
            B = tr(0, 0, abs(math.cos(ph)) * 0.025) @ rot_about(hip, Y, R(3) * s)
            A = B @ rot_about(sh, X, R(4) * math.sin(2 * ph))   # a flauta sobe e desce com a música
            return {"body": B, "head": B @ rot_about(nk, Y, R(4) * s), "arms": A,
                    "note": A @ ring_m(0.02, 0.0),
                    "leg_l": rot_about(hl, X, -R(22) * s), "leg_r": rot_about(hr, X, R(22) * s),
                    "rats": tr(0, 0, 0.06 * abs(math.sin(ph * 2)))}
        w, h = strike(t, 0.28, 0.42, 0.72)
        # toma fôlego inclinado para trás com a flauta erguida, sopra inclinando para a frente: o anel de som sai
        B = tr(0, 0.05 * w - 0.12 * h, 0) @ rot_about(hip, X, R(-12 * w + 14 * h))
        A = B @ rot_about(sh, X, R(-22 * w + 12 * h))
        ring_s = 0.02 + 1.4 * min(h, 1.1) if t >= 0.28 else 0.02
        return {"body": B, "head": B @ rot_about(nk, X, R(-12 * w + 10 * h)), "arms": A,
                "note": A @ ring_m(ring_s, 0.7 * h),
                "leg_l": rot_about(hl, X, R(-12 * h)), "leg_r": rot_about(hr, X, R(8 * w)),
                "rats": tr(0, -0.05 * h, 0.22 * h)}
    return {"anim": anim}


# =============================================================== Nuvem de Morcegos (um morcego por unidade)

BAT = (0.12, 0.1, 0.14); BATL = (0.26, 0.22, 0.3); MEMB = (0.45, 0.33, 0.4); MEMBD = (0.25, 0.17, 0.24); BEAR = (0.92, 0.62, 0.62)


def bat_cloud():
    P = []
    body = fuse([sph((0, 0.0, 0.55), 1, (0.22, 0.2, 0.24)), sph((0, -0.08, 0.76), 1, (0.17, 0.16, 0.15))], "batbody", 0.01, 0.6, 5)
    paint(body, lambda p, n: mix(BAT, BATL, smoothstep(0.2, 0.9, n.z) * 0.6)); setmat(body, vc("m2fur")); P.append(body)
    for sx in (-1, 1):
        ear = keep(cone((sx * 0.09, -0.06, 0.86), (sx * 0.17, -0.04, 1.08), 0.08, 0.01, 12)); ear.scale = (1.0, 0.5, 1.0)
        setmat(ear, col("m2ear", BEAR, 0.6)); P.append(ear)
        P.append(eye((sx * 0.07, -0.22, 0.79), (0.045, 0.02, 0.018), (0, 0, sx * -15), (0.95, 0.94, 0.88), emit=0.5))
    for sx in (-1, 1):
        lg = keep(limb([(sx * 0.08, 0.02, 0.36), (sx * 0.09, -0.02, 0.22)], 0.035, 0.03, "keep"))
        setmat(lg, col("m2fur_d", BAT, 0.8)); P.append(lg)
    tag(P, "body")
    for sx, bone in ((1, "wing_l"), (-1, "wing_r")):
        outline = [(0.14, 0.02), (0.5, -0.12), (0.85, -0.18), (1.25, -0.02), (1.05, 0.12), (0.88, 0.1), (0.72, 0.24), (0.55, 0.18), (0.38, 0.28), (0.18, 0.16)]
        pts = [(sx * x, y) for x, y in outline]
        if sx < 0:
            pts = pts[::-1]
        zf = lambda x, y: 0.62 + 0.38 * math.sin(min(abs(x), 1.2) / 1.2 * math.pi * 0.6) - 0.15 * max(0.0, abs(x) - 0.9)
        w = flat_shape(pts, zf, 0.03, "wing")
        paint(w, lambda p, n: mix(MEMB, MEMBD, smoothstep(0.7, 1.25, abs(p.x)) * 0.6)); setmat(w, vc("m2memb", 0.6))
        arm = tube([(sx * 0.14, 0.0, zf(0.14, 0)), (sx * 0.5, -0.12, zf(0.5, 0) + 0.02), (sx * 0.85, -0.18, zf(0.85, 0) + 0.02), (sx * 1.25, -0.02, zf(1.2, 0))], 0.035, 0.5, 14)
        setmat(arm, col("m2fur_d", BAT, 0.8))
        tuft = sph((sx * 1.3, 0.02, zf(1.2, 0) - 0.02), 1, (0.11, 0.07, 0.07)); setmat(tuft, col("m2fur_d", BAT, 0.8))
        tag([w, arm, tuft], bone); P += [w, arm, tuft]
    return group("bat_cloud", P)


def bat_cloud_anim():
    shl, shr = Vector((0.14, 0.0, 0.62)), Vector((-0.14, 0.0, 0.62)); mid = Vector((0, 0, 0.6))

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t; f = math.sin(ph)
            B = tr(0, 0, 0.07 * math.sin(ph + 1.3))
            return {"body": B, "wing_l": B @ rot_about(shl, Y, -R(48) * f), "wing_r": B @ rot_about(shr, Y, R(48) * f)}
        w, h = strike(t, 0.28, 0.42, 0.66)
        # mergulho: sobe recuando com as asas erguidas, desce de cabeça com as asas fechadas para trás
        B = tr(0, 0.15 * w - 0.6 * h, 0.25 * w - 0.4 * h) @ rot_about(mid, X, R(-15 * w + 40 * h))
        up = R(-60 * w)
        fold = R(55 * h)
        return {"body": B,
                "wing_l": B @ rot_about(shl, Z, fold) @ rot_about(shl, Y, up + R(25) * h),
                "wing_r": B @ rot_about(shr, Z, -fold) @ rot_about(shr, Y, -up - R(25) * h)}
    return {"anim": anim}


# =============================================================== tabela

ANIM = {"rat_brute": rat_brute_anim, "brood_mother": brood_mother_anim, "fire_imp": fire_imp_anim, "ghoul": ghoul_anim,
        "kobold_scavengers": kobold_anim, "raised_servant": raised_servant_anim, "corrupt_piper": corrupt_piper_anim,
        "bat_cloud": bat_cloud_anim}
BUILD = {"rat_brute": rat_brute, "brood_mother": brood_mother, "fire_imp": fire_imp, "ghoul": ghoul,
         "kobold_scavengers": kobold_scavengers, "raised_servant": raised_servant, "corrupt_piper": corrupt_piper,
         "bat_cloud": bat_cloud}
HUMAN = {"corrupt_piper"}
