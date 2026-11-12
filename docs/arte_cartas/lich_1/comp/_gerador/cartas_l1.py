"""Composições do lote lich_1 (vilão Lich, família Morte). Coordenadas de carta 300x420; janela 11..289 x 11..278;
fita y >= 261. Reaproveita (só leitura) Card (praga_3: #enxame_frente), sky/disk/rings/ground (praga_2),
dust/rng/RECT (praga_1), hero (praga_1), flame (dragao_1), wisp (dragao_2). Fichas novas em esqueleto/carnical/
cavaleiro/colosso; pose nova do herói em hero_l1. Clima: noite azulada, osso, névoa verde, luz de recorte (fx 'rim').
Uso: python cartas_l1.py [ids...]   (saída: LB_OUT; rascunho: LB_SCR)"""
import base  # noqa: F401
import sys, math
import numpy as np
from geom import *
from rat import mix
from cards import dust, rng, RECT
from cartas import sky, disk, rings, ground
from cartas3 import Card, stones
from cartas_d1 import flame, star
import esqueleto as E
import carnical as G
import cavaleiro as K
import colosso as C
import hero, hero_l1

INK = "#2b1a10"
SOUL = "#7dffb0"; SOUL_L = "#e0fff0"; SOUL_D = "#2e9a74"
MIST = "#6aa890"
NIGHT_T = "#101830"; NIGHT_B = "#3e5276"
MOON = "#d6e2e6"; MOON_C = "#f4f8ee"
STONE = "#5a6272"; STONE_D = "#3a4050"; STONE_L = "#7a8496"
EARTH = "#2a2a30"; EARTH_L = "#4a4640"


# =========================================================================== utilidades do lote
def night(c, top=NIGHT_T, bot=NIGHT_B):
    sky(c, top, bot)


def mist(c, y, seed, n=5, col=MIST, op=0.35, x0=-20, x1=320, h=14, name="nevoa"):
    r = rng(seed)
    for i in range(n):
        cx = x0 + (x1 - x0) * (i + r.random() * 0.6) / n; w = 60 + r.random() * 60; hh = h * (0.7 + r.random() * 0.6)
        yy = y + r.normal(0, h * 0.5)
        c.b(f"{name}{seed}_{i}", col, [(cx - w, yy + hh * 0.3), (cx - w * 0.5, yy - hh * 0.5), (cx, yy - hh * 0.7), (cx + w * 0.6, yy - hh * 0.4),
                                       (cx + w, yy + hh * 0.2), (cx + w * 0.4, yy + hh * 0.6), (cx - w * 0.4, yy + hh * 0.6)], op=op)


def tomb(c, name, x, y, w, h, rot=0, col=STONE, cross=True, broken=False):
    M = tmat(x, y, rot)
    pts = [(-w / 2, 0), (-w / 2, -h + w * 0.4), (-w * 0.36, -h + w * 0.1), (0, -h), (w * 0.36, -h + w * 0.1), (w / 2, -h + w * 0.4), (w / 2, 0)]
    if broken:
        pts = [(-w / 2, 0), (-w / 2, -h + w * 0.4), (-w * 0.3, -h + w * 0.12), (-w * 0.05, -h * 0.82), (w * 0.12, -h * 0.9), (w * 0.3, -h * 0.7),
               (w / 2, -h * 0.74), (w / 2, 0)]
    c.b(name, col, list(ap(M, pts)))
    c.b(name + "_luz", STONE_L, list(ap(M, [(-w / 2, 0), (-w / 2, -h + w * 0.4), (-w * 0.36, -h + w * 0.1), (-w * 0.24, -h + w * 0.2), (-w * 0.3, 0)])), op=0.6)
    if cross:
        c.b(name + "_cruz", STONE_D, list(ap(M, [(-1.4, -h * 0.72), (1.4, -h * 0.72), (1.4, -h * 0.58), (5, -h * 0.58), (5, -h * 0.52), (1.4, -h * 0.52),
                                                 (1.4, -h * 0.3), (-1.4, -h * 0.3), (-1.4, -h * 0.52), (-5, -h * 0.52), (-5, -h * 0.58), (-1.4, -h * 0.58)])),
            mode="poly", op=0.8)


def soul_fire(c, cx, cy, h, w, lean=0.0, seed=0, op=0.9, name="fogo_alma"):
    for k, col in enumerate([SOUL_D, SOUL, SOUL_L]):
        s = 1 - k * 0.3
        c.f(name, col, flame(cx, cy - k * h * 0.04, h * s, w * s, lean * s, seed + k), op=op)


def soul_stream(c, pts, w0, w1, op=0.75, name="alma"):
    c.f(name, SOUL_D, brush(pts, w0 * 1.5, w1 * 1.5), op=op * 0.6)
    c.f(name, SOUL, brush(pts, w0, w1), op=op)


