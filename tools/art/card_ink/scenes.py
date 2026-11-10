"""Cenas das cartas para o render de nanquim. Cada função monta a cena (Z para cima, frente = -Y) e devolve
(tipo da carta, direção da câmera, parâmetros extras). Reaproveita o kit de tools/art/blender_v2."""
import math
import bpy
from mathutils import Matrix, Vector
from mk import *
import chars, monsters, monsters2

DIRT = (0.42, 0.30, 0.20)
DIRT_D = (0.24, 0.16, 0.11)
STONE = (0.55, 0.54, 0.52)
BONE = (0.93, 0.89, 0.76)
FLAME = (1.0, 0.55, 0.12)
FLAME_HOT = (1.0, 0.9, 0.45)


def place(root, loc=(0, 0, 0), rot_z=0.0, scale=1.0, rot_x=0.0):
    root.location = loc; root.rotation_euler = (math.radians(rot_x), 0, math.radians(rot_z)); root.scale = (scale,) * 3
    return root


def flame(base, h=0.5, r=0.16, lean=(0.0, 0.0)):
    """Chama desenhada: línguas de fogo separadas (cada uma ganha contorno) e um miolo claro."""
    x, y, z = base
    out = []
    fm = mat("flame", FLAME, 0.4, emit=6.0)
    b = sph((x, y, z + r * 0.75), 1, (r, r * 0.8, r * 1.05)); shade(b); setmat(b, fm); out.append(b)
    # (deslocamento lateral, altura relativa, grossura relativa, curva)
    for (dx, hh, rr, bend) in ((0.0, 1.0, 0.78, 0.3), (-0.62, 0.62, 0.5, -0.55), (0.66, 0.7, 0.52, 0.6), (-0.3, 0.8, 0.45, 0.15), (0.34, 0.48, 0.4, -0.3)):
        top = z + h * hh
        t = tube([(x + dx * r, y, z + r * 0.5), (x + dx * r * 1.25 + lean[0] * 0.25, y, z + (top - z) * 0.4),
                  (x + dx * r * 0.7 + bend * r + lean[0] * 0.7, y + lean[1] * 0.5, z + (top - z) * 0.75),
                  (x + dx * r * 0.2 + bend * r * 1.7 + lean[0], y + lean[1], top)], r * rr, 0.04, 20)
        shade(t); setmat(t, fm); out.append(t)
    cm = mat("flame_core", FLAME_HOT, 0.4, emit=9.0)
    c = sph((x, y - r * 0.55, z + r * 0.8), 1, (r * 0.55, r * 0.45, r * 0.75)); shade(c); setmat(c, cm); out.append(c)
    t = tube([(x, y - r * 0.55, z + r * 0.7), (x + lean[0] * 0.3, y - r * 0.55, z + h * 0.3), (x + lean[0] * 0.6 + r * 0.15, y - r * 0.5, z + h * 0.52)], r * 0.36, 0.05, 16)
    shade(t); setmat(t, cm); out.append(t)
    return out


# ------------------------------------------------------------------ Toca de Ratos

