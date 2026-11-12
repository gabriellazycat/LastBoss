"""Composições do lote lich_2 (vilão Lich, família Corrente/sombra). Coordenadas de carta 300x420; janela 11..289 x 11..278;
fita y >= 261. Reaproveita (só leitura) Card/stones (praga_3), sky/disk/rings/ground (praga_2), rng/RECT (praga_1),
sparks/star (dragao_1), wisp (dragao_2), shield (dragao_1). Fichas novas: cultista (cultista.py) e lich (lichfig.py);
poses novas do herói em hero_l2.py. Uso: python cartas_l2.py [ids...]   (saída: LB_OUT; rascunho: LB_SCR)"""
import base  # noqa: F401
import sys, math
import numpy as np
from geom import *
from rat import mix
from cards import rng, RECT
from cartas import sky, disk, rings, ground
from cartas3 import Card, stones
from cartas_d1 import sparks, star
from cartas_d2 import wisp
import cultista, lichfig, hero_l2

INK = "#2b1a10"
NIGHT_T, NIGHT_B = "#10162e", "#34467a"
SH = "#8a3ad0"; SH_L = "#d8a8ff"; SH_D = "#4a1a7a"; SH_W = "#f4e6ff"   # magia de sombra (violeta)
SP = "#5ae0a8"; SP_L = "#c8ffe4"                                         # espectral (verde)
STONE = "#4a4e66"; STONE_L = "#6a6e88"; STONE_D = "#2a2c40"
BONE = "#e6d8b8"


# =========================================================================== utilidades do lote
def night(c, top=NIGHT_T, bot=NIGHT_B):
    sky(c, top, bot)


def starfield(c, x0, y0, x1, y1, n, seed, col="#dfe6ff", op=0.8):
    r = rng(seed)
    for i in range(n):
        x = x0 + r.random() * (x1 - x0); y = y0 + r.random() * (y1 - y0); s = 1.2 + r.random() * 1.6
        c.b("estrela", col, [(x, y - s * 1.6), (x + s * 0.5, y), (x, y + s * 1.6), (x - s * 0.5, y)], mode="poly", op=op)


def ring(c, cx, cy, rx, ry, w, col, op=0.9, rot=0, gaps=4, seed=1, name="anel"):
    """Anel (elipse) em arcos com falhas, cada arco = um pincel (polígono)."""
    r = rng(seed); M = chain(T(cx, cy), R(rot))
    span = 360 / gaps
    for g in range(gaps):
        a0 = g * span + r.random() * 10; a1 = a0 + span - 10 - r.random() * 12
        pts = [(math.cos(math.radians(a)) * rx, math.sin(math.radians(a)) * ry) for a in np.linspace(a0, a1, 9)]
        c.f(name, col, brush(list(ap(M, pts)), w, w * 0.6), op=op)


def runes(c, cx, cy, rx, ry, n, col, s=4, rot=0, seed=2, op=0.95, name="runa"):
    """Runas (traços curtos em ângulo) em volta de uma elipse."""
    r = rng(seed); M = chain(T(cx, cy), R(rot))
    for i in range(n):
        a = math.radians(i * 360 / n + r.random() * 8)
        p = A((math.cos(a) * rx, math.sin(a) * ry))
        k = r.integers(3)
        if k == 0:
            pts = [p + (-s * .5, -s * .6), p + (0, s * .6), p + (s * .5, -s * .6)]
        elif k == 1:
            pts = [p + (-s * .5, s * .5), p + (0, -s * .7), p + (s * .5, s * .5), p + (-s * .3, 0)]
        else:
            pts = [p + (-s * .4, -s * .6), p + (s * .4, -s * .1), p + (-s * .4, s * .1), p + (s * .4, s * .6)]
        c.f(name, col, brush(list(ap(M, pts)), 1.8, 1.2, per=2), op=op)


def sigil(c, cx, cy, rx, ry, col=SH, col_l=SH_L, rot=0, seed=3, op=1.0, fill_op=0.35, name="sigilo"):
    """Círculo de runas (elipse em perspectiva): disco de luz + 2 anéis + runas + estrela interna."""
    M = chain(T(cx, cy), R(rot))
    c.f(name + "_luz", col_l, list(ap(M, ellipse(0, 0, rx * 1.05, ry * 1.05, 0, 18))), op=fill_op * op)
    ring(c, cx, cy, rx, ry, max(2.0, rx * 0.06), col, op=0.95 * op, rot=rot, gaps=3, seed=seed, name=name + "_anel")
    ring(c, cx, cy, rx * 0.74, ry * 0.74, max(1.4, rx * 0.035), col, op=0.85 * op, rot=rot, gaps=5, seed=seed + 1, name=name + "_anel")
    runes(c, cx, cy, rx * 0.87, ry * 0.87, 10, col_l, s=max(3, rx * 0.08), rot=rot, seed=seed + 2, op=op, name=name + "_runa")
    pts = [(math.cos(math.radians(-90 + k * 144)) * rx * 0.7, math.sin(math.radians(-90 + k * 144)) * ry * 0.7) for k in range(6)]
    c.f(name + "_estrela", col, brush(list(ap(M, pts)), max(1.2, rx * 0.025), max(1.2, rx * 0.025), per=2), op=0.8 * op)


