"""Ficha do ESQUELETO (vilão Lich, família Morte). Esqueleto humano de anatomia plausível: crânio (identidade do v2:
`skull` de cartas_v2.html, frente) com mandíbula articulada, coluna de vértebras, caixa torácica com arco costal e
vãos das costelas, cintura escapular (clavículas), pelve em borboleta com forames, ossos longos com epífises e côndilos
(rádio+ulna e tíbia+fíbula em par), mãos de falanges e pés com calcâneo.
Chão em y=0. Vista 'p' = perfil olhando para a direita (espelhe com scale(-1 1) para a esquerda); vista 'f' = frente-3/4.
Unidade: crânio (com mandíbula) = 22 u. Altura em pé ≈ 7 crânios (154 u). Quadril a 3,5; pescoço (C7) a 5,9;
fêmur 1,7 / tíbia 1,6 / úmero 1,3 / antebraço 1,15 / pé 0,65 crânio. Ombros: 1,8 crânio de largura (vista f).
data-fig: <fig>_corpo (ossos, mãos, pés, trapo), <fig>_cabeca (crânio+mandíbula), <fig>_arco, <fig>_flecha, <fig>_espada,
<fig>_aljava. Vãos das costelas, forames, órbitas, nariz, dentes, suturas e brilho dos olhos = inner."""
import math
import numpy as np
from geom import *
from piper import ik

INK = "#2b1a10"
PAL = dict(bone="#e6d8b8", bone_d="#b8a886", bone_l="#f6eeda", socket="#241426", eye="#9effc4",
           rag="#3c4a52", rag_d="#26323a", wood="#6a4a2c", wood_d="#4a321e", string="#d8d0b8",
           rust="#8a5a3a", blade="#a8a49a", blade_d="#6e6a62", fletch="#4a8a7a", leather="#5a3e28")
L_TH, L_SH, L_UA, L_FA = 38.0, 36.0, 29.0, 25.0

# crânio de frente: os mesmos paths do skull() de cartas_v2.html (calota+maxila e mandíbula)
SKULL_F = "M-10 -1 C-11 -12 -5 -16 0 -16 C5 -16 11 -12 10 -1 C10 3 7 5 6 8 L-6 8 C-7 5 -10 3 -10 -1 Z"
JAW_F = "M-6 8 L-5.5 12 L5.5 12 L6 8 Z"


def frame(o, up):
    o = A(o); up = A(up) / np.linalg.norm(up); side = np.array([-up[1], up[0]])
    return lambda s, u: o + side * s + up * u


def bone(name, a, b, w0=3.4, wm=2.0, w1=3.2, fill=None, fig="corpo"):
    """Osso longo: haste fina com epífises largas nas pontas (tube de 5 pontos)."""
    a, b = A(a), A(b)
    d = b - a
    sp = [a, a + d * 0.12, a + d * 0.5, a + d * 0.88, b]
    w = [w0 * 0.8, w0, wm, w1, w1 * 0.8]
    return Pc(name, fig, fill or PAL["bone"], tube(sp, w, w, cap0=0.7, cap1=0.7, per=3))


def pair(name, a, b, wa_, wb_, gap, fill, fig="corpo"):
    """Dois ossos paralelos (rádio+ulna, tíbia+fíbula) que se juntam nas pontas, com o vão entre eles (inner)."""
    a, b = A(a), A(b); d = b - a; L = np.linalg.norm(d); t = d / L; n = np.array([-t[1], t[0]])
    m = (a + b) / 2
    p1 = [a, a + d * 0.25 + n * gap * 0.8, m + n * gap, a + d * 0.75 + n * gap * 0.8, b]
    p2 = [a, a + d * 0.25 - n * gap * 0.5, m - n * gap * 0.6, a + d * 0.75 - n * gap * 0.5, b]
    pcs = [Pc(name + "_a", fig, fill, tube(p1, [wa_ * 1.2, wa_, wa_ * 0.8, wa_, wa_ * 1.2], None, cap0=0.7, cap1=0.7, per=3)),
           Pc(name + "_b", fig, fill, tube(p2, [wb_ * 1.2, wb_, wb_ * 0.8, wb_, wb_ * 1.2], None, cap0=0.7, cap1=0.7, per=3))]
    # vão entre os dois ossos (escuro, interno)
    g = [a + d * 0.3 + n * gap * 0.15, m + n * gap * 0.2, a + d * 0.7 + n * gap * 0.15]
    pcs.append(Pc(name + "_vao", fig, PAL["socket"], brush(g, 1.0, 0.6, per=3), cls="inner"))
    return pcs


