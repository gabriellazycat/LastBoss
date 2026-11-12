"""Ficha do herói genérico (armadura, tabardo, capa, espada), visto de frente (lado do vilão)."""
import math
import numpy as np
from geom import *

HP = dict(steel="#a7b0ba", steel_d="#7c8590", tabard="#33557d", cape="#2c4468", leather="#6b4a30",
          blade="#d8dee6", gold="#c8a040", visor="#1a1a22")


def v(p):
    return A(p)


def hero(J):
    """J: juntas da pose. Ordem de pintura: capa, pernas, saia, tronco, tabardo, braços, espada, elmo."""
    h = HP; pcs = []
    pcs.append(Pc("capa", "capa", h["cape"], J["cape"]))
    for s in ("l", "r"):
        hp, kn, an, to = v(J["h" + s]), v(J["k" + s]), v(J["a" + s]), v(J["t" + s])
        pcs.append(Pc("perna_" + s, "corpo", h["steel_d"] if s == J.get("far", "l") else h["steel"],
                      tube([hp, kn, an], [7.2, 5.6, 4.4], cap0=0.5, cap1=0.5, per=4)))
        pcs.append(Pc("joelheira_" + s, "corpo", h["steel"], ellipse(kn[0], kn[1], 5.2, 4.4, 0, 8)))
        d = to - an; ang = math.degrees(math.atan2(d[1], d[0]))
        c = (an + to) / 2
        pcs.append(Pc("pe_" + s, "corpo", h["steel_d"], ellipse(c[0], c[1] - 1, np.linalg.norm(d) / 2 + 2, 3.6, ang, 8)))
    hl, hr, hc = v(J["hl"]), v(J["hr"]), v(J["hc"])
    sl, sr, nk = v(J["sl"]), v(J["sr"]), v(J["neck"])
    up = (nk - hc) / np.linalg.norm(nk - hc); side = np.array([-up[1], up[0]])  # side aponta para a direita da tela
    # saia de placas (tassets)
    pcs.append(Pc("saia", "corpo", h["steel_d"], [hl - side * 3 - up * 2, hr + side * 3 - up * 2, hr + side * 5 + (-up) * 14,
                                                hc - up * 18, hl - side * 5 - up * 14]))
    wl = sl * 0.45 + hl * 0.55 + side * 3; wr = sr * 0.45 + hr * 0.55 - side * 3
    pcs.append(Pc("tronco", "corpo", h["steel"], [sl - up * 3, nk - side * 6 + up * 1, nk + side * 6 + up * 1, sr - up * 3,
                                                sr + side * 2 - up * 10, wr, hr + side * 1 - up * 2, hc - up * 6,
                                                hl - side * 1 - up * 2, wl, sl - side * 2 - up * 10]))
    pcs.append(Pc("tabardo", "corpo", h["tabard"], [nk - side * 5 - up * 2, nk + side * 5 - up * 2, wr - side * 2, hr + side * 3 - up * 10,
                                                  hc - up * 26, hl - side * 3 - up * 10, wl + side * 2]))
    pcs.append(Pc("cinto", "corpo", h["leather"], [hl - side * 2 + up * 2, hr + side * 2 + up * 2, hr + side * 2 - up * 2, hl - side * 2 - up * 2]))
    order = ["l", "r"] if J.get("sword", "r") == "r" else ["r", "l"]
    sw_drawn = False
    for s in order:
        sh, el, wr_ = v(J["s" + s]), v(J["e" + s]), v(J["w" + s])
        fill = h["steel_d"] if s == J.get("far", "l") else h["steel"]
        pcs.append(Pc("braco_" + s, "corpo", fill, tube([sh, el, wr_], [6, 5.2, 4.4], cap0=0.5, cap1=0.4, per=4)))
        pcs.append(Pc("ombreira_" + s, "corpo", h["steel"], ellipse(sh[0], sh[1] - 1, 8.5, 6.5, -15 if s == "l" else 15, 10)))
        d = wr_ - el; d = d / np.linalg.norm(d)
        hc_ = wr_ + d * 3
        if s == J.get("sword", "r") and not sw_drawn:
            pcs += sword(hc_, J["sdir"], J.get("slen", 70))
            sw_drawn = True
        pcs.append(Pc("mao_" + s, "corpo", h["steel_d"], ellipse(hc_[0], hc_[1], 4.8, 4.2, 0, 8)))
    # elmo
    hd = v(J["head"]); Mh = chain(T(*hd), R(J.get("tilt", 0)))
    pcs.append(Pc("elmo", "cabeca", h["steel"], list(ap(Mh, [(-10, -6), (-9, -12), (-5, -16.5), (0, -17.5), (5, -16.5), (9, -12), (10, -6),
                                                             (10, 6), (7, 11), (0, 13), (-7, 11), (-10, 6)]))))
    tw = J.get("turn", 2)
    pcs.append(Pc("viseira", "cabeca", h["visor"], list(ap(Mh, [(-8 + tw, -3.5), (8 + tw, -3.5), (8 + tw, -0.5), (-8 + tw, -0.5)])), cls="inner", mode="poly"))
    pcs.append(Pc("respiro", "cabeca", h["visor"], list(ap(Mh, [(-1 + tw, -0.5), (1 + tw, -0.5), (1 + tw, 7), (-1 + tw, 7)])), cls="inner", mode="poly"))
    pcs.append(Pc("crista", "cabeca", "#2b1a10", list(ap(Mh, [(tw * .5, -17), (tw * .8, -10), (tw, -4)])), closed=False, cls="inner", sw=0.8))
    return pcs