def jag(p0, p1, n, amp, seed):
    r = rng(seed); p0, p1 = A(p0), A(p1); d = p1 - p0; L = np.linalg.norm(d); nn = np.array([-d[1], d[0]]) / L
    pts = [p0]
    for i in range(1, n):
        t = i / n
        pts.append(p0 + d * t + nn * amp * (r.random() * 2 - 1) * (1 - abs(2 * t - 1) * 0.3))
    pts.append(p1)
    return pts


def poly_brush(pts, w0, w1):
    """Pincel por segmentos retos (raio quebrado): lados paralelos a cada segmento, juntas em quina."""
    P = [A(p) for p in pts]; n = len(P)
    W = np.linspace(w0, w1, n) / 2
    L, Rr = [], []
    for i in range(n):
        if i == 0:
            d = P[1] - P[0]
        elif i == n - 1:
            d = P[-1] - P[-2]
        else:
            d = (P[i + 1] - P[i]) / np.linalg.norm(P[i + 1] - P[i]) + (P[i] - P[i - 1]) / np.linalg.norm(P[i] - P[i - 1])
        d = d / (np.linalg.norm(d) + 1e-9); nn = np.array([-d[1], d[0]])
        L.append(P[i] + nn * W[i]); Rr.append(P[i] - nn * W[i])
    return L + [P[-1] + (P[-1] - P[-2]) / np.linalg.norm(P[-1] - P[-2]) * W[-1] * 1.5] + Rr[::-1]


def bolt(c, pts, w, col=SH, col_l=SH_L, core=SH_W, op=1.0, taper=0.5, name="raio"):
    """Raio de sombra em 3 camadas (halo, corpo, núcleo) sobre uma polilinha quebrada."""
    c.f(name + "_halo", col_l, poly_brush(pts, w * 2.4, w * 2.4 * taper), mode="poly", op=0.35 * op)
    c.f(name, col, poly_brush(pts, w, w * taper), mode="poly", op=0.95 * op)
    c.f(name + "_nucleo", core, poly_brush(pts, w * 0.38, w * 0.38 * taper), mode="poly", op=op)


def bolt_pcs(pts, w, col=SH, col_l=SH_L, core=SH_W, taper=0.5, fig="raio"):
    """O mesmo raio como peças de uma figura (para ficar NA FRENTE do herói)."""
    return [Pc("raio", fig, col, poly_brush(pts, w, w * taper), mode="poly"),
            Pc("raio_halo", fig, col_l, poly_brush(pts, w * 1.6, w * 1.6 * taper), mode="poly", cls="inner", op=0.45),
            Pc("raio_nucleo", fig, core, poly_brush(pts, w * 0.38, w * 0.38 * taper), mode="poly", cls="inner")]


def orb(c, cx, cy, r, col=SH, col_l=SH_L, core=SH_W, seed=5, name="orbe"):
    c.f(name + "_halo", col_l, ellipse(cx, cy, r * 1.7, r * 1.7, 0, 16), op=0.3)
    c.f(name, col, blob(cx, cy, r, seed, 10, 0.12))
    c.f(name + "_luz", core, ellipse(cx - r * 0.2, cy - r * 0.2, r * 0.5, r * 0.5, 0, 10), op=0.95)


def burst(c, cx, cy, R, r_, n, col, col_l, rot=0, name="impacto"):
    star(c, cx, cy, R, r_, n, col, rot, 0.95, name)
    star(c, cx, cy, R * 0.55, r_ * 0.6, n, col_l, rot + 180 / n / 2, 1.0, name)


def shards(c, cx, cy, n, r0, r1, seed, col, a0=0, a1=2 * math.pi, s=(3, 7), name="estilhaco"):
    r = rng(seed)
    for i in range(n):
        a = a0 + r.random() * (a1 - a0); d = r0 + r.random() * (r1 - r0); sz = s[0] + r.random() * (s[1] - s[0])
        x, y = cx + math.cos(a) * d, cy + math.sin(a) * d; t = r.random() * 180
        c.f(name, col, list(ap(tmat(x, y, t), [(-sz, -sz * 0.3), (sz * 0.2, -sz * 0.6), (sz, sz * 0.2), (-sz * 0.3, sz * 0.5)])), mode="poly")


def mist(c, y, col, seed, n=7, op=0.45, x0=-10, x1=310, h=14, name="nevoa"):
    r = rng(seed)
    for i in range(n):
        x = x0 + (x1 - x0) * (i + r.random() * 0.6) / n
        c.b(name, col, ellipse(x, y + r.random() * 8, 30 + r.random() * 24, h * (0.6 + r.random() * 0.5), 0, 12), op=op)


def place(M, pt):
    return ap(M, [pt])[0]


def flagstones(c, x0, y0, x1, y1, col, seed, rows=4, cols=5, op=0.4, persp=0.0):
    stones(c, x0, y0, x1, y1, col, seed, rows=rows, cols=cols, op=op)


