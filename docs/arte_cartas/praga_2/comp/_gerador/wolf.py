"""Ficha do lobo (perfil): espinha + pescoço + cabeça + patas digitígradas; variação Besta Alfa por proporção."""
import base  # noqa: F401  (ajusta sys.path)
import math
import numpy as np
from geom import *

INK = "#2b1a10"
PAL = {
    "comum": dict(fur="#8d8478", far="#6a6258", belly="#e2d6c0", back="#6e655c", ear_in="#c99a8a", eye="#f2c23a",
                  nose="#2b2420", mouth="#5a1414", teeth="#f4ecd6", claw="#efe4c8", k=1.0, hk=1.0, mane=0, spikes=False),
    "peste": dict(fur="#857f6e", far="#625c4e", belly="#d8d0b4", back="#625a4c", ear_in="#b89482", eye="#a6e04a",
                  nose="#2b2420", mouth="#5a1414", teeth="#f0e8cc", claw="#e8e0c4", k=0.95, hk=1.0, mane=1.6, spikes=False),
    "alfa": dict(fur="#4e4a4c", far="#363234", belly="#9a8f86", back="#2e2a2c", ear_in="#9a6a62", eye="#ff3a1a",
                 nose="#1a1414", mouth="#5a0f12", teeth="#f6eed8", claw="#efe4c8", k=1.35, hk=1.18, mane=3.2, spikes=True),
}

# ---------------------------------------------------------------- cabeça de perfil (origem = nuca, focinho em +x)
H_CLOSED = [(-4, -5), (1, -11), (9, -14.5), (16, -13), (21, -10.5), (28, -8.8), (34, -7.6), (37, -5.8), (37.2, -3),
            (34.5, -1.2), (32, 0.8), (27, 3.2), (20, 5.2), (13, 8), (5, 10.5), (-3, 8.5)]
H_UP = [(-4, -5), (1, -11), (9, -14.5), (16, -13), (21, -10.5), (28, -8.8), (34, -7.6), (37, -5.8), (37.2, -3),
        (34.5, -1.2), (30, -0.4), (24, 0.4), (18, 1.6), (13, 5.5), (5, 10.5), (-3, 8.5)]
JAW = [(14, 3.2), (20, 2.2), (27, 1.4), (32.5, 1.2), (33.4, 2.8), (30, 4.8), (22, 6.6), (14, 8)]
HINGE = (13, 4)
EAR = [(4, -11.5), (3, -20), (5.5, -30), (11.5, -22), (16, -13)]
EAR_IN = [(6.4, -13.5), (5.8, -20), (6.8, -26), (10.6, -21), (13.4, -14.5)]
EYE = [(15.5, -7.6), (18.6, -9.8), (21.8, -8.6), (18.6, -6.8)]
NOSE = [(34.4, -7.6), (37.2, -5.9), (37.6, -3.2), (34.8, -2.4)]
CHEEK = [(2, 1), (10, 1.5), (17, 3.5), (12, 8.6), (4, 10)]


