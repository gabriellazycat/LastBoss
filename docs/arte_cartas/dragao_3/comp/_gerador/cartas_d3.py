"""Composições do lote dragao_3. Coordenadas de carta 300x420; janela 11..289 x 11..278; fita y >= 261.
Reaproveita (só leitura) Card/stones (praga_3), sky/disk/rings/ground (praga_2), dust/rng/RECT (praga_1), hero (praga_1),
fogo/brasas/faíscas/star/soak (dragao_1), dragon/wings/kobold/goblin (dragao_1), moedas/monte/brilhos (dragao_2).
Poses novas do herói em hero3.py. Uso: python cartas_d3.py [ids...]"""
import base  # noqa: F401
import sys, math
import numpy as np
from geom import *
from rat import mix
from cards import dust, rng, RECT
from cartas import sky, disk, rings, ground
from cartas3 import Card, stones
from cartas_d1 import fire, embers, sparks, star, flame, soak, FIRE, FIRE_C, FIRE_D, OIL, OIL_L
from cartas_d2 import coin, coin_face, pile, glints, wisp, drop, GOLD, GOLD_D, GOLD_L, GOLD_W
import dragon, kobold, goblin, hero3
from wings import wing

INK = "#2b1a10"
BLOOD = "#a8141e"; BLOOD_D = "#6a0a12"; BLOOD_L = "#e8505a"
TAR = "#1e1610"; TAR_L = "#5a4a3a"


def breath(c, P, dirdeg, L, w0, w1, seed, op=0.95):
    """Sopro de fogo em cone a partir de P (3 camadas + línguas), apontando para dirdeg."""
    a = math.radians(dirdeg); d = np.array([math.cos(a), math.sin(a)]); n = np.array([-d[1], d[0]])
    P = A(P); r = rng(seed)
    for k, (col, s) in enumerate([(FIRE_D, 1.0), (FIRE, 0.74), (FIRE_C, 0.46)]):
        pts = [P + n * w0 * s * 0.5]
        for t in np.linspace(0.15, 1, 7):
            pts.append(P + d * L * t * (1 - k * 0.08) + n * (w0 + (w1 - w0) * t) * s * 0.5 * (1 + r.normal(0, 0.12)))
        pts.append(P + d * L * (1.04 - k * 0.1))
        for t in np.linspace(1, 0.15, 7):
            pts.append(P + d * L * t * (1 - k * 0.08) - n * (w0 + (w1 - w0) * t) * s * 0.5 * (1 + r.normal(0, 0.12)))
        pts.append(P - n * w0 * s * 0.5)
        c.f("sopro", col, pts, op=op)
    for i in range(7):
        t = 0.3 + r.random() * 0.6; side = 1 if i % 2 else -1
        b = P + d * L * t + n * side * (w0 + (w1 - w0) * t) * 0.45
        tip = b + d * (14 + r.random() * 12) + n * side * (8 + r.random() * 8)
        c.f("lingua_fogo", FIRE, [b - d * 5, tip, b + d * 5], op=0.9)


# =========================================================================== DRAGÃO ANCIÃO
EH = (150, 104, 40, 1.95)  # cabeça 3/4: posição, giro e escala (≈2× a da ficha: escorço)


