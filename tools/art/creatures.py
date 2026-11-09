"""Monstros e herói, em 4 estilos (looks). Coordenadas da Godot: +Y cima, frente -Z.

Cada função recebe (m: Model, L: Look) e monta o modelo. O Look muda proporções (cabeça, membros),
paleta, olhos e enfeites; o shader de cada look (game/art/look_*.gdshader) faz o resto.
"""
import colorsys
import math

from kit import Model, darken, glow, lighten, mix


class Look:
    def __init__(self, idx, name, head, limb, spiky, eyes, sat, val, tint, style, budget_k=1.0, res_k=1.0):
        self.idx = idx
        self.name = name
        self.head = head      # escala das cabeças
        self.limb = limb      # espessura dos membros
        self.spiky = spiky    # enfeites agressivos (espinhos, placas)
        self.eyes = eyes      # "cute" (esclera + pupila + brilho), "dot" (pretos), "glow" (emissivos)
        self.sat = sat
        self.val = val
        self.tint = tint
        self.style = style    # parâmetros da pintura por vértice (kit.Model.build)
        self.budget_k = budget_k
        self.res_k = res_k

    def c(self, c, a=None):
        """Cor da paleta do look."""
        h, l, s = colorsys.rgb_to_hls(*c[:3])
        s = min(1.0, s * self.sat)
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        r, g, b = (min(1.0, x * self.val) for x in (r, g, b))
        r, g, b = mix((r, g, b), self.tint[:3], self.tint[3])
        alpha = c[3] if len(c) > 3 else 1.0
        return (r, g, b, alpha if a is None else a)


LOOKS = {
    1: Look(1, "argila", head=1.3, limb=1.15, spiky=False, eyes="cute", sat=1.05, val=1.05, tint=(1.0, 0.85, 0.7, 0.06),
            style=dict(ao=0.55, ao_pow=1.2, sky=0.18, height=0.08, edge=0.0, noise=0.0, hue=0.5, cool=(0.7, 0.5, 0.6), warm=(1.0, 0.9, 0.75))),
    2: Look(2, "cartum", head=1.22, limb=1.1, spiky=False, eyes="cute", sat=1.3, val=1.08, tint=(1, 1, 1, 0.0),
            style=dict(ao=0.25, ao_pow=1.0, sky=0.05, height=0.0, edge=0.0, noise=0.0)),
    3: Look(3, "pintado", head=1.05, limb=1.0, spiky=False, eyes="dot", sat=1.1, val=1.0, tint=(1.0, 0.92, 0.75, 0.05),
            style=dict(ao=0.75, ao_pow=1.1, sky=0.4, height=0.35, edge=0.6, noise=0.03, noise_freq=4.0, hue=1.0, cool=(0.45, 0.4, 0.85), warm=(1.0, 0.9, 0.65))),
    4: Look(4, "sombrio", head=0.92, limb=0.92, spiky=True, eyes="glow", sat=0.62, val=0.78, tint=(0.45, 0.5, 0.7, 0.1),
            style=dict(ao=0.65, ao_pow=1.3, sky=0.25, height=0.35, edge=0.4, noise=0.04, noise_freq=8.0)),
}

WHITE = (0.97, 0.96, 0.92)
DARK = (0.08, 0.06, 0.1)
BONE = (0.9, 0.85, 0.72)
GOLD = (1.0, 0.76, 0.26)
WOOD = (0.48, 0.3, 0.17)
STEEL = (0.74, 0.77, 0.85)
PINK = (0.95, 0.58, 0.64)


# ------------------------------------------------------------------ peças comuns

def eyes(m, L, y, z, dx, r, iris=(0.15, 0.1, 0.1), glowc=(1.0, 0.3, 0.1), yaw=0.0, angry=False):
    """Par de olhos na frente (-Z). yaw abre os olhos para os lados."""
    for sx in (-1.0, 1.0):
        x = sx * dx
        zz = z + abs(math.sin(math.radians(yaw))) * 0.0
        if L.eyes == "glow":
            m.hard("sphere", (x, y, zz), (r * 0.95, r * 0.55, r * 0.5), glow(L.c(glowc)), rot=(0, 0, sx * (-18 if angry else 0)), seg=12)
            m.hard("sphere", (x, y, zz + r * 0.25), (r * 1.25, r * 0.9, r * 0.6), L.c(DARK), seg=12)
        elif L.eyes == "dot":
            m.hard("sphere", (x, y, zz), (r * 0.85, r, r * 0.6), L.c(WHITE), seg=14)
            m.hard("sphere", (x * 1.02, y - r * 0.08, zz - r * 0.38), (r * 0.55, r * 0.65, r * 0.35), L.c(iris), seg=12)
            m.hard("sphere", (x * 1.02 - r * 0.15, y + r * 0.2, zz - r * 0.6), r * 0.15, WHITE, seg=8)
        else:  # cute
            rr = r * 1.15
            m.hard("sphere", (x, y, zz), (rr, rr * 1.1, rr * 0.7), L.c(WHITE), seg=16)
            m.hard("sphere", (x * 1.02, y - rr * 0.08, zz - rr * 0.42), (rr * 0.62, rr * 0.72, rr * 0.4), L.c(iris), seg=14)
            m.hard("sphere", (x * 1.02 - rr * 0.2, y + rr * 0.25, zz - rr * 0.72), rr * 0.2, WHITE, seg=8)
        if angry and L.eyes != "glow":
            m.hard("box", (x, y + r * 1.15, z - r * 0.2), (r * 2.2, r * 0.45, r * 0.5), L.c(DARK), rot=(0, 0, sx * 22), bevel=0.01)


def finish(m, L, budget=2500, res=0.03):
    m.style = dict(L.style)
    m.res = res / L.res_k
    m.blob_budget = int(budget * L.budget_k)
    m.detail = min(1.0, max(0.45, budget / 3000.0))
    return m


# ------------------------------------------------------------------ ratos

def rat(m, L, s=1.0, king=False):
    fur = L.c((0.44, 0.39, 0.37))
    belly = L.c((0.72, 0.64, 0.58))
    h = L.head
    if L.idx == 4:
        fur = L.c((0.34, 0.3, 0.32))
    # Corpo em gota, mais alto atrás.
    m.ell((0, 0.3 * s, 0.12 * s), (0.3 * s, 0.27 * s, 0.4 * s), fur, rot=(-8, 0, 0))
    m.ell((0, 0.27 * s, -0.12 * s), (0.25 * s, 0.24 * s, 0.25 * s), fur)
    # Cabeça e focinho.
    hc = (0, 0.42 * s, -0.36 * s)
    m.ball(hc, 0.22 * s * h, fur)
    m.ell((0, 0.38 * s, -0.36 * s - 0.24 * s * h), (0.1 * s * h, 0.1 * s * h, 0.17 * s * h), fur, rot=(-10, 0, 0))
    m.paint((0, 0.2 * s, -0.05 * s), (0.22 * s, 0.14 * s, 0.38 * s), belly, soft=0.6)
    m.paint((0, 0.33 * s, -0.36 * s - 0.25 * s * h), (0.1 * s * h, 0.08 * s * h, 0.12 * s * h), belly, soft=0.7)
    nose_z = -0.36 * s - 0.42 * s * h
    m.hard("sphere", (0, 0.39 * s, nose_z), 0.045 * s * h, L.c(PINK), seg=10)
    # Bigodes.
    for sx in (-1, 1):
        for k in (-1, 1):
            m.hard("cyl", (sx * 0.13 * s * h, 0.37 * s + k * 0.015 * s, nose_z + 0.06 * s), (0.004 * s, 0.004 * s, 0.22 * s * h), L.c(WHITE), rot=(0, 0, sx * (80 + k * 10)), bevel=0, seg=4)
    # Orelhas grandes (disco com interior rosa).
    for sx in (-1.0, 1.0):
        er = 0.13 * s * (h ** 1.2)
        ep = (sx * 0.15 * s * h, 0.42 * s + 0.2 * s * h, -0.3 * s)
        m.hard("cyl", ep, (er, er, 0.035 * s), fur, rot=(80, sx * -20, sx * 25), bevel=0.01, seg=20)
        m.hard("cyl", (ep[0] * 1.02, ep[1], ep[2] - 0.018 * s), (er * 0.68, er * 0.68, 0.02 * s), L.c(PINK), rot=(80, sx * -20, sx * 25), bevel=0, seg=20)
        if L.spiky:
            m.hard("spike", (ep[0], ep[1] + er * 0.6, ep[2]), (0.03 * s, 0.12 * s, 0.4), L.c((0.2, 0.18, 0.2)), rot=(-10, 0, sx * -25), seg=8)
    # Patas.
    for sx in (-1.0, 1.0):
        for z in (-0.2 * s, 0.26 * s):
            m.ball((sx * 0.16 * s, 0.07 * s, z), 0.075 * s * L.limb, L.c(PINK), group="feet")
    eyes(m, L, 0.5 * s, -0.36 * s - 0.17 * s * h, 0.09 * s * h, 0.052 * s * h, iris=(0.55, 0.05, 0.05), glowc=(1.0, 0.2, 0.15), angry=not king and L.idx == 4)
    # Dentões.
    m.hard("box", (0, 0.31 * s, nose_z + 0.08 * s), (0.06 * s, 0.07 * s, 0.02 * s), L.c(WHITE), rot=(-10, 0, 0), bevel=0.006)
    # Rabo em curva.
    pts = []
    for i in range(7):
        t = i / 6
        pts.append((math.sin(t * 2.4) * 0.18 * s, 0.22 * s + math.sin(t * 3.0) * 0.12 * s, 0.48 * s + t * 0.6 * s))
    for i in range(6):
        m.hard("cyl", tuple((pts[i][k] + pts[i + 1][k]) / 2 for k in range(3)), (0.022 * s * (1 - i / 7), 0.03 * s * (1 - i / 7), math.dist(pts[i], pts[i + 1]) * 1.15), L.c(PINK),
               rot=(math.degrees(math.atan2(pts[i + 1][2] - pts[i][2], pts[i + 1][1] - pts[i][1])), 0, -math.degrees(math.atan2(pts[i + 1][0] - pts[i][0], pts[i + 1][1] - pts[i][1])) * 0.5), bevel=0, seg=8)
    if L.spiky:
        for i in range(4):
            m.hard("spike", (0, 0.5 * s + (0.03 if i else 0.02) * s, -0.12 * s + i * 0.14 * s), (0.04 * s, 0.14 * s, -0.3), L.c((0.2, 0.17, 0.2)), rot=(-20, 0, 0), seg=8)
    if king:
        crown = L.c(GOLD)
        cy = 0.42 * s + 0.24 * s * h
        m.hard("cyl", (0, cy, -0.34 * s), (0.15 * s, 0.13 * s, 0.11 * s), crown, metal=1.0, rough=0.3, bevel=0.01, seg=20)
        for i in range(5):
            a = math.tau * i / 5
            m.hard("cone", (math.cos(a) * 0.13 * s, cy + 0.1 * s, -0.34 * s + math.sin(a) * 0.13 * s), (0.04 * s, 0.11 * s), crown, metal=1.0, rough=0.3, seg=8)
            m.hard("sphere", (math.cos(a) * 0.15 * s, cy + 0.01 * s, -0.34 * s + math.sin(a) * 0.15 * s), 0.022 * s, glow(L.c((1, 0.2, 0.35))), seg=8)
        # Manto vermelho com gola de arminho.
        m.ell((0, 0.42 * s, 0.14 * s), (0.36 * s, 0.12 * s, 0.4 * s), L.c((0.62, 0.08, 0.18)), rot=(-14, 0, 0), group="cape")
        m.ell((0, 0.5 * s, -0.16 * s), (0.3 * s, 0.08 * s, 0.1 * s), L.c(WHITE), group="cape")
        for i in range(5):
            m.paint(((i - 2) * 0.1 * s, 0.52 * s, -0.2 * s), 0.025 * s, L.c(DARK), soft=0.3, only="cape")
        # Cetro.
        m.hard("cyl", (0.32 * s, 0.38 * s, -0.42 * s), (0.015 * s, 0.015 * s, 0.6 * s), crown, metal=1.0, rough=0.35, rot=(-15, 0, -10), seg=8)
        m.hard("sphere", (0.37 * s, 0.68 * s, -0.5 * s), 0.05 * s, glow(L.c((1, 0.3, 0.4))), seg=12)
    return finish(m, L, budget=1800 if not king else 3200, res=0.022 * s)


