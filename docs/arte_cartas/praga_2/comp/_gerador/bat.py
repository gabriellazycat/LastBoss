"""Ficha do morcego (vista de frente, para escorço): corpo, cabeça de orelhas grandes, asas com braço + 3 dedos
e membrana recortada entre as pontas. Ângulos em graus na tela (0 = +x, negativo = para cima)."""
import base  # noqa: F401
import math
import numpy as np
from geom import *

INK = "#2b1a10"
PAL = dict(fur="#5c4436", fur_d="#45332a", chest="#7e6250", wing="#7a5458", wing_d="#5e3e44", bone="#3e2a26",
           ear_in="#c88a86", eye="#ff3a1e", mouth="#4a1014", teeth="#f4ecd6", claw="#efe4c8", nose="#8a5a58")


def _dir(a):
    r = math.radians(a)
    return np.array([math.cos(r), math.sin(r)])


def wing(side, W, prefix="asa"):
    """side = +1 (direita) / -1 (esquerda). W: dict(up, fore, f=(a3,a4,a5), L=escala, fx=escorço horizontal, curl)."""
    L = W.get("L", 1.0)
    S = np.array([5.0, -6.0])
    E = S + _dir(W["up"]) * 13 * L
    Wr = E + _dir(W["fore"]) * 22 * L
    tips = [Wr + _dir(a) * l * L for a, l in zip(W["f"], (34, 30, 23))]
    d2 = Wr + _dir(W["fore"] + W.get("d2", -12)) * 12 * L
    foot = np.array([4.4, 12.0])
    curl = W.get("curl", 0.26)

    def scallop(a, b, k=5):
        m = (a + b) / 2; m = m + (Wr - m) * curl
        out = []
        for i in range(1, k):
            t = i / k
            out.append((1 - t) ** 2 * a + 2 * (1 - t) * t * m + t * t * b)
        return out
    lead_mid = (S + E) / 2 + (np.array([0, -1.0]) if W["up"] < 30 else np.array([0.6, 0])) * 2.2
    pts = [S + np.array([0, -1.5]), lead_mid, E + _dir(W["up"] - 90) * 1.8, (E + Wr) / 2 + _dir(W["fore"] - 90) * 1.6, Wr + _dir(W["fore"] - 90) * 1.4,
           d2, tips[0]]
    pts += scallop(tips[0], tips[1]) + [tips[1]] + scallop(tips[1], tips[2]) + [tips[2]]
    # da última ponta até o pé (borda de fuga), recortada
    m_ = (tips[2] + foot) / 2; m_ = m_ + ((np.array([0, 0]) - m_) * 0.25)
    pts += [(1 - t) ** 2 * tips[2] + 2 * (1 - t) * t * m_ + t * t * foot for t in (0.25, 0.5, 0.75)] + [foot, np.array([5.0, 6.0])]
    fx = W.get("fx", 1.0)
    Mside = chain(T(*S), S_(side * fx, 1.0), T(-S[0], -S[1])) if True else None
    Mside = chain(S_(side, 1.0), T(*S), S_(fx, 1.0), T(-S[0], -S[1]))
    pcs = [Pc(f"{prefix}", f"{prefix}", PAL["wing"], list(ap(Mside, pts)), mode="poly")]
    # varetas (braço e dedos) como linhas internas com função
    pcs.append(Pc(f"{prefix}_braco", f"{prefix}", PAL["bone"], list(ap(Mside, [S, E, Wr])), closed=False, cls="inner", sw=2.0))
    for i, tp in enumerate([d2] + tips):
        mid = (Wr + tp) / 2 + _dir(math.degrees(math.atan2(*(tp - Wr)[::-1])) + 90) * 1.2
        pcs.append(Pc(f"{prefix}_dedo{i}", f"{prefix}", PAL["bone"], list(ap(Mside, [Wr, mid, tp])), closed=False, cls="inner", sw=1.0 if i else 1.2))
    th = Wr + _dir(W["fore"] - 70) * 4.5
    pcs.append(Pc(f"{prefix}_polegar", f"{prefix}", PAL["claw"], list(ap(Mside, brush([Wr, th], 2.2, 0.3, per=2)))))
    return pcs


def S_(sx, sy):
    return np.array([[sx, 0, 0], [0, sy, 0], [0, 0, 1]], float)


