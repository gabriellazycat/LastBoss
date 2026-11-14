# Modelo numérico do balanceamento (sem rodar o jogo).
# Base: medição bal_f (40 runs por célula) + participação de cada carta no dano por fase.
# Vitória do vilão: logit(p) = logit(p_F) + B*ln(V), V = dano efetivo relativo do vilão.
# B calibrado no único dado de alavanca medido: dano do herói x1,7 na F3 levou 75% -> 36%.
import json,collections,math,sys,copy
B_='C:/Users/gabri/Desktop/LastBoss/'
B=math.log(.75/.25)-math.log(.36/.64); B/=math.log(1.7)
cards={}
for f in ['cards','cards_common','cards_plague','cards_dragon','cards_lich']:
    for c in json.load(open(B_+'data/'+f+'.json',encoding='utf-8'))['cards']: cards[c['id']]=c
runs=json.load(open(B_+'reports/bal_f/runs.json',encoding='utf-8'))
WIN={('plague',1):.60,('plague',2):.48,('plague',3):.80,('plague',4):.28,
     ('dragon',1):.55,('dragon',2):.42,('dragon',3):.78,('dragon',4):.52,
     ('lich',1):.65,('lich',2):.72,('lich',3):.75,('lich',4):.65}
TGT={1:.60,2:.56,3:.52,4:.48}
share={}
for (v,p) in WIN:
    d=collections.Counter()
    for x in runs:
        if x['deck'].split('@')[0]==v and x['phase']==p:
            for k,val in x['dmg_by_card'].items():
                if k!='boss': d[k]+=val
    t=sum(d.values()); share[(v,p)]={k:val/t for k,val in d.items()}
# Grupo de heróis por fase: (classe, dano por golpe) por posição na fila. step 1,21.
CL={'escudeiro':(1,1),'arqueira':(.72,.8),'cleriga':(.9,.7),'mago':(.68,1.25)}
PARTY={1:['escudeiro']*7,2:['escudeiro','arqueira']*3+['escudeiro'],
       3:['cleriga','escudeiro','cleriga','arqueira','escudeiro','cleriga','escudeiro'],
       4:['escudeiro','arqueira','cleriga','mago','escudeiro','arqueira']}
def hits(p,h,dm=None):
    dm=dm or DMG[p]; out=[]
    for i,c in enumerate(PARTY[p]):
        d=46*CL[c][1]*dm*1.21**i
        if c=='mago': out.append((math.ceil(h/d)+math.ceil(h/(d*.5)))/2)
        else: out.append(math.ceil(h/d))
    return sum(out)/len(out)
def life_ratio(p,h_old,h_new,dm=None): return hits(p,h_new,dm)/hits(p,h_old,dm)
def party_dps(p,dm=None):
    dm=dm or DMG[p]; L=[46*CL[c][1]*dm*1.21**i/(.85 if c=='arqueira' else 1.5 if c=='mago' else 1) for i,c in enumerate(PARTY[p])]
    return sum(L) if p==4 else sum(L)/len(L)*1.15   # F4: grupo junto; 1,15 = golpe heroico/fúria em média
def big_life(p,hp,regen,dm=None):
    D=party_dps(p,dm); r=hp*regen
    return hp/max(D-r,D*.15)
DMG={1:1.0,2:1.0,3:1.0,4:1.0}   # estado da medição F

