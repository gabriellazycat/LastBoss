# Direção G · Blender v2 (09/11/2026)

Monstros, estruturas, chefe e cenário inteiro refeitos no Blender no estilo que você aprovou no comparativo de
09/11 (`docs/visual/comparativo_blender_vs_kaykit*.jpg`); heróis continuam KayKit. Feito com você fora (AFK,
autonomia total repassada pela sessão principal): as decisões que tomei no seu lugar estão no fim.

**Como ligar:** Configurações → Visual → Direção de arte → **G · Blender v2 (monstros, chefe e cenário)**
(`--set=look_ground:10,look_hero:5,look_enemies:7`). A **D continua o padrão** até você escolher.

Pranchas: `docs/visual/prancha_blender_v2_intermediaria.jpg` (5 monstros + cenário, antes de converter tudo) e
`docs/visual/prancha_blender_v2_final.jpg` (capturas reais do jogo).

## FPS com 500 unidades (D x G)

Mesma sessão, janela 1920x1080, `--autoplay=random --stress=500 --quit=25`, duas rodadas intercaladas
(`bash tools/art/capture_dirs.sh <pasta> D G --fps`; números em `docs/visual/blender_v2/fps.txt`):

| Direção | Rodada 1 (média / mín.) | Rodada 2 (média / mín.) | Média |
|---|---|---|---|
| D · padrão | 77 / 38 | 88 / 79 | **82** (mín. 38) |
| **G · Blender v2** | 72 / 60 | 77 / 71 | **74** (mín. 60) |

A G custa ~10 % na média e teve mínimo melhor. Os monstros novos têm 2 a 4,4 mil triângulos (os CC0 têm de 0,4 a
11 mil); as peças espalhadas às centenas passaram pelo `lod_props.gd` (árvore 857 → 427, pinheiro 524 → 262,
árvore morta 416 → 195, cogumelos 600 → 272), na mesma técnica de MultiMesh + nível reduzido gravado da D/F.

## O que tem

| Camada | Peças | Onde |
|---|---|---|
| Monstros e estruturas (17) | rat, rat_king, bat, skeleton, skeleton_archers, goblin_dynamiter, slime, cultists, ghost, spectre, werewolf, ogre, scrap_golem, mimic, bone_totem, bat_nest, gargoyle_tower | `monsters.py`, `monsters2.py`; animação em `anims.py` |
| Chefe (4 partes destrutíveis) | boss_core, boss_head, boss_left_arm, boss_right_arm, mesma origem e tamanho das antigas | `boss.py` |
| Chão | tree, tree_round, dead_tree, bush, rock, grass, flowers, mushroom, road_stone, gravestone, lantern | `scenery.py` |
| Locais e estrada | house, tavern, fence, coins, fountain, ritual, shrine, bridge, water | `scenery.py`, `locations.py` |
| Covil e arena | castle, arena (piso de lajes), pillar, brazier, altar, throne (menu) | `locations.py` |
| Chão, estrada e luz | looks de chão 10 (dia), 11 (outono, ato 2), 12 (crepúsculo, ato 3) | `game/art/ground_looks.gd` |

Tudo em `tools/art/blender_v2/`; malhas prontas em `assets/models/v2/`.

## Como funciona

- **Modelagem:** formas macias fundidas por voxel (corpos, folhagem) e peças duras chanfradas (pedra, madeira,
  metal), pintura por vértice. O kit (`mk.py`) e os 4 monstros aprovados (`chars.py`, `chars2.py`) são os do
  comparativo.
- **Exportação (`vat.py`):** cada modelo vira uma malha só (`.lbm`), com a cor do material nos vértices (alfa < 1 =
  brilho, como nos CC0), reduzida para um orçamento de triângulos, e, nos monstros, **andar (12 quadros) + ataque
  (8 quadros)** gravados como posição e normal por vértice. A animação é por ossos rígidos (cada parte tem um osso)
  com pesos por região para os corpos fundidos (patas do rato, braços do ogro e do lobisomem); a gosma, o fantasma
  e o espectro deformam de forma macia.
- **Importação (`tools/art/import_v2.gd`):** monta o ArrayMesh com a textura de animação (VAT) no mesmo formato dos
  CC0; o `look5.gdshader` toca a animação por instância na MultiMesh. Nada mudou no shader.
- **No jogo:** `Looks` ganhou o look 7 (pasta `v2`); o look de chão 10 tem `props_dir: v2`, e `Models.prop()` /
  `Models.boss_part()` trocam qualquer peça que exista lá. O piso da arena entra no lugar do disco montado em código.