def bone_fx(c, cx, cy, L, ang, w=2.6, col=E.PAL["bone"], name="osso", op=1.0):
    a = math.radians(ang); d = np.array([math.cos(a), math.sin(a)]) * L / 2
    p = E.bone("x", (cx - d[0], cy - d[1]), (cx + d[0], cy + d[1]), w * 1.3, w * 0.75, w * 1.2, col)
    c.f(name, col, p.pts, op=op)


def skull_fx(c, cx, cy, s, rot, col=E.PAL["bone"], name="cranio", glow=False):
    M = tmat(cx, cy, rot, s)
    c.f(name, col, d=xform_d(E.SKULL_F, M))
    c.f(name, E.PAL["bone_d"], d=xform_d(E.JAW_F, M))
    for sx in (-1, 1):
        c.f(name + "_orb", E.PAL["socket"], list(ap(M, ellipse(sx * 4.5, -2.4, 2.8, 2.6, 0, 7))))
        if glow:
            c.f(name + "_olho", SOUL, list(ap(M, ellipse(sx * 4.5, -2.4, 1.2, 1.2, 0, 6))))


def rim(c, pcs, M, dx=2.6, dy=-0.6, col="#bfe8ff", op=0.9):
    """Luz de recorte: cópia clara da silhueta unida, deslocada para o lado oposto à luz (atrás da figura, no #fx)."""
    for poly in union_poly(pcs, M):
        c.f("rim", col, list(poly + np.array([dx, dy])), mode="poly", op=op)


def front(c, name, fill, pts, mode="cr", op=None):
    """Peça na frente das figuras (#enxame_frente): terra/borda que cobre parte de uma figura."""
    c.enn += 1
    c.front.append(Pc(f"frente_{name}", f"enxame_frente_{name}", fill, pts=pts, mode=mode, op=op))


def sk_sil(name, **over):
    return E.sil(name, **over)


# =========================================================================== ESQUELETOS ARQUEIROS
def skeleton_archers():
    c = Card("skeleton_archers")
    night(c, "#0e1630", "#46608a")
    disk(c, "lua", 96, 74, 46, MOON, MOON_C)
    c.b("nuvem", "#2a3a5c", [(-10, 128), (50, 116), (120, 126), (190, 108), (310, 118), (310, 150), (-10, 156)], op=0.7)
    # o cenário: muro de cripta em ruínas (direita, atrás do segundo arqueiro)
    c.b("muro", STONE_D, [(176, 262), (178, 168), (196, 160), (204, 176), (222, 166), (236, 182), (252, 172), (262, 188), (276, 178), (310, 186), (310, 262)], mode="poly")
    stones(c, 180, 186, 310, 262, "#1e2230", 31, rows=5, cols=5, op=0.45)
    c.b("chao", "#232a3a", [(-10, 238), (90, 232), (200, 240), (310, 234), (310, 300), (-10, 300)])
    mist(c, 236, 11, n=5, op=0.4)
    # flechas do segundo arqueiro voando com fogo-fátuo (atrás das figuras): rastro verde subindo à direita
    for k, (x0, y0, x1, y1) in enumerate([(206, 128, 286, 40), (196, 118, 262, 26)]):
        soul_stream(c, [(x0, y0), ((x0 + x1) / 2 - 6, (y0 + y1) / 2 + 4), (x1, y1)], 1.0, 6.0 - k, op=0.7)
        aim = math.degrees(math.atan2(y1 - y0, x1 - x0))
        for p_ in E.arrow((x1 - 14 * math.cos(math.radians(aim)), y1 - 14 * math.sin(math.radians(aim))), aim, 26, fig="fx"):
            c.f("flecha_voo", p_.fill, p_.pts if p_.pts is not None else None, mode="poly")
    # segundo arqueiro (meio do caminho, menor, mais escuro): acabou de soltar, recuando sobre o entulho
    J2 = E.J("atirar", far="l", glow=False, arrow_nock=False, wr=(-34, -128), ebr=-1, hmr="open", hdr=190,
             bow=("l", -38, None), wl=(30, -150), al=(-36, -2), tl=(-26, -2), ar=(20, -14), tr=(30, -20), quiver=None,
             neck=(-12, -127), head=(-6, -142, -26))
    p2 = E.skeleton(J2)
    for q in p2:
        if q.fill == E.PAL["bone"]:
            q.fill = "#c4b89a"
    c.fig("arqueiro2", p2, 226, 206, -4, 0.7)
    # arqueiro principal: perfil, corda puxada até a mandíbula, mira 24° para cima, recuando (pé da frente subindo)
    aim = -24
    sh = (-12, -121)
    wl = (sh[0] + 51 * math.cos(math.radians(aim)), sh[1] + 51 * math.sin(math.radians(aim)))
    J1 = E.J("atirar", hip=(-2, -76), neck=(-13, -126), head=(-8, -141, -20), far="l", wl=wl, hdl=aim - 90,
             wr=(-16, -133), ebr=-1, bow=("l", aim, "r"), arrow_nock=True, arrow_len=72, bow_h=78,
             ar=(26, -12), tr=(37, -18), al=(-32, 0), tl=(-21, 0), quiver=((-16, -130), 116), spine_bend=3)
    p1 = E.skeleton(J1)
    M = c.fig("arqueiro", p1, 104, 266, -3, 1.42)
    c.guide = list(ap(M, [(-21, 0), (-14, -40), (-2, -76), (-13, -126), (wl[0], wl[1]), (wl[0] + 40, wl[1] - 18)]))
    c.save()


