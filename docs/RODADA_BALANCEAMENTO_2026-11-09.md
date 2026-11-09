# Rodada de balanceamento e caça a bugs — 09/11/2026

**Estado:** feita numa tarefa agendada, com você fora e autonomia total (sem perguntas, sem grilling). Tudo está no branch `balanceamento-2026-11-09`, em commits pequenos; a `main` não foi tocada e nada foi enviado ao GitHub. O primeiro commit do branch (`Snapshot antes da rodada…`) guarda tudo o que estava sem commit na `main`; as capturas brutas `docs/visual/antes` e `docs/visual/rodada_*` (~400 MB) ficaram fora do commit, mas continuam no disco.

O jogo foi balanceado **como está hoje** (grupo de 5 heróis e mapa de rotas já no código). Nada do redesign pendente de revisão foi mexido.

## Como testei

- **Testes de antes:** `tests.tscn` com 0 falhas; `--menutest`, `--routetest` e `--tiptest` OK. O `--uitest` falhou uma vez com a CPU cheia (a tecla 1 chegou antes da run estar pronta) e passou nas 3 repetições seguintes; é instabilidade do teste, não do jogo.
- **Entrada real no jogo:** o computer-use precisa de uma aprovação sua na tela, que ninguém podia dar com você fora. Por isso a entrada real foi **injetada dentro do jogo** (os mesmos eventos de mouse e teclado que o Windows entrega), num teste novo: `godot --path . -- --chaostest=1`. Ele clica nas bordas e fora da janela, em cima da HUD com carta selecionada, faz 30 cliques rápidos, arrasta cartas para lugares inválidos, clica com o jogo pausado (no mundo e numa oferta), esmaga o sacrifício, redimensiona a janela (640x360 até 1600x900), manda 400 entradas aleatórias, salva e volta ao menu no meio da run e continua, e esmaga os altares na arena. A cada quadro ele confere elixir, mão, seleção e posições.
- **Combinações esquisitas:** `godot --headless --path . res://headless/fuzz.tscn -- --seeds=1-100` monta decks absurdos (qualquer carta, cópias e finalizações demais, níveis e modificadores sorteados) e manda comandos sem sentido (índices inválidos, alvos a até 80 m, rota para nós que não existem). Ele confere invariantes a cada passo, avisa se o herói ficar parado sem motivo e confere que a run termina. 100 runs, nenhuma quebra depois das correções.

## Bugs achados e corrigidos

Cada um tem teste que falha sem a correção.

| # | Bug | Como achei | Correção | Teste |
|---|---|---|---|---|
| 1 | **Giro de mão grátis e infinito.** Durante a recarga do sacrifício (8 s), sacrificar não dava elixir, mas girava a mão de graça, sem limite. Dava para cavar o deck sem parar atrás da melhor carta. O bot Heurístico sacrificava ~1.400 vezes por run na Ruína para ter sempre o Raio Sombrio (62% do dano dele); um humano conseguia o mesmo com o botão direito. | Telemetria do lote (sacrifícios por run) | Na recarga só gira **carta morta** (fora de fase, condição ou limite, como uma finalização na estrada). Uma carta jogável fica na mão até a recarga acabar, e a HUD avisa "Sacrifício recarregando". | `t_sacrifice_and_cycle` |
| 2 | **Soltar carta fora da janela jogava a carta** num ponto do chão que você não via (a 15–16 m do herói, fora da tela). | `--chaostest` | Soltar fora da janela ou em cima da HUD cancela o arrasto; clique fora da janela é ignorado. | `--chaostest` ("arrastar e soltar em 'fora da janela'/'abaixo da janela'/'bandeja do elixir'") |
| 3 | **Clicar na bandeja do elixir com carta selecionada jogava a carta no mundo atrás dela.** | `--chaostest` | A bandeja (sacrifício + elixir + ouro) agora segura o clique. O tempo da run continua deixando o clique passar, de propósito (é texto solto sobre o mundo). | `--chaostest` ("clique com carta em cima de 'elixir'/'bandeja do elixir'") |
| 4 | **Os modos de teste e de captura sobrescreviam a sua run salva.** O salvamento automático a cada 10 s rodava também com `--uitest`, `--routetest`, capturas etc. O `--menutest` gravava o Pacto escolhido no seu `meta.save`. E o arquivo deixado por um teste fazia o `--menutest` **pular** os passos "Salvar e voltar ao menu" e "Continuar" sem avisar. | Datas dos arquivos em `user://` depois dos testes | Com qualquer argumento de linha de comando, o jogo salva em `user://test_run.save` e `user://test_meta.save`. O `--menutest` apaga o arquivo de teste antes de começar, então os passos de salvar e continuar sempre rodam. | `--menutest` (os dois passos voltaram) e conferência de que `run.save` e `meta.save` não mudam |
| 5 | **Mão sem teto.** Pacto Sombrio (compra cartas) e Biblioteca Proibida (mão +1) não tinham limite: a mão chegava a 10+ cartas, e só existem as teclas 1 a 9. | Fuzz | Teto de 9 cartas (`Sim.HAND_MAX`). | `t_hand_cap` |

