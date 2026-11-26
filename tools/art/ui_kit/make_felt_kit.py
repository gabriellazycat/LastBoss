"""Painéis e botões da interface em feltro (escolhido em 26/11/2026): as mesmas peças de 9-slice do kit "Mapa
aberto" (make_map_kit.py), com o mesmo tamanho, as mesmas margens e a moldura dentro da mesma profundidade
(UiKit.DEPTH_MAPA: painéis gold/dark/night 22 px, ink 10, botões ink 7 e gold 11), em retalho de feltro de cantos
redondos com a costura tracejada perto da borda. As molduras, gemas e fitas das cartas ficam como estão (a arte das
cartas não muda).

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

# (tamanho, profundidade máxima da moldura em px)
PIECES = {
    "panel_gold": ((300, 420), 22, "gold"),
    "panel_dark": ((300, 420), 22, "dark"),
    "panel_night": ((300, 420), 22, "night"),
    "panel_ink": ((300, 420), 10, "ink"),
    "button_gold": ((150, 210), 11, "button_gold"),
    "button_ink": ((150, 210), 7, "button_ink"),
}


def rrect_path(x0, y0, x1, y1, r, step):
    """Pontos ao longo do contorno de um retângulo de cantos redondos, espaçados de ~step."""
    pts = []
    segs = [
        ((x0 + r, y0), (x1 - r, y0)), ("arc", (x1 - r, y0 + r), -90, 0),
        ((x1, y0 + r), (x1, y1 - r)), ("arc", (x1 - r, y1 - r), 0, 90),
        ((x1 - r, y1), (x0 + r, y1)), ("arc", (x0 + r, y1 - r), 90, 180),
        ((x0, y1 - r), (x0, y0 + r)), ("arc", (x0 + r, y0 + r), 180, 270),
    ]
    for s in segs:
        if s[0] == "arc":
            c, a0, a1 = s[1], s[2], s[3]
            n = max(2, int(abs(a1 - a0) / 360 * 2 * math.pi * r / step))
            for i in range(n):
                a = math.radians(a0 + (a1 - a0) * i / n)
                pts.append((c[0] + math.cos(a) * r, c[1] + math.sin(a) * r))
        else:
            (ax, ay), (bx, by) = s
            L = math.hypot(bx - ax, by - ay)
            n = max(1, int(L / step))
            for i in range(n):
                t = i / n
                pts.append((ax + (bx - ax) * t, ay + (by - ay) * t))
    return pts


def piece(name, size, depth, key):
    W, H = size
    w, h = W * SS, H * SS
    fill, band, line = PAL[key]
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    small = W < 200
    rad = 16 * (0.7 if small else 1.0)
    inset = 1.5
    # base: feltro de cantos redondos
    d.rounded_rectangle([inset * SS, inset * SS, w - inset * SS, h - inset * SS], radius=rad * SS, fill=hexc(fill))
    # leve escurecido só na faixa da borda (dentro da margem do 9-slice; o miolo fica liso)
    edge = Image.new("L", (w, h), 0)
    de = ImageDraw.Draw(edge)
    de.rounded_rectangle([inset * SS, inset * SS, w - inset * SS, h - inset * SS], radius=rad * SS, outline=255,
                         width=int(6 * SS))
    edge = edge.filter(ImageFilter.GaussianBlur(3 * SS))
    shade = np.array(img).astype(float)
    k = (np.array(edge).astype(float) / 255.0) * 0.16
    shade[..., :3] *= (1.0 - k[..., None])
    img = Image.fromarray(np.clip(shade, 0, 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    # feltro: borda mais clara de cima (volume) e costura tracejada
    o = {"gold": 11, "dark": 11, "night": 11, "ink": 5.5, "button_gold": 6.5, "button_ink": 4.5}[key]
    assert o + 1.5 <= depth
    dash, gap = (7.0, 5.0) if not small and key != "ink" else (5.0, 4.0)
    pts = rrect_path(o * SS, o * SS, w - o * SS, h - o * SS, max(3, rad - o + 3) * SS, SS * 1.0)
    per = int((dash + gap))
    thread = hexc(band)
    th = (2.6 if not small and key != "ink" else 2.0) * SS
    # sombra da linha (o fio afunda no feltro)
    for off, col in (((0.0, 0.9 * SS), hexc(line, 150)), ((0, 0), thread)):
        for i in range(0, len(pts) - per, per):
            seg = pts[i:i + int(dash)]
            if len(seg) < 2:
                continue
            seg = [(x + off[0], y + off[1]) for (x, y) in seg]
            d.line(seg, fill=col, width=int(th), joint="curve")
    d.rounded_rectangle([inset * SS, inset * SS, w - inset * SS, h - inset * SS], radius=rad * SS,
                        outline=hexc(line, 160), width=int(1.2 * SS))
    img = img.resize((W, H), Image.LANCZOS)
    img.save(OUT / (name + ".png"))
    print("kit", name, size)


for n, (sz, dp, key) in PIECES.items():
    piece(n, sz, dp, key)