def elder_figure():
    """Dragão Ancião em escorço (coordenadas de carta): cabeça 3/4 enorme vindo para a câmera e cuspindo fogo para
    baixo-esquerda, garra de perto em primeiro plano, tronco e cauda recuando para cima-direita, asas abertas cortadas."""
    p = dragon.PAL; pcs = []
    # asas (atrás de tudo): longe à esquerda (aberta para cima-esquerda), perto à direita (cortada pela moldura)
    pcs += wing("asa_l", (196, 98), (158, 54), (126, 22), [(58, -24), (14, 8), (-6, 62), (6, 116)], (178, 122),
                p["wing_d"], p["bone"], p["claw"], arm_w=(11, 6), thumb=11, arm_fill=p["body_d"], finger_w=1.8)
    pcs += wing("asa_r", (232, 96), (262, 44), (268, 4), [(312, -16), (326, 46), (316, 108), (296, 166)], (246, 132),
                p["wing"], p["bone"], p["claw"], arm_w=(13, 7), thumb=12, arm_fill=p["body"], finger_w=2.0)
    # cauda recuando para o canto de cima à direita (pequena = longe)
    tl = [A(q) for q in [(262, 66), (276, 44), (296, 34), (318, 40)]]
    tw = [11, 8, 5, 3]
    pcs.append(Pc("cauda", "corpo", p["body_d"], tube(tl, tw, tw, cap0=0.3, cap1=0.4, per=5)))
    for i, (x, y) in enumerate([(272, 42), (286, 32), (300, 28)]):
        pcs.append(Pc(f"cauda_espinho{i}", "corpo", p["spike"], [(x - 3, y + 2), (x + 1, y - 7), (x + 4, y + 1)], mode="poly"))
    # perna de trás (perto), quase escondida atrás do tronco
    pcs += dragon.hind_leg("perna_tras", [(260, 86), (286, 108), (276, 134), (294, 146)], p["body_d"], 1.25)
    # tronco: quadril longe (cima-direita), peito perto (baixo-esquerda), mais largo no peito
    sp = [A(q) for q in [(262, 66), (238, 98), (212, 128)]]
    wa = [20, 28, 36]; wb = [22, 32, 40]
    pcs.append(Pc("tronco", "corpo", p["body"], tube(sp, wa, wb, cap0=0.8, cap1=0.5, per=5)))
    pcs.append(Pc("barriga", "corpo", p["plate"], tube(sp, [-w * 0.2 for w in wb], [w * 0.9 for w in wb], cap0=0.5, cap1=0.3, per=5), cls="inner"))
    S2 = cr_sample(sp, 6)
    for i in range(2, len(S2) - 1, 3):
        tg = S2[i + 1] - S2[i - 1]; tg /= np.linalg.norm(tg); nn = np.array([-tg[1], tg[0]])
        w = float(np.interp(i / (len(S2) - 1) * 2, range(3), wb))
        pcs.append(Pc(f"placa{i}", "corpo", INK, [S2[i] + nn * w * 0.05, S2[i] + nn * w * 0.86], closed=False, cls="inner", sw=0.8))
    # garra de longe (atrás do pescoço), agarrando o ar
    pcs += dragon.front_leg("pata_frente_l", [(184, 150), (168, 186), (150, 204)], p["body_d"], 150, 1.7)
    # pescoço: do peito à nuca, mais grosso perto da cabeça (escorço)
    nk = [A(q) for q in [(214, 124), (204, 96), (184, 82), (162, 88)]]
    nw = [26, 26, 27, 28]
    pcs.append(Pc("pescoco", "corpo", p["body"], tube(nk, nw, [w * 1.05 for w in nw], cap0=0.4, cap1=0.6, per=5)))
    pcs.append(Pc("pescoco_placas", "corpo", p["plate"], tube(nk, [w * 0.95 for w in nw], [-w * 0.35 for w in nw], cap0=0.4, cap1=0.5, per=5), cls="inner"))
    S3 = cr_sample(nk, 6)
    for i in range(3, len(S3) - 3, 3):
        tg = S3[i + 1] - S3[i - 1]; tg /= np.linalg.norm(tg); nn = np.array([-tg[1], tg[0]])
        pcs.append(Pc(f"placa_p{i}", "corpo", INK, [S3[i] + nn * 8, S3[i] - nn * 24], closed=False, cls="inner", sw=0.8))
    for i in range(1, 6):  # espinhos do dorso (lado de cima do pescoço)
        j = int(len(S3) * i / 6.4)
        tg = S3[j + 1] - S3[j - 1]; tg /= np.linalg.norm(tg); nn = np.array([-tg[1], tg[0]])
        b0 = S3[j] + nn * 25
        pcs.append(Pc(f"espinho_dorso{i}", "corpo", p["spike"], [b0 - tg * 4, b0 + nn * 11 - tg * 4, b0 + tg * 4], mode="poly"))
    # cabeça 3/4 em escorço, boca escancarada para baixo-esquerda
    pcs += dragon.head34(tmat(*EH), True)
    # garra de perto em primeiro plano, avançando para a câmera
    pcs += dragon.front_leg("pata_frente", [(218, 150), (244, 192), (214, 222)], p["body"], 140, 2.2)
    return pcs


