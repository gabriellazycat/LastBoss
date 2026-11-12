"""Composições do lote dragao_1 (coordenadas de carta 300x420; janela 11..289 x 11..278; fita y >= 261).
Reaproveita (só leitura) Card (praga_3: #enxame_frente + saída LB_OUT), sky/disk/rings/ground (praga_2), speedlines/dust/rng/RECT
(praga_1), hero (praga_1). Fichas: goblin, diabrete, dragon (este lote). Uso: python cartas_d1.py [ids...]"""
import base  # noqa: F401
import sys, math
import numpy as np
from geom import *
import hero
from rat import mix
from cards import speedlines, dust, rng, RECT
from cartas import sky, disk, rings, ground
from cartas3 import Card
import goblin, diabrete, dragon, hero_d1

INK = "#2b1a10"
OIL = "#4a2a0e"       # óleo escuro (encharcado)
OIL_L = "#a8742a"     # brilho do óleo
FIRE = "#ffb030"; FIRE_C = "#fff2a0"; FIRE_D = "#e8521e"


# ---------------------------------------------------------------- utilidades de fogo/óleo
def flame(cx, cy, h, w, lean=0.0, seed=0):
    r = rng(seed); j = lambda: (r.random() - 0.5) * w * 0.12
    return [(cx - w / 2, cy), (cx - w * 0.46 + j(), cy - h * 0.36), (cx - w * 0.2 + lean * 0.5, cy - h * 0.58),
            (cx - w * 0.3 + lean * 0.62 + j(), cy - h * 0.78), (cx + lean, cy - h), (cx + w * 0.16 + lean * 0.55, cy - h * 0.6),
            (cx + w * 0.34 + lean * 0.72 + j(), cy - h * 0.74), (cx + w * 0.44, cy - h * 0.32), (cx + w / 2, cy), (cx, cy + w * 0.14)]


def fire(c, cx, cy, h, w, lean=0.0, seed=0, op=0.95, name="chama", layers=3):
    cols = [FIRE_D, FIRE, FIRE_C][-layers:] if layers < 3 else [FIRE_D, FIRE, FIRE_C]
    for k, col in enumerate(cols):
        s = 1 - k * 0.3
        c.f(name, col, flame(cx, cy - k * h * 0.04, h * s, w * s, lean * s, seed + k), op=op)


def embers(c, x0, y0, x1, y1, n, seed, ang=-70, L=(5, 12), cols=("#ffd27a", "#ff9a3a"), op=0.9, w=(1, 2.4)):
    r = rng(seed)
    for i in range(n):
        x = x0 + r.random() * (x1 - x0); y = y0 + r.random() * (y1 - y0); l = L[0] + r.random() * (L[1] - L[0])
        a = math.radians(ang)
        c.f("brasa", cols[i % len(cols)], wedge(x, y, x + math.cos(a) * l, y + math.sin(a) * l, w[0] + r.random() * (w[1] - w[0])), mode="poly", op=op)


def sparks(c, cx, cy, n, r0, r1, seed, col="#fff2b0", op=0.95, a0=0, a1=2 * math.pi, w=2.6):
    r = rng(seed)
    for i in range(n):
        a = a0 + r.random() * (a1 - a0); d0 = r0 + r.random() * 4; d1 = d0 + 6 + r.random() * (r1 - r0)
        c.f("faisca", col, wedge(cx + math.cos(a) * d1, cy + math.sin(a) * d1, cx + math.cos(a) * d0, cy + math.sin(a) * d0, w * (0.6 + r.random() * 0.6)), mode="poly", op=op)


def star(c, cx, cy, R, r_, n=8, col=FIRE_C, rot=0, op=1.0, name="estrela"):
    pts = [(cx + math.cos(math.radians(rot + k * 180 / n)) * (R if k % 2 == 0 else r_), cy + math.sin(math.radians(rot + k * 180 / n)) * (R if k % 2 == 0 else r_)) for k in range(2 * n)]
    c.f(name, col, pts, mode="poly", op=op)


def drip(x, y, L, w=3.2):
    return [(x - w / 2, y), (x, y - w * 0.5), (x + w / 2, y), (x + w * 0.4, y + L * 0.68), (x, y + L), (x - w * 0.4, y + L * 0.68)]


