# Página das relíquias (15/11/2026): docs/reliquias/index.html com todas as relíquias de data/relics.json,
# o ícone de assets/ui/relics/, nome e efeito (locale/strings.csv), raridade, peso de sorteio, chance e força do bot.
# Uso: python tools/art/relic_page.py   →   python -m http.server 8765   →   http://localhost:8765/docs/reliquias/
import csv, json, os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main() -> None:
	rel = json.load(open(os.path.join(ROOT, "data", "relics.json"), encoding="utf-8"))["relics"]
	tr = {}
	with open(os.path.join(ROOT, "locale", "strings.csv"), encoding="utf-8", newline="") as f:
		for row in csv.reader(f):
			if len(row) >= 2 and (row[0].startswith("REL_") or row[0].startswith("RELD_")):
				tr[row[0]] = row[1]
	owners = sorted({r.get("owner", "common") for r in rel} - {"common"})
	def pool_w(owner: str) -> float:
		return sum(float(r.get("weight", 1.0)) for r in rel if r.get("owner", "common") in ("common", owner))
	out = []
	for r in rel:
		o = r.get("owner", "common")
		w = float(r.get("weight", 1.0))
		# Chance de ser a relíquia sorteada num sorteio do pool inteiro (comuns + as do vilão; para as comuns, a média dos vilões).
		ch = w / pool_w(o) if o != "common" else sum(w / pool_w(v) for v in owners) / max(1, len(owners))
		out.append({"id": r["id"], "name": tr.get("REL_" + r["id"], r["id"]), "desc": tr.get("RELD_" + r["id"], ""),
			"rarity": r.get("rarity", "common"), "weight": w, "chance": round(ch * 100, 2), "power": r.get("bot_value", 2.0),
			"owner": o, "unique": bool(r.get("unique", False)), "new": bool(r.get("new"))})
	html = open(os.path.join(ROOT, "tools", "art", "relic_page.html"), encoding="utf-8").read()
	html = html.replace("/*DATA*/[]", json.dumps(out, ensure_ascii=False))
	os.makedirs(os.path.join(ROOT, "docs", "reliquias"), exist_ok=True)
	open(os.path.join(ROOT, "docs", "reliquias", "index.html"), "w", encoding="utf-8", newline="\n").write(html)
	print(len(out), "relíquias em docs/reliquias/index.html")


if __name__ == "__main__":
	main()
