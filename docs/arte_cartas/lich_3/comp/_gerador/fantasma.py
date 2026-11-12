"""Ficha do FANTASMA (vilão Lich, almas). Forma etérea: tronco humano magro de ombros caídos, braços longos de mangas
esfarrapadas, mãos de dedos compridos (bem legíveis), cabeça de rosto comprido com órbitas fundas e boca que escancara,
cabelo/véu esvoaçando para trás e, no lugar das pernas, uma CAUDA DE NÉVOA que afina em 2-3 fiapos.
Coordenadas: cintura em (0,0) por padrão (o fantasma não toca o chão). Unidade: cabeça = 24 u (topo -14 ao queixo +11).
Pescoço→cintura ≈ 2 cabeças; cauda ≈ 3-4 cabeças; braço 1,3 / antebraço 1,3; mão 0,6 + dedos 0,55. Ombros 1,6 cabeça.
data-fig: fantasma_corpo (tronco, cauda, fiapos, braços, mangas, mãos), fantasma_cabeca (rosto, véu/cabelo).
Órbitas, olhos, boca, sobrancelhas, costelas fantasmas e dobras da cauda = inner."""
import math
import numpy as np
from geom import *
from piper import ik
from esqueleto import frame

INK = "#2b1a10"
PAL = dict(body="#cdeee4", body_d="#8cc4b8", body_l="#f2fffa", veil="#a8d8d0", socket="#1a2a34", eye="#7dffb0",
           eye_c="#f4fff0", mouth="#122028", mist="#9fd4c8")
L_UA, L_FA = 31.0, 31.0


def unit(v):
    v = A(v); return v / (np.linalg.norm(v) + 1e-9)


def head(M, turn=0.0, jaw=4.0, hair=200.0, hl=1.0, spread=22.0, fig="cabeca"):
    """Rosto comprido (frente com giro 'turn' -1..1) + véu/cabelo esvoaçando na direção 'hair' (graus, coordenadas da cabeça)."""
    p = PAL; pcs = []
    tw = turn * 3.0
    # véu / cabelo: 5 mechas saindo do topo-trás em leque em volta de 'hair' (atrás do rosto)
    for k, (o, L, w, da) in enumerate([(-8, 30, 6.0, -spread), (-4, 38, 7.0, -spread * 0.45), (0, 42, 7.5, 0),
                                       (4, 36, 7.0, spread * 0.45), (8, 28, 6.0, spread)]):
        a = math.radians(hair + da)
        d = np.array([math.cos(a), math.sin(a)]); n = np.array([-d[1], d[0]])
        b = np.array([o - tw * 0.5, -10 + abs(o) * 0.3])
        wav = 3.0 * (1 if k % 2 else -1)
        pts = [b, b + d * L * hl * 0.35 + n * wav * 0.6, b + d * L * hl * 0.7 - n * wav * 0.4, b + d * L * hl + n * wav]
        pcs.append(Pc(f"veu{k}", fig, p["veil"], tube(pts, [w, w * 0.8, w * 0.45, 0.5], None, cap0=0.8, cap1=0.3, per=4)))
    jy = jaw
    face = [(-9.6 + tw * 0.3, -6), (-8.4 + tw * 0.2, -11.5), (-4 + tw * 0.4, -14.4), (1 + tw * 0.6, -14.8), (6 + tw * 0.4, -13.6),
            (9.4 + tw * 0.2, -9), (10 + tw * 0.2, -2), (8 + tw * 0.4, 4 + jy * 0.3), (4.6 + tw * 0.6, 9 + jy * 0.8),
            (tw * 0.8, 11.5 + jy), (-4.6 + tw * 0.6, 9 + jy * 0.8), (-8.4 + tw * 0.4, 4 + jy * 0.3)]
    pcs.append(Pc("rosto", fig, p["body"], face))
    # órbitas fundas (caídas para fora: expressão de lamento) + pupilas acesas
    for s in (-1, 1):
        tg = "_l" if s < 0 else "_r"
        ox = 4.4 * s + tw
        sq = 1 - 0.25 * turn * s  # o olho do lado para onde gira encolhe
        pcs.append(Pc("orbita" + tg, fig, p["socket"], ellipse(ox, -3.0, 2.7 * sq, 3.2, -s * 22, 9), cls="inner"))
        pcs.append(Pc("olho" + tg, fig, p["eye"], ellipse(ox + 0.2 * s, -2.4, 1.0 * sq, 1.2, 0, 7), cls="inner"))
        pcs.append(Pc("olho_c" + tg, fig, p["eye_c"], ellipse(ox + 0.2 * s, -2.6, 0.45, 0.5, 0, 6), cls="inner"))
        pcs.append(Pc("sobrancelha" + tg, fig, INK, [(ox - 3.6 * s, -6.4 - 1.6), (ox, -7.6), (ox + 3.4 * s, -6.2 + 1.4)], closed=False, cls="inner", sw=0.7))
        pcs.append(Pc("maca" + tg, fig, p["body_d"], [(ox + 2.6 * s, 1.0), (ox + 1.2 * s, 3.4 + jy * 0.3), (ox - 0.4 * s, 4.6 + jy * 0.4)], closed=False, cls="inner", sw=0.6))
    pcs.append(Pc("nariz", fig, p["body_d"], [(tw + 0.6, -0.5), (tw + 1.4, 2.4), (tw - 0.4, 3.0)], closed=False, cls="inner", sw=0.6))
    # boca: oval vertical que escancara (jaw), dentro escuro
    my = 5.6 + jy * 0.35
    pcs.append(Pc("boca", fig, p["mouth"], ellipse(tw * 0.9, my + jy * 0.3, 2.6 + jy * 0.18, 1.4 + jy * 0.55, 0, 10), cls="inner"))
    return [q.moved(M) for q in pcs]