def window(c, cx, top, w, h, glass="#9ab4e0", frame=STONE, name="vitral"):
    """Janela gótica em arco (vidro claro de luar) com mainel e caixilho."""
    pts = [(cx - w / 2, top + h), (cx - w / 2, top + w * 0.45)]
    pts += [(cx + math.cos(math.radians(a)) * w / 2, top + w * 0.45 - math.sin(math.radians(a)) * w * 0.55) for a in np.linspace(170, 10, 9)]
    pts += [(cx + w / 2, top + w * 0.45), (cx + w / 2, top + h)]
    c.b(name + "_moldura", frame, [(x + (8 if x > cx else -8) * (1 if abs(x - cx) > 2 else 0), y - (8 if y < top + w * 0.5 else 0)) for x, y in pts], mode="poly")
    c.b(name, glass, pts, mode="poly")
    c.b(name + "_luz", "#dfe8ff", [(cx - w * 0.38, top + h), (cx - w * 0.38, top + w * 0.5), (cx - w * 0.05, top + w * 0.12), (cx - w * 0.05, top + h)], mode="poly", op=0.5)
    c.b(name + "_mainel", frame, [(cx - 2.5, top + 6), (cx + 2.5, top + 6), (cx + 2.5, top + h), (cx - 2.5, top + h)], mode="poly")
    c.b(name + "_travessa", frame, [(cx - w / 2, top + h * 0.55 - 2.5), (cx + w / 2, top + h * 0.55 - 2.5), (cx + w / 2, top + h * 0.55 + 2.5), (cx - w / 2, top + h * 0.55 + 2.5)], mode="poly")


# =========================================================================== CULTISTAS
def cultists():
    """3 cultistas no círculo de runas: o da frente (grande, cortado embaixo) de braços em V e cabeça para trás, puxando
    a coluna de luz violeta; dois ajoelhados atrás, um de cada lado, cantando. Lua clara atrás das mãos (halo)."""
    c = Card("cultists")
    night(c)
    starfield(c, -10, -10, 310, 120, 26, 801)
    disk(c, "lua", 120, 66, 46, "#e8e6f4", "#ffffff")
    c.b("morro", "#1c2442", [(-10, 196), (70, 184), (150, 192), (240, 178), (310, 186), (310, 300), (-10, 300)])
    # o cenário: pedras eretas (menir) em volta do círculo
    for i, (x, w, h) in enumerate([(244, 22, 66), (282, 18, 50), (20, 16, 44)]):
        c.b(f"menir{i}", STONE, [(x - w / 2, 214), (x - w / 2 + 2, 214 - h), (x + 1, 214 - h - 6), (x + w / 2, 214 - h + 4), (x + w / 2, 214)], mode="poly")
        c.b(f"menir{i}_luz", STONE_L, [(x - w / 2, 214), (x - w / 2 + 2, 214 - h), (x - w / 2 + 6, 214 - h - 2), (x - w / 2 + 5, 214)], mode="poly", op=0.8)
    c.b("chao", "#262a44", [(-10, 210), (310, 204), (310, 300), (-10, 300)])
    # círculo de runas no chão + coluna de luz subindo
    sigil(c, 180, 228, 112, 30, SH, SH_L, 0, 811, fill_op=0.5)
    c.f("coluna", SH_L, [(162, 230), (168, 120), (176, 30), (184, -10), (196, -10), (202, 40), (208, 130), (212, 230)], op=0.55)
    c.f("coluna_nucleo", SH_W, [(176, 226), (182, 90), (188, -10), (192, 90), (198, 226)], op=0.8)
    sparks(c, 188, 100, 18, 20, 60, 812, SH_L, 0.9)
    # dois ajoelhados atrás (menores), um de cada lado da coluna
    Jk = cultista.POSES["ajoelhado"]
    c.fig("cultista_b", cultista.pose("ajoelhado"), 142, 210, 0, 0.66)
    c.fig("cultista_c", cultista.pose("ajoelhado", head=(13, -97, 18)), 252, 224, 0, -0.8, 0.8)
    # o da frente: braços em V, levemente girado; mãos pegam a luz
    c.fig("cultista", cultista.pose("ritual"), 76, 274, 6, 1.36, guide=cultista.GUIDE["ritual"])
    c.save()


# =========================================================================== ACÓLITOS
def acolyte():
    """2 acólitos em sequência: o de trás solta a esfera de sombra das mãos; o raio salta para a mão do da frente
    (em estocada, grande) e dali parte para fora da carta — a corrente que dispara junto com o feitiço."""
    c = Card("acolyte")
    night(c, "#141a36", "#2e3c6a")
    # o cenário: arco de cripta com a janela gótica de luar (halo atrás da cabeça do da frente)
    c.b("parede", "#232a4a", [(-10, -10), (310, -10), (310, 300), (-10, 300)], mode="poly")
    stones(c, -10, -10, 310, 220, "#1a2040", 821, rows=7, cols=6, op=0.5)
    window(c, 184, 22, 84, 150, "#8eaad8", "#3a4262")
    c.b("chao", "#1e2238", [(-10, 214), (310, 206), (310, 300), (-10, 300)])
    stones(c, -10, 214, 310, 300, "#2c3252", 822, rows=2, cols=5, op=0.5)
    # acólito de trás (menor, à esquerda): esfera nas mãos
    Jb = cultista.POSES["orbe"]
    Mb = chain(T(40, 198), S(0.7))
    hb = (place(Mb, cultista.pontos(Jb)["mao_f"]) + place(Mb, cultista.pontos(Jb)["mao_n"])) / 2
    # da frente
    Jf = dict(cultista.POSES["disparar"], wr_f=(-26, -78))
    Mf = tmat(126, 268, -4, 1.42)
    hf_back = place(Mf, cultista.pontos(Jf)["mao_f"]); hf = place(Mf, cultista.pontos(Jf)["mao_n"])
    # corrente: esfera -> mão de trás do da frente (arco) ; mão da frente -> fora da carta
    arc = [hb, hb + (20, -40), hb * 0.4 + hf * 0.6 + (0, -70), hf + (-10, -40), hf + (0, -4)]
    bolt(c, jag(hb, hb * 0.5 + hf * 0.5 + (0, -66), 5, 7, 823) + jag(hb * 0.5 + hf * 0.5 + (0, -66), hf + (-4, -6), 5, 7, 824)[1:], 4.5, taper=0.8, name="corrente")
    bolt(c, jag(hf + (8, -2), (306, 70), 7, 9, 825), 8, taper=0.6, name="disparo")
    orb(c, hb[0], hb[1], 9, seed=826)
    burst(c, hf[0] + 6, hf[1] - 2, 18, 6, 7, SH_L, SH_W, 10, name="clarao")
    sparks(c, hf[0] + 6, hf[1], 12, 8, 30, 827, SH_L, 0.9)
    c.fig("acolito_b", cultista.pose("orbe", "acolito"), 40, 198, 0, 0.7)
    c.fig("acolito", cultista.pose("disparar", "acolito", wr_f=(-26, -78)), 126, 268, -4, 1.42, guide=cultista.GUIDE["disparar"])
    c.save()


