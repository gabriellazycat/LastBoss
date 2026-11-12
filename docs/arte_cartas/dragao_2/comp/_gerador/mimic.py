"""Ficha do MÍMICO (vilão Dragão, Ganância) e do baú base (o Baú Armadilha usa o mesmo baú, sem dentes).
Baú de madeira com tampa abaulada, cintas de ferro, cantoneiras e fechadura de ouro. O mímico: bocarra entre a tampa
e a caixa com fileiras de dentes, língua comprida roxa-avermelhada, olhos amarelos dentro do escuro sob a tampa e
quatro patinhas de garra que saem por baixo.
Modelo 3D simples (caixa + tampa em meio-cilindro com dobradiça atrás) projetado em ortográfica com guinada (yaw) e
câmera de cima (pitch); a pose 2D (inclinação do bote) vem do transform do grupo.
Unidade: altura da caixa = 22 u ("1 caixa"); largura 1,8 caixas (40 u), fundo 1,2 (26 u), tampa +0,45 (10 u).
Chão em y=0, centro da caixa em x=0. data-fig: mimico_corpo (caixa, boca, dentes de baixo, língua, patas),
mimico_tampa (tampa, dentes de cima). Cintas, tábuas, olhos, fechadura = inner."""
import math
import numpy as np
from geom import *

INK = "#2b1a10"
PAL = dict(wood="#9a6232", wood_d="#6e4222", wood_l="#b87a40", iron="#5a5660", iron_l="#8a8692", gold="#e2aa36",
           gold_l="#ffe08a", mouth="#3a0e14", palate="#7a2030", tongue="#c8405a", tongue_d="#8e2440",
           teeth="#f2e6c4", eye="#ffd23a", pupil="#2b1a10", claw="#efe0b0")
W, H, D, LH = 40.0, 22.0, 26.0, 10.0


def proj(p, yaw, pitch):
    x, y, z = p
    a, b = math.radians(yaw), math.radians(pitch)
    x1 = x * math.cos(a) + z * math.sin(a); z1 = -x * math.sin(a) + z * math.cos(a)
    X = x1; Y = -y * math.cos(b) + z1 * math.sin(b); dep = z1 * math.cos(b) + y * math.sin(b)
    return np.array([X, Y]), dep


def nvis(n, yaw, pitch):
    """Componente da normal na direção da câmera (> 0 = face visível)."""
    (_, _), d1 = proj(n, yaw, pitch)
    (_, _), d0 = proj((0, 0, 0), yaw, pitch)
    return d1 - d0


def hull(P):
    P = sorted(map(tuple, np.round(P, 3)))
    if len(P) < 3:
        return P
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, up = [], []
    for p in P:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    for p in reversed(P):
        while len(up) >= 2 and cross(up[-2], up[-1], p) <= 0:
            up.pop()
        up.append(p)
    return lo[:-1] + up[:-1]


