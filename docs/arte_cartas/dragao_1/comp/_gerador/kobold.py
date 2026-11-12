"""Ficha do kobold (vilão Dragão): reptiliano baixinho e curvado, focinho de lagarto, dois chifrinhos creme para trás,
escamas cor de ferrugem com barriga creme, lenço vermelho, colete de trapo, cauda grossa. Pernas digitígradas
(quadril→joelho→calcanhar alto→dedos). Perfil olhando para +x, chão em y=0.
Unidade: cabeça = 18 u. Altura ≈ 3,6 cabeças (65 u) curvado; coxa 12 / canela 12 / pé 7; braço 10 / antebraço 9.
data-fig: kobold_corpo (tronco, colete, lenço, braços, mãos, pernas, pés, cauda), kobold_cabeca (cabeça+chifres+mandíbula),
kobold_saco, kobold_picareta. Olho, narina, boca, dentes, escamas, listras = inner."""
import base  # noqa: F401
import math
import numpy as np
from geom import *
from piper import ik

INK = "#2b1a10"
PAL = dict(scale="#b8643a", scale_d="#8a4428", belly="#e8c890", horn="#f2e2c0", scarf="#c83a2a", vest="#6a4a30",
           sack="#c8a870", sack_d="#a88850", eye="#ffd23a", mouth="#5a1414", teeth="#f4ecd6", claw="#f2e2c0",
           pick="#8a6a44", iron="#8a8a92", gold="#e8b440")
L_TH, L_SH, L_UA, L_FA = 12.0, 12.0, 10.0, 9.0

HEAD = [(-7, -3), (-5.4, -8), (0, -9.6), (6, -7.8), (12, -5.6), (18, -4.6), (20.6, -2.8), (20.2, 0.4), (16, 1.8), (10, 3),
        (4, 6), (-2, 7), (-6, 4)]
HEAD_OPEN = [(-7, -3), (-5.4, -8), (0, -9.6), (6, -7.8), (12, -5.6), (18, -4.6), (20.6, -2.8), (20.2, 0.4), (16, 0.6),
             (10, 0.8), (4, 2.6), (-2, 7), (-6, 4)]
JAW = [(2, 3.4), (8, 2.6), (14, 4.6), (18, 7.6), (16.6, 9.6), (10, 8.6), (2, 8.4)]
HORN_N = [(-3, -8), (-8, -10.6), (-13, -14.4), (-15.4, -15.2), (-11, -10.4), (-6, -6.4)]
HORN_F = [(1, -9), (-3, -12.6), (-8, -17), (-10.4, -17.6), (-6, -12), (-1.4, -7.6)]
CREST = [(-6.4, -6), (-9.6, -4.4), (-8, -2.4), (-11.6, -0.4), (-9, 1.4), (-6, 2)]


def head(M, open_=False):
    p = PAL
    pcs = [Pc("chifre_longe", "cabeca", p["scale_d"], HORN_F)]
    if open_:
        pcs.append(Pc("mandibula", "cabeca", p["scale"], JAW))
        pcs.append(Pc("cabeca", "cabeca", p["scale"], HEAD_OPEN))
        pcs.append(Pc("boca", "cabeca", p["mouth"], [(19, 0.8), (14, 1), (8, 1.4), (4, 3), (4, 6.8), (10, 6.8), (15, 6.8)], cls="inner"))
        pcs.append(Pc("lingua", "cabeca", "#c8505a", [(6, 5), (14, 4.4), (22, 2.4), (25, 0.4), (23, 3.4), (26, 4.4), (21, 4.8), (14, 6)], cls="inner"))
        for i, x in enumerate((8, 11, 14, 17)):
            pcs.append(Pc(f"dente{i}", "cabeca", p["teeth"], [(x - 0.8, 1.1), (x + 0.8, 1), (x, 2.8)], cls="inner", mode="poly"))
    else:
        pcs.append(Pc("cabeca", "cabeca", p["scale"], HEAD))
        pcs.append(Pc("boca", "cabeca", INK, [(19, 0.8), (12, 2.6), (5, 4.4)], closed=False, cls="inner", sw=0.9))
        pcs.append(Pc("dente0", "cabeca", p["teeth"], [(15.6, 1.4), (17, 1.2), (16.4, 3.4)], cls="inner", mode="poly"))
    pcs += [Pc("crista", "cabeca", p["scale_d"], CREST), Pc("chifre", "cabeca", p["horn"], HORN_N),
            Pc("queixo_claro", "cabeca", p["belly"], [(-2, 5.4), (4, 4.6), (2, 7.2), (-3, 6.8)], cls="inner"),
            Pc("olho", "cabeca", p["eye"], ellipse(4, -3.8, 2.8, 2.2, -8, 9), cls="inner"),
            Pc("pupila", "cabeca", INK, [(4.4, -5.6), (4.6, -2)], closed=False, cls="inner", sw=0.9),
            Pc("sobrolho", "cabeca", INK, [(0.4, -6.6), (4, -7.4), (8, -6)], closed=False, cls="inner", sw=1.1),
            Pc("narina", "cabeca", INK, [(17.6, -3.4), (18.8, -3.6)], closed=False, cls="inner", sw=0.9),
            Pc("escamas", "cabeca", INK, [(8, -5.6), (10, -4.6), (12, -5)], closed=False, cls="inner", sw=0.5)]
    return [q.moved(M) for q in pcs]


