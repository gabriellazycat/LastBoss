"""Ficha do TROLL DAS CAVERNAS (comum, raro; regenera e arremessa pedras). Corcunda enorme coberta de musgo e líquen,
braços de gorila (os nós dos dedos quase no chão), pernas curtas e arqueadas, pés chatos de três dedos; cabeça baixa à
frente dos ombros, testa achatada, nariz comprido e caído, mandíbula de baixo enorme com duas presas para cima, orelhas
pontudas para trás, tufos de cabelo ralo, olhinhos amarelos fundos. Pele cinza-azulada (fria: contrasta com a caverna
quente). Unidade: cabeça = 36 u (~1,5× a natural). Curvado ≈ 5 cabeças (180 u); quadril a 2,2; coxa 1,05 / canela 1,1 /
braço 1,65 / antebraço 1,65 (gorila); corcunda ~1,4× o natural.
Vista de costas (back=True): nuca, orelhas, cabelo e só a ponta do nariz e da presa (perfil perdido); coluna e escápulas.
data-fig: troll_corpo, troll_cabeca, troll_pedra. Musgo, coluna, cicatrizes, olhos, boca, dentes, unhas = inner."""
import math
import numpy as np
from geom import *
from brutos_c1 import brute, mitt, bigfoot, deg, unit, perp, INK

PAL = dict(skin="#8c9ca8", skin_d="#687a8a", skin_l="#b0bec6", belly="#a8b4b8", moss="#6f8a3e", moss_d="#4e6a2c", hair="#3a4636",
           eye="#f0dc5a", mouth="#3a1a1e", tusk="#ece2c4", nail="#e2d6b4", rag="#7a6248", rag_d="#5a4634", rock="#8a7e70",
           rock_d="#62584c", rock_l="#ada190", scar="#c4a0a0")


def head(M, J, ctx=None):
    """Cabeça 3/4 olhando para +x (centro 0,0; ~36 u × hk). back=True: vista de trás (perfil perdido)."""
    p = PAL; f = "cabeca"; o = J.get("open", 0.6); jy = 5 * o
    if J.get("back"):
        pcs = [Pc("presa", f, p["tusk"], [(16, 6), (20, -1), (22, 7)], mode="poly"),
               Pc("nariz", f, p["skin_d"], [(12, -4), (20, -2), (24, 6), (19, 9), (13, 4)]),
               Pc("orelha_far", f, p["skin_d"], [(10, -10), (16, -20), (18, -8)]),
               Pc("cabeca", f, p["skin"], [(-14, -8), (-8, -16), (4, -18), (14, -12), (17, -2), (16, 10), (8, 17), (-6, 16), (-15, 8)]),
               Pc("orelha", f, p["skin"], [(-10, -6), (-26, -16), (-30, -10), (-16, 2)]),
               Pc("orelha_in", f, "#8a6a70", [(-14, -6), (-24, -12), (-17, -2)], cls="inner")]
        for i, (x, y, a) in enumerate(((-4, -16, -20), (4, -17, 10), (-10, -11, -40))):
            pcs.append(Pc(f"cabelo{i}", f, p["hair"], [(x - 2.5, y + 1), (x + 4 * math.sin(math.radians(a)) - 1, y - 9), (x + 2.5, y + 1)], mode="poly"))
        pcs.append(Pc("nuca", f, INK, [(-6, 6), (2, 10), (10, 8)], closed=False, cls="inner", sw=0.7))
        return [q.moved(M) for q in pcs]
    pcs = [Pc("orelha", f, p["skin_d"], [(-10, -8), (-28, -18), (-30, -11), (-14, 0)]),
           Pc("orelha_in", f, "#8a6a70", [(-14, -8), (-25, -14), (-16, -3)], cls="inner"),
           Pc("mandibula", f, p["skin_d"], [(-10, 4), (4, 6 + jy * 0.4), (22, 6 + jy), (26, 12 + jy), (20, 19 + jy), (4, 20 + jy), (-8, 14 + jy * 0.5)]),
           Pc("cabeca", f, p["skin"], [(-13, -8), (-6, -15), (6, -16), (15, -12), (21, -6), (20, 2), (12, 8), (-2, 9), (-12, 6), (-16, -1)])]
    for i, (x, y, a) in enumerate(((-4, -14, -20), (5, -15, 15), (-10, -10, -40))):
        pcs.append(Pc(f"cabelo{i}", f, p["hair"], [(x - 2.5, y + 1), (x + 4 * math.sin(math.radians(a)) - 1, y - 9), (x + 2.5, y + 1)], mode="poly"))
    pcs += [Pc("sobrancelha", f, p["skin_d"], [(2, -8), (12, -9), (21, -6), (21, -3.5), (11, -5), (2, -5)], cls="inner"),
            Pc("olho", f, p["eye"], ellipse(9, -3.6, 2.0, 1.5, -6, 7), cls="inner"),
            Pc("pupila", f, INK, ellipse(9.8, -3.6, 0.8, 0.8, 0, 6), cls="inner"),
            Pc("olho_far", f, p["eye"], ellipse(17.6, -3.2, 1.2, 1.1, 0, 6), cls="inner")]
    if o > 0.15:
        pcs.append(Pc("boca", f, p["mouth"], [(6, 8), (22, 8 + jy * 0.6), (21, 11 + jy), (8, 12 + jy * 0.7)], cls="inner"))
        for i, x in enumerate((10, 14, 18)):
            pcs.append(Pc(f"dente{i}", f, p["tusk"], [(x - 1, 8.2), (x, 10), (x + 1, 8.4)], mode="poly", cls="inner"))
    pcs += [Pc("nariz", f, p["skin_l"], [(14, -5), (20, -4), (27, 2), (29, 9), (25, 12), (20, 8), (15, 2)]),
            Pc("narina", f, INK, ellipse(24, 9.6, 1.4, 0.9, 20, 6), cls="inner"),
            Pc("verruga", f, p["skin_d"], ellipse(22, 2, 1.2, 1.2, 0, 6), cls="inner")]
    for i, (x, h) in enumerate(((7, 10), (21, 8))):
        b = 12 + jy * (0.5 + i * 0.4)
        pcs.append(Pc(f"presa{i}", f, p["tusk"], [(x - 2, b + 1), (x - 1.4, b - h * 0.6), (x + 0.6, b - h), (x + 2, b - h * 0.3), (x + 2, b + 1)]))
    return [q.moved(M) for q in pcs]


