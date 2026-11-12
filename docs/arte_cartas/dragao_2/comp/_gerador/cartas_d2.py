"""Composições do lote dragao_2 (Ganância/ouro). Coordenadas de carta 300x420; janela 11..289 x 11..278; fita y >= 261.
Reaproveita (só leitura) Card (praga_3), sky/disk/rings/ground (praga_2), speedlines/dust/rng/RECT (praga_1), hero (praga_1),
fogo/brasas/faíscas (dragao_1), goblin (dragao_1). Fichas novas: mimic (mimico.svg), guard (guardiao.svg); poses novas do
herói em hero2.py. Uso: python cartas_d2.py [ids...]"""
import base  # noqa: F401
import sys, math
import numpy as np
from geom import *
from rat import mix
from cards import speedlines, dust, rng, RECT
from cartas import sky, disk, rings, ground
from cartas3 import Card, stones
from cartas_d1 import fire, embers, sparks, star, flame, FIRE, FIRE_C, FIRE_D
import goblin, mimic, guard, hero2

INK = "#2b1a10"
GOLD = "#e8b23a"; GOLD_D = "#a8741e"; GOLD_L = "#ffe08a"; GOLD_W = "#fff6c8"
CURSE = "#9a4ad0"; CURSE_L = "#d8a0ff"; CURSE_D = "#5a2088"
ELIX = "#c04ae0"; ELIX_L = "#f0b0ff"


# ---------------------------------------------------------------- ouro
def coin(c, x, y, r, tilt=0.45, rot=0, name="moeda", layer="b", op=None, edge=True):
    add = c.b if layer == "b" else c.f
    if edge:
        add(name, GOLD_D, ellipse(x, y + r * 0.18, r, r * tilt, rot, 10), op=op)
    add(name, GOLD, ellipse(x, y, r, r * tilt, rot, 10), op=op)
    add(name + "_luz", GOLD_L, ellipse(x - r * 0.25, y - r * tilt * 0.25, r * 0.45, r * tilt * 0.4, rot, 8), op=op)


def coin_face(c, x, y, r, ang, name="moeda_ar", op=None):
    """Moeda no ar, girando (elipse com eixo em ângulo `ang`)."""
    w = 0.25 + abs(math.sin(math.radians(ang * 2.3))) * 0.75
    c.f(name, GOLD_D, ellipse(x + 0.6, y + 0.6, r, r * w, ang, 10), op=op)
    c.f(name, GOLD, ellipse(x, y, r, r * w, ang, 10), op=op)
    c.f(name, GOLD_L, ellipse(x - r * 0.2, y - r * 0.2 * w, r * 0.4, r * w * 0.35, ang, 8), op=op)


def pile(c, cx, cy, w, h, seed, name="monte", n=26, layer="b", dark=GOLD_D):
    add = c.b if layer == "b" else c.f
    r = rng(seed)
    pts = [(cx - w / 2, cy), (cx - w * 0.36, cy - h * 0.42), (cx - w * 0.14, cy - h * 0.86), (cx + w * 0.06, cy - h),
           (cx + w * 0.26, cy - h * 0.74), (cx + w * 0.42, cy - h * 0.34), (cx + w / 2, cy), (cx, cy + h * 0.08)]
    add(name, dark, pts)
    add(name + "_luz", GOLD, [(cx - w * 0.44, cy - h * 0.06), (cx - w * 0.3, cy - h * 0.46), (cx - w * 0.1, cy - h * 0.86),
                              (cx + w * 0.04, cy - h * 0.94), (cx + w * 0.14, cy - h * 0.6), (cx + w * 0.06, cy - h * 0.2), (cx - w * 0.2, cy)])
    for i in range(n):
        t = r.random(); u = r.random()
        x = cx + (t - 0.5) * w * 0.9; top = h * (1 - abs(t - 0.5) * 1.9)
        y = cy - top * u
        coin(c, x, y, 3.2 + r.random() * 2.4, 0.42, r.normal(0, 12), name=name + "_moeda", layer=layer)


def glints(c, pts, R=6, col=GOLD_W, op=1.0):
    for (x, y, s) in pts:
        star(c, x, y, R * s, R * s * 0.22, 4, col, rot=45 * 0 + 0, op=op, name="brilho")


