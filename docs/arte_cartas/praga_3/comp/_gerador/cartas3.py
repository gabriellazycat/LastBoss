"""Composições do lote praga_3 (coordenadas de carta 300x420; janela 11..289 x 11..278; fita y >= 261).
Reaproveita (só leitura) as utilidades dos lotes praga_1 (cards: speedlines, dust, rng, RECT) e praga_2 (cartas: Card, sky,
disk, rings, ground). Saída e rascunho: LB_OUT / LB_SCR (ver base.py). Uso: python cartas3.py [ids...]"""
import base  # noqa: F401
from base import OUT, SCR
import sys, math
import numpy as np
from geom import *
import rat, hero, wolf
import slime, piper
from rat import mix
from cards import speedlines, dust, rng, RECT  # praga_1
import cartas as C2  # praga_2 (Card, sky, disk, rings, ground)
from cartas import sky, disk, rings, ground
from render import shot

INK = "#2b1a10"


class Card(C2.Card):
    """Card do praga_2 + #enxame_frente (bichos na frente das figuras) + saída parametrizada."""

    def fsil(self, poly, x, y, rot, s, flip=False, fill="#3a2a20", op=None):
        M = tmat(x, y, rot, -s if flip else s, s)
        self.enn += 1
        self.front.append(Pc(f"enxf_{self.enn}", f"enxame_frente_{self.enn}", fill, pts=list(ap(M, poly)), mode="poly", op=op))
        return M

    def svg(self):
        s = super().svg()
        if self.front:
            g = '<g id="enxame_frente">\n  ' + "\n  ".join(p.svg(None, "") for p in self.front) + "\n</g>\n"
            s = s.replace('<path id="acao"', g + '<path id="acao"') if 'id="acao"' in s else s.replace("</svg>", g + "</svg>")
        return s

    def save(self):
        s = self.svg()
        open(f"{OUT}/{self.cid}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{OUT}/{self.cid}.png", (11, 11, 278, 267), 556, 534)
        shot(s, f"{SCR}/{self.cid}_guia.png", (11, 11, 278, 267), 556, 534, guide=True)


def note(c, x, y, s, col, op=0.9, rot=-12):
    """Nota musical (colcheia) como efeito."""
    M = tmat(x, y, rot, s)
    c.f("nota", col, list(ap(M, ellipse(0, 0, 4.2, 3, -20, 8))), op=op)
    c.f("nota", col, list(ap(M, [(3, -1), (4.6, -1), (4.6, -18), (3, -18)])), mode="poly", op=op)
    c.f("nota", col, list(ap(M, [(4.6, -18), (11, -13), (10, -10), (4.6, -14)])), mode="poly", op=op)


def flies(c, cx, cy, R, n, seed):
    r = rng(seed)
    for i in range(n):
        x = cx + r.normal(0, R); y = cy + r.normal(0, R * 0.7)
        c.f("mosca", INK, [(x - 2.4, y), (x, y - 1.4), (x + 2.4, y), (x, y + 1.4)], op=0.9)


def stones(c, x0, y0, x1, y1, col, seed, rows=6, cols=6, op=0.45, jitter=0.0):
    """Juntas de pedra (linhas) num retângulo."""
    r = rng(seed)
    h = (y1 - y0) / rows
    for i in range(rows + 1):
        y = y0 + i * h
        c.b(f"junta_h{seed}_{i}", col, [(x0, y), (x1, y + r.normal(0, jitter))], closed=False, sw=0.9, op=op)
        if i < rows:
            w = (x1 - x0) / cols
            off = (i % 2) * w / 2
            for k in range(cols + 1):
                x = x0 + off + k * w
                if x0 < x < x1:
                    c.b(f"junta_v{seed}_{i}_{k}", col, [(x, y), (x, y + h)], closed=False, sw=0.9, op=op)


def rat_mouth(M, posename="atacar", var="comum"):
    hx, hy, ha, hs, op = rat.POSES[posename]["head"]
    return ap(chain(M, tmat(hx, hy, ha, hs * rat.PAL[var]["hk"])), [(31, 3.6)])[0]


