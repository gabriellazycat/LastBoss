# Modelos 3D em miniaturas pintadas (15/11/2026)

Pedido: refazer heróis, inimigos e cenário em 3D para combinar com a UI, as cartas e o guache. Você saiu (AFK, autonomia
total), então as decisões abaixo foram minhas. **Nada foi commitado e o padrão do jogo não mudou**: as 7 versões estão
numa prancha à parte para você escolher.

## O que ver

- `docs/modelos_guache/prancha_perto.jpg`, `prancha_herois.jpg`, `prancha_detalhe.jpg`: as 7 versões lado a lado.
- `docs/modelos_guache/v/V<n>_<jogo|perto|detalhe|herois|cenario>.png`: fotos cheias (1920x1080) de cada versão, no chão,
  estrada e luz do jogo (guache S1). `docs/modelos_guache/base/shot_007.png`: o jogo de antes, para comparar.

| Versão | O que é |
|---|---|
| V1 | Controle: formas novas, cor por vértice, guache do shader (como é hoje) |
| V2 | Atlas pintado com dabs de pincel chato (manchas largas, borda dura) |
| V3 | Atlas aguado: lavagem larga, cor mais clara, borda molhada |
| V4 | Atlas de pincel seco: veios compridos que só clareiam |
| V5 | Cor chapada (poucas cores) + contorno de tinta no shader |
| V6 | Gorducha (cabeça maior, corpo mais largo) + dabs |
| V7 | Facetada (planos largos, 70% menos triângulos) + dabs |

Amostra: 2 heróis (Escudeiro e Mago, **feitos do zero**, sem rosto), 10 inimigos (rato, Rei dos Ratos, goblin dinamitador,
slime, esqueleto, ogro, lobisomem, morcego, fantasma, mímico) e 10 cenários (árvore, árvore redonda, pedra, arbusto, casa,
taverna, fonte, lápide, lanterna, cerca). V6 e V7 só mudam os corpos (inimigos e heróis); o cenário delas usa a forma normal
(V7 também facetou o cenário).

## Como foi feito

- **Geometria:** `tools/art/blender_g/` (`build_g.py`, `vat_g.py`, `heroes_g.py`). Usa os construtores do v2 e **apaga o que
  é miúdo** (menos de 5,5% da altura: reflexos dos olhos, sobrancelhas, dentes, fivelas). Criaturas mantêm olhos; humanos não.
  Mesma proporção e mesma animação (andar + ataque por ossos rígidos, VAT) de hoje.
- **Cor das cartas:** `palettes.py` tira 5 faixas de valor da arte de cada carta (`assets/cards`, portraits para os heróis) e
  puxa 15% da cor do modelo para elas; pretos levantados; um ganho de 0,62 porque o sol do jogo estoura tudo acima de ~0,6
  (foi o que deixava tudo lavado, inclusive o herói de antes).
- **Atlas:** UV desdobrada e empacotada (smart project), cor/posição/normal rasterizadas em 512x512 e a pincelada pintada no
  espaço do modelo (`treat.py`, numpy puro dentro do Blender), logo atravessa as costuras. Regras suas mantidas: pincel largo,
  nada de detalhe fino, a pincelada clareia mais que escurece, sombra grande e fria.
- **Shader:** `look5.gdshader` ganhou `atlas` (sem pinceladas do shader por cima) e `ink` (contorno). Nada mais mudou.
- **Importação:** `tools/art/import_g.gd` grava `assets/models/g_<n|c|f>` (cor por vértice) e `g_<geom>_a` (vértices brancos + UV)
  e copia os atlas para `assets/models/g_tex/<tratamento>_<geom>/`. Depois rode `godot --headless --path . --import`.
- **Prancha:** `tools/art/board_g.tscn` + `tools/art/capture_g.sh <pasta> [V1..V7]`.

Refazer (os 22 modelos montados ficam em `%TEMP%/lbg_<id>.blend`; `LBG_REUSE=1` só refaz graduação e atlas):

```
B="C:/Program Files/Blender Foundation/Blender 5.2/blender.exe"
"$B" -b --factory-startup -P tools/art/blender_g/build_g.py -- <saída> [ids] [--geoms=n,c,f]
godot --headless --path . -s res://tools/art/import_g.gd -- --src=<saída>
godot --headless --path . --import
bash tools/art/capture_g.sh docs/modelos_guache/v
```

## Decisões que tomei no seu lugar (rever)

1. **Atlas por IA não foi gerado.** Você pediu "tanto assada no Blender quanto IA"; o ComfyUI não estava no ar e a skill
   cartas-ia exige subi-lo, então as 5 texturas são todas procedurais em Blender. O que dá para fazer: gerar folhas de pincel
   por IA para o tratamento que você escolher.
2. **V5 usa quantização de cor** (6 níveis por canal): saem alguns tons estranhos (roxo no Escudeiro, rosa no lobisomem).
   Se for a escolhida, troco por uma quantização por paleta da carta.
3. **Cinco tratamentos, três geometrias:** você pediu "5 texturas e shaders + 2 variações de proporção"; fiz 4 atlas + o
   controle (V1) e 2 proporções sobre o dabs.
