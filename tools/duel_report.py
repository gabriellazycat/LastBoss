"""Relatório do duelo de balanço (27/11/2026): lê capturas/duelo.json (headless/duel.gd) e propõe custo, vida e dps.

Uso: python -I tools/duel_report.py [capturas/duelo.json]
Saída: balance_reports/duelo_bruto.md e pedidos_duelo_bruto.json: a leitura crua (custo ±1, sem re-simular).
As propostas que o editor mostra saem de tools/duel_tune.py (custo livre, verificadas re-simulando).

Regras (combinadas em 27/11/2026):
- herói: Escudeiro da fase 1 (dano da fase, vida sempre cheia, sem poderes).
- cada teste gasta ~12 de elixir (headless/duel.gd --budget): a carta entra com round(12/custo) cópias juntas, e
  dano e vida entram divididos pelo elixir gasto ("uma carta de 6 vale 6 cartas de 1").
- valor de UMA carta = custo efetivo x (0,5 x dano por elixir/Dm + 0,5 x vida por elixir/Lm); Dm e Lm = medianas
  por elixir dos monstros e enxames (a âncora; estruturas ficam fora dela).
- peso do custo c = c x (1 + 0,03 x (c - 1)) (prêmio nas caras); custo 0 conta 0,5; estrutura x1,25.
- carta de apoio: 1 cópia ao lado do parceiro no orçamento cheio; vale o ganho sobre o parceiro sozinho.
- razão = valor / peso. Dentro de 0,8-1,2: não muda. Fora: o custo vai até 1 elixir na direção do merecido e
  vida/dps (pelo papel) fecham o resto até o meio da faixa. Vida/efeito fixos por regra (kamikaze, armadilha,
  estrutura com duração) e linhas em que o herói saiu andando: só o custo é proposto, o resto é à mão.
"""
import json
import os
import statistics
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")
OUT = os.path.join(ROOT, "balance_reports")
FILES = ["cards", "cards_common", "cards_plague", "cards_dragon", "cards_lich"]
PREMIUM = 0.03
STRUCT_MULT = 1.25
BAND = 0.20
HP_ROLES = {"tank"}
DPS_ROLES = {"chaser", "shooter", "kamikaze"}
FIXED_FX = ("duration", "spawn_duration", "trigger", "boom", "bite")


def weight(cost, structure):
    c = 0.5 if cost <= 0 else float(cost)
    w = c * (1.0 + PREMIUM * max(0.0, c - 1.0))
    return w * (STRUCT_MULT if structure else 1.0)


def deserved_cost(w, structure):
    """Inverso de weight(): o custo (fracionado) cujo peso é w."""
    lo, hi = 0.0, 40.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if weight(mid, structure) < w:
            lo = mid
        else:
            hi = mid
    return lo


def load_cards():
    out = {}
    for f in FILES:
        with open(os.path.join(DATA, f + ".json"), encoding="utf-8") as fh:
            for d in json.load(fh)["cards"]:
                out[d["id"]] = d
    return out


def solve_scale(role, struct, dn, ln, target):
    """Fatores (vida, dps) que levam 0,5*dn + 0,5*ln (já normalizados) até target.
    Vida x g escala o tempo e o dano (vive mais, bate mais); dps x k escala só o dano. Aproximação: confirmar
    re-simulando (headless/duel.gd --set=...)."""
    cur = 0.5 * dn + 0.5 * ln
    if cur <= 0:
        return None, None
    if role in HP_ROLES or (struct and dn < 0.05 * cur):
        return target / cur, 1.0
    if role in DPS_ROLES:
        if dn > 0:
            k = (target - 0.5 * ln) / (0.5 * dn)
            if 0.5 <= k <= 2.0:
                return 1.0, k
        return target / cur, 1.0   # o dano sozinho não fecha a conta: a vida faz o resto
    # meio a meio (enxame, apoio, estrutura que bate): vida x g e dps x g -> 0,5 g² dn + 0,5 g ln = target
    a, b, c = 0.5 * dn, 0.5 * ln, -target
    if a <= 0:
        return target / cur, 1.0
    g = (-b + (b * b - 4 * a * c) ** 0.5) / (2 * a)
    return g, g


