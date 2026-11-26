"""Compoe os 9 formatos da Steam a partir da arte bruta (raw/), com e sem logo.
python -I compor.py [v01 ...]   ->  tools/art/out/steam/<v>/{com_logo,sem_logo}/<formato>.png  (+ library_logo.png so em com_logo)
O logo e o texto LAST BOSS escrito por cima (PIL); a arte nunca leva texto. Trocar o nome do jogo = mudar TITULO."""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "tools", "art", "out", "steam")
FONTS = os.path.join(ROOT, "assets", "fonts")
TITULO = "LAST BOSS"
sys.path.insert(0, HERE)
from variantes import V

# fonte, cor de preenchimento, cor do contorno, por variante (o estilo do logo acompanha a direcao de arte)
LOGO = {
    "v01": ("CinzelDecorative-Bold.ttf", (244, 226, 190), (40, 26, 50)),
    "v02": ("IMFellEnglishSC-Regular.ttf", (246, 226, 170), (38, 44, 40)),
    "v03": ("Metamorphous-Regular.ttf", (255, 214, 120), (70, 22, 14)),
    "v04": ("MarcellusSC-Regular.ttf", (205, 245, 232), (18, 30, 36)),
    "v05": ("CinzelDecorative-Bold.ttf", (250, 238, 214), (66, 44, 40)),
    "v06": ("Metamorphous-Regular.ttf", (248, 232, 206), (46, 24, 52)),
    "v07": ("IMFellEnglishSC-Regular.ttf", (248, 238, 214), (52, 44, 36)),
    "v08": ("CinzelDecorative-Bold.ttf", (255, 196, 110), (46, 22, 10)),
    "v09": ("MarcellusSC-Regular.ttf", (226, 240, 190), (30, 44, 30)),
    "v10": ("CinzelDecorative-Bold.ttf", (250, 220, 200), (44, 22, 40)),
}
# formato -> (largura, altura, bruto, centro vertical do recorte, posicao do logo, largura relativa do logo)
FORMATOS = {
    "main_capsule": (1232, 706, "land", 0.5, "bottom", 0.55),
    "header_capsule": (920, 430, "land", 0.55, "bottom", 0.62),
    "small_capsule": (462, 174, "land", 0.5, "fill", 0.90),
    "vertical_capsule": (748, 896, "port", 0.5, "top", 0.80),
    "page_background": (1438, 810, "bg", 0.5, None, 0),
    "library_capsule": (600, 900, "libcap", 0.5, "top", 0.82),
    "library_header": (920, 430, "land", 0.55, "bottom", 0.62),
    "library_hero": (3840, 1240, "wide", 0.5, None, 0),
}


# Ajustes por variante (o logo nunca cobre o rosto do chefe; no maximo o cavaleiro pequeno ou area vazia).
VERTICAIS = ("vertical_capsule", "library_capsule")
HORIZONTAIS = ("main_capsule", "header_capsule", "library_header")
# posicao do logo nos verticais: "bottom" ou "top"
POS_VERTICAL = {"v09": "top", "v10": "top"}
LARGURA_VERTICAL = {"v09": 0.70, "v10": 0.74}   # as demais usam LARGURA_BAIXO
LARGURA_BAIXO = 0.70
# nos horizontais um float e o centro vertical do logo (v10: o meio do portao e a area vazia)
POS_HORIZONTAL = {"v10": 0.44}
# centro vertical do recorte por (variante, formato)
CY = {("v01", "header_capsule"): 0.2, ("v01", "library_header"): 0.2,
      ("v02", "header_capsule"): 0.0, ("v02", "library_header"): 0.0,
      ("v05", "header_capsule"): 0.0, ("v05", "library_header"): 0.0,
      ("v07", "header_capsule"): 0.04, ("v07", "library_header"): 0.04}
# zoom no recorte da arte horizontal, para tirar bordas de papel
ZOOM_LAND = {"v05": 1.12, "v07": 1.04, "v10": 1.05}
# hero: (x do foco, y do foco, zoom) em fracao da arte bruta "wide"; o foco vai para o centro (area segura 860x380)
HERO = {"v02": (0.50, 0.30, 1.10), "v03": (0.48, 0.36, 1.10), "v04": (0.50, 0.33, 1.15), "v06": (0.50, 0.30, 1.12),
        "v07": (0.50, 0.45, 1.00), "v08": (0.46, 0.33, 1.10), "v10": (0.47, 0.56, 1.00)}


def hero(raw, foco):
    fx, fy, z = foco
    esc = max(3840 / raw.width, 1240 / raw.height) * z
    im = raw.resize((round(raw.width * esc), round(raw.height * esc)), Image.LANCZOS)
    x = min(max(round(fx * im.width - 1920), 0), im.width - 3840)
    y = min(max(round(fy * im.height - 620), 0), im.height - 1240)
    return im.crop((x, y, x + 3840, y + 1240))


