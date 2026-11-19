"""Gera tools/patch_notes.html a partir de state.json: patch notes com caixa de aprovar e exportação JSON."""
import html
import json
import time


def pct(x):
    return "—" if x is None else f"{x * 100:.0f}%"


def changes(S):
    """Lista de mudanças propostas: dicts com file/path/from/to + contexto."""
    out = []
    for kind, key in (("carta", "cards"), ("relíquia", "relics")):
        for iid, c in S.get(key, {}).items():
            p = c.get("proposal")
            if p and c.get("applied"):
                out.append({"kind": kind, "id": iid, "file": p["file"], "path": p["path"], "from": p["from"], "to": p["to"], "knob": p["knob"],
                            "why": f"impacto {c['z']:+.3f} → {p['z_after']:+.3f} (±{1.96 * p['se_after']:.3f}) da vida do grupo vs. mediana do custo/raridade",
                            "n": p["n_after"], "use": p.get("use"), "status": c.get("status")})
    for ph, i in sorted(S.get("phases", {}).items()):
        if abs(i["final"] - i["orig"]) > 1e-9:
            out.append({"kind": "fase", "id": f"fase {ph}", "file": "campaign.json", "path": ["phases", {"id": int(ph)}, "hp_mult"], "from": i["orig"], "to": i["final"],
                        "knob": "hp_mult", "why": f"humano {pct(i['probes'][0]['win'])} → {pct(i['win'])} (meta {pct(i['target'])}); aleatório {pct(i.get('random'))}",
                        "n": sum(p["n"] for p in i["probes"]), "use": None, "status": "ok"})
    return out


CSS = "body{font:14px system-ui;max-width:1100px;margin:20px auto;padding:0 12px;background:#faf6ee;color:#2b2118}table{border-collapse:collapse;width:100%;margin:8px 0}td,th{border:1px solid #cdbf9f;padding:4px 6px;text-align:left}th{background:#eadfc4}h2{margin-top:28px}.bad{background:#f6d9d0}.ok{background:#dcebcf}button{padding:8px 14px;font-size:15px}pre{background:#fff;padding:8px;max-height:260px;overflow:auto}"


def tbl(rows, head):
    return "<table><tr>" + "".join(f"<th>{h}</th>" for h in head) + "</tr>" + "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in rows) + "</table>"


def write(S, path):
    ch = changes(S)
    rows = []
    for i, c in enumerate(ch):
        rows.append([f"<input type=checkbox class=ap data-i={i}>", c["kind"], html.escape(str(c["id"])), html.escape(c["knob"]), f"{c['from']} → <b>{c['to']}</b>",
                     html.escape(c["why"]), c["n"], status_cell(c)])
    h = [f"<!doctype html><meta charset=utf-8><title>Patch notes do ajustador</title><style>{CSS}</style>",
         f"<h1>Patch notes do ajustador automático</h1><p>Gerado em {time.strftime('%d/%m/%Y %H:%M')}. Etapas feitas: {', '.join(S.get('done', [])) or 'nenhuma'}. "
         f"Nada disto foi para data/. Marque o que aprova e exporte; depois rode <code>python -I tools/balance_auto/apply_approved.py aprovados.json</code>.</p>"]
    tl = S.get("tol", {})
    h.append(f"<p>Faixa de tolerância medida (vida do grupo): cartas {tl.get('cards', 0):.3f}, relíquias {tl.get('relics', 0):.3f}, eventos {tl.get('events', 0):.3f}. "
             "Impacto = Δ da fração de vida do grupo de heróis tirada, A/B pareado por semente com o bot humano.</p>")
    sm = S.get("smoke") or {}
    if sm:
        h.append(f"<p>Smoke: {sm['runs']} runs, mediana {sm['mediana_ms'] / 1000:.1f}s por run, {sm['runs_por_hora']:.0f} runs/h.</p>")
    h.append("<h2>Mudanças propostas</h2><button onclick='exp()'>Exportar aprovados (JSON)</button> <button onclick='all_(true)'>marcar todos</button><pre id=out></pre>")
    h.append(tbl(rows, ["ok", "tipo", "item", "botão", "antes → depois", "motivo", "n", "estado"]))
    rp = [[r["kind"], html.escape(str(r["id"])), html.escape(r["why"]), f"{r.get('z', 0):+.3f}" if "z" in r else ""] for r in S.get("repensar", [])]
    h.append("<h2>Repensar (mecânica, não número)</h2>" + tbl(rp, ["tipo", "item", "motivo", "z"]))
    nu = [[r["kind"], r["id"], f"{r['use']:.2f} jogadas/run"] for r in S.get("bot_nao_usa", [])]
    h.append("<h2>O bot não usa (não é carta fraca)</h2>" + tbl(nu, ["tipo", "item", "uso"]))
    for key, title in (("cards", "Cartas"), ("relics", "Relíquias"), ("events", "Eventos e opções")):
        d = S.get(key, {})
        rr = sorted(d.items(), key=lambda kv: -abs(kv[1]["z"]))
        rows2 = [[html.escape(k), v.get("group", ""), f"{v['impact']:+.3f}", f"±{1.96 * v['se']:.3f}", f"{v['z']:+.3f}", v["n"], f"{v.get('use', 0):.2f}",
                  f"{v.get('dwin', 0) * 100:+.0f} pp", "fora" if v["flag"] else "dentro", v.get("status", "")] for k, v in rr]
        h.append(f"<h2>{title}: medição</h2>" + tbl(rows2, ["item", "grupo", "impacto", "IC95", "z", "n", "jogadas/run", "Δ vitória", "faixa", "estado"]))
    ph = S.get("phases", {})
    h.append("<h2>Dificuldade por fase (humano)</h2>" + tbl([[k, f"{v['orig']}", f"{v['final']}", pct(v["target"]), pct(v["win"]), pct(v.get("random"))] for k, v in sorted(ph.items())],
                                                          ["fase", "hp_mult antes", "depois", "meta", "humano", "aleatório"]))
    va = S.get("valid", {})
    if va:
        phs = ["0", "1", "2", "3", "4", "5", "6"]
        h.append("<h2>Validação (sementes novas, tudo ligado)</h2>" + tbl([[b] + [pct(d.get(p)) for p in phs] for b, d in va.items()], ["bot"] + [f"fase {p}" for p in phs]))
    h.append("<h2>Registro</h2><pre>" + html.escape("\n".join(S.get("log", [])[-60:])) + "</pre>")
    h.append("<script>const CH=" + json.dumps(ch, ensure_ascii=False) + ";function exp(){const a=[...document.querySelectorAll('.ap')].filter(x=>x.checked).map(x=>{const c=CH[x.dataset.i];return {kind:c.kind,id:c.id,file:c.file,path:c.path,from:c.from,to:c.to}});document.getElementById('out').textContent=JSON.stringify(a,null,1);navigator.clipboard&&navigator.clipboard.writeText(JSON.stringify(a,null,1)).catch(()=>{})}function all_(v){document.querySelectorAll('.ap').forEach(x=>x.checked=v)}</script>")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(h))


def status_cell(c):
    return {"ok": "na faixa", "parcial": "melhorou, não zerou"}.get(c.get("status"), str(c.get("status", "")))
