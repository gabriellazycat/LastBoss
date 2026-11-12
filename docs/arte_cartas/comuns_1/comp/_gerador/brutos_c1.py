"""Rig comum das CRIATURAS GRANDES do lote comuns_1 (ogro, troll das cavernas, titã da ruína).
Um rig só (tronco por pontos num referencial quadril→pescoço + membros por IK de dois ossos com músculos em 5 larguras +
mãos/pés grandes); cada criatura é um 'kit' (proporções, contorno do tronco, cabeça, paleta, extras) em ogro/troll/tita
abaixo. Vista 3/4 olhando para +x (face=1; face=−1 espelha o tronco e a cabeça). Membros 'l' saem do lado das costas e 'r' do
lado do peito; far ('l' ou 'r') diz qual par fica longe da câmera (mais escuro e desenhado atrás). Chão em y=0.
data-fig: <criatura>_corpo (tronco, membros, mãos, pés, tanga), <criatura>_cabeca, <criatura>_<prop> (clava, pedra...).
Linhas internas (umbigo, dobras, rachaduras, olhos, boca, dentes, unhas) = inner."""
import base  # noqa: F401
import math
import numpy as np
from geom import *
from piper import ik

INK = "#2b1a10"


def deg(v):
    return math.degrees(math.atan2(v[1], v[0]))


def unit(v):
    v = A(v); return v / (np.linalg.norm(v) + 1e-9)


def perp(v):
    return np.array([-v[1], v[0]])


# ============================================================ peças genéricas
def muscle(name, a, j, b, w, fill, fig="corpo", bulge=(0.45, 0.5)):
    """Membro de dois ossos a→j→b com 5 larguras w=(raiz, ventre1, junta, ventre2, ponta); o ventre do músculo fica
    deslocado para o lado de fora (bulge) para não parecer cano."""
    a, j, b = A(a), A(j), A(b)
    m1 = a + (j - a) * bulge[0]; m2 = j + (b - j) * bulge[1]
    return Pc(name, fig, fill, tube([a, m1, j, m2, b], [w[0], w[1], w[2], w[3], w[4]], None, cap0=0.55, cap1=0.45, per=4))


def mitt(name, wrist, ang, s, mode, fill, nail, fig="corpo", nfing=4, fat=1.0, claw=0.0):
    """Mão grande: palma + nfing dedos de 3 nós + polegar. ang = direção do antebraço→dedos.
    mode: fist (punho fechado), open (aberta, dedos em leque), grip (fechada em volta de um cabo), claw (garra curvada)."""
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = perp(d)
    c = A(wrist) + d * 7 * s
    pcs = [Pc(name, fig, fill, ellipse(c[0], c[1], 10 * s * fat, 9 * s * fat, ang, 12))]
    fw = 3.6 * s * fat
    for k in range(nfing):
        off = (k - (nfing - 1) / 2) * 4.6 * s * fat
        b = c + d * 5 * s + n * off
        if mode in ("fist", "grip"):
            pts = [b, b + d * 6 * s + n * off * 0.1, b + d * 6.5 * s - n * 5.5 * s]
        elif mode == "claw":
            a_ = math.radians(ang + (k - (nfing - 1) / 2) * 13); dk = np.array([math.cos(a_), math.sin(a_)])
            pts = [b, b + dk * 9 * s, b + dk * 14 * s - perp(dk) * 5 * s]
        else:
            a_ = math.radians(ang + (k - (nfing - 1) / 2) * 15); dk = np.array([math.cos(a_), math.sin(a_)])
            pts = [b, b + dk * 9 * s, b + dk * 17 * s + perp(dk) * 1.5 * s]
        pcs.append(Pc(f"{name}_dedo{k}", fig, fill, tube(pts, [fw, fw * 0.92, fw * 0.75], None, cap0=0.5, cap1=0.9, per=3)))
        if claw:
            tip = A(pts[-1]); dd = unit(A(pts[-1]) - A(pts[-2]))
            pcs.append(Pc(f"{name}_unha{k}", fig, nail, [tip + perp(dd) * fw * 0.6, tip + dd * claw * s, tip - perp(dd) * fw * 0.6], mode="poly"))
        elif mode == "open":
            tip = A(pts[-1]); dd = unit(A(pts[-1]) - A(pts[-2]))
            pcs.append(Pc(f"{name}_unha{k}", fig, nail, ellipse(*(tip - dd * 1.6 * s), 1.6 * s, 1.2 * s, deg(dd), 6), cls="inner"))
    a_ = math.radians(ang - 70 if mode != "grip" else ang - 40); dt = np.array([math.cos(a_), math.sin(a_)]); b = c - n * 7 * s * fat
    pcs.append(Pc(f"{name}_polegar", fig, fill, tube([b, b + dt * 8 * s, b + dt * 12 * s + d * 4 * s], [fw * 1.1, fw, fw * 0.8], None, cap0=0.6, cap1=0.9, per=3)))
    if mode in ("fist", "grip"):
        for k in range(nfing - 1):
            off = (k + 0.5 - (nfing - 1) / 2) * 4.6 * s * fat
            q = c + d * 11 * s + n * off
            pcs.append(Pc(f"{name}_vinco{k}", fig, INK, [q - d * 2 * s, q + d * 1.5 * s], closed=False, cls="inner", sw=0.6))
    return pcs


