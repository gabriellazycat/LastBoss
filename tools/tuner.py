"""Ajustador automático de números (sem supervisão). Roda na branch `balance`.

A cada ciclo: mede a nota atual (distância às metas), escolhe a meta mais distante,
testa candidatos nos botões ligados a ela (até ±30%), fica com o melhor se a nota cair
e faz um commit com o relatório. Nunca toca nos caminhos de data/locked.json.

Uso: python -I tools/tuner.py --cycles 10 --runs 16
"""
import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_batch as rb  # noqa: E402

ROOT = rb.ROOT
DATA = os.path.join(ROOT, "data")
MAX_STEP = 0.30

# Botões: (arquivo, caminho, efeito). efeito "+hero" = aumentar deixa o herói mais forte.
KNOBS = [
    ("hero_escudeiro.json", ["hp"], "+hero"),
    ("hero_escudeiro.json", ["damage"], "+hero"),
    ("hero_escudeiro.json", ["regen_combat"], "+hero"),
    ("boss_lorde.json", ["parts", 3, "hp"], "-hero"),
    ("boss_lorde.json", ["right_arm_dps"], "-hero"),
    ("rules.json", ["road", "target_length"], "+time"),
    ("rules.json", ["units", "damage_mult"], "-hero"),
    ("rules.json", ["units", "projectile_damage_mult"], "-hero"),
    ("hero_escudeiro.json", ["cleave_arc"], "+hero"),
]
METRIC_KNOBS = {
    "smart_win": ("+hero", "-hero"),
    "random_win": ("+hero", "-hero"),
    "hero_level": ("+level",),
    "arena_time": ("+time",),
    "deck_spread": ("deck",),
}
DECK_IDX = {"horde": 0, "ruin": 1, "treasure": 2}


def load(f):
    with open(os.path.join(DATA, f), encoding="utf-8") as fh:
        return json.load(fh)


def save(f, obj):
    with open(os.path.join(DATA, f), "w", encoding="utf-8") as fh:
        json.dump(obj, fh, ensure_ascii=False, indent=1)
        fh.write("\n")


def get(obj, path):
    for k in path:
        obj = obj[k]
    return obj


def put(obj, path, v):
    for k in path[:-1]:
        obj = obj[k]
    obj[path[-1]] = v


def locked():
    return set(load("locked.json")["paths"])


def knob_id(f, path):
    return f.replace(".json", "") + "." + ".".join(str(p) for p in path)


def evaluate(args, tag):
    runs, errs = rb.run_all(args.bots.split(","), args.decks.split(","), args.runs, args.seed0,
                            None, "res://data", os.path.join(ROOT, "reports", "tuner", tag))
    goals = load("rules.json")["goals"]
    s = rb.summarize(runs, goals)
    return s, runs, errs


def metric_error(s, name):
    """Sinal: +1 se o valor está acima da meta, -1 se abaixo."""
    rows = s["rows"]
    g = load("rules.json")["goals"]
    if name == "smart_win":
        heur = [r for r in rows if r["bot"] == "heuristic"] or rows
        v = rb.mean([r["win"] for r in heur])
        return 1 if v > g["heuristic_win"][1] else -1
    if name == "random_win":
        return 1
    if name == "hero_level":
        v = rb.mean([r["hero_level_arena"] for r in rows])
        return 1 if v is not None and v > g["hero_level_arena"][1] else -1
    if name == "arena_time":
        v = rb.mean([r["arena_t"] for r in rows])
        return 1 if v is not None and v > g["arena_arrival_s"][1] else -1
    if name == "heroes_fallen":
        v = rb.mean([r["heroes_fallen"] for r in rows])
        return 1 if v is not None and v < 5 else -1
    return 0


def deck_candidates(s):
    """Deck que mais vence perde elixir; o que menos vence ganha."""
    heur = [r for r in s["rows"] if r["bot"] == "heuristic"] or s["rows"]
    wins = {}
    for r in heur:
        wins.setdefault(r["deck"], []).append(r["win"])
    avg = {d: sum(v) / len(v) for d, v in wins.items()}
    if len(avg) < 2:
        return []
    hi = max(avg, key=avg.get)
    lo = min(avg, key=avg.get)
    out = []
    b = load("boss_lorde.json")
    for step in (0.1, 0.2):
        for d, sign in ((hi, -1), (lo, 1)):
            rules = b["decks"][DECK_IDX[d]]["rules"]
            out.append(("boss_lorde.json", ["decks", DECK_IDX[d], "rules", "elixir_mult"], 1.0 + sign * step))
            # Mais XP para o herói = deck mais fraco.
            if "hero_xp_mult" in rules:
                out.append(("boss_lorde.json", ["decks", DECK_IDX[d], "rules", "hero_xp_mult"], 1.0 - sign * step))
            if "hero_passive_mult" in rules:
                out.append(("boss_lorde.json", ["decks", DECK_IDX[d], "rules", "hero_passive_mult"], 1.0 - sign * step))
    return out


