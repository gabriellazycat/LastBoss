"""Ficha do OGRO (comum, Tanque; o golpe empurra o herói). Gigante gordo e forte: barriga enorme, ombros de touro, quase
sem pescoço (cabeça baixa entre os trapézios), pernas curtas e grossas, braços de lutador, clava de tronco com cravos.
Pele ocre-bronzeada, tanga de pele marrom com cinto de corda, bracelete de ferro; careca com um tufo de cabelo amarrado,
testa baixa, olhos pequenos, nariz de batata, mandíbula larga com presas de baixo (prognata), orelha de abano.
Unidade: cabeça = 38 u (cabeça ~1,5× a natural: criatura grande). Altura em pé ≈ 5 cabeças (190 u): quadril a 2,05;
ombro a 3,6; coxa 1,05 / canela 1,0 / braço 1,2 / antebraço 1,15; mão = 0,8 cabeça; ombros ≈ 1,7 cabeça de largura.
data-fig: ogro_corpo, ogro_cabeca, ogro_clava. Umbigo, dobras, olhos, boca, presas, unhas, cravos = inner/peças da clava."""
import math
import numpy as np
from geom import *
from brutos_c1 import brute, muscle, mitt, bigfoot, deg, unit, perp, INK

PAL = dict(skin="#c99a6a", skin_d="#a27a50", skin_l="#e0b888", belly="#d8ae80", fur="#6e4a2c", fur_d="#4e3420", rope="#c8a46a",
           iron="#6a6e74", wood="#8a5a32", wood_d="#64401f", eye="#fff2c0", iris="#3a2410", mouth="#4a1a12", tusk="#f0e4c0",
           hair="#3a2618", nail="#e8d4a8")


def head(M, J, ctx=None):
    """Cabeça 3/4 olhando para +x. Centro (0,0); ~34 u de altura × hk."""
    p = PAL; o = J.get("open", 0.6); f = "cabeca"
    jy = 4 * o
    pcs = [Pc("orelha", f, p["skin_d"], [(-12, -4), (-19, -10), (-23, -3), (-21, 6), (-14, 6)]),
           Pc("orelha_in", f, "#b8805a", [(-14, -2), (-19, -6), (-20, 1), (-16, 3)], cls="inner"),
           Pc("tufo", f, p["hair"], [(-6, -16), (-10, -24), (-5, -30), (-1, -25), (2, -31), (4, -23), (2, -16)]),
           Pc("cabeca", f, p["skin"], [(-12, -13), (-4, -18), (6, -18), (13, -13), (17, -6), (19, 0), (20, 7 + jy), (17, 14 + jy),
                                     (8, 18 + jy), (-6, 17 + jy * 0.6), (-14, 10), (-16, 0), (-15, -8)]),
           Pc("amarra", f, p["rope"], [(-6, -17), (3, -17), (3, -14.5), (-6, -14.5)], mode="poly", cls="inner"),
           Pc("sobrancelha", f, p["skin_d"], [(-1, -10), (8, -9), (17, -8), (18, -5), (8, -4.6), (-1, -6)], cls="inner"),
           Pc("olho_far", f, p["eye"], ellipse(14.5, -4, 2.0, 1.7, 0, 7), cls="inner"),
           Pc("iris_far", f, p["iris"], ellipse(15.2, -4, 1.0, 1.0, 0, 6), cls="inner"),
           Pc("olho", f, p["eye"], ellipse(5, -4, 2.8, 2.2, 0, 8), cls="inner"),
           Pc("iris", f, p["iris"], ellipse(6.4, -4, 1.3, 1.3, 0, 6), cls="inner"),
           Pc("nariz", f, p["skin_l"], [(13, -4), (18, -3), (23, 1), (22, 6), (17, 6.5), (13, 4)]),
           Pc("narina", f, INK, ellipse(19.5, 5, 1.5, 0.9, 10, 6), cls="inner"),
           Pc("bochecha", f, p["skin_d"], [(-2, 6), (5, 10), (10, 9)], closed=False, cls="inner", sw=0.7)]
    if o > 0.15:
        pcs.append(Pc("boca", f, p["mouth"], [(5, 8), (19, 7.5), (18.5, 11 + jy), (15, 13 + jy), (6, 12.5 + jy * 0.7)], cls="inner"))
        for i, x in enumerate((9, 12, 15)):
            pcs.append(Pc(f"dente{i}", f, p["tusk"], [(x - 1.2, 7.8), (x, 9.6), (x + 1.2, 7.8)], mode="poly", cls="inner"))
    else:
        pcs.append(Pc("boca", f, INK, [(5, 10), (12, 11), (19, 9)], closed=False, cls="inner", sw=0.9))
    for i, (x, h) in enumerate(((8.5, 7.5), (17.5, 6.5))):
        b = 11.5 + jy
        pcs.append(Pc(f"presa{i}", f, p["tusk"], [(x - 1.8, b + 1), (x - 1.2, b - h * 0.6), (x + 0.4, b - h), (x + 1.6, b - h * 0.4), (x + 1.8, b + 1)]))
    return [q.moved(M) for q in pcs]