def bat(m, L):
    body = L.c((0.42, 0.24, 0.55))
    wing = darken(L.c((0.42, 0.24, 0.55)), 0.3)
    mem = L.c((0.62, 0.32, 0.55)) if L.idx != 4 else L.c((0.3, 0.2, 0.32))
    h = L.head
    m.ell((0, -0.02, 0.04), (0.17, 0.2, 0.18), body)
    m.ball((0, 0.13, -0.1), 0.15 * h, body)
    m.paint((0, -0.02, -0.12), (0.1, 0.14, 0.1), lighten(body, 0.25), soft=0.6)
    for sx in (-1.0, 1.0):
        # Orelhas grandes.
        m.hard("spike", (sx * 0.08 * h, 0.22 * h, -0.08), (0.06 * h, 0.2 * h, 0.15), body, rot=(-5, 0, sx * -18), seg=10)
        # Asa: osso + membrana em leque (fora de |x| 0,18 para o shader bater).
        root = (sx * 0.14, 0.04, 0.0)
        tip = [(sx * 0.5, 0.18, -0.02), (sx * 0.78, 0.1, 0.02), (sx * 0.72, -0.06, 0.12), (sx * 0.5, -0.06, 0.16)]
        m.hard("cyl", ((root[0] + tip[0][0]) / 2, 0.11, -0.01), (0.018, 0.022, 0.38), wing, rot=(0, 0, sx * -70), bevel=0, seg=6)
        for i in range(3):
            a, b = tip[i], tip[i + 1]
            # Membrana: placa fina entre dois dedos.
            cx = (root[0] + a[0] + b[0]) / 3
            cy = (root[1] + a[1] + b[1]) / 3
            cz = (root[2] + a[2] + b[2]) / 3
            m.hard("sphere", (cx, cy, cz), (abs(a[0] - root[0]) * 0.55 + 0.05, 0.012, 0.13), mem, rot=(0, sx * (-15 + i * 22), sx * (12 - i * 10)), seg=16)
            m.hard("cyl", ((a[0] + root[0]) / 2 * 1.05, (a[1] + root[1]) / 2, (a[2] + root[2]) / 2), (0.01, 0.015, math.dist(a, root)), wing,
                   rot=(0, sx * (-5 + i * 10), sx * -(90 - math.degrees(math.atan2(a[1] - root[1], abs(a[0] - root[0]))))), bevel=0, seg=5)
        m.hard("spike", (sx * 0.05, -0.1, -0.15), (0.012, 0.05, 0), L.c(WHITE), rot=(180, 0, 0), seg=6)
    eyes(m, L, 0.16, -0.22 * h, 0.065 * h, 0.042 * h, iris=(0.1, 0.05, 0.05), glowc=(1.0, 0.85, 0.2))
    return finish(m, L, budget=1400, res=0.018)


# ------------------------------------------------------------------ esqueletos