def wisp(c, pts, w0, w1, col, op=0.7, name="maldicao"):
    c.f(name, col, brush(pts, w0, w1), op=op)


def drop(x, y, r, ang=0):
    """Gota (elixir) apontando para cima (ang=0) — ponta em -y."""
    pts = [(0, -r * 2.0), (r * 0.62, -r * 0.7), (r, 0.1 * r), (r * 0.7, r * 0.75), (0, r), (-r * 0.7, r * 0.75), (-r, 0.1 * r), (-r * 0.62, -r * 0.7)]
    return list(ap(tmat(x, y, ang), pts))


# =========================================================================== MÍMICO
def mimic_card():
    c = Card("mimic")
    sky(c, "#1c1e2c", "#46465c")
    # o cenário: pilar de pedra com tocha na parede (direita); a luz da tocha é o halo atrás da tampa
    disk(c, "luz_tocha", 176, 92, 70, "#7a5a4a")
    c.b("luz_tocha2", "#b07a50", ellipse(176, 92, 44, 44, 0, 16), op=0.7)
    c.b("pilar", "#3a3a4c", [(236, -10), (296, -10), (300, 300), (232, 300)], mode="poly")
    c.b("pilar_luz", "#52526a", [(236, -10), (250, -10), (246, 300), (232, 300)], mode="poly", op=0.8)
    stones(c, 232, -10, 300, 236, INK, 41, rows=9, cols=2, op=0.35)
    c.b("tocha_cabo", "#5a3a22", [(238, 120), (250, 118), (226, 74), (220, 78)], mode="poly")
    fire(c, 220, 80, 30, 16, -2, 77, op=0.95)
    c.b("chao", "#2a2a36", [(-10, 222), (310, 210), (310, 300), (-10, 300)], mode="poly")
    c.b("chao_luz", "#3c3c4c", [(40, 226), (240, 216), (250, 232), (30, 244)], mode="poly", op=0.8)
    # moedas espalhadas no chão (ele estava no meio do tesouro)
    r = rng(5)
    for i in range(16):
        coin(c, 20 + r.random() * 250, 228 + r.random() * 26, 3 + r.random() * 2.6, 0.4, r.normal(0, 10), name="moeda_chao")
    # efeito atrás: linhas de velocidade do bote (da esquerda-baixo), poeira
    for i in range(10):
        y = 120 + i * 13; x0 = 4 + (i % 3) * 8
        c.f("veloc", "#8a8aa8", wedge(x0, y + 20, x0 + 34 + (i % 4) * 9, y + 4, 2.6), mode="poly", op=0.55)
    dust(c, 70, 236, 30, 14, "#6a6a80", 51, (2, 5), op=0.6)
    # moedas jorrando da boca (atrás da figura) e faíscas de maldição roxas em volta da língua
    M = tmat(126, 222, 8, 2.6)
    mouth = ap(M, [(0, -26)])[0]
    for i in range(9):
        a = math.radians(-150 + i * 22); d = 40 + r.random() * 34
        coin_face(c, mouth[0] + math.cos(a) * d, mouth[1] + math.sin(a) * d * 0.8 - 10, 4 + r.random() * 2.4, r.random() * 180)
    tip = ap(M, [mimic.POSES["bote"]["tongue"][-1]])[0]
    for i in range(8):
        a = r.random() * 2 * math.pi; d = 8 + r.random() * 18
        star(c, tip[0] + math.cos(a) * d, tip[1] + math.sin(a) * d, 4.5, 1.2, 4, CURSE_L, op=0.95, name="maldicao")
    c.f("maldicao_aura", CURSE, ellipse(tip[0], tip[1], 20, 16, 0, 12), op=0.35)
    c.fig("mimico", mimic.pose("bote"), 126, 222, 8, 2.6, guide=mimic.GUIDE["bote"])
    c.save()


