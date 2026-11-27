"""Feitiços e Temporários pelo ganho sobre o esquadrão (27/11/2026): mede, propõe e confirma re-simulando.

Uso: python -I tools/spell_tune.py [--iters=3] [--seeds=10] [--from-final=1]
Roda headless/squad.gd (a party Escudeiro + Clériga + Mago da fase 1, parada, vida infinita, sem disputas; um bot
joga o esquadrão fixo por 60 s; a carta entra uma vez, de graça). Para cada carta, semente a semente:
  ganho  = (dano, vida em campo) com a carta − a linha de base (mesmo baralho, mesmos parceiros, mesma semente);
  equiv. = 0,5·Δdano/(dano da base por elixir) + 0,5·Δvida/(vida da base por elixir)   (em elixir do esquadrão);
  razão  = equiv. ÷ peso do custo (tools/duel_report.weight, +3% por elixir; Temporário ×1,25 como as estruturas).
Fora da faixa 0,80-1,20 e além do ruído entre sementes: custo = merecido (mínimo 1 se hoje custa 1 ou mais; sem passar
de max(custo atual, 10)) e o número principal do efeito (MAIN, no máximo ×0,6 a ×1,6) fecha o resto, re-simulando
(--iters voltas). Os parceiros dos combos são medidos sempre com os números de hoje.
Fora das propostas (REVISAR): ouro e mão/compra (SKIP_NOTE), ganho negativo (o teste não mede), cartas que não jogaram
e cartas de morte que mudam muito sem enxames no esquadrão (ALT_SQUAD).
Saída: balance_reports/feiticos.md e balance_reports/pedidos_feiticos.json (o editor mostra) e
capturas/esquadrao_final.json.
"""
import importlib.util
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("duel_report", os.path.join(HERE, "duel_report.py"))
dr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(dr)

ROOT = dr.ROOT
GODOT = os.environ.get("GODOT", r"C:\Users\gabri\AppData\Local\Microsoft\WinGet\Packages"
                       r"\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe")
BASE_MAX = 10
TOL = 0.10
F_MIN, F_MAX = 0.6, 1.6   # o número principal muda no máximo isso (a moderação das cartas caras do duelo)
# Número do efeito que a proposta mexe (o valor cresce mais ou menos junto com ele). Inteiros: arredonda, mínimo 1.
MAIN = {
    "shadow_bolt": "damage", "web": "duration", "boiling_oil": "dps", "soul_feast": "bonus_per_card",
    "soul_collector": "elixir_regen", "dark_forge": "monster_hp", "pack_call": "damage", "oil_splash": "soaked",
    "torch": "damage", "tar_net": "root", "corpse_blast": "hp_mult", "soul_harvest": "elixir",
    "arcane_spark": "damage", "shadow_mark": "bonus", "weakness_curse": "weak", "deep_chalice": "elixir_regen",
    "dark_sacrifice": "refund_frac", "poison_dart": "damage", "war_cry": "damage", "flooded_pit": "hero_slow",
    "infected_bite": "extra", "hunt_instinct": "speed", "devour": "dmg_bonus", "bubonic_plague": "per_stack",
    "mother_nest": "duration", "endless_swarm": "summon_n", "black_pestilence": "mult", "spark": "damage",
    "ember_rain": "dps", "eruption": "damage", "life_drain": "damage",
    "profane_ritual": "bonus", "open_grave": "raise", "soul_storm": "damage", "eternal_army": "summon_n",
}
INT_KEYS = {"bonus_per_card", "extra", "summon_n", "raise", "max_spells"}
SKIP_NOTE = {
    "dragon_vault": "dá ouro (ouro fora da conta)", "forbidden_library": "+1 carta na mão (o bot não escolhe carta)",
    "cursed_coins": "paga ouro", "gold_dart": "paga ouro", "gold_rain": "paga ouro", "molten_gold": "paga ouro",
    "gold_avalanche": "paga ouro", "toll": "paga ouro", "blood_tax": "paga ouro", "dragon_exchange": "dá ouro",
    "dark_messenger": "compra carta (o bot não escolhe carta)",
    "meteor_storm": "o número de meteoros cresce com o ouro",
}
# Combos (headless/squad.gd COMBO) e os parceiros deles: medidos com os parceiros nos números de hoje.
COMBO = {"shadow_echo", "arcane_spark", "arcane_apocalypse", "profane_ritual", "shadow_mark", "eruption", "oil_splash",
         "hunt_instinct", "mother_nest"}
