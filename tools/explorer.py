"""Bots exploradores: evoluem parâmetros de personalidade procurando estratégias que quebram o jogo.

Cada indivíduo é um arquivo data/bots/_exp_<k>.json (tipo "smart"). A aptidão é a taxa de vitória
média nos 3 decks. Quando o melhor passa o Heurístico por uma margem, ele vira uma personalidade
nova em data/bots/explorer_<n>.json e entra no relatório (é uma estratégia a investigar).

Uso: python -I tools/explorer.py --generations 6 --pop 8 --runs 6
"""
import argparse
import glob
import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_batch as rb  # noqa: E402

ROOT = rb.ROOT
BOTS = os.path.join(ROOT, "data", "bots")
GENES = {
    "max_cost": (2, 10, int), "lair_bonus": (0.0, 10.0, float), "lair_until": (0, 900, int),
    "shrine_reserve": (0, 10, int), "shrine_lookahead": (0.0, 60.0, float), "behind": (0.0, 1.0, float),
    "combo": (0.0, 6.0, float), "xp_aversion": (0.0, 5.0, float), "teleport_distance": (2.0, 6.0, float),
    "finisher_pick": (0.0, 2.0, float), "think_interval": (0.15, 0.6, float),
}


def rand_gene(rng, k):
    lo, hi, t = GENES[k]
    return t(rng.uniform(lo, hi)) if t is float else rng.randint(lo, hi)


def mutate(rng, ind, rate=0.3):
    out = dict(ind)
    for k in GENES:
        if rng.random() < rate:
            lo, hi, t = GENES[k]
            if t is int:
                out[k] = max(lo, min(hi, out[k] + rng.randint(-2, 2)))
            else:
                out[k] = round(max(lo, min(hi, out[k] + rng.gauss(0, (hi - lo) * 0.15))), 3)
    return out


def cross(rng, a, b):
    return {k: (a[k] if rng.random() < 0.5 else b[k]) for k in GENES}


def write(name, genes):
    d = {"id": name, "kind": "smart", **genes}
    with open(os.path.join(BOTS, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(d, f, indent=1)


def fitness(runs, name):
    rs = [r for r in runs if r["bot"] == name]
    return sum(rb.is_win(r) for r in rs) / max(1, len(rs))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--generations", type=int, default=6)
    ap.add_argument("--pop", type=int, default=8)
    ap.add_argument("--runs", type=int, default=6)
    ap.add_argument("--margin", type=float, default=0.15)
    ap.add_argument("--seed", type=int, default=1)
    a = ap.parse_args()
    rng = random.Random(a.seed)
    with open(os.path.join(BOTS, "heuristic.json"), encoding="utf-8") as f:
        base = json.load(f)
    seed_ind = {k: base.get(k, rand_gene(rng, k)) for k in GENES}
    pop = [seed_ind] + [mutate(rng, seed_ind, 0.6) for _ in range(a.pop // 2)]
    while len(pop) < a.pop:
        pop.append({k: rand_gene(rng, k) for k in GENES})
    decks = ["horde", "ruin", "treasure"]
    log = []
    ref_runs, _ = rb.run_all(["heuristic"], decks, a.runs, 7000, None, "res://data", os.path.join(ROOT, "reports", "explorer", "ref"))
    ref = fitness(ref_runs, "heuristic")
    print("Heurístico (referência): %.0f%%" % (ref * 100))
    best = (seed_ind, -1.0)
    try:
        for g in range(a.generations):
            names = []
            for k, ind in enumerate(pop):
                n = "_exp_%d" % k
                write(n, ind)
                names.append(n)
            runs, errs = rb.run_all(names, decks, a.runs, 7000, None, "res://data", os.path.join(ROOT, "reports", "explorer", "g%d" % g))
            scored = sorted(((fitness(runs, n), ind) for n, ind in zip(names, pop)), key=lambda x: -x[0])
            print("geração %d: melhor %.0f%%, média %.0f%%" % (g, scored[0][0] * 100, sum(s for s, _ in scored) / len(scored) * 100))
            log.append({"gen": g, "best": scored[0][0], "genes": scored[0][1]})
            if scored[0][0] > best[1]:
                best = (scored[0][1], scored[0][0])
            elite = [ind for _, ind in scored[: max(2, a.pop // 4)]]
            pop = list(elite)
            while len(pop) < a.pop:
                pop.append(mutate(rng, cross(rng, rng.choice(elite), rng.choice(elite))))
    finally:
        for f in glob.glob(os.path.join(BOTS, "_exp_*.json")):
            os.remove(f)
    found = best[1] >= ref + a.margin
    out = {"reference": ref, "best": best[1], "genes": best[0], "found": found, "log": log}
    if found:
        n = len(glob.glob(os.path.join(BOTS, "explorer_*.json"))) + 1
        write("explorer_%d" % n, best[0])
        out["saved_as"] = "explorer_%d" % n
        print("ESTRATÉGIA ENCONTRADA: %.0f%% contra %.0f%% do Heurístico -> data/bots/explorer_%d.json" % (best[1] * 100, ref * 100, n))
    else:
        print("nenhuma estratégia quebrou o jogo (melhor %.0f%%, Heurístico %.0f%%)" % (best[1] * 100, ref * 100))
    os.makedirs(os.path.join(ROOT, "reports", "explorer"), exist_ok=True)
    with open(os.path.join(ROOT, "reports", "explorer", "result.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
