"""Ficha do CARNIÇAL (Ghoul) — vilão Lich, família Morte. Morto-vivo comedor de cadáveres: magro e corcunda, pele
cinza-esverdeada colada nos ossos (costelas e vértebras aparecendo), braços longos que quase tocam o chão, mãos
enormes de três dedos e polegar com garras escuras, pernas dobradas de calcanhar alto (anda na ponta dos pés),
cabeça calva alongada, orelhas pontudas para trás, bocarra de dentes finos, olhos amarelos acesos (foco).
Chão em y=0. Vista 'p' = perfil olhando à direita; vista 'f' = frente-3/4 (para o bote em escorço).
Unidade: cabeça = 20 u. Altura curvado ≈ 5 cabeças (100 u); em pé seria 7. Coxa 1,5 / canela 1,5 / pé (metatarso) 0,7;
braço 1,5 / antebraço 1,5 (braços longos); mão 0,9 com garras de 0,5.
data-fig: carnical_corpo (tronco, braços, mãos, pernas, pés, trapo), carnical_cabeca (crânio+orelhas+mandíbula).
Costelas, vértebras, olhos, dentes, boca, garras = inner (garras têm forma própria, mas ficam no contorno do corpo)."""
import math
import numpy as np
from geom import *
from piper import ik
from esqueleto import frame

INK = "#2b1a10"
PAL = dict(skin="#a3ad8c", skin_d="#6e7a5e", skin_l="#c8ccaa", claw="#2e2a22", eye="#ffe45a", mouth="#5a1a22",
           teeth="#efe6c8", rag="#4a3a2e", rag_d="#2e241c", vein="#5e6a8a")
L_TH, L_SH, L_UA, L_FA = 30.0, 30.0, 30.0, 30.0


def deg_(v):
    return math.degrees(math.atan2(v[1], v[0]))


def limb(name, pts, w, fill, fig="corpo"):
    return Pc(name, fig, fill, tube([A(q) for q in pts], w, None, cap0=0.7, cap1=0.6, per=4))


def claw_hand(name, wrist, ang, s=1.0, spread=22, curl=0.5, fill=None, fig="corpo"):
    """Mão grande: palma, 3 dedos longos e polegar, cada um com garra escura curva."""
    p = PAL; fill = fill or p["skin"]
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    c = A(wrist) + d * 4.5 * s
    pcs = [Pc(name, fig, fill, ellipse(c[0], c[1], 6.2 * s, 5.0 * s, ang, 9))]
    for k in range(3):
        a_ = math.radians(ang + (k - 1) * spread)
        dk = np.array([math.cos(a_), math.sin(a_)]); nk = np.array([-dk[1], dk[0]])
        b = c + d * 4 * s + n * (k - 1) * 3.2 * s
        L = (13 if k == 1 else 11.5) * s
        j1 = b + dk * L * 0.5; j2 = j1 + (dk * (1 - curl) + nk * curl).astype(float) * L * 0.5
        pcs.append(Pc(f"{name}_dedo{k}", fig, fill, brush([b, j1, j2], 3.6 * s, 2.2 * s, per=3)))
        dd = (j2 - j1) / (np.linalg.norm(j2 - j1) + 1e-9); nn = np.array([-dd[1], dd[0]])
        tip = j2 + dd * 6 * s + nn * 2.4 * s * (1 if curl >= 0 else -1)
        pcs.append(Pc(f"{name}_garra{k}", fig, p["claw"], [j2 + nn * 1.3 * s, j2 + dd * 3 * s + nn * 1.6 * s, tip, j2 - nn * 1.3 * s]))
    a_ = math.radians(ang - 70)
    dt = np.array([math.cos(a_), math.sin(a_)])
    b = c - n * 4 * s
    t1 = b + dt * 7 * s
    pcs.append(Pc(f"{name}_polegar", fig, fill, brush([b, t1], 3.4 * s, 2.2 * s, per=2)))
    pcs.append(Pc(f"{name}_garra_p", fig, p["claw"], [t1 + n * 1.2 * s, t1 + dt * 5 * s + d * 1.5 * s, t1 - n * 1.2 * s]))
    return pcs


