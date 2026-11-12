"""Ficha do lobisomem: bípede digitígrado, tronco curvado de peito largo, braços longos com garras, cabeça de lobo
(a mesma da ficha do lobo, escala 1,3), juba nos ombros e calça rasgada (o resto do humano)."""
import base  # noqa: F401
import math
import numpy as np
from geom import *
import wolf

INK = "#2b1a10"
PAL = dict(fur="#6e5a4c", far="#4e3f35", belly="#b8a088", back="#55463b", ear_in="#b88476", eye="#ffd23a",
           nose="#1e1814", mouth="#5a1014", teeth="#f6eed8", claw="#efe4c8", pants="#56607a", pants_d="#3e4660", k=1.0, hk=1.0)
wolf.PAL["lobisomem"] = dict(PAL, mane=0, spikes=False)


def limb(name, joints, widths, fill, fig="corpo"):
    return Pc(name, fig, fill, tube(joints, [w / 2 for w in widths], cap0=0.5, cap1=0.5, per=4))


def hand(name, wrist, d_ang, fill, spread=60, L=14):
    """Mão aberta com 4 dedos e garras, apontando para d_ang."""
    pcs = []
    d = np.array([math.cos(math.radians(d_ang)), math.sin(math.radians(d_ang))])
    c = A(wrist) + d * 4
    pcs.append(Pc(name, "corpo", fill, ellipse(c[0], c[1], 7.6, 6, d_ang, 8)))
    for k in range(4):
        a = math.radians(d_ang - spread / 2 + k * spread / 3)
        dd = np.array([math.cos(a), math.sin(a)])
        b = c + dd * 5
        m = b + dd * L * 0.5
        pcs.append(Pc(f"{name}_dedo{k}", "corpo", fill, tube([b, m], [2.6, 2], cap0=0.3, cap1=0.6, per=2)))
        tip = m + dd * L * 0.55 + np.array([-dd[1], dd[0]]) * 1.4
        pcs.append(Pc(f"{name}_garra{k}", "corpo", PAL["claw"], brush([m, (m + tip) / 2 + np.array([-dd[1], dd[0]]) * 0.8, tip], 2.2, 0.2, per=2)))
    return pcs


def foot(name, hock, toe, fill):
    pcs = []
    d = A(toe) - A(hock); d /= np.linalg.norm(d)
    for k in range(3):
        b = A(toe) + np.array([-d[1], d[0]]) * (k - 1) * 1.6
        tip = b + d * 4.4 + np.array([0, 0.6])
        pcs.append(Pc(f"{name}_garra{k}", "corpo", PAL["claw"], brush([b, tip], 1.8, 0.2, per=2)))
    return pcs


