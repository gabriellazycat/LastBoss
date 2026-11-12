"""Ficha do Dragão Ancião (vilão Dragão). Identidade: artDragon da v2 e tracos/blender/elder_dragon.png — dragão vermelho,
chifres creme longos varridos para trás, espinhos da face em leque, placas douradas na barriga e sob o pescoço, olhos amarelos
de sobrolho bravo, boca em brasa; asas de membrana vermelha com varetas escuras; cauda com espinhos dourados e ponta de seta.
Unidade: cabeça = 30 u (nuca→focinho). Tronco (quadril→peito) ≈ 3 cabeças; pescoço ≈ 2,5 em S; cauda ≈ 6; envergadura ≈ 12.
Poses em 3/4 ou perfil (nunca de frente parado). Coordenadas absolutas da pose; +x = para onde a cabeça aponta.
data-fig: dragao_corpo (tronco, pescoço, cauda, patas, espinhos), dragao_cabeca (crânio, chifres, mandíbula, espinhos da face),
dragao_asa_l (asa de longe), dragao_asa_r (asa de perto). Placas, olhos, dentes, boca, varetas = inner."""
import base  # noqa: F401
import math
import numpy as np
from geom import *
from wings import wing

INK = "#2b1a10"
PAL = dict(body="#7a1c18", body_d="#5e1610", body_l="#9a2c1a", plate="#d9a04a", plate_d="#b07c34", horn="#f2e2c0",
           horn_d="#c8b088", wing="#8a2418", wing_d="#5a1410", bone="#3e0e0a", eye="#ffe24a", mouth="#ffb040",
           mouth_c="#fff2a0", fire="#ffd84a", claw="#f2e2c0", spike="#d8a04a", brow="#4a120c")

# ---------------------------------------------------------------- cabeça de perfil (origem = nuca; focinho em +x)
UP_CLOSED = [(-4, -6), (0, -11), (8, -12.6), (14, -11.4), (18, -8.4), (26, -7.2), (32, -6.4), (35, -4.6), (35.6, -1.4),
             (33, 0.8), (26, 1.8), (18, 3.2), (10, 6), (2, 8), (-4, 5)]
UP_OPEN = [(-4, -6), (0, -11), (8, -12.6), (14, -11.4), (18, -8.4), (26, -7.2), (32, -6.4), (35, -4.6), (35.6, -1.4),
           (33, 0), (26, -0.2), (18, 0.4), (10, 2), (4, 4.6), (-4, 5)]
JAW = [(2, 3), (10, 2.4), (20, 1.6), (29, 1.2), (31, 2.8), (27, 5.4), (18, 7.4), (8, 9), (0, 8.4)]
HINGE = (3, 4)
HORN = [(6, -10), (-2, -15), (-11, -19.6), (-19, -24.6), (-26, -31), (-29.6, -38), (-21, -29), (-12, -22.4), (-4, -15.4), (-3, -5)]
SPIKES = [[(-2, 2), (-12, 1), (-3, -1.6)], [(-3, -2.6), (-13, -6), (-3.6, -5.6)], [(0, 6), (-9, 9), (-1, 8.4)]]