def chest(yaw=-28, pitch=22, open_=0.0, teeth=True, tongue=None, legs=None, eyes=True, lock=True, lid_off=None, fig="mimico"):
    """open_: ângulo da tampa (graus, 0 = fechada; 110 = escancarada). tongue: lista de pontos 2D extras (coordenadas da
    ficha) para a língua, a partir da boca. legs: lista de (base_idx, pé 2D). lid_off: (dx, dy, rot) solta a tampa (explosão)."""
    p = PAL; pcs = []
    P = lambda q: proj(q, yaw, pitch)[0]
    hw, hd = W / 2, D / 2
    # --- caixa: 8 cantos
    C = {(sx, sy, sz): (sx * hw, sy * H, sz * hd) for sx in (-1, 1) for sy in (0, 1) for sz in (-1, 1)}
    faces = {"frente": ([(-1, 0, 1), (1, 0, 1), (1, 1, 1), (-1, 1, 1)], (0, 0, 1)),
             "lado_d": ([(1, 0, 1), (1, 0, -1), (1, 1, -1), (1, 1, 1)], (1, 0, 0)),
             "lado_e": ([(-1, 0, -1), (-1, 0, 1), (-1, 1, 1), (-1, 1, -1)], (-1, 0, 0))}
    # boca aberta: o vão da caixa (topo) aparece escuro
    box_pts = [P(C[k]) for k in C]
    pcs.append(Pc("caixa", "corpo", p["wood_d"], hull(box_pts), mode="poly"))
    for nm, (ks, n) in faces.items():
        if nvis(n, yaw, pitch) > 0.05:
            q = [P(C[k]) for k in ks]
            pcs.append(Pc("caixa_" + nm, "corpo", p["wood"] if nm == "frente" else p["wood_d"], q, mode="poly", cls="inner"))
            # tábuas (linhas horizontais) e cintas de ferro verticais
            for t in (0.36, 0.68):
                a = q[0] + (q[3] - q[0]) * t; b = q[1] + (q[2] - q[1]) * t
                pcs.append(Pc(f"tabua_{nm}{t}", "corpo", INK, [a, b], closed=False, cls="inner", sw=0.5))
            for t in (0.12, 0.88):
                a0 = q[0] + (q[1] - q[0]) * t; a1 = q[3] + (q[2] - q[3]) * t
                e = (q[1] - q[0]) / np.linalg.norm(q[1] - q[0]) * 2.2
                pcs.append(Pc(f"cinta_{nm}{t}", "corpo", p["iron"], [a0 - e, a0 + e, a1 + e, a1 - e], mode="poly", cls="inner"))
    # topo da caixa (vão da boca), visto de cima
    top = [P(C[(-1, 1, -1)]), P(C[(1, 1, -1)]), P(C[(1, 1, 1)]), P(C[(-1, 1, 1)])]
    if open_ > 4:
        pcs.append(Pc("boca", "corpo", p["mouth"], top, mode="poly", cls="inner"))
        if teeth:
            # dentes de baixo: na borda da frente e na borda do lado visível, apontando para cima
            for i in range(7):
                t = (i + 0.5) / 7
                b = P((-hw + W * t, H, hd)); up = P((-hw + W * t, H + 6.2, hd - 1))
                e = (P((hw, H, hd)) - P((-hw, H, hd))) / 7 * 0.42
                pcs.append(Pc(f"dente_b{i}", "corpo", p["teeth"], [b - e, up, b + e], mode="poly"))
            side = 1 if nvis((1, 0, 0), yaw, pitch) > 0 else -1
            for i in range(3):
                t = (i + 0.6) / 3.4
                b = P((side * hw, H, hd - D * t)); up = P((side * hw - side, H + 4, hd - D * t))
                e = (P((side * hw, H, -hd)) - P((side * hw, H, hd))) / 4 * 0.38
                pcs.append(Pc(f"dente_bl{i}", "corpo", p["teeth"], [b - e, up, b + e], mode="poly"))
    # cantoneiras de ouro (frente)
    for sx in (-1, 1):
        a = P((sx * hw, 0, hd)); b = P((sx * hw, H, hd))
        pcs.append(Pc(f"canto{sx}", "corpo", p["gold"], [a, b], closed=False, cls="inner", sw=1.6))
    # --- patas (opcional): saem por baixo dos cantos, em coordenadas da ficha
    if legs:
        for i, (corner, foot) in enumerate(legs):
            base_ = P((corner[0] * hw * 0.8, 1.5, corner[1] * hd * 0.8)); f = A(foot)
            mid = (base_ + f) / 2 + np.array([corner[0] * 3, -2])
            pcs.insert(0, Pc(f"pata{i}", "corpo", p["wood_d"] if corner[1] < 0 else p["wood"], tube([base_, mid, f], [3.4, 2.8, 2.2], cap0=0.4, cap1=0.4)))
            for k in range(3):
                a = math.radians(-150 + k * 60 + (0 if corner[0] > 0 else 0))
                tip = f + np.array([math.cos(a) * 0.4 + (k - 1) * 1.6, 3.4])
                pcs.insert(1, Pc(f"pata{i}_garra{k}", "corpo", p["claw"], brush([f + [(k - 1) * 1.2, 0.5], tip], 1.6, 0.1, per=2)))
    # --- língua (corpo): tubo que sai da boca
    if tongue is not None and open_ > 4:
        mouth_c = (P((0, H, hd * 0.2)))
        sp = [mouth_c] + [A(t) for t in tongue]
        n = len(sp)
        wa = list(np.linspace(5.2, 1.4, n));
        pcs.append(Pc("lingua", "corpo", p["tongue"], tube(sp, wa, cap0=0.3, cap1=0.9, per=4)))
        mid = [mouth_c * 0.6 + sp[1] * 0.4] + sp[1:-1]
        pcs.append(Pc("lingua_sulco", "corpo", p["tongue_d"], mid, closed=False, cls="inner", sw=0.7))
    # --- tampa: meio-cilindro de eixo x, dobradiça em (y=H, z=-hd); gira open_ graus para trás
    lid3 = []
    arc = [(math.cos(t) * hd, math.sin(t) * LH) for t in np.linspace(0, math.pi, 9)]  # z, y (a partir do centro da tampa)
    def lidpt(x, zc, yc):
        # ponto da tampa fechada: z = zc (−hd..hd), y = H + yc; gira em torno da dobradiça
        z0, y0 = zc + hd, yc  # relativo à dobradiça
        a = math.radians(open_)
        z1 = z0 * math.cos(a) - y0 * math.sin(a); y1 = z0 * math.sin(a) + y0 * math.cos(a)
        return (x, H + y1, -hd + z1)
    rim = {}
    for sx in (-1, 1):
        rim[sx] = [lidpt(sx * hw, z, y) for z, y in arc]
    lid_pts = [P(q) for sx in (-1, 1) for q in rim[sx]]
    Ml = None
    if lid_off:
        dx, dy, rot = lid_off
        c0 = np.mean(lid_pts, axis=0)
        Ml = chain(T(c0[0] + dx, c0[1] + dy), R(rot), T(-c0[0], -c0[1]))
    LP = lambda q: (ap(Ml, [P(q)])[0] if Ml is not None else P(q))
    lid_pts = [LP(q) for sx in (-1, 1) for q in rim[sx]]
    lid = []
    lid.append(Pc("tampa", "tampa", p["wood_l"], hull(lid_pts), mode="poly"))
    # parte de baixo da tampa (céu da boca) quando aberta e virada para a câmera
    if open_ > 25 and not lid_off:
        under = [LP(lidpt(-hw, -hd, 0)), LP(lidpt(hw, -hd, 0)), LP(lidpt(hw, hd, 0)), LP(lidpt(-hw, hd, 0))]
        cu = np.mean(under, axis=0); under = [cu + (q - cu) * 0.86 for q in under]  # borda de madeira da tampa aparece
        lid.append(Pc("ceu_boca", "tampa", p["palate"], under, mode="poly", cls="inner"))
        if teeth:
            for i in range(7):
                t = (i + 0.5) / 7
                b = LP(lidpt(-hw + W * t, hd, 0)); dn = LP(lidpt(-hw + W * t, hd - 1, -6.6))
                e = (LP(lidpt(hw, hd, 0)) - LP(lidpt(-hw, hd, 0))) / 7 * 0.42
                lid.append(Pc(f"dente_c{i}", "tampa", p["teeth"], [b - e, dn, b + e], mode="poly"))
        if eyes:
            for k, xx in enumerate((-9, 9)):
                e = LP(lidpt(xx, hd * 0.25, -1.5))
                lid.append(Pc(f"olho{k}", "tampa", p["eye"], ellipse(e[0], e[1], 3.4, 2.4, -10, 9), cls="inner"))
                lid.append(Pc(f"pupila{k}", "tampa", p["pupil"], ellipse(e[0] + 0.4, e[1], 0.9, 2.0, 0, 6), cls="inner"))
    # cintas de ferro da tampa (arcos), frente da tampa
    for t in ((0.12, 0.88) if (open_ < 60 or lid_off) else ()):
        x = -hw + W * t
        q = [LP(lidpt(x, z, y)) for z, y in arc]
        lid.append(Pc(f"cinta_tampa{t}", "tampa", p["iron"], q, closed=False, cls="inner", sw=2.0))
    side = 1 if nvis((1, 0, 0), yaw, pitch) > 0 else -1
    cap = [LP(lidpt(side * hw, z, y)) for z, y in arc]
    lid.append(Pc("tampa_lado", "tampa", p["wood"], cap, mode="poly", cls="inner"))
    if lock and open_ < 30:
        f = LP(lidpt(0, hd, 0.5))
        lid.append(Pc("fechadura", "tampa", p["gold"], [f + (-3.4, -1), f + (3.4, -1), f + (3.4, 5), f + (0, 7.4), f + (-3.4, 5)], cls="inner", mode="poly"))
        lid.append(Pc("buraco", "tampa", INK, ellipse(f[0], f[1] + 3, 0.9, 1.4, 0, 6), cls="inner"))
    elif lock:
        f = P((0, H - 1, hd))
        pcs.append(Pc("fechadura", "corpo", p["gold"], [f + (-3.4, -4), f + (3.4, -4), f + (3.4, 2), f + (0, 4.4), f + (-3.4, 2)], cls="inner", mode="poly"))
    # ordem: se a tampa está aberta para trás, ela fica atrás da caixa; fechada ou solta, na frente
    behind = open_ > 60 and not lid_off
    out = (lid + pcs) if behind else (pcs + lid)
    if behind and tongue is not None:
        # língua sempre na frente de tudo
        tg = [q for q in out if q.id.startswith("lingua")]
        out = [q for q in out if not q.id.startswith("lingua")] + tg
    return out