# =========================================================================== RAIO SOMBRIO
def shadow_bolt():
    """O raio de sombra vem do lado do vilão (esquerda, perto) e FURA o escudo redondo do herói, que se inclina contra
    ele com os pés escorregando; estilhaços e o raio saindo pelas costas, atrás. Arco de pedra quebrado ao fundo."""
    c = Card("shadow_bolt")
    night(c, "#121830", "#3a4a7c")
    starfield(c, 120, -10, 310, 100, 16, 831)
    # o cenário: arco de pedra arruinado atrás à direita
    c.b("arco_pe", STONE_D, [(222, 230), (226, 96), (250, 92), (252, 230)], mode="poly")
    c.b("arco", STONE_D, [(226, 104), (236, 66), (262, 40), (300, 30), (312, 30), (312, 56), (290, 60), (264, 76), (252, 100)])
    c.b("arco_luz", STONE, [(226, 230), (226, 100), (234, 98), (232, 230)], mode="poly", op=0.8)
    stones(c, 224, 100, 252, 228, INK, 832, rows=6, cols=2, op=0.25)
    c.b("chao", "#232842", [(-10, 222), (310, 214), (310, 300), (-10, 300)])
    J = hero_l2.J("empurrado_escudo")
    M = tmat(176, 262, 0, 1.38)
    sc = place(M, A(J["wl"]) + (2, -10))  # centro do escudo
    d = A((1.0, -0.32)); d /= np.linalg.norm(d)
    p0 = sc - d * 210; p1 = sc + d * 190
    # parte de trás do raio (saindo pelas costas) + estilhaços do escudo, atrás da figura
    bolt(c, jag(sc, p1, 6, 6, 833), 10, taper=0.5, name="raio_saida")
    shards(c, sc[0] + 70, sc[1] - 26, 12, 4, 40, 834, "#33557d", a0=-1.2, a1=0.6, name="estilhaco")
    sparks(c, sc[0] + 60, sc[1] - 20, 14, 6, 40, 835, SH_L, 0.9, -1.0, 0.5)
    # rastro de poeira dos pés escorregando
    for i in range(5):
        x = 262 + i * 8
        c.f("poeira", "#5a5e7a", ellipse(x, 256 - i * 2, 7 - i, 3.5 - i * 0.4, 0, 8), op=0.6)
    c.fig("heroi", hero_l2.pose("empurrado_escudo"), 176, 262, 0, 1.38, guide=hero_l2.GUIDE["empurrado_escudo"])
    # o raio entrando: na frente do herói até o escudo, com o furo/estrela no ponto de impacto
    pin = jag(p0, sc, 7, 7, 836)
    raio = bolt_pcs(pin, 13, taper=0.75)
    imp = [Pc("furo", "raio", SH_L, [(sc[0] + math.cos(math.radians(a)) * (15 if k % 2 == 0 else 6), sc[1] + math.sin(math.radians(a)) * (15 if k % 2 == 0 else 6))
                                     for k, a in enumerate(np.linspace(0, 360, 17)[:-1])], mode="poly"),
           Pc("furo_centro", "raio", SH_W, ellipse(sc[0], sc[1], 5, 5, 0, 8), cls="inner")]
    c.fig("raio", raio + imp, 0, 0)
    c.save()