def hand(name, wrist, ang, s=1.0, mode="open", fill=None, fig="corpo"):
    """Mão de dedos compridos e finos (4 dedos de 3 falanges + polegar). mode: open (leque), reach (abertos e um pouco
    curvos, para agarrar), claw (curvados)."""
    fill = fill or PAL["body"]
    d = np.array([math.cos(math.radians(ang)), math.sin(math.radians(ang))]); n = np.array([-d[1], d[0]])
    c = A(wrist) + d * 4.2 * s
    pcs = [Pc(name, fig, fill, ellipse(c[0], c[1], 5.0 * s, 4.0 * s, ang, 9))]
    spread = dict(open=17, reach=12, claw=10)[mode]
    curl = dict(open=0.0, reach=0.35, claw=0.9)[mode]
    for k in range(4):
        a_ = math.radians(ang + (k - 1.5) * spread)
        dk = np.array([math.cos(a_), math.sin(a_)]); nk = np.array([-dk[1], dk[0]])
        b = c + d * 3.4 * s + n * (k - 1.5) * 2.0 * s
        Lk = (12.5 if k in (1, 2) else 10.5) * s
        pts = [b, b + dk * Lk * 0.42, b + dk * Lk * (0.78 - curl * 0.12) + nk * curl * 2.4 * s,
               b + dk * Lk * (1.0 - curl * 0.3) + nk * curl * 5.2 * s]
        pcs.append(Pc(f"{name}_dedo{k}", fig, fill, tube(pts, [2.2 * s, 1.9 * s, 1.5 * s, 0.9 * s], None, cap0=0.6, cap1=0.9, per=3)))
    a_ = math.radians(ang - 58)
    dt = np.array([math.cos(a_), math.sin(a_)])
    b = c - n * 3.2 * s
    pcs.append(Pc(f"{name}_polegar", fig, fill, tube([b, b + dt * 4.4 * s, b + dt * 8 * s + d * 1.5 * s], [2.4 * s, 1.9 * s, 1.1 * s], None, cap0=0.6, cap1=0.9, per=3)))
    return pcs


