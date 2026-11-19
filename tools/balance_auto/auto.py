"""Ajustador automático de balanceamento (docs/PLANO_AJUSTADOR_AUTOMATICO.md).
Uso (sempre python -I): python -I tools/balance_auto/auto.py all|smoke|triage|cards|relics|events|difficulty|validate|notes
Tudo retomável: runs em cache (balance_reports/auto/runs_cache.jsonl) e estado em balance_reports/auto/state.json.
Nada vai para data/ aqui: só a página de patch notes e o JSON de patches propostos."""
import json
import math
import os
import statistics
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import engine as E  # noqa: E402
import notes  # noqa: E402

sys.stdout.reconfigure(encoding="utf-8")
STATE_P = os.path.join(E.WORK, "state.json")
VILL = ["plague", "dragon", "lich"]
PH = int(os.environ.get("BA_PHASE", 5))      # fase de medição das cartas/relíquias
BOT = "human"
TARGETS = {0: 0.90, 1: 0.60, 2: 0.56, 3: 0.52, 4: 0.48, 5: 0.44, 6: 0.40}
N1 = int(os.environ.get("BA_N1", 16))        # sementes da triagem barata
N2 = int(os.environ.get("BA_N2", 32))        # sementes extras nos suspeitos
NT = int(os.environ.get("BA_NT", 24))        # sementes por ciclo de ajuste
CYCLES = int(os.environ.get("BA_CYCLES", 4))
LIM = 0.4


def now():
    return time.strftime("%Y-%m-%d %H:%M:%S")


def load_state():
    if os.path.exists(STATE_P):
        return json.load(open(STATE_P, encoding="utf-8"))
    return {"done": [], "frozen": [], "cards": {}, "relics": {}, "events": {}, "phases": {}, "smoke": {}, "valid": {}, "log": [],
            "tol": {}, "repensar": [], "bot_nao_usa": [], "audit": {}}


S = load_state()


def save():
    E.save_json(STATE_P, S)
    try:
        notes.write(S, os.path.join(E.ROOT, "tools", "patch_notes.html"))
    except Exception as e:
        print("notes falhou:", e)


def log(msg):
    print(f"[{now()}] {msg}", flush=True)
    S["log"].append(f"{now()} {msg}")
    S["log"] = S["log"][-300:]


def cell(v, ph=PH):
    return f"{v}@{ph}"


def M(reqs):
    return E.measure_many(reqs)


def frozen():
    return [tuple(p) for p in S["frozen"]]


# ---------- catálogo ----------
def card_index():
    idx = {}
    for fn in ["cards.json", "cards_common.json", "cards_plague.json", "cards_dragon.json", "cards_lich.json"]:
        for c in E.jload("data/" + fn)["cards"]:
            assert c["id"] not in idx, "carta duplicada " + c["id"]
            idx[c["id"]] = (fn, c)
    return idx


CARDS = card_index()
VDATA = {v["id"]: v for v in E.jload("data/villains.json")["villains"]}


def ref_for(vill, cost):
    deck = VDATA[vill]["start_deck"]
    best = sorted(set(deck), key=lambda i: (abs(CARDS[i][1]["cost"] - cost), -deck.count(i), i))
    return best[0]


def cand_cards():
    out = []
    for cid, (fn, c) in CARDS.items():
        if c.get("category") == "aux" or c.get("owner") in (None, "") or c.get("owner") not in VILL + ["common"]:
            continue
        out.append((cid, c.get("owner")))
    return out


def knobs_of(c):
    """Botões da carta em ordem de preferência: lista de (path_rel, valor)."""
    ks = []
    if c.get("type") == "spell":
        for k, v in c.get("fx", {}).items():
            if isinstance(v, (int, float)) and not isinstance(v, bool) and k != "duration" and v:
                ks.append((["fx", k], v))
        if isinstance(c.get("fx", {}).get("duration"), (int, float)):
            ks.append((["fx", "duration"], c["fx"]["duration"]))
    else:
        if c.get("dps", 0) > 0:
            ks.append((["dps"], c["dps"]))
        if c.get("hp", 0) > 0:
            ks.append((["hp"], c["hp"]))
        if c.get("attack_interval", 0) and c.get("dps", 0) > 0:
            ks.append((["attack_interval"], c["attack_interval"]))
        if c.get("speed", 0) > 0:
            ks.append((["speed"], c["speed"]))
    ks.append((["cost"], c["cost"]))
    return ks


