# Rio e pontes (plano, 15/11/2026)

Hoje o rio e a ponte são feios. A ponte é um tipo de local sorteado no mapa, com um pedaço de água embaixo,
e o rio não faz sentido com a estrada. Este plano troca isso por rios de verdade, gerados com o mapa.

## Decisões (grilling de 15/11, confirmadas por ele)

**Rio**
- 1 ou 2 rios por ato, com no máximo 5 pontes no ato.
- O rio sai de uma borda do mapa e chega à outra (de lado a lado ou na diagonal), ou volta para a mesma borda.
- Ele só corta a estrada em locais. No resto do caminho, corre entre os ramos.
- Aparece no mapa do jogador (minimapa em gravura).

**Ponte**
- Todo local por onde o rio passa vira Ponte (disputa), no lugar de um local comum.
- A Ponte sai do sorteio normal e só nasce do rio.
- A disputa segue as regras de hoje (até 20 s, dano dos monstros enche a barra, 3 marcos, cartas).
  Agora o herói para em cima da ponte.

**Regras da água**
- Monstro de chão não nasce nem anda na água. Se está do outro lado, vai até a ponte mais próxima.
- Voadores (`F_FLY`) ignoram o rio.
- Empurrão (repulsão, separação, golpes) para na margem.
- O herói não entra na água e ignora alvo que está do outro lado.

**Arte**
- Rio de ~10 m, curvo, em guache S1, com correnteza animada e margens de terra e pedra.
- Pontes de madeira com parapeito, do tamanho exato da travessia.

## Decisões que assumi (para ele revisar)

- **Feitiços** valem em qualquer lugar, inclusive na água. Eles não são unidades.
- **Ataque à distância** atravessa a água: atirador e herói acertam por cima do rio.
  O herói só não *escolhe* alvo do outro lado.
- **Largura do tabuleiro da ponte**: ~5 m, o bastante para uns 3 monstros lado a lado.
  A ponte é um gargalo de verdade, mas ainda cabe briga.
- **Até onde o rio vai**: ele passa da área visível do chão (~40 m além do ramo de fora), para nunca parecer que
  acaba no meio do campo.
- **Local Ponte numa fileira cheia**: quando um rio cruza todos os locais de uma fileira, todos viram Ponte.
  Isso quebra a regra "locais da mesma fileira são de tipos diferentes" só nesse caso: ali a escolha é o ramo, não o prêmio.
- **Saves antigos** (de antes do rio): a estrada do ato atual continua sem rio até o próximo ato.
  Nada quebra, porque o rio é um campo novo com padrão vazio.

## Como o rio é gerado

O rio é descrito em termos do mapa de nós, não em metros. Ele é uma sequência de pontos de controle:
- **local-ponte**: um nó (fileira, ramo) por onde o rio passa;
- **vão**: o espaço entre dois ramos vizinhos, numa altura entre duas fileiras;
- **borda**: fora do ramo de fora, à esquerda ou à direita.

Daí sai a curva no mundo (a partir das posições reais dos nós) e a curva no minimapa (a partir de `_dpos`).
Os dois desenhos vêm do mesmo dado. O gerador roda dentro de `SimRoad.generate`, com um RNG próprio
derivado da semente. Assim a estrada continua determinística, e a mudança mexe o menos possível nas
sequências de sorteio de que os testes dependem.

Formatos sorteados:
- **lado a lado / diagonal**: borda → local-ponte (ramo 0) → vão → local-ponte (ramo 1) → … → borda oposta.
  As fileiras podem subir ou descer a cada passo (diagonal).
- **vai e volta**: borda → local-ponte → … → curva num vão → … → local-ponte → mesma borda.

**Validador (o coração do gerador).** Cada candidato só é aceito se cumprir tudo isto:
1. A curva do rio não cruza nenhuma ligação da estrada, a não ser dentro do raio de um local-ponte.
   As ligações têm desvios laterais (`_kinked`) e diagonais extras (`extra_link`), então a verificação é
   geométrica, polilinha contra polilinha.