# =========================================================================== LEGIÃO DE OSSOS
def bone_legion():
    c = Card("bone_legion")
    night(c, "#121a34", "#4a5a80")
    disk(c, "lua", 236, 52, 30, MOON, MOON_C)
    c.b("morro", "#26304a", [(-10, 170), (60, 150), (140, 140), (230, 128), (310, 134), (310, 300), (-10, 300)])
    # o cenário: portão de cemitério (pilares + grade torta) no alto à direita, de onde a legião sai
    for k, x in enumerate((196, 270)):
        c.b(f"pilar{k}", STONE, [(x - 9, 156), (x - 9, 86), (x - 12, 80), (x + 12, 80), (x + 9, 86), (x + 9, 156)], mode="poly")
        c.b(f"pilar_topo{k}", STONE_L, ellipse(x, 74, 8, 7, 0, 10))
    for k in range(7):
        x = 208 + k * 8.5
        c.b(f"grade{k}", "#1a1c26", [(x, 152), (x + (k - 3) * 1.5, 98 + abs(k - 3) * 3)], closed=False, sw=1.6)
    c.b("grade_trave", "#1a1c26", [(205, 112), (260, 116)], closed=False, sw=1.8)
    c.b("portal_luz", SOUL, ellipse(234, 132, 30, 24, 0, 12), op=0.25)
    mist(c, 150, 21, n=4, op=0.35)
    mist(c, 236, 22, n=5, op=0.3)
    # a legião: correnteza de esqueletos saindo do portão e descendo para a esquerda (perfil espelhado = correndo à esquerda)
    run = sk_sil("correr"); hit = sk_sil("golpear")
    r = rng(23)
    spots = [(234, 150, 0.30), (214, 156, 0.32), (252, 160, 0.33), (196, 168, 0.36), (232, 176, 0.38), (170, 178, 0.40),
             (262, 190, 0.44), (150, 196, 0.46), (212, 200, 0.48), (122, 206, 0.50), (186, 222, 0.56), (92, 218, 0.54),
             (60, 230, 0.60), (246, 236, 0.66)]
    for i, (x, y, s) in enumerate(spots):
        poly = hit if i % 4 == 3 else run
        fill = mix("#4a5064", "#b0a486", min(1, (s - 0.3) / 0.36))
        c.sil(poly, x, y + 8, r.normal(0, 4), s * 1.12, flip=(i % 4 != 3), fill=fill)
    # um esqueleto se desmontando no meio da carga (bons para morrer): ossos e crânio voando + alma subindo
    cx, cy = 214, 214
    soul_stream(c, [(cx - 2, cy - 6), (cx + 8, cy - 30), (cx - 4, cy - 54), (cx + 6, cy - 74)], 6, 1.5, op=0.7)
    for k, (dx, dy, L, a) in enumerate([(-16, -10, 16, 30), (12, -16, 14, -50), (20, 4, 12, 70), (-8, 8, 15, -20), (4, -26, 11, 100)]):
        bone_fx(c, cx + dx, cy + dy, L, a, 2.0)
    skull_fx(c, cx + 24, cy - 30, 0.75, 32)
    for k, (dx, dy, a) in enumerate([(-22, -24, 70), (28, -6, 120), (-26, 6, 160)]):
        c.f("risco", "#e6d8b8", wedge(cx + dx * 0.4, cy + dy * 0.4, cx + dx * 1.2, cy + dy * 1.2, 1.4), mode="poly", op=0.7)
    # o da frente: investida para a câmera e para a esquerda, espada erguida, garra vindo em escorço
    J1 = E.J("correr", hip=(0, -76), neck=(18, -124), head=(27, -140, 4), hk=1.15, jaw=7, far="l",
             ar=(30, -36), tr=(43, -36), al=(-36, -10), tl=(-42, 0),
             wr=(-6, -162), ebr=1, hmr="grip", hdr=-100, sword=("r", -104, 50, False),
             wl=(50, -96), ebl=1, hml="claw", hdl=20, hsl=1.3, spine_bend=-3)
    p1 = E.skeleton(J1)
    M = c.fig("esqueleto", p1, 150, 276, 8, -1.32, 1.32)
    c.guide = list(ap(M, [(-42, 0), (-10, -40), (0, -76), (18, -124), (36, -150)]))
    c.guide = c.guide[:5]
    c.save()


