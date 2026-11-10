"""Monstros e estruturas do Last Boss no estilo aprovado em 09/11/2026 (comparativo Blender x KayKit):
olhos grandes, formas macias fundidas por voxel, cor com contraste, silhueta que lê de cima.
Cada função devolve o grupo (vazio raiz) com as partes marcadas por osso (vat.tag)."""
import math
import bpy, bmesh
from mathutils import Matrix, Vector
from mk import *
from vat import tag
import chars, chars2
from chars import eye, BLACK, WHITE, GOLD, LEATHER, WOOD

BONE = (0.93, 0.89, 0.76)
BONE_D = (0.7, 0.64, 0.52)
RUST = (0.55, 0.3, 0.18)
IRON = (0.42, 0.43, 0.47)


def xform(objs, M):
    bpy.context.view_layer.update()
    for o in objs:
        o.matrix_world = M @ o.matrix_world
    return objs


def glow_eye(loc, r, color=(0.55, 1.0, 0.45), socket=True):
    """Órbita escura com uma pupila que brilha (esqueletos, espectros)."""
    out = []
    if socket:
        s = sph(loc, r, (1.0, 0.55, 1.1)); setmat(s, mat("socket", (0.05, 0.03, 0.06), 0.6)); out.append(s)
    p = sph((loc[0], loc[1] - r * 0.42, loc[2] - r * 0.05), r * 0.42, (1, 0.6, 1.15)); setmat(p, mat("pupil_glow_%s" % str(color), color, 0.4, emit=8.0)); out.append(p)
    hl = sph((loc[0] - r * 0.15, loc[1] - r * 0.7, loc[2] + r * 0.2), r * 0.12); setmat(hl, mat("hl", WHITE, 0.3, emit=0.6)); out.append(hl)
    return out


# ------------------------------------------------------------------ rato, goblin, gosma, ogro (aprovados)

def rat():
    return chars.rat()


def goblin_dynamiter():
    return chars2.goblin()


def slime():
    return chars2.slime()


def ogre():
    return chars2.ogre()


# ------------------------------------------------------------------ esqueleto