# =========================================================================== FAÍSCA ARCANA
def arcane_spark():
    """Visto de costas e de cima: três faíscas em sequência, cada uma maior que a anterior (a corrente cresce), descem em
    zigue-zague do canto do vilão e explodem nas costas do herói, que arqueia e abre os braços. Pilar quebrado à esquerda."""
    c = Card("arcane_spark")
    night(c, "#161a38", "#40406e")
    c.b("chao", "#2a2c4a", [(-10, 150), (310, 140), (310, 300), (-10, 300)])
    stones(c, -10, 150, 310, 300, "#3a3c5c", 841, rows=4, cols=5, op=0.45)
    # o cenário: pilar partido à esquerda (com o capitel caído)
    c.b("pilar", STONE, [(18, 236), (20, 70), (30, 62), (40, 74), (52, 66), (54, 236)], mode="poly")
    c.b("pilar_luz", STONE_L, [(20, 236), (20, 72), (28, 66), (30, 236)], mode="poly", op=0.8)
    for k in range(3):
        c.b(f"pilar_canal{k}", STONE_D, [(34 + k * 7, 230), (34 + k * 7, 80), (36 + k * 7, 80), (36 + k * 7, 230)], mode="poly", op=0.6)
    c.b("capitel", STONE, [(60, 246), (66, 228), (100, 224), (108, 240), (98, 252), (66, 254)])
    J = hero_l2.J("arqueado_costas")
    M = tmat(172, 268, 4, 1.36)
    back = place(M, (3, -112))  # entre as escápulas
    # sombra no chão
    c.b("sombra", "#1a1a30", ellipse(176, 262, 64, 10, 0, 12), op=0.6)
    # três faíscas crescendo: 1 (longe, pequena) -> 2 -> 3 (grande, no impacto)
    s1, s2 = A((268, 34)), A((96, 92))
    s3 = back
    for (a, b, w, sd) in [(s1, s2, 3.2, 842), (s2, s3, 5.5, 843)]:
        bolt(c, jag(a, b, 6, 10, sd), w, taper=0.9, name="salto")
    for (p, R_, sd) in [(s1, 9, 844), (s2, 15, 845)]:
        burst(c, p[0], p[1], R_, R_ * 0.35, 6, SH, SH_L, sd % 30, name="faisca")
        ring(c, p[0], p[1], R_ * 1.3, R_ * 1.3, 1.6, SH_L, 0.8, 0, 3, sd, name="faisca_anel")
    ring(c, s3[0], s3[1], 58, 44, 3.2, SH_L, 0.85, -10, 4, 846, name="impacto_anel")
    sparks(c, s3[0], s3[1], 22, 30, 76, 847, SH_W, 0.95)
    c.fig("heroi", hero_l2.pose("arqueado_costas"), 172, 268, 4, 1.36, guide=hero_l2.GUIDE["arqueado_costas"])
    # o estouro nas costas (figura própria, na frente do herói visto de costas)
    stp = lambda R_, r_, n, rot: [(math.cos(math.radians(rot + k * 180 / n)) * (R_ if k % 2 == 0 else r_), math.sin(math.radians(rot + k * 180 / n)) * (R_ if k % 2 == 0 else r_)) for k in range(2 * n)]
    c.fig("impacto", [Pc("estouro", "impacto", SH, stp(30, 10, 8, 8), mode="poly"),
                      Pc("estouro_luz", "impacto", SH_L, stp(17, 6, 8, 19), mode="poly", cls="inner"),
                      Pc("estouro_centro", "impacto", SH_W, ellipse(0, 0, 5, 5, 0, 8), cls="inner")], round(float(s3[0]), 3), round(float(s3[1]), 3))
    c.save()


# =========================================================================== ECO SOMBRIO
def shadow_echo():
    """O feitiço se repete: o sigilo original (no alto, apagando, contorno fantasma) e o seu eco de sombra (embaixo,
    aceso, maior) ligados por ondas de eco; do eco brota a chama de sombra no ponto escolhido, atrás do herói, que corre
    para a direita olhando por cima do ombro. Lápide inclinada como o elemento de cenário."""
    c = Card("shadow_echo")
    night(c, "#121832", "#3a3e72")
    starfield(c, -10, -10, 310, 110, 18, 851)
    c.b("chao", "#24284a", [(-10, 206), (310, 196), (310, 300), (-10, 300)])
    # o cenário: lápide inclinada à direita, atrás do herói
    c.b("lapide", STONE, list(ap(tmat(262, 214, 10), [(-20, 0), (-20, -52), (-14, -64), (0, -70), (14, -64), (20, -52), (20, 0)])))
    c.b("lapide_luz", STONE_L, list(ap(tmat(262, 214, 10), [(-20, 0), (-20, -52), (-14, -64), (-10, -66), (-12, 0)])), op=0.7)
    c.b("lapide_cruz", STONE_D, list(ap(tmat(262, 214, 10), [(-2, -56), (2, -56), (2, -26), (-2, -26)])), mode="poly")
    c.b("lapide_cruz2", STONE_D, list(ap(tmat(262, 214, 10), [(-9, -46), (9, -46), (9, -42), (-9, -42)])), mode="poly")
    # sigilo original (vertical, no alto à esquerda): fantasma, contorno só
    sigil(c, 70, 64, 40, 40, "#9a8ab8", "#cfc6e6", 0, 852, op=0.55, fill_op=0.3, name="original")
    # ondas de eco entre os dois
    for k in range(4):
        cx, cy = 70 + k * 6, 64 + k * 34
        pts = [(cx + math.cos(math.radians(a)) * (30 + k * 10), cy + math.sin(math.radians(a)) * (12 + k * 3)) for a in np.linspace(20, 160, 8)]
        c.f("onda_eco", SH_L, brush(pts, 3.2 - k * 0.4, 1.2), op=0.75 - k * 0.12)
    # o eco: mesmo sigilo, no chão, aceso e maior; chama de sombra brotando
    sigil(c, 96, 228, 78, 22, SH, SH_L, 0, 853, fill_op=0.55, name="eco")
    from cartas_d1 import flame
    for i, (x, h, w, lean) in enumerate([(54, 50, 26, -8), (140, 58, 26, 14), (72, 80, 36, -4), (122, 86, 36, 10), (98, 122, 50, 4)]):
        for k, (col, s_) in enumerate([(SH_D, 1.0), (SH, 0.72), (SH_L, 0.42)]):
            c.f("chama_sombra", col, flame(x, 232 - k * 3, h * s_, w * s_, lean * s_, 855 + i * 3 + k), op=0.95)
    sparks(c, 100, 150, 16, 10, 50, 854, SH_L, 0.9)
    c.fig("heroi", hero_l2.pose("virar_olhar"), 196, 262, 6, 1.34, guide=hero_l2.GUIDE["virar_olhar"])
    c.save()