def soak(pcs, J, seed=1, n=9, col=OIL, extra=()):
    """Herói encharcado: escorridos de óleo (inner, no data-fig do corpo/cabeça) a partir de pontos do corpo."""
    r = rng(seed)
    hd = A(J["head"]); pts = [(hd + (-6, -14), "cabeca"), (hd + (5, -15), "cabeca"), (A(J["sl"]) + (0, -4), "corpo"),
                              (A(J["sr"]) + (0, -4), "corpo"), ((A(J["neck"]) * 0.5 + A(J["hc"]) * 0.5) + (-4, 0), "corpo"),
                              ((A(J["neck"]) * 0.4 + A(J["hc"]) * 0.6) + (5, 0), "corpo"), (A(J["hl"]) + (-2, 6), "corpo"),
                              (A(J["kl"]) + (0, 2), "corpo"), (A(J["kr"]) + (0, 2), "corpo")] + list(extra)
    out = []
    for i, (p, fig) in enumerate(pts[:n] + list(extra)):
        L = 9 + r.random() * 10
        out.append(Pc(f"oleo{i}", fig, col, drip(p[0], p[1], L, 3.4 + r.random() * 1.6), cls="inner"))
        out.append(Pc(f"oleo_brilho{i}", fig, OIL_L, [(p[0] - 0.6, p[1] + 2), (p[0] - 0.4, p[1] + L * 0.5)], closed=False, cls="inner", sw=0.6))
    return pcs + out


def hero_pt(M, J, key, off=(0, 0)):
    return ap(M, [A(J[key]) + A(off)])[0]


# =========================================================================== GOBLIN DINAMITEIRO
def goblin_dynamiter():
    c = Card("goblin_dynamiter")
    sky(c, "#4a2244", "#ffb85a")
    disk(c, "sol", 128, 92, 54, "#ffe2a0", "#fff4d0")
    c.b("morros", "#a8605a", [(-10, 200), (40, 186), (110, 192), (170, 178), (240, 188), (310, 176), (310, 230), (-10, 230)], op=0.8)
    ground(c, "chao", "#7a4a34", 214, 206)
    # o cenário: aldeia ardendo no horizonte (para onde o goblin corre)
    vil = [(168, 210), (168, 196), (176, 188), (184, 196), (184, 200), (196, 200), (196, 186), (204, 176), (212, 186), (212, 204),
           (230, 204), (230, 192), (240, 182), (250, 192), (250, 202), (268, 202), (268, 190), (276, 184), (284, 190), (284, 200), (310, 200), (310, 212)]
    c.b("aldeia", "#4a2436", vil, mode="poly")
    for i, (x, y, h) in enumerate([(204, 176, 16), (240, 182, 12), (276, 184, 10)]):
        c.b(f"fumaca{i}", "#8a6a78", brush([(x, y - h), (x + 6, y - h - 16), (x + 2, y - h - 34), (x + 12, y - h - 50)], h * 0.5, h * 0.9), op=0.5)
        c.b(f"fogo_aldeia{i}", FIRE, flame(x, y + 2, h, h * 0.8, 2, 40 + i), op=0.9)
    # alvo: o herói pequeno, de guarda, na frente da aldeia
    c.fig("heroi", hero.pose("guarda"), 236, 228, 0, 0.36)
    # poeira e velocidade atrás do goblin
    dust(c, 40, 252, 40, 18, "#5a3a2a", 11, (2, 5), op=0.6)
    for x, y, rr in [(30, 244, 18), (62, 254, 14), (12, 230, 14)]:
        c.f("nuvem", "#e8c090", blob(x, y, rr, x, 9, 0.3, 0.6), op=0.55)
    for i in range(9):
        y = 120 + i * 14 + (i % 3) * 3; x0 = 6 + (i % 2) * 10
        c.f("veloc", "#fff0c8", wedge(x0, y, x0 + 26 + (i % 4) * 8, y - 3, 2.4), mode="poly", op=0.55)
    # pavio aceso: faíscas atrás da cabeça
    M = tmat(110, 258, -10, 2.4)
    tip = ap(M, [goblin.fuse_tip("correr")])[0]
    c.f("brilho", "#ffd27a", blob(tip[0], tip[1], 13, 7, 9, 0.25), op=0.7)
    sparks(c, tip[0], tip[1], 16, 4, 22, 12)
    star(c, tip[0], tip[1], 7, 2.4, 6, FIRE_C)
    c.fig("goblin", goblin.pose("correr"), 110, 258, -10, 2.4, guide=goblin.GUIDE["correr"])
    c.save()


