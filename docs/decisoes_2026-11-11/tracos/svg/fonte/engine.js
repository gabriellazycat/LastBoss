"use strict";
/* Motor: silhuetas unidas (paper.js) + nanquim de pressão + aguada solta.
   Tudo em coordenadas do mundo (viewBox 0..300 x 0..420 da carta). */
const PP=paper;PP.setup(new PP.Size(600,600));PP.settings.insertItems=false;
const r2=n=>Math.round(n*100)/100;
function mat(){return new PP.Matrix();}
function S(d,m){const it=PP.PathItem.create(d);if(m)it.transform(m);return it;}
function kids(it){if(!it)return[];return it.className==="CompoundPath"?it.children.slice():[it];}
function U(arr){arr=arr.filter(Boolean);let r=arr[0];for(let i=1;i<arr.length;i++){try{r=r.unite(arr[i]);}catch(e){console.log("unite fail",e);}}return r;}
function clean(it,min=5){const k=kids(it).filter(c=>Math.abs(c.area)>=min).map(c=>c.clone());return new PP.CompoundPath({children:k,fillRule:"evenodd"});}
function dOf(it){return (it.pathData||"").replace(/-?\d+\.\d+/g,m=>String(Math.round(+m*10)/10));}
/* deixa a silhueta com cara de curva desenhada: achata, simplifica, treme de leve */
function organic(it,o={}){const tol=o.tol??1.1,amp=o.amp??.45,nz=noise1(o.seed??(SEED++));const out=[];
  for(const c0 of kids(it)){const c=c0.clone();c.flatten(.45);if(c.segments.length>4)c.simplify(tol);
    const L=c.length;for(const sg of c.segments){const off=c.getOffsetOf(sg.point);if(off==null)continue;const nn=c.getNormalAt(off);if(!nn)continue;
      const j=(nz(off/14)-.5)*2*amp;sg.point=sg.point.add(nn.multiply(j));}
    if(Math.abs(c.area)>3)out.push(c);}
  return new PP.CompoundPath({children:out,fillRule:"evenodd"});}

/* ---------------- tinta ---------------- */
function inside(F,p){return !!F&&F.bounds.expand(2).contains(p)&&F.contains(p);}
const sinT=(d,t,fl)=>fl+(1-fl)*Math.sin(Math.min(1,Math.max(0,d)/t)*Math.PI/2);
/* stroke = {P:[Point],N:[Point],W:[w]} -> faixa preenchida */
function ribbon(P,N,W){if(P.length<2)return"";const A=[],B=[];for(let i=0;i<P.length;i++){const w=Math.max(0.04,W[i])/2;A.push(r2(P[i].x+N[i].x*w)+" "+r2(P[i].y+N[i].y*w));B.push(r2(P[i].x-N[i].x*w)+" "+r2(P[i].y-N[i].y*w));}
  return "M"+A.join("L")+"L"+B.reverse().join("L")+"Z";}
function buildStroke(P,N,T,W,st,en){ // st/en: {ext, tap, fl}
  P=P.slice();N=N.slice();W=W.slice();
  const pre=[],preN=[],preW=[];if(st.ext>0){const k=Math.max(1,Math.round(st.ext/.8));for(let i=k;i>=1;i--){pre.push(P[0].subtract(T[0].multiply(st.ext*i/k)));preN.push(N[0]);preW.push(W[0]);}}
  const post=[],postN=[],postW=[];const n=P.length;if(en.ext>0){const k=Math.max(1,Math.round(en.ext/.8));for(let i=1;i<=k;i++){post.push(P[n-1].add(T[n-1].multiply(en.ext*i/k)));postN.push(N[n-1]);postW.push(W[n-1]);}}
  P=pre.concat(P,post);N=preN.concat(N,postN);W=preW.concat(W,postW);
  const s=[0];for(let i=1;i<P.length;i++)s.push(s[i-1]+P[i].getDistance(P[i-1]));const Lt=s[s.length-1];if(Lt<1.5)return"";
  const tt0=Math.min(st.tap,Lt*.4),tt1=Math.min(en.tap,Lt*.4);
  W=W.map((w,i)=>w*sinT(s[i],tt0,st.fl)*sinT(Lt-s[i],tt1,en.fl));
  return ribbon(P,N,W);}
