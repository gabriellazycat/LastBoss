"""Ficha do TITÃ DA RUÍNA (comum, lendário; o golpe vira um pisão em área que atordoa). Colosso de pedra feito de
alvenaria de um templo em ruína: tronco de blocos encaixados largo em cima (trapézio), cintura estreita, ombros de
pedregulho; o antebraço da frente é um pedaço de coluna canelada com capitel; pés de laje; núcleo de runa âmbar
brilhando no peito (o foco) com rachaduras; cabeça pequena de elmo de pedra com a fenda do visor acesa; musgo, hera
pendurada e um arbusto crescendo no ombro (pista de escala). Unidade: cabeça = 30 u (pequena de propósito: escala
épica). Em pé ≈ 8,5 cabeças (255 u): quadril 3,7 · coxa 1,8 / canela 1,85 · braço 2,1 / antebraço 2,05 · ombros ≈ 3,6
cabeças de largura. persp=… (câmera baixa) é o escorço da carta: o alto encolhe e o pé perto da câmera cresce.
data-fig: tita_corpo (tronco, membros, mãos, pés, coluna), tita_cabeca. Juntas dos blocos, rachaduras, runa, musgo,
hera, visor = inner. O arbusto do ombro é tita_arbusto."""
import math
import numpy as np
from geom import *
from brutos_c1 import brute, mitt, block, deg, unit, perp, INK

PAL = dict(skin="#a29a8a", skin_d="#77706a", skin_l="#c6bea8", col="#d8ccb0", col_d="#b0a488", moss="#7a9a48", moss_d="#56742e",
           vine="#5c7a34", glow="#ffbe4a", glow_c="#fff0b0", glow_d="#e07a2a", crack="#3a2a20", bush="#6a8a3a", nail="#8a8478")


def head(M, J, ctx=None):
    p = PAL; f = "cabeca"
    pcs = [Pc("elmo", f, p["skin"], [(-13, -12), (-6, -17), (8, -17), (14, -11), (15, 4), (11, 13), (-9, 13), (-14, 4)], mode="poly"),
           Pc("crista", f, p["skin_d"], [(-4, -17), (-2, -24), (6, -24), (8, -17)], mode="poly"),
           Pc("musgo_elmo", f, p["moss"], blob(-2, -17, 7, 41, 8, 0.3, 0.45), cls="inner"),
           Pc("visor", f, INK, [(-9, -4), (13, -4), (13, 0), (4, 0), (4, 9), (0, 9), (0, 0), (-9, 0)], mode="poly", cls="inner"),
           Pc("olho_luz", f, p["glow"], [(-7, -3), (11.5, -3), (11.5, -1), (-7, -1)], mode="poly", cls="inner"),
           Pc("olho_centro", f, p["glow_c"], [(1, -2.8), (8, -2.8), (8, -1.2), (1, -1.2)], mode="poly", cls="inner"),
           Pc("racha_elmo", f, p["crack"], [(10, -16), (7, -10), (9, -6)], closed=False, cls="inner", sw=0.7),
           Pc("junta_elmo", f, p["skin_d"], [(-14, 6), (15, 6)], closed=False, cls="inner", sw=0.7)]
    return [q.moved(M) for q in pcs]


