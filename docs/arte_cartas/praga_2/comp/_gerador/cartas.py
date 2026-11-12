"""Composições do lote praga_2 (coordenadas de carta 300x420; janela 11..289 x 11..278; fita y >= 261)."""
import base  # noqa: F401
import sys, math
import numpy as np
from geom import *
import rat, hero, wolf, bat, boar, werewolf
from rat import mix
from cards import speedlines, dust, rng, RECT, rect  # utilitários do lote praga_1 (só leitura)
from render import shot

OUT = "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/praga_2/comp"
SCR = "C:/Users/gabri/AppData/Local/Temp/claude/df0eb8c5d2d2aad7/388ffdb7-a033-4c30-8855-5da64eb88778/scratchpad/comp_praga_2"
INK = "#2b1a10"
wolf.PAL["caca"] = dict(wolf.PAL["comum"], eye="#ff3a2a", mane=1.2)


class Card:
    def __init__(self, cid):
        self.cid = cid; self.bg = []; self.enx = []; self.fx = []; self.figs = []; self.guide = None
        self.fxn = 0; self.enn = 0; self.front = []

    def b(self, name, fill, pts=None, d=None, mode="cr", op=None, closed=True, sw=None):
        self.bg.append(Pc(f"bg_{name}", f"bg_{name}", fill, pts=pts, d=d, mode=mode, op=op, closed=closed, sw=sw))

    def f(self, name, fill, pts=None, d=None, mode="cr", op=None, closed=True, sw=None):
        self.fxn += 1
        self.fx.append(Pc(f"fx_{name}{self.fxn}", "fx", fill, pts=pts, d=d, mode=mode, op=op, closed=closed, sw=sw))

    def sil(self, poly, x, y, rot, s, flip=False, fill="#3a2a20", op=None, eyes=None):
        M = tmat(x, y, rot, -s if flip else s, s)
        self.enn += 1
        self.enx.append(Pc(f"enx_{self.enn}", f"enxame_{self.enn}", fill, pts=list(ap(M, poly)), mode="poly", op=op))
        if eyes:
            col, pts, r = eyes
            for k, e in enumerate(ap(M, pts)):
                self.enx.append(Pc(f"enx_{self.enn}_olho{k}", f"enxame_{self.enn}", col, pts=ellipse(e[0], e[1], r * s, r * s * 0.75, rot, 6), cls="inner"))
        return M

    def fig(self, name, pcs, tx, ty, rot=0, sx=1, sy=None, guide=None):
        sy = sx if sy is None else sy
        M = tmat(tx, ty, rot, sx, sy)
        self.figs.append((name, pcs, tstr(tx, ty, rot, sx, sy)))
        if guide is not None:
            self.guide = list(ap(M, guide))
        return M

    def svg(self):
        o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 420">']
        o.append('<g id="bg">\n  ' + "\n  ".join(p.svg(None, "") for p in self.bg) + "\n</g>")
        if self.enx:
            o.append('<g id="enxame">\n  ' + "\n  ".join(p.svg(None, "") for p in self.enx) + "\n</g>")
        o.append('<g id="fx">\n  ' + "\n  ".join(p.svg(None, "") for p in self.fx) + "\n</g>")
        for name, pcs, t in self.figs:
            o.append(figure_svg(name, pcs, t))
        if self.guide is not None:
            o.append(f'<path id="acao" class="guide" d="{cr_path(self.guide, False)}" fill="none" stroke="#e0402a" stroke-width="2" stroke-dasharray="5 4"/>')
        o.append("</svg>\n")
        return "\n".join(o)

    def save(self):
        s = self.svg()
        open(f"{OUT}/{self.cid}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{OUT}/{self.cid}.png", (11, 11, 278, 267), 556, 534)
        shot(s, f"{SCR}/{self.cid}_guia.png", (11, 11, 278, 267), 556, 534, guide=True)


def sky(c, top, bottom, n=6):
    """Céu em faixas (aguada em degraus)."""
    c.b("ceu", bottom, RECT, mode="poly")
    for i in range(n):
        y = -10 + i * 24
        c.b(f"ceu{i}", mix(top, bottom, i / n), [(-10, -10), (310, -10), (310, y + 30), (-10, y + 22)], mode="poly", op=0.55)


