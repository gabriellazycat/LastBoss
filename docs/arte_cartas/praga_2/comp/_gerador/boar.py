"""Ficha do javali de guerra (perfil): barril com corcova, cabeça em cunha, presas, patas curtas; barda de ferro."""
import base  # noqa: F401
import math
import numpy as np
from geom import *

INK = "#2b1a10"
PAL = dict(fur="#5e4636", far="#43322a", belly="#836652", mane="#3a2a20", snout="#c08a7c", snout_d="#7a4a44",
           tusk="#f2e8cc", eye="#ff8a1a", hoof="#2e2420", iron="#8a8e96", iron_d="#62666e", rust="#9a5a32",
           leather="#6a4428", ear_in="#a87064")

# cabeça de perfil: origem = junção com o pescoço, focinho em +x
HEAD = [(-6, -12), (2, -17), (12, -17), (22, -13), (32, -8), (40, -5), (43, -3), (43.5, 2), (41, 5), (34, 7), (26, 10),
        (16, 15), (6, 16), (-4, 11), (-8, 0)]
SNOUT = [(41.2, -4.6), (43.8, -3.4), (44.6, 0.8), (43, 4.6), (40.6, 3.4), (40.4, -1.6)]
EAR = [(4, -15), (-2, -27), (3, -27.5), (12, -18)]
EAR_IN = [(4.6, -17), (1, -24.5), (3.6, -24.8), (9.4, -18.4)]
EAR_FAR = [(-2, -14), (-9, -24), (-4, -25), (5, -16)]
EYE = [(17, -8.6), (19.6, -10), (22, -8.8), (19.6, -7.4)]
TUSK = [(30, 6), (33.4, 1), (35.6, -5), (35, -11), (37.8, -6), (37.6, 1), (33.6, 7.4)]
CHAMFRON = [(10, -17.6), (22, -14), (33, -8.6), (35, -6), (30, -3), (20, -6), (10, -10)]


def head(M, open_=0):
    p = PAL
    pcs = [Pc("orelha_l", "cabeca", p["far"], EAR_FAR),
           Pc("cabeca", "cabeca", p["fur"], HEAD),
           Pc("bochecha", "cabeca", p["belly"], [(4, 6), (16, 7), (26, 8), (16, 14), (5, 14)], cls="inner"),
           Pc("focinho", "cabeca", p["snout"], SNOUT),
           Pc("narina", "cabeca", p["snout_d"], ellipse(43.2, -1.4, 0.8, 1.4, 0, 6), cls="inner"),
           Pc("narina2", "cabeca", p["snout_d"], ellipse(43.2, 2.2, 0.8, 1.4, 0, 6), cls="inner"),
           Pc("boca", "cabeca", INK, [(40, 5.2), (32, 6.6), (24, 8.4)], closed=False, cls="inner", sw=0.9),
           Pc("presa", "cabeca", p["tusk"], TUSK),
           Pc("orelha", "cabeca", p["fur"], EAR),
           Pc("orelha_dentro", "cabeca", p["ear_in"], EAR_IN, cls="inner"),
           Pc("testeira", "armadura", p["iron"], CHAMFRON),
           Pc("testeira_chifre", "armadura", p["iron_d"], [(17, -13), (20, -25), (24, -11.6)], mode="poly"),
           Pc("testeira_rebite", "armadura", INK, ellipse(28, -7.4, 0.9, 0.9, 0, 6), cls="inner"),
           Pc("olho", "cabeca", p["eye"], EYE, cls="inner"),
           Pc("sobrancelha", "cabeca", INK, [(14, -11), (19, -12), (24, -9.4)], closed=False, cls="inner", sw=1.4),
           Pc("ruga", "cabeca", INK, [(33, -5), (36, -3), (36.5, 0)], closed=False, cls="inner", sw=0.7)]
    return [q.moved(M) for q in pcs]