def rnd_like(orig, v):
    if isinstance(orig, int) and not isinstance(orig, bool):
        return int(round(v))
    return float(f"{v:.3g}") if abs(v) < 100 else float(round(v))


# ---------- passo 6: smoke ----------
def smoke():
    log("smoke: humano em todas as fases × baralhos, 8 sementes")
    reqs = []
    for ph in range(7):
        for v in (["plague"] if ph == 0 else VILL):
            reqs.append({"patches": [], "bot": BOT, "cell": cell(v, ph), "seeds": list(range(1, 9))})
    t0 = time.time()
    M(reqs)
    wall = time.time() - t0
    allr = [r for q in reqs for r in q["runs"]]
    n = len(allr)
    S["smoke"] = {"runs": n, "wall_s": wall, "mediana_ms": statistics.median(r["ms"] for r in allr) if n else None,
                  "runs_por_hora": n / wall * 3600 if wall else None,
                  "win": {q["cell"]: E.winrate(q["runs"]) for q in reqs},
                  "hp_frac": {q["cell"]: E.mean([r["hp_frac"] for r in q["runs"]]) for q in reqs}}
    log(f"smoke ok: {n} runs em {wall:.0f}s ({S['smoke']['runs_por_hora']:.0f}/h)")
    S["done"].append("smoke")
    save()


# ---------- A/B de itens (cartas, relíquias) ----------
class Item:
    def __init__(self, kind, iid, cells, mkextra, group="", knobs=None):
        self.kind, self.id, self.cells, self.mkextra, self.group, self.knobs = kind, iid, cells, mkextra, group, knobs or []


def impact(items, seeds, patches_by_id=None):
    """Impacto de cada item (Δ hp_frac vs controle, pareado por semente). Retorna {id: dict|None}."""
    fz = list(frozen())
    reqs, ctl = [], {}
    for it in items:
        for c in it.cells:
            if c not in ctl:
                ctl[c] = {"patches": fz, "bot": BOT, "cell": c, "seeds": seeds}
                reqs.append(ctl[c])
    arms = []
    for it in items:
        extra_p = (patches_by_id or {}).get(it.id, [])
        for c in it.cells:
            r = {"patches": fz + extra_p, "bot": BOT, "cell": c, "seeds": seeds, "extra": it.mkextra(c)}
            arms.append((it, c, r))
            reqs.append(r)
    M(reqs)
    out = {}
    for it in items:
        ds = []
        for (i2, c, r) in arms:
            if i2 is it:
                da = {x["seed"]: x for x in ctl[c]["runs"]}
                ds += [(x["hp_frac"] - da[x["seed"]]["hp_frac"], x["played"], float(x["win"]) - float(da[x["seed"]]["win"])) for x in r["runs"] if x["seed"] in da]
        if len(ds) < 2:
            out[it.id] = None
            continue
        v = [d[0] for d in ds]
        m = E.mean(v)
        se = math.sqrt(sum((x - m) ** 2 for x in v) / (len(v) - 1) / len(v))
        use = E.mean([float(d[1].get(it.id, 0)) if isinstance(d[1], dict) else 0.0 for d in ds])
        out[it.id] = {"m": m, "se": se, "n": len(v), "use": use, "dwin": E.mean([d[2] for d in ds])}
    return out


def merge(a, b):
    if not a:
        return b
    if not b:
        return a
    n = a["n"] + b["n"]
    m = (a["m"] * a["n"] + b["m"] * b["n"]) / n
    var = (a["se"] ** 2 * a["n"] ** 2 + b["se"] ** 2 * b["n"] ** 2) / n ** 2
    return {"m": m, "se": math.sqrt(var), "n": n, "use": (a["use"] * a["n"] + b["use"] * b["n"]) / n,
            "dwin": (a["dwin"] * a["n"] + b["dwin"] * b["n"]) / n}