# =========================================================================== SLIME
def slime_card():
    c = Card("slime")
    c.b("fundo", "#3e4452", RECT, mode="poly")
    # túnel de esgoto (o cenário): arco de pedra, boca escura atrás do slime
    c.b("arco", "#5c6070", [(10, 300), (12, 120), (40, 52), (100, 18), (170, 14), (236, 40), (278, 100), (292, 200), (292, 300)])
    c.b("boca", "#1e2028", [(44, 300), (46, 140), (70, 82), (118, 54), (166, 52), (214, 74), (246, 124), (258, 200), (258, 300)])
    for i, a in enumerate(np.linspace(math.pi * 1.04, math.pi * 1.96, 9)):
        x0 = 151 + math.cos(a) * 108; y0 = 176 + math.sin(a) * 124; x1 = 151 + math.cos(a) * 140; y1 = 176 + math.sin(a) * 158
        c.b(f"aduela{i}", INK, [(x0, y0), (x1, y1)], closed=False, sw=1.0, op=0.5)
    c.b("chao", "#4a4e58", [(-10, 226), (310, 214), (310, 300), (-10, 300)], mode="poly")
    c.b("canal", "#5e7a3a", [(-10, 244), (310, 234), (310, 262), (-10, 272)], mode="poly", op=0.85)
    c.b("canal_luz", "#9ab85a", [(60, 248), (200, 242), (204, 248), (64, 254)], mode="poly", op=0.6)
    # o corte que acabou de dividir o slime: arco branco do golpe atrás do fio de gosma
    c.f("corte", "#f4f8e0", brush([(150, 30), (196, 74), (226, 128), (236, 186)], 1.5, 9), op=0.85)
    c.f("corte", "#e2f2a0", brush([(160, 40), (200, 80), (224, 130)], 1, 4), op=0.6)
    r = rng(201)
    for i in range(16):
        a = math.radians(-70 + r.random() * 140); d = 20 + r.random() * 60
        x = 214 + math.cos(a) * d; y = 120 + math.sin(a) * d
        c.f("respingo", "#b8dc5a", ellipse(x, y, 1.6 + r.random() * 2.6, 1.4 + r.random() * 2, math.degrees(a), 7), op=0.9)
    # terceira geração: slimezinhos no chão (silhuetas)
    for i, (x, y, s, fl) in enumerate([(248, 236, 0.26, 0), (36, 238, 0.22, 1), (270, 220, 0.18, 0)]):
        c.sil(slime.silhouette("ameaca"), x, y, 0, s, flip=bool(fl), fill="#7aa832",
              eyes=("#fff36a", [(-1, -38), (14, -38)], 4) if s > 0.2 else None)
    c.fig("slime", slime.pose("dividir"), 100, 226, -14, 1.74, guide=slime.GUIDE["dividir"])
    c.save()