# =========================================================================== BAÚ ARMADILHA
def trap_chest():
    c = Card("trap_chest")
    sky(c, "#2a1016", "#5a2a22")
    # cenário: coluna de pedra rachada (esquerda, fundo)
    c.b("coluna", "#4a2e2e", [(14, -10), (52, -10), (56, 200), (10, 206)], mode="poly")
    c.b("coluna_racha", INK, [(30, 40), (38, 70), (28, 96), (36, 130)], closed=False, sw=1.2, op=0.6)
    c.b("capitel", "#5a3a36", [(6, 20), (60, 20), (56, 36), (10, 36)], mode="poly")
    c.b("chao", "#2e1a1a", [(-10, 214), (310, 204), (310, 300), (-10, 300)], mode="poly")
    # explosão saindo da boca do baú (atrás do baú e do herói): 3 camadas + raios + moedas
    CX, CY = 128, 150
    r = rng(9)
    for i in range(14):
        a = math.radians(-180 + i * 13 + r.normal(0, 4)); L = 90 + r.random() * 70
        c.f("raio", "#ffd890", wedge(CX + math.cos(a) * L, CY + math.sin(a) * L, CX + math.cos(a) * 30, CY + math.sin(a) * 30, 7), mode="poly", op=0.7)
    c.f("fogo", FIRE_D, blob(CX, CY, 74, 3, 13, 0.24, 0.9), op=0.95)
    c.f("fogo", FIRE, blob(CX - 2, CY + 4, 54, 4, 12, 0.22, 0.9))
    c.f("fogo", FIRE_C, blob(CX - 4, CY + 8, 32, 6, 10, 0.2, 0.85))
    c.f("fogo", "#ffffff", blob(CX - 4, CY + 14, 14, 7, 8, 0.2, 0.8), op=0.9)
    for i in range(16):
        a = math.radians(-170 + r.random() * 160); d = 60 + r.random() * 70
        coin_face(c, CX + math.cos(a) * d, CY + math.sin(a) * d, 4 + r.random() * 2.6, r.random() * 180)
    embers(c, 30, 30, 260, 200, 24, 91, ang=-100, L=(4, 10))
    # o baú: mesmo baú do mímico (fechado, sem dentes), a tampa arrancada girando para cima-esquerda
    c.fig("bau", mimic.pose("fechado", lid_off=(-18, -46, -32), lock=True), 128, 236, 6, 2.3)
    # o herói de costas, na frente à direita, golpe de duas mãos que acabou de acertar (contraluz)
    c.fig("heroi", hero2.pose("golpe_costas"), 238, 300, 4, 1.18, guide=hero2.GUIDE["golpe_costas"])
    c.save()


# =========================================================================== MERCENÁRIO GOBLIN
def _cutlass(wr, el, a=-150):
    d = A(wr) - A(el); d = d / np.linalg.norm(d)
    M = chain(T(*(A(wr) + d * 2.6)), R(a))
    p = goblin.PAL
    pcs = [Pc("cabo", "cimitarra", "#5a3a22", [(-4, -1.3), (3, -1.3), (3, 1.3), (-4, 1.3)], mode="poly"),
           Pc("guarda", "cimitarra", p["gold"], [(3, -4.4), (5, -4.4), (5, 4.4), (3, 4.4)], mode="poly"),
           Pc("lamina", "cimitarra", "#d8dee6", [(5, -2), (20, -3.4), (34, -1.4), (42, 4.4), (34, 3.6), (20, 2.6), (5, 2)]),
           Pc("fio", "cimitarra", "#8a909a", [(8, 1.2), (22, 1.6), (36, 3.2)], closed=False, cls="inner", sw=0.4)]
    return [q.moved(M) for q in pcs]


def _purse(wr, el):
    p = goblin.PAL
    c = A(wr) + (0, 7)
    pcs = [Pc("bolsa", "bolsa", "#8a5a2a", [c + (-6, -4), c + (-1, -6), c + (2, -7), c + (6, -4), c + (8, 3), c + (5, 9), c + (-4, 9), c + (-8, 3)]),
           Pc("bolsa_no", "bolsa", "#c8a060", [c + (-3, -6), c + (3, -6.4)], closed=False, cls="inner", sw=1.2),
           Pc("bolsa_moeda", "bolsa", p["gold"], ellipse(c[0] + 1, c[1] + 2, 2.6, 2.6, 0, 8), cls="inner")]
    return pcs


