# Mapa de rotas escolhidas — mudanças para a planilha (09/11/2026)

**Estado:** decidido com você no grilling de 09/11/2026 e **implementado no mesmo dia**, a seu pedido, com autonomia total e sem a revisão da planilha (você estava fora). As decisões que tomei no seu lugar estão em "Decisões tomadas no seu lugar" no fim deste arquivo. Os números são propostas minhas, para o bot ajustar.

## Por que

Com o grupo de 5 heróis, as recompensas de queda são só 4 (a 5ª queda acaba a run). Os locais da estrada passam a ser a fonte principal de crescimento do deck. Hoje o herói escolhe sozinho o ramo nas bifurcações (e Ponte Quebrada/Placa Falsa são o único jeito de interferir), e dois locais (Vila e Fonte) ajudam o herói curando-o. Com a mudança, **você monta a rota** e **todo local é bom para você**.

## Decisões fechadas

1. **Mapa em rede, como um mapa de nós:** caminhos que se abrem e se reencontram, sem bifurcação em todo ponto. Cada rota completa passa por **8 a 10 pontos de interesse** (Santuários inclusos).
2. **Mapa inteiro visível desde o início**, com o tipo de cada local.
3. **Você escolhe o ramo** a qualquer momento, clicando no mapa grande. Se não tiver escolhido quando o herói chega à bifurcação, o jogo pausa e pergunta. A IA do herói não escolhe mais ramo.
4. **Os ramos não escolhidos aparecem bloqueados** no mundo (barricada, desabamento).
5. **Todas as rotas têm o mesmo comprimento:** a escolha não muda a hora da chegada à arena.
6. **A escolha do ramo é pelo tipo de prêmio:** nenhum ramo tem coisas ruins para você.
7. **As disputas continuam** (vence = 3 opções, perde = 1), mas **nenhum local ajuda o herói**.
8. **Vila vira Loja**, rara: 1 a 2 por mapa, em ramos diferentes. A Loja pausa o jogo como as ofertas. A disputa dela dá 30% de desconto.
9. **Fonte** para de curar o herói e passa a **curar as suas unidades** perto dela. A guarda (monstro seu perto quando o herói chega) continua dando a remoção de carta.
10. **Ritual, Ponte, Taverna e Santuário ficam como estão** (já favorecem você). **Santuário perdido só reduz a recompensa** (3 → 1), sem o XP que ele dava ao herói (proposta A do doc do grupo).
11. **Ouro**, moeda nova só dentro da run: vem do dano no herói e das disputas vencidas; zera ao fim da run. As Almas continuam sendo a moeda da coleção.
12. **Ponte Quebrada e Placa Falsa saem do jogo.** Uma carta comum que já existe entra no lugar da Ponte Quebrada na coleção inicial e nos decks prontos da Horda e da Ruína. Quem escolhe é o lote dos bots (te mostro antes).
13. **Queimar Vila** passa a mirar qualquer local da rota escolhida e mantém o dano de fogo.
14. **Tela:** o mapa de nós fica no mapa grande (M), que abre sozinho perto de uma bifurcação; a faixa lateral mostra a rota escolhida.
15. **Bots primeiro:** antes de qualquer balanceamento, os bots aprendem a escolher a rota, comprar na Loja e vencer as disputas (hoje vencem ~1,4 de 8).

## Mudanças por aba

### Leia-me
- Nova seção "Mapa de rotas (09/11/2026)" apontando para as abas `Mapa - `.

### Mapa - Regras (nova)
| Parâmetro | Proposta | Nota |
|---|---|---|
| Pontos de interesse por rota | 8 a 10 | Decidido |
| Santuários por rota | 2 a 3 | Proposta (hoje 2 a 4 somados por fora) |
| Lojas no mapa | 1 a 2, em ramos diferentes | Decidido |
| Fileiras do mapa (entre o início e o covil) | 9 | Proposta: uma fileira por ponto de interesse; cada fileira tem 2 ou 3 nós |
| Ligações por nó | 1 ou 2 para a fileira seguinte | Proposta: dá ramos que se abrem e se reencontram; nunca dois caminhos se cruzam |
| Distância entre pontos | ~150 m (~50 s de caminhada) | Fórmula: estrada de 1500 m ÷ 10 trechos |
| Pausa ao chegar numa bifurcação sem escolha | Sim | Decidido |
| Ouro por dano no herói | 1 a cada 40 de dano | Proposta: ~460 de ouro numa run típica (18 mil de dano, a estimativa da aba Base) |
| Ouro por disputa vencida | 25 | Proposta: ~5 vencidas = 125 |
| Ouro ao fim da run | Zera | Decidido |

