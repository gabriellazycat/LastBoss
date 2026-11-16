"""Rodada de balanceamento (15/11/2026): orquestra os lotes headless e gera os relatórios de objetivos, recarga,
relíquias e eventos. Tudo em paralelo (um processo Godot por núcleo, via tools/run_batch.run_all), sem render.

Uso (sempre com python -I):
  python -I tools/rodada.py base    --bots human,heuristic,random --runs 40      # linha de base + objetivos das cartas
  python -I tools/rodada.py draw    --bots human --runs 40                       # A/B da recarga (0 × 1.0 × 1.5)
  python -I tools/rodada.py relics  --bots human --runs 8                        # A/B de cada relíquia (mesmas sementes)
  python -I tools/rodada.py events  --bots human --runs 8                        # A/B de cada evento e opção
Combinações padrão: decks plague,dragon,lich nas fases 1 e 3 (--targets "plague@1,dragon@1,...").
Saída: balance_reports/rodada_<data>/<comando>/ (runs.json, report.md, challenges.json...).
"""
import argparse
import datetime
import json
import math
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_batch as rb  # noqa: E402

sys.stdout.reconfigure(encoding="utf-8")

ROOT = rb.ROOT
STAMP = os.environ.get("RODADA", "2026-11-15")
OUT = os.path.join(ROOT, "balance_reports", "rodada_" + STAMP)
DEFAULT_TARGETS = "plague@1,dragon@1,lich@1,plague@3,dragon@3,lich@3"


