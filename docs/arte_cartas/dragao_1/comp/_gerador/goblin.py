"""Ficha do goblin (vilão Dragão): verde, cabeçudo, orelhas longas varridas para trás, nariz adunco, olhos grandes
creme com íris laranja, bocarra de dentes tortos; túnica de couro com bandoleira vermelha; braços longos, mãos grandes
de 4 dedos, pés descalços com garras. Perfil 3/4 olhando para +x, chão em y=0.
Unidade: cabeça = 22 u (queixo→topo do crânio). Altura parado ≈ 3,4 cabeças (75 u): quadril a 1,2; pescoço a 2,3;
coxa 0,6 / canela 0,6 / pé 0,4; braço 0,55 / antebraço 0,5 / mão 0,3 (os dedos passam do joelho com o braço solto).
Membros por IK de dois ossos (joelho para a frente, cotovelo para trás/baixo).
data-fig: goblin_corpo (tronco, túnica, braços, mãos, pernas, pés = 1), goblin_cabeca (crânio, orelhas, nariz = 1),
goblin_<prop> (dinamite, tocha, balde... = 1 cada). Olhos, boca, dentes, sobrancelhas, dedos, costuras = inner."""
import base  # noqa: F401
import math
import numpy as np
from geom import *
from piper import ik

INK = "#2b1a10"
PAL = dict(skin="#7aa346", skin_d="#5f8a3a", skin_l="#87ae4c", tunic="#8c5c34", tunic_d="#6a4426", belt="#4a2c18",
           band="#a8321e", tnt="#c83c26", tnt_end="#e8b88a", fuse="#c8a060", eye="#fff6cc", iris="#e8742a",
           mouth="#3a1410", teeth="#f2e6c0", claw="#efe0b0", ear_in="#c0745a", gold="#e8b440", brow="#4f7428")
L_TH, L_SH, L_UA, L_FA = 13.5, 13.0, 12.0, 11.0


# ---------------------------------------------------------------- cabeça 3/4 (centro do crânio 0,0; +x = frente)
SKULL = [(-10, -2), (-8.6, -8), (-3, -11.6), (4, -11.2), (9, -7.6), (11, -2.5), (11.6, 3), (9.6, 8.6), (4, 11.4),
         (-2, 11), (-7, 7.4)]
EAR_N = [(-6.5, -3), (-14, -6.5), (-24, -11), (-33, -17), (-22, -6.5), (-14, 0.5), (-7, 3.5)]
EAR_N_IN = [(-9, -2.2), (-16, -6), (-26, -12.6), (-17, -3.4), (-10, 0.8)]
EAR_F = [(-1, -9.5), (-6, -15), (-12, -22), (-20, -30), (-12, -17), (-5.5, -8)]
NOSE = [(8.4, -3.2), (13, -2), (18.6, 2.6), (19, 5.6), (15.6, 5.4), (11.6, 4.2), (8.6, 3)]
JAW_OPEN = [(1.5, 6), (6, 7.6), (12.4, 6.4), (13.6, 8.4), (11, 14), (5, 16.4), (0, 13.6)]