def candidates(metric, sign, s=None):
    """Botões e multiplicadores que empurram a métrica de volta para a meta."""
    if metric == "deck_spread":
        return deck_candidates(s)
    out = []
    lk = locked()
    for f, path, eff in KNOBS:
        if knob_id(f, path) in lk or eff not in METRIC_KNOBS.get(metric, ()):
            continue
        # Vitória do jogador alta demais → herói mais forte.
        if metric in ("smart_win", "random_win"):
            up = (sign > 0) == (eff == "+hero")
        elif eff.startswith("+"):
            up = sign < 0
        else:
            up = sign > 0
        for step in (0.15, 0.3):
            out.append((f, path, 1.0 + step if up else 1.0 - step))
    return out


def apply(f, path, mult):
    obj = load(f)
    old = get(obj, path)
    new = old * mult
    if isinstance(old, int):
        new = int(round(new))
    put(obj, path, round(new, 4) if isinstance(new, float) else new)
    save(f, obj)
    return old, new


def git(*a):
    return subprocess.run(["git", "-C", ROOT, *a], capture_output=True, text=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cycles", type=int, default=10)
    ap.add_argument("--runs", type=int, default=16)
    ap.add_argument("--bots", default="heuristic,random")
    ap.add_argument("--decks", default="horde,ruin,treasure")
    ap.add_argument("--seed0", type=int, default=1000)
    ap.add_argument("--no-commit", action="store_true")
    args = ap.parse_args()
    branch = git("rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch != "balance" and not args.no_commit:
        print("o ajustador só faz commit na branch balance (atual: %s)" % branch)
        return 2
    os.makedirs(os.path.join(ROOT, "balance_reports"), exist_ok=True)
    base, _, errs = evaluate(args, "base")
    if errs:
        print("erros de script:", errs[:5])
        return 1
    print("nota inicial:", base["score"], base["score_parts"])
    tried = set()
    stuck = set()
    for cyc in range(1, args.cycles + 1):
        parts = {k: v for k, v in base["score_parts"].items() if k in METRIC_KNOBS and v > 0 and k not in stuck}
        if not parts and stuck:
            stuck.clear()
            tried.clear()
            parts = {k: v for k, v in base["score_parts"].items() if k in METRIC_KNOBS and v > 0}
        if not parts:
            print("todas as metas ajustáveis cumpridas")
            break
        ranked = sorted(parts, key=parts.get, reverse=True)[:2]
        metric = ranked[0]
        cands = []
        for mt in ranked:
            for c in candidates(mt, metric_error(base, mt), base):
                cands.append((mt,) + c)
        best = None
        for metric, f, path, mult in cands:
            key = (knob_id(f, path), mult, round(base["score"], 4))
            if key in tried:
                continue
            tried.add(key)
            old, new = apply(f, path, mult)
            s, _, errs = evaluate(args, "c%03d" % cyc)
            print("  ciclo %d %s: %s %s -> %s  nota %.3f" % (cyc, metric, knob_id(f, path), old, new, s["score"]))
            _restore(f, path, old)
            if not errs and (best is None or s["score"] < best[0]["score"]):
                best = (s, f, path, mult, old, new, metric)
        if best is None or best[0]["score"] >= base["score"]:
            print("ciclo %d: nenhum candidato melhorou %s" % (cyc, ", ".join(ranked)))
            stuck.update(ranked)
            continue
        stuck.clear()
        s, f, path, mult, old, new, metric = best
        obj = load(f)
        put(obj, path, new)
        save(f, obj)
        base = s
        md = rb.report_md(s, {"stamp": "ciclo %d" % cyc, "runs": sum(r["n"] for r in s["rows"]), "workers": os.cpu_count(), "wall_s": 0.0})
        md = "Mudança: `%s` %s → %s (meta: %s)\n\n" % (knob_id(f, path), old, new, metric) + md
        rp = os.path.join(ROOT, "balance_reports", "cycle_%03d.md" % cyc)
        with open(rp, "w", encoding="utf-8") as fh:
            fh.write(md)
        print("ciclo %d aceito: %s %s -> %s, nota %.3f" % (cyc, knob_id(f, path), old, new, s["score"]))
        if not args.no_commit:
            git("add", "data", "balance_reports")
            git("commit", "-q", "-m", "Ajuste ciclo %d: %s %s -> %s (nota %.3f)\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" % (
                cyc, knob_id(f, path), old, new, s["score"]))
    print("nota final:", base["score"], base["score_parts"])
    return 0


def _restore(f, path, old):
    obj = load(f)
    put(obj, path, old)
    save(f, obj)


if __name__ == "__main__":
    sys.exit(main())
