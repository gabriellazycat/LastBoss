"""Teste "pincel grosso" (13/11/2026): repinta a arte aprovada (mesma pose) com pinceladas largas e sem detalhe miúdo.

python -I pincel_grosso.py calibrar rat_king --variante A --denoise 0.55 0.7 0.85
python -I pincel_grosso.py gerar rat_king elder_dragon ranger --denoise 0.75
Saída: arte_ia/pincel_grosso/<card>/<variante>_d<denoise>.png (556x534, grão 0,9); prancha em arte_ia/pranchas/
"""
import argparse, os, sys, zlib
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as grainmod
from deck import crop_final, MODEL, W, H, GRAIN

OUT = os.path.join(gen.ROOT, "pincel_grosso")
R = gen.ROOT
# Pose aprovada: a imagem bruta (sem grão) que já está no baralho; o Patrulheiro vem da rodada minimalista (v1).
BASES = {
    "rat_king": (os.path.join(R, "rat_king", "krea2anime__poster__t2i__s1000.png"), "lilac",
                 "a gaunt old grey rat king seated on a throne of bones and skulls, raising a golden scepter, a gold "
                 "crown and a tattered purple cape, a crowd of grey rats with pink ears spilling forward at his feet."),
    "elder_dragon": (os.path.join(R, "elder_dragon", "krea2anime__deck__t2i__s1001.png"), "teal",
                     "a huge ancient red dragon with a pale yellow belly and long curved horns standing in side view, "
                     "breathing a stream of orange fire, wings raised."),
    "ranger": (os.path.join(R, "minimalista", "ranger", "v1_s1000_raw.png"), "ochre",
               "a hooded ranger in a plain dark green cloak and a plain brown tunic drawing a longbow, an arrow on the string."),
}
MEDIUM = "A gouache painting on rough cold-press paper, scanned from an old sketchbook: "
PAPER = "paper grain showing through, muted dusty colors, slightly blurry low-resolution scan."
VARIANTS = {
    "A": ("Pincel chato largo",
          "Painted with a very wide flat bristle brush in a few bold heavy strokes, every stroke thick and visible, "
          "shapes simplified into big chunks of color, no small details, no thin lines, no small accessories, faces "
          "and eyes reduced to one or two dabs of dark paint, " + PAPER),
    "B": ("Pincel redondo carregado",
          "Painted quickly with a big round brush loaded with thick gouache, chunky rounded strokes that overlap "
          "loosely, all small details dissolved into broad strokes, eyes as single dark dabs, simple two-tone "
          "shading, " + PAPER),
    "C": ("Pinceladas secas grossas",
          "Thick dry-brush gouache strokes with a fat worn brush, rough broken stroke edges, forms built from a few "
          "large flat strokes of color, small details merged into the main shapes, eyes as plain dark dots, " + PAPER),
}
TONE = "Grounded serious fantasy book illustration with natural proportions."


def prompt(card, v):
    _, bg, subj = BASES[card]
    return f"{MEDIUM}{subj} A plain flat {gen.BACKGROUNDS[bg]} sky behind. {TONE} {VARIANTS[v][1]}"


def make(card, v, denoise, seed=1000):
    ref = gen.upload_image(BASES[card][0])
    g, _ = gen.workflow(MODEL, prompt(card, v), seed, W, H, init_image=ref, denoise=denoise)
    png = gen.run(g)
    d = os.path.join(OUT, card)
    os.makedirs(d, exist_ok=True)
    tag = f"{v}_d{int(denoise * 100)}"
    raw = os.path.join(d, f"{tag}_raw.png")
    open(raw, "wb").write(png)
    grainmod.grain(Image.open(raw), seed=zlib.crc32(f"{card}{tag}".encode()), strength=GRAIN).save(raw.replace("_raw", "_grain"))
    crop_final(raw.replace("_raw", "_grain"), os.path.join(d, f"{tag}.png"))
    print(card, tag, flush=True)
    return tag


def prancha(name, rows):
    """rows: [(card, [(label, path), ...])]"""
    cw, ch = 278, 267
    cols = max(len(r[1]) for r in rows)
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 15)
    sheet = Image.new("RGB", (cols * (cw + 10) + 10, len(rows) * (ch + 34) + 10), (29, 26, 23))
    dr = ImageDraw.Draw(sheet)
    for r, (_, cells) in enumerate(rows):
        for k, (label, p) in enumerate(cells):
            x, y = 10 + k * (cw + 10), 10 + r * (ch + 34)
            sheet.paste(Image.open(p).convert("RGB").resize((cw, ch), Image.LANCZOS), (x, y))
            dr.text((x, y + ch + 6), label, fill=(236, 228, 214), font=font)
    out = os.path.join(gen.ROOT, "pranchas", f"{name}.png")
    sheet.save(out)
    print(out)


def atual(card):
    p = os.path.join(R, "final", f"{card}.png")
    return p if os.path.exists(p) else os.path.join(R, "minimalista", card, "v1.png")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["calibrar", "gerar"])
    ap.add_argument("cards", nargs="+")
    ap.add_argument("--variante", default="A")
    ap.add_argument("--denoise", type=float, nargs="+", default=[0.75])
    a = ap.parse_args()
    rows = []
    for c in a.cards:
        cells = [("base (pose)", atual(c))]
        if a.cmd == "calibrar":
            for dn in a.denoise:
                t = make(c, a.variante, dn)
                cells.append((f"{a.variante} denoise {dn}", os.path.join(OUT, c, f"{t}.png")))
        else:
            for v in VARIANTS:
                t = make(c, v, a.denoise[0])
                cells.append((f"{v}. {VARIANTS[v][0]}", os.path.join(OUT, c, f"{t}.png")))
        rows.append((c, cells))
    prancha("pincel_grosso_" + a.cmd, rows)
