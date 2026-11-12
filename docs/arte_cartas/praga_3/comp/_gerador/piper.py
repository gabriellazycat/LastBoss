"""Ficha do Flautista Corrompido: humano magro e curvado, casaco bicolor esfarrapado (vermelho/mostarda), chapéu cônico
caído para trás com pena, meias bicolores, sapatos de bico; flauta de osso. Pele cinza-esverdeada, olho verde aceso.
Perfil 3/4 olhando para +x, chão em y=0. Unidade: cabeça = 20 u (queixo→topo do crânio, sem chapéu).
Altura ≈ 7,5 cabeças (150 u); ombro a 6,2; quadril a 3,8; coxa 1,9; canela 1,8; braço 1,5; antebraço 1,3; mão 0,5.
Braços e pernas resolvidos por IK de dois ossos (cotovelo para baixo/trás, joelho para a frente) — articulações plausíveis.
data-fig: flautista_corpo (tronco, casaco, braços, mãos, pernas, sapatos = 1), flautista_cabeca (cabeça+cabelo+chapéu+pena = 1),
flautista_flauta (flauta = 1). Olho, boca, orelha, listras, remendos, manchas, furos da flauta = inner."""
import base  # noqa: F401
import math
import numpy as np
from geom import *

INK = "#2b1a10"
PAL = dict(skin="#b8bea0", skin_d="#8e957a", coat="#9a3a32", coat_d="#6c2a28", motley="#c8963a", motley_d="#9a7230",
           hose_n="#c8963a", hose_f="#7a2e2a", shoe="#3a2a2c", hat="#4e2a44", hat_d="#3a1f34", band="#c8963a",
           feather="#7aa03a", flute="#e6dab8", hair="#5a5a4e", eye="#c8f050", mouth="#3a1a1a", stain="#8a9a3a")
L_TH, L_SH, L_UA, L_FA = 38, 36, 30, 26


def ik(a, c, l1, l2, sign):
    a, c = A(a), A(c)
    d = c - a; dist = float(np.linalg.norm(d))
    dist = min(dist, (l1 + l2) * 0.999); dist = max(dist, abs(l1 - l2) + 1e-3)
    u = d / (np.linalg.norm(d) + 1e-9)
    cosA = (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)
    ang = math.acos(max(-1, min(1, cosA))) * sign
    R_ = np.array([[math.cos(ang), -math.sin(ang)], [math.sin(ang), math.cos(ang)]])
    b = a + (R_ @ u) * l1
    c2 = a + u * dist
    return b, c2


def tatter(p0, p1, n, depth, seed=3):
    """Barra esfarrapada de p0 a p1 (dentes para 'baixo' = normal à direita do sentido)."""
    r = np.random.default_rng(seed)
    p0, p1 = A(p0), A(p1); d = p1 - p0; nn = np.array([d[1], -d[0]]) / (np.linalg.norm(d) + 1e-9)
    out = []
    for i in range(1, 2 * n):
        t = i / (2 * n)
        q = p0 + d * t
        if i % 2 == 1:
            q = q - nn * depth * (0.6 + r.random() * 0.8)
        out.append(q)
    return out


# ---------------------------------------------------------------- cabeça (centro do crânio em 0,0; +x = frente)
HEAD = [(-8.5, -4), (-7, -9), (-1, -11.5), (5.5, -9.8), (8.6, -5.5), (9.2, -2), (15, 1.8), (9.4, 3.2), (9.6, 5), (7.6, 9.4),
        (3, 10), (-2, 8), (-6, 4.5)]
HAIR = [(-6, -6), (-10, -3), (-13, 4), (-12, 12), (-9, 18), (-6, 10), (-4, 14), (-2, 6), (-3, 0)]
HAT_CONE = [(-9, -9), (-11, -20), (-17, -30), (-29, -36), (-24, -30), (-14, -24), (-4, -21), (5, -17), (8, -9)]
HAT_BRIM = [(-16, -6), (-6, -11), (8, -11.5), (17, -8), (14, -5.5), (2, -7), (-10, -4)]
FEATHER = [(4, -14), (-2, -26), (-12, -38), (-22, -46)]
MOUTH_PT = (9.4, 4.4)