def knob(name, c, r, fill, fig="corpo", ang=0):
    return Pc(name, fig, fill, ellipse(c[0], c[1], r, r * 0.82, ang, 8))


def hand(name, wrist, ang, s=1.0, mode="open", fill=None, fig="corpo"):
    """Mão de falanges. mode: open (dedos abertos), claw (garra curvada), grip (fechada num cabo), flat (espalmada no chão)."""
    fill = fill or PAL["bone"]
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    c = A(wrist) + d * 3.4 * s
    pcs = [Pc(name, fig, fill, ellipse(c[0], c[1], 4.2 * s, 3.4 * s, ang, 8))]
    if mode == "grip":
        for k in range(4):
            b = c + d * 2.4 * s + n * (k - 1.5) * 1.9 * s
            pcs.append(Pc(f"{name}_dedo{k}", fig, fill, brush([b, b + d * 3 * s, b + d * 3.4 * s - n * 2.6 * s], 1.9 * s, 1.3 * s, per=2)))
        return pcs
    spread = dict(open=14, claw=10, flat=18)[mode]
    for k in range(4):
        a_ = math.radians(ang + (k - 1.5) * spread)
        dk = np.array([math.cos(a_), math.sin(a_)]); nk = np.array([-dk[1], dk[0]])
        b = c + d * 2.6 * s + n * (k - 1.5) * 1.7 * s
        Lk = (6.2 if k in (1, 2) else 5.2) * s
        if mode == "claw":
            pts = [b, b + dk * Lk * 0.55 - nk * 0.4 * s, b + dk * Lk * 0.85 + nk * 1.8 * s, b + dk * Lk * 0.8 + nk * 3.4 * s]
        else:
            pts = [b, b + dk * Lk * 0.5, b + dk * Lk]
        pcs.append(Pc(f"{name}_dedo{k}", fig, fill, brush(pts, 1.9 * s, 1.0 * s, per=2)))
    a_ = math.radians(ang - 62)
    dt = np.array([math.cos(a_), math.sin(a_)])
    b = c - n * 2.6 * s
    pcs.append(Pc(f"{name}_polegar", fig, fill, brush([b, b + dt * 3.4 * s, b + dt * 5.6 * s + d * 1.2 * s], 2.0 * s, 1.1 * s, per=2)))
    return pcs


def foot(name, ankle, toe, fill, fig="corpo"):
    an, to = A(ankle), A(toe); d = to - an; L = np.linalg.norm(d); t = d / L; n = np.array([-t[1], t[0]])
    if n[1] < 0:
        n = -n  # n aponta para baixo (sola)
    heel = an - t * 3.5 + n * 2.5
    pcs = [Pc(name, fig, fill, [heel - n * 2, an - n * 2.4, an + t * L * 0.55 - n * 1.6, to - n * 0.6, to + n * 1.4,
                                an + t * L * 0.5 + n * 2.6, heel + n * 1.6, heel - t * 1.5])]
    for k in (-1, 0, 1):
        b = to - t * 2 + n * (0.4 + k * 0.2) + t * 0
        pcs.append(Pc(f"{name}_artelho{k + 1}", fig, fill, brush([b - n * k * 1.6, b + t * 4 - n * k * 2.2], 1.6, 1.0, per=2)))
    return pcs