# =========================================================================== MARCA SOMBRIA
def shadow_mark():
    """Câmera alta (o vilão olha de cima): o herói foge em diagonal para baixo-esquerda pelo chão de lajes em perspectiva,
    torcendo a cabeça para o feixe; no exato instante o feixe vindo do canto de cima à direita crava a marca no ombro
    direito. O círculo-alvo no chão o acompanha. Escorço desenhado (cabeça/ombros grandes, pés pequenos), escala uniforme."""
    c = Card("shadow_mark")
    c.b("chao", "#2a2e4a", RECT, mode="poly")
    # lajes em perspectiva: linhas convergindo para um ponto de fuga acima da carta, fiadas mais largas embaixo (perto)
    vp = A((150, -360))
    for k in range(-6, 8):
        xb = 150 + k * 52
        p1 = A((xb, 310)); t = (-20 - p1[1]) / (vp[1] - p1[1]); p0 = p1 + (vp - p1) * t
        c.b("junta_v", "#1c2036", brush([p0, p1], 1.6, 3.2), op=0.8)
    ys = [-10, 18, 44, 72, 104, 140, 182, 232, 300]
    for i, y in enumerate(ys[1:-1]):
        c.b("junta_h", "#1c2036", [(-10, y - 0.8 - i * 0.2), (310, y - 0.8 - i * 0.2), (310, y + 0.8 + i * 0.2), (-10, y + 0.8 + i * 0.2)], mode="poly", op=0.8)
    r = rng(864)
    for i in range(len(ys) - 1):
        for k in range(-6, 8):
            if r.random() < 0.35:
                y0, y1 = ys[i] + 3, ys[i + 1] - 3
                f = lambda y, xb: xb + (vp[0] - xb) * ((310 - y) / (310 - vp[1]))
                xa, xb2 = 150 + k * 52, 150 + (k + 1) * 52
                c.b("laje_luz", "#363c5e", [(f(y0, xa) + 3, y0), (f(y0, xb2) - 3, y0), (f(y1, xb2) - 3, y1), (f(y1, xa) + 3, y1)], mode="poly", op=0.7)
    # o cenário: degraus da cripta no canto de cima à esquerda
    c.b("degrau1", STONE_D, [(-10, -10), (120, -10), (104, 18), (60, 40), (-10, 52)])
    c.b("degrau2", STONE, [(-10, -10), (92, -10), (78, 10), (40, 26), (-10, 34)])
    c.b("degrau2_luz", STONE_L, [(-10, -10), (70, -10), (30, 10), (-10, 18)], op=0.7)
    # círculo-alvo em perspectiva (achatado, mais largo embaixo) + mira
    sigil(c, 150, 196, 116, 52, SH, SH_L, -4, 862, fill_op=0.42, name="alvo")
    for a in (0, 90, 180, 270):
        ca, sa = math.cos(math.radians(a - 4)), math.sin(math.radians(a - 4))
        p0 = A((150 + ca * 90, 196 + sa * 40)); p1 = A((150 + ca * 128, 196 + sa * 58))
        c.f("mira", SH, brush([p1, p0], 5, 1.5), op=0.9)
    J = hero_l2.J("fuga_alto")
    M = tmat(146, 226, 14, 1.24)
    c.b("sombra", "#16182c", ellipse(150, 222, 36, 11, 14, 12), op=0.65)
    sh_ = place(M, A(J["sr"]) + (0, -4))  # ombro direito (perto do feixe)
    # rastro da corrida (poeira) atrás, para cima-direita
    for i in range(5):
        q = place(M, (24 + i * 12, -10 - i * 8))
        c.f("poeira", "#5a5e7a", ellipse(q[0], q[1], 8 - i, 4 - i * 0.5, 14, 8), op=0.6)
    # o feixe: do canto de cima à direita até o ombro (cravando)
    bolt(c, jag(A((306, -14)), sh_, 5, 6, 865), 9, taper=0.45, name="feixe")
    c.fig("heroi", hero_l2.pose("fuga_alto"), 146, 226, 14, 1.24, guide=hero_l2.GUIDE["fuga_alto"])
    # a marca cravada no ombro (figura própria, na frente): selo violeta com estrela + raios curtos de impacto
    mk = []
    stp = [(math.cos(math.radians(k * 22.5)) * (17 if k % 2 == 0 else 10), math.sin(math.radians(k * 22.5)) * (17 if k % 2 == 0 else 10)) for k in range(16)]
    pts = [(math.cos(math.radians(-90 + k * 144)) * 7.5, math.sin(math.radians(-90 + k * 144)) * 7.5) for k in range(6)]
    mk.append(Pc("marca_brilho", "marca", SH_L, stp, mode="poly"))
    mk.append(Pc("marca", "marca", SH, ellipse(0, 0, 9.5, 9.5, 0, 12), cls="inner"))
    mk.append(Pc("marca_estrela", "marca", SH_W, brush(pts, 1.9, 1.9, per=2), cls="inner"))
    c.fig("marca", mk, round(float(sh_[0]), 3), round(float(sh_[1]), 3))
    sparks(c, sh_[0], sh_[1], 14, 18, 46, 863, SH_L, 0.9)
    c.save()