def head_front(M, o=0.7):
    p = PAL; f = "cabeca"; jy = 4 * o
    pcs = []
    for s in (-1, 1):
        t = "_l" if s < 0 else "_r"
        pcs.append(Pc("orelha" + t, f, p["skin_d"], [(s * 14, -4), (s * 23, -10), (s * 26, -2), (s * 23, 7), (s * 15, 6)]))
    pcs += [Pc("tufo", f, p["hair"], [(-4, -16), (-7, -25), (-2, -31), (0, -26), (3, -31), (6, -24), (4, -16)]),
            Pc("cabeca", f, p["skin"], [(-13, -12), (-6, -18), (6, -18), (13, -12), (16, -2), (19, 8 + jy), (15, 16 + jy), (0, 19 + jy),
                                      (-15, 16 + jy), (-19, 8 + jy), (-16, -2)]),
            Pc("amarra", f, p["rope"], [(-4, -17), (4, -17), (4, -14.5), (-4, -14.5)], mode="poly", cls="inner"),
            Pc("sobrancelha", f, p["skin_d"], [(-13, -8), (0, -6), (13, -8), (13, -4.6), (0, -3), (-13, -4.6)], cls="inner")]
    for s in (-1, 1):
        t = "_l" if s < 0 else "_r"
        pcs += [Pc("olho" + t, f, p["eye"], ellipse(s * 6.5, -2, 2.6, 2.1, 0, 8), cls="inner"),
                Pc("iris" + t, f, p["iris"], ellipse(s * 6.2, -2, 1.2, 1.2, 0, 6), cls="inner")]
    pcs += [Pc("nariz", f, p["skin_l"], [(-4, -2), (4, -2), (6, 5), (0, 7.5), (-6, 5)]),
            Pc("boca", f, p["mouth"], [(-11, 9), (11, 9), (10, 12 + jy), (0, 14 + jy), (-10, 12 + jy)], cls="inner")]
    for s in (-1, 1):
        x = s * 8; b = 13 + jy
        pcs.append(Pc("presa" + ("_l" if s < 0 else "_r"), f, p["tusk"], [(x - 1.9, b + 1), (x - 1.2, b - 5), (x + s * 0.6, b - 8), (x + 1.8, b + 1)]))
    return [q.moved(M) for q in pcs]


def _hand(name, wr, ang, mode, fill, ctx):
    return mitt(name, wr, ang, 1.45, mode, fill, PAL["nail"])


def _foot(name, an, to, fill, ctx):
    return bigfoot(name, an, to, 1.5, fill, PAL["nail"])


def _over(ctx):
    p = PAL; P = ctx["P"]; up = ctx["up"]; sd = ctx["side"]
    out = [Pc("barriga_luz", "corpo", p["belly"], [P(14, 0.75), P(38, 0.66), P(46, 0.42), P(40, 0.12), P(22, 0.04), P(18, 0.4)], op=0.9),
           Pc("umbigo", "corpo", INK, [P(36, 0.3), P(39, 0.27), P(37, 0.24)], closed=False, cls="inner", sw=0.8),
           Pc("dobra_peito", "corpo", INK, [P(10, 0.8), P(24, 0.74), P(36, 0.78)], closed=False, cls="inner", sw=0.7),
           Pc("dobra_barriga", "corpo", INK, [P(16, 0.12), P(30, 0.08), P(42, 0.16)], closed=False, cls="inner", sw=0.7)]
    # tanga de pele com cinto de corda: borda recortada
    tg = [P(-26, 0.14), P(-4, 0.1), P(20, 0.08), P(44, 0.12), P(40, -0.12), P(34, -0.34), P(26, -0.22), P(16, -0.4), P(6, -0.26),
          P(-6, -0.42), P(-16, -0.26), P(-26, -0.36), P(-30, -0.1)]
    out.append(Pc("tanga", "corpo", p["fur"], tg))
    out.append(Pc("cinto", "corpo", p["rope"], [P(-28, 0.16), P(46, 0.14), P(46, 0.06), P(-28, 0.08)], mode="poly", cls="inner"))
    out.append(Pc("tanga_pelo", "corpo", p["fur_d"], [P(-14, -0.1), P(-10, -0.24)], closed=False, cls="inner", sw=0.8))
    out.append(Pc("tanga_pelo2", "corpo", p["fur_d"], [P(16, -0.12), P(20, -0.28)], closed=False, cls="inner", sw=0.8))
    return out