def elder_dragon():
    c = Card("elder_dragon")
    sky(c, "#4a1418", "#e8803a")
    disk(c, "lua", 214, 56, 50, "#f2d8a8", "#fff2d0")
    c.b("nuvem", "#7a2a24", [(-10, 150), (40, 132), (90, 146), (150, 124), (220, 140), (310, 124), (310, 176), (-10, 186)], op=0.6)
    # o cenário: torre de vigia de pedra (embaixo à esquerda) pegando fogo onde o sopro bate
    c.b("morro", "#3a1814", [(-10, 226), (60, 212), (140, 222), (230, 210), (310, 220), (310, 300), (-10, 300)])
    c.b("torre", "#5a4a4a", [(10, 262), (14, 196), (62, 192), (66, 262)], mode="poly")
    c.b("torre_luz", "#7a6a66", [(14, 196), (26, 195), (24, 262), (10, 262)], mode="poly", op=0.8)
    c.b("ameias", "#5a4a4a", [(6, 200), (6, 180), (16, 180), (16, 188), (26, 188), (26, 178), (38, 178), (38, 187), (48, 187),
                              (48, 177), (60, 177), (60, 186), (70, 186), (70, 200)], mode="poly")
    stones(c, 12, 202, 64, 260, INK, 71, rows=6, cols=3, op=0.3)
    c.b("janela", "#ffcf6a", [(32, 218), (42, 218), (42, 232), (32, 232)], mode="poly")
    # chuva de brasas (entrada) e o sopro descendo em diagonal até a torre (atrás da figura)
    embers(c, -10, -10, 310, 250, 70, 701, ang=-75, L=(6, 15), w=(1.2, 3))
    m = ap(tmat(*EH), [(3, 33)])[0]
    tx, ty = 40, 196
    ang = math.degrees(math.atan2(ty - m[1], tx - m[0]))
    L = math.hypot(ty - m[1], tx - m[0]) + 24
    breath(c, m, ang, L, 16, 64, 702)
    for i, (x, y, h) in enumerate([(18, 192, 34), (42, 184, 46), (62, 190, 30), (36, 232, 20)]):
        fire(c, x, y, h, 18, -4, 710 + i)
    sparks(c, 40, 196, 14, 20, 40, 720)
    c.fig("dragao", elder_figure(), 0, 0)
    c.guide = [(318, 40), (262, 66), (212, 128), (184, 84), (150, 104), (m[0], m[1]), (40, 196)]
    c.save()


# =========================================================================== utilidades do lote
def kob_sil(name, **over):
    """Silhueta unida de um kobold da ficha (para o enxame)."""
    return union_poly(kobold.pose(name, **over))[0]


def hero_at(M, J, key, off=(0, 0)):
    return ap(M, [A(J[key]) + A(off)])[0]


def house(c, name, x, y, w, h, roof, wall="#c8a878", wall_d="#9a7a50", lit=True):
    """Casa de aldeia (parede + telhado de palha + porta/janela), base em (x, y)."""
    c.b(name + "_parede", wall, [(x, y), (x, y - h), (x + w, y - h), (x + w, y)], mode="poly")
    c.b(name + "_sombra", wall_d, [(x + w * 0.62, y), (x + w * 0.62, y - h), (x + w, y - h), (x + w, y)], mode="poly", op=0.8)
    c.b(name + "_telhado", roof, [(x - 8, y - h + 2), (x + w * 0.5, y - h - h * 0.9), (x + w + 8, y - h + 2), (x + w + 4, y - h + 8), (x - 4, y - h + 8)])
    c.b(name + "_porta", "#4a2e1a", [(x + w * 0.2, y), (x + w * 0.2, y - h * 0.55), (x + w * 0.42, y - h * 0.55), (x + w * 0.42, y)], mode="poly")
    if lit:
        c.b(name + "_janela", "#ffcf6a", [(x + w * 0.66, y - h * 0.4), (x + w * 0.66, y - h * 0.7), (x + w * 0.86, y - h * 0.7), (x + w * 0.86, y - h * 0.4)], mode="poly")


# =========================================================================== KOBOLDS CATADORES
def kobold_scavengers():
    c = Card("kobold_scavengers")
    sky(c, "#1c3440", "#7a9c98")
    # o cenário: barranco com a toca dos kobolds (fundo, esquerda) de onde o enxame saiu
    c.b("barranco", "#4a4a3e", [(-10, 200), (-10, 96), (30, 86), (70, 100), (104, 130), (128, 176), (140, 210)])
    c.b("barranco_luz", "#6a6852", [(-10, 104), (30, 94), (66, 106), (60, 120), (24, 110), (-10, 120)], op=0.8)
    c.b("toca", "#1a1612", ellipse(52, 160, 30, 24, -6, 14))
    ground(c, "chao", "#7a6a4a", 206, 196)
    c.b("estrada", "#9a8a62", [(130, 300), (170, 220), (200, 196), (310, 190), (310, 300)], op=0.8)
    # o herói ao fundo à direita, varrendo a espada nos kobolds dos pés; cada golpe deles arranca ouro
    HX, HY, HS = 222, 236, 0.74
    J = hero3.J("golpe_baixo")
    Mh = tmat(HX, HY, 0, HS)
    hit = hero_at(Mh, J, "hc", (8, -26))
    r = rng(801)
    for i in range(9):
        a = math.radians(-170 + r.random() * 120); d = 18 + r.random() * 46
        coin_face(c, hit[0] + math.cos(a) * d, hit[1] + math.sin(a) * d * 0.8, 3.4 + r.random() * 1.8, r.random() * 180)
    star(c, hit[0], hit[1], 12, 3, 6, "#fff2b0", 10, op=0.95, name="impacto")
    sparks(c, hit[0], hit[1], 10, 8, 18, 802, col="#ffe08a")
    # enxame atrás do herói (silhuetas da ficha, escuras)
    sils = [("saltar", 166, 176, -10, 1.15, False), ("atacar", 180, 250, 0, 1.05, False), ("ameaca", 276, 250, 0, 1.0, True),
            ("atacar", 300, 232, 0, 0.9, True), ("correr", 236, 196, 0, 0.7, True)]
    for nm, x, y, rot, s, fl in sils:
        c.sil(kob_sil(nm, open=True) if nm != "ameaca" else kob_sil(nm), x, y, rot, s, fl, fill="#7a3a22")
    c.fig("heroi", hero3.pose("golpe_baixo"), HX, HY, 0, HS, guide=None)
    # um kobold pendurado na perna do herói (na frente dele)
    c.fsil(kob_sil("saltar", open=True), 252, 230, -30, 0.95, True, fill="#8a4428")
    # o catador da frente: grande, fugindo para baixo-esquerda com o saco e uma moeda no punho
    over = dict(open=True, wf=(26, -36), ebf=-1)
    pcs = kobold.pose("correr", **over)
    pcs.append(Pc("moeda_mao", "corpo", GOLD, ellipse(30, -38, 4.2, 4.2, 0, 10), cls="inner"))
    pcs.append(Pc("moeda_mao_luz", "corpo", GOLD_L, ellipse(29, -39, 1.8, 1.8, 0, 8), cls="inner"))
    dust(c, 150, 262, 26, 12, "#9a8a62", 803, (2, 5), op=0.7)
    for i in range(4):
        coin_face(c, 150 + i * 12, 186 - i * 10, 4.4, i * 40)
    for i in range(6):
        y = 150 + i * 14
        c.f("veloc", "#d8d0b0", wedge(176 + (i % 3) * 8, y, 140 + (i % 2) * 6, y + 6, 2.4), mode="poly", op=0.6)
    c.fig("kobold", pcs, 118, 270, -6, -2.3, 2.3, guide=kobold.GUIDE["correr"])
    c.save()


