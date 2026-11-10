"""Rato, Escudeiro e Arqueira feitos no Blender (versão caprichada para o comparativo)."""
import math
from mk import *

FUR = (0.36, 0.29, 0.27)
FUR_D = (0.22, 0.17, 0.17)
BELLY = (0.78, 0.68, 0.6)
PINK = (0.93, 0.55, 0.6)
SKIN = (0.95, 0.7, 0.56)
STEEL = (0.72, 0.75, 0.8)
GOLD = (1.0, 0.72, 0.28)
BLUE = (0.12, 0.27, 0.72)
RED = (0.68, 0.08, 0.12)
LEATHER = (0.38, 0.22, 0.12)
WOOD = (0.45, 0.27, 0.13)
WHITE = (0.95, 0.94, 0.9)
BLACK = (0.02, 0.02, 0.025)


def eye(loc, r, look=(0, -1, 0), brow=None):
    out = []
    e = sph(loc, r, (1, 0.6, 1.15)); setmat(e, mat("eye", BLACK, 0.08, coat=1.0)); out.append(e)
    hl = sph((loc[0] - r * 0.3, loc[1] - r * 0.55, loc[2] + r * 0.45), r * 0.3, (1, 0.5, 1)); setmat(hl, mat("hl", WHITE, 0.3, emit=0.6)); out.append(hl)
    hl2 = sph((loc[0] + r * 0.3, loc[1] - r * 0.55, loc[2] - r * 0.35), r * 0.13, (1, 0.5, 1)); setmat(hl2, mat("hl", WHITE, 0.3, emit=0.6)); out.append(hl2)
    return out


# ------------------------------------------------------------------ rato