## Como refazer

```
B="C:/Program Files/Blender Foundation/Blender 5.2/blender.exe"
"$B" -b --factory-startup -P tools/art/blender_v2/build.py -- <pasta> [ids] [--preview=<pasta>]
godot --headless --path . -s res://tools/art/import_v2.gd -- --src=<pasta>
godot --headless --path . -s res://tools/art/lod_props.gd -- --from=v2 --to=v2 --only=tree,tree_round,dead_tree,bush,flowers,mushroom,grass --keep=0.4   # uma vez, depois do import
godot --path . -s res://tools/art/capture_big.gd -- --scene=res://tools/art/board_v2.tscn --out=<pasta>/          # prancha
godot --path . -s res://tools/art/capture_big.gd -- --scene=res://tools/art/board_v2.tscn --layout=locs --out=<pasta>/  # locais
godot --path . -s res://tools/art/capture_big.gd -- --scene=res://tools/art/board_v2.tscn --layout=anim --out=<pasta>/  # animação na MultiMesh
godot --path . -s res://tools/art/capture_big.gd -- --scene=res://tools/art/showroom.tscn --look=7 --ground=10 --out=<pasta>/  # vitrine
bash tools/art/capture_dirs.sh <pasta> D G --fps
```

Cada modelo leva de 1 a 3 minutos no Blender (o remesh por voxel); rode 4 processos em paralelo com listas de ids.

## Capturas

- `docs/visual/prancha_blender_v2_final.jpg`: D x G na estrada, na horda, na arena e nas cartas; atos 2 e 3; os
  17 monstros; um local de cada tipo (loja, taverna, fonte, ritual, santuário, ponte, encruzilhada, covil, arena).
- `docs/visual/blender_v2/`: as capturas da G em tamanho cheio e o `fps.txt`.

## Decisões que tomei no seu lugar (AFK) e riscos

- **Prancha intermediária sem esperar resposta:** gerei, olhei e corrigi sozinho (você estava fora). O que a
  conferência no jogo pegou e corrigi: malhas do avesso (a Godot usa a ordem de vértices inversa à do Blender:
  o ogro parecia transparente), cores lavadas no sol da D (a exportação agora escurece 20 % e satura 30 %),
  piso da arena claro demais, casa e taverna grandes demais para o lugar delas na estrada, manchas de "pedra"
  no chão. **Risco:** você pode achar as cores mais escuras ou mais saturadas do que no comparativo do Cycles.
  O ajuste fica em `GRADE_GAIN`/`GRADE_SAT` em `vat.py`.
- **Chefe:** entrou no escopo (pedido da sessão principal, "toda a arte"). Refiz as 4 partes destrutíveis com a
  mesma origem, tamanho e posições (`PART_OFFSETS`); nada da simulação mudou. Também refiz o trono do menu, mas o
  menu monta o chefe com `Models.boss_full()`, que usa a direção atual: só muda quando a G estiver escolhida.
- **Escala do jogo mantida:** cada monstro tem a mesma altura dos CC0 (`import_cc0.gd`). O rato (0,5 m) fica
  pequeno na câmera do jogo, como o atual.
- **Animação própria:** sem esqueleto de verdade; ossos rígidos + pesos por região, gravados em VAT. Os
  movimentos são simples (passo, balanço, golpe por cima, arremesso, bote, tampa do mímico, asas). As estruturas
  (totem, ninho, torre) só "respiram" e dão um tranco no ataque. **Risco:** alguns ataques podem parecer
  rígidos de perto; de cima, na câmera do jogo, leem bem.
- **Variações por ato:** os atos 2 e 3 trocam a G para os chãos 11 (outono, folhagem laranja) e 12 (crepúsculo
  roxo), com as mesmas peças tingidas por instância. Só vale com "terrenos por ato" ligado, como hoje.
- **Água** continua com o brilho leve que o jogo já põe (`glow_material(0.2)`), agora sobre um azul mais escuro.
- **Herói:** intocado (KayKit, look 5 no seletor); a sessão principal está adicionando Arqueira, Clériga e Mago.
- **Cartas:** as peles que mostram o modelo 3D na carta (`card_art.gd`) já usam os monstros novos; a pele
  Diário (padrão) desenha as cartas à mão e não muda.
- **Não refeito:** ícones 3D das cartas de feitiço (`Models.icon`),
  efeitos (projéteis, fumaça, números) e a grama de lâminas do shader (continua a do chão da D).