def skeleton(m, L, bow):
    b = L.c(BONE)
    bd = darken(b, 0.18)
    h = L.head
    lk = L.limb
    for sx in (-1.0, 1.0):
        m.limb((sx * 0.13, 0.62, 0), (sx * 0.13, 0.36, -0.02), 0.045 * lk, b, group="leg%d" % sx)
        m.limb((sx * 0.13, 0.33, -0.02), (sx * 0.14, 0.07, 0.02), 0.04 * lk, b, group="leg%d" % sx)
        m.ball((sx * 0.13, 0.345, -0.03), 0.06 * lk, b, group="leg%d" % sx)
        m.ell((sx * 0.14, 0.04, -0.06), (0.07, 0.04, 0.12), b, group="leg%d" % sx)
        # Braço.
        m.limb((sx * 0.25, 1.08, 0), (sx * 0.33, 0.85, -0.08), 0.04 * lk, b, group="arm%d" % sx)
        m.limb((sx * 0.33, 0.83, -0.08), (sx * 0.3, 0.66, -0.26), 0.035 * lk, b, group="arm%d" % sx)
        m.ball((sx * 0.3, 0.64, -0.29), 0.05, b, group="arm%d" % sx)
    # Bacia, coluna e costelas.
    m.ell((0, 0.66, 0), (0.18, 0.08, 0.11), b, group="pelvis")
    m.limb((0, 0.7, 0.04), (0, 1.12, 0.05), 0.035, bd, group="spine")
    for i in range(4):
        y = 0.86 + i * 0.075
        w = 0.17 - abs(i - 1.5) * 0.02
        m.hard("torus", (0, y, -0.01), (w, 0.022), b, rot=(0, 0, 0), seg=20)
    m.hard("box", (0, 0.97, -0.17), (0.04, 0.26, 0.03), b, bevel=0.01)
    m.limb((-0.24, 1.12, 0), (0.24, 1.12, 0), 0.035, b, group="spine")
    # Crânio grande com mandíbula.
    hc = (0, 1.3 + 0.12 * (h - 1), -0.02)
    m.ball(hc, 0.2 * h, b, group="skull")
    m.ell((hc[0], hc[1] - 0.13 * h, hc[2] - 0.08 * h), (0.13 * h, 0.08 * h, 0.12 * h), b, group="skull")
    m.ell((0, hc[1] - 0.2 * h, hc[2] - 0.06 * h), (0.11 * h, 0.04 * h, 0.1 * h), bd, group="jaw")
    for sx in (-1.0, 1.0):
        m.ball((sx * 0.08 * h, hc[1] + 0.0, hc[2] - 0.17 * h), 0.065 * h, b, group="skull", neg=True, stiff=2.5)
    m.paint((0, hc[1] - 0.12 * h, hc[2] - 0.2 * h), (0.03 * h, 0.03 * h, 0.05 * h), L.c(DARK), soft=0.3)
    for sx in (-1.0, 1.0):
        m.hard("sphere", (sx * 0.08 * h, hc[1] - 0.005, hc[2] - 0.12 * h), (0.055 * h, 0.06 * h, 0.03 * h), L.c(DARK), seg=12)
        m.hard("sphere", (sx * 0.08 * h, hc[1] - 0.005, hc[2] - 0.15 * h), 0.025 * h, glow(L.c((0.3, 1.0, 0.6)) if L.idx != 4 else L.c((0.4, 0.8, 1.0))), seg=10)
    for i in range(5):
        m.hard("box", ((i - 2) * 0.035 * h, hc[1] - 0.17 * h, hc[2] - 0.17 * h), (0.025 * h, 0.04 * h, 0.02 * h), L.c(WHITE), bevel=0.004)
    if L.spiky:
        m.hard("cyl", (0, hc[1] + 0.12 * h, hc[2]), (0.17 * h, 0.21 * h, 0.12 * h), L.c((0.35, 0.36, 0.42)), metal=0.9, rough=0.4, seg=20)
        for sx in (-1.0, 1.0):
            m.hard("spike", (sx * 0.17 * h, hc[1] + 0.12 * h, hc[2]), (0.04 * h, 0.22 * h, 0.4), L.c((0.35, 0.36, 0.42)), metal=0.9, rough=0.4, rot=(0, 0, sx * -60), seg=10)
    if bow:
        wood = L.c(WOOD)
        # Arco recurvo à frente.
        for i in range(9):
            a = math.radians(-64 + i * 16)
            y = 0.95 + math.sin(a) * 0.48
            z = -0.42 - math.cos(a) * 0.14 + (0.06 if abs(i - 4) == 4 else 0)
            m.hard("cyl", (0.3, y, z), (0.02, 0.026, 0.13), wood, rot=(-math.degrees(a) * 0.55, 0, 0), bevel=0, seg=8)
        m.hard("cyl", (0.3, 0.95, -0.34), (0.004, 0.004, 0.93), L.c(WHITE), bevel=0, seg=4)
        m.hard("cyl", (-0.14, 1.0, 0.16), (0.075, 0.065, 0.5), darken(wood, 0.2), rot=(15, 0, 12), bevel=0.01, seg=12)
        for i in range(3):
            m.hard("cyl", (-0.2 + i * 0.05, 1.27, 0.2), (0.008, 0.008, 0.15), wood, bevel=0, seg=4)
            m.hard("cone", (-0.2 + i * 0.05, 1.37, 0.2), (0.03, 0.07), L.c((0.85, 0.2, 0.2)), seg=4)
        # Capuz rasgado.
        m.ell((0, hc[1] + 0.05, hc[2] + 0.06), (0.24 * h, 0.22 * h, 0.22 * h), L.c((0.25, 0.32, 0.22)), group="hood")
        m.ball((0, hc[1] - 0.02, hc[2] - 0.12 * h), 0.2 * h, L.c((0.25, 0.32, 0.22)), group="hood", neg=True, stiff=3.0)
        m.ell((0, 1.05, 0.08), (0.26, 0.12, 0.14), L.c((0.25, 0.32, 0.22)), group="hood")
    else:
        # Espada enferrujada e escudo redondo de madeira.
        steel = L.c((0.62, 0.6, 0.6))
        m.hard("blade", (0.3, 0.64, -0.3), (0.08, 0.02, 0.75), steel, rot=(30, 0, 0), metal=0.8, rough=0.45)
        m.hard("box", (0.3, 0.64, -0.3), (0.2, 0.04, 0.04), darken(steel, 0.3), metal=0.8, rough=0.5, bevel=0.008)
        m.hard("cyl", (-0.37, 0.85, -0.18), (0.27, 0.27, 0.05), L.c(WOOD), rot=(90, 0, 0), bevel=0.012, seg=24)
        m.hard("torus", (-0.37, 0.85, -0.21), (0.26, 0.02), L.c((0.45, 0.45, 0.48)), rot=(90, 0, 0), metal=0.8, rough=0.5, seg=24)
        m.hard("sphere", (-0.37, 0.85, -0.23), (0.06, 0.06, 0.03), L.c((0.45, 0.45, 0.48)), metal=0.8, rough=0.5, seg=12)
    return finish(m, L, budget=900, res=0.016)


# ------------------------------------------------------------------ goblin

def goblin(m, L):
    skin = L.c((0.44, 0.74, 0.28))
    h = L.head
    lk = L.limb
    cloth = L.c((0.5, 0.32, 0.18))
    for sx in (-1.0, 1.0):
        m.limb((sx * 0.11, 0.36, 0), (sx * 0.12, 0.07, 0.0), 0.06 * lk, skin, group="leg%d" % sx)
        m.ell((sx * 0.12, 0.05, -0.06), (0.08, 0.05, 0.13), L.c((0.3, 0.2, 0.12)), group="leg%d" % sx)
        m.limb((sx * 0.24, 0.68, 0), (sx * 0.34, 0.45, -0.1), 0.05 * lk, skin, group="arm%d" % sx, r2=0.045 * lk)
        m.ball((sx * 0.36, 0.42, -0.12), 0.07 * lk, skin, group="arm%d" % sx)
    m.ell((0, 0.55, 0.0), (0.24, 0.27, 0.2), cloth)
    m.ell((0, 0.38, 0.0), (0.2, 0.12, 0.17), darken(cloth, 0.2))
    m.paint((0, 0.4, -0.2), (0.25, 0.05, 0.1), L.c((0.25, 0.15, 0.08)), soft=0.3)
    hc = (0, 0.95 + 0.25 * (h - 1), -0.02)
    m.ball(hc, 0.3 * h, skin, group="head")
    m.ell((0, hc[1] - 0.12 * h, hc[2] - 0.14 * h), (0.22 * h, 0.13 * h, 0.18 * h), skin, group="head")
    m.ell((0, hc[1] - 0.02 * h, hc[2] - 0.33 * h), (0.07 * h, 0.07 * h, 0.13 * h), lighten(skin, 0.1), rot=(-25, 0, 0), group="head")
    for sx in (-1.0, 1.0):
        # Orelhas pontudas compridas.
        m.ell((sx * 0.38 * h, hc[1] + 0.06 * h, hc[2] + 0.02), (0.22 * h, 0.07 * h, 0.04 * h), skin, rot=(0, -sx * 15, sx * 18), group="ear%d" % sx)
        m.paint((sx * 0.38 * h, hc[1] + 0.06 * h, hc[2] - 0.02), (0.16 * h, 0.04 * h, 0.04 * h), L.c(PINK), rot=(0, -sx * 15, sx * 18), soft=0.6, only="ear%d" % sx)
    eyes(m, L, hc[1] + 0.06 * h, hc[2] - 0.24 * h, 0.12 * h, 0.08 * h, iris=(0.7, 0.15, 0.0), glowc=(1.0, 0.6, 0.1), angry=True)
    # Sorriso com dentes.
    m.hard("box", (0, hc[1] - 0.16 * h, hc[2] - 0.29 * h), (0.24 * h, 0.04 * h, 0.04 * h), L.c(DARK), rot=(10, 0, 0), bevel=0.01)
    for i in range(4):
        m.hard("cone", ((i - 1.5) * 0.055 * h, hc[1] - 0.14 * h, hc[2] - 0.3 * h), (0.02 * h, 0.05 * h), L.c(WHITE), rot=(180, 0, 0), seg=6)
    # Óculos de aviador na testa.
    m.hard("torus", (0, hc[1] + 0.2 * h, hc[2] - 0.05), (0.27 * h, 0.025 * h), L.c((0.35, 0.22, 0.12)), rot=(-15, 0, 0), seg=24)
    for sx in (-1.0, 1.0):
        m.hard("cyl", (sx * 0.1 * h, hc[1] + 0.22 * h, hc[2] - 0.24 * h), (0.06 * h, 0.07 * h, 0.06 * h), L.c((0.55, 0.45, 0.3)), rot=(70, 0, 0), metal=0.8, rough=0.35, seg=16)
        m.hard("cyl", (sx * 0.1 * h, hc[1] + 0.205 * h, hc[2] - 0.27 * h), (0.045 * h, 0.045 * h, 0.02 * h), glow(L.c((0.5, 0.85, 1.0))) if L.idx == 4 else L.c((0.5, 0.8, 0.95)), rot=(70, 0, 0), rough=0.1, seg=16)
    # Dinamite acesa erguida na mão direita + cinto com bananas.
    red = L.c((0.88, 0.16, 0.1))
    for i in range(3):
        m.hard("cyl", (0.37 + (i - 1) * 0.05, 0.62, -0.13 + (i % 2) * 0.03), (0.035, 0.035, 0.32), red, rot=(0, 0, -8), bevel=0.006, seg=12)
    m.hard("torus", (0.37, 0.58, -0.13), (0.075, 0.012), L.c((0.35, 0.22, 0.12)), seg=16)
    m.hard("cyl", (0.37, 0.83, -0.13), (0.006, 0.006, 0.12), L.c(WHITE), rot=(0, 0, 20), bevel=0, seg=4)
    m.hard("sphere", (0.35, 0.9, -0.13), 0.05, glow(L.c((1.0, 0.7, 0.2))), seg=10)
    m.hard("sphere", (0.35, 0.9, -0.13), 0.08, glow(L.c((1.0, 0.35, 0.05))), seg=10)
    for i in range(4):
        a = math.radians(-60 + i * 40)
        m.hard("cyl", (math.sin(a) * 0.24, 0.42, math.cos(a) * 0.19), (0.026, 0.026, 0.13), red, rot=(0, math.degrees(a), 0), bevel=0.005, seg=10)
    if L.spiky:
        m.hard("box", (0, 0.62, 0.22), (0.28, 0.3, 0.1), L.c((0.3, 0.28, 0.3)), metal=0.7, rough=0.5, bevel=0.02)
        for i in range(3):
            m.hard("spike", ((i - 1) * 0.08, 0.8, 0.24), (0.03, 0.12, 0.3), L.c((0.3, 0.28, 0.3)), metal=0.7, rough=0.5, seg=8)
    return finish(m, L, budget=1500, res=0.02)


