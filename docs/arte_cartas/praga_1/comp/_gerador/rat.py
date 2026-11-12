"""Ficha do rato: modelo de perfil (espinha + cabeça + membros), poses e variações por proporção."""
import math
import numpy as np
from geom import *

PAL = {
    "comum": dict(fur="#8b8580", far="#6c6661", belly="#cfc4b6", ear="#c4928a", ear_in="#e8aaa0", tail="#c9988e",
                  eye="#ff4a1e", nose="#d4707a", teeth="#f2e6c4", mouth="#4a1414", claw="#f2e6c4", k=1.0, hk=1.0),
    "gorda": dict(fur="#7a6f66", far="#5e554e", belly="#c2b29c", ear="#b8867c", ear_in="#e0a094", tail="#bf8e84",
                  eye="#ffb02a", nose="#cc6a72", teeth="#efe0b8", mouth="#3e1a12", claw="#efe0b8", k=1.5, hk=1.12),
    "raivoso": dict(fur="#7d7873", far="#5d5853", belly="#bdb3a6", ear="#c08078", ear_in="#e2948a", tail="#c08a82",
                    eye="#ff2a1a", nose="#d05a64", teeth="#f4ecd0", mouth="#5a0f12", claw="#f4ecd0", k=0.86, hk=1.0),
    "rei": dict(fur="#8a8784", far="#6a6765", belly="#e8e0cc", ear="#b88a84", ear_in="#e0a092", tail="#c09088",
                eye="#ffd23c", nose="#d07a80", teeth="#f2e6c4", mouth="#4a1414", claw="#f2e6c4", k=1.15, hk=1.15),
}

# ---------------------------------------------------------------- cabeça de perfil (origem = pescoço, focinho em +x)
H_CLOSED = [(-4, -6), (2, -12), (10, -15), (18, -13), (25, -9), (31, -5), (35, -2.5), (36.5, 0), (34.5, 2.2),
            (29, 3.2), (22, 5), (14, 8), (6, 9), (-2, 6)]
H_UP = [(-4, -6), (2, -12), (10, -15), (18, -13), (25, -9), (31, -5), (35, -2.5), (36.5, 0), (34.8, 2), (30, 2.4),
        (22, 2.8), (14, 4.5), (6, 9), (-2, 6)]
JAW = [(8, 3), (16, 3.6), (24, 3.4), (31, 3.2), (32.5, 5), (28, 7.5), (20, 9), (12, 9.5), (5, 8.5)]
EAR = [(5, -11), (1, -19), (3, -27), (9, -31), (16, -28), (18, -20), (14, -12)]
EAR_IN = [(7, -14), (5, -20), (6.5, -26), (10, -28), (14, -25), (14.5, -18), (12, -14)]
EAR_FAR = [(-1, -11), (-6, -18), (-6, -26), (-1, -29), (5, -26), (7, -18), (5, -12)]
EYE = [(14, -7.5), (17, -9.6), (20.6, -7.7), (17, -6.1)]
NOSE = [(34, -3.2), (36.9, -1.3), (36.7, 1), (34, 1)]


