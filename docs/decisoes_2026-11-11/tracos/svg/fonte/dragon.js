"use strict";
/* DRAGÃO ANCIÃO (elder_dragon) — mesma pose de cartas_v2 (artDragon), silhuetas unidas */
function wingParts(S_,E,W,F,body,side){const [a,b,c,d]=F,cx=(p,q,t)=>[p[0]+(W[0]-p[0])*t+(q[0]-p[0])*.5,p[1]+(W[1]-p[1])*t+(q[1]-p[1])*.5];
  const q1=cx(a,b,.38),q2=cx(b,c,.36),q3=cx(c,d,.34),q4=cx(d,body,.3);
  const mem=`M${S_[0]} ${S_[1]} L${E[0]} ${E[1]} L${W[0]} ${W[1]} L${a[0]} ${a[1]} Q${q1[0]} ${q1[1]} ${b[0]} ${b[1]} Q${q2[0]} ${q2[1]} ${c[0]} ${c[1]} Q${q3[0]} ${q3[1]} ${d[0]} ${d[1]} Q${q4[0]} ${q4[1]} ${body[0]} ${body[1]} Z`;
  const arm=brushD(`M${S_[0]} ${S_[1]} L${E[0]} ${E[1]} L${W[0]} ${W[1]}`,20,9);
  const claw=`M${W[0]} ${W[1]} q${side*-4} -10 ${side*2} -16 q${side*-1} 8 ${side*4} 12Z`;
  const fingers=[],strips=[];
  F.forEach((f,i)=>{const mx=(W[0]+f[0])/2+(side*(i-1.5)*4),my=(W[1]+f[1])/2;const dd=`M${W[0]} ${W[1]} Q${mx} ${my} ${f[0]} ${f[1]}`;fingers.push(dd);strips.push(brushD(dd,7,1.5));});
  return {mem,arm,claw,fingers,strips};}
