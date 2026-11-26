"""Gera a arte bruta da Steam: python -I gerar.py <formato> [v01 v02 ...]   formatos: land port wide bg libcap
Salva em tools/art/out/steam/raw/<v>_<formato>.png. Pula o que ja existe. GPU: uma imagem por vez."""
import sys, os, io
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "arte_ia", "_tools")))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, estilo, deck_novo
from PIL import Image
from variantes import V, SEED
SIZE = {"land": (1232, 704), "port": (752, 896), "wide": (2048, 832), "bg": (1440, 816), "libcap": (608, 912)}
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "out", "steam", "raw"))


def prompt(v, fmt):
    d = V[v]
    scene = d["bg"] if fmt == "bg" else d["port"] if fmt in ("port", "libcap") else d["wide"] if fmt == "wide" else d["land"]
    return f"{estilo.MEDIUM}{estilo.adapt_subject(scene)} {d['pal']} {estilo.TONE} {estilo.BRUSH}{estilo.TEXTURE}"


def make(v, fmt):
    out = os.path.join(OUT, f"{v}_{fmt}.png")
    if os.path.exists(out):
        return
    w, h = SIZE[fmt]
    g, _ = gen.workflow("krea2anime", prompt(v, fmt), 2000 + int(v[1:]) + SEED.get((v, fmt), 0), w, h)
    img = Image.open(io.BytesIO(gen.run(g))).convert("RGB")
    os.makedirs(OUT, exist_ok=True)
    img.save(out)
    print(v, fmt, img.size, flush=True)


if __name__ == "__main__":
    fmt = sys.argv[1]
    for v in (sys.argv[2:] or sorted(V)):
        deck_novo.com_retentativa(make, v, fmt)