def head_front(M):
    """Cabeça de frente (para investida em escorço): origem no centro da testa."""
    p = PAL
    pcs = [Pc("orelha_l", "cabeca", p["fur"], [(-10, -8), (-20, -16), (-16, -4)]),
           Pc("orelha", "cabeca", p["fur"], [(10, -8), (20, -16), (16, -4)]),
           Pc("cabeca", "cabeca", p["fur"], [(-14, -8), (-8, -13), (0, -14), (8, -13), (14, -8), (15, 4), (10, 14), (8, 22), (-8, 22), (-10, 14), (-15, 4)]),
           Pc("orelha_l_dentro", "cabeca", p["ear_in"], [(-11, -8.6), (-17.4, -13.6), (-15, -6)], cls="inner"),
           Pc("orelha_dentro", "cabeca", p["ear_in"], [(11, -8.6), (17.4, -13.6), (15, -6)], cls="inner"),
           Pc("presa_l", "cabeca", p["tusk"], [(-8, 22), (-12, 16), (-15, 6), (-13, 6), (-10, 14), (-5, 20)]),
           Pc("presa", "cabeca", p["tusk"], [(8, 22), (12, 16), (15, 6), (13, 6), (10, 14), (5, 20)]),
           Pc("focinho", "cabeca", p["snout"], ellipse(0, 22, 8.6, 5.6, 0, 10)),
           Pc("narina_l", "cabeca", p["snout_d"], ellipse(-3, 22, 1.4, 2, 0, 6), cls="inner"),
           Pc("narina", "cabeca", p["snout_d"], ellipse(3, 22, 1.4, 2, 0, 6), cls="inner"),
           Pc("testeira", "armadura", p["iron"], [(-8, -12), (0, -13.6), (8, -12), (6, 2), (3, 12), (-3, 12), (-6, 2)]),
           Pc("testeira_chifre", "armadura", p["iron_d"], [(-3, -8), (0, -22), (3, -8)], mode="poly"),
           Pc("olho_l", "cabeca", p["eye"], ellipse(-9.4, -1, 2, 1.4, 20, 6), cls="inner"),
           Pc("olho", "cabeca", p["eye"], ellipse(9.4, -1, 2, 1.4, -20, 6), cls="inner"),
           Pc("sobrancelha_l", "cabeca", INK, [(-13, -4.4), (-9, -4), (-6, -1.6)], closed=False, cls="inner", sw=1.2),
           Pc("sobrancelha", "cabeca", INK, [(13, -4.4), (9, -4), (6, -1.6)], closed=False, cls="inner", sw=1.2)]
    return [q.moved(M) for q in pcs]


def leg(name, joints, widths, fill):
    pcs = [Pc(name, "corpo", fill, tube(joints, [w / 2 for w in widths], cap0=0.4, cap1=0.2, per=4))]
    a, b = A(joints[-2]), A(joints[-1])
    d = (b - a) / (np.linalg.norm(b - a) + 1e-9); n = np.array([-d[1], d[0]])
    w = widths[-1] * 0.62
    c = b + d * 2.6
    pcs.append(Pc(name + "_casco", "corpo", PAL["hoof"], [b + n * w, c + n * w * 1.25 + d * 1.2, c - n * w * 1.25 + d * 1.2, b - n * w], mode="poly"))
    pcs.append(Pc(name + "_fenda", "corpo", "#8a7a6a", [b + d * 1.2, c + d * 1.2], closed=False, cls="inner", sw=0.5))
    return pcs


def boar_side(P):
    p = PAL; pcs = []
    pcs.append(Pc("cauda", "corpo", p["fur"], brush(P["tail"], 4, 0.8)))
    for L in P["legs"]:
        if not L[3]:
            pcs += leg(L[0], L[1], L[2], p["far"])
    sp = P["spine"]
    pcs.append(Pc("tronco", "corpo", p["fur"], tube(sp, P["wa"], P["wb"], cap0=0.9, cap1=0.6, jag=2.4, jag_range=(0.3, 1.0))))
    pcs.append(Pc("barriga", "corpo", p["belly"], tube(sp[1:], [-w * 0.5 for w in P["wb"][1:]], [w * 0.95 for w in P["wb"][1:]], cap0=0.4, cap1=0.3), cls="inner"))
    # crina (cerdas do dorso)
    S_ = cr_sample(sp, 8); n = len(S_)
    for i in range(9):
        t = 0.3 + i * 0.075
        j = min(int(n * t), n - 2); q0 = S_[j]; tg = S_[j + 1] - S_[j - 1]; tg /= np.linalg.norm(tg)
        nr = np.array([tg[1], -tg[0]])
        if nr[1] > 0:
            nr = -nr
        wa = np.interp(t, np.linspace(0, 1, len(P["wa"])), P["wa"])
        base_ = q0 + nr * wa * 0.85
        pcs.append(Pc(f"cerda{i}", "corpo", p["mane"], [base_ - tg * 3, base_ + nr * (6 + 2 * (i % 2)) - tg * 3.6, base_ + tg * 3], mode="poly"))
    # barda: placa de ferro sobre a corcova + cilha de couro
    Mb = P["barda"]
    pcs.append(Pc("cilha", "armadura", p["leather"], list(ap(Mb, [(-4, -14), (4, -14), (6, 22), (-3, 22)])), mode="poly"))
    pcs.append(Pc("barda", "armadura", p["iron"], list(ap(Mb, [(-24, -6), (-16, -16), (0, -21), (16, -18), (26, -8), (22, 4), (4, 0), (-14, 2)]))))
    pcs.append(Pc("barda_borda", "armadura", p["rust"], list(ap(Mb, [(-22, -2), (-14, 2), (4, 0), (22, 4), (21, 7), (4, 3.4), (-14, 5.4), (-23, 1.6)])), cls="inner"))
    for i, (x, y) in enumerate([(-14, -6), (-2, -10), (12, -8)]):
        pcs.append(Pc(f"barda_espigao{i}", "armadura", p["iron_d"], list(ap(Mb, [(x - 3, y - 4), (x + 1, y - 14), (x + 3, y - 4)])), mode="poly"))
    for L in P["legs"]:
        if L[3]:
            pcs += leg(L[0], L[1], L[2], p["fur"])
    hx, hy, ha, hs = P["head"]
    pcs += head(tmat(hx, hy, ha, hs))
    return pcs


