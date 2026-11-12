"""Fichas novas do lote lich_1: esqueleto, carnical, cavaleiro_morte, colosso_ossos.
Uso: python fichas_l1.py [esqueleto] [carnical] [cavaleiro_morte] [colosso_ossos]   (grava em LB_FICH = tools/art/card_blender/fichas/)"""
import base  # noqa: F401
from base import FICH
from geom import *
from fichas_lib import txt, pose_g, swatches
from render import shot
import sys


def svg_wrap(W, H, parts):
    body = "\n  ".join(parts)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">\n  <rect width="{W}" height="{H}" fill="#f6efe0"/>\n  {body}\n</svg>\n'


def ruler(x, y, unit, n, c1, c2, label):
    out = [f'<rect x="{x + i * unit}" y="{y}" width="{unit}" height="6" fill="{c1 if i % 2 == 0 else c2}" stroke="#2b1a10" stroke-width=".5"/>' for i in range(n)]
    out.append(txt(x, y + 18, label, 9))
    return "\n  ".join(out)


def ground_line(x, y, w):
    return f'<path d="M{x - w / 2} {y} L{x + w / 2} {y}" stroke="#8a7a5a" stroke-width="1.2" stroke-dasharray="3 3"/>'


def esqueleto_svg():
    W, H = 1180, 600
    import esqueleto as e
    P = [txt(20, 30, "FICHA · ESQUELETO (Lich, Morte) — esqueleto humano: crânio do v2 (frente), coluna, caixa torácica com arco costal, pelve em borboleta, rádio+ulna e tíbia+fíbula", 14, "bold"),
         txt(20, 48, "Unidade: crânio (com mandíbula) = 22 u. Altura em pé ≈ 7 crânios (154 u); quadril a 3,5; C7 a 5,9; fêmur 1,7 / tíbia 1,6 / úmero 1,3 / antebraço 1,15 / pé 0,65. Ombros 1,8 crânio (vista f).", 10),
         txt(20, 62, "IK de dois ossos: joelho para a frente, cotovelo para trás. Vista p = perfil olhando à direita (espelhe com scale(-1 1)); vista f = frente-3/4. Olhos verde-água acesos só na figura-foco.", 10),
         txt(20, 76, "data-fig: esqueleto_corpo (ossos, mãos, pés, trapo), esqueleto_cabeca (crânio+mandíbula), esqueleto_arco, esqueleto_flecha, esqueleto_espada, esqueleto_aljava. Vãos das costelas, forames, órbitas, dentes = inner.", 10),
         ruler(40, 92, 22 * 2, 4, "#e6d8b8", "#b8a886", "1 crânio = 22 u (régua ×2)")]
    P.append(pose_g("cabeca_frente", e.skull(T(0, 0), "f", 0), (80, 190, 3.0), "esqueleto", label="crânio · frente (v2)", ly=50))
    P.append(pose_g("cabeca_perfil", e.skull(T(0, 0), "p", 3), (80, 330, 3.0), "esqueleto", label="crânio · perfil, boca aberta", ly=52))
    poses = [("correr", "correr · perfil", "tronco 18° à frente, espada", 1.55),
             ("atirar", "atirar com arco · recuando", "peso atrás, corda na mandíbula", 1.55),
             ("golpear", "golpear · frente-3/4", "espada sobre o ombro, boca aberta", 1.55),
             ("erguer", "erguer-se do chão", "garra na terra, braço ao céu", 1.55)]
    for i, (nm, lab, sub, s) in enumerate(poses):
        x = 260 + i * 210; y = 530
        P.append(ground_line(x, y, 170))
        P.append(pose_g(nm, e.pose(nm), (x, y, s), "esqueleto", e.GUIDE[nm], lab, sub, ly=24))
    P.append(swatches(1040, 110, [(k, e.PAL[k]) for k in ("bone", "bone_d", "bone_l", "socket", "eye", "rag", "wood", "string", "rust", "blade", "fletch", "leather")]))
    return svg_wrap(W, H, P), (W, H)


TODO = dict(esqueleto=esqueleto_svg)
try:
    from fichas_l1_extra import EXTRA
    TODO.update(EXTRA)
except ImportError:
    pass

if __name__ == "__main__":
    for nm in (sys.argv[1:] or TODO):
        s, wh = TODO[nm]()
        open(f"{FICH}/{nm}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{FICH}/{nm}.png", (0, 0) + wh, *wh, guide=True, inkw=2.0)
        print(nm, len(s))