# =========================================================================== FLAUTISTA CORROMPIDO
def corrupt_piper():
    c = Card("corrupt_piper")
    sky(c, "#7a6a9a", "#f0c890")
    disk(c, "lua", 168, 70, 50, "#f6e6b8", "#fff6dc")
    # portão da cidade (o cenário): torre e arco, inclinado, à esquerda
    c.b("torre", "#5a4a5e", [(-10, 40), (30, 30), (64, 38), (70, 220), (-10, 230)], mode="poly")
    c.b("torre_teto", "#3e3044", [(-14, 44), (26, -10), (72, 42)], mode="poly")
    c.b("arco_portao", "#2a2230", [(4, 230), (6, 150), (22, 124), (42, 124), (56, 150), (58, 226)])
    c.b("janela", "#f0c070", [(30, 66), (40, 64), (40, 84), (30, 86)], mode="poly")
    ground(c, "chao", "#8a7a5e", 222, 210)
    for i in range(7):
        x = -10 + i * 48
        c.b(f"pedra{i}", INK, [(x, 236 - i * 1.6), (x + 30, 234 - i * 1.6)], closed=False, sw=0.8, op=0.35)
    # o bando apressado pela música: ratos correndo em fila para a direita, com linhas de velocidade
    r = rng(211)
    for i in range(11):
        x = 70 + i * 22 + r.normal(0, 4); y = 236 + r.normal(0, 6) - i * 1.2
        c.sil(rat.silhouette("correr", "comum"), x, y, -4 + r.normal(0, 4), 0.3 + r.random() * 0.08, fill=mix("#5a4e48", "#2e2622", r.random()))
    for i in range(10):
        y = 222 + r.random() * 30; x0 = 40 + r.random() * 150
        c.f("veloc", "#fff4d0", wedge(x0, y, x0 + 30 + r.random() * 30, y - 2, 2.4), mode="poly", op=0.6)
    # a melodia: notas e ondas verdes saindo da flauta e descendo até o bando
    M = tmat(122, 282, -8, 1.38)
    J = piper.POSES["tocar_salto"]
    hx, hy, ha = J["head"]
    m0 = ap(chain(M, tmat(hx, hy, ha)), [piper.MOUTH_PT])[0]
    fa = math.radians(J["fdir"] - 8)
    bell = m0 + np.array([math.cos(fa), math.sin(fa)]) * 44 * 1.38
    for i, (dx, dy, s) in enumerate([(14, -10, 1.1), (34, 4, 1.0), (52, 22, 0.9), (66, 44, 0.8), (40, 34, 0.7), (78, 16, 0.75)]):
        note(c, bell[0] + dx * 1.2, bell[1] + dy, s * 1.5, "#9ad040", rot=-12 + i * 6)
    rings(c, bell[0] - 4, bell[1] - 4, [16, 28, 40], -30, 80, "#c8ec6a", w0=4, op0=0.75, name="som")
    c.fig("flautista", piper.pose("tocar_salto"), 122, 282, -8, 1.38, guide=piper.GUIDE["tocar_salto"])
    c.save()