# ------------------------------------------------------------------ slime

def slime(m, L):
    g = L.c((0.3, 0.92, 0.5)) if L.idx != 4 else L.c((0.4, 0.95, 0.35))
    m.ell((0, 0.42, 0), (0.78, 0.5, 0.78), g)
    m.ell((0, 0.78, 0.05), (0.45, 0.25, 0.45), g)
    m.ball((0, 1.02, 0.1), 0.14, g)
    for i in range(6):
        a = math.tau * i / 6 + 0.3
        m.ell((math.cos(a) * 0.7, 0.1, math.sin(a) * 0.7), (0.22, 0.12, 0.22), g)
    # Núcleo e bolhas por dentro (cor mais escura) + brilho de geleia.
    m.paint((0.05, 0.45, 0.15), (0.38, 0.32, 0.38), darken(g, 0.35), soft=0.9)
    m.paint((-0.28, 0.8, -0.32), (0.18, 0.1, 0.12), lighten(g, 0.6), soft=0.7)
    m.paint((0.0, 0.05, 0.0), (0.9, 0.12, 0.9), darken(g, 0.2), soft=1.0)
    eyes(m, L, 0.72, -0.62, 0.22, 0.14, iris=(0.05, 0.2, 0.08), glowc=(0.85, 1.0, 0.3))
    # Boca aberta.
    m.hard("sphere", (0, 0.5, -0.74), (0.17, 0.09, 0.05), L.c(DARK), rot=(15, 0, 0), seg=16)
    m.hard("sphere", (0, 0.47, -0.76), (0.09, 0.04, 0.03), L.c((0.9, 0.35, 0.4)), rot=(15, 0, 0), seg=12)
    if L.idx == 4:
        for i in range(5):
            a = i * 1.3
            m.hard("sphere", (math.cos(a) * 0.35, 0.5 + (i % 3) * 0.12, 0.2 + math.sin(a) * 0.3), 0.06 + (i % 2) * 0.03, L.c(BONE), seg=10)
    return finish(m, L, budget=1600, res=0.035)


# ------------------------------------------------------------------ estruturas

def nest(m, L):
    rock = L.c((0.3, 0.22, 0.27))
    m.ell((0, 0.55, 0), (1.0, 0.75, 1.0), rock)
    m.ell((0, 1.35, 0), (0.72, 0.6, 0.72), rock)
    m.ell((0.05, 2.0, 0.05), (0.45, 0.5, 0.45), rock)
    m.ball((0.1, 2.5, 0.1), 0.22, rock)
    for i in range(6):
        a = math.tau * i / 6 + 0.4
        m.ell((math.cos(a) * 0.95, 0.15, math.sin(a) * 0.95), (0.35, 0.2, 0.35), rock)
    # Grutas brilhantes (buracos com luz).
    for i in range(5):
        a = math.tau * i / 5 + 0.2
        y = 0.75 + (i % 3) * 0.5
        rr = 1.0 - (y - 0.55) * 0.25
        p = (math.cos(a) * rr * 0.98, y, math.sin(a) * rr * 0.98)
        m.hard("sphere", p, (0.17, 0.2, 0.17), glow(L.c((0.65, 0.2, 0.85))), seg=12)
        m.paint(p, 0.32, darken(rock, 0.55), soft=0.8)
    m.hard("sphere", (0.1, 2.72, 0.1), 0.1, glow(L.c((0.95, 0.4, 1.0))), seg=12)
    # Ossos espetados e estalactites.
    for i in range(7):
        a = math.tau * i / 7 + 0.1
        m.hard("cyl", (math.cos(a) * 1.15, 0.25, math.sin(a) * 1.15), (0.04, 0.05, 0.6), L.c(BONE), rot=(math.sin(a) * 35, 0, -math.cos(a) * 35), bevel=0.01, seg=8)
    if L.spiky:
        for i in range(8):
            a = math.tau * i / 8
            m.hard("spike", (math.cos(a) * 0.65, 1.4 + (i % 2) * 0.5, math.sin(a) * 0.65), (0.08, 0.5, 0.2), darken(rock, 0.3), rot=(math.sin(a) * 60, 0, -math.cos(a) * 60), seg=8)
    m.paint((0, 0.1, 0), (1.3, 0.3, 1.3), darken(rock, 0.3), soft=1.0)
    m.paint((0, 2.6, 0), (0.5, 0.3, 0.5), lighten(rock, 0.15), soft=1.0)
    return finish(m, L, budget=2600, res=0.05)


def totem(m, L):
    wood = darken(L.c(WOOD), 0.25)
    b = L.c(BONE)
    m.hard("cyl", (0, 0.1, 0), (0.62, 0.78, 0.22), darken(L.c((0.5, 0.5, 0.56)), 0.3), bevel=0.04, seg=10)
    for i in range(5):
        a = math.tau * i / 5
        m.hard("sphere", (math.cos(a) * 0.6, 0.18, math.sin(a) * 0.6), (0.2, 0.14, 0.2), darken(L.c((0.5, 0.5, 0.56)), 0.2), seg=10)
    m.limb((0, 0.1, 0), (0, 2.5, 0), 0.13, wood, r2=0.09, group="pole")
    for i in range(3):
        y = 0.78 + i * 0.66
        s = 1.0 - i * 0.08
        m.ball((0, y, 0), 0.27 * s * L.head, b, group="sk%d" % i)
        m.ell((0, y - 0.15 * s, -0.1 * s), (0.18 * s, 0.1 * s, 0.17 * s), b, group="sk%d" % i)
        for sx in (-1.0, 1.0):
            m.hard("sphere", (sx * 0.1 * s, y + 0.02, -0.22 * s * L.head), (0.07 * s, 0.075 * s, 0.03), L.c(DARK), seg=10)
            m.hard("sphere", (sx * 0.1 * s, y + 0.02, -0.25 * s * L.head), 0.035 * s, glow(L.c((0.3, 1.0, 0.7))), seg=8)
        for k in range(4):
            m.hard("box", ((k - 1.5) * 0.045, y - 0.2 * s, -0.25 * s), (0.03, 0.05, 0.02), L.c(WHITE), bevel=0.004)
        if i == 2:
            for sx in (-1.0, 1.0):
                m.hard("spike", (sx * 0.22, y + 0.15, 0), (0.06, 0.45, 0.5), b, rot=(0, 0, sx * -55), seg=10)
    # Penas e fitas.
    for sx in (-1.0, 1.0):
        m.hard("sphere", (sx * 0.3, 2.3, 0.05), (0.05, 0.25, 0.02), L.c((0.82, 0.2, 0.25)), rot=(0, 0, sx * -25), seg=12)
        m.hard("sphere", (sx * 0.4, 2.2, 0.05), (0.045, 0.2, 0.02), L.c((0.2, 0.5, 0.8)) if L.idx != 4 else L.c((0.3, 0.3, 0.35)), rot=(0, 0, sx * -45), seg=12)
    m.hard("box", (0, 2.18, 0), (1.25, 0.08, 0.08), b, rot=(0, 0, 8), bevel=0.02)
    m.hard("torus", (0, 1.15, 0), (0.14, 0.025), L.c((0.8, 0.25, 0.25)), seg=16)
    m.hard("torus", (0, 1.8, 0), (0.12, 0.025), L.c((0.8, 0.25, 0.25)), seg=16)
    return finish(m, L, budget=2000, res=0.03)


def tower(m, L):
    st = L.c((0.5, 0.5, 0.57))
    std = darken(st, 0.22)
    m.hard("cyl", (0, 0.22, 0), (0.78, 0.95, 0.44), std, bevel=0.05, seg=8)
    m.hard("cyl", (0, 1.45, 0), (0.5, 0.64, 2.1), st, bevel=0.03, seg=8)
    for i in range(4):
        y = 0.65 + i * 0.5
        for k in range(8):
            a = math.tau * (k + (i % 2) * 0.5) / 8
            rr = 0.64 - (y - 0.4) * 0.065
            m.hard("box", (math.cos(a) * rr, y, math.sin(a) * rr), (0.36, 0.2, 0.08), mix(st, std, (k * 7 + i * 3) % 5 / 5), rot=(0, -math.degrees(a) + 90, 0), bevel=0.02)
    m.hard("cyl", (0, 2.62, 0), (0.78, 0.6, 0.28), std, bevel=0.03, seg=8)
    for k in range(8):
        a = math.tau * k / 8
        m.hard("box", (math.cos(a) * 0.7, 2.86, math.sin(a) * 0.7), (0.2, 0.22, 0.2), std, rot=(0, -math.degrees(a), 0), bevel=0.02)
    # Gárgula agachada no topo.
    g = darken(st, 0.08)
    m.ell((0, 3.15, 0.08), (0.36, 0.34, 0.32), g, group="garg")
    m.ball((0, 3.5, -0.18), 0.24 * L.head, g, group="garg")
    m.ell((0, 3.43, -0.4), (0.12, 0.09, 0.12), g, group="garg")
    for sx in (-1.0, 1.0):
        m.limb((sx * 0.25, 3.15, -0.12), (sx * 0.3, 2.95, -0.32), 0.07, g, group="garg")
        m.ball((sx * 0.3, 2.92, -0.36), 0.08, g, group="garg")
        m.hard("spike", (sx * 0.14, 3.65, -0.15), (0.05, 0.3, 0.6), darken(g, 0.2), rot=(-15, 0, sx * -20), seg=10)
        # Asas de pedra abertas.
        for i in range(3):
            m.hard("sphere", (sx * (0.45 + i * 0.18), 3.42 + i * 0.07, 0.25), (0.2, 0.02, 0.3 - i * 0.05), darken(g, 0.15 + i * 0.05), rot=(0, sx * 20, sx * (-25 - i * 12)), seg=12)
        m.hard("spike", (sx * 0.5, 3.6, 0.25), (0.035, 0.6, 0.0), darken(g, 0.25), rot=(0, 0, sx * -55), seg=6)
    eyes(m, L, 3.55, -0.36, 0.09, 0.05, glowc=(1.0, 0.5, 0.1), angry=True)
    for i in range(2):
        m.hard("spike", ((i - 0.5) * 0.08, 3.36, -0.47), (0.02, 0.06, 0), L.c(WHITE), rot=(180, 0, 0), seg=6)
    # Runas brilhando na torre.
    rc = glow(L.c((1.0, 0.5, 0.15)))
    for i in range(3):
        m.hard("box", (0, 0.9 + i * 0.55, -0.6 + i * 0.03), (0.12, 0.2, 0.02), rc, bevel=0)
    m.paint((0, 0.0, 0), (1.2, 0.5, 1.2), L.c((0.25, 0.4, 0.2)), soft=1.0)
    return finish(m, L, budget=1500, res=0.035)


