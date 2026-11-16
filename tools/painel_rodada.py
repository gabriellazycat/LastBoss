"""Gera o painel HTML local da rodada de balanceamento (um arquivo só, sem servidor).

Uso: python -I tools/painel_rodada.py [pasta_da_base]   (padrão: balance_reports/rodada_2026-11-15/base)
Saída: <pasta>/../painel.html — abra pelo caminho file:/// no navegador.
"""
import collections
import datetime
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "balance_reports", "rodada_2026-11-15", "base")
OUT = os.path.join(os.path.dirname(BASE), "painel.html")


def jl(p, default=None):
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except OSError:
        return default


def win(r):
    return r["result"] in ("win", "win_early")


def norm(d):
    return d if "@" in d else d + "@1"


def mean(xs):
    xs = list(xs)
    return sum(xs) / len(xs) if xs else None


runs = jl(os.path.join(BASE, "runs.json"), [])
ch = jl(os.path.join(BASE, "challenges.json"), {})
sug = jl(os.path.join(BASE, "metas_sugeridas.json"), {})
relics_ab = jl(os.path.join(os.path.dirname(BASE), "relics", "resultado.json"), {})
villains = {v["id"]: v for v in jl(os.path.join(ROOT, "data", "villains.json"), {"villains": []})["villains"]}

# ---- vitória por bot × alvo
cells = collections.defaultdict(list)
for r in runs:
    cells[(r["bot"], norm(r["deck"]))].append(r)
bots = sorted({k[0] for k in cells}, key=lambda b: (b == "random", b != "human", b))
targets = sorted({k[1] for k in cells}, key=lambda t: (int(t.split("@")[1]), t))
winrate = {f"{b}|{t}": {"n": len(rs), "win": mean(map(win, rs)), "early": mean(r["result"] == "win_early" for r in rs),
                        "arena_t": mean(r["arena_t"] for r in rs if r["arena_t"] >= 0), "fallen": mean(r.get("heroes_fallen", 0) for r in rs),
                        "level": mean(r.get("hero_level_arena", 0) for r in rs if r["arena_t"] >= 0), "waste": mean(r["waste_frac"] for r in rs),
                        "game_s": mean(r["t_end"] for r in rs), "gold": mean(r.get("gold_earned", 0.0) for r in rs),
                        "empty": mean(r.get("empty_s", 0.0) / max(r["t_end"], 1.0) * 60 for r in rs),
                        "arena_reach": mean(r["arena_t"] >= 0 for r in rs),
                        "win_arena": mean(win(r) for r in rs if r["arena_t"] >= 0)}
           for (b, t), rs in cells.items() for _ in [0] if (f"{b}|{t}")}

# ---- cartas por alvo (bots não aleatórios)
smart = [r for r in runs if r["bot"] != "random"]
cards = {}
for t in targets:
    rs = [r for r in smart if norm(r["deck"]) == t]
    if not rs:
        continue
    base_win = mean(map(win, rs))
    played, dmg, picked, offered = (collections.Counter() for _ in range(4))
    with_w = collections.defaultdict(list)
    for r in rs:
        for k, v in r["played"].items():
            played[k] += v / len(rs)
        for k, v in r["dmg_by_card"].items():
            dmg[k] += v / len(rs)
        for k, v in r["picked"].items():
            picked[k] += v
        for k, v in r["offered"].items():
            offered[k] += v
        for k in set(r["deck_final"]):
            with_w[k].append(win(r))
    n = len(rs)
    rows = []
    for k in set(played) | set(dmg):
        if k.startswith(("mod:", "remove", "ev:")):
            continue
        w = with_w.get(k, [])
        rows.append({"id": k, "played": round(played[k], 1), "dmg": round(dmg[k]),
                     "pick": (picked[k] / offered[k]) if offered[k] else None, "in_deck": len(w) / n,
                     "win_with": mean(w) if len(w) >= 8 else None,
                     "lift": (mean(w) - base_win) if len(w) >= 8 else None})
    cards[t] = {"win": base_win, "n": n, "rows": sorted(rows, key=lambda x: -x["played"])}