def skeleton(archer=False):
    P = []
    bone = mat("bone", BONE, 0.6, bump=0.15, bump_scale=40)
    bone_d = mat("bone_d", BONE_D, 0.7)
    # crânio grande (cabeça de chibi) com mandíbula separada
    skull = fuse([sph((0, 0, 1.18), 1, (0.3, 0.28, 0.27)), sph((0, -0.08, 1.04), 1, (0.22, 0.2, 0.14)),
                  sph((0.2, -0.06, 1.12), 1, (0.08, 0.1, 0.1)), sph((-0.2, -0.06, 1.12), 1, (0.08, 0.1, 0.1))], "skull", 0.01)

    def sk(p, n):
        return mix(BONE, BONE_D, smoothstep(0.4, -0.6, n.z) * 0.6 + ell_w(p, (0, -0.27, 1.03), (0.08, 0.06, 0.06)) * 0.8)
    paint(skull, sk); setmat(skull, mat("bonev", vcol=True, rough=0.6, bump=0.15, bump_scale=40)); P.append(skull)
    tag([skull], "head")
    face = []
    for sx in (-1, 1):
        face += glow_eye((sx * 0.11, -0.24, 1.17), 0.085)
    nose = box((0, -0.29, 1.07), (0.05, 0.03, 0.05), (0, 45, 0), bevel=0.01); hard(nose); setmat(nose, mat("socket", (0.05, 0.03, 0.06), 0.6)); face.append(nose)
    jaw = fuse([sph((0, -0.12, 0.94), 1, (0.16, 0.13, 0.06))], "jaw", 0.008); setmat(jaw, bone); face.append(jaw)
    for k in range(5):
        t = box((-0.1 + k * 0.05, -0.245, 0.985), (0.035, 0.02, 0.045), bevel=0.006); hard(t); setmat(t, mat("tooth", (1, 0.97, 0.88), 0.3, coat=0.5)); face.append(t)
    crack = tube([(0.05, -0.12, 1.42), (0.1, -0.18, 1.34), (0.08, -0.22, 1.28)], 0.008, 0.5, 8); setmat(crack, mat("socket", (0.05, 0.03, 0.06), 0.6)); face.append(crack)
    tag(face, "head"); P += face
    # elmo amassado (soldado) ou capuz rasgado (arqueiro)
    if not archer:
        # elmo de ferro amassado, justo no crânio (não chapéu): calota com nasal e chifrinho
        helm = sph((0, 0.03, 1.27), 1, (0.31, 0.3, 0.24)); helm = fuse([helm], "helm", 0.01)
        cut = box((0, 0.03, 1.05), (0.8, 0.8, 0.4), bevel=0)
        m = helm.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(helm); bpy.data.objects.remove(cut)
        shade(helm); setmat(helm, mat("iron", IRON, 0.5, 0.8)); P.append(helm)
        rim = torus((0, 0.03, 1.26), 0.3, 0.025, s=(1, 0.97, 1)); shade(rim); setmat(rim, mat("rusty", RUST, 0.7, 0.6)); P.append(rim)
        nasal = box((0, -0.29, 1.22), (0.05, 0.03, 0.14), bevel=0.01); hard(nasal); setmat(nasal, mat("iron", IRON, 0.5, 0.8)); P.append(nasal)
        spike = box((0, 0.03, 1.55), (0.05, 0.05, 0.1), bevel=0.01, taper=(0.15, 0.15)); hard(spike); setmat(spike, mat("rusty", RUST, 0.7, 0.6)); P.append(spike)
        tag([helm, rim, spike], "head")
    else:
        hood = fuse([sph((0, 0.05, 1.22), 1, (0.35, 0.34, 0.33)), sph((0, 0.18, 1.0), 1, (0.32, 0.18, 0.2))], "hood", 0.012)
        cut = sph((0, -0.32, 1.12), 1, (0.27, 0.3, 0.26))
        m = hood.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(hood); bpy.data.objects.remove(cut)
        shade(hood); setmat(hood, mat("hoodc", (0.62, 0.13, 0.12), 0.85, bump=0.2, bump_scale=90)); P.append(hood); tag([hood], "head")
    # tronco: costelas em arco, coluna, bacia
    torso = []
    spine = tube([(0, 0.06, 0.48), (0, 0.09, 0.66), (0, 0.06, 0.9)], 0.035, 1.0, 10); setmat(spine, bone_d); torso.append(spine)
    for k in range(3):
        z = 0.84 - k * 0.1; w = 0.2 - k * 0.025
        rib = torus((0, 0.0, z), w, 0.03, (0, 0, 0), s=(1, 0.75, 0.6)); shade(rib); setmat(rib, bone); torso.append(rib)
    stern = box((0, -0.15, 0.74), (0.05, 0.03, 0.22), bevel=0.012); hard(stern); setmat(stern, bone); torso.append(stern)
    pelvis = fuse([sph((0, 0.02, 0.46), 1, (0.17, 0.12, 0.08))], "pelvis", 0.009); setmat(pelvis, bone); torso.append(pelvis)
    cloth = cyl((0, 0.02, 0.42), 0.2, 0.14, seg=10, bevel=0.01, r2=0.17); hard(cloth); setmat(cloth, mat("rag", (0.32, 0.26, 0.38) if not archer else (0.25, 0.3, 0.18), 0.9)); torso.append(cloth)
    for sx in (-1, 1):
        sh = sph((sx * 0.22, 0.02, 0.9), 0.07); setmat(sh, bone); torso.append(sh)
    if not archer:
        pad = fuse([sph((0.24, 0.02, 0.93), 1, (0.12, 0.12, 0.08))], "pad", 0.009); setmat(pad, mat("rusty", RUST, 0.7, 0.6)); torso.append(pad)
    tag(torso, "body"); P += torso
    # pernas e braços finos, com juntas redondas
    for sx in (-1, 1):
        leg = capsule((sx * 0.1, 0.02, 0.42), (sx * 0.11, 0.0, 0.08), 0.035, 0.03) + [sph((sx * 0.11, 0.0, 0.25), 0.05)]
        for o in leg: setmat(o, bone)
        foot = fuse([sph((sx * 0.11, -0.05, 0.04), 1, (0.07, 0.11, 0.045))], "foot", 0.008); setmat(foot, bone)
        tag(leg + [foot], "leg_l" if sx > 0 else "leg_r"); P += leg + [foot]
    for sx in (-1, 1):
        hand_at = (sx * 0.32, -0.08, 0.5)
        a = capsule((sx * 0.23, 0.02, 0.88), (sx * 0.3, -0.02, 0.68), 0.03, 0.028) + capsule((sx * 0.3, -0.02, 0.68), hand_at, 0.028, 0.026) + [sph((sx * 0.3, -0.02, 0.68), 0.045)]
        for o in a: setmat(o, bone)
        hand = fuse([sph(hand_at, 0.05), sph((hand_at[0], hand_at[1] - 0.05, hand_at[2] - 0.02), 0.03)], "hand", 0.007); setmat(hand, bone)
        tag(a + [hand], "arm_l" if sx > 0 else "arm_r"); P += a + [hand]
    W = []
    if not archer:
        # espada curta enferrujada (mão direita = -x) e escudo redondo de tábuas (esquerda)
        blade = box((0, 0, 0.3), (0.07, 0.02, 0.5), bevel=0.008, taper=(0.5, 1.0)); hard(blade); setmat(blade, mat("rusty", RUST, 0.7, 0.6))
        guard = box((0, 0, 0.04), (0.18, 0.05, 0.04), bevel=0.01); hard(guard); setmat(guard, mat("iron", IRON, 0.5, 0.8))
        grip = cyl((0, 0, -0.04), 0.022, 0.12, seg=8, bevel=0.004); hard(grip); setmat(grip, mat("leather", LEATHER, 0.6))
        W = xform([blade, guard, grip], Matrix.Translation((-0.33, -0.12, 0.52)) @ Matrix.Rotation(math.radians(-60), 4, 'X'))
        tag(W, "arm_r")
        sh_ = cyl((0, 0, 0), 0.2, 0.05, (90, 0, 0), seg=20, bevel=0.012); hard(sh_); setmat(sh_, mat("wood", WOOD, 0.75, bump=0.4, bump_scale=20))
        boss = sph((0, -0.03, 0), 0.06, (1, 0.6, 1)); setmat(boss, mat("iron", IRON, 0.5, 0.8))
        band = torus((0, 0, 0), 0.2, 0.018, (90, 0, 0)); shade(band); setmat(band, mat("iron", IRON, 0.5, 0.8))
        S = xform([sh_, boss, band], Matrix.Translation((0.38, -0.14, 0.58)) @ Matrix.Rotation(math.radians(-25), 4, 'Z'))
        tag(S, "arm_l"); W += S
    else:
        bow = tube([(0, 0, -0.42), (0, -0.1, -0.2), (0, -0.13, 0), (0, -0.1, 0.2), (0, 0, 0.42)], 0.02, 0.6, 20); setmat(bow, mat("wood", WOOD, 0.75, bump=0.4, bump_scale=20))
        string = tube([(0, 0, -0.42), (0, 0.0, 0.0), (0, 0, 0.42)], 0.005, 1.0, 4); setmat(string, mat("string", (0.9, 0.88, 0.8), 0.6))
        W = xform([bow, string], Matrix.Translation((0.34, -0.14, 0.55)) @ Matrix.Rotation(math.radians(90), 4, 'Z'))
        tag(W, "arm_l")
        quiver = cyl((0.0, 0.17, 0.75), 0.07, 0.36, (-15, 20, 0), seg=10, bevel=0.01); hard(quiver); setmat(quiver, mat("leather", LEATHER, 0.6))
        arrows = []
        for k in range(3):
            a = cyl((-0.03 + k * 0.03, 0.2 + k * 0.01, 0.97), 0.008, 0.2, (-15, 20, 0), seg=6, bevel=0); arrows.append(a); setmat(a, mat("wood", WOOD, 0.75))
            f = box((-0.03 + k * 0.03 - 0.03, 0.23, 1.07), (0.02, 0.06, 0.06), (-15, 20, 0), bevel=0.004); hard(f); setmat(f, mat("feather", (0.95, 0.9, 0.85), 0.7)); arrows.append(f)
        tag([quiver] + arrows, "body"); W += [quiver] + arrows
    P += W
    return group("skeleton_archers" if archer else "skeleton", P)


