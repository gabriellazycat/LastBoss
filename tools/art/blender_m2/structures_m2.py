"""Estruturas novas (rodada visual 20/11/2026): as 10 cartas de estrutura que usavam o modelo de outra peça
recolorido (Looks.VARIANTS / campo "model" das cartas) ganham modelo próprio, fiel à arte da carta.
Mesmo kit de tools/art/blender_v2/mk.py; exportado por tools/art/blender_m2/build_m2.py (atlas de pincel seco, como
os g_n_a) e importado por tools/art/import_g.gd --m2 em assets/models/m2_a/<id>.res.

Escala: 1 unidade do Blender = 1 m no jogo (exporta com height=None e sem recentralizar: a origem é o pé da peça,
no centro do que conta como "a estrutura"). Frente = -Y (o jogo vira a frente para os heróis).
Animação: no jogo a estrutura só toca o laço "walk" (12 quadros, ~2,2 s; o ataque nunca toca para estruturas,
world_view.gd zera o lunge), então toda a vida (chama, pano, água, olhos) está no laço e fecha em t=0/t=1.
O "atk" (8 quadros) também é gravado, com antecipação, golpe rápido e volta, para o caso de o jogo passar a tocá-lo."""
import math, random
import bpy, bmesh
from mathutils import Matrix, Vector, noise
from mk import *
from vat import tag, rot_about, tr
import mk
import anims

TAU = math.tau
I4 = Matrix.Identity(4)

# id -> (altura de referência em m, orçamento de triângulos). A altura só documenta: a escala é a do Blender.
UNITS = {
    "rat_burrow": (1.5, 3000), "barricade": (1.6, 2600), "war_banner": (3.1, 2400), "trap_chest": (1.0, 2600),
    "furnace": (2.5, 3200), "rat_trap": (1.25, 2600), "sewer_flood": (2.1, 3200), "gold_mine": (2.1, 3200),
    "spike_trap": (1.0, 2000), "pack_den": (2.0, 3200),
}

# ---------------------------------------------------------------- cores (tiradas das cartas)
STONE = (0.6, 0.6, 0.62); STONE_D = (0.3, 0.31, 0.37); STONE_L = (0.66, 0.68, 0.7)
DIRT = (0.36, 0.25, 0.17); DIRT_D = (0.22, 0.15, 0.11); DIRT_L = (0.52, 0.4, 0.28)
WOODC = (0.55, 0.4, 0.26); WOOD_D = (0.32, 0.22, 0.14); WOOD_L = (0.68, 0.55, 0.4)
IRONC = (0.28, 0.29, 0.33); IRON_D = (0.16, 0.16, 0.2)
RUSTC = (0.5, 0.25, 0.14); RUST_D = (0.3, 0.14, 0.09)
RATC = (0.5, 0.55, 0.64); RAT_D = (0.32, 0.36, 0.45); PINK = (0.93, 0.6, 0.62)
FLAG = (0.8, 0.13, 0.1); FLAG_D = (0.5, 0.06, 0.06)
BONEC = (0.93, 0.89, 0.78); BONE_DC = (0.68, 0.62, 0.52)
GOLDC = (1.0, 0.76, 0.25); GOLD_D = (0.8, 0.5, 0.12)
FIRE = (1.0, 0.48, 0.12); FIRE_L = (1.0, 0.82, 0.4)
SEWER = (0.42, 0.78, 0.5); SEWER_D = (0.2, 0.45, 0.35); FUME = (0.7, 0.92, 0.45)
BRICK = (0.66, 0.32, 0.25); BRICK_D = (0.45, 0.2, 0.17)
WOLF = (0.82, 0.83, 0.86); WOLF_D = (0.55, 0.57, 0.62)
DARK = (0.03, 0.025, 0.04)


def vmat(name, rough=0.8):
    return mat(name, vcol=True, rough=rough)


def darkm():
    return mat("shadow", DARK, 0.95)


def glowm(name, c, e=8.0):
    return mat(name, c, 0.4, emit=e)


def M_(o_list, M):
    bpy.context.view_layer.update()
    for o in o_list:
        o.matrix_world = M @ o.matrix_world
    return o_list


def scl_about(p, sx, sy=None, sz=None):
    sy = sx if sy is None else sy
    sz = sx if sz is None else sz
    p = Vector(p)
    S = Matrix.Diagonal((sx, sy, sz, 1.0))
    return Matrix.Translation(p) @ S @ Matrix.Translation(-p)


def lumpy(o, amt, scale, seed):
    """Desalinha os vértices com ruído (pedra lascada, terra), depois dos modificadores."""
    apply_mods(o)
    off = Vector((seed * 7.1, seed * 3.3, seed * 1.7))
    for v in o.data.vertices:
        p = o.matrix_world @ v.co
        v.co += noise.noise_vector(p * scale + off) * amt
    return o


def cut(o, cutter):
    m = o.modifiers.new("c", 'BOOLEAN'); m.object = cutter; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'
    apply_mods(o)
    bpy.data.objects.remove(cutter, do_unlink=True)
    return o


def ease(x):
    return anims.ss(0.0, 1.0, x)


def pulse(t, a, b, c):
    """0 até a, sobe até 1 em b, volta a 0 em c (suave)."""
    if t < a or t > c:
        return 0.0
    if t < b:
        return ease((t - a) / max(b - a, 1e-6))
    return 1.0 - ease((t - b) / max(c - b, 1e-6))


def atk_curve(t, ant=0.3, hit=0.42, back=1.0):
    """Ataque com impacto: recua (antecipação) até ant, golpe rápido até hit, volta devagar. -> (antecipação 0..1, golpe 0..1)."""
    a = ease(t / ant) if t < ant else max(0.0, 1.0 - ease((t - ant) / (hit - ant)))
    g = ease((t - ant) / (hit - ant)) if ant <= t < hit else (1.0 - ease((t - hit) / (back - hit)) if t >= hit else 0.0)
    return a, g


# ---------------------------------------------------------------- peças comuns

def rat(loc, yaw=0.0, s=1.0, bone="rat", pose="stand"):
    """Rato gorducho das cartas (cinza-azulado, orelha e rabo rosados, olho escuro sem pupila). Frente -Y local."""
    def col(p, n):
        c = mix(RAT_D, RATC, smoothstep(-0.5, 0.8, n.z) * 0.8 + 0.2)
        for sx in (-1, 1):
            c = mix(c, PINK, ell_w(p, (sx * 0.1 * s + loc[0] * 0, -0.17 * s, 0.2 * s), (0.07 * s, 0.05 * s, 0.07 * s)))
        return mix(c, PINK, ell_w(p, (0, -0.36 * s, 0.1 * s), (0.04 * s, 0.05 * s, 0.04 * s)))
    parts = [sph((0, 0.05 * s, 0.13 * s), 1, (0.17 * s, 0.25 * s, 0.14 * s)),
             sph((0, -0.22 * s, 0.13 * s), 1, (0.11 * s, 0.14 * s, 0.1 * s), (-10, 0, 0)),
             sph((0, -0.34 * s, 0.1 * s), 1, (0.05 * s, 0.06 * s, 0.045 * s))]
    for sx in (-1, 1):
        parts.append(sph((sx * 0.1 * s, -0.17 * s, 0.22 * s), 1, (0.07 * s, 0.03 * s, 0.07 * s)))
    if pose == "peek":
        parts = parts[1:]
    body = fuse(parts, "ratbody", 0.012 * s, 0.6, 4)
    paint(body, col); setmat(body, vmat("ratfur", 0.85))
    out = [body]
    for sx in (-1, 1):
        e = sph((sx * 0.065 * s, -0.3 * s, 0.17 * s), 1, (0.03 * s, 0.025 * s, 0.035 * s)); setmat(e, mat("eye", DARK, 0.3)); out.append(e)
    if pose != "peek":
        tl = tube([(0, 0.28 * s, 0.1 * s), (0.08 * s, 0.5 * s, 0.04 * s), (0.2 * s, 0.62 * s, 0.03 * s)], 0.035 * s, 0.4, 10)
        setmat(tl, mat("rattail", PINK, 0.6)); out.append(tl)
    M = Matrix.Translation(loc) @ Matrix.Rotation(yaw, 4, 'Z')
    M_(out, M)
    return tag(out, bone)


def glow_pair(c, gap, r, color, name, bone):
    out = []
    for sx in (-1, 1):
        e = sph((c[0] + sx * gap, c[1], c[2]), 1, (r, r * 0.6, r * 0.75)); setmat(e, glowm(name, color, 8.0)); out.append(e)
    return tag(out, bone)