def head(M, open_=True, angry=True, look=(1.0, 0.0)):
    p = PAL; pcs = []
    pcs.append(Pc("orelha_longe", "cabeca", p["skin_d"], EAR_F))
    pcs.append(Pc("cranio", "cabeca", p["skin_l"], SKULL))
    if open_:
        pcs.append(Pc("queixo", "cabeca", p["skin_l"], JAW_OPEN))
    pcs.append(Pc("orelha", "cabeca", p["skin"], EAR_N))
    pcs.append(Pc("orelha_dentro", "cabeca", p["ear_in"], EAR_N_IN, cls="inner"))
    pcs.append(Pc("brinco", "cabeca", p["gold"], ellipse(-12, 3.5, 2.2, 2.2, 0, 8), closed=False, cls="inner", sw=0.9))
    # olhos: perto (grande) e longe (menor, atrás do nariz)
    lx, ly = look
    pcs.append(Pc("olho", "cabeca", p["eye"], ellipse(3.6, -3.4, 3.8, 3.4, -8, 10), cls="inner"))
    pcs.append(Pc("olho_longe", "cabeca", p["eye"], ellipse(10.2, -4.2, 2.2, 3.0, -8, 8), cls="inner"))
    pcs.append(Pc("iris", "cabeca", p["iris"], ellipse(4.6 + lx * 1.2, -3.2 + ly, 1.9, 1.9, 0, 8), cls="inner"))
    pcs.append(Pc("iris_longe", "cabeca", p["iris"], ellipse(10.8 + lx * 0.6, -4 + ly, 1.1, 1.5, 0, 8), cls="inner"))
    pcs.append(Pc("pupila", "cabeca", INK, ellipse(4.9 + lx * 1.3, -3.2 + ly, 0.9, 0.9, 0, 6), cls="inner"))
    pcs.append(Pc("pupila_longe", "cabeca", INK, ellipse(11 + lx * 0.6, -4 + ly, 0.6, 0.8, 0, 6), cls="inner"))
    if angry:
        pcs.append(Pc("sobrancelha", "cabeca", p["brow"], [(-1, -6.4), (3, -8.6), (8, -7.2), (7.4, -5.6), (3, -6.6), (-0.4, -5)], cls="inner"))
        pcs.append(Pc("sobrancelha_longe", "cabeca", p["brow"], [(8.8, -7.4), (11.6, -9), (12.4, -7.6), (9.6, -6.2)], cls="inner"))
    pcs.append(Pc("nariz", "cabeca", p["skin"], NOSE))
    pcs.append(Pc("narina", "cabeca", INK, [(14.6, 4.4), (16.6, 4.2)], closed=False, cls="inner", sw=0.8))
    if open_:
        mouth = [(0.6, 5.2), (6, 6.4), (12.6, 5.6), (13, 7.8), (10.6, 12.6), (5, 14.6), (0.8, 12)]
        pcs.append(Pc("boca", "cabeca", p["mouth"], mouth, cls="inner"))
        pcs.append(Pc("lingua", "cabeca", "#c8404a", [(3, 12.6), (7, 11), (10.4, 12), (7, 14.2)], cls="inner"))
        for i, x in enumerate((2.4, 5, 7.6, 10.2)):
            pcs.append(Pc(f"dente{i}", "cabeca", p["teeth"], [(x - 1.1, 5.7 + i * 0.1), (x + 1.1, 5.8 + i * 0.1), (x + 0.2, 8.4 - (i % 2))], cls="inner", mode="poly"))
        for i, x in enumerate((3.6, 8.6)):
            pcs.append(Pc(f"dente_b{i}", "cabeca", p["teeth"], [(x - 1, 13.6 - i * 0.6), (x + 1, 13.4 - i * 0.6), (x, 11)], cls="inner", mode="poly"))
    else:
        pcs.append(Pc("boca", "cabeca", INK, [(1, 6), (6, 8), (12, 6.6)], closed=False, cls="inner", sw=1.0))
        pcs.append(Pc("dente0", "cabeca", p["teeth"], [(8, 6.9), (10, 6.8), (9.2, 9.4)], cls="inner", mode="poly"))
    pcs.append(Pc("ruga", "cabeca", INK, [(-6, 4), (-5, 7.5), (-2.5, 9.6)], closed=False, cls="inner", sw=0.6))
    return [q.moved(M) for q in pcs]


