# Decisões — Last Boss

Registro das decisões tomadas fora do GDD. O conteúdo das cartas e os 12 problemas resolvidos estão em `Revisao do conteudo - Last Boss.xlsx` (abas Leia-me e Problemas).

## Projeto (06/11/2026)

- Escopo: o MVP inteiro do GDD. Ficam de fora meta-progressão, outros chefes e heróis, níveis de dificuldade e Steam.
- Ordem: a run completa (estrada → arena) fica jogável cedo, com peças cinzas. A arte do Blender é feita em paralelo e vai substituindo essas peças. Você joga a cada marco.
- Godot 4.7.2 nesta pasta, com git local. GitHub depois.
- Downloads de ferramentas e assets estão liberados. Os scripts de terceiros são lidos antes de rodar.

## Menu e HUD (06/11/2026)

Decisões que tomei no seu lugar (você deu carta branca no design):
- **Menu:** título à esquerda sobre o covil 3D, com Continuar (só se houver run salva), Nova run, Configurações e Sair. A escolha de deck virou uma tela própria com a arte das 6 cartas e as regras.
- **HUD:** o herói é a informação principal (vida grande no centro do topo, com a XP dele fina embaixo, porque cada XP que ele ganha é culpa sua). O seletor de idioma e o contador de FPS saíram da tela de jogo e foram para as configurações; o FPS fica desligado por padrão.
- **Elixir em gomos** (um por ponto). Os gomos que a carta selecionada vai gastar piscam.
- **Pausa** com menu (Continuar, Configurações, Salvar e voltar ao menu, Salvar e sair) e o deck em miniaturas. **Perder o foco da janela pausa a run.**
- **Ofertas** mostram as cartas desenhadas, como na mão, em vez de botões de texto.
- **Resultado** em tela própria: título, 8 números e os botões Nova run (vai direto para a escolha de deck) e Menu principal.
- **Idioma padrão: português**, como era antes. **Tamanho da interface: 80–115%**; acima disso a HUD do topo se sobrepõe a 16:9.
- **Fonte dos títulos:** a serifada do sistema (Georgia no Windows). Se ela não existir, o jogo usa a fonte padrão. Risco: em outro sistema, os títulos podem ficar diferentes. Para fixar o visual, falta incluir uma fonte própria no projeto.
- **Faixa de rota na vertical, na borda esquerda** (pedido seu): o início fica embaixo e o covil em cima, como o herói anda na tela; os ramos das bifurcações se abrem para os lados e os textos ficam à direita da faixa.
- **Sem alcance máximo** (pedido seu): a carta vale em qualquer ponto do chão que aparece na tela; só fica a distância mínima de 3 m do herói (feitiços continuam ignorando até ela). O anel roxo de 12 m saiu. O bot aleatório continua soltando a até 12 m para não mexer no balanceamento.

## Bot de balanceamento (06/11/2026)

1. **Meta:** as metas do GDD, juntas numa nota única (a distância até elas):
   - perfil heurístico vence 50–65% das runs;
   - perfil aleatório vence menos de 10%;
   - chegada à arena em 11–13 min;
   - herói chega à arena no nível 12–16;
   - os decks ficam a menos de 5 pontos percentuais entre si;
   - nenhuma carta aparece em mais de 70% das vitórias;
   - elixir desperdiçado abaixo de 10% da run.
2. **Velocidade:** a simulação fica separada do visual desde o primeiro dia. Ela é lógica pura, com passo fixo, determinística por semente, e roda várias runs em paralelo (uma por núcleo da CPU). Meta: 15 min de jogo em menos de 5 s. O visual só desenha o estado da simulação.
3. **Personalidades:** cada uma é um arquivo de parâmetros (agressividade, economia, gosto por enxame, risco, quanto guarda elixir...). Criar um bot é criar um arquivo. Começam pelos 5 perfis do GDD. Os **exploradores** evoluem sozinhos procurando estratégias que quebram o jogo; quando acham uma, ela vira uma personalidade nova.
4. **Ajuste de números (script, sem supervisão):**
   - pode mudar vida, dano, XP e tempos em até ±30% por ciclo;
   - o custo de elixir muda só ±1, no máximo uma vez por carta a cada 10 ciclos;
   - há uma lista de valores travados que o script nunca toca (ex.: 2,8 s de elixir, mão de 5).
   - Roda quando você mandar, ou numa tarefa agendada.