# =========================================================================== DIABRETES DE FOGO
def fire_imp():
    c = Card("fire_imp")
    sky(c, "#1e2448", "#5a4a7a")
    disk(c, "lua", 200, 168, 46, "#e8dcc0", "#fff6e0")
    # o cenário: torre de vigia com o telhado em chamas, embaixo à direita
    c.b("torre", "#2e2a40", [(222, 300), (228, 170), (290, 170), (298, 300)], mode="poly")
    c.b("ameias", "#2e2a40", [(218, 172), (218, 158), (232, 158), (232, 166), (248, 166), (248, 156), (264, 156), (264, 166),
                               (278, 166), (278, 156), (300, 156), (300, 172)], mode="poly")
    c.b("janela", "#ffb030", [(254, 204), (264, 204), (264, 222), (254, 222)], mode="poly")
    for i, (x, h) in enumerate([(230, 30), (252, 42), (274, 34), (294, 26)]):
        fire(c, x, 160, h, 18, 6, 50 + i * 3, op=0.9)
    c.b("chao", "#24203a", [(-10, 250), (310, 240), (310, 300), (-10, 300)], mode="poly")
    # linhas de fogo do mergulho (atrás), brasas
    r = rng(22)
    for i in range(9):
        o = (r.random() - 0.5) * 120; x0 = 40 + o * 0.6; y0 = 40 - o * 0.8
        L = 40 + r.random() * 50
        c.f("veloc", [FIRE, FIRE_D, FIRE_C][i % 3], wedge(x0 + L * 0.7, y0 + L * 0.7, x0, y0, 3.2), mode="poly", op=0.7)
    embers(c, 10, 20, 210, 220, 26, 21, ang=-135, L=(4, 10))
    # segundo diabrete (mais longe, no alto à direita), armando a bola de fogo
    c.fig("diabrete2", diabrete.pose("atacar"), 236, 84, 8, 1.4)
    # o da frente: mergulho em diagonal, garras para o canto de baixo
    c.fig("diabrete", diabrete.pose("mergulho"), 132, 128, 4, 2.35, guide=diabrete.GUIDE["mergulho"])
    c.save()


