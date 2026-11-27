"""Página de antes/depois dos modelos 3D (revisão de 27/11/2026).
python tools/gallery/models_page.py <pasta>   (a pasta tem antes/, depois/, vereditos.json e, se houver, jogo/)
Gera <pasta>/index.html e copia a arte das cartas para <pasta>/cartas/. Servir com: python -m http.server -d <pasta>"""
import html, json, os, shutil, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
base = os.path.abspath(sys.argv[1])
ant = json.load(open(os.path.join(base, "antes", "manifest.json"), encoding="utf8"))
dep_path = os.path.join(base, "depois", "manifest.json")
dep = json.load(open(dep_path, encoding="utf8")) if os.path.exists(dep_path) else {}
ver = json.load(open(os.path.join(base, "vereditos.json"), encoding="utf8"))
names = {}
for f in ["cards", "cards_common", "cards_plague", "cards_dragon", "cards_lich"]:
    j = json.load(open(os.path.join(ROOT, "data", f + ".json"), encoding="utf8"))
    for c in j["cards"]:
        names[c["id"]] = c.get("name", c["id"])
try:
    import csv
    for row in csv.reader(open(os.path.join(ROOT, "locale", "strings.csv"), encoding="utf8")):
        if len(row) > 1 and row[0].startswith("card_") and row[0].endswith("_name"):
            names[row[0][5:-5]] = row[1]
except Exception:
    pass
os.makedirs(os.path.join(base, "cartas"), exist_ok=True)
dep_files = {e["id"]: e["file"] for k in dep for e in dep[k]}

GROUPS = [("units", "Monstros, enxames e estruturas"), ("bosses", "Chefes"), ("heroes", "Heróis"),
          ("props", "Construções e peças dos locais"), ("scenery", "Cenário espalhado")]
LABEL = {"melhorado": "Melhorado", "igual": "Mantido", "pendente": "Fica para depois"}
cards_html = []
counts = {"melhorado": 0, "igual": 0, "pendente": 0}
for key, title in GROUPS:
    items = ant.get(key, [])
    if not items:
        continue
    cards_html.append('<h2 id="%s">%s <small>%d</small></h2><div class="grid">' % (key, title, len(items)))
    for e in items:
        v = ver.get(e["id"], ["igual", ""])
        st, note = v[0], v[1]
        counts[st] = counts.get(st, 0) + 1
        art = ""
        for c in e["cards"]:
            p = os.path.join(ROOT, "assets", "cards", c + ".png")
            if os.path.exists(p):
                shutil.copy(p, os.path.join(base, "cartas", c + ".png"))
                art = "cartas/%s.png" % c
                break
        who = ", ".join(html.escape(str(names.get(c, c))) for c in e["cards"])
        after = dep_files.get(e["id"]) if st == "melhorado" else None
        def two(d, f, cls, cap):
            # A mesma vista na luz do ato 1 (pasta d) e na do ato 2 (pasta d_a2), trocada pelo botão "Luz".
            a2 = "%s_a2/%s" % (d, f)
            alt = ' data-a2="%s"' % a2 if os.path.exists(os.path.join(base, a2)) else ""
            return '<figure class="%s"><img loading="lazy" src="%s/%s" data-a1="%s/%s"%s><figcaption>%s</figcaption></figure>' % (
                cls, d, f, d, f, alt, cap)
        pics = two("antes", e["file"], "", "antes")
        if after:
            pics += two("depois", after, "new", "depois")
        if art:
            pics += '<figure class="card"><img loading="lazy" src="%s"><figcaption>carta</figcaption></figure>' % art
        cards_html.append(
            '<article class="m %s" data-st="%s"><header><b>%s</b><span class="tag %s">%s</span></header>'
            '<div class="pics">%s</div><p class="who">%s · <code>%s</code></p>%s</article>' % (
                st, st, html.escape(e["id"]), st, LABEL.get(st, st), pics, who, html.escape(e["src"]),
                '<p class="note">%s</p>' % html.escape(note) if note else ""))
    cards_html.append("</div>")

jogo = ""
jd = os.path.join(base, "jogo")
if os.path.isdir(jd):
    pairs = sorted({f.split("__")[1] for f in os.listdir(jd) if "__" in f})
    rows = []
    for p in pairs:
        a, d = "jogo/antes__" + p, "jogo/depois__" + p
        if os.path.exists(os.path.join(base, a)) and os.path.exists(os.path.join(base, d)):
            rows.append('<div class="pair"><figure><img loading="lazy" src="%s"><figcaption>antes · %s</figcaption></figure>'
                        '<figure class="new"><img loading="lazy" src="%s"><figcaption>depois · %s</figcaption></figure></div>' % (a, p, d, p))
    if rows:
        jogo = '<h2 id="jogo">No jogo, mesma semente</h2><p style="color:var(--mute)">O primeiro par mostra o Ogro e os Esqueletos Arqueiros de perto. Os outros são cenas de controle: o autoplay muda um pouco entre as execuções, quase nenhum dos 21 aparece nelas, e elas mostram que o resto do jogo não mudou.</p>' + "".join(rows)