# =========================================================================== BIBLIOTECA PROIBIDA
def forbidden_library():
    """A biblioteca em destaque: estantes altas em arco, livros fugindo das prateleiras; no centro o cultista lê o grimório
    flutuante e comanda a revoada; um livro grande vem para a câmera (a carta a mais na mão)."""
    c = Card("forbidden_library")
    c.b("fundo", "#1a1e3a", RECT, mode="poly")
    # o cenário: estantes em arco (duas torres de prateleiras + arco no alto)
    c.b("arco", "#3a2a2a", [(-10, -10), (310, -10), (310, 300), (250, 300), (250, 96), (236, 56), (200, 26), (150, 16), (100, 26), (64, 56), (50, 96), (50, 300), (-10, 300)], mode="poly")
    c.b("vao", "#2a2e5a", [(50, 300), (50, 96), (64, 56), (100, 26), (150, 16), (200, 26), (236, 56), (250, 96), (250, 300)])
    c.b("vao_luz", "#4a4a86", ellipse(150, 120, 80, 90, 0, 16), op=0.6)
    r = rng(871)
    cols = ["#7a2a2a", "#2a4a6a", "#5a3a6a", "#3a5a3a", "#8a6a2a", "#4a2a3a"]
    for side, (x0, x1) in enumerate([(-10, 46), (254, 310)]):
        for row in range(6):
            y1 = 40 + row * 40; y0 = y1 - 32
            c.b(f"prateleira{side}{row}", "#5a3a2a", [(x0, y1), (x1, y1), (x1, y1 + 6), (x0, y1 + 6)], mode="poly")
            x = x0 + 2
            while x < x1 - 4:
                w = 4 + r.random() * 5; h = 22 + r.random() * 10
                if r.random() < 0.12:
                    x += w + 3; continue
                tilt = (r.random() - 0.5) * 6 if r.random() < 0.2 else 0
                c.b(f"lombada{side}{row}", cols[r.integers(len(cols))], list(ap(tmat(x + w / 2, y1, tilt), [(-w / 2, 0), (-w / 2, -h), (w / 2, -h), (w / 2, 0)])), mode="poly", op=0.95)
                x += w + 0.6
    c.b("chao", "#2a2440", [(50, 236), (250, 236), (310, 300), (-10, 300)], mode="poly")
    # púlpito
    c.b("pulpito", "#4a3024", [(160, 252), (166, 196), (154, 190), (204, 182), (198, 190), (190, 196), (194, 252)], mode="poly")
    c.b("pulpito_luz", "#6a4a34", [(166, 252), (170, 196), (176, 196), (174, 252)], mode="poly", op=0.8)
    # revoada de livros (fx atrás) saindo das estantes, em espiral até o grimório
    Jl = cultista.POSES["ler"]
    Mc = tmat(118, 250, 0, 1.2)
    bk = place(Mc, (48, -112))
    hand_up = place(Mc, cultista.pontos(Jl)["mao_f"])
    c.f("brilho", SH_L, ellipse(bk[0], bk[1] - 8, 40, 34, 0, 16), op=0.45)
    sparks(c, bk[0], bk[1] - 10, 16, 14, 46, 872, SH_W, 0.9)
    for k, (x, y, rot, s, col) in enumerate([(30, 70, -30, 1.0, "#2a4a6a"), (64, 34, -10, 0.9, "#7a2a2a"), (232, 44, 20, 1.0, "#5a3a6a"),
                                            (270, 96, 34, 1.1, "#3a5a3a"), (226, 150, 12, 0.9, "#8a6a2a")]):
        for q in cultista.closed_book(tmat(x, y, rot, s), col):
            c.fx.append(Pc(f"fx_livro{k}_{q.id}", "fx", q.fill, pts=q.pts, mode=q.mode))
        c.f("rastro", SH_L, brush([(x, y), (x * 0.6 + bk[0] * 0.4, y * 0.6 + bk[1] * 0.4 - 16), (bk[0], bk[1] - 14)], 3, 0.8), op=0.5)
    c.fig("cultista", cultista.pose("ler"), 118, 250, 0, 1.2, guide=cultista.GUIDE["ler"])
    c.fig("grimorio", cultista.book(T(0, 0)), round(float(bk[0]), 3), round(float(bk[1]), 3), -12, 1.25)
    # o livro grande vindo para a câmera (canto de baixo à direita, cortado)
    c.fig("livro", flying_book(), 238, 206, -16, 1.8)
    c.save()


