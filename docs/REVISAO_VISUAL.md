# Revisão visual — HUD, menu e cartas (08/11/2026)

Execução autônoma (agendada, com você fora). Pulei a `grilling` pela regra de AFK; as decisões que tomei no seu
lugar estão na seção "Decisões e riscos". Nada foi commitado.

- Backup de antes da primeira edição: `C:\Users\gabri\Desktop\LastBoss_backup_visual_2026-11-08\`
  (`game/`, `locale/`, `data/`, `assets/fonts/`, `project.godot`).
- Fotos: `docs/visual/antes/` (estado de partida) e `docs/visual/rodada_N/` (cada rodada de revisão).
  Geradas por `tools/capture_ui.sh` (19 telas, em 1920x1080 tela cheia e 1280x720, algumas em inglês).
- Galeria lado a lado: `docs/visual/galeria.html` e o Artifact privado https://claude.ai/artifact/CE8x83YteFaZfwxcaf2JmR

## 1. Diagnóstico do "antes"

Notas de 0 a 10. H = hierarquia, T = tipografia, P = paleta, E = espaçamento e alinhamento, M = molduras e materiais,
I = ícones, C = legibilidade das cartas, Mo = movimento e resposta, W = coerência com o mundo 3D, X = excesso de
informação (10 = enxuto).

| Tela | H | T | P | E | M | I | C | Mo | W | X | Média |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Título | 6 | 4 | 5 | 6 | 3 | – | – | 5 | 3 | 8 | 5,0 |
| Escolha de Pacto | 5 | 4 | 4 | 5 | 3 | 4 | 5 | 4 | 3 | 6 | 4,3 |
| Coleção | 4 | 4 | 4 | 4 | 3 | 4 | 4 | 4 | 3 | 4 | 3,8 |
| Configurações | 5 | 4 | 4 | 5 | 3 | 3 | – | 4 | 3 | 7 | 4,2 |
| HUD da run (começo e meio) | 5 | 4 | 4 | 4 | 3 | 4 | 4 | 6 | 3 | 5 | 4,2 |
| Mão + carta ampliada | 5 | 4 | 4 | 5 | 3 | 4 | 4 | 7 | 3 | 6 | 4,5 |
| Oferta de cartas | 6 | 4 | 4 | 5 | 3 | 4 | 5 | 5 | 3 | 7 | 4,6 |
| Pausa | 5 | 4 | 4 | 4 | 3 | 4 | 4 | 4 | 3 | 6 | 4,1 |
| Arena (HUD) | 5 | 4 | 4 | 5 | 3 | 4 | 4 | 6 | 3 | 5 | 4,3 |
| Resultado | 6 | 4 | 4 | 3 | 3 | – | – | 3 | 3 | 7 | 4,1 |
| Dica | 6 | 5 | 4 | 6 | 3 | – | – | 5 | 3 | 6 | 4,8 |
| Mapa grande e faixa de rota | 4 | 4 | 5 | 4 | 2 | 4 | – | 5 | 3 | 5 | 4,0 |

### O que deixa cada parte amadora

**Problemas que valem para tudo (a raiz):**
1. **Quatro linguagens visuais na mesma tela.** O mundo é um bosque enluarado com texturas fotográficas,
   herói em PBR metálico e monstros com luz pintada; a interface é um retângulo chapado roxo-escuro com
   borda roxa de 1 px. Nada nela vem do mundo (nem material, nem luz, nem cor). Confirma a pista da sessão
   anterior: a mistura de estilos é o primeiro problema.
2. **Molduras chapadas.** `StyleBoxFlat` com cantos cortados, borda de 1 px e uma sombra de 4–6 px. Sem
   relevo, sem textura, sem luz. Todos os painéis, botões e cartas têm o mesmo peso, então nada se destaca.
3. **Tipografia sem sistema.** O título usa a serifa do sistema (Georgia/Times em negrito com espaçamento de
   3 px: "LAST BOSS" parece um documento do Word); o resto usa a fonte padrão da Godot. O contorno preto de
   4 px em quase todo texto engrossa as letras e suja a leitura. Os tamanhos variam sem escala (13, 14, 15,
   16, 17, 18, 19, 20...).
4. **Paleta sem papel.** Roxo serve de fundo, de borda, de poder, de elixir e de botão. O dourado aparece em
   bordas de foco e títulos, sem regra. O texto é branco-lilás frio sobre roxo frio, e o mundo também é frio:
   não há contraste de temperatura entre interface e jogo.
5. **Sem resposta ao mouse além da cor da borda.** Botões trocam de borda; não há brilho, relevo, som visual.

**Título.** A composição é boa (texto à esquerda, chefe à direita), mas o título é uma serifa genérica sem
tratamento; a régua dourada é um retângulo de 2 px; os botões são caixas iguais às da HUD; o covil 3D é roxo
chapado sem luz dramática, e destoa do bosque fotográfico que aparece no jogo.

**Escolha de Pacto.** Três caixas de texto iguais; nenhuma imagem diz o que é cada Pacto. As palavras
coloridas competem com o título do Pacto. A fileira "Seu deck" corta os nomes ("Esqueletos Arqu...").

**Coleção.** Grade de 32 células iguais com o mesmo peso; cartas bloqueadas só ficam mais escuras; a lista
do deck à direita é uma pilha de botões grandes e idênticos que ocupa metade da tela para mostrar 10 nomes.
A grade some pela borda de baixo em 1080p.

**Configurações.** Painel genérico; abas e botões de ligar/desligar têm o mesmo desenho, então a aba ativa
não se distingue do botão "Ligado". Na captura por linha de comando o título do menu aparece atrás do painel
(o atalho `--tab` não escondia a tela de título).

**HUD da run.** O painel do herói é largo e quase vazio à direita; o selo de nível do herói (octógono) e o do
poder (octógono) são iguais, só muda a cor. Os botões "II / 1x / M" são texto em caixas. A barra de elixir são
dez retângulos roxos chapados; o número do elixir num octógono enorme. O botão Sacrificar parece desligado.
A faixa de rota é um retângulo de fundo roxo com linhas finas.

**Cartas (mão, ampliada, oferta, coleção).** Moldura de 2 px na cor da raridade e fundo roxo: parecem botões.
A arte é pequena (256x160 renderizado), com luz chapada e fundo de cor sólida; cartas sem monstro mostram
blocos cinzentos (bigorna = paralelepípedos). Nome em fonte comum, cortado no leque ("Ponte Quebrad").
O custo é um octógono roxo com número fino. Raridade só pela cor da borda (cinza/verde/azul/roxo), fácil de
confundir com o brilho de "jogável" (verde). Na oferta, metade de baixo de cada carta fica vazia.

**Pausa.** Título "Pausado" em serifa genérica; o texto "Seu deck (10/{max})" mostra a chave de formatação
crua (bug). O painel do deck tem espaço vazio grande embaixo.

**Arena.** O painel "Seu corpo" são 4 barras roxas iguais com o nome em cima; nada liga a barra à parte do
chefe. O resto é a mesma HUD.

**Resultado.** Grade de 3 colunas encostada à esquerda num painel de 820 px (sobra um terço vazio à direita);
números em serifa espaçada; "DERROTA" em vermelho com contorno preto grosso.

**Dica.** Caixa roxa com borda dourada; legível, mas sem relação com o resto.

**Mapa grande e faixa de rota.** Retângulos roxos translúcidos com contorno de 1 px; o mapa é uma linha fina
num quadrado vazio.

## 2. Direção de arte: "Covil"

Uma direção só, que vale para toda a interface. A ideia: **a interface é feita do mesmo ferro, bronze e
cristal do covil do Lorde**, iluminada pela mesma lua (luz do alto à esquerda). O mundo é frio (azul, verde,
violeta); a interface é quente (bronze, ouro velho, pergaminho) com o violeta do núcleo do chefe como cor de
poder. Contraste de temperatura em vez de mais um roxo.

**Paleta.**

| Papel | Cor | Uso |
|---|---|---|
| Ferro (fundo) | `#201b21` → `#0d0b0f` | placas, cartas (degradê vertical + grão) |
| Bronze (aro) | `#cc9e61` | molduras, réguas, rebites |
| Ouro (destaque) | `#ffd180` | títulos, foco, seleção |
| Pergaminho (texto) | `#f5ede0` | texto principal |
| Cinza quente (texto 2) | `#b8aa9e` | texto secundário |
| Vida do herói | `#db3029` | barra de vida |
| XP do herói | `#ffb84d` | barra fina, selo do herói |
| Poder / elixir | `#b875ff` / `#c76bff` | o violeta do núcleo do chefe |
| Bom / ruim | `#85ed94` / `#ff6b5c` | ganhos, perdas, erros |
| Raridade | ferro `#b3b3bd`, verdete `#75d68a`, aço azul `#70adff`, ametista `#d185ff` | aro e losango da carta |

