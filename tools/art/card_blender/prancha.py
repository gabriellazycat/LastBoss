"""Prancha de um lote: cartas montadas na moldura A (grande, 300 px) e na mão (150 px, sobre fundo escuro).

uso:  python prancha.py <pasta_do_lote> id1 id2 ...
      (cada <id>.png, 556x534, já tem de estar em <pasta_do_lote>)
gera: <pasta_do_lote>/prancha.html e <pasta_do_lote>/prancha.png

Reaproveita a moldura A, a gema de custo e a fita do nome de docs/decisoes_2026-11-11/cartas_v4.html
(o estilo fechado com o designer); nomes, custos e textos vêm de data/cards*.json + locale/strings.csv.
"""
import csv, glob, json, os, re, subprocess, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
V4 = os.path.join(ROOT, "docs", "decisoes_2026-11-11", "cartas_v4.html")
CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe"


def load_cards():
    out = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "data", "cards*.json"))):
        for c in json.load(open(f, encoding="utf-8"))["cards"]:
            out[c["id"]] = c
    return out


def load_strings():
    s = {}
    with open(os.path.join(ROOT, "locale", "strings.csv"), encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            s[row["keys"]] = row["pt"]
    return s


def flat(c, prefix=""):
    """Todos os números da carta (inclusive aninhados) para preencher {placeholders}."""
    out = {}
    for k, v in c.items():
        if isinstance(v, dict):
            out.update(flat(v, k + "_"))
            for k2, v2 in v.items():
                if not isinstance(v2, (dict, list)):
                    out.setdefault(k2, v2)
        elif not isinstance(v, list):
            out[prefix + k] = v
    return out


def fill(text, c):
    vals = flat(c)
    # como game/ui_kit.gd: frações também viram <chave>_pct (0,125 → 13)
    for k, v in list(vals.items()):
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            vals.setdefault(k + "_pct", int(round(v * 100)))
    text = re.sub(r"\[\[[^|\]]*\|([^\]]*)\]\]", r"<b>\1</b>", text)

    def rep(m):
        v = vals.get(m.group(1))
        if v is None:
            return "X"
        if isinstance(v, float) and v.is_integer():
            v = int(v)
        return str(v)
    return re.sub(r"\{(\w+)\}", rep, text)


def main():
    lote = os.path.abspath(sys.argv[1])
    ids = sys.argv[2:]
    cards, st = load_cards(), load_strings()
    data = []
    for i in ids:
        c = cards[i]
        data.append(dict(id=i, name=st.get("CARD_" + i, i), cost=c.get("cost", 0), kind=c.get("type", "spell"),
                         rar=c.get("rarity", "common"), text=fill(st.get("DESC_" + i, ""), c),
                         small=len(st.get("DESC_" + i, "")) > 90))
    html = open(V4, encoding="utf-8").read()
    # tipos que a v4 não tinha (estrutura, covil, rota)
    html = html.replace('spell:{c:"#5a2fa0",t:"Feitiço"}};',
                        'spell:{c:"#5a2fa0",t:"Feitiço"},structure:{c:"#3e5a2a",t:"Estrutura"},'
                        'lair:{c:"#2a4a6a",t:"Covil"},route:{c:"#6a5a22",t:"Rota"}};')
    a = html.index("const CARDS=[")
    b = html.index("];", a) + 2
    html = html[:a] + "const CARDS=" + json.dumps(data, ensure_ascii=False) + ";" + html[b:]
    p = html.index("/* =====================================================================================================\n   PÁGINA")
    q = html.index("</script>", p)
    page = r"""
document.body.style.background="#efe4cc";
document.querySelector("main").innerHTML=`<div id="pr" style="display:flex;flex-wrap:wrap;gap:22px;padding:18px">`+CARDS.map(c=>
 `<div style="display:flex;flex-direction:column;align-items:center;gap:8px;width:300px">
   ${slot(c,{v:"A",scale:1,img:c.id+".png"})}
   <div style="background:#1a1410;border-radius:8px;padding:10px 75px;display:flex;justify-content:center">${slot(c,{v:"A",scale:.5,compact:true,img:c.id+".png"})}</div>
   <div style="font:12px monospace;color:#3a2a1a">${c.id}</div></div>`).join("")+`</div>`;
document.querySelectorAll("header,.lede,.tech,.toggle,.pick").forEach(e=>e.remove());
"""
    html = html[:p] + page + html[q:]
    html = html.replace("</style>", ".win img.artA{object-fit:cover;object-position:50% 0}"
                        "main{max-width:none!important;padding:0!important;margin:0!important}</style>", 1)
    out_html = os.path.join(lote, "prancha.html")
    open(out_html, "w", encoding="utf-8").write(html)
    per_row = 4
    rows = (len(ids) + per_row - 1) // per_row
    w, h = 18 * 2 + per_row * 300 + (per_row - 1) * 22, 40 + rows * (420 + 8 + 210 + 8 + 20 + 22)
    out_png = os.path.join(lote, "prancha.png")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                    f"--window-size={w},{h}", f"--screenshot={out_png}", "file:///" + out_html.replace("\\", "/")],
                   check=True, capture_output=True)
    print("ok", out_png, w, h)


if __name__ == "__main__":
    main()