# =========================================================================== FORNALHA
def furnace():
    c = Card("furnace")
    sky(c, "#20141a", "#5a3028")
    c.b("parede", "#3a2a2a", [(-10, -10), (310, -10), (310, 210), (-10, 210)], op=0.7)
    stones(c, -10, -10, 310, 200, "#1a1012", 81, rows=8, cols=7, op=0.35)
    c.b("chao", "#2a1c1a", [(-10, 206), (310, 198), (310, 300), (-10, 300)], mode="poly")
    # o calor: anéis e ondas saindo da boca (atrás) — o herói não seca e o fogo arde mais
    FX, FY = 178, 168
    c.f("brilho", "#ff8a3a", ellipse(FX, FY - 10, 110, 90, 0, 18), op=0.35)
    rings(c, FX, FY - 6, [70, 88, 106], -200, 20, "#ffb060", w0=5, op0=0.6, name="calor")
    # a fornalha (a estrutura em destaque): cúpula de tijolo, chaminé, boca em brasa, grelha, fole
    c.b("chamine", "#5a3a30", [(194, -10), (232, -10), (226, 76), (198, 76)], mode="poly")
    c.b("chamine_luz", "#7a5244", [(194, -10), (204, -10), (204, 76), (198, 76)], mode="poly", op=0.8)
    c.b("cupula", "#7a4a36", [(96, 236), (100, 168), (122, 112), (160, 82), (200, 76), (240, 88), (272, 126), (286, 180), (284, 236)])
    c.b("cupula_luz", "#9a6248", [(104, 230), (108, 170), (126, 120), (156, 94), (176, 88), (150, 126), (136, 176), (130, 230)], op=0.85)
    stones(c, 104, 96, 282, 232, "#3a1e14", 82, rows=7, cols=6, op=0.4)
    c.b("boca_arco", "#4a2a1e", [(132, 230), (136, 170), (156, 140), (190, 132), (218, 144), (236, 172), (240, 230)])
    c.b("boca", "#ffb030", [(142, 230), (146, 176), (162, 152), (188, 146), (212, 156), (226, 180), (230, 230)])
    c.b("boca_centro", "#fff2a0", ellipse(186, 204, 34, 22, 0, 14))
    for i, (x, h) in enumerate([(160, 46), (186, 62), (212, 44)]):
        fire(c, x, 230, h, 24, 0, 820 + i)
    c.b("grelha", "#2a1a14", [(140, 230), (232, 230)], closed=False, sw=4)
    for k in range(5):
        x = 150 + k * 18
        c.b(f"grelha_b{k}", "#2a1a14", [(x, 214), (x, 232)], closed=False, sw=2.4)
    embers(c, 100, 0, 280, 150, 30, 823, ang=-95, L=(5, 12))
    c.f("fumaca", "#5a4a4a", blob(214, 10, 26, 824, 9, 0.3, 0.8), op=0.6)
    # goblin 1 (em cima da cúpula): pisando no fole com as duas mãos no cabo
    g2 = dict(goblin.POSES["ameaca"]); g2.update(wn=(20, -12), wf=(14, -10), hdn=60, hdf=70, head=(18, -46, 30))
    fole = [Pc("fole", "fole", "#8a5a30", [(6, 0), (34, -8), (40, 2), (34, 10)]), Pc("fole_bico", "fole", "#8a8a92", [(38, -1), (52, 2), (38, 5)], mode="poly"),
            Pc("fole_pregas", "fole", INK, [(14, -2), (16, 4)], closed=False, cls="inner", sw=0.6)]
    c.fig("goblin2", goblin.goblin(g2) + fole, 246, 112, 18, 1.15, guide=None)
    # goblin 2 (frente, esquerda): arremessando um frasco de óleo na boca da fornalha
    J = dict(goblin.POSES["arremessar"]); J.pop("props_n", None)
    def flask(wr, el):
        d = A(wr) - A(el); d = d / np.linalg.norm(d); cc = A(wr) + d * 5
        return [Pc("frasco", "frasco", "#6a4a2a", ellipse(cc[0], cc[1], 5.4, 6.4, 20, 10)),
                Pc("frasco_gargalo", "frasco", "#8a6a44", [cc + (-1.6, -6), cc + (1.6, -6), cc + (2, -11), cc + (-2, -11)], mode="poly"),
                Pc("frasco_oleo", "frasco", OIL, ellipse(cc[0], cc[1] + 1.4, 4, 3.4, 20, 8), cls="inner")]
    J["props_n"] = flask
    c.f("oleo_arco", OIL_L, brush([(66, 120), (100, 104), (136, 116), (158, 150)], 2.4, 1.0), op=0.6)
    c.fig("goblin", goblin.goblin(J), 70, 272, 6, 2.4, guide=goblin.GUIDE["arremessar"])
    c.save()