# =========================================================================== CARNIÇAL
def ghoul():
    c = Card("ghoul")
    night(c, "#0e1428", "#3e5070")
    disk(c, "lua", 112, 104, 46, MOON, MOON_C)
    c.b("arvore", "#1a1e2c", [(262, 262), (266, 150), (252, 112), (240, 90), (246, 88), (258, 108), (264, 96), (262, 70), (268, 70), (272, 104),
                              (286, 84), (292, 88), (276, 120), (278, 262)], mode="poly")
    c.b("chao", "#222838", [(-10, 226), (100, 218), (200, 226), (310, 220), (310, 300), (-10, 300)])
    mist(c, 224, 31, n=5, op=0.35)
    # o cenário: lápide rachada de onde ele salta (atrás, à esquerda)
    tomb(c, "lapide", 244, 236, 52, 88, 10, broken=True)
    c.b("terra_cova", EARTH, [(170, 248), (210, 232), (278, 236), (300, 250), (280, 262), (190, 262)])
    # mortes em volta: dois montes de ossos desabando, almas verdes subindo e curvando até o carniçal (+15% de dano)
    for k, (bx, by, s) in enumerate([(36, 252, 1.0), (262, 246, 0.9)]):
        for j, (dx, dy, L, a) in enumerate([(-8, 0, 16, 10), (6, -2, 14, -30), (0, -6, 12, 70), (10, 2, 15, 160)]):
            bone_fx(c, bx + dx * s, by + dy * s, L * s, a + k * 40, 2.2 * s, col="#cfc3a2")
        skull_fx(c, bx + 2, by - 10 * s, 0.7 * s, -20 + k * 40, col="#cfc3a2")
    soul_stream(c, [(38, 238), (30, 214), (60, 196), (110, 184), (150, 150)], 7, 2, op=0.7)
    soul_stream(c, [(262, 232), (226, 222), (206, 196), (196, 168), (172, 140)], 7, 2, op=0.7)
    for k, (x, y) in enumerate([(26, 214), (48, 166), (274, 206), (244, 150)]):
        c.f("faisca_alma", SOUL_L, ellipse(x, y, 1.8, 1.8, 0, 6), op=0.9)
    # o carniçal: bote para a câmera e para a direita, garras enormes em escorço, bocarra aberta
    J1 = dict(G.POSES["saltar"])
    J1.update(hip=(-6, -70), neck=(22, -110), head=(38, -114, -30, 1.15), hview="f", jaw=8, hunch=8, far="l",
              ar=(-34, -42), br=(-46, -38), al=(-24, -56), bl=(-38, -58),
              wr=(66, -118), ebr=1, hdr=-18, hsr=1.6, spreadr=26, curlr=0.25,
              wl=(60, -100), ebl=1, hdl=14, hsl=1.25, spreadl=24, curll=0.3)
    p1 = G.ghoul(J1)
    M = c.fig("carnical", p1, 222, 242, -22, -1.55, 1.55)
    c.guide = list(ap(M, [(-46, -38), (-14, -56), (-6, -70), (8, -98), (22, -110), (66, -118), (84, -122)]))
    c.save()


