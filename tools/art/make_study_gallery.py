"""Galeria do estudo de arte (docs/ESTUDO_DE_ARTE.md): cada cena lado a lado em todas as direções.

Uso: python -I tools/art/make_study_gallery.py <pasta do capture_dirs.sh>
Grava docs/variacoes/estudo/img/<dir>_<cena>.jpg (1920x1080) e mini/<...>.jpg (960 px),
docs/variacoes/estudo/fps.txt e docs/variacoes/estudo/galeria.html (abre direto no navegador).
"""
import html
import os
import re
import shutil
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "docs", "variacoes", "estudo")

DIRS = [
    ("C", "C · Padrão atual", "Escolha de 07/11, corrigida em 08/11."),
    ("D", "D · Aventura, dia", "KayKit + Quaternius (CC0), animados; luz de dia estilo Risk of Rain 2."),
    ("E", "E · Aventura, noite", "Os mesmos modelos; noite fria e contraste alto (Soulstone)."),
    ("F", "F · Própria refinada", "Nossos modelos refeitos (look 6) na luz nova."),
    ("A", "A · Pintado (08/11)", "Direção anterior, para comparar."),
    ("B", "B · Cartum (08/11)", "Direção anterior, para comparar."),
]
SCENES = [
    ("horda", "Horda (160 unidades)"),
    ("estrada", "Estrada"),
    ("oferta", "Oferta de cartas"),
    ("arena", "Arena (fora do escopo: chefe e arena antigos)"),
]


def fps_table(src):
    p = os.path.join(src, "fps.txt")
    if not os.path.exists(p):
        return {}
    acc = {}
    for line in open(p, encoding="utf-8"):
        m = re.match(r"(\w+) rodada\d+ .*fps_med=(\d+) fps_min=(\d+)", line)
        if m:
            acc.setdefault(m.group(1), []).append((int(m.group(2)), int(m.group(3))))
    shutil.copy(p, os.path.join(OUT, "fps.txt"))
    return {k: (round(sum(a for a, _ in v) / len(v)), min(b for _, b in v)) for k, v in acc.items()}


def main():
    src = os.path.abspath(sys.argv[1])
    os.makedirs(os.path.join(OUT, "img"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "mini"), exist_ok=True)
    fps = fps_table(src)
    for d, _, _ in DIRS:
        for s, _ in SCENES:
            p = os.path.join(src, "%s_%s.png" % (d, s))
            if not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGB")
            im.save(os.path.join(OUT, "img", "%s_%s.jpg" % (d, s)), quality=86, optimize=True)
            im.resize((960, 540), Image.LANCZOS).save(os.path.join(OUT, "mini", "%s_%s.jpg" % (d, s)), quality=82, optimize=True)
    cards = []
    for d, title, note in DIRS:
        f = fps.get(d)
        ftxt = "%d FPS médio, mínimo %d (500 unidades)" % f if f else ""
        cards.append('<div class="dir"><h3>%s</h3><p>%s</p><p class="fps">%s</p></div>' % (html.escape(title), html.escape(note), ftxt))
    rows = []
    for s, stitle in SCENES:
        cells = []
        for d, title, _ in DIRS:
            mini = "mini/%s_%s.jpg" % (d, s)
            if os.path.exists(os.path.join(OUT, mini)):
                cells.append('<figure><a href="img/%s_%s.jpg"><img src="%s" loading="lazy" alt="%s, %s"></a><figcaption>%s</figcaption></figure>'
                             % (d, s, mini, html.escape(title), html.escape(stitle), html.escape(title)))
        rows.append('<section><h2>%s</h2><div class="grid">%s</div></section>' % (html.escape(stitle), "".join(cells)))
    page = """<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Estudo de arte</title><style>
:root{--bg:#14121a;--fg:#ece8f2;--muted:#a69fb4;--card:#1f1c27;--line:#33303d;--acc:#e8b45a}
@media (prefers-color-scheme: light){:root:not([data-theme="dark"]){--bg:#f6f4f8;--fg:#1d1a24;--muted:#5e5869;--card:#fff;--line:#ddd8e4;--acc:#9a6a12}}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,sans-serif}
main{max-width:1500px;margin:0 auto;padding:24px 16px}
h1{margin:0 0 4px}h2{margin:32px 0 12px;font-size:20px}h3{margin:0 0 4px;font-size:16px}
.lead{color:var(--muted);margin:0 0 20px}
.dirs{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:12px}
.dir{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:12px}.dir p{margin:0;color:var(--muted);font-size:14px}
.fps{color:var(--acc)!important;margin-top:6px!important}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(440px,1fr));gap:12px}
figure{margin:0;background:var(--card);border:1px solid var(--line);border-radius:8px;overflow:hidden}
figure img{display:block;width:100%%;height:auto}figcaption{padding:6px 10px;font-size:14px}
@media (max-width:500px){.grid{grid-template-columns:1fr}}
</style></head><body><main>
<h1>Estudo de arte · Last Boss</h1>
<p class="lead">Referências: Risk of Rain 2, Soulstone Survivors, Megabonk. Para escolher: Configurações → Visual → Direção de arte. Clique numa foto para ver em 1920x1080. Texto completo: docs/ESTUDO_DE_ARTE.md.</p>
<div class="dirs">%s</div>
%s
</main></body></html>
""" % ("".join(cards), "".join(rows))
    open(os.path.join(OUT, "galeria.html"), "w", encoding="utf-8").write(page)
    print("galeria:", os.path.join(OUT, "galeria.html"), "fps:", fps)


if __name__ == "__main__":
    main()