**Tipografia (2 famílias, OFL).** Cinzel (700 e 900) para títulos, nomes de cartas e números grandes;
Alegreya Sans (Medium, Bold, ExtraBold) para todo o resto. Escala: 12 / 14 / 16 / 19 / 24 / 32 / 44 / 64 / 120.
Contorno no máximo 2–3 px; a leitura sobre o mundo vem de uma sombra suave (deslocada 2 px), não de contorno
grosso. Títulos grandes têm degradê de metal (ouro claro → bronze, com um brilho estreito).

**Molduras.** Um shader só (`game/ui/frame.gdshader`): placa de ferro com grão e manchas, aro de bronze com
perfil abaulado e luz do alto à esquerda, sulco escuro, sombra interna, sombra projetada, rebites em losango nos
cantos das peças grandes, brilho interno na cor de significado (raridade, seleção, foco). Cantos chanfrados
(nunca arredondados). Variações: placa (menus), placa leve (HUD sobre o mundo, sem rebites), carta, janela
(arte das cartas: centro vazado com vinheta), plaqueta (nome), botão (estados pelo shader), trilho (barras).

**Ícones e selos.** Gemas facetadas com aro de bronze: cristal hexagonal violeta (custo e elixir), escudo âmbar
(nível do herói), selo estrelado violeta (seu poder), losango de raridade no pé das cartas. Elixir em frascos
de vidro com líquido que brilha quando cheio.