def head_side(pal, M, open_=0.0, angry=False):
    pcs = [Pc("orelha_l", "cabeca", pal["far"], [(x - 5, y + 1.5) for x, y in EAR])]
    if open_ > 0:
        Mj = chain(T(*HINGE), R(open_), T(-HINGE[0], -HINGE[1]))
        jaw = list(ap(Mj, JAW))
        pcs.append(Pc("mandibula", "cabeca", pal["fur"], jaw))
        pcs.append(Pc("cabeca", "cabeca", pal["fur"], H_UP))
        jt = list(ap(Mj, [(32.5, 1.2), (27, 1.4), (20, 2.2), (14, 3.2)]))
        mouth = [(34.2, -1), (30, -0.4), (24, 0.4), (18, 1.6), (14, 4)] + jt[::-1]
        pcs.append(Pc("boca", "cabeca", pal["mouth"], mouth, cls="inner"))
        lang = list(ap(Mj, [(16, 3.6), (24, 2.8), (29, 3), (24, 5), (17, 5.4)]))
        pcs.append(Pc("lingua", "cabeca", "#c0505a", lang, cls="inner"))
        pcs.append(Pc("presa_cima", "cabeca", pal["teeth"], [(30.4, -0.6), (32.4, -0.9), (31.6, 5.2)], cls="inner", mode="poly"))
        pcs.append(Pc("presa_cima2", "cabeca", pal["teeth"], [(25, 0.1), (26.6, 0), (25.9, 3.4)], cls="inner", mode="poly"))
        lt = list(ap(Mj, [(29.4, 1.4), (31.2, 1.3), (30.6, -3.6)]))
        pcs.append(Pc("presa_baixo", "cabeca", pal["teeth"], lt, cls="inner", mode="poly"))
    else:
        pcs.append(Pc("cabeca", "cabeca", pal["fur"], H_CLOSED))
        pcs.append(Pc("boca", "cabeca", INK, [(33, 0.2), (26, 1.6), (19, 2.4)], closed=False, cls="inner", sw=0.9))
    pcs.append(Pc("bochecha", "cabeca", pal["belly"], CHEEK, cls="inner"))
    pcs.append(Pc("orelha", "cabeca", pal["fur"], EAR))
    pcs.append(Pc("orelha_dentro", "cabeca", pal["ear_in"], EAR_IN, cls="inner"))
    pcs.append(Pc("olho", "cabeca", pal["eye"], EYE, cls="inner"))
    pcs.append(Pc("nariz", "cabeca", pal["nose"], NOSE, cls="inner"))
    pcs.append(Pc("focinho_ruga", "cabeca", INK, [(22, -9.6), (25, -7.8), (27, -8.6)], closed=False, cls="inner", sw=0.6))
    if angry or open_ > 0:
        pcs.append(Pc("sobrancelha", "cabeca", INK, [(13, -10), (18, -11.6), (23, -9.4)], closed=False, cls="inner", sw=1.4))
        pcs.append(Pc("ruga", "cabeca", INK, [(24, -6), (28, -5), (31, -6)], closed=False, cls="inner", sw=0.7))
    return [p.moved(M) for p in pcs]