def claw_foot(name, ankle, ball, fill, fig="corpo"):
    """Pé de calcanhar alto: metatarso do tornozelo à bola do pé, 3 artelhos com garra."""
    p = PAL
    an, bl = A(ankle), A(ball); d = bl - an; L = np.linalg.norm(d); t = d / L; n = np.array([-t[1], t[0]])
    pcs = [limb(name, [an, an + d * 0.5, bl], [4.2, 3.4, 3.2], fill, fig)]
    for k in (-1, 0, 1):
        b = bl + np.array([k * 3.2, 0])
        tip = b + np.array([7 + k * 1.5, 1.5])
        pcs.append(Pc(f"{name}_artelho{k + 1}", fig, fill, brush([b, b + np.array([4, 0.6]), tip], 3.0, 2.0, per=2)))
        pcs.append(Pc(f"{name}_garra{k + 1}", fig, p["claw"], [tip + np.array([0, -1.2]), tip + np.array([4, 1.4]), tip + np.array([0, 1.2])]))
    return pcs


def head(M, view="p", jaw=0.0, fig="cabeca"):
    """Cabeça. p: perfil olhando à direita, centro do crânio (0,0), articulação da mandíbula em (-1,4). f: frente."""
    p = PAL; pcs = []
    if view == "p":
        pcs.append(Pc("orelha", fig, p["skin_d"], [(-4, -5), (-12, -12), (-24, -17), (-15, -6), (-5, 1)]))
        hinge = A((-1, 4))
        Mj = chain(T(*hinge), R(jaw * 3.0), T(*(-hinge)))
        jw = [(-4, 2), (2, 6), (10, 7.5), (16, 8), (16.5, 11), (11, 14), (3, 13), (-3, 9)]
        pcs.append(Pc("mandibula", fig, p["skin_d"], list(ap(Mj, jw))))
        pcs.append(Pc("cranio", fig, p["skin"], [(-11, -2), (-9, -9), (-2, -12.5), (6, -11), (10, -7), (11.5, -4), (15, -1.5), (16.5, 1.5),
                                                 (17, 5), (16, 7.6), (10, 7.4), (3, 6), (-3, 5.6), (-8, 4.4)]))
        pcs.append(Pc("orelha_dentro", fig, p["mouth"], [(-8, -5), (-15, -10), (-20, -14), (-14, -7)], cls="inner", op=0.8))
        pcs.append(Pc("orbita", fig, p["claw"], ellipse(7.4, -3.4, 3.4, 2.4, 8, 8), cls="inner"))
        pcs.append(Pc("olho", fig, p["eye"], ellipse(8.0, -3.4, 1.9, 1.4, 8, 7), cls="inner"))
        pcs.append(Pc("sobrancelha", fig, INK, [(3.5, -6.2), (8, -6.6), (12, -4.6)], closed=False, cls="inner", sw=0.9))
        pcs.append(Pc("narina", fig, p["claw"], ellipse(15, 1.4, 1.2, 0.8, 20, 6), cls="inner"))
        pcs.append(Pc("maca", fig, p["skin_d"], [(1, 1.5), (5, 0.6), (9, 1.2)], closed=False, cls="inner", sw=0.8))
        if jaw > 1.5:
            q = ap(Mj, [(16, 8.6), (4, 7.2)])
            pcs.append(Pc("boca", fig, p["mouth"], [(4, 6.6), (16, 7.2), q[0], q[1]], mode="poly", cls="inner"))
        for i in range(5):
            x = 6 + i * 2.2
            pcs.append(Pc(f"dente{i}", fig, p["teeth"], [(x - 0.9, 6.6), (x, 9.4), (x + 0.9, 6.8)], mode="poly", cls="inner"))
            q = ap(Mj, [(x - 1.0, 8.6), (x - 0.2, 6.0), (x + 0.7, 8.6)])
            pcs.append(Pc(f"dente_b{i}", fig, p["teeth"], list(q), mode="poly", cls="inner"))
    else:
        for s in (-1, 1):
            tg = "_l" if s < 0 else "_r"
            pcs.append(Pc("orelha" + tg, fig, p["skin_d"], [(s * 8, -7), (s * 15, -13), (s * 22, -22), (s * 16, -6), (s * 8, 1)]))
        jy = jaw
        pcs.append(Pc("mandibula", fig, p["skin_d"], [(-8, 4), (8, 4), (9, 10 + jy * 0.6), (5, 15 + jy), (-5, 15 + jy), (-9, 10 + jy * 0.6)]))
        pcs.append(Pc("cranio", fig, p["skin"], [(-9, 6), (-10, -3), (-8, -10), (-3, -13.5), (3, -13.5), (8, -10), (10, -3), (9, 6), (5, 8), (-5, 8)]))
        if jy > 1.5:
            pcs.append(Pc("boca", fig, p["mouth"], [(-6.5, 6.5), (6.5, 6.5), (5, 13 + jy * 0.9), (-5, 13 + jy * 0.9)], cls="inner"))
        for i in range(6):
            x = -5 + i * 2
            pcs.append(Pc(f"dente{i}", fig, p["teeth"], [(x - 0.8, 6.4), (x, 9.2), (x + 0.8, 6.4)], mode="poly", cls="inner"))
            pcs.append(Pc(f"dente_b{i}", fig, p["teeth"], [(x - 0.8, 12.6 + jy * 0.9), (x, 9.8 + jy * 0.9), (x + 0.8, 12.6 + jy * 0.9)], mode="poly", cls="inner"))
        for s in (-1, 1):
            tg = "_l" if s < 0 else "_r"
            pcs.append(Pc("orbita" + tg, fig, p["claw"], ellipse(s * 4.4, -2, 3.0, 2.2, s * 12, 8), cls="inner"))
            pcs.append(Pc("olho" + tg, fig, p["eye"], ellipse(s * 4.4, -2, 1.7, 1.3, s * 12, 7), cls="inner"))
            pcs.append(Pc("sobrancelha" + tg, fig, INK, [(s * 1.2, -4.2), (s * 4.5, -5.4), (s * 8, -4)], closed=False, cls="inner", sw=0.9))
        pcs.append(Pc("narina", fig, p["claw"], [(-1.4, 2.4), (0, 3.6), (1.4, 2.4)], closed=False, cls="inner", sw=0.8))
    return [q.moved(M) for q in pcs]