**Cartas.** Retrato: arte grande (72% da largura em altura) numa janela de bronze, plaqueta com o nome em
Cinzel sobre a borda da arte, linha de tipo em versalete, régua com losango, texto em Alegreya Sans, custo em
cristal no canto de cima, atalho num disco, raridade no aro e no losango de baixo. Retratos renderizados dos
modelos do jogo em 512x384 com MSAA, luz de três pontos e fundo com névoa na cor do tipo.

**Espaçamento e escala.** Grade de 4 px; margens internas 12–20; distância entre blocos 16–24; a HUD encosta
14 px nas bordas e não cobre o centro da tela (o herói).

**Movimento.** Entrada de tela: 0,25 s, ease-out (deslizar 24–30 px + aparecer). Passar o mouse: 0,12 s.
Carta sob o mouse: sobe e amplia em 0,15 s. Seleção: aro aceso que pulsa devagar (5 rad/s). Números de vida
e poder sobem suavemente. Nada pisca rápido.

## 3. Rodadas de revisão

Em cada rodada: captura de todas as telas (`docs/visual/rodada_N/`), a minha crítica, uma crítica independente de
um subagente novo (recebe só os caminhos das fotos e a pergunta "isto parece um jogo comercial de alto nível?",
sem saber o que mudou) e a correção do que ficou abaixo de 8.

### Rodada 1 — primeira versão da pele Covil

