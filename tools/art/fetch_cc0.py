"""Baixa os modelos CC0 da direção de arte "Aventura CC0" (hoje só os heróis KayKit são usados).

Fontes oficiais:
- KayKit (Kay Lousberg), repositórios oficiais em github.com/KayKit-Game-Assets, LICENSE.txt = CC0 1.0.
- Quaternius, hospedados no Poly Pizza (poly.pizza/u/Quaternius), licença CC0 1.0 indicada na página.

Uso: python -I tools/art/fetch_cc0.py <pasta de download>
Grava os .glb/.gltf brutos na pasta (fora do repositório); o import_cc0.gd converte os escolhidos para
assets/models/cc0/. Confere o autor e a licença de cada página antes de baixar e para se não baterem.
"""
import json
import os
import re
import subprocess
import sys
import urllib.request

UA = {"User-Agent": "Mozilla/5.0 (LastBoss asset fetch)"}

KAYKIT = [
    "Character-Pack-Adventures-1.0",
    "Character-Pack-Skeletons-1.0",
    "Dungeon-Remastered-1.0",
    "Halloween-Bits-1.0",
]

# id do jogo -> (página do Poly Pizza, nome esperado)
QUATERNIUS = {
    "bat": ("hNO9XvjlKa", "Bat"),
    "rat": ("iltq5bVNaV", "Rat"),
    "slime": ("LyjSUKHKnh", "Slime"),
    "pink_slime": ("AyP8sQmDLh", "Pink Slime"),
    "ghost": ("Iip30bDHmu", "Ghost"),
    "ghost_skull": ("TX8r9WBXpe", "Ghost Skull"),
    "orc": ("Q3z8ZX4kUy", "Orc Enemy"),
    "giant": ("BldaiPtyJa", "Giant"),
    "yeti": ("xtMYEVzyw0", "Yeti"),
    "goblin": ("OdCOFSmEhl", "Goblin"),
    "wolf": ("P1gU3Qkr9r", "Wolf"),
    "mimic": ("B8HrWzkuNp", "Mimic"),
}


def get(url: str) -> bytes:
    for tries in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=180) as r:
                return r.read()
        except OSError as e:
            print("  repetindo", url, e)
    sys.exit("falhou: " + url)


def main() -> None:
    out = os.path.abspath(sys.argv[1])
    os.makedirs(out, exist_ok=True)
    for repo in KAYKIT:
        dst = os.path.join(out, "kk-" + repo)
        if not os.path.isdir(dst):
            subprocess.run(["git", "clone", "-q", "--depth", "1",
                            "https://github.com/KayKit-Game-Assets/KayKit-%s.git" % repo, dst], check=False)
        lic = open(os.path.join(dst, "LICENSE.txt"), encoding="utf-8", errors="replace").read()
        if "CC0" not in lic and "Creative Commons Zero" not in lic:
            sys.exit("licença inesperada em " + repo)
        print("ok kaykit", repo)
    qd = os.path.join(out, "quaternius")
    os.makedirs(qd, exist_ok=True)
    sources = {}
    for gid, (page, name) in QUATERNIUS.items():
        html = get("https://poly.pizza/m/" + page).decode("utf-8", "replace")
        if "Quaternius" not in html or "CC0" not in html:
            sys.exit("autor/licença não conferem: " + page)
        m = re.search(r"https://static\.poly\.pizza/([0-9a-f-]{36})\.glb", html)
        if not m:
            sys.exit("sem .glb: " + page)
        url = m.group(0)
        p = os.path.join(qd, gid + ".glb")
        if not os.path.exists(p) or os.path.getsize(p) == 0:
            data = get(url)
            open(p + ".part", "wb").write(data)
            os.replace(p + ".part", p)
        sources[gid] = {"name": name, "page": "https://poly.pizza/m/" + page, "file": url, "author": "Quaternius", "license": "CC0 1.0"}
        print("ok quaternius", gid, name)
    json.dump(sources, open(os.path.join(qd, "sources.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