def rat():
    P = []
    body = fuse([
        sph((0, 0.12, 0.40), 1, (0.36, 0.52, 0.34), (-12, 0, 0)),
        sph((0, 0.38, 0.33), 0.35),
        sph((0, -0.22, 0.45), 1, (0.29, 0.3, 0.31)),
        sph((0, -0.5, 0.6), 1, (0.25, 0.27, 0.24)),            # cabeça
        sph((0, -0.78, 0.54), 1, (0.13, 0.2, 0.12), (12, 0, 0)),  # focinho
        sph((0.12, -0.62, 0.53), 0.12), sph((-0.12, -0.62, 0.53), 0.12),
        # patas da frente
        capsule((0.15, -0.3, 0.35), (0.17, -0.42, 0.07), 0.075, 0.06),
        capsule((-0.15, -0.3, 0.35), (-0.17, -0.42, 0.07), 0.075, 0.06),
        # coxas
        sph((0.24, 0.36, 0.27), 1, (0.13, 0.22, 0.2)), sph((-0.24, 0.36, 0.27), 1, (0.13, 0.22, 0.2)),
    ], "rat_body", voxel=0.011, smooth=0.7, iters=8)

    def fur(p, n):
        c = mix(FUR, FUR_D, smoothstep(0.35, 0.75, p.z) * 0.6 + smoothstep(0.2, 0.9, n.z) * 0.25)
        belly = smoothstep(0.1, -0.6, n.z) * smoothstep(0.55, 0.3, p.z)
        c = mix(c, BELLY, belly * 0.9)
        c = mix(c, BELLY, ell_w(p, (0, -0.8, 0.5), (0.12, 0.2, 0.1)) * 0.7)  # queixo/focinho claro
        c = mix(c, PINK, ell_w(p, (0, -0.42, 0.04), (0.3, 0.1, 0.1)))       # mãos
        return c
    paint(body, fur); setmat(body, mat("fur", vcol=True, rough=0.85, bump=0.25, bump_scale=140)); P.append(body)
    # pés traseiros e mãos rosadas
    for sx in (-1, 1):
        f = fuse([sph((sx * 0.25, 0.28, 0.04), 1, (0.08, 0.17, 0.045)), sph((sx * 0.25, 0.14, 0.05), 0.05)], "foot", 0.008)
        setmat(f, mat("pink", PINK, 0.55, sss=0.2)); P.append(f)
        h = sph((sx * 0.17, -0.46, 0.04), 1, (0.07, 0.08, 0.04)); shade(h); setmat(h, mat("pink", PINK, 0.55, sss=0.2)); P.append(h)
    # orelhas grandes
    for sx in (-1, 1):
        ear = sph((sx * 0.21, -0.43, 0.83), 1, (0.17, 0.05, 0.17), (8, 0, sx * -28), seg=48); shade(ear)
        setmat(ear, mat("fur_ear", FUR, 0.8, sss=0.15)); P.append(ear)
        inn = sph((sx * 0.215, -0.465, 0.825), 1, (0.12, 0.025, 0.12), (8, 0, sx * -28), seg=48); shade(inn)
        setmat(inn, mat("pink_in", (0.95, 0.5, 0.58), 0.5, sss=0.4)); P.append(inn)
    # nariz, olhos, dentes, bigodes
    n = sph((0, -0.96, 0.57), 0.045, (1.2, 1, 0.9)); shade(n); setmat(n, mat("nose", (0.95, 0.42, 0.5), 0.25, coat=0.6)); P.append(n)
    for sx in (-1, 1):
        P += eye((sx * 0.115, -0.7, 0.67), 0.05)
        # sobrancelha marrenta
        b = box((sx * 0.11, -0.72, 0.735), (0.09, 0.03, 0.022), (0, sx * -18, 0), bevel=0.008); hard(b); setmat(b, mat("furd", FUR_D, 0.8)); P.append(b)
    for sx in (-1, 1):
        t = box((sx * 0.022, -0.9, 0.45), (0.04, 0.02, 0.06), (8, 0, 0), bevel=0.008); hard(t); setmat(t, mat("tooth", (1, 0.97, 0.88), 0.3, coat=0.5)); P.append(t)
    for sx in (-1, 1):
        for k in (-1, 0, 1):
            w = tube([(sx * 0.07, -0.9, 0.55 + k * 0.012), (sx * 0.2, -0.93, 0.56 + k * 0.03), (sx * 0.33, -0.9, 0.55 + k * 0.06)], 0.004, 0.3, 8)
            setmat(w, mat("whisk", (0.15, 0.12, 0.12), 0.5)); P.append(w)
    # rabo em curva, afinando
    tail = tube([(0, 0.62, 0.3), (0.05, 0.85, 0.22), (0.2, 1.0, 0.12), (0.4, 1.0, 0.08), (0.55, 0.88, 0.1), (0.6, 0.72, 0.16)], 0.045, 0.18, 32)
    shade(tail); setmat(tail, mat("tail", (0.9, 0.55, 0.58), 0.5, sss=0.25, bump=0.4, bump_scale=30)); P.append(tail)
    return group("new_rat", P)


# ------------------------------------------------------------------ corpo base de boneco (escudeiro e arqueira)

def chibi_head(P, hair=None, face_y=-0.3):
    head = fuse([sph((0, 0, 1.5), 1, (0.34, 0.32, 0.33)), sph((0, -0.06, 1.38), 1, (0.27, 0.26, 0.2)),
                 sph((0.33, 0.0, 1.47), 1, (0.05, 0.07, 0.08)), sph((-0.33, 0.0, 1.47), 1, (0.05, 0.07, 0.08))], "head", 0.01)

    def sk(p, n):
        c = SKIN
        for sx in (-1, 1):
            c = mix(c, (1.0, 0.5, 0.48), ell_w(p, (sx * 0.17, -0.27, 1.4), (0.08, 0.06, 0.05)) * 0.6)
        return c
    paint(head, sk); setmat(head, mat("skin", vcol=True, rough=0.55, sss=0.25)); P.append(head)
    for sx in (-1, 1):
        P += eye((sx * 0.12, -0.3, 1.5), 0.055)
    nose = sph((0, -0.335, 1.42), 0.03, (1.2, 0.8, 0.9)); shade(nose); setmat(nose, mat("skin2", (0.96, 0.62, 0.5), 0.5, sss=0.3)); P.append(nose)
    mouth = tube([(-0.05, -0.31, 1.345), (0, -0.322, 1.335), (0.05, -0.31, 1.345)], 0.008, 1.0, 8)
    setmat(mouth, mat("mouth", (0.45, 0.15, 0.15), 0.5)); P.append(mouth)
    return head