O que entrou antes desta rodada: shader de moldura (`game/ui/frame.gdshader`), pele `UiCovil`, fontes Cinzel e
Alegreya Sans, degradê de metal nos títulos, cartas novas (grande e compacta), gemas facetadas, frascos de elixir,
retratos 512x384, botões "fantasma" no menu, brasão de cada Pacto, ícones de pausa e mapa, cenário do covil com
paredes, contraluz, facho e brasas. Bugs antigos corrigidos no caminho: o escurecimento atrás da pausa, da oferta e
do resultado tinha tamanho zero e não aparecia; "Seu deck (10/{max})" na pausa; atalho `--tab` deixava o título
atrás das configurações.

**Minha crítica (notas por tela, média dos critérios):** título 8; Pactos 7,5; coleção 7; configurações 7,5;
HUD da run 7; mão 7; oferta 7,5; pausa 7,5; arena 6,5; resultado 7,5; dica 7,5; mapa 6,5. Abaixo de 8: texto miúdo
(a Alegreya Sans tem olho pequeno), ícones das cartas sem monstro (blocos), painel das partes do corpo sem valores,
painel do tempo largo e vazio, cartas bloqueadas sem cadeado, disco azul na base do menu.

**Crítica independente (subagente):** 5,5 geral. Hierarquia 5, tipografia 6, paleta 6, espaçamento 5, molduras 6,
ícones 4, legibilidade das cartas 4, coerência 5. Os piores problemas, na ordem dele: (1) arte desigual das cartas
sem monstro (blocos cinzentos, tábuas, cilindro); (2) carta da mão com dois números, o atalho batendo no custo da
vizinha, nome pequeno em 1280x720; (3) campo de jogo vazio e herói pequeno; (4) HUD fragmentada em oito caixas
iguais; (5) título do menu de Pactos por cima da cara do chefe e um disco azul na base; (6) coleção sem cadeado,
última fileira cortada, lista do deck só texto; (7) ícones sem informação (habilidades, barras do corpo sem valor,
listas suspensas sem seta); (8) arena genérica; (9) resultado sem hierarquia e com "Derrota" repetido; (10) sinais
de ferramenta (aba Visual, "v0.1 · MVP", painel de configurações 60% vazio).

**Correções para a rodada 2:**
- Retratos: os 17 ícones das cartas sem monstro redesenhados (bigorna com metal em brasa e martelo, ponte de
  tábuas com postes e corda partida, lanterna de almas com gaiola, olho com pálpebras e pedras, aranha na teia,
  caldeirão no fogo, atril com livro acorrentado, muralha com torres e portão, raio com estrela e anéis...) e um
  pedestal de pedra com anel de runas na cor do tipo embaixo de cada um.
- Carta da mão: atalho no pé da carta (não bate mais no custo da vizinha), nome maior.
- HUD: o tempo virou texto solto sobre o mundo (uma caixa a menos); "O Herói" e "Seu poder" em Cinzel; botão
  Sacrificar com aro avermelhado; partes do corpo na arena com a vida em %; texto da faixa de rota maior.
- Menu: fundo 94% escuro atrás das telas que não são o título (o chefe não briga mais com o texto); piso do covil
  fora da contraluz (era ela que fazia o disco azul).
- Coleção: cadeado nas cartas bloqueadas; miniatura da arte em cada linha do deck; foco da grade com contorno.
- Listas suspensas com seta; painel de configurações mais baixo.
- Resultado: "Almas ganhas" em placa dourada, zeros apagados, subtítulo sem repetir o título.
- Ficaram de fora (não são interface): campo de jogo vazio e herói pequeno (câmera e cenário), arena genérica
  (arte do mundo). Ver "O que ficou para depois".

### Rodada 2

**Minha crítica:** título 8,5; Pactos 8; coleção 8; configurações 7,5; HUD da run 7,5; mão 7,5; oferta 8; pausa 8;
arena 7; resultado 8; dica 7,5; mapa 6,5. Abaixo de 8: texto da oferta pequeno em 1280x720, esqueleto estourado no
retrato, "DERROTA" puxando para rosa, chefe aparecendo atrás da coleção (a sombra do menu é um degradê que some à
direita), nome das cartas da mão coberto pela vizinha do leque, mapa grande vazio.

