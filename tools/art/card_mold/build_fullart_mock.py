"""Gera docs/arte_cartas/mockup_moldura/page_tail3.html (mock da arte cheia com os upgrades) a partir de page_tail2.html.
Uso: python tools/art/card_mold/build_fullart_mock.py   (depois monte a página com o build_mock do scratchpad)
Só para visualização antes de implementar; não faz parte do jogo."""
from pathlib import Path

D = Path(__file__).resolve().parents[3] / "docs" / "arte_cartas" / "mockup_moldura"
s = (D / "page_tail2.html").read_text(encoding="utf-8")
funcs = s[s.index("KIND.structure="):s.index("function X(c,o)")]
bind = s[s.index("function bindTilt"):s.index("KIND.structure=")]

CSS = r"""<style>
.vCr .name{top:250px!important;height:38px!important;left:30px!important;right:30px!important;font-size:23px!important;color:#fff6e2!important;text-shadow:0 1px 0 rgba(0,0,0,.55),0 0 6px rgba(0,0,0,.35)!important;z-index:8}
.vCr .panel{top:262px!important}.vCr .type{top:296px!important}.vCr .rules{top:318px!important}
.vCr .panel{background:linear-gradient(rgba(250,243,226,.78),rgba(246,236,214,.92))!important}
.m-veteran .panel{background:linear-gradient(rgba(70,92,150,.82),rgba(28,42,90,.94))!important}.m-cursed .panel{background:linear-gradient(rgba(100,60,130,.82),rgba(36,12,52,.94))!important}
.m-shadowy .panel{background:linear-gradient(rgba(70,70,80,.82),rgba(12,12,16,.94))!important}.m-cheap .panel{background:linear-gradient(rgba(200,243,232,.8),rgba(127,205,191,.94))!important}
.m-explosive .panel{background:linear-gradient(rgba(241,200,138,.8),rgba(166,93,40,.94))!important}
.sweep{position:absolute;inset:0;border-radius:10px;overflow:hidden;pointer-events:none;z-index:12}
.sweep:after{content:"";position:absolute;top:-20%;bottom:-20%;width:70px;left:-90px;transform:rotate(18deg);background:linear-gradient(90deg,transparent,rgba(255,236,170,.6),rgba(180,240,255,.45),rgba(255,170,230,.4),transparent);animation:sw 3.4s ease-in-out infinite}
@keyframes sw{0%{left:-90px}65%,100%{left:360px}}
.card.lv2{box-shadow:0 8px 18px rgba(0,0,0,.55),0 0 0 2px #cfe0f2,0 0 34px 6px rgba(140,200,255,.7)}
.card.lv3{box-shadow:0 8px 18px rgba(0,0,0,.55),0 0 0 2px #f2cf6a,0 0 44px 10px rgba(255,200,70,.85)}
.m-veteran .rules,.m-cursed .rules,.m-shadowy .rules,.m-veteran .type,.m-cursed .type,.m-shadowy .type{color:#f1e8d6!important}
.m-veteran .rules b,.m-cursed .rules b,.m-shadowy .rules b{color:#ffd98a!important}
.rules .add{display:block;font-size:14px;color:#6e5038}.rules .up{color:#1f7a2b;font-weight:700}.m-veteran .up,.m-cursed .up,.m-shadowy .up{color:#7dffa0}
.old{position:absolute;left:58px;top:8px;z-index:11;font-family:"IM Fell English SC",serif;font-size:18px;color:#fff;text-decoration:line-through;text-shadow:0 1px 3px #000}
.quad{gap:34px 44px}
</style>
<main>
 <h1>Arte cheia · carta com os mesmos efeitos</h1>
 <p class="lede">A arte ocupa a carta toda (como na <b>C da v4</b>) e a moldura, a fita, o nível e os efeitos são os que você aprovou. Duas opções de arte cheia, e depois a opção 2 com todos os upgrades.</p>
 <div id="rows"></div>
</main>
<script>

"""