def flame(loc, r, h, name="flame"):
    """Chama pintada: língua de fogo larga (gota alongada) e um miolo claro."""
    out = []
    a = fuse([sph((loc[0], loc[1], loc[2] + h * 0.22), 1, (r, r * 0.8, h * 0.28)),
              capsule((loc[0], loc[1], loc[2] + h * 0.25), (loc[0] + r * 0.15, loc[1], loc[2] + h), r * 0.75, r * 0.08)], name, r * 0.08, 0.6, 3)
    setmat(a, glowm("fire", FIRE, 6.0)); out.append(a)
    b = fuse([sph((loc[0], loc[1] - r * 0.25, loc[2] + h * 0.2), 1, (r * 0.55, r * 0.45, h * 0.18)),
              capsule((loc[0], loc[1] - r * 0.25, loc[2] + h * 0.2), (loc[0], loc[1] - r * 0.25, loc[2] + h * 0.6), r * 0.4, r * 0.05)], name + "k", r * 0.06, 0.6, 3)
    setmat(b, glowm("firek", FIRE_L, 8.0)); out.append(b)
    return out


def stake(a, b, r):
    """Estaca de madeira apontada: tronco de a até perto de b e ponta cônica em b."""
    a, b = Vector(a), Vector(b)
    d = b - a
    tip = a + d * 0.78
    body = cyl(((a + tip) / 2), r, (tip - a).length, seg=7, bevel=0.0)
    body.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    pt = cyl(((tip + b) / 2), r, (b - tip).length, seg=7, bevel=0.0, r2=0.005)
    pt.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    o = join([body, pt], "stake")
    return o


def coin_pile(loc, r, h, name="coins"):
    o = fuse([sph((loc[0], loc[1], loc[2]), 1, (r, r * 0.9, h)),
              sph((loc[0] + r * 0.5, loc[1] - r * 0.2, loc[2]), 1, (r * 0.6, r * 0.55, h * 0.6)),
              sph((loc[0] - r * 0.45, loc[1] + r * 0.25, loc[2]), 1, (r * 0.55, r * 0.5, h * 0.55))], name, max(0.01, r * 0.06), 0.4, 2)
    lumpy(o, r * 0.05, 9.0 / r, 3)
    paint(o, lambda p, n: mix(GOLD_D, GOLDC, smoothstep(-0.2, 0.9, n.z) * 0.8 + 0.2))
    setmat(o, mat("goldv", vcol=True, rough=0.35, metal=0.6))
    return o


# =============================================================== 1. Toca de Ratos

def rat_burrow():
    P = []
    def dirt(p, n):
        k = noise.noise(Vector((p.x * 1.6, p.y * 1.6, p.z * 1.6))) * 0.5 + 0.5
        return mix(mix(DIRT_D, DIRT, smoothstep(-0.3, 0.7, n.z) * 0.8 + 0.1), DIRT_L, smoothstep(0.55, 0.95, n.z) * k * 0.8)
    mound = fuse([sph((0, 0.25, 0.0), 1, (1.45, 1.2, 1.05)), sph((0.75, 0.55, 0.0), 1, (0.8, 0.75, 0.7)),
                  sph((-0.8, 0.45, 0.0), 1, (0.75, 0.7, 0.62)), sph((0, -0.55, 0.0), 1, (1.05, 0.6, 0.42)),
                  sph((-0.95, -0.4, 0.0), 1, (0.5, 0.5, 0.25)), sph((0.95, -0.35, 0.0), 1, (0.45, 0.5, 0.22))], "mound", 0.04, 0.5, 4)
    lumpy(mound, 0.06, 1.4, 5)
    cutter = sph((0, -0.9, 0.45), 1, (0.42, 0.9, 0.42))
    cut(mound, cutter)
    shade(mound); paint(mound, dirt); setmat(mound, vmat("dirtv", 0.95)); P.append(mound)
    # anel de pedra (cano velho) na boca da toca
    ring = torus((0, -0.86, 0.45), 0.5, 0.15, (90, 0, 0))
    ring.scale = (1.0, 1.3, 1.0)
    apply_mods(ring); mk._sel(ring); bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    lumpy(ring, 0.025, 4.0, 2)

    def stone(p, n):
        a = math.atan2(p.z - 0.45, p.x)
        band = 0.5 + 0.5 * math.cos(a * 7.0)
        return mix(STONE_D, STONE, smoothstep(-0.6, 0.8, n.z) * 0.5 + 0.35 * band + 0.1)
    paint(ring, stone); setmat(ring, vmat("stonev", 0.85)); P.append(ring)
    hole = sph((0, -0.6, 0.45), 1, (0.44, 0.14, 0.44)); setmat(hole, darkm()); P.append(hole)
    # chão de terra solta na frente
    apron = fuse([sph((0, -1.35, 0.0), 1, (0.75, 0.55, 0.12)), sph((0.55, -1.15, 0.0), 1, (0.4, 0.35, 0.09))], "apron", 0.03, 0.5, 3)
    lumpy(apron, 0.03, 3.0, 9); paint(apron, dirt); setmat(apron, vmat("dirtv", 0.95)); P.append(apron)
    tag(P, "body")
    # olhos no escuro (piscam em tempos diferentes)
    P += glow_pair((-0.15, -0.78, 0.6), 0.06, 0.035, (1.0, 0.45, 0.4), "ratglow", "eyes0")
    P += glow_pair((0.17, -0.78, 0.36), 0.06, 0.035, (1.0, 0.45, 0.4), "ratglow", "eyes1")
    # rato espiando da boca e um na encosta
    P += rat((0.0, -0.98, 0.12), 0.0, 1.05, "rat1", "peek")
    P += rat((0.85, -0.75, 0.05), math.radians(-35), 1.0, "rat2")
    P += rat((-0.75, -0.95, 0.03), math.radians(30), 0.95, "rat3")
    return group("rat_burrow", P)


def rat_burrow_cfg():
    def anim(kind, t):
        d = {}
        if kind == "walk":
            k = pulse(t, 0.1, 0.35, 0.75)
            d["rat1"] = tr(0, -0.18 * k, 0.04 * k) @ rot_about((0, -1.0, 0.15), 'X', math.radians(-8) * k)
            d["rat2"] = rot_about((0.85, -0.75, 0.1), 'X', math.radians(6) * math.sin(TAU * t * 2))
            d["rat3"] = rot_about((-0.75, -0.95, 0.1), 'Z', math.radians(8) * math.sin(TAU * t + 1.0))
            d["eyes0"] = scl_about((-0.15, -0.78, 0.6), 1, 1, 1 - 0.95 * pulse(t, 0.55, 0.6, 0.66))
            d["eyes1"] = scl_about((0.17, -0.78, 0.36), 1, 1, 1 - 0.95 * pulse(t, 0.82, 0.87, 0.93))
            return d
        a, g = atk_curve(t)
        d["rat1"] = tr(0, 0.12 * a - 0.45 * g, 0.08 * g) @ rot_about((0, -1.0, 0.15), 'X', math.radians(-15) * g)
        d["rat2"] = tr(0, -0.15 * g, 0)
        d["rat3"] = tr(0, -0.15 * g, 0)
        return d
    return {"anim": anim}


# =============================================================== 2. Barricada