**Crítica independente:** 5,9 geral (hierarquia 6, tipografia 7, paleta 6, espaçamento 6, molduras 7, ícones 5,
cartas 5, coerência 5). Por tela: título 7,5; Pactos 7; coleção 6 (5 em 720p); configurações 5,5–6,5; partida 5
(4,5 em 720p); mão 4,5; mapa 4; oferta 7,5 (6,5 em 720p); pausa 6,5; dica 5,5; arena 6,5; resultado 6. Piores
problemas: (1) mundo da partida lavado, sem foco, herói pequeno; (2) carta da mão com nome girado e cortado, sem
tipo nem texto; (3) canto de baixo à esquerda amontoado (custos da fila encavalados); (4) mapa grande vazio, sem
legenda; (5) faixa de rota sem legenda; (6) texto pequeno e de pouco contraste (rodapé, % das partes, Sacrificar
parecendo desligado); (7) coleção: bloqueadas ilegíveis e preço em vermelho que parece erro; (8) texto do menu por
cima do chefe e uma meia-esfera azul na base; (9) configurações com metade vazia; (10) resultado com blocos iguais.

**Correções para a rodada 3:**
- O disco/meia-esfera clara do menu era a esfera de alcance da luz de um braseiro atrás da câmera iluminando a
  névoa volumétrica (não era geometria nem o céu: listei todos os objetos 3D visíveis). As luzes pontuais do menu
  não iluminam mais a névoa; só o facho de cima.
- Véu escuro uniforme (62%) atrás de Pactos, coleção e configurações.
- Carta grande: texto 7% maior; oferta com cartas de 240 px. Carta da mão: o nome escolhe o tamanho que cabe na
  parte que a vizinha não cobre.
- Retratos menos estourados (luz principal, contraluz e halo mais fracos).
- "DERROTA" em vermelho de verdade (o degradê clareia para o pergaminho, não para o rosa).
- Mapa grande com título, legenda (locais, herói, covil), estrada com contorno e o covil como gema.
- Gemas da esteira "Próximas" menores e dentro das miniaturas.
- Texto 15% acima do tamanho nominal (era 10%); botão desligado com texto mais claro; vinheta um pouco mais forte.
- Coleção: preço que ainda não dá para pagar em cobre; bloqueadas menos apagadas.
- Mantido de propósito: a aba Visual com "Variações em avaliação" (é a ferramenta de comparação que você pediu
  para manter) e "v0.1 · MVP" no rodapé.

### Rodada 3

**Minha crítica:** título 8,5; Pactos 8,5; coleção 8; configurações 8; HUD da run 7,5; mão 7; oferta 8; pausa 8;
arena 7,5; resultado 8; dica 8; mapa 7. Abaixo de 8: legenda do mapa por cima do começo da estrada; "100%" das
partes espremido dentro da barra; nome das cartas da mão.

**Crítica independente:** 5,5 geral (hierarquia 6, tipografia 6, paleta 6, espaçamento 5,5, molduras 6, ícones 4,
cartas 5 — oferta 8, mão 4 —, coerência 4,5). Pela primeira vez ele separou interface e mundo: os três problemas
mais graves que sobram são do **mundo 3D** (cenário da run vazio e monocromático com o herói sem contraste; arena com
cara de diagrama; objetos do covil do menu cortados pela câmera). Da interface: (2) a carta da mão segue outra
linguagem (sem faixa no nome, sem tipo); (3) **bug real:** uma "carta fantasma" escura atrás da carta ampliada;
(6) 1280x720 encolhe tudo linearmente; (7) faixa de rota com cores sem legenda e o marcador do herói em cima da
legenda do mapa; (8) estados da coleção; (9) retículo de posicionamento com cara de ferramenta; (10) painéis
vazios nas configurações.

**Correções para a rodada 4:**
- **Carta fantasma:** o shader da moldura escrevia a cor final sem multiplicar pela cor de entrada, então o
  `modulate` do Control (alfa 0 da carta sob o mouse, cartas apagadas, o sumiço da carta jogada) não chegava à
  moldura. Agora multiplica.
