"""Ficha do GOLEM DE SUCATA (vilão Lich, construto, raro). Construto corcunda feito de sucata de campo de batalha e ossos:
tronco = caldeira de ferro rebitada com uma FORNALHA no peito (grade + fogo verde de almas: a mecânica — absorve aliados
mortos por perto e ganha vida), chaminé torta nas costas soltando fumaça verde, roda de carroça no quadril, ombreira de
chapa cravejada de pregos (lado de perto) e escudo redondo de madeira (lado de longe), braços longos de gorila
(braço = feixe de ossos amarrado, cotovelo de ferro, antebraço = cano grosso enferrujado), punhos enormes de chapa,
pernas curtas e grossas (coxa de barril, joelho de ferro, canela de dois ossos acorrentados, pé = bloco de ferro).
Cabeça pequena afundada entre os ombros: elmo de balde amassado com fenda em T (olhos verdes) e uma mandíbula de
esqueleto pendurada embaixo.
Vista frente-3/4, chão em y=0. Unidade: elmo (cabeça) = 30 u. Altura curvado ≈ 6,5 cabeças (195 u); ombros ≈ 4 cabeças
(criatura grande: tronco ~1,5× e cabeça ~1,5× o natural do primeiro rascunho). Coxa 1,5 / canela 1,45 / braço 1,9 /
antebraço 1,9 cabeça.
data-fig: golem_corpo (tudo menos a cabeça), golem_cabeca (elmo + mandíbula). Fornalha (vão, fogo, grade, crânio
preso), rebites, emendas, raios da roda, correntes, amarras, fenda e olhos = inner."""
import math
import numpy as np
from geom import *
from piper import ik
from esqueleto import frame, bone, knob
from colosso import bundle, small_skull, big_hand

INK = "#2b1a10"
PAL = dict(iron="#7c818a", iron_d="#52565f", iron_l="#a4a9b0", rust="#a2643c", rust_d="#6e3e26", bone="#e2d4b0",
           bone_d="#ad9c78", wood="#7a5434", wood_d="#553820", cavity="#1a1c22", soul="#7dffb0", soul_d="#2e8a6a",
           soul_l="#e0fff0", eye="#9effc4", chain="#5e6068")
L_TH, L_SH, L_UA, L_FA = 45.0, 43.0, 57.0, 57.0


def deg(v):
    return math.degrees(math.atan2(v[1], v[0]))


def unit(v):
    v = A(v); return v / (np.linalg.norm(v) + 1e-9)


def rivets(name, pts, r=1.3, fill=None):
    return [Pc(f"{name}{k}", "corpo", fill or PAL["iron_l"], ellipse(q[0], q[1], r, r, 0, 6), cls="inner") for k, q in enumerate(pts)]


def chain_wrap(name, a, b, n=3, w=9):
    """Voltas de corrente (inner) em volta de um membro de a até b."""
    a, b = A(a), A(b); d = b - a; t = unit(d); nn = np.array([-t[1], t[0]])
    out = []
    for k in range(n):
        m = a + d * (0.3 + 0.18 * k)
        out.append(Pc(f"{name}{k}", "corpo", PAL["chain"], [m + nn * w + t * 2, m + t * 3.5, m - nn * w + t * 1], closed=False, cls="inner", sw=1.4))
    return out