def gold_merc():
    c = Card("gold_merc")
    sky(c, "#24183a", "#5a3a64")
    disk(c, "halo", 196, 84, 58, "#c89a4a", "#f2d27a")
    # cenário: monte de ouro de onde ele salta (embaixo à esquerda) e a pilha de moedas ao fundo
    pile(c, 70, 262, 190, 70, 3, n=30)
    pile(c, 252, 240, 120, 44, 4, n=14)
    # efeito: moedas que ele chuta para trás no salto e brilho de ganância
    r = rng(17)
    for i in range(12):
        x = 30 + r.random() * 120; y = 150 + r.random() * 80
        coin_face(c, x, y, 3.8 + r.random() * 2, r.random() * 180)
    for i in range(8):
        y = 160 + i * 11; x0 = 20 + (i % 3) * 10
        c.f("veloc", "#f2d27a", wedge(x0, y + 26, x0 + 30 + (i % 4) * 8, y + 4, 2.4), mode="poly", op=0.5)
    glints(c, [(214, 60, 1.4), (120, 50, 1.0), (240, 130, 0.9), (90, 120, 0.8)])
    over = dict(props_n=lambda w, e: _cutlass(w, e, -118), props_f=_purse, wn=(10, -86), wf=(-18, -64), ebf=1, hdf=120, fistf=True, hdn=-80,
                head=(16, -70, 14), open=True)
    J = dict(goblin.POSES["saltar"]); J.update(over)
    pcs = goblin.goblin(J)
    # elmo de ferro amassado com cravos de ouro (peça da cabeça)
    hx, hy, ha = J["head"]
    Mh = tmat(hx, hy, ha)
    helm = [(-10.6, -2), (-9.6, -9), (-4, -13.4), (3, -13.4), (9, -10), (11.6, -4.4), (12.4, -1.6), (4, -4.2), (-2, -4.6)]
    pcs.append(Pc("elmo", "cabeca", "#7a7a86", list(ap(Mh, helm))))
    pcs.append(Pc("elmo_cravo", "cabeca", goblin.PAL["gold"], list(ap(Mh, [(-3, -13), (-1, -17.6), (1, -13)])), mode="poly"))
    pcs.append(Pc("elmo_borda", "cabeca", goblin.PAL["gold"], list(ap(Mh, [(-10.4, -2.4), (-2, -4.8), (4, -4.4), (12.2, -1.8)])), closed=False, cls="inner", sw=1.4))
    c.fig("goblin", pcs, 160, 250, -12, 2.5, guide=goblin.GUIDE["saltar"])
    c.save()


# =========================================================================== ISCA DE OURO
def gold_bait():
    c = Card("gold_bait")
    sky(c, "#3a2c5a", "#b88aa0")
    c.b("mata", "#2e2846", [(-10, 120), (20, 96), (44, 110), (70, 84), (100, 104), (140, 80), (180, 100), (220, 76), (260, 96), (310, 80), (310, 170), (-10, 170)])
    ground(c, "chao", "#5a4a5e", 150, 140)
    # o cenário: a estrada (que ele abandonou) curvando para o fundo, à direita, com a placa de rota
    c.b("estrada", "#9a8a8a", [(236, 300), (262, 230), (276, 180), (282, 146), (310, 140), (310, 300)])
    c.b("placa_poste", "#5a3a22", [(272, 112), (278, 112), (278, 176), (272, 176)], mode="poly")
    c.b("placa", "#8a6034", [(256, 112), (288, 110), (298, 118), (288, 126), (256, 126)], mode="poly")
    # trilha de moedas da estrada até o monte (embaixo à esquerda)
    for i, t in enumerate(np.linspace(0, 1, 9)):
        x = 262 - t * 180 + math.sin(t * 6) * 10; y = 186 + t * 40
        coin(c, x, y, 3.2 + t * 2.2, 0.42, 0, name="trilha")
    # efeito atrás: raios dourados saindo do monte
    PX, PY = 62, 236
    r = rng(23)
    for i in range(11):
        a = math.radians(-170 + i * 15); L = 80 + r.random() * 60
        c.f("raio", GOLD_L, wedge(PX + math.cos(a) * L, PY + math.sin(a) * L, PX + math.cos(a) * 26, PY + math.sin(a) * 26, 10), mode="poly", op=0.45)
    c.f("brilho_monte", "#fff0b0", ellipse(PX, PY - 20, 60, 44, 0, 14), op=0.45)
    pile(c, PX, PY + 14, 110, 58, 8, n=26, layer="f")
    # o fio de cobiça: fita dourada do monte até o elmo do herói
    M = tmat(184, 238, -6, 0.98)
    hd = ap(M, [hero2.J("atraido")["head"]])[0]
    wisp(c, [(PX + 10, PY - 40), (100, 150), (140, 128), (hd[0] - 12, hd[1] - 4)], 6, 1.4, GOLD_L, op=0.75, name="cobica")
    wisp(c, [(PX + 2, PY - 34), (88, 170), (130, 150), (hd[0] - 10, hd[1] + 4)], 4, 1.0, GOLD, op=0.6, name="cobica")
    glints(c, [(PX - 14, PY - 34, 1.5), (PX + 22, PY - 22, 1.1), (PX - 34, PY - 8, 0.9), (PX + 6, PY - 46, 0.8)])
    c.fig("heroi", hero2.pose("atraido"), 184, 238, -6, 0.98, guide=hero2.GUIDE["atraido"])
    c.save()


