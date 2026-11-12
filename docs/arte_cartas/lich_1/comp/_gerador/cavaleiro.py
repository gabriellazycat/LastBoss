"""Ficha do CAVALEIRO DA MORTE (vilão Lich, família Morte). Tanque: armadura de placas negro-azulada com enfeites de
osso (costelas em relevo no peitoral, crânio na fivela, espigões de osso nas ombreiras), elmo fechado de chifres
curvos com fenda em T e olhos verde-água acesos, gorjal serrilhado, capa roxo-escura esfarrapada e montante de lâmina
escura com runas que acendem quando o Lich lança um feitiço (a mecânica: cada feitiço o cura e dá dano).
Vista frente-3/4, chão em y=0. Unidade: elmo = 24 u. Altura ≈ 7,5 elmos (180 u); ombros = 3 elmos de largura (com as
ombreiras); coxa 1,7 / canela 1,7 / braço 1,4 / antebraço 1,3 elmo. Criatura grande: tronco ~1,4× o natural.
data-fig: cavaleiro_corpo (pernas, faldas, tronco, braços, manoplas, capa), cavaleiro_cabeca (elmo+chifres),
cavaleiro_espada. Costelas em relevo, fenda, olhos, runas, rebites, crânio da fivela = inner."""
import math
import numpy as np
from geom import *
from piper import ik
from esqueleto import frame

INK = "#2b1a10"
PAL = dict(armor="#4a5466", armor_d="#2c3240", armor_l="#8494aa", bone="#d8ccb0", bone_d="#a89a7c", cape="#3a2a4e",
           cape_d="#241a34", eye="#7affd8", rune="#7affd8", blade="#556072", blade_l="#a8b6c8", visor="#0e1016",
           leather="#3a2a1e")
L_TH, L_SH, L_UA, L_FA = 41.0, 40.0, 34.0, 31.0


def plate(c, w, h, ang, fill, name, fig="corpo", pts=None, cls=None):
    base_ = pts or [(-1, -0.6), (-0.6, -1), (0.6, -1), (1, -0.6), (0.9, 0.7), (0, 1), (-0.9, 0.7)]
    return Pc(name, fig, fill, list(ap(chain(T(*c), R(ang), S(w, h)), base_)), cls=cls)


def deg(v):
    return math.degrees(math.atan2(v[1], v[0]))


def helm(M, fig="cabeca"):
    """Elmo fechado de chifres. Centro (0,0), queixo/gorjal em y≈+16."""
    p = PAL; pcs = []
    for s in (-1, 1):
        tg = "_l" if s < 0 else "_r"
        # chifre: sai da têmpora, abre para fora e sobe curvando para a frente/dentro
        pcs.append(Pc("chifre" + tg, fig, p["bone"], [(s * 10, -6), (s * 20, -10), (s * 28, -20), (s * 29, -34), (s * 24, -46),
                                                       (s * 25, -34), (s * 21, -22), (s * 14, -15), (s * 9, -13)]))
    pcs.append(Pc("gorjal", fig, p["armor_d"], [(-15, 8), (15, 8), (16, 15), (12, 13), (9, 18), (5, 14), (0, 19), (-5, 14), (-9, 18),
                                                (-12, 13), (-16, 15)]))
    pcs.append(Pc("elmo", fig, p["armor"], [(-12, 10), (-13, -2), (-12, -11), (-7, -17), (0, -19), (7, -17), (12, -11), (13, -2),
                                            (12, 10), (6, 13), (0, 15), (-6, 13)]))
    pcs.append(Pc("crista", fig, p["armor_d"], [(-2.4, -18.6), (0, -27), (2.4, -18.6), (1.4, -8), (-1.4, -8)]))
    pcs.append(Pc("elmo_luz", fig, p["armor_l"], [(-10, -4), (-9.5, -11), (-5, -15.5), (-6.5, -9), (-7.5, -2)], cls="inner", op=0.85))
    pcs.append(Pc("fenda", fig, p["visor"], [(-10, -4.5), (10, -4.5), (10, -1), (1.6, -1), (1.6, 9), (-1.6, 9), (-1.6, -1), (-10, -1)], mode="poly", cls="inner"))
    for s in (-1, 1):
        pcs.append(Pc("olho" + ("_l" if s < 0 else "_r"), fig, p["eye"], ellipse(s * 5.2, -2.8, 2.0, 1.2, 0, 7), cls="inner"))
    for i, (x, y) in enumerate([(-9, 6), (9, 6), (-6, 10), (6, 10)]):
        pcs.append(Pc(f"respiro{i}", fig, p["visor"], ellipse(x, y, 0.9, 0.9, 0, 6), cls="inner"))
    return [q.moved(M) for q in pcs]