function sceneDragon(){
  SEED=11;const r=rng(131);
  const scn={L:[.45,.85],kmul:1.1,inkc:"#3e2214",inkc2:"#4e2c1a",lineW:1,ink:{w:1.75,a:.56,b:.6,min:.3},objs:[]};
  const O=scn.objs;
  const DM=mat().translate(150,150).rotate(-7,new PP.Point(0,0)).scale(1.12).translate(-150,-146);
  let bg=`<defs>
   <linearGradient id="dsky" x1="0" y1="0" x2="0" y2="300" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#a8506a"/><stop offset=".45" stop-color="#e2905a"/><stop offset=".8" stop-color="#f4c070"/><stop offset="1" stop-color="#f4c070" stop-opacity="0"/></linearGradient>
   <radialGradient id="wgL" cx="38" cy="58" r="200" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#6a2232"/><stop offset=".5" stop-color="#a03c3c"/><stop offset="1" stop-color="#e09a70"/></radialGradient>
   <radialGradient id="wgR" cx="266" cy="50" r="200" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#6a2232"/><stop offset=".5" stop-color="#a03c3c"/><stop offset="1" stop-color="#e09a70"/></radialGradient>
   <radialGradient id="mouthG" cx="152" cy="132" r="26" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fff4c0"/><stop offset=".4" stop-color="#ffcc3a"/><stop offset=".85" stop-color="#f06a1a"/><stop offset="1" stop-color="#b02a10"/></radialGradient>
  </defs>`;
  const pl=(d,c,op,f="washBg")=>`<path d="${d}" fill="${c}" opacity="${op}" filter="url(#${f})"/>`;
  // céu em aguada, lua deixada em papel
  const moon="M150 8 C204 8 248 52 248 106 C248 160 204 204 150 204 C96 204 52 160 52 106 C52 52 96 8 150 8 Z";
  const skyHole=S("M-20 -20 H320 V320 H-20Z").subtract(S(moon));
  bg+=pl(dOf(skyHole),"url(#dsky)",.42);
  bg+=pl(moon,"#fbe9b8",.55)+pl(blobD(110,96,8,3,7,.3),"#e8c890",.5)+pl(blobD(180,120,12,4,7,.3),"#e8c890",.45)+pl(blobD(160,64,6,5,7,.3),"#e8c890",.4);
  for(let i=0;i<5;i++){const y=150+i*26;bg+=pl(`M-30 ${y} Q80 ${y-14} 150 ${y+4} T330 ${y-6} L330 ${y+8} Q220 ${y+16} 150 ${y+14} T-30 ${y+12}Z`,i%2?"#c06a4a":"#e8945a",.22);}
  bg+=pl("M-20 228 C60 222 120 236 180 230 C230 226 280 232 320 228 L320 300 L-20 300Z","#7a3a2a",.4);
  bg+=`<path d="${dOf(S(moon))}" fill="none" stroke="#c88a40" stroke-width="1.6" opacity=".5" filter="url(#washBg)"/>`;
  // ---------- asas ----------
  const wing=(S_,E,W,F,body,side,gid)=>{const w=wingParts(S_,E,W,F,body,side);
    return {id:"wing"+side,m:DM,parts:{mem:w.mem,arm:w.arm,claw:w.claw},tol:1.2,fill:`url(#${gid})`,shade:"#4a0e0a",deep:"#3a0806",k:12,op:.8,shOp:.6,gapN:7,ink:{w:1.8,corner:48},
      patches:w.strips.map(s=>({d:s,col:"#6a1810",op:.55,free:true})).concat([{part:"arm",col:"#8a2418",op:.7},{part:"claw",col:"#f2e2c0",op:1}]),
      lines:w.fingers.map((f,i)=>({d:f,w:2.1,w0:1.2,w1:.22,ext1:1.6})),
      edges:[["arm",["mem"],{w:1.1}]]};};
  O.push(wing([118,170],[74,120],[38,58],[[-8,10],[-16,96],[4,178],[60,226]],[112,228],-1,"wgL"));
  O.push(wing([182,170],[228,116],[266,50],[[314,4],[320,92],[300,180],[244,228]],[188,228],1,"wgR"));
  // ---------- corpo + cauda ----------
  const tl="M172 268 C212 296 254 300 268 330 C282 360 246 384 206 374 C186 368 176 380 170 398";
  let sp="";{const pth=S(tl);const Lt=pth.length;for(let i=1;i<8;i++){const t=i/9,p=pth.getPointAt(Lt*t),tg=pth.getTangentAt(Lt*t);const nx=tg.y,ny=-tg.x,w=(26-23*Math.pow(t,.7))/2;
    sp+=`M${r2(p.x+nx*w-tg.x*4)} ${r2(p.y+ny*w-tg.y*4)} L${r2(p.x+nx*(w+9-6*t))} ${r2(p.y+ny*(w+9-6*t))} L${r2(p.x+nx*w+tg.x*4)} ${r2(p.y+ny*w+tg.y*4)} Z`;}}
  const D={
   legL:"M124 246 C110 262 104 282 108 300 C110 310 122 312 126 302 C128 286 134 270 144 258 Z",
   legR:"M178 256 C190 268 196 286 194 302 C192 312 180 314 177 304 C176 288 172 274 164 262 Z",
   body:"M104 174 C94 208 104 248 124 274 C140 292 166 292 182 274 C202 248 212 208 200 174 C180 156 124 156 104 174 Z",
   plates:"M136 168 C130 200 133 240 145 272 L160 272 C171 240 173 200 167 168 Z",
   neck:"M128 172 C120 150 128 126 138 108 L166 108 C176 126 184 150 176 172 Z",
   neckP:"M143 168 C139 148 141 128 146 110 L160 110 C164 128 165 148 162 168 Z",
   armL:"M122 186 C106 200 96 220 92 240 C90 250 100 256 106 248 C112 232 122 218 136 206 Z",
   armR:"M182 186 C198 200 208 220 212 240 C214 250 204 256 198 248 C192 232 182 218 168 206 Z"};
  const tal=(x,y,dx,dy)=>brushD(`M${x} ${y} q${dx*.6} ${dy*.2} ${dx} ${dy}`,3.6,.3);
  const tals=tal(94,246,-10,10)+tal(98,250,-6,14)+tal(104,251,0,14)+tal(108,248,6,11)+tal(210,246,10,10)+tal(206,250,6,14)+tal(200,251,0,14)+tal(196,248,-6,11);
  let pl1="";for(let i=1;i<9;i+=1){const y=176+i*11;pl1+=`M${136+i*.6+1} ${y} Q152 ${y+5} ${167-i*.3-1} ${y}`;}
  let np="";for(let i=1;i<6;i++){const y=114+i*9;np+=`M${146-i*.4+.8} ${y} Q153 ${y+4} ${160+i*.4-.8} ${y}`;}
  O.push({id:"body",m:DM,parts:{tail:brushD(tl,26,3,{pow:.7}),spikes:sp,legL:D.legL,legR:D.legR,body:D.body,neck:D.neck,armL:D.armL,armR:D.armR,tals},
    fill:"#b8442c",shade:"#4a0e0a",deep:"#360806",k:13,op:.85,shOp:.7,gapN:6,ink:{w:2},
    patches:[{d:D.plates,col:"#e8b45a",op:.85},{d:D.neckP,col:"#e8b45a",op:.85},{part:"spikes",col:"#e0a850",op:.85},{part:"tals",col:"#f4e6c8",op:1},{part:"armL",col:"#c85a3a",op:.5},{part:"armR",col:"#c85a3a",op:.5}],
    edges:[["body",["legL","legR","tail"],{w:1}],["neck",["body"],{w:.9,keep:.28}],["armL",["body"],{w:1,keep:.4}],["armR",["body"],{w:1.1,keep:.45}],["spikes",["tail"],{w:.6}],["tals",["armL","armR"],{w:.5}]],
    lines:[{d:"M136 169 C130 200 133 240 145 271",w:.85,w0:.6,w1:1},{d:"M167 169 C173 200 171 240 160 271",w:1,w0:.6,w1:1},{d:pl1,w:.5,w0:.7,w1:.7},
      {d:"M143 166 C139 148 141 128 146 111",w:.7},{d:"M162 166 C165 148 164 128 160 111",w:.8},{d:np,w:.45,w0:.7,w1:.7},
      {d:"M188 200 q3 3 6 0 M192 214 q3 3 6 0 M186 228 q3 3 6 0 M178 246 q3 3 6 0 M190 244 q3 3 6 0",w:.55,w0:1,w1:.4}]});
  // ---------- cabeça ----------
  const fr=[[131,78,112,50],[130,86,108,66],[132,94,112,84],[173,78,192,50],[174,86,196,66],[172,94,192,84]].map(q=>brushD(`M${q[0]} ${q[1]} Q${q[0]-(q[0]-q[2])*.2} ${(q[1]+q[3])/2} ${q[2]} ${q[3]}`,11,.6)).join("");
  const H={hornL:"M138 54 C118 40 104 18 110 -8 C116 14 130 30 150 44 Z",hornR:"M166 54 C186 40 200 18 194 -8 C188 14 174 30 154 44 Z",frills:fr,
    skull:"M128 78 C124 60 136 44 152 40 C168 44 180 60 176 78 C174 86 170 92 166 97 L138 97 C134 92 130 86 128 78 Z",
    jaw:"M134 120 C128 142 136 170 152 177 C168 170 176 142 170 120 C168 144 162 162 152 168 C142 162 136 144 134 120 Z",
    mouth:"M136 116 C142 120 148 121 152 121 C156 121 162 120 168 116 C172 138 166 160 152 166 C138 160 132 138 136 116 Z",
    snout:"M133 90 C133 104 139 117 152 121 C165 117 171 104 171 90 C164 94 158 96 152 96 C146 96 140 94 133 90 Z"};
  let teeth="";const tp=[];[[139,118,8],[144,120,12],[148,121,7],[156,121,7],[160,120,12],[165,118,8]].forEach(t=>tp.push(`M${t[0]-2} ${t[1]} L${t[0]} ${t[1]+t[2]} L${t[0]+2} ${t[1]}Z`));
  [[140,152,-8],[145,160,-11],[159,160,-11],[164,152,-8]].forEach(t=>tp.push(`M${t[0]-2} ${t[1]} L${t[0]} ${t[1]+t[2]} L${t[0]+2} ${t[1]}Z`));
  const tw=dOf(S(tp.join("")).transform(DM));
  O.push({id:"head",m:DM,parts:H,tol:.8,fill:"#b03c26",shade:"#4a0e0a",deep:"#360806",k:9,op:.85,shOp:.7,gapN:4,ink:{w:1.9,corner:46},
    patches:[{part:"hornL",col:"#f0e2c4",op:.95},{part:"hornR",col:"#f0e2c4",op:.95},{part:"mouth",col:"url(#mouthG)",op:1},{part:"snout",col:"#cc5a36",op:.7},{part:"frills",col:"#7a2016",op:.6},
      {d:"M124 69 L150 76 L148 83 L127 77 Z M180 69 L154 76 L156 83 L177 77 Z",col:"#5a140e",op:.75},
      {d:"M130 79 L146 84 L144 88 L132 84 Z M174 79 L158 84 L160 88 L172 84 Z",col:"#ffd23a",op:1,organic:false},
      {d:"M143 104 C142 100 147 100 147 104 Z M161 104 C162 100 157 100 157 104 Z",col:"#2a0806",op:.9,organic:false}],
    edges:[["snout",["skull","mouth","jaw"],{w:1.1}],["mouth",["jaw"],{w:.9}],["hornL",["skull"],{w:.9}],["hornR",["skull"],{w:.9}],["frills",["skull"],{w:.6}]],
    lines:[{d:"M127 77 L148 83",w:1.6,w0:1,w1:.6},{d:"M177 77 L156 83",w:1.6,w0:1,w1:.6},{d:"M139 81.5 L138.6 86.5 M165 81.5 L165.4 86.5",w:1.2,w0:1,w1:1,tap0:.8,tap1:.8},
      {d:"M124 28 l7 -2 M116 14 l7 -1 M180 28 l-7 -2 M188 14 l-7 -1",w:.6,w0:1,w1:.3},{d:"M146 48 C148 56 150 64 150 72",w:.55},{d:"M158 48 C156 56 154 64 154 72",w:.55}],
    top:`<path d="${tw}" fill="#fbf2dc" stroke="#3e2214" stroke-width=".55" stroke-linejoin="round"/>`});
  const res=buildScene(scn);
  // fumaça das narinas (traço fino) e chuva de brasas
  let fx=`<g filter="url(#inkw)"><path d="${openInk(spiral(132,90,8,1.2,3,-1),{w:.8,w0:1,w1:.3,noOcc:true},null,DM)+openInk(spiral(172,90,8,1.2,0,1),{w:.8,w0:1,w1:.3,noOcc:true},null,DM)}" fill="#8a6a5a" opacity=".8"/></g>`;
  let emb="";for(let i=0;i<40;i++){const x=r()*320-10,y=r()*260,l=5+r()*9;emb+=wedge(x,y,x+l*.38,y-l,1+r()*1.4);}
  fx+=`<path d="${emb}" fill="#e8742a" opacity=".75" filter="url(#washBg)"/>`;
  return compose(bg,res,fx);}
