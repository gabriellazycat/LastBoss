"""Renderiza as camadas do molde de carta (moldura A da v4) em PNGs transparentes com o Chrome headless.

Uso: python tools/art/card_mold/render_layers.py [pasta_tmp] [--only=texto]
     --only=explosive_edge,explosive_mask refaz só as camadas cujo nome contém um dos textos (as outras ficam como estão).
Saída: assets/cards/mold/*.png (600x840 a carta grande, 600x760 a da mão; 2x do desenho 300x420 / 300x380).
Depende de docs/decisoes_2026-11-11/cartas_v4.html (funções de pintura, filtros e moldura) e de overlays.js (upgrades).
Depois de rodar, abra o projeto no Godot (ou `godot --headless --import`) para importar as imagens.
"""
import json
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets" / "cards" / "mold"
_POS = [a for a in sys.argv[1:] if not a.startswith("--")]
ONLY = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--only=")), "")
TMP = Path(_POS[0]) if _POS else ROOT / ".godot" / "mold_tmp"
CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe"
SRC = ROOT / "docs" / "decisoes_2026-11-11" / "cartas_v4.html"
FONT = (ROOT / "assets" / "fonts" / "IMFellEnglishSC-Regular.ttf").as_posix()

RARS = ["common", "uncommon", "rare", "legendary"]
TYPES = {"monster": "#a8261a", "swarm": "#cc6b21", "spell": "#754fc7", "structure": "#deb340",
         "route": "#3566ab", "lair": "#527038", "finisher": "#1f1b18"}
MODS = ["cheap", "veteran", "explosive", "cursed", "shadowy"]
PAPERS = {
    "none": "linear-gradient(#f6ecd4,#e3d3ac)",
    "cheap": "linear-gradient(#c9f3e8,#7fcdbf)",
    "veteran": "linear-gradient(#4a62a0,#1b2a58)",
    "explosive": "linear-gradient(#f1c88a,#a65d28)",
    "cursed": "linear-gradient(#6a3f8c,#240a35)",
    "shadowy": "linear-gradient(#4a4952,#0b0b0f)",
}


def cells():
    L = []
    for sz in ("full", "cmp"):
        for rar in RARS:
            L.append({"name": f"frame_{rar}_{sz}", "t": "frame", "rar": rar, "cmp": sz == "cmp"})
        for t in TYPES:
            L.append({"name": f"ribbon_{t}_{sz}", "t": "ribbon", "kind": t, "cmp": sz == "cmp"})
        for p in PAPERS:
            L.append({"name": f"paper_{p}_{sz}", "t": "paper", "paper": p, "cmp": sz == "cmp"})
            if sz == "full":
                L.append({"name": f"panel_{p}_{sz}", "t": "panel", "paper": p, "cmp": False})
        for k in ["lv2", "lv3"] + MODS + ["explosive_edge", "explosive_mask"]:
            L.append({"name": f"{'mod_' if k in MODS or k.startswith('explosive_') else ''}{k}_{sz}", "t": "ov", "kind": k, "cmp": sz == "cmp"})
    for k in ("plaque2", "plaque3"):
        L.append({"name": k, "t": "ov", "kind": k, "cmp": False})
    for rar in RARS:
        for tint in ("purple", "teal"):
            L.append({"name": f"gem_{rar}_{tint}", "t": "gem", "rar": rar, "tint": tint, "w": 70, "h": 80})
    for c in L:
        c.setdefault("w", 300)
        c.setdefault("h", 380 if c.get("cmp") else 420)
    return L


def build_head():
    src = SRC.read_text(encoding="utf-8").split("\n")
    i = next(k for k, l in enumerate(src) if "PÁGINA" in l) - 1
    head = "\n".join(src[:i])
    a, b = head.index("<main>"), head.index("</main>") + 7
    head = head[:a] + head[b:] + "\n"
    return head