def skeleton_archers():
    return skeleton(True)


# ------------------------------------------------------------------ fantasma

def ghost():
    P = []
    GH = (0.72, 0.9, 1.0)
    GH_D = (0.38, 0.55, 0.85)
    pts = [sph((0, 0, 1.0), 1, (0.42, 0.4, 0.44)), sph((0, 0.02, 0.62), 1, (0.38, 0.36, 0.36))]
    for k in range(5):  # barra da cauda em ondas
        a = k / 5 * math.tau
        pts.append(sph((math.cos(a) * 0.28, math.sin(a) * 0.28, 0.28), 1, (0.13, 0.13, 0.2)))
    pts.append(sph((0.05, 0.35, 0.35), 1, (0.12, 0.2, 0.12), (-30, 0, 0)))
    body = fuse(pts, "ghost", 0.012, smooth=0.8, iters=10)

    def col(p, n):
        c = mix(GH_D, GH, smoothstep(0.2, 1.1, p.z))
        return mix(c, (0.95, 1.0, 1.0), smoothstep(0.3, 1.0, n.z) * 0.3)
    paint(body, col); setmat(body, mat("ghostv", vcol=True, rough=0.3, emit=0.0, coat=0.5)); P.append(body)
    tag([body], "body")
    face = []
    for sx in (-1, 1):
        e = sph((sx * 0.15, -0.37, 1.02), 1, (0.09, 0.05, 0.13)); shade(e); setmat(e, mat("eye", BLACK, 0.08, coat=1.0)); face.append(e)
        hl = sph((sx * 0.15 - 0.03, -0.42, 1.07), 0.025); setmat(hl, mat("hl", WHITE, 0.3, emit=0.6)); face.append(hl)
        brow = box((sx * 0.15, -0.4, 1.17), (0.12, 0.03, 0.03), (0, sx * 20, 0), bevel=0.01); hard(brow); setmat(brow, mat("ghd", GH_D, 0.5)); face.append(brow)
    mouth = sph((0, -0.32, 0.8), 1, (0.12, 0.06, 0.08)); shade(mouth); setmat(mouth, mat("gmouth", (0.04, 0.03, 0.1), 0.4)); face.append(mouth)
    tag(face, "body"); P += face
    for sx in (-1, 1):
        a = fuse(capsule((sx * 0.33, -0.05, 0.85), (sx * 0.5, -0.2, 0.68), 0.08, 0.06) + [sph((sx * 0.52, -0.22, 0.66), 0.075)], "garm", 0.01)
        paint(a, lambda p, n: GH); setmat(a, mat("ghostv", vcol=True, rough=0.3, coat=0.5)); P.append(a)
        tag([a], "arm_l" if sx > 0 else "arm_r")
    # corrente presa no pulso: o fantasma carrega o peso de quando era vivo
    links = []
    for k in range(4):
        l = torus((0.55, -0.24 - k * 0.0, 0.58 - k * 0.09), 0.04, 0.012, (0, 90 if k % 2 else 0, 0)); shade(l); setmat(l, mat("iron", IRON, 0.5, 0.8)); links.append(l)
    ball = sph((0.55, -0.24, 0.2), 0.08); setmat(ball, mat("iron", IRON, 0.5, 0.8)); links.append(ball)
    tag(links, "arm_l"); P += links
    return group("ghost", P)