def head(M, jaw=4.0, glow=True, fig="cabeca"):
    """Elmo de balde amassado (topo em -15, base em +9) com fenda em T e mandíbula de esqueleto pendurada (abre com jaw)."""
    p = PAL; pcs = []
    jy = jaw
    # mandíbula de esqueleto embaixo do elmo
    pcs.append(Pc("mandibula", fig, p["bone_d"], [(-9, 6), (-9.5, 11 + jy * 0.5), (-6, 15 + jy), (6, 15 + jy), (9.5, 11 + jy * 0.5), (9, 6)]))
    for i, x in enumerate((-4.5, -1.5, 1.5, 4.5)):
        pcs.append(Pc(f"dente{i}", fig, p["bone"], [(x - 1.2, 9.5 + jy * 0.9), (x, 6.5 + jy * 0.9), (x + 1.2, 9.5 + jy * 0.9)], mode="poly", cls="inner"))
    # elmo
    pcs.append(Pc("elmo", fig, p["iron"], [(-12, 9), (-13, -4), (-12.4, -11), (-8, -15), (0, -16.4), (8, -15), (12.4, -11), (13, -4), (12, 9),
                                         (5, 10.4), (-5, 10.4)]))
    pcs.append(Pc("elmo_aro", fig, p["rust"], [(-13, 4.4), (13, 4.4), (12.6, 9.4), (-12.6, 9.4)], mode="poly", cls="inner"))
    pcs.append(Pc("amassado", fig, p["iron_d"], [(4, -14), (7.6, -9.6), (5.4, -6.4)], closed=False, cls="inner", sw=0.8))
    pcs.append(Pc("prego_topo", fig, p["iron_d"], [(-3, -15.6), (-1.6, -24), (-0.2, -15.8)], mode="poly"))
    # fenda em T com olhos acesos
    pcs.append(Pc("fenda", fig, p["cavity"], [(-10, -5.6), (10, -5.6), (10, -2.4), (1.6, -2.4), (1.6, 5), (-1.6, 5), (-1.6, -2.4), (-10, -2.4)],
                  mode="poly", cls="inner"))
    if glow:
        for s in (-1, 1):
            pcs.append(Pc("olho" + ("_l" if s < 0 else "_r"), fig, p["eye"], ellipse(s * 5.6, -4.0, 2.2, 1.2, 0, 7), cls="inner"))
    pcs += [Pc(f"rebite_elmo{k}", fig, p["iron_l"], ellipse(x, 6.9, 0.9, 0.9, 0, 6), cls="inner") for k, x in enumerate((-9, -3, 3, 9))]
    return [q.moved(M) for q in pcs]