def barricade():
    P = []
    def wood(p, n):
        k = noise.noise(Vector((p.x * 3, p.y * 3, p.z * 0.6))) * 0.5 + 0.5
        return mix(WOOD_D, WOODC, smoothstep(-0.4, 0.8, n.z) * 0.4 + 0.35 + k * 0.3)
    # estacas apontadas, inclinadas para a frente (o inimigo vem de -Y)
    xs = [-1.05, -0.7, -0.35, 0.0, 0.35, 0.7, 1.05]
    for i, x in enumerate(xs):
        L = 1.75 + (0.2 if i % 2 else 0.0) - abs(x) * 0.1
        a = Vector((x, 0.55, 0.0))
        b = a + Vector((0.03 * (i - 3), -math.cos(math.radians(65)) * L, math.sin(math.radians(65)) * L))
        s = stake(a, b, 0.12)
        paint(s, wood); setmat(s, vmat("woodv", 0.85)); P.append(s)
    # duas travessas (toras) amarradas com cinta de ferro
    for (y, z) in ((0.55 - 0.42 * 0.466 - 0.1, 0.42), (0.55 - 0.95 * 0.466 - 0.1, 0.95)):
        lg = cyl((0, y, z), 0.1, 2.6, (0, 90, 0), seg=10, bevel=0.0)
        apply_mods(lg); paint(lg, wood); setmat(lg, vmat("woodv", 0.85)); P.append(lg)
        for x in (-0.9, 0.9):
            band = cyl((x, y, z), 0.125, 0.12, (0, 90, 0), seg=10, bevel=0.0); setmat(band, mat("iron", IRONC, 0.5, 0.6)); P.append(band)
    # escoras atrás
    for x in (-0.8, 0.8):
        sc = tube([(x, 0.2, 1.0), (x, 0.65, 0.5), (x, 1.15, 0.0)], 0.08, 1.0, 8)
        paint(sc, wood); setmat(sc, vmat("woodv", 0.85)); P.append(sc)
    tag(P, "body")
    # roda de carroça encostada na ponta esquerda
    W = []
    rim = torus((0, 0, 0), 0.55, 0.07, (0, 0, 0)); apply_mods(rim)
    hub = cyl((0, 0, 0), 0.12, 0.2, seg=12, bevel=0.0)
    sp = [box((0, 0, 0), (1.04, 0.07, 0.06), (0, 0, k * 30), bevel=0.0) for k in range(3)]
    for o in sp:
        apply_mods(o)
    wheel = join([rim, hub] + sp, "wheel")
    paint(wheel, lambda p, n: mix(WOOD_D, WOODC, 0.55))
    setmat(wheel, vmat("woodv", 0.85))
    wheel.rotation_euler = (math.radians(90), math.radians(-12), math.radians(80))
    wheel.location = (-1.45, -0.05, 0.6)
    W.append(wheel)
    tag(W, "wheel"); P += W
    # a carta mostra as estacas deitadas para trás, pontas para cima: de frente (câmera do jogo) a paliçada aparece inteira
    M_(P, Matrix.Rotation(math.pi, 4, 'Z'))
    return group("barricade", P)


def barricade_cfg():
    piv = Vector((0, -0.3, 0.0))
    WP = (1.45, 0.05, 0.6)

    def anim(kind, t):
        if kind == "walk":
            s_ = math.sin(TAU * t)
            return {"body": rot_about(piv, 'X', math.radians(0.8) * s_),
                    "wheel": rot_about(WP, 'X', math.radians(1.5) * math.sin(TAU * t + 0.8))}
        a, g = atk_curve(t)
        sh = math.sin(t * 46) * 0.03 * (1 - t)
        B = tr(sh, 0, 0) @ rot_about(piv, 'X', math.radians(4) * a - math.radians(7) * g)
        return {"body": B, "wheel": B @ rot_about(WP, 'Y', math.radians(6) * g)}
    return {"anim": anim}


# =============================================================== 3. Estandarte de Guerra

FLAG_L = 1.75
FLAG_H = 0.95
FLAG_TOP = 2.55


def _flag_mesh():
    nx, nz = 18, 8
    bm = bmesh.new()
    V = {}
    for i in range(nx + 1):
        for j in range(nz + 1):
            x = 0.06 + i / nx * FLAG_L
            u = i / nx
            h = FLAG_H * (1.0 - 0.35 * u)          # flâmula: afina para a ponta
            z = FLAG_TOP - (FLAG_H - h) * 0.5 * 0 - j / nz * h - u * 0.25
            V[i, j] = bm.verts.new((x, 0.0, z))
    for i in range(nx):
        for j in range(nz):
            u = (i + 0.5) / nx
            v = (j + 0.5) / nz
            if u > 0.62 and abs(v - 0.5) < (u - 0.62) / 0.38 * 0.42:    # rabo de andorinha
                continue
            bm.faces.new((V[i, j], V[i + 1, j], V[i + 1, j + 1], V[i, j + 1]))
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context='VERTS')
    me = bpy.data.meshes.new("flag"); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("flag", me); bpy.context.scene.collection.objects.link(o)
    m = o.modifiers.new("so", 'SOLIDIFY'); m.thickness = 0.05; m.offset = 0.0
    apply_mods(o)
    shade(o)
    paint(o, lambda p, n: mix(FLAG_D, FLAG, 0.75 + 0.25 * smoothstep(1.5, 2.6, p.z)))
    setmat(o, vmat("flagv", 0.8))
    return o


def war_banner():
    P = []
    pole = cyl((0, 0, 1.45), 0.075, 2.9, seg=10, bevel=0.0); apply_mods(pole)
    paint(pole, lambda p, n: mix(WOOD_D, WOODC, 0.5 + 0.3 * smoothstep(-0.5, 0.8, n.x)))
    setmat(pole, vmat("woodv", 0.85)); P.append(pole)
    # base: monte de pedras e terra que segura o mastro
    base = fuse([sph((0, 0, 0.0), 1, (0.55, 0.5, 0.26)), sph((0.3, -0.25, 0.0), 1, (0.3, 0.28, 0.2)), sph((-0.3, 0.2, 0.0), 1, (0.32, 0.3, 0.22)),
                 sph((-0.2, -0.3, 0.05), 1, (0.22, 0.2, 0.18))], "cairn", 0.03, 0.5, 3)
    lumpy(base, 0.05, 3.0, 2)
    paint(base, lambda p, n: mix(STONE_D, STONE, smoothstep(-0.3, 0.9, n.z) * 0.8 + 0.1)); setmat(base, vmat("stonev", 0.85)); P.append(base)
    # lança fincada ao lado
    sp = cyl((0.42, -0.18, 0.75), 0.04, 1.5, (0, -12, 0), seg=8, bevel=0.0); apply_mods(sp); setmat(sp, mat("woodd", WOOD_D, 0.8)); P.append(sp)
    tip = cyl((0.58, -0.18, 1.58), 0.075, 0.28, (0, -12, 0), seg=4, bevel=0.0, r2=0.0); setmat(tip, mat("iron", IRONC, 0.5, 0.6)); P.append(tip)
    # caveira de boi com chifres no topo (sem pupila: órbitas escuras)
    sk = fuse([sph((0, -0.05, 3.0), 1, (0.16, 0.17, 0.16)), sph((0, -0.17, 2.82), 1, (0.09, 0.09, 0.15))], "skull", 0.01, 0.6, 4)
    paint(sk, lambda p, n: mix(BONE_DC, BONEC, smoothstep(-0.5, 0.8, n.z) * 0.7 + 0.25)); setmat(sk, vmat("bonev", 0.6)); P.append(sk)
    for sx in (-1, 1):
        h = tube([(sx * 0.12, -0.02, 3.05), (sx * 0.32, 0.0, 3.08), (sx * 0.42, -0.05, 3.25), (sx * 0.4, -0.08, 3.38)], 0.055, 0.25, 10)
        paint(h, lambda p, n: mix(BONEC, (0.3, 0.26, 0.22), smoothstep(3.15, 3.38, p.z))); setmat(h, vmat("hornv", 0.6)); P.append(h)
        so = sph((sx * 0.07, -0.19, 2.99), 1, (0.05, 0.03, 0.05)); setmat(so, mat("socketd", (0.12, 0.08, 0.1), 0.8)); P.append(so)
    # nó de corda vermelha amarrando o pano
    knot = sph((0, -0.02, 2.62), 1, (0.11, 0.11, 0.09)); setmat(knot, mat("flagknot", FLAG_D, 0.8)); P.append(knot)
    tag(P, "body")
    fl = _flag_mesh(); fl["bone"] = "flag"; P.append(fl)
    return group("war_banner", P)