FW = [13, 8, 5, 4.4]
HW = [17, 9, 5, 4.4]
POSES = {
    # investida: galope baixo, cabeça baixa, presas à frente
    "investida": dict(
        spine=[(0, -34), (16, -40), (34, -42), (52, -40), (62, -36)], wa=[9, 10, 12, 16, 15], wb=[14, 17, 19, 20, 17],
        head=(60, -30, 18, 1.08), tail=[(-6, -36), (-12, -44), (-10, -50)], barda=tmat(50, -45, 4, 0.72),
        legs=[("pata_frente_l", [(56, -26), (64, -16), (76, -14), (84, -12)], FW, False),
              ("pata_tras_l", [(8, -26), (10, -14), (-4, -10), (-12, -4)], HW, False),
              ("pata_tras", [(6, -28), (0, -16), (-14, -14), (-22, -10)], HW, True),
              ("pata_frente", [(58, -24), (56, -12), (64, -4), (72, -2)], FW, True)]),
    # lançar: cabeça sobe com as presas (o golpe que empurra), patas da frente fincadas
    "lancar": dict(
        spine=[(0, -30), (16, -38), (34, -44), (50, -48), (60, -48)], wa=[9, 10, 12, 16, 15], wb=[14, 17, 19, 20, 17],
        head=(60, -46, -32, 1.08), tail=[(-6, -32), (-14, -38), (-16, -46)], barda=tmat(48, -51, -8, 0.72),
        legs=[("pata_frente_l", [(54, -38), (62, -24), (66, -10), (70, 0)], FW, False),
              ("pata_tras_l", [(8, -24), (2, -12), (-12, -6), (-18, 0)], HW, False),
              ("pata_tras", [(6, -26), (-2, -14), (-16, -8), (-24, -2)], HW, True),
              ("pata_frente", [(58, -40), (68, -28), (74, -14), (80, -4)], FW, True)]),
    # ameaça: cava o chão com a pata, cabeça baixa, bufando
    "ameaca": dict(
        spine=[(0, -38), (16, -42), (34, -42), (50, -38), (58, -32)], wa=[9, 10, 12, 16, 15], wb=[14, 17, 19, 20, 17],
        head=(56, -24, 28, 1.08), tail=[(-6, -40), (-14, -44), (-20, -40)], barda=tmat(48, -45, 8, 0.72),
        legs=[("pata_frente_l", [(52, -24), (52, -14), (56, -6), (58, 0)], FW, False),
              ("pata_tras_l", [(8, -30), (14, -18), (8, -8), (10, 0)], HW, False),
              ("pata_tras", [(4, -30), (8, -18), (0, -8), (2, 0)], HW, True),
              ("pata_frente", [(56, -22), (46, -14), (40, -6), (34, -4)], FW, True)]),
    "trote": dict(
        spine=[(0, -36), (16, -42), (34, -44), (52, -42), (60, -38)], wa=[9, 10, 12, 16, 15], wb=[14, 17, 19, 20, 17],
        head=(58, -34, 10, 1.08), tail=[(-6, -38), (-12, -44), (-14, -50)], barda=tmat(50, -47, 2, 0.72),
        legs=[("pata_frente_l", [(54, -28), (58, -16), (56, -6), (58, 0)], FW, False),
              ("pata_tras_l", [(8, -28), (18, -16), (10, -8), (14, 0)], HW, False),
              ("pata_tras", [(4, -30), (2, -18), (-6, -8), (-6, 0)], HW, True),
              ("pata_frente", [(58, -28), (66, -18), (64, -8), (70, -2)], FW, True)]),
}
GUIDE = {"investida": [(-16, -48), (10, -40), (40, -44), (70, -30), (106, -18)],
         "lancar": [(-24, -2), (0, -32), (36, -46), (70, -70), (90, -96)],
         "ameaca": [(-20, -42), (10, -42), (40, -42), (70, -18), (96, -2)],
         "trote": [(-14, -48), (10, -42), (40, -46), (70, -34), (100, -30)]}


def pose(name):
    return boar_side(POSES[name])