def head_front(M, open_=True):
    p = PAL
    EAR = [(-9, -4), (-18, -8), (-30, -16), (-36, -20), (-24, -6), (-14, 2), (-8, 4)]
    EIN = [(-11, -2.5), (-19, -7), (-28, -14), (-19, -3), (-12, 1)]
    pcs = [Pc("orelha_l", "cabeca", p["skin"], EAR), Pc("orelha", "cabeca", p["skin"], [(-x, y) for x, y in EAR]),
           Pc("orelha_l_dentro", "cabeca", p["ear_in"], EIN, cls="inner"),
           Pc("orelha_dentro", "cabeca", p["ear_in"], [(-x, y) for x, y in EIN], cls="inner"),
           Pc("cranio", "cabeca", p["skin_l"], [(-10.6, -1), (-9, -8), (-4, -11.6), (0, -12), (4, -11.6), (9, -8), (10.6, -1),
                                                (10, 6), (6, 11), (0, 12.4), (-6, 11), (-10, 6)])]
    for s in (-1, 1):
        pcs.append(Pc("olho" + ("_l" if s < 0 else ""), "cabeca", p["eye"], ellipse(s * 4.8, -3.4, 3.6, 3.2, -s * 10, 10), cls="inner"))
        pcs.append(Pc("iris" + ("_l" if s < 0 else ""), "cabeca", p["iris"], ellipse(s * 4.4, -3, 1.8, 1.8, 0, 8), cls="inner"))
        pcs.append(Pc("pupila" + ("_l" if s < 0 else ""), "cabeca", INK, ellipse(s * 4.4, -3, 0.8, 0.8, 0, 6), cls="inner"))
        pcs.append(Pc("sobrancelha" + ("_l" if s < 0 else ""), "cabeca", p["brow"], [(s * 1.2, -5.6), (s * 5, -8.4), (s * 9, -7.8), (s * 8.6, -6.2), (s * 5, -6.8), (s * 1.6, -4.4)], cls="inner"))
    pcs.append(Pc("nariz", "cabeca", p["skin"], [(-1.6, -3), (1.6, -3), (3, 4), (2, 6.4), (-2, 6.4), (-3, 4)]))
    if open_:
        pcs.append(Pc("boca", "cabeca", p["mouth"], [(-8, 6), (0, 8), (8, 6), (6, 11), (0, 12.6), (-6, 11)], cls="inner"))
        for i, x in enumerate((-5.6, -2, 2, 5.6)):
            pcs.append(Pc(f"dente{i}", "cabeca", p["teeth"], [(x - 1.1, 6.9), (x + 1.1, 7), (x, 9.4)], cls="inner", mode="poly"))
    return [q.moved(M) for q in pcs]


# ---------------------------------------------------------------- mãos e pés
def hand(name, wrist, fwd_deg, fill, s=1.0, fist=False, spread=34):
    d = np.array([math.cos(math.radians(fwd_deg)), math.sin(math.radians(fwd_deg))]); n = np.array([-d[1], d[0]])
    w = A(wrist); c = w + d * 3.2 * s
    pcs = [Pc(name, "corpo", fill, ellipse(c[0], c[1], 4.2 * s, 3.4 * s, fwd_deg, 9))]
    if fist:
        return pcs
    for k in range(3):
        a = math.radians(fwd_deg + (k - 1) * spread / 2)
        b = c + d * 2.8 * s + n * (k - 1) * 1.8 * s
        tip = b + np.array([math.cos(a), math.sin(a)]) * 5.4 * s
        pcs.append(Pc(f"{name}_dedo{k}", "corpo", fill, brush([b, (b + tip) / 2 + n * 0.4, tip], 2.6 * s, 1.0 * s, per=2)))
        pcs.append(Pc(f"{name}_garra{k}", "corpo", PAL["claw"], brush([tip - (tip - b) * 0.08, tip + (tip - b) * 0.32], 1.2 * s, 0.1, per=2)))
    th = c - n * 3.0 * s + d * 0.5 * s
    tht = th + np.array([math.cos(math.radians(fwd_deg - 60)), math.sin(math.radians(fwd_deg - 60))]) * 4.2 * s
    pcs.append(Pc(f"{name}_polegar", "corpo", fill, brush([th, tht], 2.6 * s, 1.0 * s, per=2)))
    return pcs


def foot(name, ankle, toe, fill):
    a, t = A(ankle), A(toe); d = t - a; L = np.linalg.norm(d); u = d / L; n = np.array([-u[1], u[0]])
    pts = [a - u * 2 - n * 2.6, a + n * 2.8, a + u * L * 0.5 + n * 2.6, t + n * 1.4, t + u * 1.2, t - n * 1.6, a + u * L * 0.4 - n * 2.4]
    pcs = [Pc(name, "corpo", fill, pts)]
    for k in range(3):
        b = t - u * 0.6 + n * (k - 1) * 1.3
        pcs.append(Pc(f"{name}_garra{k}", "corpo", PAL["claw"], brush([b, b + u * 2.6 + n * (k - 1) * 0.7], 1.3, 0.1, per=2)))
    return pcs


