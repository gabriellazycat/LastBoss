"""Cenário dos looks de chão (árvores, arbusto, pedra), um conjunto por look. Coordenadas da Godot.
Substituem Models.prop("tree" | "tree_round" | "dead_tree" | "bush" | "rock") quando look_ground > 0."""
import math
import random

from kit import darken, glow, lighten, mix

STYLE = dict(ao=0.6, ao_pow=1.2, sky=0.35, height=0.25, edge=0.3, noise=0.05, noise_freq=3.0, hue=0.6, cool=(0.6, 0.6, 0.85), warm=(1.0, 0.92, 0.7))


def _finish(m, budget, res):
    m.style = dict(STYLE)
    m.res = res
    m.blob_budget = budget
    m.detail = min(1.0, max(0.45, budget / 3000.0))
    return m


def trunk(m, base_r, top_r, h, col, bend=0.0, branches=(), seed=1):
    """Tronco afinando com curva e galhos (lista de (altura, ângulo, comprimento, inclinação))."""
    rnd = random.Random(seed)
    pts = []
    for i in range(5):
        t = i / 4
        pts.append((math.sin(t * 2.2) * bend, t * h, math.cos(t * 1.7) * bend * 0.5))
    for i in range(4):
        r = base_r + (top_r - base_r) * (i + 0.5) / 4
        m.limb(pts[i], pts[i + 1], r, col, group="trunk")
    # Raízes.
    for k in range(4):
        a = k * math.tau / 4 + rnd.random() * 0.6
        m.limb((0, 0.25, 0), (math.cos(a) * base_r * 2.2, 0.0, math.sin(a) * base_r * 2.2), base_r * 0.55, col, r2=base_r * 0.2, group="trunk")
    for (bh, ba, bl, bt) in branches:
        a = math.radians(ba)
        p0 = (math.sin(bh * 2.2) * bend, bh * h, 0)
        p1 = (p0[0] + math.cos(a) * bl, p0[1] + bl * bt, p0[2] + math.sin(a) * bl)
        m.limb(p0, p1, top_r * 0.8, col, r2=top_r * 0.35, group="trunk")
    return pts[-1]


def canopy(m, center, rx, ry, n, col, seed=1, top=None, group="leaves"):
    """Copa em cachos: n elipsoides em volta do centro, mais claros em cima."""
    rnd = random.Random(seed)
    cx, cy, cz = center
    m.ell(center, (rx * 0.72, ry * 0.68, rx * 0.72), col, group=group)
    # Cachos grandes e, por cima, calombos menores: a copa fica "folhuda" em vez de um balão liso.
    for i in range(n):
        a = rnd.random() * math.tau
        e = rnd.uniform(-0.5, 0.9)
        r = rnd.uniform(0.36, 0.5)
        p = (cx + math.cos(a) * rx * 0.66 * math.cos(e), cy + math.sin(e) * ry * 0.6, cz + math.sin(a) * rx * 0.66 * math.cos(e))
        m.ell(p, (rx * r, ry * r * 0.85, rx * r), col, group=group)
    for i in range(n * 2):
        a = rnd.random() * math.tau
        e = rnd.uniform(-0.3, 1.2)
        p = (cx + math.cos(a) * rx * 0.88 * math.cos(e), cy + math.sin(e) * ry * 0.82, cz + math.sin(a) * rx * 0.88 * math.cos(e))
        m.ball(p, rx * rnd.uniform(0.14, 0.22), col, group=group)
    # Manchas de verde mais claro e mais escuro (luz pintada).
    for i in range(n):
        a = rnd.random() * math.tau
        p = (cx + math.cos(a) * rx * 0.8, cy + rnd.uniform(-0.3, 0.8) * ry, cz + math.sin(a) * rx * 0.8)
        m.paint(p, rx * rnd.uniform(0.25, 0.4), lighten(col, 0.18) if i % 2 else darken(col, 0.2), soft=1.0, only=group)
    if top:
        m.paint((cx, cy + ry * 0.75, cz), (rx * 1.0, ry * 0.55, rx * 1.0), top, soft=1.0, only=group)
    m.paint((cx, cy - ry * 0.85, cz), (rx * 1.2, ry * 0.55, rx * 1.2), darken(col, 0.45), soft=1.0, only=group)