def head_side(pal, M, open_=0.0, var="comum", crown=False):
    pcs = []
    ear_far = EAR_FAR if not crown else [(x - 5, y + 1) for x, y in EAR_FAR]
    ear = EAR if not crown else [(x - 5, y + 1) for x, y in EAR]
    ear_in = EAR_IN if not crown else [(x - 5, y + 1) for x, y in EAR_IN]
    pcs.append(Pc("orelha_l", "cabeca", pal["far"], ear_far))
    if open_ > 0:
        hinge = A((9, 3.5))
        Mj = chain(T(*hinge), R(open_), T(*(-hinge)))
        jaw = list(ap(Mj, JAW))
        pcs.append(Pc("mandibula", "cabeca", pal["fur"], jaw))
        pcs.append(Pc("cabeca", "cabeca", pal["fur"], H_UP))
        jtop = list(ap(Mj, [(31, 3.2), (24, 3.4), (16, 3.6), (8, 3)]))
        mouth = [(31.5, 2.4), (22, 2.8), (13, 4.6)] + jtop[::-1][:1] + jtop[::-1][1:][::-1]
        mouth = [(31.5, 2.4), (22, 2.8), (13, 4.6), (9, 4)] + jtop[2:0:-1] + [jtop[0]]
        pcs.append(Pc("boca", "cabeca", pal["mouth"], mouth, cls="inner"))
        pcs.append(Pc("dente_cima", "cabeca", pal["teeth"], [(30.6, 2), (32.6, 2), (32.3, 8.2), (30.9, 7.6)], cls="inner", mode="poly"))
        lt = list(ap(Mj, [(29.6, 3.4), (31.4, 3.4), (31, -1.6), (29.8, -1.2)]))
        pcs.append(Pc("dente_baixo", "cabeca", pal["teeth"], lt, cls="inner", mode="poly"))
    else:
        pcs.append(Pc("cabeca", "cabeca", pal["fur"], H_CLOSED))
        pcs.append(Pc("dente_cima", "cabeca", pal["teeth"], [(31.6, 2.6), (33.2, 2.6), (33, 6), (31.8, 5.8)], cls="inner", mode="poly"))
        pcs.append(Pc("boca", "cabeca", "#2b1a10", [(29, 3.4), (24, 4), (20, 5.6)], closed=False, cls="inner", sw=0.9))
    pcs.append(Pc("orelha", "cabeca", pal["ear"], ear))
    pcs.append(Pc("orelha_dentro", "cabeca", pal["ear_in"], ear_in, cls="inner"))
    pcs.append(Pc("olho", "cabeca", pal["eye"], EYE, cls="inner"))
    pcs.append(Pc("nariz", "cabeca", pal["nose"], NOSE, cls="inner"))
    if var == "raivoso" or open_ > 0:
        pcs.append(Pc("sobrancelha", "cabeca", "#2b1a10", [(12, -10.5), (17, -10.8), (22, -8.6)], closed=False, cls="inner", sw=1.4))
    for i, (ex, ey) in enumerate([(50, -7), (51, 0), (48, 7)]):
        pcs.append(Pc(f"bigode_{i}", "cabeca", "#2b1a10", [(32, -0.5 + i), (41, (ey - 0.5 + i) / 2), (ex, ey)], closed=False, cls="inner", sw=0.6))
    return [p.moved(M) for p in pcs]


def leg(name, joints, widths, fill, pal, claws=False, paw=True):
    pcs = [Pc(name, "corpo", fill, tube(joints, [w / 2 for w in widths], cap0=0.4, cap1=0.6, per=4))]
    a, b = A(joints[-2]), A(joints[-1])
    d = (b - a) / (np.linalg.norm(b - a) + 1e-9)
    if paw:
        c = b + d * 1.5
        ang = math.degrees(math.atan2(d[1], d[0]))
        pcs.append(Pc(name + "_mao", "corpo", fill, ellipse(c[0], c[1], widths[-1] * 0.9, widths[-1] * 0.55, ang, 8)))
        nrm = np.array([-d[1], d[0]])
        for k, s in enumerate((-1, 0, 1)):
            base = c + d * widths[-1] * 0.6 + nrm * s * widths[-1] * 0.4
            if claws:
                tip = base + d * 5 + nrm * s * 1.5 - np.array([0, 1.0])
                pcs.append(Pc(f"{name}_garra{k}", "corpo", pal["claw"], brush([base, (base + tip) / 2 + nrm * 0.8, tip], 1.8, 0.2, per=2)))
            else:
                pcs.append(Pc(f"{name}_dedo{k}", "corpo", "#2b1a10", [base - d * 2, base], closed=False, cls="inner", sw=0.6))
    return pcs


