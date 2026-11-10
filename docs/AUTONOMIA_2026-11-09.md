# Rodada autônoma de 09/11/2026 (usuário fora, autonomia total)

Pedido: famílias de cartas e combos, toda a arte (monstros e cenário no Blender, heróis KayKit), personagens (Arqueira, Clériga, Mago), campanha com fases e tutorial e, no fim, uma super rodada de testes de balanceamento e bugs. Sem perguntas ao usuário.

Branch de trabalho: `campanha-combos` (checkout principal). A arte está numa sessão separada, no worktree dela; o merge é feito no fim.

## Progresso (atualizado a cada etapa; a retomada automática lê daqui)

Status: CONCLUÍDO
Última atualização: 2026-11-10 04:10

- [x] 1. Mapear cartas, decks, heróis e menu no código
- [x] 2. Famílias de cartas, combos e pactos novos
- [x] 3. Classes Arqueira, Clériga e Mago (KayKit)
- [x] 4. Campanha: fases 0 (tutorial) a 4 (grupo que levanta o caído)
- [x] 5. Integrar a arte da sessão "Refazer monstros e cenário no Blender" (branch dela)
- [x] 6. Super rodada de testes, balanceamento e bugs
- [x] 7. Merge na main e relatório final

## Decisões assumidas no lugar do usuário

**Cartas e combos**
1. **18 cartas novas em 5 famílias**, um pacto por família. O deck inicial (Horda) é só de Bando.
   - **Bando (Horda):** Ratos Raivosos (+4% de dano por bicho de Bando em campo, até +100%), Chamado do Bando (Bando +50% de velocidade e de dano por 6 s) e Toca de Ratos (solta um rato a cada 1,5 s).
   - **Fogo (Ruína):** Balde de Óleo (encharca o herói por 1 de elixir), Tocha (no herói encharcado, ele pega fogo), Diabretes de Fogo e Rede de Piche (prende e encharca). O pacto perdeu o "monstros custam +1".
   - **Cobiça (Tesouro):** Mercenário Goblin (+15% de vida e dano a cada 25 de ouro guardado), Pedágio (30 de ouro viram 3 de elixir) e Moedas Amaldiçoadas (o herói para para catar e leva maldições). O Mímico morde em dobro perto da Isca de Ouro.
   - **Morte (Cripta, pacto novo):** Legião de Ossos (5 esqueletos baratos), Carniçal (+15% de dano a cada morte sua por perto), Explosão de Cadáver (explode um monstro seu) e Colheita de Almas (cada morte devolve elixir por 10 s).
   - **Sequência (Culto, pacto novo):** Faísca Arcana (+45 de dano por feitiço jogado nos últimos 6 s), Eco Sombrio (repete o último feitiço), Acólitos (atiram junto quando você joga um feitiço) e Marca Sombria (+40% de dano de feitiço).
2. **Combos explicados só no texto da carta**, como você pediu: nada de aviso nem brilho na tela.
3. **Arte das cartas novas:** cada uma usa o modelo 3D e o desenho de uma carta parecida (campos `model` e `art` em `data/cards.json`). Exemplos: Ratos Raivosos usam o rato e o Carniçal usa o lobisomem no desenho. Modelos próprios ficam para depois.
4. **Liberação:** a coleção inicial ganhou as cartas da Horda nova. Cada pacto liberado traz as cartas do deck dele para a coleção.

**Campanha** (`data/campaign.json`)
5. **Fases:**
   - **0 · Tutorial:** 3 Escudeiros com 40% da vida e 55% do golpe, 1 ato, deck da Horda.
   - **1 · Os Escudeiros:** a run de antes, com 7 Escudeiros.
   - **2 · A Patrulha:** Escudeiro e Arqueira se alternam.
   - **3 · A Cruzada:** Clérigas, Escudeiros e 1 Arqueira.
   - **4 · A Companhia:** 6 heróis de 4 classes, com 80% da vida, e o grupo que se levanta.
6. **Desbloqueios:** cada vitória libera a fase seguinte e um pacto: fase 1 → Ruína, 2 → Tesouro, 3 → Cripta, 4 → Culto. Num jogo novo, a tela do grupo já começa no tutorial.
7. **Classes** (`data/hero_classes.json`):
   - **Arqueira:** 72% da vida, alcance de 7 m e sem escudo.
   - **Clériga:** se cura 1,2% da vida por segundo e, ao cair, dá +25% de vida ao próximo herói.
   - **Mago:** 68% da vida, golpe que explode em 2,6 m e ataque lento.
   - Todas usam as mesmas 15 habilidades do Escudeiro.
8. **Fase de grupo:** cada queda traz o próximo da fila, que levanta o caído com 50% da vida (uma vez por herói). Quando a fila acaba, um seguidor vira o herói da vez. Você vence quando não sobra ninguém de pé.
   - Os seguidores andam em formação perto do líder e podem sair para bater num monstro.
   - Os monstros vão no herói mais perto, e a explosão do Goblin acerta todos no raio.