def dynamite(M, lit=True, n=3):
    """Feixe de dinamite (origem = mão; bastões ao longo de +x). Retorna peças em goblin_dinamite + pavio/faísca."""
    p = PAL; pcs = []
    offs = [(-3.2, 0), (0.6, -2.2), (0.6, 2.2)][:n]
    for i, (oy, oz) in enumerate(offs):
        pcs.append(Pc(f"bastao{i}", "dinamite", p["tnt"], [(-6 + oz, oy - 1.9), (12 + oz, oy - 1.9), (12 + oz, oy + 1.9), (-6 + oz, oy + 1.9)], mode="poly"))
        pcs.append(Pc(f"ponta{i}", "dinamite", p["tnt_end"], ellipse(12 + oz, oy, 1.1, 1.9, 0, 8), cls="inner"))
    pcs.append(Pc("amarra", "dinamite", p["fuse"], [(1, -5.4), (3, -5.4), (3, 4.4), (1, 4.4)], mode="poly", cls="inner"))
    pcs.append(Pc("pavio", "dinamite", INK, [(12.6, -3.2), (15, -6), (17.6, -6.4), (19.4, -8.6)], closed=False, cls="inner", sw=0.8))
    return [q.moved(M) for q in pcs], ap(M, [(19.4, -8.6)])[0]


# ---------------------------------------------------------------- corpo
def goblin(J):
    p = PAL; pcs = []
    hip, nk = A(J["hip"]), A(J["neck"])
    up = (nk - hip) / np.linalg.norm(nk - hip); side = np.array([-up[1], up[0]])  # side: para trás (−x) quando de pé
    fwd = -side
    # membros do lado de longe (escuros), atrás do tronco
    def leg(tag, fill):
        hp = hip + fwd * (1.5 if tag == "n" else -1.5)
        kn, an = ik(hp, J["a" + tag], L_TH, L_SH, J.get("kb" + tag, -1))
        out = [Pc("perna_" + tag, "corpo", fill, tube([hp, kn, an], [4.4, 3.0, 2.2], cap0=0.4, cap1=0.4, per=4))]
        out.append(Pc("joelho_" + tag, "corpo", fill, ellipse(kn[0], kn[1], 3.0, 2.8, 0, 8)))
        out += foot("pe_" + tag, an, J["t" + tag], fill)
        return out

    def arm(tag, fill):
        sh = nk - up * 2.5 + fwd * (2.5 if tag == "n" else -2.5)
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        out = [Pc("braco_" + tag, "corpo", fill, tube([sh, el, wr], [3.2, 2.4, 2.0], cap0=0.5, cap1=0.3, per=4))]
        out += hand("mao_" + tag, wr, J.get("hd" + tag, math.degrees(math.atan2(*(wr - el)[::-1]))), fill, J.get("hs", 1.0),
                    fist=J.get("fist" + tag, False), spread=J.get("sp" + tag, 34))
        return out, sh, el, wr

    pcs += leg("f", p["skin_d"])
    farm, fsh, fel, fwr = arm("f", p["skin_d"])
    pcs += farm
    # tronco: barriga redonda para a frente, ombros estreitos
    belly = hip + up * 9 + fwd * 6.5
    pcs.append(Pc("tronco", "corpo", p["skin"], [hip - fwd * 6 - up * 1, hip + fwd * 5 - up * 1.5, belly + up * -2, belly + up * 4,
                                               nk + fwd * 4.5 - up * 1, nk + up * 1.5, nk - fwd * 5 - up * 1, hip - fwd * 7.5 + up * 9]))
    # túnica de couro (sem mangas), barra recortada
    pcs.append(Pc("tunica", "corpo", p["tunic"], [nk - fwd * 4.8 - up * 2, nk + fwd * 4.2 - up * 2.5, belly + up * 3.6 - fwd * 0.4,
                                                belly - up * 2.4 + fwd * 0.4, hip + fwd * 6 - up * 4, hip + fwd * 2 - up * 7,
                                                hip - fwd * 1 - up * 4.5, hip - fwd * 4 - up * 7.5, hip - fwd * 7.6 - up * 3.6,
                                                hip - fwd * 7.8 + up * 9]))
    pcs.append(Pc("cinto", "corpo", p["belt"], [hip - fwd * 7.6 + up * 0.6, hip + fwd * 6.4 + up * 0.2, hip + fwd * 6.2 - up * 2.2,
                                              hip - fwd * 7.6 - up * 1.8], mode="poly", cls="inner"))
    b0 = nk - fwd * 4 - up * 2; b1 = hip + fwd * 5.6 + up * 1
    pcs.append(Pc("bandoleira", "corpo", p["band"], brush([b0, (b0 + b1) / 2 + side * 1.2, b1], 3.6, 3.2), cls="inner"))
    for i in range(3):
        q = b0 + (b1 - b0) * (0.28 + i * 0.22)
        pcs.append(Pc(f"band_bastao{i}", "corpo", p["tnt"], list(ap(chain(T(*q), R(math.degrees(math.atan2(*(b1 - b0)[::-1])) + 90)),
                                                                  [(-1.2, -3), (1.2, -3), (1.2, 3), (-1.2, 3)])), mode="poly", cls="inner"))
    pcs.append(Pc("costura", "corpo", INK, [nk + fwd * 1 - up * 4, belly + up * 1.5 - fwd * 2.5, hip + fwd * 2 - up * 2.5], closed=False, cls="inner", sw=0.5))
    pcs += leg("n", p["skin"])
    # props seguros pela mão de longe ficam atrás do tronco; pela de perto, na frente
    narm, nsh, nel, nwr = arm("n", p["skin"])
    props_f, props_n = J.get("props_f"), J.get("props_n")
    if props_f:
        pcs[0:0] = props_f(fwr, fel)
    if props_n:
        pcs += props_n(nwr, nel)
    pcs += narm
    hx, hy, ha = J["head"]
    pcs += head(tmat(hx, hy, ha, J.get("hk", 1.0)), J.get("open", True), True, J.get("look", (1, 0)))
    return pcs