intro = open(os.path.join(base, "resumo.html"), encoding="utf8").read() if os.path.exists(os.path.join(base, "resumo.html")) else ""
page = """<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><title>Last Boss · modelos 3D antes e depois</title>
<style>
:root{--bg:#1d2230;--panel:#262c3d;--ink:#ece6d6;--mute:#a59f93;--gold:#d9a441;--sage:#8fae7e;--line:#39405a}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 Georgia,serif}
main{max-width:1500px;margin:0 auto;padding:28px 28px 80px}
h1{font-size:30px;margin:0 0 4px}h2{margin:44px 0 14px;font-size:22px;border-bottom:1px dashed var(--line);padding-bottom:6px}
h2 small{color:var(--mute);font-size:14px}
.intro{background:var(--panel);border:1px dashed #4b5370;border-radius:12px;padding:18px 22px;max-width:1000px}
.intro li{margin:4px 0}
nav{position:sticky;top:0;background:var(--bg);padding:10px 0;z-index:2;display:flex;gap:8px;flex-wrap:wrap;border-bottom:1px solid var(--line)}
nav button,nav a{background:var(--panel);color:var(--ink);border:1px solid var(--line);border-radius:999px;padding:5px 14px;font:inherit;cursor:pointer;text-decoration:none}
nav button.on{background:var(--gold);color:#221a0c;border-color:var(--gold)}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(440px,1fr));gap:16px}
.m{background:var(--panel);border-radius:12px;padding:12px;border:1px solid var(--line)}
.m.melhorado{border-color:#6c7f4f}
.m header{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px}
.tag{font-size:12px;border-radius:999px;padding:2px 10px;background:#3a4157;color:var(--mute)}
.tag.melhorado{background:var(--sage);color:#17210f}.tag.pendente{background:#7a5a3a;color:#f6e7d0}
.pics{display:flex;gap:6px}figure{margin:0;flex:1;min-width:0}figure img{width:100%;border-radius:8px;display:block;aspect-ratio:1;object-fit:cover;cursor:zoom-in}
figcaption{font-size:12px;color:var(--mute);text-align:center}figure.new figcaption{color:var(--sage)}
.who{color:var(--mute);font-size:13px;margin:8px 0 0}.note{margin:6px 0 0;font-size:14px}
code{font-size:12px;color:#c9c1ad}
.pair{display:flex;gap:10px;margin-bottom:14px}.pair figure img{aspect-ratio:auto}
#zoom{position:fixed;inset:0;background:#000c;display:none;align-items:center;justify-content:center;z-index:9;cursor:zoom-out}
#zoom img{max-width:94vw;max-height:94vh;border-radius:8px}
</style></head><body><main>
<h1>Modelos 3D · antes e depois</h1><p style="color:var(--mute)">Revisão de 27/11/2026 · {{N}} modelos · {{M}} melhorados · {{I}} mantidos · {{P}} para depois</p>
<div class="intro">{{INTRO}}</div>
<nav><button class="on" data-f="all">Todos</button><button data-f="melhorado">Só os melhorados</button><button data-f="igual">Mantidos</button>
<span style="flex:1"></span><button class="luz on" data-l="a1">Luz do ato 1</button><button class="luz" data-l="a2">Luz do ato 2</button>
<a href="#units">Monstros</a><a href="#bosses">Chefes</a><a href="#heroes">Heróis</a><a href="#props">Construções</a><a href="#scenery">Cenário</a>{{JLINK}}</nav>
{{JOGO}}
{{CARDS}}
</main><div id="zoom"><img></div>
<script>
document.querySelectorAll('nav button.luz').forEach(b=>b.onclick=()=>{document.querySelectorAll('nav button.luz').forEach(x=>x.classList.toggle('on',x===b));
document.querySelectorAll('img[data-a1]').forEach(i=>{const s=i.dataset[b.dataset.l];if(s)i.src=s})});
document.querySelectorAll('nav button:not(.luz)').forEach(b=>b.onclick=()=>{document.querySelectorAll('nav button:not(.luz)').forEach(x=>x.classList.toggle('on',x===b));
document.querySelectorAll('.m').forEach(m=>m.style.display=(b.dataset.f==='all'||m.dataset.st===b.dataset.f)?'':'none')});
const z=document.getElementById('zoom');document.querySelectorAll('figure img').forEach(i=>i.onclick=()=>{z.querySelector('img').src=i.src;z.style.display='flex'});z.onclick=()=>z.style.display='none';
</script></body></html>"""
for k, val in [("{{N}}", str(sum(counts.values()))), ("{{M}}", str(counts.get("melhorado", 0))), ("{{I}}", str(counts.get("igual", 0))),
               ("{{P}}", str(counts.get("pendente", 0))), ("{{INTRO}}", intro), ("{{JLINK}}", '<a href="#jogo">No jogo</a>' if jogo else ""),
               ("{{JOGO}}", jogo), ("{{CARDS}}", "".join(cards_html))]:
    page = page.replace(k, val)
open(os.path.join(base, "index.html"), "w", encoding="utf8").write(page)
print("ok", counts)