def disk(c, name, cx, cy, r, col, core=None):
    c.b(name, col, ellipse(cx, cy, r, r, 0, 18))
    if core:
        c.b(name + "_centro", core, ellipse(cx - r * 0.12, cy - r * 0.12, r * 0.7, r * 0.7, 0, 16), op=0.7)


def rings(c, cx, cy, radii, a0, a1, col, w0=5, op0=0.8, name="onda"):
    for i, rr in enumerate(radii):
        pts = [(cx + math.cos(math.radians(a)) * rr, cy + math.sin(math.radians(a)) * rr) for a in np.linspace(a0, a1, 10)]
        c.f(name, col, brush(pts, max(1.2, w0 - i), 1.2), op=max(0.25, op0 - i * 0.13))


def ground(c, name, col, y0, y1, x0=-10, x1=310):
    c.b(name, col, [(x0, y0), (x1, y1), (x1, 300), (x0, 300)], mode="poly")


# =========================================================================== JAVALI DE GUERRA
def war_boar():
    c = Card("war_boar")
    sky(c, "#b9a6c4", "#ead8b0")
    c.b("serra", "#9a8aa6", [(-10, 150), (40, 128), (96, 140), (150, 118), (220, 136), (310, 120), (310, 190), (-10, 190)], op=0.8)
    ground(c, "chao", "#8a7a4e", 196, 186)
    # paliçada quebrada (o cenário): estacas tombando atrás do herói
    for i, (x, rot, h) in enumerate([(14, -28, 74), (38, -40, 66), (64, -12, 70), (92, 18, 50)]):
        M = tmat(x, 200, rot)
        c.b(f"estaca{i}", "#8a6a44", list(ap(M, [(-6, 0), (-6, -h), (0, -h - 9), (6, -h), (6, 0)])), mode="poly")
    c.b("estaca_corda", "#c8a870", [(4, 150), (40, 160), (76, 148)], closed=False, sw=1.6)
    # impacto: estrela de choque entre a presa e o herói
    ix, iy = 100, 104
    r = rng(61)
    for i in range(14):
        a = r.random() * 6.283; d0 = 6 + r.random() * 6; d1 = d0 + 16 + r.random() * 26
        c.f("choque", "#fff2b0", wedge(ix + math.cos(a) * d1, iy + math.sin(a) * d1, ix + math.cos(a) * d0, iy + math.sin(a) * d0, 3.4), mode="poly", op=0.9)
    dust(c, 196, 246, 70, 22, "#5a4630", 62, (1.2, 3.2))
    for x, y, rr in [(250, 236, 30), (150, 244, 24), (286, 214, 22)]:
        c.f("nuvem", "#e8d6a8", blob(x, y, rr, x, 9, 0.3, 0.5), op=0.6)
    speedlines(c, 250, 160, 10, 30, 70, "#fff4d0", 63, op=0.5, a0=math.radians(-40), a1=math.radians(40))
    # herói arremessado para trás, atordoado (estrelas acima do elmo)
    Mh = c.fig("heroi", hero.pose("defesa"), 74, 140, -40, 0.46)
    hc = ap(Mh, [hero.POSES["defesa"]["head"]])[0]
    for i in range(4):
        a = math.radians(-160 + i * 50)
        x, y = hc[0] + math.cos(a) * 16, hc[1] - 8 + math.sin(a) * 6
        star = [(x + math.cos(math.radians(k * 36 - 90)) * (4 if k % 2 == 0 else 1.7), y + math.sin(math.radians(k * 36 - 90)) * (4 if k % 2 == 0 else 1.7)) for k in range(10)]
        c.f("tontura", "#ffe066", star, mode="poly")
    c.fig("javali", boar.pose("lancar"), 252, 246, -2, -1.7, 1.7, guide=boar.GUIDE["lancar"])
    c.save()