# =========================================================================== ÓLEO FERVENTE
def boiling_oil():
    """Câmera no alto da muralha, olhando para baixo: o caldeirão (frente) despeja; o herói escorrega e cai na poça fervendo."""
    c = Card("boiling_oil")
    c.b("pátio", "#7a6450", RECT, mode="poly")
    r = rng(30)
    for i in range(40):  # pedras do calçamento vistas de cima
        x = r.random() * 300; y = 60 + r.random() * 220
        c.b(f"pedra{i}", INK, ellipse(x, y, 7 + r.random() * 5, 4 + r.random() * 2, r.random() * 30, 7), closed=False, sw=0.7, op=0.25)
    # a poça fervendo (grande, vista de cima), bolhas, vapor e chamas na borda
    PX, PY = 178, 186
    c.f("poca", "#5a3410", blob(PX, PY, 92, 33, 14, 0.12, 0.6), op=0.92)
    c.f("poca_brilho", "#b8782a", ellipse(PX - 20, PY - 16, 50, 12, -8, 14), op=0.6)
    for i in range(16):
        a = r.random() * 6.283; d = r.random() * 70
        c.f("bolha", "#d89a40", ellipse(PX + math.cos(a) * d, PY + math.sin(a) * d * 0.55, 2 + r.random() * 3, 1.6 + r.random() * 2.4, 0, 8), op=0.9)
    for i, a in enumerate((200, 230, 330, 0, 25, 150)):
        x = PX + math.cos(math.radians(a)) * 92; y = PY + math.sin(math.radians(a)) * 56
        fire(c, x, y + 6, 26 + (i % 2) * 8, 14, 3, 60 + i * 3, op=0.9)
    # o jorro: do bico do caldeirão (frente, alto-esquerda) descendo até a poça, afinando com a distância
    CM = tmat(66, 64, 52, 1.65)
    lip = ap(CM, [(24, -15)])[0]
    HX, HY, HR, HS = 186, 214, 24, 0.72
    Mh = tmat(HX, HY, HR, HS)
    tgt = hero_pt(Mh, hero.POSES["escorregar"], "hl", (0, -10))
    c.f("jorro", "#7a4a14", brush([lip, lip * 0.55 + tgt * 0.45 + (6, -6), tgt], 22, 6), op=0.95)
    c.f("jorro_brilho", "#c88a30", brush([lip + (4, 2), lip * 0.5 + tgt * 0.5], 6, 2), op=0.8)
    for k, rr in enumerate((26, 40)):
        pts = [(tgt[0] + math.cos(math.radians(a)) * rr, tgt[1] + 14 + math.sin(math.radians(a)) * rr * 0.5) for a in np.linspace(10, 350, 14)]
        c.f("onda", "#c88a30", brush(pts, 2.4 - k, 1.2), op=0.7)
    for i, (x, y) in enumerate([(120, 150), (240, 150), (220, 236)]):
        c.f("vapor", "#f4e6d0", brush([(x, y), (x - 8, y - 22), (x + 4, y - 40)], 2, 9), op=0.4)
    # herói escorregando na poça: pé no alto, caindo de costas, encharcado
    J = hero.POSES["escorregar"]
    c.fig("heroi", soak(hero_d1.pose("escorregar"), J, seed=3), HX, HY, HR, HS)
    r2 = rng(32)
    for i in range(14):
        a = r2.random() * 6.283; d = 20 + r2.random() * 40
        c.f("respingo", "#7a4a14", ellipse(tgt[0] + math.cos(a) * d, tgt[1] + math.sin(a) * d * 0.6, 1.6 + r2.random() * 2.4, 1.4 + r2.random() * 1.6, 0, 7), op=0.9)
    # frente: a borda da muralha (de cima) e o caldeirão virado — figuras na frente de tudo
    mur = [Pc("parapeito", "muralha", "#6a5a5e", [(-10, -10), (120, -10), (96, 24), (40, 40), (-10, 56)], mode="poly"),
           Pc("ameia", "muralha", "#7a6a6e", [(-10, 56), (40, 40), (34, 86), (-10, 100)], mode="poly"),
           Pc("junta1", "muralha", INK, [(4, 18), (60, 6)], closed=False, cls="inner", sw=0.8),
           Pc("junta2", "muralha", INK, [(16, 46), (20, 70)], closed=False, cls="inner", sw=0.8)]
    cal = [Pc("caldeirao", "caldeirao", "#3a3238", list(ap(CM, [(-22, -16), (22, -16), (24, -6), (18, 12), (0, 18), (-18, 12), (-24, -6)]))),
           Pc("borda", "caldeirao", "#5a5058", list(ap(CM, [(-24, -18), (24, -18), (24, -12), (-24, -12)])), mode="poly", cls="inner"),
           Pc("oleo_boca", "caldeirao", "#7a4a14", list(ap(CM, ellipse(8, -16, 15, 3, 0, 10))), cls="inner"),
           Pc("alca", "caldeirao", INK, list(ap(CM, [(-20, -16), (-26, -30), (0, -38), (26, -30), (20, -16)])), closed=False, cls="inner", sw=1.4)]
    c.figs += [("muralha", mur, "translate(0 0)"), ("caldeirao", cal, "translate(0 0)")]
    c.f("vapor_caldeirao", "#f4e6d0", brush([lip + (8, -2), lip + (20, -14), lip + (14, -30)], 3, 9), op=0.5)
    c.guide = [(20, 30), (lip[0], lip[1]), (tgt[0], tgt[1]), (HX + 40, HY - 60), (HX + 60, HY - 110)]
    c.save()