def centers(res, groups):
    cen = {}
    for g in set(groups.values()):
        xs = [res[i]["m"] for i in res if res[i] and groups[i] == g]
        cen[g] = statistics.median(xs) if xs else 0.0
    return cen


def tol_from(res):
    ses = [r["se"] for r in res.values() if r]
    return 1.96 * statistics.median(ses) if ses else 0.1


def out_of_band(r, center, tol):
    z = r["m"] - center
    return abs(z) > tol and abs(z) > 1.96 * r["se"]


# ---------- camada 0/1: cartas ----------
def card_items():
    its = []
    for cid, owner in cand_cards():
        cost = CARDS[cid][1]["cost"]
        vs = VILL if owner == "common" else [owner]
        refs = {cell(v): ref_for(v, cost) for v in vs}
        its.append(Item("card", cid, [cell(v) for v in vs],
                        lambda c, cid=cid, refs=refs: {"swap_card": f"{cid}:{refs[c]}"} if refs[c] != cid else {},
                        group=f"custo{cost}", knobs=knobs_of(CARDS[cid][1])))
    return its


def triage():
    log("triagem de cartas: passo 1")
    its = card_items()
    res = impact(its, list(range(101, 101 + N1)))
    groups = {i.id: i.group for i in its}
    res = {k: v for k, v in res.items() if v}
    cen = centers(res, groups)
    tol = tol_from(res)
    log(f"tolerância (1,96×ep mediano com {N1} sementes) = {tol:.3f} da vida do grupo")
    sus = [i for i in its if i.id in res and (abs(res[i.id]["m"] - cen[groups[i.id]]) > tol * 0.6 or res[i.id]["use"] < 0.3)]
    log(f"suspeitos: {len(sus)}/{len(its)}; passo 2 com +{N2} sementes")
    res2 = impact(sus, list(range(201, 201 + N2)))
    for k, v in res2.items():
        res[k] = merge(res[k], v)
    cen = centers(res, groups)
    full = {k: v for k, v in res.items() if v and v["n"] >= N1 + N2}
    tol = tol_from(full) if full else tol
    S["tol"]["cards"] = tol
    S["cards"] = {}
    S["bot_nao_usa"] = [b for b in S["bot_nao_usa"] if b["kind"] != "card"]
    for it in its:
        r = res.get(it.id)
        if not r:
            continue
        S["cards"][it.id] = {"impact": r["m"], "se": r["se"], "n": r["n"], "use": r["use"], "center": cen[it.group], "z": r["m"] - cen[it.group],
                             "group": it.group, "flag": bool(out_of_band(r, cen[it.group], tol)), "dwin": r["dwin"], "history": []}
        if r["use"] < 0.3 and r["n"] >= N1 + N2:
            S["bot_nao_usa"].append({"kind": "card", "id": it.id, "use": r["use"]})
    log(f"tolerância final = {tol:.3f}; fora da faixa: {sum(c['flag'] for c in S['cards'].values())}")
    S["done"].append("triage")
    save()


