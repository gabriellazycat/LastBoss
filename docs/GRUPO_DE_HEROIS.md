# Grupo de heróis — mudanças para a planilha (09/11/2026)

**Estado:** implementado em 09/11/2026 a seu pedido, antes da revisão da planilha, que ainda não foi atualizada. Números em uso: herói 1 com 1700 de vida e 44 de golpe, ×1,26 por herói (a tabela abaixo é a proposta original).

## Por que

A run tinha um herói só, com uma barra de vida que voltava (nível, Fonte, Vila) e um XP que ele ganhava por causa dos seus monstros. O dano que você causava sumia, o seu nível quase não aparecia e parecia que você só ajudava o herói. Com um grupo em fila, cada morte é um marco que a cura não desfaz, e sem XP os monstros só custam elixir.

## Decisões fechadas

1. **Grupo de 5 heróis** (todos o Escudeiro por enquanto), em fila, na estrada e na arena. Vence quem matar os 5; perde se algum vencer o chefe. O limite de tempo da run segue como hoje.
2. **Arena:** o chefe mantém o dano (partes e núcleo) de um herói para o próximo.
3. **Chegada do herói novo:** ele vem andando logo atrás do que caiu, com a câmera recuando um pouco. Nunca nasce na frente da câmera. Durante a chegada, um aviso mostra a habilidade nova.
4. **Sem nenhum XP.** Acabam o XP do jogador e o XP do herói. O herói *k* tem nível *k* e *k*−1 habilidades (o 1º não tem, o 5º tem 4: o teto de 4 de 07/11 fecha sozinho).
5. **Habilidade nova:** 3 sorteadas, vale a que melhor responde ao que mais feriu o grupo (como hoje). O dano recebido soma entre os heróis.
6. **Recompensa:** cada queda dá 1 de 3 opções (carta nova, nível de carta, modificador ou remoção). Locais e contratos mantêm as ofertas de hoje. Acabam só as ofertas por nível do jogador.
7. O herói novo chega com vida e escudo cheios. Maldição e efeitos ficam no que caiu.

## Mudanças por aba

### Leia-me
- Decisão 1 ("Fora: … outros heróis") continua valendo: todos são o Escudeiro. Acrescentar a decisão nova "Grupo de 5 heróis em fila (09/11/2026)".
- Decisão 5 (XP da família do Slime) fica sem objeto.

### Problemas
- D (P2) Ninho de Morcegos e D (P5) Rei dos Ratos: a divisão de XP some.
- D (P14) Sem Testemunhas: refeito (ver Contratos).

### Base
| Linha | Hoje | Muda para |
|---|---|---|
| XP do herói por ponto de elixir que morre; XP para o nível 2; crescimento do XP por nível; Fração do elixir em unidades que morrem; XP total entregue na fase 1; XP acumulado até o nível 15 | 20 / 100 / 0,15 / 0,75 / fórmulas | **Saem** |
| Level-ups do jogador desejados; crescimento do dano por nível do jogador; dano para o 1º level-up | 10 / 0,15 / fórmula | **Saem** |
| Vida do Escudeiro no nível 1; Vida no nível 14 (chegada típica) | 1500 / fórmula | Vida do herói 1 e passo por herói (ver abaixo) |
| Crescimento da vida do herói por nível | 0,08 | Passo de força por herói (abaixo) |
| *(nova)* Heróis no grupo | — | 5 |
| *(nova)* Segundos de chegada do herói novo | — | 8 |
| *(nova)* Opções da recompensa de queda | — | 3 |
| Elixir, duração da fase 1 (720 s), dano por ponto de elixir (70), velocidade, escudo | — | Sem mudança |

> A planilha diz vida 1500 e golpe 40; o jogo usa 3364 e 52 desde o balanceamento do bot. Convém acertar a planilha com o que o jogo realmente usa.

**Números novos (propostas minhas, para o bot ajustar em até ±30% por ciclo).** Ponto de partida: a soma da vida dos 5 heróis fica perto dos ~18 a 20 mil de dano que a planilha prevê hoje na fase 1 (`ARQUITETURA.md`). O passo de ×1,28 vem de 8% por nível ao longo de ~13 níveis (≈ ×2,7) divididos em 4 passos.

| Herói | Nível | Habilidades | Vida (×1,28) | Golpe (×1,28) |
|---|---|---|---|---|
| 1 | 1 | 0 | 2.300 | 52 |
| 2 | 2 | 1 | 2.940 | 67 |
| 3 | 3 | 2 | 3.770 | 85 |
| 4 | 4 | 3 | 4.820 | 109 |
| 5 | 5 | 4 | 6.170 | 140 |

### Upgrades
- **Segundo Fôlego:** "uma vez por run" vira **"uma vez por herói"** (cada herói é um corpo novo; senão só o primeiro usaria).
- As outras 14 não mudam. A coluna "Counter de" continua sendo o critério de escolha, agora somando o dano de todos os heróis.

### Contratos
- **Sem Testemunhas** ("causar 200 de dano sem o herói ganhar XP"): sem XP o objetivo perde o sentido. Proposta: **"causar 200 de dano sem perder nenhum monstro"**, prazo 40 s, mesma recompensa (carta de finalização).