def war_banner_cfg():
    def wave(p, t, amp, cyc, spd):
        u = max(0.0, (p.x - 0.06) / FLAG_L)
        k = 6.5
        ph = k * u - TAU * t * spd
        A = amp * u ** 1.15
        dy = A * math.sin(ph) + A * 0.35 * math.sin(2.3 * ph + p.z * 3.0)
        dydx = (A * k * math.cos(ph)) / FLAG_L
        dz = -0.12 * u * u * (0.6 + 0.4 * math.sin(ph * 0.5 + 1.0)) if cyc else 0.0
        return dy, dydx, dz

    def deform(p, n, bone, t):
        if bone != "flag":
            return p, n
        if t <= 1.0:
            dy, dydx, dz = wave(p, t, 0.32, True, 2)
        else:
            u_ = t - 1.0
            a, g = atk_curve(u_)
            dy, dydx, dz = wave(p, u_, 0.32 + 0.35 * g - 0.15 * a, True, 3)
            dz += 0.15 * g * max(0.0, (p.x - 0.06) / FLAG_L)
        q = Vector((p.x, p.y + dy, p.z + dz))
        s = 1.0 if n.y >= 0 else -1.0
        nn = Vector((n.x - s * dydx * abs(n.y), n.y, n.z)).normalized()
        return q, nn

    def anim(kind, t):
        if kind == "walk":
            return {"body": rot_about((0, 0, 0), 'Y', math.radians(0.6) * math.sin(TAU * t))}
        a, g = atk_curve(t)
        sh = math.sin(t * 40) * 0.025 * (1 - t)
        return {"body": tr(sh, 0, 0) @ rot_about((0, 0, 0), 'X', math.radians(-3) * a + math.radians(5) * g)}

    def anim2(kind, t):
        d = anim(kind, t)
        d["flag"] = d["body"]
        return d
    return {"anim": anim2, "deform": deform}


# =============================================================== 4. Baú Armadilha

CH_W, CH_D, CH_H = 1.05, 0.72, 0.55
HINGE = Vector((0, CH_D / 2, CH_H))


def trap_chest():
    P = []
    woodm = vmat("woodv", 0.8)
    def wood(p, n):
        band = 0.5 + 0.5 * math.cos(p.z * 26.0)
        return mix(WOOD_D, WOODC, 0.45 + 0.25 * band + 0.2 * smoothstep(-0.4, 0.8, n.z))
    body = box((0, 0, CH_H / 2), (CH_W, CH_D, CH_H), bevel=0.03, seg=2); hard(body); paint(body, wood); setmat(body, woodm); P.append(body)
    # cantoneiras de ferro escuro (largas, como na carta)
    ironm = mat("iron", IRON_D, 0.45, 0.7)
    for sx in (-1, 1):
        for sy in (-1, 1):
            c = box((sx * (CH_W / 2 - 0.05), sy * (CH_D / 2 - 0.05), CH_H / 2), (0.14, 0.14, CH_H + 0.02), bevel=0.015); hard(c); setmat(c, ironm); P.append(c)
    for z in (0.06, CH_H - 0.06):
        b = box((0, 0, z), (CH_W + 0.03, CH_D + 0.03, 0.09), bevel=0.012); hard(b); setmat(b, ironm); P.append(b)
    # brasa dentro (o baú é uma bomba): brilho laranja na fresta
    gl = box((0, 0, CH_H - 0.02), (CH_W - 0.12, CH_D - 0.12, 0.06), bevel=0.0); setmat(gl, glowm("chestglow", FIRE, 6.0)); P.append(gl)
    # moedas no chão (iscas)
    P.append(coin_pile((-0.55, -0.55, 0.0), 0.2, 0.07))
    P.append(coin_pile((0.42, -0.62, 0.0), 0.14, 0.05))
    tag(P, "body")
    # tampa abaulada, com dentes de ferro (armadilha de mandíbula) na borda
    L = []
    lid = cyl((0, 0, CH_H), CH_D / 2 + 0.01, CH_W + 0.02, (0, 90, 0), seg=16, bevel=0.0)
    bm = bmesh.new(); bm.from_mesh(lid.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if (lid.matrix_world @ v.co).z < CH_H - 0.001 and False], context='VERTS')
    bm.to_mesh(lid.data); bm.free()
    apply_mods(lid)
    mk._sel(lid); bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    me = lid.data
    for v in me.vertices:   # metade de baixo do cilindro achatada na borda: tampa em meia-lua
        if v.co.z < 0:
            v.co.z = 0.0
    lid.scale = (1.0, 1.0, 0.75); mk._sel(lid); bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    shade(lid); paint(lid, lambda p, n: mix(WOOD_D, WOODC, 0.55 + 0.25 * smoothstep(0.0, 1.0, n.z))); setmat(lid, woodm); L.append(lid)
    for x in (-0.36, 0.36):
        st = cyl((x, 0, CH_H), CH_D / 2 + 0.035, 0.1, (0, 90, 0), seg=16, bevel=0.0); apply_mods(st)
        mk._sel(st); bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        for v in st.data.vertices:
            if v.co.z < 0:
                v.co.z = 0.0
        st.scale = (1.0, 1.0, 0.78); mk._sel(st); bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        setmat(st, ironm); L.append(st)
    lock = box((0, -CH_D / 2 - 0.03, CH_H - 0.02), (0.2, 0.06, 0.24), bevel=0.02); hard(lock); setmat(lock, mat("brass", (0.75, 0.55, 0.22), 0.4, 0.8)); L.append(lock)
    # dentes de ferro: uma peça só (serrilha) presa na borda da tampa
    teeth = []
    for k in range(7):
        x = -0.42 + k * 0.14
        tt = cyl((x, -CH_D / 2 + 0.06, CH_H - 0.07), 0.055, 0.14, (180, 0, 0), seg=4, bevel=0.0, r2=0.0); apply_mods(tt); teeth.append(tt)
    th = join(teeth, "teeth"); setmat(th, mat("teethiron", (0.62, 0.6, 0.58), 0.4, 0.7)); L.append(th)
    tag(L, "lid"); P += L
    return group("trap_chest", P)


def trap_chest_cfg():
    def anim(kind, t):
        if kind == "walk":
            # a tampa estremece e abre uma fresta (a brasa aparece), duas vezes por volta
            k = pulse(t, 0.05, 0.18, 0.32) * 0.7 + pulse(t, 0.55, 0.62, 0.72) * 1.0
            jit = math.sin(TAU * t * 6) * 0.004
            B = tr(jit, 0, 0)
            return {"body": B, "lid": B @ rot_about(HINGE, 'X', -math.radians(16) * k)}
        a, g = atk_curve(t, 0.3, 0.4)
        hop = 0.1 * g
        B = tr(0, 0, hop) @ scl_about((0, 0, 0), 1 + 0.06 * a, 1 + 0.06 * a, 1 - 0.1 * a)
        return {"body": B, "lid": B @ rot_about(HINGE, 'X', -math.radians(8) * a - math.radians(80) * g)}
    return {"anim": anim}


# =============================================================== 5. Fornalha

def furnace():
    """Plinto de pedra clara, cúpula de ferro preta com a boca acesa e chaminé alta (como na carta)."""
    P = []
    def stone(p, n):
        row = math.floor(p.z / 0.3)
        a = (p.x + p.y) * 2.2 + row * 0.9
        band = 0.5 + 0.5 * math.cos(a * 2.0)
        return mix(STONE_D, STONE_L, 0.35 + 0.25 * band + 0.3 * smoothstep(-0.5, 0.9, n.z))
    base = box((0, 0.05, 0.45), (2.0, 1.8, 0.9), bevel=0.08, seg=2); hard(base); lumpy(base, 0.025, 3.0, 2)
    base = cut(base, cyl((0, -0.9, 0.3), 0.26, 0.6, (90, 0, 0), seg=12, bevel=0.0))
    paint(base, stone); setmat(base, vmat("stonev", 0.85)); P.append(base)
    ash = cyl((0, -0.72, 0.3), 0.25, 0.2, (90, 0, 0), seg=12, bevel=0.0); setmat(ash, darkm()); P.append(ash)
    dome = sph((0, 0.15, 0.9), 1, (0.82, 0.82, 0.95), seg=24)
    bm = bmesh.new(); bm.from_mesh(dome.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.02], context='VERTS')
    bm.to_mesh(dome.data); bm.free()
    shade(dome)
    paint(dome, lambda p, n: mix((0.07, 0.07, 0.09), (0.26, 0.26, 0.31), smoothstep(-0.3, 0.9, n.z) * 0.7 + 0.1)); setmat(dome, vmat("domev", 0.6)); P.append(dome)
    back = sph((0, -0.6, 1.25), 1, (0.42, 0.12, 0.38)); setmat(back, glowm("furnback", (1.0, 0.36, 0.08), 4.0)); P.append(back)
    arch = torus((0, -0.66, 1.25), 0.44, 0.09, (90, 0, 0)); apply_mods(arch); setmat(arch, mat("iron", IRON_D, 0.45, 0.7)); P.append(arch)
    # brasas derramadas na frente do plinto
    coals = fuse([sph((0, -0.72, 0.92), 1, (0.38, 0.22, 0.05)), sph((0.25, -0.82, 0.91), 1, (0.16, 0.12, 0.04))], "coalsin", 0.015, 0.5, 2); setmat(coals, glowm("ember", FIRE, 3.0)); P.append(coals)
    # chaminé alta
    ch = cyl((0, 0.3, 2.15), 0.2, 1.1, seg=10, bevel=0.0); apply_mods(ch)
    paint(ch, lambda p, n: mix((0.07, 0.07, 0.09), (0.25, 0.25, 0.3), 0.5)); setmat(ch, vmat("domev", 0.6)); P.append(ch)
    cap = cyl((0, 0.3, 2.72), 0.28, 0.12, seg=10, bevel=0.0); setmat(cap, mat("iron", IRON_D, 0.45, 0.7)); P.append(cap)
    # monte de carvão e o atiçador encostado
    coal = fuse([sph((0.85, -0.95, 0.0), 1, (0.32, 0.28, 0.18)), sph((1.05, -0.65, 0.0), 1, (0.22, 0.2, 0.13))], "coal", 0.025, 0.4, 2)
    lumpy(coal, 0.04, 6.0, 7); paint(coal, lambda p, n: mix((0.08, 0.07, 0.09), (0.22, 0.2, 0.24), smoothstep(0.2, 1.0, n.z))); setmat(coal, vmat("coalv", 0.9)); P.append(coal)
    tong = tube([(-1.1, -0.3, 0.02), (-1.15, -0.25, 0.9), (-1.12, -0.2, 1.7), (-1.0, -0.22, 1.85)], 0.05, 1.0, 10); setmat(tong, mat("iron", IRON_D, 0.45, 0.7)); P.append(tong)
    tag(P, "body")
    # fogo: três línguas grandes saindo da boca, tremendo em tempos diferentes
    for k, (x, h) in enumerate(FL_X):
        F = flame((x, -0.62, 1.0), 0.2 if k < 2 else 0.26, h, "flame%d" % k)
        tag(F, "fl%d" % k); P += F
    for k in range(4):
        e = sph((0, 0, 0), 1, (0.06, 0.06, 0.07)); setmat(e, glowm("spark", FIRE_L, 8.0)); e.location = (0.05 * (k % 2) - 0.02, 0.3, 2.82)
        tag([e], "sp%d" % k); P.append(e)
    return group("furnace", P)