def head(M, open_=0.0, far_horn=True, glow=True):
    p = PAL; pcs = []
    if far_horn:
        pcs.append(Pc("chifre_longe", "cabeca", p["horn_d"], [(x + 7, y - 2) for x, y in HORN]))
    for i, s in enumerate(SPIKES):
        pcs.append(Pc(f"espinho_face{i}", "cabeca", p["body_d"], s, mode="poly"))
    if open_ > 0:
        Mj = chain(T(*HINGE), R(open_), T(-HINGE[0], -HINGE[1]))
        jaw = list(ap(Mj, JAW))
        pcs.append(Pc("mandibula", "cabeca", p["body_l"], jaw))
        pcs.append(Pc("cranio", "cabeca", p["body"], UP_OPEN))
        jt = list(ap(Mj, [(29, 1.2), (20, 1.6), (10, 2.4), (4, 3.4)]))
        mouth = [(34, 0.2), (26, -0.2), (18, 0.4), (10, 2), (4, 4.4)] + jt[::-1]
        pcs.append(Pc("boca", "cabeca", p["mouth"], mouth, cls="inner"))
        if glow:
            c = (A(mouth[2]) + A(jt[1])) / 2
            pcs.append(Pc("boca_brasa", "cabeca", p["mouth_c"], ellipse(c[0], c[1], 5, 2.6, open_ * 0.5, 8), cls="inner"))
        for i, x in enumerate((31, 26.5, 22, 17)):
            pcs.append(Pc(f"dente{i}", "cabeca", p["claw"], [(x - 1, 0.1), (x + 1, 0.1), (x, 3.4 - (i % 2))], cls="inner", mode="poly"))
        for i, (x, y) in enumerate([(27, 1.3), (22, 1.6), (15, 2.1)]):
            q = list(ap(Mj, [(x - 1, y), (x + 1, y), (x, y - 3.2 + (i % 2))]))
            pcs.append(Pc(f"dente_b{i}", "cabeca", p["claw"], q, cls="inner", mode="poly"))
    else:
        pcs.append(Pc("cranio", "cabeca", p["body"], UP_CLOSED))
        pcs.append(Pc("boca", "cabeca", INK, [(34, 0.4), (24, 2), (14, 4.2), (6, 6.8)], closed=False, cls="inner", sw=0.9))
        pcs.append(Pc("dente0", "cabeca", p["claw"], [(27.4, 1.4), (29, 1.2), (28.4, 4.4)], cls="inner", mode="poly"))
    pcs.append(Pc("chifre", "cabeca", p["horn"], HORN))
    pcs.append(Pc("chifre_aneis", "cabeca", INK, [(-10, -16.4), (-12, -19.6)], closed=False, cls="inner", sw=0.6))
    pcs.append(Pc("chifre_aneis2", "cabeca", INK, [(-18, -21), (-20, -24.6)], closed=False, cls="inner", sw=0.6))
    pcs.append(Pc("sobrolho", "cabeca", p["brow"], [(9, -9.6), (14, -11.8), (21, -9.2), (20, -7.4), (14, -8.8), (10, -7.6)], cls="inner"))
    pcs.append(Pc("olho", "cabeca", p["eye"], [(12, -7.4), (16.4, -8.4), (19.6, -7), (15.6, -5.6)], cls="inner"))
    pcs.append(Pc("pupila", "cabeca", INK, [(16, -8.2), (15.8, -5.8)], closed=False, cls="inner", sw=0.9))
    pcs.append(Pc("narina", "cabeca", INK, [(32, -4.6), (34, -4.2)], closed=False, cls="inner", sw=1.0))
    pcs.append(Pc("escama_focinho", "cabeca", INK, [(22, -6.6), (25, -5.4), (28, -5.8)], closed=False, cls="inner", sw=0.6))
    return [q.moved(M) for q in pcs]