Sem bug (conferido): pausar trava cliques e teclas no mundo e na oferta; o tempo do Sim não anda na pausa; a oferta continua resolvível depois de pausar; o elixir nunca fica negativo com cliques no mesmo quadro; os altares esmagados respeitam a recarga do teleporte; o leque de cartas fica visível em todas as janelas testadas; salvar e continuar retoma a mesma run (mesmo tempo, mão e caminho); nenhum erro de script nas 100 runs do fuzz nem no `--chaostest`.

**Antes da rodada, a sua run salva e o meta foram copiados** para `C:\Users\gabri\AppData\Local\Temp\claude\…\scratchpad\run.save.bak` e `meta.save.after_tests`. O `run.save` não foi tocado (continua de 02:47). O `meta.save` já tinha sido regravado pelos `--menutest` de antes da correção (às 07:39): o efeito é o Pacto escolhido voltar para Horda. Almas e coleção não mudam com esse teste.

## Balanceamento

### Antes e depois (720 runs, 48 por bot e Pacto, mesmas sementes 5000+)

| bot | antes: Horda / Ruína / Tesouro | média | depois: Horda / Ruína / Tesouro | média |
|---|---|---|---|---|
| Heurístico (o "bot bom") | 58 / 69 / 71% | 66% | **54 / 62 / 75%** | **64%** |
| Economista | 73 / 67 / 75% | 72% | 52 / 65 / 67% | 61% |
| Enxame | 56 / 48 / 83% | 62% | 54 / 23 / 73% | 50% |
| Guloso | 50 / 48 / 60% | 53% | 44 / 50 / 44% | 46% |
| **Aleatório** | 35 / 6 / **60%** | **34%** | **10 / 6 / 21%** | **12%** |

Conferência em sementes que nenhuma etapa viu (10000+, 60 runs por célula): Heurístico 57 / 53 / 75% (62%), Economista 57%, **Aleatório 25 / 3 / 25% (18%)**.

| meta | antes | depois |
|---|---|---|
| Heurístico vence 50–65% | 66% (fora por pouco, e carregado pelo giro grátis) | 64% ✓ |
| Aleatório vence menos de 10% | 34% | 12% (18% em outras sementes) ✗ |
| Chegada à arena 660–780 s | ~812 s | ~783 s (quase) |
| Herói que chega à arena: o 3º ou o 4º (2 a 3 mortos na estrada) | 4,0 (no limite) | 3,6 ✓ |
| Pactos a menos de 5 pontos entre si (bot bom) | 13 pontos | 21 pontos ✗ |
| Nenhuma carta ganha na run em mais de 70% das vitórias | ✓ | ✓ |
| Elixir perdido abaixo de 10% | ✓ | ✓ |
| **Nota** (soma das distâncias, 0 = ideal; métricas novas) | **0,375** | **0,194** |

