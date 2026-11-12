"""Ficha do Cultista (lote lich_2): humano encapuzado de manto longo, rosto em sombra com olhos acesos, mangas de sino,
mãos pálidas e ossudas. Duas variações de cor/máscara: 'cultista' (manto vinho, faixa dourada, olhos violeta) e
'acolito' (manto creme de noviço, estola violeta, meia-máscara de osso). Perfil 3/4 olhando para +x, chão em y=0.
Unidade: cabeça = 20 u. Altura ≈ 7,5 cabeças (150 u com o capuz); ombro a 6; quadril a 3,8; coxa 1,9 / canela 1,8;
braço 1,5 / antebraço 1,3. Braços e pernas por IK de dois ossos (praga_3/piper.ik, só leitura).
O manto é calculado das juntas: frente pelo joelho da frente, costas pelo joelho de trás, barra a ~7 u acima dos tornozelos
(as botas aparecem). data-fig: cultista_corpo (manto, capa curta, mangas, mãos, pernas, botas = 1),
cultista_cabeca (capuz + rosto = 1). Rosto vazio, olhos, máscara, dobras, faixa, bordado, boca da manga = inner."""
import base  # noqa: F401
import math
import numpy as np
from geom import *
from piper import ik, hand, shoe

INK = "#2b1a10"
PALS = {
    "cultista": dict(robe="#7a2030", robe_d="#521624", cape="#64192a", trim="#c8a040", sash="#c8a040", skin="#b8aab4",
                     skin_d="#8e8094", void="#140c18", eye="#d890ff", leg="#2a1a22", boot="#2a1c1c", mask=None, fold="#3a0e18"),
    "acolito": dict(robe="#d2c6a8", robe_d="#a89a7c", cape="#bcae90", trim="#6a3a9a", sash="#6a3a9a", skin="#c8b8a8",
                    skin_d="#9a8a7c", void="#16101c", eye="#b070ff", leg="#4a4038", boot="#3a2e26", mask="#ece2c8", fold="#7a6c50"),
}
L_TH, L_SH, L_UA, L_FA = 38, 36, 30, 26

# capuz em perfil 3/4 (centro do crânio em 0,0; +x = frente); ponta caída para trás
HOOD = [(11, -7), (5, -13.5), (-3, -16), (-9, -19), (-14, -22), (-12, -13), (-15, -4), (-15, 6), (-12, 13), (-4, 16.5),
        (6, 15.5), (12, 10.5), (14.5, 2)]
VOID = [(13, -6.5), (8.5, -8.5), (5, -4), (4.5, 3), (6.5, 9.5), (11.5, 10), (13.5, 3)]
MASK = [(5.5, -5), (12.8, -5.6), (13.4, 1.5), (11.4, 6.5), (8, 7.2), (5.6, 3.5)]


def head(M, var="cultista", glow=True):
    p = PALS[var]; pcs = []
    pcs.append(Pc("capuz", "cabeca", p["robe"], HOOD))
    pcs.append(Pc("capuz_dobra", "cabeca", p["fold"], [(-3, -13), (-8, -2), (-6, 10)], closed=False, cls="inner", sw=0.9))
    pcs.append(Pc("capuz_borda", "cabeca", p["trim"], [(11, -7), (5.5, -10), (3, -3), (3.5, 6), (6, 13.5)], closed=False, cls="inner", sw=1.6))
    pcs.append(Pc("rosto", "cabeca", p["void"], VOID, cls="inner"))
    if p["mask"]:
        pcs.append(Pc("mascara", "cabeca", p["mask"], MASK, cls="inner"))
        pcs.append(Pc("mascara_olho", "cabeca", p["void"], ellipse(10.6, -1.8, 2.0, 1.3, -8, 6), cls="inner"))
    if glow:
        pcs.append(Pc("olho", "cabeca", p["eye"], ellipse(10.8, -1.8, 1.6, 0.9, -8, 6), cls="inner"))
        pcs.append(Pc("olho_l", "cabeca", p["eye"], ellipse(6.9, -1.4, 1.0, 0.8, -8, 6), cls="inner"))
    return [q.moved(M) for q in pcs]