# =========================================================================== ESGOTO TRANSBORDANTE
def sewer_flood():
    c = Card("sewer_flood")
    c.b("muro", "#8a8272", RECT, mode="poly")
    c.b("muro_sombra", "#6e675a", [(-10, 160), (310, 120), (310, 300), (-10, 300)], mode="poly", op=0.6)
    stones(c, -10, -10, 310, 170, INK, 221, rows=6, cols=7, op=0.3)
    # a saída de esgoto (a estrutura): boca redonda de pedra, grade arrebentada
    c.b("boca_anel", "#5e584c", ellipse(96, 82, 76, 70, -8, 22))
    for i, a in enumerate(np.linspace(0, 2 * math.pi, 13)[:-1]):
        c.b(f"aduela{i}", INK, [(96 + math.cos(a) * 58, 82 + math.sin(a) * 53), (96 + math.cos(a) * 76, 82 + math.sin(a) * 70)], closed=False, sw=1.0, op=0.55)
    c.b("boca", "#1a1814", ellipse(98, 84, 56, 51, -8, 20))
    for i, (x0, y0, x1, y1) in enumerate([(56, 40, 40, 120), (84, 34, 78, 70), (130, 40, 160, 86), (150, 56, 168, 64)]):
        c.b(f"grade{i}", "#4a3a30", brush([(x0, y0), ((x0 + x1) / 2 + 3, (y0 + y1) / 2), (x1, y1)], 4.5, 3.5), op=1)
    c.b("grade_ferrugem", "#8a5a34", brush([(90, 30), (104, 26), (120, 30)], 3, 2))
    # torrente verde-esgoto em diagonal até a frente
    c.b("agua", "#6e8a34", [(52, 100), (90, 120), (140, 108), (170, 130), (220, 170), (270, 196), (310, 210), (310, 300), (40, 300), (30, 220), (40, 150)])
    c.b("agua_escura", "#4e6a26", [(40, 180), (80, 200), (140, 230), (200, 250), (310, 270), (310, 300), (30, 300)], op=0.9)
    for i, P in enumerate([[(60, 120), (90, 150), (130, 170), (180, 196)], [(100, 118), (150, 140), (210, 178), (260, 204)],
                           [(48, 170), (100, 210), (170, 240)], [(140, 130), (190, 162), (250, 190), (300, 214)]]):
        c.b(f"espuma{i}", "#d8e8a0", brush(P, 1.5, 5), op=0.8)
    # ratos sendo cuspidos pela torrente (enxame) — um por segundo
    r = rng(222)
    for i, (x, y, s, rot, fl, nm) in enumerate([(70, 82, 0.28, 30, 0, "correr"), (112, 96, 0.3, 60, 1, "atacar"), (60, 140, 0.34, 20, 0, "atacar"),
                                                 (250, 200, 0.36, 10, 0, "correr"), (40, 200, 0.4, -20, 1, "correr"), (150, 128, 0.3, 40, 0, "correr"),
                                                 (282, 232, 0.4, -6, 0, "atacar")]):
        c.sil(rat.silhouette(nm, "comum"), x, y, rot, s, flip=bool(fl), fill=mix("#4a4038", "#2a221e", r.random()))
    r2 = rng(223)
    for i in range(18):
        x = 130 + r2.normal(0, 40); y = 150 + r2.normal(0, 30)
        c.f("gota", "#c8e07a", ellipse(x, y, 1.4 + r2.random() * 2.4, 1.2 + r2.random() * 1.6, 0, 6), op=0.85)
    speedlines(c, 200, 150, 12, 40, 110, "#eef4d0", 224, op=0.45, a0=math.radians(-40), a1=math.radians(60))
    c.fig("rato", rat.pose_saltar("comum"), 200, 132, 14, 0.62, guide=[(-60, 160), (-20, 80), (0, 0), (20, -60)])
    c.save()


# =========================================================================== MORDIDA INFECTADA
def infected_bite():
    c = Card("infected_bite")
    sky(c, "#3a3e5a", "#7a8094")
    # árvore morta (o cenário), atrás à esquerda
    c.b("arvore", "#262838", [(20, 300), (30, 200), (24, 130), (8, 70), (-10, 40), (-10, -10), (14, -10), (30, 50), (44, 90), (70, 40), (98, 10),
                              (104, 20), (80, 56), (58, 110), (56, 200), (70, 300)])
    ground(c, "chao", "#3a3c4a", 236, 228)
    HX, HY, HR, HS = 198, 242, -4, 1.0
    Mh = tmat(HX, HY, HR, HS)
    J = hero.POSES["defesa"]
    bite_local = (A(J["kl"]) * 0.6 + A(J["al"]) * 0.4)
    bite = ap(Mh, [bite_local])[0]
    # explosão de peste no ponto da mordida (atrás), veias verdes e bolhas subindo
    c.f("brilho", "#b8e05a", blob(bite[0], bite[1], 46, 5, 12, 0.18), op=0.55)
    c.f("brilho", "#e8f8a0", blob(bite[0], bite[1], 24, 6, 10, 0.2), op=0.8)
    r = rng(231)
    for i in range(10):
        a = r.random() * 6.283; d0 = 14; d1 = 34 + r.random() * 30
        c.f("raio", "#d8f080", wedge(bite[0] + math.cos(a) * d1, bite[1] + math.sin(a) * d1, bite[0] + math.cos(a) * d0, bite[1] + math.sin(a) * d0, 3.4), mode="poly", op=0.8)
    for i in range(10):
        x = bite[0] + r.normal(0, 30); y = bite[1] - 20 - r.random() * 70
        rr = 2 + r.random() * 4
        c.f("bolha", "#a6d84a", ellipse(x, y, rr, rr, 0, 8), op=0.75)
    pcs = hero.pose("defesa")
    # infecção no braço do herói: manchas verdes saindo da mordida (inner)
    el, wl = A(J["kl"]), A(J["hl"])
    for k, t in enumerate([0.3, 0.7]):
        q = el + (wl - el) * t
        pcs.append(Pc(f"peste{k}", "corpo", "#8ac03a", blob(q[0], q[1] + 2, 3.4, 300 + k, 7, 0.3), cls="inner", op=0.9))
    for k, P in enumerate([[el + (2, -2), el + (-3, -12), el + (0, -24)], [el + (-2, 2), el + (4, -10), el + (8, -20)]]):
        pcs.append(Pc(f"veia{k}", "corpo", "#6aa02a", P, closed=False, cls="inner", sw=1.4))
    c.fig("heroi", pcs, HX, HY, HR, HS)
    # o rato: bote da ficha (atacar), girado, com a boca fechando no antebraço
    rot, s = -16, 1.42
    M0 = tmat(0, 0, rot, s)
    m0 = rat_mouth(M0)
    tx, ty = bite - m0 + np.array([-2, 3])
    c.fig("rato", rat.pose("atacar", "raivoso"), tx, ty, rot, s, guide=[(-70, -36), (-20, -32), (20, -34), (60, -24), (92, -2)])
    speedlines(c, 60, 230, 12, 20, 70, "#c8d0e8", 232, op=0.4, a0=math.radians(120), a1=math.radians(220))
    c.save()