# ------------------------------------------------------------------ humanoides

def cultist(m, L):
    robe = L.c((0.4, 0.08, 0.22))
    rd = darken(robe, 0.3)
    trim = L.c(GOLD)
    m.ell((0, 0.42, 0), (0.42, 0.45, 0.38), robe)
    m.ell((0, 0.9, 0), (0.28, 0.4, 0.24), robe)
    for i in range(7):
        a = math.tau * i / 7
        m.ell((math.cos(a) * 0.36, 0.08, math.sin(a) * 0.34), (0.14, 0.1, 0.14), robe)
    m.paint((0, 0.0, 0), (0.6, 0.14, 0.6), trim, soft=0.25)
    m.paint((0, 0.7, -0.3), (0.06, 0.6, 0.15), trim, soft=0.3)
    # Capuz pontudo.
    hc = (0, 1.32, 0)
    m.ell(hc, (0.27 * L.head, 0.3 * L.head, 0.27 * L.head), robe, group="hood")
    m.limb((0, 1.5, 0.08), (0, 1.85, 0.3), 0.12, robe, r2=0.03, group="hood")
    m.ball((0, 1.28, -0.2 * L.head), 0.2 * L.head, robe, group="hood", neg=True, stiff=3.0)
    m.hard("sphere", (0, 1.27, -0.1 * L.head), (0.19 * L.head, 0.22 * L.head, 0.1), L.c(DARK), seg=16)
    for sx in (-1.0, 1.0):
        m.hard("sphere", (sx * 0.07 * L.head, 1.29, -0.18 * L.head), (0.04, 0.025, 0.02), glow(L.c((1.0, 0.3, 0.95))), rot=(0, 0, sx * -15), seg=10)
    # Mangas largas, mãos juntas segurando o cajado.
    for sx in (-1.0, 1.0):
        m.limb((sx * 0.25, 1.05, 0), (sx * 0.2, 0.82, -0.28), 0.1, robe, r2=0.14, group="sl%d" % sx)
        m.ball((sx * 0.16, 0.78, -0.36), 0.06, L.c((0.75, 0.62, 0.6)), group="hand%d" % sx)
    m.hard("cyl", (0.22, 0.9, -0.38), (0.025, 0.03, 1.8), L.c(WOOD), rot=(-6, 0, -6), bevel=0, seg=8)
    m.hard("torus", (0.25, 1.85, -0.45), (0.11, 0.02), trim, rot=(90, 0, 0), metal=1.0, rough=0.3, seg=20)
    m.hard("sphere", (0.25, 1.85, -0.45), (0.08, 0.13, 0.08), glow(L.c((0.85, 0.3, 1.0))), seg=10)
    # Livro e pingente.
    m.hard("box", (-0.16, 0.86, -0.34), (0.2, 0.26, 0.06), L.c((0.25, 0.12, 0.08)), rot=(-30, 20, 0), bevel=0.01)
    m.hard("sphere", (0, 1.05, -0.25), 0.05, glow(L.c((1.0, 0.25, 0.4))), seg=10)
    if L.spiky:
        for sx in (-1.0, 1.0):
            m.hard("spike", (sx * 0.15, 1.5, 0), (0.05, 0.35, 0.5), L.c(BONE), rot=(0, 0, sx * -35), seg=8)
    return finish(m, L, budget=1500, res=0.025)


def ogre(m, L):
    skin = L.c((0.42, 0.58, 0.3))
    sd = darken(skin, 0.2)
    h = L.head
    lk = L.limb
    for sx in (-1.0, 1.0):
        m.limb((sx * 0.4, 0.75, 0.05), (sx * 0.45, 0.15, 0.0), 0.24 * lk, sd, r2=0.2 * lk, group="leg%d" % sx)
        m.ell((sx * 0.45, 0.08, -0.12), (0.22, 0.1, 0.28), sd, group="leg%d" % sx)
        # Braços enormes com punho no chão.
        m.ball((sx * 0.95, 1.85, 0.0), 0.33, skin, group="arm%d" % sx)
        m.limb((sx * 1.05, 1.7, 0), (sx * 1.2, 1.1, -0.2), 0.27 * lk, skin, r2=0.22 * lk, group="arm%d" % sx)
        m.limb((sx * 1.2, 1.05, -0.2), (sx * 1.25, 0.55, -0.35), 0.26 * lk, skin, r2=0.3 * lk, group="arm%d" % sx)
        m.ball((sx * 1.25, 0.42, -0.38), 0.3 * lk, lighten(skin, 0.05), group="arm%d" % sx)
    m.ell((0, 1.4, 0.05), (0.92, 0.82, 0.75), skin)
    m.ell((0, 1.12, -0.32), (0.7, 0.55, 0.5), lighten(skin, 0.06))
    m.paint((0, 1.1, -0.65), (0.5, 0.42, 0.2), lighten(skin, 0.18), soft=0.8)
    # Tanga e cinto.
    m.ell((0, 0.82, 0), (0.86, 0.22, 0.7), L.c((0.42, 0.28, 0.16)), group="belt")
    m.hard("torus", (0, 0.9, 0), (0.86, 0.06), L.c((0.3, 0.2, 0.12)), rot=(0, 0, 0), seg=28)
    m.hard("box", (0, 0.9, -0.86), (0.28, 0.22, 0.06), L.c(STEEL), metal=0.9, rough=0.4, bevel=0.02)
    # Cabeça pequena entre os ombros.
    hc = (0, 2.2 + 0.25 * (h - 1), -0.35)
    m.ball(hc, 0.36 * h, skin, group="head")
    m.ell((0, hc[1] - 0.17 * h, hc[2] - 0.18 * h), (0.3 * h, 0.18 * h, 0.2 * h), skin, group="head")
    m.ell((0, hc[1] - 0.02 * h, hc[2] - 0.34 * h), (0.09 * h, 0.08 * h, 0.07 * h), sd, group="head")
    eyes(m, L, hc[1] + 0.1 * h, hc[2] - 0.27 * h, 0.13 * h, 0.07 * h, iris=(0.45, 0.2, 0.0), glowc=(1.0, 0.4, 0.1), angry=True)
    for sx in (-1.0, 1.0):
        m.hard("spike", (sx * 0.17 * h, hc[1] - 0.2 * h, hc[2] - 0.33 * h), (0.05 * h, 0.2 * h, -0.4), L.c(WHITE), rot=(0, 0, sx * -8), seg=10)
        m.ell((sx * 0.36 * h, hc[1] + 0.02, hc[2] + 0.05), (0.1 * h, 0.08 * h, 0.04 * h), skin, group="head")
    # Clava cravejada.
    wood = L.c(WOOD)
    m.hard("cyl", (1.35, 0.95, -0.95), (0.22, 0.09, 1.3), wood, rot=(-62, 0, 8), bevel=0.03, seg=12)
    for i in range(6):
        a = i * 1.1
        p = (1.35 + math.cos(a) * 0.2, 0.68 + math.sin(a) * 0.1 - i * 0.03, -1.4 + math.sin(a) * 0.15)
        m.hard("cone", p, (0.05, 0.16), L.c(STEEL), rot=(math.degrees(math.sin(a)) * 1.5 - 60, 0, math.degrees(math.cos(a)) * 1.5), metal=0.9, rough=0.4, seg=6)
    if L.spiky:
        for sx in (-1.0, 1.0):
            m.hard("cyl", (sx * 0.95, 2.05, 0), (0.25, 0.4, 0.3), L.c((0.35, 0.35, 0.4)), metal=0.9, rough=0.4, rot=(0, 0, sx * -30), bevel=0.02, seg=14)
            for k in range(3):
                m.hard("spike", (sx * (0.85 + k * 0.15), 2.25, -0.1 + k * 0.1), (0.06, 0.35, 0.2), L.c((0.35, 0.35, 0.4)), metal=0.9, rough=0.4, rot=(0, 0, sx * -30), seg=8)
    return finish(m, L, budget=3200, res=0.045)


