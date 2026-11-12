"""Ficha do slime da Praga: gelatina verde-peste com um crânio de rato boiando dentro.
Volume em "cabeças": a unidade é a altura do slime parado (60 u = 1 corpo); rosto ≈ 0,4 do corpo, olhos no terço de cima.
Comportamento físico: comprime ao pousar (achata e alarga), estica no salto (gota inclinada), escorre na base.
data-fig: slime_corpo (massa + pseudópodes + gotas presas = 1 silhueta), slime_broto (a metade que se solta ao dividir).
Rosto, crânio, bolhas e brilho = class=inner."""
import base  # noqa: F401
import math
import numpy as np
from geom import *

INK = "#2b1a10"
PAL = dict(body="#9cc23e", body_d="#6f9a2c", hi="#e2f2a0", core="#7aa832", skull="#efe6c8", eye="#fff36a", pupil="#2b1a10",
           mouth="#3a4a14", drip="#8ab436", bubble="#d6ec8a")


def face(M, open_=0.6, angry=True, s=1.0):
    """Rosto local: centro entre os olhos em (0,0), olhando para +x levemente (3/4)."""
    p = PAL; pcs = []
    for k, (x, r) in enumerate([(-7, 5.2), (8, 6.2)]):
        pcs.append(Pc(f"olho{k}", "corpo", p["eye"], ellipse(x, 0, r, r * 1.15, 0, 10), cls="inner"))
        pcs.append(Pc(f"pupila{k}", "corpo", p["pupil"], ellipse(x + 1.6, 0.8, r * 0.38, r * 0.6, 0, 8), cls="inner"))
    if angry:
        pcs.append(Pc("sobrancelha0", "corpo", INK, [(-13, -7), (-7, -6), (-2, -3.5)], closed=False, cls="inner", sw=1.8))
        pcs.append(Pc("sobrancelha1", "corpo", INK, [(16, -8.5), (9, -7.4), (3, -4)], closed=False, cls="inner", sw=1.8))
    h = 4 + 10 * open_
    mouth = [(-10, 9), (-4, 11), (4, 11.5), (13, 9), (14, 9 + h * 0.5), (8, 9 + h), (0, 10 + h * 0.9), (-7, 9 + h * 0.6)]
    pcs.append(Pc("boca", "corpo", p["mouth"], mouth, cls="inner"))
    for k, x in enumerate([-5, 2, 9]):
        pcs.append(Pc(f"dente{k}", "corpo", p["skull"], [(x - 1.8, 10.6 + (k == 1) * 0.4), (x + 1.8, 10.8), (x, 15)], cls="inner", mode="poly"))
    return [q.moved(chain(M, S(s))) for q in pcs]


def skull(M):
    p = PAL
    pcs = [Pc("cranio", "corpo", p["skull"], [(-12, -2), (-8, -7), (0, -8), (8, -5), (14, -1), (19, 2), (17, 4.5), (8, 5), (0, 6), (-9, 5)], cls="inner", op=0.75),
           Pc("cranio_olho", "corpo", "#5a6a2a", ellipse(2, -2, 2.6, 2, 0, 8), cls="inner", op=0.8),
           Pc("cranio_dente", "corpo", p["skull"], [(15, 4), (17, 4), (16.6, 8.5), (15.2, 8)], cls="inner", mode="poly", op=0.75)]
    return [q.moved(M) for q in pcs]


def bubbles(pts):
    return [Pc(f"bolha{k}", "corpo", PAL["bubble"], ellipse(x, y, r, r, 0, 8), cls="inner", op=0.8) for k, (x, y, r) in enumerate(pts)]


def drip(name, top, L, w, fill=None, fig="corpo"):
    x, y = top
    return Pc(name, fig, fill or PAL["body"], [(x - w / 2, y - 2), (x + w / 2, y - 2), (x + w * 0.3, y + L * 0.6), (x + w * 0.55, y + L * 0.9),
                                              (x, y + L), (x - w * 0.55, y + L * 0.9), (x - w * 0.3, y + L * 0.6)])


def drop(name, c, r, ang, fig="corpo"):
    """Gota solta (lágrima) voando na direção ang."""
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    c = A(c)
    return Pc(name, fig, PAL["body"], [c + d * r, c + n * r * 0.85 - d * r * 0.3, c - d * r * 2.2, c - n * r * 0.85 - d * r * 0.3])


