"""Calibra a campanha contra o bot humano (rodada de 10/11/2026).

Fase 1: `hero_hp_mult` de cada pacto (data/boss_lorde.json). Fases 2 a 4: `pact_hp[pacto]` da fase
(data/campaign.json), um ajuste por pacto dentro da fase. Passo multiplicativo amortecido (±cap por ciclo);
células já dentro da faixa (meta ± tol) não mexem.

Ordem (os botões são aninhados: o da fase 1 vale em todas as fases): primeiro só --phases 1, depois congela e
calibra --phases 2,3,4. Calibrar os dois juntos fazia as células oscilarem.

Uso: python -I tools/tune_human.py --cycles 3 --runs 32 [--phases 1,2,3,4] [--pacts horde,ruin] [--seed0 101]
"""
import argparse
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import run_batch  # noqa: E402

PACTS = ["horde", "ruin", "treasure", "crypt", "cult"]
# Meta do bot humano por fase: a campanha fica mais difícil a cada fase.
TARGET = {1: 0.60, 2: 0.56, 3: 0.52, 4: 0.48}
TOL = 0.06


def load(p):
    with open(os.path.join(ROOT, p), encoding="utf-8") as f:
        return json.load(f)


def save(p, d):
    with open(os.path.join(ROOT, p), "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=1)


# Inclinação medida (10/11/2026, Ruína fase 1, mesmas 64 sementes): vida 0,8 -> 86%, 0,92 -> 73%, 1,05 -> 59%,
# ou ~1,0 ponto de vitória por 1% de vida (em log). --slope usa isso para corrigir num passo só.
SLOPE = 1.0


def factor(win, target, k=1.3, cap=0.18, tol=TOL):
    """Vitória acima da meta -> heróis mais fortes (multiplicador maior)."""
    if abs(win - target) <= tol:
        return 1.0
    return math.exp(max(-cap, min(cap, k * (win - target))))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cycles", type=int, default=3)
    ap.add_argument("--runs", type=int, default=32)
    ap.add_argument("--phases", default="1,2,3,4")
    ap.add_argument("--pacts", default=",".join(PACTS))
    ap.add_argument("--seed0", type=int, default=101)
    ap.add_argument("--bot", default="human")
    ap.add_argument("--slope", action="store_true", help="um passo pela inclinação medida (k=1/SLOPE, teto 30%%, sem tolerância)")
    ap.add_argument("--fixed-seeds", action="store_true", help="as mesmas sementes em todo ciclo")
    a = ap.parse_args()
    phases = [int(x) for x in a.phases.split(",")]
    pacts = a.pacts.split(",")
    for cyc in range(a.cycles):
        decks = [p if ph == 1 else f"{p}@{ph}" for ph in phases for p in pacts]
        out = os.path.join(ROOT, "reports", "tune_human_tmp")
        # Sementes novas a cada ciclo: não ajusta ao ruído de um mesmo lote.
        runs, errs = run_batch.run_all([a.bot], decks, a.runs, seed0=a.seed0 + (0 if a.fixed_seeds else cyc * 1000), out=out)
        if errs:
            print("ERROS:", errs[:5])
        boss = load("data/boss_lorde.json")
        camp = load("data/campaign.json")
        print(f"\n== ciclo {cyc + 1}")
        for ph in phases:
            line = []
            for p in pacts:
                lb = p if ph == 1 else f"{p}@{ph}"
                rs = [r for r in runs if r["deck"] == lb]
                w = sum(run_batch.is_win(r) for r in rs) / max(1, len(rs))
                to = sum(r["result"] == "timeout" for r in rs)
                f = factor(w, TARGET[ph], k=1.0 / SLOPE, cap=0.3, tol=0.02) if a.slope else factor(w, TARGET[ph])
                if ph == 1:
                    for d in boss["decks"]:
                        if d["id"] == p:
                            d["rules"]["hero_hp_mult"] = round(float(d["rules"].get("hero_hp_mult", 1.0)) * f, 3)
                            nv = d["rules"]["hero_hp_mult"]
                else:
                    for phd in camp["phases"]:
                        if int(phd["id"]) == ph:
                            ph_hp = phd.setdefault("pact_hp", {})
                            ph_hp[p] = round(float(ph_hp.get(p, 1.0)) * f, 3)
                            nv = ph_hp[p]
                if nv < 0.55 or nv > 1.6:
                    print(f"  ATENÇÃO {lb}: botão em {nv} (fora de 0.55-1.6): problema de estrutura, não de número")
                line.append(f"{p}={w:.0%}{'(' + str(to) + 'to)' if to else ''}->{nv}")
            print(f"fase {ph} (meta {TARGET[ph]:.0%}): " + "  ".join(line))
        save("data/boss_lorde.json", boss)
        save("data/campaign.json", camp)


if __name__ == "__main__":
    main()