def measure(run, cards):
    rows = {"+".join(c["cards"]): c for c in run["cases"]}
    partners = {c["cards"][0]: c["cards"][1] for c in run["cases"] if len(c["cards"]) == 2}
    items = []
    for r in rows.values():
        ids = r["cards"]
        if len(ids) != 1 or ids[0] not in cards:
            continue   # duplas e unidades filhas (rat, bat...) não são cartas
        cid = ids[0]
        d = cards[cid]
        if d.get("type") not in ("monster", "swarm", "structure"):
            continue
        dmg, life, capped, spent, note = r["dmg"], r["life"], r["capped"], r["spent"], ""
        solo = (r["dmg"] / r["spent"], r["life"] / r["spent"])   # a carta sozinha (para apoio que também luta)
        road = r.get("road", 0) > 0
        if cid in partners:
            duo = rows[cid + "+" + partners[cid]]
            alone = rows[partners[cid]]
            dmg = max(0.0, duo["dmg"] - alone["dmg"])
            life = max(0.0, duo["life"] - alone["life"])
            capped, spent, road = duo["capped"], duo["spent"], duo.get("road", 0) > 0
            note = "dupla com %s (ganho)" % partners[cid]
        struct = d["type"] == "structure"
        fx = d.get("fx", {})
        fixed = d.get("archetype") == "kamikaze" or (struct and any(k in fx for k in FIXED_FX))
        items.append({"id": cid, "cost": d["cost"], "role": "structure" if struct else d.get("archetype", "?"),
                      "struct": struct, "dmg": dmg / spent, "life": life / spent, "capped": capped, "note": note,
                      "copies": r["copies"][0], "road": road, "solo": solo, "fixed": fixed, "ce": max(0.5, float(d["cost"])),
                      "w": weight(d["cost"], struct), "hp": d.get("hp", 0), "dps": d.get("dps", 0)})
    return items


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "capturas", "duelo.json")
    with open(src, encoding="utf-8") as fh:
        run = json.load(fh)
    cards = load_cards()
    items = measure(run, cards)
    if not items:
        sys.exit("nenhuma carta no duelo")
    anchor = [i for i in items if not i["struct"]]
    dm = statistics.median([i["dmg"] for i in anchor])
    lm = statistics.median([i["life"] for i in anchor])
    pedidos = []
    for i in items:
        dn, ln = i["ce"] * i["dmg"] / dm, i["ce"] * i["life"] / lm
        v = 0.5 * dn + 0.5 * ln
        i["value"] = v
        i["ratio"] = v / i["w"]
        i["deserved"] = deserved_cost(v, i["struct"])
        i["new_cost"] = i["cost"]
        i["hp_f"] = i["dps_f"] = 1.0
        manual = i["fixed"] or i["road"]
        if abs(i["ratio"] - 1.0) <= BAND:
            i["verdict"] = "ok"
            continue
        want = round(i["deserved"])
        if want > i["cost"]:
            i["new_cost"] = i["cost"] + 1
        elif want < i["cost"]:
            i["new_cost"] = max(0, i["cost"] - 1)
        target = weight(i["new_cost"], i["struct"])
        if abs(v / target - 1.0) > BAND / 2 and not manual:
            hf, df = solve_scale(i["role"], i["struct"], dn, ln, target)
            if hf is not None:
                i["hp_f"], i["dps_f"] = hf, df
        i["verdict"] = "forte" if i["ratio"] > 1 else "fraca"
        ch = {}
        if i["new_cost"] != i["cost"]:
            ch["cost"] = i["new_cost"]
        if abs(i["hp_f"] - 1) > 0.02 and i["hp"]:
            ch["hp"] = int(round(i["hp"] * i["hp_f"] / 5.0) * 5) or 5
        if abs(i["dps_f"] - 1) > 0.02 and i["dps"]:
            nd = round(i["dps"] * i["dps_f"], 1 if i["dps"] < 20 else 0)
            ch["dps"] = int(nd) if float(nd).is_integer() else nd
        pedidos.append({
            "id": i["id"], "status": "pendente", "origem": "duelo",
            "mudancas": ch,
            "antes": {k: cards[i["id"]].get(k) for k in ch},
            "fator": round(target / v, 3) if v > 0 else None,
            "motivo": "%s: valor %.2f contra %.2f do custo %d (%+.0f%%); merecido %.1f%s%s" % (
                i["verdict"], v, i["w"], i["cost"], (i["ratio"] - 1) * 100, i["deserved"],
                "; " + i["note"] if i["note"] else "",
                "; REVISAR À MÃO (%s): só o custo foi proposto" % (
                    "o herói saiu andando" if i["road"] else "vida/efeito fixos por regra") if manual else ""),
        })
    os.makedirs(OUT, exist_ok=True)
    items.sort(key=lambda i: -i["ratio"])
    md = ["# Duelo contra o Escudeiro da fase 1\n",
          "Golpe do herói: %.0f; vida sempre cheia; %d sementes; teto %d s; ~%g de elixir por teste. "
          "Âncora (mediana dos monstros e enxames): Dm = %.1f de dano por elixir, Lm = %.2f s por elixir.\n"
          % (run["hero_dmg"], run["seeds"], run["cap"], run.get("budget", 0), dm, lm),
          "Dano e vida são POR ELIXIR gasto. Razão = valor ÷ peso do custo (1,00 = no ponto; faixa 0,80-1,20).\n",
          "| carta | papel | custo | cópias | dano/elixir | vida/elixir (s) | valor | peso | razão | merecido | proposta |",
          "|---|---|---|---|---|---|---|---|---|---|---|"]
    for i in items:
        prop = []
        if i["new_cost"] != i["cost"]:
            prop.append("custo %d→%d" % (i["cost"], i["new_cost"]))
        if abs(i["hp_f"] - 1) > 0.02:
            prop.append("vida ×%.2f" % i["hp_f"])
        if abs(i["dps_f"] - 1) > 0.02:
            prop.append("dps ×%.2f" % i["dps_f"])
        if i["verdict"] != "ok" and i["road"]:
            prop.append("herói saiu andando ³")
        elif i["verdict"] != "ok" and i["fixed"]:
            prop.append("resto à mão ²")
        md.append("| %s%s | %s | %d | %d | %.0f | %.2f%s | %.2f | %.2f | %.2f | %.1f | %s |" % (
            i["id"], " ¹" if i["note"] else "", i["role"], i["cost"], i["copies"], i["dmg"], i["life"],
            " (teto)" if i["capped"] else "", i["value"], i["w"], i["ratio"], i["deserved"], ", ".join(prop) or "—"))
    md.append("\n¹ carta de apoio: 1 cópia ao lado do parceiro no orçamento cheio; vale o ganho sobre o parceiro sozinho, "
              "por elixir do apoio.")
    md.append("² vida ou efeito fixos por regra (kamikaze, armadilha, estrutura com duração): o duelo sugere só o custo.")
    md.append("³ em alguma semente o herói não conseguiu matar e seguiu andando até um local da estrada: número inflado.")
    with open(os.path.join(OUT, "duelo_bruto.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(md) + "\n")
    with open(os.path.join(OUT, "pedidos_duelo_bruto.json"), "w", encoding="utf-8") as fh:
        json.dump({"dm": dm, "lm": lm, "pedidos": pedidos}, fh, indent=1, ensure_ascii=False)
    print("\n".join(md))
    print("\n%d propostas em balance_reports/pedidos_duelo_bruto.json" % len(pedidos))


if __name__ == "__main__":
    main()