# =========================================================================== SERVO REANIMADO
def raised_servant():
    c = Card("raised_servant")
    # câmera de cima: o chão ocupa a carta toda (terra de cemitério), a cova aberta no meio
    c.b("chao", "#2e3442", RECT, mode="poly")
    c.b("chao_luz", "#46506a", [(-10, -10), (310, -10), (310, 60), (180, 90), (60, 70), (-10, 100)], op=0.7)
    mist(c, 40, 41, n=4, op=0.3, h=18)
    r = rng(42)
    for i in range(16):
        x = r.random() * 300; y = r.random() * 260
        c.b(f"pedra{i}", "#3a4252", blob(x, y, 2 + r.random() * 3, 400 + i, 6, 0.3))
    c.b("grama", "#2a3a36", [(-10, 200), (40, 190), (60, 210), (20, 230), (-10, 236)], op=0.8)
    # o cenário: cova recém-aberta com a cruz de madeira tombada
    c.b("cova", "#181c28", [(72, 118), (222, 104), (238, 222), (84, 238)])
    c.b("cova_borda", EARTH_L, [(72, 118), (222, 104), (226, 112), (76, 126)], op=0.9)
    c.b("monte_terra", "#4a4234", [(226, 92), (262, 70), (296, 92), (300, 160), (270, 200), (246, 204), (236, 140)])
    c.b("cruz", "#6a4a2c", list(ap(tmat(258, 70, 38), [(-3, 40), (-3, -8), (-14, -8), (-14, -14), (-3, -14), (-3, -26), (3, -26), (3, -14),
                                                        (14, -14), (14, -8), (3, -8), (3, 40)])), mode="poly")
    c.b("pa", "#5a4a3a", [(28, 40), (34, 38), (70, 96), (66, 100)], mode="poly")
    c.b("pa_lamina", "#7a7a80", [(14, 20), (30, 14), (38, 36), (24, 44)])
    # 1 morte que vale 2: duas chamas de alma gêmeas girando em volta dele
    soul_stream(c, [(100, 200), (82, 150), (96, 92), (132, 60), (160, 52)], 7, 1.5, op=0.75)
    soul_stream(c, [(212, 200), (232, 150), (220, 96), (186, 62), (166, 56)], 7, 1.5, op=0.75)
    skull_fx(c, 160, 44, 0.8, -6, col=SOUL_L, glow=False)
    skull_fx(c, 176, 50, 0.7, 14, col=SOUL_L, glow=False)
    # o servo: erguendo-se da cova visto de cima, braço estendido para a câmera (mão grande em escorço)
    J1 = E.J("erguer", hip=(4, 6), neck=(-2, -44), head=(-6, -60, -18), hk=1.2, jaw=7, far="l",
             wr=(30, -92), ebr=1, hmr="claw", hdr=-70, hsr=1.5, wl=(-40, -6), ebl=1, hml="flat", hdl=170)
    p1 = E.skeleton(J1)
    M = c.fig("servo", p1, 150, 222, 14, 1.75)
    # borda de baixo da cova + terra caindo por cima do quadril
    front(c, "borda_cova", "#4a4234", [(66, 232), (130, 216), (200, 214), (250, 222), (262, 262), (60, 262)])
    front(c, "terra1", "#5a5040", blob(122, 220, 8, 7, 7, 0.3))
    front(c, "terra2", "#5a5040", blob(188, 216, 7, 8, 7, 0.3))
    c.guide = list(ap(M, [(-40, -6), (-10, -10), (-2, -44), (20, -76), (34, -100)]))
    c.save()


# =========================================================================== TOTEM DE OSSOS
def totem_pcs():
    """Totem de ossos (estrutura): poste de madeira, três crânios empilhados, ossos cruzados, crânio-coroa de chifres
    com olhos acesos, cordas e uma placa de runa verde. Coordenadas próprias, base em (0,0), altura ~200."""
    p = E.PAL; pcs = []
    pcs.append(Pc("poste", "totem", "#4a3424", [(-6, 0), (-7, -150), (7, -150), (6, 0)], mode="poly"))
    pcs.append(Pc("base_pedras", "totem", STONE, [(-30, 2), (-26, -10), (-12, -16), (12, -16), (26, -10), (30, 2)]))
    for k, (y, s, r_) in enumerate([(-30, 1.15, -4), (-62, 1.05, 6), (-92, 0.95, -6)]):
        pcs += C.small_skull(f"cranio{k}", (0, y), s * 1.4, r_, p["bone"] if k != 1 else p["bone_d"], fig="totem")
        pcs.append(Pc(f"corda{k}", "totem", C.PAL["rope"], [(-9, y + 15), (9, y + 15), (9, y + 18), (-9, y + 18)], mode="poly", cls="inner"))
    # ossos cruzados (braços do totem)
    for k, (a, b) in enumerate([((-44, -136), (40, -104)), ((44, -138), (-40, -106))]):
        pcs.append(E.bone(f"osso_cruz{k}", a, b, 4.6, 2.8, 4.4, p["bone"], fig="totem"))
    for k, x in enumerate((-44, 44)):
        pcs.append(Pc(f"pena{k}", "totem", "#3a4a52", [(x, -136), (x - 4 * np.sign(x), -118), (x + 2 * np.sign(x), -112), (x + 4 * np.sign(x), -130)]))
    # crânio-coroa com chifres
    for k, a in enumerate((-150, -120, -90, -60, -30)):
        d = np.array([math.cos(math.radians(a)), math.sin(math.radians(a))])
        pcs.append(Pc(f"coroa{k}", "totem", p["bone_d"], [np.array((0, -160)) + d * 14 - np.array([-d[1], d[0]]) * 3.6,
                                                          np.array((0, -160)) + d * (40 if k == 2 else 32),
                                                          np.array((0, -160)) + d * 14 + np.array([-d[1], d[0]]) * 3.6]))
    pcs += E.skull(tmat(0, -158, 0, 1.55), "f", 4, True, fig="totem")
    # placa de runa pendurada
    pcs.append(Pc("placa", "totem", "#5a4a38", [(-10, -122), (10, -122), (12, -104), (-12, -104)], mode="poly"))
    pcs.append(Pc("runa", "totem", SOUL, [(-4, -119), (4, -119), (0, -113), (4, -107), (-4, -107), (0, -113)], mode="poly", cls="inner"))
    return pcs


