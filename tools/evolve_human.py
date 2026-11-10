"""Evolui a estratégia do bot humano (rodada de 10/11/2026).

Só os genes de estratégia mudam; os limites humanos (reação, mira, erro, distração) ficam fixos. Estratégia (1+λ):
a cada geração, λ mutantes do melhor atual; o melhor mutante só vence se passar o atual (reavaliado nas mesmas
sementes) por `--margin`. No fim, valida o campeão contra o perfil original em sementes que a busca não viu e
grava data/bots/human.json só se ele for melhor ali também.

Uso: python -I tools/evolve_human.py --gens 4 --lam 6 --runs 20 [--decks horde,ruin,...]
"""
import argparse
import json
import os
import random
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_batch as rb  # noqa: E402

ROOT = rb.ROOT
GENES = {
    "wave": (2.0, 9.5), "full_margin": (0.0, 3.0), "flank": (0.4, 3.1), "melee_gap": (0.0, 4.0), "lead_s": (0.0, 1.0),
    "group_spell": (0.0, 3.0), "shield_window": (0.0, 3.0), "dump_after": (1.0, 8.0), "combo": (0.0, 3.0),
    "contest_reserve": (2.0, 9.0), "shrine_reserve": (0.0, 6.0), "teleport_distance": (2.0, 6.0),
    "teleport_reserve": (0.0, 4.0), "arena_front": (0.2, 0.9), "behind": (0.0, 1.0), "max_cost": (4.0, 10.0),
    "skip_below": (1.0, 4.0), "deck_target": (9.0, 16.0), "finisher_pick": (0.0, 1.5), "lair_bonus": (0.0, 10.0),
    "route_shop": (0.0, 8.0), "route_shrine": (0.0, 8.0), "route_ritual": (0.0, 8.0),
}
INT_GENES = {"max_cost", "contest_reserve", "shrine_reserve"}


def mutate(rng, p, rate=0.35, scale=0.25):
    q = dict(p)
    for k, (lo, hi) in GENES.items():
        if rng.random() < rate:
            v = float(q.get(k, (lo + hi) / 2)) + rng.gauss(0, (hi - lo) * scale)
            v = min(hi, max(lo, v))
            q[k] = int(round(v)) if k in INT_GENES else round(v, 3)
    return q


def evaluate(cands, decks, runs, seed0, tag):
    """cands: {nome: perfil}. Devolve {nome: vitória média}."""
    out = os.path.join(ROOT, "reports", "evolve_tmp", tag)
    data = os.path.join(out, "data")
    if os.path.exists(data):
        shutil.rmtree(data)
    shutil.copytree(os.path.join(ROOT, "data"), data)
    for name, prof in cands.items():
        prof = dict(prof, id=name)
        with open(os.path.join(data, "bots", name + ".json"), "w", encoding="utf-8") as f:
            json.dump(prof, f, ensure_ascii=False, indent=1)
    runs_, errs = rb.run_all(list(cands), decks, runs, seed0, out=out, data=data.replace("\\", "/"))
    if errs:
        print("ERROS:", errs[:5])
    res = {}
    for name in cands:
        rs = [r for r in runs_ if r["bot"] == name]
        res[name] = sum(rb.is_win(r) for r in rs) / max(1, len(rs))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gens", type=int, default=4)
    ap.add_argument("--lam", type=int, default=6)
    ap.add_argument("--runs", type=int, default=20)
    ap.add_argument("--margin", type=float, default=0.02)
    ap.add_argument("--decks", default="horde,ruin,treasure,crypt,cult,horde@4,cult@4")
    ap.add_argument("--seed", type=int, default=7)
    a = ap.parse_args()
    rng = random.Random(a.seed)
    decks = a.decks.split(",")
    path = os.path.join(ROOT, "data", "bots", "human.json")
    with open(path, encoding="utf-8") as f:
        orig = json.load(f)
    best = dict(orig)
    for g in range(a.gens):
        cands = {"hx_best": best}
        for k in range(a.lam):
            cands[f"hx_m{k}"] = mutate(rng, best)
        res = evaluate(cands, decks, a.runs, 7001 + g * 500, f"g{g}")
        top = max(res, key=res.get)
        print(f"geração {g + 1}: atual {res['hx_best']:.1%}, melhor mutante {top} {res[top]:.1%}  " +
              " ".join(f"{k}={v:.0%}" for k, v in sorted(res.items())), flush=True)
        if top != "hx_best" and res[top] >= res["hx_best"] + a.margin:
            best = cands[top]
            diff = {k: best[k] for k in GENES if best.get(k) != cands["hx_best"].get(k)}
            print("  novo campeão:", diff, flush=True)
    # Validação em sementes novas: campeão contra o original.
    res = evaluate({"hx_orig": orig, "hx_champ": best}, decks, a.runs * 2, 90001, "val")
    print(f"validação (sementes novas, {a.runs * 2} por deck): original {res['hx_orig']:.1%}, campeão {res['hx_champ']:.1%}", flush=True)
    if res["hx_champ"] > res["hx_orig"] + 0.01:
        best = dict(best, id="human")
        best["_doc"] = orig.get("_doc", "") + " Estratégia evoluída por tools/evolve_human.py (10/11/2026)."
        with open(path, "w", encoding="utf-8") as f:
            json.dump(best, f, ensure_ascii=False, indent=1)
        print("gravado em data/bots/human.json")
    else:
        print("campeão não passou na validação: data/bots/human.json fica como estava")


if __name__ == "__main__":
    main()
