"use strict";
/* REI DOS RATOS — mesma pose e composição de cartas_v2 (artKing), redesenhado com silhuetas unidas */
const circ=(cx,cy,r,ry)=>{ry=ry??r;return `M${cx-r} ${cy} A${r} ${ry} 0 1 0 ${cx+r} ${cy} A${r} ${ry} 0 1 0 ${cx-r} ${cy}Z`;};
const RAT_A={
 tail:"M12 40 C-16 30 -40 48 -62 39 C-76 33 -88 37 -98 46",
 back:"M24 50 C14 58 4 62 -8 64 C-13 65 -13 69 -8 69 C6 69 18 64 32 56 Z",
 body:"M10 42 C5 24 28 11 54 13 C74 14 88 19 98 27 C106 31 116 35 127 42 C119 48 108 50 100 50 C90 56 72 60 54 58 C34 58 13 56 10 42 Z",
 belly:"M30 54 C46 60 70 58 88 52 C80 58 64 61 48 60 C40 59 34 57 30 54 Z",
 front:"M90 47 C98 54 108 60 118 62 C123 63 124 67 119 68 C108 68 96 64 84 55 Z",
 ear:"M85 24 C81 12 92 4 100 11 C105 17 101 27 92 28 Z",
 earIn:"M88 22 C86 15 92 10 97 14 C99 19 96 24 91 24 Z",eye:[106,33]};
const RAT_B=Object.assign({},RAT_A,{
 tail:"M14 36 C-10 20 -32 32 -52 22 C-66 15 -78 19 -88 28",
 back:"M30 50 C40 58 52 62 62 64 C67 65 67 69 62 69 C48 69 36 64 24 58 Z",
 body:"M12 40 C8 19 30 7 56 11 C76 13 90 19 100 27 C108 31 117 35 127 42 C119 48 108 50 100 50 C92 56 74 58 56 56 C36 56 15 54 12 40 Z",
 front:"M94 47 C90 56 84 62 76 66 C71 68 69 64 73 62 C78 58 82 54 86 47 Z"});
function ratObj(x,y,sc,flip,rot,pose,big){const R=pose?RAT_B:RAT_A;
  const m=mat().translate(x,y).rotate(rot,new PP.Point(0,0)).scale(sc*flip,sc).translate(-60,-66);
  const e=m.transform(new PP.Point(R.eye[0],R.eye[1]));
  return {id:"rat",m,parts:{tail:brushD(R.tail,7,1.4),back:R.back,body:R.body,front:R.front,ear:R.ear},
    fill:"#9a8676",shade:"#4a3448",k:6,op:.8,patches:[{d:R.belly,col:"#dccab0",op:.7},{part:"tail",col:"#cfa498",op:.75},{d:R.earIn,col:"#e3a296",op:.8}],
    ink:{w:1.25},edges:[["ear",["body"],{w:.7}],["front",["body"],{w:.7}],["back",["body"],{w:.6}]],
    lines:big?[{d:"M125 42 C132 39 138 36 146 34",w:.5,w0:1,w1:.2},{d:"M125 44 C132 45 138 47 145 51",w:.5,w0:1,w1:.2}]:[],
    dabs:[{x:e.x,y:e.y,world:true,svg:`<circle cx="@X" cy="@Y" r="${r2(1.5*sc*2.2)}" fill="#e8a020"/><circle cx="@X" cy="@Y" r="${r2(.7*sc*2.2)}" fill="#3a1e10"/>`}]};}