PAGE_JS = r"""
const TYPE_COL=__TYPES__;
for(const k in TYPE_COL)KIND[k]={c:TYPE_COL[k],t:k};
const PAPERS=__PAPERS__;
const PANELS={none:"linear-gradient(rgba(250,243,226,.78),rgba(246,236,214,.92))",cheap:"linear-gradient(rgba(200,243,232,.8),rgba(127,205,191,.94))",veteran:"linear-gradient(rgba(70,92,150,.82),rgba(28,42,90,.94))",explosive:"linear-gradient(rgba(241,200,138,.8),rgba(166,93,40,.94))",cursed:"linear-gradient(rgba(100,60,130,.82),rgba(36,12,52,.94))",shadowy:"linear-gradient(rgba(70,70,80,.82),rgba(12,12,16,.94))"};
const CELLS=__CELLS__;
const PITCH=[__PX__,__PY__];
let N=0;
function content(c,idx){
  if(c.t==="frame"){const seed=(c.rar.length*7+67)|0;return frameSvg("C",c.rar,c.cmp,"monster",[],seed,false);}
  if(c.t==="ribbon"){const kc=KIND[c.kind].c,y=c.cmp?318:250,hh=c.cmp?50:38,m=mix(kc,"#000000",.35);
    const f1_=(v)=>v;let s="";
    s+=`<path d="M30 ${y+5} L6 ${y+8} L16 ${y+hh/2+7} L6 ${y+hh+6} L30 ${y+hh+3}Z" fill="${m}" filter="url(#frameInk)"/><path d="M270 ${y+5} L294 ${y+8} L284 ${y+hh/2+7} L294 ${y+hh+6} L270 ${y+hh+3}Z" fill="${m}" filter="url(#frameInk)"/>`;
    s+=`<path d="M30 ${y+hh+3} L22 ${y+hh+10} L22 ${y+hh-2}Z M270 ${y+hh+3} L278 ${y+hh+10} L278 ${y+hh-2}Z" fill="#1a0c06" opacity=".7"/>`;
    s+=`<path d="M22 ${y} Q150 ${y-7} 278 ${y} L278 ${y+hh} Q150 ${y+hh-7} 22 ${y+hh}Z" fill="${kc}" filter="url(#gemWash)"/><path d="M22 ${y} Q150 ${y-7} 278 ${y} L278 ${y+hh} Q150 ${y+hh-7} 22 ${y+hh}Z" fill="none" stroke="#1e0e06" stroke-width="1.3" filter="url(#frameInk)"/>`;
    s+=`<path d="M26 ${y+3.5} Q150 ${y-3.5} 274 ${y+3.5}" fill="none" stroke="#fff2d8" stroke-width="1" opacity=".45"/>`;
    return `<svg width="300" height="${c.h}" viewBox="0 0 300 ${c.h}" overflow="hidden">${s}</svg>`;}
  if(c.t==="panel")return `<div style="position:absolute;left:12px;right:12px;top:262px;bottom:12px;border-radius:3px;background:${PANELS[c.paper]};clip-path:polygon(0 7px,4% 2px,9% 6px,15% 1px,22% 5px,30% 0,37% 4px,45% 1px,53% 5px,60% 1px,68% 4px,75% 0,82% 5px,89% 1px,95% 5px,100% 2px,100% 100%,0 100%)"></div>`;
  if(c.t==="paper")return `<div style="width:300px;height:${c.h}px;border-radius:10px;background:radial-gradient(80% 60% at 25% 0,rgba(255,252,240,.8),transparent 70%),radial-gradient(70% 50% at 90% 100%,rgba(150,110,60,.25),transparent 70%),${PAPERS[c.paper]}"></div>`;
  if(c.t==="gem"){let s=gemSvg(0,c.rar).replace(/<text[\s\S]*?<\/text>/,"");
    if(c.tint==="teal")s=s.replace("#c79af8","#9af8ec").replace("#7a3ad0","#1fb5b0").replace("#3a1478","#0b5f63").replace("#2a1240","#0b3a3c");
    return s.replace("<svg ","<svg width=\"70\" height=\"80\" ");}
  if(c.t==="ov"){const wb=c.cmp?316:310;return `<svg width="300" height="${c.h}" viewBox="0 0 300 ${c.h}" overflow="hidden">${overlay(c.kind,c.h,wb,"x"+idx)}</svg>`;}
  if(c.t==="rays")return `<div style="width:${c.w}px;height:${c.h}px;background:repeating-conic-gradient(from 0deg at 50% 50%,${c.col} 0 ${c.a}deg,transparent ${c.a}deg ${c.b}deg);-webkit-mask-image:radial-gradient(closest-side,#000 35%,transparent 100%)"></div>`;
  return "";}
const stage=document.getElementById("stage");
CELLS.forEach((c,i)=>{const d=document.createElement("div");d.className="cell";
  d.style.cssText=`position:absolute;left:${20+(i%__COLS__)*PITCH[0]}px;top:${20+Math.floor(i/__COLS__)*PITCH[1]}px;width:${c.w}px;height:${c.h}px;overflow:hidden`;
  d.innerHTML=content(c,i);stage.appendChild(d);});
"""


def render_sheet(head, ov_js, items, tag):
    cols = 6
    px, py = 540 if any(c["w"] > 300 for c in items) else 320, 540 if any(c["h"] > 420 for c in items) else 440
    rows = math.ceil(len(items) / cols)
    css = f"""<style>@font-face{{font-family:"IM Fell English SC";src:url("file:///{FONT}")}}
html,body{{background:transparent!important;margin:0}}body{{background:transparent!important}}#stage{{position:absolute;left:0;top:0}}</style>"""
    js = (PAGE_JS.replace("__TYPES__", json.dumps(TYPES)).replace("__PAPERS__", json.dumps(PAPERS))
          .replace("__CELLS__", json.dumps(items)).replace("__PX__", str(px)).replace("__PY__", str(py))
          .replace("__COLS__", str(cols)))
    html = head.replace("</head>", css + "</head>", 1) + '<div id="stage"></div>\n<script>\n' + ov_js + "\n</script>\n" \
        + "<script>\n" + js + "\n</script>\n</body></html>"
    # a primeira <script> da v4 ficou aberta no corte: fecha antes do nosso
    html = html.replace('<div id="stage"></div>', "</script>\n<div id=\"stage\"></div>", 1)
    page = TMP / f"{tag}.html"
    page.write_text(html, encoding="utf-8")
    W, H = 40 + cols * px, 40 + rows * py
    shot = TMP / f"{tag}.png"
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=2",
                    "--default-background-color=00000000",
                    f"--user-data-dir={TMP / 'chrome_profile'}", f"--window-size={W},{H}", "--virtual-time-budget=4000",
                    f"--screenshot={shot}", page.as_uri()], check=True, capture_output=True)
    im = Image.open(shot).convert("RGBA")
    for i, c in enumerate(items):
        x, y = 20 + (i % cols) * px, 20 + (i // cols) * py
        im.crop((x * 2, y * 2, (x + c["w"]) * 2, (y + c["h"]) * 2)).save(OUT / f"{c['name']}.png")
    print(tag, len(items), im.size)


def main():
    TMP.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    head = build_head()
    ov_js = (Path(__file__).parent / "overlays.js").read_text(encoding="utf-8")
    items = [c for c in cells() if not ONLY or any(o in c["name"] for o in ONLY.split(","))]
    chunk = 24
    for n in range(0, len(items), chunk):
        render_sheet(head, ov_js, items[n:n + chunk], f"sheet{n // chunk}")
    print("total", len(items), "->", OUT)


if __name__ == "__main__":
    main()