def tune(kind, key, items_all, file_of, base_path_of, tol):
    """Busca por coordenadas: um botão por item por ciclo; passo por secante em ln(fator); limites ±40% (custo ±1)."""
    active = {i.id: i for i in items_all if S[key].get(i.id, {}).get("flag")}
    st = {cid: {"k": 0, "f": 1.0, "pts": []} for cid in active}
    last = {cid: S[key][cid]["z"] for cid in active}
    for cyc in range(CYCLES):
        todo = [it for cid, it in active.items() if S[key][cid].get("status") not in ("ok", "repensar")]
        prop = {}
        for it in todo:
            s = st[it.id]
            z = last[it.id]
            while s["k"] < len(it.knobs):
                path, orig = it.knobs[s["k"]]
                sign = -1.0 if z > 0 else 1.0
                if path == ["cost"]:
                    new = orig + (1 if z > 0 else -1)
                    if new < 0 or new == orig:
                        s["k"] += 1
                        continue
                    prop[it.id] = (path, orig, new, None)
                    break
                if len(s["pts"]) >= 2 and abs(s["pts"][-1][0] - s["pts"][-2][0]) > 1e-6:
                    (x0, y0), (x1, y1) = s["pts"][-2], s["pts"][-1]
                    slope = (y1 - y0) / (x1 - x0)
                    d = -y1 / slope if abs(slope) > 1e-9 else 0.15 * sign
                    d = max(-0.3, min(0.3, d))
                else:
                    d = 0.15 * sign
                if path[-1] == "attack_interval":
                    d = -d   # intervalo maior = mais fraco
                f_new = min(1 + LIM, max(1 - LIM, math.exp(math.log(s["f"]) + d)))
                new = rnd_like(orig, orig * f_new)
                if abs(f_new - s["f"]) < 0.02 or new == orig:
                    s["k"] += 1
                    s["f"], s["pts"] = 1.0, []
                    continue
                prop[it.id] = (path, orig, new, f_new)
                break
            if it.id not in prop:
                S[key][it.id]["status"] = "repensar"
        if not prop:
            break
        patches = {cid: [(file_of(cid), base_path_of(cid) + p[0], p[2])] for cid, p in prop.items()}
        seeds = list(range(5000 + 100 * cyc, 5000 + 100 * cyc + NT))
        res = impact([active[c] for c in prop], seeds, patches)
        for cid, (path, orig, new, f_new) in prop.items():
            r = res.get(cid)
            if not r:
                continue
            s = st[cid]
            z = r["m"] - S[key][cid]["center"]
            last[cid] = z
            if f_new is not None:
                s["f"] = f_new
                s["pts"].append((math.log(f_new), z))
            hist = S[key][cid]["history"]
            hist.append({"cycle": cyc, "knob": ".".join(map(str, path)), "from": orig, "to": new, "z": z, "se": r["se"], "n": r["n"]})
            S[key][cid]["proposal"] = {"knob": ".".join(map(str, path)), "file": file_of(cid), "path": base_path_of(cid) + path, "from": orig, "to": new,
                                       "z_after": z, "se_after": r["se"], "n_after": r["n"], "use": r["use"], "dwin": r["dwin"]}
            if abs(z) <= max(tol, 1.96 * r["se"]):
                S[key][cid]["status"] = "ok"
            elif len(hist) >= 3 and hist[-1]["knob"] == hist[-3]["knob"] and abs(hist[-1]["z"]) > 0.7 * abs(hist[-3]["z"]):
                s["k"] += 1
                s["f"], s["pts"] = 1.0, []
        log(f"{kind} ciclo {cyc + 1}: {len(prop)} itens ajustados; na faixa: {sum(1 for c in active if S[key][c].get('status') == 'ok')}/{len(active)}")
        save()
    for cid in active:
        c = S[key][cid]
        if c.get("status") == "repensar":
            S["repensar"].append({"kind": kind, "id": cid, "why": "botões saturados ou sem efeito", "z": c["z"]})
        elif c.get("status") != "ok":
            c["status"] = "parcial"


def cards_layer():
    its = card_items()
    log("camada 1: ajuste de cartas")
    tune("card", "cards", its, lambda cid: CARDS[cid][0], lambda cid: ["cards", {"id": cid}], S["tol"]["cards"])
    for cid, c in S["cards"].items():
        p = c.get("proposal")
        if p and c.get("status") == "ok" and abs(p["z_after"]) < abs(c["z"]):
            S["frozen"].append([p["file"], p["path"], p["to"]])
            c["applied"] = True
    S["done"].append("cards")
    save()