function skullObj(x,y,s,rot,glow){const m=mat().translate(x,y).rotate(rot,new PP.Point(0,0)).scale(s);
  return {id:"skull",m,parts:{cr:"M-10 -1 C-11 -12 -5 -16 0 -16 C5 -16 11 -12 10 -1 C10 3 7 5 6 8 L-6 8 C-7 5 -10 3 -10 -1 Z",jaw:"M-6 8 L-5.5 12 L5.5 12 L6 8 Z"},
    fill:"#efe4c8",shade:"#a89070",k:3.5,op:.85,gapN:2,ink:{w:1.05,seg:80},
    patches:[{d:"M-7 -3 C-7 -6 -2 -6 -2 -2 C-2 1 -7 1 -7 -3 Z M7 -3 C7 -6 2 -6 2 -2 C2 1 7 1 7 -3 Z M0 2 L-1.6 5 L1.6 5 Z",col:"#3a2434",op:.85,organic:false}].concat(glow?[{d:"M-6 -3 C-6 -5 -3 -5 -3 -2.5 C-3 -.5 -6 -.5 -6 -3Z M6 -3 C6 -5 3 -5 3 -2.5 C3 -.5 6 -.5 6 -3Z",col:glow,op:.95,organic:false}]:[]),
    lines:[{d:"M-3 8.5 V11.5 M0 8.5 V12 M3 8.5 V11.5",w:.45,w0:1,w1:.4}]};}