def skull(M, view="f", jaw=0.0, glow=True, fill=None, fill_d=None, fig="cabeca"):
    """Crânio. view f = frente (paths do v2); p = perfil olhando para a direita. Centro da calota em (0,0); queixo ~ y+12."""
    p = PAL; fill = fill or p["bone"]; fill_d = fill_d or p["bone_d"]; pcs = []
    if view == "f":
        jy = jaw
        pcs.append(Pc("mandibula", fig, fill_d, d=f"M-6 {fmt(8 + jy * 0.4)} L-5.5 {fmt(12 + jy)} L5.5 {fmt(12 + jy)} L6 {fmt(8 + jy * 0.4)} Z"))
        pcs.append(Pc("cranio", fig, fill, d=SKULL_F))
        for s in (-1, 1):
            tg = "_l" if s < 0 else "_r"
            ox = 7 * s
            pcs.append(Pc("orbita" + tg, fig, p["socket"], d=f"M{fmt(ox)} -3 C{fmt(ox)} -6 {fmt(2 * s)} -6 {fmt(2 * s)} -2 C{fmt(2 * s)} 1 {fmt(ox)} 1 {fmt(ox)} -3 Z", cls="inner"))
            if glow:
                pcs.append(Pc("olho" + tg, fig, p["eye"], ellipse(4.5 * s, -2.5, 1.3, 1.3, 0, 6), cls="inner"))
        pcs.append(Pc("nariz", fig, p["socket"], [(0, 2), (-1.6, 5), (1.6, 5)], mode="poly", cls="inner"))
        for i, x in enumerate((-3, 0, 3)):
            pcs.append(Pc(f"dente{i}", fig, INK, [(x, 8), (x, 11.5 if x else 12)], closed=False, cls="inner", sw=0.7))
        if jy > 1.5:
            pcs.append(Pc("boca", fig, p["socket"], [(-5, 8.6), (5, 8.6), (4.6, 8 + jy * 0.9), (-4.6, 8 + jy * 0.9)], mode="poly", cls="inner"))
        pcs.append(Pc("sutura", fig, fill_d, [(-2, -15.5), (0, -11), (-1, -7)], closed=False, cls="inner", sw=0.6))
    else:
        # perfil: calota redonda atrás, testa, arcada, osso nasal, maxila com dentes; mandíbula gira na articulação (-2,5)
        hinge = A((-2.5, 5.0))
        Mj = chain(T(*hinge), R(jaw * 3.2), T(*(-hinge)))
        jw = [(-3.5, 3.5), (0, 6.2), (8, 7.2), (11.5, 7.6), (12, 10.5), (9, 12.8), (3, 12.4), (-1.5, 11), (-4, 7.5)]
        pcs.append(Pc("mandibula", fig, fill_d, list(ap(Mj, jw))))
        pcs.append(Pc("cranio", fig, fill, [(-12, -6), (-10.5, -12.5), (-4, -16.6), (3.5, -15.6), (9, -11), (10.6, -5.5), (12.2, -3.4),
                                            (12.6, 0.6), (13.4, 3.2), (12.6, 7.2), (7.5, 8.2), (2, 6.8), (-2.5, 5.5), (-7, 5.4),
                                            (-10.4, 2.4)]))
        pcs.append(Pc("orbita", fig, p["socket"], ellipse(6.4, -2.6, 3.4, 3.2, 10, 9), cls="inner"))
        if glow:
            pcs.append(Pc("olho", fig, p["eye"], ellipse(7.0, -2.4, 1.4, 1.3, 0, 6), cls="inner"))
        pcs.append(Pc("nariz", fig, p["socket"], [(10.6, 1.2), (12.6, 2.4), (11.6, 4.6), (10, 4)], cls="inner"))
        pcs.append(Pc("zigoma", fig, fill_d, [(-1, 3.2), (3, 2.6), (6.4, 2.4)], closed=False, cls="inner", sw=0.7))
        pcs.append(Pc("orelha", fig, p["socket"], ellipse(-4.2, 2.2, 1.3, 1.6, 0, 6), cls="inner"))
        for i, x in enumerate((6.5, 8.5, 10.5)):
            pcs.append(Pc(f"dente{i}", fig, INK, [(x, 6.4), (x, 8.6)], closed=False, cls="inner", sw=0.6))
            q = ap(Mj, [(x - 0.4, 7.2), (x - 0.4, 9.2)])
            pcs.append(Pc(f"dente_b{i}", fig, INK, list(q), closed=False, cls="inner", sw=0.6))
        if jaw > 1.5:
            q = ap(Mj, [(11.2, 7.4), (4, 6.8)])
            pcs.append(Pc("boca", fig, p["socket"], [(4, 6.8), (11.8, 7.0), q[0], q[1]], mode="poly", cls="inner"))
        pcs.append(Pc("sutura", fig, fill_d, [(-6, -15), (-3, -10), (-6, -6)], closed=False, cls="inner", sw=0.6))
    return [q.moved(M) for q in pcs]