# =========================================================================== BALDE DE ÓLEO
def oil_splash():
    """Câmera atrás do herói (lado do vilão): o jato de óleo do balde o acerta de lado, ele recua e escorrega."""
    c = Card("oil_splash")
    c.b("muro", "#8a8e9a", RECT, mode="poly")
    for i in range(7):
        y = 6 + i * 26
        c.b(f"junta_h{i}", INK, [(-10, y), (310, y - 4)], closed=False, sw=0.8, op=0.25)
        for k in range(7):
            x = -10 + k * 52 + (i % 2) * 26
            c.b(f"junta_v{i}_{k}", INK, [(x, y), (x, y + 26)], closed=False, sw=0.8, op=0.25)
    # o cenário: o portão do pátio, para onde o herói olhava
    c.b("portao", "#6a5038", [(176, 200), (176, 104), (198, 76), (246, 64), (294, 76), (310, 96), (310, 200)])
    for i in range(5):
        c.b(f"tabua{i}", INK, [(196 + i * 24, 80), (196 + i * 24, 200)], closed=False, sw=0.9, op=0.45)
    ground(c, "chao", "#6a6a72", 206, 198)
    # o balde girando no ar (da esquerda), o jato em leque atravessando a cena e estourando no ombro do herói
    BX, BY = 46, 92
    HX, HY, HS = 188, 252, 0.92
    Mh = tmat(HX, HY, 8, HS)
    J = hero.POSES["costas_recuo"]
    hit = hero_pt(Mh, J, "sl", (-6, 6))
    d = np.array([math.cos(math.radians(16)), math.sin(math.radians(16))]); n = np.array([-d[1], d[0]])
    m0 = np.array([BX, BY]) + d * 36
    c.f("jato", "#3a2008", [m0 - n * 10, m0 + d * 40 - n * 18, hit + (-26, -30), hit + (6, -26), hit + (12, 6), hit + (-22, 18),
                            m0 + d * 40 + n * 14, m0 + n * 10], op=0.95)
    c.f("jato_brilho", "#a8742a", brush([m0 + d * 8, m0 + d * 50 - n * 6, hit + (-40, -18)], 2, 4), op=0.8)
    r0 = rng(40)
    for i in range(10):
        p = m0 + d * (r0.random() * 80) + n * r0.normal(0, 16)
        c.f("gota", "#3a2008", ellipse(p[0], p[1], 1.6 + r0.random() * 2.4, 1.2 + r0.random() * 1.6, 16, 7), op=0.95)
    r = rng(41)
    for i in range(30):  # estouro: respingos saindo para a direita e para cima
        a = math.radians(-100 + r.random() * 150); d = 14 + r.random() * 70
        x = hit[0] + 14 + math.cos(a) * d; y = hit[1] - 10 + math.sin(a) * d * 0.8
        c.f("respingo", "#4a2a0e", ellipse(x, y, 1.6 + r.random() * 3.4, 1.2 + r.random() * 2.2, math.degrees(a), 8), op=0.95)
    # poça de óleo no chão e o rastro do pé que escorregou
    c.f("poca", "#3a2008", ellipse(HX + 10, HY - 6, 70, 12, -3, 14), op=0.9)
    c.f("rastro", "#a8742a", brush([(HX + 20, HY - 8), (HX + 50, HY - 12)], 3, 1), op=0.8)
    speedlines(c, BX, BY, 8, 24, 40, "#f4f0e0", 42, op=0.5, a0=math.radians(120), a1=math.radians(240))
    pcs = [p for p in soak(hero_d1.pose("costas_recuo", back=True), J, seed=5, n=9) if not (p.id.startswith("oleo") and p.fig == "cabeca")]
    c.fig("heroi", pcs, HX, HY, 8, HS)
    M = tmat(BX, BY, 106, 1.0)
    balde = [Pc("balde", "balde", "#8a5a30", list(ap(M, [(-20, -22), (20, -22), (16, 22), (-16, 22)])), mode="poly"),
             Pc("balde_boca", "balde", "#3a2008", list(ap(M, ellipse(0, -22, 20, 6, 0, 14)))),
             Pc("aro1", "balde", "#7a7a84", list(ap(M, [(-19, -12), (19, -12), (18.5, -8), (-18.5, -8)])), mode="poly", cls="inner"),
             Pc("aro2", "balde", "#7a7a84", list(ap(M, [(-17, 10), (17, 10), (16.6, 14), (-16.6, 14)])), mode="poly", cls="inner"),
             Pc("alca", "balde", INK, list(ap(M, [(-20, -18), (-14, 4), (0, 12), (14, 4), (20, -18)])), closed=False, cls="inner", sw=1.4)]
    for k in range(3):
        balde.append(Pc(f"ripa{k}", "balde", INK, list(ap(M, [(-8 + k * 8, -16), (-7 + k * 7, 20)])), closed=False, cls="inner", sw=0.7))
    c.figs.append(("balde", balde, "translate(0 0)"))
    c.guide = [(10, 120), (BX, BY), (hit[0] - 30, hit[1] - 30), (hit[0], hit[1]), (HX + 30, HY)]
    c.save()


