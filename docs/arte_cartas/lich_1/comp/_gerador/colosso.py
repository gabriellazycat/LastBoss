"""Ficha do COLOSSO DE OSSOS (vilão Lich, lendário). Gigante corcunda feito de ossos amarrados: pernas curtas e grossas
(feixes de três fêmures, crânio na rótula), braços longos de gorila (feixes de ossos, mãos de falanges-fêmur), caixa
torácica enorme e ABERTA cheia de crânios dos mortos que absorveu com um brilho verde no meio (a mecânica: absorve os
mortos por perto e, ao morrer, vira esqueletos), ombreiras de crânios empilhados, espinhos de vértebras nas costas e
uma cabeça de crânio grande com chifres de osso e mandíbula caída.
Vista frente-3/4, chão em y=0. Unidade: crânio da cabeça = 36 u. Altura curvado ≈ 6 crânios (215 u); ombros = 3 crânios
de largura de cada lado do pescoço (ombros ≈ 2,6 crânios no total, tronco ~1,5× o natural: criatura grande).
Coxa 1,2 / canela 1,2 / braço 1,55 / antebraço 1,55 crânio.
data-fig: colosso_corpo (tudo menos a cabeça), colosso_cabeca (crânio+chifres+mandíbula). Vão da caixa torácica,
crânios presos, brilho, órbitas, dentes e amarras = inner."""
import math
import numpy as np
from geom import *
from piper import ik
from esqueleto import frame, bone, knob, SKULL_F
import esqueleto as E

INK = "#2b1a10"
PAL = dict(bone="#e2d4b0", bone_d="#ad9c78", bone_l="#f4ead0", cavity="#1c2230", soul="#7dffb0", soul_d="#2e8a6a",
           eye="#9effc4", socket="#241426", rope="#5a4632")
L_TH, L_SH, L_UA, L_FA = 44.0, 44.0, 56.0, 56.0


def deg(v):
    return math.degrees(math.atan2(v[1], v[0]))


def bundle(name, a, b, n, w, fill, spread=4.2):
    """Feixe de n ossos paralelos de a até b, com uma amarra no meio."""
    a, b = A(a), A(b); d = b - a; t = d / np.linalg.norm(d); nn = np.array([-t[1], t[0]])
    out = []
    for k in range(n):
        off = (k - (n - 1) / 2) * spread
        a2 = a + nn * off + t * (k % 2) * 3; b2 = b + nn * off * 0.8 - t * ((k + 1) % 2) * 2
        out.append(bone(f"{name}{k}", a2, b2, w * 1.25, w * 0.75, w * 1.15, fill))
    m = a + d * 0.48
    half = (n - 1) / 2 * spread + w
    out.append(Pc(f"{name}_amarra", "corpo", PAL["rope"], [m + nn * half - t * 2.4, m + nn * half + t * 2.4, m - nn * half + t * 2.4, m - nn * half - t * 2.4],
                  mode="poly", cls="inner"))
    return out


def small_skull(name, c, s, rot, fill=None, glow=False, cls=None, fig="corpo"):
    """Crânio pequeno (o do v2) como peça: c = centro, s = escala."""
    M = tmat(c[0], c[1], rot, s)
    pcs = [Pc(name, fig, fill or PAL["bone"], d=xform_d(SKULL_F, M), cls=cls)]
    pcs.append(Pc(name + "_mand", fig, fill or PAL["bone_d"], d=xform_d("M-6 8 L-5.5 12 L5.5 12 L6 8 Z", M), cls=cls))
    for sx in (-1, 1):
        pcs.append(Pc(f"{name}_orb{'l' if sx < 0 else 'r'}", fig, PAL["socket"], list(ap(M, ellipse(sx * 4.5, -2.4, 2.8, 2.6, 0, 7))), cls="inner"))
        if glow:
            pcs.append(Pc(f"{name}_olho{'l' if sx < 0 else 'r'}", fig, PAL["soul"], list(ap(M, ellipse(sx * 4.5, -2.4, 1.1, 1.1, 0, 6))), cls="inner"))
    pcs.append(Pc(name + "_nariz", fig, PAL["socket"], list(ap(M, [(0, 2), (-1.6, 5), (1.6, 5)])), mode="poly", cls="inner"))
    return pcs


