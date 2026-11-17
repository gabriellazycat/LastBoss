"""Gera tools/deck_base.html: todas as cartas, para montar o deck inicial de cada vilão.
Uso (na raiz do projeto): python tools/gerar_deck_base.py   e abra tools/deck_base.html"""
import json, csv, os, re
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def J(p): return json.load(open(os.path.join(R, p), encoding="utf8"))
names, descs, kws = {}, {}, {}
for row in csv.DictReader(open(os.path.join(R, "locale/strings.csv"), encoding="utf8")):
    k = row["keys"]
    if k.startswith("CARD_"): names[k[5:]] = row["pt"]
    elif k.startswith("DESC_"): descs[k[5:]] = row["pt"]
    elif k.startswith("KW_"): kws[k[3:]] = row["pt"]
def num(x): return int(round(x)) if abs(x - round(x)) < 1e-9 or abs(x) >= 20 else round(x * 10) / 10
def desc(c):
    t = descs.get(c["id"], ""); p = {"count": c.get("count", 1)}
    for k, x in (c.get("fx") or {}).items():
        if isinstance(x, (int, float)) and not isinstance(x, bool): p[k + "_pct"] = int(round(x * 100)); p[k] = num(x)
        else: p[k] = x
    t = re.sub(r"\[\[[a-z_0-9]+\|([^\]]*)\]\]", chr(92) + "1", t)
    t = re.sub(r"\[\[([a-z_0-9]+)\]\]", lambda m: kws.get(m.group(1), m.group(1)), t)
    return re.sub(r"\{(\w+)\}", lambda m: str(p.get(m.group(1), "{%s}" % m.group(1))), t)
raw = []
for f in ["cards", "cards_common", "cards_plague", "cards_dragon", "cards_lich"]:
    raw += J("data/%s.json" % f)["cards"]
cards = [{"id": c["id"], "name": names.get(c["id"], c["id"]), "owner": c.get("owner", "common"),
          "rarity": c.get("rarity", "common"), "cost": c.get("cost", 0), "type": c.get("type", ""),
          "cat": c.get("category", ""), "desc": desc(c), "hp": c.get("hp", 0), "dps": c.get("dps", 0),
          "count": c.get("count", 0),
          "art": os.path.exists(os.path.join(R, "assets/cards/%s.png" % c["id"]))} for c in raw]
nomes = {"plague": "Praga (Rei dos Ratos)", "dragon": "Dragão", "lich": "Lich"}
vill = [{"id": v["id"], "name": nomes.get(v["id"], v["id"]), "start_deck": v["start_deck"]} for v in J("data/villains.json")["villains"]]
data = json.dumps({"cards": cards, "villains": vill}, ensure_ascii=False)
tpl = open(os.path.join(R, "tools/deck_base.tpl.html"), encoding="utf8").read()
open(os.path.join(R, "tools/deck_base.html"), "w", encoding="utf8").write(tpl.replace("/*DATA*/null", data))
print("ok", len(cards), "cartas")
