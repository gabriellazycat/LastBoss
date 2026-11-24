"""Kit da pele "Mapa aberto" (13/11/2026): as peças de 9-slice da interface, redesenhadas como o pergaminho do mapa da rota: papel areia com manchas e borda queimada,
contorno irregular, moldura de linha dupla de tinta tremida à mão, faixas com as pontas em V. Nada reto.

Uso: python -I tools/art/ui_kit/make_map_kit.py   (depois: godot --headless --path . --import)
Saída: assets/ui/kit_mapa/*.png com as margens de 9-slice de UiParch (painéis 34 px, "ink" 14, botões 9/17,
fitas 34/14/18): tudo que importa fica dentro das margens, o miolo é papel liso que estica sem distorcer.
"""
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets" / "ui" / "kit_mapa"
OUT.mkdir(parents=True, exist_ok=True)
SS = 3  # supersampling: desenha em 3x e reduz (linhas lisas)

INK = (58, 42, 28)
RED = (168, 50, 58)
PAPER_C = np.array([232, 214, 168], float)   # centro do papel
PAPER_E = np.array([205, 182, 130], float)   # perto da borda
BURN = np.array([150, 112, 62], float)       # borda queimada


def noise2(w, h, scale, seed):
    """Ruído de valor suave (sem dependências), 0..1."""
    rng = np.random.default_rng(seed)
    gw, gh = int(w / scale) + 3, int(h / scale) + 3
    g = rng.random((gh, gw))
    ys = np.linspace(0, gh - 3, h)
    xs = np.linspace(0, gw - 3, w)
    x0 = np.floor(xs).astype(int)
    y0 = np.floor(ys).astype(int)
    fx = xs - x0
    fy = ys - y0
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    a = g[np.ix_(y0, x0)]
    b = g[np.ix_(y0, x0 + 1)]
    c = g[np.ix_(y0 + 1, x0)]
    d = g[np.ix_(y0 + 1, x0 + 1)]
    top = a + (b - a) * fx[None, :]
    bot = c + (d - c) * fx[None, :]
    return top + (bot - top) * fy[:, None]


def wobble_rect(w, h, inset, amp, seed, step=6):
    """Contorno de retângulo tremido (lista de pontos), como traço à mão: a tremida é suave e lenta."""
    rnd = random.Random(seed)
    ph = [rnd.random() * 6.28 for _ in range(6)]
    pts = []
    x0, y0, x1, y1 = inset, inset, w - inset, h - inset
    per = 2 * ((x1 - x0) + (y1 - y0))
    t = 0.0
    while t < per:
        if t < x1 - x0:
            x, y, nx, ny = x0 + t, y0, 0, -1
        elif t < (x1 - x0) + (y1 - y0):
            x, y, nx, ny = x1, y0 + (t - (x1 - x0)), 1, 0
        elif t < 2 * (x1 - x0) + (y1 - y0):
            x, y, nx, ny = x1 - (t - (x1 - x0) - (y1 - y0)), y1, 0, 1
        else:
            x, y, nx, ny = x0, y1 - (t - 2 * (x1 - x0) - (y1 - y0)), -1, 0
        o = amp * (0.55 * math.sin(t * 0.021 + ph[0]) + 0.3 * math.sin(t * 0.057 + ph[1]) + 0.15 * math.sin(t * 0.13 + ph[2]))
        pts.append((x + nx * o, y + ny * o))
        t += step
    return pts


