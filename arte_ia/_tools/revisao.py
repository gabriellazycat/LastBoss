"""Página local para revisar as cartas novas: marcar quais refazer e escrever o motivo (13/11/2026).

python -I revisao.py            ->  http://127.0.0.1:8792/
Serve arte_ia/final_novo/<id>.png (e, no botão "arte antiga", arte_ia/final/<id>.png). O que o designer marca é salvo
sozinho em arte_ia/refazer_pedidos.json: {"<id>": {"refazer": true, "motivo": "..."}}. Só escuta em 127.0.0.1.
"""
import json, os, sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))   # arte_ia/
PEDIDOS = os.path.join(ROOT, "refazer_pedidos.json")
PORT = 8792
FACCOES = {"plague": "Rainha da Peste", "dragon": "Dragão Avarento", "lich": "Lich", "common": "Comuns", "base": "Base"}


def cartas():
    out = []
    for c in json.load(open(os.path.join(ROOT, "cards.json"), encoding="utf-8")):
        p = os.path.join(ROOT, "final_novo", c["id"] + ".png")
        if os.path.exists(p):
            out.append(dict(id=c["id"], pt=c.get("pt", c["id"]), faccao=c["villain"], tipo=c["type"],
                            v=int(os.path.getmtime(p)),
                            antiga=os.path.exists(os.path.join(ROOT, "final", c["id"] + ".png"))))
    return out


def pedidos():
    try:
        return json.load(open(PEDIDOS, encoding="utf-8"))
    except Exception:
        return {}


