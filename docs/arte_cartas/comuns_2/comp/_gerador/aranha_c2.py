"""Ficha da ARANHA (comuns: Teia). Aranha-tecelã grande, do tamanho de um cão: cefalotórax + abdome bojudo, 8 patas
de 3 segmentos com o joelho (patela) bem acima do corpo, quelíceras com presas, 8 olhos (2 grandes no meio).
Unidade: cabeça = comprimento do cefalotórax = 20 u. Abdome 1,7 × 1,3 cabeças; fêmur 1,4; tíbia 1,3; tarso 1,4;
envergadura das patas ≈ 5 cabeças. Cor natural: castanho-escuro peludo, marca laranja no abdome (lê a 150 px),
olhos vermelhos brilhantes (foco). data-fig: aranha_corpo (cefalotórax, patas, quelíceras), aranha_abdome.
Olhos, marcas, pelos e presas = inner. Patas do lado de longe (escuras) antes do corpo; as de perto, depois."""
import math
import numpy as np
from geom import *

PAL = dict(body="#3e2c2a", body_d="#2a1e1e", leg="#4a3430", leg_d="#33241f", abd="#4e3430", mark="#e07a2a",
           mark_l="#f4b04a", eye="#ff3a2e", eye_l="#ffd0c0", fang="#d8c8a8", hair="#7a5a4a", silk="#f2f0ea")
INK = "#2b1a10"


def _u(v):
    v = A(v); return v / (np.linalg.norm(v) + 1e-9)


def leg(name, base, knee, tip, bend, fill, w=1.0):
    """Pata: base -> joelho (alto) -> tornozelo (dobra para fora) -> ponta. bend>0 dobra para a esquerda do vetor joelho->ponta."""
    b, k, t = A(base), A(knee), A(tip)
    d = t - k; n = np.array([-d[1], d[0]]) / (np.linalg.norm(d) + 1e-9)
    an = k + d * 0.42 + n * bend
    return [Pc(name, "corpo", fill, tube([b, k, an, t], [3.8 * w, 3.0 * w, 2.2 * w, 0.8 * w], cap0=0.5, cap1=0.3, per=4)),
            Pc(name + "_joelho", "corpo", fill, ellipse(k[0], k[1], 3.2 * w, 3.0 * w, 0, 8))]


def head_side(ce, ang, cl, open_=0.4, eye_glow=True):
    """Quelíceras + olhos de perfil (frente = +x da direção ang)."""
    p = PAL; M = tmat(ce[0], ce[1], ang)
    pcs = [Pc("quelicera", "corpo", p["body_d"], list(ap(M, [(cl * 0.36, -1), (cl * 0.62, 0), (cl * 0.66, 5), (cl * 0.52, 8), (cl * 0.34, 5)])))]
    a = math.radians(70 + open_ * 50)
    tipx, tipy = cl * 0.58 + math.cos(a) * 6, 7 + math.sin(a) * 6
    pcs.append(Pc("presa", "corpo", p["fang"], list(ap(M, [(cl * 0.52, 6), (cl * 0.62, 6.5), (tipx, tipy)])), mode="poly", cls="inner"))
    for i, (x, y, r) in enumerate([(0.40, -5.2, 1.9), (0.30, -6.4, 1.4), (0.47, -3.4, 1.3), (0.22, -5.0, 1.0)]):
        e = ap(M, [(cl * x, y)])[0]
        pcs.append(Pc(f"olho{i}", "corpo", p["eye"], ellipse(e[0], e[1], r, r, 0, 7), cls="inner"))
        if i == 0 and eye_glow:
            pcs.append(Pc("olho_brilho", "corpo", p["eye_l"], ellipse(e[0] - 0.5, e[1] - 0.6, 0.6, 0.6, 0, 6), cls="inner"))
    return pcs