# =========================================================================== DEVORAR
def devour():
    c = Card("devour")
    sky(c, "#5a2a34", "#d88a5a")
    disk(c, "brilho", 176, 96, 70, "#f0b070", "#f8d8a0")
    # altar de pedra (o cenário): laje do sacrifício com ossos
    c.b("altar", "#5a4e4e", [(0, 300), (8, 206), (150, 196), (236, 206), (244, 300)], mode="poly")
    c.b("altar_topo", "#7a6c68", [(0, 206), (40, 190), (180, 182), (250, 196), (236, 206), (150, 198), (8, 208)], mode="poly")
    c.b("altar_fenda", INK, [(70, 210), (80, 236), (74, 262)], closed=False, sw=1.2, op=0.6)
    c.b("altar_sangue", "#7a1a1e", [(120, 190), (150, 188), (154, 196), (140, 220), (134, 200)], op=0.9)
    ground(c, "chao", "#3e2a2a", 240, 236, 240, 310)
    for i, (x, y, a) in enumerate([(30, 194, -10), (190, 188, 20), (214, 196, -30)]):
        M = tmat(x, y, a)
        c.b(f"osso{i}", "#efe4c8", list(ap(M, [(-10, -1.6), (10, -1.6), (12, -3.4), (14, 0), (12, 3.4), (10, 1.6), (-10, 1.6), (-12, 3.4), (-14, 0), (-12, -3.4)])), mode="cr")
    WX, WY, WR, WS = 34, 198, -8, 1.42
    M = tmat(WX, WY, WR, WS)
    hx, hy, ha, hs, op = wolf.POSES["ameaca"]["head"]
    Mhd = chain(M, tmat(hx, hy, ha, hs * wolf.PAL["alfa"]["hk"]))
    jaw = ap(Mhd, [(27, 2)])[0]
    chest = ap(M, [(56, -44)])[0]
    # aura de fúria vermelha atrás da fera e as almas dos ratos sacrificados sendo sugadas (enxame translúcido)
    for i, rr in enumerate([84, 62]):
        c.f("aura", "#ff4a3a", blob(chest[0] - 10, chest[1] - 6, rr, 20 + i, 14, 0.22, 0.75), op=0.22 + i * 0.12)
    for i, (x, y, rot, s) in enumerate([(236, 44, 20, 0.5), (60, 70, -20, 0.46)]):
        c.sil(rat.silhouette("correr", "comum"), x, y, rot, s, flip=(i == 0), fill="#ffb0a0", op=0.6)
        P = [(x + (-20 if i == 0 else 30), y + 10), ((x + chest[0]) / 2 + (30 if i == 0 else -20), (y + chest[1]) / 2 - 10), (chest[0] + 10, chest[1] - 10)]
        c.f("alma", "#ff8a6a", brush(P, 10, 2), op=0.55)
    # cura: cruzes verdes subindo
    r = rng(241)
    for i in range(7):
        x = 40 + r.random() * 140; y = 60 + r.random() * 120; s = 2.4 + r.random() * 2
        c.f("cura", "#a6e05a", [(x - s, y - s * 0.35), (x - s * 0.35, y - s * 0.35), (x - s * 0.35, y - s), (x + s * 0.35, y - s), (x + s * 0.35, y - s * 0.35),
                                (x + s, y - s * 0.35), (x + s, y + s * 0.35), (x + s * 0.35, y + s * 0.35), (x + s * 0.35, y + s), (x - s * 0.35, y + s),
                                (x - s * 0.35, y + s * 0.35), (x - s, y + s * 0.35)], mode="poly", op=0.9)
    # o rato nas mandíbulas (atrás da cabeça do lobo, atravessado)
    rr = jaw - ap(tmat(0, 0, 98, 0.74), [(6, -26)])[0] + np.array([0, 4])  # garupa do rato presa entre os dentes
    c.fig("rato", rat.pose("correr", "comum"), rr[0], rr[1], 98, 0.74)
    c.fig("fera", wolf.pose("ameaca", "alfa"), WX, WY, WR, WS, guide=wolf.GUIDE["ameaca"])
    c.save()