FL_X = ((-0.2, 0.55), (0.2, 0.6), (0.0, 0.78))
SPARK_PH = (0.0, 0.25, 0.5, 0.75)
SPARK_X = (0.12, -0.15, 0.2, -0.08)


def furnace_cfg():
    def fl(k, t, boost=0.0):
        piv = Vector((FL_X[k][0], -0.62, 1.0))
        ph = TAU * t * (3, 2, 4)[k] + k * 1.7
        sz = 1.0 + 0.16 * math.sin(ph) + 0.06 * math.sin(ph * 2.3) + boost
        sw = math.radians(7) * math.sin(ph * 0.5 + k) if False else math.radians(6) * math.sin(TAU * t * 2 + k * 2.1)
        return rot_about(piv, 'Y', sw) @ scl_about(piv, 1 + 0.4 * boost, 1 + 0.4 * boost, sz)

    def sp(k, t):
        u = (t + SPARK_PH[k]) % 1.0
        base = Vector((0.05 * (k % 2) - 0.02, 0.3, 2.82))
        s = math.sin(math.pi * u)
        tgt = Vector((SPARK_X[k] * u * 3, 0.3 + 0.15 * u, 2.82 + 0.9 * u))
        return Matrix.Translation(tgt - base) @ scl_about(base, max(0.02, s))

    def anim(kind, t):
        d = {}
        if kind == "walk":
            for k in range(3):
                d["fl%d" % k] = fl(k, t)
            for k in range(4):
                d["sp%d" % k] = sp(k, t)
            return d
        a, g = atk_curve(t, 0.25, 0.38)
        for k in range(3):
            d["fl%d" % k] = fl(k, t, 0.9 * g - 0.3 * a)
        for k in range(4):
            d["sp%d" % k] = sp(k, (t * 2) % 1.0)
        d["body"] = scl_about((0, 0, 0), 1 + 0.03 * g, 1 + 0.03 * g, 1 - 0.03 * a + 0.04 * g)
        return d
    return {"anim": anim}


# =============================================================== 6. Ratoeira

TR_HINGE = Vector((0, -0.22, 0.96))
TR_OPEN = 150.0


def rat_trap():
    P = []
    def wood(p, n):
        band = 0.5 + 0.5 * math.cos(p.x * 9.0)
        return mix(WOOD_D, WOODC, 0.45 + 0.25 * band + 0.2 * smoothstep(-0.4, 0.8, n.z))
    plank = box((0, 0, 0.07), (1.6, 1.25, 0.14), bevel=0.02); hard(plank); paint(plank, wood); setmat(plank, vmat("woodv", 0.85)); P.append(plank)
    def rust(p, n):
        k = noise.noise(Vector((p.x * 3, p.y * 3, p.z * 3))) * 0.5 + 0.5
        return mix(RUST_D, RUSTC, 0.3 + 0.5 * k + 0.2 * smoothstep(-0.4, 0.8, n.z))
    rm = vmat("rustv", 0.7)
    # caixa de ferro enferrujado, boca escura em arco na frente
    boxo = box((0, 0.1, 0.55), (1.0, 0.65, 0.82), bevel=0.04); hard(boxo)
    c1 = box((0, -0.3, 0.45), (0.5, 0.4, 0.5), bevel=0.0); boxo = cut(boxo, c1)
    c2 = cyl((0, -0.3, 0.7), 0.25, 0.4, (90, 0, 0), seg=14, bevel=0.0); boxo = cut(boxo, c2)
    paint(boxo, rust); setmat(boxo, rm); P.append(boxo)
    inside = box((0, 0.12, 0.55), (0.48, 0.5, 0.6), bevel=0.0); setmat(inside, darkm()); P.append(inside)
    # mola em espiral grossa na frente, queijo de isca e o arame do gatilho
    for k in range(3):
        sp = torus((-0.25 + k * 0.25, -0.5, 0.2), 0.08, 0.03, (0, 90, 0)); apply_mods(sp); setmat(sp, mat("iron", IRONC, 0.5, 0.6)); P.append(sp)
    spr = cyl((0, -0.5, 0.2), 0.035, 0.7, (0, 90, 0), seg=8, bevel=0.0); setmat(spr, mat("iron", IRONC, 0.5, 0.6)); P.append(spr)
    ch = cyl((0.0, -0.32, 0.2), 0.16, 0.12, seg=3, bevel=0.0); setmat(ch, mat("cheese", (1.0, 0.82, 0.3), 0.6)); P.append(ch)
    # estaca velha atrás (silhueta da carta)
    post = cyl((-0.65, 0.5, 0.75), 0.07, 1.5, (0, -8, 0), seg=6, bevel=0.0); apply_mods(post); lumpy(post, 0.015, 5.0, 1)
    paint(post, wood); setmat(post, vmat("woodv", 0.85)); P.append(post)
    hook = tube([(0.3, 0.3, 0.96), (0.3, 0.35, 1.4), (0.3, 0.1, 1.55), (0.3, -0.08, 1.45)], 0.05, 0.8, 10); setmat(hook, mat("rustd", RUST_D, 0.6, 0.4)); P.append(hook)
    tag(P, "body")
    # porta pesada levantada, presa na dobradiça de cima-trás; gancho por cima
    D = []
    door = box((0, 0, 0), (1.08, 0.08, 0.95), bevel=0.02); hard(door); paint(door, rust); setmat(door, rm)
    M = Matrix.Translation(TR_HINGE) @ Matrix.Rotation(math.radians(TR_OPEN), 4, 'X') @ Matrix.Translation((0, -0.05, -0.47))
    M_([door], M)
    D.append(door)
    tag(D, "door"); P += D
    P += rat((0.62, -0.62, 0.0), math.radians(20), 1.05, "rat1")
    P += rat((-0.55, -0.75, 0.0), math.radians(-25), 1.0, "rat2")
    return group("rat_trap", P)