def _tnt(on="n", ang=None, n=3):
    def f(wr, el):
        d = A(wr) - A(el); a = math.degrees(math.atan2(d[1], d[0])) if ang is None else ang
        pcs, tip = dynamite(chain(T(*(A(wr) + d / np.linalg.norm(d) * 3)), R(a + 90)), n=n)
        f.tip = tip
        return pcs
    f.tip = None
    return f


POSES = {
    # corrida de sprint: tronco 30° à frente, joelho de perto alto, dinamite acesa erguida na mão de perto
    "correr": dict(hip=(0, -28), neck=(10, -46), head=(17, -58, 8), ab=(0, 0), an=(14, -10), tn=(23, -9), kbn=-1,
                   af=(-16, -6), tf=(-23, -1), kbf=-1, wn=(-15, -40), ebn=1, hdn=-150, wf=(26, -44), ebf=-1, hdf=-10, spf=46,
                   props_n=_tnt("n", ang=-128)),
    # arremesso: corpo torcido para trás, braço de perto atrás e alto com a dinamite, braço de longe apontando
    "arremessar": dict(hip=(0, -26), neck=(-5, -45), head=(1, -58, -10), an=(15, -1), tn=(22, 0), kbn=-1, af=(-15, 0),
                       tf=(-21, 0), kbf=-1, wn=(-27, -50), ebn=1, hdn=200, wf=(20, -50), ebf=-1, hdf=-10, spf=50,
                       props_n=_tnt("n", ang=-120)),
    # salto: no ar, pernas encolhidas, braços para cima (pose do artGoblin da v2)
    "saltar": dict(hip=(0, -40), neck=(8, -58), head=(16, -70, 12), an=(10, -36), tn=(18, -35), kbn=-1, af=(-12, -30),
                   tf=(-19, -26), kbf=-1, wn=(22, -78), ebn=-1, hdn=-60, wf=(-12, -82), ebf=1, hdf=-110, spf=50, spn=50,
                   props_n=_tnt("n", ang=-115)),
    # ameaça: agachado, pernas abertas, mãos abertas em garra, cabeça para a frente, sorriso de dentes
    "ameaca": dict(hip=(0, -20), neck=(9, -36), head=(18, -46, 14), an=(14, 0), tn=(22, 0), kbn=-1, af=(-12, 0), tf=(-18, 0),
                   kbf=-1, wn=(26, -30), ebn=-1, hdn=-30, spn=56, wf=(-2, -26), ebf=1, hdf=-20, spf=56),
}
GUIDE = {"correr": [(-23, -1), (-4, -22), (10, -46), (20, -62), (24, -76)],
         "arremessar": [(22, 0), (4, -24), (-6, -46), (-18, -60), (-30, -66)],
         "saltar": [(-19, -26), (0, -40), (12, -62), (16, -84), (12, -96)],
         "ameaca": [(-18, 0), (-4, -16), (10, -34), (22, -46), (32, -50)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return goblin(J)


def fuse_tip(name):
    """Ponta do pavio (faísca) da dinamite numa pose — em coordenadas da ficha."""
    J = POSES[name]
    goblin(J)
    return J["props_n"].tip