def rat_burrow():
    P = []

    def soil(p, n):
        return mix(DIRT_D, DIRT, smoothstep(-0.2, 0.9, n.z) * 0.7 + smoothstep(0.0, 1.0, p.z) * 0.3)
    mound = fuse([sph((0, 0.25, 0.35), 1, (1.25, 1.05, 0.72)), sph((-0.75, 0.1, 0.2), 1, (0.6, 0.6, 0.38)),
                  sph((0.8, 0.3, 0.22), 1, (0.62, 0.6, 0.42)), sph((0.2, 0.8, 0.25), 1, (0.7, 0.5, 0.4)),
                  sph((-0.3, -0.55, 0.08), 1, (0.55, 0.35, 0.14)), sph((0.45, -0.6, 0.07), 1, (0.45, 0.3, 0.12))],
                 "mound", 0.03, smooth=0.6, iters=6)
    cut = sph((0, -0.72, 0.36), 1, (0.44, 0.6, 0.4))
    m = mound.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; apply_mods(mound); bpy.data.objects.remove(cut)
    shade(mound); paint(mound, soil); setmat(mound, mat("soil", vcol=True, rough=0.95, bump=0.5, bump_scale=18)); P.append(mound)
    hole = sph((0, -0.38, 0.36), 1, (0.4, 0.3, 0.37)); setmat(hole, mat("shadow", (0.03, 0.02, 0.03), 0.9)); P.append(hole)
    # escoras de madeira na boca da toca: é obra de rato, não de bicho do mato
    wood = mat("wood", (0.45, 0.27, 0.13), 0.8, bump=0.4, bump_scale=25)
    for (loc, size, rot) in (((-0.44, -0.86, 0.36), (0.1, 0.1, 0.8), (0, -8, 0)), ((0.44, -0.86, 0.36), (0.1, 0.1, 0.8), (0, 9, 0)),
                             ((0.0, -0.87, 0.78), (1.1, 0.12, 0.11), (0, 4, 0))):
        b = box(loc, size, rot, bevel=0.02); hard(b); setmat(b, wood); P.append(b)
    # olhos no escuro, pedrinhas, um osso roído e um pedaço de queijo
    for (x, z) in ((-0.14, 0.42), (0.0, 0.42), (0.17, 0.3), (0.3, 0.3)):
        e = sph((x, -0.6, z), 1, (0.035, 0.02, 0.03)); setmat(e, mat("eyeglow", (1.0, 0.82, 0.25), 0.4, emit=8.0)); P.append(e)
    for (x, y, r) in ((-0.95, -0.75, 0.1), (0.9, -0.85, 0.08), (1.2, -0.3, 0.12), (-1.25, -0.25, 0.07), (0.62, -1.02, 0.05)):
        s = sph((x, y, r * 0.6), r, (1, 0.9, 0.7)); shade(s); setmat(s, mat("stone", STONE, 0.9)); P.append(s)
    bone = fuse(capsule((-0.8, -1.05, 0.05), (-0.48, -1.18, 0.05), 0.03) + [sph((-0.83, -1.02, 0.07), 0.045), sph((-0.83, -1.08, 0.03), 0.045),
                sph((-0.45, -1.15, 0.07), 0.045), sph((-0.45, -1.21, 0.03), 0.045)], "bone", 0.008)
    setmat(bone, mat("bone", BONE, 0.6)); P.append(bone)
    ch = box((0.95, -1.0, 0.09), (0.26, 0.2, 0.16), (0, 0, 25), bevel=0.02, taper=(0.9, 0.2)); hard(ch); setmat(ch, mat("cheese", (0.98, 0.78, 0.22), 0.5)); P.append(ch)
    group("burrow", P)
    # ratos: um saindo da boca, um já fora olhando para o jogador, um no alto do monte
    place(chars.rat(), (0.02, -0.72, 0.05), rot_z=6, scale=0.62)
    place(chars.rat(), (-0.72, -1.25, 0.0), rot_z=-38, scale=0.6)
    place(chars.rat(), (0.5, 0.2, 0.86), rot_z=40, scale=0.5)
    return {"kind": "structure", "dir": (0.42, -1.0, 0.36)}


# ------------------------------------------------------------------ Carniçal