def mimic(m, L):
    wood = L.c(WOOD)
    gold = L.c(GOLD)
    m.hard("box", (0, 0.33, 0), (1.3, 0.62, 0.9), wood, bevel=0.05)
    for x in (-0.58, 0.58):
        m.hard("box", (x, 0.33, 0), (0.1, 0.66, 0.94), gold, metal=1.0, rough=0.35, bevel=0.02)
    m.hard("box", (0, 0.06, 0), (1.36, 0.1, 0.96), darken(gold, 0.2), metal=1.0, rough=0.35, bevel=0.02)
    # Tampa aberta (meio cilindro) com dentes.
    m.hard("cyl", (0, 0.95, 0.42), (0.46, 0.46, 1.3), mix(wood, (1, 1, 1), 0.08), rot=(0, 0, 90), bevel=0.03, seg=20)
    m.hard("box", (0, 0.66, 0.0), (1.12, 0.12, 0.72), L.c((0.35, 0.04, 0.1)), bevel=0.04)
    for i in range(8):
        x = -0.52 + i * 0.15
        m.hard("cone", (x, 0.58, -0.4), (0.055, 0.2), L.c(WHITE), rot=(180, 0, 0), seg=8)
        m.hard("cone", (x + 0.07, 0.82, -0.3), (0.05, 0.18), L.c(WHITE), rot=(-30, 0, 0), seg=8)
    # Língua comprida.
    tg = L.c((0.92, 0.3, 0.42))
    for i in range(6):
        t = i / 5
        m.ball((0.05 + math.sin(t * 3) * 0.12, 0.6 - t * 0.35, -0.3 - t * 0.55), 0.11 - t * 0.04, tg, group="tongue")
    m.hard("box", (0, 0.45, -0.47), (0.24, 0.28, 0.06), gold, metal=1.0, rough=0.3, bevel=0.02)
    m.hard("cyl", (0, 0.45, -0.51), (0.05, 0.05, 0.03), L.c(DARK), rot=(90, 0, 0), bevel=0, seg=12)
    eyes(m, L, 1.05, 0.0, 0.3, 0.1, iris=(0.6, 0.1, 0.0), glowc=(1.0, 0.3, 0.1), angry=True)
    # Moedas caindo.
    for i in range(5):
        m.hard("cyl", (-0.4 + i * 0.2, 0.75 + (i % 2) * 0.05, -0.15), (0.06, 0.06, 0.015), gold, rot=(60 + i * 20, 0, i * 30), metal=1.0, rough=0.3, bevel=0, seg=14)
    if L.spiky:
        for sx in (-1.0, 1.0):
            for k in range(3):
                m.ell((sx * 0.7, 0.2, -0.2 + k * 0.25), (0.06, 0.25, 0.06), L.c((0.2, 0.12, 0.15)), rot=(0, 0, sx * 40), group="leg%d%d" % (sx, k))
    return finish(m, L, budget=1200, res=0.03)


def ghost(m, L, colr):
    c = L.c(colr)
    m.ball((0, 1.45, 0), 0.52 * L.head, c)
    m.ell((0, 0.95, 0.05), (0.5, 0.55, 0.45), c)
    # Cauda ondulada.
    for i in range(6):
        a = math.tau * i / 6
        m.ell((math.cos(a) * 0.3, 0.42, 0.05 + math.sin(a) * 0.28), (0.14, 0.3, 0.14), c, rot=(math.sin(a) * 15, 0, -math.cos(a) * 15))
    for sx in (-1.0, 1.0):
        m.limb((sx * 0.4, 1.2, -0.05), (sx * 0.72, 1.3, -0.35), 0.11, c, r2=0.06, group="arm%d" % sx)
    m.paint((0, 0.3, 0), (0.7, 0.6, 0.7), darken(c, 0.25), soft=1.0)
    m.paint((0, 1.7, -0.2), (0.4, 0.3, 0.3), lighten(c, 0.3), soft=1.0)
    hc = 1.45
    if L.eyes == "glow":
        eyes(m, L, hc + 0.05, -0.45 * L.head, 0.17, 0.08, glowc=(0.4, 1.0, 0.95), angry=True)
    else:
        for sx in (-1.0, 1.0):
            m.hard("sphere", (sx * 0.17 * L.head, hc + 0.06, -0.44 * L.head), (0.09 * L.head, 0.13 * L.head, 0.05), L.c(DARK), seg=14)
            m.hard("sphere", (sx * 0.17 * L.head - 0.03, hc + 0.11, -0.48 * L.head), 0.025, WHITE, seg=8)
    m.hard("sphere", (0, hc - 0.2, -0.45 * L.head), (0.11, 0.14, 0.05), L.c(DARK), seg=14)
    if L.spiky:
        m.hard("torus", (0, 0.95, 0.05), (0.42, 0.03), L.c((0.3, 0.3, 0.35)), metal=0.8, rough=0.5, rot=(10, 0, 0), seg=24)
        m.hard("cyl", (0.45, 0.8, 0.2), (0.03, 0.03, 0.5), L.c((0.3, 0.3, 0.35)), metal=0.8, rough=0.5, rot=(30, 0, 40), seg=6)
    return finish(m, L, budget=1300, res=0.04)


def werewolf(m, L):
    fur = L.c((0.4, 0.31, 0.27))
    lf = lighten(fur, 0.22)
    h = L.head
    lk = L.limb
    for sx in (-1.0, 1.0):
        # Pernas dobradas de lobo.
        m.limb((sx * 0.24, 0.8, 0.1), (sx * 0.28, 0.45, -0.12), 0.14 * lk, fur, r2=0.1 * lk, group="leg%d" % sx)
        m.limb((sx * 0.28, 0.43, -0.12), (sx * 0.26, 0.12, 0.12), 0.08 * lk, fur, group="leg%d" % sx)
        m.ell((sx * 0.26, 0.05, -0.02), (0.1, 0.06, 0.18), darken(fur, 0.2), group="leg%d" % sx)
        # Braços longos com garras.
        m.limb((sx * 0.5, 1.55, -0.1), (sx * 0.66, 1.1, -0.35), 0.13 * lk, fur, r2=0.1 * lk, group="arm%d" % sx)
        m.limb((sx * 0.66, 1.08, -0.37), (sx * 0.62, 0.72, -0.6), 0.09 * lk, fur, r2=0.11 * lk, group="arm%d" % sx)
        for c in range(3):
            m.hard("spike", (sx * 0.62 + (c - 1) * 0.045, 0.66, -0.66), (0.022, 0.13, 0.6), L.c(WHITE), rot=(-150, 0, 0), seg=6)
    m.ell((0, 1.25, -0.05), (0.5, 0.48, 0.42), fur, rot=(-25, 0, 0))
    m.ell((0, 0.9, 0.08), (0.34, 0.3, 0.3), fur)
    m.paint((0, 1.15, -0.4), (0.3, 0.35, 0.2), lf, soft=0.8)
    # Juba.
    for i in range(7):
        a = math.radians(-70 + i * 23)
        m.ell((math.sin(a) * 0.35, 1.62, -0.08 + math.cos(a) * 0.12), (0.14, 0.22, 0.14), darken(fur, 0.15), rot=(-30, 0, -math.degrees(a) * 0.5), group="mane")
    # Cabeça com focinho comprido.
    hc = (0, 1.78 + 0.2 * (h - 1), -0.35)
    m.ball(hc, 0.27 * h, fur, group="head")
    m.ell((0, hc[1] - 0.08 * h, hc[2] - 0.28 * h), (0.13 * h, 0.12 * h, 0.22 * h), fur, rot=(10, 0, 0), group="head")
    m.paint((0, hc[1] - 0.15 * h, hc[2] - 0.3 * h), (0.12 * h, 0.07 * h, 0.2 * h), lf, soft=0.7)
    m.hard("sphere", (0, hc[1] - 0.04 * h, hc[2] - 0.5 * h), (0.06 * h, 0.045 * h, 0.04 * h), L.c(DARK), seg=12)
    for sx in (-1.0, 1.0):
        m.hard("spike", (sx * 0.14 * h, hc[1] + 0.18 * h, hc[2] + 0.02), (0.08 * h, 0.26 * h, 0.2), fur, rot=(-10, 0, sx * -18), seg=10)
        m.hard("spike", (sx * 0.05 * h, hc[1] - 0.17 * h, hc[2] - 0.42 * h), (0.018 * h, 0.07 * h, 0), L.c(WHITE), rot=(180, 0, 0), seg=6)
    eyes(m, L, hc[1] + 0.06 * h, hc[2] - 0.2 * h, 0.1 * h, 0.05 * h, iris=(0.9, 0.6, 0.0), glowc=(1.0, 0.85, 0.1), angry=True)
    # Calça rasgada.
    m.ell((0, 0.78, 0.08), (0.36, 0.16, 0.32), L.c((0.28, 0.32, 0.5)), group="pants")
    if L.spiky:
        for i in range(5):
            m.hard("spike", (0, 1.55 - i * 0.14, 0.3 + i * 0.02), (0.05, 0.22, 0.5), darken(fur, 0.4), rot=(70, 0, 0), seg=8)
    return finish(m, L, budget=2400, res=0.03)


