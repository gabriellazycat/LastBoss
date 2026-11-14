"""Gera tools/escolher_base.html: tela para escolher o deck base de cada vilão (classe)
e os desafios que liberam as cartas bloqueadas.
Uso (na raiz do projeto): python tools/gerar_escolher_base.py"""
import json, csv, os, re
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def J(p): return json.load(open(os.path.join(R, p), encoding="utf8"))
names, descs, kws = {}, {}, {}
for row in csv.DictReader(open(os.path.join(R, "locale/strings.csv"), encoding="utf8")):
    k = row["keys"]
    if k.startswith("CARD_"): names[k[5:]] = row["pt"]
    elif k.startswith("DESC_"): descs[k[5:]] = row["pt"]
    elif k.startswith("KW_"): kws[k[3:]] = row["pt"]

def num(x):
    return int(round(x)) if abs(x - round(x)) < 1e-9 or abs(x) >= 20 else round(x * 10) / 10

def desc(c):
    t = descs.get(c["id"], "")
    p = {"count": c.get("count", 1)}
    for k, x in (c.get("fx") or {}).items():
        if isinstance(x, (int, float)) and not isinstance(x, bool):
            p[k + "_pct"] = int(round(x * 100)); p[k] = num(x)
        else:
            p[k] = x
    t = re.sub(r"\[\[[a-z_0-9]+\|([^\]]*)\]\]", chr(92) + "1", t)
    t = re.sub(r"\[\[([a-z_0-9]+)\]\]", lambda m: kws.get(m.group(1), m.group(1)), t)
    return re.sub(r"\{(\w+)\}", lambda m: str(p.get(m.group(1), "{%s}" % m.group(1))), t)

raw = []
for f in ["cards", "cards_common", "cards_plague", "cards_dragon", "cards_lich"]:
    raw += J("data/%s.json" % f)["cards"]
cards = [{"id": c["id"], "name": names.get(c["id"], c["id"]), "owner": c.get("owner", "common"),
          "rarity": c.get("rarity", "common"), "cost": c.get("cost", 0), "type": c.get("type", ""),
          "cat": c.get("category", ""), "desc": desc(c), "hp": c.get("hp", 0), "dps": c.get("dps", 0),
          "count": c.get("count", 0), "tags": c.get("tags", []) + (["beast"] if (c.get("fx") or {}).get("beast") is True else []),
          "art": os.path.exists(os.path.join(R, "assets/cards/%s.png" % c["id"]))} for c in raw]