def head_front(pal, M, open_=True):
    """Cabeça de frente (para escorço): origem no centro do crânio."""
    pcs = [Pc("orelha_l", "cabeca", pal["fur"], [(-9, -8), (-17, -20), (-15, -34), (-5, -16)]),
           Pc("orelha", "cabeca", pal["fur"], [(9, -8), (17, -20), (15, -34), (5, -16)]),
           Pc("orelha_l_dentro", "cabeca", pal["ear_in"], [(-10, -12), (-15, -21), (-14, -29), (-8, -16)], cls="inner"),
           Pc("orelha_dentro", "cabeca", pal["ear_in"], [(10, -12), (15, -21), (14, -29), (8, -16)], cls="inner"),
           Pc("cabeca", "cabeca", pal["fur"], [(-18, -2), (-14, -12), (-6, -16), (0, -16.5), (6, -16), (14, -12), (18, -2), (20, 8),
                                                (12, 12), (8, 22), (0, 25), (-8, 22), (-12, 12), (-20, 8)]),
           Pc("bochecha_l", "cabeca", pal["belly"], [(-19, 7), (-12, 6), (-9, 14), (-13, 13)], cls="inner"),
           Pc("bochecha", "cabeca", pal["belly"], [(19, 7), (12, 6), (9, 14), (13, 13)], cls="inner"),
           Pc("focinho", "cabeca", pal["belly"], [(-7, 4), (0, 1), (7, 4), (8, 16), (0, 22), (-8, 16)], cls="inner")]
    if open_:
        pcs.append(Pc("boca", "cabeca", pal["mouth"], [(-7, 17), (0, 15.5), (7, 17), (5, 27), (0, 29), (-5, 27)], cls="inner"))
        for i, (x, s) in enumerate([(-5, 1), (5, -1)]):
            pcs.append(Pc(f"presa{i}", "cabeca", pal["teeth"], [(x - 1.2, 17), (x + 1.2, 17), (x + s * 0.3, 22)], cls="inner", mode="poly"))
            pcs.append(Pc(f"presa_b{i}", "cabeca", pal["teeth"], [(x - 1, 27), (x + 1, 27), (x + s * 0.3, 23)], cls="inner", mode="poly"))
    pcs.append(Pc("nariz", "cabeca", pal["nose"], [(-4, 9), (0, 7.5), (4, 9), (3, 12.5), (0, 13.5), (-3, 12.5)], cls="inner"))
    pcs.append(Pc("olho_l", "cabeca", pal["eye"], [(-12, -3), (-8, -5.5), (-4.5, -3.5), (-8.5, -1.5)], cls="inner"))
    pcs.append(Pc("olho", "cabeca", pal["eye"], [(12, -3), (8, -5.5), (4.5, -3.5), (8.5, -1.5)], cls="inner"))
    pcs.append(Pc("sobrancelha_l", "cabeca", INK, [(-13, -7), (-8, -7.4), (-3, -4)], closed=False, cls="inner", sw=1.3))
    pcs.append(Pc("sobrancelha", "cabeca", INK, [(13, -7), (8, -7.4), (3, -4)], closed=False, cls="inner", sw=1.3))
    pcs.append(Pc("testa", "cabeca", INK, [(0, -11), (0, -4)], closed=False, cls="inner", sw=0.7))
    return [p.moved(M) for p in pcs]


# ---------------------------------------------------------------- patas
def leg(name, joints, widths, fill, pal, front=True):
    pcs = [Pc(name, "corpo", fill, tube(joints, [w / 2 for w in widths], cap0=0.4, cap1=0.5, per=4))]
    a, b = A(joints[-2]), A(joints[-1])
    d = (b - a) / (np.linalg.norm(b - a) + 1e-9)
    # pata: almofada alongada para a frente do último segmento
    ang = math.degrees(math.atan2(d[1], d[0]))
    fwd = np.array([1.0, 0.0]) if abs(d[1]) > 0.75 else d  # pata no chão aponta para a frente
    c = b + fwd * widths[-1] * 0.7
    pa = math.degrees(math.atan2(fwd[1], fwd[0]))
    w = widths[-1]
    pcs.append(Pc(name + "_pata", "corpo", fill, ellipse(c[0], c[1], w * 1.25, w * 0.62, pa, 8)))
    nrm = np.array([-fwd[1], fwd[0]])
    for k in range(3):
        base = c + fwd * w * 1.05 + nrm * (k - 1) * w * 0.32
        tip = base + fwd * 2.6 + nrm * 0.9
        pcs.append(Pc(f"{name}_unha{k}", "corpo", pal["claw"], brush([base, tip], 1.3, 0.2, per=2)))
    return pcs