def bigfoot(name, ankle, toe, s, fill, nail, fig="corpo", ntoe=3, heel=1.0):
    """Pé largo e chato: calcanhar + peito do pé + ntoe dedos curtos com unha."""
    an, to = A(ankle), A(toe); d = unit(to - an); n = perp(d)
    L = np.linalg.norm(to - an)
    pcs = [Pc(name, fig, fill, [an - d * 6 * s * heel - n * 1 * s, an + n * 8 * s, an + d * L * 0.55 + n * 7 * s, to + n * 6 * s, to - n * 5 * s,
                                an + d * L * 0.4 - n * 7.5 * s, an - d * 4 * s * heel - n * 7 * s])]
    for k in range(ntoe):
        off = (k - (ntoe - 1) / 2) * 5 * s
        b = to - d * 4 * s + n * off * 0.9
        e = to + d * 5 * s + n * off * 1.1 - n * 1.5 * s
        pcs.append(Pc(f"{name}_dedo{k}", fig, fill, tube([b, (b + e) / 2 + n * 0.8 * s, e], [3.4 * s, 3.2 * s, 2.6 * s], None, cap0=0.5, cap1=0.9, per=3)))
        pcs.append(Pc(f"{name}_unha{k}", fig, nail, ellipse(*(e - d * 0.8 * s), 1.8 * s, 1.4 * s, deg(d), 6), cls="inner"))
    return pcs


def block(name, a, b, w0, w1, fill, fig="corpo", ch=0.25, skew=0.0):
    """Bloco de pedra de a até b (largura w0→w1) com quinas chanfradas (para o titã)."""
    a, b = A(a), A(b); d = b - a; t = unit(d); n = perp(t)
    c0 = ch * w0; c1 = ch * w1
    pts = [a + n * (w0 / 2 - c0), a + n * w0 / 2 + t * c0, b + n * w1 / 2 - t * c1 + t * skew, b + n * (w1 / 2 - c1),
           b - n * (w1 / 2 - c1), b - n * w1 / 2 - t * c1 - t * skew, a - n * w0 / 2 + t * c0, a - n * (w0 / 2 - c0)]
    return Pc(name, fig, fill, pts, mode="poly")


