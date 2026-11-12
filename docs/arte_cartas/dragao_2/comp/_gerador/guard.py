"""Ficha do GUARDA DO TESOURO (vilão Dragão, Ganância): guardião de ouro e osso — esqueleto grande numa armadura de
ouro (elmo de chifres com coroa, peitoral maciço, ombreiras de espigão, faldas e grevas), coluna e braços de osso à
mostra, olhos de brasa azul-turquesa (frio contra o ouro quente), capa vermelha esfarrapada, escudo redondo de ouro com
o emblema do dragão e machado grande. É um tanque: lento, largo, peso nos calcanhares.
Vista frontal-3/4, chão em y=0. Unidade: cabeça (crânio+elmo) = 26 u. Altura ≈ 6 cabeças (156 u); ombros = 3 cabeças
de largura (criatura grande: cabeça e tronco ~1,4× o natural); coxa 1,4 / canela 1,4 / braço 1,2 / antebraço 1,1.
data-fig: guardiao_corpo (pernas, faldas, tronco, braços, mãos, capa = 1), guardiao_cabeca (crânio+elmo+chifres = 1),
guardiao_escudo, guardiao_machado. Costelas, vértebras, olhos, dentes, emblema, rebites = inner."""
import math
import numpy as np
from geom import *
from piper import ik

INK = "#2b1a10"
PAL = dict(bone="#e8dcc0", bone_d="#b8a886", gold="#d9a332", gold_d="#a8741e", gold_l="#f6d676", cape="#8a2232",
           cape_d="#5e1424", eye="#5af0dc", socket="#1c1a22", haft="#6a4426", blade="#c8ccd4", blade_d="#8a909a",
           gem="#c8283a")
L_TH, L_SH, L_UA, L_FA = 36.0, 36.0, 30.0, 28.0


def plate(c, w, h, ang, fill, name, fig="corpo", pts=None):
    base_ = pts or [(-1, -0.6), (-0.6, -1), (0.6, -1), (1, -0.6), (0.9, 0.7), (0, 1), (-0.9, 0.7)]
    M = chain(T(*c), R(ang), S(w, h))
    return Pc(name, fig, fill, list(ap(M, base_)))


def bone(name, a, b, w0, w1, fill, fig="corpo"):
    a, b = A(a), A(b)
    return Pc(name, fig, fill, tube([a, (a + b) / 2, b], [w0, w0 * 0.7, w1], cap0=0.6, cap1=0.6, per=3))


def skull_helm(M, jaw=0.0):
    """Crânio com elmo de ouro, frente-3/4. Centro do crânio (0,0); queixo em y≈+15."""
    p = PAL; pcs = []
    pcs.append(Pc("chifre_l", "cabeca", p["bone"], [(-11, -10), (-22, -16), (-30, -28), (-28, -40), (-24, -30), (-16, -22), (-8, -18)]))
    pcs.append(Pc("chifre_r", "cabeca", p["bone"], [(11, -10), (22, -16), (30, -28), (28, -40), (24, -30), (16, -22), (8, -18)]))
    pcs.append(Pc("cranio", "cabeca", p["bone"], [(-12, -4), (-12, 6), (-8, 11), (-5, 13), (5, 13), (8, 11), (12, 6), (12, -4)]))
    jy = jaw
    pcs.append(Pc("mandibula", "cabeca", p["bone_d"], [(-9, 9 + jy * 0.5), (9, 9 + jy * 0.5), (8, 16 + jy), (3, 19 + jy), (-3, 19 + jy), (-8, 16 + jy)]))
    pcs.append(Pc("elmo", "cabeca", p["gold"], [(-14, 2), (-15, -8), (-12, -16), (-6, -20), (0, -21), (6, -20), (12, -16), (15, -8),
                                              (14, 2), (10, 0), (9, -4), (3, -3), (0, -1), (-3, -3), (-9, -4), (-10, 0)]))
    for i, x in enumerate((-9, -3.5, 3.5, 9)):
        h = 9 if i in (1, 2) else 6
        pcs.append(Pc(f"coroa{i}", "cabeca", p["gold_l"], [(x - 2.6, -18.5 + abs(x) * 0.15), (x, -18.5 - h + abs(x) * 0.15), (x + 2.6, -18.5 + abs(x) * 0.15)], mode="poly"))
    pcs.append(Pc("gema", "cabeca", p["gem"], ellipse(0, -14, 2.2, 2.6, 0, 8), cls="inner"))
    for s in (-1, 1):
        pcs.append(Pc("orbita" + ("_l" if s < 0 else ""), "cabeca", p["socket"], ellipse(s * 5, 2.5, 3.8, 3.2, s * 8, 9), cls="inner"))
        pcs.append(Pc("olho" + ("_l" if s < 0 else ""), "cabeca", p["eye"], ellipse(s * 5, 2.8, 1.6, 1.3, 0, 7), cls="inner"))
    pcs.append(Pc("nariz", "cabeca", p["socket"], [(0, 5.5), (1.6, 9), (-1.6, 9)], cls="inner", mode="poly"))
    for i in range(6):
        x = -6.2 + i * 2.5
        pcs.append(Pc(f"dente{i}", "cabeca", INK, [(x, 10.5), (x, 12.6)], closed=False, cls="inner", sw=0.5))
        pcs.append(Pc(f"dente_b{i}", "cabeca", INK, [(x, 12 + jy), (x, 14 + jy)], closed=False, cls="inner", sw=0.5))
    if jy > 2:
        pcs.append(Pc("boca", "cabeca", p["socket"], [(-6, 12.6), (6, 12.6), (5.4, 12 + jy), (-5.4, 12 + jy)], cls="inner", mode="poly"))
    return [q.moved(M) for q in pcs]