def big_hand(name, wrist, ang, s=1.0, mode="fist", fill=None):
    """Mão de falanges grossas (4 dedos de dois segmentos com nós + polegar)."""
    fill = fill or PAL["bone"]
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    c = A(wrist) + d * 7 * s
    pcs = [Pc(name, "corpo", fill, ellipse(c[0], c[1], 10 * s, 8.5 * s, ang, 10))]
    for k in range(4):
        b = c + d * 5 * s + n * (k - 1.5) * 4.6 * s
        if mode == "fist":
            j1 = b + d * 6 * s; j2 = j1 + n * 0 - d * 0 + (d * 0.2 + n * -0.0) * s
            pts = [b, b + d * 6 * s, b + d * 7 * s - n * 5 * s]
        else:
            a_ = math.radians(ang + (k - 1.5) * 16); dk = np.array([math.cos(a_), math.sin(a_)])
            pts = [b, b + dk * 10 * s, b + dk * 19 * s + n * 2 * s]
        pcs.append(Pc(f"{name}_dedo{k}", "corpo", fill, tube(pts, [3.4 * s, 3.0 * s, 2.4 * s], None, cap0=0.6, cap1=0.8, per=3)))
        pcs.append(Pc(f"{name}_no{k}", "corpo", fill, ellipse(*(pts[1]), 3.6 * s, 3.2 * s, 0, 7)))
    a_ = math.radians(ang - 70); dt = np.array([math.cos(a_), math.sin(a_)]); b = c - n * 8 * s
    pcs.append(Pc(f"{name}_polegar", "corpo", fill, tube([b, b + dt * 8 * s, b + dt * 13 * s + d * 3 * s], [3.6 * s, 3.0 * s, 2.4 * s], None, cap0=0.6, cap1=0.8, per=3)))
    return pcs


def head(M, jaw=6.0, fig="cabeca"):
    """Crânio grande com chifres de osso (curvos para a frente) e mandíbula caída. Centro da calota (0,0); escala 1 = v2 (×1.3 no rig)."""
    p = PAL; pcs = []
    for s in (-1, 1):
        tg = "_l" if s < 0 else "_r"
        pcs.append(Pc("chifre" + tg, fig, p["bone_d"], [(s * 8, -12), (s * 16, -16), (s * 24, -16), (s * 30, -10), (s * 31, -1), (s * 27, 6),
                                                         (s * 26, -2), (s * 23, -8), (s * 16, -9), (s * 9, -6)]))
        for k in range(3):
            q = (s * (17 + k * 4.4), -13.4 + k * 1.2)
            pcs.append(Pc(f"chifre_anel{k}{tg}", fig, INK, [(q[0] - s * 0.6, q[1] - 2.6), (q[0] + s * 0.4, q[1] + 3.2)], closed=False, cls="inner", sw=0.6))
    jy = jaw
    pcs.append(Pc("mandibula", fig, p["bone_d"], [(-8, 6 + jy * 0.3), (8, 6 + jy * 0.3), (8.5, 10 + jy), (5, 14 + jy), (-5, 14 + jy), (-8.5, 10 + jy)]))
    pcs.append(Pc("cranio", fig, p["bone"], d=SKULL_F))
    pcs.append(Pc("sobrecenho", fig, p["bone_d"], [(-9.6, -6), (-2, -4.6), (0, -6.6), (2, -4.6), (9.6, -6), (8, -8), (0, -9), (-8, -8)], cls="inner", op=0.9))
    for s in (-1, 1):
        tg = "_l" if s < 0 else "_r"
        pcs.append(Pc("orbita" + tg, fig, p["socket"], ellipse(s * 4.6, -2.2, 3.0, 2.8, s * 10, 8), cls="inner"))
        pcs.append(Pc("olho" + tg, fig, p["eye"], ellipse(s * 4.6, -2.0, 1.4, 1.4, 0, 6), cls="inner"))
    pcs.append(Pc("nariz", fig, p["socket"], [(0, 2), (-1.6, 5), (1.6, 5)], mode="poly", cls="inner"))
    if jy > 1.5:
        pcs.append(Pc("boca", fig, p["socket"], [(-5.6, 8.4), (5.6, 8.4), (5, 9 + jy), (-5, 9 + jy)], cls="inner"))
    for i, x in enumerate((-4, -1.4, 1.4, 4)):
        pcs.append(Pc(f"dente{i}", fig, p["bone_l"], [(x - 1, 8), (x, 10.6), (x + 1, 8)], mode="poly", cls="inner"))
        pcs.append(Pc(f"dente_b{i}", fig, p["bone_l"], [(x - 1, 9 + jy + 3.4), (x, 9 + jy + 0.8), (x + 1, 9 + jy + 3.4)], mode="poly", cls="inner"))
    pcs.append(Pc("rachadura", fig, INK, [(3, -15.6), (4.6, -11), (2.6, -8.6)], closed=False, cls="inner", sw=0.7))
    return [q.moved(M) for q in pcs]