def rat_trap_cfg():
    def anim(kind, t):
        if kind == "walk":
            jit = math.radians(2.5) * pulse(t, 0.4, 0.45, 0.55) * math.sin(TAU * t * 10)
            return {"door": rot_about(TR_HINGE, 'X', jit),
                    "rat1": rot_about((0.62, -0.62, 0.1), 'X', math.radians(7) * math.sin(TAU * t * 2)),
                    "rat2": rot_about((-0.55, -0.75, 0.1), 'Z', math.radians(10) * math.sin(TAU * t + 1.3))}
        a, g = atk_curve(t, 0.3, 0.38)
        door = rot_about(TR_HINGE, 'X', math.radians(12) * a - math.radians(TR_OPEN - 4) * g)
        sh = tr(math.sin(t * 50) * 0.02 * g, 0, 0)
        return {"door": sh @ door, "body": sh, "rat1": tr(0.2 * g, 0.15 * g, 0), "rat2": tr(-0.2 * g, 0.15 * g, 0)}
    return {"anim": anim}


# =============================================================== 7. Inundação de Esgoto

ARCH_C = Vector((0, -0.35, 0.95))


def sewer_flood():
    P = []
    def brick(p, n):
        row = math.floor(p.z / 0.26)
        col_ = math.floor((p.x + (row % 2) * 0.25) / 0.5)
        v = ((row * 7 + col_ * 13) % 5) / 4.0
        return mix(BRICK_D, BRICK, 0.45 + 0.35 * v + 0.15 * smoothstep(-0.3, 0.8, n.z))
    wall = box((0, 0.1, 1.0), (2.6, 0.5, 2.0), bevel=0.04); hard(wall)
    wall = cut(wall, cyl((0, -0.2, 0.95), 0.62, 1.2, (90, 0, 0), seg=20, bevel=0.0))
    wall = cut(wall, box((0, -0.2, 0.47), (1.24, 1.2, 0.96), bevel=0.0))
    lumpy(wall, 0.02, 2.0, 3)
    paint(wall, brick); setmat(wall, vmat("brickv", 0.85)); P.append(wall)
    def stone(p, n):
        a = math.atan2(p.z - ARCH_C.z, p.x)
        band = 0.5 + 0.5 * math.cos(a * 9.0)
        return mix(STONE_D, STONE, 0.35 + 0.35 * band + 0.2 * smoothstep(-0.5, 0.8, n.z))
    ring = torus((0, -0.2, 0.95), 0.72, 0.17, (90, 0, 0)); ring.scale = (1, 1.25, 1)
    apply_mods(ring); mk._sel(ring); bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bm = bmesh.new(); bm.from_mesh(ring.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.5], context='VERTS')
    bm.to_mesh(ring.data); bm.free()
    for sx in (-1, 1):   # pés do arco
        pf = box((sx * 0.72, -0.2, 0.25), (0.34, 0.5, 0.5), bevel=0.03); hard(pf); paint(pf, stone); setmat(pf, vmat("stonev", 0.85)); P.append(pf)
    paint(ring, stone); setmat(ring, vmat("stonev", 0.85)); P.append(ring)
    tunnel = cyl((0, 0.05, 0.95), 0.6, 0.4, (90, 0, 0), seg=18, bevel=0.0); setmat(tunnel, darkm()); P.append(tunnel)
    tunb = box((0, 0.05, 0.47), (1.2, 0.4, 0.95), bevel=0.0); setmat(tunb, darkm()); P.append(tunb)
    # grade de ferro em meia-lua por cima do arco
    gr = []
    for k in range(5):
        x = -0.4 + k * 0.2
        h = 0.32 - abs(x) * 0.35
        b = cyl((x, -0.3, 1.95 + h / 2), 0.04, h + 0.1, seg=6, bevel=0.0); apply_mods(b); gr.append(b)
    arc = tube([(-0.5, -0.3, 1.92), (-0.3, -0.3, 2.22), (0.3, -0.3, 2.22), (0.5, -0.3, 1.92)], 0.05, 1.0, 14)
    grate = join(gr + [arc], "grate"); setmat(grate, mat("iron", IRON_D, 0.45, 0.6)); P.append(grate)
    tag(P, "body")
    # água verde: cai da boca e espalha numa poça
    W = []
    path = [(0, -0.05, 0.5), (0, -0.35, 0.47), (0, -0.6, 0.36), (0, -0.78, 0.2), (0, -0.92, 0.06)]
    blobs = []
    for k, q in enumerate(path):
        nxt = path[min(k + 1, len(path) - 1)]; prv = path[max(k - 1, 0)]
        ang = math.degrees(math.atan2(nxt[2] - prv[2], -(nxt[1] - prv[1])))
        blobs.append(sph(q, 1, (0.5 + 0.06 * k, 0.2, 0.08), (-ang, 0, 0)))
    fall = fuse(blobs, "fall", 0.025, 0.6, 4)
    paint(fall, lambda p, n: mix(SEWER_D, SEWER, 0.55 + 0.45 * smoothstep(0.0, 0.9, n.z)))
    setmat(fall, mat("sewerv", vcol=True, rough=0.2, emit=0.0)); W.append(fall)
    pool = fuse([sph((0, -1.25, 0.0), 1, (1.35, 0.8, 0.07)), sph((0.75, -1.6, 0.0), 1, (0.6, 0.45, 0.05)), sph((-0.8, -1.5, 0.0), 1, (0.65, 0.5, 0.05))], "pool", 0.03, 0.6, 4)
    paint(pool, lambda p, n: mix(SEWER_D, SEWER, 0.6 + 0.4 * smoothstep(0.6, 1.0, n.z))); setmat(pool, mat("sewerv", vcol=True, rough=0.2)); W.append(pool)
    tag(W, "water"); P += W
    # brilho tóxico: gotas que brilham na queda
    for k in range(3):
        g = sph((0.25 * (k - 1), -0.6, 0.35), 1, (0.07, 0.07, 0.07)); setmat(g, glowm("toxglow", FUME, 3.0)); tag([g], "drop%d" % k); P.append(g)
    # fumaça verde: duas nuvens que sobem pelos lados
    for k, x in enumerate((-0.85, 0.75)):
        f = fuse([sph((x, -0.55, 1.2), 1, (0.26, 0.2, 0.22)), sph((x + 0.15, -0.55, 1.42), 1, (0.2, 0.16, 0.18))], "fume", 0.02, 0.6, 3)
        setmat(f, mat("fumeg", FUME, 0.9, emit=0.7)); tag([f], "fume%d" % k); P.append(f)
    # ratos nadando
    P += rat((0.6, -1.35, -0.05), math.radians(-30), 1.0, "rat1")
    P += rat((-0.55, -1.5, -0.05), math.radians(25), 0.95, "rat2")
    return group("sewer_flood", P)


def sewer_flood_cfg():
    def deform(p, n, bone, t):
        if bone != "water":
            return p, n
        tt = t if t <= 1.0 else (t - 1.0)
        amp = 0.03 if t <= 1.0 else 0.03 + 0.05 * atk_curve(tt)[1]
        s = -p.y * 1.0 + (0.6 - p.z)
        r = math.hypot(p.x, p.y + 1.25)
        if p.z > 0.06:
            w = amp * math.sin(9.0 * s - TAU * tt * 3)
        else:
            w = amp * 0.8 * math.sin(7.0 * r - TAU * tt * 2) * smoothstep(0.0, 0.25, r)
        return Vector((p.x, p.y, p.z)) + n * w, n

    def anim(kind, t):
        d = {}
        tt = t
        for k in range(3):
            u = (tt * 2 + k / 3.0) % 1.0
            base = Vector((0.25 * (k - 1), -0.6, 0.35))
            tgt = Vector((base.x * 1.3, -0.6 - 0.45 * u, 0.42 - 0.38 * u * u))
            d["drop%d" % k] = Matrix.Translation(tgt - base) @ scl_about(base, max(0.05, math.sin(math.pi * u)))
        for k, x in enumerate((-0.85, 0.75)):
            u = (tt + k * 0.5) % 1.0
            c = Vector((x, -0.55, 1.3))
            d["fume%d" % k] = tr(0.1 * u * (1 if x > 0 else -1), 0, 0.6 * u) @ scl_about(c, max(0.05, math.sin(math.pi * u) * (0.7 + 0.6 * u)))
        if kind == "walk":
            d["rat1"] = tr(0, 0, 0.03 * math.sin(TAU * t * 2)) @ rot_about((0.6, -1.35, 0.1), 'Y', math.radians(6) * math.sin(TAU * t))
            d["rat2"] = tr(0, 0, 0.03 * math.sin(TAU * t * 2 + 2.0)) @ rot_about((-0.55, -1.5, 0.1), 'Y', math.radians(6) * math.sin(TAU * t + 1.0))
            return d
        a, g = atk_curve(t)
        d["rat1"] = tr(0.1 * g, -0.4 * g, 0.05 * g)
        d["rat2"] = tr(-0.1 * g, -0.4 * g, 0.05 * g)
        d["water"] = scl_about((0, -0.3, 0), 1 + 0.12 * g, 1 + 0.2 * g, 1 + 0.4 * g)
        return d
    return {"anim": anim, "deform": deform}