# ============================================================ rig
def brute(J, K):
    """J: hip, neck, head=(x,y,rot), hk, far, a_l/t_l/kb_l, a_r/t_r/kb_r, w_l/eb_l/hd_l/hm_l, w_r/... , open (0..1), back (bool),
    persp (dict opcional: escorço da câmera baixa). K: kit da criatura (ver ogro/troll/tita)."""
    p = K["pal"]; fig = "corpo"
    far = J.get("far", "l"); near = "r" if far == "l" else "l"
    flip = J.get("face", 1)  # 1 = olhando para a direita; -1 espelha o tronco
    hip, nk = A(J["hip"]), A(J["neck"])
    upv = nk - hip; up = unit(upv); side = np.array([-up[1], up[0]])  # side: para a direita da tela quando de pé
    P = lambda s, t: hip + side * s * flip + upv * t
    TH, SH, UA, FA = K["L"]
    shf, shn, sht = J.get("sh", K["sh"]); hpf, hpn, hpt = K["hipj"]
    # 'l' = lado de trás do corpo (costas), 'r' = lado da frente (peito); far diz qual dos dois fica longe da câmera
    joint = {"sh_l": P(shf, sht), "sh_r": P(shn, sht), "hp_l": P(hpf, hpt), "hp_r": P(hpn, hpt)}
    col = lambda tag: p["skin_d"] if tag == far else (p["skin_l"] if J.get("near_lit") else p["skin"])
    ctx = dict(J=J, K=K, P=P, hip=hip, nk=nk, up=up, side=side * flip, flip=flip, far=far, near=near, joint=joint, col=col)

    def leg(tag):
        hj = joint["hp_" + tag]
        kn, an = ik(hj, J["a_" + tag], TH, SH, J.get("kb_" + tag, -1 * flip))
        ctx["kn_" + tag], ctx["an_" + tag] = kn, an
        out = (K["limb"]("perna_" + tag, hj, kn, an, K["wleg"], col(tag), ctx) if K.get("limb") else
               [muscle("perna_" + tag, hj, kn, an, K["wleg"], col(tag), fig, K.get("legbulge", (0.45, 0.4)))])
        if K.get("knee"):
            out.append(Pc("joelho_" + tag, fig, col(tag), ellipse(kn[0], kn[1], K["knee"], K["knee"] * 0.85, 0, 9)))
        out += K["foot"]("pe_" + tag, an, J["t_" + tag], col(tag), ctx)
        return out

    def arm(tag):
        sh = joint["sh_" + tag]
        el, wr = ik(sh, J["w_" + tag], UA, FA, J.get("eb_" + tag, 1 * flip))
        ctx["el_" + tag], ctx["wr_" + tag] = el, wr
        out = (K["limb"]("braco_" + tag, sh, el, wr, K["warm"], col(tag), ctx) if K.get("limb") else
               [muscle("braco_" + tag, sh, el, wr, K["warm"], col(tag), fig, K.get("armbulge", (0.4, 0.42)))])
        if K.get("shoulder"):
            out.append(Pc("ombro_" + tag, fig, col(tag), ellipse(sh[0], sh[1], K["shoulder"], K["shoulder"] * 0.86, deg(side), 12)))
        ang = J.get("hd_" + tag, deg(wr - el))
        out += K["hand"]("mao_" + tag, wr, ang, J.get("hm_" + tag, "fist"), col(tag), ctx)
        return out

    pcs = []
    if K.get("back_extra"):
        pcs += K["back_extra"](ctx)
    fa = arm(far)
    if J.get("prop_" + far):
        pcs += J["prop_" + far](ctx, far)
    pcs += fa
    pcs += leg(far)
    pcs += leg(near)
    tor = [P(s, t) for s, t in K["torso"]]
    pcs.append(Pc("tronco", fig, p["skin"], tor, mode=K.get("torso_mode", "cr")))
    if K.get("over_torso"):
        pcs += K["over_torso"](ctx)
    head_first = J.get("head_behind_arm", True)
    hx, hy, hr = J["head"]
    Mh = tmat(hx, hy, hr, J.get("hk", 1.0) * (-1 if flip < 0 else 1), J.get("hk", 1.0))
    hp_ = K["head"](Mh, J, ctx)
    if head_first:
        pcs += hp_
    na = arm(near)
    pcs += na
    if J.get("prop_" + near):
        pcs += J["prop_" + near](ctx, near)
    if not head_first:
        pcs += hp_
    if J.get("prop_under"):  # prop atrás de tudo (ex.: pedra segura por trás pelas duas mãos), calculado com os pulsos já prontos
        pcs = J["prop_under"](ctx, near) + pcs
    if J.get("persp"):
        pcs = persp(pcs, **J["persp"])
    return pcs


def persp(pcs, cx=0.0, top=-240.0, k=0.45, near=None):
    """Escorço de câmera baixa (de baixo para cima): quanto mais alto o ponto, mais ele encolhe em direção ao eixo cx
    (largura) e mais o alto do corpo se comprime (altura). near = (cx, cy, s, ids): peças perto da câmera crescem em
    volta de (cx, cy)."""
    def f(q):
        q = A(q); h = np.clip(-q[1] / -top if top else 0, 0, 1.4)
        sx = 1 - k * h
        y = q[1] * (1 - k * 0.45 * h)
        return np.array([cx + (q[0] - cx) * sx, y])
    out = []
    for p in pcs:
        if p.pts is None:
            out.append(p); continue
        Q = [f(q) for q in p.pts]
        if near and any(p.id == x or p.id.startswith(x + "_") for x in near[3]):
            c = A(near[:2]); Q = [c + (q - c) * near[2] for q in Q]
        out.append(Pc(p.id, p.fig, p.fill, pts=Q, closed=p.closed, cls=p.cls, mode=p.mode, sw=p.sw, op=p.op))
    return out


def rename(pcs, figmap):
    """Troca o data-fig de algumas peças (ex.: 'clava' → figura própria)."""
    return [Pc(p.id, figmap.get(p.fig, p.fig), p.fill, pts=p.pts, d=p.d, closed=p.closed, cls=p.cls, mode=p.mode, sw=p.sw, op=p.op)
            for p in pcs]