- **O domo azul do menu era o piso do covil:** o shader de toon acendia a parte do piso perto da câmera. Achei
  escondendo uma peça do cenário por vez (antes tinha descartado a névoa e as luzes). O piso do menu agora usa um
  material fosco escuro.
- Carta da mão com o nome em Cinzel numa plaqueta (a mesma linguagem da carta grande), em uma linha quando cabe.
- Mapa grande: faixas próprias para o título e a legenda; a estrada não passa mais por baixo deles.
- Arena: a % de cada parte foi para a linha do nome, em dourado.

### Rodada 4

**Minha crítica:** título 8,5; Pactos 8,5; coleção 8; configurações 8; HUD da run 8; mão 7,5; oferta 8,5; pausa 8;
arena 7,5; resultado 8; dica 8; mapa 7,5. Abaixo de 8: legenda do mapa encostando no aro; números "pulando".

**Crítica independente:** **interface 6/10**, geral (com o mundo 3D) ~5. Por tela: título 6, Pactos 6,5–7,
coleção 5 (4 em 720p), configurações 4–5, run 4–4,5, mão 4, mapa 5, oferta 7, pausa 6, dica 5, arena 4,5,
resultado 6,5. Os três primeiros problemas da lista continuam no mundo 3D (cena vazia, arena de diagrama, estrada
"adesivo", vegetação ciano). Da interface: nome da carta da mão cortado em duas linhas ("DINAMITEIRC"); textos
soltos no mundo sem fundo ("Bifurcação · 194 m"); elixir sem bandeja; algarismos antigos da Alegreya Sans
(alturas irregulares em 3364/3364, 70 Almas); "DERROTA" salmão; destaque do menu com degradê marrom "barato";
foco da coleção em "L"; "Esqueletos Arqueiros" em versalete quebrando a grade do resultado.

**Correções para a rodada 5:** algarismos alinhados (recurso OpenType `lnum` em todas as variações da Alegreya
Sans); o degradê dos títulos clareia pouco em cores saturadas (o vermelho fica vermelho); no menu, o foco é um
losango e um sublinhado dourado que some para a direita; nomes da mão em duas linhas escolhem o tamanho pela palavra
mais longa; bandeja de ferro atrás do sacrifício e do elixir; fundo escuro atrás do rodapé de atalhos e dos rótulos
da faixa de rota; nomes da carta mais jogada em texto comum; carta ampliada sobe mais; contorno de foco da
coleção maior; `.gdignore` em `docs/visual` (a Godot importava as capturas e o `.pck` exportado foi de 91 MB para
330 MB).

### Rodada 5

**Minha crítica:** título 8,5; Pactos 8,5; coleção 8; configurações 7,5; HUD da run 8; mão 7,5; oferta 8,5;
pausa 8; arena 7,5; resultado 8,5; dica 8; mapa 8.

**Crítica independente:** interface 6/10, mundo 3D 4,5, geral 5,5. Interface por tela: título 7, Pactos 7, coleção
5,5, configurações 4,5–6, run 5,5, mão 6, mapa 5, oferta 7,5, pausa 6, dica 6, arena 6, resultado 7. Novidades da
lista: o mesmo cristal roxo mostrava três números diferentes (custo, seu nível, elixir); na legenda do mapa o herói
tinha o azul da Fonte Sagrada e o covil o roxo do Círculo de Ritual; configurações com 70% vazio; cartas da oferta
com sobra embaixo; "Você nv 2" na fonte padrão da Godot, solto no mundo.

**Correções para a rodada 6:** o selo do seu poder virou um disco de bronze com estrela (não parece mais o cristal
do custo); no mapa e na faixa de rota o herói é branco-pergaminho e o covil uma gema dourada; rótulos da faixa em
pílula com aro de bronze; o painel de configurações acompanha a altura da aba; cartas da oferta mais curtas;
cartas da mão de 116x146 para 124x158; números e avisos flutuantes no mundo em Cinzel.

