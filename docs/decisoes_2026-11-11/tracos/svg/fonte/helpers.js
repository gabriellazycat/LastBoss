"use strict";
const NS="http://www.w3.org/2000/svg";
const f1=n=>(Math.round(n*10)/10);
let UID=0,SEED=11,CUR=null,SCN=null;
function rng(seed){let s=(Math.imul(seed|0,2654435761)>>>0)||1;return()=>{s^=s<<13;s>>>=0;s^=s>>>17;s^=s<<5;s>>>=0;return s/4294967296;};}
function noise1(seed){const r=rng(seed),t=Array.from({length:97},r);return x=>{const i=Math.floor(x),f=x-i,a=t[((i%97)+97)%97],b=t[(((i+1)%97)+97)%97],u=(1-Math.cos(f*Math.PI))/2;return a+(b-a)*u;};}
function hx(c){c=c.replace("#","");if(c.length===3)c=c.split("").map(x=>x+x).join("");return [0,2,4].map(i=>parseInt(c.substr(i,2),16));}
function mix(a,b,t){const A=hx(a),B=hx(b);return "#"+A.map((v,i)=>Math.max(0,Math.min(255,Math.round(v+(B[i]-v)*t))).toString(16).padStart(2,"0")).join("");}
function rotV(v,deg){const a=deg*Math.PI/180,c=Math.cos(a),s=Math.sin(a);return [v[0]*c-v[1]*s,v[0]*s+v[1]*c];}
function nrm(v){const l=Math.hypot(v[0],v[1])||1;return [v[0]/l,v[1]/l];}
const MSVG=document.createElementNS(NS,"svg");MSVG.setAttribute("style","position:absolute;width:0;height:0;overflow:hidden");document.body.appendChild(MSVG);
const MPATH=document.createElementNS(NS,"path");MSVG.appendChild(MPATH);
function subpaths(d){return d.trim().split(/(?=M)/).filter(s=>s.trim().length>1);}
function sample(d,step){MPATH.setAttribute("d",d);const L=MPATH.getTotalLength();const n=Math.max(6,Math.ceil(L/step));const pts=[];
  for(let i=0;i<=n;i++){const p=MPATH.getPointAtLength(L*i/n);pts.push([p.x,p.y]);}
  const closed=/z\s*$/i.test(d.trim());if(closed)pts.pop();return {pts,L,closed};}
function frames(pts,closed){const n=pts.length,T=[],N=[];
  for(let i=0;i<n;i++){const a=pts[closed?(i-1+n)%n:Math.max(0,i-1)],b=pts[closed?(i+1)%n:Math.min(n-1,i+1)];
    let tx=b[0]-a[0],ty=b[1]-a[1];const l=Math.hypot(tx,ty)||1;tx/=l;ty/=l;T.push([tx,ty]);N.push([-ty,tx]);}
  let sg=1;if(closed){let A=0;for(let i=0;i<n;i++){const p=pts[i],q=pts[(i+1)%n];A+=p[0]*q[1]-q[0]*p[1];}sg=A>0?-1:1;}
  return {T,N:N.map(v=>[v[0]*sg,v[1]*sg])};}
function ribbonP(P,N,W){const A=[],B=[];for(let i=0;i<P.length;i++){const w=W[i]/2;A.push(f1(P[i][0]+N[i][0]*w)+" "+f1(P[i][1]+N[i][1]*w));B.push(f1(P[i][0]-N[i][0]*w)+" "+f1(P[i][1]-N[i][1]*w));}
  return "M"+A.join("L")+"L"+B.reverse().join("L")+"Z";}
function brushD(d,w0,w1,o={}){let out="";for(const sp of subpaths(d)){const {pts}=sample(sp,o.step??1.5);const {N}=frames(pts,false);const n=pts.length,nz=noise1(o.seed??(SEED++));
  const W=pts.map((p,i)=>{const u=i/(n-1);let w=w0+(w1-w0)*Math.pow(u,o.pow??1);if(o.t0)w*=Math.min(1,i/(o.t0/1.5));if(o.wob)w*=1-o.wob/2+o.wob*nz(i*.08);return Math.max(.05,w);});
  out+=ribbonP(pts,N,W);}return out;}