# =========================================================================== PRAGA BUBÔNICA
def bubonic_plague():
    c = Card("bubonic_plague")
    sky(c, "#5a6a4a", "#c8c890")
    # porta marcada com a cruz da peste (o cenário)
    c.b("parede", "#8a7e6a", [(-10, -10), (130, -10), (126, 300), (-10, 300)], mode="poly")
    c.b("porta", "#5a3e2c", [(14, 300), (16, 70), (40, 40), (76, 36), (100, 64), (102, 300)])
    for i, x in enumerate([38, 60, 82]):
        c.b(f"tabua{i}", INK, [(x, 50 + abs(x - 58) * 0.3), (x, 300)], closed=False, sw=1.0, op=0.5)
    c.b("cruz_v", "#c0302a", brush([(58, 74), (60, 120), (58, 170)], 9, 7), op=0.9)
    c.b("cruz_h", "#c0302a", brush([(30, 112), (60, 114), (88, 110)], 8, 7), op=0.9)
    ground(c, "chao", "#5a5444", 236, 230)
    # miasma verde atrás do herói + moscas
    for i, (x, y, rr) in enumerate([(186, 70, 60), (230, 120, 50), (150, 140, 48), (210, 40, 40)]):
        c.f("miasma", "#9ab83a", blob(x, y, rr, 50 + i, 10, 0.25), op=0.35)
    flies(c, 200, 70, 34, 14, 251)
    J = hero.POSES["preso"]
    pcs = hero.pose("preso")
    # bubões (acúmulos de Peste) nas juntas: roxo-escuro com borda verde acesa (inner)
    for k, (key, dx, dy, rr) in enumerate([("neck", 6, 4, 4.4), ("el", 0, 0, 4.0), ("sr", -4, 6, 3.6), ("kr", -2, -4, 4.2), ("hc", 4, -12, 3.8), ("kl", 2, 0, 3.4)]):
        x, y = A(J[key]) + (dx, dy)
        pcs.append(Pc(f"bubao{k}", "corpo", "#9ad040", ellipse(x, y, rr + 1.2, rr + 0.9, 0, 9), cls="inner"))
        pcs.append(Pc(f"bubao{k}_c", "corpo", "#3a2440", ellipse(x, y, rr, rr * 0.8, 0, 9), cls="inner"))
    c.fig("heroi", pcs, 182, 286, 8, 1.36, guide=[(-20, -1), (-14, -40), (0, -80), (6, -130), (20, -160)])
    # ratos mordendo as pernas (na frente do herói)
    for i, (x, y, rot, s, fl) in enumerate([(122, 238, -30, 0.42, 0), (250, 244, 24, 0.4, 1), (140, 256, -10, 0.36, 0)]):
        c.fsil(rat.silhouette("atacar", "comum"), x, y, rot, s, flip=bool(fl), fill="#3e3430")
    c.save()