def golem(m, L):
    rust = L.c((0.6, 0.38, 0.22))
    steel = L.c((0.5, 0.52, 0.58))
    cyan = glow(L.c((0.3, 0.9, 1.0)))
    for sx in (-1.0, 1.0):
        m.hard("box", (sx * 0.36, 0.4, 0), (0.4, 0.78, 0.42), darken(rust, 0.2), bevel=0.04, metal=0.6, rough=0.6)
        m.hard("box", (sx * 0.36, 0.08, -0.06), (0.5, 0.16, 0.6), darken(steel, 0.2), bevel=0.03, metal=0.8, rough=0.5)
        m.hard("sphere", (sx * 0.82, 1.78, 0), (0.32, 0.3, 0.32), steel, metal=0.8, rough=0.45, seg=16)
        m.hard("box", (sx * 1.0, 1.25, 0), (0.36, 0.8, 0.36), darken(steel, 0.25), rot=(0, 0, sx * -8), bevel=0.03, metal=0.8, rough=0.5)
        m.hard("box", (sx * 1.08, 0.62, -0.05), (0.56, 0.46, 0.56), rust, bevel=0.06, metal=0.6, rough=0.6)
        for k in range(3):
            m.hard("box", (sx * 1.08 + (k - 1) * 0.16, 0.33, -0.3), (0.1, 0.16, 0.1), darken(steel, 0.3), metal=0.8, rough=0.5, bevel=0.02)
        # Canos.
        m.hard("cyl", (sx * 0.45, 2.15, 0.35), (0.06, 0.06, 0.6), steel, rot=(-20, 0, sx * 15), metal=0.8, rough=0.45, seg=10)
        m.hard("sphere", (sx * 0.52, 2.45, 0.42), 0.06, glow(L.c((1.0, 0.6, 0.2))), seg=8)
    m.hard("box", (0, 1.3, 0), (1.35, 1.12, 0.92), rust, rot=(0, 0, 3), bevel=0.08, metal=0.6, rough=0.6)
    m.hard("box", (0, 1.52, 0), (1.42, 0.22, 0.98), darken(rust, 0.2), bevel=0.03, metal=0.6, rough=0.6)
    for i in range(8):
        x = -0.6 + i * 0.17
        m.hard("sphere", (x, 1.52, -0.5), 0.035, steel, metal=0.9, rough=0.4, seg=8)
    m.hard("cyl", (0, 1.15, -0.47), (0.24, 0.24, 0.08), steel, rot=(90, 0, 0), metal=0.9, rough=0.35, bevel=0.01, seg=20)
    m.hard("cyl", (0, 1.15, -0.5), (0.17, 0.17, 0.06), cyan, rot=(90, 0, 0), bevel=0, seg=20)
    # Cabeça de caldeira com visor.
    m.hard("cyl", (0, 2.12, -0.08), (0.3, 0.34, 0.5), rust, bevel=0.04, metal=0.6, rough=0.55, seg=16)
    m.hard("sphere", (0, 2.37, -0.08), (0.3, 0.16, 0.3), darken(rust, 0.1), metal=0.6, rough=0.55, seg=16)
    m.hard("box", (0, 2.15, -0.38), (0.4, 0.08, 0.06), cyan, bevel=0.01)
    m.hard("cyl", (0.18, 2.6, 0.1), (0.04, 0.04, 0.5), steel, rot=(0, 0, 15), metal=0.8, rough=0.4, seg=8)
    m.hard("sphere", (0.25, 2.85, 0.1), 0.06, glow(L.c((1.0, 0.25, 0.15))), seg=10)
    # Manchas de ferrugem e remendos.
    for i in range(4):
        m.hard("box", (-0.35 + i * 0.25, 0.95 + (i % 2) * 0.3, -0.47), (0.16, 0.14, 0.02), mix(steel, rust, 0.4), rot=(0, 0, i * 17), metal=0.8, rough=0.5, bevel=0)
    if L.spiky:
        for sx in (-1.0, 1.0):
            for k in range(3):
                m.hard("spike", (sx * (0.65 + k * 0.15), 2.0, 0.0), (0.06, 0.4, 0.2), darken(steel, 0.3), rot=(0, 0, sx * -40), metal=0.9, rough=0.4, seg=8)
    return finish(m, L, budget=1500, res=0.04)


# ------------------------------------------------------------------ herói (peças articuladas)