def head(M, open_=False, grin=True):
    p = PAL; pcs = []
    pcs.append(Pc("cabelo", "cabeca", p["hair"], HAIR))
    pcs.append(Pc("cabeca", "cabeca", p["skin"], HEAD))
    pcs.append(Pc("bochecha", "cabeca", p["skin_d"], [(-5, 2), (0, 3), (5, 7), (2, 9.5), (-3, 7.5)], cls="inner", op=0.8))
    pcs.append(Pc("orelha", "cabeca", p["skin_d"], [(-3, -1), (-7, -6), (-5.5, 1.5), (-3, 3)], cls="inner"))
    pcs.append(Pc("olheira", "cabeca", "#5a6a4a", ellipse(4.6, -3, 3.4, 2.4, -8, 8), cls="inner", op=0.8))
    pcs.append(Pc("olho", "cabeca", p["eye"], [(2.6, -3), (4.6, -4.4), (7, -3.2), (4.8, -2.2)], cls="inner"))
    pcs.append(Pc("sobrancelha", "cabeca", INK, [(1.5, -5), (5, -6.6), (8.6, -6.2)], closed=False, cls="inner", sw=1.1))
    if grin:
        pcs.append(Pc("boca", "cabeca", INK, [(9, 5.6), (6, 6.4), (3.4, 5)], closed=False, cls="inner", sw=0.9))
    pcs.append(Pc("chapeu_cone", "cabeca", p["hat"], HAT_CONE))
    pcs.append(Pc("chapeu_aba", "cabeca", p["hat_d"], HAT_BRIM))
    pcs.append(Pc("chapeu_fita", "cabeca", p["band"], [(-9, -10), (8, -10.5), (7.4, -13), (-9.6, -12.6)], cls="inner", mode="poly"))
    pcs.append(Pc("pena", "cabeca", p["feather"], brush(FEATHER, 5.5, 0.6, per=4)))
    pcs.append(Pc("pena_haste", "cabeca", INK, FEATHER, closed=False, cls="inner", sw=0.6))
    return [q.moved(M) for q in pcs]


def head_front(M):
    p = PAL
    pcs = [Pc("cabelo", "cabeca", p["hair"], [(-12, -4), (-14, 8), (-10, 16), (-8, 6), (8, 6), (10, 16), (14, 8), (12, -4)]),
           Pc("cabeca", "cabeca", p["skin"], [(-8.5, -6), (-7, -10.5), (0, -12), (7, -10.5), (8.5, -6), (8, 3), (4, 9), (0, 11), (-4, 9), (-8, 3)]),
           Pc("nariz", "cabeca", p["skin_d"], [(0, -4), (1.6, 3), (0, 5), (-1.6, 3)], cls="inner"),
           Pc("olho_l", "cabeca", p["eye"], ellipse(-4, -3, 2.2, 1.1, 8, 6), cls="inner"),
           Pc("olho", "cabeca", p["eye"], ellipse(4, -3, 2.2, 1.1, -8, 6), cls="inner"),
           Pc("boca", "cabeca", INK, [(-4, 6.4), (0, 7.4), (4, 6.4)], closed=False, cls="inner", sw=0.9),
           Pc("chapeu_cone", "cabeca", p["hat"], [(-9, -9), (-7, -22), (-2, -34), (6, -40), (4, -30), (6, -20), (9, -9)]),
           Pc("chapeu_aba", "cabeca", p["hat_d"], ellipse(0, -9, 17, 3.6, 0, 12)),
           Pc("pena", "cabeca", p["feather"], brush([(6, -12), (12, -24), (14, -38)], 5, 0.6, per=4))]
    return [q.moved(M) for q in pcs]


def hand(name, c, ang, fill, curl=0.0, spread=50, L=8, fig="corpo"):
    """Mão longa e ossuda: palma + 4 dedos (curl>0 = dedos fechando em volta da flauta)."""
    pcs = []
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))])
    c = A(c)
    pcs.append(Pc(name, fig, fill, ellipse(c[0], c[1], 3.8, 2.7, ang, 8)))
    for k in range(4):
        a = math.radians(ang - spread / 2 + k * spread / 3)
        dd = np.array([math.cos(a), math.sin(a)]); nn = np.array([-dd[1], dd[0]])
        b = c + dd * 2.8
        m = b + dd * L * 0.55
        tip = m + (dd * (1 - curl) + nn * curl) * L * 0.5
        pcs.append(Pc(f"{name}_dedo{k}", fig, fill, tube([b, m, tip], [1.15, 0.95, 0.7], cap0=0.3, cap1=0.8, per=2)))
    return pcs


def shoe(name, ankle, toe, fill):
    a, t = A(ankle), A(toe); d = t - a; L = np.linalg.norm(d); d /= L; n = np.array([-d[1], d[0]])
    if n[1] > 0:
        n = -n  # n aponta para cima do pé
    tip = t + d * 6 + n * 4
    return Pc(name, "corpo", fill, [a + n * 4, a + d * L * 0.6 + n * 3, t + n * 1.5, tip, t - n * 0.5 + d * 2, t - n * 2.6, a - n * 3.4, a - d * 2.5])


