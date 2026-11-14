"""Rodada 8 (13/11/2026): a IA repinta o A1 já sabendo da textura de esponja das artes antigas (não é filtro).
Pose e quantidade de elementos = A1 (pincel_grosso_a.py); o Patrulheiro com menos detalhe e sombra mais simples.

Três modos (mesmo assunto, mesma semente):
  T  texto     — rascunho = A1; a esponja descrita no prompt;
  F  rascunho  — rascunho = A1 com a esponja por cor (guache_esponja2.py, F2): a IA repinta a textura que já vê;
  R  referência — rascunho = A1 + a arte antiga (bone_legion) como referência de estilo (LoRA krea2_style_reference).

python -I esponja_ia.py [--modos T F R] [--cards rat_king elder_dragon ranger]
Saída: arte_ia/esponja_ia/<card>/<modo>.png; prancha arte_ia/pranchas/esponja_ia.png
"""
import argparse, os, sys, zlib
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as gm
import pincel_grosso as pg, pincel_grosso_a as pa, guache_rala as gr, guache_esponja2 as ge
from deck import crop_final, MODEL, W, H

OUT = os.path.join(gen.ROOT, "esponja_ia")
REF = os.path.join(gen.ROOT, "_backup_assets_cards", "bone_legion.png")
MEDIUM = "A flat gouache poster painting on rough paper, scanned from an old sketchbook: "
SUBJ = dict(pa.SUBJ)
SUBJ["ranger"] = ("ochre", "a hooded ranger in a plain dark green cloak and a plain brown tunic tied with a plain "
                  "cloth sash, drawing a plain wooden longbow, an arrow on the string. His clothes are painted as "
                  "large plain shapes with one flat shadow tone.")
SPONGE = ("Large flat shapes of color, each color area mottled with soft fluffy speckles of a lighter tint of the "
          "same color, as if the paint was dabbed on with a natural sea sponge, every color with its own sponge "
          "pattern. The background sky has bigger, stronger sponge mottling; the figure has finer, subtler mottling. "
          "Eyes as one small dark dot, muted dusty colors.")
TONE = "Grounded serious fantasy book illustration with natural proportions."
DENOISE = {"T": 0.6, "F": 0.5, "R": 0.6}
NOMES = {"T": "esponja no texto", "F": "repinta a esponja", "R": "arte antiga de referência"}


def prompt(card):
    bg, subj = SUBJ[card]
    return f"{MEDIUM}{subj} A plain flat {gen.BACKGROUNDS[bg]} sky behind. {TONE} {SPONGE}"


def base_a1(card):
    src = Image.open(os.path.join(pa.OUT, card, "A1_raw.png")).convert("RGB")
    return gr.achatar(src) if card == "ranger" else src


def workflow_ref_i2i(p, seed, init_name, ref_name, denoise, strength=0.6):
    g, _ = gen.workflow_krea2_ref(gen.MODELS[MODEL], p, seed, W, H, ref_name, strength)
    g["30"] = {"class_type": "LoadImage", "inputs": {"image": init_name}}
    g["31"] = {"class_type": "ImageScale", "inputs": {"image": ["30", 0], "upscale_method": "lanczos",
                                                      "width": W, "height": H, "crop": "center"}}
    g["10"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["31", 0], "vae": ["3", 0]}}
    g["15"]["inputs"]["denoise"] = denoise
    return g


def make(card, modo, seed=1000):
    d = os.path.join(OUT, card)
    os.makedirs(d, exist_ok=True)
    init = os.path.join(d, f"_init_{modo}.png")
    if modo == "F":
        ge.esponja2(base_a1(card), zlib.crc32(f"{card}F2".encode()), 0.32, 1.15, 1.4)[0].save(init)
    else:
        base_a1(card).save(init)
    p = prompt(card)
    init_name = gen.upload_image(init)
    if modo == "R":
        g = workflow_ref_i2i(p, seed, init_name, gen.upload_image(REF), DENOISE[modo])
    else:
        g, _ = gen.workflow(MODEL, p, seed, W, H, init_image=init_name, denoise=DENOISE[modo])
    raw = os.path.join(d, f"{modo}_raw.png")
    open(raw, "wb").write(gen.run(g))
    crop_final(raw, os.path.join(d, f"{modo}.png"))       # sem grain.py: a textura agora vem da pintura
    open(os.path.join(d, f"{modo}.txt"), "w", encoding="utf-8").write(f"denoise {DENOISE[modo]}\n{p}\n")
    print(card, modo, flush=True)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--modos", nargs="+", default=["T", "F", "R"])
    ap.add_argument("--cards", nargs="+", default=list(SUBJ))
    a = ap.parse_args()
    for c in a.cards:
        for m in a.modos:
            make(c, m)
    rows = [(c, [(f"{pa.NAMES[c]} · A1", os.path.join(pa.OUT, c, "A1.png"))] +
             [(f"{m}. {NOMES[m]}", os.path.join(OUT, c, f"{m}.png")) for m in ("T", "F", "R")
              if os.path.exists(os.path.join(OUT, c, f"{m}.png"))]) for c in SUBJ]
    pg.prancha("esponja_ia", rows)