PARTNER_IDS = {"spark", "torch", "oil_splash", "wolf_pack", "rat_burrow"}
# Cartas que contam mortes ou unidades: conferidas com um esquadrão sem enxames.
DEATH = ["soul_feast", "soul_harvest", "open_grave", "dark_sacrifice", "soul_storm", "corpse_blast", "devour"]
ALT_SQUAD = "ghoul,werewolf"
# Repetem ou reforçam outros feitiços: o valor depende de quais vêm junto (com 2 Faíscas sai quase nada).
PARTNER_DEPENDENT = {"arcane_apocalypse", "shadow_echo", "shadow_mark"}


def _spec(sets, skip=()):
    return ";".join("%s.%s=%s" % (cid, "cost" if k == "cost" else "fx." + k, v)
                    for cid, ch in sets.items() if cid not in skip for k, v in ch.items())


def _godot(spec, seeds, out, cards, squad=""):
    cmd = [GODOT, "--headless", "--path", ROOT, "-s", "res://headless/squad.gd", "--",
           "--seeds=%d" % seeds, "--out=" + out, "--set=" + spec]
    if cards:
        cmd.append("--cards=" + ",".join(sorted(cards)))
    if squad:
        cmd.append("--squad=" + squad)
    p = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if not os.path.exists(out) or "SCRIPT ERROR" in p.stdout + p.stderr:
        sys.exit("esquadrão falhou:\n" + (p.stdout + p.stderr)[-3000:])
    with open(out, encoding="utf-8") as fh:
        return json.load(fh)


def run_squad(sets, seeds, out, cards):
    """Duas rodadas: os combos com os parceiros congelados nos números de hoje; o resto com todas as propostas."""
    cards = sorted(cards)
    plain = [c for c in cards if c not in COMBO]
    combo = [c for c in cards if c in COMBO]
    runs = []
    if plain:
        runs.append(_godot(_spec(sets), seeds, out.replace(".json", "_a.json"), plain))
    if combo:
        runs.append(_godot(_spec(sets, PARTNER_IDS), seeds, out.replace(".json", "_b.json"), combo))
    merged = dict(runs[0])
    merged["cases"] = []
    for k, r in enumerate(runs):
        for c in r["cases"]:
            c = dict(c)
            c["base"] = "%d:%s" % (k, c["base"])
            merged["cases"].append(c)
    merged["set"] = _spec(sets)
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(merged, fh, indent=1, ensure_ascii=False)
    return merged


def measure(run, cards, costs):
    """{id: dict}: ganho por semente contra a base da mesma semente; média, ruído (2·desvio/√n) e razão."""
    base = {c["base"]: c for c in run["cases"] if c["card"] == ""}
    out = {}
    for c in run["cases"]:
        cid = c["card"]
        if not cid:
            continue
        b = base[c["base"]]
        eqs, eds, els = [], [], []
        for i in range(len(c["dmg_s"])):
            e0 = max(1.0, b["spent_s"][i])
            ed = (c["dmg_s"][i] - b["dmg_s"][i]) / max(1.0, b["dmg_s"][i] / e0)
            el = (c["life_s"][i] - b["life_s"][i]) / max(1.0, b["life_s"][i] / e0)
            eds.append(ed)
            els.append(el)
            eqs.append(0.5 * ed + 0.5 * el)
        n = len(eqs)
        mean = sum(eqs) / n
        sd = (sum((x - mean) ** 2 for x in eqs) / max(1, n - 1)) ** 0.5
        lair = cards[cid]["type"] == "lair"
        cost = costs.get(cid, cards[cid]["cost"])
        w = dr.weight(cost, lair)
        out[cid] = {"ratio": mean / w, "err": 2 * sd / n ** 0.5 / w, "equiv": mean, "ed": sum(eds) / n,
                    "el": sum(els) / n, "lair": lair, "cost": cost, "failed": c["failed"], "base": c["base"]}
    return out


def rnd(key, x):
    if key in INT_KEYS:
        return max(1, int(round(x)))
    nd = round(x, 2 if x < 2 else (1 if x < 20 else 0))
    return int(nd) if float(nd).is_integer() else nd


