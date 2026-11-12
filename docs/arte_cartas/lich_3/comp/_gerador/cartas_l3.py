"""Composições do lote lich_3 (vilão Lich, almas e morte). Coordenadas de carta 300x420; janela 11..289 x 11..278;
fita y >= 261. Reaproveita (só leitura) Card (praga_3), sky/disk/rings (praga_2), dust/rng/RECT (praga_1),
flame/star (dragao_1), utilidades do lich_1 (night, mist, tomb, soul_fire, soul_stream, bone_fx, skull_fx, rim, front),
esqueleto/carnical (lich_1). Fichas novas: fantasma, golem (golem_sucata). Poses novas do herói: hero_l3.
Clima: noite azulada, osso, almas verde-espectrais, luz de recorte; SEM lua cheia atrás da figura (vitral, portal,
ampulheta, fogo do altar, névoa iluminada, olho da tempestade).
Uso: python cartas_l3.py [ids...]   (saída: LB_OUT; rascunho: LB_SCR)"""
import base  # noqa: F401
import sys, math
import numpy as np
from geom import *
from rat import mix
from cards import dust, rng, RECT
from cartas import sky, disk, rings
from cartas3 import Card, stones
from cartas_d1 import flame, star
from cartas_l1 import (night, mist, tomb, soul_fire, soul_stream, bone_fx, skull_fx, rim, front, sk_sil,
                       SOUL, SOUL_L, SOUL_D, MIST, STONE, STONE_D, STONE_L, EARTH, EARTH_L, INK)
import esqueleto as E
import carnical as G
import fantasma as FA
import golem as GO
import hero_l3

ELIX = "#d860f4"; ELIX_L = "#f4c8ff"
VIOLET = "#9a6aff"; VIOLET_L = "#d8c4ff"; VIOLET_D = "#4a2a8a"
BLOOD = "#d84a4a"; BLOOD_L = "#ff9a8a"
FOG_L = "#7a9cc0"


# =========================================================================== utilidades do lote
def glow(c, name, cx, cy, rx, ry, cols, ops=(0.25, 0.4, 0.6), fx=False):
    """Halo em camadas (fundo claro atrás da figura)."""
    add = c.f if fx else c.b
    for k, (col, op) in enumerate(zip(cols, ops)):
        s = 1 - k * 0.3
        add(f"{name}{k}", col, ellipse(cx, cy, rx * s, ry * s, 0, 16), op=op)


def elixir_drop(c, x, y, s=1.0, rot=0, op=0.95):
    M = tmat(x, y, rot, s)
    c.f("elixir", ELIX, list(ap(M, [(0, -6), (2.6, -1.6), (3.6, 1.6), (2.2, 4.2), (0, 5), (-2.2, 4.2), (-3.6, 1.6), (-2.6, -1.6)])), op=op)
    c.f("elixir_luz", ELIX_L, list(ap(M, ellipse(-1.2, 1.2, 0.9, 1.3, 0, 6))), op=op)


def soul_wisp(c, x, y, s, rot, name="alma_cranio", trail=None):
    """Alma em forma de crânio com rastro (cauda de névoa)."""
    if trail is not None:
        soul_stream(c, trail, 1.2 * s, 9 * s, op=0.6, name=name + "_rastro")
    M = tmat(x, y, rot, s)
    c.f(name, "#a8e4c4", d=xform_d("M-6 8 L-5.5 13 L5.5 13 L6 8 Z", M))
    c.f(name, SOUL_L, d=xform_d(E.SKULL_F, M))
    for sx in (-1, 1):
        c.f(name + "_orb", "#1e4a40", list(ap(M, ellipse(sx * 4.5, -2.4, 2.8, 2.6, 0, 7))))
    c.f(name + "_nariz", "#1e4a40", list(ap(M, [(0, 2), (-1.4, 4.6), (1.4, 4.6)])), mode="poly")


def front_stones(c, x0, y0, x1, y1, col, seed, rows=6, cols=6, op=0.45):
    """Juntas de pedra na frente das figuras (#enxame_frente), para parede que cobre parte de uma figura."""
    h = (y1 - y0) / rows; w = (x1 - x0) / cols
    for i in range(rows + 1):
        y = y0 + i * h
        front(c, f"junta_h{i}", col, [(x0, y), (x1, y)], mode="poly")
        c.front[-1].closed = False; c.front[-1].sw = 0.9; c.front[-1].op = op
        if i < rows:
            for k in range(cols + 1):
                x = x0 + (i % 2) * w / 2 + k * w
                if x0 < x < x1:
                    front(c, f"junta_v{i}_{k}", col, [(x, y), (x, y + h)], mode="poly")
                    c.front[-1].closed = False; c.front[-1].sw = 0.9; c.front[-1].op = op


def sparks(c, pts, col=SOUL_L, r=1.6, op=0.9, name="faisca"):
    for x, y in pts:
        c.f(name, col, ellipse(x, y, r, r, 0, 6), op=op)