def greatsword(hand, ang, L=112, fig="espada", runes=True, glow=1.0):
    """Montante: hand = mão de cima no cabo; ang = direção cabo→ponta (graus)."""
    p = PAL
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    h = A(hand); pm = h - d * 20; g = h + d * 6; tip = g + d * L
    pcs = [Pc("cabo", fig, p["leather"], [pm + n * 2.2, g + n * 2.2, g - n * 2.2, pm - n * 2.2], mode="poly")]
    # pomo de crânio
    pcs.append(Pc("pomo", fig, p["bone"], [pm + n * 4.4, pm - d * 4 + n * 4.6, pm - d * 8 + n * 2.6, pm - d * 9, pm - d * 8 - n * 2.6, pm - d * 4 - n * 4.6, pm - n * 4.4]))
    pcs.append(Pc("pomo_olhos", fig, p["visor"], [pm - d * 4 + n * 2.2, pm - d * 5.4 + n * 0.6, pm - d * 4 - n * 0.6], mode="poly", cls="inner"))
    # lâmina larga com ponta em losango e serrilha perto da guarda
    pcs.append(Pc("lamina", fig, p["blade"], [g + n * 6, g + d * 10 + n * 7.6, g + d * 14 + n * 5.6, g + d * 18 + n * 7.4, tip - d * 16 + n * 6.4,
                                              tip, tip - d * 16 - n * 6.4, g + d * 18 - n * 7.4, g + d * 14 - n * 5.6, g + d * 10 - n * 7.6, g - n * 6], mode="poly"))
    pcs.append(Pc("fio", fig, p["blade_l"], [g + d * 20 + n * 6.2, tip - d * 14 + n * 5.4, tip - d * 2], closed=False, cls="inner", sw=1.0, mode="poly"))
    pcs.append(Pc("canal", fig, p["armor_d"], [g + d * 8 + n * 1.4, tip - d * 22 + n * 1.0, tip - d * 22 - n * 1.0, g + d * 8 - n * 1.4], mode="poly", cls="inner"))
    if runes:
        for k in range(5):
            c = g + d * (16 + k * (L - 44) / 4)
            r_ = [c - d * 2.6, c + n * 1.8, c + d * 2.6, c - n * 1.8] if k % 2 else [c - d * 2.6 + n * 1.4, c + d * 2.6 + n * 1.4, c + d * 0.4 - n * 1.8]
            pcs.append(Pc(f"runa{k}", fig, p["rune"], r_, mode="poly", cls="inner", op=round(0.55 + 0.45 * glow, 2)))
    # guarda de osso em asas curvas
    pcs.append(Pc("guarda", fig, p["bone"], [g - n * 18 - d * 6, g - n * 13 - d * 1, g - n * 4 + d * 2, g + n * 4 + d * 2, g + n * 13 - d * 1,
                                             g + n * 18 - d * 6, g + n * 12 + d * 3, g + n * 4 + d * 5, g - n * 4 + d * 5, g - n * 12 + d * 3]))
    return pcs


def gauntlet(name, wrist, ang, s=1.0, mode="fist", fig="corpo"):
    p = PAL
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    c = A(wrist) + d * 4.6 * s
    pcs = [Pc(name, fig, p["armor_d"], ellipse(c[0], c[1], 6.2 * s, 5.4 * s, ang, 9))]
    if mode == "open":
        for k in range(4):
            a_ = math.radians(ang + (k - 1.5) * 18)
            dk = np.array([math.cos(a_), math.sin(a_)])
            b = c + d * 3.6 * s + n * (k - 1.5) * 2.6 * s
            pcs.append(Pc(f"{name}_dedo{k}", fig, p["armor_d"], [b + n * 1.6 * s, b + dk * 9 * s, b + dk * 12.5 * s, b - n * 1.6 * s], mode="poly"))
        a_ = math.radians(ang - 66); dt = np.array([math.cos(a_), math.sin(a_)]); b = c - n * 4.2 * s
        pcs.append(Pc(f"{name}_polegar", fig, p["armor_d"], [b + d * 1.6 * s, b + dt * 9 * s, b - d * 1.6 * s], mode="poly"))
    pcs.append(Pc(f"{name}_punho", fig, p["armor"], [A(wrist) + n * 5.4 * s - d * 3 * s, A(wrist) + n * 6.2 * s + d * 2.4 * s,
                                                    A(wrist) - n * 6.2 * s + d * 2.4 * s, A(wrist) - n * 5.4 * s - d * 3 * s], mode="poly"))
    return pcs