# =========================================================================== NINHO-MÃE
def mother_nest():
    c = Card("mother_nest")
    sky(c, "#8a7aa0", "#e8c890")
    # o ninho (a estrutura): monte de palha, trapos e ossos, com a toca central acesa
    c.b("ninho", "#9a7a48", [(-10, 300), (-10, 200), (30, 170), (80, 150), (150, 142), (220, 150), (270, 172), (310, 196), (310, 300)])
    c.b("ninho_sombra", "#7a5e36", [(-10, 250), (60, 236), (150, 240), (240, 232), (310, 244), (310, 300), (-10, 300)], op=0.9)
    c.b("trapo", "#7a5a8a", [(20, 200), (60, 186), (78, 206), (40, 220)], op=0.9)
    c.b("trapo2", "#a8586a", [(222, 186), (262, 192), (270, 214), (232, 210)], op=0.9)
    r = rng(261)
    for i in range(26):
        x = r.random() * 300; y = 160 + r.random() * 80; a = r.normal(0, 0.5)
        c.b(f"palha{i}", "#e0c070", [(x, y), (x + math.cos(a) * 16, y + math.sin(a) * 6)], closed=False, sw=1.2)
    for i, (x, y, a) in enumerate([(98, 214, 20), (214, 222, -14)]):
        M = tmat(x, y, a)
        c.b(f"osso{i}", "#efe4c8", list(ap(M, [(-10, -1.6), (10, -1.6), (12, -3.4), (14, 0), (12, 3.4), (10, 1.6), (-10, 1.6), (-12, 3.4), (-14, 0), (-12, -3.4)])))
    c.b("toca_borda", "#4a3420", ellipse(150, 176, 44, 26, 0, 16))
    c.b("toca", "#2a1a10", ellipse(150, 178, 36, 20, 0, 16))
    c.b("toca_luz", "#d8f080", ellipse(150, 180, 24, 12, 0, 14), op=0.9)
    for i, (x, y) in enumerate([(40, 236), (262, 240)]):
        c.b(f"toca_lado{i}", "#2a1a10", ellipse(x, y, 16, 8, 0, 12))
    # pulso em dobro: dois conjuntos de anéis saindo da toca
    rings(c, 150, 180, [50, 70, 90], 180, 360, "#e8f080", w0=6, op0=0.85, name="pulso")
    rings(c, 150, 180, [118, 136], 180, 360, "#f8d870", w0=4, op0=0.6, name="pulso2")
    # filhotes saindo das tocas laterais (enxame)
    for i, (x, y, s, fl, rot) in enumerate([(56, 240, 0.32, 1, 6), (24, 252, 0.36, 1, -4), (246, 244, 0.32, 0, -6), (276, 254, 0.36, 0, 4),
                                            (90, 166, 0.26, 1, 12), (214, 168, 0.26, 0, -12)]):
        c.sil(rat.silhouette("correr", "comum"), x, y, rot, s, flip=bool(fl), fill=mix("#6a5e56", "#3a302a", 0.5))
    # dois ratos saltando juntos da mesma toca, em V (produz em dobro)
    c.fig("rato_esq", rat.pose("atacar", "comum"), 110, 186, 46, -1.06, 1.06, guide=None)
    c.fig("rato_dir", rat.pose("atacar", "comum"), 190, 186, -46, 1.06, guide=[(-70, -36), (-20, -32), (20, -34), (60, -24), (92, -2)])
    c.save()