Relatórios: `reports/rodada_antes/`, `reports/rodada_depois/`, `reports/rodada_depois_sementes10000/` (a pasta `reports/` fica fora do git).

### Como cheguei lá

1. **Primeiro o bot de referência**, como pede a lição de 07/11: um bot "bom" fraco não separa habilidade de sorte. O explorador (algoritmo genético) achou 92% nas sementes de treino, mas só 66% nas sementes novas: estava sobreajustado. O Economista seguia como o melhor. Depois das mudanças de regra, uma segunda busca só no Tesouro achou um perfil que, nas regras novas, empata com o Economista na média e tem a menor diferença entre Pactos. Ele virou o novo `heuristic.json`. O antigo está copiado em `…\scratchpad\heuristic_antigo.json`.
2. **Telemetria por run** mostrou onde está a habilidade. **Na estrada, jogar ao acaso mata quase tantos heróis quanto jogar bem** (2 a 3,4 em todos os bots); quem separa os bots é a **arena** (o bot bom teleporta 7 a 12 vezes, o Aleatório 1 a 2). No Tesouro o Aleatório matava 3,4 heróis na estrada e 13 de 48 runs nem chegavam à arena.
3. **Alavancas medidas uma a uma** (32–40 runs por célula, ±8 pontos de ruído), classificadas entre as que separam os bots e as que só movem todos juntos:

| alavanca | bot bom | Aleatório | veredito |
|---|---|---|---|
| Herói +15% de vida e golpe | 76 → 34% | 38 → 22% | só move os dois (pior) |
| Projétil dos monstros ×1,2 → ×0,9 | 76 → 56% | 38 → 27% | só move os dois |
| **Corpo a corpo dos monstros ×2,5 → ×2,0** | 76 → 72% | 38 → **26%** (Horda 38 → 16%) | **separa** ✓ |
| Tesouro: elixir inicial 8 → 5 | Tesouro 91 → 75% | Tesouro 72 → 53% | move os dois |
| Mímico: raio de atração 10 → 6 m, ou 1 maldição | ≈ | ≈ | sem efeito |
| **Tesouro: heróis +25% de vida** | Tesouro 91 → 62% | Tesouro 72 → 47% | necessário (o Pacto só tinha vantagens) |
| **Mímico custa 4** | 62 → 65% | 23 → 18% | **separa** ✓ |
| Arqueiros DPS 8 → 6 | 62 → 51% | 23 → 16% | forte demais; **7** no meio ✓ |
| **Estrada 1500 → 1400 m** | ≈ | ≈ | só a chegada à arena (−45 s) ✓ |
| Heróis da Horda +20% / +30% de vida | ≈ / cai | ≈ | não entrou |

### O que mudou nos números

| onde | antes | depois |
|---|---|---|
| `rules.json` → `units.damage_mult` (corpo a corpo dos monstros) | 2,5 | **2,0** |
| `rules.json` → `road.target_length` | 1500 m | **1400 m** |
| `boss_lorde.json` → Tesouro | 8 de elixir, sem custo | **7 de elixir, heróis +25% de vida** (`hero_hp_mult` 1,25) |
| `cards.json` → Mímico, custo | 3 | **4** |
| `cards.json` → Esqueletos Arqueiros, DPS | 8 | **7** |
| `bots/heuristic.json` | perfil de 07/11 | melhor perfil do explorador nas regras novas |
| `rules.json` → meta `hero_level_arena` | 12–16 (nível do herói, jogo de um herói só) | **3–4** (o herói que chega à arena) |