function wedge(x1,y1,x2,y2,w){const dx=x2-x1,dy=y2-y1,l=Math.hypot(dx,dy)||1,nx=-dy/l,ny=dx/l;return `M${f1(x1+nx*w/2)} ${f1(y1+ny*w/2)}L${f1(x2)} ${f1(y2)}L${f1(x1-nx*w/2)} ${f1(y1-ny*w/2)}Z`;}
function splat(cx,cy,R,n,col,seed,sz=1.6,op=.8){const r=rng(seed);let s="";for(let i=0;i<n;i++){const a=r()*6.283,dd=Math.pow(r(),.7)*R,rr=sz*(.25+r()*r()*2.4);s+=`<circle cx="${f1(cx+Math.cos(a)*dd)}" cy="${f1(cy+Math.sin(a)*dd)}" r="${f1(rr)}"/>`;}return `<g fill="${col}" opacity="${op}">${s}</g>`;}
function crClosed(P){const n=P.length;let d=`M${f1(P[0][0])} ${f1(P[0][1])}`;for(let i=0;i<n;i++){const p0=P[(i-1+n)%n],p1=P[i],p2=P[(i+1)%n],p3=P[(i+2)%n];
  d+=`C${f1(p1[0]+(p2[0]-p0[0])/6)} ${f1(p1[1]+(p2[1]-p0[1])/6)} ${f1(p2[0]-(p3[0]-p1[0])/6)} ${f1(p2[1]-(p3[1]-p1[1])/6)} ${f1(p2[0])} ${f1(p2[1])}`;}return d+"Z";}
function crOpen(P){let d=`M${f1(P[0][0])} ${f1(P[0][1])}`;for(let i=0;i<P.length-1;i++){const p0=P[Math.max(0,i-1)],p1=P[i],p2=P[i+1],p3=P[Math.min(P.length-1,i+2)];
  d+=`C${f1(p1[0]+(p2[0]-p0[0])/6)} ${f1(p1[1]+(p2[1]-p0[1])/6)} ${f1(p2[0]-(p3[0]-p1[0])/6)} ${f1(p2[1]-(p3[1]-p1[1])/6)} ${f1(p2[0])} ${f1(p2[1])}`;}return d;}
function blobD(cx,cy,r,seed,n=9,j=.22,sy=1){const q=rng(seed),P=[];for(let i=0;i<n;i++){const a=i/n*6.283+q()*.3,rr=r*(1-j+q()*2*j);P.push([cx+Math.cos(a)*rr,cy+Math.sin(a)*rr*sy]);}return crClosed(P);}
function spiral(cx,cy,r,turns,a0=0,dir=1){const P=[];const n=Math.round(turns*14);for(let i=0;i<=n;i++){const u=i/n,a=a0+dir*u*turns*6.283,rr=r*(1-u*.85);P.push([cx+Math.cos(a)*rr,cy+Math.sin(a)*rr]);}return crOpen(P);}
function boneD(len,w){const r=w*.5,hw=w/2,l=len;
  return `M${f1(r*1.6)} ${f1(-hw*.55)} Q${f1(l/2)} ${f1(-hw*.2)} ${f1(l-r*1.6)} ${f1(-hw*.55)} C${f1(l-r*1.2)} ${f1(-r*2.4)} ${f1(l+r*1.1)} ${f1(-r*2.3)} ${f1(l+r*.5)} 0 C${f1(l+r*1.1)} ${f1(r*2.3)} ${f1(l-r*1.2)} ${f1(r*2.4)} ${f1(l-r*1.6)} ${f1(hw*.55)} Q${f1(l/2)} ${f1(hw*.2)} ${f1(r*1.6)} ${f1(hw*.55)} C${f1(r*1.2)} ${f1(r*2.4)} ${f1(-r*1.1)} ${f1(r*2.3)} ${f1(-r*.5)} 0 C${f1(-r*1.1)} ${f1(-r*2.3)} ${f1(r*1.2)} ${f1(-r*2.4)} ${f1(r*1.6)} ${f1(-hw*.55)} Z`;}