def head_front(M, open_=True):
    p = PAL
    EAR = [(-8.8, -16.4), (-13, -24), (-14.4, -31.6), (-8.4, -27.4), (-2.4, -21.4)]
    EIN = [(-8.4, -18.6), (-11.4, -24.4), (-12.4, -28.6), (-8.6, -25.6), (-4.6, -21.4)]
    pcs = [Pc("orelha_l", "cabeca", p["fur"], EAR),
           Pc("orelha", "cabeca", p["fur"], [(-x, y) for x, y in EAR]),
           Pc("cabeca", "cabeca", p["fur"], [(-9.4, -15), (-7.6, -20.6), (0, -22.6), (7.6, -20.6), (9.4, -15), (7.4, -10), (3.6, -7.4), (0, -6.8), (-3.6, -7.4), (-7.4, -10)]),
           Pc("orelha_l_dentro", "cabeca", p["ear_in"], EIN, cls="inner"),
           Pc("orelha_dentro", "cabeca", p["ear_in"], [(-x, y) for x, y in EIN], cls="inner"),
           Pc("nariz", "cabeca", p["nose"], [(-1.6, -14.6), (0, -17.4), (1.6, -14.6), (0, -13.4)], cls="inner")]
    if open_:
        pcs.append(Pc("boca", "cabeca", p["mouth"], [(-3.6, -12), (0, -12.8), (3.6, -12), (2.6, -8.4), (0, -7.8), (-2.6, -8.4)], cls="inner"))
        pcs.append(Pc("presa_l", "cabeca", p["teeth"], [(-2.8, -12.1), (-1.6, -12.4), (-2.1, -9.4)], cls="inner", mode="poly"))
        pcs.append(Pc("presa", "cabeca", p["teeth"], [(2.8, -12.1), (1.6, -12.4), (2.1, -9.4)], cls="inner", mode="poly"))
    else:
        pcs.append(Pc("boca", "cabeca", INK, [(-2.6, -11), (0, -10.4), (2.6, -11)], closed=False, cls="inner", sw=0.6))
    pcs.append(Pc("olho_l", "cabeca", p["eye"], ellipse(-3.6, -16.4, 1.5, 1.1, 20, 6), cls="inner"))
    pcs.append(Pc("olho", "cabeca", p["eye"], ellipse(3.6, -16.4, 1.5, 1.1, -20, 6), cls="inner"))
    pcs.append(Pc("sobrancelha_l", "cabeca", INK, [(-6, -18.6), (-3.4, -18.2), (-1.2, -16.8)], closed=False, cls="inner", sw=0.8))
    pcs.append(Pc("sobrancelha", "cabeca", INK, [(6, -18.6), (3.4, -18.2), (1.2, -16.8)], closed=False, cls="inner", sw=0.8))
    return [q.moved(M) for q in pcs]


def head_side(M):
    p = PAL
    pcs = [Pc("orelha", "cabeca", p["fur"], [(-4, -6), (-8, -20), (-2, -22), (3, -8)]),
           Pc("cabeca", "cabeca", p["fur"], [(-7, -2), (-4, -7), (2, -8), (7, -5), (10, -3.4), (11, -1), (9, 1.6), (6, 3.4), (0, 4.6), (-5, 3.6)]),
           Pc("orelha_dentro", "cabeca", p["ear_in"], [(-3.4, -8), (-6.6, -18.4), (-2.8, -19.6), (1.4, -8.6)], cls="inner"),
           Pc("boca", "cabeca", p["mouth"], [(9, 1.2), (4, 2.2), (1, 1.6), (5, 4), (8.4, 2.6)], cls="inner"),
           Pc("presa", "cabeca", p["teeth"], [(7.6, 1.2), (8.6, 1.2), (8, 3.8)], cls="inner", mode="poly"),
           Pc("nariz", "cabeca", p["nose"], [(9.6, -4), (11.6, -2.4), (10.4, -0.6)], cls="inner"),
           Pc("olho", "cabeca", p["eye"], ellipse(3.6, -3.2, 1.4, 1.1, 0, 6), cls="inner")]
    return [q.moved(M) for q in pcs]


def body(open_=True, feet="baixo", tilt=0):
    p = PAL
    pcs = []
    for s in (-1, 1):
        nm = "perna" if s > 0 else "perna_l"
        if feet == "frente":
            jt = [(3 * s, 6), (6.5 * s, 10), (6 * s, 14.5)]
        else:
            jt = [(3 * s, 6), (4.6 * s, 10.5), (4.4 * s, 14)]
        pcs.append(Pc(nm, "corpo", p["fur_d"], tube(jt, [1.6, 1.2, 1.0], cap0=0.4, cap1=0.5, per=3)))
        b = A(jt[-1])
        for k in range(3):
            tip = b + np.array([(k - 1) * 1.4 + s * 0.6, 3.2])
            pcs.append(Pc(f"{nm}_garra{k}", "corpo", p["claw"], brush([b + np.array([(k - 1) * 0.8, 0]), tip], 1.0, 0.2, per=2)))
    pcs.append(Pc("tronco", "corpo", p["fur"], [(-7.6, -8), (0, -10.4), (7.6, -8), (9, -2), (7.4, 4), (4, 8), (0, 9.2), (-4, 8), (-7.4, 4), (-9, -2)]))
    pcs.append(Pc("peito", "corpo", p["chest"], [(-4.6, -6), (0, -7.4), (4.6, -6), (5.2, -1), (3, 4), (0, 5.4), (-3, 4), (-5.2, -1)], cls="inner"))
    for i, (x, y) in enumerate([(-2.4, -2), (1.4, 1.4), (-1, 4.6), (2.6, -4)]):
        pcs.append(Pc(f"pelo{i}", "corpo", INK, [(x, y), (x + 0.6, y + 1.8)], closed=False, cls="inner", sw=0.5))
    pcs += head_front(T(0, 0), open_)
    return pcs