def bow(hand_pt, aim_deg, H=72, draw_pt=None, fig="arco"):
    """Arco recurvo de madeira: hand_pt = punho, aim_deg = direção da flecha. draw_pt = mão que puxa a corda (ou None)."""
    p = PAL
    d = np.array([math.cos(math.radians(aim_deg)), math.sin(math.radians(aim_deg))]); n = np.array([-d[1], d[0]])
    h = A(hand_pt)
    bend = 14 if draw_pt is not None else 8
    top = h + n * H / 2 - d * (bend - 2); bot = h - n * H / 2 - d * (bend - 2)
    # recurvo: pontas viram para a frente
    spine = [bot + d * 4 - n * 2, bot, h - n * H * 0.28 + d * 1.5, h + d * 3, h + n * H * 0.28 + d * 1.5, top, top + d * 4 + n * 2]
    w = [1.0, 1.7, 2.4, 3.0, 2.4, 1.7, 1.0]
    pcs = [Pc("arco", fig, p["wood"], tube(spine, w, None, cap0=0.4, cap1=0.4, per=3))]
    pcs.append(Pc("punho", fig, p["leather"], [h + n * 5 + d * 4.6, h + n * 5 - d * 1.6, h - n * 5 - d * 1.6, h - n * 5 + d * 4.6], mode="poly"))
    sp = draw_pt if draw_pt is not None else (h - d * (bend + 2))
    pcs.append(Pc("corda", fig, p["string"], [top, A(sp), bot], closed=False, cls="inner", sw=0.8, mode="poly"))
    return pcs


def arrow(tail, aim_deg, L=74, fig="flecha", fire=False):
    p = PAL
    d = np.array([math.cos(math.radians(aim_deg)), math.sin(math.radians(aim_deg))]); n = np.array([-d[1], d[0]])
    t0 = A(tail); tip = t0 + d * L
    pcs = [Pc("haste", fig, p["wood_d"], [t0 + n * 0.9, tip - d * 6 + n * 0.9, tip - d * 6 - n * 0.9, t0 - n * 0.9], mode="poly"),
           Pc("ponta", fig, p["blade_d"], [tip - d * 7 + n * 3, tip, tip - d * 7 - n * 3, tip - d * 5], mode="poly")]
    for s in (-1, 1):
        pcs.append(Pc(f"pena{'_l' if s < 0 else '_r'}", fig, p["fletch"], [t0 + d * 1, t0 + d * 12 + n * s * 1, t0 + d * 9 + n * s * 4.6, t0 - d * 1 + n * s * 4.2], mode="poly"))
    return pcs


def sword(hand_pt, ang, L=50, fig="espada", broken=False):
    """Espada curta enferrujada (lâmina lascada)."""
    p = PAL
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    h = A(hand_pt); pm = h - d * 6; g = h + d * 4; tip = g + d * L
    blade = [g + n * 3.2, g + d * L * 0.45 + n * 3.0, g + d * L * 0.5 + n * 1.6, g + d * L * 0.56 + n * 3.0, tip - d * 8 + n * 2.6, tip,
             tip - d * 8 - n * 2.6, g + d * L * 0.7 - n * 3.0, g + d * L * 0.3 - n * 2.0, g + d * L * 0.25 - n * 3.2, g - n * 3.2]
    if broken:
        blade = [g + n * 3.2, g + d * L * 0.55 + n * 3.0, g + d * L * 0.62 + n * 0.5, g + d * L * 0.58 - n * 1.5, g + d * L * 0.66 - n * 3.0, g - n * 3.2]
    pcs = [Pc("cabo", fig, p["leather"], [pm + n * 1.6, g + n * 1.6, g - n * 1.6, pm - n * 1.6], mode="poly"),
           Pc("pomo", fig, p["rust"], ellipse(pm[0], pm[1], 2.6, 2.6, 0, 8)),
           Pc("lamina", fig, p["blade"], blade, mode="poly"),
           Pc("guarda", fig, p["rust"], [g - n * 7 - d * 1.4, g + n * 7 - d * 1.4, g + n * 7 + d * 1.4, g - n * 7 + d * 1.4], mode="poly")]
    for k, (a_, b_) in enumerate([(0.2, 0.32), (0.62, 0.7)]):
        if broken and a_ > 0.5:
            continue
        pcs.append(Pc(f"ferrugem{k}", fig, p["rust"], [g + d * L * a_ + n * 2.4, g + d * L * b_ + n * 1.6, g + d * L * b_ - n * 0.6, g + d * L * a_ + n * 0.2], cls="inner", op=0.8))
    return pcs