def head_front(ce, s=1.0, open_=0.5, tilt=0):
    """Rosto de frente: 2 olhos grandes no meio, 6 menores em arco, quelíceras e presas abertas."""
    p = PAL; M = tmat(ce[0], ce[1], tilt, s)
    pcs = []
    for sx in (-1, 1):
        pcs.append(Pc(f"quelicera_{'l' if sx < 0 else 'r'}", "corpo", p["body_d"],
                      list(ap(M, [(sx * 1.0, 2), (sx * 6.4, 2.4), (sx * 6.8, 8), (sx * 4.2, 12.4), (sx * 1.2, 10)]))))
        pcs.append(Pc(f"presa_{'l' if sx < 0 else 'r'}", "corpo", p["fang"],
                      list(ap(M, [(sx * 2.6, 11), (sx * 5.4, 11), (sx * (3.0 - open_ * 4), 17.5)])), mode="poly", cls="inner"))
    eyes = [(-2.4, -3.4, 2.3), (2.4, -3.4, 2.3), (-6.2, -2.0, 1.3), (6.2, -2.0, 1.3), (-4.6, -6.6, 1.2), (4.6, -6.6, 1.2), (-7.4, -5.4, 0.9), (7.4, -5.4, 0.9)]
    for i, (x, y, r) in enumerate(eyes):
        e = ap(M, [(x, y)])[0]
        pcs.append(Pc(f"olho{i}", "corpo", p["eye"], ellipse(e[0], e[1], r * s, r * s, 0, 7), cls="inner"))
        if i < 2:
            pcs.append(Pc(f"olho_brilho{i}", "corpo", p["eye_l"], ellipse(e[0] - 0.7 * s, e[1] - 0.7 * s, 0.7 * s, 0.7 * s, 0, 6), cls="inner"))
    return pcs


def abdomen(c, ang, rx, ry, fill=None, mark=True):
    """Abdome bojudo com a marca laranja em 'ampulheta/folha' e listras de pelo."""
    p = PAL; M = tmat(c[0], c[1], ang)
    pcs = [Pc("abdome", "abdome", fill or p["abd"], list(ap(M, [(rx, 0), (rx * 0.8, -ry * 0.72), (rx * 0.2, -ry), (-rx * 0.5, -ry * 0.9),
                                                               (-rx * 0.96, -ry * 0.4), (-rx, ry * 0.15), (-rx * 0.62, ry * 0.8),
                                                               (0, ry), (rx * 0.7, ry * 0.68)])))]
    if mark:
        pcs.append(Pc("marca", "abdome", p["mark"], list(ap(M, [(rx * 0.62, 0), (rx * 0.25, -ry * 0.34), (-rx * 0.05, -ry * 0.18),
                                                               (-rx * 0.4, -ry * 0.42), (-rx * 0.72, -ry * 0.1), (-rx * 0.4, ry * 0.2),
                                                               (-rx * 0.05, ry * 0.06), (rx * 0.25, ry * 0.3)])), cls="inner"))
        pcs.append(Pc("marca_luz", "abdome", p["mark_l"], list(ap(M, ellipse(rx * 0.25, -ry * 0.06, rx * 0.14, ry * 0.1, 0, 7))), cls="inner"))
    for k in range(3):
        y = (-0.55 + k * 0.5) * ry
        pcs.append(Pc(f"pelo{k}", "abdome", p["hair"], list(ap(M, [(-rx * 0.85, y), (-rx * 0.5, y + 2), (-rx * 0.15, y + 1)])),
                      closed=False, cls="inner", sw=0.6))
    return pcs