def wolf_side(P, var="comum"):
    pal = PAL[var]; k = pal["k"]
    pcs = []
    # cauda (pincel peludo)
    tw = P.get("tailw", 8.5) * min(k, 1.25)
    pcs.append(Pc("cauda", "corpo", pal["fur"], tube(P["tail"], [tw * 0.45, tw, tw * 1.05, tw * 0.55], cap0=0.4, cap1=1.4, per=4)))
    pcs.append(Pc("cauda_ponta", "corpo", pal["back"], tube(P["tail"][2:], [tw * 0.55, tw * 0.3], cap0=0.0, cap1=1.0, per=4), cls="inner"))
    for L in P["legs"]:
        if not L[3]:
            pcs += leg(L[0], L[1], [w * min(k, 1.3) for w in L[2]], pal["far"], pal)
    sp = P["spine"]
    wa = [w * k * 1.2 for w in P["wa"]]; wb = [w * k * 1.22 for w in P["wb"]]
    pcs.append(Pc("tronco", "corpo", pal["fur"], tube(sp, wa, wb, cap0=0.9, cap1=0.3, jag=pal["mane"] * 0.6 if pal["mane"] else 0,
                                                    jag_range=(0.45, 0.98))))
    pcs.append(Pc("dorso", "corpo", pal["back"], tube(sp, [w * 1.0 for w in wa], [-w * 0.55 for w in wa], cap0=0.5, cap1=0.2), cls="inner"))
    pcs.append(Pc("barriga", "corpo", pal["belly"], tube(sp[1:], [-w * 0.45 for w in wb[1:]], [w * 0.95 for w in wb[1:]], cap0=0.4, cap1=0.3), cls="inner"))
    # pescoço até a cabeça
    nk = P["neck"]; nw = [w * k * 1.15 for w in P.get("nw", [14, 12, 10])]
    pcs.append(Pc("pescoco", "corpo", pal["fur"], tube(nk, nw, [w * 1.1 for w in nw], cap0=0.3, cap1=0.6,
                                                     jag=pal["mane"] if pal["mane"] else 0, jag_range=(0.0, 0.95))))
    pcs.append(Pc("peito", "corpo", pal["belly"], tube(nk[:-1], [-w * 0.2 for w in nw[:-1]], [w * 1.05 for w in nw[:-1]], cap0=0.6, cap1=0.6), cls="inner"))
    if pal["spikes"]:
        S_ = cr_sample(sp, 8)
        n = len(S_)
        for i, t in enumerate([0.55, 0.68, 0.8, 0.92]):
            j = int(n * t); p0 = S_[j]; tg = S_[min(j + 1, n - 1)] - S_[j - 1]; tg /= np.linalg.norm(tg)
            nrm = np.array([tg[1], -tg[0]])
            if nrm[1] > 0:
                nrm = -nrm
            base = p0 + nrm * wa[min(int(t * len(wa)), len(wa) - 1)] * 0.8
            h = 9 + 4 * math.sin(i * 1.7)
            pcs.append(Pc(f"espinho{i}", "corpo", "#d8ccb0", [base - tg * 3.4, base + nrm * h - tg * 3.5, base + tg * 3.4], mode="poly"))
    for L in P["legs"]:
        if L[3]:
            pcs += leg(L[0], L[1], [w * min(k, 1.3) for w in L[2]], pal["fur"], pal)
    hx, hy, ha, hs, op = P["head"]
    pcs += head_side(pal, tmat(hx, hy, ha, hs * pal["hk"]), op, angry=P.get("angry", False))
    if var == "alfa":
        Mh = tmat(hx, hy, ha, hs * pal["hk"])
        pcs.append(Pc("cicatriz", "cabeca", "#c8706a", list(ap(Mh, [(13, -14), (17, -9), (21, -3)])), closed=False, cls="inner", sw=1.2))
    return pcs