9. **Tutorial:** 10 caixas que pausam o jogo na hora certa: início, como jogar, combo do Bando, Chamado, escudo, sacrifício, locais, queda do herói, arena e fim. Tem o botão "Pular tutorial".

**Arte**
10. **A direção G · Blender v2 virou a padrão.** Ela traz monstros, chefe e cenário feitos no Blender, com os heróis da KayKit. A configuração salva migra uma vez, e a D continua em Configurações → Visual. Detalhes e FPS em `docs/ARTE_BLENDER.md`.
11. **Modelos das classes:**
    - Arqueira: Ladino com capuz da KayKit, com besta.
    - Mago: Mago da KayKit, com cajado.
    - Clériga: o mesmo Mago, com tom dourado, livro aberto e sem cajado.

## Riscos

- **Seguidores e feitiços:** Tocha, Faísca Arcana, Explosão de Cadáver e a explosão do Goblin acertam todos os heróis no raio. Os outros feitiços e as zonas (óleo, teia, raio) ainda acertam só o herói da vez.
- **A barra de vida da HUD é só do líder.** Os seguidores aparecem como "N de pé" e no mundo.
- **Classes sem habilidades próprias:** todas sorteiam as mesmas habilidades do Escudeiro.
- **Arte emprestada:** as cartas novas usam modelos e desenhos de cartas parecidas.
- **Planilha sem as cartas novas:** ela não recebeu as cartas nem a campanha. Os números estão nos JSON.
- **Testes com janela:** o tutorial e a tela da campanha foram conferidos por captura, não com cliques reais.

## Super rodada de testes e balanceamento (10/11/2026)

**Testes**
- **Automáticos:** `tests/tests.gd` passa com 0 falhas, incluindo os novos de combos, classes, fase de grupo e salvar e continuar na fase de grupo.
- **Fuzz:** `headless/fuzz.tscn`, 160 runs com decks malucos nos 5 pactos e nas 5 fases, 0 falhas. Ele achou um bug antigo: a mão ficava menor que o tamanho quando uma oferta removia uma carta dela. Corrigido.
- **Capturas olhadas uma a uma** (`docs/visual/campanha/`): menu de pactos e fases, tutorial, fase de grupo, Arqueira e Clériga, arena e resultado na direção G.

**Bugs achados e corrigidos na rodada**
- Morte contada duas vezes na Explosão de Cadáver.
- Eco Sombrio repetia o Pedágio sem ouro.
- O número de dano aparecia no líder quando o golpe acertava um seguidor.
- Seguidores se afastavam 30 a 80 m do grupo.
- Arte das cartas novas em branco no Diário.
- A regra "monstros custam +0" aparecia na tela.
- A Explosão de Cadáver travava a mão quando não havia monstro perto (achado olhando uma captura). Agora ela levanta 3 esqueletos.
- A mão não completava quando a Biblioteca Proibida pedia carta com o baralho vazio.

**Balanceamento** (bot heurístico; `tools/tune_campaign.py` mexe na vida dos heróis por pacto e por fase)

| Fase | Horda | Ruína | Tesouro | Cripta | Culto |
|---|---|---|---|---|---|
| 0 tutorial | 100% | – | – | – | – |
| 1 | 56% | 57% | 53% | 54-58% | 56% |
| 2 | 47-55% | 60-68% | 48-60% | 40-65% | 40-48% |
| 3 | 52-67% | 30-36% | 50-53% | 55-65% | 23-35% |
| 4 | 20-22% | 50-57% | 28-33% | 38-47% | 50-60% |

As faixas são de lotes com 30 a 72 runs (margem de uns ±8%). Lote final: `reports/20261110-035609/report.md`.

**Mudanças de número**
- **Vida dos heróis por pacto:** Horda 0,62; Ruína 0,79; Tesouro 0,74; Cripta 0,64; Culto 1,03.
- **Vida por fase:** 2 → 1,1; 3 → 0,99; 4 → 0,77.
- **Morte:** Carniçal 330 de vida e 16 de DPS, +20% por morte; Legião com 6 esqueletos de 75 de vida; Explosão 3,5× a vida (mínimo 130); Colheita com 0,5 de elixir por morte.
- **Fogo:** Tocha com 95 de dano e queima de 35/s; Diabretes com 85 de vida e 15 de DPS; Balde de Óleo encharca por 10 s.
- **Classes:** Clériga com 0,6%/s de cura e escudo de 120; Mago com 50% de dano na explosão.
- **Fase de grupo:** formação a 3,6 m. Feitiço de área no grupo dá o dano inteiro no herói mais perto e metade nos outros. A fase 4 tem 1 Mago só.

**Riscos que ficaram**
- **O bot aleatório vence 27 a 46% na fase 1.** A meta antiga era 10%: baixar a vida dos heróis para equilibrar os pactos fracos facilitou para todos.
- **Contras fortes por fase:** Horda vai mal na fase 4 (enxame contra grupo; o texto da fase avisa). Ruína e Culto vão mal na fase 3 (Clérigas).
- **Tesouro na fase 3 ainda estoura o tempo** (40 min) em parte das runs do bot aleatório.