/* contorno fechado da silhueta: largura pela luz, quebras em quinas com sobra, falhas no lado da luz, oclusão */
function contourInk(it,o,F,Ld){const step=o.step??.85,w=o.w??1.8,a=o.a??.5,b=o.b??.62,lost=o.lost??.3,occ=o.occ??.9,cornerDeg=o.corner??52,seg=o.seg??130;let out="";
  let ci=0;
  for(const c of kids(it)){ci++;const L=c.length;if(L<4)continue;const n=Math.max(10,Math.ceil(L/step));const nz=noise1((o.seed??3)+ci*13),gz=noise1((o.seed??3)+ci*13+71),rr=rng((o.seed??3)+ci*7);
    const P=[],N=[],T=[];
    for(let i=0;i<n;i++){const off=L*i/n;const p=c.getPointAt(off),t=c.getTangentAt(off);if(!p||!t)continue;let nn=new PP.Point(-t.y,t.x);if(it.contains(p.add(nn.multiply(.5))))nn=nn.multiply(-1);P.push(p);T.push(t);N.push(nn);}
    const m=P.length;if(m<6)continue;
    const on=[],W=[];let s=0;
    for(let i=0;i<m;i++){if(i)s+=P[i].getDistance(P[i-1]);const dot=N[i].x*Ld[0]+N[i].y*Ld[1];
      let ww=w*Math.max(o.min??.2,Math.min(1.35,a+b*dot))*(.78+.44*nz(s/17));
      let v=!(inside(F,P[i])||inside(F,P[i].add(N[i].multiply(occ))));
      if(v&&dot<-(o.lostDot??.45)&&gz(s/26)<lost)v="lost";
      on.push(v);W.push(ww);}
    // quinas
    const brk=new Array(m).fill(0);const K=Math.max(2,Math.round(3/step));
    const turn=i=>{const t0=T[(i-K+m)%m],t1=T[(i+K)%m];return Math.acos(Math.max(-1,Math.min(1,t0.x*t1.x+t0.y*t1.y)))*180/Math.PI;};
    const tv=P.map((_,i)=>turn(i));
    for(let i=0;i<m;i++){if(tv[i]>cornerDeg&&tv[i]>=tv[(i-1+m)%m]&&tv[i]>=tv[(i+1)%m])brk[i]=1;}
    // quebras longas (traço retomado)
    let acc=0,lim=seg*(.7+rr()*.6);for(let i=0;i<m;i++){acc+=step;if(brk[i]){acc=0;continue;}if(acc>lim){brk[i]=2;acc=0;lim=seg*(.7+rr()*.6);}}
    // começar num ponto "fora" ou numa quebra
    let st=on.findIndex(v=>v!==true);if(st<0){st=brk.findIndex(v=>v>0);if(st<0)st=0;}
    let cur=null,startT=null;
    const flush=(endType)=>{if(cur&&cur.length>2){const ends={corner:{ext:o.over??2.6,tap:3.5,fl:.22},long:{ext:2.2,tap:5,fl:.08},occ:{ext:.6,tap:1.2,fl:.55},lost:{ext:0,tap:8,fl:0}};
        out+=buildStroke(cur.map(i=>P[i]),cur.map(i=>N[i]),cur.map(i=>T[i]),cur.map(i=>W[i]),ends[startT],ends[endType]);}cur=null;};
    for(let k=0;k<=m;k++){const i=(st+k)%m;const v=on[i];
      if(v===true){if(!cur){cur=[];const pv=on[(i-1+m)%m];startT=pv==="lost"?"lost":(pv===false?"occ":(brk[i]===1?"corner":"long"));}
        cur.push(i);
        if(brk[i]&&cur.length>1&&k<m){flush(brk[i]===1?"corner":"long");cur=[i];startT=brk[i]===1?"corner":"long";}}
      else{if(cur)flush(v==="lost"?"lost":"occ");}}
    flush(on[st]==="lost"?"lost":(on[st]===false?"occ":"long"));}
  return out;}