2. Fora das pontes, o rio fica a pelo menos `LEASH_MAX` da estrada. Senão a coleira puxa o herói para a água.
3. Em cada ponte, as ligações que chegam ficam numa margem e as que saem ficam na outra.
4. Rio de borda a borda: toda rota do início ao covil passa por **exatamente uma** ponte dele. Duas pontes do
   mesmo rio deixariam o herói na margem errada. Vai e volta: nenhuma ligação entra nem sai do bolsão sem
   passar por uma ponte.
5. O total de pontes no ato é no máximo 5. A fileira da Loja (um nó só) nunca vira ponte. O Ajudante nunca vira ponte.

Se nenhum candidato passar, o gerador tenta de novo. Depois usa o formato mais simples (uma fileira cheia).
Em último caso, o ato fica sem rio, e um teste conta quantas vezes isso acontece.

Um teste headless sorteia algumas centenas de sementes × 3 atos e confere as regras 1 a 5.

## Regra da água na simulação: um lugar só

O terreno vira um objeto com três consultas:
- `is_water(x, y)`;
- `region_of(x, y)`: em que margem o ponto está;
- `clamp_out(x, y)`: o ponto da margem mais próximo.

Essas consultas rodam como passo final em **todo** movimento de unidade de chão e do herói. Assim não é preciso
corrigir cada movimento (`_step`, `separate()`, empurrão, `_expel`, medo, desvio da isca, espalhamento de
grupo, unidades que nascem de morte ou de estrutura). O passo final cobre todos.

- **Andar até a ponte**: as margens viram regiões e as pontes, portais. Uma unidade de chão cujo alvo está em
  outra região mira primeiro a cabeceira do portal mais próximo, depois a outra cabeceira, depois o alvo.
  Com 2 rios ou um bolsão, isso pode dar mais de um salto (busca pequena no grafo de regiões).
- **Herói**: `_choose_target` descarta alvo de outra região. O passo final impede o herói de entrar na água.
- **Colocar carta**: `valid_target` recusa carta de unidade de chão sobre a água (`BAD_TARGET`) e aceita
  voadores e feitiços. Cuidado: hoje `in_any_ring` já proíbe pôr carta no anel de 10 m da Ponte. Isso vai
  ser revisto, porque com a briga na ponte faz sentido pôr monstro nas cabeceiras.
- **Bots**: conferir como `player_bot` e `human_bot` reagem a `BAD_TARGET`, para os bots de balanceamento
  não perderem jogadas sem ninguém ver.

## Locais

- A Ponte sai de `location_weights` em todos os atos (rules e campanha).
- Os nós-ponte ganham o tipo fixo antes da busca de 400 tentativas, como a Loja.
- `_place_helpers` exclui nós-ponte.
- A disputa usa o centro da ponte. O herói para no meio do tabuleiro.

## Arte e mapa

- **Mundo**: malha do rio construída ao longo da curva (fita com margens), com material guache S1 e
  correnteza animada. Pontes de madeira com parapeito, do comprimento da travessia e alinhadas com a estrada.
  Isso mantém as duas correções de 11/11: a altura do tabuleiro (`_add_surface`, para fantasma, unidades e
  herói ficarem em cima) e a ponte virada para a estrada.
- **Minimapa**: o rio desenhado em gravura (traço duplo com hachura de água) pelos mesmos pontos de controle.
  As curvas das ligações no minimapa têm puxadores de ±75 e podem cruzar o desenho do rio. Perto do rio,
  vou reduzir esses puxadores.

## Ordem de trabalho

1. **Base**: rodar a suíte de testes antes de mexer (a árvore está com muitas mudanças sem commit).
2. **Gerador + validador + teste de sementes.** Depois, uma **prancha com ~12 mapas reais** gerados (minimapa
   com o rio) para ele aprovar o traçado **antes** de qualquer outra coisa.