def legs(P, pants, boot, greave=None):
    for sx in (-1, 1):
        leg = fuse([capsule((sx * 0.15, 0, 0.62), (sx * 0.16, -0.01, 0.34), 0.11, 0.095), capsule((sx * 0.16, -0.01, 0.34), (sx * 0.16, 0.0, 0.14), 0.095, 0.085)], "leg", 0.01)
        setmat(leg, pants); P.append(leg)
        b = fuse([sph((sx * 0.16, -0.04, 0.08), 1, (0.12, 0.17, 0.09)), capsule((sx * 0.16, 0, 0.1), (sx * 0.16, 0, 0.28), 0.11, 0.115)], "boot", 0.01)
        setmat(b, boot); P.append(b)
        cuff = torus((sx * 0.16, 0, 0.29), 0.115, 0.03); shade(cuff); setmat(cuff, boot); P.append(cuff)
        if greave:
            g = sph((sx * 0.16, -0.08, 0.36), 1, (0.09, 0.05, 0.08)); shade(g); setmat(g, greave); P.append(g)


def arm(P, sx, sleeve, glove, hand_at, pad=None):
    sh = (sx * 0.36, 0, 1.08)
    el = (sx * 0.47, -0.02, 0.88)
    a = fuse([capsule(sh, el, 0.085, 0.075), capsule(el, hand_at, 0.075, 0.07)], "arm", 0.009)
    setmat(a, sleeve); P.append(a)
    h = fuse([sph(hand_at, 0.085), sph((hand_at[0] + sx * 0.04, hand_at[1] - 0.05, hand_at[2] + 0.03), 0.04)], "hand", 0.008)
    setmat(h, glove); P.append(h)
    if pad:
        p = sph((sx * 0.37, 0, 1.12), 1, (0.17, 0.17, 0.13), (0, sx * 20, 0)); shade(p); setmat(p, pad); P.append(p)


# ------------------------------------------------------------------ escudeiro