# ---------- camada 3: relíquias ----------
def relic_items():
    its = []
    for r in E.jload("data/relics.json")["relics"]:
        ks = [(["fx", k], v) for k, v in r.get("fx", {}).items() if isinstance(v, (int, float)) and not isinstance(v, bool) and v]
        its.append(Item("relic", r["id"], [cell(v) for v in VILL], lambda c, rid=r["id"]: {"force_relic": rid}, group=r.get("rarity", ""), knobs=ks))
    return its


def relics_layer():
    log("camada 3: relíquias (A/B com force_relic)")
    its = relic_items()
    groups = {i.id: i.group for i in its}
    res = {k: v for k, v in impact(its, list(range(301, 301 + N1))).items() if v}
    cen = centers(res, groups)
    tol = tol_from(res)
    sus = [i for i in its if i.id in res and abs(res[i.id]["m"] - cen[groups[i.id]]) > tol * 0.6]
    for k, v in impact(sus, list(range(401, 401 + N2))).items():
        res[k] = merge(res[k], v)
    cen = centers(res, groups)
    S["tol"]["relics"] = tol
    S["relics"] = {}
    for it in its:
        r = res.get(it.id)
        if r:
            S["relics"][it.id] = {"impact": r["m"], "se": r["se"], "n": r["n"], "use": r["use"], "center": cen[it.group], "z": r["m"] - cen[it.group],
                                  "group": it.group, "flag": bool(out_of_band(r, cen[it.group], tol)), "dwin": r["dwin"], "history": []}
    for it in its:
        c = S["relics"].get(it.id)
        if c and c["flag"] and not it.knobs:
            c["status"] = "repensar"
            S["repensar"].append({"kind": "relic", "id": it.id, "why": "efeito sem número em fx (estrutural)", "z": c["z"]})
    tune("relic", "relics", [i for i in its if i.knobs], lambda cid: "relics.json", lambda cid: ["relics", {"id": cid}], tol)
    for cid, c in S["relics"].items():
        p = c.get("proposal")
        if p and c.get("status") == "ok" and abs(p["z_after"]) < abs(c["z"]):
            S["frozen"].append([p["file"], p["path"], p["to"]])
            c["applied"] = True
    S["done"].append("relics")
    save()


# ---------- camada 4: eventos ----------
def events_layer():
    log("camada 4: eventos (medição; sem botões automáticos)")
    its = []
    for ev in E.jload("data/events.json")["events"]:
        for i, op in enumerate(ev["options"]):
            its.append(Item("event", f"{ev['id']}:{i}:{op['id']}", [cell(v) for v in VILL], lambda c, k=f"{ev['id']}:{i}": {"force_event": k}, group="evento"))
    res = {k: v for k, v in impact(its, list(range(501, 501 + N1 + N2))).items() if v}
    cen = statistics.median([v["m"] for v in res.values()]) if res else 0
    tol = tol_from(res)
    S["tol"]["events"] = tol
    S["events"] = {}
    for k, v in res.items():
        z = v["m"] - cen
        fl = bool(out_of_band(v, cen, tol))
        S["events"][k] = {"impact": v["m"], "se": v["se"], "n": v["n"], "center": cen, "z": z, "flag": fl, "dwin": v["dwin"], "use": 0, "history": []}
        if fl:
            S["repensar"].append({"kind": "event", "id": k, "why": "impacto fora da faixa; evento sem botão automático", "z": z})
    S["done"].append("events")
    save()


# ---------- camada 5: dificuldade ----------
def logit(p):
    p = min(0.96, max(0.04, p))
    return math.log(p / (1 - p))


def hp_patch(ph, val, orig):
    return [("campaign.json", ["phases", {"id": ph}, "hp_mult"], round(val, 4))] if abs(val - orig) > 1e-9 else []


