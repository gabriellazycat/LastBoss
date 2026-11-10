"""Tabela rápida de vitória por bot × deck (rodada de 10/11/2026).

Uso: python -I tools/winrates.py --bots human,heuristic,random --decks horde,ruin --runs 24 [--seed0 1] [--out dir]
Imprime a tabela; com --out grava runs.json lá.
"""
import argparse
import json
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_batch as rb  # noqa: E402


def table(runs):
    g = defaultdict(list)
    for r in runs:
        g[(r["deck"], r["bot"])].append(r)
    bots = sorted({r["bot"] for r in runs})
    decks = sorted({r["deck"] for r in runs}, key=lambda d: (d.partition("@")[2] or "1", d))
    out = ["deck | " + " | ".join(bots) + " | timeout"]
    for d in decks:
        cells = []
        to = 0
        for b in bots:
            rs = g.get((d, b), [])
            w = sum(rb.is_win(r) for r in rs) / max(1, len(rs))
            to += sum(r["result"] == "timeout" for r in rs)
            cells.append(f"{w:4.0%}")
        out.append(f"{d:12s} | " + " | ".join(cells) + f" | {to}")
    for b in bots:
        rs = [r for r in runs if r["bot"] == b]
        out.append(f"média {b}: {sum(rb.is_win(r) for r in rs) / max(1, len(rs)):.0%}  (n={len(rs)})")
    return "\n".join(out)


def make_variant(patches, dst):
    """Copia data/ para dst e aplica os patches "arquivo.a.b=valor" (o valor é JSON, ou texto)."""
    import shutil
    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(os.path.join(rb.ROOT, "data"), dst)
    for p in patches:
        path, _, val = p.partition("=")
        try:
            v = json.loads(val)
        except ValueError:
            v = val
        fn, *keys = path.split(".")
        f = os.path.join(dst, fn + ".json")
        with open(f, encoding="utf-8") as fh:
            d = json.load(fh)
        o = d
        for k in keys[:-1]:
            o = o[int(k)] if isinstance(o, list) else o[k]
        o[keys[-1]] = v
        with open(f, "w", encoding="utf-8") as fh:
            json.dump(d, fh, ensure_ascii=False, indent=1)
    return dst.replace("\\", "/")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bots", default="human,heuristic,random")
    ap.add_argument("--decks", default="horde,ruin,treasure,crypt,cult")
    ap.add_argument("--runs", type=int, default=24)
    ap.add_argument("--seed0", type=int, default=1)
    ap.add_argument("--out", default="")
    ap.add_argument("--patch", action="append", default=[],
                    help="arquivo.caminho.chave=valor (ex.: rules.arena.part_hp_mult=0.6); roda numa cópia de data/")
    a = ap.parse_args()
    out = a.out or os.path.join(rb.ROOT, "reports", "winrates_tmp")
    data = "res://data"
    if a.patch:
        data = make_variant(a.patch, os.path.join(out, "data"))
    runs, errs = rb.run_all(a.bots.split(","), a.decks.split(","), a.runs, a.seed0, out=out, data=data)
    if errs:
        print("ERROS:", *errs[:10], sep="\n")
    if a.out:
        with open(os.path.join(out, "runs.json"), "w", encoding="utf-8") as f:
            json.dump(runs, f)
    print(table(runs))


if __name__ == "__main__":
    main()