### Mapa - Locais (nova; substitui a aba Deck - Locais)
| Local | Peso | O que faz | Disputa | Venceu | Perdeu |
|---|---|---|---|---|---|
| Santuário | 2 a 3 por rota | Contagem de 10 s | Monstro seu no raio quando a contagem acaba | 3 cartas raras+ | 1 carta rara+ (sem XP ao herói) |
| Círculo de Ritual | 2 | Seu elixir ×2 com o herói dentro | O círculo sobreviver (300 de vida) | Sobe 1 entre 3 cartas | Sobe 1 sorteada |
| Taverna | 2 | Herói ataca 40% mais devagar por 15 s | 150 de dano nesses 15 s | 3 modificadores | 1 modificador |
| Ponte | 2 | Coleira de 1,5 m e +50% de dano dos bandos | 200 de dano na ponte | Escolha livre, 1 entre 3 | 1 carta comum |
| **Fonte** | 2 | **Por 15 s depois que o herói chega, cura 5% da vida máx./s das suas unidades a até 8 m** | Monstro seu a até 6 m quando o herói chega | Remove qualquer carta | Remove 1 entre 2 sorteadas |
| **Loja** (era a Vila) | 1 a 2 por mapa | Abre a tela da Loja quando o herói sai do raio (7 m); pausa o jogo | **150 de dano enquanto o herói está no raio** | **30% de desconto** | Preço cheio |

### Mapa - Loja (nova)
| Item | Preço (ouro) | Quantos aparecem |
|---|---|---|
| Carta comum | 50 | 3 cartas sorteadas (raridade pela tabela de tempo) |
| Carta incomum | 75 | |
| Carta rara | 120 | |
| Carta lendária | 180 | |
| Subir o nível de uma carta | 75 | 1 |
| Modificador | 60 | 1 |
| Remover uma carta | 50 | 1 (preço sobe 25 a cada uso na run) |

Com ~585 de ouro numa run típica, dá para comprar ~7 itens a preço cheio (~10 com desconto), divididos entre as 1 ou 2 lojas da rota. Pode ser muito: se for, o primeiro botão é o dano por ouro (40 → 60). Cada item comprado some da Loja, e cada Loja tem o seu próprio sorteio (proposta).

### Rota e Covil
- **Ponte Quebrada** e **Placa Falsa**: saem.
- **Queimar Vila**: o efeito vira "Escolha um local da rota escolhida; quando o herói passa por ele, queima por X s" (mesmo dano de fogo de hoje). O nome pode ficar ou virar "Incêndio" (pergunta abaixo).
- **Isca de Ouro**: sem mudança de regra (só desvio, como no doc do grupo).

### Deck - Locais
- Toda a aba fica marcada como substituída pela **Mapa - Locais**.

### Deck - Coleção
- Ponte Quebrada e Placa Falsa saem (32 → 30 cartas). A coleção inicial perde a Ponte Quebrada e ganha a carta escolhida pelo lote.

### Deck - Pactos
- Horda e Ruína: a Ponte Quebrada sai do deck pronto; entra a substituta.

### Deck - Regras
- "Almas por local por onde o herói passou": sem mudança (2).
- "Locais por onde o herói passa numa run típica" = 9: sem mudança.

## Fora da planilha (comportamento e tela)
- O mapa grande (M) desenha a rede: nós por tipo de local, ligações, o caminho já percorrido, o escolhido destacado e os bloqueados apagados. Clicar num nó da fileira seguinte escolhe o ramo.
- No mundo 3D, os ramos não escolhidos ficam bloqueados por uma barricada na entrada.
- A faixa lateral mostra só a rota escolhida (e os trechos ainda abertos à frente).
- O ouro aparece na HUD perto do elixir.