def rat_side(P, var="comum"):
    pal = PAL[var]; k = pal["k"]
    pcs = [Pc("cauda", "corpo", pal["tail"], brush(P["tail"], 7 * min(k, 1.3), 0.8))]
    for L in P["legs"]:
        if not L[3]:
            pcs += leg(L[0], L[1], [w * min(k, 1.35) for w in L[2]], pal["far"], pal, claws=L[4])
    wa = [w * k for w in P["wa"]]; wb = [w * k for w in P["wb"]]
    pcs.append(Pc("tronco", "corpo", pal["fur"], tube(P["spine"], wa, wb, cap0=0.9, cap1=0.5,
                                                    jag=2.2 if var == "raivoso" else 0)))
    sp = P["spine"]
    pcs.append(Pc("barriga", "corpo", pal["belly"], tube(sp[1:], [-w * 0.15 for w in wb[1:]], [w * 0.92 for w in wb[1:]], cap0=0.5, cap1=0.3)))
    if var == "raivoso":
        for i in range(3):
            t = 0.35 + i * 0.12
            c = cr_sample(sp, 8)[int(len(cr_sample(sp, 8)) * t)]
            pcs.append(Pc(f"costela{i}", "corpo", "#2b1a10", [c + (-3, -2), c + (0, 4), c + (2, 8)], closed=False, cls="inner", sw=0.7))
    for L in P["legs"]:
        if L[3]:
            pcs += leg(L[0], L[1], [w * min(k, 1.35) for w in L[2]], pal["fur"], pal, claws=L[4])
    hx, hy, ha, hs, op = P["head"]
    pcs += head_side(pal, tmat(hx, hy, ha, hs * pal["hk"]), op, var)
    return pcs


# ---------------------------------------------------------------- poses de perfil (olhando para +x, chão em y=0)
FRONT_W = [5, 4, 3.2, 2.6]
HIND_W = [10, 6, 3.4, 2.6]
POSES = {
    "correr": dict(
        spine=[(0, -24), (18, -30), (38, -31), (56, -28), (68, -25)], wa=[8, 10, 11, 10, 7], wb=[9, 11, 11, 9, 6],
        head=(64, -28, 6, 1.0, 0), tail=[(-4, -23), (-22, -27), (-46, -20), (-70, -26), (-92, -18)],
        legs=[("pata_frente_l", [(54, -22), (64, -10), (76, -3), (82, 0)], FRONT_W, False, False),
              ("pata_tras_l", [(12, -20), (2, -9), (-8, -3), (-18, -1)], HIND_W, False, False),
              ("pata_tras", [(8, -22), (-4, -14), (-16, -8), (-27, -8)], HIND_W, True, False),
              ("pata_frente", [(58, -24), (70, -16), (84, -12), (93, -11)], FRONT_W, True, False)]),
    "atacar": dict(
        spine=[(0, -26), (16, -34), (34, -33), (50, -27), (61, -21)], wa=[8, 10, 11, 10, 7], wb=[9, 11, 11, 9, 6],
        head=(58, -24, 16, 1.05, 32), tail=[(-3, -24), (-20, -34), (-40, -30), (-58, -41), (-74, -35)],
        legs=[("pata_frente_l", [(50, -20), (58, -8), (70, -8), (79, -11)], FRONT_W, False, True),
              ("pata_tras_l", [(12, -18), (26, -8), (13, -2), (27, 0)], HIND_W, False, False),
              ("pata_tras", [(8, -20), (22, -10), (6, -3), (20, 0)], HIND_W, True, False),
              ("pata_frente", [(54, -22), (64, -16), (77, -18), (86, -24)], FRONT_W, True, True)]),
    "ameaca": dict(
        spine=[(0, -16), (4, -34), (12, -50), (22, -62), (31, -70)], wa=[13, 13, 12, 10, 7], wb=[12, 12, 11, 9, 6],
        head=(29, -73, -24, 1.0, 34), tail=[(-6, -10), (-24, -4), (-42, -11), (-58, -3), (-70, -8)],
        legs=[("pata_frente_l", [(25, -58), (35, -46), (45, -51), (51, -58)], FRONT_W, False, True),
              ("pata_tras_l", [(0, -12), (10, -6), (-4, -2), (10, 0)], HIND_W, False, False),
              ("pata_tras", [(6, -14), (18, -10), (6, -2), (22, 0)], HIND_W, True, False),
              ("pata_frente", [(28, -60), (39, -52), (49, -60), (54, -69)], FRONT_W, True, True)]),
    "andar_pesado": dict(
        spine=[(0, -24), (20, -32), (42, -32), (60, -26), (70, -21)], wa=[8, 10, 11, 10, 7], wb=[9, 11, 11, 9, 6],
        head=(67, -23, 12, 1.0, 0), tail=[(-4, -20), (-20, -16), (-40, -18), (-60, -10), (-78, -12)],
        legs=[("pata_frente_l", [(56, -16), (66, -11), (73, -7), (79, -7)], FRONT_W, False, False),
              ("pata_tras_l", [(8, -16), (16, -7), (4, -2), (16, 0)], HIND_W, False, False),
              ("pata_tras", [(12, -18), (22, -11), (11, -6), (21, -5)], HIND_W, True, False),
              ("pata_frente", [(60, -18), (63, -8), (65, -2), (73, 0)], FRONT_W, True, False)]),
}