3. Regras da água na simulação (terreno, passo final, portais, alvo do herói, `valid_target`, bots).
4. Save/load: o rio entra no save da estrada. Teste de ida e volta.
5. Arte do rio e das pontes no mundo e no minimapa. Capturas no jogo, numa ponte, antes e depois.
6. Testes completos, bots de balanceamento (para ver se a Ponte ficou forte ou fraca demais agora que
   aparece de 2 a 5 vezes por ato), relatório.

## Andamento

**16/11 — passo 2 feito (gerador + validador + prancha).** Prancha em `docs/rio_e_pontes/index.html`.
- `sim/rivers.gd` (SimRivers): grafo de faces, candidatos, validação, A* no corredor livre, Chaikin.
  `sim/road.gd` chama na geração. A Ponte saiu de `location_weights`; config em `rules.road.river`.
- **Mudanças em relação ao plano:**
  - O traçado no mundo não passa pelos pontos médios. Ele é achado por A* numa grade que evita a estrada,
    porque os desvios das ligações deixam pouco espaço entre os ramos.
  - Quando nenhum rio cabe na estrada sorteada, o jogo sorteia outra estrada para o ato (até 6 vezes, mesmo
    rng). Sem isso, 14% dos atos ficavam sem rio.
  - As ligações das transições que tocam uma ponte são refeitas: trecho reto de 12 m pela ponte, todas com o
    mesmo comprimento novo e a curva do lado mais longe do rio.
  - A estrada de hoje já tinha cruzamentos no desenho entre ligações. O validador só recusa cruzamento *novo*.
- Minimapa: `_real_rivers` desenha o rio pelos mesmos pontos de controle. Lagos e enfeites ficam fora dele.
- Teste `t_rivers` (120 sementes × 3 atos) e ferramentas `tools/river/quick.gd` (só o teste) e
  `tools/river/sheet.gd` (prancha SVG/PNG).
- **Rio natural (16/11, pedido dele: "não existe rio reto"):** `SimRivers.meander` aplica curvas irregulares
  (a fase acelera e freia, a altura de cada curva varia e um desvio longo leva o rio de um lado para o outro).
  As curvas ficam calmas perto das pontes. No mundo: `meander_amp` 16 m, `meander_wl` 120 m, e só entra se
  continuar longe da estrada (senão tenta 60%, 30% e depois sem curva). No minimapa: amplitude 62 e onda 470
  unidades, limitadas pelo espaço livre até as trilhas.
- **Diagonal (16/11, escolha dele: "maioria diagonal, lados variados"):** cada rio que atravessa sorteia para que
  lado sobe. Os candidatos que cortam a estrada em fileiras diferentes nesse sentido pesam 14 vezes mais
  (`diagonal_weight`), no outro sentido 2 vezes, e os retos 0,2. As pontas de fora sempre ficam inclinadas, mesmo
  quando as pontes estão na mesma fileira. Resultado: 48% das travessias cortam em fileiras diferentes, porque
  muitas diagonais não cabem na estrada.
- **Foz (16/11, pedido dele: "o rio quando chega no mar se mistura"):** no mapa do jogador, o rio é cortado na
  costa. Nos últimos 120 unidades as margens se abrem num estuário e terminam exatamente na praia, que é
  desenhada já aberta ali (as linhas de onda do mar também). Cada emenda é um canto arredondado (`FILLET` de 30 unidades): a margem vira e segue a costa, e a praia é
  densa (a cada 8 unidades) perto das bocas, sem trecho reto. Pedaços curtos das linhas de onda são descartados. A água da foz é pintada em triângulos (um polígono que se cruza o Godot não pinta, sem erro). As margens
  são alisadas antes de emendar (sem dobra na curva de dentro); se uma margem não chega à costa, ela segue na
  própria direção virando aos poucos para o mar. Medido em 12 mapas: a maior virada de uma margem é 12° e a
  emenda com a praia, no máximo 4°. `--mapscroll=river0` centra a captura no rio.

