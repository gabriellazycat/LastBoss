#!/usr/bin/env bash
# Lote dos clipes dos efeitos (rodada visual 20/11/2026). Uso: bash tools/capture_clips_fx.sh <seq> [estilos]
# seq = magias | feiticos | combate | taverna ; estilos = "0 1 2" (padrão)
cd "$(dirname "$0")/.."
B="--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --camzoom=-14"
SEQ="${1:-feiticos}"; STY="${2:-0 1 2}"
for v in $STY; do
  case "$SEQ" in
    feiticos) bash tools/capture_clip.sh fx v$v --fx=$v feiticos 58 "$B --fxdemo=torch,web,boiling_oil,shadow_bolt,arcane_spark,corpse_blast,weakness_curse --herostop=1 --fxat=2 --fxgap=4 --fxdist=0 --fxemit=hit:1,death:1,heal:1,shield:1,level:1,magic:1.4,fire:1.4,collapse:1 --fxeat=30 --fxegap=3.5" ;;
    combate) bash tools/capture_clip.sh fx v$v --fx=$v combate 30 "$B --herostop=1 --spawn=skeleton_archers,goblin_dynamiter,slime,fire_imp,goblin_dynamiter" ;;
    magias) bash tools/capture_clip.sh fx v$v --fx=$v magias 66 "$B --herostop=1 --fxdemo=torch,shadow_bolt,arcane_spark,corpse_blast,weakness_curse,web,boiling_oil --fxat=2 --fxgap=6 --fxdist=0 --fxemit=hit:1,death:1,heal:1,shield:1,level:1 --fxeat=50 --fxegap=3.5" ;;
    proj) bash tools/capture_clip.sh fx v$v --fx=$v flecha 12 "--start=horde --seed=7 --firstparty=arqueira.guardiao.cleriga.assassino --camzoom=-14 --herostop=1 --spawn=skeleton_archers,skeleton_archers,skeleton_archers,skeleton_archers"
          bash tools/capture_clip.sh fx v$v --fx=$v orbe 12 "--start=horde --seed=7 --firstparty=mago.guardiao.cleriga.assassino --camzoom=-14 --herostop=1 --spawn=skeleton_archers,skeleton_archers,skeleton_archers,skeleton_archers" ;;
    herois) bash tools/capture_clip.sh herois v$v --herois=$v party 14 "--fx=0 --start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --camzoom=-14 --herostop=1 --spawn=slime,slime,goblin_dynamiter,slime" ;;
    arena) bash tools/capture_clip.sh arena v$v --arena=$v chefe 12 "--fx=0 --firstparty=guardiao.cleriga.mago.assassino --camzoom=-6 --autoplay=heuristic --phase=6 --seed=7 --skip=arena --speed=1 --fxrel=1" ;;
    taverna) bash tools/capture_clip.sh fx v$v --fx=$v taverna 30 "--start=horde --seed=7 --firstparty=guardiao.cleriga.mago.assassino --offerat=3 --offer=contest:tavern --spawn=goblin_dynamiter,goblin_dynamiter,goblin_dynamiter,fire_imp,slime --camzoom=-8" ;;
  esac
done