# =========================================================================== FANTASMA
def ghost():
    c = Card("ghost")
    # interior de cripta escuro (o fantasma claro salta do escuro); vitral de vidro FUNDO (valor médio) atrás, à esquerda
    c.b("fundo", "#10141f", RECT, mode="poly")
    c.b("parede_luz", "#1a2236", [(-10, -10), (200, -10), (190, 240), (-10, 250)], op=0.8)
    vx, vy0, vy1, vw = 84, 22, 200, 96
    glow(c, "vitral_halo", vx, 110, 110, 130, ["#1e2c48", "#2a4064", "#3a5a80"], (0.5, 0.4, 0.35))
    arch = [(vx - vw / 2, vy1), (vx - vw / 2, vy0 + 60), (vx - vw * 0.42, vy0 + 28), (vx - vw * 0.22, vy0 + 6), (vx, vy0 - 4),
            (vx + vw * 0.22, vy0 + 6), (vx + vw * 0.42, vy0 + 28), (vx + vw / 2, vy0 + 60), (vx + vw / 2, vy1)]
    c.b("vitral_moldura", STONE_D, [(x + (7 if x > vx else -7 if x < vx else 0), y - (7 if y < vy1 else -7)) for x, y in arch], mode="cr")
    c.b("vitral", "#34507a", arch)
    for k, (pts, col) in enumerate([([(vx - 42, 196), (vx - 42, 124), (vx - 6, 124), (vx - 6, 196)], "#3e7a8a"),
                                    ([(vx + 6, 196), (vx + 6, 124), (vx + 42, 124), (vx + 42, 196)], "#5a4a96"),
                                    ([(vx - 42, 116), (vx - 42, 76), (vx - 6, 62), (vx - 6, 116)], "#6a8ab0"),
                                    ([(vx + 6, 116), (vx + 6, 62), (vx + 42, 76), (vx + 42, 116)], "#3a8a78")]):
        c.b(f"painel{k}", col, pts, mode="poly", op=0.85)
    for k, pts in enumerate([[(vx, 2), (vx, 200)], [(vx - 48, 120), (vx + 48, 120)], [(vx - 48, 160), (vx + 48, 160)],
                             [(vx - 30, 34), (vx, 62), (vx + 30, 34)], [(vx - 48, 80), (vx, 62), (vx + 48, 80)]]):
        c.b(f"chumbo{k}", "#161a26", pts, closed=False, sw=2.4)
    for k in range(4):
        a = math.radians(45 + k * 90)
        c.b(f"rosacea{k}", "#5aa0a8" if k % 2 else "#7a6ab8", ellipse(vx + math.cos(a) * 6, 46 + math.sin(a) * 6, 5, 5, 0, 8), op=0.95)
    c.b("raio_luz", "#6a90b8", [(vx - 48, 200), (vx + 48, 200), (vx + 110, 262), (vx - 10, 262)], mode="poly", op=0.2)
    c.b("chao", "#161c2c", [(-10, 238), (310, 232), (310, 300), (-10, 300)], mode="poly")
    c.b("chao_luz", "#2e4260", ellipse(vx + 50, 250, 80, 10, 0, 12), op=0.5)
    # parede de pedra da direita por onde ele atravessa
    c.b("parede", STONE_D, [(214, -10), (310, -10), (310, 300), (206, 300), (208, 150)], mode="poly")
    stones(c, 208, -10, 310, 300, "#1a1e2a", 101, rows=12, cols=3, op=0.55)
    c.b("parede_quina", STONE, [(206, 300), (208, 150), (214, -10), (220, -10), (216, 150), (214, 300)], mode="poly", op=0.8)
    # o fantasma: mergulhando para fora da parede, para a esquerda e para baixo, mãos à frente (pose 'atravessar' espelhada)
    J1 = FA.J("atravessar", head=(50, -30, -20, 1.55), turn=0.5, jaw=8, hair=180, hl=1.0, spread=16,
              wl=(78, -46), ebl=-1, hdl=-20, hml="reach", hsl=1.2, wr=(86, -8), ebr=1, hdr=16, hmr="reach", hsr=1.7)
    p1 = FA.ghost(J1)
    M = c.fig("fantasma", p1, 170, 136, -30, -1.26, 1.26)
    # ondas na pedra onde o corpo sai (atravessar) + motas de alma
    ey = float(ap(M, [(-60, 2)])[0][1]); ex = 212.0
    for k, rr in enumerate((24, 36, 50)):
        pts = [(ex + math.cos(math.radians(a)) * rr * 0.35, ey + math.sin(math.radians(a)) * rr) for a in np.linspace(105, 255, 9)]
        c.f("onda_parede", SOUL_L if k == 0 else SOUL, brush(pts, 3.4 - k * 0.6, 1.0), op=0.85 - k * 0.2)
    sparks(c, [(234, 70), (250, 150), (226, 210), (40, 230), (130, 226), (24, 60)], SOUL_L, 1.6, 0.85)
    # rastro frio do Medo: fiapos violeta atrás das mãos
    for k, (pts, w0) in enumerate([([(64, 96), (44, 84), (26, 92), (14, 78)], 5), ([(66, 128), (46, 142), (30, 136), (16, 150)], 4)]):
        c.f("medo", "#6a5aa8", brush(pts, w0, 1.2), op=0.6)
    mist(c, 246, 103, n=5, op=0.35, col=MIST)
    # a parte da cauda que ainda está dentro da pedra fica coberta pela parede
    front(c, "parede_frente", STONE_D, [(214, -10), (310, -10), (310, 300), (212, 300), (214, 150)], mode="poly")
    front_stones(c, 214, -10, 310, 300, "#1a1e2a", 101, rows=12, cols=3, op=0.55)
    c.guide = list(ap(M, FA.GUIDE["atravessar"]))
    c.save()