def club(ang, L=92):
    """Clava de tronco (cabo fino → cabeça grossa com nós e cravos de ferro), presa pela mão. ang: direção mão→ponta."""
    def f(ctx, tag):
        wr = ctx["wr_" + tag]; el = ctx["el_" + tag]
        d0 = unit(wr - el); c = wr + d0 * 10
        d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = perp(d)
        b = c - d * 12; e = c + d * L
        pts = [b, c + d * L * 0.3, c + d * L * 0.62, c + d * L * 0.86, e]
        p = PAL; fg = "clava"
        out = [Pc("clava", fg, p["wood"], tube(pts, [3.6, 5.5, 9.5, 12.5, 11], [3.6, 5.0, 8.5, 11.5, 10], cap0=0.6, cap1=0.75, per=4))]
        for i, (t, s_) in enumerate(((0.62, 1), (0.8, -1), (0.94, 1), (0.72, -1), (0.88, 0.2))):
            q = c + d * L * t; w = 6 + 7 * t
            base_ = q + n * s_ * w * 0.95
            out.append(Pc(f"cravo{i}", fg, p["iron"], [base_ - d * 2.2, base_ + n * s_ * 6.5 + d * 0.5, base_ + d * 2.2], mode="poly"))
        out.append(Pc("clava_no", fg, p["wood_d"], ellipse(*(c + d * L * 0.5 + n * 2), 2.6, 1.8, ang, 7), cls="inner"))
        out.append(Pc("clava_veio", fg, p["wood_d"], [c + d * L * 0.4 - n * 3, c + d * L * 0.7 - n * 5, c + d * L * 0.9 - n * 4], closed=False, cls="inner", sw=0.8))
        out.append(Pc("clava_faixa", fg, p["rope"], [b + d * 4 + n * 4.2, b + d * 9 + n * 4.4, b + d * 9 - n * 4.4, b + d * 4 - n * 4.2], mode="poly", cls="inner"))
        f.tip = e; f.head = c + d * L * 0.8
        return out
    f.tip = None
    return f


K = dict(pal=PAL, L=(40, 38, 46, 44), sh=(-30, 26, 0.9), hipj=(-14, 16, 0.02),
         torso=[(-22, -0.08), (-30, 0.25), (-38, 0.6), (-44, 0.85), (-36, 1.02), (-18, 1.12), (4, 1.14), (24, 1.06), (36, 0.9), (40, 0.7),
                (48, 0.48), (52, 0.28), (46, 0.06), (30, -0.1), (8, -0.16), (-10, -0.14)],
         wleg=(15, 14, 10, 11, 7.5), warm=(13, 12.5, 9, 13, 8), knee=11, shoulder=15,
         hand=_hand, foot=_foot, head=head, over_torso=_over)


def _bracer(ctx, tag):
    el, wr = ctx["el_" + tag], ctx["wr_" + tag]; d = unit(wr - el); n = perp(d)
    a = wr - d * 16; b = wr - d * 3
    return [Pc("bracelete", "corpo", PAL["iron"], [a + n * 10, b + n * 8.6, b - n * 8.6, a - n * 10], mode="poly")]


def _with(*fs):
    def g(ctx, tag):
        out = []
        for f in fs:
            out += f(ctx, tag)
        return out
    return g


