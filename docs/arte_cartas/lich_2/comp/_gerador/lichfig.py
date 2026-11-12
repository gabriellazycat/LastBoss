"""Ficha do Lich (lote lich_2): esqueleto coroado, manto esfarrapado violeta-noite, gola alta em leque, ombreiras de osso,
mangas rasgadas mostrando os ossos do antebraço, mãos de osso com magia; flutua (sem pés à vista; barra some em névoa).
Perfil 3/4 olhando para +x, chão em y=0. Unidade: crânio = 22 u. Altura ≈ 8 crânios (176 u com a coroa).
Braços por IK de dois ossos (praga_3/piper.ik, só leitura). data-fig: lich_corpo (manto, gola, ombreiras, braços, mãos = 1),
lich_cabeca (crânio + mandíbula + coroa = 1), lich_cajado (cajado = 1). Órbitas, olhos, dentes, nariz, rachadura, gema,
farrapos internos, runas = inner."""
import base  # noqa: F401
import math
import numpy as np
from geom import *
from piper import ik, hand, tatter

INK = "#2b1a10"
PAL = dict(robe="#2e2440", robe_d="#1e1830", trim="#7a5ab0", bone="#e6d8b8", bone_d="#b8a886", socket="#241426",
           eye="#9effc4", crown="#5a5468", crown_l="#8a8498", gem="#7af0c0", magic="#c080ff", staff="#4a3a30")
L_UA, L_FA = 31, 27.5

HEAD = [(-10, -2), (-9.5, -9), (-3, -13.5), (5, -12.5), (10, -7.5), (11.8, -1), (12.6, 4.5), (10.5, 7.8), (4, 8.6), (-2, 8),
        (-8, 5)]
JAW = [(3, 8), (12, 7.4), (12.6, 11), (9.5, 14.2), (3.5, 13.2)]
CROWN = [(-10.5, -5), (-11, -12), (-9, -10.5), (-7, -19), (-4.5, -12.5), (0, -21), (3.5, -13.5), (7, -19.5), (8.6, -11.5),
         (11.5, -15), (11, -6.5)]


def head(M, jaw_open=0.0):
    p = PAL; pcs = []
    Mj = chain(T(3, 8), R(jaw_open * 18), T(-3, -8))
    pcs.append(Pc("mandibula", "cabeca", p["bone_d"], list(ap(Mj, JAW))))
    pcs.append(Pc("cranio", "cabeca", p["bone"], HEAD))
    pcs.append(Pc("coroa", "cabeca", p["crown"], CROWN, mode="poly"))
    pcs.append(Pc("coroa_aro", "cabeca", p["crown_l"], [(-10.5, -6.5), (11, -8)], closed=False, cls="inner", sw=1.2))
    pcs.append(Pc("gema", "cabeca", p["gem"], ellipse(0.5, -10.5, 1.8, 2.2, 0, 6), cls="inner"))
    pcs.append(Pc("orbita", "cabeca", p["socket"], ellipse(6.6, -0.8, 3.0, 3.5, -6, 8), cls="inner"))
    pcs.append(Pc("orbita_l", "cabeca", p["socket"], ellipse(11.4, -0.6, 1.3, 3.0, -6, 6), cls="inner"))
    pcs.append(Pc("olho", "cabeca", p["eye"], ellipse(7.0, -0.6, 1.4, 1.5, 0, 6), cls="inner"))
    pcs.append(Pc("nariz", "cabeca", p["socket"], [(11.6, 3), (12.6, 5.4), (10.6, 5.4)], cls="inner", mode="poly"))
    pcs.append(Pc("dentes", "cabeca", INK, [(4.5, 8.4), (12, 7.4)], closed=False, cls="inner", sw=0.7))
    for k, x in enumerate((6, 8, 10)):
        pcs.append(Pc(f"dente{k}", "cabeca", INK, [(x, 7.2), (x, 9.6)], closed=False, cls="inner", sw=0.5))
    pcs.append(Pc("rachadura", "cabeca", p["bone_d"], [(-4, -12), (-2, -7), (-5, -3)], closed=False, cls="inner", sw=0.8))
    return [q.moved(M) for q in pcs]