def boulder(m, s, col, moss=None, seed=1):
    rnd = random.Random(seed)
    m.ell((0, 0.28 * s, 0), (0.75 * s, 0.42 * s, 0.6 * s), col, rot=(0, 20, 6), group="rock")
    for i in range(3):
        a = rnd.random() * math.tau
        m.ell((math.cos(a) * 0.45 * s, 0.18 * s, math.sin(a) * 0.4 * s), (0.38 * s, 0.26 * s, 0.32 * s), darken(col, 0.08 * i), rot=(0, rnd.random() * 90, 10), group="rock")
    if moss:
        m.paint((0, 0.75 * s, 0), (0.9 * s, 0.35 * s, 0.8 * s), moss, soft=0.8)


# ------------------------------------------------------------------ por look

def ground_prop(m, g, pid):
    if g == 1:
        return _meadow(m, pid)
    if g == 2:
        return _moon(m, pid)
    if g == 3:
        return _autumn(m, pid)
    return _cursed(m, pid)


def _meadow(m, pid):
    bark = (0.42, 0.3, 0.2)
    leaf = (0.22, 0.45, 0.15)
    if pid == "tree":
        top = trunk(m, 0.22, 0.13, 2.6, bark, bend=0.12, branches=[(0.6, 40, 0.9, 0.7), (0.7, 200, 0.8, 0.8)], seed=3)
        canopy(m, (top[0], 3.4, top[2]), 1.55, 1.25, 9, leaf, seed=3, top=(0.48, 0.68, 0.25))
        for i in range(5):
            a = i * 1.3
            m.hard("sphere", (math.cos(a) * 1.3, 3.2 + (i % 3) * 0.4, math.sin(a) * 1.3), 0.07, (0.95, 0.85, 0.95), seg=8)
        return _finish(m, 2600, 0.07)
    if pid == "tree_round":
        top = trunk(m, 0.18, 0.12, 1.9, darken(bark, 0.1), bend=0.05, seed=5)
        canopy(m, (top[0], 2.75, top[2]), 1.3, 1.15, 7, (0.3, 0.5, 0.17), seed=5, top=(0.52, 0.7, 0.28))
        for i in range(7):
            a = i * 0.9
            m.hard("sphere", (math.cos(a) * 1.15, 2.4 + (i % 3) * 0.45, math.sin(a) * 1.15), 0.09, (0.9, 0.2, 0.15), seg=8)
        return _finish(m, 2200, 0.065)
    if pid == "dead_tree":
        trunk(m, 0.32, 0.22, 0.8, bark, seed=7)
        m.ell((0, 0.85, 0), (0.33, 0.06, 0.33), (0.75, 0.6, 0.42), group="cut")
        m.paint((0, 0.4, 0.3), (0.4, 0.3, 0.2), (0.3, 0.5, 0.2), soft=0.8)
        for i in range(3):
            m.hard("cyl", (0.25 + i * 0.08, 0.92, 0.1 * i), (0.012, 0.012, 0.12), (0.95, 0.92, 0.85), seg=6, bevel=0)
            m.hard("sphere", (0.25 + i * 0.08, 0.99, 0.1 * i), (0.06, 0.035, 0.06), (0.85, 0.25, 0.2), seg=10)
        return _finish(m, 1400, 0.05)
    if pid == "bush":
        canopy(m, (0, 0.35, 0), 0.55, 0.38, 5, (0.32, 0.55, 0.22), seed=9, top=(0.55, 0.75, 0.3))
        for i in range(6):
            a = i * 1.1
            m.hard("sphere", (math.cos(a) * 0.45, 0.4 + (i % 2) * 0.2, math.sin(a) * 0.45), 0.045, (1.0, 0.85, 0.3), seg=8)
        return _finish(m, 900, 0.04)
    boulder(m, 1.0, (0.55, 0.55, 0.52), moss=(0.35, 0.55, 0.25), seed=11)
    return _finish(m, 900, 0.045)


