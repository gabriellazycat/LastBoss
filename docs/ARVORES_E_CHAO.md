# Árvores, arbustos e textura do mundo (22/11/2026)

Pedido: árvores e arbustos "parecem feitos de massinha", refazer no Blender; o visual e os modelos estão bons, o que
incomoda é a textura do mundo, trazer variações bonitas e condizentes com a UI e as cartas. Ele estava fora: sem
perguntas, decisões abaixo. Nada commitado.

## O que mudou

### Árvores e arbustos (padrão novo: `--arvores=7`)
- **Por que pareciam massinha:** a copa era um punhado de elipsoides fundidos por voxel, alisados e decimados, com
  sombra em degradê macio: superfície lisa e borda redonda, como argila.
- **Agora:** cada tufo é um miolo escuro facetado coberto por dezenas de placas angulosas (a forma de uma pincelada de
  pincel chato, ponta para baixo e para fora). Cada placa tem **uma cor chapada e uma normal só**: a luz do jogo pinta a
  placa inteira de uma vez, em degraus, como o guache das cartas. As pontas serrilham a silhueta; o miolo escuro
  aparece entre elas como a sombra funda das cartas. O atlas leva um veio de pincel largo em cada placa (só clareia).
- **Mesmas silhuetas que ele aprovou em 21/11:** carvalho largo e carvalho torto (estilo 5), pinheiro de saias e
  álamo (estilo 6), nos 3 atos (primavera, outono com folhas misturadas, terra amaldiçoada roxa e seca).
  O padrão `7` sorteia carvalho ou pinheiro por bosque, como o `4` fazia com os estilos 2 e 3.
- **Arbustos novos** (`assets/models/arv5/bush_a<ato>`), um por ato, já com a cor do ato (a tinta por instância
  saiu quando eles estão ligados, senão a cor dobrava). O do ato 3 é ralo, com galhos secos espetados.
- Triângulos: carvalho 1,1 a 3 mil, pinheiro 0,4 a 1,1 mil, álamo 0,9 a 1,9 mil, arbusto 1 a 1,5 mil
  (antes: ~1,2 mil por árvore e ~220 o arbusto). FPS nas capturas: ver "Verificação".
- Fontes: `tools/art/blender_arvores/build_pinceladas.py` (Blender em segundo plano), depois
  `bash tools/art/blender_arvores/fazer.sh <estilo> <saída>` e `godot --headless --path . --import`.
  Pranchas: `docs/arvores_chao/pranchas/`.
- `--arvores=4` volta às de 21/11; `--arvores=0`, às antigas.

### Textura do chão e da estrada (padrão: `--chao=2`, relva pincelada, escolhida por ele)
- **Por que era feia:** o chão (`ground_ror`) somava manchas em várias escalas, um relevo falso por ruído (a luz
  desenhava manchas claras e escuras no chão plano), salpicos miúdos e, por cima, as pinceladas genéricas do
  `paint_albedo`. Tudo junto virava borrão. A estrada puxava para o vermelho-tijolo, que a luz quente, a névoa azul e a
  LUT dos escuros deixavam rosada.
- **Agora:** `game/art/ground_tela.gdshader` e `game/art/road_tela.gdshader`, quatro estilos, cada um **uma** ideia de
  pintura, sem relevo falso e sem salpico, com as mesmas cores por ato de antes:
  1. **Guache chapado:** três campos grandes de verde (fundo, frio, verde-amarelo) com borda pintada nítida,
     três valores, e pinceladas largas deitadas que só clareiam, como os fundos das cartas.
  2. **Relva pincelada (padrão, escolhida por ele em 22/11):** campos macios e pinceladas de relva largas afinando, todas para o mesmo lado.
  3. **Mosaico de pinceladas:** manchas de pincel de ~1,5 m, cada uma num tom vizinho; conversa com as copas novas.
  4. **Liso:** só os campos em degradê macio; o cenário e as unidades aparecem mais.
- A estrada de cada estilo segue o mesmo campo (máscara, ramos escurecidos, brilho), com a terra cor de areia/ocre
  dos caminhos das cartas, trilha do meio mais clara e beirada um tom mais escura (sem o contorno escuro largo).
- `--chao=0` volta ao chão e à estrada de antes. `GroundLooks.TELA` no código.

## Escolha dele (22/11/2026)
- Ficou com as árvores e arbustos novos (`--arvores=7`) e escolheu a **relva pincelada** (`--chao=2`), que virou o padrão.

## Decisões que tomei no lugar dele (e riscos)
- **Novo como padrão:** ele pediu para refazer, então árvores e arbustos novos e o chão 1 eram o padrão provisório; o de antes
  fica a uma opção de distância. Se ele preferir outro chão, é trocar `GroundLooks.TELA` (1 a 4).
- **Escolhi o guache chapado** porque é o mais parecido com os fundos das cartas (campos lisos, borda pintada, pincel
  largo) e o mais calmo; a relva pincelada é a mais "viva"; o liso é a mais limpa.
- **Não mexi** em luz, céu, névoa, regiões do cenário, modelos das unidades, prédios ou UI. Só árvores, arbustos,
  chão e estrada.
- **Sem textura de foto, sem filtro de tela, sem grão por cima** (já recusados antes). Pinceladas só clareiam.
- **A estrada mudou de cor:** de vermelho-tijolo (que saía rosado) para areia/ocre na primavera e no outono, como
  os caminhos das cartas; na terra amaldiçoada fica no roxo acinzentado. É mudança de cor que ele não pediu
  explicitamente; `--chao=0` volta à estrada (e ao chão) de antes.
- **Mais triângulos** nas árvores e arbustos (copa de placas). Medido nas capturas; se pesar em máquina fraca, dá para
  baixar a densidade de placas (`density`/`dab` no gerador) sem mudar o estilo.
- **Árvore morta, tocos, troncos, flores e grama 3D** ficaram como estavam (não foram citados).
- A página de revisão (porta 8769) ganhou a frente "Árvores e chão" com antes/depois.

## Verificação
- Suíte completa (`res://tests/tests.tscn`, headless): 981 ok, **0 falhas** (a suíte não compila shaders).
- Shaders: uma rodada com janela (fora da tela) de cada modo — padrão, `--chao=0`, `--arvores=4`, `--chao=2/3/4` —
  sem nenhum SHADER ERROR nem SCRIPT ERROR no log.
- Capturas das mesmas 4 cenas (ato 1 estrada, ato 1 perto, ato 2, ato 3) em `docs/arvores_chao/`: `antes/`
  (árvores de 21/11 + chão de antes), `chao0/` (árvores novas + chão de antes), `chao1/` a `chao4/` (árvores novas +
  cada chão). Pranchas das árvores em `docs/arvores_chao/pranchas/`.
- FPS nas mesmas cenas (contador do jogo, uma amostra por cena): antes 100 / 81 / 97; árvores novas com o chão de antes
  94 / 81 / 93; árvores novas com o chão 1 (padrão) 103 / 95 / 115. Uma amostra por cena, algumas com a suíte
  rodando ao lado: dá para dizer que não piorou, não que ficou mais rápido.
- Corrigido no caminho: placas das copas com a face virada (metade sumia), terra grande no chão lendo como estrada
  (agora clareiras pequenas e misturadas à relva), placa clara de pedra no ato 3, estrada laranja no ato 3 (a cor de
  areia vale só na primavera e no outono).
- Não verificado: ele ainda não viu; o vento nas copas novas e o trecho da troca de ato (os dois chãos visíveis ao
  mesmo tempo) só foram vistos em captura parada, não em movimento.