def head_front(M, var="cultista"):
    p = PALS[var]
    pcs = [Pc("capuz", "cabeca", p["robe"], [(-13, 11), (-15, -1), (-11, -12), (-4, -18), (2, -22), (6, -16), (11, -12), (15, -1), (13, 11), (6, 16), (-6, 16)]),
           Pc("capuz_borda", "cabeca", p["trim"], [(-9, 12), (-10, -2), (-6, -10), (0, -12.5), (6, -10), (10, -2), (9, 12)], closed=False, cls="inner", sw=1.6),
           Pc("rosto", "cabeca", p["void"], [(-8, 10), (-9, -2), (-5, -9), (0, -11), (5, -9), (9, -2), (8, 10), (0, 13)], cls="inner")]
    if p["mask"]:
        pcs.append(Pc("mascara", "cabeca", p["mask"], [(-7.5, -4), (7.5, -4), (7, 3), (3, 7), (-3, 7), (-7, 3)], cls="inner"))
        pcs += [Pc("mascara_olho_l", "cabeca", p["void"], ellipse(-3.4, -1, 2.2, 1.4, 6, 6), cls="inner"),
                Pc("mascara_olho", "cabeca", p["void"], ellipse(3.4, -1, 2.2, 1.4, -6, 6), cls="inner")]
    pcs += [Pc("olho_l", "cabeca", p["eye"], ellipse(-3.4, -1, 1.5, 0.9, 6, 6), cls="inner"),
            Pc("olho", "cabeca", p["eye"], ellipse(3.4, -1, 1.5, 0.9, -6, 6), cls="inner")]
    return [q.moved(M) for q in pcs]


def sleeve(name, sh, el, wr, fill, fill_in, w=(5.2, 5.0, 6.2), flare=8.5):
    """Manga de sino: tubo do ombro ao punho + boca larga passando do punho (a mão sai de dentro)."""
    sh, el, wr = A(sh), A(el), A(wr)
    d = (wr - el) / (np.linalg.norm(wr - el) + 1e-9); n = np.array([-d[1], d[0]])
    pcs = [Pc(name, "corpo", fill, tube([sh, el, wr], list(w), cap0=0.5, cap1=0.0, per=4)),
           Pc(name + "_boca", "corpo", fill, [wr - n * w[2] - d * 2, wr + d * 5 - n * flare, wr + d * 6.5 + n * flare, wr + n * w[2] - d * 2], mode="cr"),
           Pc(name + "_dentro", "corpo", fill_in, ellipse(*(wr + d * 5.6), flare * 0.85, 2.2, math.degrees(math.atan2(n[1], n[0])), 8), cls="inner")]
    return pcs, wr + d * 6


def wave(p0, p1, n, amp, down):
    p0, p1 = A(p0), A(p1); out = []
    for i in range(1, n):
        t = i / n; q = p0 + (p1 - p0) * t
        out.append(q + A(down) * amp * (1 if i % 2 else 0.35))
    return out