# =========================================================================== COFRE DO DRAGÃO
def dragon_vault():
    c = Card("dragon_vault")
    sky(c, "#1a1428", "#4a3a5a")
    # o cenário/estrutura: o paredão de rocha com a porta-cofre redonda escancarada; ouro brilhando lá dentro
    c.b("rocha", "#3a3040", [(-10, -10), (310, -10), (310, 230), (-10, 230)])
    c.b("rocha_luz", "#4e4256", [(-10, -10), (90, -10), (60, 80), (20, 160), (-10, 200)], op=0.7)
    VX, VY, VR = 150, 128, 92
    c.b("tunel", "#1a1010", ellipse(VX, VY, VR, VR, 0, 24))
    c.f("brilho_ouro", "#ffe08a", ellipse(VX, VY + 18, VR * 0.86, VR * 0.7, 0, 20), op=0.55)
    pile(c, VX, VY + 70, 170, 80, 831, n=34)
    r = rng(832)
    for i in range(12):
        a = math.radians(-160 + i * 12 + r.normal(0, 4)); L = 70 + r.random() * 40
        c.f("raio", GOLD_L, wedge(VX + math.cos(a) * L, VY + 20 + math.sin(a) * L, VX + math.cos(a) * 20, VY + 20 + math.sin(a) * 20, 8), mode="poly", op=0.45)
    c.b("aro", "#8a6a3a", ellipse(VX, VY, VR + 10, VR + 10, 0, 24), op=0.0)
    # aro de ouro e ferro em volta da abertura
    c.b("aro_ferro", "#5a5a66", brush([(VX + math.cos(math.radians(a)) * (VR + 6), VY + math.sin(math.radians(a)) * (VR + 6)) for a in range(150, 391, 10)], 14, 14))
    # a porta redonda aberta para a direita (em perspectiva: elipse estreita), com o brasão do dragão
    DX = 268
    c.b("porta", "#b88a3a", ellipse(DX, VY + 6, 30, VR - 4, 4, 22))
    c.b("porta_luz", GOLD, ellipse(DX - 6, VY + 2, 20, VR - 18, 4, 20))
    for k in range(5):
        y = VY - 64 + k * 32
        c.b(f"trinco{k}", "#5a5a66", [(DX - 30, y), (DX - 46, y + 1), (DX - 46, y + 6), (DX - 30, y + 5)], mode="poly")
    c.b("brasao", "#7a1c18", [(DX - 12, VY - 10), (DX - 4, VY - 24), (DX + 6, VY - 20), (DX + 2, VY - 8), (DX + 10, VY + 2), (DX - 2, VY + 6), (DX - 10, VY + 16), (DX - 14, VY + 2)])
    c.b("brasao_olho", "#ffe24a", ellipse(DX - 2, VY - 14, 2.4, 1.6, 0, 8))
    c.b("chao", "#2a2230", [(-10, 226), (310, 220), (310, 300), (-10, 300)], mode="poly")
    # moedas jorrando para dentro: o ouro que entra vem em dobro (moedas pequenas viram grandes perto da porta)
    for i, t in enumerate(np.linspace(0, 1, 9)):
        x = 20 + t * 110; y = 40 + t * 70 - math.sin(t * math.pi) * 30
        coin_face(c, x, y, 3 + t * 4, i * 23)
    glints(c, [(VX - 30, VY + 40, 1.4), (VX + 40, VY + 30, 1.1), (VX + 10, VY + 6, 0.9), (60, 60, 0.8)])
    # kobolds carregando sacos de ouro para dentro (silhuetas no fundo e um grande na frente)
    c.sil(kob_sil("saltar", open=True), 176, 150, 20, 0.9, False, fill="#5a2a18")
    c.sil(kob_sil("correr"), 222, 214, 0, 0.8, True, fill="#6a3420")
    pcs = kobold.pose("correr", open=True)
    c.fig("kobold", pcs, 70, 262, -8, 2.2, guide=kobold.GUIDE["correr"])
    c.save()


