"""Roda lotes headless em paralelo (um processo Godot por núcleo) e gera o relatório.

Uso: python -I tools/run_batch.py --bots random,greedy --decks horde,ruin,treasure --runs 60
Saída: reports/<carimbo>/runs.json, summary.json e report.md
"""
import argparse
import concurrent.futures as cf
import datetime
import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get("GODOT", r"C:\Users\gabri\AppData\Local\Microsoft\WinGet\Packages"
                       r"\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe")


def run_chunk(bot, deck, seeds, out, data):
    cmd = [GODOT, "--headless", "--path", ROOT, "res://headless/batch.tscn", "--",
           f"--bot={bot}", f"--deck={deck}", f"--seeds={seeds}", f"--out={out}", f"--data={data}"]
    p = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    errs = [l for l in (p.stdout + p.stderr).splitlines() if "SCRIPT ERROR" in l or "Parse Error" in l]
    if p.returncode != 0 or not os.path.exists(out):
        raise RuntimeError(f"{bot}/{deck}/{seeds}: código {p.returncode}\n{p.stderr[-2000:]}")
    with open(out, encoding="utf-8") as f:
        return json.load(f)["runs"], errs


def is_win(r):
    return r["result"] in ("win", "win_early")


def mean(xs):
    xs = [x for x in xs if x is not None]
    return sum(xs) / len(xs) if xs else None


def summarize(runs, goals):
    groups = {}
    for r in runs:
        groups.setdefault((r["bot"], r["deck"]), []).append(r)
    rows = []
    for (bot, deck), rs in sorted(groups.items()):
        arr = [r for r in rs if r["arena_t"] >= 0]
        rows.append({
            "bot": bot, "deck": deck, "n": len(rs),
            "win": sum(is_win(r) for r in rs) / len(rs),
            "win_early": sum(r["result"] == "win_early" for r in rs) / len(rs),
            "loss": sum(r["result"] == "loss" for r in rs) / len(rs),
            "timeout": sum(r["result"] == "timeout" for r in rs) / len(rs),
            "arena_t": mean([r["arena_t"] for r in arr]),
            "hero_level_arena": mean([r["hero_level_arena"] for r in arr]),
            "player_level_arena": mean([r["player_level_arena"] for r in arr]),
            "waste": mean([r["waste_frac"] for r in rs]),
            "wall_ms": mean([r["wall_ms"] for r in rs]),
            "game_s": mean([r["t_end"] for r in rs]),
        })
    # Cartas: taxa de escolha e de vitória quando escolhida (bots não aleatórios).
    cards = {}
    smart = [r for r in runs if r["bot"] != "random"]
    wins = [r for r in smart if is_win(r)]
    for r in smart:
        for k, v in r["offered"].items():
            c = cards.setdefault(k, {"offered": 0, "picked": 0, "runs_picked": 0, "wins_picked": 0, "in_wins": 0})
            c["offered"] += v
        for k, v in r["picked"].items():
            c = cards.setdefault(k, {"offered": 0, "picked": 0, "runs_picked": 0, "wins_picked": 0, "in_wins": 0})
            c["picked"] += v
            c["runs_picked"] += 1
            c["wins_picked"] += is_win(r)
    for r in wins:
        for k in set(r["deck_final"]):
            cards.setdefault(k, {"offered": 0, "picked": 0, "runs_picked": 0, "wins_picked": 0, "in_wins": 0})["in_wins"] += 1
    for k, c in cards.items():
        c["pick_rate"] = c["picked"] / c["offered"] if c["offered"] else None
        c["win_when_picked"] = c["wins_picked"] / c["runs_picked"] if c["runs_picked"] else None
        c["in_wins_frac"] = c["in_wins"] / len(wins) if wins else None
    score, parts = goal_score(rows, cards, goals)
    return {"rows": rows, "cards": cards, "score": score, "score_parts": parts}


def dist(v, lo, hi):
    if v is None:
        return 1.0
    if v < lo:
        return (lo - v) / max(abs(lo), 1e-6)
    if v > hi:
        return (v - hi) / max(abs(hi), 1e-6)
    return 0.0