POSES = {
    # andar: passo pesado, clava apoiada no ombro de trás, braço da frente balançando
    "andar": dict(hip=(0, -78), neck=(8, -150), head=(22, -160, 4), hk=1.34, open=0.2, far="l",
                  a_l=(-34, -6), t_l=(-18, -2), a_r=(32, -4), t_r=(52, -2),
                  w_l=(-6, -170), eb_l=1, hd_l=-150, hm_l="grip", w_r=(52, -96), eb_r=1, hd_r=70, hm_r="fist",
                  prop_l=club(-160, 86)),
    # golpe: acabou de varrer de baixo para cima — clava lá no alto à frente, braço de trás jogado atrás, tronco torcido
    "golpe": dict(hip=(0, -74), neck=(20, -144), head=(40, -150, 12), hk=1.34, open=1.0, far="l",
                  a_l=(-50, -10), t_l=(-36, -2), kb_l=-1, a_r=(44, -4), t_r=(64, -2),
                  w_l=(-62, -104), eb_l=1, hd_l=200, hm_l="open", w_r=(118, -196), eb_r=1, hd_r=-50, hm_r="grip",
                  prop_r=_with(club(-62, 96), _bracer)),
    # esmagar: clava erguida acima da cabeça com as duas mãos, peito estufado, prestes a descer
    "esmagar": dict(hip=(0, -80), neck=(-6, -152), head=(10, -160, -8), hk=1.34, open=0.9, far="l",
                    a_l=(-30, -2), t_l=(-14, 0), a_r=(36, -2), t_r=(56, 0),
                    w_l=(-30, -208), eb_l=1, hd_l=-110, hm_l="grip", w_r=(-16, -214), eb_r=-1, hd_r=-120, hm_r="grip",
                    prop_r=club(-160, 92), head_behind_arm=False),
    # rugir: parada de ameaça, base larga, braços abertos com os punhos fechados, inclinado à frente
    "rugir": dict(hip=(0, -72), neck=(18, -142), head=(36, -148, 14), hk=1.34, open=1.0, far="l",
                  a_l=(-44, -2), t_l=(-28, 0), a_r=(46, -2), t_r=(66, 0),
                  w_l=(-58, -116), eb_l=1, hd_l=230, hm_l="fist", w_r=(84, -110), eb_r=-1, hd_r=-30, hm_r="open"),
}
GUIDE = {"andar": [(-18, -2), (-6, -40), (0, -78), (8, -150), (20, -184)],
         "golpe": [(-36, -2), (-20, -40), (0, -74), (20, -144), (118, -196), (160, -280)],
         "esmagar": [(56, 0), (20, -40), (0, -80), (-6, -152), (-30, -250)],
         "rugir": [(-28, 0), (-10, -36), (0, -72), (18, -142), (40, -170)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return brute(J, K)


def ficha():
    from fichas_l1 import svg_wrap, ruler, ground_line
    from fichas_lib import txt, pose_g, swatches
    W, H = 1300, 640
    P = [txt(20, 30, "FICHA · OGRO (comum, Tanque) — gordo e forte, barriga enorme, ombros de touro, quase sem pescoço, clava de tronco com cravos", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 38 u (~1,5× a natural). Em pé ≈ 5 cabeças (190 u): quadril 2,05 · ombro 3,6 · coxa 1,05 / canela 1,0 · braço 1,2 / antebraço 1,15 · mão 0,8 · ombros 1,7 cabeça.", 10),
         txt(20, 62, "IK: joelho para a frente, cotovelo para trás. Pele ocre, tanga de pele com cinto de corda, bracelete de ferro. Presas de baixo, olhos pequenos, nariz de batata, tufo amarrado.", 10),
         txt(20, 76, "data-fig: ogro_corpo (tronco, tanga, membros, mãos, pés), ogro_cabeca (cabeça, orelha, tufo, nariz, presas), ogro_clava (clava + cravos). Olhos, boca, dobras, umbigo, unhas = inner.", 10),
         ruler(40, 92, 38 * 1.5, 5, PAL["skin"], PAL["skin_d"], "1 cabeça = 38 u (régua ×1,5)")]
    P.append(pose_g("cabeca_34", head(T(0, 0), dict(open=0.7)), (90, 200, 2.4), "ogro", label="cabeça · 3/4", ly=60))
    P.append(pose_g("cabeca_frente", head_front(T(0, 0), 0.8), (90, 380, 2.4), "ogro", label="cabeça · frente, rugindo", ly=66))
    for i, (nm, lab, sub) in enumerate([("andar", "andar · passo pesado", "clava no ombro"),
                                        ("golpe", "golpe · varrida para cima", "o herói voa (Tanque, empurra)"),
                                        ("esmagar", "esmagar · clava no alto", "duas mãos, peito estufado"),
                                        ("rugir", "rugir · ameaça", "base larga, braços abertos")]):
        x = 300 + i * 235; y = 590
        P.append(ground_line(x, y, 190))
        P.append(pose_g(nm, pose(nm), (x, y, 1.45 if nm != "golpe" else 1.3), "ogro", GUIDE[nm], lab, sub, ly=24))
    P.append(swatches(1190, 110, [(k, PAL[k]) for k in ("skin", "skin_d", "skin_l", "belly", "fur", "rope", "iron", "wood", "tusk", "hair")]))
    return svg_wrap(W, H, P), (W, H)