def head34(M, open_=True):
    """Cabeça 3/4 de frente (para cartas de câmera baixa): origem no centro do crânio, focinho para baixo; lado de longe comprimido."""
    p = PAL
    def sq(pts):  # comprime o lado esquerdo (longe)
        return [(x * (0.78 if x < 0 else 1.0) + 3, y) for x, y in pts]
    HR = [(10, -10), (18, -22), (24, -36), (25, -48), (30, -36), (27, -20), (18, -6)]
    pcs = [Pc("chifre_l", "cabeca", p["horn_d"], sq([(-x, y) for x, y in HR])), Pc("chifre", "cabeca", p["horn"], sq(HR))]
    for s in (-1, 1):
        for k, (a, b, c) in enumerate([((20, -2), (34, -8), (21, -6)), ((19, 4), (32, 4), (19, 8)), ((16, 10), (26, 16), (14, 14))]):
            pcs.append(Pc(f"espinho{'_l' if s < 0 else ''}{k}", "cabeca", p["body_d"], sq([(s * a[0], a[1]), (s * b[0], b[1]), (s * c[0], c[1])]), mode="poly"))
    pcs.append(Pc("cranio", "cabeca", p["body"], sq([(-20, -4), (-18, -14), (-8, -20), (0, -21), (8, -20), (18, -14), (20, -4), (18, 8),
                                                   (12, 14), (-12, 14), (-18, 8)])))
    if open_:
        pcs.append(Pc("mandibula", "cabeca", p["body_l"], sq([(-12, 22), (12, 22), (14, 34), (8, 42), (0, 44), (-8, 42), (-14, 34)])))
        pcs.append(Pc("boca", "cabeca", p["mouth"], sq([(-10, 24), (10, 24), (10, 34), (0, 39), (-10, 34)]), cls="inner"))
        pcs.append(Pc("boca_brasa", "cabeca", p["mouth_c"], sq(ellipse(0, 31, 6, 4, 0, 8)), cls="inner"))
    pcs.append(Pc("focinho", "cabeca", p["body_l"], sq([(-13, 10), (13, 10), (14, 22), (8, 26), (-8, 26), (-14, 22)])))
    for s in (-1, 1):
        pcs.append(Pc("sobrolho" + ("_l" if s < 0 else ""), "cabeca", p["brow"], sq([(s * 3, -7), (s * 16, -11), (s * 18, -8), (s * 5, -4)]), cls="inner"))
        pcs.append(Pc("olho" + ("_l" if s < 0 else ""), "cabeca", p["eye"], sq([(s * 6, -4), (s * 15, -7), (s * 15, -4), (s * 8, -2)]), cls="inner"))
        pcs.append(Pc("narina" + ("_l" if s < 0 else ""), "cabeca", INK, sq([(s * 4, 20), (s * 6, 18)]), closed=False, cls="inner", sw=1.0))
    if open_:
        for s in (-1, 1):
            for k, x in enumerate((3, 7)):
                pcs.append(Pc(f"dente{s}{k}", "cabeca", p["claw"], sq([(s * x - 1.2, 25), (s * x + 1.2, 25), (s * x, 30)]), cls="inner", mode="poly"))
    return [q.moved(M) for q in pcs]


# ---------------------------------------------------------------- membros
def claws(name, at, d_deg, n, L, w, spread):
    out = []
    for k in range(n):
        a = math.radians(d_deg + (k - (n - 1) / 2) * spread / max(1, n - 1))
        b = A(at); tip = b + np.array([math.cos(a), math.sin(a)]) * L
        mid = (b + tip) / 2 + np.array([-math.sin(a), math.cos(a)]) * L * 0.12
        out.append(Pc(f"{name}_garra{k}", "corpo", PAL["claw"], brush([b, mid, tip], w, 0.2, per=2)))
    return out


def front_leg(name, J3, fill, cdir=None, k=1.0):
    sh, el, wr = (A(q) for q in J3)
    pcs = [Pc(name, "corpo", fill, tube([sh, el, wr], [7 * k, 5 * k, 3.6 * k], cap0=0.5, cap1=0.5, per=4))]
    d = wr - el; d = d / np.linalg.norm(d)
    cd = math.degrees(math.atan2(d[1], d[0])) if cdir is None else cdir
    pcs.append(Pc(name + "_mao", "corpo", fill, ellipse(*(wr + d * 2.4 * k), 5 * k, 4 * k, cd, 8)))
    pcs += claws(name, wr + np.array([math.cos(math.radians(cd)), math.sin(math.radians(cd))]) * 5.6 * k, cd, 4, 8 * k, 2.8 * k, 70)
    return pcs


