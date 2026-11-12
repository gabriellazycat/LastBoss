"""Fichas novas do lote lich_2: cultista (com a variação acólito) e lich. Uso: python fichas_l2.py [cultista] [lich]
Saída em LB_FICH (padrão tools/art/card_blender/fichas)."""
import base  # noqa: F401
from base import FICH
from geom import *
import cultista, lichfig
from fichas_lib import txt, pose_g, swatches
from render import shot


def svg_wrap(W, H, parts):
    body = "\n  ".join(parts)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">\n  <rect width="{W}" height="{H}" fill="#f6efe0"/>\n  {body}\n</svg>\n'


def ruler(x, y, unit, n, c1, c2, label):
    out = [f'<rect x="{x + i * unit}" y="{y}" width="{unit}" height="6" fill="{c1 if i % 2 == 0 else c2}" stroke="#2b1a10" stroke-width=".5"/>' for i in range(n)]
    out.append(txt(x, y + 18, label, 9))
    return "\n  ".join(out)


def ground_line(x0, x1, y):
    return f'<path d="M{x0} {y} L{x1} {y}" stroke="#a89a80" stroke-width="1.2" stroke-dasharray="3 4"/>'


def cultista_svg():
    W, H = 1180, 640
    C = cultista
    P = [txt(20, 30, "FICHA · CULTISTA (Lich, Corrente) — humano encapuzado de manto longo, rosto em sombra com olhos acesos, mangas de sino", 15, "bold"),
         txt(20, 48, "Unidade: cabeça = 20 u. Altura ≈ 7,5 cabeças (150 u com capuz); ombro a 6; quadril a 3,8; coxa 1,9 / canela 1,8; braço 1,5 / antebraço 1,3; mãos longas e ossudas (0,5).", 10),
         txt(20, 62, "IK de dois ossos (joelho para a frente, cotovelo para fora). O manto sai das juntas: frente pelo joelho da frente, costas pelo de trás, barra ~7 u acima do tornozelo (botas aparecem).", 10),
         txt(20, 76, "Variações: CULTISTA (manto vinho, faixa dourada, rosto vazio com olhos violeta) e ACÓLITO (manto creme de noviço, estola violeta, meia-máscara de osso). Silhueta: capuz de ponta caída + mangas de sino.", 10),
         txt(20, 90, "data-fig: cultista_corpo (manto, capa curta, mangas, mãos, pernas, botas = 1), cultista_cabeca (capuz + rosto = 1). Rosto vazio, olhos, máscara, dobras, faixa, barra, boca da manga = inner.", 10),
         ruler(40, 104, 20 * 1.4, 8, "#7a2030", "#d2c6a8", "1 cabeça = 20 u (régua ×1,4)")]
    P.append(pose_g("cabeca_perfil", C.head(T(0, 0)), (70, 200, 2.6), "cultista", label="capuz · perfil 3/4", ly=56))
    P.append(pose_g("cabeca_frente", C.head_front(T(0, 0)), (70, 340, 2.6), "cultista", label="capuz · frente", ly=56))
    P.append(pose_g("acolito_frente", C.head_front(T(0, 0), "acolito"), (70, 480, 2.6), "acolito", label="acólito · frente", ly=56))
    y0 = 560
    P.append(ground_line(150, 1000, y0))
    P.append(pose_g("ritual", C.pose("ritual"), (250, y0, 2.4), "cultista", C.GUIDE["ritual"], "ritual · braços em V", "cabeça para trás, costas em C", ly=22))
    P.append(pose_g("disparar", C.pose("disparar", "acolito"), (470, y0, 2.4), "acolito", C.GUIDE["disparar"], "disparar · estocada (acólito)", "braço esticado lança, outro puxa", ly=22))
    P.append(pose_g("ajoelhado", C.pose("ajoelhado"), (720, y0, 2.4), "cultista", C.GUIDE["ajoelhado"], "cantar · ajoelhado", "mãos juntas, cabeça baixa", ly=22))
    P.append(pose_g("orbe", C.pose("orbe", "acolito"), (1100, y0 - 330, 1.25), "acolito", C.GUIDE["orbe"], "orbe · mãos em concha", "(acólito, escala menor)", ly=14))
    P.append(pose_g("ler", C.pose("ler", "acolito") + C.book(tmat(46, -112, -12, 1.0)), (900, y0, 2.4), "acolito", C.GUIDE["ler"], "ler · grimório flutuante", "mão de longe comanda os livros", ly=22))
    P.append(swatches(1010, 330, [("cult robe", C.PALS["cultista"]["robe"]), ("cult robe_d", C.PALS["cultista"]["robe_d"]),
                                   ("cult trim", C.PALS["cultista"]["trim"]), ("cult skin", C.PALS["cultista"]["skin"]),
                                   ("void", C.PALS["cultista"]["void"]), ("cult eye", C.PALS["cultista"]["eye"]),
                                   ("acol robe", C.PALS["acolito"]["robe"]), ("acol robe_d", C.PALS["acolito"]["robe_d"]),
                                   ("acol estola", C.PALS["acolito"]["trim"]), ("acol mask", C.PALS["acolito"]["mask"]),
                                   ("acol eye", C.PALS["acolito"]["eye"]), ("boot", C.PALS["cultista"]["boot"])]))
    return svg_wrap(W, H, P), (W, H)