def piper(J):
    p = PAL; pcs = []
    hc = A(J["hip"]); nk = A(J["neck"])
    up = (nk - hc) / np.linalg.norm(nk - hc); fwd = np.array([-up[1], up[0]]) * -1  # fwd: perpendicular ao tronco, para +x
    if fwd[0] < 0:
        fwd = -fwd
    hx, hy, ha = J["head"]
    Mh = tmat(hx, hy, ha, 1.0)
    mouth = ap(Mh, [MOUTH_PT])[0]
    # flauta: da boca na direção 'fdir' (ou da mão, se 'flute_hand')
    fa = math.radians(J["fdir"]); fd = np.array([math.cos(fa), math.sin(fa)]); fn = np.array([-fd[1], fd[0]])
    f0 = A(J["flute_from"]) if "flute_from" in J else mouth + fd * 0.6
    FL = J.get("flen", 44)
    # pernas (longe primeiro)
    legs = {}
    for s in ("f", "n"):
        hip = hc + fwd * (2 if s == "n" else -2)
        knee, ank = ik(hip, J["ank_" + s], L_TH, L_SH, J.get("knee_" + s, -1))
        legs[s] = (hip, knee, ank)
    hipf, kneef, ankf = legs["f"]
    pcs.append(Pc("perna_l", "corpo", p["hose_f"], tube([hipf, kneef, ankf], [4.6, 3.4, 2.4], cap0=0.4, cap1=0.4, per=4)))
    pcs.append(shoe("sapato_l", ankf, J["toe_f"], p["shoe"]))
    # braço de longe (atrás do tronco)
    arms = {}
    for s in ("f", "n"):
        sh = A(J["sh_" + s])
        if "wr_" + s in J:
            wr = A(J["wr_" + s])
        else:
            wr = f0 + fd * FL * J["grip_" + s] - fn * 2.6 - fd * 3.0
        el, wr2 = ik(sh, wr, L_UA, L_FA, J.get("elb_" + s, 1))
        arms[s] = (sh, el, wr2)
    shf, elf, wrf = arms["f"]
    pcs.append(Pc("braco_l", "corpo", p["coat_d"], tube([shf, elf, wrf], [4.4, 3.6, 2.8], cap0=0.5, cap1=0.3, per=4)))
    # casaco (costas), tronco, casaco (frente)
    sp = [hc, hc * 0.5 + nk * 0.5 + fwd * J.get("hunch", 4) * 0.5, hc * 0.2 + nk * 0.8 + fwd * J.get("hunch", 4), nk]
    pcs.append(Pc("casaco", "corpo", p["coat"], J["coat"]))
    pcs.append(Pc("tronco", "corpo", p["coat"], tube(sp, [7, 8, 9, 5], [8, 9, 10, 5], cap0=0.6, cap1=0.6, per=4)))
    pcs.append(Pc("gola", "corpo", p["motley"], [nk - up * 3 - fwd * 8, nk + up * 4 - fwd * 5, nk + up * 4 + fwd * 6, nk - up * 4 + fwd * 8], mode="cr"))
    # remendo bicolor (metade mostarda do casaco: o "pied" do flautista) e manchas de peste
    pcs.append(Pc("casaco_retalho", "corpo", p["motley"], J["patch"], cls="inner", op=0.95))
    for k, (x, y, r) in enumerate(J.get("stains", [])):
        pcs.append(Pc(f"mancha{k}", "corpo", p["stain"], blob(x, y, r, 40 + k, 7, 0.3), cls="inner", op=0.8))
    pcs.append(Pc("cinto", "corpo", p["shoe"], [hc + up * 6 - fwd * 9, hc + up * 6 + fwd * 9, hc + up * 2 + fwd * 9, hc + up * 2 - fwd * 9], mode="poly"))
    # perna de perto
    hipn, kneen, ankn = legs["n"]
    pcs.append(Pc("perna", "corpo", p["hose_n"], tube([hipn, kneen, ankn], [5, 3.6, 2.6], cap0=0.4, cap1=0.4, per=4)))
    for k in range(3):
        t = 0.25 + k * 0.25
        q = kneen + (ankn - kneen) * t; dd = (ankn - kneen) / np.linalg.norm(ankn - kneen); nn = np.array([-dd[1], dd[0]])
        pcs.append(Pc(f"listra{k}", "corpo", p["coat_d"], [q - nn * 2.2 - dd * 1.2, q + nn * 2.2 + dd * 1.2], closed=False, cls="inner", sw=1.2))
    pcs.append(shoe("sapato", ankn, J["toe_n"], p["shoe"]))
    # flauta
    f1 = f0 + fd * FL
    pcs.append(Pc("flauta", "flauta", p["flute"], [f0 + fn * 1.5, f1 + fn * 2.0 - fd * 4, f1 + fn * 3.6, f1 + fd * 1.2, f1 - fn * 3.6, f1 - fn * 2.0 - fd * 4, f0 - fn * 1.5], mode="poly"))
    for k in range(4):
        q = f0 + fd * FL * (0.36 + k * 0.1)
        pcs.append(Pc(f"furo{k}", "flauta", INK, ellipse(q[0], q[1], 0.9, 0.7, J["fdir"], 6), cls="inner"))
    pcs.append(Pc("flauta_no", "flauta", "#c8b890", [f0 + fd * FL * 0.22 + fn * 1.8, f0 + fd * FL * 0.22 - fn * 1.8], closed=False, cls="inner", sw=1.0))
    # braço de perto + mãos
    sh, el, wr = arms["n"]
    pcs.append(Pc("braco", "corpo", p["coat"], tube([sh, el, wr], [5.2, 4.2, 3.2], cap0=0.5, cap1=0.3, per=4)))
    pcs.append(Pc("punho_manga", "corpo", p["motley"], ellipse(wr[0], wr[1], 3.6, 3.0, J["fdir"], 8)))
    hf = J.get("hands", {})
    af, cf = hf.get("f", (J["fdir"] + 70, 0.75))
    an, cn = hf.get("n", (J["fdir"] + 70, 0.75))
    pcs += hand("mao_l", wrf + (wrf - elf) / np.linalg.norm(wrf - elf) * 3, af, p["skin_d"], cf)
    pcs += hand("mao", wr + (wr - el) / np.linalg.norm(wr - el) * 3, an, p["skin"], cn)
    pcs += head(Mh)
    return pcs


