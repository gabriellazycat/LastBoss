"""Composições do lote praga_1 (coordenadas de carta 300x420; janela 11..289 x 11..278)."""
import sys, math
import numpy as np
from geom import *
import rat, hero
from rat import mix
from render import shot

OUT = "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/praga_1/comp"
INK = "#2b1a10"
RG = {"correr": [(-90, -18), (-40, -22), (10, -28), (60, -28), (98, -12)],
      "atacar": [(-70, -36), (-20, -32), (20, -34), (60, -24), (92, -2)],
      "ameaca": [(-30, -2), (2, -22), (12, -50), (28, -74), (58, -98)],
      "saltar": [(120, -130), (40, -60), (0, 0), (-10, 60)],
      "rei": [(-10, -6), (6, -40), (18, -80), (50, -110), (92, -126)]}


class Card:
    def __init__(self, cid):
        self.cid = cid; self.bg = []; self.enx = []; self.fx = []; self.figs = []; self.guide = None; self.defs = ""
        self.fxn = 0; self.bgn = 0; self.enn = 0

    def b(self, name, fill, pts=None, d=None, mode="cr", op=None, closed=True, sw=None):
        self.bgn += 1
        self.bg.append(Pc(f"bg_{name}", f"bg_{name}", fill, pts=pts, d=d, mode=mode, op=op, closed=closed, sw=sw))

    def f(self, name, fill, pts=None, d=None, mode="cr", op=None, closed=True, sw=None):
        self.fxn += 1
        self.fx.append(Pc(f"fx_{name}{self.fxn}", "fx", fill, pts=pts, d=d, mode=mode, op=op, closed=closed, sw=sw))

    def sil(self, pose, var, x, y, rot, s, flip=False, fill="#3a2a20", op=None, eye=None):
        P = rat.silhouette(pose, var)
        M = tmat(x, y, rot, -s if flip else s, s)
        self.enn += 1
        self.enx.append(Pc(f"enx_{self.enn}", f"enxame_{self.enn}", fill, pts=list(ap(M, P)), mode="poly", op=op))
        if eye:
            loc = (17 + 64, -7.5 - 28) if pose == "correr" else None
            hx, hy, ha, hs, _ = rat.POSES[pose]["head"] if pose in rat.POSES else (0, 0, 0, 1, 0)
            Mh = tmat(hx, hy, ha, hs * rat.PAL[var]["hk"])
            e = ap(chain(M, Mh), [(17, -7.8)])[0]
            self.enx.append(Pc(f"enx_{self.enn}_olho", f"enxame_{self.enn}", eye, pts=ellipse(e[0], e[1], 1.6 * s, 1.1 * s, rot, 6), cls="inner"))
        return M

    def fig(self, name, pcs, tx, ty, rot=0, sx=1, sy=None, guide=None):
        sy = sx if sy is None else sy
        M = tmat(tx, ty, rot, sx, sy)
        self.figs.append((name, pcs, tstr(tx, ty, rot, sx, sy)))
        if guide is not None:
            self.guide = list(ap(M, guide))
        return M

    def svg(self):
        o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 420">']
        if self.defs:
            o.append(f"<defs>{self.defs}</defs>")
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
        shot(s, f"{OUT}/../../../../../AppData/Local/Temp/x.png" if False else
             f"C:/Users/gabri/AppData/Local/Temp/claude/df0eb8c5d2d2aad7/388ffdb7-a033-4c30-8855-5da64eb88778/scratchpad/comp_praga_1/{self.cid}_guia.png",
             (11, 11, 278, 267), 556, 534, guide=True)


RECT = [(-10, -10), (310, -10), (310, 300), (-10, 300)]


def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def arch(cx, cy, s):
    """Arco de túnel (aberto embaixo) -> polígono fechado com espessura de anel."""
    pts = []
    for k in range(0, 13):
        a = math.pi + k / 12 * math.pi
        pts.append((cx + math.cos(a) * 45 * s, cy - 5 * s + math.sin(a) * 47 * s))
    return [(cx - 45 * s, cy + 70 * s)] + pts + [(cx + 45 * s, cy + 70 * s)]