def pose(name, var="comum"):
    return rat_side(POSES[name], var)


# ---------------------------------------------------------------- pose de salto frontal (escorço) — do rato da v2 (artHorde)
H = {
    "tail": "M170 80 C186 50 214 40 236 30 C256 20 254 4 278 -4",
    "hind1": "M204 86 C218 70 236 58 256 52 C266 49 270 59 262 63 C246 70 232 80 220 94 Z",
    "hind2": "M100 92 C88 76 74 64 56 58 C47 55 44 65 52 68 C66 74 78 84 88 98 Z",
    "body": "M106 150 C94 124 104 92 128 80 C140 74 160 74 172 80 C196 92 206 124 194 150 C184 172 116 172 106 150 Z",
    "armL": "M118 162 C102 168 86 180 74 196 C68 204 73 213 82 210 C96 206 110 194 130 180 Z",
    "armR": "M180 162 C196 166 212 175 226 188 C232 196 227 205 219 203 C204 199 190 190 170 180 Z",
    "earL": "M112 108 C90 98 80 70 96 55 C112 42 132 60 133 88 Z",
    "earLin": "M112 100 C99 92 94 74 102 65 C112 58 124 72 125 90 Z",
    "earR": "M167 88 C168 60 186 42 202 54 C218 67 208 98 188 108 Z",
    "earRin": "M175 90 C175 73 186 59 196 65 C205 73 200 92 188 100 Z",
    "head": "M104 132 C100 104 122 86 150 86 C178 86 200 104 196 132 C194 150 182 164 168 172 C160 178 140 178 132 172 C118 164 106 150 104 132 Z",
    "chest": "M124 170 C132 186 168 186 176 170 C172 192 128 192 124 170 Z",
    "muzzle": "M128 140 C130 126 170 126 172 140 C174 156 162 168 150 170 C138 168 126 156 128 140 Z",
    "mouth": "M133 156 C140 161 160 161 167 156 C171 172 162 189 150 191 C138 189 129 172 133 156 Z",
    "nose": "M142 142 C144 136 156 136 158 142 C158 148 152 151 150 151 C148 151 142 148 142 142 Z",
    "eyeL": "M120 124 C124 116 134 116 138 124 C134 128 124 129 120 124 Z",
    "eyeR": "M162 124 C166 116 176 116 180 124 C176 129 166 128 162 124 Z",
}