def flying_book():
    """Livro aberto voando para a câmera: capas como asas, folhas em leque, runas acesas."""
    cov = "#5a2a6a"; page = "#efe4c8"
    return [Pc("capa_l", "livro", cov, [(0, 2), (-18, -4), (-30, -16), (-24, 6), (-4, 10)]),
            Pc("capa_r", "livro", cov, [(0, 2), (18, -6), (32, -20), (26, 4), (4, 10)]),
            Pc("folhas_l", "livro", page, [(0, 0), (-16, -8), (-26, -16), (-22, -2), (-3, 5)]),
            Pc("folhas_r", "livro", page, [(0, 0), (16, -10), (28, -20), (24, -2), (3, 5)]),
            Pc("folha_solta", "livro", page, [(2, -2), (8, -16), (18, -22), (12, -8)], cls="inner"),
            Pc("runa_l", "livro", SH, [(-18, -6), (-14, -9), (-10, -5), (-7, -7)], closed=False, cls="inner", sw=1.0),
            Pc("runa_r", "livro", SH, [(8, -7), (12, -11), (16, -7), (20, -10)], closed=False, cls="inner", sw=1.0),
            Pc("lombada", "livro", INK, [(0, 0), (0, 6)], closed=False, cls="inner", sw=0.8)]


# =========================================================================== APOCALIPSE ARCANO
def arcane_apocalypse():
    """O Lich em pessoa, de baixo para cima, braços erguidos: acima dele gira o redemoinho com os sigilos dos feitiços
    repetidos (raio, faísca, marca, eco), e dele chovem raios sobre a terra. Torre arruinada atrás; halo atrás do crânio."""
    c = Card("arcane_apocalypse")
    sky(c, "#1a0e30", "#3a3a78")
    # redemoinho: anéis grandes inclinados
    for k, (rx, ry, op) in enumerate([(150, 46, 0.5), (118, 36, 0.6), (86, 26, 0.7)]):
        ring(c, 150, 50, rx, ry, 4 - k * 0.6, SH_L if k else SH, op, -8, 4, 880 + k, name="redemoinho")
    c.f("redemoinho_luz", SH_L, ellipse(150, 50, 70, 22, -8, 16), op=0.4)
    # o cenário: torre arruinada à esquerda, morros
    c.b("morro", "#1c1838", [(-10, 210), (80, 196), (180, 206), (310, 190), (310, 300), (-10, 300)])
    c.b("torre", "#2a2a46", [(14, 214), (18, 92), (24, 86), (30, 96), (38, 80), (46, 92), (52, 84), (56, 214)], mode="poly")
    c.b("torre_luz", "#3e3e62", [(18, 214), (18, 94), (26, 90), (28, 214)], mode="poly", op=0.8)
    c.b("torre_janela", "#c080ff", [(30, 130), (38, 130), (38, 146), (30, 146)], mode="poly", op=0.9)
    # raios caindo do redemoinho sobre a terra (atrás)
    for i, (a, b, sd) in enumerate([((40, 60), (60, 200), 881), ((262, 56), (250, 196), 882), ((206, 40), (290, 150), 883)]):
        bolt(c, jag(a, b, 6, 9, sd), 4.5, taper=0.7, name="chuva")
        burst(c, b[0], b[1], 12, 4, 7, SH, SH_L, 0, name="queda")
    J = lichfig.POSES["conjurar"]
    M = tmat(150, 266, 0, 1.16)
    sk = place(M, J["head"][:2])
    hs = lichfig.hands(J)
    hl, hr = place(M, hs["f"]), place(M, hs["n"])
    # halo atrás do crânio
    disk(c, "halo", sk[0] + 2, sk[1] - 4, 34, "#c8b0ff", "#f2eaff")
    # sigilos dos feitiços repetidos girando no redemoinho (cada um com o seu ícone)
    for k, (x, y, r_) in enumerate([(56, 52, 17), (106, 32, 14), (196, 32, 14), (246, 54, 17), (150, 26, 12)]):
        sigil(c, x, y, r_, r_, SH, SH_L, k * 20, 890 + k * 7, fill_op=0.55, name=f"feitico{k}")
    bolt(c, [A((50, 46)), A((56, 52)), A((52, 56)), A((62, 60))], 2.4, taper=1.0, name="icone_raio")
    star(c, 106, 32, 8, 3, 5, SH_W, 0, 1.0, "icone_faisca")
    ring(c, 196, 32, 7, 7, 2.0, SH_W, 1.0, 0, 2, 897, name="icone_marca")
    for k in range(2):
        ring(c, 246, 54, 5 + k * 5, 5 + k * 5, 1.6, SH_W, 0.9 - k * 0.3, 0, 3, 898 + k, name="icone_eco")
    # fios de magia das mãos aos sigilos
    for h, tgt in ((hl, (56, 52)), (hr, (246, 54))):
        wisp(c, [h, h * 0.5 + A(tgt) * 0.5 + (0, -10), A(tgt)], 4, 1.2, SH_L, 0.75, "fio")
        orb(c, h[0], h[1], 7, seed=int(h[0]))
    mist(c, 252, "#6a5a9a", 884, 8, 0.5)
    c.fig("lich", lichfig.pose("conjurar", hs=1.35), 150, 266, 0, 1.16, guide=lichfig.GUIDE["conjurar"])
    c.save()


ALL = dict(cultists=cultists, acolyte=acolyte, shadow_bolt=shadow_bolt, arcane_spark=arcane_spark, shadow_echo=shadow_echo,
           shadow_mark=shadow_mark, forbidden_library=forbidden_library, arcane_apocalypse=arcane_apocalypse)

if __name__ == "__main__":
    for nm in (sys.argv[1:] or ALL):
        ALL[nm]()
        print("ok", nm)