def ghoul():
    P = []
    SK = (0.55, 0.62, 0.52)
    SK_D = (0.30, 0.36, 0.33)

    def skin(p, n):
        c = mix(SK_D, SK, smoothstep(-0.3, 0.8, n.z) * 0.55 + 0.25)
        c = mix(c, (0.62, 0.45, 0.42), ell_w(p, (0, -0.25, 0.95), (0.3, 0.2, 0.3)) * 0.5)   # barriga arroxeada
        return c
    body = fuse([
        sph((0, 0.05, 1.0), 1, (0.34, 0.3, 0.4), (-28, 0, 0)),          # tronco curvado
        sph((0, 0.2, 1.3), 1, (0.38, 0.3, 0.26), (-35, 0, 0)),          # corcunda
        sph((0, -0.28, 1.42), 1, (0.2, 0.2, 0.18)),                      # pescoço para a frente
        sph((0, -0.5, 1.52), 1, (0.25, 0.27, 0.24)),                     # cabeça
        sph((0, -0.66, 1.38), 1, (0.17, 0.16, 0.1)),                     # mandíbula caída
        sph((0, 0.1, 0.62), 1, (0.27, 0.22, 0.2)),                       # quadril
        capsule((0.2, 0.08, 0.6), (0.3, -0.18, 0.32), 0.1, 0.075), capsule((0.3, -0.18, 0.32), (0.26, 0.02, 0.06), 0.07, 0.06),
        capsule((-0.2, 0.08, 0.6), (-0.3, -0.12, 0.32), 0.1, 0.075), capsule((-0.3, -0.12, 0.32), (-0.26, 0.1, 0.06), 0.07, 0.06),
        # braços compridos, um estendido para agarrar e um arrastando no chão
        capsule((0.36, 0.05, 1.3), (0.6, -0.3, 1.02), 0.085, 0.065), capsule((0.6, -0.3, 1.02), (0.5, -0.82, 1.12), 0.065, 0.055),
        capsule((-0.36, 0.05, 1.3), (-0.62, -0.1, 0.82), 0.085, 0.065), capsule((-0.62, -0.1, 0.82), (-0.6, -0.42, 0.3), 0.065, 0.055),
        sph((0.26, -0.06, 0.05), 1, (0.09, 0.16, 0.05)), sph((-0.26, 0.0, 0.05), 1, (0.09, 0.16, 0.05)),
        sph((0.5, -0.9, 1.13), 1, (0.09, 0.1, 0.07)), sph((-0.6, -0.48, 0.26), 1, (0.09, 0.1, 0.07)),
    ], "ghoul_body", 0.014, smooth=0.6, iters=7)
    paint(body, skin); setmat(body, mat("ghoulskin", vcol=True, rough=0.8, bump=0.3, bump_scale=60)); P.append(body)
    # espinhas da coluna e costelas marcadas
    for k in range(5):
        t = k / 4.0
        s = sph((0, 0.36 - t * 0.32, 1.52 - t * 0.5 + 0.06), 1, (0.045, 0.06, 0.07), (-35 + t * 40, 0, 0)); shade(s)
        setmat(s, mat("bone", BONE, 0.6)); P.append(s)
    for sx in (-1, 1):
        for k in range(3):
            r = tube([(sx * 0.1, -0.2, 1.12 - k * 0.1), (sx * 0.27, -0.22, 1.1 - k * 0.1), (sx * 0.33, -0.06, 1.12 - k * 0.1)], 0.018, 0.6, 8)
            setmat(r, mat("rib", (0.36, 0.42, 0.38), 0.8)); P.append(r)
        P += monsters.glow_eye((sx * 0.11, -0.72, 1.56), 0.062, color=(1.0, 0.86, 0.3))
        ear = sph((sx * 0.25, -0.44, 1.6), 1, (0.05, 0.03, 0.13), (0, sx * -35, sx * -20)); shade(ear); setmat(ear, mat("ghoulear", SK_D, 0.8)); P.append(ear)
    # boca aberta escura, dentes tortos, língua
    mouth = sph((0, -0.72, 1.4), 1, (0.12, 0.07, 0.08)); setmat(mouth, mat("shadow", (0.03, 0.02, 0.03), 0.9)); P.append(mouth)
    for (x, z, hh, rz) in ((-0.09, 1.45, 0.07, 8), (-0.03, 1.46, 0.09, -4), (0.04, 1.455, 0.06, 6), (0.095, 1.45, 0.08, -10),
                           (-0.06, 1.345, -0.06, 5), (0.02, 1.34, -0.07, -6), (0.08, 1.35, -0.05, 9)):
        t = box((x, -0.79, z - hh * 0.5), (0.03, 0.025, abs(hh)), (0, rz, 0), bevel=0.006, taper=(0.2, 0.5) if hh < 0 else None)
        if hh > 0:
            t.rotation_euler[0] = math.radians(180)
        hard(t); setmat(t, mat("tooth", (1, 0.97, 0.85), 0.3)); P.append(t)
    # garras
    claw = mat("claw", (0.12, 0.1, 0.1), 0.4)
    for (c, d) in (((0.5, -0.98, 1.13), (0, -1, -0.25)), ((-0.6, -0.56, 0.24), (0, -1, -0.5))):
        for k in (-1, 0, 1):
            a = Vector(c) + Vector((k * 0.05, 0, 0.0)); b = a + Vector(d).normalized() * 0.13 + Vector((k * 0.02, 0, 0))
            t = tube([tuple(a), tuple((a + b) / 2 + Vector((0, 0, 0.02))), tuple(b)], 0.016, 0.15, 8); setmat(t, claw); P.append(t)
    # trapos na cintura
    rag = mat("rag", (0.32, 0.22, 0.18), 0.9)
    for (x, y, rz, ln) in ((0.0, -0.2, 0, 0.36), (0.2, -0.12, 25, 0.28), (-0.2, -0.1, -25, 0.3), (0.0, 0.3, 180, 0.3)):
        r = box((x, y, 0.62 - ln * 0.5), (0.2, 0.025, ln), (8, 0, rz), bevel=0.01, taper=(0.7, 1)); r.rotation_euler[0] = math.radians(172)
        hard(r); setmat(r, rag); P.append(r)
    group("ghoul", P)
    # cova aberta: lápide torta, terra revirada, um crânio
    G = []
    st = mat("gravestone", STONE, 0.9, bump=0.4, bump_scale=14)
    slab = box((-0.85, 0.75, 0.55), (0.6, 0.14, 1.1), (6, -9, 14), bevel=0.05); hard(slab); setmat(slab, st); G.append(slab)
    top = cyl((-0.93, 0.78, 1.08), 0.3, 0.14, rot=(96, -9, 14), seg=24, bevel=0.03); hard(top); setmat(top, st); G.append(top)
    dirt = fuse([sph((0.75, 0.55, 0.05), 1, (0.55, 0.45, 0.2)), sph((1.0, 0.1, 0.03), 1, (0.35, 0.3, 0.13)), sph((0.35, 0.85, 0.04), 1, (0.4, 0.3, 0.15))], "dirt", 0.03)
    setmat(dirt, mat("soilf", DIRT_D, 0.95, bump=0.5, bump_scale=18)); G.append(dirt)
    sk = fuse([sph((0.95, -0.35, 0.12), 1, (0.13, 0.14, 0.12)), sph((0.95, -0.45, 0.07), 1, (0.09, 0.08, 0.06))], "skull", 0.008)
    setmat(sk, mat("bone", BONE, 0.6)); G.append(sk)
    for sx in (-1, 1):
        s = sph((0.95 + sx * 0.05, -0.47, 0.14), 1, (0.03, 0.02, 0.035)); setmat(s, mat("shadow", (0.03, 0.02, 0.03), 0.9)); G.append(s)
    group("grave", G)
    return {"kind": "monster", "dir": (0.5, -1.0, 0.22)}