def _moon(m, pid):
    bark = (0.2, 0.18, 0.2)
    if pid == "tree":
        # Pinheiro escuro: camadas de cones com borda azulada.
        trunk(m, 0.18, 0.08, 1.4, bark, seed=13)
        for i in range(5):
            r = 1.5 - i * 0.26
            y = 1.3 + i * 0.75
            m.hard("cone", (0, y, 0), (r, 1.25), mix((0.06, 0.2, 0.22), (0.12, 0.32, 0.34), i / 4), rot=(0, i * 23, 0), seg=10, bevel=0.06)
        m.paint((0, 5.0, 0), (1.0, 1.0, 1.0), (0.3, 0.55, 0.6), soft=1.0)
        return _finish(m, 1400, 0.06)
    if pid == "tree_round":
        # Salgueiro azul com cachos caídos e vaga-lumes presos.
        top = trunk(m, 0.2, 0.12, 2.0, bark, bend=0.15, seed=15)
        canopy(m, (top[0], 2.9, top[2]), 1.4, 0.9, 7, (0.1, 0.22, 0.22), seed=15, top=(0.22, 0.42, 0.4))
        for i in range(14):
            a = i * math.tau / 14 + (i % 2) * 0.2
            m.limb((math.cos(a) * 1.2, 2.55, math.sin(a) * 1.2), (math.cos(a) * 1.38, 1.3 + (i % 3) * 0.3, math.sin(a) * 1.38), 0.07, (0.1, 0.22, 0.2), r2=0.03, group="drape")
        for i in range(6):
            a = i * 1.7
            m.hard("sphere", (math.cos(a) * 1.0, 2.2 + (i % 3) * 0.35, math.sin(a) * 1.0), 0.06, glow((0.6, 1.0, 0.85)), seg=8)
        return _finish(m, 2400, 0.065)
    if pid == "dead_tree":
        trunk(m, 0.16, 0.08, 2.8, (0.24, 0.22, 0.26), bend=0.25, branches=[(0.55, 30, 1.0, 0.5), (0.7, 170, 0.9, 0.6), (0.85, 300, 0.7, 0.8)], seed=17)
        for i in range(4):
            a = i * 1.6
            m.hard("cyl", (math.cos(a) * 0.4, 0.08, math.sin(a) * 0.4), (0.03, 0.04, 0.16), (0.85, 0.85, 0.9), seg=6, bevel=0)
            m.hard("sphere", (math.cos(a) * 0.4, 0.2, math.sin(a) * 0.4), (0.1, 0.05, 0.1), glow((0.3, 0.85, 1.0)), seg=10)
        return _finish(m, 1600, 0.04)
    if pid == "bush":
        for i in range(7):
            a = i * math.tau / 7
            m.ell((math.cos(a) * 0.3, 0.3, math.sin(a) * 0.3), (0.1, 0.35, 0.06), (0.1, 0.3, 0.28), rot=(math.sin(a) * 35, 0, -math.cos(a) * 35), group="fern")
        for i in range(4):
            m.hard("sphere", (math.cos(i * 1.6) * 0.2, 0.45, math.sin(i * 1.6) * 0.2), 0.05, glow((0.4, 0.8, 1.0)), seg=8)
        return _finish(m, 900, 0.035)
    boulder(m, 1.0, (0.32, 0.36, 0.42), moss=(0.15, 0.4, 0.38), seed=19)
    m.hard("box", (0.0, 0.62, -0.25), (0.14, 0.02, 0.05), glow((0.4, 0.9, 1.0)), rot=(0, 30, 0), bevel=0)
    return _finish(m, 900, 0.045)