def goal_score(rows, cards, g):
    """Nota única: soma das distâncias normalizadas às metas (0 = todas cumpridas)."""
    parts = {}
    heur = [r for r in rows if r["bot"] in ("heuristic", "greedy")]
    rnd = [r for r in rows if r["bot"] == "random"]
    if heur:
        parts["smart_win"] = dist(mean([r["win"] for r in heur]), *g["heuristic_win"])
        parts["deck_spread"] = max(0.0, (max(r["win"] for r in heur) - min(r["win"] for r in heur)) - g["deck_spread_max"])
    if rnd:
        parts["random_win"] = max(0.0, mean([r["win"] for r in rnd]) - g["random_win_max"])
    parts["arena_time"] = dist(mean([r["arena_t"] for r in rows]), *g["arena_arrival_s"])
    parts["hero_level"] = dist(mean([r["hero_level_arena"] for r in rows]), *g["hero_level_arena"])
    parts["waste"] = max(0.0, mean([r["waste"] for r in rows]) - g["elixir_waste_max"])
    top = max([c["in_wins_frac"] or 0.0 for k, c in cards.items() if not k.startswith(("mod:", "remove"))] or [0.0])
    parts["card_dominance"] = max(0.0, top - g["card_in_wins_max"])
    return round(sum(parts.values()), 4), parts


def pct(v):
    return "—" if v is None else f"{v * 100:.0f}%"


def num(v, f="{:.1f}"):
    return "—" if v is None else f.format(v)


def report_md(s, meta):
    L = [f"# Relatório de balanceamento — {meta['stamp']}", "",
         f"Runs: {meta['runs']} · processos: {meta['workers']} · tempo total: {meta['wall_s']:.1f} s · "
         f"nota (distância às metas, 0 = ideal): **{s['score']}**", "",
         "| bot | deck | n | vitória | antecipada | derrota | arena (s) | herói nv | jogador nv | elixir perdido | ms/run |",
         "|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in s["rows"]:
        L.append(f"| {r['bot']} | {r['deck']} | {r['n']} | {pct(r['win'])} | {pct(r['win_early'])} | {pct(r['loss'])} | "
                 f"{num(r['arena_t'], '{:.0f}')} | {num(r['hero_level_arena'])} | {num(r['player_level_arena'])} | "
                 f"{pct(r['waste'])} | {num(r['wall_ms'], '{:.0f}')} |")
    L += ["", "## Metas", "", "| meta | distância |", "|---|---|"]
    for k, v in s["score_parts"].items():
        L.append(f"| {k} | {v:.3f} |")
    L += ["", "## Cartas (bots não aleatórios)", "",
          "| carta | oferecida | escolha | vitória quando escolhida | nas vitórias |", "|---|---|---|---|---|"]
    for k, c in sorted(s["cards"].items(), key=lambda kv: -(kv[1]["pick_rate"] or 0)):
        L.append(f"| {k} | {c['offered']} | {pct(c['pick_rate'])} | {pct(c['win_when_picked'])} | {pct(c['in_wins_frac'])} |")
    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bots", default="random,greedy")
    ap.add_argument("--decks", default="horde,ruin,treasure")
    ap.add_argument("--runs", type=int, default=60, help="runs por combinação bot×deck")
    ap.add_argument("--seed0", type=int, default=1)
    ap.add_argument("--workers", type=int, default=os.cpu_count() or 4)
    ap.add_argument("--data", default="res://data")
    ap.add_argument("--out", default="")
    a = ap.parse_args()
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    out = a.out or os.path.join(ROOT, "reports", stamp)
    os.makedirs(os.path.join(out, "parts"), exist_ok=True)
    jobs = []
    per = max(1, a.runs // max(1, a.workers // (len(a.bots.split(",")) * len(a.decks.split(","))) or 1))
    for bot in a.bots.split(","):
        for deck in a.decks.split(","):
            s = a.seed0
            while s < a.seed0 + a.runs:
                e = min(a.seed0 + a.runs - 1, s + per - 1)
                jobs.append((bot, deck, f"{s}-{e}", os.path.join(out, "parts", f"{bot}_{deck}_{s}.json")))
                s = e + 1
    t0 = time.time()
    runs, errs = [], []
    with cf.ThreadPoolExecutor(max_workers=a.workers) as ex:
        for res in ex.map(lambda j: run_chunk(*j, a.data), jobs):
            runs += res[0]
            errs += res[1]
    wall = time.time() - t0
    with open(os.path.join(ROOT, "data", "rules.json"), encoding="utf-8") as f:
        goals = json.load(f)["goals"]
    s = summarize(runs, goals)
    meta = {"stamp": stamp, "runs": len(runs), "workers": a.workers, "wall_s": wall, "script_errors": errs[:20]}
    with open(os.path.join(out, "runs.json"), "w", encoding="utf-8") as f:
        json.dump(runs, f)
    with open(os.path.join(out, "summary.json"), "w", encoding="utf-8") as f:
        json.dump({"meta": meta, **s}, f, indent=1)
    md = report_md(s, meta)
    with open(os.path.join(out, "report.md"), "w", encoding="utf-8") as f:
        f.write(md)
    print(md.split("## Cartas")[0])
    if errs:
        print("ERROS DE SCRIPT:", *errs[:10], sep="\n")
    print("saída:", out)
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