def werewolf(J):
    p = PAL; pcs = []
    pcs.append(Pc("cauda", "corpo", p["fur"], tube(J["tail"], [3, 6, 6.5, 3], cap0=0.4, cap1=1.4, per=4)))
    # lado de longe
    pcs.append(limb("perna_l", J["legl"], [22, 13, 7.5, 5.6], p["far"]))
    pcs += foot("pe_l", J["legl"][-2], J["legl"][-1], p["far"])
    pcs.append(Pc("calca_l", "corpo", p["pants_d"], tube(J["legl"][:2], [10.6, 6.6], [10.6, 6.6], cap0=0.5, cap1=0.0, per=4, jag=2.2, jag_range=(0.5, 1.0))))
    pcs.append(limb("braco_l", J["arml"], [16, 12, 8.5], p["far"]))
    pcs += hand("mao_l", J["arml"][-1], J["handl"], p["far"], J.get("spreadl", 50))
    # tronco curvado: peito largo, cintura fina
    sp = J["spine"]
    pcs.append(Pc("tronco", "corpo", p["fur"], tube(sp, J.get("wa", [13, 10, 16, 20, 17]), J.get("wb", [14, 10, 19, 25, 20]), cap0=0.8, cap1=0.6,
                                                  jag=2.4, jag_range=(0.55, 1.0))))
    pcs.append(Pc("peito", "corpo", p["belly"], tube(sp[1:], [-w * 0.3 for w in J.get("wb", [14, 10, 19, 25, 20])[1:]],
                                                   [w * 0.9 for w in J.get("wb", [14, 10, 19, 25, 20])[1:]], cap0=0.3, cap1=0.4), cls="inner"))
    pcs.append(Pc("calca_cos", "corpo", p["pants"], tube(sp[:2], [13.6, 10.6], [14.6, 10.6], cap0=0.8, cap1=0.0, per=3)))
    # juba (ombros/nuca)
    nk = J["neck"]
    pcs.append(Pc("juba", "corpo", p["fur"], tube(nk, [19, 16, 11], [17, 14, 9], cap0=0.4, cap1=0.6, jag=3.2, jag_range=(0.0, 0.9))))
    # lado de perto
    pcs.append(limb("perna", J["legr"], [24, 14, 8, 6], p["fur"]))
    pcs += foot("pe", J["legr"][-2], J["legr"][-1], p["fur"])
    pcs.append(Pc("calca", "corpo", p["pants"], tube(J["legr"][:2], [11.6, 7.2], [11.6, 7.2], cap0=0.5, cap1=0.0, per=4, jag=2.4, jag_range=(0.5, 1.0))))
    pcs.append(limb("braco", J["armr"], [18, 13.5, 9.5], p["fur"]))
    pcs += hand("mao", J["armr"][-1], J["handr"], p["fur"], J.get("spreadr", 60))
    hx, hy, ha, hs, op = J["head"]
    pcs += wolf.head_side(wolf.PAL["lobisomem"], tmat(hx, hy, ha, hs), op, angry=True)
    return pcs


POSES = {
    # salto com as garras: tronco em diagonal, braço de perto alcança, perna de perto empurra para trás
    "saltar": dict(
        spine=[(-2, -58), (8, -70), (20, -82), (32, -92), (40, -98)],
        neck=[(36, -96), (46, -102), (54, -106)], head=(50, -110, 12, 1.0, 32),
        tail=[(-6, -58), (-22, -60), (-36, -54), (-50, -56)],
        legr=[(0, -58), (-10, -42), (-30, -34), (-44, -28)], legl=[(4, -58), (24, -50), (14, -32), (26, -24)],
        armr=[(34, -88), (52, -78), (72, -80)], handr=0, arml=[(30, -94), (24, -118), (32, -140)], handl=-75),
    # uivo: de pé, costas arqueadas, cabeça para trás, braços abertos para baixo
    "uivar": dict(
        spine=[(0, -60), (4, -72), (10, -84), (10, -96), (6, -104)],
        neck=[(6, -100), (8, -110), (10, -118)], head=(8, -118, -72, 1.0, 26),
        tail=[(-4, -60), (-16, -52), (-26, -40), (-30, -28)],
        legr=[(2, -60), (14, -38), (0, -18), (10, 0)], legl=[(-2, -60), (6, -38), (-14, -16), (-6, 0)],
        armr=[(10, -96), (24, -78), (36, -64)], handr=50, arml=[(2, -96), (-12, -80), (-24, -66)], handl=120),
    # espreita: agachado, uma mão no chão, a outra armada
    "espreitar": dict(
        spine=[(0, -40), (12, -46), (24, -50), (36, -50), (44, -48)], wa=[13, 10, 16, 20, 17], wb=[14, 10, 19, 25, 20],
        neck=[(42, -50), (52, -50), (60, -48)], head=(58, -52, 10, 1.0, 20),
        tail=[(-4, -40), (-18, -36), (-30, -26), (-40, -22)],
        legr=[(0, -40), (16, -26), (-6, -14), (4, 0)], legl=[(4, -40), (20, -24), (-2, -10), (8, 0)],
        armr=[(40, -46), (44, -28), (52, -8)], handr=20, spreadr=70, arml=[(38, -50), (54, -60), (66, -52)], handl=-10),
}
GUIDE = {"saltar": [(-46, -26), (-10, -46), (20, -80), (52, -104), (86, -112)],
         "uivar": [(10, 0), (6, -40), (6, -80), (12, -118), (24, -150)],
         "espreitar": [(4, 0), (0, -30), (30, -50), (70, -50), (96, -44)]}


def pose(name):
    return werewolf(POSES[name])
