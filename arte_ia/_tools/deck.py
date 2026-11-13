"""Deck batch driver for the chosen style (see .claude/skills/cartas-ia/SKILL.md). No LLM tokens: pure queue.

python deck.py mestra [--seed 1000]          generate the master card (rat_king, style deck, no reference)
python deck.py aprovar-mestra <file>         freeze arte_ia/rat_king/<file> as the style reference
python deck.py lote plague|dragon|lich|common|base|<ids...>   generate every card of the batch that has a subject
python deck.py refazer <id> [<id>...]        new seed (+1) for those cards, same style and reference
python deck.py prancha <lote>                rebuild the contact sheet only
State: _tools/deck_state.json {card: {"seed": n, "file": ...}}. Finals: arte_ia/final/<id>.png (556x534).
"""
import argparse, json, os, shutil, sys, time
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import gen, grain as grainmod, zlib

T = os.path.dirname(os.path.abspath(__file__))
ROOT = gen.ROOT
MODEL, STYLE, W, H = "krea2anime", "deck", 768, 736   # 12 Nov: ~2x faster than 1056x1024, same look at the 556x534 final
FINAL_W, FINAL_H = 556, 534
MASTER = os.path.join(T, "mestra.png")
STATE = os.path.join(T, "deck_state.json")
GRAIN = 0.9
REF_STRENGTH = 0.6          # only with --ref; the 12 Nov pilot chose text-only (crisper, half the time)


def load(p, d):
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else d


def cards_of(lote):
    cards = json.load(open(os.path.join(ROOT, "cards.json"), encoding="utf-8"))
    if lote in {"plague", "dragon", "lich", "common", "base"}:
        return [c["id"] for c in cards if c["villain"] == lote]
    return [lote]


def crop_final(src, dst):
    im = Image.open(src).convert("RGB")
    s = max(FINAL_W / im.width, FINAL_H / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    l, t = (im.width - FINAL_W) // 2, (im.height - FINAL_H) // 2
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    im.crop((l, t, l + FINAL_W, t + FINAL_H)).save(dst)


def make(card, seed, ref_name, final_dir="final"):
    prompt = gen.build_prompt(card, STYLE)
    if ref_name:
        g, _ = gen.workflow_krea2_ref(gen.MODELS[MODEL], prompt, seed, W, H, ref_name, REF_STRENGTH)
        mode = "ref"
    else:
        g, _ = gen.workflow(MODEL, prompt, seed, W, H)
        mode = "t2i"
    t = time.time()
    png = gen.run(g)
    dt = time.time() - t
    name = f"{MODEL}__{STYLE}__{mode}__s{seed}.png"
    gen.save(card, name, png, dict(model=MODEL, unet=gen.MODELS[MODEL]["unet"], style=STYLE, mode=mode, seed=seed,
                                   denoise=1.0, sigmas="simple", src="mestra.png" if ref_name else "", w=W, h=H,
                                   seconds=round(dt, 1), prompt=prompt, created=time.strftime("%Y-%m-%d %H:%M:%S")))
    path = os.path.join(ROOT, card, name)
    gp = path[:-4] + f"__grain{int(GRAIN * 100)}.png"
    grainmod.grain(Image.open(path), seed=zlib.crc32(name.encode()), strength=GRAIN).save(gp)
    crop_final(gp, os.path.join(ROOT, final_dir, f"{card}.png"))
    print(f"{card} s{seed} {dt:.0f}s", flush=True)
    return os.path.basename(gp)


def names():
    out = {}
    for line in open(os.path.join(gen.GAME, "locale", "strings.csv"), encoding="utf-8"):
        if line.startswith("CARD_"):
            k, pt = line.split(",")[:2]
            out[k[5:]] = pt
    return out


def prancha(lote, ids, final_dir="final"):
    nm = names()
    ids = [c for c in ids if os.path.exists(os.path.join(ROOT, final_dir, f"{c}.png"))]
    if not ids:
        return
    cw, ch, cols = 278, 267, 6
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 15)
    rows = (len(ids) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (cw + 10) + 10, rows * (ch + 34) + 10), (29, 26, 23))
    d = ImageDraw.Draw(sheet)
    for i, c in enumerate(ids):
        x, y = 10 + (i % cols) * (cw + 10), 10 + (i // cols) * (ch + 34)
        sheet.paste(Image.open(os.path.join(ROOT, final_dir, f"{c}.png")).resize((cw, ch), Image.LANCZOS), (x, y))
        d.text((x, y + ch + 6), f"{nm.get(c, c)}  ·  {c}", fill=(236, 228, 214), font=font)
    os.makedirs(os.path.join(ROOT, "pranchas"), exist_ok=True)
    out = os.path.join(ROOT, "pranchas", f"{lote}.png")
    sheet.save(out)
    print(out)


def ref_upload():
    if not os.path.exists(MASTER):
        sys.exit("No master yet: run `deck.py mestra` and `deck.py aprovar-mestra <file>` first.")
    return gen.upload_image(MASTER)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["mestra", "aprovar-mestra", "lote", "refazer", "prancha", "piloto"])
    ap.add_argument("args", nargs="*")
    ap.add_argument("--seed", type=int, default=1000)
    ap.add_argument("--ref", action="store_true", help="also use the master as style reference (default off since 12 Nov pilot)")
    a = ap.parse_args()
    st = load(STATE, {})
    subjects = gen.load_subjects()
    if a.cmd == "mestra":
        make("rat_king", a.seed, None)
    elif a.cmd == "aprovar-mestra":
        shutil.copyfile(os.path.join(ROOT, "rat_king", a.args[0]), MASTER)
        crop_final(MASTER, os.path.join(ROOT, "final", "rat_king.png"))
        st["rat_king"] = {"seed": int(a.args[0].split("__s")[1].split("_")[0].split(".")[0]), "file": a.args[0], "master": True}
        print("master =", a.args[0])
    elif a.cmd == "piloto":                              # same cards with and without the master reference
        ref = ref_upload()
        for mode, r in (("texto", None), ("ref", ref)):
            for c in a.args:
                make(c, a.seed, r, f"final_piloto/{mode}")
            prancha(f"piloto_{mode}", a.args, f"final_piloto/{mode}")
    elif a.cmd in ("lote", "refazer"):
        ref = ref_upload() if a.ref else None
        ids = [c for l in a.args for c in cards_of(l)]
        for c in ids:
            if c not in subjects:
                print(f"{c}: no subject yet, skipped", flush=True)
                continue
            if st.get(c, {}).get("master"):
                continue
            if a.cmd == "lote" and c in st:
                continue                                   # already generated; use `refazer` to change it
            seed = st[c]["seed"] + 1 if (a.cmd == "refazer" and c in st) else a.seed
            st[c] = {"seed": seed, "file": make(c, seed, ref)}
            json.dump(st, open(STATE, "w", encoding="utf-8"), indent=1)
        if a.cmd == "lote" and len(a.args) == 1:
            prancha(a.args[0], cards_of(a.args[0]))
    elif a.cmd == "prancha":
        prancha(a.args[0], cards_of(a.args[0]))
    json.dump(st, open(STATE, "w", encoding="utf-8"), indent=1)


if __name__ == "__main__":
    main()