# =========================================================================== GOLEM DE SUCATA
def scrap_golem():
    c = Card("scrap_golem")
    night(c, "#0a1022", "#2a3a5c")
    # névoa iluminada no horizonte (o fundo claro atrás dos ombros e da cabeça)
    c.b("nevoa_luz", FOG_L, [(-10, 110), (60, 94), (150, 88), (240, 98), (310, 90), (310, 196), (-10, 200)], op=0.7)
    c.b("nevoa_luz2", "#c4d8ea", [(-10, 140), (90, 120), (200, 128), (310, 116), (310, 176), (-10, 182)], op=0.65)
    # o cenário: catapulta quebrada no campo de batalha (esquerda, atrás)
    c.b("catapulta_base", "#2a2a34", [(14, 206), (96, 200), (98, 214), (12, 220)], mode="poly")
    c.b("catapulta_braco", "#2a2a34", [(40, 204), (44, 200), (100, 120), (106, 124)], mode="poly")
    c.b("catapulta_roda", "#2a2a34", ellipse(26, 214, 10, 10, 0, 10))
    c.b("catapulta_roda2", "#2a2a34", ellipse(86, 210, 9, 9, 0, 10))
    c.b("catapulta_concha", "#2a2a34", ellipse(103, 118, 8, 5, -50, 8))
    for k, (x, a) in enumerate([(140, -20), (166, 12), (272, -30), (290, 16)]):
        c.b(f"lanca{k}", "#2a2a34", list(ap(tmat(x, 214, a), [(-1, 0), (-1, -46), (0, -52), (1, -46), (1, 0)])), mode="poly")
    c.b("chao", "#22283a", [(-10, 216), (120, 208), (310, 214), (310, 300), (-10, 300)])
    mist(c, 222, 111, n=5, op=0.35)
    # os mortos por perto: monte de ossos à esquerda sendo SUGADO para a fornalha (corrente verde com ossos voando)
    for j, (dx, dy, L, a) in enumerate([(-8, 0, 16, 10), (6, -2, 14, -30), (0, -6, 12, 70), (10, 2, 15, 160)]):
        bone_fx(c, 40 + dx, 248 + dy, L, a, 2.2, col="#cfc3a2")
    skull_fx(c, 42, 238, 0.7, -20, col="#cfc3a2")
    soul_stream(c, [(40, 236), (34, 200), (60, 172), (100, 160), (126, 156)], 9, 2.5, op=0.65)
    for k, (x, y, L, a) in enumerate([(36, 214, 12, 40), (52, 182, 12, -30), (84, 164, 10, 80)]):
        bone_fx(c, x, y, L, a, 2.2, col="#cfc3a2")
    sparks(c, [(20, 200), (70, 150), (286, 120), (270, 200)], SOUL_L)
    # fumaça verde da chaminé (atrás)
    for k, (x, y, r_) in enumerate([(84, 22, 11), (70, 8, 14), (52, -4, 17)]):
        c.f("fumaca", "#4a8a74", blob(x, y, r_, 700 + k, 9, 0.25), op=0.55)
    # o golem: avança para a câmera e para a direita, ergue um esqueleto morto pelo braço para jogá-lo na fornalha aberta
    p1 = GO.pose("erguer_morto")
    MG = tmat(118, 274, -3, 1.0)
    fist = ap(MG, [(128, -152)])[0]
    # o esqueleto agarrado pelo pulso (mole, pendurado) + a alma dele já sendo puxada para a fornalha
    JS = E.J("golpear", view="f", hip=(2, -72), neck=(-2, -123), head=(-14, -134, 34), jaw=7, glow=False, far="l",
             al=(-2, -6), tl=(-6, 2), ar=(12, -2), tr=(14, 6), kbl=1, kbr=1,
             wr=(6, -168), ebr=-1, hmr="grip", hdr=-90, wl=(-18, -84), ebl=1, hml="open", hdl=100, sword=None, rag=None)
    ps = E.skeleton(JS)
    s_ = 0.66
    MS = chain(T(*fist), R(-16), S(s_), T(-6, 168))
    ox, oy = ap(MS, [(0, 0)])[0]
    c.fig("esqueleto", ps, round(float(ox), 3), round(float(oy), 3), -16, s_)
    furn = ap(MG, [(10, -126)])[0]
    soul_stream(c, [(fist[0] - 2, fist[1] + 64), (fist[0] - 24, fist[1] + 50), (furn[0] + 40, furn[1] + 14), (furn[0] + 10, furn[1] + 4)], 8, 2.5, op=0.75)
    M = c.fig("golem", p1, 118, 274, -3, 1.0)
    rim(c, p1, M, 2.4, -0.8, "#bfe8ff", 0.6)
    c.guide = list(ap(M, GO.GUIDE["erguer_morto"]))
    c.save()