def set_main(cards, cid, ch, factor):
    """Número principal = hoje × factor (limitado a F_MIN-F_MAX); some da proposta se arredondar para o de hoje."""
    key = MAIN.get(cid)
    if not key or key not in cards[cid].get("fx", {}):
        return
    v0 = float(cards[cid]["fx"][key])
    v = rnd(key, v0 * min(F_MAX, max(F_MIN, factor)))
    if v != cards[cid]["fx"][key]:
        ch[key] = v
    else:
        ch.pop(key, None)


def main():
    a = {"iters": "3", "seeds": "10"}
    for s in sys.argv[1:]:
        if s.startswith("--") and "=" in s:
            k, v = s[2:].split("=", 1)
            a[k] = v
    cards = dr.load_cards()
    seeds = int(a["seeds"])
    ids = sorted(c for c, d in cards.items() if d["type"] in ("spell", "lair") and c not in SKIP_NOTE)
    p0 = os.path.join(ROOT, "capturas", "esquadrao.json")
    palt = os.path.join(ROOT, "capturas", "esquadrao_sem_enxame.json")
    fpath = os.path.join(ROOT, "capturas", "esquadrao_final.json")
    if a.get("from-final"):
        with open(p0, encoding="utf-8") as fh:
            base_run = json.load(fh)
        with open(palt, encoding="utf-8") as fh:
            alt_run = json.load(fh)
    else:
        base_run = run_squad({}, seeds, p0, ids)
        alt_run = _godot("", seeds, palt, DEATH, ALT_SQUAD)
    m0 = measure(base_run, cards, {})
    alt = measure(alt_run, cards, {})
    costs, sets, review, noise = {}, {}, {}, set()
    for cid, r in m0.items():
        cur = cards[cid]["cost"]
        if r["failed"]:
            review[cid] = "a carta não jogou no teste"
            continue
        if cid in PARTNER_DEPENDENT:
            review[cid] = "o valor depende de quais feitiços vêm junto (medido com 2 Faíscas, %.2f)" % r["ratio"]
            continue
        if r["equiv"] <= 0:
            review[cid] = "o ganho sai negativo: o teste não mede esta carta"
            continue
        if cid in alt and not (0.67 <= alt[cid]["ratio"] / r["ratio"] <= 1.5):
            review[cid] = "depende do esquadrão: %.2f com enxames, %.2f sem" % (r["ratio"], alt[cid]["ratio"])
            continue
        if abs(r["ratio"] - 1) <= dr.BAND:
            continue
        if abs(r["ratio"] - 1) <= r["err"]:
            noise.add(cid)
            continue
        nc = int(round(dr.deserved_cost(r["equiv"], r["lair"])))
        nc = min(max(cur, BASE_MAX), max(1 if cur >= 1 else 0, nc))
        costs[cid] = nc
        ch = {}
        if nc != cur:
            ch["cost"] = nc
        set_main(cards, cid, ch, dr.weight(nc, r["lair"]) / r["equiv"])
        sets[cid] = ch
    for it in range(0 if a.get("from-final") else int(a["iters"])):
        live = {k: v for k, v in sets.items() if v}
        if not live:
            break
        run = run_squad(live, seeds, os.path.join(ROOT, "capturas", "esquadrao_it%d.json" % it), list(costs))
        mm = measure(run, cards, costs)
        off = []
        for cid in costs:
            r = mm.get(cid)
            if not r or abs(r["ratio"] - 1) <= max(TOL, r["err"]):
                continue
            off.append("%s %.2f" % (cid, r["ratio"]))
            key = MAIN.get(cid)
            if key and key in cards[cid].get("fx", {}) and r["ratio"] > 0:
                ch = sets[cid]
                f_now = float(ch.get(key, cards[cid]["fx"][key])) / float(cards[cid]["fx"][key])
                set_main(cards, cid, ch, f_now / r["ratio"])
        print("volta %d: %d fora: %s" % (it + 1, len(off), ", ".join(off)), flush=True)
        if not off:
            break
    sets = {k: v for k, v in sets.items() if v}
    if a.get("from-final"):
        # Só refaz o relatório com a rodada final gravada (sem re-simular); as cartas que viraram REVISAR saem.
        with open(fpath, encoding="utf-8") as fh:
            final = json.load(fh)
        sets = {}
        for part in filter(None, final["set"].split(";")):
            key, val = part.split("=")
            bits = key.split(".")
            sets.setdefault(bits[0], {})[bits[-1]] = int(float(val)) if float(val).is_integer() else float(val)
        sets = {k: v for k, v in sets.items() if k not in review}
    elif sets:
        final = run_squad(sets, seeds, fpath, list(costs))
    else:
        final = base_run
    mf = measure(final, cards, costs)
    pedidos, md = [], [
        "# Feitiços e Temporários: ganho sobre o esquadrão\n",
        "Party Escudeiro + Clériga + Mago (fase 1, nível 1), parada, vida infinita, sem poderes, sem disputas; %g s; %d "
        "sementes. Um bot joga o esquadrão fixo (%s) com o elixir real; a carta entra uma vez, de graça. Equivalente = "
        "0,5·Δdano + 0,5·Δvida em campo, em elixir do esquadrão. Peso: +3%% por elixir; Temporário ×1,25. O número "
        "principal muda no máximo ×%.1f a ×%.1f; parceiros dos combos medidos com os números de hoje.\n" % (
            base_run["secs"], base_run["seeds"], ", ".join(base_run["squad"]), F_MIN, F_MAX),
        "Razão = equivalente ÷ peso do custo (1,00 = no ponto; faixa 0,80-1,20); ± = ruído entre sementes. "
        "\"dano/vida\" = quanto do ganho veio de cada parte, em elixir do esquadrão.\n",
        "| carta | tipo | custo | número | dano/vida | razão antes | razão depois | obs. |",
        "|---|---|---|---|---|---|---|---|"]
    for cid, r in sorted(m0.items(), key=lambda kv: -kv[1]["ratio"]):
        d = cards[cid]
        ch = sets.get(cid, {})
        after = mf[cid]["ratio"] if cid in mf and ch else None
        obs = []
        if cid in review:
            obs.append("REVISAR: " + review[cid])
        if cid in noise:
            obs.append("fora da faixa, mas dentro do ruído: sem proposta")
        partners = r["base"].split("|", 1)[1] if "|" in r["base"] else ""
        if partners:
            obs.append("com " + partners.replace(",", " + "))
        if cid in alt and cid not in review:
            obs.append("sem enxames: %.2f" % alt[cid]["ratio"])
        if cid in costs and not MAIN.get(cid):
            obs.append("sem número principal: só o custo")
        if after is not None and abs(after - 1) > dr.BAND:
            obs.append("não fechou na faixa (limite da mudança)")
        key = MAIN.get(cid)
        cost_s = "%s → %s" % (d["cost"], ch["cost"]) if "cost" in ch else str(d["cost"])
        num_s = "—"
        if key and key in d.get("fx", {}):
            num_s = "%s %s → %s" % (key, d["fx"][key], ch[key]) if key in ch else "%s %s" % (key, d["fx"][key])
        md.append("| %s | %s | %s | %s | %.1f / %.1f | %.2f ± %.2f | %s | %s |" % (
            cid, "temporário" if r["lair"] else "feitiço", cost_s, num_s, r["ed"], r["el"], r["ratio"], r["err"],
            "%.2f" % after if after is not None else "—", "; ".join(obs)))
        if ch:
            mud = {("cost" if k == "cost" else "fx." + k): v for k, v in ch.items()}
            antes = {("cost" if k == "cost" else "fx." + k): (d["cost"] if k == "cost" else d["fx"][k]) for k in ch}
            pedidos.append({"id": cid, "status": "pendente", "origem": "esquadrão", "mudancas": mud, "antes": antes,
                            "motivo": "razão %.2f → %.2f%s" % (r["ratio"], after if after is not None else r["ratio"],
                                                              "; " + "; ".join(obs) if obs else "")})
    for cid, why in sorted(SKIP_NOTE.items()):
        d = cards[cid]
        md.append("| %s | %s | %s | — | — | — | — | REVISAR: %s |" % (
            cid, "temporário" if d["type"] == "lair" else "feitiço", d["cost"], why))
    os.makedirs(dr.OUT, exist_ok=True)
    with open(os.path.join(dr.OUT, "feiticos.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(md) + "\n")
    with open(os.path.join(dr.OUT, "pedidos_feiticos.json"), "w", encoding="utf-8") as fh:
        json.dump({"pedidos": pedidos}, fh, indent=1, ensure_ascii=False)
    print("ok: %d propostas, %d REVISAR, %d no ruído" % (len(pedidos), len(review) + len(SKIP_NOTE), len(noise)))


if __name__ == "__main__":
    main()