# =========================================================================== PEDÁGIO
def toll():
    c = Card("toll")
    sky(c, "#7aa0b8", "#f0dcae")
    c.b("morros", "#a8b48a", [(-10, 170), (60, 150), (130, 162), (200, 140), (310, 156), (310, 210), (-10, 210)], op=0.85)
    ground(c, "chao", "#b89a6a", 196, 188)
    c.b("estrada", "#d8c090", [(-10, 250), (310, 222), (310, 246), (-10, 290)], mode="poly")
    # o cenário: posto do pedágio — poste com a caixa de moedas e a cancela listrada baixada
    c.b("poste", "#6a4426", [(92, 250), (106, 250), (104, 140), (94, 140)], mode="poly")
    c.b("caixa", "#7a5030", [(80, 142), (118, 142), (120, 110), (78, 110)], mode="poly")
    c.b("caixa_tampa", "#5a3a22", [(74, 112), (124, 112), (120, 102), (78, 102)], mode="poly")
    c.b("fenda", INK, [(90, 106), (108, 106)], closed=False, sw=2.2)
    c.b("cadeado", GOLD, ellipse(99, 128, 5, 6, 0, 8))
    # efeito: o ouro entra na caixa (jorro de moedas do canto de cima à esquerda) e sai como elixir (gotas roxas subindo)
    r = rng(31)
    for i, t in enumerate(np.linspace(0, 1, 11)):
        x = 10 + t * 86 + r.normal(0, 3); y = 20 + t * 76 - math.sin(t * math.pi) * 22 + r.normal(0, 3)
        coin_face(c, x, y, 5.6 - t * 1.6, r.random() * 180)
    for i in range(9):
        a = math.radians(-120 + i * 12 + r.normal(0, 4)); d = 22 + i * 9 + r.random() * 6
        x = 99 + math.cos(a) * d * 0.9; y = 100 + math.sin(a) * d
        c.f("elixir", ELIX, drop(x, y, 5.6 + (8 - i) * 0.35, math.degrees(a) + 90), op=0.95)
        c.f("elixir_luz", ELIX_L, ellipse(x - 1.4, y - 1.6, 1.6, 2.2, 0, 6), op=0.9)
    c.f("elixir_jato", ELIX, [(90, 104), (99, 64), (108, 104)], op=0.85)
    c.f("elixir_jato_luz", ELIX_L, [(96, 102), (99, 76), (102, 102)], op=0.8)
    rings(c, 99, 98, [14, 24], -170, -10, ELIX_L, w0=3.4, op0=0.7, name="elixir_onda")
    glints(c, [(118, 92, 1.1), (80, 78, 0.8), (140, 54, 0.9)], col="#fff0ff")
    # o herói freando em cima da cancela, à direita
    dust(c, 196, 248, 26, 14, "#8a6a44", 61, (2, 5), op=0.7)
    c.fig("heroi", hero2.pose("freiar"), 228, 252, -4, 0.98, guide=hero2.GUIDE["freiar"])
    # a cancela listrada (silhueta própria) passa NA FRENTE das coxas do herói: ele foi barrado
    k = 0.102
    bar = [Pc("barra", "cancela", "#f2ece0", [(104, 196), (304, 176), (304, 186), (104, 206)], mode="poly")]
    for i in range(6):
        x0 = 112 + i * 34
        bar.append(Pc(f"listra{i}", "cancela", "#c8302a", [(x0, 196 - (x0 - 104) * k), (x0 + 16, 196 - (x0 + 16 - 104) * k),
                                                         (x0 + 16, 206 - (x0 + 16 - 104) * k), (x0, 206 - (x0 - 104) * k)], mode="poly", cls="inner"))
    bar.append(Pc("eixo", "cancela", INK, ellipse(100, 200, 4, 4, 0, 8), cls="inner"))
    c.fig("cancela", bar, 0, 0)
    c.save()