def difficulty():
    log("camada 5: dificuldade por fase (só hp_mult)")
    camp = E.jload("data/campaign.json")["phases"]
    for ph in range(7):
        orig = camp[ph]["hp_mult"]
        cur = orig
        vs = ["plague"] if ph == 0 else VILL
        hist, slope = [], -2.5
        info = {"orig": orig, "target": TARGETS[ph], "probes": []}
        for pr in range(6):
            reqs = [{"patches": frozen() + hp_patch(ph, cur, orig), "bot": BOT, "cell": cell(v, ph),
                     "seeds": list(range(7000 + 40 * pr, 7000 + 40 * pr + 30))} for v in vs]
            M(reqs)
            p = E.mean([E.winrate(r["runs"]) for r in reqs])
            n = sum(len(r["runs"]) for r in reqs)
            info["probes"].append({"hp_mult": cur, "win": p, "n": n})
            log(f"fase {ph}: hp_mult={cur:.3f} humano={p:.0%} (meta {TARGETS[ph]:.0%}, n={n})")
            if abs(p - TARGETS[ph]) <= 0.06:
                break
            hist.append((math.log(cur), logit(p)))
            if len(hist) >= 2 and abs(hist[-1][0] - hist[-2][0]) > 1e-3:
                sl = (hist[-1][1] - hist[-2][1]) / (hist[-1][0] - hist[-2][0])
                if sl < -0.3:
                    slope = sl
            d = max(-0.35, min(0.35, (logit(TARGETS[ph]) - logit(p)) / slope))
            new = min(orig * 2.0, max(orig * 0.5, cur * math.exp(d)))
            if abs(new - cur) < 1e-3:
                S["repensar"].append({"kind": "phase", "id": str(ph), "why": f"hp_mult saturou em {cur:.3f} (humano {p:.0%}, meta {TARGETS[ph]:.0%})"})
                break
            cur = new
        info["final"] = round(cur, 4)
        info["win"] = info["probes"][-1]["win"]
        reqs = [{"patches": frozen() + hp_patch(ph, cur, orig), "bot": "random", "cell": cell(v, ph), "seeds": list(range(8000, 8020))} for v in vs]
        M(reqs)
        info["random"] = E.mean([E.winrate(r["runs"]) for r in reqs])
        if abs(info["win"] - TARGETS[ph]) <= 0.1 and info["random"] > 0.25:
            S["repensar"].append({"kind": "phase", "id": str(ph), "why": f"alarme de mecânica: humano {info['win']:.0%} mas aleatório {info['random']:.0%} (>25%)"})
        S["phases"][str(ph)] = info
        save()
    S["done"].append("difficulty")
    save()


# ---------- validação ----------
def validate():
    log("validação: família human_* e heurístico, sementes novas, tudo ligado")
    camp = E.jload("data/campaign.json")["phases"]
    patches = frozen()
    for ph in range(7):
        f = S["phases"].get(str(ph), {}).get("final")
        if f:
            patches = patches + hp_patch(ph, f, camp[ph]["hp_mult"])
    S["final_patches"] = [list(p) for p in patches]
    bots = ["human", "human_novice", "human_careful", "human_rusher", "human_spell", "human_swarm", "heuristic", "random"]
    reqs = [{"patches": patches, "bot": b, "cell": cell(v, ph), "seeds": list(range(90001, 90013))}
            for b in bots for ph in range(7) for v in (["plague"] if ph == 0 else VILL)]
    M(reqs)
    tab = {}
    for r in reqs:
        tab.setdefault(r["bot"], {}).setdefault(r["cell"].split("@")[1], []).append(E.winrate(r["runs"]))
    S["valid"] = {b: {ph: E.mean(v) for ph, v in d.items()} for b, d in tab.items()}
    S["done"].append("validate")
    save()


def run_all():
    steps = [("smoke", smoke), ("triage", triage), ("cards", cards_layer), ("relics", relics_layer), ("events", events_layer),
             ("difficulty", difficulty), ("validate", validate)]
    for name, fn in steps:
        if name not in S["done"]:
            fn()
    S["finished"] = now()
    save()
    log("TUDO PRONTO. Página: tools/patch_notes.html")


if __name__ == "__main__":
    E.load_store()
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    {"all": run_all, "smoke": smoke, "triage": triage, "cards": cards_layer, "relics": relics_layer, "events": events_layer,
     "difficulty": difficulty, "validate": validate, "notes": save}[cmd]()
