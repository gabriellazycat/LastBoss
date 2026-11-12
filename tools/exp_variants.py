"""Experimentos de balanceamento sem tocar em data/: cada variante é uma cópia de data/ em res://data_exp/<nome>
com ajustes em villains.json/campaign.json/rules.json; roda o bot humano e imprime a vitória por baralho.
Uso: python -I tools/exp_variants.py --decks plague --runs 48 --var nome='{"villains.plague.rules.infestation":0.1}' ..."""
import argparse, json, os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import run_batch as rb

def setp(d, path, val):
    ks = path.split(".")
    cur = d
    for k in ks[:-1]:
        cur = next((x for x in cur if x.get("id") == k), None) if isinstance(cur, list) else cur[k]
    cur[ks[-1]] = val

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--decks", default="plague"); ap.add_argument("--runs", type=int, default=48)
    ap.add_argument("--bot", default="human"); ap.add_argument("--seed0", type=int, default=9001)
    ap.add_argument("--var", action="append", default=[])
    a = ap.parse_args()
    for spec in a.var:
        name, _, js = spec.partition("=")
        edits = json.loads(js)
        dst = os.path.join(ROOT, "data_exp", name)
        shutil.rmtree(dst, ignore_errors=True); shutil.copytree(os.path.join(ROOT, "data"), dst)
        files = {}
        for path, val in edits.items():
            fn, _, rest = path.partition(".")
            if fn not in files:
                files[fn] = json.load(open(os.path.join(dst, fn + ".json"), encoding="utf-8"))
            root = files[fn]
            ks = rest.split(".")
            cur = root
            for k in ks[:-1]:
                if isinstance(cur, dict) and k in cur: cur = cur[k]
                elif isinstance(cur, dict):
                    for lk in ("villains", "phases"):
                        if lk in cur: cur = next(x for x in cur[lk] if str(x.get("id")) == k); break
                else: cur = next(x for x in cur if str(x.get("id")) == k)
            cur[ks[-1]] = val
        for fn, d in files.items():
            json.dump(d, open(os.path.join(dst, fn + ".json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        runs, errs = rb.run_all([a.bot], a.decks.split(","), a.runs, seed0=a.seed0, out=os.path.join(ROOT, "reports", "exp_tmp", name), data=f"res://data_exp/{name}")
        cells = []
        for dk in a.decks.split(","):
            rs = [r for r in runs if r["deck"] == dk]
            cells.append(f"{dk}={sum(rb.is_win(r) for r in rs)/max(1,len(rs)):.0%}(early {sum(r['result']=='win_early' for r in rs)/max(1,len(rs)):.0%})")
        print(name, edits, " ".join(cells), flush=True)
main()