# =========================================================================== MOEDAS AMALDIÇOADAS
def cursed_coins():
    c = Card("cursed_coins")
    sky(c, "#14202a", "#34484e")
    # cenário: árvore seca torta à esquerda
    c.b("arvore", "#1e1a22", brush([(30, 300), (36, 200), (26, 140), (40, 80), (70, 30), (100, 6)], 30, 8))
    c.b("galho1", "#1e1a22", brush([(34, 150), (8, 120), (-8, 116)], 9, 2))
    c.b("galho2", "#1e1a22", brush([(48, 70), (90, 60), (120, 40)], 8, 2))
    c.b("galho3", "#1e1a22", brush([(60, 46), (64, 10), (80, -6)], 6, 2))
    ground(c, "chao", "#4a4a40", 168, 160)
    c.b("estrada", "#7a7058", [(-10, 210), (310, 186), (310, 300), (-10, 300)], mode="poly")
    # moedas no chão em volta do herói (câmera de cima)
    r = rng(41)
    coins = []
    for i in range(18):
        x = 90 + r.random() * 190; y = 220 + r.random() * 34
        coins.append((x, y)); coin(c, x, y, 4 + r.random() * 2.2, 0.5, r.normal(0, 10), name="moeda_chao")
    # efeito atrás: fumaça de maldição roxa subindo das moedas e enrolando no braço; caveirinhas na fumaça
    for i, (x, y) in enumerate(coins[:9]):
        h = 40 + r.random() * 50
        wisp(c, [(x, y - 2), (x + r.normal(0, 8), y - h * 0.4), (x + r.normal(0, 14), y - h * 0.8), (x + r.normal(0, 18), y - h)], 7, 1.2, CURSE, op=0.55)
    c.f("maldicao_nevoa", CURSE_D, ellipse(160, 236, 90, 22, -4, 14), op=0.45)
    for (x, y, s) in [(120, 140, 1.0), (232, 120, 0.8)]:
        c.f("caveira", CURSE_L, [(x - 7 * s, y), (x - 7 * s, y - 8 * s), (x, y - 12 * s), (x + 7 * s, y - 8 * s), (x + 7 * s, y), (x + 3 * s, y + 5 * s), (x - 3 * s, y + 5 * s)], op=0.65)
        c.f("caveira_olho", CURSE_D, ellipse(x - 3 * s, y - 3 * s, 2 * s, 2 * s, 0, 6), op=0.9)
        c.f("caveira_olho", CURSE_D, ellipse(x + 3 * s, y - 3 * s, 2 * s, 2 * s, 0, 6), op=0.9)
    # e o ouro que você ganha: moedas subindo para o canto de cima à esquerda (para o vilão)
    for i in range(6):
        t = i / 5
        coin_face(c, 200 - t * 120 + r.normal(0, 6), 140 - t * 110, 3.6 + t * 1.6, r.random() * 180)
    glints(c, [(84, 40, 1.0), (130, 80, 0.8)])
    M = tmat(166, 250, 9, 1.3, 1.18)
    J = hero2.J("catar")
    hand = ap(M, [J["wl"]])[0]
    c.f("brilho_moeda", GOLD_L, ellipse(hand[0], hand[1] + 6, 12, 8, 0, 10), op=0.7)
    pile(c, hand[0] + 2, hand[1] + 30, 46, 16, 44, n=8, layer="f")
    for k in range(4):
        a = -1 if k % 2 else 1
        wisp(c, [(hand[0] - 12 + k * 8, hand[1] + 26), (hand[0] - 16 + k * 8 + a * 10, hand[1] + 4), (hand[0] - 8 + k * 8 - a * 12, hand[1] - 18),
                 (hand[0] + k * 8 + a * 8, hand[1] - 46), (hand[0] + k * 10, hand[1] - 70)], 8, 1.2, CURSE if k % 2 else CURSE_L, op=0.75)
    c.f("maldicao_nuvem", CURSE, blob(hand[0] + 10, hand[1] - 70, 26, 81, 9, 0.25, 0.8), op=0.5)
    x, y, s_ = hand[0] + 10, hand[1] - 74, 1.6
    c.f("caveira", CURSE_L, [(x - 7 * s_, y), (x - 7 * s_, y - 8 * s_), (x, y - 12 * s_), (x + 7 * s_, y - 8 * s_), (x + 7 * s_, y), (x + 3 * s_, y + 5 * s_), (x - 3 * s_, y + 5 * s_)], op=0.85)
    for ex in (-3, 3):
        c.f("caveira_olho", CURSE_D, ellipse(x + ex * s_, y - 3 * s_, 2 * s_, 2 * s_, 0, 6), op=0.95)
    pcs = hero2.pose("catar")
    # a moeda na mão (inner, na cor do ouro) e a mão amaldiçoada (veias roxas)
    pcs.append(Pc("moeda_mao", "corpo", GOLD, ellipse(J["wl"][0] + 1, J["wl"][1] + 5, 4.6, 2.6, 0, 8), cls="inner"))
    c.fig("heroi", pcs, 166, 250, 9, 1.3, 1.18, guide=hero2.GUIDE["catar"])
    c.save()