def hind_leg(name, J4, fill, k=1.0):
    hp, kn, an, to = (A(q) for q in J4)
    pcs = [Pc(name, "corpo", fill, tube([hp, kn, an], [12 * k, 7 * k, 4.2 * k], cap0=0.4, cap1=0.4, per=4))]
    pcs.append(Pc(name + "_coxa", "corpo", fill, ellipse(*((hp * 0.6 + kn * 0.4)), 13 * k, 10 * k, math.degrees(math.atan2(*(kn - hp)[::-1])), 10)))
    pcs.append(Pc(name + "_pe", "corpo", fill, brush([an, to], 7 * k, 5 * k, per=2)))
    d = to - an; d = d / np.linalg.norm(d)
    pcs += claws(name, to, math.degrees(math.atan2(d[1], d[0])), 3, 7 * k, 2.8 * k, 50)
    return pcs


def dragon(J):
    p = PAL; pcs = []
    wl, wr_ = J["WF"], J["WN"]
    pcs += wing("asa_l", wl[0], wl[1], wl[2], wl[3:7], wl[7], p["wing_d"], p["bone"], p["claw"], arm_w=(9, 5), thumb=9, arm_fill=p["body_d"], finger_w=1.6)
    if not J.get("near_wing_front"):
        pcs += wing("asa_r", wr_[0], wr_[1], wr_[2], wr_[3:7], wr_[7], p["wing"], p["bone"], p["claw"], arm_w=(10, 6), thumb=10, arm_fill=p["body"], finger_w=1.8)
    pcs += hind_leg("perna_tras_l", J["hf"], p["body_d"], 1.35)
    pcs += front_leg("pata_frente_l", J["ff"], p["body_d"], J.get("cdf"), 1.3)
    # cauda com espinhos dourados e ponta de seta
    tl = [A(q) for q in J["tail"]]
    n = len(tl)
    tw = list(np.linspace(21, 2.6, n))
    pcs.append(Pc("cauda", "corpo", p["body"], tube(tl, tw, [w * 0.9 for w in tw], cap0=0.3, cap1=0.4, per=5)))
    S_ = cr_sample(tl, 6); m = len(S_)
    for i in range(1, 9):
        j = int(m * (0.1 + i * 0.095)); j = min(j, m - 2)
        q0 = S_[j]; tg = S_[j + 1] - S_[j - 1]; tg /= np.linalg.norm(tg); nn = np.array([-tg[1], tg[0]])
        w = float(np.interp(j / (m - 1) * (n - 1), range(n), tw)) * 0.9
        base_ = q0 + nn * w * 0.95; h = 9 - i * 0.7
        pcs.append(Pc(f"cauda_espinho{i}", "corpo", p["spike"], [base_ - tg * 3, base_ + nn * h + tg * 2.4, base_ + tg * 3], mode="poly"))
    a, b = S_[-3], S_[-1]; d = (b - a) / np.linalg.norm(b - a); nrm = np.array([-d[1], d[0]])
    pcs.append(Pc("cauda_seta", "corpo", p["body_d"], [b - d * 2, b + nrm * 8 - d * 5, b + d * 13, b - nrm * 8 - d * 5], mode="poly"))
    # tronco
    sp = [A(q) for q in J["spine"]]
    wa = [w * 1.35 for w in J.get("wa", [16, 20, 22])]; wb = [w * 1.35 for w in J.get("wb", [18, 26, 24])]
    pcs.append(Pc("tronco", "corpo", p["body"], tube(sp, wa, wb, cap0=0.8, cap1=0.5, per=5)))
    pcs.append(Pc("barriga", "corpo", p["plate"], tube(sp, [-w * 0.25 for w in wb], [w * 0.92 for w in wb], cap0=0.5, cap1=0.3, per=5), cls="inner"))
    S2 = cr_sample(sp, 6)
    for i in range(1, len(S2) - 1, 3):
        tg = S2[i + 1] - S2[i - 1]; tg /= np.linalg.norm(tg); nn = np.array([-tg[1], tg[0]])
        w = float(np.interp(i / (len(S2) - 1) * 2, range(3), wb))
        pcs.append(Pc(f"placa{i}", "corpo", INK, [S2[i] + nn * w * 0.0, S2[i] + nn * w * 0.5 + tg * 1.4, S2[i] + nn * w * 0.88], closed=False, cls="inner", sw=0.7))
    # pescoço
    nk = [A(q) for q in J["neck"]]
    nw = J.get("nw", [23, 19, 15.5, 13])
    pcs.append(Pc("pescoco", "corpo", p["body"], tube(nk, nw, [w * 1.05 for w in nw], cap0=0.4, cap1=0.6, per=5)))
    pcs.append(Pc("pescoco_placas", "corpo", p["plate"], tube(nk[:-1] + [nk[-1] * 0.7 + nk[-2] * 0.3], [-w * 0.3 for w in nw], [w * 0.95 for w in nw], cap0=0.4, cap1=0.6, per=5), cls="inner"))
    S3 = cr_sample(nk, 6)
    for i in range(2, len(S3) - 3, 3):
        tg = S3[i + 1] - S3[i - 1]; tg /= np.linalg.norm(tg); nn = np.array([-tg[1], tg[0]])
        w = float(np.interp(i / (len(S3) - 1) * (len(nw) - 1), range(len(nw)), nw))
        pcs.append(Pc(f"placa_p{i}", "corpo", INK, [S3[i] - nn * w * 0.2, S3[i] + nn * w * 0.9], closed=False, cls="inner", sw=0.6))
    # espinhos do dorso (pescoço)
    for i in range(1, 6):
        j = int(len(S3) * i / 6.5)
        tg = S3[j + 1] - S3[j - 1]; tg /= np.linalg.norm(tg); nn = np.array([tg[1], -tg[0]])
        w = float(np.interp(j / (len(S3) - 1) * (len(nw) - 1), range(len(nw)), nw))
        b0 = S3[j] + nn * w * 0.9
        pcs.append(Pc(f"espinho_dorso{i}", "corpo", p["spike"], [b0 - tg * 2.4, b0 + nn * 6 - tg * 2.6, b0 + tg * 2.4], mode="poly"))
    pcs += hind_leg("perna_tras", J["hn"], p["body"], 1.35)
    pcs += front_leg("pata_frente", J["fn"], p["body"], J.get("cdn"), 1.3)
    hx, hy, ha, hs, op = J["head"]
    pcs += head(tmat(hx, hy, ha, hs), op)
    if J.get("near_wing_front"):
        pcs += wing("asa_r", wr_[0], wr_[1], wr_[2], wr_[3:7], wr_[7], p["wing"], p["bone"], p["claw"], arm_w=(10, 6), thumb=10, arm_fill=p["body"], finger_w=1.8)
    return pcs


