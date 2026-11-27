"""Painéis e botões da interface em feltro (escolhido em 26/11/2026): as mesmas peças de 9-slice do kit "Mapa
aberto" (make_map_kit.py), com o mesmo tamanho, as mesmas margens e a moldura dentro da mesma profundidade
(UiKit.DEPTH_MAPA: painéis gold/dark/night 22 px, ink 10, botões ink 7 e gold 11), em retalho de feltro de cantos
redondos com a costura tracejada perto da borda. As molduras, gemas e fitas das cartas ficam como estão (a arte das
cartas não muda).

Costura de passo fixo (26/11/2026): as caixas usam o 9-slice em TILE_FIT (UiParch.box/button_box), então o miolo de
cada borda tem exatamente dois pontos de costura e se repete em vez de esticar; a peça tem 2 × margem do 9-slice +
2 pontos de cada lado. O canto (fixo) divide o seu trecho de costura num número inteiro de pontos, e o raio do canto
e o escurecido da borda cabem dentro da margem (o miolo fica liso e se repete sem emenda).

Uso: python -I tools/art/ui_kit/make_felt_kit.py   (depois: godot --headless --path . --import)
"""
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets" / "ui" / "kit_mapa"
SS = 4


def hexc(h, a=255):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


# cor do feltro, cor da linha da costura, cor da sombra da linha e do contorno fino
PAL = {
    "gold": ("#ecdfc6", "#c9973f", "#b98a52"),
    "dark": ("#d3bb94", "#f3e6cc", "#a98a64"),
    "night": ("#a9b3c6", "#f1e7d2", "#8692a8"),
    "ink": ("#efe4cf", "#8a6a50", "#c9b493"),
    "button_gold": ("#efdcb6", "#a8742e", "#c9a46a"),
    "button_ink": ("#efe4cf", "#8a6a50", "#c9b493"),
}

# (margem do 9-slice em UiParch, profundidade máxima da moldura em px, paleta, ponto (traço, vão), espessura da linha,
#  raio do canto)
PIECES = {
    "panel_gold": (34, 22, "gold", (7.0, 5.0), 2.6, 16.0),
    "panel_dark": (34, 22, "dark", (7.0, 5.0), 2.6, 16.0),
    "panel_night": (34, 22, "night", (7.0, 5.0), 2.6, 16.0),
    "panel_ink": (14, 10, "ink", (5.0, 4.0), 2.0, 13.0),
    "button_gold": (17, 11, "button_gold", (5.0, 4.0), 2.0, 11.2),
    "button_ink": (9, 7, "button_ink", (5.0, 4.0), 2.0, 8.5),
}


def rrect_point(x0, y0, x1, y1, r, t):
    """Ponto a `t` px do começo do lado de cima (x0 + r, y0), em sentido horário, num retângulo de cantos redondos."""
    w, h = x1 - x0 - 2 * r, y1 - y0 - 2 * r
    arc = math.pi * 0.5 * r
    per = 2 * (w + h) + 4 * arc
    t %= per
    for (sx, sy, dx, dy), L, c, a0 in (
            ((x0 + r, y0, 1, 0), w, (x1 - r, y0 + r), -90), ((x1, y0 + r, 0, 1), h, (x1 - r, y1 - r), 0),
            ((x1 - r, y1, -1, 0), w, (x0 + r, y1 - r), 90), ((x0, y1 - r, 0, -1), h, (x0 + r, y0 + r), 180)):
        if t <= L:
            return (sx + dx * t, sy + dy * t)
        t -= L
        if t <= arc:
            ang = math.radians(a0 + 90 * t / arc)
            return (c[0] + math.cos(ang) * r, c[1] + math.sin(ang) * r)
        t -= arc
    return (x0 + r, y0)


def stitch_dashes(W, H, m, o, rs, dash, gap):
    """Traços da costura (listas de pontos, px 1:1): o miolo de cada lado (entre as margens m do 9-slice) com passo
    exato dash + gap começando na margem; cada canto com um número inteiro de pontos no seu trecho."""
    per = dash + gap
    x0, y0, x1, y1 = o, o, W - o, H - o
    corner = 2 * (m - o - rs) + math.pi * 0.5 * rs
    runs = []
    t = m - o - rs          # do começo do lado de cima até a margem
    for L in (W - 2 * m, corner, H - 2 * m, corner, W - 2 * m, corner, H - 2 * m, corner):
        runs.append((t, L))
        t += L
    out = []
    for t0, L in runs:
        n = max(1, round(L / per))
        pe = L / n
        dl = dash * pe / per
        for j in range(n):
            a = t0 + j * pe
            k = max(2, int(dl * 4))
            out.append([rrect_point(x0, y0, x1, y1, rs, a + dl * i / k) for i in range(k + 1)])
    return out


def piece(name, m, depth, key, dg, thick, rad):
    dash, gap = dg
    per = dash + gap
    W = H = int(2 * m + 2 * per)   # miolo de cada lado = 2 pontos
    assert rad <= m
    w, h = W * SS, H * SS
    fill, band, line = PAL[key]
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    inset = 1.5
    # base: feltro de cantos redondos
    d.rounded_rectangle([inset * SS, inset * SS, w - inset * SS, h - inset * SS], radius=rad * SS, fill=hexc(fill))
    # leve escurecido só na faixa da borda, que acaba antes da margem do 9-slice (o miolo fica liso)
    ew, eb = min(6.0, 0.35 * m), min(3.0, 0.18 * m)
    edge = Image.new("L", (w, h), 0)
    de = ImageDraw.Draw(edge)
    de.rounded_rectangle([inset * SS, inset * SS, w - inset * SS, h - inset * SS], radius=rad * SS, outline=255,
                         width=int(ew * SS))
    edge = edge.filter(ImageFilter.GaussianBlur(eb * SS))
    shade = np.array(img).astype(float)
    k = (np.array(edge).astype(float) / 255.0) * 0.16
    shade[..., :3] *= (1.0 - k[..., None])
    img = Image.fromarray(np.clip(shade, 0, 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    # costura tracejada, concêntrica ao canto
    o = {"gold": 11, "dark": 11, "night": 11, "ink": 5.5, "button_gold": 6.5, "button_ink": 4.5}[key]
    assert o + 1.5 <= depth
    rs = max(2.0, rad - o)
    segs = stitch_dashes(W, H, m, o, rs, dash, gap)
    thread = hexc(band)
    th = thick * SS
    # sombra da linha (o fio afunda no feltro)
    for off, col in (((0.0, 0.9), hexc(line, 150)), ((0, 0), thread)):
        for seg in segs:
            d.line([((x + off[0]) * SS, (y + off[1]) * SS) for (x, y) in seg], fill=col, width=int(th), joint="curve")
    d.rounded_rectangle([inset * SS, inset * SS, w - inset * SS, h - inset * SS], radius=rad * SS,
                        outline=hexc(line, 160), width=int(1.2 * SS))
    img = img.resize((W, H), Image.LANCZOS)
    img.save(OUT / (name + ".png"))
    print("kit", name, (W, H))


for n, args in PIECES.items():
    piece(n, *args)