# =============================================================== 8. Mina de Ouro

def gold_mine():
    P = []
    def rock(p, n):
        k = noise.noise(Vector((p.x * 1.3, p.y * 1.3, p.z * 1.3))) * 0.5 + 0.5
        return mix(STONE_D, STONE_L, smoothstep(-0.3, 0.9, n.z) * 0.55 + k * 0.3)
    hill = fuse([sph((0, 0.35, 0.0), 1, (1.45, 1.1, 1.7)), sph((-0.95, 0.15, 0.0), 1, (0.75, 0.8, 1.15)),
                 sph((1.0, 0.3, 0.0), 1, (0.7, 0.75, 1.3)), sph((0.35, 0.6, 1.2), 1, (0.75, 0.6, 0.75)),
                 sph((-1.25, -0.4, 0.0), 1, (0.45, 0.45, 0.5)), sph((1.3, -0.35, 0.0), 1, (0.4, 0.45, 0.42))], "hill", 0.045, 0.3, 2)
    lumpy(hill, 0.14, 1.1, 4)
    # facetas largas de pedra: decimar e deixar os planos duros
    dm = hill.modifiers.new("d", 'DECIMATE'); dm.ratio = 0.04; apply_mods(hill)
    for pl in hill.data.polygons:
        pl.use_smooth = False
    hill = cut(hill, sph((0, -0.75, 0.55), 1, (0.7, 0.9, 0.85)))
    paint(hill, rock); setmat(hill, vmat("rockv", 0.85)); P.append(hill)
    cave = sph((0, -0.35, 0.55), 1, (0.62, 0.5, 0.75)); setmat(cave, darkm()); P.append(cave)
    # escoras de madeira na boca da mina
    wm = vmat("woodv", 0.85)
    def wood(p, n):
        return mix(WOOD_D, WOODC, 0.5 + 0.3 * smoothstep(-0.4, 0.8, n.z))
    for sx in (-1, 1):
        b = box((sx * 0.62, -0.72, 0.62), (0.16, 0.16, 1.24), (0, sx * 4, 0), bevel=0.02); hard(b); paint(b, wood); setmat(b, wm); P.append(b)
    top = box((0, -0.74, 1.28), (1.55, 0.18, 0.18), bevel=0.02); hard(top); paint(top, wood); setmat(top, wm); P.append(top)
    # ouro derramando da boca (montes grandes, chapados) e carrinho cheio
    gold = fuse([sph((0.15, -0.7, 0.0), 1, (0.55, 0.42, 0.3)), sph((0.55, -1.05, 0.0), 1, (0.42, 0.35, 0.2)),
                 sph((-0.3, -1.05, 0.0), 1, (0.35, 0.3, 0.15)), sph((0.95, -1.3, 0.0), 1, (0.25, 0.22, 0.1))], "gold", 0.025, 0.3, 2)
    lumpy(gold, 0.045, 5.0, 6)
    paint(gold, lambda p, n: mix(GOLD_D, GOLDC, smoothstep(-0.2, 0.9, n.z) * 0.8 + 0.2)); setmat(gold, mat("goldv", vcol=True, rough=0.35, metal=0.6, emit=0.0)); P.append(gold)
    tag(P, "body")
    C = []
    cart = box((-0.85, -1.0, 0.4), (0.75, 0.55, 0.42), (0, 0, 15), bevel=0.03, taper=(1.18, 1.18)); hard(cart)
    paint(cart, lambda p, n: mix(IRON_D, (0.45, 0.42, 0.42), 0.45 + 0.3 * smoothstep(-0.4, 0.8, n.z))); setmat(cart, vmat("cartv", 0.6)); C.append(cart)
    load = coin_pile((-0.85, -1.0, 0.6), 0.36, 0.18, "cartgold"); C.append(load)
    for (dx, dy) in ((-0.25, -0.22), (0.25, -0.22), (-0.25, 0.22), (0.25, 0.22)):
        q = Matrix.Rotation(math.radians(15), 4, 'Z') @ Vector((dx, dy, 0))
        w = cyl((-0.85 + q.x, -1.0 + q.y, 0.13), 0.13, 0.08, (0, 90, 15), seg=10, bevel=0.0); setmat(w, mat("iron", IRON_D, 0.45, 0.6)); C.append(w)
    tag(C, "cart"); P += C
    # brilhos: estrelas de quatro pontas que acendem e apagam
    for k, loc in enumerate(((0.3, -0.95, 0.42), (-0.85, -1.05, 0.85), (0.75, -1.25, 0.28), (-0.05, -0.8, 0.62))):
        st = []
        for r_ in ((0, 0, 0), (0, 0, 90)):
            b = box(loc, (0.26, 0.04, 0.05), (0, 0, 0), bevel=0.0, taper=None)
            b.rotation_euler = (math.radians(90), math.radians(r_[2]), 0); apply_mods(b); st.append(b)
        s = join(st, "spark"); setmat(s, glowm("goldspark", (1.0, 0.95, 0.65), 8.0)); tag([s], "gs%d" % k); P.append(s)
    return group("gold_mine", P)


GS_LOC = ((0.3, -0.95, 0.42), (-0.85, -1.05, 0.85), (0.75, -1.25, 0.28), (-0.05, -0.8, 0.62))


def gold_mine_cfg():
    def anim(kind, t):
        d = {}
        for k, loc in enumerate(GS_LOC):
            u = (t + k * 0.25) % 1.0
            s = pulse(u, 0.0, 0.12, 0.3)
            d["gs%d" % k] = scl_about(loc, max(0.03, s)) @ rot_about(loc, 'Y', 0.0)
        if kind == "walk":
            d["cart"] = rot_about((-0.85, -1.0, 0.0), 'X', math.radians(1.5) * math.sin(TAU * t))
            return d
        a, g = atk_curve(t)
        d["cart"] = tr(0, 0, 0.12 * g) @ rot_about((-0.85, -1.0, 0.0), 'Y', math.radians(8) * g)
        d["body"] = scl_about((0, 0, 0), 1, 1, 1 - 0.03 * a + 0.03 * g)
        for k, loc in enumerate(GS_LOC):
            d["gs%d" % k] = scl_about(loc, max(0.03, 1.4 * g))
        return d
    return {"anim": anim}


# =============================================================== 9. Armadilha de Espinhos

SPK = [(-0.42, -0.3, 1.05, 4), (0.0, -0.4, 1.2, -3), (0.42, -0.28, 1.1, 6), (-0.25, 0.12, 1.15, -6),
       (0.22, 0.1, 1.25, 3), (-0.48, 0.42, 0.95, 8), (0.48, 0.4, 1.0, -8), (0.0, 0.45, 1.05, 0)]


def spike_trap():
    P = []
    def dirt(p, n):
        k = noise.noise(Vector((p.x * 2.2, p.y * 2.2, 0))) * 0.5 + 0.5
        return mix(DIRT_D, DIRT_L, 0.25 + 0.45 * k * smoothstep(0.3, 1.0, n.z))
    pit = fuse([sph((0, 0, 0.0), 1, (1.0, 0.95, 0.1)), sph((0.4, -0.45, 0.0), 1, (0.45, 0.4, 0.07)), sph((-0.5, 0.4, 0.0), 1, (0.45, 0.45, 0.08))], "pit", 0.03, 0.6, 3)
    lumpy(pit, 0.025, 3.0, 2); paint(pit, dirt); setmat(pit, vmat("dirtv", 0.95)); P.append(pit)
    # moldura de tábuas quebradas em volta
    wm = vmat("woodv", 0.85)
    def wood(p, n):
        return mix(WOOD_D, WOODC, 0.5 + 0.3 * smoothstep(-0.4, 0.8, n.z))
    for (x, y, sx, sy, r) in ((0, -0.78, 1.5, 0.2, 3), (0, 0.8, 1.4, 0.2, -4), (-0.8, 0, 0.2, 1.3, 2), (0.82, 0.02, 0.2, 1.2, -3)):
        b = box((x, y, 0.06), (sx, sy, 0.1), (0, 0, r), bevel=0.02); hard(b); paint(b, wood); setmat(b, wm); P.append(b)
    hole = fuse([sph((0, 0, 0.02), 1, (0.65, 0.65, 0.03))], "holes", 0.02, 0.5, 2); setmat(hole, mat("pitd", (0.1, 0.07, 0.06), 0.95)); P.append(hole)
    tag(P, "body")
    # estacas apontadas (sobem do chão)
    S = []
    for k, (x, y, h, lean) in enumerate(SPK):
        a = (x, y, -0.25)
        b = (x + math.sin(math.radians(lean)) * 0.2, y - 0.05, h)
        s = stake(a, b, 0.12)
        paint(s, lambda p, n: mix(WOOD_D, WOOD_L, smoothstep(0.1, 0.9, p.z) * 0.6 + 0.2 * smoothstep(-0.4, 0.8, n.z)))
        setmat(s, vmat("stakev", 0.8)); S.append(s)
    tag(S, "spikes"); P += S
    return group("spike_trap", P)


