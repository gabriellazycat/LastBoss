# Chefes finais (modelo de jogo)
Refinamento do blockout aprovado (`../README.md`) em `tools/art/blender_v2/bosses_final.py`: mesma silhueta e mesmas 4 partes, mesmo kit (`mk.py`), cor nos vértices, orçamento do chefe atual (núcleo 6000, cabeça 3000, braços 2500 triângulos).

- Arquivos: `assets/models/v2/boss_{plague,dragon,lich}_{core,head,left_arm,right_arm}.res` e `boss_lich_circle.res` (círculo ritual, cenário, não é parte). Os `boss_*.res` do chefe atual não mudaram.
- Origem por parte: `PART_OFFSETS` no script (ombro dos braços, pescoço da cabeça, chão do núcleo). Na Godot: `BossModels.part_offsets(vilão)` / `BossModels.boss_full(vilão)` (`game/art/boss_models.gd`). Sem algum arquivo, cai no chefe atual.
- Captura: `chefes_jogo.png` (câmera do jogo, 55°, fov 40, chefes virados para a câmera como na arena).

Regerar:
```
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_v2/bosses_final.py -- --out=<pasta> [--only=plague,dragon,lich]
godot --headless --path . -s res://tools/art/import_v2.gd -- --src=<pasta>
godot --path . res://docs/decisoes_2026-11-10/chefes/final/captura_chefes.tscn -- [--view=game|front|back] [--out=<png>]
```
O Blender leva uns 3 a 4 min por chefe (fusão por voxel e redução de triângulos).