def paper(w, h, seed, tone=(1.0, 1.0, 1.0), edge_amp=5.0, edge_in=4.0, burn_w=22.0):
    """Papel de mapa RGBA: preenchimento com manchas, borda queimada e contorno irregular (alfa)."""
    W, H = w * SS, h * SS
    n1 = noise2(W, H, 90 * SS, seed)
    n2 = noise2(W, H, 26 * SS, seed + 1)
    yy, xx = np.mgrid[0:H, 0:W]
    dx = np.minimum(xx, W - 1 - xx) / SS
    dy = np.minimum(yy, H - 1 - yy) / SS
    d = np.minimum(dx, dy)
    # cor: centro -> borda, manchas grandes e salpico leve
    k = np.clip(1.0 - d / max(min(w, h) * 0.5, 1), 0, 1) ** 1.6
    col = PAPER_C[None, None, :] * (1 - k[..., None]) + PAPER_E[None, None, :] * k[..., None]
    stain = np.clip((n1 - 0.55) * 2.4, 0, 1)[..., None]
    col = col * (1 - stain * 0.10) + np.array([190, 160, 100])[None, None, :] * stain * 0.10
    col = col * (0.97 + 0.06 * n2[..., None])
    burn = np.clip(1 - (d - edge_in) / burn_w, 0, 1) ** 2 * (0.55 + 0.45 * n2)
    col = col * (1 - burn[..., None] * 0.35) + BURN[None, None, :] * burn[..., None] * 0.35
    col = col * np.array(tone)[None, None, :]
    # contorno irregular: distância à borda com ruído
    rag = edge_in + edge_amp * (noise2(W, H, 14 * SS, seed + 2) - 0.5) * 2 + edge_amp * 0.4 * (noise2(W, H, 4 * SS, seed + 3) - 0.5)
    a = np.clip((d - rag) * SS / 1.5, 0, 1)
    img = np.dstack([np.clip(col, 0, 255), a * 255]).astype(np.uint8)
    im = Image.fromarray(img, "RGBA")
    # sombra curta fora do papel
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    sa = im.split()[3].filter(ImageFilter.GaussianBlur(3 * SS))
    sh.putalpha(sa.point(lambda v: int(v * 0.35)))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(sh, (0, 2 * SS))
    out.alpha_composite(im)
    return out


def ink_frame(im, insets_widths, seed, color=INK, amp=1.6):
    """Linhas de tinta tremidas: [(inset_px, largura_px, cor?)] no tamanho final (desenha em SS)."""
    dr = ImageDraw.Draw(im)
    W, H = im.size
    for i, item in enumerate(insets_widths):
        inset, wd = item[0], item[1]
        col = item[2] if len(item) > 2 else color
        pts = wobble_rect(W, H, inset * SS, amp * SS, seed + i * 17, step=5 * SS)
        pts.append(pts[0])
        dr.line(pts, fill=col + (255,), width=max(1, int(wd * SS)), joint="curve")
    return im


def finish(im, w, h, name):
    im.resize((w, h), Image.LANCZOS).save(OUT / f"{name}.png")


def panel(name, w, h, seed, frame, tone=(1, 1, 1)):
    im = paper(w, h, seed, tone)
    ink_frame(im, frame, seed)
    finish(im, w, h, name)


# Painéis (300x420, margem 34): linha dupla dentro dos 34 px.
panel("panel_gold", 300, 420, 11, [(13, 3.0), (19.5, 1.4)])
panel("panel_dark", 300, 420, 12, [(13, 3.0), (19.5, 1.4)], tone=(0.86, 0.82, 0.76))
panel("panel_night", 300, 420, 13, [(13, 3.0), (19.5, 1.4)], tone=(0.84, 0.88, 0.96))
# "ink" (margem 14): traço único.
im = paper(300, 420, 14, edge_amp=3.5, edge_in=2.5, burn_w=12)
ink_frame(im, [(7, 2.0)], 14, amp=1.2)
finish(im, 300, 420, "panel_ink")
# Botões (150x210): normal margem 9 = traço único; mouse/apertado margem 17 = linha dupla com a de dentro vermelha.
im = paper(150, 210, 21, edge_amp=2.5, edge_in=2.0, burn_w=8)
ink_frame(im, [(4.5, 1.8)], 21, amp=0.9)
finish(im, 150, 210, "button_ink")
im = paper(150, 210, 22, tone=(1.04, 1.03, 1.0), edge_amp=2.5, edge_in=2.0, burn_w=8)
ink_frame(im, [(4.5, 2.2), (9.5, 1.6, RED)], 22, amp=0.9)
finish(im, 150, 210, "button_gold")