# =========================================================================== MATILHA DE LOBOS
def wolf_pack():
    c = Card("wolf_pack")
    sky(c, "#a890a8", "#f0d8a0")
    disk(c, "sol", 214, 128, 50, "#f8e2a0", "#fff4d0")
    # pinheiros mortos (o cenário): orla da floresta
    for i, (x, h, w) in enumerate([(20, 150, 26), (58, 120, 20), (236, 140, 24), (270, 170, 30), (300, 120, 20)]):
        pts = [(x, 200 - h)]
        for k in range(1, 6):
            yy = 200 - h + k * h / 6
            pts = [(x - w * k / 6 - 3, yy)] + pts + [(x + w * k / 6 + 3, yy)]
        c.b(f"pinheiro{i}", "#4a4460", [(x - 3, 205)] + pts + [(x + 3, 205)], mode="poly", op=0.85)
    ground(c, "chao", "#6e6a48", 178, 196)
    # rastro de Peste: névoa verde e pegadas brilhando, de baixo-esquerda para cima-direita
    for i, (x, y) in enumerate([(20, 246), (70, 232), (126, 218), (180, 204), (232, 190), (276, 180)]):
        c.f("pegada", "#b8e05a", ellipse(x, y, 4.2, 2, -8, 8), op=0.85)
        for k, (dx, h) in enumerate([(-5, 30), (4, 40)]):
            P = [(x + dx, y), (x + dx + 6, y - h * 0.35), (x + dx - 4, y - h * 0.7), (x + dx + 3, y - h)]
            c.f("vapor", "#a6c84a", brush(P, 5 - k, 0.8), op=0.55)
    r = rng(71)
    for i in range(12):
        x = 20 + r.random() * 270; y = 60 + r.random() * 150
        rr = 2 + r.random() * 4
        c.f("bolha", "#c4e070", ellipse(x, y, rr, rr, 0, 8), op=0.7)
    speedlines(c, 120, 150, 14, 60, 140, "#f4ecd0", 72, op=0.4, a0=math.radians(150), a1=math.radians(220))
    c.fig("lobo3", wolf.pose("correr", "peste"), 104, 112, -12, 0.5)
    c.fig("lobo2", wolf.pose("correr", "peste"), 26, 156, -14, 0.74)
    c.fig("lider", wolf.pose("correr", "peste"), 92, 232, -22, 1.32, guide=wolf.GUIDE["correr"])
    c.save()


# =========================================================================== LOBISOMEM
def werewolf_card():
    c = Card("werewolf")
    sky(c, "#3e4670", "#7a7ea4")
    disk(c, "lua", 206, 82, 62, "#f2e6c0", "#fff8e0")
    c.b("lua_mancha", "#e0d0a4", ellipse(186, 70, 12, 9, 20, 8), op=0.7)
    c.b("lua_mancha2", "#e0d0a4", ellipse(226, 104, 9, 7, -10, 8), op=0.7)
    c.b("morro", "#2e3454", [(-10, 210), (80, 190), (180, 204), (310, 186), (310, 300), (-10, 300)])
    ground(c, "chao", "#46465e", 236, 228)
    speedlines(c, 60, 210, 16, 30, 110, "#c8d0f0", 81, op=0.45, a0=math.radians(120), a1=math.radians(220))
    r = rng(82)
    for i in range(10):
        x = 20 + r.random() * 90; y = 150 + r.random() * 90
        c.f("folha", "#8a7a5a", blob(x, y, 1.6 + r.random() * 2, 800 + i, 5, 0.4, 0.6), op=0.85)
    c.fig("heroi", hero.pose("defesa"), 262, 246, 10, 0.5)
    c.fig("lobisomem", werewolf.pose("saltar"), 92, 236, 8, 1.42, guide=werewolf.GUIDE["saltar"])
    c.save()