def golem(J):
    """J: hip, neck, head=(x,y,rot), hk, jaw, far, al/ar tl/tr kbl/kbr, wl/wr ebl/ebr hdl/hdr hml/hmr hsl/hsr,
    door (0 fechada .. 1 aberta), glow (0..1), smoke (ângulo da chaminé)."""
    p = PAL; pcs = []
    hip, nk = A(J["hip"]), A(J["neck"])
    up = unit(nk - hip); side = np.array([-up[1], up[0]])
    F = frame(nk, up); H = frame(hip, up)
    far = J.get("far", "l")
    shl, shr = F(-56, -14), F(56, -14); hjl, hjr = H(-24, -2), H(24, -2)

    def leg(tag):
        hj = hjl if tag == "l" else hjr
        kn, an = ik(hj, J["a" + tag], L_TH, L_SH, J.get("kb" + tag, -1))
        dk = far == tag
        out = [Pc("coxa_" + tag, "corpo", p["rust_d"] if dk else p["rust"], tube([hj, (hj + kn) / 2, kn], [15, 16, 12], None, cap0=0.6, cap1=0.5, per=3))]
        t = unit(kn - hj); nn = np.array([-t[1], t[0]])
        for k, u in enumerate((0.3, 0.7)):
            m = hj + (kn - hj) * u
            out.append(Pc(f"coxa_aro_{tag}{k}", "corpo", p["iron_d"], [m + nn * 16, m - nn * 16], closed=False, cls="inner", sw=1.6))
        out += bundle("canela_" + tag, kn, an, 2, 6.4, p["bone_d"] if dk else p["bone"], 7.0)
        out += chain_wrap("corrente_canela_" + tag, kn, an, 2, 10)
        out.append(Pc("joelho_" + tag, "corpo", p["iron_d"] if dk else p["iron"], ellipse(kn[0], kn[1], 12, 10, deg(t), 10)))
        out += rivets("rebite_joelho_" + tag, [kn + np.array([-5, -2]), kn + np.array([5, -2]), kn + np.array([0, 4])])
        to = A(J["t" + tag]); dd = unit(to - an); n2 = np.array([-dd[1], dd[0]])
        if n2[1] < 0:
            n2 = -n2
        blk = [an - dd * 14 + n2 * 9, an - dd * 12 - n2 * 6, an + dd * 4 - n2 * 8, to - n2 * 3, to + dd * 4 + n2 * 4, to + n2 * 9]
        out.append(Pc("pe_" + tag, "corpo", p["iron_d"] if dk else p["iron"], blk, mode="poly"))
        out += rivets("rebite_pe_" + tag, [an - dd * 6 + n2 * 2, to - dd * 6 + n2 * 2])
        return out

    def arm(tag):
        sh = shl if tag == "l" else shr
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        dk = far == tag
        out = bundle("braco_" + tag, sh, el, 3, 5.6, p["bone_d"] if dk else p["bone"], 5.6)
        t = unit(wr - el)
        out.append(Pc("antebraco_" + tag, "corpo", p["rust_d"] if dk else p["rust"],
                      tube([el + t * 4, (el + wr) / 2, wr - t * 2], [12, 13.5, 14.5], None, cap0=0.4, cap1=0.3, per=3)))
        nn = np.array([-t[1], t[0]])
        for k, u in enumerate((0.25, 0.6, 0.9)):
            m = el + (wr - el) * u
            w_ = 12 + u * 3
            out.append(Pc(f"cano_aro_{tag}{k}", "corpo", p["iron_d"], [m + nn * w_, m - nn * w_], closed=False, cls="inner", sw=1.6))
        out.append(knob("cotovelo_" + tag, el, 12, p["iron_d"] if dk else p["iron"]))
        out += rivets("rebite_cot_" + tag, [el + np.array([-4, 0]), el + np.array([4, 0])])
        ang = J.get("hd" + tag, deg(t))
        out += big_hand("mao_" + tag, wr, ang, J.get("hs" + tag, 1.5), J.get("hm" + tag, "fist"), p["iron_d"] if dk else p["iron"])
        return out

    def pauldron(tag):
        sh = shl if tag == "l" else shr; sg = -1 if tag == "l" else 1
        if tag == far:  # escudo redondo de madeira com umbo de ferro
            c = sh + up * 6 + side * sg * 4
            out = [Pc("escudo_" + tag, "corpo", p["wood_d"], ellipse(c[0], c[1], 26, 23, deg(side), 14))]
            out.append(Pc("umbo_" + tag, "corpo", p["iron"], ellipse(c[0], c[1], 7, 6, 0, 9)))
            for k in range(3):
                a = math.radians(k * 60 + 20)
                dv = np.array([math.cos(a), math.sin(a)])
                out.append(Pc(f"tabua_{tag}{k}", "corpo", INK, [c + dv * 8, c + dv * 23], closed=False, cls="inner", sw=0.7))
            return out
        c = sh + up * 8 + side * sg * 2
        plate = [c - side * sg * 24 + up * 4, c - side * sg * 8 + up * 14, c + side * sg * 14 + up * 12, c + side * sg * 28 - up * 2,
                 c + side * sg * 24 - up * 18, c + side * sg * 4 - up * 14, c - side * sg * 22 - up * 8]
        out = [Pc("ombreira_" + tag, "corpo", p["iron"], plate)]
        for k, (ds, du, L) in enumerate([(-10, 10, 18), (4, 13, 24), (18, 8, 18)]):
            b = c + side * sg * ds + up * du
            dv = unit(up * 1.0 + side * sg * (0.35 + k * 0.25))
            nv = np.array([-dv[1], dv[0]])
            out.append(Pc(f"prego_{tag}{k}", "corpo", p["iron_d"], [b - nv * 3, b + dv * L, b + nv * 3], mode="poly"))
        out += rivets("rebite_ombro_" + tag, [c + side * sg * k_ - up * 6 for k_ in (-12, 0, 12)])
        return out

    # chaminé torta nas costas (atrás de tudo), saindo acima do ombro de longe
    sm = J.get("smoke", 0.0)
    sgf = -1 if far == "l" else 1
    b0 = F(sgf * 30, -6)
    pts = [b0, b0 + up * 20 + side * sgf * 6, b0 + up * 40 + side * sgf * (14 + sm * 0.2), b0 + up * 52 + side * sgf * (24 + sm * 0.4)]
    pcs.append(Pc("chamine", "corpo", p["rust_d"], tube(pts, [8, 7.5, 7, 7], None, cap0=0.3, cap1=0.2, per=3)))
    tp = pts[-1]; tdir = unit(pts[-1] - pts[-2]); tn = np.array([-tdir[1], tdir[0]])
    pcs.append(Pc("chamine_boca", "corpo", p["iron_d"], [tp - tn * 10, tp + tn * 10, tp + tn * 9 + tdir * 6, tp - tn * 9 + tdir * 6], mode="poly"))
    pcs += arm(far)
    pcs += pauldron(far)
    pcs += leg(far)
    pcs += leg("r" if far == "l" else "l")
    # roda de carroça no quadril (meio escondida pela caldeira)
    wc = H(0, 2)
    pcs.append(Pc("roda", "corpo", p["wood"], ellipse(wc[0], wc[1], 30, 26, deg(side), 16)))
    for k in range(8):
        a = math.radians(k * 45 + 10)
        dv = np.array([math.cos(a) * 26, math.sin(a) * 22])
        pcs.append(Pc(f"raio{k}", "corpo", p["wood_d"], [wc + dv * 0.25, wc + dv * 0.92], closed=False, cls="inner", sw=1.6))
    pcs.append(Pc("cubo", "corpo", p["iron_d"], ellipse(wc[0], wc[1], 6, 5, 0, 8), cls="inner"))
    # caldeira (tronco maciço)
    boil = [F(-44, 6), F(-20, 12), F(20, 12), F(44, 6), F(58, -14), F(66, -44), F(60, -72), F(40, -90), F(0, -96), F(-40, -90),
            F(-60, -72), F(-66, -44), F(-58, -14)]
    pcs.append(Pc("caldeira", "corpo", p["iron"], boil))
    pcs.append(Pc("caldeira_ferrugem", "corpo", p["rust"], [F(-60, -72), F(-40, -90), F(0, -96), F(40, -90), F(60, -72), F(50, -80),
                                                          F(20, -88), F(-20, -88), F(-50, -80)], cls="inner", op=0.8))
    for k, u in enumerate((-12, -80)):
        w_ = 58 if k == 0 else 54
        pcs.append(Pc(f"cinta{k}", "corpo", p["iron_d"], [F(-w_, u), F(0, u + 4), F(w_, u)], closed=False, cls="inner", sw=2.0))
        pcs += rivets(f"rebite_cinta{k}_", [F(x, u + 2.6 - abs(x) * 0.04) for x in (-44, -24, 24, 44)])
    # ossos espetados nas emendas (mortos absorvidos)
    for k, (a, b) in enumerate([((-50, -60), (-74, -48)), ((48, -30), (72, -40)), ((-30, -88), (-38, -110))]):
        pcs.append(bone(f"osso_espetado{k}", F(*a), F(*b), 4.6, 2.8, 4.4, p["bone"]))
    # fornalha no peito: vão escuro + fogo verde de almas + crânio sendo consumido + grade
    door = J.get("door", 0.0); g = J.get("glow", 1.0)
    c0 = F(4, -46)
    pcs.append(Pc("fornalha", "corpo", p["cavity"], ellipse(c0[0], c0[1], 24, 21, deg(side), 14), cls="inner"))
    pcs.append(Pc("fogo", "corpo", p["soul_d"], ellipse(c0[0], c0[1] + 2, 21, 18, deg(side), 14), cls="inner", op=round(0.6 + 0.3 * g, 2)))
    fl = [c0 + side * x + up * y for x, y in [(-16, -10), (-12, 4), (-8, -2), (-4, 12), (0, 2), (5, 14), (9, 0), (13, 6), (17, -10)]]
    pcs.append(Pc("chama", "corpo", p["soul"], fl, cls="inner", op=0.95))
    pcs.append(Pc("chama_centro", "corpo", p["soul_l"], [c0 + side * x + up * y for x, y in [(-7, -9), (-3, 2), (1, -3), (4, 6), (8, -9)]], cls="inner"))
    pcs += small_skull("cranio_fornalha", c0 + up * -6 + side * -2, 0.8, -10, p["bone_d"], glow=False, cls="inner")
    if door < 0.5:
        for k in range(4):
            x = -15 + k * 10
            pcs.append(Pc(f"grade{k}", "corpo", p["iron_d"], [c0 + side * x + up * 17, c0 + side * x - up * 17], closed=False, cls="inner", sw=2.2))
    pcs.append(Pc("fornalha_aro", "corpo", p["iron_d"], ellipse(c0[0], c0[1], 26, 23, deg(side), 14), closed=False, cls="inner", sw=2.4))
    if door >= 0.5:  # porta aberta pendurada na dobradiça do lado de perto
        sgn = 1 if far == "l" else -1
        hg = c0 + side * sgn * 25
        dpts = [hg + up * 18, hg + side * sgn * 22 + up * 14, hg + side * sgn * 24 - up * 14, hg - up * 18]
        pcs.append(Pc("porta", "corpo", p["iron_d"], dpts))
        pcs += rivets("rebite_porta", [hg + side * sgn * 12 + up * 8, hg + side * sgn * 12 - up * 8])
    pcs += pauldron("r" if far == "l" else "l")
    pcs += arm("r" if far == "l" else "l")
    hx, hy, hr = J["head"]
    pcs += head(tmat(hx, hy, hr, J.get("hk", 1.5)), J.get("jaw", 4))
    return pcs