def shield(M, fig="escudo"):
    p = PAL; pcs = []
    pcs.append(Pc("escudo", fig, p["gold"], ellipse(0, 0, 30, 30, 0, 18)))
    pcs.append(Pc("escudo_campo", fig, p["cape"], ellipse(0, 0, 24, 24, 0, 18), cls="inner"))
    # emblema: cabeça de dragão estilizada (ouro) no campo vermelho
    pcs.append(Pc("emblema", fig, p["gold_l"], [(-13, 6), (-10, -6), (-4, -12), (2, -10), (12, -12), (8, -6), (14, -2), (6, 0),
                                              (10, 6), (2, 4), (-2, 10), (-6, 6)], cls="inner"))
    pcs.append(Pc("emblema_olho", fig, INK, ellipse(0, -5, 1.4, 1.1, 0, 6), cls="inner"))
    for i in range(10):
        a = i / 10 * 2 * math.pi
        pcs.append(Pc(f"rebite{i}", fig, p["gold_d"], ellipse(math.cos(a) * 27, math.sin(a) * 27, 1.3, 1.3, 0, 6), cls="inner"))
    return [q.moved(M) for q in pcs]


def axe(hand, ang, L=100, fig="machado"):
    """Machado grande: hand = mão (ponto de pega a 30% do cabo), ang = direção cabo→lâmina (graus)."""
    p = PAL
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    h0 = A(hand) - d * L * 0.3; h1 = h0 + d * L
    pcs = [Pc("cabo", fig, p["haft"], [h0 + n * 2.4, h1 + n * 2.4, h1 - n * 2.4, h0 - n * 2.4], mode="poly")]
    c = h1 - d * 12
    # lâmina em meia-lua (lado +n) e espigão (lado −n)
    bl = [c + d * 6 + n * 3, c + d * 18 + n * 16, c + d * 10 + n * 30, c - d * 4 + n * 32, c - d * 16 + n * 26, c - d * 10 + n * 14, c - d * 6 + n * 3]
    pcs.append(Pc("lamina", fig, p["blade"], bl))
    pcs.append(Pc("fio", fig, p["blade_d"], [c + d * 12 + n * 18, c + d * 6 + n * 28, c - d * 6 + n * 30, c - d * 13 + n * 25], closed=False, cls="inner", sw=0.8))
    pcs.append(Pc("espigao", fig, p["gold"], [c + d * 4 - n * 3, c - n * 16, c - d * 4 - n * 3], mode="poly"))
    pcs.append(Pc("ponta", fig, p["gold"], [h1 - n * 3, h1 + d * 12, h1 + n * 3], mode="poly"))
    pcs.append(Pc("pomo", fig, p["gold"], ellipse(h0[0], h0[1], 4, 4, 0, 8)))
    return pcs


def bony_hand(name, wrist, ang, s=1.0, fist=True):
    p = PAL
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    c = A(wrist) + d * 4 * s
    pcs = [Pc(name, "corpo", p["bone"], ellipse(c[0], c[1], 5.6 * s, 4.6 * s, ang, 9))]
    if not fist:
        for k in range(4):
            b = c + d * 3.6 * s + n * (k - 1.5) * 2.4 * s
            pcs.append(Pc(f"{name}_dedo{k}", "corpo", p["bone"], brush([b, b + d * 7 * s + n * (k - 1.5) * 1.2], 2.2 * s, 1.2 * s, per=2)))
    return pcs