def ghost(J):
    """J: neck, waist, head=(x,y,rot[,s]), turn, jaw, hair (graus, mundo), tail=[pontos da cintura à ponta], tw (largura
    da cauda na cintura), wisps=[(t, ang, L)] fiapos, wl/wr punhos, ebl/ebr, hdl/hdr, hml/hmr, hsl/hsr, far, drape (graus:
    para onde as mangas esvoaçam)."""
    p = PAL; pcs = []
    nk, wa = A(J["neck"]), A(J.get("waist", (0, 0)))
    up = unit(nk - wa); side = np.array([-up[1], up[0]])
    F = frame(nk, up)
    far = J.get("far", "l")
    shl, shr = F(-19, -5), F(19, -5)
    drape = J.get("drape", 160)
    dv = np.array([math.cos(math.radians(drape)), math.sin(math.radians(drape))])

    def arm(tag):
        sh = shl if tag == "l" else shr
        el, wr = ik(sh, J["w" + tag], L_UA, L_FA, J.get("eb" + tag, 1))
        fill = p["body_d"] if tag == far else p["body"]
        out = [Pc("braco_" + tag, "corpo", fill, tube([sh, el, wr], [5.4, 4.2, 3.0], None, cap0=0.6, cap1=0.5, per=4))]
        # manga esfarrapada: borda de cima = antebraço (cotovelo -> 80%), borda de baixo = dentes pendendo para 'drape'
        fa = wr - el; L = np.linalg.norm(fa); t = fa / L
        ts = np.linspace(-0.08, 0.8, 7)
        top = [el + fa * u for u in ts]
        lens = [5, 15, 7, 18, 6, 12, 3]
        bot = [el + fa * u + dv * l_ + t * (l_ * 0.25) for u, l_ in zip(ts, lens)]
        out.append(Pc("manga_" + tag, "corpo", fill, top + bot[::-1], mode="poly"))
        out += hand("mao_" + tag, wr, J.get("hd" + tag, math.degrees(math.atan2(t[1], t[0]))), J.get("hs" + tag, 1.0),
                    J.get("hm" + tag, "open"), fill)
        return out

    # cauda de névoa (atrás de tudo): tube da cintura à ponta + fiapos
    tail = [A(q) for q in J["tail"]]
    sp = [F(0, -30), wa] + tail
    tw = J.get("tw", 15)
    n_ = len(sp)
    w = [tw * 0.95, tw] + [tw * (1 - (i + 1) / (n_ - 1)) ** 0.9 + 0.8 for i in range(n_ - 2)]
    pcs.append(Pc("cauda", "corpo", p["body_d"], tube(sp, w, None, cap0=0.5, cap1=0.6, per=5)))
    smp = cr_sample(sp, 8)
    for k, (tt, ang, L) in enumerate(J.get("wisps", [(0.62, 30, 30), (0.78, -35, 26)])):
        i = int(tt * (len(smp) - 1))
        b = smp[i]; tg = unit(smp[min(i + 1, len(smp) - 1)] - smp[max(i - 1, 0)])
        a = math.atan2(tg[1], tg[0]) + math.radians(ang)
        dd = np.array([math.cos(a), math.sin(a)]); nn = np.array([-dd[1], dd[0]])
        ww = max(2.5, tw * (1 - tt) * 0.8)
        pts = [b, b + dd * L * 0.4 + nn * 3, b + dd * L * 0.75 - nn * 2, b + dd * L]
        pcs.append(Pc(f"fiapo{k}", "corpo", p["body_d"], tube(pts, [ww, ww * 0.75, ww * 0.4, 0.5], None, cap0=0.6, cap1=0.3, per=4)))
    # dobras da cauda (inner)
    for k, tt in enumerate((0.25, 0.45)):
        i = int(tt * (len(smp) - 1)); b = smp[i]; tg = unit(smp[i + 1] - smp[i - 1]); nn = np.array([-tg[1], tg[0]])
        ww = tw * (1 - tt * 0.8) * 0.7
        pcs.append(Pc(f"dobra{k}", "corpo", p["body_d"], [b + nn * ww, b + tg * 6, b - nn * ww * 0.6], closed=False, cls="inner", sw=0.7))
    pcs += arm(far)
    # tronco magro: ombros caídos, peito, cintura (funde na cauda)
    tr = [F(-22, -4), F(-12, 1), F(0, 2), F(12, 1), F(22, -4), F(21, -12), F(17, -22), F(13, -34), F(10, -44),
          wa + side * 11 + up * 4, wa + side * 13, wa - side * 13, wa - side * 11 + up * 4, F(-10, -44), F(-13, -34), F(-17, -22), F(-21, -12)]
    pcs.append(Pc("tronco", "corpo", p["body"], tr))
    pcs.append(Pc("pescoco", "corpo", p["body"], [F(-6, -2), F(-5, 10), F(5, 10), F(6, -2)]))
    # costelas fantasmas (inner) e clavículas
    pcs.append(Pc("clavicula_l", "corpo", p["body_d"], [F(-4, -2), F(-12, -4), F(-18, -4)], closed=False, cls="inner", sw=0.7))
    pcs.append(Pc("clavicula_r", "corpo", p["body_d"], [F(4, -2), F(12, -4), F(18, -4)], closed=False, cls="inner", sw=0.7))
    for i in range(3):
        u = -14 - i * 8; w_ = 13 - i * 1.2
        for s in (-1, 1):
            pcs.append(Pc(f"costela{i}{'l' if s < 0 else 'r'}", "corpo", p["body_d"], [F(s * 3, u + 1), F(s * w_ * 0.7, u - 1.5), F(s * w_, u - 5)],
                          closed=False, cls="inner", sw=0.6))
    pcs += arm("r" if far == "l" else "l")
    hx, hy, hr = J["head"][:3]
    hs = J["head"][3] if len(J["head"]) > 3 else 1.0
    hair_local = J.get("hair", 200) - hr
    pcs += head(tmat(hx, hy, hr, hs), J.get("turn", 0), J.get("jaw", 4), hair_local, J.get("hl", 1.0), J.get("spread", 22))
    return pcs