# =========================================================================== INCÊNDIO
def burn_village():
    c = Card("burn_village")
    sky(c, "#2a1a2e", "#c0603a")
    c.b("morros", "#4a2a34", [(-10, 150), (60, 130), (130, 146), (210, 122), (310, 140), (310, 200), (-10, 200)], op=0.9)
    ground(c, "chao", "#5a3a2e", 190, 184)
    c.b("estrada", "#8a6a4a", [(70, 300), (130, 200), (150, 186), (176, 186), (200, 300)])
    # o cenário: a aldeia; o local marcado explode em fogo quando o herói chega
    house(c, "casa1", 40, 196, 54, 36, "#c8a050")
    house(c, "casa2", 196, 196, 62, 42, "#c8a050")
    house(c, "casa3", 118, 176, 30, 20, "#a88040", lit=False)
    # a marca do vilão no chão (runa em brasa), no ponto da estrada
    MX, MY = 168, 214
    c.f("marca", "#ff6a2a", ellipse(MX, MY, 40, 10, 0, 18), op=0.85)
    c.f("marca_runa", "#fff2a0", [(MX - 22, MY), (MX, MY - 6), (MX + 22, MY), (MX, MY + 6)], op=0.9)
    # o fogo explodindo das casas e da marca
    for i, (x, y, h, w) in enumerate([(60, 160, 66, 34), (86, 168, 44, 22), (220, 154, 76, 40), (250, 160, 52, 26),
                                      (132, 158, 40, 20), (MX - 18, MY, 50, 22), (MX + 16, MY, 58, 24), (MX, MY - 2, 80, 30)]):
        fire(c, x, y, h, w, (i % 3 - 1) * 4, 840 + i)
    embers(c, 20, 0, 300, 200, 50, 849, ang=-70, L=(5, 13))
    c.f("fumaca", "#3a2a30", blob(90, 40, 40, 850, 10, 0.3, 0.7), op=0.55)
    c.f("fumaca", "#3a2a30", blob(230, 30, 46, 851, 10, 0.3, 0.7), op=0.55)
    # o herói de costas chegando correndo pela estrada (frente, embaixo)
    dust(c, 70, 262, 22, 10, "#8a6a4a", 852, (2, 5), op=0.7)
    c.fig("heroi", hero3.pose("correr_costas"), 84, 292, -8, 0.86, guide=hero3.GUIDE["correr_costas"])
    c.save()