def colossus(J):
    """J: hip, neck, head=(x,y,rot), hk, jaw, far, al/ar tl/tr kbl/kbr, wl/wr ebl/ebr hdl/hdr hml/hmr, glow (0..1)."""
    p = PAL; pcs = []
    hip, nk = A(J["hip"]), A(J["neck"])
    up = (nk - hip) / np.linalg.norm(nk - hip); side = np.array([-up[1], up[0]])
    F = frame(nk, up); H = frame(hip, up)
    far = J.get("far", "l")
    shl, shr = F(-46, -12), F(46, -12); hjl, hjr = H(-18, -4), H(18, -4)
    col = lambda tag: p["bone_d"] if tag == far else p["bone"]

    def leg(tag):
        hj = hjl if tag == "l" else hjr
        kn, an = ik(hj, J["a" + tag], L_TH, L_SH, J.get("kb" + tag, -1))
        c = col(tag)
        out = bundle("coxa_" + tag, hj, kn, 3, 5.2, c, 5.0) + bundle("canela_" + tag, kn, an, 2, 5.6, c, 6.0)
        out += small_skull("rotula_" + tag, kn + (kn - hj) / np.linalg.norm(kn - hj) * 2, 0.95, deg(kn - hj) - 90 if False else 0, c)
        to = A(J["t" + tag]); dd = to - an; t = dd / np.linalg.norm(dd)
        out.append(Pc("calcanhar_" + tag, "corpo", c, ellipse(an[0], an[1] + 2, 9, 7, 0, 9)))
        for k in (-1, 0, 1):
            b = an + t * 4 + np.array([k * 4, 3])
            e = to + np.array([k * 7, 0])
            out.append(Pc(f"artelho_{tag}{k + 1}", "corpo", c, tube([b, (b + e) / 2 + np.array([0, -2]), e], [3.6, 3.2, 2.6], None, cap0=0.6, cap1=0.8, per=3)))
        return out

    def arm(tag):
        sh = shl if tag == "l" else shr
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        c = col(tag)
        out = bundle("braco_" + tag, sh, el, 3, 5.0, c, 5.0) + bundle("antebraco_" + tag, el, wr, 3, 4.6, c, 4.6)
        out.append(knob("cotovelo_" + tag, el, 9, c))
        ang = J.get("hd" + tag, deg(wr - el))
        out += big_hand("mao_" + tag, wr, ang, J.get("hs" + tag, 1.0), J.get("hm" + tag, "fist"), c)
        return out

    def pauldron(tag):
        sh = shl if tag == "l" else shr; sg = -1 if tag == "l" else 1
        out = [Pc("escapula_" + tag, "corpo", p["bone_d"], [sh + up * 10 - side * sg * 14, sh + up * 14 + side * sg * 8, sh + side * sg * 16, sh - up * 12 + side * sg * 4, sh - up * 8 - side * sg * 16])]
        for k, (ds, du, s_, r_) in enumerate([(-6, 10, 1.15, -10), (8, 6, 1.05, 14), (0, -4, 1.2, 0)]):
            out += small_skull(f"ombro_{tag}{k}", sh + side * sg * ds + up * du, s_, sg * r_, p["bone"] if tag != far else p["bone_d"])
        return out

    # espinhos de vértebra nas costas (atrás de tudo, saindo acima dos ombros)
    for k, (ds, h) in enumerate([(-14, 26), (0, 34), (14, 26)]):
        b = F(ds, -4)
        pcs.append(Pc(f"espinho_dorsal{k}", "corpo", p["bone_d"], [b - side * 5, b + up * h + side * ds * 0.2, b + side * 5]))
    pcs += arm(far)
    pcs += pauldron(far)
    pcs += leg(far)
    pcs += leg("r" if far == "l" else "l")
    # pelve grande
    pv = [H(-28, 10), H(-12, 5), H(0, 8), H(12, 5), H(28, 10), H(26, -2), H(14, -10), H(6, -18), H(-6, -18), H(-14, -10), H(-26, -2)]
    pcs.append(Pc("pelve", "corpo", p["bone"], pv))
    for s in (-1, 1):
        q = H(s * 10, -8)
        pcs.append(Pc("forame" + ("_l" if s < 0 else "_r"), "corpo", p["socket"], ellipse(q[0], q[1], 4.4, 3.4, 0, 7), cls="inner"))
    # coluna grossa (lombar) entre pelve e costelas
    for k, t in enumerate(np.linspace(0.08, 0.5, 4)):
        q = hip + (nk - hip) * t
        pcs.append(Pc(f"vertebra{k}", "corpo", p["bone_d"], ellipse(q[0], q[1], 8.5, 5.6, deg(side), 9)))
    # caixa torácica enorme e aberta: base escura (vão) + costelas por cima + crânios presos + brilho verde
    cav = [F(-34, 2), F(-14, 6), F(14, 6), F(34, 2), F(42, -22), F(40, -48), F(30, -70), F(14, -80), F(0, -74), F(-14, -80), F(-30, -70),
           F(-40, -48), F(-42, -22)]
    pcs.append(Pc("vao_peito", "corpo", p["cavity"], cav))
    g = J.get("glow", 1.0)
    c0 = F(0, -40)
    pcs.append(Pc("alma", "corpo", p["soul_d"], ellipse(c0[0], c0[1], 26, 24, 0, 14), cls="inner", op=round(0.5 + 0.3 * g, 2)))
    pcs.append(Pc("alma_centro", "corpo", p["soul"], ellipse(c0[0], c0[1] + 2, 14 * (0.7 + 0.3 * g), 13 * (0.7 + 0.3 * g), 0, 12), cls="inner", op=0.85))
    for k, (ds, du, s_, r_) in enumerate([(-18, -30, 0.95, -18), (16, -26, 0.9, 16), (-4, -56, 0.85, 6), (20, -54, 0.8, 24), (-22, -58, 0.75, -26)]):
        pcs += small_skull(f"preso{k}", F(ds, du), s_, r_, p["bone_d"], glow=(k == 2), cls="inner")
    # costelas quebradas na frente: saem das laterais e curvam para dentro sem fechar (o peito fica aberto no meio)
    for i in range(4):
        for s in (-1, 1):
            y = -8 - i * 17
            w_ = 42 - abs(i - 1.2) * 3.6
            tipx = 13 + i * 1.5 + (3 if s > 0 else 0)
            pts = [F(s * (w_ - 4), y + 6), F(s * (w_ + 1), y - 4), F(s * (w_ - 6), y - 12), F(s * tipx, y - 10 + i * 0.5)]
            pcs.append(Pc(f"costela{i}{'l' if s < 0 else 'r'}", "corpo", p["bone"], tube(pts, [4.2, 4.8, 4.0, 2.6], None, cap0=0.6, cap1=0.9, per=3)))
    # clavículas grossas ligando os ombros
    pcs.append(Pc("claviculas", "corpo", p["bone"], tube([shl + up * 6, F(-16, 2), F(16, 2), shr + up * 6], [5, 4.4, 4.4, 5], None, cap0=0.6, cap1=0.6, per=3)))
    pcs += pauldron("r" if far == "l" else "l")
    pcs += arm("r" if far == "l" else "l")
    hx, hy, hr = J["head"]
    pcs += head(tmat(hx, hy, hr, J.get("hk", 1.6)), J.get("jaw", 6))
    return pcs