def head_front(M, jaw_open=0.0):
    p = PAL
    jaw = [(-6.5, 8), (6.5, 8), (5.5, 13 + jaw_open * 4), (0, 14.5 + jaw_open * 4), (-5.5, 13 + jaw_open * 4)]
    pcs = [Pc("mandibula", "cabeca", p["bone_d"], jaw),
           Pc("cranio", "cabeca", p["bone"], [(-11, -4), (-10, -11), (0, -14.5), (10, -11), (11, -4), (10, 3.5), (6.5, 8.5), (-6.5, 8.5), (-10, 3.5)]),
           Pc("coroa", "cabeca", p["crown"], [(-12, -5), (-13, -14), (-10, -11.5), (-8, -20), (-4.5, -13), (0, -23), (4.5, -13), (8, -20),
                                             (10, -11.5), (13, -14), (12, -5)], mode="poly"),
           Pc("coroa_aro", "cabeca", p["crown_l"], [(-12, -6.5), (12, -6.5)], closed=False, cls="inner", sw=1.2),
           Pc("gema", "cabeca", p["gem"], ellipse(0, -10, 2, 2.4, 0, 6), cls="inner"),
           Pc("orbita_l", "cabeca", p["socket"], ellipse(-4.6, -0.5, 3.3, 3.8, 8, 8), cls="inner"),
           Pc("orbita", "cabeca", p["socket"], ellipse(4.6, -0.5, 3.3, 3.8, -8, 8), cls="inner"),
           Pc("olho_l", "cabeca", p["eye"], ellipse(-4.4, -0.3, 1.5, 1.6, 0, 6), cls="inner"),
           Pc("olho", "cabeca", p["eye"], ellipse(4.4, -0.3, 1.5, 1.6, 0, 6), cls="inner"),
           Pc("nariz", "cabeca", p["socket"], [(0, 2.5), (1.6, 5.6), (-1.6, 5.6)], cls="inner", mode="poly"),
           Pc("dentes", "cabeca", INK, [(-5.5, 8.6), (5.5, 8.6)], closed=False, cls="inner", sw=0.7)]
    for k, x in enumerate((-3, 0, 3)):
        pcs.append(Pc(f"dente{k}", "cabeca", INK, [(x, 7.4), (x, 10)], closed=False, cls="inner", sw=0.5))
    return [q.moved(M) for q in pcs]


def bone_arm(name, sh, el, wr, sleeve_fill, p, cut=0.35):
    """Manga rasgada do ombro até passar do cotovelo; dali o antebraço é osso (rádio + ulna)."""
    sh, el, wr = A(sh), A(el), A(wr)
    d = (wr - el) / (np.linalg.norm(wr - el) + 1e-9); n = np.array([-d[1], d[0]])
    se = el + (wr - el) * cut
    pcs = [Pc(name + "_osso", "corpo", p["bone"], tube([el, wr], [2.6, 1.8], cap0=0.5, cap1=0.6, per=3)),
           Pc(name + "_ulna", "corpo", p["bone_d"], [el + n * 0.8 + d * 4, wr + n * 0.6 - d * 2], closed=False, cls="inner", sw=0.7)]
    pcs.append(Pc(name, "corpo", sleeve_fill, tube([sh, el, se], [6.4, 6.2, 7.6], cap0=0.5, cap1=0.0, per=4)))
    rag = [se - n * 8.5] + [se + d * (5 if k % 2 else 1.5) + n * (-8.5 + k * 17 / 5) for k in range(1, 5)] + [se + n * 8.5]
    pcs.append(Pc(name + "_farrapo", "corpo", sleeve_fill, rag + [se + n * 6 - d * 3, se - n * 6 - d * 3], mode="poly"))
    return pcs, wr + d * 2.5