def quiver(top, ang, fig="aljava"):
    p = PAL
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    t = A(top); b = t + d * 34
    pcs = []
    for k in range(3):
        q = t + n * (k - 1) * 2.6
        pcs.append(Pc(f"flecha_aljava{k}", fig, p["fletch"], [q - d * 8 + n * 1.6, q + n * 1.6, q - n * 1.6, q - d * 8 - n * 1.6], mode="poly"))
    pcs.append(Pc("aljava", fig, p["leather"], [t + n * 5, b + n * 4, b + d * 2, b - n * 4, t - n * 5]))
    pcs.append(Pc("aljava_cinta", fig, p["wood_d"], [t + d * 6 + n * 5, t + d * 6 - n * 5], closed=False, cls="inner", sw=1.0))
    return pcs


def rag(pts, fig="corpo", fill=None):
    return Pc("trapo", fig, fill or PAL["rag"], pts)


def skeleton(J):
    """J: hip, neck (C7), head=(x, y, rot), view ('p'|'f'), hview, jaw, al/ar tl/tr (tornozelo/artelhos), kbl/kbr,
    wl/wr (pulsos), ebl/ebr, hdl/hdr (ângulo da mão), hml/hmr (modo da mão), far ('l'|'r'), legs (False = enterrado),
    bow=(tag, aim, draw_tag|None), arrow_nock (bool), sword=(tag, ang, L, broken), quiver=(top, ang), rag=[pts], glow."""
    p = PAL; pcs = []
    view = J.get("view", "p"); far = J.get("far", "l")
    hip, nk = A(J["hip"]), A(J["neck"])
    up = (nk - hip) / np.linalg.norm(nk - hip); side = np.array([-up[1], up[0]])
    F = frame(nk, up); H = frame(hip, up)
    if view == "f":
        shl, shr = F(-18, -5), F(18, -5); hjl, hjr = H(-10, -3), H(10, -3)
    else:
        shl, shr = F(-2, -6), F(1, -6); hjl, hjr = H(-1, -3), H(1.5, -3)
    col = lambda tag: p["bone_d"] if tag == far else p["bone"]
    props_back, props_front = [], []

    def leg(tag):
        if J.get("legs", True) is False:
            return []
        hj = hjl if tag == "l" else hjr
        kn, an = ik(hj, J["a" + tag], L_TH, L_SH, J.get("kb" + tag, -1))
        c = col(tag)
        out = [bone("femur_" + tag, hj, kn, 3.8, 2.4, 3.6, c)]
        out += pair("canela_" + tag, kn, an, 2.0, 1.1, 2.0, c)
        out.append(knob("patela_" + tag, kn + (kn - hj) / np.linalg.norm(kn - hj) * 0.5, 3.4, c))
        out += foot("pe_" + tag, an, J["t" + tag], c)
        return out

    def arm(tag):
        sh = shl if tag == "l" else shr
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        c = col(tag)
        out = [bone("umero_" + tag, sh, el, 3.4, 2.0, 3.0, c)]
        out += pair("antebraco_" + tag, el, wr, 1.7, 1.3, 1.7, c)
        out.append(knob("cotovelo_" + tag, el, 2.8, c))
        ang = J.get("hd" + tag, math.degrees(math.atan2(*(wr - el)[::-1])))
        out += hand("mao_" + tag, wr, ang, J.get("hs" + tag, J.get("hs", 1.0)), J.get("hm" + tag, "open"), c)
        return out, el, wr

    if J.get("quiver"):
        props_back += quiver(*J["quiver"])
    # membros do lado de longe primeiro
    far_arm, _, wfar = arm(far)
    pcs += props_back
    pcs += leg(far)
    pcs += far_arm
    # coluna (lombar e cervical): cordão contínuo + vértebras
    if view == "f":
        sp0, sp1 = H(0, 2), F(0, -32)
    else:
        sp0, sp1 = H(-4, 4), F(-9, -30)
    bend = J.get("spine_bend", 0)
    mid = (sp0 + sp1) / 2 + side * bend
    spine = [sp0, mid, sp1]
    pcs.append(Pc("coluna", "corpo", p["bone_d"], tube(spine, [1.8, 1.8, 1.8], None, cap0=0.5, cap1=0.5, per=4)))
    ss = cr_sample(spine, 6)
    for i in range(0, len(ss) - 1, 2):
        tg = ss[min(i + 1, len(ss) - 1)] - ss[max(i - 1, 0)]; a_ = math.degrees(math.atan2(tg[1], tg[0]))
        pcs.append(Pc(f"vertebra{i}", "corpo", p["bone"], ellipse(ss[i][0], ss[i][1], 2.2, 3.6, a_, 8)))
    # pelve
    if J.get("legs", True) is not False:
        if view == "f":
            pv = [H(-15, 7), H(-7, 3), H(0, 5), H(7, 3), H(15, 7), H(14, -1), H(8, -6), H(4, -11), H(-4, -11), H(-8, -6), H(-14, -1)]
            pcs.append(Pc("pelve", "corpo", p["bone"], pv))
            for s in (-1, 1):
                q = H(s * 6, -6)
                pcs.append(Pc("forame" + ("_l" if s < 0 else "_r"), "corpo", p["socket"], ellipse(q[0], q[1], 2.6, 2.0, 0, 7), cls="inner"))
        else:
            pv = [H(-9, 8), H(-2, 6), H(4, 9), H(7, 2), H(5, -6), H(0, -10), H(-6, -7), H(-10, 0)]
            pcs.append(Pc("pelve", "corpo", p["bone"], pv))
            q = H(1, -5)
            pcs.append(Pc("forame", "corpo", p["socket"], ellipse(q[0], q[1], 2.2, 2.0, 0, 7), cls="inner"))
    if J.get("rag"):
        pcs.append(rag(J["rag"]))
    # caixa torácica
    if view == "f":
        rc = [F(-8, 1), F(8, 1), F(15, -6), F(17, -16), F(15, -26), F(9, -32), F(3, -29), F(0, -24), F(-3, -29), F(-9, -32),
              F(-15, -26), F(-17, -16), F(-15, -6)]
        pcs.append(Pc("costelas", "corpo", p["bone"], rc))
        for i in range(4):
            for s in (-1, 1):
                g = [F(s * 3, -6.5 - i * 6), F(s * 9, -6 - i * 6.4), F(s * 14, -8.5 - i * 6.2)]
                pcs.append(Pc(f"vao_costela{i}{'l' if s < 0 else 'r'}", "corpo", p["socket"], brush(g, 2.0, 0.8, per=3), cls="inner"))
        pcs.append(Pc("esterno", "corpo", p["bone_d"], [F(0, 0), F(0, -20)], closed=False, cls="inner", sw=0.7))
        pcs.append(Pc("claviculas", "corpo", p["bone"], tube([shl + up * 1, F(-6, 1), F(6, 1), shr + up * 1], [1.8] * 4, None, cap0=0.6, cap1=0.6, per=3)))
    else:
        rc = [F(-9, 1), F(-2, 2.5), F(6, -2), F(11, -10), F(12.5, -20), F(9.5, -29), F(2, -33), F(-6, -31), F(-11, -24), F(-12, -12)]
        pcs.append(Pc("costelas", "corpo", p["bone"], rc))
        for i in range(4):
            g = [F(-8, -6 - i * 6), F(0, -6.5 - i * 6.6), F(8, -10 - i * 6.2)]
            pcs.append(Pc(f"vao_costela{i}", "corpo", p["socket"], brush(g, 2.0, 0.8, per=3), cls="inner"))
        pcs.append(Pc("escapula", "corpo", p["bone_d"], [F(-10, -2), F(-6, -4), F(-7, -16), F(-11, -13)], cls="inner", op=0.9))
    # cervical até o crânio
    hx, hy, hr = J["head"]
    hk = J.get("hk", 1.0)
    Mh = tmat(hx, hy, hr, hk)
    base_ = ap(Mh, [(-6, 6)] if J.get("hview", view) == "p" else [(0, 10)])[0]
    cv = [nk + up * 1, (nk + base_) / 2, base_]
    for i, q in enumerate(cr_sample(cv, 2)):
        pcs.append(Pc(f"cervical{i}", "corpo", p["bone"], ellipse(q[0], q[1], 2.4, 2.0, 0, 7)))
    pcs += leg("r" if far == "l" else "l")
    near_arm, _, wnear = arm("r" if far == "l" else "l")
    # arma/arco: arco na mão de longe fica à frente do corpo (perfil), espada na mão de perto por cima
    if J.get("bow"):
        tag, aim, dtag = J["bow"]
        wb = wfar if tag == far else wnear
        dp = (wnear if dtag != far else wfar) if dtag else None
        bp = bow(wb, aim, J.get("bow_h", 72), dp)
        if J.get("arrow_nock") and dp is not None:
            bp += arrow(dp - np.array([math.cos(math.radians(aim)), math.sin(math.radians(aim))]) * 2, aim, J.get("arrow_len", 70))
        props_front += bp
    if J.get("sword"):
        tag, ang, L, broken = J["sword"]
        ww = wfar if tag == far else wnear
        sp_ = sword(ww, ang, L, broken=broken)
        if tag == far:
            pcs = sp_ + pcs  # espada na mão de longe: atrás do corpo
        else:
            props_front += sp_
    pcs += near_arm
    pcs += skull(Mh, J.get("hview", view), J.get("jaw", 0), J.get("glow", True))
    pcs += props_front
    return pcs