def logo_img(v, largura, duas_linhas=False):
    fonte, cor, contorno = LOGO[v]
    linhas = TITULO.split(" ") if duas_linhas else [TITULO]
    tam = 400
    f = ImageFont.truetype(os.path.join(FONTS, fonte), tam)
    caixas = [f.getbbox(t, stroke_width=tam // 12) for t in linhas]
    w = max(b[2] - b[0] for b in caixas)
    lh = int(tam * 1.05)
    h = lh * len(linhas)
    pad = tam // 3
    base = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    sombra = Image.new("RGBA", base.size, (0, 0, 0, 0))
    for i, t in enumerate(linhas):
        for im, off, kw in ((sombra, (0, tam // 14), dict(fill=(0, 0, 0, 200), stroke_width=tam // 12, stroke_fill=(0, 0, 0, 200))),
                            (base, (0, 0), dict(fill=cor + (255,), stroke_width=tam // 16, stroke_fill=contorno + (255,)))):
            d = ImageDraw.Draw(im)
            bw = caixas[i][2] - caixas[i][0]
            d.text((pad + (w - bw) // 2 - caixas[i][0] + off[0], pad + i * lh + off[1]), t, font=f, **kw)
    sombra = sombra.filter(ImageFilter.GaussianBlur(tam // 24))
    out = Image.alpha_composite(sombra, base)
    out = out.crop(out.getbbox())
    return out.resize((largura, max(1, round(out.height * largura / out.width))), Image.LANCZOS)


def degrade(img, topo):
    """Escurece a borda onde o logo fica, para ele ler melhor (so nas versoes com logo)."""
    w, h = img.size
    m = Image.new("L", (1, h))
    for y in range(h):
        t = (1 - y / (h * 0.42)) if topo else ((y - h * 0.58) / (h * 0.42))
        m.putpixel((0, y), int(max(0.0, min(1.0, t)) * 150))
    m = m.resize((w, h))
    return Image.composite(Image.new("RGB", (w, h), (12, 8, 18)), img, m)


def fit(raw, w, h, cy):
    return ImageOps.fit(raw, (w, h), Image.LANCZOS, centering=(0.5, cy))


def compor(v):
    raws = {}
    for k in ("land", "port", "wide", "libcap", "bg"):
        p = os.path.join(OUT, "raw", f"{v}_{k}.png")
        if os.path.exists(p):
            raws[k] = Image.open(p).convert("RGB")
    for nome, (w, h, k, cy, pos, rel) in FORMATOS.items():
        if k not in raws:
            continue
        base = raws[k]
        if nome in VERTICAIS:
            pos = POS_VERTICAL.get(v, "bottom")
            rel = LARGURA_VERTICAL.get(v, LARGURA_BAIXO)
        elif nome in HORIZONTAIS:
            pos = POS_HORIZONTAL.get(v, pos)
        cy = CY.get((v, nome), cy)
        if k == "land" and v in ZOOM_LAND:
            z = ZOOM_LAND[v]
            mx, my = round(base.width * (1 - 1 / z) / 2), round(base.height * (1 - 1 / z) / 2)
            topo = 0 if v == "v05" else my                  # v05: o castelo encosta no topo; corta so embaixo
            base = base.crop((mx, topo, base.width - mx, base.height - 2 * my + topo))
        for com in (False, True):
            d = os.path.join(OUT, v, "com_logo" if com else "sem_logo")
            os.makedirs(d, exist_ok=True)
            img = hero(base, HERO.get(v, (0.5, 0.5, 1.0))) if k == "wide" else fit(base, w, h, cy)
            if com and pos:                      # hero e fundo nunca levam logo (so copiados para a pasta ficar completa)
                if pos == "fill":
                    img = ImageEnhance_dim(img)
                    lg = logo_img(v, int(w * rel))
                    if lg.height > h * 0.82:
                        lg = lg.resize((int(lg.width * h * 0.82 / lg.height), int(h * 0.82)), Image.LANCZOS)
                    img.paste(lg, ((w - lg.width) // 2, (h - lg.height) // 2), lg)
                else:
                    lg = logo_img(v, int(w * rel), duas_linhas=(h > w))
                    if isinstance(pos, float):
                        y = round(h * pos - lg.height / 2)
                    else:
                        img = degrade(img, pos == "top")
                        y = int(h * 0.05) if pos == "top" else h - lg.height - int(h * 0.04)
                    img.paste(lg, ((w - lg.width) // 2, y), lg)
            img.save(os.path.join(d, nome + ".png"))
    d = os.path.join(OUT, v, "com_logo")
    os.makedirs(d, exist_ok=True)
    logo_img(v, 1280).save(os.path.join(d, "library_logo.png"))


def ImageEnhance_dim(img):
    return Image.eval(img, lambda x: int(x * 0.55))


if __name__ == "__main__":
    for v in (sys.argv[1:] or sorted(V)):
        compor(v)
        print("ok", v)