# =========================================================================== ENXAME SEM FIM
def endless_swarm():
    c = Card("endless_swarm")
    sky(c, "#2e2a44", "#5a5070")
    cx, cy, rx, ry = 170, 156, 112, 60
    c.b("brilho", "#6a8a4a", ellipse(cx, cy + 6, rx * 0.9, ry * 1.3, 0, 18), op=0.7)
    c.b("brilho2", "#a6c860", ellipse(cx, cy + 10, rx * 0.5, ry * 0.7, 0, 16), op=0.6)
    ground(c, "chao", "#36304a", 214, 206)
    ring = [(cx + math.cos(a) * rx, cy + 4 + math.sin(a) * ry) for a in np.linspace(0, 2 * math.pi, 25)]
    c.b("trilha", "#7a9a4a", brush(ring, 16, 16), op=0.55)
    # o anel sem fim: ratos correndo em roda (perspectiva), metade de trás mais escura
    r = rng(271)
    n = 12
    for i in range(n):
        a = i / n * 2 * math.pi + 0.08
        x = cx + math.cos(a) * rx; y = cy + math.sin(a) * ry
        dx, dy = -math.sin(a) * rx, math.cos(a) * ry  # sentido de corrida (anti-horário no chão)
        left = dx < 0
        rot_ = max(-30, min(30, math.degrees(math.atan2(dy, abs(dx))))) * (-1 if left else 1)
        front = math.sin(a) > 0
        s = (0.64 if front else 0.46) + r.random() * 0.04
        poly = rat.silhouette("correr", "comum") * np.array([max(0.5, abs(math.sin(a))), 1.0])  # escorço nas laterais
        c.sil(poly, x, y, rot_, s, flip=left, fill=("#5e5462" if front else "#443c50"),
              eyes=("#c8f050", [(81 * max(0.5, abs(math.sin(a))), -35.5)], 1.8) if front and i % 2 == 0 else None)
    # o herói cercado, pequeno, no meio do anel
    c.fig("heroi", hero.pose("guarda"), cx + 6, cy + 30, 0, 0.5)
    # renascer: ossos no chão com chamas verdes subindo até o rato da frente
    for i, (x, y, a) in enumerate([(52, 236, 10), (84, 244, -20), (40, 250, 40)]):
        M = tmat(x, y, a, 0.9)
        c.f("osso", "#efe4c8", list(ap(M, [(-10, -1.6), (10, -1.6), (12, -3.4), (14, 0), (12, 3.4), (10, 1.6), (-10, 1.6), (-12, 3.4), (-14, 0), (-12, -3.4)])))
    c.f("cranio", "#efe4c8", [(60, 222), (70, 216), (84, 218), (92, 224), (86, 228), (70, 230)])
    for i, (x, h, w) in enumerate([(40, 70, 14), (62, 96, 18), (86, 80, 14), (110, 56, 10)]):
        P = [(x, 246), (x + 8, 246 - h * 0.35), (x - 4, 246 - h * 0.7), (x + 6, 246 - h)]
        c.f("chama", "#a6e05a", brush(P, w, 1), op=0.75)
        c.f("chama", "#e8f8a0", brush(P[:3], w * 0.45, 1), op=0.8)
    # eco fantasma do rato renascido (silhueta verde atrás)
    c.sil(rat.silhouette("atacar", "comum"), 70, 214, -26, 1.16, fill="#a6e05a", op=0.45)
    c.fig("rato", rat.pose("atacar", "raivoso"), 60, 232, -26, 1.2, guide=[(-70, -36), (-20, -32), (20, -34), (60, -24), (92, -2)])
    c.save()


ALL = dict(slime=slime_card, corrupt_piper=corrupt_piper, sewer_flood=sewer_flood, infected_bite=infected_bite, devour=devour,
           bubonic_plague=bubonic_plague, mother_nest=mother_nest, endless_swarm=endless_swarm)

if __name__ == "__main__":
    for k in (sys.argv[1:] or ALL):
        ALL[k](); print("ok", k)