# =========================================================================== OURO DERRETIDO
def molten_gold():
    c = Card("molten_gold")
    sky(c, "#1a1220", "#4a2a34")
    # cenário: paredão de rocha da caverna à direita
    c.b("rocha", "#2e2028", [(230, -10), (310, -10), (310, 300), (250, 300), (240, 220), (258, 150), (236, 80)])
    c.b("rocha_luz", "#4a3036", [(236, 80), (258, 150), (240, 220), (250, 300), (236, 300), (226, 210), (244, 150), (224, 84)], op=0.8)
    c.b("chao", "#2a1c22", [(-10, 200), (310, 190), (310, 300), (-10, 300)], mode="poly")
    # a poça de ouro derretido (atrás do herói) com brilho
    c.b("poca", GOLD_D, ellipse(150, 230, 120, 34, -3, 18))
    c.b("poca_luz", GOLD, ellipse(146, 226, 100, 24, -3, 16))
    c.b("poca_brilho", GOLD_L, ellipse(120, 222, 40, 8, -3, 10), op=0.8)
    # efeito: moedas derretendo no ar (canto de cima à esquerda) e o jorro de ouro caindo em diagonal no herói
    r = rng(51)
    for i in range(7):
        t = i / 6
        x = 20 + t * 60 + r.normal(0, 6); y = 20 + t * 40 + r.normal(0, 4)
        coin_face(c, x, y, 6 - t * 0.6, r.random() * 180)
        c.f("pingo", GOLD, drop(x + 2, y + 10, 2.4 + t, 180), op=0.95)
    c.f("jorro", GOLD_D, brush([(60, 40), (100, 70), (130, 104), (148, 140)], 34, 20))
    c.f("jorro", GOLD, brush([(62, 42), (100, 72), (128, 106), (144, 140)], 24, 12))
    c.f("jorro_luz", GOLD_W, brush([(70, 46), (104, 76), (126, 106)], 7, 3), op=0.9)
    for i in range(10):
        a = math.radians(-170 + i * 18 + r.normal(0, 5)); d = 30 + r.random() * 30
        c.f("respingo", GOLD, drop(150 + math.cos(a) * d, 140 + math.sin(a) * d * 0.7, 2.4 + r.random() * 2, math.degrees(a) + 90), op=0.95)
    # fogo: o ouro queima (chamas na borda da poça) e fumaça
    for i, (x, y, h) in enumerate([(46, 232, 26), (82, 248, 20), (230, 236, 28), (254, 222, 20), (204, 252, 18)]):
        fire(c, x, y, h, 14, 2, 70 + i, op=0.95)
    embers(c, 20, 60, 280, 220, 22, 52, ang=-80, L=(4, 9))
    M = tmat(150, 252, 6, 1.02, 0.95)
    pcs = hero2.pose("afundar")
    # ouro escorrendo pelo elmo e ombros (inner, cor do ouro)
    J = hero2.J("afundar")
    for k, (key, off) in enumerate([("head", (-6, -12)), ("head", (5, -14)), ("sl", (0, -4)), ("sr", (0, -4)), ("neck", (-2, 6))]):
        p = A(J[key]) + A(off); L = 10 + k * 2
        pcs.append(Pc(f"ouro{k}", "cabeca" if key == "head" else "corpo", GOLD,
                      [(p[0] - 2, p[1]), (p[0], p[1] - 1.6), (p[0] + 2, p[1]), (p[0] + 1.4, p[1] + L * 0.7), (p[0], p[1] + L), (p[0] - 1.4, p[1] + L * 0.7)], cls="inner"))
    c.fig("heroi", pcs, 150, 252, 6, 1.02, 0.95, guide=hero2.GUIDE["afundar"])
    # a borda da frente da massa de ouro, por cima das pernas (silhueta própria)
    lip = [(30, 238), (62, 220), (96, 206), (124, 200), (150, 194), (178, 200), (210, 204), (246, 214), (270, 232), (240, 246), (150, 250), (60, 248)]
    c.fig("ouro", [Pc("massa", "massa", GOLD, lip), Pc("massa_luz", "massa", GOLD_L, [(80, 220), (130, 204), (176, 204), (150, 212), (100, 222)], cls="inner"),
                   Pc("massa_onda", "massa", GOLD_D, [(70, 236), (120, 226), (180, 226), (236, 232)], closed=False, cls="inner", sw=1.2)], 0, 0)
    c.save()