def head_front(M, o=0.8):
    p = PAL; f = "cabeca"; jy = 5 * o
    pcs = []
    for s in (-1, 1):
        t = "_l" if s < 0 else "_r"
        pcs.append(Pc("orelha" + t, f, p["skin_d"], [(s * 12, -6), (s * 32, -16), (s * 30, -8), (s * 14, 3)]))
    pcs += [Pc("mandibula", f, p["skin_d"], [(-16, 2), (16, 2), (20, 10 + jy), (12, 19 + jy), (-12, 19 + jy), (-20, 10 + jy)]),
            Pc("cabeca", f, p["skin"], [(-14, -8), (-7, -15), (7, -15), (14, -8), (15, 2), (8, 7), (-8, 7), (-15, 2)])]
    for i, x in enumerate((-6, 3, -1)):
        pcs.append(Pc(f"cabelo{i}", f, p["hair"], [(x - 2.5, -13), (x + i - 1, -23), (x + 2.5, -13)], mode="poly"))
    pcs += [Pc("sobrancelha", f, p["skin_d"], [(-14, -7), (0, -4), (14, -7), (14, -4), (0, -1.5), (-14, -4)], cls="inner")]
    for s in (-1, 1):
        t = "_l" if s < 0 else "_r"
        pcs += [Pc("olho" + t, f, p["eye"], ellipse(s * 6, -2, 1.8, 1.4, 0, 7), cls="inner"),
                Pc("pupila" + t, f, INK, ellipse(s * 6, -2, 0.8, 0.8, 0, 6), cls="inner")]
    pcs += [Pc("boca", f, p["mouth"], [(-12, 8), (12, 8), (11, 11 + jy), (-11, 11 + jy)], cls="inner"),
            Pc("nariz", f, p["skin_l"], [(-3, -3), (3, -3), (5, 8), (2, 12), (-2, 12), (-5, 8)])]
    for s in (-1, 1):
        x = s * 9; b = 13 + jy
        pcs.append(Pc("presa" + ("_l" if s < 0 else "_r"), f, p["tusk"], [(x - 2, b + 1), (x - 1.2, b - 6), (x + s * 0.8, b - 10), (x + 2, b + 1)]))
    return [q.moved(M) for q in pcs]


def _hand(name, wr, ang, mode, fill, ctx):
    return mitt(name, wr, ang, 1.5, mode, fill, PAL["nail"], nfing=3, fat=1.1, claw=5.0 if mode in ("open", "claw") else 0)


def _foot(name, an, to, fill, ctx):
    return bigfoot(name, an, to, 1.55, fill, PAL["nail"], ntoe=3)