# =========================================================================== REDE DE PICHE
def tar_net():
    c = Card("tar_net")
    sky(c, "#6a7a5a", "#c8c08a")
    # câmera de cima: chão de terra; o cenário: o toco de árvore onde a rede está amarrada
    c.b("chao", "#9a8a5a", RECT, mode="poly")
    c.b("chao_luz", "#b0a070", ellipse(150, 170, 150, 90, -8, 20), op=0.6)
    c.b("toco", "#5a3a22", [(214, 40), (226, 10), (262, 4), (290, 18), (296, 52), (276, 74), (234, 72)])
    c.b("toco_topo", "#9a7040", ellipse(256, 30, 30, 16, -8, 14))
    c.b("toco_aneis", "#6a4a2a", ellipse(256, 30, 16, 8, -8, 12), closed=False, sw=1.0)
    # poça de piche embaixo do herói
    c.b("poca", TAR, blob(150, 232, 86, 861, 12, 0.2, 0.32))
    c.b("poca_brilho", TAR_L, ellipse(120, 226, 30, 4, -4, 10), op=0.7)
    # respingos de piche (efeito, atrás)
    r = rng(862)
    for i in range(12):
        a = r.random() * 2 * math.pi; d = 90 + r.random() * 40
        c.f("respingo", TAR, blob(150 + math.cos(a) * d, 150 + math.sin(a) * d * 0.7, 2 + r.random() * 4, 863 + i, 7, 0.3), op=0.9)
    HX, HY, HS = 150, 244, 1.4
    J = hero3.J("enredado")
    pcs = soak(hero3.pose("enredado"), J, seed=9, n=8, col=TAR)
    c.fig("heroi", pcs, HX, HY, -4, HS, guide=hero3.GUIDE["enredado"])
    # a rede de piche por cima do herói: fios grossos pretos presos em estacas e no toco (silhueta própria)
    anchors = [(24, 250), (14, 120), (90, 30), (250, 52), (292, 168)]
    ctr = (156, 168)
    net = []
    for k, a in enumerate(anchors):
        net.append(Pc(f"fio{k}", "rede", TAR, brush([a, ((a[0] + ctr[0]) / 2 + 4, (a[1] + ctr[1]) / 2 + 6), ctr], 4.0, 2.4, per=3)))
    for ring_r in (44, 92):
        pts = []
        for k in range(len(anchors) + 1):
            a = A(anchors[k % len(anchors)]); v = (a - A(ctr)); v = v / np.linalg.norm(v)
            pts.append(A(ctr) + v * ring_r + (0, ring_r * 0.12))
        for k in range(len(pts) - 1):
            m = (pts[k] + pts[k + 1]) / 2 + (0, ring_r * 0.12)
            net.append(Pc(f"anel{ring_r}_{k}", "rede", TAR, brush([pts[k], m, pts[k + 1]], 2.8, 2.8, per=3)))
    for k, a in enumerate(anchors):
        if k in (3,):
            continue
        net.append(Pc(f"estaca{k}", "rede", "#6a4a2a", [(a[0] - 3, a[1] + 4), (a[0] - 2, a[1] - 10), (a[0] + 2, a[1] - 10), (a[0] + 3, a[1] + 4)], mode="poly"))
    for k in range(6):
        x = 70 + k * 30; y = 150 + (k % 3) * 26 - 20
        net.append(Pc(f"pingo{k}", "rede", TAR, [(x - 2, y), (x, y - 2), (x + 2, y), (x + 1.4, y + 9), (x, y + 12), (x - 1.4, y + 9)]))
        net.append(Pc(f"brilho_fio{k}", "rede", TAR_L, [(x - 6, y - 4), (x + 2, y - 6)], closed=False, cls="inner", sw=0.8))
    c.fig("rede", net, 0, 0)
    c.save()


# =========================================================================== IMPOSTO DE SANGUE
def blood_tax():
    c = Card("blood_tax")
    sky(c, "#1a2230", "#4a5a6a")
    disk(c, "lua", 82, 70, 40, "#c8c8c0", "#e8e8dc")
    ground(c, "chao", "#3a3a40", 214, 204)
    # o cenário: o altar do tributo com a taça de ouro (esquerda), onde o sangue vira moedas
    c.b("altar", "#5a5460", [(24, 252), (30, 200), (106, 196), (112, 250)], mode="poly")
    c.b("altar_tampo", "#7a7480", [(18, 204), (24, 190), (114, 186), (118, 200)], mode="poly")
    c.b("altar_runa", BLOOD, [(52, 222), (68, 212), (84, 222), (68, 232)], op=0.8)
    c.b("taca_pe", GOLD_D, [(56, 190), (82, 190), (74, 180), (72, 160), (66, 160), (64, 180)], mode="poly")
    c.b("taca", GOLD, [(46, 130), (92, 130), (88, 150), (76, 162), (62, 162), (50, 150)])
    c.b("taca_sangue", BLOOD, ellipse(69, 132, 22, 5, 0, 12))
    c.b("taca_luz", GOLD_L, [(52, 136), (58, 136), (60, 152)], closed=False, sw=2)
    # o fio de sangue do peito do herói até a taça; as gotas viram moedas no caminho
    HX, HY, HS = 214, 256, 1.12
    J = hero3.J("cambalear")
    Mh = tmat(HX, HY, 4, HS)
    chest = hero_at(Mh, J, "wl", (2, 4))
    pts = [chest, (chest[0] - 30, chest[1] - 40), (150, 80), (110, 92), (80, 124)]
    wisp(c, pts, 8, 2, BLOOD, op=0.85, name="sangue")
    wisp(c, [(p[0] + 4, p[1] + 6) for p in pts], 4, 1.2, BLOOD_L, op=0.6, name="sangue")
    S = cr_sample([A(p) for p in pts], 8)
    for k, i in enumerate(range(6, len(S) - 4, 4)):
        x, y = S[i]
        if k % 2 == 0:
            c.f("gota", BLOOD, drop(x + 8, y + 10, 3.4, 200), op=0.95)
        else:
            coin_face(c, x - 6, y - 10, 4.6, k * 30)
    glints(c, [(69, 120, 1.3), (100, 100, 0.9)])
    c.f("aura", BLOOD_D, ellipse(chest[0], chest[1], 26, 22, 0, 12), op=0.45)
    pcs = hero3.pose("cambalear")
    pcs.append(Pc("ferida", "corpo", BLOOD, ellipse(J["wl"][0] + 4, J["wl"][1] + 6, 5, 3.4, 20, 8), cls="inner"))
    c.fig("heroi", pcs, HX, HY, 4, HS, guide=hero3.GUIDE["cambalear"])
    c.save()