def factors(p,S):
    """fator de dano de cada carta na fase p para o estado S (dict de mudanças) vs. medição F."""
    f={}
    dm=S.get('dmg',{}).get(p,DMG[p])
    # 1) heróis: dano da fase muda o tempo de vida de tudo (V /= dm) -> aplicado fora
    # ratos: limiar de golpe + dps
    r_old=dict(rat_horde=(25,4),rabid_rats=(30,5),rat_tide=(22,4),rat=(25,4))
    for k,(h0,d0) in r_old.items():
        h1,d1=S['rats'][k]
        f[k]=life_ratio(p,h0,h1,dm)/life_ratio(p,h0,h0,dm)*(d1/d0)*S.get('spin',{}).get(k,1)
    # troll
    f['cave_troll']=big_life(p,*S['troll'],dm)/big_life(p,2200,.02,dm)
    # legião, kobolds
    f['bone_legion']=life_ratio(p,75,S['legion'],dm)*S.get('legion_dps',1)
    f['kobold_scavengers']=life_ratio(p,35,S['kobold'],dm)
    f['goblin_dynamiter']=S.get('dyn',1)
    for k,v in S.get('flat',{}).items(): f[k]=f.get(k,1)*v
    if p==4:
        k=2.0
        sp=(1+S['splash']*k)/(1+.3*k)
        for c in ('torch','shadow_bolt','soul_storm','arcane_spark','ember_rain','boiling_oil','gold_avalanche','poison_dart','spark','life_drain','eruption','meteor_storm'):
            f[c]=f.get(c,1)*sp
    return f,dm
def predict(S,show=True):
    err=0;out={}
    for (v,p),w in WIN.items():
        f,dm=factors(p,S)
        sh=share[(v,p)]
        V=sum(s*f.get(k,1) for k,s in sh.items())
        V/= (dm/1.0)**1.0   # dano do herói: tempo de vida das unidades
        lg=math.log(w/(1-w))+B*math.log(V)
        q=1/(1+math.exp(-lg)); out[(v,p)]=q
        err+=(q-TGT[p])**2
    if show:
        print(f'B={B:.2f}  erro rms {math.sqrt(err/12)*100:.1f} pts')
        for v in ('plague','dragon','lich'):
            print(f' {v:7}'+''.join(f'  F{p} {out[(v,p)]*100:4.0f} ({(out[(v,p)]-TGT[p])*100:+3.0f})' for p in (1,2,3,4)))
        for p in (1,2,3,4): print(f'  média F{p}: {sum(out[(v,p)] for v in ("plague","dragon","lich"))/3*100:.0f} (meta {TGT[p]*100:.0f})')
    return out
LICH_POSTF={'corpse_blast':.81,'shadow_bolt':125/140,'soul_storm':50/60,'acolyte':5/6}
NOW=dict(rats=dict(rat_horde=(33,4.4),rabid_rats=(39,5.5),rat_tide=(29,4.4),rat=(33,4.4)),
         spin=dict(rat_horde=1.04,rabid_rats=1.04,rat_tide=1.04,rat=1.04),
         troll=(2200,.02),legion=75,kobold=35,splash=.3,flat=dict(LICH_POSTF),dmg={3:1.4})

# ---- Rodada numérica de 13/11/2026 (aplicada nos dados, sem rodar bots) ----
def aplicado():
    S=copy.deepcopy(NOW)
    S['troll']=(1800,.01)
    S['rats']=dict(rat_horde=(52,4.0),rabid_rats=(58,5.0),rat_tide=(49,4.0),rat=(52,4.0))
    S['splash']=.15; S['legion']=65; S['kobold']=48; S['dyn']=1.0
    for k in ['kobold_scavengers','drakeling','treasure_guard','gold_merc','ash_salamander']: S['flat'][k]=1.3
    for k in ['corpse_blast','soul_storm']: S['flat'][k]=S['flat'].get(k,1)*1.1
    return S

if __name__=='__main__':
    import copy
    print('--- medição F (bal_f, real) ---')
    predict(dict(rats=dict(rat_horde=(25,4),rabid_rats=(30,5),rat_tide=(22,4),rat=(25,4)),troll=(2200,.02),legion=75,kobold=35,splash=.3))
    print('--- antes desta rodada (nunca medido) ---'); predict(NOW)
    print('--- depois desta rodada (previsão) ---'); predict(aplicado())
    for b in (2.2,4.0):
        print(f'--- sensibilidade B={b} ---'); B=b; globals()['B']=b; predict(aplicado())