# ---- desafios: por alvo (bot humano base + média dos perfis humanos)
chal = {}
for key, d in ch.items():
    bot, deck = key.split("|", 1)
    if bot == "random":
        continue
    chal.setdefault(norm(deck), {})
    for cid, e in d.items():
        a = chal[norm(deck)].setdefault(cid, {"kind": e["kind"], "meta": e["meta"], "total": e["total"], "runs": e["runs"], "meds": [], "cumpre": [], "p90": []})
        a["meds"].append(e["mediana"])
        a["cumpre"].append(e["cumpre"])
        a["p90"].append(e["p90"])
chal_out = {t: [{"id": c, "kind": a["kind"], "meta": a["meta"], "total": a["total"], "runs": a["runs"], "mediana": mean(a["meds"]),
                 "p90": max(a["p90"]), "cumpre": mean(a["cumpre"]), "sug": sug.get(c, {}).get("sugestao")}
                for c, a in d.items()] for t, d in chal.items()}

# ---- relíquias e eventos (triagem nos runs da base)
screen = {}
for label, keyf in [("relic", lambda r: set(r["relics"])), ("event", lambda r: {k for k in r["event_picks"]})]:
    items = set().union(*(keyf(r) for r in smart)) if smart else set()
    out = []
    for it in items:
        parts = []
        for t in targets:
            rs = [r for r in smart if norm(r["deck"]) == t]
            w = [r for r in rs if it in keyf(r)]
            wo = [r for r in rs if it not in keyf(r)]
            if len(w) >= 8 and len(wo) >= 8:
                parts.append((mean(map(win, w)) - mean(map(win, wo)), len(w)))
        if parts:
            tot = sum(n for _, n in parts)
            out.append({"id": it, "delta": sum(d * n for d, n in parts) / tot, "n": tot})
    screen[label] = sorted(out, key=lambda x: -x["delta"])
ab = []
for name, d in relics_ab.items():
    dh = [p["dheroes"][0] for p in d.values() if p["dheroes"][0] is not None]
    dw = [p["dwin"][0] for p in d.values() if p["dwin"][0] is not None]
    if dh:
        ab.append({"id": name, "dheroes": mean(dh), "dwin": mean(dw), "combos": len(d)})
ab.sort(key=lambda x: -x["dheroes"])

data = {"gerado": datetime.datetime.now().strftime("%d/%m/%Y %H:%M"), "pasta": os.path.relpath(BASE, ROOT), "runs": len(runs),
        "bots": bots, "targets": targets, "winrate": winrate, "cards": cards, "chal": chal_out, "screen": screen, "ab": ab,
        "goals": jl(os.path.join(ROOT, "data", "rules.json"), {}).get("goals", {})}