POSES = {
    # marchar: passo pesado para a direita, punho de perto balançando à frente, ombros rolando
    "marchar": dict(hip=(0, -84), neck=(10, -170), head=(18, -178, 6), hk=1.55, jaw=3, far="l",
                    al=(-40, -2), tl=(-58, 0), kbl=1, ar=(42, -14), tr=(62, -12), kbr=-1,
                    wl=(-82, -72), ebl=1, hdl=110, wr=(74, -84), ebr=-1, hdr=50, smoke=10),
    # absorver: inclinado para a frente, mão de longe agarrando um morto no chão, fornalha aberta em labareda, punho erguido
    "absorver": dict(hip=(-6, -78), neck=(22, -156), head=(36, -160, 18), hk=1.55, jaw=7, far="l", door=1.0,
                     al=(-50, 0), tl=(-68, 0), kbl=1, ar=(38, 0), tr=(58, 0), kbr=-1,
                     wl=(-60, -6), ebl=1, hml="open", hdl=100, hsl=1.6, wr=(84, -150), ebr=-1, hdr=-70, hsr=1.6, smoke=-20),
    # golpear: punho de perto erguido acima da cabeça para esmagar, o de longe à frente, base larga, rugindo
    "golpear": dict(hip=(0, -82), neck=(-6, -166), head=(-12, -172, -10), hk=1.55, jaw=8, far="l",
                    al=(-52, 0), tl=(-70, 0), kbl=1, ar=(46, 0), tr=(64, 0), kbr=-1,
                    wl=(-96, -110), ebl=1, hml="open", hdl=170, wr=(30, -262), ebr=-1, hdr=-100, hsr=1.7, smoke=0),
    # erguer um morto: passo para a direita, ergue um esqueleto morto pelo pulso (braço de perto aberto ao lado) para jogá-lo
    # na fornalha aberta; mão de longe aberta, baixa à frente (scrap_golem)
    "erguer_morto": dict(hip=(0, -84), neck=(8, -170), head=(14, -178, 4), hk=1.55, jaw=6, far="l", door=1.0, smoke=-10,
                         al=(-40, -2), tl=(-58, 0), kbl=1, ar=(42, -14), tr=(62, -12), kbr=-1,
                         wr=(118, -150), ebr=-1, hdr=-10, hmr="fist", hsr=1.5, wl=(-84, -64), ebl=1, hdl=110, hml="open", hsl=1.35),
}
GUIDE = {"marchar": [(-58, 0), (-20, -40), (0, -84), (10, -170), (22, -194)],
         "absorver": [(-68, 0), (-30, -40), (-6, -78), (22, -156), (50, -170)],
         "erguer_morto": [(-58, 0), (-20, -40), (0, -84), (8, -170), (70, -190), (118, -150)],
         "golpear": [(-70, 0), (-26, -40), (0, -82), (-6, -166), (20, -230), (30, -262)]}