def lich(J):
    p = PAL; pcs = []
    hc = A(J["hip"]); nk = A(J["neck"])
    up = (nk - hc) / np.linalg.norm(nk - hc); fwd = np.array([-up[1], up[0]]) * -1
    if fwd[0] < 0:
        fwd = -fwd
    arms = {}
    for s in ("f", "n"):
        el, wr = ik(J["sh_" + s], J["wr_" + s], L_UA, L_FA, J.get("elb_" + s, 1))
        arms[s] = (A(J["sh_" + s]), el, wr)
    # gola alta em leque (atrás do crânio)
    gc = nk + up * 4 - fwd * 4
    gola = [nk - fwd * 13 - up * 2, gc - fwd * 22 + up * 14, gc - fwd * 21 + up * 30, gc - fwd * 10 + up * 38, gc + fwd * 1 + up * 33,
            gc + fwd * 6 + up * 22, nk + fwd * 9 - up * 1]
    pcs.append(Pc("gola", "corpo", p["robe_d"], gola))
    pcs.append(Pc("gola_forro", "corpo", p["trim"], [gc - fwd * 17 + up * 14, gc - fwd * 16 + up * 28, gc - fwd * 8 + up * 34, gc + fwd * 0 + up * 29, gc + fwd * 3 + up * 12, gc - fwd * 6 + up * 4], cls="inner", op=0.85))
    for k in range(4):  # varetas da gola
        t = k / 3.0
        tip = (gc - fwd * 21 + up * 30) * (1 - t) + (gc + fwd * 1 + up * 33) * t
        pcs.append(Pc(f"gola_vareta{k}", "corpo", p["robe_d"], [gc + up * 2, tip], closed=False, cls="inner", sw=0.9))
    # braço de longe
    sf, ef, wf = arms["f"]
    pc, hand_f = bone_arm("braco_l", sf, ef, wf, p["robe_d"], p, J.get("cut_f", 0.35))
    pcs += pc
    # cajado (na mão de longe, se houver)
    if J.get("staff"):
        a = math.radians(J["staff"]); d = np.array([math.cos(a), math.sin(a)])
        top = hand_f + d * J.get("staff_up", 46); bot = hand_f - d * J.get("staff_dn", 88)
        pcs.append(Pc("cajado", "cajado", p["staff"], tube([bot, hand_f, top], [1.8, 2.2, 2.6], cap0=0.4, cap1=0.3, per=3)))
        n = np.array([-d[1], d[0]])
        pcs.append(Pc("cajado_garra", "cajado", p["bone_d"], [top - n * 6 - d * 2, top - n * 7 + d * 8, top - n * 2 + d * 4, top + d * 11, top + n * 2 + d * 4,
                                                         top + n * 7 + d * 8, top + n * 6 - d * 2]))
        pcs.append(Pc("cajado_gema", "cajado", p["gem"], ellipse(*(top + d * 5), 3.4, 4.2, J["staff"] + 90, 8), cls="inner"))
    # manto
    hemF, hemB = A(J["hemF"]), A(J["hemB"])
    chest = nk * 0.62 + hc * 0.38 + fwd * 13
    back = nk * 0.5 + hc * 0.5 - fwd * 13
    robe = [nk + fwd * 7, chest, hc + fwd * 13, hemF] + tatter(hemF, hemB, 5, 9, J.get("seed", 5)) + [hemB, hc - fwd * 15, back, nk - fwd * 9]
    pcs.append(Pc("manto", "corpo", p["robe"], robe))
    pcs.append(Pc("manto_frente", "corpo", p["trim"], [nk + fwd * 6, chest - fwd * 2, hc + fwd * 8, hemF * 0.85 + hemB * 0.15 + up * 6], closed=False, cls="inner", sw=1.6))
    for k, t in enumerate((0.35, 0.65)):
        top = hc + fwd * (-8 + 16 * t); bot = hemB + (hemF - hemB) * t + up * 8
        pcs.append(Pc(f"dobra{k}", "corpo", p["robe_d"], [top, top * 0.5 + bot * 0.5 + fwd * 2, bot], closed=False, cls="inner", sw=1.0))
    pcs.append(Pc("cinto", "corpo", p["bone_d"], [hc + up * 8 - fwd * 13, hc + up * 8 + fwd * 13, hc + up * 4 + fwd * 13, hc + up * 4 - fwd * 13.5], mode="poly", cls="inner"))
    # ombreiras de osso
    for s, nm in (("f", "ombreira_l"), ("n", "ombreira")):
        c = arms[s][0]
        pcs.append(Pc(nm, "corpo", p["bone"] if s == "n" else p["bone_d"], ellipse(c[0], c[1] - 2, 9, 6.5, -10, 10)))
        pcs.append(Pc(nm + "_espinho", "corpo", p["bone"] if s == "n" else p["bone_d"], wedge(c[0] - 2, c[1] - 6, c[0] - 6, c[1] - 15, 5), mode="poly"))
    # braço de perto
    sn, en, wn = arms["n"]
    pc, hand_n = bone_arm("braco", sn, en, wn, p["robe"], p, J.get("cut_n", 0.35))
    pcs += pc
    hf = J.get("hands", {})
    af_, cf, spf = hf.get("f", (math.degrees(math.atan2(*(wf - ef)[::-1])), 0.4, 50))
    an_, cn, spn = hf.get("n", (math.degrees(math.atan2(*(wn - en)[::-1])), 0.2, 60))
    pcs += hand("mao_l", hand_f, af_, p["bone_d"], cf, spf, L=10)
    pcs += hand("mao", hand_n, an_, p["bone"], cn, spn, L=10.5)
    hx, hy, ha = J["head"]
    pcs += head(tmat(hx, hy, ha, J.get("hs", 1.15)), J.get("jaw", 0.0))
    return pcs