### Decks (antiga) e Deck - Pactos
- **Horda:** "o herói ganha +10% de XP" vira **"os heróis têm +10% de vida"** (proposta; o preço da mão de 6 cartas continua existindo).
- **Ruína:** sai "XP passivo do herói ×2". Fica "feitiços +15% de dano; monstros custam +1". O bot mede se ficou forte demais.
- **Tesouro:** "level-ups oferecem 2 opções" vira **"a recompensa de queda tem 4 opções"** (em vez de 3).

### Deck - Regras
- "Ofertas por nível do jogador: níveis pares" sai. Entra **"Ofertas por queda de herói: toda queda, 3 opções; toda escolha pausa; pode recusar"** (5 por run).
- "Bônus extra por vitória antecipada (herói morre na estrada)" passa a valer quando **os 5 caem antes da arena**.
- "Taxa de vitória de referência: 0,47" e "Dano típico no herói por run" são refeitos no primeiro lote depois da mudança.

### Deck - Locais
- **Santuário:** hoje, se você perde, "o herói ainda ganha os 80 de XP". Proposta A (a que recomendo): **perder só reduz a recompensa (3 → 1), sem penalidade extra**. Proposta B: perder dá ao herói uma bênção (escudo cheio e +20% de dano por 20 s).
- Círculo de Ritual, Vila, Taverna, Fonte Sagrada e Ponte: sem mudança.

### Cartas de campo
- A coluna **"XP ao herói por unidade"** sai, junto das notas D (P2), D (P5) e D5.
- **Isca de Ouro** (`gold_bait`, desvio de até 30 m): hoje dá 40 de XP ao herói. Proposta: **fica só como desvio** (o herói perde tempo indo até ela). O bot mede se ainda vale 2 de elixir.
- O custo em XP das cartas caras (`cost_exp` = 0,7) acaba: monstro caro passa a custar só elixir. Convém conferir Ogro e Golem de Sucata no primeiro lote.

## Fora da planilha (comportamento e tela)
- Intervalo da chegada: 8 s (valor a testar jogando). A caminhada começa depois que você escolhe a recompensa, porque as ofertas pausam o jogo como hoje.
- A câmera recua o suficiente para o herói novo aparecer vindo de trás, nunca do nada na frente dela.
- A barra de XP do herói vira **"Herói 2 de 5"**, ao lado da fileira de habilidades. A barra "Seu poder" e o nível do jogador saem da tela, do resultado e das dicas.
- A habilidade nova aparece em um aviso durante a chegada.

## O que muda no código (só depois da planilha aprovada)
- `sim/sim.gd`: `hero` única vira fila de heróis (`sim.hero` aparece em 81 pontos de 13 arquivos). `_check_end` (linhas 340–346) passa para o próximo herói e só vence com a fila vazia. Saem `hero_gain_xp` e suas chamadas (treino passivo, Santuário, morte de unidade, Isca, custo em XP) e o XP do jogador em `damage_hero` e `_player_next`.
- `sim/hero.gd`: sai `xp`, `xp_needed` e `level_up`. O nível vem do índice do herói e `second_used` passa a ser por herói.
- `game/hud.gd`, `game/world_view.gd`, `game/audio.gd`: os eventos `HERO_LEVEL` e `PLAYER_LEVEL` viram a chegada do herói. HUD, dicas e textos mudam, mais o recuo da câmera.
- `bots/player_bot.gd` e `data/bots/*.json`: o parâmetro `xp_aversion` (heurístico 2,26, economista 0,5, enxame 0) sai do perfil e do explorador. O bot passa a escolher a recompensa de queda.
- `data/rules.json` (`hero_xp`, `player_xp`, `offers.level_every`, `locations.shrine.hero_xp`), `hero_escudeiro.json`, `boss_lorde.json` (`hero_xp_mult`, `hero_passive_mult`), `cards.json` (`gold_bait`), `contracts.json` e `tools/xlsx_to_json.py`.
- `sim/save_game.gd`, `tests/tests.gd` e `tools/run_batch.py` (as metas "herói chega à arena no nível 12–16" e "nível do jogador" saem).

## Riscos
1. **A curva pode ficar pesada nos últimos heróis.** Cada herói é ~28% mais forte, e o deck cresce só com 5 quedas, os locais e os contratos. Os lotes dos bots mostram.
2. **Monstros caros ficam mais baratos de usar.** Sem a penalidade de XP, eles podem dominar.
3. **Os 47% de vitória e as metas atuais deixam de valer.** O primeiro lote depois da mudança serve de nova referência.
4. **Muita coisa na tela ao mesmo tempo:** a oferta de recompensa e o aviso da habilidade logo depois da queda.

## Perguntas só suas (comentário na planilha)
1. Santuário: proposta A (sem penalidade) ou B (bênção)?
2. Quantos heróis devem chegar vivos à arena com o bot bom? Minha sugestão: 2 ou 3 dos 5, para a arena ser uma parte relevante da run.
3. "Sem Testemunhas" com o objetivo "sem perder nenhum monstro" serve?
4. Pacto Horda com "+10% de vida dos heróis" serve?