5. **Mudanças de regra (sessão do Claude):** o Claude lê os relatórios acumulados e aplica as mudanças de regra que os números não resolvem. Pode reescrever efeitos de cartas, upgrades e contratos. Nunca toca nos 4 pilares do GDD e nunca tira cartas do jogo.
6. **Histórico:** um commit por ciclo, com o relatório, na branch `balance`. Um pacote só entra na `main` depois de você jogar pelo menos uma run com ele.
7. **Ordem:** a simulação separada e os bots Aleatório e Guloso entram no marco 1. O ajustador e os exploradores entram logo que a run completa existir.

## Herói com menos poderes e rebalanceamento (07/11/2026)

Pedido seu: no máximo 4 poderes, um a cada 4 níveis; mais XP do jogador pelo dano no chefe; as palavras-chave não pausam mais; balancear até que quem joga bem vença, mas sem ser fácil. Você estava fora, com autonomia total, então as decisões abaixo são minhas.

**Regras**
- **Poderes do herói:** ele aprende uma habilidade nos níveis 4, 8, 12 e 16 e para aí (`hero_xp.upgrade_every` = 4, `upgrade_max` = 4). Os níveis continuam dando vida e dano.
- **XP do jogador:** `player_xp.per_damage` = 1,25 (todo dano rende 25% a mais) e `player_xp.arena_mult` = 2 (na arena, onde você é o chefe em pessoa, o dano rende o dobro). Interpretei "dano de boss" como o dano causado na luta contra o chefe; o 1,25 vale para a run inteira.
- **Caixas de palavra-chave não pausam:** a opção "Pausar ao passar o mouse" saiu das configurações, junto com o aviso "Pausado enquanto você lê".
- **XP do herói cresce menos que o custo da carta** (`hero_xp.cost_exp` = 0,7, com `per_elixir` subindo de 20 para 27 para compensar). Antes, o bot bom ganhava mais quando nunca jogava monstros acima de 3 de elixir, porque um Ogro morto dava XP demais ao herói. Com a mudança, essa diferença caiu de 14 para 5 pontos.

**Números** (partindo dos da branch `balance`, que já tinham sido medidos)
- Herói: vida 1950 → 3364, dano 30 → 52 (compensa os ~11 poderes que ele deixou de ter).
- Arena: altares com 1500 de vida (eram 300). O herói quebrava os altares no caminho e o teleporte deixava de valer; agora desviar do herói é o que separa quem joga bem de quem joga ao acaso.
- Arqueiros Esqueleto: dano 12 → 8, vida 120 → 75. Eles carregavam o bot aleatório (cerca de 330 de dano por jogada, quase o dobro do bot bom).
- Monstros que recuam: velocidade de recuo 0,55 → 0,4.
- Decks: Ruína e Tesouro voltaram a ter elixir normal (1,0); o Tesouro deixou de dar menos XP ao herói (1,0).
- Monstros causam 2,5× de dano corpo a corpo e 1,2× à distância; o primeiro nível do jogador pede 375 de dano (como na `balance`).

**Como medi "jogar bem"**
- O Heurístico escrito à mão quase não ganhava do Aleatório (49% contra 39%): mudar só a força do herói movia os dois juntos. Rodei o explorador (algoritmo genético nos parâmetros do bot) e o melhor perfil encontrado virou o novo `data/bots/heuristic.json`. Ele joga com monstros baratos, investe no covil no começo, evita dar XP ao herói e teleporta quando o herói chega perto.
- Lote final (`reports/final_balance/report.md`, 5 perfis, 48 runs por deck, sementes que o explorador não viu): bot bom **47%** (Horda 52%, Ruína 48%, Tesouro 42%), Aleatório **12%** (Horda 6%, Ruína 8%, Tesouro 23%). Nota 0,25 (era 0,89 no último relatório da `balance`); chegada à arena, nível do herói e do jogador e elixir perdido ficaram dentro das metas. Entre lotes, a vitória varia uns ±5 pontos.

**Riscos**
- O bot bom é melhor que o antigo, mas ainda é um bot. Uma pessoa que pensa deve passar dos 50%; se ficar fácil ou difícil demais, o próximo botão é a vida e o dano do herói (5% para mais ou para menos muda a vitória do bot bom em uns 5 pontos).
- O Tesouro continua o deck mais difícil para quem joga bem e o mais fácil para quem joga ao acaso (vitórias cedo com Mímico e Arqueiros).
- **Defeito corrigido no caminho:** o salvamento pulava toda variável chamada `rng` (para não gravar o gerador aleatório), e nas unidades `rng` é o alcance. Ao usar Continuar, todo atirador e toda torre ficavam com alcance 0. O teste de retomada pegou isso no tick 13000.
- Os números estão direto nos JSON. O `xlsx_to_json.py` já tem as regras novas e os altares, mas a planilha ainda tem os valores antigos de vida e dano do herói e dos arqueiros (e o script não gera os multiplicadores de dano dos monstros nem as regras dos decks); regerar os dados a partir da planilha desfaz parte do balanceamento.