def hands(J):
    out = {}
    for s in ("f", "n"):
        el, wr = ik(J["sh_" + s], J["wr_" + s], L_UA, L_FA, J.get("elb_" + s, 1))
        d = (wr - el) / np.linalg.norm(wr - el)
        out[s] = wr + d * 10
    return out


POSES = {
    # conjurar: braços erguidos, corpo em C para trás, boca aberta
    "conjurar": dict(hip=(0, -86), neck=(-6, -138), head=(-9, -153, -22), jaw=0.8,
                     sh_f=(-15, -132), sh_n=(3, -132), wr_f=(-46, -182), wr_n=(32, -188), elb_f=-1, elb_n=1,
                     hands=dict(f=(-115, 0.1, 80), n=(-60, 0.1, 80)), hemF=(34, -12), hemB=(-42, -8)),
    # apontar: braço de perto esticado lançando, ombro à frente, manto voando para trás
    "apontar": dict(hip=(0, -86), neck=(14, -136), head=(22, -152, 6), jaw=0.3,
                    sh_f=(4, -130), sh_n=(20, -130), wr_n=(80, -140), wr_f=(-22, -104), elb_f=1, elb_n=1,
                    hands=dict(n=(-6, 0.0, 70), f=(150, 0.6, 40)), hemF=(30, -10), hemB=(-56, -20), seed=7),
    # flutuar: ameaça parada, cajado na mão de longe, mão de perto aberta (palma para cima) com a chama
    "flutuar": dict(hip=(0, -92), neck=(4, -142), head=(8, -158, 8), jaw=0.0,
                    sh_f=(-8, -136), sh_n=(12, -136), wr_f=(-22, -110), wr_n=(40, -114), elb_f=1, elb_n=1, staff=-82,
                    hands=dict(f=(-80, 0.85, 40), n=(-40, 0.3, 80)), hemF=(28, -14), hemB=(-40, -12), seed=9),
}
GUIDE = {"conjurar": [(-30, -10), (-4, -60), (-4, -110), (-9, -153), (-30, -176)],
         "apontar": [(-50, -18), (-10, -60), (10, -110), (22, -150), (80, -140)],
         "flutuar": [(-20, -12), (-4, -60), (2, -110), (8, -158), (12, -180)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return lich(J)