def pose_saltar(var="comum", local=True):
    """Rato saltando para a câmera. Coordenadas locais: centro da cabeça em (0,0)."""
    pal = PAL[var]
    M = T(-150, -130)
    tail_pts = bez_points(H["tail"], 2.0)[0]
    pcs = [Pc("cauda", "corpo", pal["tail"], brush(list(tail_pts[::4]), 9, 1.2))]
    pcs.append(Pc("pata_tras_l", "corpo", pal["far"], d=H["hind2"]))
    pcs.append(Pc("pata_tras", "corpo", pal["far"], d=H["hind1"]))
    for s, (x1, y1) in enumerate([(54, 58), (50, 64), (262, 52), (266, 58)]):
        dx = -9 if x1 < 150 else 9
        pcs.append(Pc(f"dedo_tras{s}", "corpo", pal["claw"], brush([(x1, y1), (x1 + dx * .6, y1 - 3), (x1 + dx, y1 - 5)], 1.8, 0.2, per=2)))
    pcs.append(Pc("tronco", "corpo", pal["fur"], d=H["body"]))
    pcs.append(Pc("pata_frente_l", "corpo", pal["fur"], d=H["armR"]))
    pcs.append(Pc("orelha_l", "cabeca", pal["ear"], d=H["earL"]))
    pcs.append(Pc("orelha", "cabeca", pal["ear"], d=H["earR"]))
    pcs.append(Pc("orelha_l_dentro", "cabeca", pal["ear_in"], d=H["earLin"], cls="inner"))
    pcs.append(Pc("orelha_dentro", "cabeca", pal["ear_in"], d=H["earRin"], cls="inner"))
    pcs.append(Pc("cabeca", "cabeca", pal["fur"], d=H["head"]))
    pcs.append(Pc("peito", "corpo", pal["belly"], d=H["chest"]))
    pcs.append(Pc("focinho", "cabeca", mix(pal["fur"], "#e6d6c0", .45), d=H["muzzle"], cls="inner"))
    pcs.append(Pc("boca", "cabeca", pal["mouth"], d=H["mouth"], cls="inner"))
    pcs.append(Pc("dente_l", "cabeca", pal["teeth"], [(143.5, 157), (144.6, 174), (149, 173.5), (149, 157)], cls="inner", mode="poly"))
    pcs.append(Pc("dente_r", "cabeca", pal["teeth"], [(151, 157), (151, 173.5), (155.4, 174), (156.5, 157)], cls="inner", mode="poly"))
    pcs.append(Pc("nariz", "cabeca", pal["nose"], d=H["nose"], cls="inner"))
    pcs.append(Pc("pata_frente", "corpo", pal["fur"], d=H["armL"]))
    for i, (a, b) in enumerate([((76, 200), (61, 195)), ((73, 205), (58, 207)), ((75, 210), (62, 218)), ((80, 212), (72, 224)),
                                ((225, 193), (240, 187)), ((228, 199), (243, 199)), ((226, 204), (239, 211)), ((220, 206), (228, 217))]):
        m = ((a[0] + b[0]) / 2 + (b[1] - a[1]) * .2, (a[1] + b[1]) / 2 - (b[0] - a[0]) * .2)
        pcs.append(Pc(f"garra{i}", "corpo", pal["claw"], brush([a, m, b], 2.6, 0.3, per=3)))
    pcs.append(Pc("olho_l", "cabeca", pal["eye"], d=H["eyeL"], cls="inner"))
    pcs.append(Pc("olho", "cabeca", pal["eye"], d=H["eyeR"], cls="inner"))
    pcs.append(Pc("sobrancelha_l", "cabeca", "#2b1a10", [(114, 115), (126, 118), (137, 124)], closed=False, cls="inner", sw=2.4))
    pcs.append(Pc("sobrancelha", "cabeca", "#2b1a10", [(186, 115), (174, 118), (163, 124)], closed=False, cls="inner", sw=2.4))
    for i, wd in enumerate(["M130 146 C112 141 96 141 78 146", "M130 151 C112 153 97 158 82 167", "M170 146 C188 141 204 141 222 146", "M170 151 C188 153 203 158 218 167"]):
        pcs.append(Pc(f"bigode_{i}", "cabeca", "#2b1a10", d=wd, closed=False, cls="inner", sw=0.8))
    return [p.moved(M) for p in pcs] if local else pcs


def mix(a, b, t):
    ha = [int(a[i:i + 2], 16) for i in (1, 3, 5)]; hb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(ha, hb))