POSES = {
    # atravessar: corpo quase deitado, mergulhando para a direita (através de uma parede), braços à frente, cauda longa atrás
    "atravessar": dict(neck=(30, -20), waist=(-14, 0), head=(50, -28, 70, 1.45), turn=0.6, jaw=3, hair=185, hl=1.1, spread=14,
                       tail=[(-44, 6), (-74, 0), (-100, -12), (-122, -8)], tw=14,
                       wisps=[(0.55, 40, 26), (0.75, -40, 22)], far="l", drape=170,
                       wl=(80, -40), ebl=-1, hdl=-10, hml="reach", wr=(84, -14), ebr=1, hdr=10, hmr="reach", hsr=1.05),
    # avançar: flutuando para a câmera, inclinado, mão direita grande em escorço (o toque do Medo), esquerda para trás
    "avancar": dict(neck=(8, -78), waist=(0, -26), head=(14, -98, 12, 1.5), turn=0.3, jaw=5, hair=165, hl=1.0, spread=18,
                    tail=[(-10, 6), (-30, 30), (-22, 54), (-40, 70)], tw=16,
                    wisps=[(0.6, 50, 24), (0.8, -40, 20)], far="l", drape=200,
                    wl=(-46, -50), ebl=1, hdl=200, hml="open", wr=(58, -96), ebr=-1, hdr=-30, hmr="reach", hsr=2.0),
    # gritar: cabeça projetada para a frente com a boca escancarada, braços abertos para trás, cauda em S erguida
    "gritar": dict(neck=(4, -80), waist=(-2, -28), head=(12, -101, 10, 1.5), turn=0.0, jaw=10, hair=215, hl=1.2, spread=26,
                   tail=[(4, -6), (20, 14), (8, 38), (-16, 50), (-30, 44)], tw=17,
                   wisps=[(0.5, 50, 26), (0.7, -50, 24), (0.88, 40, 18)], far="r", drape=240,
                   wl=(-62, -102), ebl=1, hdl=200, hml="claw", wr=(64, -104), ebr=-1, hdr=-20, hmr="claw"),
}
GUIDE = {"atravessar": [(-122, -8), (-74, 0), (-14, 0), (30, -20), (60, -34)],
         "avancar": [(-40, 70), (-22, 54), (-10, 6), (0, -26), (8, -78), (20, -110)],
         "gritar": [(-30, 44), (8, 38), (4, -6), (-2, -28), (4, -80), (16, -112)]}


def pose(name, **over):
    J = dict(POSES[name]); J.update(over)
    return ghost(J)


def J(name, **over):
    d = dict(POSES[name]); d.update(over)
    return d


def ficha(svg_wrap, ruler, ground_line):
    from fichas_lib import txt, pose_g, swatches
    W, H = 1180, 560
    P = [txt(20, 30, "FICHA · FANTASMA (Lich, almas) — forma etérea: rosto comprido de órbitas fundas e boca que escancara, mãos de dedos longos, cauda de névoa", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 24 u. Pescoço→cintura ≈ 2 cabeças; cauda 3–4 cabeças afinando em 2–3 fiapos; braço 1,3 / antebraço 1,3; mão 0,6 + dedos 0,55; ombros 1,6 cabeça.", 10),
         txt(20, 62, "Não toca o chão (cintura em y=0 = referência). Véu/cabelo e mangas esvoaçam CONTRA o movimento. Olhos verdes acesos = brilho próprio (foco); corpo claro e frio contra a noite.", 10),
         txt(20, 76, "data-fig: fantasma_corpo (tronco, cauda, fiapos, braços, mangas, mãos), fantasma_cabeca (rosto + véu). Órbitas, olhos, boca, sobrancelhas, costelas e dobras = inner.", 10),
         ruler(40, 92, 24 * 2, 4, "#cdeee4", "#8cc4b8", "1 cabeça = 24 u (régua ×2)")]
    P.append(pose_g("cabeca_frente", head(T(0, 0), 0, 3, 90, 1.0, 40), (80, 200, 3.0), "fantasma", label="cabeça · frente", ly=56))
    P.append(pose_g("cabeca_34", head(T(0, 0), 0.7, 10, 170, 1.0, 22), (80, 390, 3.0), "fantasma", label="cabeça · 3/4, grito", ly=74))
    for i, (nm, lab, sub, pos) in enumerate([("atravessar", "atravessar · mergulho", "deitado, braços à frente", (390, 330)),
                                            ("avancar", "avançar · o toque", "mão em escorço para a câmera", (680, 400)),
                                            ("gritar", "gritar · Medo", "boca escancarada, braços abertos", (930, 400))]):
        P.append(pose_g(nm, pose(nm), (pos[0], pos[1], 1.7), "fantasma", GUIDE[nm], lab, sub, ly=150 if nm != "atravessar" else 80))
    P.append(swatches(1040, 110, [(k, PAL[k]) for k in ("body", "body_d", "body_l", "veil", "socket", "eye", "eye_c", "mouth")]))
    return svg_wrap(W, H, P), (W, H)