def _over(ctx):
    p = PAL; P = ctx["P"]; J = ctx["J"]
    out = []
    if J.get("back"):
        out += [Pc("coluna", "corpo", INK, [P(-26, 1.04), P(-30, 0.7), P(-26, 0.36), P(-18, 0.08)], closed=False, cls="inner", sw=1.0),
                Pc("escapula", "corpo", INK, [P(-10, 0.98), P(-4, 0.82), P(-12, 0.68)], closed=False, cls="inner", sw=0.8),
                Pc("escapula2", "corpo", INK, [P(-36, 0.9), P(-38, 0.74)], closed=False, cls="inner", sw=0.8)]
    else:
        out += [Pc("barriga", "corpo", p["belly"], [P(8, 0.8), P(26, 0.72), P(30, 0.42), P(24, 0.12), P(10, 0.08), P(6, 0.4)], op=0.9),
                Pc("dobra", "corpo", INK, [P(10, 0.62), P(22, 0.58), P(30, 0.62)], closed=False, cls="inner", sw=0.7)]
    # musgo e líquen na corcunda (manchas presas ao contorno das costas)
    for i, (s, t, w, h) in enumerate(((-30, 0.62, 10, 7), (-22, 1.06, 12, 6), (-34, 0.32, 7, 5), (-8, 1.16, 8, 4))):
        q = P(s, t)
        out.append(Pc(f"musgo{i}", "corpo", p["moss"], blob(q[0], q[1], w, 300 + i, 9, 0.3, h / w), cls="inner", op=0.95))
    out.append(Pc("cicatriz", "corpo", p["scar"], [P(-20, 0.5), P(-12, 0.62)], closed=False, cls="inner", sw=1.0))
    # tanga de trapo
    out.append(Pc("tanga", "corpo", p["rag"], [P(-22, 0.12), P(22, 0.08), P(20, -0.18), P(12, -0.32), P(4, -0.16), P(-6, -0.36), P(-16, -0.2), P(-24, -0.26)]))
    out.append(Pc("tanga_corda", "corpo", p["rag_d"], [P(-23, 0.14), P(23, 0.1), P(23, 0.04), P(-23, 0.08)], mode="poly", cls="inner"))
    return out


def rock(r=26, seed=7, dx=0, dy=-18):
    """Pedregulho erguido entre as duas mãos (centro = meio dos pulsos + (dx, dy))."""
    def f(ctx, tag):
        w = (ctx["wr_l"] + ctx["wr_r"]) / 2 if "wr_l" in ctx and "wr_r" in ctx else ctx["wr_" + tag]
        c = w + np.array([dx, dy])
        p = PAL
        out = [Pc("pedra", "pedra", p["rock"], blob(c[0], c[1], r, seed, 11, 0.16, 0.86)),
               Pc("pedra_luz", "pedra", p["rock_l"], blob(c[0] - r * 0.3, c[1] - r * 0.3, r * 0.45, seed + 1, 8, 0.2, 0.7), cls="inner", op=0.8),
               Pc("pedra_racha", "pedra", INK, [(c[0] - r * 0.1, c[1] - r * 0.7), (c[0] + r * 0.1, c[1] - r * 0.2), (c[0] - r * 0.05, c[1] + r * 0.3)], closed=False, cls="inner", sw=0.8),
               Pc("pedra_musgo", "pedra", p["moss"], blob(c[0] + r * 0.4, c[1] - r * 0.55, r * 0.22, seed + 2, 7, 0.3, 0.6), cls="inner")]
        f.center = c
        return out
    f.center = None
    return f


K = dict(pal=PAL, L=(38, 40, 60, 60), sh=(-24, 18, 0.92), hipj=(-12, 12, 0.02),
         torso=[(-20, -0.1), (-30, 0.2), (-37, 0.5), (-38, 0.8), (-28, 1.06), (-8, 1.2), (10, 1.17), (22, 1.0), (30, 0.78), (32, 0.5),
                (28, 0.22), (18, -0.06), (0, -0.14), (-12, -0.12)],
         wleg=(13, 12, 9, 10.5, 7.5), warm=(12.5, 10.5, 8, 12, 7.5), knee=10, shoulder=15,
         hand=_hand, foot=_foot, head=head, over_torso=_over)

