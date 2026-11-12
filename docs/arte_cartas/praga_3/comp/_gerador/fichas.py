"""Fichas novas do lote praga_3: slime e flautista corrompido. Uso: python fichas.py [slime] [flautista]"""
import base  # noqa: F401
from base import FICH
from geom import *
import slime, piper
from fichas_lib import txt, pose_g, swatches
from render import shot


def svg_wrap(W, H, parts):
    body = "\n  ".join(parts)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">\n  <rect width="{W}" height="{H}" fill="#f6efe0"/>\n  {body}\n</svg>\n'


def ruler(x, y, unit, n, c1, c2, label):
    out = [f'<rect x="{x + i * unit}" y="{y}" width="{unit}" height="6" fill="{c1 if i % 2 == 0 else c2}" stroke="#2b1a10" stroke-width=".5"/>' for i in range(n)]
    out.append(txt(x, y + 18, label, 9))
    return "\n  ".join(out)


def slime_svg():
    W, H = 1000, 520
    P = [txt(20, 30, "FICHA · SLIME (Praga) — gelatina verde-peste com crânio de rato boiando; divide-se ao morrer", 16, "bold"),
         txt(20, 48, "Unidade: altura do slime parado = 60 u (1 corpo). Largura parado ≈ 1,6 corpo; rosto ≈ 0,4 corpo, olhos no terço de cima, boca larga com 3 dentes.", 10),
         txt(20, 62, "Física: comprime ao pousar (achata e alarga), estica no salto (gota inclinada, base arrastando), escorre na base (gotas presas). Ao dividir: o broto sai com o próprio rosto (geração seguinte = ×0,6).", 10),
         txt(20, 76, "data-fig: slime_corpo (massa + pseudópodes + escorridos = 1 silhueta), slime_broto (a metade que se solta), gotas soltas = 1 cada. Rosto, crânio, bolhas, sombra e brilho = class=inner.", 10),
         ruler(40, 92, 60 * 0.5, 4, "#9cc23e", "#6f9a2c", "1 corpo = 60 u (régua ×0,5)")]
    P.append(pose_g("cabeca_frente", slime.head_front(T(0, 0)), (90, 220, 2.2), "slime", label="rosto · frente", ly=64))
    P.append(pose_g("ameaca", slime.pose("ameaca"), (300, 270, 2.0), "slime", slime.GUIDE["ameaca"], "ameaça · parado", "domo largo, pseudópode erguido", ly=34))
    P.append(pose_g("saltar", slime.pose("saltar"), (560, 280, 2.0), "slime", slime.GUIDE["saltar"], "saltar · esticado", "gota diagonal, base arrastando, gotas soltas", ly=44))
    P.append(pose_g("dividir", slime.pose("dividir"), (300, 470, 2.0), "slime", slime.GUIDE["dividir"], "dividir · o broto se solta", "fio de gosma entre as duas massas", ly=24))
    P.append(pose_g("rastejar", slime.pose("rastejar"), (640, 470, 2.0), "slime", slime.GUIDE["rastejar"], "rastejar · onda baixa", "frente erguida, base escorrendo", ly=24))
    P.append(swatches(820, 110, [(k, v) for k, v in slime.PAL.items()]))
    return svg_wrap(W, H, P), (W, H)


def flautista_svg():
    W, H = 1000, 560
    P = [txt(20, 30, "FICHA · FLAUTISTA CORROMPIDO (Praga) — humano magro e curvado, casaco bicolor esfarrapado, chapéu cônico, flauta de osso", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 20 u (queixo→topo do crânio). Altura ≈ 7,5 cabeças; ombro a 6,2; quadril a 3,8; coxa 1,9 / canela 1,8; braço 1,5 / antebraço 1,3; mãos longas (0,5) e ossudas.", 10),
         txt(20, 62, "Braços e pernas por IK de dois ossos (joelho sempre para a frente, cotovelo para baixo). Mãos nos furos da flauta quando toca. Chapéu caído para trás com pena verde = silhueta reconhecível.", 10),
         txt(20, 76, "data-fig: flautista_corpo (tronco, casaco, braços, mãos, pernas, sapatos), flautista_cabeca (cabeça+cabelo+chapéu+pena), flautista_flauta. Olho, boca, listras, remendo, manchas, furos = inner.", 10),
         ruler(40, 92, 20 * 1.6, 8, "#b8bea0", "#9a3a32", "1 cabeça = 20 u (régua ×1,6)")]
    P.append(pose_g("cabeca_perfil", piper.head(T(0, 0)), (80, 220, 2.6), "flautista", label="cabeça · perfil 3/4", ly=50))
    P.append(pose_g("cabeca_frente", piper.head_front(T(0, 0)), (80, 380, 2.6), "flautista", label="cabeça · frente", ly=50))
    P.append(pose_g("tocar_andar", piper.pose("tocar_andar"), (290, 500, 2.4), "flautista", piper.GUIDE["tocar_andar"], "tocar · passo de dança", "joelho alto, tronco para a frente", ly=26))
    P.append(pose_g("tocar_salto", piper.pose("tocar_salto"), (530, 530, 2.4), "flautista", piper.GUIDE["tocar_salto"], "tocar · salto", "no ar, casaco esvoaçando", ly=14))
    P.append(pose_g("ameaca", piper.pose("ameaca"), (760, 500, 2.4), "flautista", piper.GUIDE["ameaca"], "ameaça · batuta", "flauta apontada, mão chamando", ly=26))
    P.append(swatches(880, 380, [(k, v) for k, v in piper.PAL.items() if k in ("skin", "coat", "coat_d", "motley", "hose_f", "hat", "feather", "flute", "eye", "stain")]))
    return svg_wrap(W, H, P), (W, H)


if __name__ == "__main__":
    import sys
    todo = dict(slime=slime_svg, flautista=flautista_svg)
    for nm in (sys.argv[1:] or todo):
        s, wh = todo[nm]()
        open(f"{FICH}/{nm}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{FICH}/{nm}.png", (0, 0) + wh, *wh, guide=True, inkw=2.2)
        print(nm, len(s))
