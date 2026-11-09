"""Renderiza tools/art/sketches.html no Chrome sem cabeça e corta em assets/cards/<id>.png (fundo transparente).

Uso: python tools/art/render_sketches.py
Os desenhos são SVG com filtros (tremor do traço) que o importador de SVG da Godot não entende; por isso viram PNG
aqui, uma vez, e o jogo só carrega as imagens.
"""
import os
import re
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HTML = os.path.join(ROOT, "tools", "art", "sketches.html")
OUT = os.path.join(ROOT, "assets", "cards")
CHROME = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
]
COLS, CW, CH = 6, 520, 416


def main() -> int:
    src = open(HTML, encoding="utf-8").read()
    body = src[src.index("const D={"):src.index("};\nconst only")]
    ids = re.findall(r"^([a-z_]+):\[\"", body, re.M)
    rows = (len(ids) + COLS - 1) // COLS
    exe = next((c for c in CHROME if os.path.exists(c)), None)
    if exe is None:
        print("Chrome/Edge não encontrado")
        return 1
    shot = os.path.join(tempfile.mkdtemp(), "sheet.png")
    url = "file:///" + HTML.replace("\\", "/")
    subprocess.run([exe, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    "--default-background-color=00000000", f"--window-size={COLS * CW},{rows * CH}",
                    "--virtual-time-budget=3000", f"--screenshot={shot}", url], check=True, capture_output=True)
    sheet = Image.open(shot).convert("RGBA")
    if sheet.size != (COLS * CW, rows * CH):
        print("folha com tamanho inesperado:", sheet.size)
        return 1
    os.makedirs(OUT, exist_ok=True)
    for i, cid in enumerate(ids):
        x, y = (i % COLS) * CW, (i // COLS) * CH
        cell = sheet.crop((x, y, x + CW, y + CH))
        # Corta a margem vazia (com folga de 4%): a carta escala o desenho para caber, então o desenho enche a área.
        bb = cell.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
        if bb:
            pad = int(max(bb[2] - bb[0], bb[3] - bb[1]) * 0.04)
            cell = cell.crop((max(bb[0] - pad, 0), max(bb[1] - pad, 0), min(bb[2] + pad, CW), min(bb[3] + pad, CH)))
        cell.save(os.path.join(OUT, cid + ".png"), optimize=True)
    print(f"{len(ids)} desenhos em {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
