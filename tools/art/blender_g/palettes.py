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
    "ash_salamander": "ash_salamander", "drakeling": "drakeling", "brown_bear": "brown_bear", "spitting_viper": "spitting_viper",
    "ash_phoenix": "ash_phoenix", "bone_dragon": "bone_dragon", "magma_golem": "magma_golem",
    "villain_plague": "villain_plague", "villain_dragon": "villain_dragon", "villain_lich": "villain_lich",
}
# cenário: média das paletas de cinco cartas de terra (o chão e os fundos das cartas são sálvia, lavanda e areia)
SCENERY = ["slime", "goblin_dynamiter", "ogre", "werewolf", "wolf_pack"]


HAND = {
    "ash_phoenix": [[0.25, [0.45, 0.1, 0.05]], [0.38, [0.75, 0.2, 0.06]], [0.5, [0.95, 0.4, 0.08]], [0.65, [1.0, 0.62, 0.15]], [0.8, [1.0, 0.85, 0.4]]],
    "ash_salamander": [[0.1, [0.07, 0.06, 0.08]], [0.2, [0.14, 0.13, 0.16]], [0.35, [0.45, 0.2, 0.1]], [0.55, [0.95, 0.42, 0.1]], [0.75, [1.0, 0.7, 0.25]]],
    "magma_golem": [[0.1, [0.1, 0.09, 0.1]], [0.2, [0.2, 0.19, 0.21]], [0.3, [0.3, 0.27, 0.28]], [0.5, [0.95, 0.4, 0.1]], [0.75, [1.0, 0.75, 0.3]]],
    "bone_dragon": [[0.35, [0.45, 0.42, 0.38]], [0.5, [0.68, 0.64, 0.55]], [0.65, [0.83, 0.79, 0.68]], [0.78, [0.9, 0.87, 0.78]], [0.9, [0.96, 0.94, 0.88]]],
    "spitting_viper": [[0.2, [0.18, 0.24, 0.1]], [0.35, [0.34, 0.42, 0.16]], [0.5, [0.52, 0.6, 0.25]], [0.7, [0.75, 0.78, 0.45]], [0.88, [0.9, 0.88, 0.65]]],
    "brown_bear": [[0.15, [0.14, 0.09, 0.07]], [0.28, [0.27, 0.17, 0.11]], [0.4, [0.42, 0.27, 0.17]], [0.55, [0.58, 0.4, 0.27]], [0.75, [0.75, 0.6, 0.45]]],
    "drakeling": [[0.2, [0.33, 0.06, 0.07]], [0.32, [0.58, 0.12, 0.1]], [0.45, [0.8, 0.18, 0.12]], [0.65, [0.95, 0.5, 0.35]], [0.85, [1.0, 0.85, 0.6]]],
}


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
    # Modelos novos (17/11/2026): o miolo da carta traz o fundo cinza e apagava a cor; paleta do próprio bicho, à mão.
    res.update(HAND)
    json.dump(res, open(os.path.join(HERE, "palettes.json"), "w"))


main()