# =========================================================================== NINHO DE MORCEGOS
def bat_nest():
    c = Card("bat_nest")
    sky(c, "#7a5e8e", "#f0b870")
    disk(c, "brilho", 92, 150, 70, "#f6d8a0", "#fff0c8")
    ground(c, "chao", "#5a4a5a", 236, 230)
    # árvore morta oca (a construção): tronco inclinado, galho longo para a direita
    trunk = [(20, 300), (34, 230), (40, 170), (34, 110), (44, 60), (62, 20), (80, -10), (120, -10), (112, 22), (130, 44), (180, 34),
             (250, 22), (310, 14), (310, 32), (240, 42), (176, 56), (134, 80), (140, 150), (136, 210), (150, 300)]
    c.b("tronco", "#4e3a3a", trunk)
    c.b("tronco_luz", "#6a5250", [(44, 230), (52, 170), (46, 110), (58, 60), (74, 28), (80, 60), (66, 120), (70, 190), (64, 250)], op=0.8)
    c.b("oco_borda", "#2e2024", ellipse(92, 150, 30, 40, 8, 14))
    c.b("oco", "#120c10", ellipse(93, 152, 22, 32, 8, 14))
    for i, (x, y) in enumerate([(84, 140), (100, 146), (90, 166)]):
        c.b(f"oco_olho{i}", "#ffb02a", ellipse(x, y, 2.2, 1.4, 0, 6))
        c.b(f"oco_olho{i}b", "#ffb02a", ellipse(x + 5, y, 2.2, 1.4, 0, 6))
    for i, P in enumerate([[(40, 200), (30, 190)], [(130, 120), (150, 110), (160, 112)], [(60, 80), (48, 70)]]):
        c.b(f"galho{i}", "#4e3a3a", P, closed=False, sw=3)
    # morcegos pendurados no galho
    for i, (x, y, s) in enumerate([(204, 52, 1.0), (232, 46, 0.92), (262, 40, 1.05), (288, 36, 0.9)]):
        P = bat.silhouette("pendurado")
        c.sil(P, x, y, 0, s, fill="#3a2a2e")
    # revoada saindo do oco e vindo para a frente (cresce até o morcego grande)
    r = rng(91)
    for i, (x, y, s, nm, rot) in enumerate([(104, 150, 0.3, "voar_cima", -10), (118, 166, 0.36, "voar_baixo", 6), (102, 184, 0.42, "mergulho", -20),
                                            (132, 196, 0.5, "voar_cima", 12), (114, 222, 0.6, "voar_baixo", -8), (150, 70, 0.34, "voar_baixo", 10),
                                            (126, 100, 0.3, "voar_cima", -14), (166, 98, 0.28, "mergulho", 20)]):
        c.sil(bat.silhouette(nm), x, y, rot, s, fill=mix("#5a3a3a", "#2a1a1e", min(1, s * 1.6)),
              eyes=("#ffb02a", [(-3.6, -16.4), (3.6, -16.4)], 1.4) if s > 0.4 else None)
    speedlines(c, 92, 150, 12, 40, 80, "#fff0c8", 92, op=0.5, a0=math.radians(-80), a1=math.radians(40))
    c.fig("morcego", bat.pose("voar_cima"), 234, 202, -10, 2.0, guide=bat.GUIDE["voar_cima"])
    c.save()


# =========================================================================== NUVEM DE MORCEGOS
def bat_cloud():
    c = Card("bat_cloud")
    sky(c, "#4a5a7a", "#a8b4c4")
    disk(c, "lua", 96, 92, 56, "#eef0e0", "#ffffff")
    # muralha com estacas (o obstáculo que eles sobrevoam)
    c.b("muralha", "#6a6470", [(-10, 214), (310, 196), (310, 300), (-10, 300)], mode="poly")
    for i in range(9):
        x = -6 + i * 36; y = 212 - i * 2.1
        c.b(f"merlao{i}", "#7a7480", [(x, y), (x, y - 20), (x + 22, y - 21.5), (x + 22, y - 1.5)], mode="poly")
    for i in range(12):
        x = 2 + i * 26; y = 196 - i * 1.5
        c.b(f"estaca{i}", "#4a3e3a", [(x - 3, y), (x, y - 30 - (i % 3) * 6), (x + 3, y)], mode="poly")
    for i, P in enumerate([[(20, 240), (100, 236)], [(150, 232), (240, 226)], [(60, 262), (180, 256)]]):
        c.b(f"junta{i}", INK, P, closed=False, sw=0.8, op=0.5)
    # a nuvem: arco de morcegos passando por cima da muralha, da esquerda-baixo para a direita-cima
    r = rng(101)
    for i in range(34):
        t = r.random()
        x = -10 + t * 300 + r.normal(0, 10)
        y = 200 - math.sin(t * math.pi) * 130 - t * 50 + r.normal(0, 12)
        s = 0.26 + r.random() * 0.26
        nm = ["voar_cima", "voar_baixo", "atacar"][i % 3]
        c.sil(bat.silhouette(nm), x, y, r.normal(0, 22) + (t - 0.5) * 30, s, flip=r.random() < 0.5, fill=mix("#4a3a40", "#20161a", r.random()),
              eyes=("#ff4a2a", [(-3.6, -16.4), (3.6, -16.4)], 1.6) if r.random() < 0.3 else None)
    speedlines(c, 150, 80, 12, 40, 120, "#e0e8f4", 102, op=0.4, a0=math.radians(150), a1=math.radians(220))
    c.fig("morcego", bat.pose("atacar"), 196, 150, -24, 2.45, guide=bat.GUIDE["atacar"])
    c.save()


