"""Put the AI deck into the game. Idempotent; backs up first.

python -I arte_ia/_tools/integrar.py
- copies the current assets/cards/<id>.png to arte_ia/_backup_assets_cards/<id>.png (only the first time, so the
  backup always holds the pre-AI art)
- copies arte_ia/final/<id>.png to assets/cards/<id>.png (556x534, same size the game used)
- adds every card id to data/card_art.json "painted" (so the hand of every skin uses the painted art)
"""
import json, os, shutil
from PIL import Image

T = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(T)
GAME = os.path.dirname(ROOT)
cards = [c["id"] for c in json.load(open(os.path.join(ROOT, "cards.json"), encoding="utf-8"))]
bk = os.path.join(ROOT, "_backup_assets_cards")
os.makedirs(bk, exist_ok=True)
done, missing = [], []
for c in cards:
    src = os.path.join(ROOT, "final", f"{c}.png")
    dst = os.path.join(GAME, "assets", "cards", f"{c}.png")
    if not os.path.exists(src):
        missing.append(c)
        continue
    if os.path.exists(dst) and not os.path.exists(os.path.join(bk, f"{c}.png")):
        shutil.copyfile(dst, os.path.join(bk, f"{c}.png"))
    im = Image.open(src)
    assert im.size == (556, 534), (c, im.size)
    shutil.copyfile(src, dst)
    done.append(c)
p = os.path.join(GAME, "data", "card_art.json")
j = json.load(open(p, encoding="utf-8"))
j["painted"] = sorted(set(j.get("painted", [])) | set(done))
j["_doc"] = ("Cartas com a arte pintada (IA local, estilo B, 12/11/2026; arte_ia/). A mão de todas as peles usa "
             "assets/cards/<id>.png no lugar do retrato 3D para estas.")
with open(p, "w", encoding="utf-8", newline="\n") as f:
    f.write(json.dumps(j, indent="\t", ensure_ascii=False) + "\n")
print(f"integradas {len(done)}; faltando {missing}; painted {len(j['painted'])}")
