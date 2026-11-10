# Rodada autônoma de 09/11/2026 (usuário fora, autonomia total)

Pedido: famílias de cartas e combos, toda a arte (monstros e cenário no Blender, heróis KayKit), personagens (Arqueira, Clériga, Mago), campanha com fases e tutorial e, no fim, uma super rodada de testes de balanceamento e bugs. Sem perguntas ao usuário.

Branch de trabalho: `campanha-combos` (checkout principal). A arte está numa sessão separada, no worktree dela; o merge é feito no fim.

## Progresso (atualizado a cada etapa; a retomada automática lê daqui)

Status: EM ANDAMENTO
Última atualização: 2026-11-10 03:33

- [x] 1. Mapear cartas, decks, heróis e menu no código
- [x] 2. Famílias de cartas, combos e pactos novos
- [x] 3. Classes Arqueira, Clériga e Mago (KayKit)
- [x] 4. Campanha: fases 0 (tutorial) a 4 (grupo que levanta o caído)
- [x] 5. Integrar a arte da sessão "Refazer monstros e cenário no Blender" (branch dela)
- [ ] 6. Super rodada de testes, balanceamento e bugs
- [ ] 7. Merge na main e relatório final

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
