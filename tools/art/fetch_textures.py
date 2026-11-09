"""Baixa as texturas de chão (CC0, Poly Haven) usadas pelos looks de chão. Uso: python -I tools/art/fetch_textures.py"""
import json
import os
import sys
import urllib.request

IDS = ["aerial_grass_rock", "grass_path_2", "forest_leaves_02", "mossy_cobblestone", "dry_decay_leaves", "brown_mud_dry",
       "burned_ground_01", "cobblestone_floor_08", "leafy_grass", "mud_cracked_dry_03"]
MAPS = {"Diffuse": "diff", "nor_gl": "nor"}
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "textures", "ground")


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "LastBoss-asset-fetch"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main():
    os.makedirs(OUT, exist_ok=True)
    for tid in IDS:
        files = json.loads(get("https://api.polyhaven.com/files/" + tid))
        for key, short in MAPS.items():
            dst = os.path.join(OUT, "%s_%s.jpg" % (tid, short))
            if os.path.exists(dst):
                continue
            url = files[key]["1k"]["jpg"]["url"]
            if not url.startswith("https://dl.polyhaven.org/"):
                sys.exit("url inesperada: " + url)
            open(dst, "wb").write(get(url))
            print(tid, short, os.path.getsize(dst) // 1024, "KB")


main()
