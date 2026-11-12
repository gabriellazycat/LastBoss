"""Poses novas do herói genérico para o lote dragao_2 (mesma ficha/construção de praga_1/hero.py, só juntas novas).
Não editam tools/art/card_blender/fichas/heroi.svg (outro agente mexe nela); ficam registradas nos .md das cartas.
  atraido      (gold_bait)    — andando de lado, hipnotizado, braço estendido para o ouro, espada arrastando
  catar        (cursed_coins) — ajoelhado, mão esquerda catando moedas, espada fincada no chão
  afundar      (molten_gold)  — atolado no ouro derretido, cabeça para trás, braço esquerdo esticado para o alto, espada atolada de lado
  freiar       (toll)         — freando de supetão, perna da frente esticada, capa jogada para a frente
  golpe_costas (trap_chest)   — visto de costas, golpe de duas mãos para baixo-esquerda (sem viseira, capa por cima)"""
from geom import *
import hero

POSES2 = {
    "atraido": dict(head=(-10, -146), tilt=-16, turn=-3, neck=(-7, -134), sl=(-28, -124), sr=(16, -128), el=(-50, -114),
                    wl=(-70, -110), er=(28, -104), wr=(36, -80), sdir=(0.5, 0.86), slen=72, hc=(0, -80), hl=(-11, -80),
                    hr=(11, -78), kl=(-30, -46), al=(-42, -8), tl=(-50, -2), kr=(14, -42), ar=(26, -8), tr=(30, -1), far="r",
                    cape=[(-20, -130), (14, -132), (40, -112), (62, -80), (58, -46), (30, -40), (4, -52), (-20, -92)]),
    "catar": dict(head=(-6, -110), tilt=-26, turn=-3, neck=(-4, -98), sl=(-24, -90), sr=(18, -92), el=(-38, -66), wl=(-30, -38),
                  er=(38, -70), wr=(46, -48), sdir=(0.06, 1), slen=44, hc=(0, -50), hl=(-11, -50), hr=(11, -48),
                  kl=(-24, -34), al=(-28, -4), tl=(-36, 0), kr=(16, -6), ar=(28, -10), tr=(34, -8), far="r",
                  cape=[(-16, -96), (16, -98), (36, -80), (48, -44), (40, -14), (14, -16), (-12, -30), (-26, -60), (-28, -86)]),
    "afundar": dict(head=(-6, -144), tilt=-22, turn=-2, neck=(-4, -132), sl=(-24, -124), sr=(20, -124), el=(-40, -150), wl=(-50, -176),
                    er=(42, -104), wr=(62, -92), sdir=(0.94, 0.34), slen=64, hc=(0, -80), hl=(-11, -80), hr=(11, -78),
                    kl=(-18, -44), al=(-16, -8), tl=(-22, -2), kr=(18, -46), ar=(20, -8), tr=(26, -2), far="r",
                    cape=[(-18, -130), (18, -130), (46, -110), (68, -84), (54, -64), (-40, -66), (-62, -86), (-38, -116)]),
    "freiar": dict(head=(12, -140), tilt=14, turn=2, neck=(9, -128), sl=(-11, -120), sr=(31, -120), el=(-30, -112), wl=(-46, -124),
                   er=(44, -100), wr=(58, -112), sdir=(0.82, -0.57), slen=66, hc=(10, -74), hl=(-1, -74), hr=(21, -72),
                   kl=(-22, -44), al=(-46, -14), tl=(-54, -10), kr=(30, -38), ar=(22, -4), tr=(30, 0), far="r",
                   cape=[(-8, -126), (26, -128), (16, -110), (-8, -96), (-36, -86), (-60, -96), (-44, -116)]),
    "golpe_costas": dict(head=(-4, -148), tilt=-8, turn=0, neck=(-2, -136), sl=(-22, -126), sr=(22, -122), el=(-30, -104),
                         wl=(-40, -94), er=(4, -104), wr=(-33, -97), sdir=(-0.74, 0.67), slen=76, hc=(0, -80), hl=(-11, -80),
                         hr=(11, -78), kl=(-32, -44), al=(-42, -6), tl=(-42, -1), kr=(24, -40), ar=(34, -4), tr=(36, 0), far="l",
                         cape=[(-20, -130), (20, -128), (40, -100), (60, -58), (54, -26), (16, -32), (-16, -28), (-32, -60), (-32, -104)]),
}
BACK = {"golpe_costas"}
GUIDE = {"atraido": [(-50, -2), (-30, -46), (-4, -90), (-10, -146), (-30, -160)],
         "catar": [(34, -8), (10, -40), (-4, -98), (-14, -118)],
         "afundar": [(10, -40), (0, -90), (-6, -144), (-40, -170)],
         "freiar": [(-54, -10), (-10, -50), (10, -100), (14, -150)],
         "golpe_costas": [(36, 0), (10, -60), (-4, -130), (-40, -96), (-80, -40)]}


def back_view(pcs):
    """Herói de costas: sem viseira/respiro; capa por cima do corpo e atrás dos braços."""
    pcs = [p for p in pcs if p.id not in ("viseira", "respiro")]
    capa = [p for p in pcs if p.id == "capa"]
    rest = [p for p in pcs if p.id != "capa"]
    k = next(i for i, p in enumerate(rest) if p.id.startswith("braco_"))
    return rest[:k] + capa + rest[k:]


def pose(name):
    if name in hero.POSES:
        return hero.pose(name)
    pcs = hero.hero(POSES2[name])
    return back_view(pcs) if name in BACK else pcs


def J(name):
    return hero.POSES.get(name) or POSES2[name]