# =========================================================================== AVALANCHE DE OURO
def gold_avalanche():
    c = Card("gold_avalanche")
    sky(c, "#2a1a2a", "#6a4a4a")
    # o cenário: a boca da caverna do tesouro (rocha em cima à esquerda) de onde desaba o ouro
    c.b("rocha", "#2e2228", [(-10, -10), (180, -10), (150, 30), (100, 50), (40, 70), (-10, 90)])
    c.b("rocha_luz", "#4a383e", [(-10, 60), (40, 46), (96, 30), (140, 10), (100, 40), (40, 64), (-10, 80)], op=0.8)
    for i, (x, y, h) in enumerate([(160, 20, 30), (120, 40, 22), (60, 62, 26)]):
        c.b(f"estalactite{i}", "#2e2228", [(x - 7, y - 4), (x + 7, y - 4), (x, y + h)], mode="poly")
    ground(c, "chao", "#3a2a2a", 236, 226)
    # a onda de ouro (o protagonista): vem do canto de cima à esquerda e quebra em crista por cima do herói
    wave = [(-10, 30), (50, 22), (120, 30), (180, 50), (226, 80), (250, 112), (246, 134), (230, 126), (214, 108), (194, 104),
            (172, 122), (156, 160), (156, 200), (176, 236), (214, 258), (310, 266), (310, 300), (-10, 300)]
    c.f("onda_sombra", GOLD_D, [(x + 6, y + 8) for x, y in wave])
    c.f("onda", GOLD, wave)
    c.f("onda_luz", GOLD_L, brush([(0, 44), (60, 38), (130, 48), (190, 70), (232, 104)], 12, 4), op=0.9)
    c.f("onda_dobra", GOLD_D, brush([(40, 120), (90, 110), (140, 120), (170, 150)], 6, 2), op=0.8)
    c.f("onda_dobra", GOLD_D, brush([(30, 200), (80, 180), (130, 190), (160, 220)], 6, 2), op=0.8)
    r = rng(871)
    for i in range(46):
        x = -10 + r.random() * 230; y = 40 + r.random() * 240
        if x > 150 + (y - 100) * 0.1 and y < 230:
            continue
        coin(c, x, y, 3 + r.random() * 2.6, 0.45, r.normal(0, 30), name="onda_moeda", layer="f")
    # moedas espirrando da crista, sobre o herói e para a direita
    for i in range(26):
        a = math.radians(-60 + r.random() * 150); d = 14 + r.random() * 60
        coin_face(c, 244 + math.cos(a) * d, 120 + math.sin(a) * d * 0.8, 3.4 + r.random() * 2.4, r.random() * 180)
    glints(c, [(60, 44, 1.4), (190, 72, 1.3), (90, 160, 1.0), (262, 150, 0.9)])
    for i in range(7):
        y = 150 + i * 12
        c.f("veloc", "#e8d0a0", wedge(250, y + 8, 296, y - 4, 2.4), mode="poly", op=0.55)
    # o herói arremessado de costas pela onda, preso na frente da crista
    c.fig("heroi", hero3.pose("derrubado"), 214, 250, 12, 1.12, guide=hero3.GUIDE["derrubado"])
    # a borda da frente da onda engolindo o quadril e as pernas de baixo (silhueta própria)
    lip = [(120, 300), (140, 246), (170, 222), (204, 214), (234, 220), (262, 236), (290, 250), (310, 256), (310, 300)]
    c.fig("ouro", [Pc("crista", "massa", GOLD, lip), Pc("crista_luz", "massa", GOLD_L, [(160, 240), (200, 226), (240, 232), (204, 236)], cls="inner")]
          + [Pc(f"crista_moeda{k}", "massa", GOLD_D, ellipse(160 + k * 24, 250 + (k % 2) * 6, 5, 2.4, 0, 8), cls="inner") for k in range(6)], 0, 0)
    c.save()


ALL = dict(elder_dragon=elder_dragon, kobold_scavengers=kobold_scavengers, furnace=furnace, dragon_vault=dragon_vault,
           burn_village=burn_village, tar_net=tar_net, blood_tax=blood_tax, gold_avalanche=gold_avalanche)

if __name__ == "__main__":
    for nm in (sys.argv[1:] or ALL):
        ALL[nm]()
        print(nm)