POSES = {
    # disfarçado: fechado, parado, nenhum sinal (é o baú base do Baú Armadilha)
    "fechado": dict(yaw=-28, pitch=22, open_=0, teeth=False, eyes=False),
    # espreitando: tampa entreaberta, olhos acesos na fresta, uma ponta de língua
    "espreitar": dict(yaw=-24, pitch=20, open_=22, tongue=[(14, -16), (22, -10), (27, -13)],
                      legs=[((1, 1), (18, 2)), ((-1, 1), (-17, 2))]),
    # bote: tampa escancarada, língua em S para a frente, patas esticadas no salto
    "bote": dict(yaw=-32, pitch=18, open_=96, tongue=[(16, -20), (28, -12), (38, -18), (48, -12), (54, -2)],
                 legs=[((1, 1), (24, 8)), ((-1, 1), (-16, 10)), ((1, -1), (28, -2)), ((-1, -1), (-24, 0))]),
    # mordida: tampa fechando (45°), corpo projetado, língua recolhendo
    "morder": dict(yaw=-18, pitch=24, open_=48, tongue=[(10, -8), (20, 0)],
                   legs=[((1, 1), (20, 4)), ((-1, 1), (-20, 3))]),
}
GUIDE = {"fechado": [(-24, 0), (0, -18), (22, -36)],
         "espreitar": [(-22, 0), (0, -22), (24, -30)],
         "bote": [(-26, 6), (-4, -24), (28, -16), (54, -2)],
         "morder": [(-24, 2), (0, -26), (22, -42)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return chest(**J)
