#!/usr/bin/env bash
# Lote das capturas da rodada visual no worktree visual: efeitos (e0/e1/e2), heróis (h0/h1/h2), arena (a0/a1/a2).
cd "$(dirname "$0")/.."
B="--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --camzoom=-14"
for v in 0 1 2; do
  bash tools/capture_fx.sh e$v $v 0.25 fogo "$B --fxdemo=torch"
  bash tools/capture_fx.sh e$v $v 1.2 teia "$B --fxdemo=web"
  bash tools/capture_fx.sh e$v $v 0.8 oleo "$B --fxdemo=boiling_oil"
  bash tools/capture_fx.sh e$v $v 0.3 oleo_respingo "$B --fxdemo=oil_splash"
  bash tools/capture_fx.sh e$v $v 0.15 sombra "$B --fxdemo=shadow_bolt"
  bash tools/capture_fx.sh e$v $v 0.2 corpo "$B --fxdemo=corpse_blast"
  bash tools/capture_fx.sh e$v $v 0.2 arcano "$B --fxdemo=arcane_spark"
  bash tools/capture_fx.sh e$v $v 0 disputa "--start=horde --seed=7 --firstparty=guardiao.arqueira.mago.besteiro --offerat=3 --offer=contest:tavern --spawn=skeleton_archers,goblin_dynamiter,slime,fire_imp --camzoom=-8 --fxdemo=, --fxat=9"
done
for v in 0 1 2; do
  bash tools/capture_fx.sh h$v 0 0 estrada "--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --camzoom=-14 --fxdemo=, --fxat=5" --herois=$v
  bash tools/capture_fx.sh h$v 0 0 disputa "--start=horde --seed=7 --firstparty=barbaro.arqueira.escudeiro.besteiro --offerat=3 --offer=contest:tavern --spawn=skeleton_archers,goblin_dynamiter,slime --camzoom=-8 --fxdemo=, --fxat=9" --herois=$v
done
for v in 0 1 2; do
  bash tools/capture_fx.sh a$v 0 0 arena "--autoplay=heuristic --phase=6 --seed=7 --skip=arena --speed=1 --fxdemo=, --fxat=0 --fxwait=4" --arena=$v
done
