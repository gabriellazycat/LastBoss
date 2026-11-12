"""Ficha do diabrete de fogo (fire_imp): pequeno demônio voador laranja-brasa, barriga amarela, asas de morcego bordô,
chifrinhos creme varridos para trás, orelha pontuda, crista de chama entre os chifres, cauda longa com ponta de seta em brasa.
3/4 olhando para +x. Origem = quadril. Unidade: cabeça = 16 u; tronco (quadril→pescoço) = 14 u; braço 8 / antebraço 7;
coxa 8 / canela 8 / pé 4; cauda ≈ 60 u. Envergadura ≈ 6 cabeças.
data-fig: diabrete_corpo (tronco, braços, mãos, pernas, pés, cauda), diabrete_cabeca (cabeça+chifres+orelha+crista),
diabrete_asa_l (longe), diabrete_asa_r (perto), diabrete_fogo (bola de fogo na mão, quando houver)."""
import base  # noqa: F401
import math
import numpy as np
from geom import *
from piper import ik
from wings import wing

INK = "#2b1a10"
PAL = dict(skin="#f07a2a", skin_d="#c8501e", belly="#ffd25a", wing="#8a2a22", wing_d="#6a1c18", bone="#4a140e",
           horn="#f2e2c0", eye="#fff07a", pupil="#2b1a10", mouth="#5a1010", teeth="#fff4dc", claw="#f2e2c0",
           flame="#ffb030", flame_c="#fff2a0")
L_UA, L_FA, L_TH, L_SH = 8.0, 7.0, 8.0, 8.0

HEAD = [(-7, -2), (-6, -6.6), (-1.5, -8.8), (4.6, -7.8), (8, -3.6), (8.8, 1), (7, 5.2), (3, 9.6), (0.6, 9.2), (-3.6, 6.6), (-6.6, 3)]
HORN_N = [(-3, -7.4), (-7, -11), (-12, -13.4), (-15, -18), (-11, -15.6), (-6.4, -13.6), (-1, -9.4)]
HORN_F = [(2.6, -8.4), (0.4, -12.6), (-2.4, -17), (-3.6, -21), (0.6, -16.8), (4.4, -12.6), (5.4, -8)]
EAR = [(-5.4, -1.4), (-10, -3.4), (-16, -3), (-11, 0.6), (-6, 2.4)]
CREST = [(-3, -8.4), (-4, -13), (-1.6, -11.6), (-0.4, -17.4), (1.6, -12), (3.4, -14), (3.2, -8.4)]


def head(M, open_=True):
    p = PAL
    pcs = [Pc("chifre_longe", "cabeca", p["horn"], HORN_F), Pc("crista", "cabeca", p["flame"], CREST),
           Pc("cabeca", "cabeca", p["skin"], HEAD), Pc("chifre", "cabeca", p["horn"], HORN_N), Pc("orelha", "cabeca", p["skin"], EAR),
           Pc("crista_centro", "cabeca", p["flame_c"], [(-1.6, -9), (-0.6, -14), (1, -9.4)], cls="inner"),
           Pc("orelha_dentro", "cabeca", p["skin_d"], [(-7, -0.6), (-11, -1.8), (-13.6, -1.6), (-10, 0.4)], cls="inner"),
           Pc("olho", "cabeca", p["eye"], [(1, -3.6), (4.6, -5.4), (6, -3.4), (2.6, -1.8)], cls="inner"),
           Pc("olho_longe", "cabeca", p["eye"], [(6.8, -4.2), (8.4, -5), (8.6, -3.2), (7.2, -2.6)], cls="inner"),
           Pc("pupila", "cabeca", INK, [(3.8, -4.6), (4.4, -2.4)], closed=False, cls="inner", sw=0.8),
           Pc("sobrancelha", "cabeca", INK, [(0, -5), (3.4, -6.8), (7, -6.4)], closed=False, cls="inner", sw=1.1)]
    if open_:
        pcs.append(Pc("boca", "cabeca", p["mouth"], [(0.4, 2), (4.6, 2.6), (8.2, 1.2), (6.4, 5.6), (3, 6.8), (0.6, 4.6)], cls="inner"))
        for i, (x, y) in enumerate([(2.2, 2.3), (6.6, 2)]):
            pcs.append(Pc(f"presa{i}", "cabeca", p["teeth"], [(x - 0.8, y), (x + 0.8, y), (x, y + 2.4)], cls="inner", mode="poly"))
    else:
        pcs.append(Pc("boca", "cabeca", INK, [(0.4, 2.6), (4.6, 3.6), (8.2, 1.4)], closed=False, cls="inner", sw=0.9))
    return [q.moved(M) for q in pcs]