# ------------------------------------------------------------------ Diabretes de Fogo

def _imp(M):
    P = []
    RD = (0.78, 0.2, 0.12)
    RD_D = (0.42, 0.08, 0.1)

    def skin(p, n):
        return mix(RD_D, RD, smoothstep(-0.4, 0.8, n.z) * 0.6 + 0.2)
    body = fuse([
        sph((0, 0.0, 0.52), 1, (0.2, 0.18, 0.22)), sph((0, -0.04, 0.4), 1, (0.17, 0.16, 0.14)),      # barriguinha
        sph((0, -0.06, 0.86), 1, (0.27, 0.25, 0.24)),                                                  # cabeção
        capsule((0.17, 0, 0.6), (0.36, -0.14, 0.72), 0.05, 0.04), capsule((0.36, -0.14, 0.72), (0.4, -0.3, 0.9), 0.04, 0.045),
        capsule((-0.17, 0, 0.6), (-0.34, -0.12, 0.5), 0.05, 0.04), capsule((-0.34, -0.12, 0.5), (-0.36, -0.3, 0.42), 0.04, 0.045),
        capsule((0.1, 0, 0.34), (0.16, -0.08, 0.16), 0.06, 0.045), capsule((-0.1, 0, 0.34), (-0.15, 0.06, 0.14), 0.06, 0.045),
        sph((0.17, -0.14, 0.12), 1, (0.06, 0.1, 0.04)), sph((-0.16, 0.0, 0.1), 1, (0.06, 0.1, 0.04)),
    ], "imp_body", 0.01, smooth=0.6, iters=6)
    paint(body, skin); setmat(body, mat("impskin", vcol=True, rough=0.6, bump=0.15, bump_scale=90)); P.append(body)
    horn = mat("horn", (0.16, 0.1, 0.1), 0.4)
    for sx in (-1, 1):
        h = tube([(sx * 0.16, -0.04, 1.04), (sx * 0.27, -0.02, 1.18), (sx * 0.24, -0.08, 1.32)], 0.05, 0.15, 12); setmat(h, horn); P.append(h)
        ear = sph((sx * 0.3, -0.02, 0.9), 1, (0.14, 0.03, 0.07), (0, sx * -25, sx * 15)); shade(ear); setmat(ear, mat("impear", RD_D, 0.7)); P.append(ear)
        P += monsters2.yellow_eye((sx * 0.11, -0.27, 0.9), 0.075, sx=sx)
        # asas de morcego: braço, dedos e membrana
        W = []
        sh = Vector((sx * 0.14, 0.14, 0.66)); el = Vector((sx * 0.5, 0.22, 0.98))
        tips = [Vector((sx * 0.95, 0.2, 1.12)), Vector((sx * 0.98, 0.24, 0.72)), Vector((sx * 0.7, 0.22, 0.45))]
        a = tube([tuple(sh), tuple(el)], 0.025, 0.8, 6); setmat(a, horn); W.append(a)
        for t in tips:
            f = tube([tuple(el), tuple((el + t) / 2 + Vector((0, 0, 0.03))), tuple(t)], 0.015, 0.4, 8); setmat(f, horn); W.append(f)
        blobs = []
        for k in range(len(tips)):
            b = tips[k]; c = tips[k + 1] if k + 1 < len(tips) else sh + Vector((0, 0.04, -0.15))
            ctr = (el + b + c) / 3; size = max((b - el).length, (c - el).length) * 0.5
            blobs.append(sph(tuple(ctr), 1, (size * 0.9, 0.012, size * 0.62), (0, sx * -math.degrees(math.atan2(ctr.z - el.z, abs(ctr.x - el.x))), 0)))
        mem = fuse(blobs, "wing", 0.012, smooth=0.4, iters=3); setmat(mem, mat("impwing", (0.5, 0.1, 0.12), 0.6)); W.append(mem)
        P += W
    mouth = sph((0, -0.29, 0.76), 1, (0.13, 0.05, 0.06)); setmat(mouth, mat("shadow", (0.03, 0.02, 0.03), 0.9)); P.append(mouth)
    for sx in (-1, 1):
        f = box((sx * 0.07, -0.31, 0.775), (0.03, 0.02, 0.06), bevel=0.006, taper=(0.15, 0.4)); f.rotation_euler[0] = math.radians(180)
        hard(f); setmat(f, mat("tooth", (1, 0.97, 0.88), 0.3)); P.append(f)
    tail = tube([(0, 0.16, 0.36), (0.05, 0.4, 0.3), (0.2, 0.55, 0.42), (0.3, 0.5, 0.62)], 0.035, 0.3, 16); setmat(tail, mat("impskin2", RD_D, 0.6)); P.append(tail)
    tip = box((0.33, 0.48, 0.7), (0.12, 0.03, 0.14), (0, 25, 0), bevel=0.01, taper=(0.05, 1)); hard(tip); setmat(tip, horn); P.append(tip)
    P += flame((0.4, -0.3, 0.95), h=0.42, r=0.13, lean=(0.03, 0.0))     # bola de fogo na mão
    P += flame((0, -0.02, 1.08), h=0.3, r=0.09)                          # topete em chamas
    monsters.xform(P, M)
    return P