def jload(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return json.load(f)


def pct(v):
    return "—" if v is None else f"{v * 100:.0f}%"


def quant(xs, q):
    xs = sorted(xs)
    if not xs:
        return None
    k = (len(xs) - 1) * q
    lo, hi = int(math.floor(k)), int(math.ceil(k))
    return xs[lo] + (xs[hi] - xs[lo]) * (k - lo)


def median(xs):
    return quant(xs, 0.5)


def run(bots, targets, runs, seed0, workers, out, extra=None):
    os.makedirs(out, exist_ok=True)
    t0 = time.time()
    res, errs = rb.run_all(bots, targets, runs, seed0, workers, "res://data", out, "full", extra)
    wall = time.time() - t0
    if errs:
        print("ERROS DE SCRIPT:", *errs[:10], sep="\n")
    return res, wall, errs


def save(out, name, obj):
    with open(os.path.join(out, name), "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=1, ensure_ascii=False)


def write_md(out, name, text):
    with open(os.path.join(out, name), "w", encoding="utf-8") as f:
        f.write(text)


# ------------------------------------------------------------------ objetivos das cartas

def challenge_report(runs):
    """Por (bot, deck, fase) e carta: o que as runs alcançaram no desafio (v), a meta (g) e quantas cumprem."""
    groups = {}
    for r in runs:
        groups.setdefault((r["bot"], r["deck"]), []).append(r)
    out = {}
    for (bot, deck), rs in groups.items():
        cards = {}
        for r in rs:
            for cid, c in r.get("track", {}).items():
                e = cards.setdefault(cid, {"g": c["g"], "kind": c["kind"], "total": c["total"], "runs": c["runs"], "v": []})
                e["v"].append(c["v"])
        out[f"{bot}|{deck}"] = {cid: {
            "kind": e["kind"], "meta": e["g"], "total": e["total"], "runs": e["runs"], "n": len(e["v"]),
            "media": sum(e["v"]) / len(e["v"]), "mediana": median(e["v"]), "p10": quant(e["v"], 0.1), "p90": quant(e["v"], 0.9),
            "cumpre": sum(1 for x in e["v"] if x >= e["g"] - 1e-4) / len(e["v"]),
        } for cid, e in cards.items()}
    return out


def challenges_md(ch, runs):
    wins = {}
    for r in runs:
        k = f"{r['bot']}|{r['deck']}"
        wins.setdefault(k, []).append(rb.is_win(r))
    L = ["# Objetivos das cartas: o que uma run alcança", "",
         "`mediana` = valor típico por run (já na unidade do desafio); `cumpre` = fração das runs que bate a meta atual.",
         "Desafios com `total`/`runs` somam várias fases: o valor aqui é o de UMA run (compare com meta ÷ nº de runs esperado).", ""]
    for key in sorted(ch):
        w = wins.get(key, [])
        L += [f"## {key} (n={len(w)}, vitória {pct(sum(w) / len(w) if w else None)})", "",
              "| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |", "|---|---|---|---|---|---|---|---|---|"]
        for cid, e in sorted(ch[key].items(), key=lambda kv: kv[1]["cumpre"]):
            obs = "acumulado" if e["total"] else ("runs" if e["runs"] else "")
            L.append(f"| {cid} | {e['kind']} | {e['meta']:g} | {e['media']:.1f} | {e['mediana']:.1f} | {e['p10']:.1f} | {e['p90']:.1f} | {pct(e['cumpre'])} | {obs} |")
        L.append("")
    return "\n".join(L)


def suggest_goals(ch):
    """Meta sugerida por carta = mediana do melhor perfil não aleatório entre decks do dono (arredondada). Só sugestão."""
    best = {}
    for key, cards in ch.items():
        if key.startswith("random|"):
            continue
        for cid, e in cards.items():
            if e["kind"] in ("win_phase", "wins", "heroes_total", "win_without", "win_max", "no_loss", "loss_max", "soak_ignite", "peak_multi"):
                continue
            b = best.setdefault(cid, {"meta": e["meta"], "kind": e["kind"], "meds": []})
            b["meds"].append(e["mediana"])
    return {cid: {"meta_atual": b["meta"], "kind": b["kind"], "mediana_maxima": max(b["meds"]), "sugestao": int(round(max(b["meds"]) * 0.9))}
            for cid, b in best.items()}


# ------------------------------------------------------------------ comparação pareada (mesmas sementes)

def by_seed(runs):
    return {(r["bot"], r["deck"], r["seed"]): r for r in runs}


def paired(base, test):
    """Delta pareado (test − base) por semente: vitória, heróis caídos, tempo de chegada à arena."""
    b = by_seed(base)
    dw, dh, da = [], [], []
    for r in test:
        k = (r["bot"], r["deck"], r["seed"])
        if k not in b:
            continue
        dw.append(float(rb.is_win(r)) - float(rb.is_win(b[k])))
        dh.append(r.get("heroes_fallen", 0) - b[k].get("heroes_fallen", 0))
        if r["arena_t"] >= 0 and b[k]["arena_t"] >= 0:
            da.append(r["arena_t"] - b[k]["arena_t"])

    def ms(xs):
        n = len(xs)
        if n == 0:
            return None, None
        m = sum(xs) / n
        sd = math.sqrt(sum((x - m) ** 2 for x in xs) / max(1, n - 1))
        return m, sd / math.sqrt(n)
    return {"n": len(dw), "dwin": ms(dw), "dheroes": ms(dh), "darena": ms(da),
            "win": sum(float(rb.is_win(r)) for r in test) / max(1, len(test))}


def flag(m_se, big):
    m, se = m_se
    if m is None:
        return ""
    if abs(m) > 2 * se and abs(m) >= big:
        return " ▲" if m > 0 else " ▼"
    return ""


# ------------------------------------------------------------------ comandos

def cmd_base(a):
    out = os.path.join(OUT, a.name or "base")
    runs, wall, errs = run(a.bots.split(","), a.targets.split(","), a.runs, a.seed0, a.workers, out)
    goals = jload("data/rules.json")["goals"]
    s = rb.summarize(runs, goals)
    meta = {"stamp": datetime.datetime.now().isoformat(timespec="seconds"), "pool": "full", "runs": len(runs),
            "workers": a.workers, "wall_s": wall, "script_errors": errs[:20]}
    save(out, "runs.json", runs)
    save(out, "summary.json", {"meta": meta, **s})
    write_md(out, "report.md", rb.report_md(s, meta))
    ch = challenge_report(runs)
    save(out, "challenges.json", ch)
    write_md(out, "challenges.md", challenges_md(ch, runs))
    save(out, "metas_sugeridas.json", suggest_goals(ch))
    # Resumo extra: recarga e bot (mão vazia, tropeços).
    L = ["# Recarga e tropeços do bot", "", "| bot | deck | vaga vazia (s/min) | jogadas | recusadas | tropeços |", "|---|---|---|---|---|---|"]
    groups = {}
    for r in runs:
        groups.setdefault((r["bot"], r["deck"]), []).append(r)
    for (bot, deck), rs in sorted(groups.items()):
        em = rb.mean([r.get("empty_s", 0.0) / max(r["t_end"], 1.0) * 60.0 for r in rs])
        bs = [r.get("bot_stats", {}) for r in rs if r.get("bot_stats")]
        pl = rb.mean([b.get("plays", 0) for b in bs]) if bs else None
        rf = rb.mean([b.get("refused", 0) for b in bs]) if bs else None
        ms_ = rb.mean([b.get("mistakes", 0) + b.get("lapses", 0) for b in bs]) if bs else None
        L.append(f"| {bot} | {deck} | {rb.num(em)} | {rb.num(pl, '{:.0f}')} | {rb.num(rf, '{:.1f}')} | {rb.num(ms_, '{:.1f}')} |")
    write_md(out, "recarga.md", "\n".join(L) + "\n")
    print(rb.report_md(s, meta).split("## Cartas")[0])
    print("saída:", out)


def cmd_draw(a):
    out = os.path.join(OUT, "recarga_ab")
    allr = []
    for mult in a.mults.split(","):
        sub = os.path.join(out, f"x{mult}")
        runs, _, _ = run(a.bots.split(","), a.targets.split(","), a.runs, a.seed0, a.workers, sub, {"draw_delay": mult})
        for r in runs:
            r["_mult"] = mult
        allr += runs
    save(out, "runs.json", allr)
    L = ["# A/B da recarga da vaga (multiplicador de DRAW_DELAY; 1.0 = regra atual)", "",
         "| bot | deck | recarga | vitória | heróis caídos | arena (s) | elixir perdido | cartas/min a2 | vaga vazia s/min |", "|---|---|---|---|---|---|---|---|---|"]
    for bot in a.bots.split(","):
        for tg in a.targets.split(","):
            for mult in a.mults.split(","):
                rs = [r for r in allr if r["_mult"] == mult and r["bot"] == bot and norm(r["deck"]) == norm(tg)]
                if not rs:
                    continue
                L.append(f"| {bot} | {tg} | x{mult} | {pct(sum(map(rb.is_win, rs)) / len(rs))} | {rb.num(rb.mean([r.get('heroes_fallen', 0) for r in rs]))} | "
                         f"{rb.num(rb.mean([r['arena_t'] for r in rs if r['arena_t'] >= 0]), '{:.0f}')} | {pct(rb.mean([r['waste_frac'] for r in rs]))} | "
                         f"{rb.num(rb.pace(rs)['plays_min'][1])} | {rb.num(rb.mean([r.get('empty_s', 0.0) / max(r['t_end'], 1.0) * 60.0 for r in rs]))} |")
    write_md(out, "report.md", "\n".join(L) + "\n")
    print("\n".join(L))


def norm(t):
    return t if "@" in t else t + "@1"


def _compat(owner, deck):
    return owner in (None, "", "common", "all") or owner == deck.partition("@")[0]


def cmd_ab(a, kind):
    """kind = relics | events. Cada item forçado, mesmas sementes da linha de base (a.base)."""
    base_runs = json.load(open(os.path.join(OUT, a.base, "runs.json"), encoding="utf-8"))
    bots = a.bots.split(",")
    targets = a.targets.split(",")
    if kind == "relics":
        items = [(rid, {"force_relic": rid}, r.get("owner")) for rid, r in jload("data/relics.json")["relics"].items()] \
            if isinstance(jload("data/relics.json")["relics"], dict) else \
            [(r["id"], {"force_relic": r["id"]}, r.get("owner")) for r in jload("data/relics.json")["relics"]]
    else:
        items = []
        for ev in jload("data/events.json")["events"]:
            for k, op in enumerate(ev["options"]):
                items.append((f"{ev['id']}:{op['id']}", {"force_event": f"{ev['id']}:{k}"}, ev.get("owner")))
    if a.only:
        items = [i for i in items if any(o in i[0] for o in a.only.split(","))]
    out = os.path.join(OUT, kind)
    os.makedirs(out, exist_ok=True)
    res = {}
    for name, extra, owner in items:
        tg = [t for t in targets if _compat(owner, t)]
        if not tg:
            continue
        runs, _, _ = run(bots, tg, a.runs, a.seed0, a.workers, os.path.join(out, "tmp"), extra)
        res[name] = {}
        for t in tg:
            for bot in bots:
                tr = [r for r in runs if norm(r["deck"]) == norm(t) and r["bot"] == bot]
                br = [r for r in base_runs if norm(r["deck"]) == norm(t) and r["bot"] == bot and r["seed"] < a.seed0 + a.runs]
                res[name][f"{bot}|{t}"] = paired(br, tr) | {"base_win": sum(map(rb.is_win, br)) / max(1, len(br))}
                if kind == "events":
                    picks = {}
                    for r in tr:
                        for k2, v in r.get("event_picks", {}).items():
                            picks[k2] = picks.get(k2, 0) + v
                    res[name][f"{bot}|{t}"]["event_picks"] = picks
        save(out, "resultado.json", res)
        print("feito:", name, flush=True)
    L = [f"# A/B de {kind} (mesmas sementes da linha de base `{a.base}`; ▲/▼ = delta > 2 erros-padrão e ≥ 8 pp)", "",
         "| item | combo | n | vitória base | vitória c/ item | Δ vitória (pp) | Δ heróis caídos | Δ arena (s) |", "|---|---|---|---|---|---|---|---|"]
    for name, d in res.items():
        for combo, p in d.items():
            dw, dh, da = p["dwin"], p["dheroes"], p["darena"]
            L.append(f"| {name} | {combo.replace(chr(124), chr(47))} | {p['n']} | {pct(p['base_win'])} | {pct(p['win'])} | "
                     f"{'—' if dw[0] is None else '%+.0f' % (dw[0] * 100)}{flag(dw, 0.08)} | "
                     f"{'—' if dh[0] is None else '%+.2f' % dh[0]}{flag(dh, 0.3)} | {'—' if da[0] is None else '%+.0f' % da[0]} |")
    if kind == "events":
        # Cada opção contra a opção "leave" (ou "nothing") do mesmo evento: o efeito real da opção, sem o valor
        # dos outros eventos que o bot normal aproveita na linha de base.
        L += ["", "## Cada opção contra sair do evento (vitória absoluta, pp)", "", "| opção | combo | vitória | vs. sair |", "|---|---|---|---|"]
        for name, d in res.items():
            ev = name.split(":")[0]
            ref = next((res[n] for n in res if n.startswith(ev + ":") and n.split(":")[1] in ("leave", "nothing", "ignore", "skip")), None)
            for combo, p in d.items():
                rv = ref[combo]["win"] if ref and combo in ref else None
                dtxt = '—' if rv is None else '%+.0f' % ((p['win'] - rv) * 100)
                L.append(f"| {name} | {combo.replace(chr(124), chr(47))} | {pct(p['win'])} | {dtxt} |")
    # Ranking por Δ vitória médio entre combos.
    rank = sorted(((sum(p["dwin"][0] or 0.0 for p in d.values()) / len(d), name) for name, d in res.items()), reverse=True)
    L += ["", "## Ranking (Δ vitória médio, pp)", ""] + [f"- {name}: {m * 100:+.1f}" for m, name in rank]
    write_md(out, "report.md", "\n".join(L) + "\n")
    print("\n".join(L[-40:]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["base", "draw", "relics", "events"])
    ap.add_argument("--bots", default="human")
    ap.add_argument("--targets", default=DEFAULT_TARGETS)
    ap.add_argument("--runs", type=int, default=40)
    ap.add_argument("--seed0", type=int, default=1)
    ap.add_argument("--workers", type=int, default=os.cpu_count() or 4)
    ap.add_argument("--name", default="")
    ap.add_argument("--mults", default="0,1.0,1.5")
    ap.add_argument("--base", default="base", help="pasta da linha de base (relics/events)")
    ap.add_argument("--only", default="", help="filtra relíquias/eventos por trecho do nome (vírgula)")
    a = ap.parse_args()
    if a.cmd == "base":
        cmd_base(a)
    elif a.cmd == "draw":
        cmd_draw(a)
    else:
        cmd_ab(a, a.cmd)


if __name__ == "__main__":
    main()