## O que muda no código (só depois da planilha aprovada)
- `sim/road.gd`: a geração em pernas (`single`/`fork` de 2 ramos) vira uma rede por fileiras com o mesmo comprimento em todas as rotas. `next_fork_index`, `closed` e `forced` mudam.
- `sim/sim.gd`: `_road()` deixa de chamar `hero.choose_branch`; entra o comando `route` do jogador (já existe na lista de comandos) e a pausa na bifurcação. Vila → Loja (`_resolve_location`, `_offer_location`), Fonte nova, Santuário sem XP, ouro, oferta de loja. Saem `broken_bridge` e `false_sign` (linhas 735 e 890).
- `sim/hero.gd`: sai `choose_branch`.
- `bots/player_bot.gd`: sai a lógica das duas cartas (linha 276); entra a escolha de rota, a compra na Loja e o jogo pelas disputas.
- `game/minimap.gd` (mapa de nós), `game/route_strip.gd`, `game/world_view.gd` (barricadas, Loja no lugar da Vila), `game/hud.gd` (ouro, linha 684), `game/art/models.gd` (sai o modelo das duas cartas).
- `data/rules.json` (`road`, `locations`, `location_rewards`, ouro, loja), `data/cards.json`, `data/meta.json`, `data/boss_lorde.json`, `locale/strings.csv`, `tools/xlsx_to_json.py`, `sim/save_game.gd` (ouro e rota), `tests/tests.gd`.

## Riscos
1. **A escolha "só pelo tipo de prêmio" pode virar automática:** se um tipo de local for sempre melhor (ex.: Santuário), a rota ótima é sempre a mesma. O lote dos bots mostra quais locais as rotas vencedoras usam.
2. **O deck pode crescer demais:** 8 a 10 locais com recompensa + Loja + 4 quedas + contratos. Recusar continua possível, e a remoção na Loja ajuda.
3. **O ouro reaproxima "dano rende algo"**, que saiu com o XP. Se a Loja ficar forte, a run vira acumular dano para comprar.
4. **Sem a cura da Vila e da Fonte, o herói perde sustentação** na estrada; os heróis podem cair cedo demais. O primeiro lote mede.
5. **Duas cartas a menos na coleção** muda as Almas para desbloquear tudo (a Placa Falsa custava 70).

## Perguntas que respondi no seu lugar (você estava fora; confira e mude se quiser)
1. **Os 8 a 10 pontos são por rota.** O mapa tem 2 a 3 nós por fileira (~22 nós), e cada caminho passa por um nó de cada fileira.
2. **Queimar Vila virou "Incêndio"** (en: Wildfire). O id interno continua `burn_village`, para não quebrar coleções salvas.
3. **Preços e ouro da aba Mapa - Loja** entraram como estão.
4. **Fonte: 5% da vida máxima por segundo, por 15 s, a até 8 m.**