# ---------------------------------------------------------------- Rei dos Ratos (de pé, inclinado, cetro apontando)
def pose_rei():
    pal = PAL["rei"]; pcs = []
    MANTO = [(10, -92), (26, -94), (30, -84), (22, -60), (14, -30), (6, -2), (-20, 4), (-50, -2), (-74, -14), (-88, -34),
             (-80, -46), (-92, -62), (-74, -70), (-60, -86), (-40, -90), (-18, -96)]
    pcs.append(Pc("manto", "manto", "#5a3a8c", MANTO))
    pcs.append(Pc("manto_forro", "manto", "#3e2866", [(-70, -16), (-86, -34), (-78, -44), (-62, -30), (-44, -20), (-24, -10), (-30, -2)], cls="inner"))
    pcs.append(Pc("cauda", "corpo", pal["tail"], brush([(-2, -14), (-14, -2), (-36, 2), (-58, -6), (-74, -2)], 7, 0.8)))
    pcs += leg("perna_l", [(0, -24), (-8, -14), (-16, -6), (-6, 0)], [14, 9, 5, 4], pal["far"], pal)
    pcs.append(Pc("tronco", "corpo", pal["fur"], tube([(2, -22), (6, -44), (12, -64), (20, -80), (26, -92)],
                                                    [19, 24, 23, 18, 11], [19, 25, 24, 18, 10], cap0=0.9, cap1=0.4)))
    pcs.append(Pc("barriga", "corpo", pal["belly"], ellipse(16, -52, 16, 25, -14, 10)))
    pcs += leg("perna", [(8, -24), (22, -16), (14, -6), (28, 0)], [15, 9, 5, 4], pal["fur"], pal)
    pcs += leg("braco_l", [(16, -82), (0, -72), (-14, -80)], [11, 8, 6], pal["far"], pal)
    pcs.append(Pc("gola", "manto", "#f4f0e6", [(4, -86), (14, -94), (30, -96), (40, -90), (36, -82), (22, -84), (10, -78)]))
    for i, (x, y) in enumerate([(14, -88), (24, -90), (33, -88)]):
        pcs.append(Pc(f"gola_pinta{i}", "manto", "#2b1a10", ellipse(x, y, 1.2, 1.6, 0, 6), cls="inner"))
    pcs.append(Pc("broche", "manto", "#c8303a", ellipse(26, -84, 3, 3, 0, 8), cls="inner"))
    # cetro: haste diagonal pela mão, gema roxa na ponta
    a, b = A((34, -54)), A((92, -120))
    d = (b - a) / np.linalg.norm(b - a); n = np.array([-d[1], d[0]])
    pcs.append(Pc("cetro_haste", "cetro", "#c8942e", [a + n * 2.2, b + n * 1.8, b - n * 1.8, a - n * 2.2], mode="poly"))
    pcs.append(Pc("cetro_pomo", "cetro", "#c8942e", ellipse(a[0], a[1], 4, 4, 0, 8)))
    g = b + d * 9
    pcs.append(Pc("cetro_gema", "cetro", "#7a4cc8", [b + n * 6 + d * 2, g + d * 6, b - n * 6 + d * 2, b - d * 3], mode="poly"))
    pcs.append(Pc("cetro_brilho", "cetro", "#d8c0ff", [b + n * 2 + d * 3, g + d * 1, b + d * 1], cls="inner", mode="poly"))
    pcs += leg("braco", [(26, -82), (42, -74), (56, -80)], [12, 8.5, 6.5], pal["fur"], pal)
    Mh = tmat(25, -95, -20, 1.38)
    pcs += head_side(pal, Mh, 26, "rei", crown=True)
    CROWN = [(2, -12), (0, -24), (5, -18), (10, -28), (14, -18), (19, -27), (21, -16), (24, -21), (22, -10), (12, -9)]
    pcs.append(Pc("coroa", "coroa", "#e2a93a", list(ap(Mh, CROWN)), mode="poly"))
    for i, (x, y, c) in enumerate([(8, -13, "#c8303a"), (15, -13, "#3a9a5a")]):
        pcs.append(Pc(f"coroa_joia{i}", "coroa", c, list(ap(Mh, ellipse(x, y, 1.8, 1.8, 0, 6))), cls="inner"))
    for i, (x, y) in enumerate([(0, -24), (10, -28), (19, -27), (24, -21)]):
        pcs.append(Pc(f"coroa_bola{i}", "coroa", "#f0c050", list(ap(Mh, ellipse(x, y, 1.6, 1.6, 0, 6))), cls="inner"))
    return pcs


# ---------------------------------------------------------------- silhueta única (multidões)
_SIL = {}


def silhouette(name="correr", var="comum", flip=False):
    key = (name, var)
    if key not in _SIL:
        pcs = pose(name, var) if name != "saltar" else pose_saltar(var)
        polys = union_poly(pcs, off=(140, 140))
        _SIL[key] = polys[0]
    P = _SIL[key].copy()
    if flip:
        P[:, 0] = -P[:, 0]
    return P