# ---------------------------------------------------------------- desafios sugeridos
# (texto com {a}, [valor comum, incomum, rara, lendária])
RI = {"common": 0, "uncommon": 1, "rare": 2, "legendary": 3}
GEN = {
    "unit": [("Tenha {a} monstros seus em campo ao mesmo tempo", [6, 8, 10, 12]),
             ("Vença {a} fases com este vilão", [1, 2, 3, 4]),
             ("Derrote o herói sem perder nenhum monstro", [0, 0, 0, 0])],
    "spell": [("Jogue {a} feitiços em 20 segundos", [3, 4, 5, 6]),
              ("Jogue {a} feitiços numa mesma fase", [15, 20, 25, 35]),
              ("Vença {a} fases com este vilão", [1, 2, 3, 4])],
    "struct": [("Tenha {a} estruturas em campo ao mesmo tempo", [2, 3, 4, 5]),
               ("Jogue {a} estruturas numa mesma fase", [8, 12, 15, 20]),
               ("Vença {a} fases com este vilão", [1, 2, 3, 4])],
    "lair": [("Jogue {a} cartas Temporárias numa mesma fase", [3, 5, 8, 10]),
             ("Vença {a} fases com este vilão", [1, 2, 3, 4])],
    "route": [("Marque {a} locais na rota numa mesma fase", [2, 3, 4, 5]),
              ("Vença {a} fases com este vilão", [1, 2, 3, 4])],
}
THEME = {
    "plague": {
        "unit": [("Tenha {a} ratos em campo ao mesmo tempo", [10, 12, 16, 20]),
                 ("Tenha {a} bichos de Bando em campo ao mesmo tempo", [8, 10, 14, 18]),
                 ("Jogue {a} cartas de Bando numa mesma fase", [25, 30, 40, 50])],
        "spell": [("Jogue {a} feitiços de Bando numa mesma fase", [8, 12, 16, 20]),
                  ("Tenha {a} bichos de Bando em campo ao jogar um feitiço", [4, 6, 8, 10])],
        "struct": [("Tenha {a} bichos de Bando perto de uma estrutura sua", [4, 6, 8, 10])],
    },
    "dragon": {
        "unit": [("Termine uma fase com {a} de ouro", [40, 60, 90, 120]),
                 ("Queime o herói por {a} segundos numa mesma fase", [20, 30, 40, 60]),
                 ("Tenha {a} monstros de Fogo em campo ao mesmo tempo", [2, 3, 4, 5])],
        "spell": [("Jogue {a} feitiços de Fogo numa mesma fase", [8, 12, 15, 20]),
                  ("Deixe o herói Encharcado e incendeie-o em até {a} segundos", [8, 7, 6, 5]),
                  ("Termine uma fase com {a} de ouro", [40, 60, 90, 120])],
        "struct": [("Termine uma fase com {a} de ouro", [40, 60, 90, 120])],
        "route": [("Termine uma fase com {a} de ouro", [40, 60, 90, 120])],
    },
    "lich": {
        "unit": [("Tenha {a} mortos-vivos em campo ao mesmo tempo", [6, 8, 10, 12]),
                 ("Faça {a} dos seus monstros morrerem numa mesma fase", [60, 90, 120, 150])],
        "spell": [("Jogue {a} feitiços de Sombra em 15 segundos", [3, 4, 5, 6]),
                  ("Faça {a} dos seus monstros morrerem numa mesma fase", [60, 90, 120, 150])],
        "struct": [("Faça {a} dos seus monstros morrerem perto de uma estrutura sua", [4, 6, 8, 10])],
    },
}
OVERRIDE = {  # cartas marcantes: desafio escolhido a dedo
    "rat_king": "Tenha 15 ratos em campo ao mesmo tempo",
    "rat_tide": "Tenha 25 ratos em campo ao mesmo tempo",
    "endless_swarm": "Tenha 30 bichos de Bando em campo ao mesmo tempo",
    "dragon_vault": "Termine uma fase com 100 de ouro",
    "gold_avalanche": "Ganhe 600 de ouro numa mesma fase",
    "meteor_storm": "Jogue 15 feitiços de Fogo numa mesma fase",
    "eternal_army": "Tenha 12 mortos-vivos em campo ao mesmo tempo",
    "soul_storm": "Faça 120 dos seus monstros morrerem numa mesma fase",
}

def kind(c):
    t, cat = c["type"], c["cat"]
    if cat == "lair": return "lair"
    if cat == "route": return "route"
    if t == "spell": return "spell"
    if t.startswith("struct"): return "struct"
    return "unit"

def fmt(tpl, r):
    text, vals = tpl
    s = text.replace("{a}", str(vals[r]))
    return s.replace(" 1 fases", " 1 fase")

nomes = {"plague": "Praga (Rei dos Ratos)", "dragon": "Dragão", "lich": "Lich"}
vill = [{"id": v["id"], "name": nomes.get(v["id"], v["id"]), "start_deck": v["start_deck"]}
        for v in J("data/villains.json")["villains"]]
ro = lambda c: (RI[c["rarity"]], c["cost"], c["id"])
alts = {}
for v in vill:
    vid = v["id"]; alts[vid] = {}; turn = {}
    for c in sorted([c for c in cards if c["owner"] in (vid, "common")], key=ro):
        k, r = kind(c), RI[c["rarity"]]
        pool = THEME.get(vid, {}).get(k, []) + GEN[k]
        i = turn.get(k, 0); turn[k] = i + 1
        out = []
        for j in range(len(pool)):
            s = fmt(pool[(i + j) % len(pool)], r)
            if s not in out: out.append(s)
        if c["id"] in OVERRIDE: out.insert(0, OVERRIDE[c["id"]])
        alts[vid][c["id"]] = out[:5]

defs = {}
for vid, v in J("tools/desbloqueios.json").items():
    if vid.startswith("_"): continue
    defs[vid] = {k: (["free"] if x == "F" else ["locked", x[2:].replace(" 1 fases", " 1 fase")]) for k, x in v["unlocks"].items()}
data = json.dumps({"cards": cards, "villains": vill, "alts": alts, "defaults": defs}, ensure_ascii=False)
tpl = open(os.path.join(R, "tools/escolher_base.tpl.html"), encoding="utf8").read()
open(os.path.join(R, "tools/escolher_base.html"), "w", encoding="utf8").write(tpl.replace("/*DATA*/null", data))
print("ok", len(cards), "cartas")