def head_front(M):
    p = PAL
    H = [(-8, -2), (-6.6, -7.6), (0, -9.6), (6.6, -7.6), (8, -2), (6, 4), (4, 10), (0, 11.6), (-4, 10), (-6, 4)]
    HR = [(4, -8), (9, -10.6), (13, -14.4), (15.4, -15.2), (11, -10.4), (6.4, -6)]
    pcs = [Pc("chifre_l", "cabeca", p["horn"], [(-x, y) for x, y in HR]), Pc("chifre", "cabeca", p["horn"], HR),
           Pc("cabeca", "cabeca", p["scale"], H)]
    for s in (-1, 1):
        pcs.append(Pc("olho" + ("_l" if s < 0 else ""), "cabeca", p["eye"], ellipse(s * 4.6, -3.2, 2.4, 2.0, s * 10, 8), cls="inner"))
        pcs.append(Pc("pupila" + ("_l" if s < 0 else ""), "cabeca", INK, [(s * 4.6, -4.8), (s * 4.6, -1.6)], closed=False, cls="inner", sw=0.9))
        pcs.append(Pc("narina" + ("_l" if s < 0 else ""), "cabeca", INK, [(s * 1.4, 7.4), (s * 2.2, 7)], closed=False, cls="inner", sw=0.8))
    pcs.append(Pc("boca", "cabeca", INK, [(-3.6, 9.6), (0, 10.4), (3.6, 9.6)], closed=False, cls="inner", sw=0.8))
    pcs.append(Pc("focinho_claro", "cabeca", p["belly"], [(-2.6, 3), (2.6, 3), (3, 9), (0, 10), (-3, 9)], cls="inner"))
    return [q.moved(M) for q in pcs]


def pick(M):
    """Picareta: origem na empunhadura, cabo ao longo de -y (para cima), cabeça de ferro no fim."""
    p = PAL
    pcs = [Pc("cabo", "picareta", p["pick"], [(-1.3, 8), (1.3, 8), (1.3, -30), (-1.3, -30)], mode="poly"),
           Pc("ferro", "picareta", p["iron"], [(-1.6, -27), (-8, -27.6), (-16, -25.6), (-20, -22), (-14, -24.4), (-6, -25.2),
                                              (-1, -24.6), (1, -24.4), (8, -25.6), (15, -28.6), (19, -33), (14, -31), (8, -30.4), (1.6, -31)]),
           Pc("amarra", "picareta", p["scarf"], [(-1.8, -23), (1.8, -23), (1.8, -21), (-1.8, -21)], mode="poly", cls="inner")]
    return [q.moved(M) for q in pcs]