POSES = {
    # corrida de perfil: tronco inclinado 18° para a frente, joelho da frente alto, perna de trás empurrando, espada à frente
    "correr": dict(view="p", hip=(0, -74), neck=(17, -124), head=(25, -139, 6), jaw=2, far="l",
                   ar=(32, -34), tr=(45, -33), kbr=-1, al=(-34, -12), tl=(-41, -2), kbl=-1,
                   wr=(44, -110), ebr=1, hmr="grip", hdr=-30, wl=(-14, -92), ebl=-1, hml="open",
                   sword=("r", -48, 46, False), spine_bend=-3),
    # tiro de arco de perfil, recuando: peso no pé de trás, corda puxada até a mandíbula, mira 15° para cima
    "atirar": dict(view="p", hip=(-4, -76), neck=(-9, -127), head=(-4, -142, -12), jaw=0, far="l",
                   ar=(28, -6), tr=(39, -2), kbr=-1, al=(-30, 0), tl=(-19, 0), kbl=-1,
                   wl=(41, -138), ebl=1, hml="grip", hdl=-105, wr=(-14, -134), ebr=-1, hmr="grip", hdr=160,
                   bow=("l", -15, "r"), arrow_nock=True, quiver=((-14, -132), 112), spine_bend=2),
    # golpe de frente-3/4: espada erguida sobre o ombro (preparação), braço livre à frente, base larga
    "golpear": dict(view="f", hip=(0, -72), neck=(-8, -123), head=(-11, -139, -12), jaw=5, far="l",
                    al=(-36, 0), tl=(-46, 0), kbl=1, ar=(32, -2), tr=(42, 0), kbr=-1,
                    wr=(26, -158), ebr=-1, hmr="grip", hdr=-120, wl=(-50, -104), ebl=1, hml="claw",
                    sword=("r", -128, 48, False), rag=None),
    # erguer-se do chão (frente-3/4): só tronco e braços acima da terra; uma garra no chão, a outra estendida para o céu
    "erguer": dict(view="f", hip=(6, 4), neck=(-2, -44), head=(-6, -60, -22), jaw=6, far="l", legs=False,
                   wr=(36, -86), ebr=1, hmr="claw", hdr=-80, wl=(-38, -2), ebl=1, hml="flat", hdl=160),
}
GUIDE = {"correr": [(-41, -2), (-10, -40), (0, -74), (17, -124), (30, -150)],
         "atirar": [(-19, 0), (-10, -40), (-4, -76), (-9, -127), (0, -150)],
         "golpear": [(-46, 0), (-20, -40), (0, -72), (-8, -123), (20, -160)],
         "erguer": [(-36, -2), (-10, -10), (-2, -36), (20, -70), (34, -78)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return skeleton(J)


def J(name, **over):
    d = dict(POSES[name]); d.update(over)
    return d


def sil(name, **over):
    """Silhueta unida (para multidões em #enxame)."""
    polys = union_poly(pose(name, glow=False, **over), off=(140, 230))  # o raster do union_outline só cobre a janela
    area = lambda P: 0.5 * abs(np.dot(P[:, 0], np.roll(P[:, 1], 1)) - np.dot(P[:, 1], np.roll(P[:, 0], 1)))
    return max(polys, key=area)
