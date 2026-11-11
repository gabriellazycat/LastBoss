"""Ajuste da campanha (rodada autônoma de 09/11/2026; vilões em 11/11/2026): mexe na vida dos heróis por vilão e
por fase até o bot heurístico ficar perto da meta de vitória.

Uso: python -I tools/tune_campaign.py --cycles 3 --runs 32 [--phases 1] [--villains plague,dragon,lich]

Botões: `rules.hero_hp_mult` de cada vilão (data/villains.json) e `hp_mult` de cada fase (data/campaign.json).
Na fase 1, só os vilões; nas outras fases, só o multiplicador da fase (a média dos vilões). Passo limitado a
±20% por ciclo. Grava os JSON e imprime a tabela de cada ciclo.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import run_batch  # noqa: E402

VILLAINS = ["plague", "dragon", "lich"]
# Meta de vitória do bot heurístico por fase (a campanha fica mais difícil a cada fase).
TARGET = {0: 0.9, 1: 0.57, 2: 0.52, 3: 0.47, 4: 0.42}


def load(p):
    with open(os.path.join(ROOT, p), encoding="utf-8") as f:
        return json.load(f)


def save(p, d):
    with open(os.path.join(ROOT, p), "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=1)


def step(win, target, k=0.5, cap=0.15):
    """Vitória acima da meta -> heróis mais fortes (multiplicador maior)."""
    return 1.0 + max(-cap, min(cap, k * (win - target)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cycles", type=int, default=2)
    ap.add_argument("--runs", type=int, default=32)
    ap.add_argument("--phases", default="1")
    ap.add_argument("--villains", "--pacts", dest="villains", default=",".join(VILLAINS))
    ap.add_argument("--pool", default="full", help="full (pool inteiro do vilão) ou start (coleção inicial)")
    args = ap.parse_args()
    phases = [int(x) for x in args.phases.split(",")]
    VILLAINS[:] = args.villains.split(",")
    for cyc in range(args.cycles):
        decks = []
        for ph in phases:
            for p in VILLAINS:
                decks.append(p if ph == 1 else f"{p}@{ph}")
        out = os.path.join(ROOT, "reports", "tune_tmp")
        runs, errs = run_batch.run_all(["heuristic"], decks, args.runs, out=out, pool=args.pool)
        if errs:
            print("ERROS:", errs[:5])
        win = {}
        for lb in decks:
            rs = [r for r in runs if r["deck"] == lb]
            win[lb] = sum(1 for r in rs if run_batch.is_win(r)) / max(1, len(rs))
        vil = load("data/villains.json")
        camp = load("data/campaign.json")
        print(f"\n== ciclo {cyc + 1}: {out}")
        for ph in phases:
            labels = [p if ph == 1 else f"{p}@{ph}" for p in VILLAINS]
            ws = [win.get(lb, 0.0) for lb in labels]
            print(f"fase {ph}: " + "  ".join(f"{lb}={w:.0%}" for lb, w in zip(labels, ws)))
            if ph == 1:
                for d in vil["villains"]:
                    if d["id"] in VILLAINS:
                        m = step(win.get(d["id"], 0.0), TARGET[1])
                        d["rules"]["hero_hp_mult"] = round(float(d["rules"].get("hero_hp_mult", 1.0)) * m, 3)
                        print(f"  {d['id']}: hero_hp_mult -> {d['rules']['hero_hp_mult']}")
            else:
                avg = sum(ws) / len(ws)
                for phd in camp["phases"]:
                    if int(phd["id"]) == ph:
                        phd["hp_mult"] = round(float(phd.get("hp_mult", 1.0)) * step(avg, TARGET[ph]), 3)
                        print(f"  fase {ph} (média {avg:.0%}): hp_mult -> {phd['hp_mult']}")
        save("data/villains.json", vil)
        save("data/campaign.json", camp)


if __name__ == "__main__":
    main()