/* traço aberto: afina nas pontas, pressão maior no começo, oclusão */
function openInk(d,o,F,m){const it=typeof d==="string"?S(d,m):d;let out="";const w=o.w??1,step=o.step??.7;
  for(const c of kids(it)){const L=c.length;if(L<1.5)continue;const n=Math.max(4,Math.ceil(L/step));const nz=noise1(o.seed??(SEED++));
    const P=[],N=[],T=[],W=[],V=[];
    for(let i=0;i<=n;i++){const off=Math.min(L,L*i/n);const p=c.getPointAt(off),t=c.getTangentAt(off);if(!p||!t)continue;P.push(p);T.push(t);N.push(new PP.Point(-t.y,t.x));
      const u=i/n;let ww=w*((o.w0??1)+((o.w1??.55)-(o.w0??1))*u)*(.8+.4*nz(off/9));W.push(ww);V.push(!(o.noOcc)&&inside(F,p)?0:1);}
    let cur=[],sT=null;const flush=eT=>{if(cur.length>1)out+=buildStroke(cur.map(i=>P[i]),cur.map(i=>N[i]),cur.map(i=>T[i]),cur.map(i=>W[i]),sT,eT);cur=[];};
    const endA={ext:o.ext0??.6,tap:o.tap0??Math.min(4,L*.3),fl:o.fl0??.12},endB={ext:o.ext1??1,tap:o.tap1??Math.min(6,L*.4),fl:o.fl1??.04},occE={ext:.5,tap:1,fl:.5};
    for(let i=0;i<P.length;i++){if(V[i]){if(!cur.length)sT=i===0?endA:occE;cur.push(i);}else if(cur.length)flush(occE);}
    if(cur.length)flush(endB);}
  return out;}
/* aresta interna: o contorno da parte que cai dentro das partes de trás do mesmo grupo */
function edgeIn(part,behind,o,F){let out="";const step=.8;
  for(const c of kids(part)){const L=c.length;const n=Math.ceil(L/step);let run=[];
    const flushRun=()=>{if(run.length*step>(o.minLen??5)){const kp=o.keep??1;const segs=kp>=.5?[run]:[run.slice(0,Math.max(3,Math.round(run.length*kp))),run.slice(Math.round(run.length*(1-kp))).reverse()];if(o.oneEnd)segs.length=1;for(const sg of segs){if(sg.length<3)continue;const pth=new PP.Path(sg);out+=openInk(pth,Object.assign({tap0:2,tap1:kp<.5?Math.max(4,sg.length*step*.6):4,fl0:.15,fl1:.0},o),F);}}run=[];};
    for(let i=0;i<=n;i++){const p=c.getPointAt(Math.min(L,L*i/n));if(!p)continue;
      const ins=behind.contains(p)&&behind.getNearestPoint(p).getDistance(p)>(o.margin??1.4);
      if(ins)run.push(p);else flushRun();}
    flushRun();}
  return out;}

/* ---------------- cena ---------------- */
/* obj: {id, parts:{k:d}, m (Matrix), union:[k] (padrão: todas), shape (PathItem pronto), fill, shade, deep, op, patches:[{d|part,col,op,m}],
         ink:{...}|0, lines:[{d,w,...}], edges:[[k,[k..],{w}]], top:"svg", wash:"wash" } */