def cultist(J, var="cultista"):
    p = PALS[var]; pcs = []
    hc = A(J["hip"]); nk = A(J["neck"])
    up = (nk - hc) / np.linalg.norm(nk - hc); fwd = np.array([-up[1], up[0]]) * -1
    if fwd[0] < 0:
        fwd = -fwd
    hunch = J.get("hunch", 3)
    legs = {}
    for s in ("f", "n"):
        hip = hc + fwd * (2 if s == "n" else -2)
        if "kp_" + s in J:  # joelho dado (ajoelhado: coxa e canela no chão não cabem no IK)
            knee, ank = A(J["kp_" + s]), A(J["ank_" + s])
        else:
            knee, ank = ik(hip, J["ank_" + s], L_TH, L_SH, J.get("knee_" + s, -1))
        legs[s] = (hip, knee, ank)
    for s, nm, col in (("f", "perna_l", p["leg"]), ("n", "perna", p["leg"])):
        h_, k_, a_ = legs[s]
        pcs.append(Pc(nm, "corpo", col, tube([h_, k_, a_], [5, 3.8, 2.8], cap0=0.4, cap1=0.4, per=4)))
        pcs.append(shoe(("bota_l" if s == "f" else "bota"), a_, J["toe_" + s], p["boot"]))
    # braço de longe (atrás do manto)
    arms = {}
    for s in ("f", "n"):
        el, wr = ik(J["sh_" + s], J["wr_" + s], L_UA, L_FA, J.get("elb_" + s, 1))
        arms[s] = (A(J["sh_" + s]), el, wr)
    sf, ef, wf = arms["f"]
    pc, hand_f = sleeve("manga_l", sf, ef, wf, p["robe_d"], p["void"])
    pcs += pc
    # manto: frente pelo joelho da frente, costas pelo joelho de trás; barra acima dos tornozelos
    kf = legs["n"][1] if np.dot(legs["n"][1] - hc, fwd) >= np.dot(legs["f"][1] - hc, fwd) else legs["f"][1]
    kb = legs["f"][1] if kf is legs["n"][1] else legs["n"][1]
    af = legs["n"][2] if kf is legs["n"][1] else legs["f"][2]
    ab = legs["f"][2] if kf is legs["n"][1] else legs["n"][2]
    flow = A(J.get("flow", (0, 0)))
    hemF = A(J["hemF"]) if "hemF" in J else af + up * 7 + fwd * 7 + flow * 0.6
    hemB = A(J["hemB"]) if "hemB" in J else ab + up * 7 - fwd * 9 + flow
    chest = nk * 0.62 + hc * 0.38 + fwd * (9 + hunch)
    back = nk * 0.5 + hc * 0.5 - fwd * (10 - hunch * 0.4)
    down = -up
    robe = [nk + fwd * 4 + up * 1, chest, hc + fwd * 9, kf + fwd * 5.5, hemF]
    robe += wave(hemF, hemB, 6, 2.6, down)
    robe += [hemB, kb - fwd * 6 + flow * 0.4, hc - fwd * 11, back, nk - fwd * 6 + up * 1]
    pcs.append(Pc("manto", "corpo", p["robe"], robe))
    # dobras do manto (do quadril à barra) e faixa
    for k, t in enumerate((0.3, 0.62)):
        top = hc + fwd * (-6 + 12 * t)
        bot = hemB + (hemF - hemB) * t
        pcs.append(Pc(f"dobra{k}", "corpo", p["fold"], [top, top * 0.5 + bot * 0.5 + fwd * 1.5, bot + up * 3], closed=False, cls="inner", sw=0.9))
    pcs.append(Pc("faixa", "corpo", p["sash"], [hc + up * 7 - fwd * 10, hc + up * 7 + fwd * 9.5, hc + up * 3 + fwd * 9.5, hc + up * 3 - fwd * 10.5], mode="poly", cls="inner"))
    pcs.append(Pc("faixa_ponta", "corpo", p["sash"], [hc + up * 4 + fwd * 7, hc - up * 18 + fwd * 9 + flow * 0.3, hc - up * 18 + fwd * 4 + flow * 0.3, hc + up * 4 + fwd * 3], mode="poly", cls="inner"))
    pcs.append(Pc("barra", "corpo", p["trim"], [hemF + up * 2.5] + wave(hemF + up * 2.5, hemB + up * 2.5, 6, 2.6, down) + [hemB + up * 2.5], closed=False, cls="inner", sw=1.4))
    # capa curta (sobre os ombros, presa ao capuz)
    pcs.append(Pc("capa_curta", "corpo", p["cape"], [nk + fwd * 6 + up * 3, nk + fwd * 10 - up * 8, nk + fwd * 4 - up * 15, nk - fwd * 6 - up * 17,
                                                   nk - fwd * 12 - up * 10, nk - fwd * 9 + up * 2]))
    # braço de perto + mãos
    sn, en, wn = arms["n"]
    pc, hand_n = sleeve("manga", sn, en, wn, p["robe"], p["void"], w=(5.6, 5.4, 6.6), flare=9)
    pcs += pc
    hf = J.get("hands", {})
    af_, cf, spf = hf.get("f", (math.degrees(math.atan2(*(wf - ef)[::-1])), 0.4, 50))
    an_, cn, spn = hf.get("n", (math.degrees(math.atan2(*(wn - en)[::-1])), 0.4, 50))
    pcs += hand("mao_l", hand_f, af_, p["skin_d"], cf, spf)
    pcs += hand("mao", hand_n, an_, p["skin"], cn, spn)
    hx, hy, ha = J["head"]
    pcs += head(tmat(hx, hy, ha, 1.0), var, J.get("glow", True))
    return pcs


def pontos(J):
    """Pontos úteis da pose (para encostar efeitos): mãos e cabeça, em coordenadas da pose."""
    out = {}
    for s in ("f", "n"):
        el, wr = ik(J["sh_" + s], J["wr_" + s], L_UA, L_FA, J.get("elb_" + s, 1))
        d = (wr - el) / np.linalg.norm(wr - el)
        out["mao_" + s] = wr + d * 11
    out["cabeca"] = A(J["head"][:2])
    return out