def spider(J):
    """J: ce (centro do cefalotórax), ang (direção da frente), cl (comprimento), ab=(x, y, ang, rx, ry),
    legs=[(nome, base, joelho, ponta, dobra, 'f'|'n')], view='side'|'front'|'top', open (presas)."""
    p = PAL; pcs = []
    ce = A(J["ce"]); ang = J.get("ang", 0); cl = J.get("cl", 20); cw = J.get("cw", 15)
    legs = J["legs"]
    ab = J["ab"]
    ab_first = J.get("ab_behind", True)
    for (nm, b, k, t, bend, lay) in legs:
        if lay == "f":
            pcs += leg(nm, b, k, t, bend, p["leg_d"])
    abd = abdomen((ab[0], ab[1]), ab[2], ab[3], ab[4])
    if ab_first:
        pcs += abd
    view = J.get("view", "side")
    M = tmat(ce[0], ce[1], ang)
    if view == "front":
        pcs.append(Pc("cefalotorax", "corpo", p["body"], ellipse(ce[0], ce[1], cw * 0.62, cl * 0.5, ang, 12)))
    else:
        pcs.append(Pc("cefalotorax", "corpo", p["body"], list(ap(M, [(cl * 0.5, -1), (cl * 0.36, -cw * 0.4), (0, -cw * 0.48), (-cl * 0.42, -cw * 0.34),
                                                                    (-cl * 0.5, 0), (-cl * 0.4, cw * 0.34), (0, cw * 0.42), (cl * 0.38, cw * 0.32)]))))
        pcs.append(Pc("sulco", "corpo", p["body_d"], list(ap(M, [(-cl * 0.34, 0), (0, 0), (cl * 0.18, -1)])), closed=False, cls="inner", sw=0.7))
    if not ab_first:
        pcs += abd
    for (nm, b, k, t, bend, lay) in legs:
        if lay == "n":
            pcs += leg(nm, b, k, t, bend, p["leg"])
    if view == "front":
        pcs += head_front(ce + A(J.get("face_off", (0, 2))), J.get("face_s", 1.0), J.get("open", 0.5), J.get("tilt", 0))
    elif view == "side":
        pcs += head_side(ce, ang, cl, J.get("open", 0.4))
    # pelos nas patas de perto (traços curtos)
    for (nm, b, k, t, bend, lay) in legs:
        if lay == "n":
            k_, t_ = A(k), A(t); d = t_ - k_; n_ = np.array([-d[1], d[0]]) / (np.linalg.norm(d) + 1e-9)
            for f in (0.2, 0.35):
                q = k_ + d * f
                pcs.append(Pc(f"{nm}_pelo{f}", "corpo", p["hair"], [q + n_ * 2.2, q + n_ * 4.2 + d * 0.05], closed=False, cls="inner", sw=0.5))
    return pcs


def _sym(cx, legs):
    """Espelha patas (lado direito -> esquerdo) em torno de x = cx (vistas de frente/de cima)."""
    out = []
    for (nm, b, k, t, bend, lay) in legs:
        out.append((nm + "_r", b, k, t, bend, lay))
        m = lambda q: (2 * cx - q[0], q[1])
        out.append((nm + "_l", m(b), m(k), m(t), -bend, lay))
    return out


POSES = {
    # andar: perfil para a direita, patas alternadas (o par 1 e 3 de perto no apoio, 2 e 4 no ar)
    "andar": dict(ce=(12, -24), ang=-4, ab=(-20, -30, -18, 21, 16), view="side", open=0.2,
                  legs=[("f0", (18, -22), (30, -48), (56, -2), -5, "f"), ("f1", (14, -21), (22, -52), (40, -6), -5, "f"),
                        ("f2", (8, -21), (0, -50), (-6, -2), 5, "f"), ("f3", (4, -21), (-8, -44), (-34, -4), 5, "f"),
                        ("n0", (20, -20), (38, -44), (62, -10), -5, "n"), ("n1", (16, -18), (26, -46), (34, 0), -6, "n"),
                        ("n2", (10, -18), (6, -48), (8, -6), 5, "n"), ("n3", (6, -18), (-4, -42), (-24, 0), 6, "n")]),
    # atacar: empinada, pares 1 e 2 erguidos para a frente e para cima, presas abertas, abdome baixo atrás
    "atacar": dict(ce=(8, -36), ang=-38, ab=(-16, -20, 24, 21, 16), view="side", open=1.0,
                   legs=[("f0", (14, -42), (22, -76), (48, -86), -6, "f"), ("f1", (12, -38), (32, -64), (56, -58), -6, "f"),
                         ("f2", (6, -34), (-2, -52), (6, -2), 6, "f"), ("f3", (2, -32), (-14, -42), (-32, -2), 6, "f"),
                         ("n0", (16, -38), (30, -70), (60, -72), -6, "n"), ("n1", (12, -34), (36, -54), (62, -44), -6, "n"),
                         ("n2", (6, -30), (4, -48), (14, 0), 6, "n"), ("n3", (2, -28), (-10, -38), (-22, 0), 6, "n")]),
    # descer: pendurada no fio, de cima/frente, cabeça para baixo, patas abertas como uma mão que vai agarrar
    "descer": dict(ce=(0, -10), ang=90, cl=20, cw=17, ab=(0, -34, 90, 20, 17), view="front", face_off=(0, 3), open=0.9,
                   legs=_sym(0, [("p0", (5, -2), (20, 2), (24, 30), -6, "n"), ("p1", (7, -8), (28, -14), (42, 12), -6, "n"),
                                 ("p2", (7, -14), (30, -30), (46, -40), 6, "f"), ("p3", (5, -18), (22, -40), (30, -62), 6, "f")])),
    # ameaça: de frente, agachada, corpo baixo, patas abertas, as duas da frente erguidas, presas abertas
    "ameaca": dict(ce=(0, -18), ang=0, cl=20, cw=19, ab=(0, -36, 0, 22, 16), view="front", face_off=(0, 1), open=1.0,
                   legs=_sym(0, [("p0", (6, -14), (18, -46), (26, -64), 5, "n"), ("p1", (8, -16), (30, -40), (44, -2), -6, "n"),
                                 ("p2", (8, -20), (34, -36), (60, -4), -6, "f"), ("p3", (6, -24), (26, -44), (40, -14), -6, "f")])),
}
GUIDE = {"andar": [(-40, -40), (-20, -30), (12, -24), (34, -20), (56, -12)],
         "atacar": [(-34, -10), (-16, -20), (8, -36), (24, -60), (50, -84)],
         "descer": [(0, -80), (0, -34), (0, -10), (0, 14)],
         "ameaca": [(-50, -2), (-20, -30), (0, -40), (20, -30), (50, -2)]}
