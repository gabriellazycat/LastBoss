"""Poses novas do herói genérico para o lote lich_3 (mesmo rig de praga_1/hero.py, só juntas novas; não edita heroi.svg).
Já usadas antes (não repetir): avancar, preso, defesa, guarda (praga); escorregar, costas_recuo, capa_fogo, choque, recuo,
correr_escudo (dragao_1); atraido, catar, afundar, freiar, golpe_costas (dragao_2); golpe_baixo, correr_costas, enredado,
cambalear, derrubado (dragao_3); fincar (lich_1); empurrado_escudo, arqueado_costas, virar_olhar, marcado (lich_2).
  agachar_olhar (soul_feast)     — agachado bem baixo, de frente, joelhos abertos, espada baixa de lado, braço livre aberto
                                   para o alto, capa SUGADA para cima (as almas sobem para a bocarra)
  golpe_alto    (soul_harvest)   — perfil para a direita, estocada-golpe de duas mãos descendo no esqueleto, perna da
                                   frente dobrada, perna de trás esticada, capa para trás
  arrancado     (life_drain)     — ajoelhado num joelho, costas arqueadas, cabeça jogada para trás, braços jogados para
                                   baixo e para os lados (a vida sai do peito), espada arrastando
  sentado       (profane_ritual) — caído sentado, apoiado na mão de trás, pernas para a frente, espada erguida apontando
                                   para o altar (de lado, olhando à direita)
  salto_tras    (open_grave)     — no ar, saltando para trás: joelhos encolhidos, tronco inclinado para trás, braço livre
                                   jogado para o alto, espada apontando para baixo-frente (para as mãos que saem da cova)
  girar         (soul_storm)     — giro com a espada na horizontal varrendo a tempestade, base larga, braço livre para o
                                   alto, capa enrolando em espiral (câmera alta na carta)"""
from geom import *
import hero
from hero2 import back_view  # noqa: F401

POSES_L3 = {
    "agachar_olhar": dict(head=(-4, -116), tilt=-14, turn=-2, neck=(-2, -103), sl=(-22, -95), sr=(18, -97), el=(-44, -110), wl=(-58, -128),
                          er=(36, -76), wr=(50, -60), sdir=(0.62, 0.78), slen=60, hc=(0, -52), hl=(-11, -52), hr=(11, -50),
                          kl=(-32, -34), al=(-38, -4), tl=(-48, 0), kr=(30, -30), ar=(36, -4), tr=(46, 0), far="l",
                          cape=[(-18, -100), (16, -102), (28, -114), (40, -140), (22, -128), (6, -150), (-10, -128), (-30, -142), (-34, -114)]),
    "golpe_alto": dict(head=(28, -134), tilt=18, turn=3, neck=(20, -122), sl=(4, -116), sr=(32, -116), el=(30, -108), wl=(56, -110),
                       er=(48, -100), wr=(60, -112), sdir=(0.9, 0.44), slen=66, hc=(0, -72), hl=(-8, -72), hr=(8, -70),
                       kl=(-24, -40), al=(-48, -8), tl=(-56, -2), kr=(32, -42), ar=(42, -4), tr=(54, 0), far="l",
                       cape=[(4, -120), (28, -122), (10, -102), (-14, -94), (-40, -96), (-66, -106), (-56, -116), (-74, -130), (-40, -132), (-14, -130)]),
    "arrancado": dict(head=(-14, -108), tilt=-30, turn=-2, neck=(-6, -97), sl=(-26, -89), sr=(14, -93), el=(-42, -72), wl=(-60, -60),
                      er=(36, -74), wr=(52, -58), sdir=(0.4, 0.92), slen=50, hc=(0, -46), hl=(-11, -46), hr=(11, -44),
                      kl=(-14, -4), al=(-40, -6), tl=(-48, -2), kr=(26, -40), ar=(30, -4), tr=(40, 0), far="l",
                      cape=[(-22, -94), (12, -98), (18, -80), (20, -58), (12, -42), (-6, -40), (-24, -42), (-34, -58), (-34, -80)]),
    "sentado": dict(head=(-22, -78), tilt=-8, turn=3, neck=(-18, -66), sl=(-32, -58), sr=(-6, -62), el=(-46, -34), wl=(-54, -8),
                    er=(10, -62), wr=(26, -76), sdir=(0.72, -0.69), slen=62, hc=(0, -18), hl=(-9, -18), hr=(9, -16),
                    kl=(28, -28), al=(52, -6), tl=(62, -8), kr=(22, -44), ar=(46, -8), tr=(56, -12), far="l",
                    cape=[(-30, -62), (-6, -66), (-2, -42), (-8, -12), (-40, -2), (-72, 0), (-64, -24), (-48, -48)]),
    "salto_tras": dict(head=(-20, -142), tilt=-22, turn=2, neck=(-14, -130), sl=(-32, -122), sr=(4, -126), el=(-50, -138), wl=(-62, -158),
                       er=(20, -110), wr=(36, -98), sdir=(0.74, 0.67), slen=64, hc=(0, -80), hl=(-10, -80), hr=(10, -78),
                       kl=(16, -88), al=(8, -58), tl=(18, -52), kr=(26, -98), ar=(36, -68), tr=(46, -64), far="l",
                       cape=[(-30, -126), (4, -130), (14, -112), (22, -82), (6, -62), (-16, -66), (-30, -86), (-40, -106)]),
    "girar": dict(head=(6, -136), tilt=10, turn=1, neck=(4, -122), sl=(-16, -114), sr=(24, -114), el=(-36, -128), wl=(-52, -146),
                  er=(48, -112), wr=(70, -108), sdir=(0.97, 0.24), slen=74, hc=(0, -70), hl=(-12, -70), hr=(12, -70),
                  kl=(-30, -38), al=(-44, -4), tl=(-54, 0), kr=(28, -36), ar=(40, -4), tr=(50, 0), far="l",
                  cape=[(-16, -120), (22, -120), (10, -100), (-20, -86), (-52, -84), (-84, -96), (-70, -110), (-90, -124), (-50, -124)]),
}
GUIDE = {
    "agachar_olhar": [(-48, 0), (-32, -34), (0, -52), (-2, -103), (-30, -140)],
    "golpe_alto": [(-56, -2), (-24, -40), (0, -72), (20, -122), (60, -112), (110, -84)],
    "arrancado": [(40, 0), (26, -40), (0, -46), (-6, -97), (-24, -118)],
    "sentado": [(-54, -8), (-32, -40), (-18, -66), (10, -62), (60, -110)],
    "salto_tras": [(46, -64), (26, -98), (0, -80), (-14, -130), (-30, -160)],
    "girar": [(-54, 0), (-30, -38), (0, -70), (4, -122), (70, -108), (140, -90)],
}
hero.POSES.update(POSES_L3)
PREV_S = 1.4


def pose(name, back=False):
    pcs = hero.hero(POSES_L3[name])
    return back_view(pcs) if back else pcs


def J(name):
    return POSES_L3[name]