POSES = {
    # ritual: de pé, braços erguidos em V, cabeça jogada para trás, costas arqueadas (linha em C)
    "ritual": dict(hip=(0, -76), neck=(-5, -122), hunch=-2, head=(-8, -135, -32),
                   sh_f=(-10, -117), sh_n=(-1, -117), wr_f=(-34, -168), wr_n=(26, -170), elb_f=-1, elb_n=1,
                   hands=dict(f=(-110, 0.15, 70), n=(-60, 0.15, 70)),
                   ank_f=(-20, -4), toe_f=(-8, 0), ank_n=(20, -4), toe_n=(32, 0), knee_f=-1, knee_n=-1, flow=(-6, 0)),
    # disparar: estocada, braço de perto esticado lançando o raio, braço de longe puxado para trás, tronco 28° à frente
    "disparar": dict(hip=(0, -64), neck=(24, -108), hunch=4, head=(33, -119, 6),
                     sh_f=(17, -104), sh_n=(25, -104), wr_n=(66, -110), wr_f=(-16, -88), elb_f=1, elb_n=1,
                     hands=dict(n=(-8, 0.0, 80), f=(200, 0.6, 40)),
                     ank_n=(42, -4), toe_n=(54, 0), ank_f=(-46, -4), toe_f=(-38, 0), knee_n=-1, knee_f=-1, flow=(-14, -2)),
    # cantar ajoelhado: ajoelhado, mãos juntas diante do peito, cabeça baixa
    "ajoelhado": dict(hip=(-8, -40), neck=(6, -86), hunch=7, head=(13, -97, 28),
                      sh_f=(0, -82), sh_n=(8, -82), wr_f=(24, -66), wr_n=(26, -68), elb_f=1, elb_n=1,
                      hands=dict(f=(-70, 0.5, 30), n=(-80, 0.5, 30)),
                      kp_n=(24, -6), ank_n=(-10, -3), toe_n=(-22, 0), kp_f=(16, -5), ank_f=(-18, -3), toe_f=(-30, 0),
                      hemF=(34, -1), hemB=(-34, -1)),
    # ler: de pé, levemente curvado, mão de perto sob o grimório flutuante, mão de longe erguida comandando os livros
    "ler": dict(hip=(0, -76), neck=(6, -122), hunch=6, head=(14, -132, 22),
                sh_f=(0, -118), sh_n=(8, -118), wr_n=(36, -94), wr_f=(-10, -156), elb_f=-1, elb_n=1,
                hands=dict(n=(-20, 0.1, 70), f=(-95, 0.1, 80)),
                ank_f=(-14, -4), toe_f=(-2, 0), ank_n=(16, -4), toe_n=(28, 0), knee_f=-1, knee_n=-1, flow=(-4, 0)),
    # orbe: passo à frente, as duas mãos em concha diante do peito segurando a esfera de sombra (prestes a soltar)
    "orbe": dict(hip=(0, -74), neck=(12, -119), hunch=5, head=(20, -130, 12),
                 sh_f=(6, -115), sh_n=(14, -115), wr_f=(36, -92), wr_n=(40, -82), elb_f=1, elb_n=1,
                 hands=dict(f=(-30, 0.55, 60), n=(30, 0.55, 60)),
                 ank_f=(-22, -4), toe_f=(-10, 0), ank_n=(26, -4), toe_n=(38, 0), knee_f=-1, knee_n=-1, flow=(-8, 0)),
}
GUIDE = {"ritual": [(-14, 0), (-2, -50), (0, -100), (-8, -136), (-24, -160)],
         "disparar": [(-42, -2), (-10, -40), (14, -86), (34, -120), (70, -112)],
         "ajoelhado": [(-30, 0), (-8, -40), (6, -86), (18, -104)],
         "orbe": [(-18, 0), (0, -50), (12, -100), (22, -130)],
         "ler": [(-8, 0), (0, -50), (6, -100), (16, -132), (36, -100)]}


def pose(name, var="cultista", **over):
    J = dict(POSES[name]); J.update(over)
    return cultist(J, var)


def book(M, open_=True, cover="#3a2a4a", page="#efe4c8", glow="#b070ff"):
    """Grimório aberto (centro da lombada em 0,0, páginas abertas para cima). data-fig: livro."""
    pcs = [Pc("capa", "livro", cover, [(-17, 1), (-15, -9), (0, -6), (15, -9), (17, 1), (0, 4)], mode="poly"),
           Pc("pagina_l", "livro", page, [(-15, -1.5), (-13, -10), (-6, -11), (0, -8), (0, 1), (-7, -2)]),
           Pc("pagina_r", "livro", page, [(15, -1.5), (13, -10), (6, -11), (0, -8), (0, 1), (7, -2)]),
           Pc("runa_l", "livro", glow, [(-11, -6), (-8, -8), (-5, -5), (-3, -7)], closed=False, cls="inner", sw=0.9),
           Pc("runa_r", "livro", glow, [(4, -6), (7, -8.5), (10, -6), (12, -7.5)], closed=False, cls="inner", sw=0.9),
           Pc("lombada", "livro", INK, [(0, -8), (0, 1)], closed=False, cls="inner", sw=0.7)]
    return [q.moved(M) for q in pcs]


def closed_book(M, cover="#5a2a3a", page="#e6d8b4", fig="livro"):
    """Livro fechado voando, capa aberta como asa (centro em 0,0, lombada para a esquerda)."""
    pcs = [Pc("capa", fig, cover, [(-9, -6), (9, -7), (10, 6), (-8, 7)], mode="poly"),
           Pc("folhas", fig, page, [(-7, -4.5), (8.5, -5.5), (8.5, 5), (-6.5, 5.5)], mode="poly", cls="inner"),
           Pc("aba", fig, cover, [(-9, -6), (-16, -15), (2, -14), (9, -7)], mode="poly")]
    return [q.moved(M) for q in pcs]