def fire_imp():
    a = _imp(Matrix.Translation((-0.55, 0.0, 0.55)) @ Matrix.Rotation(math.radians(18), 4, 'Z') @ Matrix.Rotation(math.radians(-10), 4, 'X'))
    b = _imp(Matrix.Translation((0.62, 0.45, 1.05)) @ Matrix.Rotation(math.radians(-24), 4, 'Z') @ Matrix.Rotation(math.radians(-14), 4, 'X') @ Matrix.Scale(0.82, 4))
    group("imps", a + b)
    # rastro de brasas embaixo: eles voam
    E = []
    for (x, y, z, r) in ((-0.5, 0.1, 0.25, 0.05), (-0.3, 0.2, 0.1, 0.035), (0.5, 0.5, 0.7, 0.045), (0.75, 0.6, 0.5, 0.03), (0.1, 0.3, 0.4, 0.025)):
        s = sph((x, y, z), r); shade(s); setmat(s, mat("ember", FLAME, 0.4, emit=6.0)); E.append(s)
    group("embers", E)
    return {"kind": "monster", "dir": (0.3, -1.0, 0.12)}


# ------------------------------------------------------------------ Tocha (feitiço)

def torch():
    """Tocha arremessada: cabo na diagonal, fogo subindo e ficando para trás, fagulhas e fumaça."""
    P = []
    wood = mat("wood", (0.45, 0.27, 0.13), 0.8, bump=0.5, bump_scale=30)
    h = cyl((0, 0, 0.75), 0.075, 1.5, seg=14, bevel=0.012, r2=0.1); hard(h); setmat(h, wood); P.append(h)
    iron = mat("iron", (0.3, 0.3, 0.33), 0.5, metal=0.6)
    for z in (1.42, 1.62, 0.12):
        b = cyl((0, 0, z), 0.12 if z > 1 else 0.085, 0.07, seg=18, bevel=0.012); hard(b); setmat(b, iron); P.append(b)
    wrap = fuse([sph((0, 0, 1.56), 1, (0.2, 0.2, 0.2)), sph((0.05, 0.02, 1.72), 1, (0.18, 0.17, 0.14)), sph((-0.06, -0.03, 1.46), 1, (0.16, 0.16, 0.12))], "wrap", 0.014)
    setmat(wrap, mat("pitch", (0.18, 0.13, 0.1), 0.9, bump=0.6, bump_scale=40)); P.append(wrap)
    for (a, z) in ((0.4, 1.36), (2.5, 1.34)):
        t = tube([(math.cos(a) * 0.1, math.sin(a) * 0.1, z), (math.cos(a) * 0.2, math.sin(a) * 0.2, z - 0.12), (math.cos(a) * 0.22, math.sin(a) * 0.22, z - 0.3)], 0.022, 0.4, 10)
        setmat(t, mat("cloth", (0.55, 0.42, 0.3), 0.9)); P.append(t)
    root = group("torch", P)
    root.rotation_euler = (0, math.radians(58), 0)
    root.location = (-0.2, 0, 0.1)
    bpy.context.view_layer.update()
    tip = root.matrix_world @ Vector((0, 0, 1.68))
    F = flame((tip.x - 0.02, tip.y, tip.z - 0.12), h=1.5, r=0.36, lean=(-0.75, 0.0))
    for (dx, dz, r) in ((-0.9, 1.1, 0.04), (-1.3, 0.75, 0.032), (-0.4, 1.75, 0.03), (-1.55, 1.3, 0.024), (0.35, 1.2, 0.028), (-1.0, 1.7, 0.02), (0.1, 1.75, 0.02)):
        s = sph((tip.x + dx, tip.y, tip.z + dz), r); shade(s); setmat(s, mat("ember", FLAME, 0.4, emit=6.0)); F.append(s)
    smoke = mat("smoke", (0.5, 0.48, 0.46), 0.95)
    for (ox, oz) in ((-1.1, 1.5), (-1.5, 1.05)):
        s = tube([(tip.x + ox, tip.y + 0.05, tip.z + oz), (tip.x + ox - 0.3, tip.y + 0.05, tip.z + oz + 0.16), (tip.x + ox - 0.22, tip.y + 0.05, tip.z + oz + 0.38),
                  (tip.x + ox - 0.5, tip.y + 0.05, tip.z + oz + 0.46), (tip.x + ox - 0.62, tip.y + 0.05, tip.z + oz + 0.3)], 0.034, 0.3, 16)
        setmat(s, smoke); F.append(s)
    # riscos de movimento atrás do cabo: é um arremesso
    ink_m = mat("speed", (0.03, 0.02, 0.03), 0.9)
    for (z0, ln) in ((0.18, 0.7), (0.42, 0.5), (-0.05, 0.55)):
        s = tube([(-1.35 - ln, 0.0, z0), (-1.35, 0.0, z0 + 0.02)], 0.012, 0.3, 4); setmat(s, ink_m); F.append(s)
    group("fire", F)
    return {"kind": "spell", "dir": (0.0, -1.0, 0.06), "hatch": 22.0}