def highlight(name, pts, fig="corpo"):
    return Pc(name, fig, PAL["hi"], pts, cls="inner", op=0.75)


def slime(P):
    p = PAL; pcs = []
    for k, (sp, w) in enumerate(P.get("pods_back", [])):
        pcs.append(Pc(f"pseudopode_l{k}", "corpo", p["body_d"], tube(sp, [x / 2 for x in w], cap0=0.4, cap1=0.9, per=4)))
    if "puddle" in P:
        x0, x1 = P["puddle"]
        pcs.append(Pc("poca", "corpo", p["body_d"], [(x0, 1), (x0 + 6, -3), ((x0 + x1) / 2, -4), (x1 - 6, -3), (x1, 1), (x1 - 10, 4.5), ((x0 + x1) / 2, 5.5), (x0 + 10, 4.5)]))
    pcs.append(Pc("massa", "corpo", p["body"], P["body"]))
    pcs.append(Pc("massa_sombra", "corpo", p["body_d"], P["shade"], cls="inner", op=0.7))
    for k, (top, L, w) in enumerate(P.get("drips", [])):
        pcs.append(drip(f"escorrido{k}", top, L, w))
    for k, (sp, w) in enumerate(P.get("pods", [])):
        pcs.append(Pc(f"pseudopode{k}", "corpo", p["body"], tube(sp, [x / 2 for x in w], cap0=0.4, cap1=0.9, per=4)))
    sx, sy, sa = P["skull"]
    pcs += skull(tmat(sx, sy, sa, 1.0))
    pcs += bubbles(P["bubbles"])
    pcs.append(highlight("brilho", P["hi"]))
    fx_, fy, fa, fs, op = P["face"]
    pcs += face(tmat(fx_, fy, fa), op, True, fs)
    if "bud" in P:
        B = P["bud"]
        pcs.append(Pc("broto", "broto", p["body"], B["body"]))
        pcs.append(Pc("broto_sombra", "broto", p["body_d"], B["shade"], cls="inner", op=0.7))
        pcs.append(highlight("broto_brilho", B["hi"], "broto"))
        bx, by, ba, bs, bo = B["face"]
        pcs += [Pc("broto_" + q.id, "broto", q.fill, pts=q.pts, cls=q.cls, closed=q.closed, sw=q.sw, mode=q.mode, op=q.op)
                for q in face(tmat(bx, by, ba), bo, True, bs)]
    for k, (c, r, a) in enumerate(P.get("drops", [])):
        pcs.append(drop(f"gota{k}", c, r, a, fig=f"gota{k}"))
    return pcs