## Deck que evolui na run e meta-progressão (07/11/2026)

Decidido com você no grilling de 07/11; números e revisões de carta aprovados nas abas "Deck - " da planilha. **Reverte a decisão "fora: meta-progressão"** acima.
- **Cada local da estrada dá uma escolha para o deck:** Santuário = carta rara, Ritual = subir o nível de uma carta, Vila = carta comum/incomum, Taverna = modificador, Fonte = remover carta, Ponte = escolha livre. Vencer a disputa do local dá 3 opções; perder dá 1. Toda recompensa pode ser recusada (tecla 0, botão Recusar, B no controle).
- **Disputas:** Ritual = o círculo sobreviver ao herói; Santuário = como antes; Vila = o herói não curar (vila queimada conta como vitória); Taverna = 150 de dano nos 15 s de lentidão; Fonte = monstro seu a até 6 m quando o herói chega (aí ele não bebe); Ponte = 200 de dano nela.
- **Níveis de carta 1 a 3:** +25% nos números principais por nível (`lvl` de cada carta em `cards.json`); cartas de rota e a Biblioteca ficam 1 mais baratas por nível; 11 cartas têm um especial no N3 (`n3`). O nome ganha "+" por nível.
- **Ofertas por nível do jogador** só em níveis pares (`offers.level_every`). Contratos iguais.
- **Deck base de 10 cartas** (mão 5), no máximo 2 cópias e 1 finalização; remover nunca deixa o deck abaixo de 6.
- **Meta:** Almas em toda run (1 por 400 de dano no herói, 2 por local, +40 por vitória, +20 se for na estrada); coleção inicial de 16 cartas, as outras 16 custam 70/100/180 Almas por raridade (~19 runs para tudo). Ofertas na run só sorteiam cartas desbloqueadas. Salvo em `user://meta.save`, que nunca é apagado.
- **Horda, Ruína e Tesouro viram Pactos:** só as regras; as cartas vêm do deck montado na coleção (os 3 decks prontos de 10 cartas são atalhos lá).
- **Revisões de carta:** Raio Cósmico 1200 → 1000 de dano (o nível escala o cone); Pacto Sombrio tira 40% da vida da parte mais inteira em vez de destruí-la; Slime 240 → 300 de vida; Lobisomem custa 4; Totem de Ossos raio 8 m; Fantasma medo de 2 s.

Decisões que tomei no seu lugar durante a implementação (você deu carta branca):
- **Sacrifício com recarga:** sacrificar sempre gira a mão, mas o +1 de elixir vem no máximo a cada 8 s (`sacrifice_cooldown`). Sem isso, sacrificar sem parar era elixir infinito (um humano também conseguia); com o deck maior, o bot achou isso e vencia a Ruína em 100% das runs em ~100 s, só de Raio Sombrio.
- **Deck pronto da Ruína com 1 Raio Sombrio** (a segunda cópia virou Torre de Gárgula): com 2, a Ruína vencia 96%.
- **Bots:** recusam oferta fraca, acima de 12 cartas a carta nova vale menos e sacrificam a carta que nunca jogam (custo acima do `max_cost` do perfil).
- Cópias iguais aparecem uma vez só nas ofertas de nível e de remoção.

Riscos e pendências:
- **O balanceamento ainda não está nas metas** (`reports/deck_v5/report.md`): bot bom na Ruína 69%, na Horda e no Tesouro 23% (era 47% em média); Aleatório 0–19%. O Raio Sombrio continua a carta mais forte, e as outras perderam o elixir grátis do sacrifício. Próximo passo: o ajustador (`tools/tuner.py`) com os decks prontos novos.
- Os bots quase nunca vencem a disputa dos locais (≈1,4 de 8): eles não sabem das condições. Uma pessoa vai ganhar bem mais recompensas cheias do que o lote mede.


## Grupo de 5 heróis, sem XP (09/11/2026)

Decidido com você no grilling de 09/11 e implementado no mesmo dia. **Reverte** o XP do herói e do jogador, a decisão "o dano no herói rende XP ao jogador" e "um poder a cada 4 níveis". Detalhes e lista da planilha em `docs/GRUPO_DE_HEROIS.md`.

