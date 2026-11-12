"""Poses novas do herói genérico (lote dragao_1), sobre o rig do praga_1 (hero.hero, só leitura).
Acrescentadas à ficha heroi.svg sem mudar as 4 existentes. Também: vista de costas (capa por cima do tronco, sem viseira)
e escudo redondo (data-fig heroi_escudo) na mão esquerda."""
import base  # noqa: F401
import math
import numpy as np
from geom import *
import hero

NEW = {
    # escorregar: pé direito chutado para o alto, tronco caindo para trás, braços se debatendo (óleo no chão)
    "escorregar": dict(head=(-22, -136), tilt=-28, turn=1, neck=(-15, -124), sl=(-35, -114), sr=(5, -126), el=(-56, -126), wl=(-66, -148),
                       er=(26, -146), wr=(36, -168), sdir=(0.35, -0.94), slen=64, hc=(0, -70), hl=(-10, -70), hr=(10, -70),
                       kl=(-14, -36), al=(-8, -4), tl=(-1, 0), kr=(32, -84), ar=(56, -100), tr=(64, -108), far="l",
                       cape=[(-30, -120), (4, -130), (24, -110), (30, -80), (14, -50), (-20, -40), (-56, -56), (-70, -86), (-52, -112)]),
    # atingido de costas: recua com o braço erguido, calcanhar escorregando (usado com back=True)
    "costas_recuo": dict(head=(6, -148), tilt=14, neck=(3, -136), sl=(-19, -126), sr=(23, -128), el=(-38, -142), wl=(-50, -162),
                         er=(42, -112), wr=(60, -104), sdir=(0.92, 0.38), slen=60, hc=(0, -80), hl=(-11, -80), hr=(11, -80),
                         kl=(-24, -42), al=(-32, -4), tl=(-40, 0), kr=(20, -44), ar=(30, -12), tr=(34, -4), far="r",
                         cape=[(-20, -132), (22, -134), (34, -110), (44, -70), (40, -38), (14, -30), (-16, -32), (-40, -44), (-40, -84), (-32, -118)]),
    # capa em fogo: girando para fugir, olha a capa por cima do ombro e bate nela; espada erguida
    "capa_fogo": dict(head=(16, -146), tilt=20, turn=-3, neck=(9, -134), sl=(-13, -125), sr=(29, -126), el=(-34, -110), wl=(-52, -96),
                      er=(46, -140), wr=(62, -152), sdir=(0.8, -0.6), slen=64, hc=(6, -78), hl=(-5, -78), hr=(17, -76),
                      kl=(-12, -40), al=(-24, -6), tl=(-32, -1), kr=(34, -48), ar=(46, -12), tr=(54, -6), far="l",
                      cape=[(-10, -130), (22, -132), (12, -100), (-14, -66), (-52, -44), (-92, -54), (-94, -92), (-56, -120)]),
    # choque: a faísca acerta, corpo arqueado, braços abertos, espada solta para cima
    "choque": dict(head=(0, -148), tilt=-14, neck=(0, -135), sl=(-22, -124), sr=(22, -124), el=(-46, -130), wl=(-66, -142),
                   er=(46, -130), wr=(64, -146), sdir=(0.45, -0.89), slen=64, hc=(0, -76), hl=(-11, -76), hr=(11, -76),
                   kl=(-24, -40), al=(-36, -4), tl=(-44, 0), kr=(24, -40), ar=(36, -4), tr=(44, 0),
                   cape=[(-18, -132), (18, -132), (46, -112), (62, -80), (44, -50), (0, -40), (-44, -50), (-62, -80), (-46, -112)]),
    # recuo agachado: tropeça para trás, braço livre jogado para trás, espada apontada
    "recuo": dict(head=(-10, -128), tilt=-20, neck=(-8, -116), sl=(-28, -108), sr=(12, -112), el=(-46, -96), wl=(-58, -82),
                  er=(30, -96), wr=(46, -108), sdir=(0.95, -0.3), slen=62, hc=(-2, -66), hl=(-13, -66), hr=(9, -64),
                  kl=(-30, -36), al=(-34, -4), tl=(-42, 0), kr=(24, -32), ar=(16, -2), tr=(24, 0), far="l",
                  cape=[(-26, -112), (10, -116), (30, -96), (36, -60), (20, -36), (-16, -30), (-50, -44), (-58, -76), (-44, -104)]),
    # correr com escudo: escudo erguido sobre a cabeça (mão esquerda), espada para trás, perna de trás no ar
    "correr_escudo": dict(head=(6, -146), tilt=10, turn=2, neck=(4, -134), sl=(-16, -124), sr=(24, -126), el=(-30, -146), wl=(-12, -160),
                          er=(36, -104), wr=(30, -82), sdir=(-0.55, 0.83), slen=58, hc=(4, -78), hl=(-7, -78), hr=(15, -76),
                          kl=(-26, -46), al=(-44, -26), tl=(-52, -20), kr=(30, -48), ar=(30, -8), tr=(40, -2), far="l", shield=True,
                          cape=[(-14, -132), (20, -134), (6, -110), (-22, -84), (-60, -64), (-88, -72), (-80, -104), (-44, -126)]),
}
GUIDE = {"escorregar": [(-1, 0), (-8, -40), (-10, -80), (-18, -124), (-30, -150)],
         "costas_recuo": [(34, -4), (20, -40), (2, -90), (4, -136), (12, -160)],
         "capa_fogo": [(-32, -1), (-10, -40), (4, -80), (12, -134), (24, -160)],
         "choque": [(0, 0), (0, -40), (2, -90), (0, -140), (-6, -170)],
         "recuo": [(24, 0), (10, -30), (-2, -66), (-8, -116), (-16, -140)],
         "correr_escudo": [(40, -2), (26, -40), (6, -80), (4, -134), (10, -160)]}
hero.POSES.update(NEW)


def shield(J):
    h = hero.HP
    w = A(J["wl"]); c = w + (2, -10)
    return [Pc("escudo", "escudo", h["tabard"], ellipse(c[0], c[1], 24, 21, -8, 16)),
            Pc("escudo_aro", "escudo", h["steel"], ellipse(c[0], c[1], 24, 21, -8, 16), closed=False, cls="inner", sw=2.2),
            Pc("escudo_umbo", "escudo", h["gold"], ellipse(c[0], c[1], 5, 4.6, 0, 8), cls="inner"),
            Pc("escudo_faixa", "escudo", h["gold"], [(c[0] - 20, c[1] - 6), (c[0] + 20, c[1] + 4)], closed=False, cls="inner", sw=2.0)]


def pose(name, back=False):
    J = hero.POSES[name]
    pcs = hero.hero(J)
    if back:  # de costas: sem viseira/respiro; capa por cima do tronco, braços e elmo por cima da capa
        pcs = [p for p in pcs if p.id not in ("viseira", "respiro")]
        capa = [p for p in pcs if p.id == "capa"]
        pcs = [p for p in pcs if p.id != "capa"]
        k = next(i for i, p in enumerate(pcs) if p.id == "cinto") + 1
        pcs = pcs[:k] + capa + pcs[k:]
        hd = A(J["head"]); Mh = chain(T(*hd), R(J.get("tilt", 0)))
        pcs += [Pc("nuca", "cabeca", hero.HP["steel_d"], list(ap(Mh, [(-9, 2), (9, 2), (8, 10), (0, 12.5), (-8, 10)])), cls="inner")]
    if J.get("shield"):
        k = next(i for i, p in enumerate(pcs) if p.id == "elmo")
        pcs = pcs[:k] + shield(J) + pcs[k:]
    return pcs