# =========================================================================== BESTA ALFA
def alpha_beast():
    c = Card("alpha_beast")
    sky(c, "#6a3a3e", "#f0a060")
    c.b("nuvem", "#8a4a48", [(-10, -10), (310, -10), (310, 40), (220, 56), (120, 30), (-10, 60)], op=0.7)
    # rochedo (o cenário) — a Besta no alto, câmera baixa
    c.b("rocha", "#4a3a3a", [(40, 300), (60, 236), (86, 214), (130, 204), (190, 210), (230, 226), (262, 260), (280, 300)])
    c.b("rocha_luz", "#6a5250", [(70, 236), (92, 218), (130, 210), (150, 212), (112, 224), (84, 244)], op=0.9)
    c.b("rocha_fenda", INK, [(150, 214), (160, 240), (154, 266)], closed=False, sw=1.2, op=0.7)
    # chamado do bando: anéis dourados saindo do focinho
    M = tmat(152, 224, -6, 1.24)
    hx, hy, ha, hs, op = wolf.POSES["uivar"]["head"]
    snout = ap(chain(M, tmat(hx, hy, ha, hs * wolf.PAL["alfa"]["hk"])), [(36, -3)])[0]
    rings(c, snout[0] - 6, snout[1] + 14, [34, 58, 84, 112], -200, 20, "#f6c840", w0=7, op0=0.9)
    rings(c, snout[0] - 6, snout[1] + 14, [140, 168], -190, 10, "#f6d870", w0=4, op0=0.5)
    # o bando chegando: lobos e ratos subindo pelos lados, morcegos no céu
    for i, (x, y, s, fl) in enumerate([(30, 246, 0.5, 0), (8, 222, 0.38, 0), (270, 250, 0.5, 1), (292, 226, 0.4, 1)]):
        c.sil(wolf.silhouette("correr", "comum"), x, y, -10 if not fl else 10, s, flip=bool(fl), fill="#2e2224")
    for i, (x, y, s, fl) in enumerate([(70, 270, 0.42, 0), (232, 276, 0.42, 1), (50, 262, 0.34, 0)]):
        c.sil(rat.silhouette("correr", "comum"), x, y, -8 if not fl else 8, s, flip=bool(fl), fill="#3a2a2a")
    for i, (x, y, s) in enumerate([(40, 60, 0.5), (66, 36, 0.4), (262, 70, 0.48), (238, 40, 0.38), (284, 104, 0.4)]):
        c.sil(bat.silhouette(["voar_cima", "voar_baixo"][i % 2]), x, y, 0, s, fill="#3a2226")
    c.fig("alfa", wolf.pose("uivar", "alfa"), 152, 224, -6, 1.24, guide=wolf.GUIDE["uivar"])
    c.save()


# =========================================================================== INSTINTO DE CAÇA
def hunt_instinct():
    c = Card("hunt_instinct")
    sky(c, "#24283e", "#4e4a6a")
    c.b("brilho", "#7a4a6a", ellipse(220, 110, 110, 90, 0, 14), op=0.6)
    for i, (x, w) in enumerate([(14, 18), (52, 12), (300, 22)]):
        c.b(f"tronco{i}", "#1c1e30", [(x - w, -10), (x + w, -10), (x + w * 0.8, 300), (x - w * 0.8, 300)], mode="poly")
    ground(c, "chao", "#2e2e40", 232, 224)
    # o herói (alvo) à direita, cortado pela moldura
    Mh = c.fig("heroi", hero.pose("defesa"), 248, 250, -8, 1.02)
    # roubo de vida: fitas vermelhas saindo do braço do herói e voltando para o lobo
    src = ap(Mh, [hero.POSES["defesa"]["wl"]])[0]
    for i, (dx, dy, w) in enumerate([(0, 0, 7), (6, 14, 5), (-8, 22, 4)]):
        P = [(src[0] + dx, src[1] + dy), (src[0] - 30 + dx, src[1] - 40 + dy), (130 + dx, 50 + dy), (70 + dx, 90 + dy * 2), (40, 150 + dy)]
        c.f("vida", "#ff3040", brush(P, w * 1.4, 1.2), op=0.9)
    r = rng(111)
    for i in range(14):
        t = r.random()
        x = src[0] - t * 170 + r.normal(0, 8); y = src[1] + t * 100 + r.normal(0, 10)
        c.f("gota", "#ff5a50", ellipse(x, y, 1.6 + r.random() * 2, 1.4 + r.random() * 1.6, 0, 6), op=0.9)
    speedlines(c, 70, 180, 16, 30, 120, "#c8b0d8", 112, op=0.4, a0=math.radians(140), a1=math.radians(230))
    c.fig("lobo", wolf.pose("atacar", "caca"), 40, 240, -8, 1.45, guide=wolf.GUIDE["atacar"])
    c.save()