def hero_part(m, L, part):
    """Mesmos pivôs do jogo: perna em (±0,16; 0,72), torso em 0,75, cabeça em 1,4, braços em (±0,48; 1,33), capa em (0; 1,4; 0,24).
    Cada peça tem a origem na própria articulação."""
    blue = L.c((0.2, 0.38, 0.85)) if L.idx != 4 else L.c((0.18, 0.24, 0.5))
    steel = L.c(STEEL)
    steel_d = darken(steel, 0.25)
    gold = L.c(GOLD)
    red = L.c((0.7, 0.1, 0.16))
    skin = L.c((0.9, 0.66, 0.52))
    leather = L.c((0.42, 0.26, 0.15))
    h = L.head
    met = dict(metal=0.85, rough=0.32)
    if part == "torso":
        if L.idx == 3:
            # Gibão de couro sobre cota de malha (escudeiro jovem).
            m.ell((0, 0.38, 0), (0.31, 0.37, 0.23), L.c((0.5, 0.52, 0.56)), rough=0.5, metal=0.6)
            m.ell((0, 0.4, 0.0), (0.33, 0.33, 0.255), leather, group="vest")
            m.ball((0, 0.4, -0.3), 0.2, leather, group="vest", neg=True, stiff=3.0)
            m.ell((0, 0.12, 0), (0.3, 0.16, 0.24), L.c((0.45, 0.47, 0.5)), rough=0.5, metal=0.6)
            for i in range(4):
                m.hard("sphere", (0.0, 0.3 + i * 0.1, -0.24), 0.018, gold, **met, seg=8)
        else:
            m.ell((0, 0.38, 0), (0.33, 0.38, 0.25), steel, rough=0.35, metal=0.85)
            m.ell((0, 0.12, 0), (0.3, 0.16, 0.24), steel_d, rough=0.4, metal=0.8)
        # Tabardo azul com cruz dourada.
        m.hard("box", (0, 0.3, -0.255), (0.42, 0.55, 0.03), blue, bevel=0.01, rough=0.8)
        m.hard("box", (0, 0.32, -0.275), (0.08, 0.36, 0.02), gold, bevel=0.005, **met)
        m.hard("box", (0, 0.4, -0.275), (0.26, 0.07, 0.02), gold, bevel=0.005, **met)
        m.hard("box", (0, -0.12, -0.2), (0.36, 0.3, 0.03), blue, rot=(8, 0, 0), bevel=0.01, rough=0.8)
        # Cinto.
        m.hard("torus", (0, 0.04, 0), (0.29, 0.04), leather, seg=28)
        m.hard("box", (0, 0.04, -0.3), (0.1, 0.09, 0.03), gold, bevel=0.01, **met)
        # Ombreiras.
        for sx in (-1.0, 1.0):
            m.hard("sphere", (sx * 0.38, 0.6, 0), (0.2, 0.15, 0.2), lighten(steel, 0.08), **met, seg=18)
            m.hard("torus", (sx * 0.38, 0.55, 0), (0.18, 0.02), gold, **met, seg=20)
            if L.spiky:
                m.hard("spike", (sx * 0.42, 0.7, 0), (0.05, 0.25, 0.0), steel_d, rot=(0, 0, sx * -30), **met, seg=8)
        m.hard("torus", (0, 0.72, 0), (0.17, 0.035), leather, seg=20)
        return finish(m, L, budget=1200, res=0.02)
    if part == "head":
        if L.idx in (1, 2):
            # Elmo aberto: rosto à mostra (olhos grandes), bem cartunesco.
            hr = 0.3 * h
            m.ball((0, 0.28 * h, 0), hr, skin, group="face")
            m.paint((0, 0.2 * h, -hr), (0.06, 0.04, 0.05), L.c((1.0, 0.55, 0.5)), soft=0.6)
            for sx in (-1.0, 1.0):
                m.paint((sx * 0.17 * h, 0.17 * h, -hr * 0.85), (0.06, 0.04, 0.05), L.c((1.0, 0.55, 0.55)), soft=0.9)
            eyes(m, L, 0.3 * h, -hr * 0.88, 0.1 * h, 0.06 * h, iris=(0.15, 0.3, 0.6))
            m.ell((0, 0.36 * h, 0.03), (hr * 1.1, hr * 0.98, hr * 1.1), steel, group="helm", metal=0.85, rough=0.32)
            m.ball((0, 0.24 * h, -hr * 0.75), hr * 0.85, steel, group="helm", neg=True, stiff=3.0)
            # Aba do elmo em arco sobre a testa.
            m.hard("torus", (0, 0.36 * h + hr * 0.12, -0.02), (hr * 1.02, 0.035), steel_d, rot=(-12, 0, 0), seg=28, **met)
            # Topete vermelho.
            for i in range(5):
                m.hard("sphere", (0, 0.36 * h + hr * 0.95 - i * 0.025, 0.02 + i * 0.07), (0.05, 0.1, 0.09), red, rot=(-30 + i * 20, 0, 0), seg=12)
            m.hard("box", (0, 0.36 * h + hr * 0.9, 0.0), (0.04, 0.1, 0.12), gold, **met, bevel=0.005)
        elif L.idx == 3:
            # Escudeiro jovem: rosto, cabelo desgrenhado e capuz baixado no pescoço.
            hr = 0.27 * h
            hair = L.c((0.42, 0.24, 0.12))
            m.ball((0, 0.3 * h, 0), hr, skin, group="face")
            m.ell((0, 0.2 * h, -hr * 0.55), (hr * 0.62, hr * 0.5, hr * 0.5), skin, group="face")
            m.ell((0, 0.27 * h, -hr * 1.0), (0.035, 0.045, 0.04), skin, group="face")
            for sx in (-1.0, 1.0):
                m.ell((sx * hr * 0.98, 0.3 * h, 0.0), (0.04, 0.07, 0.05), skin, group="face")
                m.paint((sx * 0.12 * h, 0.22 * h, -hr * 0.82), (0.05, 0.035, 0.04), L.c((1.0, 0.6, 0.55)), soft=0.9)
                m.hard("box", (sx * 0.085 * h, 0.4 * h, -hr * 0.93), (0.085, 0.022, 0.02), hair, rot=(0, 0, sx * -10), bevel=0.004)
            eyes(m, L, 0.33 * h, -hr * 0.9, 0.085 * h, 0.045 * h, iris=(0.2, 0.35, 0.6))
            m.hard("box", (0, 0.17 * h, -hr * 0.97), (0.07, 0.012, 0.012), L.c((0.55, 0.25, 0.2)), bevel=0)
            # Cabelo: capa sobre o crânio + mechas.
            m.ell((0, 0.4 * h, 0.03), (hr * 1.06, hr * 0.72, hr * 1.08), hair, group="hair")
            m.ball((0, 0.28 * h, -hr * 0.8), hr * 0.78, hair, group="hair", neg=True, stiff=3.0)
            # Mechas lisas fundidas ao cabelo (as pontas finas ficavam pretas de tanta oclusão).
            for i in range(6):
                a = math.radians(-75 + i * 30)
                m.ell((math.sin(a) * hr * 0.75, 0.5 * h + (i % 2) * 0.03, -math.cos(a) * hr * 0.5 + 0.06), (0.07, 0.06, 0.11), hair, rot=(25, math.degrees(a), 0), group="hair")
            for i in range(3):
                m.ell(((i - 1) * 0.1, 0.47 * h, -hr * 0.8), (0.07, 0.045, 0.06), hair, rot=(-20, 0, (i - 1) * 25), group="hair")
            # Capuz baixado (azul) em volta do pescoço.
            m.ell((0, 0.04, 0.06), (hr * 1.05, 0.09, hr * 0.95), blue, group="hood")
            m.ell((0, 0.08, 0.2), (hr * 0.8, 0.14, 0.1), blue, group="hood")
        else:
            # Elmo fechado com visor (heróico / sombrio).
            hr = 0.29 * h
            m.hard("sphere", (0, 0.3 * h, 0), (hr * 1.02, hr * 1.1, hr * 1.08), lighten(steel, 0.08), seg=24, **met)
            m.hard("cyl", (0, 0.18 * h, -0.01), (hr * 1.0, hr * 1.06, 0.15), steel, seg=24, bevel=0.02, **met)
            m.hard("box", (0, 0.3 * h, -hr * 1.02), (hr * 1.3, 0.05, 0.08), L.c(DARK), bevel=0.01)
            m.hard("box", (0, 0.2 * h, -hr * 1.02), (0.04, 0.16, 0.06), L.c(DARK), bevel=0.005)
            vis = glow(L.c((0.5, 0.85, 1.0))) if L.idx == 4 else L.c(DARK)
            m.hard("box", (0, 0.3 * h, -hr * 1.06), (hr * 1.1, 0.025, 0.02), vis, bevel=0)
            m.hard("box", (0, 0.3 * h + hr * 0.6, 0), (0.035, hr * 0.4, hr * 1.6), gold, bevel=0.01, **met)
            for i in range(5):
                m.hard("sphere", (0, 0.3 * h + hr * 1.05 - i * 0.02, -0.05 + i * 0.08), (0.05, 0.1, 0.1), red if L.idx != 4 else L.c((0.15, 0.15, 0.2)), rot=(-30 + i * 22, 0, 0), seg=12)
            if L.spiky:
                for sx in (-1.0, 1.0):
                    m.hard("spike", (sx * hr * 0.9, 0.35 * h, 0), (0.05, 0.3, 0.4), steel_d, rot=(0, 0, sx * -65), **met, seg=8)
        return finish(m, L, budget=1400, res=0.016)
    if part == "leg":
        lk = L.limb
        m.limb((0, 0, 0), (0, -0.32, -0.02), 0.1 * lk, steel_d, r2=0.085 * lk, metal=0.85, rough=0.35)
        m.ball((0, -0.32, -0.04), 0.1 * lk, steel, metal=0.85, rough=0.3)
        m.limb((0, -0.34, -0.02), (0, -0.6, 0.0), 0.085 * lk, steel, metal=0.85, rough=0.3)
        m.ell((0, -0.66, -0.06), (0.11 * lk, 0.07, 0.18), leather, group="boot")
        m.hard("box", (0, -0.6, -0.02), (0.2, 0.1, 0.22), darken(leather, 0.15), bevel=0.02)
        return finish(m, L, budget=500, res=0.016)
    if part == "arm_sword":
        lk = L.limb
        m.limb((0, 0, 0), (0, -0.48, -0.02), 0.08 * lk, steel_d, r2=0.07 * lk, metal=0.85, rough=0.35)
        m.ell((0, -0.53, -0.02), (0.09, 0.08, 0.09), leather, group="hand")
        m.hard("cyl", (0, -0.55, 0.02), (0.035, 0.035, 0.28), leather, rot=(90, 0, 0), bevel=0, seg=10)
        m.hard("sphere", (0, -0.55, 0.17), 0.045, gold, **met, seg=12)
        m.hard("box", (0, -0.55, -0.13), (0.38, 0.05, 0.06), gold, bevel=0.012, **met)
        bl = glow(mix(L.c((0.9, 0.95, 1.0)), (0.6, 0.85, 1.0), 0.3)) if L.idx == 4 else L.c((0.88, 0.92, 1.0))
        blade = (0.11, 0.03, 1.3)
        m.hard("blade", (0, -0.55, -0.16), blade, bl if L.idx != 4 else L.c((0.6, 0.62, 0.7)), metal=0.95, rough=0.15)
        if L.idx == 4:
            m.hard("box", (0, -0.55, -0.7), (0.025, 0.035, 0.95), bl, bevel=0)
        return finish(m, L, budget=700, res=0.016)
    if part == "arm_shield":
        lk = L.limb
        m.limb((0, 0, 0), (0, -0.46, -0.04), 0.08 * lk, steel_d, r2=0.07 * lk, metal=0.85, rough=0.35)
        m.ball((0, -0.5, -0.08), 0.08, leather, group="hand")
        # Escudo heráldico (gota) curvo.
        sc = (0, -0.38, -0.24)
        m.hard("sphere", sc, (0.38, 0.46, 0.08), blue, rough=0.6, seg=28)
        m.hard("torus", (sc[0], sc[1], sc[2] - 0.01), (0.39, 0.035), gold, rot=(90, 0, 0), **met, seg=32)
        m.hard("box", (0, sc[1], sc[2] - 0.08), (0.07, 0.6, 0.04), gold, bevel=0.01, **met)
        m.hard("box", (0, sc[1] + 0.1, sc[2] - 0.08), (0.48, 0.07, 0.04), gold, bevel=0.01, **met)
        m.hard("sphere", (0, sc[1] + 0.1, sc[2] - 0.1), (0.07, 0.07, 0.04), lighten(gold, 0.2), **met, seg=14)
        if L.spiky:
            m.hard("spike", (0, sc[1] + 0.1, sc[2] - 0.12), (0.05, 0.2, 0), steel_d, rot=(-90, 0, 0), **met, seg=8)
        return finish(m, L, budget=700, res=0.016)
    if part == "cape":
        # Capa com dobras (ondas de cor e de forma).
        for i in range(5):
            x = (i - 2) * 0.13
            m.ell((x, -0.5, 0.02 + (i % 2) * 0.03), (0.09, 0.52, 0.05), red, group="cape")
        m.ell((0, -0.05, 0.0), (0.32, 0.08, 0.06), red, group="cape")
        m.paint((0, -1.0, 0.05), (0.5, 0.12, 0.2), darken(red, 0.35), soft=0.8)
        m.hard("box", (0, -1.0, 0.04), (0.62, 0.05, 0.08), gold if L.idx != 4 else L.c((0.3, 0.3, 0.35)), bevel=0.01, **met)
        return finish(m, L, budget=800, res=0.02)
    raise KeyError(part)


UNITS = {
    "rat": lambda m, L: rat(m, L),
    "rat_king": lambda m, L: rat(m, L, 1.9, True),
    "bat": bat,
    "skeleton_archers": lambda m, L: skeleton(m, L, True),
    "skeleton": lambda m, L: skeleton(m, L, False),
    "goblin_dynamiter": goblin,
    "slime": slime,
    "bat_nest": nest,
    "bone_totem": totem,
    "cultists": cultist,
    "ogre": ogre,
    "mimic": mimic,
    "ghost": lambda m, L: ghost(m, L, (0.7, 0.88, 1.0)),
    "spectre": lambda m, L: ghost(m, L, (0.35, 1.0, 0.85)),
    "gargoyle_tower": tower,
    "werewolf": werewolf,
    "scrap_golem": golem,
}
HERO_PARTS = ["torso", "head", "leg", "arm_sword", "arm_shield", "cape"]