## Decisões tomadas no seu lugar (09/11/2026, implementação)
- **A primeira escolha é logo no começo:** o início da estrada já se divide em 2 ou 3 ramos, então a run abre com o mapa e o jogo pausado. O aviso "Bifurcação" explica.
- **O mapa grande virou um esquema** (fileiras de baixo para cima, pistas lado a lado), e não a estrada em escala. A estrada real tem 1,5 km por ~80 m, e desenhada em escala as escolhas viravam uma linha fina ilegível. O mapa abre sozinho quando o herói para numa bifurcação e fecha quando ele volta a andar. Ele vai até perto da borda de baixo, por cima do leque de cartas.
- **Como escolher:** clicar num local à frente, no mapa ou na faixa, planeja o caminho até ele (todas as bifurcações no meio). Na bifurcação, as teclas 1, 2 e 3 escolhem da esquerda para a direita; no controle, L1/R1 trocam e A confirma. Dá para mudar o plano enquanto o herói não passou da bifurcação.
- **Barreira:** cerca, pedras e tronco seco na entrada de cada ramo não escolhido, onde ele já se afastou do ramo escolhido. O ramo fechado fica transparente. Os ramos que ficaram inalcançáveis só ficam transparentes.
- **Ramos de uma fileira para a seguinte:** cada nó liga a 1 ou 2 nós da fileira seguinte (vizinhos); as ligações nunca se cruzam. O comprimento igual vem de ondas laterais suaves na estrada mais curta.
- **Nós da mesma fileira têm tipos diferentes**, para a escolha ser sempre "qual prêmio".
- **Santuários:** a geração procura um mapa em que toda rota passe por 2 ou 3. Em 30 mapas de teste, 7,5% das rotas ficam fora (1 ou 4).
- **Lojas:** nunca duas na mesma rota; ficam a partir da 3ª fileira.
- **Ouro:** conta o dano no herói e o absorvido pelo escudo (como as Almas) e aparece ao lado do elixir. A remoção na loja encarece 25 a cada compra na run.
- **Loja:** abre quando o herói sai do raio. Carta e modificador saem na hora. "Subir nível" e "Tirar carta" abrem a escolha da carta e só cobram quando você escolhe; voltar não cobra. "Sair da loja" é o 0, o B ou o botão.
- **Incêndio:** marca um local ainda à frente no caminho; quando o herói entra nele, o local pega fogo (40 de dano por segundo por 10 s, no raio do local). A carta só pode ser jogada se houver local à frente.
- **Ritual:** o herói só mira círculos do próprio caminho (antes ele podia atacar um círculo de outro ramo próximo).
- **Substitutas da Ponte Quebrada:** coleção inicial → **Incêndio** (a rota continua com 2 cartas desde a 1ª run); deck pronto da Horda → **Óleo Fervente**; da Ruína → **segunda Teia**. Escolhidas pelo lote (abaixo). O Goblin extra na Ruína custava 4 (monstros +1) e o Heurístico nunca jogava.
- **Bots:** o aleatório e o guloso sorteiam o ramo; os "smart" escolhem o caminho que soma mais valor (Santuário 5, Ritual 4, Loja 3,5 + ouro/150, Fonte 2,5 + deck grande, outros 3). Eles guardam elixir antes de Taverna, Ponte e Loja, põem monstros de guarda na Fonte e no Ritual e compram o item que mais vale pelo preço. Parâmetros novos no explorador: `contest_reserve`, `contest_lookahead`, `gold_value`, `route_shrine`, `route_shop`, `route_ritual`.
- **Salvamento da run:** ganhou versão (2). Um salvamento antigo, de antes do mapa novo, não carrega: o Continuar volta ao menu e apaga o arquivo. A coleção salva perde Ponte Quebrada e Placa Falsa sem devolver Almas (quem tinha desbloqueado a Placa Falsa perde 70).
- **Testes de janela e capturas** seguem o primeiro ramo sozinhos; `--routewait=1` faz esperar a escolha, e `--routetest=1` testa a escolha com a entrada real.

## Resultado do lote (reports/route_final/report.md, 720 runs, 5 bots, sementes 2000+)
| bot | Horda | Ruína | Tesouro |
|---|---|---|---|
| Heurístico | 48% | 48% | 69% |
| Economista | 69% | 67% | 77% |
| Enxame | 50% | 48% | 69% |
| Guloso | 48% | 62% | 71% |
| Aleatório | 29% | 12% | 54% |

- Heurístico na média: 55%, dentro da meta (50–65%). O Aleatório (32%) continua muito acima da meta (<10%), puxado pelo Tesouro, como antes da mudança.
- Os bots ainda perdem a maioria das disputas (Heurístico ~3 de 9) e quase não compram (0,6 a 1,3 itens por run com 400–700 de ouro). Uma pessoa deve ganhar mais disputas e comprar mais que o bot.
- Chegada à arena entre 600 e 990 s. A meta "herói chega no nível 12–16" não vale mais desde o grupo de heróis e continua na nota (falta refazer as metas).

## Riscos novos
- **A pausa no começo da run** pode estranhar: a primeira coisa é escolher o caminho.
- **O mapa grande cobre o leque de cartas** quando está aberto. Ele fecha sozinho depois da escolha.
- **A estrada visível ficou mais larga e cheia:** ~50 ligações em vez de 8 trechos. A grama ganhou um teto por célula (não dobra onde duas faixas se encontram) e as lanternas ficaram a cada ~56 m (eram 38). Com 500 unidades, a comparação na mesma sessão deu 40 FPS com a rede contra 34 com uma estrada única (mesmo código, `lanes` = 1): a rede não pesa mais. Os valores absolutos variaram de 34 a 53 FPS entre execuções nesta máquina carregada, então não dá para comparar com os 90 FPS de 06/11.
- **Duas estradas lado a lado se sobrepõem perto dos nós** (as ligações saem do mesmo ponto); fica um trecho de calçamento largo.
- **A planilha e o conversor:** as abas Mapa - têm os números em uso. O `xlsx_to_json.py` gera a estrada e as lojas novas, mas não gera `location_rewards` (já não gerava antes).