# =========================================================================== MÃE DA NINHADA
def brood_mother():
    c = Card("brood_mother")
    sky(c, "#a898b8", "#e0c890")
    c.b("parede", "#8a7a8a", [(-10, -10), (120, -10), (110, 200), (-10, 210)], mode="poly", op=0.7)
    for i in range(6):
        y = 10 + i * 34
        c.b(f"tijolo{i}", INK, [(-10, y), (114 - i * 0.4, y - 1)], closed=False, sw=0.7, op=0.4)
    ground(c, "chao", "#7a6a52", 206, 200)
    # ninho de palha e trapos (o cenário)
    c.b("ninho", "#b89048", [(30, 262), (40, 228), (90, 206), (160, 200), (232, 210), (276, 234), (282, 266)])
    c.b("ninho_trapo", "#7a5a8a", [(60, 236), (110, 218), (140, 230), (96, 248)], op=0.9)
    c.b("ninho_trapo2", "#a8586a", [(196, 222), (250, 226), (262, 244), (210, 246)], op=0.9)
    r = rng(121)
    for i in range(22):
        x = 40 + r.random() * 230; y = 210 + r.random() * 40; a = r.normal(0, 0.6)
        c.b(f"palha{i}", "#e0c070", [(x, y), (x + math.cos(a) * 16, y + math.sin(a) * 6)], closed=False, sw=1.2)
    # filhotes saindo do ninho (enxame)
    for i, (x, y, s, fl, rot) in enumerate([(56, 226, 0.36, 1, 10), (34, 246, 0.42, 1, 0), (250, 230, 0.36, 0, -10), (270, 252, 0.44, 0, 0),
                                            (226, 248, 0.32, 0, -20), (84, 252, 0.34, 1, 6)]):
        c.sil(rat.silhouette("correr", "comum"), x, y, rot, s, flip=bool(fl), fill=mix("#8b8580", "#4a3e38", 0.5))
    # aura de ninhada (pequenos corações? não: halo morno atrás da cabeça) + moscas da praga
    disk(c, "halo", 190, 70, 46, "#f4dca0", "#fff2d0")
    for i in range(6):
        x = 220 + r.random() * 60; y = 30 + r.random() * 60
        c.f("mosca", INK, [(x - 2.5, y), (x, y - 1.5), (x + 2.5, y), (x, y + 1.5)], op=0.9)
    # filhotes saindo debaixo da barriga
    for i, (x, y, rot, sc, fl) in enumerate([(168, 240, 4, 0.34, 0), (196, 232, -6, 0.3, 0)]):
        c.sil(rat.silhouette("correr", "comum"), x, y, rot, sc, flip=bool(fl), fill="#5a4e48")
    pcs = rat.pose("ameaca", "gorda")
    # barriga da ninhada (cheia): peça a mais no corpo, da cor da barriga
    pcs.insert(next(i for i, p in enumerate(pcs) if p.id == "barriga") + 1,
               Pc("barriga_cheia", "corpo", rat.PAL["gorda"]["belly"], ellipse(16, -34, 19, 24, -18, 12)))
    c.fig("mae", pcs, 130, 226, 6, 1.62, guide=[(-30, -2), (2, -22), (12, -50), (28, -74), (58, -98)])
    c.save()


ALL = dict(bat_nest=bat_nest, bat_cloud=bat_cloud, wolf_pack=wolf_pack, werewolf=werewolf_card, war_boar=war_boar,
           alpha_beast=alpha_beast, hunt_instinct=hunt_instinct, brood_mother=brood_mother)

if __name__ == "__main__":
    for k in (sys.argv[1:] or ALL):
        ALL[k](); print("ok", k)