A planilha foi atualizada nas abas Cartas de campo (Arqueiros com 75 de vida e DPS 7, já que ela ainda tinha 120/12 de antes de 07/11, e Mímico com custo 4), Deck - Pactos (regra e elixir do Tesouro) e Leia-me (resumo desta rodada). A planilha foi recalculada numa cópia pelo LibreOffice, sem nenhum erro de fórmula. O texto do Tesouro na tela dos Pactos diz "7 de elixir… mas os heróis têm +25% de vida".

## O que ficou sem resolver

1. **O Aleatório ainda vence 12–18%** (a meta é menos de 10%), sobretudo na Horda (10–25%) e no Tesouro (21–25%). A causa de fundo continua: **a estrada não premia habilidade**. Soltar monstros perto do herói ao acaso mata quase tantos heróis quanto jogar bem. Os próximos passos que eu tentaria: (a) disputas dos locais valerem mais (hoje o bot bom vence ~3 de 9 e o Aleatório ~1); (b) algo na estrada que premie posição, como o escudo frontal pesar mais contra quem ataca de frente; (c) o Mímico só atrair o herói se ele estiver no caminho dele.
2. **O Tesouro continua o Pacto mais fácil para o bot bom** (75% contra 53–62% nos outros). Apertar mais o Tesouro derrubava o bot bom tanto quanto o Aleatório.
3. **O Enxame vai mal na Ruína (23%)**: ele só joga monstros de até 3 de elixir, e na Ruína todos custam +1. É limite do perfil, não do jogo.
4. **Runs que terminam por tempo** subiram um pouco no Tesouro (Aleatório e Enxame, 5%). O replay (`headless/replay.tscn`) mostrou que não é travamento: o 4º herói tem ~4.250 de vida e se cura, e quem só joga unidades baratas não consegue mais derrubá-lo antes de 1.500 s.
5. **O `--uitest` falha às vezes com a CPU cheia** (espera fixa de 0,5 s antes da primeira tecla). Passou em todas as repetições sem carga.
6. **A planilha e o conversor continuam divergindo** em coisas de antes desta rodada: o conversor não gera `location_rewards`, os multiplicadores dos monstros nem a lista de bots. Regerar `data/` a partir da planilha ainda desfaz parte do balanceamento.

## Decisões e riscos que assumi no seu lugar

- **Branch e commits:** criei `balanceamento-2026-11-09` a partir da `main` com tudo o que estava sem commit (snapshot), e fiz um commit por assunto. Não mexi na `main` e não fiz push.
- **Capturas fora do snapshot:** `docs/visual/antes` e `docs/visual/rodada_*` (~400 MB de PNG) ficaram fora do commit para não inchar o repositório. Continuam no disco.
- **Regra nova do sacrifício** (na recarga só gira carta morta): é mudança de regra, não de número. Ela muda a sensação de "girar a mão": uma mão ruim fica até 8 s parada. Se incomodar, a alternativa é um giro barato com recarga curta, de 2 s por exemplo.
- **Tesouro com custo:** "heróis +25% de vida" foi escolha minha, no mesmo formato da Horda (+10%). Faz sentido no tema (o tesouro atrai heróis mais bem equipados), mas é decisão de design sua.
- **Corpo a corpo ×2,0** deixa todos os monstros de contato 20% mais fracos. Quem joga com Ratos sente.
- **Bot de referência trocado:** os números "Heurístico" deste relatório usam o perfil novo; o de 07/11 cai para 40% nas regras novas (ele dependia do giro grátis).
- **Meta nova "herói 3–4 na arena"**: tirei da sugestão do `docs/GRUPO_DE_HEROIS.md` ("2 ou 3 dos 5 chegam vivos à arena").
- **Não usei o computer-use:** ele pede aprovação na tela, e você estava fora. A entrada real foi injetada dentro do jogo. Por isso o comportamento do mouse físico do Windows (cursor saindo da janela durante um arrasto, por exemplo) foi simulado, não feito de verdade.
- **Arquivos de teste novos em `user://`:** `test_run.save` e `test_meta.save` aparecem na pasta de dados do jogo. Podem ser apagados.
