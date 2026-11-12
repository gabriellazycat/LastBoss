/* Camadas do molde de carta (renderizadas em PNG por render_layers.py).
   Usa as funções de pintura e a moldura de docs/decisoes_2026-11-11/cartas_v4.html (frameSvg, gemSvg, rough, flourish...).
   Escolhas do designer (12/11/2026): nível 2 e 3 = opção 2 com placa; Barato 2 sem pontilhado; Veterano 1; Explosivo 1;
   Amaldiçoado 2 (rachaduras viram shader animado); Sombrio 2 (manchas viram shader animado). */
const star=(x,y,r,f="#fff",o=.95)=>`<path d="M${x} ${y-r} Q${x} ${y} ${x+r} ${y} Q${x} ${y} ${x} ${y+r} Q${x} ${y} ${x-r} ${y} Q${x} ${y} ${x} ${y-r}Z" fill="${f}" opacity="${o}" filter="url(#bloom)"/>`;
const rivet=(x,y,r=3)=>`<circle cx="${x}" cy="${y}" r="${r}" fill="#dfe8f0" stroke="#2a3440" stroke-width="1.1"/><circle cx="${x-r*.3}" cy="${y-r*.3}" r="${r*.35}" fill="#fff"/>`;
const flame=(x,y,w,h,j,c1)=>`<path d="M${x-w/2} ${y} C${x-w/2} ${y-h*.4} ${x-w*.2} ${y-h*.55} ${x+j} ${y-h} C${x+w*.2} ${y-h*.55} ${x+w/2} ${y-h*.4} ${x+w/2} ${y}Z" fill="url(#${c1})"/>`;
function gradDefs(id){return `<defs>
 <linearGradient id="fl${id}" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#ffe27a"/><stop offset=".5" stop-color="#ff8a1f"/><stop offset="1" stop-color="#c2310c"/></linearGradient>
 <linearGradient id="nv${id}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3a5aa8"/><stop offset="1" stop-color="#15234f"/></linearGradient>
 <radialGradient id="vg${id}" cx="50%" cy="60%" r="70%"><stop offset=".5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".7"/></radialGradient></defs>`;}
function jag(H,seed,amp,base,step){const r=rng(seed);let P=[];const w=300,h=H;
 for(let t=0;t<=w;t+=step)P.push([t,base+r()*amp]);for(let t=0;t<=h;t+=step)P.push([w-(base+r()*amp),t]);
 for(let t=w;t>=0;t-=step)P.push([t,h-(base+r()*amp)]);for(let t=h;t>=0;t-=step)P.push([base+r()*amp,t]);
 return "M"+P.map(p=>f1(p[0])+" "+f1(p[1])).join("L")+"Z";}
