"""Teste de estilo minimalista (13/11/2026): 5 variações de guache mais simples, sem tocar no estilo "deck".

python -I minimalista.py rat_king elder_dragon ranger [--seed 1000]
Saída: arte_ia/minimalista/<card>/v<N>.png (556x534, grão 0,9) e arte_ia/pranchas/minimalista.png
"""
import argparse, json, os, sys, time, zlib
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as grainmod
from deck import crop_final, MODEL, W, H, GRAIN

OUT = os.path.join(gen.ROOT, "minimalista")
PAPER = "paper grain showing through, muted dusty colors, slightly blurry low-resolution scan."
EYES = "eyes as tiny plain dark dots with no highlight"

# Mesmo meio do baralho (guache pôster, papel, cores apagadas); só a quantidade de detalhe muda.
VARIANTS = {
    1: ("Pôster enxuto",
        "A flat gouache poster painting on rough cold-press paper, scanned from an old sketchbook: ",
        f"Bold flat shapes of opaque gouache in a small palette of four colors, large simple shapes with no small "
        f"details, faces simplified to a few flat planes, {EYES}, simple two-tone shading with light from the upper "
        f"left, dry-brush texture inside each shape, {PAPER}"),
    2: ("Esboço rápido",
        "A quick loose gouache sketch painted in a few minutes on rough cold-press paper, scanned from an old sketchbook: ",
        f"A handful of fast broad strokes with a large flat brush, each stroke visible and unblended, ragged unfinished "
        f"edges, no fine details anywhere, {EYES}, small palette of muted colors, {PAPER}"),
    3: ("Silhueta",
        "A flat gouache poster painting on rough cold-press paper, scanned from an old sketchbook: ",
        f"Large flat silhouette shapes of opaque gouache in three or four colors, almost no interior detail, features "
        f"reduced to a few brush marks, {EYES}, one flat shadow tone, dry-brush edges, {PAPER}"),
    4: ("Pincel largo",
        "A gouache painting made alla prima with a wide flat brush on rough cold-press paper, scanned from an old sketchbook: ",
        f"Thick blocky strokes, forms carved from a few big planes of color, crisp brush-edge marks, no small details "
        f"inside the shapes, {EYES}, light from the upper left, {PAPER}"),
    5: ("Manchas soltas",
        "A simple gouache painting on rough cold-press paper, scanned from an old sketchbook: ",
        f"Big soft patches of color laid quickly with a loaded brush, a few loose dry-brush accents, minimal detail, "
        f"{EYES}, limited palette, lots of bare paper texture, {PAPER}"),
}

# Assuntos mais curtos que os do baralho: menos objetos, menos partes.
SUBJECTS = {
    "rat_king": ("lilac", "a gaunt old grey rat king with pink ears and a long pink tail sitting on a simple throne of "
                 "bones, raising a golden scepter in his right hand. A gold crown on his head and a tattered purple "
                 "cape. Three grey rats run forward at his feet."),
    "elder_dragon": ("teal", "a huge ancient red dragon with a pale yellow belly and long curved horns, standing on "
                     "all four legs in side view with its head stretched forward, breathing one straight stream of "
                     "orange fire toward the right. Both wings half-open above its back."),
    "ranger": ("ochre", "a lone hooded human ranger in a dark green hooded cloak and brown leather armor, standing in "
               "three-quarter view and drawing a longbow with both hands, an arrow on the string. A quiver of arrows "
               "on the back."),
}
TONE = "Grounded serious fantasy book illustration with natural proportions, every limb and object whole and readable."
NAMES = {"rat_king": "Rei dos Ratos", "elder_dragon": "Dragão Ancião", "ranger": "Patrulheiro"}


def prompt(card, v):
    bg, subj = SUBJECTS[card]
    _, medium, texture = VARIANTS[v]
    return f"{medium}{subj} A plain flat {gen.BACKGROUNDS[bg]} sky behind. {TONE} {texture}"


def make(card, v, seed):
    p = prompt(card, v)
    g, _ = gen.workflow(MODEL, p, seed, W, H)
    t = time.time()
    png = gen.run(g)
    d = os.path.join(OUT, card)
    os.makedirs(d, exist_ok=True)
    raw = os.path.join(d, f"v{v}_s{seed}_raw.png")
    open(raw, "wb").write(png)
    gp = raw.replace("_raw", "_grain")
    grainmod.grain(Image.open(raw), seed=zlib.crc32(os.path.basename(raw).encode()), strength=GRAIN).save(gp)
    crop_final(gp, os.path.join(d, f"v{v}.png"))
    json.dump({"prompt": p, "seed": seed, "seconds": round(time.time() - t, 1)},
              open(os.path.join(d, f"v{v}.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print(f"{card} v{v} {time.time() - t:.0f}s", flush=True)


def prancha():
    cards = [c for c in SUBJECTS if os.path.isdir(os.path.join(OUT, c))]
    cw, ch = 278, 267
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 15)
    ref = os.path.join(gen.ROOT, "final")
    cols = 6                                       # coluna 0 = arte atual do baralho, 1-5 = variações
    sheet = Image.new("RGB", (cols * (cw + 10) + 10, len(cards) * (ch + 34) + 10), (29, 26, 23))
    dr = ImageDraw.Draw(sheet)
    for r, c in enumerate(cards):
        for k in range(cols):
            p = os.path.join(ref, f"{c}.png") if k == 0 else os.path.join(OUT, c, f"v{k}.png")
            x, y = 10 + k * (cw + 10), 10 + r * (ch + 34)
            if os.path.exists(p):
                sheet.paste(Image.open(p).convert("RGB").resize((cw, ch), Image.LANCZOS), (x, y))
            label = "atual" if k == 0 else f"{k}. {VARIANTS[k][0]}"
            dr.text((x, y + ch + 6), f"{NAMES[c]} · {label}", fill=(236, 228, 214), font=font)
    out = os.path.join(gen.ROOT, "pranchas", "minimalista.png")
    sheet.save(out)
    print(out)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cards", nargs="*")
    ap.add_argument("--seed", type=int, default=1000)
    ap.add_argument("--so-prancha", action="store_true")
    a = ap.parse_args()
    if not a.so_prancha:
        for c in a.cards:
            for v in VARIANTS:
                make(c, v, a.seed)
    prancha()