def bat(P):
    pcs = wing(-1, P["wl"], "asa_l") + wing(1, P["wr"], "asa")
    pcs += body(P.get("open", True), P.get("feet", "baixo"))
    return pcs


POSES = {
    # bater de asas: alto (asas em V)
    "voar_cima": dict(wl=dict(up=-38, fore=-72, f=(-58, -22, 18)), wr=dict(up=-34, fore=-66, f=(-52, -16, 24))),
    # bater de asas: baixo (asas em concha, pontas abaixo do corpo)
    "voar_baixo": dict(wl=dict(up=16, fore=42, f=(64, 96, 122), curl=0.18), wr=dict(up=12, fore=38, f=(58, 90, 118), curl=0.18)),
    # planar / atacar: asas abertas quase na horizontal, garras à frente, boca aberta
    "atacar": dict(wl=dict(up=-14, fore=-4, f=(-16, 20, 54), fx=0.78), wr=dict(up=-20, fore=-12, f=(-26, 12, 48), L=1.08), feet="frente"),
    # mergulho: asas recolhidas para trás e para cima, corpo vindo para a câmera
    "mergulho": dict(wl=dict(up=-62, fore=-98, f=(-84, -64, -38), L=0.86, fx=0.9, curl=0.32),
                     wr=dict(up=-56, fore=-90, f=(-76, -56, -30), L=0.9, curl=0.32), feet="frente"),
}
GUIDE = {"voar_cima": [(0, 20), (0, 0), (0, -24), (2, -38)], "voar_baixo": [(0, 22), (0, 0), (0, -24)],
         "atacar": [(-40, -30), (-16, -10), (0, 0), (8, 18)], "mergulho": [(0, -60), (0, -24), (0, 0), (0, 20)]}


def pose(name):
    if name == "pendurado":
        return pendurado()
    return bat(POSES[name])


def pendurado():
    """De cabeça para baixo, preso pelos pés, asas enroladas (casulo). Origem: ponto de apoio dos pés."""
    p = PAL
    pcs = []
    for s in (-1, 1):
        nm = "perna" if s > 0 else "perna_l"
        pcs.append(Pc(nm, "corpo", p["fur_d"], tube([(2.4 * s, 0), (3 * s, 5), (3.6 * s, 9)], [1.2, 1.4, 1.6], cap0=0.6, cap1=0.3, per=3)))
        for k in range(3):
            b = np.array([2.4 * s + (k - 1) * 0.9, 0.4])
            pcs.append(Pc(f"{nm}_garra{k}", "corpo", p["claw"], brush([b, b + np.array([(k - 1) * 0.6, -2.8])], 1.0, 0.2, per=2)))
    pcs.append(Pc("asas", "corpo", p["wing"], [(-5, 8), (0, 6.6), (5, 8), (9, 16), (10, 26), (7, 34), (0, 37), (-7, 34), (-10, 26), (-9, 16)]))
    pcs.append(Pc("asas_dobra", "corpo", p["wing_d"], [(1, 8), (6, 12), (8, 24), (5, 33), (2, 34), (4, 24), (3, 14)], cls="inner"))
    pcs.append(Pc("asas_vareta", "corpo", p["bone"], [(-2, 9), (-5, 20), (-3, 33)], closed=False, cls="inner", sw=1.0))
    pcs.append(Pc("asas_vareta2", "corpo", p["bone"], [(4, 10), (7, 22), (4, 33)], closed=False, cls="inner", sw=1.0))
    pcs.append(Pc("polegar_l", "corpo", p["claw"], brush([(-6, 12), (-8, 10)], 1.6, 0.3, per=2)))
    pcs.append(Pc("polegar", "corpo", p["claw"], brush([(6, 12), (8, 10)], 1.6, 0.3, per=2)))
    pcs += head_front(chain(T(0, 26), R(180)), open_=False)
    return pcs


_SIL = {}


def silhouette(name="voar_cima"):
    if name not in _SIL:
        polys = union_poly(pose(name), off=(80, 80))
        _SIL[name] = max(polys, key=len)
    return _SIL[name].copy()
