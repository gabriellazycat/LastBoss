"""Rebuild arte_ia/gallery.json + thumbnails (arte_ia/_thumbs). index.html reads gallery.json.

python build_gallery.py
"""
import json, os, re, shutil
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GAME = os.path.dirname(ROOT)
TH = os.path.join(ROOT, "_thumbs")


def thumb(src, rel):
    out = os.path.join(TH, rel.replace("/", "__").rsplit(".", 1)[0] + ".jpg")
    if not os.path.exists(out) or os.path.getmtime(out) < os.path.getmtime(src):
        im = Image.open(src).convert("RGB")
        im.thumbnail((360, 360), Image.LANCZOS)
        im.save(out, quality=85)
    return "_thumbs/" + os.path.basename(out)


def main():
    os.makedirs(TH, exist_ok=True)
    names = {}
    for line in open(os.path.join(GAME, "locale", "strings.csv"), encoding="utf-8"):
        if line.startswith("CARD_"):
            k, pt, en = (line.rstrip("\n").split(",") + ["", ""])[:3]
            names[k[5:]] = pt
    cards = []
    for card in sorted(os.listdir(ROOT)):
        d = os.path.join(ROOT, card)
        if card.startswith(("_", ".")) or not os.path.isdir(d):
            continue
        idx = json.load(open(os.path.join(d, "index.json"), encoding="utf-8")) if os.path.exists(os.path.join(d, "index.json")) else {"images": []}
        meta = {e["file"]: e for e in idx["images"]}
        orig = os.path.join(GAME, "assets", "cards", card + ".png")
        if os.path.exists(orig):
            shutil.copyfile(orig, os.path.join(d, "_original.png"))
        items = []
        for f in sorted(os.listdir(d)):
            if not f.endswith(".png"):
                continue
            rel = f"{card}/{f}"
            if f == "_original.png":
                e = dict(model="original", style="code", mode="original", seed="", prompt="Current code-made art (assets/cards).")
            else:
                gm = re.search(r"__grain(\d*)", f)
                base = re.sub(r"__grain\d*", "", f)
                e = dict(meta.get(base, {}))
                if not e:
                    p = base[:-4].split("__")
                    e = dict(model=p[0], style=p[1] if len(p) > 1 else "", mode=p[2] if len(p) > 2 else "", seed=p[3][1:] if len(p) > 3 else "")
                if gm:
                    gs = int(gm.group(1)) / 100 if gm.group(1) else 1.0
                    e["mode"] = str(e.get("mode", "")) + "+grain" + ("" if gs == 1.0 else f"{gs:g}")
                    e["post"] = f"grain.py (non-AI), strength {gs:g}"
            items.append(dict(file=rel, thumb=thumb(os.path.join(d, f), rel), **{k: v for k, v in e.items() if k != "file"}))
        cards.append(dict(id=card, name=names.get(card, card), images=items))
    json.dump(dict(cards=cards), open(os.path.join(ROOT, "gallery.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    print(sum(len(c["images"]) for c in cards), "images in", len(cards), "cards")


if __name__ == "__main__":
    main()