POSES = {
    # marcha: passo pesado para a direita-frente, punho esquerdo balançando à frente, cabeça baixa à frente dos ombros
    "marchar": dict(hip=(0, -84), neck=(10, -176), head=(18, -202, 4), hk=2.3, jaw=5, far="l",
                    al=(-40, -2), tl=(-56, 0), kbl=1, ar=(42, -14), tr=(58, -12), kbr=-1,
                    wl=(-74, -60), ebl=1, hdl=110, wr=(70, -84), ebr=-1, hdr=40),
    # esmagar: inclinado para a frente, punho direito descendo no chão, esquerdo erguido atrás, boca escancarada
    "esmagar": dict(hip=(-6, -80), neck=(16, -166), head=(36, -190, 14), hk=2.3, jaw=9, far="l",
                    al=(-50, 0), tl=(-64, 0), kbl=1, ar=(36, 0), tr=(52, 0), kbr=-1,
                    wl=(-60, -214), ebl=-1, hdl=-120, wr=(78, -10), ebr=-1, hdr=80),
    # absorver: braços abertos, peito aberto para a frente, cabeça jogada para trás rugindo (os mortos voam para o peito)
    "absorver": dict(hip=(0, -86), neck=(0, -180), head=(0, -216, -4), hk=2.3, jaw=10, far="r", glow=1.0,
                     al=(-40, 0), tl=(-54, 0), kbl=1, ar=(40, 0), tr=(54, 0), kbr=-1,
                     wl=(-104, -158), ebl=1, hml="open", hdl=-140, wr=(104, -158), ebr=-1, hmr="open", hdr=-40),
}
GUIDE = {"marchar": [(-56, 0), (-20, -40), (0, -84), (10, -176), (20, -200)],
         "esmagar": [(-64, 0), (-30, -40), (-6, -80), (16, -166), (60, -100), (78, -10)],
         "absorver": [(-54, 0), (-10, -40), (0, -86), (0, -180), (0, -216)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return colossus(J)


def ficha(svg_wrap, ruler, ground_line):
    from fichas_lib import txt, pose_g, swatches
    W, H = 1240, 640
    P = [txt(20, 30, "FICHA · COLOSSO DE OSSOS (Lich, lendário) — gigante de ossos amarrados, peito aberto cheio de crânios absorvidos e brilho verde, crânio de chifres", 14, "bold"),
         txt(20, 48, "Unidade: crânio da cabeça = 36 u. Altura curvado ≈ 6 crânios (215 u); ombros ≈ 2,6 crânios; coxa 1,2 / canela 1,2 / braço 1,55 / antebraço 1,55 (braços de gorila). Tronco ~1,5× o natural.", 10),
         txt(20, 62, "Feixes de 3 ossos com amarra de corda; rótulas e ombreiras de crânios; espinhos de vértebra nas costas. O peito mostra a mecânica: mortos presos + alma verde (brilho = foco).", 10),
         txt(20, 76, "data-fig: colosso_corpo (tudo menos a cabeça), colosso_cabeca (crânio grande + chifres + mandíbula). Vão do peito com crânios presos, alma, órbitas, dentes e amarras = inner.", 10),
         ruler(40, 92, 36 * 2, 3, "#e2d4b0", "#ad9c78", "1 crânio = 36 u (régua ×2)")]
    P.append(pose_g("cabeca_frente", head(T(0, 0), 7), (100, 230, 3.4), "colosso", label="cabeça · frente", ly=80))
    for i, (nm, lab, sub) in enumerate([("marchar", "marchar · passo pesado", "punho balançando à frente"),
                                        ("esmagar", "esmagar · punho no chão", "inclinado, boca escancarada"),
                                        ("absorver", "absorver os mortos", "braços abertos, peito aberto")]):
        x = 360 + i * 290; y = 590
        P.append(ground_line(x, y, 240))
        P.append(pose_g(nm, pose(nm), (x, y, 1.12), "colosso", GUIDE[nm], lab, sub, ly=24))
    P.append(swatches(1100, 110, [(k, PAL[k]) for k in ("bone", "bone_d", "bone_l", "cavity", "soul", "soul_d", "eye", "rope")]))
    return svg_wrap(W, H, P), (W, H)