POSES = {
    # parado / ameaça: domo largo, pseudópodes erguidos, boca aberta
    "ameaca": dict(
        body=[(-46, 0), (-47, -12), (-40, -30), (-26, -48), (-6, -58), (14, -56), (31, -45), (42, -28), (47, -11), (50, 0), (28, 3), (0, 4), (-26, 3)],
        shade=[(40, -26), (46, -10), (49, 0), (28, 3), (0, 4), (-26, 3), (-44, 1), (-10, -4), (24, -10)],
        pods=[([(36, -34), (52, -48), (58, -66), (52, -76)], [16, 11, 7, 4])],
        pods_back=[([(-34, -32), (-52, -42), (-62, -36)], [14, 9, 5])],
        puddle=(-62, 66), drips=[((54, -72), 7, 4)],
        skull=(-10, -18, -12), bubbles=[(18, -14, 2.4), (-26, -26, 1.8), (26, -30, 1.4), (-2, -6, 1.6)],
        hi=[(-30, -36), (-20, -48), (-6, -53), (-12, -46), (-24, -36)],
        face=(6, -38, -4, 1.0, 0.8)),
    # salto: gota esticada em diagonal, base arrastando, pseudópodes para a frente
    "saltar": dict(
        body=tube([(-56, 8), (-36, -6), (-12, -26), (12, -44), (30, -54)], [1.5, 7, 16, 26, 22], [1.5, 7, 15, 24, 22], cap0=0.3, cap1=1.0, per=3),
        shade=[(-50, 6), (-28, -4), (-4, -16), (22, -28), (40, -36), (44, -48), (30, -30), (6, -12), (-22, 2)],
        pods=[([(28, -40), (46, -38), (64, -46), (74, -56)], [14, 9, 6, 3]), ([(30, -64), (44, -78), (60, -84)], [12, 7, 3])],
        drips=[((-30, 0), 6, 4), ((-6, -12), 5, 4)],
        skull=(4, -34, -36), bubbles=[(-22, -6, 2), (22, -54, 1.6), (-38, 2, 1.4)],
        hi=[(0, -44), (12, -60), (28, -70), (20, -62), (6, -48)],
        drops=[((-68, 16), 3.2, 200), ((-62, 26), 2.4, 210), ((-50, 22), 2, 190)],
        face=(30, -52, -30, 0.95, 1.0)),
    # dividir: massa principal e o broto se separando por um fio de gosma (o instante da mecânica)
    "dividir": dict(
        body=[(-40, 0), (-44, -14), (-38, -32), (-22, -46), (-2, -50), (14, -44), (22, -36), (30, -38), (40, -42), (44, -36), (30, -28), (24, -18), (28, -6), (32, 0), (0, 4), (-24, 3)],
        shade=[(20, -14), (28, -4), (32, 0), (0, 4), (-24, 3), (-38, 1), (-6, -4)],
        pods_back=[([(-30, -28), (-48, -34), (-58, -26)], [12, 8, 4])],
        puddle=(-58, 44),
        skull=(-12, -18, -8), bubbles=[(10, -12, 2), (-28, -22, 1.6)],
        hi=[(-28, -30), (-18, -42), (-4, -46), (-10, -38), (-22, -30)],
        face=(-2, -30, -6, 0.9, 0.7),
        bud=dict(body=[(42, -40), (48, -54), (60, -64), (74, -66), (86, -58), (90, -44), (84, -32), (70, -26), (56, -28), (46, -34)],
                 shade=[(86, -44), (84, -32), (70, -26), (56, -28), (62, -34), (78, -38)],
                 hi=[(52, -50), (60, -60), (70, -62), (62, -56)],
                 face=(70, -48, 8, 0.62, 0.9))),
    # rastejar: onda baixa, frente erguida, base escorrendo para trás
    "rastejar": dict(
        body=[(-60, 2), (-58, -8), (-44, -16), (-26, -22), (-6, -32), (12, -44), (28, -48), (40, -40), (44, -24), (46, -6), (48, 2), (20, 4), (-20, 4)],
        shade=[(40, -24), (44, -6), (48, 2), (20, 4), (-20, 4), (-58, 3), (-20, -4), (20, -10)],
        pods=[([(38, -24), (54, -18), (66, -8), (70, 0)], [12, 8, 6, 4])],
        puddle=(-74, 60),
        skull=(-14, -12, 6), bubbles=[(-40, -6, 1.6), (6, -14, 2)],
        hi=[(-10, -28), (6, -40), (20, -44), (8, -36)],
        face=(24, -32, -10, 0.85, 0.5)),
}
GUIDE = {"ameaca": [(-40, 2), (-20, -30), (10, -54), (50, -70)],
         "saltar": [(-70, 18), (-30, -4), (10, -36), (50, -62), (80, -70)],
         "dividir": [(-40, 2), (-10, -30), (30, -40), (70, -50), (96, -58)],
         "rastejar": [(-62, 2), (-20, -12), (20, -40), (56, -14), (72, 0)]}


def pose(name):
    return slime(POSES[name])


def head_front(M):
    """Rosto de frente (ficha): massa em domo + rosto centrado."""
    pcs = [Pc("massa", "corpo", PAL["body"], [(-30, 18), (-32, 0), (-24, -18), (0, -26), (24, -18), (32, 0), (30, 18), (0, 22)])]
    pcs += face(T(0, -6), 0.8, True, 1.0)
    return [q.moved(M) for q in pcs]


_SIL = {}


def silhouette(name="ameaca"):
    if name not in _SIL:
        _SIL[name] = union_poly([q for q in pose(name) if q.fig == "corpo"], off=(120, 120))[0]
    return _SIL[name].copy()