### Rodada 6

Capturada (`docs/visual/rodada_6/`, é a da galeria). **A crítica independente não rodou:** o subagente parou com
"session limit" da API no meio da avaliação. **Minha crítica:** título 8,5; Pactos 8,5; coleção 8; configurações
8; HUD da run 8; mão 8; oferta 8,5; pausa 8; arena 7,5; resultado 8,5; dica 8; mapa 8.

### Por que parei na rodada 6

O critério era "duas rodadas seguidas sem nada abaixo de 8, ou 10 rodadas". Não cheguei a nenhum dos dois:

- Nas minhas notas, só a arena fica abaixo de 8, e o que a puxa é a arte do mundo (disco roxo, pilares lisos).
- O crítico independente nunca passou de 6 na interface e de 5,5 no geral. Desde a rodada 3 ele põe os três piores
  problemas no **mundo 3D** (cenário vazio e frio, herói pequeno e sem contraste, arena de diagrama, chefe de
  primitivas), que esta tarefa não cobre.
- A crítica da rodada 6 parou no limite de uso, e o mesmo limite vale para mim: preferi fechar com tudo verificado
  a abrir uma rodada que não terminaria.

## 4. Verificação

- **Testes:** `tests.tscn` 0 falhas. `--uitest`, `--menutest` e `--tiptest` OK na janela padrão (o `--uitest`
  passou em 5 de 5 execuções).
- **Teste da entrada real em outras condições:** com interface em 115% passa. Com a janela no canto em 1280x720,
  com a interface em 80% ou em tela cheia, o passo "arrastar e soltar" falha, **e falha igual no projeto de
  antes**, então não é regressão. O passo "selecionar com tecla 1" falhou 2 vezes em umas 10 execuções nessas
  condições e passou nas repetições: está instável (provavelmente foco da janela ou o cursor físico).
- **Texto:** capturas em pt e en, 1280x720 e 1920x1080 em todas as rodadas; interface em 80% e 115% passou pelo
  teste da entrada real (sem foto).
- **Desempenho com 500 unidades:** as medições oscilaram demais para concluir. A placa de vídeo estava com 76% de
  uso antes de rodar o jogo, e o PROGRESSO registra 90 FPS nesta máquina. Intercalando antes e depois, 4 pares:
  antes 33 / 33 / 38 / 28 FPS (média 33), depois 40 / 35 / 31 / 27 (média 33). A média ficou igual, mas o mínimo
  do depois foi menor em 3 dos 4 pares (23–29 contra 27–37). **Não dá para afirmar** que a perda é menor que 5%:
  refaça com a máquina livre (comando no PROGRESSO).
- **Exportação:** `export/LastBoss.exe` gerado (o `.pck` voltou a 91 MB depois do `.gdignore`) e aberto sem
  erros de script.

## 5. Decisões que tomei no seu lugar (AFK) e riscos

- **Direção única "Covil"** (ferro, bronze, ouro e o violeta do chefe; quente contra o mundo frio), sem pedir
  aprovação de alternativas.
- **A pele nova é a HUD 0.** A antiga 0 passou a ser a 5, "Clássica (a antiga)", e as peles 1–4 continuam. O seu
  `settings.cfg` guarda HUD 0, então você já abre na nova. Para voltar: Configurações → Visual → HUD 5.
- **Molduras por shader**, não por textura. O shader mede o tamanho da peça pelas derivadas do UV e usa uma
  uniforme global (`ui_px`, em `project.godot`) atualizada a cada quadro pelo `main.gd`.
- **Mexi em arte fora da interface, só onde ela é a interface:** os ícones das cartas sem monstro
  (`Models.icon`, usados só nos retratos), a luz dos retratos, o cenário 3D do menu (paredes, contraluz, facho,
  brasas, piso fosco) e a fonte dos números flutuantes. Não toquei no chão, no herói, nos monstros nem na arena que
  você escolheu.
