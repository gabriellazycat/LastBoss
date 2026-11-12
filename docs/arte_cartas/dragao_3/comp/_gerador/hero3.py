"""Poses novas do herói genérico para o lote dragao_3 (mesmo rig de praga_1/hero.py, só juntas novas; não editam heroi.svg).
Já usadas antes (não repetir): avancar, preso, defesa, guarda (praga); escorregar, costas_recuo, capa_fogo, choque, recuo,
correr_escudo (dragao_1); atraido, catar, afundar, freiar, golpe_costas (dragao_2).
  golpe_baixo   (kobold_scavengers) — base larga, espada varrendo para baixo nos kobolds dos pés, braço livre jogado para trás
  correr_costas (burn_village)      — visto de costas, correndo para a aldeia, perna de trás chutada, capa esvoaçando
  enredado      (tar_net)           — puxado para o chão pela rede: um joelho no chão, cotovelos colados, cabeça baixa
  cambalear     (blood_tax)         — cambaleia de lado, mão no peito (o sangue sai dali), espada arrastando a ponta no chão
  derrubado     (gold_avalanche)    — arremessado de costas pela onda de ouro: corpo em C, pernas no ar, braços abertos"""
from geom import *
import hero
from hero2 import back_view

POSES3 = {
    "golpe_baixo": dict(head=(10, -134), tilt=18, turn=2, neck=(8, -122), sl=(-12, -113), sr=(29, -110), el=(-34, -122), wl=(-54, -134),
                        er=(44, -92), wr=(48, -66), sdir=(0.3, 0.95), slen=62, hc=(5, -70), hl=(-6, -70), hr=(16, -68),
                        kl=(-28, -38), al=(-40, -4), tl=(-48, 0), kr=(36, -40), ar=(44, -4), tr=(52, 0), far="l",
                        cape=[(-8, -118), (24, -118), (40, -100), (52, -66), (40, -44), (8, -44), (-30, -52), (-60, -76), (-40, -108)]),
    "correr_costas": dict(head=(6, -152), tilt=6, turn=0, neck=(4, -140), sl=(-17, -130), sr=(25, -130), el=(-34, -112), wl=(-30, -92),
                          er=(42, -114), wr=(54, -132), sdir=(0.55, -0.83), slen=60, hc=(2, -84), hl=(-9, -84), hr=(13, -82),
                          kl=(-16, -52), al=(-34, -30), tl=(-38, -22), kr=(22, -44), ar=(16, -6), tr=(20, 0), far="l",
                          cape=[(-18, -136), (24, -136), (40, -120), (70, -110), (88, -84), (60, -70), (30, -60), (-10, -62), (-30, -96)]),
    "enredado": dict(head=(16, -104), tilt=30, turn=3, neck=(11, -94), sl=(-9, -88), sr=(31, -84), el=(-24, -68), wl=(-10, -56),
                     er=(44, -62), wr=(36, -40), sdir=(0.35, 0.94), slen=48, hc=(4, -48), hl=(-7, -48), hr=(15, -46),
                     kl=(-22, -6), al=(-50, -8), tl=(-58, -4), kr=(32, -28), ar=(38, -2), tr=(48, 0), far="l",
                     cape=[(-6, -94), (26, -92), (40, -76), (44, -50), (30, -36), (4, -40), (-20, -46), (-28, -66), (-20, -86)]),
    "cambalear": dict(head=(-16, -138), tilt=-26, turn=-2, neck=(-11, -127), sl=(-31, -116), sr=(11, -121), el=(-24, -96), wl=(-6, -104),
                      er=(30, -96), wr=(42, -72), sdir=(0.5, 0.87), slen=72, hc=(-2, -74), hl=(-13, -74), hr=(9, -72),
                      kl=(-26, -38), al=(-16, -4), tl=(-24, 0), kr=(10, -36), ar=(30, -6), tr=(38, -2), far="r",
                      cape=[(-26, -122), (8, -124), (34, -108), (58, -84), (66, -54), (40, -46), (10, -52), (-20, -80), (-40, -104)]),
    "derrubado": dict(head=(-40, -96), tilt=-62, turn=-2, neck=(-29, -90), sl=(-36, -72), sr=(-18, -102), el=(-62, -56), wl=(-82, -66),
                      er=(-2, -126), wr=(12, -146), sdir=(0.1, -0.99), slen=58, hc=(2, -62), hl=(-4, -54), hr=(10, -68),
                      kl=(20, -96), al=(46, -84), tl=(54, -90), kr=(36, -60), ar=(62, -72), tr=(70, -80), far="l",
                      cape=[(-34, -86), (-20, -100), (0, -110), (24, -126), (16, -96), (14, -62), (-8, -40), (-40, -40), (-58, -62)]),
}
BACK = {"correr_costas"}
GUIDE = {"golpe_baixo": [(-48, 0), (-20, -40), (6, -90), (10, -134), (20, -150)],
         "correr_costas": [(20, 0), (14, -40), (4, -90), (6, -152), (10, -170)],
         "enredado": [(-58, -4), (-20, -10), (4, -50), (16, -104), (26, -116)],
         "cambalear": [(38, -2), (10, -36), (-2, -74), (-16, -138), (-30, -156)],
         "derrubado": [(70, -80), (36, -60), (2, -62), (-29, -90), (-50, -100)]}
hero.POSES.update(POSES3)


def pose(name):
    pcs = hero.hero(POSES3[name])
    return back_view(pcs) if name in BACK else pcs


def J(name):
    return POSES3[name]