def rng(seed):
    return np.random.default_rng(seed)


def speedlines(c, cx, cy, n, r0, r1, col, seed, w=(1.2, 3), op=0.35, a0=0, a1=2 * math.pi):
    r = rng(seed)
    for i in range(n):
        a = a0 + r.random() * (a1 - a0); d0 = r0 + r.random() * 30; d1 = d0 + 40 + r.random() * (r1 - r0)
        c.f("veloc", col, wedge(cx + math.cos(a) * d1, cy + math.sin(a) * d1, cx + math.cos(a) * d0, cy + math.sin(a) * d0,
                                w[0] + r.random() * (w[1] - w[0])), mode="poly", op=op)


def dust(c, cx, cy, R, n, col, seed, sz=(1, 3), op=0.7, name="poeira"):
    r = rng(seed)
    for i in range(n):
        a = r.random() * 6.283; d = (r.random() ** 0.7) * R
        c.f(name, col, blob(cx + math.cos(a) * d, cy + math.sin(a) * d * 0.7, sz[0] + r.random() * (sz[1] - sz[0]), 100 + i + seed, 6, 0.3), op=op)


# =========================================================================== HORDA DE RATOS
def rat_horde():
    c = Card("rat_horde")
    c.b("parede", "#5a4030", RECT, mode="poly")
    c.b("chao", "#a98450", [(-10, 168), (310, 168), (310, 300), (-10, 300)], mode="poly")
    c.b("luz", "#f6e2a4", [(92 - 34, 186), (92 + 34, 186), (250, 300), (-60, 300)], mode="poly", op=0.55)
    c.b("tunel_anel", "#2e2018", arch(92, 118, 1.62))
    c.b("tunel_tijolos", "#4a3426", arch(92, 118, 1.3))
    c.b("tunel_boca", "#fbeec0", arch(92, 118, 1.0))
    c.b("tunel_brilho", "#fffbe8", ellipse(92, 112, 26, 30, 0, 10))
    r = rng(4)
    for i in range(10):  # juntas dos tijolos do arco
        a = math.pi + (i + 0.5) / 10 * math.pi
        x0, y0 = 92 + math.cos(a) * 47, 110 + math.sin(a) * 49
        x1, y1 = 92 + math.cos(a) * 74, 110 + math.sin(a) * 77
        c.b(f"junta{i}", INK, [(x0, y0), (x1, y1)], closed=False, sw=0.9, op=0.6)
    speedlines(c, 92, 115, 22, 55, 150, "#fff0c0", 5, op=0.4, a0=-0.9, a1=2.4)
    # enxame saindo do túnel, crescendo para a frente
    pos = [(80, 150, .18, 0), (104, 152, .2, 1), (70, 158, .24, 1), (114, 160, .26, 0), (60, 170, .3, 1), (128, 168, .32, 0),
           (40, 180, .36, 1), (90, 178, .38, 0), (150, 176, .4, 0), (22, 196, .46, 1), (70, 196, .5, 1), (246, 196, .52, 0)]
    for i, (x, y, s, fl) in enumerate(pos):
        col = mix("#c49a60", "#3a2a20", min(1, (s - 0.15) * 2.8))
        c.sil("correr", "comum", x, y, (8 if fl else -6), s, flip=bool(fl), fill=col)
    dust(c, 150, 214, 120, 18, "#3a2a1e", 11, (1, 2.6))
    for x, y, rr in [(40, 214, 30), (240, 222, 34)]:
        c.f("nuvem", "#e9d39c", blob(x, y, rr, x, 9, 0.3, 0.45), op=0.5)
    c.fig("corredor", rat.pose("correr"), 18, 262, -4, 1.02)
    c.fig("saltador", rat.pose_saltar(), 182, 112, -14, 0.8, guide=RG["saltar"])
    c.save()