# =========================================================================== GUARDA DO TESOURO
def treasure_guard():
    c = Card("treasure_guard")
    sky(c, "#121a30", "#34466e")
    disk(c, "halo", 166, 74, 56, "#5a6c98", "#8aa0c8")
    # cenário: o tesouro (monte de ouro com taça e coroa) sob os pés dele
    pile(c, 150, 280, 300, 74, 13, n=40)
    c.b("taca", GOLD_D, [(40, 236), (56, 236), (52, 222), (60, 206), (36, 206), (44, 222)], mode="poly")
    c.b("taca_luz", GOLD_L, [(40, 208), (46, 208), (46, 220)], closed=False, sw=1.4)
    c.b("coroa", GOLD, [(240, 238), (270, 236), (272, 222), (264, 230), (258, 218), (252, 230), (246, 220), (240, 232)], mode="poly")
    # efeito: anéis da provocação saindo do escudo + moedas escorrendo do monte
    M = tmat(150, 262, -4, 1.26)
    J = guard.POSES["provocar"]
    # mão esquerda (escudo): posição aproximada pela IK da ficha
    shl = A(J["neck"]) - np.array([34, 0]) - np.array([0, -4]) * -1
    sc = ap(M, [A(J["wl"]) + A(J["shield_place"][:2])])[0]
    rings(c, sc[0], sc[1], [44, 58, 72], 110, 250, "#e85a3a", w0=5, op0=0.7, name="provocacao")
    r = rng(61)
    for i in range(8):
        coin_face(c, 30 + r.random() * 240, 200 + r.random() * 30, 3.6 + r.random() * 1.6, r.random() * 180)
    glints(c, [(60, 210, 1.2), (250, 214, 1.0), (140, 30, 0.8)])
    c.fig("guardiao", guard.pose("provocar"), 150, 262, -4, 1.26, guide=guard.GUIDE["provocar"])
    c.save()


ALL = dict(mimic=mimic_card, trap_chest=trap_chest, gold_merc=gold_merc, gold_bait=gold_bait, toll=toll,
           cursed_coins=cursed_coins, molten_gold=molten_gold, treasure_guard=treasure_guard)

if __name__ == "__main__":
    for nm in (sys.argv[1:] or ALL):
        ALL[nm]()
        print(nm)
