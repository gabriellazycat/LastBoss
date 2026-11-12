"""Fichas novas do lote dragao_2: mimico (baú base + mímico), guardiao (Guarda do Tesouro).
Uso: python fichas.py [mimico] [guardiao]  (grava em tools/art/card_blender/fichas/)"""
import base  # noqa: F401
from base import FICH
from geom import *
from fichas_lib import txt, pose_g, swatches
from render import shot
import sys
sys.path.insert(0, "C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/dragao_1/comp/_gerador")
from fichas import svg_wrap, ruler  # dragao_1 (só leitura)


def mimico_svg():
    W, H = 1000, 520
    import mimic as m
    P = [txt(20, 30, "FICHA · MÍMICO e BAÚ (Dragão, Ganância) — baú de madeira de tampa abaulada, cintas de ferro, cantoneiras e fechadura de ouro", 14, "bold"),
         txt(20, 48, "Unidade: altura da caixa = 22 u. Largura 1,8 caixas (40 u), fundo 1,2 (26 u), tampa +0,45 (10 u). Modelo 3D (caixa + meio-cilindro com dobradiça atrás),", 10),
         txt(20, 62, "projetado em 3/4 de cima (yaw −18..−32°, pitch 18..24°). Mímico: dentes nas bordas da caixa e da tampa, língua roxa-avermelhada, olhos amarelos no céu da boca, 4 patas de garra.", 10),
         txt(20, 76, "data-fig: mimico_corpo (caixa, boca, dentes de baixo, língua, patas), mimico_tampa (tampa, dentes de cima). Baú Armadilha = pose 'fechado' sem dentes (bau_corpo, bau_tampa).", 10),
         ruler(40, 92, 22 * 2, 4, "#9a6232", "#6e4222", "1 caixa = 22 u (régua ×2)")]
    for i, (nm, lab, sub) in enumerate([("fechado", "fechado · disfarce / baú base", "tampa fechada, sem sinais"),
                                        ("espreitar", "espreitar · fresta", "olhos e ponta da língua"),
                                        ("bote", "bote · salto", "tampa escancarada, língua em S"),
                                        ("morder", "morder · fechando", "tampa a 48°, corpo para a frente")]):
        x = 130 + i * 230
        P.append(pose_g(nm, m.pose(nm), (x, 380, 3.0), "mimico", m.GUIDE[nm], lab, sub, ly=40))
    P.append(pose_g("tampa_solta", m.pose("fechado", lid_off=(-18, -46, -32)), (420, 190, 1.3), "bau", None, "baú armadilha · tampa solta", "explosão", ly=26))
    P.append(swatches(860, 96, [(k, m.PAL[k]) for k in ("wood", "wood_d", "wood_l", "iron", "gold", "mouth", "palate", "tongue", "teeth", "eye")]))
    return svg_wrap(W, H, P), (W, H)


def guardiao_svg():
    W, H = 1180, 600
    import guard as g
    P = [txt(20, 30, "FICHA · GUARDA DO TESOURO (Dragão, Ganância) — esqueleto grande em armadura de ouro, olhos turquesa, escudo e machado", 14, "bold"),
         txt(20, 48, "Unidade: cabeça (crânio+elmo) = 26 u. Altura ≈ 6 cabeças (156 u); ombros = 3 cabeças (criatura grande: cabeça e tronco ~1,4× o natural). Coxa/canela 1,4; braço 1,2; antebraço 1,1.", 10),
         txt(20, 62, "Osso à mostra: coluna, costelas de baixo, braços e pernas (IK de dois ossos); ouro: elmo, peitoral, ombreiras de espigão, braçais, faldas, grevas. Olho turquesa = brilho próprio (foco).", 10),
         txt(20, 76, "data-fig: guardiao_corpo (pernas, faldas, tronco, braços, mãos, capa), guardiao_cabeca (crânio+elmo+chifres), guardiao_escudo, guardiao_machado. Costelas, vértebras, olhos, dentes, emblema = inner.", 10),
         ruler(40, 92, 26 * 2, 4, "#d9a332", "#e8dcc0", "1 cabeça = 26 u (régua ×2)")]
    P.append(pose_g("cabeca_frente", g.skull_helm(T(0, 0)), (90, 200, 2.0), "guardiao", label="cabeça · frente", ly=50))
    P.append(pose_g("cabeca_rugido", g.skull_helm(T(0, 0), jaw=7), (90, 360, 2.0), "guardiao", label="cabeça · rugido", ly=56))
    for i, (nm, lab, sub) in enumerate([("provocar", "provocar · escudo à frente", "base larga, machado erguido"),
                                        ("golpe", "golpe · machado em diagonal", "tronco torcido, escudo atrás"),
                                        ("marchar", "marchar · passo pesado", "machado no ombro")]):
        x = 300 + i * 240
        P.append(pose_g(nm, g.pose(nm), (x, 540, 1.4), "guardiao", g.GUIDE[nm], lab, sub, ly=26))
    P.append(swatches(1030, 110, [(k, g.PAL[k]) for k in ("bone", "bone_d", "gold", "gold_d", "gold_l", "cape", "eye", "blade", "haft", "gem")]))
    return svg_wrap(W, H, P), (W, H)


if __name__ == "__main__":
    todo = dict(mimico=mimico_svg, guardiao=guardiao_svg)
    for nm in (sys.argv[1:] or todo):
        s, wh = todo[nm]()
        open(f"{FICH}/{nm}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{FICH}/{nm}.png", (0, 0) + wh, *wh, guide=True, inkw=2.2)
        print(nm, len(s))