def head_front(M):
    p = PAL
    H = [(-7.6, -2), (-6.6, -6.8), (0, -9), (6.6, -6.8), (7.6, -2), (6.6, 3.6), (3, 8), (0, 10), (-3, 8), (-6.6, 3.6)]
    HR = [(3, -7.4), (7, -11), (11, -13.4), (13, -18), (10, -15.6), (6, -13.6), (1.6, -9.4)]
    E = [(6.6, -1.6), (12, -4), (16, -3), (11.4, 1), (6.4, 2.4)]
    pcs = [Pc("chifre_l", "cabeca", p["horn"], [(-x, y) for x, y in HR]), Pc("chifre", "cabeca", p["horn"], HR),
           Pc("crista", "cabeca", p["flame"], [(-3, -8), (-3.4, -13), (-1, -11.6), (0, -18), (1.4, -11.6), (3.4, -13), (3, -8)]),
           Pc("orelha_l", "cabeca", p["skin"], [(-x, y) for x, y in E]), Pc("orelha", "cabeca", p["skin"], E),
           Pc("cabeca", "cabeca", p["skin"], H)]
    for s in (-1, 1):
        pcs.append(Pc("olho" + ("_l" if s < 0 else ""), "cabeca", p["eye"], [(s * 1.2, -3), (s * 5.4, -4.6), (s * 5.2, -2), (s * 2, -1.4)], cls="inner"))
        pcs.append(Pc("sobrancelha" + ("_l" if s < 0 else ""), "cabeca", INK, [(s * 0.8, -4.2), (s * 3.6, -5.8), (s * 6.4, -5.4)], closed=False, cls="inner", sw=1.0))
    pcs.append(Pc("boca", "cabeca", p["mouth"], [(-5, 2.6), (0, 3.6), (5, 2.6), (3, 6.4), (0, 7.2), (-3, 6.4)], cls="inner"))
    for x in (-2.6, 2.6):
        pcs.append(Pc(f"presa{x}", "cabeca", p["teeth"], [(x - 0.8, 3.1), (x + 0.8, 3.1), (x, 5.6)], cls="inner", mode="poly"))
    return [q.moved(M) for q in pcs]


def claws(name, wr, d_deg, fill, n=3, L=3.4, spread=40):
    pcs = []
    w = A(wr)
    for k in range(n):
        a = math.radians(d_deg + (k - (n - 1) / 2) * spread / (n - 1))
        tip = w + np.array([math.cos(a), math.sin(a)]) * L
        pcs.append(Pc(f"{name}_garra{k}", "corpo", fill, brush([w, tip], 1.5, 0.15, per=2)))
    return pcs


def fireball(M, r=6.0):
    p = PAL
    pcs = [Pc("fogo", "fogo", p["flame"], [(-r, 0), (-r * 0.8, -r * 0.9), (-r * 0.3, -r * 1.6), (0, -r * 2.4), (r * 0.3, -r * 1.4),
                                          (r * 0.8, -r * 1.3), (r * 0.9, -r * 0.4), (r, 0.3), (r * 0.6, r * 0.9), (0, r), (-r * 0.6, r * 0.9)]),
           Pc("fogo_centro", "fogo", p["flame_c"], ellipse(0, 0, r * 0.55, r * 0.5, 0, 8), cls="inner")]
    return [q.moved(M) for q in pcs]