PREV_S = 2.6


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return spider(J)


def J(name, **over):
    d = dict(POSES[name]); d.update(over)
    return d


def ficha(svg_wrap, ruler, ground_line):
    from fichas_lib import txt, pose_g, swatches
    W, H = 1180, 560
    P = [txt(20, 30, "FICHA · ARANHA (comuns, Teia) — tecelã do tamanho de um cão: cefalotórax + abdome bojudo, 8 patas com joelho acima do corpo", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = cefalotórax 20 u. Abdome 1,7 × 1,3 cab.; fêmur 1,4 / tíbia 1,3 / tarso 1,4; envergadura ≈ 5 cab. Patas: base → joelho alto → tornozelo dobrado para fora → ponta fina.", 10),
         txt(20, 62, "Castanho-escuro peludo, marca laranja no abdome (lê a 150 px), 8 olhos vermelhos (2 grandes no meio = foco). Fio de seda claro. Patas de longe escuras atrás do corpo.", 10),
         txt(20, 76, "data-fig: aranha_corpo (cefalotórax, 8 patas, quelíceras), aranha_abdome. Olhos, presas, marca, sulco e pelos = inner.", 10),
         ruler(40, 92, 20 * 2, 4, PAL["body"], PAL["mark"], "1 cabeça = 20 u (régua ×2)")]
    P.append(pose_g("cabeca_frente", head_front(A((0, 0)), 1.0, 0.8) + [Pc("cefalo", "corpo", PAL["body"], ellipse(0, 0, 10, 10, 0, 10))][:0],
                    (80, 190, 4.0), "aranha", label="rosto · frente", ly=80))
    hs = [Pc("cefalotorax", "corpo", PAL["body"], list(ap(T(0, 0), [(10, -1), (7, -6), (0, -7), (-8, -5), (-10, 0), (-8, 5), (0, 6), (8, 5)])))]
    P.append(pose_g("cabeca_perfil", hs + head_side(A((0, 0)), 0, 20, 0.8), (80, 350, 4.0), "aranha", label="cabeça · perfil", ly=60))
    for nm, lab, sub, pos in [("andar", "andar · perfil", "patas alternadas", (330, 340)),
                              ("atacar", "atacar · empinada", "pares 1–2 erguidos, presas abertas", (560, 380)),
                              ("descer", "descer · no fio", "de cima, patas abertas para agarrar", (800, 300)),
                              ("ameaca", "ameaça · de frente", "agachada, par da frente erguido", (1010, 360))]:
        s_ = 2.3
        extra = ""
        if nm == "descer":
            extra = f'<path d="M{pos[0]} {pos[1] - 34 * s_ - 120} L{pos[0]} {pos[1] - 50 * s_}" stroke="{PAL["silk"]}" stroke-width="1.6"/><path d="M{pos[0]} {pos[1] - 34 * s_ - 120} L{pos[0]} {pos[1] - 50 * s_}" stroke="#8a8a80" stroke-width=".5"/>'
        P.append(extra + pose_g(nm, pose(nm), (pos[0], pos[1], s_), "aranha", GUIDE[nm], lab, sub, ly=60 if nm != "descer" else 200))
    P.append(swatches(1060, 420, [(k, PAL[k]) for k in ("body", "leg", "abd", "mark", "eye", "fang", "silk")]))
    return svg_wrap(W, H, P), (W, H)