# =========================================================================== REI DOS RATOS
def rat_king():
    c = Card("rat_king")
    c.b("parede", "#8a78a8", RECT, mode="poly")
    r = rng(7)
    for i in range(14):
        x = (i % 4) * 82 - 20 + (i // 4 % 2) * 40; y = (i // 4) * 54 - 10
        c.b(f"pedra{i}", "#7a6898", [(x + 3, y + 3), (x + 76, y + 4), (x + 75, y + 49), (x + 2, y + 50)], op=0.8)
    c.b("chao", "#5a4a70", [(-10, 238), (310, 230), (310, 300), (-10, 300)], mode="poly")
    M = tmat(128, 228, 7, 1.24)
    hc = ap(M, [(34, -104)])[0]
    c.b("halo", "#f2d27a", ellipse(hc[0], hc[1], 62, 62, 0, 16))
    c.b("halo_centro", "#fff2c0", ellipse(hc[0], hc[1], 40, 40, 0, 14), op=0.7)
    # trono de ossos: espaldar em leque + assento
    for i, ang in enumerate([-160, -135, -110, -70, -45, -20]):
        a = math.radians(ang); L = 150
        x0, y0 = 156 + math.cos(a) * 30, 200 + math.sin(a) * 30
        x1, y1 = 156 + math.cos(a) * L, 200 + math.sin(a) * L
        M2 = chain(T(x0, y0), R(ang))
        c.b(f"osso{i}", "#e6d8b8", d=xform_d(bone_d(L - 30, 9), M2))
    c.b("assento", "#6a4a38", [(70, 200), (240, 196), (252, 214), (246, 250), (64, 252), (58, 216)])
    c.b("assento_tampo", "#8a6248", [(66, 196), (244, 192), (250, 204), (60, 208)])
    for i, (x, y) in enumerate([(84, 230), (226, 226)]):
        c.b(f"caveira{i}", "#e6d8b8", [(x - 10, y - 2), (x - 9, y - 12), (x, y - 16), (x + 9, y - 12), (x + 10, y - 2), (x + 6, y + 6), (x - 6, y + 6)])
        c.b(f"caveira{i}_olhos", "#241426", ellipse(x - 4, y - 4, 2.6, 3, 0, 6) , op=1)
        c.b(f"caveira{i}_olho2", "#241426", ellipse(x + 4, y - 4, 2.6, 3, 0, 6), op=1)
    # súditos aos pés
    for i, (x, y, s, fl) in enumerate([(30, 258, .42, 0), (80, 262, .5, 0), (250, 258, .46, 1), (290, 252, .4, 1), (200, 266, .5, 1)]):
        c.sil("correr", "comum", x, y, 0, s, flip=bool(fl), fill="#3a2a40")
    r = rng(9)
    for i in range(18):
        a = r.random() * 6.283; d0 = 66 + r.random() * 10; d1 = d0 + 10 + r.random() * 22
        c.f("faisca", "#fff0a0", wedge(hc[0] + math.cos(a) * d1, hc[1] + math.sin(a) * d1, hc[0] + math.cos(a) * d0, hc[1] + math.sin(a) * d0, 2.2), mode="poly", op=0.85)
    c.fig("rei", rat.pose_rei(), 128, 228, 7, 1.24, guide=RG["rei"])
    c.save()


def bone_d(l, w):
    r = w * .5; hw = w / 2
    return (f"M{r*1.6} {-hw*.55} Q{l/2} {-hw*.2} {l-r*1.6} {-hw*.55} C{l-r*1.2} {-r*2.4} {l+r*1.1} {-r*2.3} {l+r*.5} 0 "
            f"C{l+r*1.1} {r*2.3} {l-r*1.2} {r*2.4} {l-r*1.6} {hw*.55} Q{l/2} {hw*.2} {r*1.6} {hw*.55} "
            f"C{r*1.2} {r*2.4} {-r*1.1} {r*2.3} {-r*.5} 0 C{-r*1.1} {-r*2.3} {r*1.2} {-r*2.4} {r*1.6} {-hw*.55} Z")


# =========================================================================== RATOS RAIVOSOS
def rabid_rats():
    c = Card("rabid_rats")
    c.b("parede", "#6f7a4c", RECT, mode="poly")
    c.b("brilho", "#c8cf96", ellipse(120, 150, 120, 95, -20, 14), op=0.85)
    c.b("brilho_centro", "#e6e8c0", ellipse(110, 160, 70, 55, -20, 12), op=0.7)
    c.b("chao", "#56603a", [(-10, 236), (310, 222), (310, 300), (-10, 300)], mode="poly")
    c.b("buraco_borda", "#3e4428", [(206, 30), (262, 18), (300, 40), (306, 104), (276, 126), (226, 116), (200, 78)])
    c.b("buraco", "#141a0c", [(216, 40), (260, 30), (292, 50), (294, 98), (270, 114), (232, 106), (212, 76)])
    for i, P in enumerate([[(212, 76), (190, 90), (176, 112)], [(260, 30), (250, 10), (256, -4)], [(294, 98), (300, 130)]]):
        c.b(f"rachadura{i}", INK, P, closed=False, sw=1.2, op=0.8)
    c.sil("atacar", "raivoso", 262, 70, -14, 0.62, flip=True, fill="#2c3018", eye="#a8301c")
    c.sil("correr", "raivoso", 244, 110, -26, 0.55, flip=True, fill="#3a3e22", eye="#a8301c")
    c.sil("atacar", "raivoso", 290, 150, -20, 0.7, flip=True, fill="#40462a")
    r = rng(13)
    for i in range(9):
        x0 = 150 + r.random() * 120; y0 = 120 + r.random() * 90; L = 18 + r.random() * 26
        c.f("frenesi", "#c83a2a", wedge(x0, y0, x0 + L, y0 - L * 0.55, 2.4 + r.random() * 2), mode="poly", op=0.7)
    dust(c, 70, 200, 40, 12, "#f4f0e0", 21, (1, 2.4), op=0.85, name="espuma")
    c.fig("raivoso", rat.pose("atacar", "raivoso"), 196, 148, -24, -1.72, 1.72, guide=RG["atacar"])
    c.save()


# =========================================================================== RATAZANA
def rat_brute():
    c = Card("rat_brute")
    c.b("parede", "#a898c0", RECT, mode="poly")
    c.b("luz", "#e8dcf0", ellipse(170, 120, 130, 90, 0, 14), op=0.8)
    c.b("chao", "#7a6a8a", [(-10, 226), (310, 236), (310, 300), (-10, 300)], mode="poly")
    c.b("cano_boca", "#4e4a5a", ellipse(44, 92, 46, 50, 0, 14))
    c.b("cano_aro", "#6e6878", ellipse(44, 92, 46, 50, 0, 14), op=0)
    c.b("cano_dentro", "#1c1820", ellipse(48, 94, 34, 38, 0, 12))
    c.b("lodo", "#7fae3a", [(30, 110), (66, 112), (70, 140), (62, 190), (72, 228), (20, 232), (34, 190), (26, 140)])
    c.b("poca", "#6e9a30", ellipse(60, 236, 70, 12, 0, 12))
    r = rng(17)
    for i in range(10):
        x = 120 + r.random() * 160; y = 50 + r.random() * 120; rr = 3 + r.random() * 6
        c.f("bolha", "#9ac850", ellipse(x, y, rr, rr, 0, 8), op=0.75)
    for i in range(6):
        x = 150 + r.random() * 130; y = 40 + r.random() * 80
        c.f("mosca", INK, [(x - 2.5, y), (x, y - 1.5), (x + 2.5, y), (x, y + 1.5)], op=0.9)
        c.f("mosca_asa", "#f4f0f8", ellipse(x - 1, y - 2.6, 2.2, 1.3, -30, 6), op=0.8)
    M = c.fig("ratazana", rat.pose("atacar", "gorda"), 108, 222, -15, 1.72, guide=RG["atacar"])
    # baba verde pingando da mandíbula (abaixo da boca, nunca sobre o rosto)
    hx, hy, ha, hs, op = rat.POSES["atacar"]["head"]
    Mh = chain(M, tmat(hx, hy, ha, hs * rat.PAL["gorda"]["hk"]))
    p = ap(Mh, [(24, 10), (28, 10)])
    for i, (x, y) in enumerate(p):
        c.f("baba", "#8cc23a", [(x - 2, y), (x + 2, y), (x + 1.4, y + 14 + i * 6), (x, y + 18 + i * 6), (x - 1.4, y + 14 + i * 6)])
    c.save()


# =========================================================================== TOCA DE RATOS
def rat_burrow():
    c = Card("rat_burrow")
    c.b("ceu", "#e2c486", RECT, mode="poly")
    c.b("ceu_alto", "#b8a0b8", [(-10, -10), (310, -10), (310, 60), (-10, 90)], mode="poly", op=0.8)
    c.b("morros", "#8a7a90", [(-10, 132), (60, 104), (130, 118), (210, 96), (310, 120), (310, 160), (-10, 160)])
    c.b("chao", "#9a7a50", [(-10, 200), (310, 196), (310, 300), (-10, 300)], mode="poly")
    c.b("monte", "#6e4e32", [(10, 252), (40, 170), (90, 128), (150, 116), (212, 130), (262, 170), (292, 250)])
    c.b("monte_luz", "#8e6a44", [(48, 180), (92, 136), (150, 124), (180, 130), (120, 150), (76, 190)], op=0.8)
    c.b("buraco_borda", "#4a3220", ellipse(150, 192, 58, 36, -6, 14))
    c.b("buraco", "#1e140e", ellipse(150, 196, 46, 27, -6, 14))
    c.b("tabua", "#a8784a", [(220, 146), (276, 126), (280, 136), (224, 158)], mode="poly")
    c.b("tabua2", "#946640", [(26, 196), (40, 140), (49, 142), (36, 198)], mode="poly")
    for i, P in enumerate([[(98, 178), (84, 168), (70, 172)], [(204, 176), (220, 172), (232, 182)], [(120, 170), (114, 158)]]):
        c.b(f"raiz{i}", "#3a2614", P, closed=False, sw=1.6)
    for x, y, s, fl in [(40, 236, .45, 1), (250, 240, .5, 0), (268, 214, .36, 0)]:
        c.sil("correr", "comum", x, y, 0, s, flip=bool(fl), fill="#3a2a20")
    c.sil("ameaca", "comum", 128, 210, -6, 0.42, fill="#2a1c14")
    r = rng(23)
    for i in range(16):
        a = math.radians(-160 + r.random() * 140); d = 50 + r.random() * 60
        x, y = 150 + math.cos(a) * d, 186 + math.sin(a) * d * 0.9
        c.f("torrao", "#5a3e26", blob(x, y, 1.5 + r.random() * 3, 300 + i, 6, 0.35))
    speedlines(c, 150, 190, 12, 40, 90, "#f4e2b0", 24, op=0.45, a0=math.radians(-150), a1=math.radians(-20))
    M = tmat(0, 0, -34, 1.38)
    rump = ap(M, [(-6, -22)])[0]
    c.fig("rato", rat.pose("correr"), 146 - rump[0], 196 - rump[1], -34, 1.38, guide=RG["correr"])
    c.save()


# =========================================================================== RATOEIRA VIVA
def rat_trap():
    c = Card("rat_trap")
    c.b("fundo", "#5a5878", RECT, mode="poly")
    c.b("contraluz", "#e8d8a8", ellipse(196, 112, 80, 94, 0, 16), op=0.9)
    c.b("contraluz_centro", "#fff4d0", ellipse(196, 114, 46, 58, 0, 14), op=0.8)
    c.b("chao", "#6a5c48", [(-10, 214), (310, 206), (310, 300), (-10, 300)], mode="poly")
    c.b("arvore_l", "#3a3850", [(-10, -10), (34, -10), (30, 80), (40, 216), (-10, 220)])
    c.b("arvore_r", "#3a3850", [(270, -10), (310, -10), (310, 214), (262, 210), (276, 100)])
    # ratoeira (a construção): base de madeira em perspectiva, barra de ferro fechando no tornozelo
    Mh = tmat(196, 230, 0, 0.86)
    ank = ap(Mh, [hero.POSES["preso"]["al"]])[0]
    trap = [Pc("base", "base", "#a8783e", [(62, 214), (250, 206), (282, 252), (36, 262)], mode="poly"),
            Pc("base_lado", "base", "#7a5428", [(36, 262), (282, 252), (282, 260), (36, 270)], mode="poly"),
            Pc("mola", "barra", "#5a5a62", ellipse(ank[0] + 34, ank[1] + 6, 9, 6, 0, 10)),
            Pc("barra", "barra", "#6a6a74", [(ank[0] - 30, ank[1] + 14), (ank[0] - 24, ank[1] - 2), (ank[0] + 14, ank[1] - 4), (ank[0] + 44, ank[1] + 6),
                                             (ank[0] + 42, ank[1] + 12), (ank[0] + 14, ank[1] + 4), (ank[0] - 18, ank[1] + 5), (ank[0] - 22, ank[1] + 17)], mode="poly"),
            Pc("dentes", "barra", "#8a8a94", [(ank[0] - 22, ank[1] + 2), (ank[0] - 18, ank[1] - 10), (ank[0] - 12, ank[1] - 2), (ank[0] - 6, ank[1] - 12),
                                              (ank[0], ank[1] - 3), (ank[0] + 6, ank[1] - 13), (ank[0] + 12, ank[1] - 4), (ank[0] + 18, ank[1] - 12), (ank[0] + 22, ank[1] - 2)], mode="poly"),
            Pc("veio", "base", INK, [(90, 236), (200, 230)], closed=False, cls="inner", sw=0.7),
            Pc("veio2", "base", INK, [(70, 250), (160, 246)], closed=False, cls="inner", sw=0.7)]
    c.figs.append(("ratoeira", trap, "translate(0 0)"))
    speedlines(c, ank[0], ank[1], 10, 8, 40, "#fff4d0", 31, op=0.7, a0=math.radians(-170), a1=math.radians(-10))
    dust(c, ank[0], ank[1] + 4, 30, 10, "#c8a870", 32, (1, 2.4))
    c.sil("atacar", "comum", 262, 200, 30, 0.85, flip=True, fill="#3a3448")
    c.fig("heroi", hero.pose("preso"), 196, 230, 0, 0.86)
    c.fig("rato", rat.pose("atacar"), 52, 246, -40, 1.32, guide=RG["atacar"])
    c.save()


# =========================================================================== CHAMADO DO BANDO
def pack_call():
    c = Card("pack_call")
    c.b("ceu", "#8a8a58", RECT, mode="poly")
    c.b("horizonte", "#e8c070", [(-10, 60), (310, 40), (310, 130), (-10, 130)], op=0.9)
    c.b("sol", "#fff0c0", ellipse(214, 104, 40, 30, 0, 12), op=0.9)
    c.b("chao", "#6e6a3a", [(-10, 120), (310, 112), (310, 300), (-10, 300)], mode="poly")
    c.b("estrada", "#c8a86a", [(206, 116), (222, 116), (310, 300), (40, 300)], mode="poly", op=0.8)
    # ondas do chamado: arcos dourados saindo do canto do vilão em direção ao herói
    for i, rr in enumerate([70, 120, 175, 235]):
        pts = [(-10 + math.cos(math.radians(a)) * rr, 300 + math.sin(math.radians(a)) * rr) for a in np.linspace(-80, -8, 9)]
        c.f("onda", "#f0c040", brush(pts, 5 - i, 1.5), op=0.75 - i * 0.12)
    c.fig("heroi", hero.pose("defesa"), 214, 120, 0, 0.42)
    for i, (x, y, s) in enumerate([(196, 126, .16), (232, 128, .18), (176, 138, .22), (246, 142, .26), (150, 160, .32), (236, 172, .38), (110, 190, .44)]):
        c.sil("correr", "comum", x, y, -8, s, fill=mix("#3a2a20", "#7a6a50", 1 - s * 2))
        c.f("rastro", "#fff0b0", wedge(x - 20 * s, y - 18 * s, x - 140 * s, y - 10 * s, 6 * s), mode="poly", op=0.55)
    r = rng(41)
    for i in range(10):
        y = 170 + r.random() * 80; x = 10 + r.random() * 60
        c.f("veloc", "#fff4c8", wedge(x + 60, y - 22, x - 30, y + 6, 1.5 + r.random() * 2), mode="poly", op=0.5)
    c.fig("lider", rat.pose("correr"), 102, 214, -22, 1.32, guide=RG["correr"])
    c.save()


# =========================================================================== MARÉ DE RATOS
def rat_tide():
    c = Card("rat_tide")
    c.b("ceu", "#d8d0b8", RECT, mode="poly")
    c.b("nuvem", "#a898b8", [(-10, -10), (310, -10), (310, 50), (200, 70), (100, 40), (-10, 64)], op=0.8)
    c.b("chao", "#8a7a60", [(-10, 238), (310, 230), (310, 300), (-10, 300)], mode="poly")
    c.b("muro", "#9a8a78", [(-10, 200), (60, 196), (64, 240), (-10, 242)], mode="poly")
    # a onda de ratos (massa escura) com a crista enrolando para a esquerda
    wave = [(310, 260), (310, 40), (262, 20), (200, 22), (140, 40), (96, 62), (70, 90), (66, 118), (84, 130), (104, 118),
            (120, 108), (140, 120), (150, 150), (170, 190), (176, 240), (190, 262)]
    c.enn += 1
    c.enx.append(Pc("enx_onda", "enxame_onda", "#5e5248", wave))
    c.enx.append(Pc("enx_onda_luz", "enxame_onda", "#6a6058", [(300, 50), (262, 34), (204, 36), (150, 54), (112, 78), (150, 72), (210, 58), (290, 70)], cls="inner"))
    r = rng(51)
    for i in range(26):
        t = r.random()
        x = 120 + r.random() * 180; y = 40 + r.random() * 210
        if (x - 160) < (y - 40) * -0.2:
            continue
        c.sil("correr", "comum", x, y, -40 + r.random() * 60, 0.28 + r.random() * 0.25, flip=r.random() < .7, fill=mix("#6a6058", "#2e2620", r.random()))
    for i, (x, y, rot, s) in enumerate([(96, 54, -30, .36), (120, 30, -50, .3), (70, 84, -10, .32), (160, 20, -20, .34), (200, 12, -8, .32),
                                        (246, 8, 0, .3), (286, 18, 6, .3), (80, 116, 20, .3), (112, 104, 30, .28), (140, 128, 60, .3), (158, 170, 70, .32), (172, 214, 80, .34)]):
        c.sil("correr", "comum", x, y, rot, s, flip=True, fill="#3a3028")
    r = rng(52)
    for i in range(18):
        a = math.radians(170 + r.random() * 120); d = 20 + r.random() * 50
        c.f("respingo", "#4a4038", blob(140 + math.cos(a) * d, 40 + math.sin(a) * d, 1.2 + r.random() * 2.6, 600 + i, 6, 0.3))
    c.fig("heroi", hero.pose("defesa"), 52, 238, 0, 0.36)
    c.fig("mergulho", rat.pose("correr"), 132, 104, -38, -1.2, 1.2, guide=RG["correr"])
    c.save()


ALL = dict(rat_horde=rat_horde, rat_king=rat_king, rabid_rats=rabid_rats, rat_brute=rat_brute, rat_burrow=rat_burrow,
           rat_trap=rat_trap, pack_call=pack_call, rat_tide=rat_tide)

if __name__ == "__main__":
    import os
    os.makedirs(OUT, exist_ok=True)
    for k in (sys.argv[1:] or ALL):
        ALL[k](); print("ok", k)