def sack(M):
    p = PAL
    pcs = [Pc("saco", "saco", p["sack"], [(-12, -2), (-11, -10), (-4, -14.6), (4, -14), (11, -8), (12, 0), (8, 7), (0, 9), (-8, 7)]),
           Pc("boca_saco", "saco", p["sack_d"], [(8, -11), (12, -15), (16, -13), (13, -9)]),
           Pc("remendo", "saco", p["sack_d"], [(-6, -2), (-1, -3), (0, 2), (-5, 3)], cls="inner", mode="poly"),
           Pc("moeda", "saco", p["gold"], ellipse(14.6, -16.4, 2, 2, 0, 8), cls="inner"),
           Pc("dobra", "saco", INK, [(-2, -12), (2, -4), (2, 4)], closed=False, cls="inner", sw=0.6)]
    return [q.moved(M) for q in pcs]


def kobold(J):
    p = PAL; pcs = []
    hip, nk = A(J["hip"]), A(J["neck"])
    up = (nk - hip) / np.linalg.norm(nk - hip); fwd = np.array([-up[1], up[0]])
    if J.get("sack_back"):
        pcs += sack(tmat(*(nk - fwd * 9 + up * 0), J.get("sack_rot", -20), 1.0))
    # cauda grossa
    tl = [hip + fwd * 1 - up * 1] + [A(q) for q in J["tail"]]
    pcs.append(Pc("cauda", "corpo", p["scale_d"], tube(tl, [5.4, 4.4, 3.2, 2, 1][:len(tl)], cap0=0.3, cap1=0.8, per=4)))

    def leg(tag, fill):
        hp = hip + fwd * (1.5 if tag == "n" else -1.5)
        an, to = A(J["a" + tag]), A(J["t" + tag])
        kn, an = ik(hp, an, L_TH, L_SH, J.get("kb" + tag, -1))
        out = [Pc("perna_" + tag, "corpo", fill, tube([hp, kn, an], [4.8, 2.8, 2.0], cap0=0.4, cap1=0.4, per=4))]
        out.append(Pc("pe_" + tag, "corpo", fill, brush([an, to], 3.4, 2.4, per=2)))
        d = to - an; d = d / np.linalg.norm(d); n = np.array([-d[1], d[0]])
        for k in range(3):
            b = to + n * (k - 1) * 1.2
            out.append(Pc(f"pe_{tag}_garra{k}", "corpo", p["claw"], brush([b, b + d * 2.8 + n * (k - 1) * 0.6], 1.3, 0.1, per=2)))
        return out

    def arm(tag, fill):
        sh = nk - up * 2.4 + fwd * (2 if tag == "n" else -2)
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        out = [Pc("braco_" + tag, "corpo", fill, tube([sh, el, wr], [2.8, 2.1, 1.8], cap0=0.5, cap1=0.3, per=4))]
        d = wr - el; d = d / np.linalg.norm(d); n = np.array([-d[1], d[0]])
        out.append(Pc("mao_" + tag, "corpo", fill, ellipse(*(wr + d * 1.6), 2.8, 2.2, math.degrees(math.atan2(d[1], d[0])), 8)))
        for k in range(3):
            b = wr + d * 3.4 + n * (k - 1) * 1.2
            out.append(Pc(f"mao_{tag}_garra{k}", "corpo", p["claw"], brush([b, b + d * 2.6 + n * (k - 1) * 0.8], 1.2, 0.1, per=2)))
        return out, wr, el

    pcs += leg("f", p["scale_d"])
    fa, fwr, fel = arm("f", p["scale_d"])
    pcs += fa
    belly = hip + up * 8 + fwd * 5
    pcs.append(Pc("tronco", "corpo", p["scale"], [hip - fwd * 5.4 - up * 1, hip + fwd * 4 - up * 1.6, belly, belly + up * 6 - fwd * 0.6,
                                                nk + fwd * 4, nk + up * 2, nk - fwd * 4.6 + up * 0.4, hip - fwd * 6.6 + up * 9]))
    pcs.append(Pc("barriga", "corpo", p["belly"], [hip + fwd * 2.6 - up * 1, belly - fwd * 0.6, belly + up * 6 - fwd * 1.4,
                                                 nk + fwd * 2.8 - up * 1, nk + fwd * 1 - up * 3, hip + fwd * 0.6 + up * 6], cls="inner"))
    for i in range(3):
        a0 = hip + up * (4 + i * 4.4) + fwd * 1.4; a1 = a0 + fwd * 3.4
        pcs.append(Pc(f"listra{i}", "corpo", INK, [a0, a1], closed=False, cls="inner", sw=0.5))
    pcs.append(Pc("colete", "corpo", p["vest"], [nk - fwd * 4.6 - up * 1.4, nk + fwd * 0.4 - up * 2, hip + up * 6, hip - fwd * 2 - up * 0.4,
                                               hip - fwd * 6.4 + up * 0.6, hip - fwd * 6.8 + up * 9]))
    pcs.append(Pc("lenco", "corpo", p["scarf"], [nk - fwd * 4.4 - up * 1, nk + fwd * 3.8 - up * 1.4, nk + fwd * 4 + up * 1.6,
                                               nk - fwd * 4.8 + up * 1.6, nk - fwd * 8 - up * 2.4, nk - fwd * 9.6 - up * 6, nk - fwd * 6 - up * 3.4]))
    pcs += leg("n", p["scale"])
    na, nwr, nel = arm("n", p["scale"])
    hx, hy, ha = J["head"]
    pcs += head(tmat(hx, hy, ha, J.get("hk", 1.0)), J.get("open", False))
    if J.get("pick"):
        gx, gy, ga = J["pick"]
        pcs += pick(tmat(gx, gy, ga))
    pcs += na
    if J.get("sack_hand"):
        pcs += sack(tmat(*(A(nwr) + A(J["sack_hand"][:2])), J["sack_hand"][2], 0.8))
    return pcs