JS = r"""
function ribbon(kind,rar){const kc=KIND[kind].c,y=250,hh=38;const gilt=(rar==="rare"||rar==="legendary")?"url(#gilt)":"none";let s="";
 s+='<path d="M30 '+(y+5)+' L6 '+(y+8)+' L16 '+(y+hh/2+7)+' L6 '+(y+hh+6)+' L30 '+(y+hh+3)+'Z" fill="'+mix(kc,"#000000",.35)+'" filter="url(#frameInk)"/><path d="M270 '+(y+5)+' L294 '+(y+8)+' L284 '+(y+hh/2+7)+' L294 '+(y+hh+6)+' L270 '+(y+hh+3)+'Z" fill="'+mix(kc,"#000000",.35)+'" filter="url(#frameInk)"/>';
 s+='<path d="M22 '+y+' Q150 '+(y-7)+' 278 '+y+' L278 '+(y+hh)+' Q150 '+(y+hh-7)+' 22 '+(y+hh)+'Z" fill="'+kc+'" filter="url(#gemWash)"/><path d="M22 '+y+' Q150 '+(y-7)+' 278 '+y+' L278 '+(y+hh)+' Q150 '+(y+hh-7)+' 22 '+(y+hh)+'Z" fill="none" stroke="#1e0e06" stroke-width="1.3" filter="url(#frameInk)"/>';
 s+='<path d="M26 '+(y+3.5)+' Q150 '+(y-3.5)+' 274 '+(y+3.5)+'" fill="none" stroke="#fff2d8" stroke-width="1" opacity=".45"/>';
 if(gilt!=="none")s+='<path d="M22 '+(y+hh)+' Q150 '+(y+hh-7)+' 278 '+(y+hh)+'" fill="none" stroke="'+gilt+'" stroke-width="1.6"/>';
 return '<svg class="frame" viewBox="0 0 300 420" width="300" height="420" style="z-index:7">'+s+'</svg>';}
function Y(c,o){o=Object.assign({v:"C",scale:1},o);const mods=o.mods||[],lvl=o.level||1;
 const c2=Object.assign({},c);let old=0;
 if(mods.includes("cheap")){old=c.cost;c2.cost=c.cost-1;}
 c2.text=c.text+mods.filter(m=>TXT[m]).map(m=>TXT[m]).join("");
 if(mods.includes("veteran"))c2.text=c2.text.replace("libera 6",'libera <span class="up">7 ▲</span>');
 o.img=c.img;o.mods=[];o.level=1;
 let h=slot(c2,o);
 const wb=310;let ov="";
 const kinds=[];if(lvl>1)kinds.push("lv"+lvl);mods.forEach(m=>kinds.push(m));
 kinds.forEach(k=>{const va=(k==="veteran"||k==="explosive")?1:2;ov+='<svg class="ov" viewBox="0 0 300 420" width="300" height="420" style="position:absolute;left:0;top:0;z-index:7;overflow:visible;pointer-events:none">'+overlay(k,va,420,k==="explosive"?252:wb,"y"+(OID++))+'</svg>';});
 if(o.rib)h=h.replace('<div class="gem">',ribbon(c.kind,c.rar)+'<div class="gem">');
 h=h.replace('<div class="gem">',ov+'<div class="gem">');
 h=h.replace('class="card ','class="card '+(o.rib?"vCr ":"")+(lvl>1?"lv"+lvl+" ":"")+(mods[0]?"m-"+mods[0]+" ":""));
 if(old)h=h.replace('<div class="gem">','<div class="gem cheapg"><span class="old">'+old+'</span>');
 if(lvl===3)h=h.replace('<div class="shine">','<div class="sweep"></div><div class="shine">');
 return h;}
const cell=(h,cap)=>'<div class="cell">'+h+'<div class="vcap">'+cap+'</div></div>';
const G={scale:320/300},SM={scale:.5,compact:true};
const mk=(o)=>Y(K,Object.assign({},G,o));
document.getElementById("rows").innerHTML=
'<section><h2>1 · Duas opções de arte cheia</h2><div class="quad" style="margin-top:20px">'+
 cell(mk({}),"<b>Opção 1</b> · como a C da v4: arte até a base, título em nanquim sobre um painel de papel translúcido")+
 cell(mk({rib:1}),"<b>Opção 2</b> · arte cheia com a <b>fita dobrada</b> do nome por cima e o texto no painel embaixo")+
 cell(mk({rib:1,level:3,mods:["explosive"]}),"<b>Opção 2</b> com nível 3 + Explosivo (a carta queimada se sobressai)")+'</div></section>'+
'<section><h2>2 · Opção 2 com os upgrades</h2><div class="quad" style="margin-top:20px">'+
 [{level:2},{level:3},{mods:["cheap"]},{mods:["veteran"]},{mods:["explosive"]},{mods:["cursed"]},{mods:["shadowy"]}].map((o,i)=>cell(mk(Object.assign({rib:1},o)),["Nível 2","Nível 3","Barato","Veterano","Explosivo","Amaldiçoado (no jogo, as rachaduras são um shader animado)","Sombrio (no jogo, as manchas são um shader animado)"][i])).join("")+'</div></section>'+
'<section><h2>3 · Na mão a 150 px</h2><div class="hand"><div class="lbl">Opção 1 e opção 2</div>'+[{},{rib:1},{rib:1,level:3},{rib:1,mods:["explosive"]},{rib:1,mods:["cursed"]}].map(o=>Y(K,Object.assign({},SM,o))).join("")+'</div></section>';
bindTilt();
</script></body></html>
"""

(D / "page_tail3.html").write_text(CSS + bind + funcs + JS, encoding="utf-8")
print("ok")