POSES = {
    # tocar dançando: passo com joelho alto, tronco inclinado para a frente, flauta para baixo-frente
    "tocar_andar": dict(
        hip=(0, -76), neck=(14, -122), hunch=6, head=(23, -133, 14), fdir=38, flen=44, grip_f=0.42, grip_n=0.74,
        sh_f=(6, -118), sh_n=(14, -118), elb_f=1, elb_n=1,
        ank_f=(-22, -6), toe_f=(-10, -1), knee_f=-1, ank_n=(26, -42), toe_n=(38, -38), knee_n=-1,
        coat=[(2, -124), (16, -126), (22, -112), (18, -90), (16, -74)] + tatter((16, -74), (-26, -50), 5, 7, 11) + [(-26, -50), (-18, -80), (-8, -112)],
        patch=[(4, -120), (12, -122), (14, -100), (10, -80), (0, -72), (-12, -66), (-10, -90)],
        stains=[(-14, -66, 3.2), (8, -98, 2.4)]),
    # tocar saltando: no ar, corpo em diagonal, perna de perto encolhida, de longe esticada para trás, casaco esvoaçando
    "tocar_salto": dict(
        hip=(0, -92), neck=(26, -134), hunch=7, head=(36, -144, 22), fdir=48, flen=44, grip_f=0.42, grip_n=0.74,
        sh_f=(18, -130), sh_n=(26, -130), elb_f=1, elb_n=1,
        ank_f=(-52, -70), toe_f=(-62, -62), knee_f=-1, ank_n=(12, -56), toe_n=(24, -54), knee_n=-1,
        coat=[(16, -136), (30, -138), (34, -124), (26, -100), (14, -86)] + tatter((14, -86), (-40, -96), 5, 8, 12) + [(-40, -96), (-20, -112), (2, -128)],
        patch=[(18, -132), (26, -134), (24, -112), (14, -94), (2, -90), (-14, -94), (-4, -110)],
        stains=[(-22, -96, 3.4), (20, -114, 2.2)]),
    # ameaça: de pé, curvado, flauta apontada como batuta, mão de longe chamando com os dedos
    "ameaca": dict(
        hip=(0, -76), neck=(8, -124), hunch=7, head=(15, -136, -6), fdir=-14, flen=44, flute_from=(38, -96),
        sh_f=(2, -120), sh_n=(10, -120), wr_f=(-8, -148), wr_n=(34, -98), elb_f=1, elb_n=1,
        hands=dict(f=(-100, 0.55), n=(-10, 0.85)),
        ank_f=(-14, -5), toe_f=(-2, 0), knee_f=-1, ank_n=(16, -5), toe_n=(30, 0), knee_n=-1,
        coat=[(-4, -126), (10, -128), (16, -112), (16, -92), (18, -72)] + tatter((18, -72), (-20, -66), 5, 7, 13) + [(-20, -66), (-16, -94), (-12, -116)],
        patch=[(0, -122), (8, -124), (10, -104), (8, -84), (-2, -74), (-12, -70), (-10, -96)],
        stains=[(-10, -72, 3), (6, -106, 2.2)]),
}
GUIDE = {"tocar_andar": [(-18, -2), (-6, -50), (8, -96), (22, -130), (46, -150)],
         "tocar_salto": [(-60, -64), (-20, -88), (12, -116), (36, -146), (60, -164)],
         "ameaca": [(-10, 0), (0, -50), (8, -100), (16, -136), (20, -170)]}


def pose(name):
    return piper(POSES[name])