4. **Cores só 15% das cartas**: puxar mais tornava tudo cinza (as cartas são dessaturadas e a luz do jogo ainda estoura).
5. **Heróis sem rosto, mão esquerda com escudo (+x), espada na direita**, 1,75 m; Mago de túnica larga com cajado aceso.
6. Cenário recebe a mesma graduação (ganho 0,62), sem paleta de carta.

## O que falta (por isso nada foi trocado no jogo)

- **Integração no jogo:** os modelos novos só aparecem na prancha. Unidades entram pelo `Looks` (precisam de um look 8 que
  aponte para `g_<geom>_a` e ligue `use_tex/atlas`); o cenário e os locais usam `prop.gdshader`, que ainda não lê atlas.
- **Heróis em campo:** o jogo usa `HeroRig` (esqueleto KayKit). Os heróis novos são VAT; falta um `HeroVat` com o mesmo estado
  (parado, andar, correr, golpe, bloquear) e a classe Arqueira e Clériga (só Escudeiro e Mago foram feitos).
- **Resto do conjunto** (chefes, outros inimigos e cenário, arena, castelo, ponte...) depende de qual versão você escolher.
- **Reflexo da cena:** a prancha não mostra HUD nem cartas; só mundo, na câmera do jogo.
- Durante a sessão `game/hud.gd` ganhou um erro de parse (`below` não declarado, linha 582) por edição de outra sessão
  às 13:41; não é desta rodada e não afeta a prancha, mas o jogo não abre até ser corrigido.

---

# Atualização: V4 (pincel seco) escolhida e aplicada ao jogo todo

Você escolheu a **V4 · pincel seco** (`docs/modelos_guache/escolha.json`) e pediu duas regras: **cores e tons iguais aos
das cartas** e, nos inimigos, **olhos sem pupila, de uma cor só**. Feito (nada commitado):

- **Padrão do jogo:** `Settings model_g = 4` (`ART_REV` 6 leva quem já tinha configuração salva). Opção em Configurações →
  Vídeo → "Modelos 3D"; 0 desliga (volta aos modelos v2), 1 a 7 são as versões da prancha (as 1 a 7 antigas **não** foram
  refeitas com as regras novas: valem só a V4).
- **Conjunto inteiro refeito** (73 modelos em `assets/models/g_n` e `g_n_a`, atlas em `g_tex/dry_n`): todos os inimigos e
  estruturas do v2, as 3 criaturas da Praga, as 3 do Dragão e as 3 do Lich, os 3 chefes (4 partes cada, mais o círculo do
  Lich), o chefe antigo, todo o cenário e os 4 heróis (Escudeiro, Mago, **Arqueira** e **Clériga** novos). O `HeroVat`
  (`game/art/hero_vat.gd`) anima os 4 heróis por textura; o KayKit não é mais usado com a V4.
- **Cor das cartas:** cada modelo puxa 65% da paleta da arte da **própria carta** (cenário: 45%, média de cinco cartas de
  terra), com ganho 0,45 (criaturas) e 0,6 (cenário), porque a luz do jogo dobra o brilho. Resultado: cinza-azulado e
  lavanda foscos como as cartas, sem o branco estourado de antes.
- **Olhos:** `vat_g.flatten_eyes` apaga pupila, reflexo e órbita e deixa o olho de uma cor só (quase preto; o Rei dos Ratos
  vermelho). Os olhos brilhantes dos esqueletos ficam, de uma cor e maiores.
- Pipeline: `build_g_all.py` (todos os exportadores do v2 com a exportação nova), `palettes.py` (paleta por carta). Memória
  da regra: `models-3d-match-cards-eyes`.

**Não verificado / pendências:** os chefes e a arena não foram vistos em jogo (as capturas automáticas pulam para a tela de
vitória); o brilho de dano some nos heróis novos; os testes do projeto têm 2 falhas em "Ritual Profano", fora desta rodada
(cartas); a tela de escolha (`escolher.html`) ainda mostra as versões antigas.

---

# Ajuste (15/11, tarde): heróis antigos, mais cor, Mãe da Ninhada

Feedback: inimigos com mais cor, modelos que não condiziam com a carta e herói novo feio.
- **Heróis:** voltaram ao modelo antigo (KayKit, `HeroRig`) nas 8 classes; `Looks.hero_rig()` não usa mais o `HeroVat`
  (código e modelos `g_*/escudeiro` etc. seguem no repositório, desligados).
- **Mais cor:** graduação refeita com `LBG_PULL=0.3 LBG_SAT=1.45 LBG_GAIN=0.5 LBG_PULL_SC=0.25 LBG_GAIN_SC=0.6` (antes 0,65 /
  1,15 / 0,45). 69 modelos reimportados (heróis novos não foram refeitos). Olhos de uma cor só, sem pupila, mantidos.
- **Mãe da Ninhada** usava o slime (VARIANTS em `looks.gd`); agora é o rato grande (escala 1,6). Outras cartas que
  emprestam o modelo de outra (ghoul = lobisomem, fire_imp = morcego, corrupt_piper = cultistas...) não foram revistas.