POSES = {
    # sopro: 3/4, tronco subindo em diagonal, pescoço em S, cabeça projetada para baixo-frente, asas meio abertas
    "sopro": dict(spine=[(0, 0), (24, -32), (50, -60)], neck=[(50, -64), (62, -94), (88, -108), (110, -100)],
                  head=(108, -102, 22, 1.5, 30),
                  hn=[(6, 4), (32, 22), (16, 46), (36, 52)], hf=[(-6, 0), (-12, 24), (-28, 46), (-10, 52)],
                  fn=[(50, -46), (68, -28), (86, -40)], ff=[(42, -54), (60, -60), (78, -72)], cdn=-40, cdf=-50,
                  tail=[(-6, 6), (-40, 22), (-80, 30), (-112, 20), (-132, 0), (-140, -24)],
                  WN=[(40, -66), (8, -118), (-16, -168), (-92, -150), (-102, -92), (-82, -42), (-44, -12), (12, -26)],
                  WF=[(48, -70), (62, -128), (74, -186), (132, -198), (152, -160), (142, -122), (112, -92), (58, -64)]),
    # mergulho: diagonal 35° descendo para a direita, garras à frente, boca aberta, asas varridas para trás
    "mergulho": dict(spine=[(0, 0), (30, 20), (60, 40)], neck=[(62, 44), (82, 56), (100, 72), (114, 88)],
                     head=(112, 86, 44, 1.5, 22),
                     hn=[(6, 8), (22, 30), (-4, 32), (-20, 40)], hf=[(-4, 6), (10, 24), (-16, 24), (-30, 28)],
                     fn=[(60, 50), (80, 74), (102, 86)], ff=[(54, 44), (80, 60), (104, 70)], cdn=30, cdf=20,
                     tail=[(-8, -4), (-46, -22), (-84, -50), (-104, -88), (-96, -126)],
                     WN=[(34, 18), (24, -30), (-4, -72), (-84, -108), (-94, -58), (-74, -18), (-34, 2), (24, 14)],
                     WF=[(48, 26), (58, -22), (52, -82), (12, -140), (-20, -112), (-22, -72), (6, -32), (40, 22)]),
    # rugido: empinado em 3/4, peito para a câmera, cabeça erguida rugindo, asas abertas
    "rugido": dict(spine=[(0, 0), (8, -40), (16, -80)], neck=[(16, -84), (20, -104), (34, -124), (32, -142)],
                   head=(30, -144, -52, 1.5, 30), wa=[18, 20, 20], wb=[20, 26, 22],
                   hn=[(8, 6), (32, 16), (20, 44), (40, 50)], hf=[(-8, 2), (-26, 12), (-30, 42), (-12, 50)],
                   fn=[(22, -66), (46, -58), (56, -82)], ff=[(8, -70), (-8, -76), (-16, -98)], cdn=-80, cdf=-100,
                   tail=[(-6, 8), (-30, 30), (-70, 40), (-110, 34), (-140, 18), (-150, -4)],
                   WN=[(4, -84), (-30, -130), (-70, -172), (-160, -160), (-172, -100), (-150, -42), (-92, -12), (-4, -44)],
                   WF=[(22, -88), (52, -142), (92, -182), (170, -192), (190, -132), (172, -72), (112, -42), (26, -52)]),
    # sobrevoo: perfil voando para a direita, asas em batida para cima, patas recolhidas
    "sobrevoo": dict(spine=[(0, 0), (36, -6), (70, -6)], neck=[(70, -8), (92, -16), (112, -26), (132, -26)],
                     head=(130, -26, 4, 1.5, 0), wa=[14, 18, 18], wb=[16, 22, 20],
                     hn=[(6, 6), (18, 22), (-4, 28), (-20, 34)], hf=[(-2, 4), (8, 20), (-14, 24), (-30, 28)],
                     fn=[(66, 8), (78, 22), (94, 18)], ff=[(58, 6), (72, 18), (86, 16)], cdn=10, cdf=10,
                     tail=[(-8, 0), (-50, 6), (-100, 2), (-140, -8), (-172, -4)],
                     WN=[(44, -14), (36, -56), (26, -104), (-34, -146), (-56, -96), (-46, -48), (-16, -16), (24, -6)],
                     WF=[(56, -16), (62, -48), (56, -88), (20, -126), (0, -96), (8, -56), (28, -26), (52, -8)]),
}
GUIDE = {"sopro": [(-140, -24), (-60, 30), (0, 0), (50, -62), (80, -106), (140, -90)],
         "mergulho": [(-96, -126), (-60, -30), (0, 0), (60, 42), (120, 96)],
         "rugido": [(-150, -4), (-40, 36), (0, 0), (16, -82), (36, -150), (60, -190)],
         "sobrevoo": [(-172, -4), (-60, 4), (0, 0), (70, -8), (140, -28)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return dragon(J)


def mouth_pt(name):
    """Ponta do focinho / boca da pose (onde nasce o sopro), em coordenadas da pose."""
    hx, hy, ha, hs, op = POSES[name]["head"]
    return ap(tmat(hx, hy, ha, hs), [(36, 1)])[0]