/* kind: lv2 lv3 plaque2 plaque3 cheap veteran explosive cursed shadowy; H = 420 (grande) ou 380 (mão); wb = fundo da janela da arte */
function overlay(kind,H,wb,id){let s=gradDefs(id);const r=rng(kind.length*17+3);
 if(kind==="lv2"){
  const br=`<path d="M2 44 V10 Q2 2 10 2 H44 V14 H15 V44Z" fill="url(#steel)" stroke="#2a3440" stroke-width="1.4" filter="url(#frameInk)"/>${rivet(9,9,2.8)}`;
  s+=br+`<g transform="translate(300 0) scale(-1 1)">${br}</g><g transform="translate(0 ${H}) scale(1 -1)">${br}</g><g transform="translate(300 ${H}) scale(-1 -1)">${br}</g>`;
  s+=`<path d="M3 60 V${H-60} M297 60 V${H-60}" stroke="url(#steel)" stroke-width="6" stroke-linecap="round"/>`;
  s+=`<rect x="0" y="0" width="300" height="${wb}" fill="rgba(110,170,255,.12)"/>`+star(250,40,10)+star(48,160,8);
 }
 if(kind==="lv3"){
  s+=`<path d="${rough(3,3,294,H-6,5,.4,8)}" fill="none" stroke="url(#giltShim)" stroke-width="6" filter="url(#frameInk)"/>`;
  [[8,8,1,1],[292,8,-1,1],[8,H-8,1,-1],[292,H-8,-1,-1]].forEach(p=>s+=flourish(p[0],p[1],p[2],p[3],2.1,"url(#giltShim)",2.2));
  for(let i=0;i<9;i++){const y=60+i*((H-130)/8);[[7,-1],[293,1]].forEach(q=>{s+=`<path d="M${q[0]} ${y} q${q[1]*14} -6 ${q[1]*18} -18 q${-q[1]*14} 2 ${-q[1]*18} 18z" fill="url(#giltShim)" stroke="#6a3f06" stroke-width=".8" opacity=".95"/>`;});}
  s+=`<g transform="translate(150 4)"><path d="M-44 0 C-26 -10 -10 -8 0 -20 C10 -8 26 -10 44 0 C26 8 10 6 0 12 C-10 6 -26 8 -44 0Z" fill="url(#giltShim)" stroke="#6a3f06" stroke-width="1.6"/><path d="M0 -12 L8 0 L0 8 L-8 0Z" fill="#e33a3a" stroke="#6a3f06"/></g>`;
  s+=star(40,44,11,"#fff6c8")+star(256,36,9,"#fff6c8")+star(262,190,10,"#fff6c8");
 }
 if(kind==="plaque2")s+=`<g transform="translate(150 ${H-17})"><ellipse rx="26" ry="12" fill="url(#steel)" stroke="#2a3440" stroke-width="1.6"/>${rivet(-20,0,2.4)}${rivet(20,0,2.4)}</g>`;
 if(kind==="plaque3")s+=`<g transform="translate(150 ${H-17})"><ellipse rx="30" ry="12" fill="url(#giltShim)" stroke="#6a3f06" stroke-width="1.6"/></g>`;
 if(kind==="cheap"){
  s+=`<path d="M262 -10 C270 10 250 20 258 36" fill="none" stroke="#7a5a2a" stroke-width="2.4"/>`;
  s+=`<g transform="translate(258 78) rotate(10)" filter="url(#frameInk)"><path d="M-22 -30 L22 -30 L30 -18 L30 40 L-30 40 L-30 -18Z" fill="#f6edd6" stroke="#0a7a80" stroke-width="3"/><circle cx="0" cy="-21" r="4.4" fill="#2a3a3a"/><text y="-4" text-anchor="middle" font-family="IM Fell English SC,serif" font-size="9" fill="#0a7a80" letter-spacing="1.5">PREÇO</text><text y="30" text-anchor="middle" font-family="IM Fell English SC,serif" font-size="34" fill="#0a7a80">−1</text></g>`;
  [[40,226,8],[62,238,6],[250,238,7],[28,244,5]].forEach(c=>{if(c[1]<wb-4)s+=`<circle cx="${c[0]}" cy="${c[1]}" r="${c[2]}" fill="#f0c14b" stroke="#8a5a14" stroke-width="1.4"/><circle cx="${c[0]-c[2]*.3}" cy="${c[1]-c[2]*.3}" r="${c[2]*.3}" fill="#fff6c8"/>`;});
  s+=star(40,60,8,"#d8fff8")+star(200,40,6,"#d8fff8");
 }
 if(kind==="veteran"){
  s+=`<g filter="url(#frameInk)"><path d="M196 -4 L246 -4 L304 58 L304 104Z" fill="url(#nv${id})" stroke="#ffd98a" stroke-width="2.4"/><path d="M204 -4 L240 -4 L304 66 L304 90" fill="none" stroke="#ffd98a" stroke-width="1.2" stroke-dasharray="4 3"/></g>`;
  s+=`<g transform="translate(262 36) rotate(45)"><path d="M-24 -4 L-12 -12 L0 -4 L12 -12 L24 -4 L24 3 L12 -5 L0 3 L-12 -5 L-24 3Z" fill="#ffd98a"/><path d="M-24 8 L-12 0 L0 8 L12 0 L24 8 L24 15 L12 7 L0 15 L-12 7 L-24 15Z" fill="#ffd98a"/></g>`;
  s+=`<path d="M11 ${wb-60} L289 ${wb-120} L289 ${wb-96} L11 ${wb-36}Z" fill="rgba(190,215,255,.2)"/>`+star(54,52,10,"#dbe8ff")+star(240,170,9,"#dbe8ff")+star(80,200,6,"#dbe8ff");
 }
 if(kind==="explosive"){
  const fb=(H===380?318:250)+2;   // as chamas morrem na fita do nome (o nome tem que continuar legível)
  for(let i=0;i<16;i++){const x=16+i*17.5+(r()-.5)*8,h=34+r()*58;s+=`<g filter="url(#washBg)" opacity=".95">${flame(x,fb,26+r()*14,h,(r()-.5)*10,"fl"+id)}</g>`;}
  s+=`<g filter="url(#bloom)" fill="#ffd27a">${(()=>{let p="";for(let i=0;i<46;i++){const x=r()*290+5,y=r()*(wb-20),l=6+r()*12;p+=wedge(x,y,x+l*.38,y-l,1+r()*1.8);}return `<path d="${p}"/>`;})()}</g>`;
  s+=`<rect x="0" y="0" width="300" height="${wb}" fill="url(#vg${id})" opacity=".7"/>`;
 }
 /* a carta Explosiva tem a silhueta queimada e irregular: a máscara recorta a carta inteira e a borda desenha a brasa */
 if(kind==="explosive_mask")s+=`<path d="${jag(H,3,22,2,9)}" fill="#fff"/>`;
 if(kind==="explosive_edge")s+=`<path d="${jag(H,3,22,2,9)}" fill="none" stroke="#1a0c06" stroke-width="9" stroke-linejoin="round" opacity=".92" filter="url(#frameInk)"/><path d="${jag(H,3,22,2,9)}" fill="none" stroke="#ff7a1a" stroke-width="2.6" filter="url(#bloom)"/>`;
 /* só as partes estáticas: as rachaduras do Amaldiçoado e as manchas do Sombrio são shaders (game/ui/card_*.gdshader) */
 if(kind==="cursed"){
  s+=`<g transform="translate(250 56)" filter="url(#bloom)"><path d="M-26 0 Q0 -22 26 0 Q0 22 -26 0Z" fill="#2a0a3c" stroke="#e6a8ff" stroke-width="2.4"/><circle r="8" fill="#e6a8ff"/><circle r="3.4" fill="#2a0a3c"/></g>`;
  for(let i=0;i<4;i++)s+=`<path d="M${40+i*70} ${wb-6} C${20+i*70} ${wb-50} ${70+i*70} ${wb-80} ${44+i*70} ${wb-130}" fill="none" stroke="#d9a0ff" stroke-width="3" opacity=".5" filter="url(#soft2)"/>`;
  s+=`<rect x="0" y="0" width="300" height="${wb}" fill="rgba(90,0,140,.28)"/>`;
 }
 if(kind==="shadowy"){
  s+=`<path d="${rough(4,4,292,H-8,3,.6,8)}" fill="none" stroke="#dfe4ff" stroke-width="2.4" opacity=".85" filter="url(#bloom)"/>`;
  s+=`<path d="M11 ${wb} C30 ${wb-60} 70 ${wb-40} 100 ${wb-100} C120 ${wb-60} 150 ${wb-30} 190 ${wb-90} C220 ${wb-50} 250 ${wb-70} 289 ${wb-110} V${wb} Z" fill="#06060a" opacity=".85" filter="url(#washBg)"/>`;
  s+=`<g filter="url(#bloom)"><path d="M232 20 a22 22 0 1 0 22 28 a17 17 0 1 1 -22 -28Z" fill="#eef0ff"/></g>`;
 }
 return s;}
