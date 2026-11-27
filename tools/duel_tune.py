"""Ajuste iterativo do duelo (27/11/2026): custo livre + vida/dps confirmados re-simulando.

Uso: python -I tools/duel_tune.py [--iters=3] [--seeds=5]
Lê capturas/duelo.json (rodada original, dá a âncora Dm/Lm e o ponto de partida), e para cada carta fora da faixa:
  1. custo = merecido arredondado, sem limite de passo, mas sem passar de max(custo atual, 10): o elixir base é 10
     e "merecido" acima disso costuma ser o teto da conta, não medida. O que o custo não fecha vai para vida/dps;
  2. vida/dps (pelo papel, tools/duel_report.solve_scale) chutados para o peso do custo novo;
  3. roda headless/duel.gd com todos os números novos (--set), mede de novo e corrige vida/dps; repete --iters vezes.
A âncora NÃO se move: Dm e Lm são os da rodada original (mediana dos 53 monstros e enxames de hoje).
Fora das propostas (só na tabela, "REVISAR"): linhas em que o herói saiu andando (número inflado) e atiradores
(o duelo os põe 6 m à frente de um herói corpo a corpo com escudo frontal: o pior lugar para eles).
Vida/efeito fixos por regra (kamikaze, armadilha, estrutura com duração): só o custo muda.
Apoio que também luta: vale a melhor leitura entre o ganho na dupla e a carta sozinha.
Saída: balance_reports/duelo.md, balance_reports/pedidos_duelo.json (o editor mostra) e capturas/duelo_final.json.
"""
import importlib.util
import json
import os
import statistics
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("duel_report", os.path.join(HERE, "duel_report.py"))
dr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(dr)

ROOT = dr.ROOT
GODOT = os.environ.get("GODOT", r"C:\Users\gabri\AppData\Local\Microsoft\WinGet\Packages"
                       r"\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe")
BASE_MAX = 10      # rules.elixir.max: sem relíquia, nada acima disso cabe na barra (Sim.max_offer_cost)
TOL = 0.10         # alvo: razão entre 0,90 e 1,10 (o meio da faixa de 0,80-1,20)


def run_duel(sets, seeds, out):
    spec = ";".join("%s.%s=%s" % (cid, k, v) for cid, ch in sets.items() for k, v in ch.items())
    cmd = [GODOT, "--headless", "--path", ROOT, "-s", "res://headless/duel.gd", "--",
           "--seeds=%d" % seeds, "--out=" + out, "--set=" + spec]
    p = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if not os.path.exists(out) or "SCRIPT ERROR" in p.stdout + p.stderr:
        sys.exit("duelo falhou:\n" + (p.stdout + p.stderr)[-3000:])
    with open(out, encoding="utf-8") as fh:
        return json.load(fh)


def ratios(run, cards, dm, lm, costs):
    """{id: (razão, dn, ln, item)} com a âncora fixa e o peso do custo NOVO."""
    out = {}
    for i in dr.measure(run, cards):
        c = costs.get(i["id"], i["cost"])
        ce = max(0.5, float(c))
        dn, ln = ce * i["dmg"] / dm, ce * i["life"] / lm
        v = 0.5 * dn + 0.5 * ln
        if i["note"] and "sozinha" not in i["note"]:
            sdn, sln = ce * i["solo"][0] / dm, ce * i["solo"][1] / lm
            if 0.5 * sdn + 0.5 * sln > v:   # rende mais lutando sozinho do que como bônus: vale a melhor leitura
                dn, ln = sdn, sln
                v = 0.5 * dn + 0.5 * ln
                i["note"] += "; vale a leitura sozinha"
        out[i["id"]] = (v / dr.weight(c, i["struct"]), dn, ln, i, v)
    return out


def rnd(field, x):
    if field == "hp":
        return max(5, int(round(x / 5.0) * 5))
    nd = round(x, 1 if x < 20 else 0)
    return int(nd) if float(nd).is_integer() else nd


