"""Paleta de cada modelo, tirada da arte da carta dele (assets/cards/<carta>.png): 5 faixas de valor, cor média de
cada uma (sRGB 0..1). Roda com o Python do sistema: python -I palettes.py  ->  palettes.json"""
import json, os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
CARDS = os.path.join(HERE, "..", "..", "..", "assets", "cards")
PORT = os.path.join(HERE, "..", "..", "..", "assets", "ui", "portraits")

# modelo -> carta cuja arte dá a paleta (null = paleta do ato, tirada de duas cartas de cenário)
CARD = {
    "rat": "rat_horde", "rat_king": "rat_king", "goblin_dynamiter": "goblin_dynamiter", "slime": "slime",
    "skeleton": "raised_servant", "ogre": "ogre", "werewolf": "werewolf", "bat": "bat_cloud", "ghost": "ghost",
    "mimic": "mimic", "escudeiro": "hero_escudeiro", "mago": "hero_mago",
    "skeleton_archers": "skeleton_archers", "cultists": "cultists", "spectre": "ghost", "scrap_golem": "scrap_golem",
    "bone_totem": "bone_totem", "bat_nest": "bat_nest", "gargoyle_tower": "gargoyle_tower", "wolf_pack": "wolf_pack",
    "war_boar": "war_boar", "alpha_beast": "alpha_beast", "cave_troll": "cave_troll", "treasure_guard": "treasure_guard",
    "elder_dragon": "elder_dragon", "death_knight": "death_knight", "bone_colossus": "bone_colossus", "ruin_titan": "ruin_titan",
    "arqueira": "hero_arqueira", "cleriga": "hero_cleriga",
    "villain_plague": "villain_plague", "villain_dragon": "villain_dragon", "villain_lich": "villain_lich",
}
# cenário: média das paletas de cinco cartas de terra (o chão e os fundos das cartas são sálvia, lavanda e areia)
SCENERY = ["slime", "goblin_dynamiter", "ogre", "werewolf", "wolf_pack"]


def pal(path):
    im = Image.open(path).convert("RGB")
    im.thumbnail((160, 160))
    a = np.asarray(im, dtype=np.float64) / 255.0
    # a moldura da carta fica de fora: só o miolo
    h, w = a.shape[:2]
    a = a[int(h * 0.1):int(h * 0.9), int(w * 0.1):int(w * 0.9)].reshape(-1, 3)
    L = a @ np.array([0.3, 0.59, 0.11])
    order = np.argsort(L)
    out = []
    for k in range(5):
        sl = order[int(len(order) * k / 5):int(len(order) * (k + 1) / 5)]
        c = a[sl].mean(axis=0)
        out.append([float(L[sl].mean()), [float(x) for x in c]])
    return out


def main():
    res = {}
    for k, card in CARD.items():
        p = os.path.join(CARDS, card + ".png")
        if not os.path.exists(p):
            p = os.path.join(PORT, card + ".png")
        res[k] = pal(p)
        print(k, card, [[round(x, 2) for x in c[1]] for c in res[k]])
    res["scenery"] = [[sum(res[k][b][0] for k in SCENERY) / len(SCENERY), [sum(res[k][b][1][c] for k in SCENERY) / len(SCENERY) for c in range(3)]] for b in range(5)]
    json.dump(res, open(os.path.join(HERE, "palettes.json"), "w"))


main()