def sugestoes():
    """Sugestões do Claude (arte_ia/sugestoes_claude.json): {"<id>": {"prioridade": "alta|media", "motivo": "..."}}"""
    try:
        return json.load(open(os.path.join(ROOT, "sugestoes_claude.json"), encoding="utf-8"))
    except Exception:
        return {}


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code, body, ctype):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        p = urlparse(self.path).path
        if p == "/":
            return self._send(200, PAGE.encode("utf-8"), "text/html; charset=utf-8")
        if p == "/dados":
            return self._send(200, json.dumps(dict(cartas=cartas(), pedidos=pedidos(), faccoes=FACCOES, sugestoes=sugestoes()),
                                              ensure_ascii=False).encode("utf-8"), "application/json")
        for pref, pasta in (("/img/", "final_novo"), ("/antiga/", "final")):
            if p.startswith(pref):
                cid = p[len(pref):-4]
                if p.endswith(".png") and cid.replace("_", "").isalnum():
                    f = os.path.join(ROOT, pasta, cid + ".png")
                    if os.path.exists(f):
                        return self._send(200, open(f, "rb").read(), "image/png")
        self._send(404, b"nao encontrado", "text/plain")

    def do_POST(self):
        if urlparse(self.path).path != "/salvar":
            return self._send(404, b"nao encontrado", "text/plain")
        n = int(self.headers.get("Content-Length", "0"))
        dados = json.loads(self.rfile.read(n).decode("utf-8"))
        ids = {c["id"] for c in cartas()}
        limpo = {k: dict(refazer=bool(v.get("refazer")), motivo=str(v.get("motivo", ""))[:2000])
                 for k, v in dados.items() if k in ids and (v.get("refazer") or v.get("motivo"))}
        json.dump(limpo, open(PEDIDOS, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        self._send(200, json.dumps(dict(ok=True, marcadas=sum(1 for v in limpo.values() if v["refazer"]))).encode(),
                   "application/json")


PAGE = r"""<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Revisão das cartas</title>
<style>
:root{--bg:#1d1a17;--panel:#2a2622;--line:#4a423a;--text:#ece4d6;--mut:#a79c8a;--acc:#e0a458;--bad:#d9604c}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:15px/1.4 system-ui,Segoe UI,sans-serif}
header{position:sticky;top:0;z-index:5;background:#15130f;border-bottom:1px solid var(--line);padding:10px 16px;display:flex;flex-wrap:wrap;gap:10px;align-items:center}
h1{font-size:17px;margin:0 8px 0 0}.cnt{color:var(--acc);font-weight:600}.save{color:var(--mut);font-size:13px;margin-left:auto}
button,input[type=search]{background:var(--panel);color:var(--text);border:1px solid var(--line);border-radius:6px;padding:6px 10px;font:inherit}
button{cursor:pointer}button.on{background:var(--acc);color:#1d1a17;border-color:var(--acc);font-weight:600}
label.tg{display:flex;gap:6px;align-items:center;color:var(--mut);cursor:pointer}
main{display:grid;grid-template-columns:repeat(auto-fill,minmax(270px,1fr));gap:14px;padding:16px}
.card{background:var(--panel);border:2px solid var(--line);border-radius:8px;overflow:hidden;display:flex;flex-direction:column}
.card.sug{border-color:#f2c14e;box-shadow:0 0 0 3px rgba(242,193,78,.28)}
.sugbox{margin:0 10px 6px;padding:6px 8px;background:#3a2f17;border:1px dashed #f2c14e;border-radius:6px;font-size:13px;color:#f2d9a0}
.sugbox b{color:#f2c14e}.sugbox button{margin-top:6px;padding:3px 9px;font-size:12px}
.leg{color:var(--mut);font-size:12.5px}.leg i{display:inline-block;width:11px;height:11px;border-radius:2px;vertical-align:-1px;margin:0 3px 0 8px}
.card.sel{border-color:var(--bad)}.card img{width:100%;aspect-ratio:556/534;object-fit:cover;display:block;cursor:zoom-in;background:#111}
.meta{padding:8px 10px 4px;display:flex;justify-content:space-between;gap:8px;align-items:baseline}.nm{font-weight:600}.id{color:var(--mut);font-size:12px}
.chk{padding:2px 10px 8px;display:flex;gap:8px;align-items:center;cursor:pointer;user-select:none}.chk input{width:18px;height:18px;accent-color:var(--bad)}
textarea{display:none;margin:0 10px 10px;width:calc(100% - 20px);min-height:64px;background:#15130f;color:var(--text);border:1px solid var(--bad);border-radius:6px;padding:7px;font:inherit;resize:vertical}
.card.sel textarea{display:block}
#lb{position:fixed;inset:0;background:rgba(0,0,0,.88);display:none;z-index:20;align-items:center;justify-content:center;flex-direction:column;gap:10px}
#lb.on{display:flex}#lb img{max-width:92vw;max-height:80vh;border-radius:6px}#lb .cap{color:var(--text)}#lb .hint{color:var(--mut);font-size:13px}
</style></head><body>
<header><h1>Revisão das cartas</h1><span id="cnt" class="cnt"></span>
<span id="fac"></span><input id="q" type="search" placeholder="buscar nome ou id">
<label class="tg"><input id="ant" type="checkbox"> mostrar arte antiga</label>
<span class="leg"><i style="background:#f2c14e"></i>sugestão do Claude<i style="background:#d9604c"></i>você marcou</span>
<span class="save" id="save">nada salvo ainda</span></header>
<main id="grid"></main>
<div id="lb"><img id="lbi"><div class="cap" id="lbc"></div><div class="hint">← → trocam de carta · Esc fecha · R marca/desmarca</div></div>
<script>
let D=null,P={},S={},fil='todas',timer=null,vis=[],cur=-1;
const $=s=>document.querySelector(s);
fetch('/dados').then(r=>r.json()).then(d=>{D=d;P=d.pedidos||{};S=d.sugestoes||{};build();render()});
function build(){const f=$('#fac');const mk=(k,t)=>{const b=document.createElement('button');b.textContent=t;b.dataset.k=k;b.onclick=()=>{fil=k;render()};f.appendChild(b)};
 mk('todas','Todas');for(const k in D.faccoes)mk(k,D.faccoes[k]);mk('marcadas','Marcadas');mk('sugeridas','Sugestões do Claude ('+Object.keys(S).length+')');
 $('#q').oninput=render;$('#ant').onchange=render}
function img(c){return ($('#ant').checked&&c.antiga?'/antiga/':'/img/')+c.id+'.png?v='+c.v}
function marcadas(){return Object.values(P).filter(x=>x.refazer).length}
function render(){
 document.querySelectorAll('#fac button').forEach(b=>b.classList.toggle('on',b.dataset.k===fil));
 const q=$('#q').value.trim().toLowerCase();
 vis=D.cartas.filter(c=>(fil==='todas'||(fil==='marcadas'?(P[c.id]&&P[c.id].refazer):fil==='sugeridas'?!!S[c.id]:c.faccao===fil))&&(!q||c.pt.toLowerCase().includes(q)||c.id.includes(q)));
 const g=$('#grid');g.innerHTML='';
 vis.forEach((c,i)=>{const p=P[c.id]||{};const el=document.createElement('div');el.className='card'+(p.refazer?' sel':'');
  el.innerHTML='<img loading="lazy"><div class="meta"><span class="nm"></span><span class="id"></span></div><label class="chk"><input type="checkbox"> Refazer esta carta</label><textarea placeholder="Por quê? (ex.: o dragão ficou com cara de cachorro)"></textarea>';
  const sg=S[c.id];if(sg){el.classList.add('sug');const bx=document.createElement('div');bx.className='sugbox';
   bx.innerHTML='<b>Sugestão do Claude ('+(sg.prioridade==='alta'?'prioritária':'secundária')+'):</b> <span></span><br><button>Aceitar: marcar para refazer</button>';
   bx.querySelector('span').textContent=sg.motivo;
   bx.querySelector('button').onclick=()=>{set(c.id,{refazer:true,motivo:(P[c.id]&&P[c.id].motivo)||sg.motivo});render()};
   el.querySelector('.meta').after(bx)}
  const im=el.querySelector('img');im.src=img(c);im.onclick=()=>open(i);
  el.querySelector('.nm').textContent=c.pt;el.querySelector('.id').textContent=c.id+' · '+(D.faccoes[c.faccao]||c.faccao);
  const cb=el.querySelector('input'),ta=el.querySelector('textarea');cb.checked=!!p.refazer;ta.value=p.motivo||'';
  cb.onchange=()=>{set(c.id,{refazer:cb.checked});el.classList.toggle('sel',cb.checked);if(cb.checked)ta.focus();count()};
  ta.oninput=()=>set(c.id,{motivo:ta.value});g.appendChild(el)});
 count()}
function count(){$('#cnt').textContent=D.cartas.length+' cartas · '+marcadas()+' para refazer'}
function set(id,patch){P[id]=Object.assign({refazer:false,motivo:''},P[id]||{},patch);if(!P[id].refazer&&!P[id].motivo)delete P[id];
 clearTimeout(timer);$('#save').textContent='salvando…';timer=setTimeout(salvar,400)}
function salvar(){fetch('/salvar',{method:'POST',body:JSON.stringify(P)}).then(r=>r.json()).then(r=>{$('#save').textContent='salvo às '+new Date().toLocaleTimeString()+' ('+r.marcadas+' marcadas)'}).catch(()=>{$('#save').textContent='ERRO ao salvar: o servidor está rodando?'})}
function open(i){cur=i;const c=vis[i];$('#lbi').src=img(c);$('#lbc').textContent=c.pt+' ('+c.id+')'+((P[c.id]||{}).refazer?' — MARCADA':'');$('#lb').classList.add('on')}
$('#lb').onclick=()=>$('#lb').classList.remove('on');
document.addEventListener('keydown',e=>{if(!$('#lb').classList.contains('on'))return;
 if(e.key==='Escape')$('#lb').classList.remove('on');
 else if(e.key==='ArrowRight'&&cur<vis.length-1)open(cur+1);else if(e.key==='ArrowLeft'&&cur>0)open(cur-1);
 else if(e.key.toLowerCase()==='r'){const c=vis[cur];set(c.id,{refazer:!(P[c.id]&&P[c.id].refazer)});open(cur);render();}});
</script></body></html>"""

if __name__ == "__main__":
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), H)
    print(f"http://127.0.0.1:{PORT}/  (pedidos em {PEDIDOS})", flush=True)
    srv.serve_forever()