def bone_totem():
    c = Card("bone_totem")
    night(c, "#0c1228", "#34466a")
    disk(c, "lua", 168, 58, 44, MOON, MOON_C)
    c.b("chao", "#202838", [(-10, 210), (120, 200), (310, 206), (310, 300), (-10, 300)])
    mist(c, 208, 51, n=5, op=0.35)
    # aura do totem: anéis verdes no chão (raio de 8 m) e brilho
    c.b("aura", SOUL_D, ellipse(150, 236, 130, 30, 0, 18), op=0.35)
    for k, rr in enumerate((60, 92, 124)):
        pts = [(150 + math.cos(math.radians(a)) * rr, 236 + math.sin(math.radians(a)) * rr * 0.24) for a in np.linspace(195, 345, 10)]
        c.f("anel", SOUL, brush(pts, 3.4 - k * 0.8, 1.2), op=0.75 - k * 0.15)
    # espíritos subindo do chão para o totem
    soul_stream(c, [(40, 236), (54, 200), (84, 170), (122, 150)], 5, 1.2, op=0.6)
    soul_stream(c, [(262, 232), (250, 196), (220, 168), (180, 150)], 5, 1.2, op=0.6)
    # mãos de esqueleto rompendo a terra ao fundo
    for k, (x, y, a, s) in enumerate([(98, 214, -100, 0.9), (214, 212, -80, 0.85)]):
        for q in E.hand("x", (x, y), a, s * 1.6, "claw"):
            c.f("mao_terra", "#cfc3a2", q.pts)
        c.f("mao_terra", "#cfc3a2", E.bone("x", (x, y + 14), (x + math.cos(math.radians(a)) * 2, y), 3, 2, 3).pts)
    # o totem: câmera baixa, levemente inclinado (estrutura imponente)
    tp = totem_pcs()
    M = c.fig("totem", tp, 150, 246, 4, 1.12)
    # os mortos voltando: esqueleto erguendo-se à esquerda (frente) e outro à direita (menor, espelhado)
    J1 = E.J("erguer", hip=(4, 6), wr=(30, -88), hdr=-70, glow=True, jaw=6)
    p1 = E.skeleton(J1)
    c.fig("erguido", p1, 56, 268, -8, 1.05)
    J2 = E.J("erguer", hip=(4, 6), head=(-6, -60, -4), wr=(36, -70), hdr=-50, glow=False, jaw=3)
    p2 = E.skeleton(J2)
    for q in p2:
        if q.fill == E.PAL["bone"]:
            q.fill = "#cfc3a2"
    c.fig("erguido2", p2, 252, 264, 6, -0.86, 0.86)
    front(c, "terra_e", "#2c2a2c", [(-10, 262), (10, 252), (60, 248), (106, 256), (110, 280), (-10, 280)])
    front(c, "terra_d", "#2c2a2c", [(206, 258), (240, 250), (280, 252), (310, 256), (310, 280), (200, 280)])
    c.guide = list(ap(M, [(0, 0), (0, -80), (0, -160), (4, -210)]))
    c.save()