def _autumn(m, pid):
    bark = (0.35, 0.24, 0.17)
    if pid == "tree":
        top = trunk(m, 0.22, 0.13, 2.6, bark, bend=0.15, branches=[(0.55, 60, 1.0, 0.6), (0.75, 230, 0.8, 0.7)], seed=21)
        canopy(m, (top[0], 3.4, top[2]), 1.6, 1.2, 9, (0.85, 0.42, 0.12), seed=21, top=(1.0, 0.72, 0.25))
        return _finish(m, 2600, 0.07)
    if pid == "tree_round":
        top = trunk(m, 0.16, 0.1, 2.0, (0.75, 0.72, 0.68), bend=0.06, seed=23)
        m.paint((0, 1.0, 0), (0.25, 1.2, 0.25), (0.82, 0.8, 0.76), soft=0.5)
        canopy(m, (top[0], 2.8, top[2]), 1.25, 1.2, 7, (0.95, 0.68, 0.15), seed=23, top=(1.0, 0.85, 0.35))
        return _finish(m, 2200, 0.065)
    if pid == "dead_tree":
        trunk(m, 0.15, 0.07, 2.6, bark, bend=0.2, branches=[(0.5, 20, 0.9, 0.6), (0.65, 150, 0.8, 0.7), (0.8, 260, 0.6, 0.9)], seed=25)
        for i in range(4):
            a = i * 1.5
            m.hard("sphere", (0.3 + math.cos(a) * 0.5, 2.0 + i * 0.2, math.sin(a) * 0.5), (0.08, 0.02, 0.06), (0.9, 0.45, 0.12), rot=(30, i * 40, 0), seg=8)
        return _finish(m, 1600, 0.04)
    if pid == "bush":
        canopy(m, (0, 0.35, 0), 0.55, 0.38, 5, (0.75, 0.18, 0.12), seed=27, top=(0.95, 0.45, 0.2))
        return _finish(m, 900, 0.04)
    boulder(m, 1.0, (0.5, 0.46, 0.42), seed=29)
    for i in range(5):
        a = i * 1.2
        m.hard("sphere", (math.cos(a) * 0.5, 0.55 + (i % 2) * 0.1, math.sin(a) * 0.4), (0.09, 0.015, 0.06), (0.95, 0.5 + (i % 3) * 0.12, 0.12), rot=(10, i * 50, 0), seg=8)
    return _finish(m, 900, 0.045)


def _cursed(m, pid):
    bark = (0.12, 0.09, 0.11)
    crack = glow((1.0, 0.3, 0.85))
    if pid == "tree":
        trunk(m, 0.26, 0.1, 3.2, bark, bend=0.35, branches=[(0.5, 30, 1.3, 0.4), (0.62, 160, 1.1, 0.6), (0.78, 260, 1.0, 0.8), (0.9, 90, 0.8, 0.9)], seed=31)
        for i in range(4):
            m.hard("box", (math.sin(i * 1.3) * 0.1, 0.5 + i * 0.55, -0.2), (0.04, 0.32, 0.02), crack, rot=(0, i * 40, i * 10), bevel=0)
        return _finish(m, 1800, 0.05)
    if pid == "tree_round":
        # Aglomerado de cristais roxos que brilham por dentro.
        rnd = random.Random(33)
        m.ell((0, 0.2, 0), (0.9, 0.3, 0.8), (0.18, 0.14, 0.18), group="base")
        for i in range(9):
            a = rnd.random() * math.tau
            r = rnd.uniform(0.0, 0.6)
            h = rnd.uniform(1.0, 2.8)
            m.hard("cone", (math.cos(a) * r, h * 0.45, math.sin(a) * r), (rnd.uniform(0.18, 0.3), h), (0.55, 0.2, 0.75, 0.55), rot=(math.cos(a) * 20 * r, rnd.random() * 90, -math.sin(a) * 20 * r), seg=6, bevel=0.02, smooth=False)
        return _finish(m, 1000, 0.05)
    if pid == "dead_tree":
        trunk(m, 0.2, 0.1, 1.4, bark, bend=0.1, seed=35)
        for i in range(8):
            a = i * math.tau / 8
            m.hard("spike", (math.cos(a) * 0.18, 0.4 + (i % 3) * 0.3, math.sin(a) * 0.18), (0.05, 0.45, 0.3), darken(bark, 0.2), rot=(math.sin(a) * 70, 0, -math.cos(a) * 70), seg=8)
        return _finish(m, 1200, 0.04)
    if pid == "bush":
        for i in range(9):
            a = i * math.tau / 9
            m.hard("spike", (0, 0.05, 0), (0.04, 0.7, 0.25), (0.2, 0.12, 0.15), rot=(math.sin(a) * 50, math.degrees(a), -math.cos(a) * 50), seg=8)
        m.hard("sphere", (0, 0.2, 0), 0.07, crack, seg=10)
        return _finish(m, 600, 0.04)
    boulder(m, 1.0, (0.22, 0.18, 0.22), seed=37)
    for i in range(3):
        m.hard("cone", (0.2 * i - 0.2, 0.55, 0.1 * i), (0.08, 0.45), (0.65, 0.2, 0.8, 0.5), rot=(10 - i * 10, 0, 15 - i * 15), seg=6, smooth=False)
    return _finish(m, 900, 0.045)


PROPS = ["tree", "tree_round", "dead_tree", "bush", "rock"]
