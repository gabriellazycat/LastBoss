"""Gera tools/art/out/steam/index.html (contact sheet das 10 variacoes). python -I indice.py"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from variantes import V
OUT = os.path.abspath(os.path.join(HERE, "..", "out", "steam"))
FMT = ["main_capsule", "header_capsule", "small_capsule", "vertical_capsule", "library_capsule", "library_header", "page_background", "library_hero"]
html = ["<meta charset=utf-8><title>Last Boss - Steam</title><style>body{background:#1a1620;color:#eee;font:14px sans-serif;margin:20px}"
        "img{max-width:100%;border:1px solid #444;margin:3px}.r{display:flex;flex-wrap:wrap;align-items:flex-start}h2{margin-top:40px}"
        ".s{max-width:300px}</style><h1>Last Boss - imagens da Steam (10 variacoes)</h1>"]
for v, d in V.items():
    if not os.path.isdir(os.path.join(OUT, v)):
        continue
    html.append(f"<h2>{v} - {d['nome']}</h2>")
    for sub in ("com_logo", "sem_logo"):
        html.append(f"<h3>{sub}</h3><div class=r>")
        for f in FMT + (["library_logo"] if sub == "com_logo" else []):
            p = f"{v}/{sub}/{f}.png"
            if os.path.exists(os.path.join(OUT, p)):
                html.append(f"<a href='{p}'><img class=s src='{p}' title='{f}'></a>")
        html.append("</div>")
open(os.path.join(OUT, "index.html"), "w", encoding="utf-8").write("\n".join(html))
print("index.html ok")