def knight():
    P = []
    steel = mat("steel", (0.62, 0.65, 0.7), 0.42, 0.85, bump=0.03, bump_scale=8)
    steel_d = mat("steel_d", (0.42, 0.44, 0.5), 0.45, 0.85)
    gold = mat("gold", GOLD, 0.25, 1.0)
    blue = mat("blue", BLUE, 0.8, bump=0.08, bump_scale=200)
    red = mat("red", RED, 0.75, bump=0.08, bump_scale=200)
    leather = mat("leather", LEATHER, 0.55, bump=0.1, bump_scale=60)
    legs(P, steel_d, leather, steel)
    # torso: peitoral de aço + túnica azul em saia
    chest = fuse([sph((0, 0, 0.98), 1, (0.33, 0.25, 0.27)), sph((0, -0.04, 0.84), 1, (0.29, 0.22, 0.18))], "chest", 0.01)
    setmat(chest, steel); P.append(chest)
    skirt = cyl((0, 0, 0.66), 0.3, 0.26, seg=48, bevel=0.03, r2=0.24); hard(skirt); setmat(skirt, blue); P.append(skirt)
    # tabardo
    tab = sph((0, -0.17, 0.86), 1, (0.2, 0.1, 0.3)); shade(tab); setmat(tab, blue); P.append(tab)
    for (l, sz) in (((0, -0.27, 0.86), (0.05, 0.02, 0.24)), ((0, -0.265, 0.93), (0.17, 0.02, 0.05))):
        c = box(l, sz, (-4, 0, 0), bevel=0.008); hard(c); setmat(c, gold); P.append(c)
    belt = torus((0, 0, 0.74), 0.29, 0.035, s=(1, 0.88, 1)); shade(belt); setmat(belt, leather); P.append(belt)
    bk = box((0, -0.29, 0.74), (0.09, 0.03, 0.08), bevel=0.01); hard(bk); setmat(bk, gold); P.append(bk)
    collar = torus((0, 0, 1.2), 0.15, 0.04); shade(collar); setmat(collar, leather); P.append(collar)
    # capa
    cape = fuse([sph((0, 0.24, 0.85), 1, (0.32, 0.05, 0.42), (8, 0, 0))] + [sph((x, 0.27, 0.6), 1, (0.08, 0.05, 0.2)) for x in (-0.24, -0.08, 0.08, 0.24)], "cape", 0.01)
    setmat(cape, red); P.append(cape)
    # braços: direita segura a espada, esquerda o escudo
    arm(P, 1, steel_d, mat("glove", (0.32, 0.2, 0.12), 0.6), (0.52, -0.1, 0.7), steel)
    arm(P, -1, steel_d, mat("glove", (0.32, 0.2, 0.12), 0.6), (-0.52, -0.12, 0.72), steel)
    for sx in (-1, 1):
        rim = torus((sx * 0.37, 0, 1.06), 0.15, 0.022, (0, sx * 20, 0)); shade(rim); setmat(rim, gold); P.append(rim)
    # espada (montada em pé na origem e girada para a mão)
    sw = []
    grip = cyl((0, 0, 0), 0.03, 0.22, bevel=0.0); shade(grip); setmat(grip, leather); sw.append(grip)
    pom = sph((0, 0, -0.13), 0.045); shade(pom); setmat(pom, gold); sw.append(pom)
    guard = box((0, 0, 0.12), (0.32, 0.06, 0.05), bevel=0.015); hard(guard); setmat(guard, gold); sw.append(guard)
    gem = sph((0, -0.035, 0.12), 0.025); shade(gem); setmat(gem, mat("gem", (0.1, 0.35, 1.0), 0.1, coat=1.0)); sw.append(gem)
    blade = box((0, 0, 0.6), (0.12, 0.028, 0.92), bevel=0.01, taper=(0.12, 0.5)); hard(blade)
    setmat(blade, mat("blade", (0.85, 0.88, 0.93), 0.18, 1.0)); sw.append(blade)
    fuller = box((0, -0.0145, 0.5), (0.025, 0.004, 0.6), bevel=0.0); hard(fuller); setmat(fuller, steel_d); sw.append(fuller)
    from mathutils import Matrix
    M = Matrix.Translation((0.53, -0.12, 0.7)) @ Matrix.Rotation(math.radians(-35), 4, 'X') @ Matrix.Rotation(math.radians(10), 4, 'Y')
    for o in sw:
        o.matrix_world = M @ o.matrix_world
    P += sw
    # escudo redondo
    sc = (-0.6, -0.2, 0.78)
    sh = cyl(sc, 0.34, 0.06, (90, 0, -20), seg=64, bevel=0.02); hard(sh); setmat(sh, blue); P.append(sh)
    rim = torus(sc, 0.34, 0.03, (90, 0, -20)); shade(rim); setmat(rim, gold); P.append(rim)
    boss = sph((sc[0] + 0.012, sc[1] - 0.04, sc[2]), 1, (0.09, 0.05, 0.09), (0, 0, -20)); shade(boss); setmat(boss, steel); P.append(boss)
    for (s, l) in (((0.06, 0.02, 0.44), (0, 0, 0)), ((0.44, 0.02, 0.06), (0, 0, 0.06))):
        c = box((sc[0] + 0.01, sc[1] - 0.04, sc[2] + l[2]), s, (0, 0, -20), bevel=0.008); hard(c); setmat(c, gold); P.append(c)
    # cabeça com elmo aberto e penacho
    head = chibi_head(P)
    helm = fuse([sph((0, 0.02, 1.56), 1, (0.38, 0.37, 0.37))], "helm", 0.01)
    import bpy
    cut = sph((0, -0.32, 1.42), 1, (0.27, 0.3, 0.2))
    m = helm.modifiers.new("cut", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'
    apply_mods(helm); bpy.data.objects.remove(cut)
    m = helm.modifiers.new("sol", 'SOLIDIFY'); m.thickness = 0.03; apply_mods(helm)
    m = helm.modifiers.new("bv", 'BEVEL'); m.width = 0.012; m.segments = 2; m.limit_method = 'ANGLE'; apply_mods(helm)
    shade(helm); setmat(helm, steel); P.append(helm)
    brim = torus((0, -0.02, 1.55), 0.37, 0.028, (-28, 0, 0), s=(1, 1, 1)); shade(brim); setmat(brim, gold); P.append(brim)
    ridge = box((0, 0.0, 1.9), (0.05, 0.5, 0.1), bevel=0.02); hard(ridge, 1); setmat(ridge, gold); P.append(ridge)
    plume = fuse([sph((0, -0.02 + i * 0.1, 2.0 + 0.04 * math.sin(i * 0.9) - i * i * 0.012), 1, (0.075, 0.13, 0.12 - i * 0.012), (-20 + i * 12, 0, 0)) for i in range(6)], "plume", 0.01)
    setmat(plume, mat("plume", (0.85, 0.12, 0.15), 0.7, bump=0.3, bump_scale=90)); P.append(plume)
    return group("new_knight", P)


# ------------------------------------------------------------------ arqueira

def archer():
    import bpy
    P = []
    green = mat("green", (0.16, 0.42, 0.2), 0.8, bump=0.08, bump_scale=200)
    green_d = mat("green_d", (0.09, 0.24, 0.13), 0.85, bump=0.08, bump_scale=200)
    leather = mat("leather", LEATHER, 0.55, bump=0.1, bump_scale=60)
    leather_l = mat("leather_l", (0.58, 0.38, 0.2), 0.55, bump=0.1, bump_scale=60)
    pants = mat("pants", (0.3, 0.24, 0.2), 0.8, bump=0.08, bump_scale=200)
    hairm = mat("hair", (0.62, 0.25, 0.08), 0.45, bump=0.15, bump_scale=40)
    legs(P, pants, leather_l)
    # túnica verde, corpete de couro
    body = fuse([sph((0, 0, 0.97), 1, (0.3, 0.23, 0.27)), sph((0, 0, 0.8), 1, (0.27, 0.21, 0.17))], "tunic", 0.01)
    setmat(body, green); P.append(body)
    sk = cyl((0, 0, 0.62), 0.27, 0.28, seg=48, bevel=0.03, r2=0.24); hard(sk); setmat(sk, green); P.append(sk)
    for x in (-0.12, 0.12):  # aberturas da saia
        f = box((x, -0.245, 0.6), (0.13, 0.035, 0.2), bevel=0.03, seg=4, taper=(1.1, 1.0)); hard(f); setmat(f, green_d); P.append(f)
    vest = fuse([sph((0, -0.1, 0.86), 1, (0.22, 0.16, 0.15))], "vest", 0.01); setmat(vest, leather); P.append(vest)
    for i in range(3):
        lace = box((0, -0.245, 0.8 + i * 0.06), (0.1, 0.012, 0.014), bevel=0.003); hard(lace); setmat(lace, leather_l); P.append(lace)
    belt = torus((0, 0, 0.73), 0.27, 0.03, s=(1, 0.9, 1)); shade(belt); setmat(belt, leather_l); P.append(belt)
    pouch = box((0.2, -0.2, 0.68), (0.1, 0.06, 0.1), (0, 0, 30), bevel=0.02); hard(pouch, 1); setmat(pouch, leather); P.append(pouch)
    # capa com capuz
    cloak = fuse([sph((0, 0.2, 0.86), 1, (0.34, 0.06, 0.45), (8, 0, 0)), sph((0, 0.08, 1.16), 1, (0.32, 0.2, 0.1))] +
                 [sph((x, 0.24, 0.58), 1, (0.08, 0.05, 0.2)) for x in (-0.24, -0.08, 0.08, 0.24)], "cloak", 0.01)
    setmat(cloak, green_d); P.append(cloak)
    # aljava nas costas
    q = cyl((0.12, 0.3, 1.0), 0.085, 0.5, (0, -25, 0), bevel=0.01); hard(q); setmat(q, leather); P.append(q)
    for i in range(5):
        x = 0.12 + 0.13 * math.sin(math.radians(25)) + (i - 2) * 0.025
        sh = cyl((x + 0.08, 0.3 + (i % 2) * 0.03, 1.3), 0.008, 0.3, (0, -25, 0), bevel=0); shade(sh); setmat(sh, mat("shaft", (0.75, 0.6, 0.4), 0.6)); P.append(sh)
        fl = box((x + 0.15, 0.3 + (i % 2) * 0.03, 1.44), (0.008, 0.04, 0.08), (0, -25, 0), bevel=0.003); hard(fl)
        setmat(fl, mat("fletch", (0.9, 0.2, 0.2) if i % 2 else (0.95, 0.93, 0.88), 0.7)); P.append(fl)
    qs = tube([(0.22, -0.15, 1.17), (0.08, -0.252, 1.0), (-0.1, -0.252, 0.86), (-0.24, -0.17, 0.75)], 0.02, 1.0, 16)
    setmat(qs, leather); P.append(qs)
    # braços: esquerda segura o arco, direita relaxada
    arm(P, -1, green, mat("glove", (0.32, 0.2, 0.12), 0.6), (-0.55, -0.15, 0.82))
    arm(P, 1, green, mat("glove", (0.32, 0.2, 0.12), 0.6), (0.5, -0.08, 0.7))
    for sx, hz in ((-1, 0.9), (1, 0.8)):
        br = cyl((sx * 0.5, -0.04, hz), 0.08, 0.12, (0, sx * 25, 0), bevel=0.01); hard(br); setmat(br, leather_l); P.append(br)
    # arco longo
    bx, by = -0.58, -0.18
    bow = tube([(bx, by, 0.25), (bx - 0.02, by - 0.18, 0.5), (bx, by - 0.08, 0.82), (bx - 0.02, by - 0.18, 1.14), (bx, by, 1.38)], 0.025, 0.45, 32)
    setmat(bow, mat("bow", WOOD, 0.45, coat=0.3, bump=0.2, bump_scale=25)); P.append(bow)
    grip = cyl((bx, by - 0.08, 0.82), 0.035, 0.14, bevel=0.0); shade(grip); setmat(grip, leather); P.append(grip)
    string = tube([(bx, by + 0.005, 0.27), (bx, by + 0.005, 1.36)], 0.004, 1.0, 4)
    setmat(string, mat("string", (0.9, 0.88, 0.8), 0.5)); P.append(string)
    # cabeça, cabelo ruivo, capuz
    head = chibi_head(P)
    bangs = fuse([sph((x, -0.24, 1.66 - abs(x) * 0.4), 1, (0.11, 0.08, 0.08), (20, 0, x * 60)) for x in (-0.16, -0.05, 0.06, 0.17)] +
                 [sph((0, 0.02, 1.62), 1, (0.35, 0.33, 0.27))], "hair", 0.01)
    setmat(bangs, hairm); P.append(bangs)
    braid = fuse([sph((0.24, 0.12 + i * 0.02, 1.33 - i * 0.1), 0.065 - i * 0.006) for i in range(5)], "braid", 0.008)
    setmat(braid, hairm); P.append(braid)
    hood = fuse([sph((0, 0.05, 1.56), 1, (0.385, 0.375, 0.39)), sph((0, 0.3, 1.72), 1, (0.1, 0.22, 0.1), (60, 0, 0))], "hood", 0.012)
    cut = sph((0, -0.38, 1.47), 1, (0.32, 0.36, 0.31))
    m = hood.modifiers.new("cut", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'
    apply_mods(hood); bpy.data.objects.remove(cut)
    m = hood.modifiers.new("sol", 'SOLIDIFY'); m.thickness = 0.035; apply_mods(hood)
    m = hood.modifiers.new("sm", 'SMOOTH'); m.factor = 0.5; m.iterations = 3; apply_mods(hood)
    shade(hood); setmat(hood, green_d); P.append(hood)
    return group("new_archer", P)