def imp(J):
    p = PAL; pcs = []
    hip, nk = A(J["hip"]), A(J["neck"])
    up = (nk - hip) / np.linalg.norm(nk - hip)
    fwd = np.array([-up[1], up[0]])  # para +x quando de pé (up = (0,-1) -> fwd = (1,0))
    S = nk - up * 3.5 - fwd * 1.5
    wf = J["WF"]; wn = J["WN"]
    pcs += wing("asa_l", S + fwd * 1.5, wf[0], wf[1], wf[2:5], wf[5], p["wing_d"], p["bone"], p["claw"], arm_w=(3.4, 2), thumb=3.2, arm_fill=p["skin_d"], finger_w=0.8)
    # cauda
    tl = [hip - fwd * 2] + [A(q) for q in J["tail"]]
    pcs.append(Pc("cauda", "corpo", p["skin_d"], tube(tl, [2.4, 1.8, 1.3, 1.0, 0.8, 0.7][:len(tl)], cap0=0.3, cap1=0.3, per=4)))
    a, b = A(tl[-2]), A(tl[-1]); d = (b - a) / np.linalg.norm(b - a); n = np.array([-d[1], d[0]])
    pcs.append(Pc("cauda_ponta", "corpo", p["skin_d"], [b - d * 1.0, b + n * 3.4 - d * 1.6, b + d * 5.4, b - n * 3.4 - d * 1.6], mode="poly"))
    pcs.append(Pc("cauda_chama", "corpo", p["flame"], [b + d * 4.4, b + d * 7 + n * 2, b + d * 10.6 + n * 0.6, b + d * 8.6, b + d * 9.6 - n * 2.4], cls="inner"))

    def leg(tag, fill):
        hp = hip + fwd * (1.2 if tag == "n" else -1.2)
        kn, an = ik(hp, J["a" + tag], L_TH, L_SH, J.get("kb" + tag, -1))
        out = [Pc("perna_" + tag, "corpo", fill, tube([hp, kn, an], [2.8, 1.8, 1.3], cap0=0.4, cap1=0.4, per=4))]
        t = A(J["t" + tag]); dd = t - an
        out.append(Pc("pe_" + tag, "corpo", fill, brush([an, t], 2.6, 1.2, per=2)))
        out += claws("pe_" + tag, t, math.degrees(math.atan2(dd[1], dd[0])), p["claw"], L=2.6, spread=50)
        return out

    def arm(tag, fill):
        sh = nk - up * 1.8 + fwd * (1.4 if tag == "n" else -1.0)
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        out = [Pc("braco_" + tag, "corpo", fill, tube([sh, el, wr], [2.2, 1.6, 1.4], cap0=0.5, cap1=0.3, per=4))]
        dd = wr - el
        out.append(Pc("mao_" + tag, "corpo", fill, ellipse(wr[0], wr[1], 2.2, 1.8, math.degrees(math.atan2(dd[1], dd[0])), 7)))
        out += claws("mao_" + tag, wr + dd / np.linalg.norm(dd) * 1.6, J.get("hd" + tag, math.degrees(math.atan2(dd[1], dd[0]))), p["claw"], L=3.4, spread=J.get("sp" + tag, 50))
        return out, wr

    pcs += leg("f", p["skin_d"])
    fa, fwr = arm("f", p["skin_d"])
    pcs += fa
    belly = hip + up * 5 + fwd * 3.6
    pcs.append(Pc("tronco", "corpo", p["skin"], [hip - fwd * 3.4 - up * 1, hip + fwd * 2.6 - up * 1.6, belly, belly + up * 4,
                                               nk + fwd * 2.6, nk + up * 1, nk - fwd * 3, hip - fwd * 4.4 + up * 6]))
    pcs.append(Pc("barriga", "corpo", p["belly"], [hip + fwd * 1.4 - up * 0.8, belly + fwd * -0.2, belly + up * 4 - fwd * 0.6, nk + fwd * 1.6 - up * 1.2,
                                                 nk - up * 2.4, hip + up * 3], cls="inner"))
    pcs += leg("n", p["skin"])
    na, nwr = arm("n", p["skin"])
    hx, hy, ha = J["head"]
    pcs += head(tmat(hx, hy, ha, J.get("hk", 1.0)), J.get("open", True))
    pcs += na
    if J.get("ball"):
        pcs += fireball(tmat(*(A(nwr) + A(J["ball"][:2])), 0, J["ball"][2]))
    near = wing("asa_r", S - fwd * 0.5, wn[0], wn[1], wn[2:5], wn[5], p["wing"], p["bone"], p["claw"], arm_w=(3.6, 2.2), thumb=3.4, arm_fill=p["skin"], finger_w=0.9)
    if J.get("near_back"):  # asa de perto atrás do corpo (mergulho: o corpo fica visível)
        k = len(wing("asa_l", S + fwd * 1.5, wf[0], wf[1], wf[2:5], wf[5], p["wing_d"], p["bone"], p["claw"]))
        return pcs[:k] + near + pcs[k:]
    return pcs + near