def ghoul(J):
    """J: hip, neck, head=(x, y, rot, scale?), view, hview, jaw, al/ar (tornozelo), bl/br (bola do pé), kbl/kbr,
    wl/wr, ebl/ebr, hdl/hdr, hsl/hsr (escala da mão: escorço), curll/curlr, far, hunch, rag."""
    p = PAL; pcs = []
    view = J.get("view", "p"); far = J.get("far", "l")
    hip, nk = A(J["hip"]), A(J["neck"])
    up = (nk - hip) / np.linalg.norm(nk - hip); side = np.array([-up[1], up[0]])
    F = frame(nk, up); H = frame(hip, up)
    L = np.linalg.norm(nk - hip)
    hunch = J.get("hunch", 9)
    if view == "f":
        shl, shr = F(-15, -4), F(15, -4); hjl, hjr = H(-7, -2), H(7, -2)
    else:
        shl, shr = F(-1, -5), F(2, -5); hjl, hjr = H(-1, -2), H(2, -2)
    col = lambda tag: p["skin_d"] if tag == far else p["skin"]

    def leg(tag):
        hj = hjl if tag == "l" else hjr
        kn, an = ik(hj, J["a" + tag], L_TH, L_SH, J.get("kb" + tag, -1))
        c = col(tag)
        out = [limb("coxa_" + tag, [hj, (hj + kn) / 2, kn], [7, 5.4, 4.2], c),
               limb("canela_" + tag, [kn, (kn + an) / 2, an], [4.4, 3.2, 3.0], c),
               Pc("joelho_" + tag, "corpo", c, ellipse(kn[0], kn[1], 4.6, 4.0, 0, 8))]
        out += claw_foot("pe_" + tag, an, J["b" + tag], c)
        return out

    def arm(tag):
        sh = shl if tag == "l" else shr
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        c = col(tag)
        out = [limb("braco_" + tag, [sh, (sh + el) / 2, el], [5.6, 4.0, 3.6], c),
               limb("antebraco_" + tag, [el, (el + wr) / 2, wr], [4.0, 3.4, 3.0], c),
               Pc("cotovelo_" + tag, "corpo", c, ellipse(el[0], el[1], 4.0, 3.4, 0, 8))]
        ang = J.get("hd" + tag, math.degrees(math.atan2(*(wr - el)[::-1])))
        out += claw_hand("mao_" + tag, wr, ang, J.get("hs" + tag, 1.0), J.get("spread" + tag, 22), J.get("curl" + tag, 0.5), c)
        return out

    pcs += arm(far)
    pcs += leg(far)
    # tronco: corcunda (lado das costas mais largo em cima), cintura fina, peito afundado
    mid = (hip + nk) / 2 - side * hunch * (1 if view == "p" else 0.2)
    sp = [hip - up * 4, mid, nk + up * 2]
    if view == "p":
        wa = [7, 11, 9]; wb = [7, 7, 8]
    else:
        wa = [9, 11, 15]; wb = [9, 11, 15]
    pcs.append(Pc("tronco", "corpo", p["skin"], tube(sp, wa, wb, cap0=0.6, cap1=0.5, per=5)))
    if view == "p":
        # massas humanoides: caixa torácica (peito à frente), escápula/ombro, quadril e nádega
        ch = F(2, -12); ang = deg_(up) + 90
        pcs.append(Pc("caixa_toracica", "corpo", p["skin"], ellipse(ch[0], ch[1], 15, 11, ang, 12)))
        sc = F(-6, -6)
        pcs.append(Pc("escapula", "corpo", p["skin"], ellipse(sc[0], sc[1], 8, 6.5, ang, 10)))
        pcs.append(Pc("ombro", "corpo", col(far if False else ("r" if far == "l" else "l")), ellipse(shr[0] if far == "l" else shl[0], shr[1] if far == "l" else shl[1], 7, 6, ang, 10)))
        hp_ = H(-1, 0)
        pcs.append(Pc("quadril", "corpo", p["skin"], ellipse(hp_[0], hp_[1], 10, 9, ang, 10)))
        wa_ = H(1, 14)
        pcs.append(Pc("cintura", "corpo", p["skin_d"], [wa_ - side * 0, wa_ + side * 6], closed=False, cls="inner", sw=0.8))
    # trapo na cintura
    if J.get("rag", True):
        if view == "p":
            rg = [H(-8, 4), H(8, 4), H(10, -6), H(6, -14), H(3, -9), H(0, -16), H(-3, -9), H(-7, -13), H(-10, -4)]
        else:
            rg = [H(-11, 4), H(11, 4), H(12, -6), H(7, -15), H(3, -9), H(-1, -17), H(-4, -9), H(-8, -14), H(-12, -5)]
        pcs.append(Pc("trapo", "corpo", p["rag"], rg))
    # costelas aparecendo (linhas internas no peito) e vértebras (nós nas costas)
    S = cr_sample(sp, 8); n_ = len(S)
    Tg = np.gradient(S, axis=0); Tg /= np.linalg.norm(Tg, axis=1)[:, None]; N = np.c_[-Tg[:, 1], Tg[:, 0]]
    WA = np.interp(np.linspace(0, 2, n_), range(3), wa); WB = np.interp(np.linspace(0, 2, n_), range(3), wb)
    if view == "p":
        for k in range(4):
            a_ = F(12, -6 - k * 4.6); m_ = F(3, -4 - k * 5); b_ = F(-6, -6 - k * 5.4)
            pcs.append(Pc(f"costela{k}", "corpo", p["skin_d"], [a_, m_, b_], closed=False, cls="inner", sw=0.9))
        for k, i in enumerate(range(int(n_ * 0.3), int(n_ * 0.95), 2)):
            q = S[i] - N[i] * WA[i] * 0.96
            pcs.append(Pc(f"vertebra{k}", "corpo", p["skin_l"], ellipse(q[0], q[1], 1.6, 1.2, 0, 6), cls="inner"))
    else:
        for k in range(4):
            for s in (-1, 1):
                y = -10 - k * 5
                pcs.append(Pc(f"costela{k}{s}", "corpo", p["skin_d"], [F(s * 2, y), F(s * 8, y + 1.5), F(s * 12, y - 1)], closed=False, cls="inner", sw=0.8))
        pcs.append(Pc("esterno", "corpo", p["skin_d"], [F(0, -6), F(0, -26)], closed=False, cls="inner", sw=0.7))
    pcs += leg("r" if far == "l" else "l")
    hx, hy, hr = J["head"][:3]
    hk = J["head"][3] if len(J["head"]) > 3 else 1.0
    Mh = tmat(hx, hy, hr, hk)
    pcs += head(Mh, J.get("hview", view), J.get("jaw", 0))
    pcs += arm("r" if far == "l" else "l")
    return pcs