- **Fila:** 5 heróis (Escudeiro), na estrada e na arena. Vence quem matar os 5; perde se algum vencer o chefe. O chefe mantém o dano entre um herói e o próximo. `rules.party` = tamanho 5, passo ×1,26, chegada 8 s.
- **Chegada:** o herói novo reaparece 8 s de caminhada atrás do ponto da queda (na arena, no portão); a câmera recua uns 3 s.
- **Progressão:** nenhum XP. O herói *k* tem nível *k* e *k*−1 habilidades (3 sorteadas, a que responde ao dano do grupo). Vida e golpe ×passo por herói; vida cheia na chegada; maldição e efeitos ficam no que caiu.
- **Recompensa:** cada queda abre uma oferta de 1 entre 3. Locais e contratos mantêm as suas. Acabam as ofertas por nível e a barra "Seu poder".
- **Peças que dependiam de XP:** Horda = heróis +10% de vida; Ruína perde o "XP passivo ×2"; Tesouro = oferta de queda com 4 opções; Isca de Ouro vira só desvio; Santuário perdido só reduz a recompensa; "Sem Testemunhas" = 200 de dano sem perder monstro; `xp_aversion` saiu dos bots.
- **Números (provisórios):** herói 1 com 1700 de vida e 44 de golpe, ×1,26 por herói (a planilha propunha 2300/52/×1,28, forte demais no lote). Lote de 144 runs: bot Heurístico vence ~51% (Horda 62, Ruína 54, Tesouro 38), Aleatório ~36% (Tesouro 71% alto demais). Ainda não passou pelo ajustador.

Riscos e pendências:
- Balanceamento por fazer: o Aleatório vence demais no Tesouro e a chegada à arena está em 600–1100 s. Falta passar o ajustador e redefinir as metas (`heroes_fallen` no lugar de nível do herói/jogador).
- A planilha (`Revisao do conteudo - Last Boss.xlsx`) ainda não reflete a mudança.
- Não joguei com janela: a chegada do herói e a câmera não foram vistas em tela.

## Mapa de rotas escolhidas (09/11/2026)

Decidido com você no grilling de 09/11 e implementado no mesmo dia, com autonomia total (você estava fora). Detalhes, números, decisões que tomei no seu lugar e riscos em `docs/MAPA_DE_ROTAS.md`; os números estão nas abas `Mapa - ` da planilha.

- **Mapa em rede (fileiras de 2 ou 3 nós):** cada rota passa por 8 a 10 locais. O mapa aparece inteiro desde o início. **Você escolhe o ramo** (a IA do herói não escolhe mais); sem escolha, o jogo pausa na bifurcação. Os ramos não escolhidos ficam bloqueados. Todas as rotas têm o mesmo comprimento: a escolha é só de prêmio.
- **Nenhum local ajuda o herói.** A **Vila virou Loja** (1 a 2 por mapa, nunca 2 na mesma rota), paga com **ouro da run** (1 por 40 de dano no herói, 25 por disputa vencida). A disputa da Loja (150 de dano com o herói no raio) dá 30% de desconto. A **Fonte cura as suas unidades** (5%/s por 15 s, a até 8 m). Santuário perdido só reduz a recompensa. Ritual, Ponte e Taverna ficam como estavam.
- **Ponte Quebrada e Placa Falsa saíram do jogo** (30 cartas). **Queimar Vila virou Incêndio:** marca um local à frente, que pega fogo quando o herói chega. Substitutas da Ponte Quebrada: Incêndio na coleção inicial, Óleo Fervente no deck pronto da Horda e uma segunda Teia no da Ruína (escolhidas pelo lote).
- **Bots:** escolhem a rota (os "smart" pelo valor do caminho), compram na Loja e jogam pelas disputas (guardam elixir antes de Taverna, Ponte e Loja; põem guarda na Fonte e no Ritual).
- **Lote final** (`reports/route_final/report.md`, 720 runs): Heurístico 55% (Horda 48, Ruína 48, Tesouro 69); Aleatório 32% (Tesouro 54%, ainda alto, como antes).

Riscos e pendências:
- O Aleatório continua acima da meta (<10%), principalmente no Tesouro; as metas antigas (nível do herói) ainda entram na nota. Falta o ajustador e refazer as metas (pendência do grupo de heróis).
- Salvamentos de run anteriores ao mapa novo não carregam (o Continuar volta ao menu). Quem desbloqueou a Placa Falsa perde as 70 Almas.
- Não joguei uma run inteira com a janela; as capturas e os testes de entrada (`--routetest`) cobrem a escolha, o mapa, a faixa e a Loja.