POSES = {
    # mergulho: diagonal descendo para a direita, garras à frente, asas varridas para trás, cauda chicoteando
    "mergulho": dict(hip=(0, 0), neck=(10.5, 7.5), head=(17.5, 10.5, 28), wn=(19, 21), wf=(14, 22), ebn=-1, ebf=-1, hdn=60, hdf=75, near_back=True,
                     an=(-11, -4), tn=(-14, -8), af=(-9, -9), tf=(-13, -13), kbn=1, kbf=1,
                     tail=[(-10, -4), (-22, -4), (-32, -12), (-38, -24), (-36, -34)],
                     WN=[(-2, -10), (-14, -18), (-40, -26), (-38, -12), (-28, -2), (-4, 3)],
                     WF=[(4, -12), (-6, -24), (-28, -40), (-34, -28), (-28, -16), (0, -2)]),
    # voar: corpo quase de pé, asas erguidas (batida para cima), pernas soltas
    "voar": dict(hip=(0, 0), neck=(3.5, -14), head=(6, -22, 6), wn=(11, -5), wf=(9, -4), ebn=1, ebf=1, hdn=30, hdf=40,
                 an=(3, 14), tn=(6, 17), af=(-3, 13), tf=(0, 17), kbn=-1, kbf=-1,
                 tail=[(-8, 6), (-18, 4), (-28, 10), (-32, 20), (-28, 28)],
                 WN=[(-8, -24), (-6, -38), (-26, -48), (-32, -34), (-28, -20), (-4, -4)],
                 WF=[(6, -26), (14, -40), (30, -50), (34, -36), (26, -22), (4, -6)]),
    # atacar: bola de fogo erguida atrás da cabeça, asas abertas, braço de longe aponta
    "atacar": dict(hip=(0, 0), neck=(-1.5, -14), head=(1, -22, -6), wn=(-13, -27), wf=(13, -13), ebn=1, ebf=-1, hdn=-100, hdf=-10, spf=60,
                   an=(9, 9), tn=(12, 12), af=(3, 12), tf=(6, 15), kbn=-1, kbf=-1, ball=(-4, -6, 1.1),
                   tail=[(-8, 4), (-18, 10), (-26, 6), (-30, -4), (-24, -12)],
                   WN=[(-12, -18), (-22, -28), (-44, -26), (-42, -10), (-30, 0), (-4, -3)],
                   WF=[(6, -22), (14, -34), (34, -38), (36, -24), (26, -12), (3, -6)]),
    # ameaça: pairando em C, as duas garras abertas para a frente, cabeça avançada
    "ameaca": dict(hip=(0, 0), neck=(6, -12), head=(12.5, -18.5, 14), wn=(18, -9), wf=(17, -4), ebn=-1, ebf=-1, hdn=-10, hdf=0, spn=70, spf=70,
                   an=(7, 8), tn=(10, 11), af=(1, 10), tf=(4, 13), kbn=-1, kbf=-1,
                   tail=[(-8, 6), (-16, 14), (-26, 14), (-32, 6), (-30, -4)],
                   WN=[(-8, -20), (-15, -32), (-36, -34), (-38, -20), (-28, -8), (-3, -4)],
                   WF=[(2, -22), (8, -36), (24, -44), (28, -30), (20, -18), (3, -8)]),
}
GUIDE = {"mergulho": [(-36, -34), (-24, -10), (0, 0), (14, 12), (30, 26)],
         "voar": [(0, 18), (0, 0), (4, -14), (7, -28)],
         "atacar": [(6, 15), (3, 0), (-1, -14), (-6, -30), (-10, -40)],
         "ameaca": [(-30, -4), (-20, 14), (0, 0), (10, -14), (20, -18)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    # wn/wf: alvos dos pulsos (tuplas de 2) vs. asas (listas de 6) — separados aqui
    return imp(J)