# =========================================================================== TOCHA
def torch():
    """Câmera baixa: a tocha passou raspando, o óleo da capa explode em chamas; o herói gira para fugir e bate na capa."""
    c = Card("torch")
    sky(c, "#1c1a3a", "#4a3a6a")
    # o cenário: casa de palha em chamas ao fundo, à direita
    c.b("casa", "#3a2a2e", [(212, 214), (212, 150), (296, 150), (296, 214)], mode="poly")
    c.b("telhado", "#6a5030", [(200, 156), (254, 100), (310, 156)], mode="poly")
    c.b("janela_casa", "#ffb030", [(268, 170), (280, 170), (280, 184), (268, 184)], mode="poly")
    for i, (x, h) in enumerate([(232, 36), (254, 48), (278, 32)]):
        c.b(f"fogo_casa{i}", FIRE, flame(x, 132 + abs(x - 254) * 0.9, h, 20, 4, 70 + i), op=0.85)
    c.b("fumaca", "#3e3650", brush([(254, 96), (244, 66), (258, 36), (246, 4)], 12, 26), op=0.6)
    ground(c, "chao", "#2a2636", 228, 222)
    J = hero.POSES["capa_fogo"]
    HX, HY, HS = 176, 262, 1.0
    Mh = tmat(HX, HY, 0, HS)
    # a capa pegando fogo: labaredas grandes saindo da capa (atrás do corpo), faíscas
    cape = ap(Mh, [(-92, -70), (-70, -48), (-80, -100), (-40, -56), (-56, -116)])
    c.f("brilho", "#ff9a3a", blob(cape[0][0] + 20, cape[0][1] - 10, 50, 80, 12, 0.18), op=0.45)
    for i, (p, h) in enumerate(zip(cape, (70, 56, 50, 44, 40))):
        fire(c, p[0], p[1], h, 24, -10, 90 + i * 3, op=0.95)
    sparks(c, cape[0][0], cape[0][1] - 20, 18, 10, 40, 98, a0=math.radians(180), a1=math.radians(330))
    c.fig("heroi", soak(hero_d1.pose("capa_fogo"), J, seed=7, n=7), HX, HY, 0, HS)
    # a tocha que passou raspando, ainda girando no ar à esquerda
    TX, TY = 40, 96
    M = tmat(TX, TY, 130, 1.2)
    for k, rr in enumerate((30, 42)):
        pts = [(TX + math.cos(math.radians(a)) * rr, TY + math.sin(math.radians(a)) * rr * 0.8) for a in np.linspace(-20, 80, 8)]
        c.f("giro", "#f4e8d0", brush(pts, 1, 3.2 - k), op=0.55)
    tocha = [Pc("cabo", "tocha", "#7a5030", list(ap(M, [(-3.6, 0), (3.6, 0), (2.8, -56), (-2.8, -56)])), mode="poly"),
             Pc("pano", "tocha", "#5a4030", list(ap(M, [(-6, 8), (6, 8), (7, -10), (-7, -10)])), mode="poly")]
    hd = ap(M, [(0, 6)])[0]
    fl = [Pc("chama", "chama", FIRE, flame(hd[0], hd[1] + 8, 34, 20, 10, 97)),
          Pc("chama_meio", "chama", FIRE_C, flame(hd[0], hd[1] + 6, 18, 10, 5, 96), cls="inner")]
    c.figs += [("tocha", tocha, "translate(0 0)"), ("tocha_chama", fl, "translate(0 0)")]
    c.guide = [(hd[0], hd[1]), (cape[2][0], cape[2][1] - 30), (HX - 10, HY - 60), (HX + 16, HY - 146), (HX + 70, HY - 160)]
    c.save()


