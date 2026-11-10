# Blockout dos 3 chefes novos (para aprovar a silhueta)
Esquerdo = +X do Blender (lado direito da tela vendo de frente), como no `boss.py`. Cada chefe tem 4 objetos `<id>_left/_right/_head/_core`.
- **Rainha da Praga** (`plague`): esq = pata com cetro de osso; dir = garra enorme; cabeça = rata de coroa torta e orelhas grandes; núcleo = ninho de trapos, ventre cheio de ratos, peito, capa e o "trono" de costelas.
- **Dragão Avarento** (`dragon`): esq = asa; dir = garra sobre o ouro; cabeça = chifres e fornalha na boca; núcleo = monte de moedas, corpo, cauda e coração-brasa no peito.
- **Lich** (`lich`): esq = mão com grimório aberto; dir = mão com foice; cabeça = caveira coroada com chamas verdes; núcleo = manto, costelas e filactério. O círculo ritual (`lich_circle`) é cenário, não é parte.
- Porte: escala final de cada chefe ajustada ao atual (5,6 m de altura; pegada 4,2 x 3,2 m), ver `FIT` no script.
- Imagens: `<chefe>/frente.png` (3/4), `<chefe>/jogo.png` (câmera 55°), `chefes.png` (comparação com o Lorde atual), `chefes_partes.png` (cores: azul esq, vermelho dir, amarelo cabeça, verde núcleo).

Regerar (a prancha leva uns 5 min por causa do chefe atual). O Blender grava `chefes_raw.png`/`chefes_partes_raw.png`; o script em Python do sistema (Pillow) põe nomes e legenda:
```
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_v2/bosses_v3.py -- --out=<pasta>
python tools/art/blender_v2/bosses_v3_labels.py <pasta>   # gera chefes.png e chefes_partes.png (descarte os *_raw.png)
```
Opções: `--only=plague,dragon,lich` (só as fotos por chefe) e `--sheet` (só as pranchas).