function buildScene(scn){
  const Ld=nrm(scn.L);const objs=scn.objs;
  // 1) silhuetas
  for(const ob of objs){const m=ob.m||null;ob.P={};for(const k in (ob.parts||{}))ob.P[k]=S(ob.parts[k],m);
    let raw=ob.shape||U((ob.union||Object.keys(ob.P)).map(k=>ob.P[k].clone()));
    raw=clean(raw,ob.minArea??4);ob.sil=ob.noOrganic?raw:organic(raw,{tol:ob.tol??1.0,amp:ob.amp??.4,seed:ob.seed??(SEED++)});}
  // 2) uniões da frente (sufixo)
  let acc=null;for(let i=objs.length-1;i>=0;i--){objs[i].F=acc;if(objs[i].occludes!==false)acc=acc?U([acc,objs[i].sil]):objs[i].sil.clone();}
  // 3) aguada
  let washes="",inks="",tops="";
  for(const ob of objs){const F=ob.F;let vis=ob.sil;if(F&&F.bounds.intersects(vis.bounds)){try{vis=vis.subtract(F);}catch(e){console.log("sub fail",ob.id);}}
    ob.vis=vis;if(Math.abs(kidsArea(vis))<2)continue;
    let g="";const k=(ob.k??8)*(scn.kmul??1);const reg=ob.reg||scn.reg||[1.8,1.3];
    if(ob.fill){let base=vis;
      if(ob.gaps!==0){ // papel aparecendo do lado da luz
        try{const bl=gapEdge(vis,Ld,ob.gapSeed??(SEED++),ob.gapN??4,ob.gapR??Math.max(2.5,Math.min(7,Math.sqrt(kidsArea(vis))*.05)));if(bl)base=vis.subtract(bl);}catch(e){console.log("gap",e);}}
      g+=`<path d="${dOf(base)}" fill="${ob.fill}" fill-rule="evenodd" opacity="${ob.op??.85}"/>`;}
    for(const pt of (ob.patches||[])){let ps=pt.part?ob.P[pt.part].clone():S(pt.d,pt.noM?null:ob.m);if(pt.organic!==false)ps=organic(ps,{tol:.8,amp:.3});try{ps=ps.intersect(pt.free?ob.sil.clone().scale(1.04):vis);}catch(e){}
      g+=`<path d="${dOf(ps)}" fill="${pt.col}" fill-rule="evenodd" opacity="${pt.op??.8}"/>`;}
    if(ob.shade){try{const sh=vis.subtract(vis.clone().translate(new PP.Point(-Ld[0]*k,-Ld[1]*k)));g+=`<path d="${dOf(sh)}" fill="${ob.shade}" fill-rule="evenodd" opacity="${ob.shOp??.6}"/>`;
      if(ob.deep){const dp=vis.subtract(vis.clone().translate(new PP.Point(-Ld[0]*k*.42,-Ld[1]*k*.42)));g+=`<path d="${dOf(dp)}" fill="${ob.deep}" fill-rule="evenodd" opacity="${ob.dpOp??.5}"/>`;}}catch(e){}}
    washes+=`<g filter="url(#${ob.wash||"wash"})" transform="translate(${reg[0]} ${reg[1]})">${g}</g>`+(ob.washExtra||"");
    // 4) tinta
    const io=Object.assign({},scn.ink,ob.ink||{});
    if(ob.ink!==0)inks+=`<path d="${contourInk(ob.sil,io,F,Ld)}" fill="${io.col||scn.inkc}"/>`;
    let li="";for(const ln of (ob.lines||[]))li+=openInk(ln.d,Object.assign({w:scn.lineW??1},ln),F,ln.noM?null:ob.m);
    for(const e of (ob.edges||[])){const part=ob.P[e[0]];const beh=U(e[1].map(k=>ob.P[k].clone()));li+=edgeIn(part,beh,Object.assign({w:scn.lineW??1},e[2]||{}),F);}
    if(ob.flicks){const q=rng(ob.flickSeed??(SEED++));const cand=[];for(const c of kids(ob.sil)){const L=c.length;for(let i=0;i<L;i+=2.5){const p=c.getPointAt(i),t=c.getTangentAt(i);if(!p)continue;let nn=new PP.Point(-t.y,t.x);if(ob.sil.contains(p.add(nn.multiply(.5))))nn=nn.multiply(-1);
        if(nn.x*Ld[0]+nn.y*Ld[1]>(ob.flickDot??.35)&&!inside(F,p)&&!inside(F,p.add(nn.multiply(2))))cand.push([p,nn,t]);}}
      for(let i=0;i<ob.flicks&&cand.length;i++){const [p,nn,t]=cand[Math.floor(q()*cand.length)];const len=3+q()*3.5,sg=q()<.5?1:-1;
        const a=p.subtract(nn.multiply(1.2)),b=p.add(nn.multiply(len*.75)).add(t.multiply(sg*len*.6));const pth=new PP.Path([a,a.add(b).divide(2).add(t.multiply(sg*.6)),b]);pth.smooth();
        li+=openInk(pth,{w:ob.flickW??1.1,w0:1,w1:.2,tap0:.8,tap1:3,fl0:.5,noOcc:true},null);}}
    if(li)inks+=`<path d="${li}" fill="${scn.inkc2||scn.inkc}"/>`;
    if(ob.top)tops+=ob.top;
    for(const db of (ob.dabs||[])){const p=ob.m&&!db.world?ob.m.transform(new PP.Point(db.x,db.y)):new PP.Point(db.x,db.y);if(!inside(F,p))tops+=db.svg.replace(/@X/g,r2(p.x)).replace(/@Y/g,r2(p.y));}}
  return {washes,inks,tops};}
function kidsArea(it){return kids(it).reduce((s,c)=>s+Math.abs(c.area),0);}
function gapEdge(vis,Ld,seed,n,R){const q=rng(seed);const cand=[];for(const c of kids(vis)){const L=c.length;for(let i=0;i<L;i+=3){const p=c.getPointAt(i),t=c.getTangentAt(i);if(!p)continue;let nn=new PP.Point(-t.y,t.x);if(vis.contains(p.add(nn.multiply(.5))))nn=nn.multiply(-1);if(nn.x*Ld[0]+nn.y*Ld[1]<-.55)cand.push([p,nn]);}}
  if(!cand.length)return null;let it=null;for(let i=0;i<n;i++){const [p,nn]=cand[Math.floor(q()*cand.length)];const rr=R*(.6+q()*.8);const cx=p.x-nn.x*rr*.5,cy=p.y-nn.y*rr*.5;const b=S(blobD(cx,cy,rr,seed+i*3,8,.4,.55+q()*.5));it=it?it.unite(b):b;}return it;}