HTML = r"""<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Last Boss — painel de balanceamento</title>
<style>
:root{--bg:#f6f1e7;--card:#fffdf8;--ink:#2b2418;--mut:#7a6f5c;--line:#e3d9c4;--ok:#2f7d4f;--bad:#b3432f;--warn:#b98a1b;--acc:#5b3f8c}
@media(prefers-color-scheme:dark){:root{--bg:#1b1812;--card:#26221a;--ink:#efe7d4;--mut:#a39a85;--line:#3a3427;--ok:#5fc08a;--bad:#e5806c;--warn:#e0b84e;--acc:#b79af0}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.45 system-ui,Segoe UI,sans-serif}
header{padding:20px 16px 8px;max-width:1200px;margin:auto}h1{margin:0;font-size:24px}h2{margin:28px 0 8px;font-size:18px}
.sub{color:var(--mut);font-size:13px}main{max-width:1200px;margin:auto;padding:0 16px 60px}
.banner{background:color-mix(in srgb,var(--warn) 18%,var(--card));border:1px solid var(--warn);border-radius:8px;padding:10px 12px;margin:12px 0;font-size:14px}
.tabs{display:flex;gap:6px;flex-wrap:wrap;margin:14px 0}.tabs button,.sel button{background:var(--card);border:1px solid var(--line);color:var(--ink);padding:6px 12px;border-radius:999px;cursor:pointer;font:inherit}
.tabs button.on,.sel button.on{background:var(--acc);color:#fff;border-color:var(--acc)}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:10px}
.kpi{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:10px 12px}.kpi b{display:block;font-size:22px}.kpi span{color:var(--mut);font-size:12px}
.wrap{overflow-x:auto;background:var(--card);border:1px solid var(--line);border-radius:10px}
table{border-collapse:collapse;width:100%;font-size:13.5px}th,td{padding:6px 9px;border-bottom:1px solid var(--line);text-align:right;white-space:nowrap}
th{position:sticky;top:0;background:var(--card);cursor:pointer;color:var(--mut);font-weight:600}th:first-child,td:first-child{text-align:left}
.bar{display:inline-block;height:8px;border-radius:4px;background:var(--acc);vertical-align:middle;margin-left:6px}
.kpi .pill{display:inline-block;margin-top:4px}.pill{border-radius:999px;padding:1px 8px;font-size:12px;color:#fff}.g{background:var(--ok)}.r{background:var(--bad)}.y{background:var(--warn)}
.two{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:12px}
input{background:var(--card);color:var(--ink);border:1px solid var(--line);border-radius:6px;padding:5px 8px;font:inherit}
.hide{display:none}
</style></head><body>
<header><h1>Last Boss — painel de balanceamento</h1><div class="sub" id="meta"></div></header>
<main>
<div class="banner"><b>Atenção:</b> estes números vêm da linha de base das 12:20 de 15/11. Depois dela, outra conversa mudou <code>rules.json</code> e <code>campaign.json</code>; um controle às 14:05 deu 100% de vitória. Refaça a base antes de decidir valores (veja <code>docs/RODADA_2026-11-15.md</code>).</div>
<div class="tabs" id="tabs"></div>
<section id="s-visao"></section><section id="s-cartas" class="hide"></section><section id="s-desafios" class="hide"></section><section id="s-extras" class="hide"></section>
</main>
<script>
const D=__DATA__;
const $=(s,e=document)=>e.querySelector(s);const pc=v=>v==null?'—':Math.round(v*100)+'%';const nf=(v,d=1)=>v==null?'—':v.toFixed(d);
const nome=x=>x.replace(/_/g,' ');
let tgt=D.targets[0];let botSel='humanos';
const isHum=b=>b.startsWith('human');
function col(w,lo=.5,hi=.65){return w==null?'':(w<lo?'r':w>hi?'y':'g')}
$('#meta').textContent=`${D.runs} runs · fonte ${D.pasta} · gerado ${D.gerado}`;
const tabs=[['visao','Visão geral'],['cartas','Cartas'],['desafios','Desafios'],['extras','Relíquias e eventos']];
$('#tabs').innerHTML=tabs.map(([k,n],i)=>`<button data-k="${k}" class="${i?'':'on'}">${n}</button>`).join('');
$('#tabs').onclick=e=>{const k=e.target.dataset.k;if(!k)return;for(const b of $('#tabs').children)b.classList.toggle('on',b.dataset.k===k);for(const [t] of tabs)$('#s-'+t).classList.toggle('hide',t!==k)};
function sorter(tb){tb.querySelectorAll('th').forEach((th,i)=>th.onclick=()=>{const rows=[...tb.querySelectorAll('tbody tr')];const dir=th.dataset.d==='1'?-1:1;th.dataset.d=dir===1?'1':'0';
 rows.sort((a,b)=>{const x=a.children[i].dataset.v??a.children[i].textContent,y=b.children[i].dataset.v??b.children[i].textContent;const nx=parseFloat(x),ny=parseFloat(y);return (isNaN(nx)||isNaN(ny)?String(x).localeCompare(String(y)):nx-ny)*dir});
 rows.forEach(r=>tb.querySelector('tbody').appendChild(r))})}
function tgtButtons(id,fn){return `<div class="sel" id="${id}" style="display:flex;gap:6px;flex-wrap:wrap;margin:8px 0">`+D.targets.map(t=>`<button data-t="${t}" class="${t===tgt?'on':''}">${t.replace('@1',' · fase 1').replace('@3',' · fase 3')}</button>`).join('')+'</div>'}
function bindTgt(id,fn){$('#'+id).onclick=e=>{if(!e.target.dataset.t)return;tgt=e.target.dataset.t;fn()}}
// ---------- visão geral
function visao(){
 const hum=D.bots.filter(isHum),all=D.targets;
 const avg=(t,bs)=>{const v=bs.map(b=>D.winrate[b+'|'+t]).filter(Boolean);return v.length?v.reduce((a,x)=>a+x.win,0)/v.length:null};
 let h=`<h2>Vitória do bot por deck e fase</h2><div class="grid">`+all.map(t=>{const w=avg(t,hum);return `<div class="kpi"><span>${t.replace('@1',' · fase 1').replace('@3',' · fase 3')}</span><b>${pc(w)}</b><span class="pill ${col(w,t.endsWith('@1')?.5:.4,t.endsWith('@1')?.65:.6)}">${t.endsWith('@1')?'meta 50–65%':'meta ~40–60%'}</span></div>`}).join('')+`</div>`;
 h+=`<h2>Todos os bots</h2><div class="wrap"><table id="t-win"><thead><tr><th>bot</th>`+all.map(t=>`<th>${t}</th>`).join('')+`<th>média</th></tr></thead><tbody>`+
 D.bots.map(b=>{const vs=all.map(t=>D.winrate[b+'|'+t]);const m=vs.filter(Boolean).reduce((a,x)=>a+x.win,0)/Math.max(1,vs.filter(Boolean).length);
  return `<tr><td>${b}</td>`+vs.map(v=>v?`<td data-v="${v.win}"><span class="pill ${col(v.win)}">${pc(v.win)}</span> <span class="sub">n=${v.n}</span></td>`:'<td>—</td>').join('')+`<td data-v="${m}"><b>${pc(m)}</b></td></tr>`}).join('')+`</tbody></table></div>`;
 h+=`<h2>Detalhes (bot humano padrão)</h2><div class="wrap"><table id="t-det"><thead><tr><th>alvo</th><th>vitória</th><th>antecipada</th><th>chega à arena</th><th>vence na arena</th><th>chegada (s)</th><th>duração (s)</th><th>heróis caídos</th><th>nível herói</th><th>elixir perdido</th><th>ouro</th><th>vaga vazia (s/min)</th></tr></thead><tbody>`+
 all.map(t=>{const v=D.winrate['human|'+t];return v?`<tr><td>${t}</td><td data-v="${v.win}">${pc(v.win)}</td><td>${pc(v.early)}</td><td>${pc(v.arena_reach)}</td><td>${pc(v.win_arena)}</td><td>${nf(v.arena_t,0)}</td><td>${nf(v.game_s,0)}</td><td>${nf(v.fallen)}</td><td>${nf(v.level)}</td><td>${pc(v.waste)}</td><td>${nf(v.gold,0)}</td><td>${nf(v.empty)}</td></tr>`:''}).join('')+`</tbody></table></div>`;
 h+=`<h2>Metas do projeto</h2><div class="sub">vitória do bot bom ${D.goals.heuristic_win?D.goals.heuristic_win.map(x=>pc(x)).join(' a '):'—'} · aleatório ≤ ${pc(D.goals.random_win_max)} · chegada à arena ${D.goals.arena_arrival_s?D.goals.arena_arrival_s.join('–'):'—'} s · diferença entre decks ≤ ${pc(D.goals.deck_spread_max)} · carta dominante ≤ ${pc(D.goals.card_in_wins_max)} das vitórias.</div>`;
 $('#s-visao').innerHTML=h;sorter($('#t-win'));sorter($('#t-det'))}
// ---------- cartas
function cartas(){
 const c=D.cards[tgt];if(!c){$('#s-cartas').innerHTML='sem dados';return}
 const used=[...c.rows].sort((a,b)=>b.played-a.played)[0],dmg=[...c.rows].sort((a,b)=>b.dmg-a.dmg)[0],best=[...c.rows].filter(r=>r.lift!=null).sort((a,b)=>b.lift-a.lift)[0],worst=[...c.rows].filter(r=>r.lift!=null).sort((a,b)=>a.lift-b.lift)[0];
 let h=`<h2>Cartas — ${tgt}</h2>`+tgtButtons('b-c')+`<div class="grid"><div class="kpi"><span>Mais usada (jogadas/run)</span><b>${nome(used.id)}</b><span>${nf(used.played)} por run</span></div>
 <div class="kpi"><span>Mais dano (por run)</span><b>${nome(dmg.id)}</b><span>${dmg.dmg.toLocaleString('pt-BR')}</span></div>
 <div class="kpi"><span>Melhor (vitória com ela no deck final)</span><b>${best?nome(best.id):'—'}</b><span>${best?'+'+Math.round(best.lift*100)+' pp sobre a média':''}</span></div>
 <div class="kpi"><span>Pior</span><b>${worst?nome(worst.id):'—'}</b><span>${worst?Math.round(worst.lift*100)+' pp':''}</span></div>
 <div class="kpi"><span>Vitória média (bots não aleatórios)</span><b>${pc(c.win)}</b><span>n=${c.n} runs</span></div></div>
 <div class="sub" style="margin-top:8px">“Melhor/pior” compara a vitória das runs que terminaram com a carta no deck com a média; cartas ganhas mais tarde aparecem em runs que vão mais longe, então há viés. Só entram cartas com ≥ 8 runs.</div>
 <h2>Todas as cartas</h2><div class="wrap"><table id="t-cards"><thead><tr><th>carta</th><th>jogadas/run</th><th>dano/run</th><th>escolha quando oferecida</th><th>no deck final</th><th>vitória com ela</th><th>efeito (pp)</th></tr></thead><tbody>`+
 c.rows.map(r=>`<tr><td>${nome(r.id)}</td><td data-v="${r.played}">${nf(r.played)}<span class="bar" style="width:${Math.min(80,r.played*2)}px"></span></td><td data-v="${r.dmg}">${r.dmg.toLocaleString('pt-BR')}</td><td data-v="${r.pick??-1}">${pc(r.pick)}</td><td data-v="${r.in_deck}">${pc(r.in_deck)}</td><td data-v="${r.win_with??-1}">${pc(r.win_with)}</td><td data-v="${r.lift??-99}">${r.lift==null?'—':(r.lift>0?'+':'')+Math.round(r.lift*100)}</td></tr>`).join('')+`</tbody></table></div>`;
 $('#s-cartas').innerHTML=h;bindTgt('b-c',()=>{cartas();desafios()});sorter($('#t-cards'))}
// ---------- desafios
function desafios(){
 const l=D.chal[tgt];if(!l){$('#s-desafios').innerHTML='sem dados';return}
 const feitos=l.filter(x=>x.cumpre>=.5).length;
 let h=`<h2>Desafios das cartas — ${tgt}</h2>`+tgtButtons('b-d')+`<div class="grid"><div class="kpi"><span>Desafios cumpridos na maioria das runs</span><b>${feitos} / ${l.length}</b></div><div class="kpi"><span>Nunca cumpridos (0%)</span><b>${l.filter(x=>x.cumpre===0).length}</b></div><div class="kpi"><span>Fáceis (≥ 90%)</span><b>${l.filter(x=>x.cumpre>=.9).length}</b></div></div>
 <div class="sub" style="margin-top:8px">“cumpre” = fração das runs (perfis humanos) que bate a meta numa única run. Desafios “acumulado” somam várias fases, então 0% numa run é esperado. “sugestão” = 90% da maior mediana medida (só para contagens).</div>
 <div style="margin:8px 0"><input id="f-d" placeholder="filtrar carta ou tipo…"></div>
 <div class="wrap"><table id="t-ch"><thead><tr><th>carta</th><th>tipo</th><th>meta</th><th>mediana</th><th>p90</th><th>cumpre</th><th>sugestão</th><th>obs</th></tr></thead><tbody>`+
 l.sort((a,b)=>a.cumpre-b.cumpre).map(x=>`<tr><td>${nome(x.id)}</td><td>${x.kind}</td><td data-v="${x.meta}">${x.meta}</td><td data-v="${x.mediana}">${nf(x.mediana)}</td><td data-v="${x.p90}">${nf(x.p90)}</td><td data-v="${x.cumpre}"><span class="pill ${x.cumpre>=.9?'y':x.cumpre>=.1?'g':'r'}">${pc(x.cumpre)}</span></td><td>${x.sug??'—'}</td><td>${x.total?'acumulado':x.runs?'várias runs':''}</td></tr>`).join('')+`</tbody></table></div>`;
 $('#s-desafios').innerHTML=h;bindTgt('b-d',()=>{cartas();desafios()});sorter($('#t-ch'));
 $('#f-d').oninput=e=>{const q=e.target.value.toLowerCase();document.querySelectorAll('#t-ch tbody tr').forEach(r=>r.classList.toggle('hide',!r.textContent.toLowerCase().includes(q)))}}
// ---------- relíquias e eventos
function extras(){
 const tb=(rows,t)=>`<div class="wrap"><table><thead><tr><th>${t}</th><th>efeito na vitória (pp)</th><th>runs</th></tr></thead><tbody>`+rows.map(r=>`<tr><td>${nome(r.id)}</td><td><span class="pill ${r.delta>.08?'y':r.delta<-.08?'r':'g'}">${(r.delta>0?'+':'')+Math.round(r.delta*100)}</span></td><td>${r.n}</td></tr>`).join('')+`</tbody></table></div>`;
 let h=`<h2>Triagem nos runs da base (com ≥ 8 runs com e sem)</h2><div class="sub">Há viés de sobrevivência: relíquias do fim da run aparecem em runs que foram longe.</div><div class="two"><div><h2>Relíquias — melhores</h2>${tb(D.screen.relic.slice(0,12),'relíquia')}</div><div><h2>Relíquias — piores</h2>${tb(D.screen.relic.slice(-12).reverse(),'relíquia')}</div></div>
 <h2>Opções de evento escolhidas</h2>${tb(D.screen.event,'evento:opção')}
 <h2>A/B das relíquias forçadas (⚠ inválido)</h2><div class="banner">Este lote rodou enquanto o jogo mudava; os valores quase idênticos entre relíquias mostram o efeito da mudança, não da relíquia. Refazer.</div>
 <div class="wrap"><table><thead><tr><th>relíquia</th><th>Δ heróis caídos</th><th>Δ vitória (pp)</th><th>decks</th></tr></thead><tbody>`+D.ab.slice(0,60).map(r=>`<tr><td>${nome(r.id)}</td><td>${r.dheroes>0?'+':''}${nf(r.dheroes,2)}</td><td>${r.dwin>0?'+':''}${Math.round(r.dwin*100)}</td><td>${r.combos}</td></tr>`).join('')+`</tbody></table></div>`;
 $('#s-extras').innerHTML=h}
visao();cartas();desafios();extras();
</script></body></html>"""

with open(OUT, "w", encoding="utf-8") as f:
    f.write(HTML.replace("__DATA__", json.dumps(data, ensure_ascii=False)))
print("painel:", OUT)