# =========================================================================== BANQUETE DE ALMAS
def soul_feast():
    c = Card("soul_feast")
    night(c, "#0c1226", "#34486e")
    # o portal / a bocarra espectral (fundo claro, foco): crânio enorme de luz verde inspirando as almas
    cx, cy = 150, 54
    glow(c, "portal", cx, cy + 10, 124, 86, ["#1e4a52", "#2e7a70", "#5ab89a"], (0.5, 0.45, 0.4))
    c.b("chao", "#1e2638", [(-10, 214), (120, 206), (310, 212), (310, 300), (-10, 300)])
    c.b("circulo", SOUL_D, ellipse(150, 246, 132, 26, 0, 18), op=0.3)
    mist(c, 214, 121, n=5, op=0.3)
    M = tmat(cx, cy, 0, 4.0)
    c.f("bocarra", "#c8f4dc", d=xform_d(E.SKULL_F, M), op=0.92)
    for sx in (-1, 1):
        c.f("bocarra_orb", "#1e4a40", list(ap(M, ellipse(sx * 4.6, -3, 3.0, 2.8, sx * 12, 9))), op=0.9)
        c.f("bocarra_olho", SOUL, list(ap(M, ellipse(sx * 4.6, -2.8, 1.2, 1.2, 0, 7))), op=1.0)
    c.f("bocarra_nariz", "#1e4a40", list(ap(M, [(0, 1.6), (-1.6, 4.6), (1.6, 4.6)])), mode="poly", op=0.9)
    c.f("bocarra_mand", "#a8e4c4", list(ap(M, [(-7.6, 8), (7.6, 8), (8.4, 16), (4, 21), (-4, 21), (-8.4, 16)])), op=0.9)
    c.f("bocarra_boca", "#0e2a28", list(ap(M, [(-5.6, 7.6), (5.6, 7.6), (6, 13), (3, 17), (-3, 17), (-6, 13)])), op=0.95)
    for i, x in enumerate((-4, -1.4, 1.4, 4)):
        c.f("bocarra_dente", "#e8fff4", list(ap(M, [(x - 1, 7.4), (x, 10), (x + 1, 7.4)])), mode="poly")
    # os monstros sacrificados em volta do herói: esqueletos se desfazendo em chamas de alma
    run = sk_sil("golpear", jaw=4)
    for k, (x, y, s, fl, rot) in enumerate([(50, 256, 0.72, False, 8), (254, 254, 0.7, True, -8), (214, 210, 0.4, True, -4), (88, 210, 0.38, False, 6)]):
        c.sil(run, x, y, rot, s, flip=fl, fill="#c8bc9c" if s > 0.5 else "#8a8678", op=0.95 if s > 0.5 else 0.8)
        soul_fire(c, x + (6 if fl else -6) * s, y - 60 * s, 60 * s, 40 * s, 0, 300 + k * 9, op=0.8)
    # quatro correntes de alma subindo para a boca (com elixir voltando: gotas violeta)
    for k, pts in enumerate([[(40, 206), (36, 150), (70, 112), (128, 104)], [(262, 202), (268, 146), (232, 112), (172, 104)],
                             [(92, 184), (102, 146), (136, 118)], [(210, 184), (200, 146), (164, 118)]]):
        soul_stream(c, pts, 9 if k < 2 else 6, 2.5, op=0.7)
    for k, (x, y, rot) in enumerate([(48, 166, -20), (60, 124, 10), (254, 160, 20), (240, 122, -10), (110, 150, 0), (190, 150, 0)]):
        elixir_drop(c, x, y, 1.15, rot)
    sparks(c, [(20, 130), (284, 128), (150, 132), (30, 230), (276, 222)], SOUL_L)
    # o herói: agachado no meio do banquete, capa sugada para cima
    hp = hero_l3.pose("agachar_olhar")
    M = c.fig("heroi", hp, 152, 272, 0, 0.94)
    rim(c, hp, M, 0, -2.6, "#d8fff0", 0.7)  # luz verde vindo de cima
    c.guide = list(ap(M, hero_l3.GUIDE["agachar_olhar"])) + [(cx - 6, cy + 30)]
    c.save()


# =========================================================================== COLHEITA DE ALMAS
def hourglass(c, x, y, h, w):
    """Ampulheta espectral (cenário): armação de osso escuro, vidro claro brilhando, areia de almas verdes."""
    top, bot = y - h / 2, y + h / 2
    glow(c, "ampulheta_halo", x, y, w * 1.5, h * 0.75, ["#1e4a52", "#2e6a6a", "#5aa898"], (0.45, 0.4, 0.35))
    glass = [(x - w * 0.42, top + 8), (x + w * 0.42, top + 8), (x + w * 0.4, top + h * 0.22), (x + w * 0.08, y - 3), (x + w * 0.08, y + 3),
             (x + w * 0.4, bot - h * 0.22), (x + w * 0.42, bot - 8), (x - w * 0.42, bot - 8), (x - w * 0.4, bot - h * 0.22),
             (x - w * 0.08, y + 3), (x - w * 0.08, y - 3), (x - w * 0.4, top + h * 0.22)]
    c.b("ampulheta_vidro", "#cfeee4", glass, op=0.92)
    c.b("ampulheta_areia_cima", SOUL_D, [(x - w * 0.3, top + h * 0.26), (x + w * 0.3, top + h * 0.26), (x + w * 0.06, y - 4), (x - w * 0.06, y - 4)], op=0.85)
    c.b("ampulheta_fio", SOUL, [(x - 1.2, y - 4), (x + 1.2, y - 4), (x + 1.2, bot - 22), (x - 1.2, bot - 22)], mode="poly", op=0.95)
    c.b("ampulheta_areia_baixo", SOUL, [(x - w * 0.4, bot - 9), (x - w * 0.22, bot - 18), (x, bot - 24), (x + w * 0.22, bot - 18), (x + w * 0.4, bot - 9)], op=0.9)
    for k, yy in enumerate((top, bot)):
        c.b(f"ampulheta_tampa{k}", "#3a3040", [(x - w * 0.56, yy - 5), (x + w * 0.56, yy - 5), (x + w * 0.56, yy + 5), (x - w * 0.56, yy + 5)], mode="poly")
    for k, sx in enumerate((-1, 1)):
        c.b(f"ampulheta_haste{k}", "#cfc3a2", [(x + sx * w * 0.5 - 2.4, top + 4), (x + sx * w * 0.5 + 2.4, top + 4), (x + sx * w * 0.5 + 2, bot - 4),
                                                (x + sx * w * 0.5 - 2, bot - 4)], mode="poly")
    skull_fx(c, x, top - 12, 0.9, 0, col="#cfc3a2", name="ampulheta_cranio")