# =========================================================================== COLOSSO DE OSSOS
def bone_colossus():
    c = Card("bone_colossus")
    night(c, "#0c1026", "#3a4a70")
    disk(c, "lua", 236, 44, 34, MOON, MOON_C)
    c.b("chao", "#1e2434", [(-10, 226), (120, 220), (310, 228), (310, 300), (-10, 300)])
    mist(c, 230, 61, n=5, op=0.35)
    # o cenário: capela em ruínas, pequena, aos pés dele (escala)
    c.b("capela", STONE_D, [(14, 252), (14, 196), (34, 176), (54, 196), (54, 252)], mode="poly")
    c.b("capela_torre", STONE, [(26, 196), (26, 158), (34, 146), (42, 158), (42, 196)], mode="poly")
    c.b("capela_janela", "#ffd88a", [(30, 210), (38, 210), (38, 224), (30, 224)], mode="poly", op=0.9)
    # mortos sendo sugados para o peito: esqueletos e ossos voando em correntes verdes das duas laterais
    soul_stream(c, [(-6, 210), (40, 178), (90, 150), (128, 134)], 9, 3, op=0.6)
    soul_stream(c, [(306, 214), (270, 180), (214, 150), (170, 136)], 9, 3, op=0.6)
    run = sk_sil("correr", jaw=4)
    for k, (x, y, rot, s, fl) in enumerate([(30, 196, -40, 0.30, False), (70, 166, -30, 0.26, False), (272, 196, 40, 0.30, True), (236, 168, 30, 0.26, True)]):
        c.sil(run, x, y, rot, s, flip=fl, fill="#b8ac8c")
    for k, (x, y, L, a) in enumerate([(104, 150, 14, 30), (196, 152, 14, -40), (56, 186, 12, 80), (250, 186, 12, 120), (116, 128, 10, -10)]):
        bone_fx(c, x, y, L, a, 2.2, col="#cfc3a2")
    # o colosso: marcha para a câmera, câmera baixa, chifres e punho cortados pela moldura
    J1 = dict(C.POSES["marchar"])
    J1.update(hip=(0, -86), neck=(6, -178), head=(12, -198, 4), hk=2.2, jaw=8, far="l",
              al=(-44, -4), tl=(-58, 0), ar=(40, -10), tr=(56, -6),
              wl=(-86, -86), ebl=1, hdl=120, wr=(70, -150), ebr=-1, hmr="open", hdr=-60, hsr=1.35, glow=1.0)
    p1 = C.colossus(J1)
    M = c.fig("colosso", p1, 148, 288, -7, 1.04)
    c.guide = list(ap(M, [(-58, 0), (-24, -40), (0, -86), (6, -178), (10, -230)]))
    c.save()


# =========================================================================== CAVALEIRO DA MORTE
def death_knight():
    c = Card("death_knight")
    night(c, "#0e1228", "#3a4870")
    disk(c, "lua", 150, 66, 50, MOON, MOON_C)
    c.b("chao", "#1e2232", [(-10, 222), (140, 214), (310, 220), (310, 300), (-10, 300)])
    mist(c, 224, 71, n=5, op=0.35)
    # o cenário: portão quebrado de uma fortaleza (arco caído) atrás à direita
    c.b("arco", STONE_D, [(222, 250), (222, 150), (236, 124), (262, 112), (288, 120), (310, 140), (310, 250), (292, 250), (292, 160), (280, 140),
                          (262, 134), (246, 142), (238, 160), (238, 250)], mode="poly")
    stones(c, 222, 150, 238, 250, "#141824", 72, rows=6, cols=1, op=0.5)
    # o feitiço do Lich: círculo rúnico violeta atrás e a energia descendo em espiral até as runas do montante
    c.f("circulo", "#b07aff", ellipse(64, 64, 40, 40, 0, 18), op=0.25)
    for k, rr in enumerate((40, 30)):
        pts = [(64 + math.cos(math.radians(a)) * rr, 64 + math.sin(math.radians(a)) * rr) for a in np.linspace(-20 + k * 40, 300 + k * 40, 12)]
        c.f("circulo_anel", "#c8a0ff", brush(pts, 2.4, 1.0), op=0.8)
    for k in range(6):
        a = math.radians(k * 60 + 15)
        c.f("glifo", "#e8d8ff", [(64 + math.cos(a) * 34, 64 + math.sin(a) * 34), (64 + math.cos(a + 0.1) * 30, 64 + math.sin(a + 0.1) * 30),
                                 (64 + math.cos(a + 0.2) * 34, 64 + math.sin(a + 0.2) * 34)], mode="poly", op=0.9)
    soul_stream(c, [(60, 100), (40, 126), (52, 156), (30, 180), (22, 196)], 6, 2, op=0.75)
    c.f("energia", "#c8a0ff", brush([(72, 100), (58, 132), (66, 160), (44, 186), (34, 200)], 5, 1.4), op=0.75)
    # o cavaleiro: investida em diagonal para a direita, montante arrastado atrás com as runas acesas
    J1 = dict(K.POSES["investir"])
    J1.update(hip=(-4, -84), neck=(20, -140), head=(28, -158, 12), glow=1.0,
              ar=(42, -30), tr=(56, -26), al=(-48, -6), tl=(-58, 0),
              wl=(56, -116), hml="open", hdl=-20, wr=(-30, -90), sword=("r", 158, 108), sword_back=True,
              cape=[(-14, -150), (34, -146), (16, -120), (-10, -102), (-34, -90), (-58, -84), (-72, -96), (-62, -110), (-78, -122), (-50, -134)])
    p1 = K.knight(J1)
    M = c.fig("cavaleiro", p1, 156, 280, -8, 1.24)
    rim(c, p1, M, 2.8, -0.6, "#bfe8ff", 0.75)
    for k, (x, y) in enumerate([(20, 236), (34, 252), (52, 244)]):
        c.f("faisca", "#c8a0ff", ellipse(x, y, 1.8, 1.8, 0, 6), op=0.9)
    c.guide = list(ap(M, [(-58, 0), (-22, -40), (-4, -84), (20, -140), (44, -172)]))
    c.save()