- **Textos:** chave nova `UI_RUN_DECK` (o deck da run pode passar de 10 cartas) e `UI_MAP_*`; subtítulos do
  resultado sem repetir o título. Só texto de exibição.
- **Bugs antigos corrigidos no caminho:** escurecimento da pausa, oferta e resultado com tamanho zero;
  "Seu deck (10/{max})"; `--tab` deixando o título atrás das configurações.
- **Mantido de propósito:** a aba Visual com "Variações em avaliação" (é a ferramenta que você pediu para manter)
  e "v0.1 · MVP" no rodapé. O crítico chamou os dois de "texto de desenvolvimento".
- **Risco:** o shader depende de a Godot passar o `modulate` na cor de entrada e de o tamanho dos marcadores
  (9–13 px) não coincidir com outra textura desenhada pelo mesmo Control. Se uma peça aparecer sem moldura ou com
  moldura onde não devia, é por aí.
- **Risco:** a carta da mão ficou maior (124x158). O leque sobe uns 12 px na tela.
- **Risco:** quebras de linha. Edições em Python no Windows converteram alguns arquivos para CRLF. Corrigi
  comparando com o backup, mas `tools/art/import_models.gd` (fora do backup) foi convertido e restaurado duas vezes
  a partir de uma cópia do projeto; ele está igual ao original.

## 6. Assets novos e licenças

| Arquivo | Origem | Licença |
|---|---|---|
| `assets/fonts/Cinzel-VF.ttf` | Google Fonts (github.com/google/fonts, `ofl/cinzel`) | SIL OFL 1.1 — `assets/fonts/OFL-cinzel.txt` |
| `assets/fonts/AlegreyaSans-Medium.ttf`, `-Bold.ttf`, `-ExtraBold.ttf` | Google Fonts (`ofl/alegreyasans`) | SIL OFL 1.1 — `assets/fonts/OFL-alegreyasans.txt` |

Tudo o mais (molduras, gemas, ícones, retratos) é gerado por código no próprio projeto.

## 7. Arquivos

- Novos: `game/ui_covil.gd`, `game/ui/frame.gdshader`, `game/ui/title.gdshader`, `tools/capture_ui.sh`,
  `tools/make_gallery.py`, `docs/visual/` (fotos, galeria, `.gdignore`).
- Alterados: `ui_kit.gd`, `ui_skins.gd`, `hud.gd`, `menu.gd`, `hand_fan.gd`, `elixir_bar.gd`, `route_strip.gd`,
  `minimap.gd`, `collection.gd`, `settings_panel.gd`, `tips.gd`, `main.gd`, `world_view.gd` (fonte dos números),
  `settings.gd` (comentário), `art/card_art.gd`, `art/models.gd` (ícones), `locale/strings.csv`, `project.godot`
  (uniforme global), `PROGRESSO.md`.

## 8. O que ficou para depois

1. **Mundo 3D da run e da arena** (o maior peso nas críticas): contraste do herói, cenário com pontos de interesse,
   chão menos uniforme, arena com material e escala, chefe com mais forma. Pede uma passada de arte do mundo, de
   preferência como direção única, junto com a interface.
2. **Ícones das habilidades do herói** (`upgrade_icon.gd`): o crítico achou genéricos e pequenos.
3. **Glifos de controle** (A, B, L1) nas configurações e nas dicas, no lugar do texto.
4. **Tamanho mínimo de texto em 1280x720:** a interface encolhe linearmente; textos secundários ficam com 10–12 px.
5. **Rodada 6 sem crítica independente** e **medição de FPS limpa** (máquina livre).
6. Retículo branco de posicionamento no mundo (o crítico achou com cara de ferramenta de editor).

**Anexo: primeira medição de desempenho (rodada 2, 500 unidades, intercalada):** antes 27 / 31 / 38 FPS, depois 26 / 33 / 26. Os
números variaram demais entre execuções iguais (o PROGRESSO registra 90 nesta máquina), então não servem para
decidir; refiz a medição na verificação final (seção 4).
