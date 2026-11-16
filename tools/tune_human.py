"""Calibra a campanha contra o bot humano (rodada de 10/11/2026; vilões em 11/11/2026).

Fase 1: `rules.hero_hp_mult` de cada vilão (data/villains.json). Fases 2 a 4: `villain_hp[vilão]` da fase
(data/campaign.json), um ajuste por vilão dentro da fase. Passo multiplicativo amortecido (±cap por ciclo);
células já dentro da faixa (meta ± tol) não mexem.

Ordem (os botões são aninhados: o da fase 1 vale em todas as fases): primeiro só --phases 1, depois congela e
calibra --phases 2,3,4. Calibrar os dois juntos fazia as células oscilarem.

Uso: python -I tools/tune_human.py --cycles 3 --runs 32 [--phases 1,2,3,4] [--villains plague,dragon] [--seed0 101]
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

VILLAINS = ["plague", "dragon", "lich"]
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
    ap.add_argument("--villains", "--pacts", dest="villains", default=",".join(VILLAINS))
    ap.add_argument("--pool", default="full", help="full (pool inteiro do vilão) ou start (coleção inicial)")
    ap.add_argument("--seed0", type=int, default=101)
    ap.add_argument("--bot", default="human")
    ap.add_argument("--slope", action="store_true", help="um passo pela inclinação medida (k=1/SLOPE, teto 30%%, sem tolerância)")
    ap.add_argument("--fixed-seeds", action="store_true", help="as mesmas sementes em todo ciclo")
    a = ap.parse_args()
    phases = [int(x) for x in a.phases.split(",")]
    pacts = a.villains.split(",")
    for cyc in range(a.cycles):
        decks = [p if ph == 1 else f"{p}@{ph}" for ph in phases for p in pacts]
        out = os.path.join(ROOT, "reports", "tune_human_tmp")
        # Sementes novas a cada ciclo: não ajusta ao ruído de um mesmo lote.
        runs, errs = run_batch.run_all([a.bot], decks, a.runs, seed0=a.seed0 + (0 if a.fixed_seeds else cyc * 1000), out=out, pool=a.pool)
        if errs:
            print("ERROS:", errs[:5])
        vil = load("data/villains.json")
        camp = load("data/campaign.json")
        print(f"\n== ciclo {cyc + 1}")
        # 15/11/2026: o jogo só lê o hp_mult/damage_mult DA FASE (campaign.json); a vida por vilão (villains.json
        # rules.hero_hp_mult) e villain_hp não são lidos pelo Sim. O botão é um só por fase e usa a média dos vilões;
        # a diferença entre vilões se corrige nas cartas/regras do vilão, não aqui.
        for ph in phases:
            line = []
            ws = []
            for p in pacts:
                lb = p if ph == 1 else f"{p}@{ph}"
                rs = [r for r in runs if r["deck"] == lb]
                w = sum(run_batch.is_win(r) for r in rs) / max(1, len(rs))
                ws.append(w)
                to = sum(r["result"] == "timeout" for r in rs)
                line.append(f"{p}={w:.0%}{'(' + str(to) + 'to)' if to else ''}")
            m = sum(ws) / len(ws)
            f = factor(m, TARGET[ph], k=1.0 / SLOPE, cap=0.3, tol=0.02) if a.slope else factor(m, TARGET[ph])
            for phd in camp["phases"]:
                if int(phd["id"]) == ph:
                    phd["hp_mult"] = round(float(phd.get("hp_mult", 1.0)) * f, 3)
                    nv = phd["hp_mult"]
            print(f"fase {ph} (meta {TARGET[ph]:.0%}, média {m:.0%}): " + "  ".join(line) + f"  -> hp_mult {nv}")
        save("data/campaign.json", camp)


if __name__ == "__main__":
    main()