def soul_harvest():
    c = Card("soul_harvest")
    night(c, "#0e1430", "#3e5278")
    hourglass(c, 222, 84, 128, 66)
    c.b("chao", "#222a3c", [(-10, 226), (130, 218), (310, 226), (310, 300), (-10, 300)])
    mist(c, 230, 131, n=5, op=0.35)
    # o golpe: arco branco da espada descendo (atrás) + o esqueleto se desmontando e a alma subindo para a ampulheta
    c.f("arco_golpe", "#f4f8ee", brush([(120, 60), (176, 82), (214, 122), (236, 168)], 1.4, 10), op=0.8)
    sx_, sy_ = 236, 178
    soul_stream(c, [(sx_ - 2, sy_ - 6), (sx_ + 18, sy_ - 30), (sx_ + 4, sy_ - 56), (sx_ - 12, sy_ - 74), (222, 150)], 8, 2, op=0.75)
    elixir_drop(c, 206, 128, 1.4, -12)
    elixir_drop(c, 252, 118, 1.1, 14)
    for k, (dx, dy, L, a) in enumerate([(-14, -10, 16, 30), (22, -8, 14, -50), (28, 12, 12, 70), (-20, 14, 15, -20), (34, -24, 11, 100)]):
        bone_fx(c, sx_ + dx, sy_ + dy, L, a, 2.2)
    for k, (dx, dy, a) in enumerate([(-24, -22, 60), (34, -4, 120), (-26, 8, 170), (14, -30, 90)]):
        c.f("risco", "#e6d8b8", wedge(sx_ + dx * 0.4, sy_ + dy * 0.4, sx_ + dx * 1.3, sy_ + dy * 1.3, 1.4), mode="poly", op=0.7)
    # o esqueleto atingido: tomba para trás, crânio saltando do pescoço, braços jogados
    J2 = E.J("golpear", hip=(4, -70), neck=(16, -118), head=(30, -140, 40), jaw=6, far="l",
             al=(-30, 0), tl=(-40, 0), ar=(30, -4), tr=(40, -2),
             wr=(52, -136), ebr=-1, hmr="open", hdr=-60, wl=(-40, -126), ebl=1, hml="claw", hdl=-150, sword=None, rag=None)
    p2 = E.skeleton(J2)
    c.fig("esqueleto", p2, 238, 262, 14, -0.98, 0.98)
    # o herói: golpe de duas mãos descendo
    hp = hero_l3.pose("golpe_alto")
    M = c.fig("heroi", hp, 80, 266, -4, 1.22)
    c.guide = list(ap(M, hero_l3.GUIDE["golpe_alto"]))
    c.save()