def lich_svg():
    W, H = 1180, 640
    L = lichfig
    P = [txt(20, 30, "FICHA · LICH (vilão) — esqueleto coroado de manto esfarrapado, gola alta, mãos de osso com magia; flutua (sem pés à vista)", 15, "bold"),
         txt(20, 48, "Unidade: crânio = 22 u (como o esqueleto). Altura ≈ 8 crânios (176 u, coroa incluída) — mais alto que um humano; ombros largos (2,2 crânios) pela gola e ombreiras de osso.", 10),
         txt(20, 62, "Braços: úmero 1,4 / antebraço 1,25 crânio, mangas rasgadas que mostram rádio e ulna; dedos longos (0,6). Manto termina em farrapos que somem em névoa (barra a ~10 u do chão).", 10),
         txt(20, 76, "Brilho só nos olhos (verde-espectral) e nas mãos (violeta). Coroa de ferro escurecido com pontas e uma gema; gola alta em leque atrás do crânio = silhueta reconhecível.", 10),
         txt(20, 90, "data-fig: lich_corpo (manto, gola, ombreiras, braços, mãos = 1), lich_cabeca (crânio + mandíbula + coroa = 1), lich_cajado. Órbitas, dentes, rachaduras, farrapos, runas = inner.", 10),
         ruler(40, 104, 22 * 1.3, 8, "#e6d8b8", "#2e2440", "1 crânio = 22 u (régua ×1,3)")]
    P.append(pose_g("cabeca_frente", L.head_front(T(0, 0)), (80, 210, 2.6), "lich", label="crânio · frente", ly=62))
    P.append(pose_g("cabeca_perfil", L.head(T(0, 0)), (80, 380, 2.6), "lich", label="crânio · perfil 3/4", ly=62))
    y0 = 590
    P.append(ground_line(160, 1000, y0))
    P.append(pose_g("conjurar", L.pose("conjurar"), (300, y0, 2.1), "lich", L.GUIDE["conjurar"], "conjurar · braços erguidos", "corpo em C para trás, gola aberta", ly=24))
    P.append(pose_g("apontar", L.pose("apontar"), (560, y0, 2.1), "lich", L.GUIDE["apontar"], "apontar · lança o feitiço", "braço esticado, ombro à frente", ly=24))
    P.append(pose_g("flutuar", L.pose("flutuar"), (820, y0, 2.1), "lich", L.GUIDE["flutuar"], "flutuar · ameaça", "cajado na mão, mão aberta com chama", ly=24))
    P.append(swatches(1010, 110, [(k, v) for k, v in L.PAL.items()]))
    return svg_wrap(W, H, P), (W, H)


if __name__ == "__main__":
    import sys
    todo = dict(cultista=cultista_svg, lich=lich_svg)
    for nm in (sys.argv[1:] or todo):
        s, wh = todo[nm]()
        open(f"{FICH}/{nm}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{FICH}/{nm}.png", (0, 0) + wh, *wh, guide=True, inkw=2.2)
        print(nm, len(s))