# =========================================================================== FAÍSCA
def spark():
    """A faísca acerta o herói 1 (choque, braços abertos) e o fogo salta para o herói 2, que tropeça para trás."""
    c = Card("spark")
    sky(c, "#2a2244", "#8a5a6a")
    for i, (x, rot) in enumerate([(14, -6), (60, 4), (150, -8), (200, 6), (292, 12)]):
        Mf = tmat(x, 214, rot)
        c.b(f"estaca{i}", "#4a3428", list(ap(Mf, [(-5, 0), (-5, -58), (0, -66), (5, -58), (5, 0)])), mode="poly")
    c.b("travessa", "#5a4030", brush([(-10, 178), (80, 172), (310, 168)], 6, 6))
    c.b("travessa2", "#5a4030", brush([(-10, 200), (310, 194)], 5, 5))
    ground(c, "chao", "#3a3040", 214, 210)
    J, J2 = hero.POSES["choque"], hero.POSES["recuo"]
    HX, HY, HS = 96, 250, 0.78
    H2X, H2Y, H2S = 236, 232, 0.66
    Mh, M2 = tmat(HX, HY, 8, HS), tmat(H2X, H2Y, -6, H2S)
    hit = hero_pt(Mh, J, "sr", (4, 10))
    tgt = hero_pt(M2, J2, "sl", (6, 10))
    mid = (A(hit) + A(tgt)) / 2 + (0, -46)
    arc = cr_sample([hit, (hit + mid) / 2 + (0, -12), mid, (mid + tgt) / 2 + (0, -10), tgt], 4)
    for i, p in enumerate(arc[2:-1:2]):
        fire(c, p[0], p[1] + 8, 18 - abs(i - 3) * 1.4, 12, 4, 120 + i, op=0.9)
    c.f("arco", FIRE_C, brush(list(arc[::3]), 2.4, 1.2), op=0.8)
    for i, p in enumerate(ap(Mh, [(-50, -90), (50, -84), (0, -50)])):
        fire(c, p[0], p[1], 30, 16, 4, 140 + i, op=0.9)
    for i, p in enumerate(ap(M2, [(-30, -70), (20, -50)])):
        fire(c, p[0], p[1], 24, 14, -4, 150 + i, op=0.9)
    c.f("brilho2", "#ffe08a", blob(tgt[0], tgt[1], 12, 19, 9, 0.2), op=0.7)
    star(c, tgt[0], tgt[1], 9, 3, 6, FIRE_C, 0)
    c.fig("heroi2", soak(hero_d1.pose("recuo"), J2, seed=11, n=6), H2X, H2Y, -6, H2S)
    # a faísca chegando do alto à esquerda (ponto focal): rastro em zigue-zague até o ombro do herói 1
    zz = [(250, -6), (210, 20), (196, 40), (170, 52), (hit[0] + 8, hit[1] - 8)]
    c.f("rastro", FIRE, brush(zz, 1, 6), op=0.8)
    c.f("rastro", FIRE_C, brush(zz, 0.6, 2.4), op=0.9)
    c.f("brilho", "#ffe08a", blob(hit[0], hit[1], 18, 9, 10, 0.2), op=0.75)
    star(c, hit[0], hit[1], 16, 5, 8, FIRE_C, 10)
    sparks(c, hit[0], hit[1], 16, 6, 26, 131)
    c.fig("heroi", soak(hero_d1.pose("choque"), J, seed=12), HX, HY, 8, HS)
    c.guide = [(250, -6), (170, 52), (hit[0], hit[1]), (mid[0], mid[1]), (tgt[0], tgt[1])]
    c.save()