function sceneKing(){
  SEED=11;const r=rng(77);
  const scn={L:[.5,.86],kmul:1.1,inkc:"#4a2c18",inkc2:"#5a3a22",lineW:1,ink:{w:1.75,a:.56,b:.6,min:.3},objs:[]};
  const O=scn.objs;
  // ---------- fundo (só aguada) ----------
  let bg="";
  const pl=(d,c,op,f="washBg")=>`<path d="${d}" fill="${c}" opacity="${op}" filter="url(#${f})"/>`;
  bg+=pl("M-20 -20 H320 V300 H-20Z","#e9dcc8",.35);
  bg+=pl(blobD(150,100,120,7,11,.18),"#f3d68c",.55)+pl(blobD(150,96,72,8,9,.2),"#f8e6a8",.6);
  bg+=pl("M-20 -20 L60 -20 C40 60 30 160 40 270 L-20 270Z","#a48ac0",.26)+pl("M320 -20 L240 -20 C262 60 272 160 262 270 L320 270Z","#a48ac0",.26);
  const gothic=(cx,w,top,bot)=>`M${cx-w} ${bot} L${cx-w} ${top+w*1.1} Q${cx-w} ${top+w*.2} ${cx} ${top} Q${cx+w} ${top+w*.2} ${cx+w} ${top+w*1.1} L${cx+w} ${bot}`;
  bg+=`<path d="${brushD(gothic(28,38,20,260),9,9)}" fill="#8a6aa8" opacity=".3" filter="url(#washBg)"/><path d="${brushD(gothic(272,38,20,260),9,9)}" fill="#8a6aa8" opacity=".3" filter="url(#washBg)"/>`;
  bg+=pl("M-20 250 Q150 232 320 250 L320 440 L-20 440Z","#6a4a66",.4);
  // ---------- leque de ossos e espadas ----------
  for(let i=0;i<15;i++){const deg=-170+i*11.3+(r()-.5)*5,a=deg*Math.PI/180,r0=36,len=118+r()*42;const x1=150+Math.cos(a)*r0,y1=214+Math.sin(a)*r0;
    const m=mat().translate(x1,y1).rotate(deg,new PP.Point(0,0));
    if(i%4===2){O.push({id:"sword",m,parts:{blade:`M0 -3.2 L${len-14} -3.2 L${len} 0 L${len-14} 3.2 L0 3.2 Z`,guard:"M-4 -10 L4 -10 L4 10 L-4 10 Z",grip:"M-22 -2.4 L-4 -2.4 L-4 2.4 L-22 2.4 Z"},
       fill:"#c2ccd4",shade:"#6c7a88",k:2.5,op:.8,gaps:0,patches:[{part:"guard",col:"#d8a440",op:.9},{part:"grip",col:"#7a4a2a",op:.85}],ink:{w:1,seg:200},
       lines:[{d:`M5 0 L${len-18} 0`,w:.45,w0:.6,w1:1}],edges:[["guard",["blade","grip"],{w:.6}]]});}
    else{const w=9+r()*5;O.push({id:"bone",m,parts:{b:boneD(len,w)},fill:"#f0e4c4",shade:"#b49c74",k:3,op:.8,gapN:2,ink:{w:1.05,seg:120,lost:.35}});}}
  // ---------- monte de sucata ----------
  O.push({id:"mound",parts:{m:"M-10 300 C10 262 46 242 86 238 C120 234 180 234 214 238 C250 244 284 262 310 300 L310 440 L-10 440 Z"},fill:"#7a5a74",shade:"#3e2848",k:12,op:.6,ink:{w:1.4,seg:90,lost:.45}});
  O.push({id:"wheel",parts:{w:"M18 210 C18 196 42 196 42 210 C42 224 18 224 18 210 Z M24 210 C24 216 36 216 36 210 C36 204 24 204 24 210 Z"},fill:"#9a6a40",shade:"#4a3020",k:3,ink:{w:1.1}});
  O.push({id:"crate1",parts:{f:"M8 236 L62 226 L70 270 L14 282 Z",t:"M8 236 L62 226 L76 216 L22 224 Z",s:"M62 226 L76 216 L82 258 L70 270 Z"},fill:"#b88450",shade:"#5a3a22",k:5,op:.8,
    patches:[{part:"t",col:"#dcae70",op:.75},{part:"s",col:"#6a4428",op:.75}],ink:{w:1.3,corner:40},lines:[{d:"M9 237 L62 227 L70 269",w:.75,w0:.9,w1:.7},{d:"M12 258 L66 248",w:.5},{d:"M30 231 L37 278",w:.45}]});
  O.push({id:"crate2",parts:{f:"M226 240 L282 232 L288 280 L230 288 Z",t:"M226 240 L282 232 L296 222 L240 228 Z"},fill:"#a87444",shade:"#5a3a22",k:5,op:.8,
    patches:[{part:"t",col:"#d8a86a",op:.75}],ink:{w:1.3,corner:40},lines:[{d:"M227 241 L282 233",w:.75},{d:"M228 263 L285 256",w:.5},{d:"M256 237 L260 285",w:.45}]});
  O.push({id:"shield",parts:{s:"M250 210 C270 206 292 216 294 236 C296 256 282 270 266 272 L258 250 L268 236 L252 228 Z"},fill:"#8a9cac",shade:"#3e4e5e",k:4,op:.8,ink:{w:1.2},patches:[{d:"M262 214 C278 216 288 226 288 240 L284 240 C283 228 276 220 262 218Z",col:"#d8a840",op:.85}]});
  const candle=(x,y,h)=>({id:"candle",parts:{c:`M${x-3.5} ${y} L${x+3.5} ${y} L${x+3.5} ${y-h} L${x-3.5} ${y-h} Z`},fill:"#f4ead0",shade:"#c0a880",k:2,ink:{w:.9,corner:40},gaps:0,
    top:`<path d="${blobD(x,y-h-7,9,x,8,.3)}" fill="#ffd870" opacity=".45" filter="url(#washBg)"/><path d="M${x} ${y-h-14} C${x+4} ${y-h-8} ${x+3} ${y-h-2} ${x} ${y-h-1} C${x-3} ${y-h-2} ${x-4} ${y-h-8} ${x} ${y-h-14} Z" fill="#ffc444" opacity=".9"/><path d="M${x} ${y-h-9} C${x+1.6} ${y-h-6} ${x+1.2} ${y-h-3} ${x} ${y-h-2} C${x-1.2} ${y-h-3} ${x-1.6} ${y-h-6} ${x} ${y-h-9}Z" fill="#fff4c8"/>`});
  O.push(candle(30,226,16),candle(44,224,10),candle(262,229,14));
  O.push(skullObj(66,262,1.25,-12),skullObj(112,254,1.05,8),skullObj(196,258,1.1,-6),skullObj(244,276,1.3,14,"#b070f0"),skullObj(160,282,1.4,4));
  for(let i=0;i<34;i++){const x=40+r()*220,y=244+r()*44,rr=3.2+r()*2.4,ro=(r()-.5)*40;if(i%2)continue;
    const m=mat().translate(x,y).rotate(ro,new PP.Point(0,0));
    O.push({id:"coin",m,parts:{c:circ(0,0,rr,rr*.5)},fill:"#e8b040",shade:"#a8701a",k:1.5,op:.9,gaps:0,ink:{w:.75,lost:.5,seg:60},noOrganic:true,
      patches:[{d:circ(-rr*.3,-rr*.15,rr*.35,rr*.12),col:"#fff4c8",op:.9,organic:false}]});}
  O.push(ratObj(34,282,.42,1,-24,1,1),ratObj(270,286,.44,-1,22,0,1),ratObj(92,318,.36,1,-30,1,0),ratObj(214,322,.34,-1,28,1,0),ratObj(20,346,.5,1,-18,0,1),ratObj(282,352,.48,-1,16,1,1));
  // ---------- o rei ----------
  const K={
   cape:"M78 112 C60 150 48 210 34 262 C60 274 100 280 150 280 C200 280 240 274 266 262 C252 210 240 150 222 112 C196 100 104 100 78 112 Z",
   hem:"M34 262 C60 274 100 280 150 280 C200 280 240 274 266 262 L268 270 C240 284 200 288 150 288 C100 288 60 284 32 270 Z",
   tail:"M184 246 C214 262 248 262 262 284 C270 300 256 318 274 330",
   body:"M108 128 C98 160 100 204 114 232 C132 250 170 250 188 232 C202 204 204 160 194 128 Z",
   belly:"M134 160 C128 186 132 214 142 228 C150 232 160 231 166 225 C174 210 176 184 170 160 C160 152 142 152 134 160 Z",
   footL:"M120 236 C112 244 102 252 106 259 C120 262 134 257 141 248 Z",
   footR:"M166 248 C172 258 186 263 199 259 C201 250 193 242 182 236 Z",
   armRu:"M192 130 C210 140 220 158 224 178 C226 186 218 190 212 184 C206 168 198 154 186 144 Z",
   armRf:"M212 178 C218 186 230 190 240 190 C247 192 247 198 240 200 C228 202 216 198 206 190 Z",
   armLu:"M110 132 C94 140 82 156 80 172 C80 182 92 184 96 176 C98 162 106 150 118 142 Z",
   armLf:"M82 176 C74 166 70 148 72 128 C74 120 84 120 86 128 C86 146 90 160 96 172 Z",
   paw:"M69 128 C67 118 76 112 84 114 C91 116 93 126 87 132 C80 135 71 134 69 128 Z",
   collar:"M84 120 C92 100 124 96 150 102 C176 96 210 100 218 120 C212 136 186 142 150 138 C116 142 90 136 84 120 Z",
   head:"M114 104 C110 80 126 62 152 60 C176 60 190 76 188 98 C186 112 178 122 166 126 C152 130 136 128 124 132 C110 136 96 139 89 133 C85 127 96 118 106 112 Z",
   jowl:"M95 125 C104 116 124 114 138 120 C140 128 126 133 112 135 C102 137 93 133 95 125 Z",
   earB:"M126 72 C114 54 118 36 134 38 C146 40 148 58 142 70 Z",
   earF:"M170 68 C172 47 190 39 201 51 C209 63 199 80 184 82 Z",
   nose:"M83 129 C84 124 92 123 94 128 C94 133 87 134 83 129 Z",
   tooth:"M97 134 L98 143 L102.5 142.5 L102 134 Z",
   crown:"M122 66 L117 34 L131 48 L139 21 L150 44 L161 16 L169 42 L183 29 L184 61 C166 57 142 59 122 66 Z"};
  O.push({id:"cape",parts:{cape:K.cape,hem:K.hem},fill:"#8a58c0",shade:"#2e1450",deep:"#24103e",k:16,op:.82,shOp:.55,gapN:6,ink:{w:1.9},
    patches:[{part:"hem",col:"#f6eee0",op:.95},{d:"M80 116 C66 150 56 200 46 250 L60 252 C68 200 78 150 92 116Z",col:"#b88ae0",op:.45}],
    lines:[{d:"M98 134 C90 180 80 230 70 268",w:1.1,w0:1,w1:.4},{d:"M204 134 C212 180 222 230 232 268",w:1.2,w0:1,w1:.4},{d:"M176 216 C180 240 184 262 186 278",w:.9,w0:.4,w1:1},
      {d:"M36 263 C62 274 100 280 150 280 C200 280 240 274 265 263",w:.8,w0:.8,w1:.9}]});
  O.push({id:"scepter",parts:{shaft:"M80 214 L84 213 L70 48 L66 49 Z",knob:"M74 222 C74 214 90 214 90 222 C90 230 74 230 74 222 Z",cage:"M56 46 C56 30 62 22 68 18 C74 22 80 30 80 46 C76 50 60 50 56 46 Z"},
    fill:"#f0e2c0",shade:"#b09870",k:2,op:.9,gaps:0,patches:[{part:"cage",col:"#dca440",op:.9}],ink:{w:1.25},edges:[["cage",["shaft"],{w:.6}]],
    top:`<path d="${blobD(68,36,15,3,8,.3)}" fill="#c890ff" opacity=".5" filter="url(#washBg)"/><path d="M68 24 L76 36 L68 47 L60 36 Z" fill="#a868e8" opacity=".9"/><path d="M68 26 L71 34 L68 36 L64 34Z" fill="#f0dcff"/>`,
    lines:[{d:"M68 24 L76 36 L68 47 L60 36 Z",w:.7,noM:true,noOcc:true,w0:1,w1:1}]});
  O.push(skullObj(234,214,1.5,6,"#f0b020"));
  O.push({id:"body",parts:{tail:brushD(K.tail,8,1.4),body:K.body,footL:K.footL,footR:K.footR,armRu:K.armRu,armRf:K.armRf,armLu:K.armLu,armLf:K.armLf,paw:K.paw},
    fill:"#98806a",shade:"#3c2a44",deep:"#2a1a30",k:13,op:.85,shOp:.72,flicks:9,gapN:6,ink:{w:2},
    patches:[{d:K.belly,col:"#dccaae",op:.75},{part:"footL",col:"#d8a094",op:.85},{part:"footR",col:"#d8a094",op:.85},{part:"paw",col:"#d8a094",op:.85},{part:"tail",col:"#caa094",op:.8}],
    edges:[["armRu",["body"],{w:1}],["armLu",["body"],{w:.9}],["armLf",["armLu"],{w:.9}],["armRf",["armRu"],{w:.9}],["paw",["armLf"],{w:.8}],["footL",["body"],{w:.8}],["footR",["body"],{w:.8}]],
    lines:[{d:"M135 164 C129 188 132 212 141 226",w:.6,w0:.3,w1:1},
      {d:"M107 257 l-6 4 M114 260 l-3 6 M122 259 l0 6 M196 258 l6 4 M190 261 l3 6 M182 261 l0 6",w:.9,w0:1,w1:.2},
      {d:"M240 190 l6 -2 M242 195 l7 1 M239 200 l6 4",w:.9,w0:1,w1:.2},{d:"M72 124 L83 122.5 M71 129 L85 128",w:.6,w0:.5,w1:1}]});
  let spots=[];const q=rng(5);for(let i=0;i<16;i++){const x=92+q()*120,y=108+q()*24+(Math.abs(x-150)<40?6:0);spots.push({x,y,world:true,svg:`<path d="M@X @Y q1.4 2.8 0 6 q-1.4 -2.8 0 -6Z" fill="#3a2418" opacity=".85"/>`});}
  O.push({id:"collar",parts:{c:K.collar},fill:"#f6f0e2",shade:"#b8a8c8",k:6,op:.9,gapN:3,ink:{w:1.6,lost:.4},dabs:spots});
  O.push({id:"brooch",parts:{b:"M142 132 C142 124 158 124 158 132 C158 140 142 140 142 132 Z"},fill:"#e0aa40",shade:"#9a6418",k:2,ink:{w:.9},gaps:0,dabs:[{x:150,y:132,world:true,svg:`<circle cx="@X" cy="@Y" r="3" fill="#d42a30"/><circle cx="149" cy="131" r="1" fill="#ffd0c0"/>`}]});
  O.push({id:"head",parts:{earB:K.earB,head:K.head,jowl:K.jowl,earF:K.earF,nose:K.nose,tooth:K.tooth},fill:"#a08a76",shade:"#3c2a44",deep:"#2a1a30",k:10,op:.85,shOp:.72,flicks:5,flickW:.9,gapN:5,ink:{w:2},
    patches:[{part:"jowl",col:"#e4d4bc",op:.8},{d:"M128 68 C120 56 122 44 132 44 C140 46 140 58 137 66 Z",col:"#e6a296",op:.85},{d:"M176 68 C178 54 190 48 196 56 C201 64 194 76 184 77 Z",col:"#e6a296",op:.85},
      {part:"nose",col:"#dc6c74",op:.9},{part:"tooth",col:"#fbf0d4",op:1},
      {d:"M118 94 C122 88 132 88 136 94 C130 96.5 122 97 118 94 Z M153 90 C158 84 169 84 173 90 C167 93 158 94 153 90 Z",col:"#f2b420",op:1,organic:false}],
    edges:[["earF",["head"],{w:1}],["jowl",["head"],{w:.7,margin:1.8}],["nose",["head","jowl"],{w:.7}],["tooth",["head","jowl"],{w:.5}]],
    lines:[{d:"M115 92 C121 85 132 85 138 91",w:1.7,w0:.5,w1:1,fl0:.1},{d:"M150 88 C156 81 169 81 175 88",w:1.7,w0:.5,w1:1},
      {d:"M118 94.5 C124 97 131 96.5 136 94",w:.5},{d:"M153 90.5 C159 93.5 166 93 173 90",w:.5},
      {d:"M126.5 89.5 L127.5 95 M162.5 86 L163.5 91.5",w:1.3,w0:1,w1:1,tap0:.8,tap1:.8},
      {d:"M112 84 C120 77 132 77 140 81",w:.7,w0:.3,w1:1},{d:"M149 78 C158 72 170 73 178 78",w:.7,w0:.3,w1:1},
      {d:"M104 140 C112 142 120 140 126 136",w:.9},{d:"M88 128.5 l1.6 .3",w:1.2,w0:1,w1:1},
      {d:"M97 128 C80 120 62 122 44 132",w:.55,w0:1,w1:.15,noOcc:true},{d:"M97 132 C80 134 64 142 52 155",w:.55,w0:1,w1:.15,noOcc:true},
      {d:"M164 70 C168 64 176 62 182 64",w:.6,w0:.2,w1:1}]});
  const cm=mat().translate(152,46).rotate(-8,new PP.Point(0,0)).translate(-152,-46);
  O.push({id:"crown",m:cm,parts:{c:K.crown,b1:circ(117,34,2.2),b2:circ(139,21,2.2),b3:circ(161,16,2.4),b4:circ(183,29,2.2)},tol:.5,amp:.2,fill:"#eab43c",shade:"#a86a18",k:4,op:.92,gapN:3,ink:{w:1.4,corner:45,over:2},
    patches:[{d:"M123 60 C142 54 166 52 184 55 L184 61 C166 57 142 59 122 66Z",col:"#c8841c",op:.7}],
    lines:[{d:"M123 59 C142 53 166 51 184 54",w:.8}],
    dabs:[{x:150,y:56,svg:`<circle cx="@X" cy="@Y" r="3" fill="#d42030"/>`},{x:134,y:59,svg:`<circle cx="@X" cy="@Y" r="2.3" fill="#8a40e0"/>`},{x:170,y:55,svg:`<circle cx="@X" cy="@Y" r="2.3" fill="#2aa0b0"/>`}]});
  const res=buildScene(scn);
  let fx="";const q2=rng(23);for(let i=0;i<14;i++){const a=q2()*6.283,d=70+q2()*60,x=150+Math.cos(a)*d,y=96+Math.sin(a)*d*.8;if(y>230)continue;fx+=`<path d="M${r2(x)} ${r2(y-3)} L${r2(x+.8)} ${r2(y)} L${r2(x)} ${r2(y+3)} L${r2(x-.8)} ${r2(y)}Z M${r2(x-3)} ${r2(y)} L${r2(x)} ${r2(y+.8)} L${r2(x+3)} ${r2(y)} L${r2(x)} ${r2(y-.8)}Z" fill="#c8902a" opacity=".8"/>`;}
  return compose(bg+fx,res,"");}