def _limb(name, a, j, b, w, fill, ctx):
    """Membro de blocos: bloco superior, pedregulho na junta, bloco inferior (no braço da frente, uma coluna canelada)."""
    a, j, b = A(a), A(j), A(b); p = PAL
    out = [block(name, a, j + unit(j - a) * 2, w[0] * 2, w[1] * 2, fill, ch=0.22),
           Pc(name + "_junta", "corpo", fill, blob(j[0], j[1], w[2] * 1.15, hash(name) % 97, 8, 0.12))]
    col_arm = name.startswith("braco_") and name.endswith(ctx["near"]) and ctx["J"].get("column", True)
    if col_arm:
        d = unit(b - j); n = perp(d)
        out.append(block(name + "_coluna", j + d * 4, b - d * 4, w[3] * 1.7, w[4] * 1.8, p["col"], ch=0.08))
        out.append(block(name + "_capitel", b - d * 10, b + d * 2, w[4] * 2.6, w[4] * 2.4, p["col_d"], ch=0.15))
        out.append(block(name + "_base", j, j + d * 9, w[3] * 2.3, w[3] * 2.1, p["col_d"], ch=0.15))
        for k in (-1, 0, 1):
            out.append(Pc(f"{name}_canelura{k}", "corpo", p["col_d"], [j + d * 12 + n * k * w[3] * 0.5, b - d * 12 + n * k * w[4] * 0.5], closed=False, cls="inner", sw=0.8))
        out.append(Pc(name + "_quebra", "corpo", p["crack"], [j + d * 26 - n * w[3] * 0.8, j + d * 30, j + d * 27 + n * w[3] * 0.7], closed=False, cls="inner", sw=0.8))
    else:
        out.append(block(name + "_b", j - unit(b - j) * 2, b, w[3] * 2, w[4] * 2, fill, ch=0.22))
        m = (j + b) / 2; n = perp(unit(b - j))
        out.append(Pc(name + "_junta2", "corpo", p["skin_d"], [m - n * w[3] * 0.9, m + n * w[3] * 0.9], closed=False, cls="inner", sw=0.7))
    m = (a + j) / 2; n = perp(unit(j - a))
    out.append(Pc(name + "_racha", "corpo", p["crack"], [m - n * w[1] * 0.6, m + unit(j - a) * 6, m + n * w[1] * 0.3 + unit(j - a) * 10], closed=False, cls="inner", sw=0.7))
    return out


def _hand(name, wr, ang, mode, fill, ctx):
    return mitt(name, wr, ang, 1.7, mode, fill, PAL["nail"], nfing=3, fat=1.15)


def _foot(name, an, to, fill, ctx):
    an, to = A(an), A(to); d = unit(to - an); n = perp(d)
    if n[1] > 0:
        n = -n  # n aponta para cima
    L = np.linalg.norm(to - an)
    pts = [an - d * 14 + n * 4, an - d * 10 + n * 16, an + d * L * 0.3 + n * 16, to + d * 8 + n * 7, to + d * 10 - n * 3, an - d * 16 - n * 3]
    return [Pc(name, "corpo", fill, pts, mode="poly"),
            Pc(name + "_junta", "corpo", PAL["skin_d"], [an + d * L * 0.35 + n * 15, to + d * 4 - n * 2], closed=False, cls="inner", sw=0.7)]


def _back(ctx):
    """Arbusto crescendo no ombro de trás (atrás de tudo) — pista de escala."""
    sh = ctx["joint"]["sh_l"]; up = ctx["up"]
    c = sh + up * 22
    p = PAL
    out = [Pc("arbusto", "arbusto", p["bush"], blob(c[0], c[1], 13, 61, 10, 0.3, 0.8))]
    out.append(Pc("arbusto_tronco", "arbusto", "#6a4a2c", [c - up * 6, c - up * 18], closed=False, cls="inner", sw=1.6))
    return out