# =========================================================================== EXPLOSÃO DE CADÁVER
def corpse_blast():
    c = Card("corpse_blast")
    night(c, "#0e1430", "#40527a")
    c.b("chao", "#232a3c", [(-10, 226), (140, 220), (310, 228), (310, 300), (-10, 300)])
    cx, cy = 78, 168
    # clarão da explosão (foco: maior contraste) e onda de choque indo para o herói
    c.b("clarao", "#3e7a6a", ellipse(cx, cy, 120, 110, 0, 18), op=0.45)
    c.b("clarao2", "#7ac8a8", ellipse(cx, cy, 74, 68, 0, 16), op=0.55)
    for k, rr in enumerate((70, 96, 124)):
        pts = [(cx + math.cos(math.radians(a)) * rr, cy + math.sin(math.radians(a)) * rr * 0.92) for a in np.linspace(-60, 60, 10)]
        c.f("onda", SOUL_L if k == 0 else SOUL, brush(pts, 5 - k * 1.2, 1.4), op=0.85 - k * 0.2)
    # o cenário: lápide tombando com o sopro (direita, atrás do herói)
    tomb(c, "lapide", 262, 236, 40, 70, 22, broken=False)
    # a explosão: chamas de alma em leque + estrela branca no centro
    for k, (dx, dy, h, w, ln) in enumerate([(-20, 20, 70, 40, -20), (16, 22, 80, 44, 24), (0, 30, 96, 50, 4), (-34, 30, 50, 30, -30), (36, 30, 54, 30, 34)]):
        soul_fire(c, cx + dx, cy + dy, h, w, ln, 900 + k * 7, op=0.9)
    star(c, cx, cy - 6, 40, 10, 10, SOUL_L, rot=8, op=0.95, name="estalo")
    star(c, cx, cy - 6, 22, 7, 8, "#ffffff", rot=30, op=1.0, name="estalo")
    # o cadáver explodindo: crânio, costelas, ossos voando em todas as direções (rastro verde)
    r = rng(91)
    for k in range(11):
        a = -150 + k * 300 / 10 + r.normal(0, 8)
        d = 48 + r.random() * 34
        x = cx + math.cos(math.radians(a)) * d; y = cy + math.sin(math.radians(a)) * d * 0.9
        c.f("rastro", SOUL, wedge(x, y, cx + math.cos(math.radians(a)) * (d - 26), cy + math.sin(math.radians(a)) * (d - 26) * 0.9, 4), mode="poly", op=0.55)
        bone_fx(c, x, y, 10 + r.random() * 8, a + 90 + r.normal(0, 30), 2.2)
    skull_fx(c, cx - 30, cy - 92, 1.15, -30, glow=True)
    for k, (dx, dy, a) in enumerate([(-40, -50, -40), (-52, 10, 200)]):
        p = E.PAL
        pts = [(-12, 0), (-4, -3), (6, -2), (12, 4), (8, 6), (0, 3), (-10, 5)]
        c.f("costelas_voando", p["bone"], list(ap(tmat(cx + dx, cy + dy, a, 1.2), pts)))
    # o herói: fincado contra o sopro (pose nova 'fincar'), escorregando para trás, capa jogada
    hp = hero_l1.pose("fincar")
    M = c.fig("heroi", hp, 214, 262, 0, 1.28)
    rim(c, hp, M, -2.6, -0.8, "#d8fff0", 0.75)  # recorte do lado da explosão (esquerda)
    dust(c, 290, 258, 16, 10, "#6a6a74", 93, sz=(1.5, 3.5), op=0.7)
    for k in range(3):
        c.f("risco_pe", "#8a8a96", [(300 - k * 4, 250 + k * 3), (280 - k * 3, 254 + k * 3)], closed=False, sw=1.2, op=0.7)
    c.guide = list(ap(M, [(70, -2), (36, -32), (6, -60), (-27, -107), (-46, -126)])) + [(cx, cy)]
    c.save()


ALL = dict(skeleton_archers=skeleton_archers, bone_legion=bone_legion, ghoul=ghoul, raised_servant=raised_servant,
           bone_totem=bone_totem, bone_colossus=bone_colossus, death_knight=death_knight, corpse_blast=corpse_blast)

if __name__ == "__main__":
    for nm in (sys.argv[1:] or ALL):
        ALL[nm]()
        print(nm)
