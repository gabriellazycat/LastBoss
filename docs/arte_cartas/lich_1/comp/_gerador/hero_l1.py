"""Pose nova do herói genérico para o lote lich_1 (mesmo rig de praga_1/hero.py, só juntas novas; não edita heroi.svg).
Já usadas antes (não repetir): avancar, preso, defesa, guarda (praga); escorregar, costas_recuo, capa_fogo, choque, recuo,
correr_escudo (dragao_1); atraido, catar, afundar, freiar, golpe_costas (dragao_2); golpe_baixo, correr_costas, enredado,
cambalear, derrubado (dragao_3).
  fincar (corpse_blast) — de pé, inclinado ~35° CONTRA a explosão (à esquerda), espada fincada no chão com as duas mãos
                          como âncora, perna da frente dobrada, perna de trás esticada escorregando (pé arrastando),
                          capa jogada para trás pelo sopro; cabeça baixa virada para o lado do impacto."""
from geom import *
import hero

POSES_L1 = {
    "fincar": dict(head=(-34, -118), tilt=-34, turn=-3, neck=(-27, -107), sl=(-44, -94), sr=(-8, -100), el=(-54, -72), wl=(-42, -56),
                   er=(-24, -78), wr=(-36, -62), sdir=(-0.34, 0.94), slen=56, hc=(6, -60), hl=(-5, -60), hr=(17, -58),
                   kl=(-30, -32), al=(-40, -4), tl=(-50, 0), kr=(36, -32), ar=(60, -8), tr=(70, -2), far="r",
                   cape=[(-40, -104), (-6, -108), (26, -116), (64, -126), (98, -112), (84, -96), (108, -82), (70, -74), (36, -76), (4, -82), (-22, -88)]),
}
GUIDE = {"fincar": [(70, -2), (36, -32), (6, -60), (-27, -107), (-46, -126)]}
hero.POSES.update(POSES_L1)


def pose(name):
    return hero.hero(POSES_L1[name])


def J(name):
    return POSES_L1[name]