def spike_trap_cfg():
    def anim(kind, t):
        if kind == "walk":
            # t=0 no alto; recolhe até 45%, espera, encolhe um pouco (antecipação) e salta de volta no fim
            if t < 0.25:
                h = 1.0 - 0.55 * ease(t / 0.25)
            elif t < 0.75:
                h = 0.45 + 0.02 * math.sin(TAU * (t - 0.25) * 4)
            elif t < 0.88:
                h = 0.45 - 0.12 * ease((t - 0.75) / 0.13)
            else:
                h = 0.33 + 0.67 * ease((t - 0.88) / 0.12)
            return {"spikes": tr(0, 0, -(1.0 - h) * 0.9)}
        a, g = atk_curve(t, 0.3, 0.36)
        h = 0.45 - 0.15 * a + 0.55 * g + 0.15 * g * (1 - g)
        sh = math.sin(t * 60) * 0.015 * g
        return {"spikes": tr(sh, 0, -(1.0 - min(h, 1.1)) * 0.9), "body": tr(sh * 0.5, 0, 0)}
    return {"anim": anim}


# =============================================================== 10. Covil da Matilha

def pack_den():
    P = []
    rng = random.Random(4)
    stones, ctrs = [], []
    for ring_i, (zr, rr, n) in enumerate(((0.12, 1.5, 14), (0.45, 1.42, 13), (0.8, 1.22, 12), (1.1, 0.92, 10), (1.33, 0.52, 6), (1.45, 0.0, 1))):
        for k in range(n):
            a = k / n * TAU + ring_i * 0.4 + rng.uniform(-0.1, 0.1)
            s_ = rng.uniform(0.85, 1.15)
            c = (math.cos(a) * rr, math.sin(a) * rr * 0.95, zr)
            ctrs.append((Vector(c), rng.random()))
            stones.append(sph(c, 1, (0.36 * s_, 0.3 * s_, 0.2 * s_), (rng.uniform(-15, 15), 0, math.degrees(a) + 90)))
    stones.append(sph((0, 0, 0.45), 1, (1.35, 1.3, 0.95)))
    dome = fuse(stones, "cairn", 0.035, 0.15, 1)
    dome = cut(dome, sph((0, -1.4, 0.3), 1, (0.72, 0.85, 0.72)))

    def slate(p, n):
        best, val, d2 = 9.0, 0.5, 9.0
        for c, v in ctrs:
            d = (p - c).length
            if d < best:
                d2 = best; best, val = d, v
            elif d < d2:
                d2 = d
        seam = smoothstep(0.08, 0.0, d2 - best)
        base = mix((0.27, 0.27, 0.31), (0.55, 0.55, 0.58), 0.25 + 0.5 * val + 0.25 * smoothstep(-0.3, 0.9, n.z))
        return mix(base, (0.12, 0.12, 0.15), seam * 0.8)
    paint(dome, slate); setmat(dome, vmat("slatev", 0.85)); P.append(dome)
    inside = sph((0, -0.75, 0.35), 1, (0.62, 0.12, 0.55)); setmat(inside, darkm()); P.append(inside)
    # chão batido na frente
    apron = fuse([sph((0, -1.45, 0.0), 1, (0.8, 0.5, 0.06))], "apron", 0.03, 0.5, 3); lumpy(apron, 0.02, 3.0, 2)
    paint(apron, lambda p, n: mix((0.55, 0.45, 0.32), (0.72, 0.62, 0.45), 0.5)); setmat(apron, vmat("sandv", 0.95)); P.append(apron)
    # árvore seca no topo
    tw = mat("deadwood", (0.3, 0.24, 0.22), 0.85)
    tr_ = tube([(0.1, 0.15, 1.5), (0.0, 0.1, 2.0), (0.12, 0.05, 2.5), (0.05, 0.0, 2.9)], 0.11, 0.35, 12); setmat(tr_, tw); P.append(tr_)
    for (b, c) in (((0.05, 0.08, 2.25), (0.5, 0.0, 2.75)), ((0.08, 0.05, 2.45), (-0.4, 0.1, 2.95)), ((0.1, 0.1, 2.0), (-0.45, 0.0, 2.3))):
        br = tube([b, ((b[0] + c[0]) / 2, (b[1] + c[1]) / 2, (b[2] + c[2]) / 2 + 0.05), c], 0.06, 0.35, 8); setmat(br, tw); P.append(br)
    tag(P, "body")
    # olhos no escuro e um filhote espiando
    P += glow_pair((-0.22, -0.9, 0.5), 0.07, 0.04, (1.0, 0.92, 0.6), "wolfglow", "eyes0")
    P += glow_pair((0.25, -0.9, 0.36), 0.07, 0.04, (1.0, 0.92, 0.6), "wolfglow", "eyes1")
    W = []
    def fur(p, n):
        return mix(WOLF_D, WOLF, smoothstep(-0.4, 0.8, n.z) * 0.7 + 0.3)
    pup = fuse([sph((0, -1.0, 0.25), 1, (0.2, 0.24, 0.18)), sph((0, -1.22, 0.3), 1, (0.17, 0.16, 0.15)),
                sph((0, -1.38, 0.26), 1, (0.08, 0.1, 0.07)),
                cyl((-0.1, -1.18, 0.47), 0.06, 0.16, (10, -15, 0), seg=4, bevel=0.0, r2=0.005),
                cyl((0.1, -1.18, 0.47), 0.06, 0.16, (10, 15, 0), seg=4, bevel=0.0, r2=0.005)], "pup", 0.012, 0.5, 3)
    paint(pup, fur); setmat(pup, vmat("wolfv", 0.85)); W.append(pup)
    nose = sph((0, -1.47, 0.29), 1, (0.04, 0.035, 0.03)); setmat(nose, mat("nose", (0.12, 0.1, 0.12), 0.4)); W.append(nose)
    for sx in (-1, 1):
        e = sph((sx * 0.075, -1.33, 0.36), 1, (0.03, 0.02, 0.035)); setmat(e, mat("eye", DARK, 0.3)); W.append(e)
    tag(W, "pup"); P += W
    return group("pack_den", P)


def pack_den_cfg():
    def anim(kind, t):
        d = {}
        if kind == "walk":
            k = pulse(t, 0.15, 0.4, 0.8)
            d["pup"] = tr(0, -0.14 * k, 0.0) @ rot_about((0, -1.1, 0.25), 'Z', math.radians(14) * math.sin(TAU * t * 2) * k)
            d["eyes0"] = scl_about((-0.22, -0.9, 0.5), 1, 1, 1 - 0.95 * pulse(t, 0.45, 0.5, 0.56))
            d["eyes1"] = scl_about((0.25, -0.9, 0.36), 1, 1, 1 - 0.95 * pulse(t, 0.85, 0.9, 0.96))
            return d
        a, g = atk_curve(t)
        d["pup"] = tr(0, 0.1 * a - 0.45 * g, 0.06 * g) @ rot_about((0, -1.1, 0.25), 'X', math.radians(-18) * g)
        return d
    return {"anim": anim}


CFG = {"rat_burrow": rat_burrow_cfg, "barricade": barricade_cfg, "war_banner": war_banner_cfg, "trap_chest": trap_chest_cfg,
       "furnace": furnace_cfg, "rat_trap": rat_trap_cfg, "sewer_flood": sewer_flood_cfg, "gold_mine": gold_mine_cfg,
       "spike_trap": spike_trap_cfg, "pack_den": pack_den_cfg}


def build(i):
    return globals()[i]()


def cfg(i):
    return CFG[i]()