def knight(J):
    """J: hip, neck, head=(x,y,rot), far, al/ar, tl/tr, kbl/kbr, wl/wr, ebl/ebr, hdl/hdr, hml/hmr ('fist'|'open'),
    sword=(tag, ang, L) — tag 'both' = duas mãos (wr em cima no cabo), sword_back (espada atrás do corpo), cape, glow."""
    p = PAL; pcs = []
    hip, nk = A(J["hip"]), A(J["neck"])
    up = (nk - hip) / np.linalg.norm(nk - hip); side = np.array([-up[1], up[0]])
    F = frame(nk, up); H = frame(hip, up)
    far = J.get("far", "l")
    shl, shr = F(-24, -6), F(24, -6); hjl, hjr = H(-11, -2), H(11, -2)
    pcs.append(Pc("capa", "corpo", p["cape_d"], J["cape"]))
    sword_pcs = []
    if J.get("sword"):
        tag, ang, L = J["sword"]
        wtag = "r" if tag == "both" else tag
        el, wr = ik(shr if wtag == "r" else shl, J["w" + wtag], L_UA, L_FA, J.get("eb" + wtag, 1))
        sword_pcs = greatsword(wr + np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]) * 4.6, ang, L, glow=J.get("glow", 1.0))
        if J.get("sword_back"):
            pcs += sword_pcs; sword_pcs = []

    def leg(tag):
        hj = hjl if tag == "l" else hjr
        kn, an = ik(hj, J["a" + tag], L_TH, L_SH, J.get("kb" + tag, -1))
        c = p["armor_d"] if tag == far else p["armor"]
        out = [Pc("coxa_" + tag, "corpo", c, tube([hj, (hj + kn) / 2, kn], [9, 8, 6.6], None, cap0=0.6, cap1=0.6, per=3)),
               Pc("greva_" + tag, "corpo", c, tube([kn, kn * 0.4 + an * 0.6, an], [7.6, 7.0, 5.4], None, cap0=0.5, cap1=0.6, per=3))]
        kd = kn - hj; kd /= np.linalg.norm(kd); kn_side = np.array([-kd[1], kd[0]])
        out.append(plate(kn, 8, 7, deg(kd) - 90, p["armor_l"] if tag != far else p["armor"], "joelheira_" + tag))
        sp = kn + (kn - an) * 0.0 + kn_side * (-6 if tag == "l" else 6)
        out.append(Pc("espigao_joelho_" + tag, "corpo", p["bone"], [kn + kn_side * 3 - kd * 3, sp + kd * 2 + kn_side * (-5 if tag == "l" else 5), kn + kd * 3]))
        to = A(J["t" + tag]); dd = to - an
        out.append(Pc("pe_" + tag, "corpo", p["armor_d"], [an - dd * 0.25 + np.array([0, -5]), an + np.array([0, -6]), to + np.array([0, -2]),
                                                           to + dd / np.linalg.norm(dd) * 4 + np.array([0, 0.5]), to + np.array([0, 1.5]), an - dd * 0.3 + np.array([0, 1.5])]))
        return out

    def arm(tag):
        sh = shl if tag == "l" else shr
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        c = p["armor_d"] if tag == far else p["armor"]
        out = [Pc("braco_" + tag, "corpo", c, tube([sh, (sh + el) / 2, el], [7.4, 6.4, 5.8], None, cap0=0.5, cap1=0.5, per=3)),
               Pc("antebraco_" + tag, "corpo", c, tube([el, (el + wr) / 2, wr], [6.6, 6.8, 5.6], None, cap0=0.5, cap1=0.4, per=3)),
               plate(el, 6.4, 5.6, 0, p["armor_l"] if tag != far else p["armor"], "cotoveleira_" + tag)]
        ang = J.get("hd" + tag, deg(wr - el))
        out += gauntlet("manopla_" + tag, wr, ang, 1.0, J.get("hm" + tag, "fist"))
        return out

    def pauldron(tag):
        sh = shl if tag == "l" else shr; sg = -1 if tag == "l" else 1
        out = [plate(sh + up * 3 + side * sg * 2, 17, 12, sg * 14 + deg(side) * 0, p["armor"], "ombreira_" + tag,
                     pts=[(-1, 0.5), (-0.85, -0.5), (-0.2, -1), (0.6, -0.9), (1, -0.1), (0.9, 0.75), (0, 0.95)]),
               plate(sh - up * 6 + side * sg * 5, 12, 6, sg * 22, p["armor_d"], "ombreira2_" + tag,
                     pts=[(-1, -0.6), (1, -0.6), (0.9, 0.7), (-0.9, 0.7)])]
        for k in range(3):
            b = sh + up * (10 - k * 1.5) + side * sg * (k * 7 - 6)
            out.append(Pc(f"espigao_{tag}{k}", "corpo", p["bone"], [b - side * 3, b + up * (16 - k * 3) + side * sg * (4 + k * 2), b + side * 3]))
        return out

    pcs += arm(far)
    pcs += leg(far)
    pcs += leg("r" if far == "l" else "l")
    # faldas
    for i, s in enumerate((-1, -0.35, 0.35, 1)):
        c = H(s * 14, -10)
        pcs.append(plate(c, 8, 13, deg(-up) - 90 + s * 10, p["armor"] if abs(s) < 0.5 else p["armor_d"], f"falda{i}",
                         pts=[(-1, -1), (1, -1), (0.9, 0.8), (0, 1), (-0.9, 0.8)]))
    pcs.append(Pc("cinto", "corpo", p["leather"], [H(-18, 2), H(18, 2), H(18, -4), H(-18, -4)], mode="poly"))
    pcs.append(Pc("fivela", "corpo", p["bone"], [H(-4, 3), H(4, 3), H(4.6, -1), H(2, -5), H(-2, -5), H(-4.6, -1)], cls="inner"))
    pcs.append(Pc("fivela_olhos", "corpo", p["visor"], [H(-2.4, 0.4), H(-0.6, 0.4), H(-1.5, -1.4)], mode="poly", cls="inner"))
    # peitoral maciço, cintura afunilando, costelas de osso em relevo
    pcs.append(Pc("peitoral", "corpo", p["armor"], [F(-28, -1), F(-10, 3), F(10, 3), F(28, -1), F(26, -20), F(18, -36), F(12, -48),
                                                   H(13, 4), H(-13, 4), F(-12, -48), F(-18, -36), F(-26, -20)]))
    pcs.append(Pc("peito_luz", "corpo", p["armor_l"], [F(-24, -3), F(-8, 1), F(-10, -16), F(-20, -26)], cls="inner", op=0.7))
    pcs.append(Pc("quilha", "corpo", p["armor_d"], [F(0, 2), F(0, -44)], closed=False, cls="inner", sw=1.0))
    for i in range(4):
        for s in (-1, 1):
            pcs.append(Pc(f"costela{i}{'l' if s < 0 else 'r'}", "corpo", p["bone"],
                          brush([F(s * 2.5, -8 - i * 7.5), F(s * 10, -7 - i * 7.8), F(s * 17, -11 - i * 7.2)], 3.0 - i * 0.3, 1.0, per=3), cls="inner"))
    for tag in (far, "r" if far == "l" else "l"):
        pcs += pauldron(tag) if tag == far else []
    pcs += arm("r" if far == "l" else "l")
    pcs += pauldron("r" if far == "l" else "l")
    hx, hy, hr = J["head"]
    pcs += helm(tmat(hx, hy, hr, J.get("hk", 1.0)))
    pcs += sword_pcs
    return pcs