# =========================================================================== DRENO DE VIDA
def life_drain():
    c = Card("life_drain")
    night(c, "#0e1228", "#3a466c")
    c.b("nevoa_luz", FOG_L, [(-10, 140), (80, 126), (180, 132), (310, 120), (310, 200), (-10, 206)], op=0.5)
    c.b("nevoa_luz2", "#b4c8dc", [(120, 150), (200, 138), (310, 142), (310, 178), (130, 182)], op=0.45)
    # o cenário: coluna quebrada da cripta (esquerda)
    c.b("coluna", STONE_D, [(12, 240), (14, 70), (20, 58), (30, 64), (40, 52), (46, 60), (44, 240)], mode="poly")
    c.b("coluna_luz", STONE, [(36, 240), (38, 64), (44, 60), (44, 240)], mode="poly", op=0.8)
    for k, y in enumerate((100, 150, 200)):
        c.b(f"coluna_junta{k}", "#1a1e2a", [(14, y), (44, y + 2)], closed=False, sw=1.2, op=0.7)
    c.b("coluna_base", STONE, [(4, 248), (6, 236), (52, 236), (54, 248)], mode="poly")
    c.b("chao", "#1e2436", [(-10, 232), (140, 226), (310, 232), (310, 300), (-10, 300)])
    mist(c, 236, 141, n=5, op=0.35)
    # sombra (dano de Sombra): poça violeta-escura sob o herói com tentáculos subindo
    c.b("poca_sombra", VIOLET_D, ellipse(110, 256, 64, 12, 0, 14), op=0.7)
    for k, pts in enumerate([[(64, 256), (56, 226), (66, 198)], [(160, 256), (170, 230), (162, 206)], [(86, 258), (74, 236)]]):
        c.f("tentaculo", "#3a2470", brush(pts, 6, 1.2), op=0.8)
    # a vida arrancada do peito: corrente vermelha que vira verde e cura o carniçal
    MH = tmat(98, 264, 0, 1.14)
    hx, hy = ap(MH, [(-4, -76)])[0]
    c.f("vida", BLOOD, brush([(hx, hy), (hx + 6, hy - 50), (hx + 22, hy - 86), (150, 58), (182, 56)], 16, 8), op=0.85)
    c.f("vida_luz", BLOOD_L, brush([(hx + 2, hy - 4), (hx + 8, hy - 50), (hx + 24, hy - 84), (150, 60), (176, 58)], 6, 2.5), op=0.8)
    # o brilho no peito (de onde a vida é arrancada) fica na frente do herói
    front(c, "peito_brilho", BLOOD_L, ellipse(hx, hy, 7, 6, 0, 10), op=0.95)
    front(c, "peito_jorro", BLOOD, brush([(hx, hy), (hx + 3, hy - 16), (hx + 6, hy - 34)], 12, 9), op=0.9)
    soul_stream(c, [(174, 56), (210, 60), (234, 92), (242, 126)], 11, 4, op=0.85)
    for k, (x, y) in enumerate([(132, 96), (106, 84), (160, 48), (148, 78)]):
        c.f("gota_vida", BLOOD_L, ellipse(x, y, 2.2, 1.6, -30, 7), op=0.9)
    # cura: cruzes verdes e halo em volta do carniçal
    glow(c, "cura", 246, 190, 54, 70, [SOUL_D, SOUL, SOUL_L], (0.25, 0.25, 0.2), fx=True)
    for k, (x, y, s) in enumerate([(206, 160, 1.0), (284, 168, 0.8), (220, 226, 0.8), (276, 222, 1.0), (262, 120, 0.7)]):
        c.f("cruz_cura", SOUL_L, list(ap(tmat(x, y, 0, s), [(-1.6, -6), (1.6, -6), (1.6, -1.6), (6, -1.6), (6, 1.6), (1.6, 1.6), (1.6, 6), (-1.6, 6),
                                                              (-1.6, 1.6), (-6, 1.6), (-6, -1.6), (-1.6, -1.6)])), mode="poly", op=0.9)
    # o morto-vivo curado: carniçal de braços abertos sorvendo a vida (pose 'uivar' da ficha), espelhado
    J2 = dict(G.POSES["uivar"]); J2.update(head=(2, -112, 18), jaw=9)
    p2 = G.ghoul(J2)
    c.fig("carnical", p2, 246, 258, -6, -1.04, 1.04)
    # o herói: ajoelhado, arqueado, a vida saindo do peito
    hp = hero_l3.pose("arrancado")
    M = c.fig("heroi", hp, 98, 264, 0, 1.14)
    rim(c, hp, M, 2.4, -0.4, "#ffb0a0", 0.6)
    c.guide = list(ap(M, hero_l3.GUIDE["arrancado"])) + [(130, 70), (180, 56), (242, 126)]
    c.save()