FW = [13, 8.2, 5.2, 4.6]
HW = [19, 11, 6, 4.8]
POSES = {
    # galope estendido: fase de suspensão, patas da frente alcançam, traseiras empurram
    "correr": dict(
        spine=[(0, -46), (18, -50), (36, -51), (52, -52), (61, -53)], wa=[7, 8, 8, 9, 9], wb=[12, 10, 18, 24, 22],
        neck=[(57, -56), (70, -60), (82, -62)], nw=[15, 13, 10], head=(78, -66, 6, 1.0, 14),
        tail=[(-4, -48), (-18, -52), (-36, -50), (-54, -54)],
        legs=[("pata_frente_l", [(55, -44), (63, -30), (77, -18), (89, -14)], FW, False),
              ("pata_tras_l", [(8, -44), (8, -28), (-10, -22), (-22, -14)], HW, False),
              ("pata_tras", [(6, -46), (-2, -32), (-20, -26), (-34, -24)], HW, True),
              ("pata_frente", [(59, -46), (71, -36), (87, -32), (99, -30)], FW, True)]),
    # bote: salto em diagonal, garras à frente, boca aberta
    "atacar": dict(
        spine=[(0, -40), (18, -50), (38, -60), (56, -70), (66, -76)], wa=[7, 8, 8, 9, 9], wb=[12, 10, 18, 24, 22],
        neck=[(62, -80), (74, -90), (86, -96)], nw=[15, 13, 10], head=(82, -100, 14, 1.05, 30), angry=True,
        tail=[(-4, -40), (-20, -38), (-38, -30), (-56, -30)],
        legs=[("pata_frente_l", [(60, -66), (74, -70), (88, -80), (96, -90)], FW, False),
              ("pata_tras_l", [(8, -38), (2, -22), (-16, -18), (-28, -8)], HW, False),
              ("pata_tras", [(6, -40), (-6, -28), (-24, -26), (-36, -18)], HW, True),
              ("pata_frente", [(64, -70), (80, -66), (94, -72), (104, -82)], FW, True)]),
    # uivo: sentado, peito alto, cabeça para cima
    "uivar": dict(
        spine=[(0, -14), (8, -30), (20, -46), (32, -60), (40, -70)], wa=[8, 8, 8, 8, 7], wb=[14, 12, 15, 18, 17],
        neck=[(38, -76), (44, -90), (48, -100)], nw=[15, 13, 10], head=(46, -102, -58, 1.0, 22),
        tail=[(-6, -8), (-20, -2), (-36, 0), (-54, -2)], tailw=8,
        legs=[("pata_frente_l", [(34, -56), (30, -38), (34, -18), (38, 0)], FW, False),
              ("pata_tras_l", [(6, -20), (26, -12), (4, -3), (20, 0)], HW, False),
              ("pata_tras", [(2, -20), (22, -10), (0, -3), (16, 0)], HW, True),
              ("pata_frente", [(42, -58), (42, -38), (46, -18), (50, 0)], FW, True)]),
    # ameaça: cabeça baixa, rosnando, peso para trás, patas da frente abertas
    "ameaca": dict(
        spine=[(0, -48), (20, -54), (40, -52), (58, -46), (68, -42)], wa=[7, 8, 8, 9, 9], wb=[12, 10, 18, 24, 22],
        neck=[(66, -44), (78, -42), (90, -38)], nw=[15, 13, 10], head=(86, -42, 14, 1.0, 18), angry=True,
        tail=[(-4, -48), (-16, -44), (-28, -34), (-36, -22)],
        legs=[("pata_frente_l", [(62, -36), (60, -22), (66, -8), (72, 0)], FW, False),
              ("pata_tras_l", [(8, -46), (20, -30), (6, -16), (10, 0)], HW, False),
              ("pata_tras", [(4, -48), (14, -30), (-2, -14), (2, 0)], HW, True),
              ("pata_frente", [(66, -38), (72, -24), (80, -10), (88, 0)], FW, True)]),
}
GUIDE = {"correr": [(-50, -54), (0, -50), (44, -54), (82, -64), (116, -66)],
         "atacar": [(-50, -26), (0, -40), (50, -68), (90, -100), (120, -112)],
         "uivar": [(8, 0), (6, -24), (24, -52), (44, -92), (64, -132)],
         "ameaca": [(-36, -22), (0, -46), (50, -50), (90, -40), (122, -32)]}


def pose(name, var="comum"):
    return wolf_side(POSES[name], var)


_SIL = {}


def silhouette(name="correr", var="comum"):
    key = (name, var)
    if key not in _SIL:
        _SIL[key] = union_poly(pose(name, var), off=(160, 160))[0]
    return _SIL[key].copy()