def _over(ctx):
    p = PAL; P = ctx["P"]
    out = []
    # juntas de alvenaria (fiadas desencontradas)
    for i, t in enumerate((0.22, 0.46, 0.7, 0.92)):
        w = 30 + t * 22
        out.append(Pc(f"fiada{i}", "corpo", p["skin_d"], [P(-w, t), P(w * 0.95, t + 0.01)], closed=False, cls="inner", sw=0.8))
        for k, s in enumerate((-0.5, 0.15, 0.7) if i % 2 == 0 else (-0.2, 0.45)):
            out.append(Pc(f"junta{i}_{k}", "corpo", p["skin_d"], [P(s * w, t), P(s * w, t + 0.24 if i < 3 else t + 0.16)], closed=False, cls="inner", sw=0.8))
    # núcleo de runa no peito com rachaduras acesas
    c = P(8, 0.66)
    out.append(Pc("runa_halo", "corpo", p["glow_d"], ellipse(c[0], c[1], 15, 15, 0, 12), cls="inner", op=0.75))
    out.append(Pc("runa", "corpo", p["glow"], [c + (0, -11), c + (8, -2), c + (4, 10), c + (-4, 10), c + (-8, -2)], mode="poly", cls="inner"))
    out.append(Pc("runa_centro", "corpo", p["glow_c"], ellipse(c[0], c[1], 3.6, 3.6, 0, 8), cls="inner"))
    for k, (dx, dy) in enumerate(((-26, -14), (24, -20), (20, 24), (-22, 22))):
        out.append(Pc(f"racha_luz{k}", "corpo", p["glow"], [c, c + (dx * 0.5, dy * 0.4 + 3), c + (dx, dy)], closed=False, cls="inner", sw=1.4))
    # musgo e hera pendurada dos ombros
    for i, (s, t, r) in enumerate(((-40, 1.02, 12), (34, 1.05, 9), (-20, 0.3, 7))):
        q = P(s, t)
        out.append(Pc(f"musgo{i}", "corpo", p["moss"], blob(q[0], q[1], r, 500 + i, 9, 0.3, 0.55), cls="inner"))
    for i, (s, L) in enumerate(((-44, 0.42), (-30, 0.3), (40, 0.36))):
        a = P(s, 1.02); b = P(s + 4, 1.02 - L)
        out.append(Pc(f"hera{i}", "corpo", p["vine"], [a, (a + b) / 2 + (3, 0), b], closed=False, cls="inner", sw=1.6))
        for k in range(3):
            q = a + (b - a) * (0.3 + k * 0.3)
            out.append(Pc(f"folha{i}_{k}", "corpo", p["moss"], ellipse(q[0] + 2.5, q[1], 2.6, 1.6, 30, 6), cls="inner"))
    # cinturão de pedra (verga partida)
    out.append(Pc("verga", "corpo", p["skin_d"], [P(-30, 0.08), P(30, 0.08), P(28, -0.06), P(-28, -0.06)], mode="poly"))
    return out


K = dict(pal=PAL, L=(54, 56, 64, 62), sh=(-44, 40, 0.94), hipj=(-18, 18, 0.0), torso_mode="poly",
         torso=[(-26, -0.06), (-34, 0.3), (-46, 0.68), (-58, 0.92), (-50, 1.08), (-22, 1.13), (-8, 1.2), (12, 1.2), (24, 1.13), (50, 1.06),
                (58, 0.88), (46, 0.58), (34, 0.28), (26, -0.06), (0, -0.12)],
         wleg=(16, 15, 13, 13, 11), warm=(14, 13, 12, 11, 9), limb=_limb, hand=_hand, foot=_foot, head=head,
         over_torso=_over, back_extra=_back)