# =========================================================================== RITUAL PROFANO
def profane_ritual():
    c = Card("profane_ritual")
    c.b("fundo", "#141428", RECT, mode="poly")
    c.b("fundo_luz", "#24244a", [(80, -10), (310, -10), (310, 230), (90, 230)], op=0.8)
    # coluna de fogo violeta do altar (fundo claro atrás do sacrificado)
    ax, ay = 196, 196
    glow(c, "fogo_halo", ax, 110, 110, 130, ["#3a2a6a", "#6a4aaa", "#a888e0"], (0.45, 0.4, 0.35))
    c.b("chao", "#1c1c30", [(-10, 210), (310, 204), (310, 300), (-10, 300)], mode="poly")
    # círculo ritual no chão (perspectiva) + glifos
    c.b("circulo", VIOLET, ellipse(ax, 236, 108, 22, 0, 18), op=0.35)
    for k, rr in enumerate((104, 84)):
        pts = [(ax + math.cos(math.radians(a)) * rr, 236 + math.sin(math.radians(a)) * rr * 0.21) for a in np.linspace(0, 340, 14)]
        c.b(f"circulo_anel{k}", VIOLET_L, pts, closed=False, sw=1.6 - k * 0.4, op=0.8)
    star_pts = [(ax + math.cos(math.radians(-90 + k * 144)) * 80, 236 + math.sin(math.radians(-90 + k * 144)) * 17) for k in range(6)]
    c.b("pentagrama", VIOLET_L, star_pts, closed=False, sw=1.0, op=0.6, mode="poly")
    # o cenário: altar de pedra com crânios entalhados
    c.b("altar", STONE, [(146, 240), (148, 196), (244, 190), (248, 236)], mode="poly")
    c.b("altar_topo", STONE_L, [(140, 198), (150, 186), (250, 182), (254, 194)], mode="poly")
    c.b("altar_sombra", STONE_D, [(200, 238), (202, 194), (248, 190), (248, 236)], mode="poly", op=0.8)
    for k, x in enumerate((166, 196, 226)):
        skull_fx(c, x, 216, 0.6, 0, col="#3a3a4a", name="altar_entalhe")
    # chamas violeta-verdes consumindo o sacrificado + a alma arrancada subindo e se partindo em 3 runas (3 feitiços)
    for k, (dx, h, w, ln) in enumerate([(-30, 60, 34, -10), (28, 66, 36, 10), (0, 90, 44, 0)]):
        for j, col in enumerate([VIOLET_D, VIOLET, VIOLET_L]):
            s = 1 - j * 0.3
            c.f("fogo_violeta", col, flame(ax + dx, 192 - j * 3, h * s, w * s, ln * s, 500 + k * 7 + j), op=0.85)
    soul_stream(c, [(ax, 150), (ax - 6, 120), (ax + 4, 92), (ax, 70)], 10, 3, op=0.8)
    for k, (x, y) in enumerate([(ax - 54, 48), (ax, 30), (ax + 54, 48)]):
        soul_stream(c, [(ax, 76), ((ax + x) / 2, (76 + y) / 2 + 6), (x, y + 8)], 4, 1.6, op=0.6)
        c.f("runa_halo", VIOLET, ellipse(x, y, 14, 14, 0, 12), op=0.45)
        c.f("runa_disco", VIOLET_L, ellipse(x, y, 9.5, 9.5, 0, 12), op=0.95)
        glyph = [(0, -6), (4, 0), (0, 6), (-4, 0)] if k != 1 else [(0, -6.5), (5.5, 4), (-5.5, 4)]
        c.f("runa", VIOLET_D, list(ap(tmat(x, y, 0), glyph)), closed=True, mode="poly", op=0.95)
        c.f("runa_risco", VIOLET_D, [(x, y - 7), (x, y + 7)], closed=False, sw=1.2, op=0.9)
    sparks(c, [(150, 150), (248, 140), (130, 96), (262, 88), (172, 60), (222, 62)], VIOLET_L, 1.6)
    # o sacrificado: esqueleto preso ao altar (da cintura para cima), arqueado para trás, a alma saindo do peito
    J2 = E.J("erguer", hip=(2, 4), neck=(-8, -42), head=(-16, -56, -40), jaw=8, far="r", glow=True,
             wr=(34, -60), ebr=1, hmr="open", hdr=-40, wl=(-42, -50), ebl=-1, hml="claw", hdl=-150)
    p2 = E.skeleton(J2)
    c.fig("sacrificado", p2, 198, 192, 6, 1.1)
    # o herói: caído sentado no chão, espada erguida para o altar
    hp = hero_l3.pose("sentado")
    M = c.fig("heroi", hp, 66, 262, 0, 1.3)
    rim(c, hp, M, 2.4, -0.8, VIOLET_L, 0.7)
    c.guide = list(ap(M, hero_l3.GUIDE["sentado"])) + [(ax, 150), (ax, 70)]
    c.save()


# =========================================================================== TÚMULO ABERTO
def open_grave():
    c = Card("open_grave")
    night(c, "#0e1430", "#3e5278")
    c.b("nevoa_luz", FOG_L, [(-10, 128), (70, 116), (170, 124), (310, 110), (310, 196), (-10, 200)], op=0.55)
    c.b("nevoa_luz2", "#b8d0e4", [(130, 140), (220, 126), (310, 132), (310, 168), (140, 172)], op=0.5)
    c.b("cerca", "#1e2434", [(-10, 186), (310, 176), (310, 182), (-10, 192)], mode="poly", op=0.8)
    for k in range(12):
        x = -4 + k * 28
        c.b(f"cerca_haste{k}", "#1e2434", [(x - 1.4, 192), (x - 1.4, 160), (x, 154), (x + 1.4, 160), (x + 1.4, 190)], mode="poly", op=0.8)
    c.b("chao", "#232a3c", [(-10, 216), (140, 210), (310, 216), (310, 300), (-10, 300)])
    mist(c, 220, 151, n=5, op=0.35)
    # o cenário: lápide rachada inclinando sobre a cova que explode
    tomb(c, "lapide", 254, 212, 58, 112, 14, broken=True)
    c.b("cova", "#14161e", [(140, 254), (170, 232), (250, 230), (290, 250), (250, 262), (160, 264)])
    # terra e pedras voando da cova (atrás das figuras) + clarão verde saindo do buraco
    glow(c, "cova_brilho", 214, 236, 70, 26, [SOUL_D, SOUL, SOUL_L], (0.35, 0.3, 0.3), fx=True)
    r = rng(161)
    for k in range(14):
        a = math.radians(-160 + r.random() * 140); d = 30 + r.random() * 60
        x = 214 + math.cos(a) * d; y = 232 + math.sin(a) * d * 0.9
        c.f("terra", "#4a4234" if k % 3 else "#6a6050", blob(x, y, 2.4 + r.random() * 3.4, 1600 + k, 7, 0.3), op=0.95)
    soul_stream(c, [(196, 236), (184, 200), (196, 170), (186, 140)], 7, 1.5, op=0.6)
    soul_stream(c, [(250, 236), (266, 200), (256, 168)], 6, 1.5, op=0.6)
    # dois esqueletos rompendo a terra: um grande agarrando para o herói, outro saindo atrás (2 esqueletos = a carta)
    J3 = E.J("erguer", hip=(4, 8), head=(-4, -62, 10), jaw=4, glow=False, wr=(30, -84), hdr=-80, wl=(-40, -20), hml="claw", hdl=-170)
    p3 = E.skeleton(J3)
    for q in p3:
        if q.fill == E.PAL["bone"]:
            q.fill = "#cfc3a2"
    c.fig("esqueleto2", p3, 274, 250, 10, -0.8, 0.8)
    J2 = E.J("erguer", hip=(6, 6), neck=(-6, -44), head=(-14, -60, -24), jaw=8, far="l", glow=True,
             wr=(-62, -62), ebr=-1, hmr="claw", hdr=-150, hsr=1.6, wl=(30, -8), ebl=1, hml="flat", hdl=10)
    p2 = E.skeleton(J2)
    M2 = c.fig("esqueleto", p2, 204, 254, -4, 1.36)
    front(c, "borda_cova", "#3a3428", [(130, 262), (150, 248), (190, 244), (236, 248), (262, 254), (300, 256), (300, 290), (130, 290)])
    front(c, "torrao1", "#4a4234", blob(176, 248, 7, 1701, 7, 0.3))
    front(c, "torrao2", "#4a4234", blob(232, 250, 8, 1702, 7, 0.3))
    # o herói: saltando para trás no ar
    hp = hero_l3.pose("salto_tras")
    M = c.fig("heroi", hp, 92, 230, -10, 1.04)
    c.f("sombra_heroi", "#10141e", ellipse(84, 256, 32, 5, 0, 10), op=0.6)
    dust(c, 84, 254, 20, 10, "#5a5a64", 163, sz=(1.5, 3.2), op=0.7)
    c.guide = list(ap(M, hero_l3.GUIDE["salto_tras"]))
    c.guide = list(ap(M2, [(30, -8), (0, 6), (-6, -44), (-30, -58), (-62, -62)]))
    c.save()