# Molduras sobre arte (retratos): só a linha dupla, miolo transparente.
def frame_only(name, lines, seed):
    im = Image.new("RGBA", (300 * SS, 420 * SS), (0, 0, 0, 0))
    # tira de papel por baixo das linhas (passe-partout fino)
    pp = paper(300, 420, seed, edge_amp=3, edge_in=2, burn_w=10)
    mask = Image.new("L", pp.size, 0)
    ImageDraw.Draw(mask).rectangle([0, 0, pp.size[0], pp.size[1]], fill=255)
    ImageDraw.Draw(mask).rectangle([24 * SS, 24 * SS, pp.size[0] - 24 * SS, pp.size[1] - 24 * SS], fill=0)
    pp.putalpha(Image.fromarray(np.minimum(np.array(pp.split()[3]), np.array(mask))))
    im.alpha_composite(pp)
    ink_frame(im, lines, seed)
    finish(im, 300, 420, name)


frame_only("frame_gold", [(13, 3.0), (20, 1.4)], 31)
frame_only("frame_legend", [(12, 3.0), (17, 1.4, RED), (21.5, 1.4)], 32)
frame_only("frame_heavy", [(12, 4.2), (19, 2.0)], 33)

# Fitas (300x61, margens 34/14/18): faixa de mapa com pontas em V, cor por tipo, linha de tinta.
RIB = {"monster": (168, 50, 58), "swarm": (176, 112, 52), "spell": (112, 82, 150), "structure": (122, 92, 62),
       "route": (70, 116, 104), "lair": (98, 50, 84), "finisher": (64, 54, 48)}


def ribbon(name, base, seed, dim=False):
    w, h = 300, 61
    W, H = w * SS, h * SS
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    notch = 16 * SS
    top, bot = 6 * SS, H - 10 * SS
    poly = [(0, top), (W, top), (W - notch, (top + bot) / 2), (W, bot), (0, bot), (notch, (top + bot) / 2)]
    # leve curva da faixa (não reta): sobe no meio
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    n = noise2(W, H, 30 * SS, seed)
    c = np.array(base, float)
    if dim:
        c = c * 0.72 + np.array([60, 50, 40]) * 0.28
    yy = np.mgrid[0:H, 0:W][0] / H
    shade = 1.0 + 0.10 * (0.5 - np.abs(yy - 0.42)) * 2   # brilho na faixa do meio
    col = c[None, None, :] * shade[..., None] * (0.94 + 0.10 * n[..., None])
    rgba = np.dstack([np.clip(col, 0, 255), np.array(mask)]).astype(np.uint8)
    rib = Image.fromarray(rgba, "RGBA")
    # sombra
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh.putalpha(mask.filter(ImageFilter.GaussianBlur(2.5 * SS)).point(lambda v: int(v * 0.35)))
    im.alpha_composite(sh, (0, 2 * SS))
    im.alpha_composite(rib)
    dr = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    def wob(p):
        return (p[0] + rnd.uniform(-0.6, 0.6) * SS, p[1] + rnd.uniform(-0.6, 0.6) * SS)
    outline = [wob(p) for p in poly] + [wob(poly[0])]
    dr.line(outline, fill=INK + (255,), width=int(2.2 * SS), joint="curve")
    # filete interno claro, como a costura da faixa do mapa
    dr.line([(notch + 6 * SS, top + 5 * SS), (W - notch - 6 * SS, top + 5 * SS)], fill=(255, 240, 210, 70), width=int(1.2 * SS))
    finish(im, w, h, name)


for i, (t, c) in enumerate(RIB.items()):
    ribbon(f"ribbon_{t}", c, 40 + i)
    ribbon(f"ribbon_{t}_dim", c, 40 + i, dim=True)

# Gemas de custo (gem_*.png): as mesmas das cartas, já estão em kit_mapa (o kit antigo de onde vieram saiu em 24/11/2026).
print("kit do mapa em", OUT)