def guard(J):
    p = PAL; pcs = []
    hip, nk = A(J["hip"]), A(J["neck"])
    up = (nk - hip) / np.linalg.norm(nk - hip); side = np.array([-up[1], up[0]])  # side → direita da tela
    # capa esfarrapada atrás
    cp = J["cape"]
    pcs.append(Pc("capa", "corpo", p["cape_d"], cp))
    shl = nk - side * 34 - up * 4; shr = nk + side * 34 - up * 4
    hl_ = hip - side * 12; hr_ = hip + side * 12

    def leg(tag, hp, fill):
        kn, an = ik(hp, J["a" + tag], L_TH, L_SH, J.get("kb" + tag, 1))
        out = [bone("femur_" + tag, hp, kn, 5.4, 4.4, fill), bone("tibia_" + tag, kn, an, 4.4, 4.0, fill)]
        out.append(plate((kn * 0.35 + an * 0.65), 9, 15, math.degrees(math.atan2(*(an - kn)[::-1])) - 90, p["gold_d"] if tag == J.get("far") else p["gold"], "greva_" + tag))
        out.append(plate(kn, 8, 7, 0, p["gold"], "joelheira_" + tag))
        to = A(J["t" + tag]); dd = to - an
        out.append(Pc("pe_" + tag, "corpo", p["gold_d"], ellipse((an[0] + to[0]) / 2, (an[1] + to[1]) / 2 - 2, np.linalg.norm(dd) / 2 + 5, 6, math.degrees(math.atan2(dd[1], dd[0])), 9)))
        return out

    far = J.get("far", "l")
    pcs += leg("l", hl_, p["bone_d"] if far == "l" else p["bone"]) if far == "l" else []
    pcs += leg("r", hr_, p["bone_d"]) if far == "r" else []
    # pelve e coluna à mostra
    pcs.append(Pc("pelve", "corpo", p["bone"], [hip - side * 16 - up * 2, hip + side * 16 - up * 2, hip + side * 10 - up * 10, hip - side * 10 - up * 10]))
    spine0 = hip + up * 4; spine1 = hip + up * 30
    pcs.append(bone("coluna", spine0, spine1, 5, 5, p["bone"]))
    for i in range(4):
        q = spine0 + (spine1 - spine0) * (0.15 + i * 0.22)
        pcs.append(Pc(f"vertebra{i}", "corpo", INK, [q - side * 4, q + side * 4], closed=False, cls="inner", sw=0.6))
    # costelas de baixo, à mostra entre o peitoral e as faldas
    for i in range(3):
        y = hip + up * (22 + i * 6)
        for s in (-1, 1):
            pcs.append(Pc(f"costela{i}{s}", "corpo", p["bone"], brush([y + side * s * 3, y + side * s * 14 - up * 3, y + side * s * 20 - up * 8], 3.2, 1.6, per=2)))
    pcs += leg("l", hl_, p["bone"]) if far != "l" else []
    pcs += leg("r", hr_, p["bone"]) if far != "r" else []
    # faldas (saia de placas de ouro)
    for i, s in enumerate((-1, -0.35, 0.35, 1)):
        c = hip + side * s * 13 - up * 9
        pcs.append(plate(c, 7.5, 11, math.degrees(math.atan2(*up[::-1])) + 90 + s * 8, p["gold"] if abs(s) < 0.5 else p["gold_d"], f"falda{i}",
                         pts=[(-1, -1), (1, -1), (0.9, 0.8), (0, 1), (-0.9, 0.8)]))
    pcs.append(Pc("cinto", "corpo", p["haft"], [hip - side * 17 + up * 1, hip + side * 17 + up * 1, hip + side * 17 - up * 4, hip - side * 17 - up * 4], mode="poly"))
    pcs.append(Pc("fivela", "corpo", p["gold_l"], ellipse(*(hip - up * 1.5), 4, 3.2, 0, 8), cls="inner"))
    # peitoral maciço
    ch = nk - up * 22
    pcs.append(Pc("peitoral", "corpo", p["gold"], [nk - side * 26 - up * 2, nk - side * 8 + up * 3, nk + side * 8 + up * 3, nk + side * 26 - up * 2,
                                                 ch + side * 28 - up * 6, ch + side * 16 - up * 22, ch - up * 26, ch - side * 16 - up * 22,
                                                 ch - side * 28 - up * 6]))
    pcs.append(Pc("peito_luz", "corpo", p["gold_l"], [nk - side * 18 - up * 4, nk - side * 4 + up * 0, ch - side * 6 - up * 8, ch - side * 20 - up * 2], cls="inner"))
    pcs.append(Pc("peito_quilha", "corpo", INK, [nk - up * 1, ch - up * 24], closed=False, cls="inner", sw=0.7))
    pcs.append(Pc("gema_peito", "corpo", p["gem"], ellipse(*(ch - up * 2), 3.4, 4, 0, 8), cls="inner"))

    def arm(tag, sh, fill, after_props=None):
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        out = [bone("umero_" + tag, sh, el, 5.0, 4.2, fill), bone("antebraco_" + tag, el, wr, 4.4, 4.0, fill)]
        out.append(plate(el * 0.3 + wr * 0.7, 7.5, 11, math.degrees(math.atan2(*(wr - el)[::-1])) - 90, p["gold"], "bracal_" + tag))
        out += bony_hand("mao_" + tag, wr, J.get("hd" + tag, math.degrees(math.atan2(*(wr - el)[::-1]))), 1.0, J.get("fist" + tag, True))
        return out, el, wr

    ordr = J.get("order", ("l", "r"))
    for tag in ordr:
        sh = shl if tag == "l" else shr
        arm_pcs, el, wr = arm(tag, sh, p["bone_d"] if tag == far else p["bone"])
        if J.get("shield") == tag:
            sx, sy, srot, ss = J["shield_place"]
            spcs = shield(tmat(wr[0] + sx, wr[1] + sy, srot, ss, ss * J.get("shield_sq", 1.0)))
            if J.get("shield_front", True):
                pcs += arm_pcs + spcs
            else:
                pcs += spcs + arm_pcs
        elif J.get("axe") == tag:
            apcs = axe(wr, J["axe_ang"], J.get("axe_len", 100))
            pcs += apcs + arm_pcs if J.get("axe_back", False) else arm_pcs + apcs
        else:
            pcs += arm_pcs
        # ombreira de espigões por cima do braço
        pcs.append(plate(sh + up * 2, 15, 11, -12 if tag == "l" else 12, p["gold"], "ombreira_" + tag,
                         pts=[(-1, 0.4), (-0.8, -0.6), (-0.2, -1), (0.6, -0.9), (1, -0.2), (0.9, 0.7), (0, 0.9)]))
        sgn = -1 if tag == "l" else 1
        for k in range(3):
            b = sh + up * (9 - k * 1) + side * sgn * (k * 6 - 4)
            pcs.append(Pc(f"espigao_{tag}{k}", "corpo", p["gold_l"], [b - side * 2.6, b + up * (9 - k * 2) + side * sgn * 3, b + side * 2.6], mode="poly"))
    hx, hy, ha = J["head"]
    pcs += skull_helm(tmat(hx, hy, ha, J.get("hk", 1.25)), J.get("jaw", 0))
    return pcs