PREV_S = 1.0


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return golem(J)


def J(name, **over):
    d = dict(POSES[name]); d.update(over)
    return d


def ficha(svg_wrap, ruler, ground_line):
    from fichas_lib import txt, pose_g, swatches
    W, H = 1240, 660
    P = [txt(20, 30, "FICHA · GOLEM DE SUCATA (Lich, construto) — caldeira rebitada com fornalha de almas no peito, chaminé, roda, ombreira de pregos, escudo, punhos de chapa", 14, "bold"),
         txt(20, 48, "Unidade: elmo = 30 u. Altura curvado ≈ 6,5 cabeças (195 u); ombros ≈ 4 cabeças; coxa 1,5 / canela 1,45 / braço 1,9 / antebraço 1,9 (braços de gorila). Tronco e cabeça ~1,5× o natural.", 10),
         txt(20, 62, "Sucata (ferro cinza, ferrugem laranja, madeira) + ossos (braços, canelas, ossos espetados). A fornalha verde mostra a mecânica (absorve os mortos): é o brilho-foco junto com a fenda do elmo.", 10),
         txt(20, 76, "data-fig: golem_corpo (tudo menos a cabeça), golem_cabeca (elmo de balde + mandíbula de esqueleto). Fornalha, fogo, grade, rebites, emendas, raios, correntes, fenda e olhos = inner.", 10),
         ruler(40, 92, 30 * 2, 3, "#7c818a", "#a2643c", "1 cabeça = 30 u (régua ×2)")]
    P.append(pose_g("cabeca_frente", head(T(0, 0), 5), (100, 240, 3.6), "golem", label="cabeça · frente (elmo + mandíbula)", ly=86))
    for i, (nm, lab, sub) in enumerate([("marchar", "marchar · passo pesado", "punho balançando à frente"),
                                        ("absorver", "absorver · agarra um morto", "fornalha aberta, mão no chão"),
                                        ("golpear", "golpear · punho no alto", "base larga, rugindo"),
                                        ("erguer_morto", "erguer um morto", "esqueleto pelo pulso → fornalha")]):
        x = 330 + i * 225; y = 610
        P.append(ground_line(x, y, 200))
        P.append(pose_g(nm, pose(nm), (x, y, 0.92), "golem", GUIDE[nm], lab, sub, ly=24))
    P.append(swatches(1100, 110, [(k, PAL[k]) for k in ("iron", "iron_d", "rust", "rust_d", "bone", "wood", "cavity", "soul", "eye", "chain")]))
    return svg_wrap(W, H, P), (W, H)