# ------------------------------------------------------------------ Rainha da Praga (retrato)

def plague_queen():
    k = monsters2.rat_king()
    place(k, (0, 0, 0), rot_z=-14)
    P = []
    # gola de trapos e manto
    cloak = fuse([sph((0, 0.12, 0.42), 1, (0.56, 0.5, 0.26)), sph((0, 0.28, 0.2), 1, (0.66, 0.56, 0.24))], "cloak", 0.016, smooth=0.5, iters=4)
    setmat(cloak, mat("cloak", (0.36, 0.1, 0.2), 0.85, bump=0.3, bump_scale=30)); P.append(cloak)
    fur = mat("collar", (0.86, 0.82, 0.7), 0.95, bump=0.8, bump_scale=60)
    for i in range(9):
        a = math.radians(200 + i * 17.5)
        s = sph((math.cos(a) * 0.5, 0.1 + math.sin(a) * 0.42, 0.5), 1, (0.13, 0.13, 0.11)); shade(s); setmat(s, fur); P.append(s)
    # cetro de osso com caveira de rato
    bone = mat("bone", BONE, 0.6)
    st = tube([(0.72, -0.2, 0.0), (0.7, -0.22, 0.55), (0.66, -0.25, 1.1)], 0.035, 0.9, 10); setmat(st, bone); P.append(st)
    sk = fuse([sph((0.65, -0.27, 1.2), 1, (0.11, 0.13, 0.1)), sph((0.65, -0.4, 1.16), 1, (0.055, 0.1, 0.05))], "ratskull", 0.008); setmat(sk, bone); P.append(sk)
    for sx in (-1, 1):
        e = sph((0.65 + sx * 0.05, -0.36, 1.22), 1, (0.028, 0.02, 0.03)); setmat(e, mat("plagueglow", (0.6, 1.0, 0.35), 0.4, emit=8.0)); P.append(e)
    group("regalia", P)
    place(chars.rat(), (-0.62, -0.5, 0.0), rot_z=30, scale=0.36)
    place(chars.rat(), (0.3, -0.7, 0.0), rot_z=-20, scale=0.33)
    return {"kind": "monster", "dir": (0.28, -1.0, 0.16), "lens": 95}


SCENES = {"rat_burrow": rat_burrow, "ghoul": ghoul, "fire_imp": fire_imp, "torch": torch, "plague_queen": plague_queen}