POSES = {
    # espreitar: agachado de perfil, nós dos dedos no chão, dorso arqueado alto, cabeça baixa à frente
    "espreitar": dict(view="p", hip=(-14, -40), neck=(18, -58), head=(34, -56, 18), jaw=1, hunch=12, far="l",
                      ar=(-2, -8), br=(8, 0), kbr=-1, al=(-30, -6), bl=(-20, 0), kbl=-1,
                      wr=(42, -24), ebr=1, hdr=78, curlr=0.8, wl=(24, -22), ebl=1, hdl=84, curll=0.8),
    # saltar: bote em diagonal subindo, braços à frente com garras abertas, pernas esticadas atrás
    "saltar": dict(view="p", hip=(-6, -70), neck=(22, -110), head=(38, -114, -10), jaw=7, hunch=8, far="l",
                   ar=(-34, -42), br=(-46, -38), kbr=-1, al=(-24, -56), bl=(-38, -58), kbl=-1,
                   wr=(66, -118), ebr=1, hdr=-10, curlr=0.2, spreadr=26, wl=(60, -100), ebl=1, hdl=8, curll=0.25),
    # atacar (frente-3/4): agachado de base larga, garra direita erguida para o golpe, esquerda baixa à frente, bocarra aberta
    "atacar": dict(view="f", hip=(0, -46), neck=(-4, -88), head=(-6, -102, -8), hview="f", jaw=6, hunch=4, far="l",
                   al=(-30, -6), bl=(-38, 0), kbl=1, ar=(28, -6), br=(36, 0), kbr=-1,
                   wr=(30, -132), ebr=-1, hdr=-100, spreadr=26, curlr=0.3, wl=(-34, -48), ebl=1, hdl=110, curll=0.6, hsl=1.0),
    # uivar: em pé curvado, cabeça jogada para trás gritando, braços abertos para baixo (sorve as mortes em volta)
    "uivar": dict(view="f", hip=(0, -58), neck=(2, -100), head=(4, -114, 14), hview="f", jaw=8, hunch=2, far="r",
                  al=(-20, -6), bl=(-28, 0), kbl=1, ar=(22, -6), br=(30, 0), kbr=-1,
                  wl=(-46, -72), ebl=1, hdl=150, spreadl=28, curll=-0.1, wr=(48, -70), ebr=-1, hdr=30, spreadr=28, curlr=-0.1),
}
GUIDE = {"espreitar": [(-20, 0), (-14, -40), (18, -58), (40, -50)],
         "saltar": [(-46, -38), (-14, -56), (-6, -70), (8, -98), (22, -110), (66, -118)],
         "atacar": [(-38, 0), (-10, -40), (-4, -88), (30, -132)],
         "uivar": [(-28, 0), (-6, -40), (2, -100), (6, -126)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return ghoul(J)