POSES = {
    # corrida com o saco: tronco baixo à frente, saco nas costas preso pela mão de perto no ombro
    "correr": dict(hip=(0, -25), neck=(13, -39), head=(21, -47, 12), an=(13, -7), tn=(20, 0), kbn=-1, af=(-15, -7), tf=(-10, 0),
                   kbf=-1, wn=(8, -46), ebn=-1, wf=(22, -28), ebf=-1, sack_back=True, sack_rot=-30,
                   tail=[(-10, -24), (-22, -20), (-32, -13), (-40, -8)]),
    # golpe de picareta: as duas mãos no alto atrás da cabeça, passo largo
    "atacar": dict(hip=(0, -23), neck=(5, -41), head=(12, -49, -4), open=True, an=(16, -7), tn=(22, 0), kbn=-1, af=(-15, -7),
                   tf=(-10, 0), kbf=-1, wn=(-4, -58), ebn=-1, wf=(0, -56), ebf=-1, pick=(-2, -57, -60),
                   tail=[(-10, -22), (-22, -18), (-32, -10), (-40, -2)]),
    # salto: mergulho no tesouro, corpo em diagonal descendo, cauda de leme
    "saltar": dict(hip=(0, -42), neck=(15, -33), head=(23, -27, 34), open=True, an=(-14, -48), tn=(-21, -52), kbn=1,
                   af=(-12, -42), tf=(-19, -44), kbf=1, wn=(31, -22), ebn=-1, wf=(29, -18), ebf=-1,
                   tail=[(-8, -46), (-20, -54), (-32, -58), (-42, -56)]),
    # ameaça: agachado, cabeça erguida sibilando, picareta atravessada em guarda
    "ameaca": dict(hip=(0, -18), neck=(9, -33), head=(16, -41, -16), open=True, an=(12, -6), tn=(19, 0), kbn=-1, af=(-9, -6),
                   tf=(-3, 0), kbf=-1, wn=(17, -27), ebn=-1, wf=(8, -21), ebf=-1, pick=(15, -25, 78),
                   tail=[(-8, -15), (-20, -8), (-31, -4), (-38, -10)]),
}
GUIDE = {"correr": [(-10, 0), (-2, -20), (13, -39), (24, -48), (32, -50)],
         "atacar": [(22, 0), (6, -22), (5, -41), (-6, -60), (-20, -80)],
         "saltar": [(-42, -56), (-16, -48), (0, -42), (16, -32), (30, -22)],
         "ameaca": [(-3, 0), (-2, -16), (9, -33), (15, -44), (14, -54)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return kobold(J)