def sword(hand, sdir, L):
    h = HP
    d = A(sdir) / np.linalg.norm(sdir); n = np.array([-d[1], d[0]])
    pm = hand - d * 8; g = hand + d * 5; tip = g + d * L
    pcs = [Pc("cabo", "espada", h["leather"], [pm + n * 1.8, g + n * 1.8, g - n * 1.8, pm - n * 1.8], mode="poly"),
           Pc("pomo", "espada", h["gold"], ellipse(pm[0], pm[1], 3, 3, 0, 8)),
           Pc("lamina", "espada", h["blade"], [g + n * 3, tip - d * 9 + n * 2.4, tip, tip - d * 9 - n * 2.4, g - n * 3], mode="poly"),
           Pc("guarda", "espada", h["gold"], [g - n * 10 - d * 1.5, g + n * 10 - d * 1.5, g + n * 10 + d * 1.5, g - n * 10 + d * 1.5], mode="poly"),
           Pc("fio", "espada", "#7c8590", [g + d * 2, tip - d * 6], closed=False, cls="inner", sw=0.6)]
    return pcs


POSES = {
    "avancar": dict(head=(2, -150), tilt=-4, neck=(1, -138), sl=(-22, -128), sr=(22, -130), el=(-30, -104), wl=(-24, -84),
                    er=(36, -148), wr=(42, -170), sdir=(0.45, -0.89), hc=(0, -82), hl=(-11, -82), hr=(11, -80),
                    kl=(-14, -44), kr=(16, -50), al=(-16, -6), ar=(18, -14), tl=(-23, -1), tr=(24, -6),
                    cape=[(-18, -134), (18, -136), (34, -112), (40, -64), (30, -32), (-8, -26), (-42, -36), (-56, -72), (-38, -114)]),
    "preso": dict(head=(9, -142), tilt=20, turn=-1, neck=(6, -130), sl=(-16, -120), sr=(26, -124), el=(-36, -116), wl=(-54, -128),
                  er=(42, -140), wr=(52, -162), sdir=(0.15, -0.99), hc=(4, -76), hl=(-7, -76), hr=(15, -74),
                  kl=(-21, -40), al=(-14, -5), tl=(-20, -1), kr=(28, -56), ar=(36, -28), tr=(45, -27), far="r",
                  cape=[(-12, -128), (22, -132), (44, -112), (64, -86), (56, -60), (34, -52), (12, -60), (-10, -86)]),
    "defesa": dict(head=(-3, -140), tilt=-10, turn=3, neck=(-1, -128), sl=(-22, -118), sr=(20, -120), el=(-36, -134), wl=(-12, -150),
                   er=(34, -96), wr=(46, -76), sdir=(0.85, 0.5), hc=(0, -74), hl=(-12, -74), hr=(12, -72),
                   kl=(-28, -40), al=(-34, -5), tl=(-42, -1), kr=(24, -38), ar=(28, -5), tr=(36, -1),
                   cape=[(-18, -124), (16, -126), (40, -108), (52, -70), (44, -40), (10, -44), (-30, -40), (-46, -76), (-34, -112)]),
    "guarda": dict(head=(0, -150), neck=(0, -138), sl=(-21, -128), sr=(21, -128), el=(-18, -100), er=(16, -102), wl=(-2, -96),
                   wr=(3, -98), sdir=(0.28, -0.96), slen=74, hc=(0, -80), hl=(-11, -80), hr=(11, -80),
                   kl=(-16, -42), al=(-20, -5), tl=(-27, -1), kr=(16, -42), ar=(20, -5), tr=(27, -1),
                   cape=[(-18, -134), (18, -134), (32, -100), (36, -40), (26, -8), (-26, -8), (-36, -40), (-32, -100)]),
}


def pose(name):
    return hero(POSES[name])