CAPE = [(-30, -132), (30, -132), (48, -100), (56, -40), (46, -6), (36, -16), (26, 0), (14, -12), (0, 2), (-14, -12), (-26, 0), (-38, -14), (-50, -4), (-58, -44), (-50, -102)]
POSES = {
    # provocação (taunt): base larga, escudo à frente batido no peito... projetado para a câmera, machado erguido atrás
    "provocar": dict(hip=(0, -76), neck=(4, -132), head=(6, -152, 6), jaw=7, al=(-34, -4), tl=(-46, 0), ar=(34, -4), tr=(46, 0),
                     kbl=-1, kbr=1, wl=(-40, -98), ebl=-1, wr=(52, -150), ebr=1, hdr=-80, far="r",
                     shield="l", shield_place=(-4, 4, -10, 1.15), axe="r", axe_ang=-62, axe_len=92, axe_back=True,
                     order=("r", "l"), cape=CAPE),
    # golpe: machado descendo em diagonal, tronco torcido, escudo para trás
    "golpe": dict(hip=(0, -72), neck=(-10, -126), head=(-14, -146, -12), jaw=4, al=(-40, -4), tl=(-52, 0), ar=(30, -2), tr=(40, 0),
                  kbl=-1, kbr=1, wl=(-44, -110), ebl=1, wr=(-60, -128), ebr=1, far="r",
                  shield="r", shield_place=(8, 6, 20, 0.95), shield_front=False, axe="l", axe_ang=-150, axe_len=110,
                  order=("r", "l"), cape=CAPE),
    # marcha: passo pesado, escudo baixo, machado no ombro
    "marchar": dict(hip=(0, -78), neck=(2, -134), head=(4, -154, 2), jaw=0, al=(-22, -12), tl=(-32, -8), ar=(26, -2), tr=(36, 0),
                    kbl=-1, kbr=1, wl=(-38, -86), ebl=-1, wr=(30, -112), ebr=1, far="l",
                    shield="l", shield_place=(-6, 8, 0, 1.05), axe="r", axe_ang=-120, axe_len=110, axe_back=True, cape=CAPE),
}
GUIDE = {"provocar": [(-46, 0), (-20, -40), (2, -90), (6, -152), (14, -180)],
         "golpe": [(40, 0), (14, -40), (-10, -126), (-50, -150), (-90, -130)],
         "marchar": [(36, 0), (10, -40), (2, -100), (4, -160)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return guard(J)