POSES = {
    # andar nos nós dos dedos: corcunda no alto, braço da frente apoiado no chão, cabeça baixa à frente
    "andar": dict(hip=(0, -76), neck=(40, -136), head=(62, -134, 6), hk=1.3, open=0.3, far="l",
                  a_l=(-30, -6), t_l=(-14, -2), a_r=(24, -4), t_r=(44, -2),
                  w_l=(-10, -40), eb_l=1, hd_l=110, hm_l="fist", w_r=(84, -22), eb_r=1, hd_r=90, hm_r="fist"),
    # arremessar (3/4 frente): pedra erguida sobre a cabeça com as duas mãos, tronco jogado para trás
    "arremessar": dict(hip=(0, -80), neck=(-16, -150), head=(4, -150, -6), hk=1.3, open=1.0, far="l",
                       a_l=(-34, -2), t_l=(-18, 0), a_r=(38, -4), t_r=(58, -2),
                       w_l=(-58, -188), eb_l=-1, hd_l=-70, hm_l="open", w_r=(12, -194), eb_r=1, hd_r=-110, hm_r="open",
                       prop_under=rock(30, 7, 0, -26)),
    # arremessar de costas: o mesmo instante visto por trás (câmera sobre o ombro), olhando para a direita-fundo
    "arremessar_costas": dict(hip=(0, -80), neck=(6, -150), head=(16, -160, 6), hk=1.3, open=1.0, far="r", back=True, near_lit=True, sh=(-34, 30, 0.92),
                              a_l=(-36, -2), t_l=(-20, 0), a_r=(40, -6), t_r=(56, -4),
                              w_l=(-46, -196), eb_l=-1, hd_l=-70, hm_l="open", w_r=(42, -204), eb_r=1, hd_r=-110, hm_r="open",
                              prop_under=rock(32, 9, 0, -26)),
    # ameaça regenerando: agachado, braços abertos com as garras, rugido; feridas fechando
    "ameaca": dict(hip=(0, -66), neck=(30, -132), head=(50, -136, 14), hk=1.3, open=1.0, far="l",
                   a_l=(-40, -2), t_l=(-24, 0), a_r=(42, -2), t_r=(62, 0),
                   w_l=(-62, -100), eb_l=1, hd_l=200, hm_l="claw", w_r=(96, -70), eb_r=1, hd_r=10, hm_r="claw"),
}
GUIDE = {"andar": [(-14, -2), (-6, -40), (0, -76), (40, -136), (70, -150)],
         "arremessar": [(58, -2), (24, -40), (0, -80), (-16, -150), (-30, -230)],
         "arremessar_costas": [(56, -4), (24, -40), (0, -80), (6, -150), (0, -240)],
         "ameaca": [(-24, 0), (-10, -34), (0, -66), (30, -132), (60, -150)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return brute(J, K)


def ficha():
    from fichas_l1 import svg_wrap, ruler, ground_line
    from fichas_lib import txt, pose_g, swatches
    W, H = 1300, 640
    P = [txt(20, 30, "FICHA · TROLL DAS CAVERNAS (comum, raro) — corcunda com musgo, braços de gorila, nariz comprido, presas de baixo; regenera e arremessa pedras", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 36 u (~1,5× a natural). Curvado ≈ 5 cabeças (180 u): quadril 2,2 · coxa 1,05 / canela 1,1 · braço 1,65 / antebraço 1,65 (os nós quase no chão) · mão 0,85.", 10),
         txt(20, 62, "IK: joelho para a frente, cotovelo para trás. Pele cinza-azulada (fria) contra a caverna quente; olhinhos amarelos = brilho do foco. Mãos e pés de 3 dedos com unhas grossas.", 10),
         txt(20, 76, "data-fig: troll_corpo (tronco, tanga, membros, mãos, pés), troll_cabeca, troll_pedra. Musgo, coluna/escápulas (de costas), cicatriz, olhos, boca, dentes, unhas = inner.", 10),
         ruler(40, 92, 36 * 1.5, 5, PAL["skin"], PAL["skin_d"], "1 cabeça = 36 u (régua ×1,5)")]
    P.append(pose_g("cabeca_34", head(T(0, 0), dict(open=0.8)), (90, 200, 2.4), "troll", label="cabeça · 3/4, rugindo", ly=60))
    P.append(pose_g("cabeca_frente", head_front(T(0, 0), 0.8), (90, 380, 2.4), "troll", label="cabeça · frente", ly=66))
    P.append(pose_g("cabeca_costas", head(T(0, 0), dict(back=True)), (90, 520, 1.8), "troll", label="cabeça · costas (perfil perdido)", ly=46))
    for i, (nm, lab, sub) in enumerate([("andar", "andar nos nós dos dedos", "corcunda no alto"),
                                        ("arremessar", "arremessar · pedra no alto", "tronco jogado para trás"),
                                        ("arremessar_costas", "arremessar · de costas", "câmera sobre o ombro"),
                                        ("ameaca", "ameaça · regenerando", "garras abertas, rugido")]):
        x = 300 + i * 235; y = 590
        P.append(ground_line(x, y, 190))
        P.append(pose_g(nm, pose(nm), (x, y, 1.4), "troll", GUIDE[nm], lab, sub, ly=24))
    P.append(swatches(1190, 110, [(k, PAL[k]) for k in ("skin", "skin_d", "skin_l", "belly", "moss", "hair", "eye", "tusk", "rag", "rock")]))
    return svg_wrap(W, H, P), (W, H)
