"""Poses novas do herói genérico para o lote lich_2 (mesmo rig de praga_1/hero.py, só juntas novas; não edita heroi.svg).
Já usadas antes (não repetir): avancar, preso, defesa, guarda (praga); escorregar, costas_recuo, capa_fogo, choque, recuo,
correr_escudo (dragao_1); atraido, catar, afundar, freiar, golpe_costas (dragao_2); golpe_baixo, correr_costas, enredado,
cambalear, derrubado (dragao_3); fincar (lich_1).
  empurrado_escudo (shadow_bolt)  — inclinado para dentro do escudo redondo (braço esquerdo à frente), pés escorregando para
                                    trás, perna de trás esticada, espada baixa para trás; o raio fura o escudo
  arqueado_costas  (arcane_spark) — de costas: atingido nas costas, peito para a frente, ombros puxados, braços jogados para
                                    os lados, pé direito saindo do chão, capa jogada de lado
  virar_olhar      (shadow_echo)  — correndo para a direita e olhando para trás por cima do ombro (viseira à esquerda),
                                    espada erguida à frente, braço livre para trás
  fuga_alto        (shadow_mark)  — câmera alta de verdade, por escorço desenhado: correndo em diagonal para baixo-esquerda,
                                    tronco torcido, cabeça virando para o feixe (cima-direita); ombros largos e cabeça maior
                                    (perto da câmera), quadril estreito, pernas curtas e pés menores (longe); espada para trás,
                                    braço livre jogado à frente, capa esvoaçando para cima-direita. (A pose 'marcado' da volta 1
                                    foi descartada pelo controlador.)"""
import base  # noqa: F401
from geom import *
import hero
from hero2 import back_view
from hero_d1 import shield

POSES_L2 = {
    "empurrado_escudo": dict(head=(-18, -126), tilt=-22, turn=-2, neck=(-13, -115), sl=(-32, -104), sr=(8, -110), el=(-50, -98),
                             wl=(-54, -88), er=(24, -90), wr=(34, -68), sdir=(0.62, 0.78), slen=60, hc=(6, -64), hl=(-5, -64),
                             hr=(17, -62), kl=(-24, -36), al=(-36, -4), tl=(-46, 0), kr=(38, -34), ar=(64, -10), tr=(74, -6),
                             far="r", shield=True,
                             cape=[(-24, -112), (6, -116), (30, -110), (60, -104), (92, -92), (80, -78), (98, -64), (62, -60), (34, -56), (10, -70), (-14, -92)]),
    "arqueado_costas": dict(head=(4, -146), tilt=10, turn=0, neck=(3, -134), sl=(-19, -123), sr=(23, -124), el=(-42, -112),
                            wl=(-62, -124), er=(44, -110), wr=(64, -98), sdir=(0.72, 0.69), slen=62, hc=(4, -80), hl=(-7, -80),
                            hr=(15, -78), kl=(-12, -42), al=(-18, -6), tl=(-22, 0), kr=(24, -48), ar=(34, -22), tr=(40, -19), far="l",
                            cape=[(-17, -128), (21, -128), (20, -104), (12, -74), (-6, -50), (-34, -40), (-50, -54), (-38, -88), (-26, -116)]),
    "virar_olhar": dict(head=(-6, -146), tilt=-16, turn=-4, neck=(-1, -134), sl=(-18, -124), sr=(24, -126), el=(-34, -106),
                        wl=(-50, -96), er=(42, -110), wr=(58, -124), sdir=(0.5, -0.87), slen=64, hc=(6, -80), hl=(-5, -80),
                        hr=(17, -78), kl=(-10, -44), al=(-30, -24), tl=(-38, -20), kr=(30, -46), ar=(36, -8), tr=(46, -2), far="l",
                        cape=[(-14, -130), (20, -132), (8, -112), (-14, -96), (-44, -88), (-72, -96), (-62, -112), (-40, -124)]),
    "fuga_alto": dict(head=(-4, -118), tilt=16, turn=3, neck=(-4, -104), sl=(-30, -96), sr=(24, -100), el=(-46, -74),
                      wl=(-40, -50), er=(46, -88), wr=(66, -76), sdir=(0.86, 0.5), slen=52, hc=(0, -54), hl=(-6, -54),
                      hr=(8, -53), kl=(-14, -34), al=(-24, -20), tl=(-28, -16), kr=(14, -30), ar=(16, -10), tr=(20, -6), far="l",
                      escorco=dict(head=1.4, shoulder=1.3, foot=0.7),
                      cape=[(-26, -104), (22, -108), (44, -118), (70, -124), (92, -116), (80, -104), (96, -92), (62, -86), (36, -74), (14, -66), (-16, -80)]),
}
BACK = {"arqueado_costas"}
GUIDE = {"empurrado_escudo": [(74, -6), (38, -34), (6, -64), (-13, -115), (-30, -140)],
         "arqueado_costas": [(-22, 0), (-10, -40), (6, -80), (3, -134), (-4, -156)],
         "virar_olhar": [(46, -2), (28, -40), (6, -80), (-1, -134), (-16, -156)],
         "fuga_alto": [(-28, -16), (-14, -34), (0, -54), (-4, -104), (4, -132)]}
hero.POSES.update(POSES_L2)


def pose(name):
    J = POSES_L2[name]
    pcs = hero.hero(J)
    if name in BACK:
        pcs = back_view(pcs)
    if J.get("shield"):
        k = next(i for i, p in enumerate(pcs) if p.id == "elmo")
        pcs = pcs[:k] + shield(J) + pcs[k:]
    if J.get("escorco"):
        pcs = escorco(pcs, J, **J["escorco"])
    return pcs


def escorco(pcs, J, head=1.0, shoulder=1.0, foot=1.0):
    """Escorço desenhado (câmera alta): cada peça perto da câmera cresce em volta da sua junta (elmo, ombreiras) e as
    longe encolhem (pés). A figura continua com transformação uniforme na carta."""
    hd = A(J["head"])
    anc = {"ombreira_l": A(J["sl"]), "ombreira_r": A(J["sr"]),
           "pe_l": (A(J["al"]) + A(J["tl"])) / 2, "pe_r": (A(J["ar"]) + A(J["tr"])) / 2}
    out = []
    for p in pcs:
        if p.fig == "cabeca":
            s, c = head, hd
        elif p.id in ("ombreira_l", "ombreira_r"):
            s, c = shoulder, anc[p.id]
        elif p.id in ("pe_l", "pe_r"):
            s, c = foot, anc[p.id]
        else:
            out.append(p); continue
        out.append(p.moved(chain(T(*c), S(s), T(*(-c)))))
    return out


def J(name):
    return POSES_L2[name]
