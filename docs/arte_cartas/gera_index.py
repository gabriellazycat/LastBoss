"""Gera docs/arte_cartas/index.html: todas as pranchas por vilão, com links para composição e comparação.
uso: python docs/arte_cartas/gera_index.py"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
LOTES = [("Praga", ["praga_1", "praga_2", "praga_3"]),
         ("Dragão", ["dragao_1", "dragao_2", "dragao_3"]),
         ("Lich", ["lich_1", "lich_2", "lich_3"]),
         ("Comuns", ["comuns_1", "comuns_2"])]

parts = []
for vil, lotes in LOTES:
    parts.append(f'<h2>{vil}</h2>')
    for l in lotes:
        p = os.path.join(HERE, l, "prancha.png")
        if not os.path.exists(p):
            parts.append(f'<p class="pend">{l}: prancha ainda não gerada</p>')
            continue
        links = [f'<a href="{l}/prancha.html">prancha interativa</a>']
        for f, t in (("comparacao.png", "composição × acabamento"), ("comp/folha.png", "folha da composição")):
            if os.path.exists(os.path.join(HERE, l, f)):
                links.append(f'<a href="{l}/{f}">{t}</a>')
        parts.append(f'<section><h3>{l} · {" · ".join(links)}</h3><a href="{l}/prancha.png"><img src="{l}/prancha.png" alt="prancha {l}"></a></section>')

caps = []
cdir = os.path.join(HERE, "capturas")
if os.path.isdir(cdir):
    for v in sorted(os.listdir(cdir)):
        for f in sorted(os.listdir(os.path.join(cdir, v))):
            if f.endswith(".png"):
                caps.append(f'<figure><a href="capturas/{v}/{f}"><img src="capturas/{v}/{f}"></a><figcaption>{v} · {f[:-4]}</figcaption></figure>')

html = f"""<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Arte das cartas</title>
<style>
:root{{--bg:#efe4cc;--ink:#2a1a10;--mut:#6b5440;--line:#c9b48e}}
@media (prefers-color-scheme:dark){{:root{{--bg:#1c1612;--ink:#efe4cc;--mut:#b8a488;--line:#4a3a2a}}}}
body{{margin:0;background:var(--bg);color:var(--ink);font-family:Georgia,serif}}
main{{max-width:1340px;margin:0 auto;padding:24px 16px 80px}}
h1{{margin:0 0 4px}} h2{{border-bottom:2px solid var(--line);padding-bottom:4px;margin-top:40px}}
h3{{font-size:15px;font-weight:normal;color:var(--mut)}} a{{color:inherit}}
img{{max-width:100%;height:auto;display:block;border-radius:6px}}
.pend{{color:var(--mut);font-style:italic}}
.caps{{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:16px}}
figure{{margin:0}} figcaption{{font-size:13px;color:var(--mut)}}
</style></head><body><main>
<h1>Arte das cartas do Last Boss</h1>
<p>Composição dinâmica (SVG calcado das fichas) + acabamento Blender com nanquim e aquarela solta; moldura A, nome embaixo.
Cada prancha mostra a carta grande e na mão a 150 px sobre a arena escura. Relatório: <a href="RELATORIO.md">RELATORIO.md</a> ·
estudo: <a href="ESTUDO_TCG.md">ESTUDO_TCG.md</a>.</p>
{''.join(parts)}
<h2>No jogo</h2><div class="caps">{''.join(caps)}</div>
</main></body></html>"""
open(os.path.join(HERE, "index.html"), "w", encoding="utf-8").write(html)
print("ok")