def main():
    a = {"iters": "3", "seeds": "5"}
    for s in sys.argv[1:]:
        if s.startswith("--") and "=" in s:
            k, v = s[2:].split("=", 1)
            a[k] = v
    cards = dr.load_cards()
    with open(os.path.join(ROOT, "capturas", "duelo.json"), encoding="utf-8") as fh:
        base = json.load(fh)
    items = dr.measure(base, cards)
    anchor = [i for i in items if not i["struct"]]
    dm = statistics.median([i["dmg"] for i in anchor])
    lm = statistics.median([i["life"] for i in anchor])
    r0 = ratios(base, cards, dm, lm, {})
    costs, sets, manual, review = {}, {}, set(), {}
    for cid, (ratio, dn, ln, i, v) in r0.items():
        if abs(ratio - 1.0) <= dr.BAND:
            continue
        if i["road"]:
            review[cid] = "herói saiu andando, número inflado"
            continue
        if i["role"] == "shooter":
            review[cid] = "atirador posto na frente do herói, duelo injusto"
            continue
        nc = min(max(i["cost"], BASE_MAX), max(0, int(round(dr.deserved_cost(v, i["struct"])))))
        costs[cid] = nc
        sets[cid] = {}
        if nc != i["cost"]:
            sets[cid]["cost"] = nc
        if i["fixed"]:
            manual.add(cid)
            continue
        # Chute inicial: a carta com o custo novo entra com outro número de cópias; o valor por elixir quase não muda,
        # então o chute é pela razão contra o peso novo.
        hf, df = dr.solve_scale(i["role"], i["struct"], dn, ln, dr.weight(nc, i["struct"]))
        if hf and abs(hf - 1) > 0.02 and i["hp"]:
            sets[cid]["hp"] = rnd("hp", i["hp"] * hf)
        if df and abs(df - 1) > 0.02 and i["dps"]:
            sets[cid]["dps"] = rnd("dps", i["dps"] * df)
    sets = {k: v for k, v in sets.items() if v}
    run = base
    for it in range(0 if a.get("from-final") else int(a["iters"])):
        out = os.path.join(ROOT, "capturas", "duelo_it%d.json" % it)
        run = run_duel(sets, int(a["seeds"]), out)
        rr = ratios(run, cards, dm, lm, costs)
        off = []
        for cid in costs:
            if cid in manual or cid not in rr:
                continue
            ratio, dn, ln, i, v = rr[cid]
            if abs(ratio - 1.0) <= TOL:
                continue
            off.append("%s %.2f" % (cid, ratio))
            cur = sets.setdefault(cid, {})
            hp0 = float(cur.get("hp", cards[cid].get("hp", 0)))
            dps0 = float(cur.get("dps", cards[cid].get("dps", 0)))
            hf, df = dr.solve_scale(i["role"], i["struct"], dn, ln, dr.weight(costs[cid], i["struct"]))
            if hf and hp0 and abs(hf - 1) > 0.02:
                cur["hp"] = rnd("hp", hp0 * hf)
            if df and dps0 and abs(df - 1) > 0.02:
                cur["dps"] = rnd("dps", dps0 * df)
        print("volta %d: %d fora de 0,90-1,10: %s" % (it + 1, len(off), ", ".join(off)), flush=True)
        if not off:
            break
    fpath = os.path.join(ROOT, "capturas", "duelo_final.json")
    if a.get("from-final"):
        # Só refaz o relatório: os números aplicados estão gravados na própria rodada final (campo "set").
        with open(fpath, encoding="utf-8") as fh:
            final = json.load(fh)
        sets = {}
        for part in filter(None, final["set"].split(";")):
            key, val = part.split("=")
            cid, field = key.split(".", 1)
            sets.setdefault(cid, {})[field] = int(float(val)) if field in ("cost", "hp") or float(val).is_integer() else float(val)
    else:
        final = run_duel(sets, int(a["seeds"]), fpath)
    rr = ratios(final, cards, dm, lm, costs)
    pedidos, md = [], [
        "# Duelo contra o Escudeiro da fase 1: propostas verificadas\n",
        "Golpe do herói: %.0f; vida sempre cheia; %d sementes; ~%g de elixir por teste. Âncora FIXA da rodada original "
        "(mediana dos monstros e enxames): Dm = %.1f de dano por elixir, Lm = %.2f s por elixir. Custo livre, sem passar "
        "de max(custo atual, %d); vida e dps re-simulados até a razão ficar perto de 1.\n" % (
            final["hero_dmg"], final["seeds"], final.get("budget", 0), dm, lm, BASE_MAX),
        "Razão = valor ÷ peso do custo (1,00 = no ponto; faixa 0,80-1,20). \"antes\" = números de hoje; \"depois\" = "
        "medido de novo com a proposta.\n",
        "| carta | papel | custo | vida | dps | razão antes | razão depois | obs. |",
        "|---|---|---|---|---|---|---|---|"]
    for cid, (ratio0, _, _, i0, _) in sorted(r0.items(), key=lambda kv: -kv[1][0]):
        d = cards[cid]
        ch = sets.get(cid, {})
        after = rr[cid][0] if cid in rr else ratio0
        obs = []
        if cid in review:
            obs.append("REVISAR: " + review[cid])
        if cid in manual:
            obs.append("vida/efeito fixos: só o custo")
        if i0["note"]:
            obs.append(i0["note"])
        if cid in costs and cid not in manual and abs(after - 1) > dr.BAND:
            obs.append("não fechou na faixa")

        def col(k):
            return "%s → %s" % (d.get(k), ch[k]) if k in ch and ch[k] != d.get(k) else str(d.get(k, "—"))
        md.append("| %s | %s | %s | %s | %s | %.2f | %s | %s |" % (
            cid, i0["role"], col("cost"), col("hp"), col("dps"), ratio0,
            "%.2f" % after if ch else "—", "; ".join(obs)))
        if ch:
            pedidos.append({"id": cid, "status": "pendente", "origem": "duelo", "mudancas": ch,
                            "antes": {k: d.get(k) for k in ch},
                            "motivo": "razão %.2f → %.2f%s" % (ratio0, after, "; " + "; ".join(obs) if obs else "")})
    md.append("\nCarta de apoio: 1 cópia ao lado do parceiro no orçamento cheio; vale o ganho sobre o parceiro sozinho.")
    def hist(cs):
        return " ".join("%d:%d" % (c, cs.count(c)) for c in sorted(set(cs)))
    md.append("\nCustos (custo:quantas cartas) hoje: " + hist([cards[c]["cost"] for c in r0]))
    md.append("Custos com as propostas: " + hist([sets.get(c, {}).get("cost", cards[c]["cost"]) for c in r0]))
    os.makedirs(dr.OUT, exist_ok=True)
    with open(os.path.join(dr.OUT, "duelo.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(md) + "\n")
    with open(os.path.join(dr.OUT, "pedidos_duelo.json"), "w", encoding="utf-8") as fh:
        json.dump({"dm": dm, "lm": lm, "pedidos": pedidos}, fh, indent=1, ensure_ascii=False)
    print("\n".join(md))


if __name__ == "__main__":
    main()