# =========================================================================== CHUVA DE BRASAS
def ember_rain():
    """Câmera baixa: o Dragão Ancião enorme no céu despeja brasas; o herói corre com o escudo sobre a cabeça."""
    c = Card("ember_rain")
    sky(c, "#3a1420", "#e0703a")
    c.b("nuvens", "#5a2028", [(-10, 120), (40, 100), (110, 116), (170, 94), (240, 110), (310, 96), (310, -10), (-10, -10)], op=0.7)
    ground(c, "chao", "#5a3428", 236, 230)
    # o Dragão Ancião passando por cima (grande, cortado pela moldura): é dele que caem as brasas
    c.fig("dragao", dragon.pose("sobrevoo"), 196, 92, -14, -0.78, 0.78)
    # brasas em diagonal (atrás do herói) e poças pegando fogo no chão
    embers(c, -10, 80, 310, 260, 80, 201, ang=-62, L=(6, 16), w=(1.2, 3))
    for i, (x, y, rx) in enumerate([(50, 246, 30), (250, 252, 34)]):
        c.f("poca", "#3a2008", ellipse(x, y, rx, rx * 0.2, -3, 14), op=0.9)
        for k in range(3):
            fire(c, x - rx * 0.6 + k * rx * 0.6, y - 1, 20 + (k % 2) * 10, 12, 3, 200 + i * 5 + k, op=0.9)
    # poeira dos passos
    dust(c, 110, 254, 26, 10, "#3a2018", 13, (2, 4), op=0.6)
    J = hero.POSES["correr_escudo"]
    HX, HY, HS = 150, 282, 1.0
    Mh = tmat(HX, HY, -4, HS)
    sh = ap(Mh, [A(J["wl"]) + (2, -10)])[0]
    for i, (dx, dy) in enumerate([(-14, -14), (8, -20), (20, -8)]):
        star(c, sh[0] + dx, sh[1] + dy, 8, 2.6, 6, FIRE_C, i * 13)
    sparks(c, sh[0], sh[1] - 12, 12, 16, 30, 202, a0=math.radians(190), a1=math.radians(350))
    c.fig("heroi", hero_d1.pose("correr_escudo"), HX, HY, -4, HS)
    c.guide = [(HX + 40, HY - 2), (HX + 26, HY - 40), (HX + 6, HY - 80), (sh[0], sh[1]), (120, 60), (40, 30)]
    c.save()


# =========================================================================== ERUPÇÃO
def eruption():
    c = Card("eruption")
    sky(c, "#2a0c14", "#a0301e")
    # o cenário: vulcão em erupção ao fundo
    c.b("vulcao", "#3a1418", [(-10, 210), (60, 140), (96, 92), (118, 88), (140, 96), (176, 140), (250, 196), (310, 210), (310, 240), (-10, 240)])
    c.b("lava_vulcao", "#ff7a2a", brush([(108, 94), (102, 120), (110, 150), (98, 190)], 2, 6), op=0.9)
    c.b("coluna", "#5a2024", blob(112, 50, 34, 301, 10, 0.3, 1.2), op=0.8)
    c.b("coluna_fogo", "#ff9a3a", blob(112, 78, 14, 302, 8, 0.3, 1.4), op=0.85)
    ground(c, "chao", "#2a1214", 222, 214)
    # rachaduras de lava no chão
    for i, P in enumerate([[(0, 250), (40, 244), (70, 252), (110, 240)], [(150, 236), (190, 246), (230, 238), (300, 248)],
                           [(110, 240), (130, 228), (150, 236)]]):
        c.b(f"racha{i}", "#ff8a2a", brush(P, 2, 3), op=0.9)
    # a explosão (o protagonista): coluna de fogo a partir da poça encharcada, atrás do herói
    EX, EY = 196, 224
    for k, (rr, col, op) in enumerate([(92, FIRE_D, 0.8), (70, FIRE, 0.9), (44, FIRE_C, 0.95)]):
        c.f("explosao", col, blob(EX - 10, EY - 70 - k * 6, rr, 400 + k, 14, 0.24, 1.15), op=op)
    for i in range(12):
        a = math.radians(-170 + i * 15); d0 = 70; d1 = 118 + (i % 3) * 14
        c.f("raio", "#fff0b0", wedge(EX - 10 + math.cos(a) * d1, EY - 70 + math.sin(a) * d1, EX - 10 + math.cos(a) * d0, EY - 70 + math.sin(a) * d0, 5), mode="poly", op=0.8)
    r = rng(403)
    for i in range(10):
        x = EX - 60 + r.random() * 120; y = EY - 140 + r.random() * 60
        c.f("pedra", "#2a1214", blob(x, y, 2 + r.random() * 4, 410 + i, 6, 0.35), op=0.95)
    embers(c, 40, 40, 300, 240, 30, 404, ang=-80, L=(5, 12))
    # herói arremessado pela explosão, em contraluz
    c.fig("heroi", hero.pose("preso"), 168, 170, -38, 0.66)
    c.guide = [(120, 250), (150, 200), (196, 120), (240, 60)]
    c.save()


ALL = dict(goblin_dynamiter=goblin_dynamiter, fire_imp=fire_imp, boiling_oil=boiling_oil, oil_splash=oil_splash, torch=torch,
           spark=spark, ember_rain=ember_rain, eruption=eruption)

if __name__ == "__main__":
    for nm in (sys.argv[1:] or ALL):
        ALL[nm]()
        print(nm)