function gapBlobs(bd,seed,n,R){const q=rng(seed);let it=null;for(let i=0;i<n;i++){const cx=bd.x+q()*bd.width,cy=bd.y+q()*bd.height;const b=S(blobD(cx,cy,R*(.5+q()),seed+i,8,.35,.6+q()*.6));it=it?it.unite(b):b;}return it;}

const DEFS=`<defs>
 <filter id="wash" x="-12%" y="-12%" width="124%" height="124%" color-interpolation-filters="sRGB">
  <feTurbulence type="fractalNoise" baseFrequency=".035" numOctaves="3" seed="7" result="n"/>
  <feDisplacementMap in="SourceGraphic" in2="n" scale="6.5" xChannelSelector="R" yChannelSelector="G" result="d"/>
  <feGaussianBlur in="d" stdDeviation=".6" result="b"/>
  <feTurbulence type="fractalNoise" baseFrequency=".045" numOctaves="4" seed="31" result="c"/>
  <feColorMatrix in="c" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  1.5 0 0 0 -.05" result="ca"/>
  <feTurbulence type="fractalNoise" baseFrequency=".7" numOctaves="2" seed="2" result="g"/>
  <feColorMatrix in="g" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  .45 0 0 0 .7" result="ga"/>
  <feComposite in="ca" in2="ga" operator="arithmetic" k1="1" result="m"/>
  <feComposite in="b" in2="m" operator="in" result="grain"/>
  <feMorphology in="b" operator="erode" radius="1.1" result="er"/>
  <feComposite in="b" in2="er" operator="out" result="edge"/>
  <feColorMatrix in="edge" type="matrix" values=".62 0 0 0 0  0 .55 0 0 0  0 0 .6 0 0  0 0 0 .6 0" result="edge2"/>
  <feMerge><feMergeNode in="grain"/><feMergeNode in="edge2"/></feMerge>
 </filter>
 <filter id="washBg" x="-10%" y="-10%" width="120%" height="120%" color-interpolation-filters="sRGB">
  <feTurbulence type="fractalNoise" baseFrequency=".022" numOctaves="3" seed="4" result="n"/>
  <feDisplacementMap in="SourceGraphic" in2="n" scale="16" xChannelSelector="R" yChannelSelector="G" result="d"/>
  <feGaussianBlur in="d" stdDeviation="1.2" result="b"/>
  <feTurbulence type="fractalNoise" baseFrequency=".75" numOctaves="2" seed="12" result="g"/>
  <feColorMatrix in="g" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  .9 0 0 0 .3" result="ga"/>
  <feComposite in="b" in2="ga" operator="in" result="grain"/>
  <feMorphology in="b" operator="erode" radius="1.6" result="er"/>
  <feComposite in="b" in2="er" operator="out" result="edge"/>
  <feColorMatrix in="edge" type="matrix" values=".7 0 0 0 0  0 .62 0 0 0  0 0 .66 0 0  0 0 0 .8 0" result="edge2"/>
  <feMerge><feMergeNode in="grain"/><feMergeNode in="edge2"/></feMerge>
 </filter>
 <filter id="inkw" x="-4%" y="-4%" width="108%" height="108%"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="1" seed="5" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale=".9"/></filter>
 <filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="4"/></filter>
 <filter id="paperGrain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency=".65" numOctaves="3" seed="21"/><feColorMatrix type="matrix" values="0 0 0 0 .32  0 0 0 0 .22  0 0 0 0 .12  0 0 0 -1.3 .74"/></filter>
</defs>`;
const PAPER="#fbf6ea";
function compose(bg,res,fx){
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="11 11 278 239" width="556" height="478">${DEFS}
<rect x="0" y="0" width="300" height="420" fill="${PAPER}"/>
<g id="bg">${bg}</g>
<g id="wash">${res.washes}</g>
<g id="ink" filter="url(#inkw)">${res.inks}</g>
<g id="top">${res.tops}${fx||""}</g>
<rect x="0" y="0" width="300" height="420" filter="url(#paperGrain)" opacity=".2" style="mix-blend-mode:multiply"/>
</svg>`;}