# =========================================================================== TEMPESTADE DE ALMAS
def soul_storm():
    c = Card("soul_storm")
    # câmera alta: o chão ocupa a carta toda; o OLHO da tempestade é o fundo claro sob o herói
    c.b("chao", "#252c3e", RECT, mode="poly")
    c.b("chao_luz", "#3a4660", [(-10, -10), (310, -10), (310, 70), (150, 100), (-10, 80)], op=0.6)
    cx, cy = 150, 176
    glow(c, "olho", cx, cy, 120, 74, ["#1e4a52", "#2e7a70", "#7ac8a8"], (0.5, 0.45, 0.45))
    c.b("olho_centro", "#c8f4dc", ellipse(cx, cy + 6, 46, 24, 0, 14), op=0.55)
    # o cenário: anel de lápides tombadas em volta (vistas de cima, em perspectiva)
    for k, a in enumerate(np.linspace(200, 340, 6)):
        x = cx + math.cos(math.radians(a)) * 132; y = cy + math.sin(math.radians(a)) * 92
        tomb(c, f"lapide{k}", x, y, 20, 32, (a - 270) * 0.5, cross=False)
    r = rng(171)
    for i in range(14):
        c.b(f"pedra{i}", "#323a4e", blob(r.random() * 300, r.random() * 270, 2 + r.random() * 3, 1800 + i, 6, 0.3))
    # a tempestade: braços de alma em espiral em volta do herói + crânios-alma rodando (um por morte)
    for k in range(5):
        a0 = k * 72
        pts = []
        for j in range(7):
            t = j / 6
            a = math.radians(a0 + t * 200); rr = 128 - t * 84
            pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr * 0.62))
        soul_stream(c, pts, 10 - (k % 2) * 3, 1.5, op=0.6)
    for k, (a, rr, s) in enumerate([(200, 116, 1.25), (250, 96, 0.9), (300, 120, 1.15), (350, 92, 0.85), (30, 124, 1.4), (90, 104, 1.1),
                                    (140, 118, 1.3), (110, 70, 0.7), (330, 64, 0.7)]):
        x = cx + math.cos(math.radians(a)) * rr; y = cy + math.sin(math.radians(a)) * rr * 0.62
        ta = math.radians(a - 28)
        trail = [(cx + math.cos(ta) * rr * 1.04, cy + math.sin(ta) * rr * 0.64), ((x + cx + math.cos(ta) * rr) / 2, (y + cy + math.sin(ta) * rr * 0.62) / 2), (x, y)]
        soul_wisp(c, x, y, s, a + 90, trail=trail)
    sparks(c, [(40, 60), (270, 40), (28, 240), (284, 230), (150, 30), (90, 120), (214, 110)], SOUL_L)
    # o herói: girando com a espada (câmera alta: levemente achatado)
    hp = hero_l3.pose("girar")
    c.f("sombra_heroi", "#10141e", ellipse(cx - 2, 248, 44, 9, 0, 12), op=0.5)
    M = c.fig("heroi", hp, cx - 4, 250, -6, 1.06, 0.92)
    rim(c, hp, M, 0, 2.4, "#d8fff0", 0.7)  # luz verde vindo de baixo (o olho)
    c.guide = list(ap(M, hero_l3.GUIDE["girar"]))
    c.save()


ALL = dict(ghost=ghost, scrap_golem=scrap_golem, soul_feast=soul_feast, soul_harvest=soul_harvest, life_drain=life_drain,
           profane_ritual=profane_ritual, open_grave=open_grave, soul_storm=soul_storm)

if __name__ == "__main__":
    for nm in (sys.argv[1:] or ALL):
        ALL[nm]()
        print(nm)
