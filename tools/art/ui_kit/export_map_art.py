"""Arte das telas especiais da pele "Mapa aberto" tirada das maquetes aprovadas (docs/ui_propostas/escolher.html).

Uso (com o servidor da raiz do repositório na porta 8766, .claude/launch.json "ui-propostas"):
    python -I tools/art/ui_kit/export_map_art.py
Saída em assets/ui/map/:
  bg_<tela>.png  — só o fundo desenhado (papel, estradas, bosques, rio, rosa dos ventos), transparente fora do papel,
                   recortado no retângulo do papel + MARGIN px. O jogo põe por cima lugares, textos, cartas e botões
                   nas mesmas coordenadas da maquete (papel em PAPER[tela] na tela de 1920x1080).
  icon_<símbolo>.svg — os desenhos a tinta (covil, biblioteca, torre, moinho, barco, tenda, serviços...).
  node_<símbolo>.svg / node_<símbolo>_hot.svg — o lugar do mapa: anel duplo com o desenho; "hot" = anel vermelho.
"""
import re
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
PAGE = ROOT / "docs" / "ui_propostas" / "escolher.html"
OUT = ROOT / "assets" / "ui" / "map"
OUT.mkdir(parents=True, exist_ok=True)
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
URL = "http://localhost:8766/docs/ui_propostas/escolher.html?solo=6&bg=1&tela="
MARGIN = 24
# retângulo do papel de cada tela na maquete (x, y, largura, altura)
PAPER = {"menuA": (140, 60, 1640, 960), "lojaB": (140, 90, 1640, 900), "colA": (140, 60, 1640, 960)}
INK = "#3a2a1c"
RED = "#a8323a"


def render_bg(tela):
    shot = OUT / f"_tmp_{tela}.png"
    with tempfile.TemporaryDirectory() as prof:
        for _ in range(3):
            try:
                subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", f"--user-data-dir={prof}",
                                "--window-size=1920,1080", "--default-background-color=00000000", "--virtual-time-budget=6000",
                                f"--screenshot={shot}", URL + tela], timeout=100, capture_output=True)
            except subprocess.TimeoutExpired:
                continue
            if shot.exists():
                break
    im = Image.open(shot).convert("RGBA")
    x, y, w, h = PAPER[tela]
    im.crop((x - MARGIN, y - MARGIN, x + w + MARGIN, y + h + MARGIN)).save(OUT / f"bg_{tela}.png")
    shot.unlink()
    print("ok fundo", tela)


def symbols():
    s = PAGE.read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r'<symbol id="([\w-]+)" viewBox="([\d.\s-]+)"[^>]*>(.*?)</symbol>', s, re.S):
        out[m.group(1)] = (m.group(2), m.group(3))
    return out


def write_svgs():
    sy = symbols()
    # desenhos usados pelo jogo (os de paisagem já vão no fundo)
    want = ["m-lair", "m-library", "m-tower", "m-mill", "m-boat", "m-tent", "m-house", "m-tree", "m-pine", "m-mount",
            "m-rat", "m-serpent", "m-bosque", "s-up", "s-cheap", "s-remove", "s-relic"]
    defs = "".join(f'<symbol id="{k}" viewBox="{v[0]}">{v[1]}</symbol>' for k, v in sy.items() if k.startswith(("m-", "s-")))
    for k in want:
        vb, body = sy[k]
        # ícone solto: o desenho com os símbolos de que ele depende
        (OUT / f"icon_{k}.svg").write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="{vb}" width="256" height="{int(256 * float(vb.split()[3]) / float(vb.split()[2]))}">'
            f'<defs>{defs}</defs>{body}</svg>'.replace('href="#', 'xlink:href="#'), encoding="utf-8")
    # lugar do mapa: anel duplo + desenho (normal e aceso)
    for k in ["m-lair", "m-library", "m-tower", "m-mill", "m-boat", "m-tent", "s-up", "s-cheap", "s-remove", "s-relic"]:
        vb = sy[k][0]
        # sem <svg> aninhado: o leitor de SVG da Godot ignora o viewBox dele (o desenho saía pequeno no canto)
        sc = 70.0 / max(float(vb.split()[2]), float(vb.split()[3]))
        for hot in (False, True):
            ring = RED if hot else INK
            svg = (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 120 120" width="240" height="240">'
                   f'<defs>{defs}</defs>'
                   f'<circle cx="60" cy="60" r="56" fill="#e8d6a8" stroke="{ring}" stroke-width="{5 if hot else 4}"/>'
                   f'<circle cx="60" cy="60" r="47" fill="none" stroke="{INK}" stroke-width="2"/>'
                   f'<g transform="translate({25 + (70 - float(vb.split()[2]) * sc) / 2:.2f},{24 + (70 - float(vb.split()[3]) * sc) / 2:.2f}) scale({sc:.4f})">{sy[k][1]}</g></svg>').replace('href="#', 'xlink:href="#')
            (OUT / f"node_{k}{'_hot' if hot else ''}.svg").write_text(svg, encoding="utf-8")
    print("ok svgs")


if __name__ == "__main__":
    import sys
    write_svgs()
    if "--svgs" not in sys.argv:
        for t in PAPER:
            render_bg(t)