**16/11 — passos 3 a 5 feitos (água na simulação, save, arte 3D).** Prancha aprovada por ele antes.
- `sim/terrain.gd` (SimTerrain): grade de 1 m com terra, água e tabuleiro. As regiões (margens) vêm de um
  preenchimento sem atravessar água nem tabuleiro, e cada ponte liga duas regiões pelas cabeceiras. A grade acaba
  onde o rio acaba; com margem, a beirada ligava as duas margens.
- `Sim.terra()` refaz o terreno quando a estrada muda. `Sim._water_pass` roda no fim de cada passo: herói, grupo,
  Ajudante e monstros de chão que terminaram na água voltam deslizando para a margem de onde vieram.
- `SimUnits._step`: monstro de chão em outra margem mira a cabeceira da ponte do caminho. Quando já dá para ir
  reto até a outra cabeceira sem pisar na água, ele vai (sem isso, oscilava na cabeceira).
- Herói: `_choose_target` ignora monstro do outro lado (`same_side`). Na disputa da Ponte ele fica firme no
  tabuleiro, mesmo brigando.
- Cartas: `valid_target` recusa monstro de chão na água; voador e feitiço podem. `clear_of_rings` (a mira dos
  bots) também tira o ponto da água.
- Save: o rio vai junto com a estrada; o terreno não (é refeito). Save de antes dos rios carrega sem rio.
- Mundo: `_build_rivers` desenha uma fita por rio com `game/art/river_paint.gdshader` (guache chapado em três
  tons, pinceladas que descem o rio, margem de terra que se desfaz na grama). A ponte é girada e escalada pelo
  tamanho do modelo para o tabuleiro da simulação (15 × 5,2 m). O capim e o cenário não nascem na água; a beira
  do rio ganha pedras, arbustos e flores.
- Teste `t_water`: carta na água, unidade que cai na água, travessia pela ponte, alvo do herói, save/load.
- **Decisões que assumi:**
  - Raio da disputa da Ponte de 10 para 4 m, para ela começar com o herói já no tabuleiro (a 10 m ele parava
    na margem).
  - Tabuleiro de 15 × 5,2 m (`deck_overhang` 2,5 m além da água de cada lado; `deck_half_width` 2,6).
  - Herói firme na ponte durante a disputa.
- `river.enabled = false` volta ao jeito antigo (sem rio, Ponte sorteada): só para comparar o balanço.

**16/11 — passo 6: balanço (bots greedy e human × praga, dragão e lich, 20 runs cada, mesmas sementes).**
Resultados em `reports/river_ab/` (sem_rio usa `reports/river_ab/data_sem_rio`, a regra antiga).

| | sem rio (antes) | com rio |
|---|---|---|
| vitória do jogador | 99% | 98% |
| Pontes por run | 1,66 | 2,34 (+41%) |
| Ponte vencida | 28% | 33% |
| disputas por run / vencidas | 10,8 / 23% | 11,1 / 26% |
| duração média | 973 s | 1007 s (+3%) |

- Com o rio, a Ponte aparece 41% mais e fica um pouco mais fácil de vencer (os monstros afunilam no tabuleiro,
  onde o herói está). O resto quase não muda.
- A vitória está no teto nos dois casos (98–99%), então este lote não mede bem a dificuldade geral. Não mexi
  em números: a Ponte mais frequente e um pouco mais fácil parece o efeito pedido ("brigam na ponte").

## Riscos

- O validador pode recusar muitas sementes em atos com muitas diagonais. A contagem de "ato sem rio" no
  teste mostra isso cedo.
- Mudar o sorteio dos locais muda a sequência do RNG. Testes que dependiam da sorte podem quebrar.
  Isso já aconteceu duas vezes (observações 84 e 104); conferir antes de chamar de "falha de outro".
- Mais Pontes por ato significa mais disputas de dano no herói. O balanço da recompensa da Ponte pode precisar de ajuste.