POSES = {
    # andar: passada larga e lenta, braço-coluna pendendo à frente
    "andar": dict(hip=(0, -110), neck=(10, -206), head=(16, -226, 4), hk=1.0, far="l",
                  a_l=(-48, -8), t_l=(-26, -2), a_r=(50, -6), t_r=(76, -2),
                  w_l=(-40, -90), eb_l=1, hd_l=100, hm_l="fist", w_r=(66, -84), eb_r=1, hd_r=80, hm_r="fist"),
    # erguer: o pé da frente no alto (antes do pisão), braços abertos para equilibrar
    "erguer": dict(hip=(0, -116), neck=(-8, -212), head=(-4, -232, -6), hk=1.0, far="l",
                   a_l=(-30, -4), t_l=(-8, 0), a_r=(56, -70), t_r=(80, -70), kb_r=-1,
                   w_l=(-96, -150), eb_l=-1, hd_l=200, hm_l="open", w_r=(90, -170), eb_r=1, hd_r=-20, hm_r="fist"),
    # pisão: o pé desce no chão (impacto), joelho dobrado, tronco curvado sobre ele, punho de trás erguido
    "pisao": dict(hip=(0, -98), neck=(24, -190), head=(36, -206, 10), hk=1.0, far="l",
                  a_l=(-58, -10), t_l=(-36, -2), kb_l=-1, a_r=(56, -6), t_r=(84, -2),
                  w_l=(-70, -196), eb_l=-1, hd_l=-120, hm_l="fist", w_r=(96, -100), eb_r=1, hd_r=60, hm_r="fist"),
    # pisão em câmera baixa (a carta): mesmo instante com escorço — o alto encolhe, o pé da frente cresce
    "pisao_baixo": dict(hip=(0, -98), neck=(18, -190), head=(26, -208, 8), hk=1.05, far="l",
                        a_l=(-50, -12), t_l=(-30, -4), kb_l=-1, a_r=(60, -6), t_r=(92, -2),
                        w_l=(-78, -200), eb_l=-1, hd_l=-120, hm_l="fist", w_r=(96, -104), eb_r=1, hd_r=60, hm_r="fist",
                        persp=dict(cx=10, top=-260, k=0.42, near=(70, -6, 1.35, ("pe_r", "perna_r_b", "perna_r_junta2")))),
}
GUIDE = {"andar": [(-26, -2), (-14, -50), (0, -110), (10, -206), (18, -246)],
         "erguer": [(-8, 0), (-6, -60), (0, -116), (-8, -212), (-4, -252)],
         "pisao": [(84, -2), (40, -60), (0, -98), (24, -190), (40, -226)],
         "pisao_baixo": [(92, -2), (40, -60), (0, -98), (18, -150), (24, -190)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return brute(J, K)


def ficha():
    from fichas_l1 import svg_wrap, ruler, ground_line
    from fichas_lib import txt, pose_g, swatches
    W, H = 1300, 680
    P = [txt(20, 30, "FICHA · TITÃ DA RUÍNA (comum, lendário) — colosso de alvenaria de templo em ruína, braço-coluna, runa âmbar no peito, elmo de visor aceso", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 30 u (pequena de propósito: escala épica). Em pé ≈ 8,5 cabeças (255 u): quadril 3,7 · coxa 1,8 / canela 1,85 · braço 2,1 / antebraço 2,05 · ombros ≈ 3,6 cabeças.", 10),
         txt(20, 62, "Membros de blocos chanfrados com pedregulho na junta; antebraço da frente = coluna canelada com capitel; pés de laje. Musgo, hera e arbusto no ombro (escala). Pedra quente contra céu frio, ou contraluz.", 10),
         txt(20, 76, "data-fig: tita_corpo (tudo menos cabeça e arbusto), tita_cabeca, tita_arbusto. Juntas, rachaduras, runa e rachas acesas, musgo, hera, visor = inner. 'pisao_baixo' = escorço da câmera baixa da carta.", 10),
         ruler(40, 92, 30 * 1.5, 6, PAL["skin"], PAL["skin_d"], "1 cabeça = 30 u (régua ×1,5)")]
    P.append(pose_g("cabeca_34", head(T(0, 0), {}), (80, 200, 2.8), "tita", label="cabeça · elmo de pedra", ly=50))
    for i, (nm, lab, sub) in enumerate([("andar", "andar · passada lenta", "braço-coluna pendendo"),
                                        ("erguer", "erguer o pé", "antes do pisão"),
                                        ("pisao", "pisão · impacto", "atordoa em área"),
                                        ("pisao_baixo", "pisão · câmera baixa", "escorço da carta")]):
        x = 270 + i * 250; y = 640
        P.append(ground_line(x, y, 210))
        P.append(pose_g(nm, pose(nm), (x, y, 1.5), "tita", GUIDE[nm], lab, sub, ly=24))
    P.append(swatches(1190, 110, [(k, PAL[k]) for k in ("skin", "skin_d", "skin_l", "col", "col_d", "moss", "vine", "glow", "glow_c", "bush")]))
    return svg_wrap(W, H, P), (W, H)