CAPE = [(-30, -150), (30, -150), (50, -110), (60, -50), (54, -6), (42, -16), (34, 0), (22, -12), (8, 2), (-6, -12), (-20, 0), (-34, -14), (-48, -2), (-60, -48), (-52, -112)]
POSES = {
    # investida: diagonal para a direita, tronco 20° à frente, montante arrastado baixo atrás, manopla livre à frente
    "investir": dict(hip=(-4, -82), neck=(18, -140), head=(24, -158, 10), far="l",
                     ar=(40, -26), tr=(54, -22), kbr=-1, al=(-46, -6), tl=(-56, 0), kbl=-1,
                     wl=(52, -112), ebl=1, hml="open", hdl=-10, wr=(-26, -86), ebr=-1, sword=("r", 160, 104), sword_back=True,
                     cape=[(-14, -150), (34, -146), (16, -120), (-10, -96), (-40, -76), (-74, -62), (-96, -78), (-84, -100), (-104, -110),
                           (-80, -124), (-90, -138), (-56, -140)]),
    # golpe: montante erguido acima da cabeça com as duas mãos, tronco arqueado para trás (logo antes de descer)
    "golpe": dict(hip=(0, -80), neck=(-6, -138), head=(-4, -156, -6), far="l",
                  al=(-38, 0), tl=(-50, 0), kbl=1, ar=(34, -4), tr=(46, 0), kbr=-1,
                  wr=(-14, -186), ebr=-1, wl=(-22, -176), ebl=1, hdr=-150, sword=("both", -150, 104),
                  cape=CAPE),
    # guarda: de frente, montante fincado à frente com as duas mãos no pomo, base larga (câmera baixa na carta)
    "guarda": dict(hip=(0, -82), neck=(0, -140), head=(0, -158, 0), far="l",
                   al=(-30, 0), tl=(-40, 0), kbl=1, ar=(30, 0), tr=(40, 0), kbr=-1,
                   wr=(4, -96), ebr=-1, wl=(-6, -92), ebl=1, hdr=90, hdl=90, sword=("both", 90, 82),
                   cape=CAPE),
    # absorver: mão esquerda aberta erguida puxando a magia do feitiço, montante baixo na direita, cabeça olhando a mão
    "absorver": dict(hip=(0, -82), neck=(6, -140), head=(2, -158, -14), far="r",
                     al=(-34, 0), tl=(-44, 0), kbl=1, ar=(28, -2), tr=(40, 0), kbr=-1,
                     wl=(-40, -186), ebl=1, hml="open", hdl=-100, wr=(46, -90), ebr=-1, sword=("r", 60, 104),
                     cape=CAPE),
}
GUIDE = {"investir": [(-56, 0), (-20, -40), (-4, -82), (18, -140), (40, -170)],
         "golpe": [(-50, 0), (-20, -40), (0, -80), (-6, -138), (-20, -186), (20, -260)],
         "guarda": [(-30, 0), (0, -80), (0, -170)],
         "absorver": [(40, 0), (10, -40), (0, -82), (6, -140), (-40, -190)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return knight(J)


def ficha(svg_wrap, ruler, ground_line):
    from fichas_lib import txt, pose_g, swatches
    W, H = 1240, 640
    P = [txt(20, 30, "FICHA · CAVALEIRO DA MORTE (Lich, Morte) — armadura negro-azulada com osso, elmo de chifres e olhos verde-água, capa roxa esfarrapada, montante de runas", 14, "bold"),
         txt(20, 48, "Unidade: elmo = 24 u. Altura ≈ 7,5 elmos (180 u); ombros = 3 elmos (com ombreiras); coxa 1,7 / canela 1,7 / braço 1,4 / antebraço 1,3. Tanque: tronco ~1,4× o natural.", 10),
         txt(20, 62, "As runas da lâmina (verde-água) acendem quando o Lich lança feitiço: a mecânica (cura + dano). Brilho próprio = olhos OU runas, o que for o foco da carta.", 10),
         txt(20, 76, "data-fig: cavaleiro_corpo (capa, pernas, faldas, tronco, braços, manoplas, ombreiras), cavaleiro_cabeca (elmo+chifres+gorjal), cavaleiro_espada. Costelas, fenda, olhos, runas = inner.", 10),
         ruler(40, 92, 24 * 2, 4, "#4a5466", "#d8ccb0", "1 elmo = 24 u (régua ×2)")]
    P.append(pose_g("cabeca_frente", helm(T(0, 0)), (90, 220, 2.4), "cavaleiro", label="elmo · frente", ly=56))
    for i, (nm, lab, sub) in enumerate([("investir", "investir · diagonal", "montante arrastado atrás"),
                                        ("golpe", "golpe · duas mãos", "logo antes de descer"),
                                        ("guarda", "guarda · imponente", "montante fincado"),
                                        ("absorver", "absorver o feitiço", "mão aberta erguida")]):
        x = 300 + i * 220; y = 590
        P.append(ground_line(x, y, 180))
        P.append(pose_g(nm, pose(nm), (x, y, 1.45), "cavaleiro", GUIDE[nm], lab, sub, ly=24))
    P.append(swatches(1100, 110, [(k, PAL[k]) for k in ("armor", "armor_d", "armor_l", "bone", "cape", "cape_d", "eye", "blade", "blade_l", "leather")]))
    return svg_wrap(W, H, P), (W, H)
