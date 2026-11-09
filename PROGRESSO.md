# Progresso — Last Boss

## Fluxo de nova run e mapa em tela cheia (09/11/2026)

Feito a pedido, sem alterar a simulação. Ainda não commitado.

- **Nova run:** Nova run → escolhe o deck (Horda, Ruína ou Tesouro, com as 10 cartas do deck em foco à vista) → confirma o grupo de heróis (fila de 7, com nível, habilidades, vida e golpe de cada um) → começa. Saiu o "Meu deck" e o construtor: o deck é sempre o do Pacto. A Coleção ficou no menu principal só para ver cartas e desbloquear com Almas.
- **Grupo:** hoje só existe um grupo (os 7 Escudeiros), então a tela é de confirmação; a estrutura já comporta mais grupos.
- **Mapa:** ocupa a tela inteira, em estilo de mapa antigo (pergaminho, trilhas a tinta: feitas em traço cheio, possíveis e planejada tracejadas, ramos fechados com X, bússola, rabiscos de montanha e árvore). A run fica parada com o mapa aberto; Esc, M ou o botão Fechar o fecham (na bifurcação a escolha é obrigatória).
- **Testes:** 0 falhas; `--menutest` e `--routetest` OK (o `_click` agora aplica a escala da janela, o que fazia o `--menutest` falhar); `--uitest` só falha no arrastar, como antes.


## Run em 3 atos, disputas novas, relíquias, eventos e compêndio (09/11/2026)

Feito a partir do seu playtest, com você fora; **na `main` desde 09/11/2026**, junto com a direção de arte D como padrão. Executável: `export/LastBoss.exe` (os atalhos por estilo estão em `export/atos_e_arte/`). O resumo, as decisões que tomei no seu lugar e os riscos estão em `docs/RUN_EM_ATOS.md`.

- **Estrutura da run:**
  - 3 atos, 20 a 24 locais e 7 heróis.
  - Uma relíquia no fim de cada ato.
  - Local "?" com eventos de texto.
  - Loja garantida em toda rota.
- **Locais:** disputas sustentadas, e o herói para no local até ela acabar. A bifurcação é escolhida depois do evento.
- **Herói e arena:**
  - Recargas das habilidades na HUD, e o nome da habilidade sobre o herói 1 s antes de ela disparar.
  - Na arena, o herói caça atiradores e estruturas.
  - O teleporte custa 2 de elixir.
- **Interface:**
  - Clique em qualquer parte da carta.
  - Dica do local no mapa grande.
  - Compêndio no menu.
- **Estrada:** trechos retos, sem piscar.
- **Testes:**
  - 0 falhas headless, com testes novos para disputas, atos, relíquias, eventos, ofertas, aviso de habilidade e arena.
  - Fuzz sem falhas.
  - O `--uitest` está igual à versão anterior: só o arrastar falha, como antes.
  - O `--menutest` não rodou neste ambiente, nem na versão anterior.
- **Balanceamento:** o bot bom ainda não supera o aleatório. Os números são um meio-termo (ver o doc).
- **Arte:** o estudo de RoR2, Soulstone e Megabonk está em `docs/ESTUDO_DE_ARTE.md`. A direção D (Aventura, dia) é o padrão; as outras seguem em Configurações → Visual.
- **Capturas novas:** `--offerat=2 --offer=relic`, `--offer=event[:id]`, `--offer=contest:<tavern|fountain|ritual|shrine|bridge>`, `--menu=compendium`.

## Rodada de balanceamento e bugs (09/11/2026)

Feita numa tarefa agendada, com você fora. Tudo está no branch **`balanceamento-2026-11-09`** (a `main` não mudou). Relatório completo, com números de antes e depois, pendências e decisões que tomei no seu lugar: `docs/RODADA_BALANCEAMENTO_2026-11-09.md`.

- **5 bugs corrigidos, cada um com teste:**
  - sacrificar girava a mão de graça e sem limite durante a recarga (dava para cavar o deck atrás da melhor carta);
  - soltar uma carta fora da janela a jogava longe da tela;
  - clicar na bandeja do elixir com uma carta selecionada jogava a carta atrás dela;
  - os modos de teste sobrescreviam a sua run salva e o Pacto escolhido;
  - a mão passava de 9 cartas.
- **Balanceamento** (720 runs, mesmas sementes): quem joga ao acaso vence **12%** (era 34%; 18% em outras sementes, meta < 10%). O bot bom vence **64%** (meta 50–65%). Mudanças: corpo a corpo dos monstros ×2,0, Tesouro com heróis +25% de vida e 7 de elixir, Mímico custa 4, Arqueiros DPS 7, estrada de 1400 m. Planilha atualizada.
- **Testes novos:** `--chaostest` (entrada real esquisita) e `headless/fuzz.tscn` (decks e comandos absurdos). Todos os testes passam.

## Mapa de rotas escolhidas (09/11/2026)

A estrada virou uma **rede de caminhos** e **você escolhe por onde o herói vai**: em cada bifurcação o jogo pausa e o mapa grande abre (clique num local, teclas 1–3 ou L1/R1 + A no controle); dá para planejar vários trechos clicando num local mais à frente, no mapa ou na faixa. Os ramos não escolhidos ganham uma barreira. **Todo local é bom para você:** a Vila virou **Loja** (paga com o ouro que o dano no herói rende) e a Fonte cura os seus monstros. Ponte Quebrada e Placa Falsa saíram; Queimar Vila virou **Incêndio**. Testes: 0 falhas, mais `--uitest`, `--menutest`, `--tiptest` e o novo `--routetest` OK. Lote de 720 runs: Heurístico 55%, Aleatório 32%. Detalhes em `docs/MAPA_DE_ROTAS.md` e `DECISOES.md`.

- Capturas: `--routewait=1` (espera a escolha na primeira bifurcação), `--offerat=2 --offer=shop` (Loja com 200 de ouro; `shop:0` sem desconto).

## Grupo de heróis, sem XP (09/11/2026)

A run agora tem **5 heróis em fila** (estrada e arena) e **nenhum XP**: cada queda traz o próximo, um nível acima, com uma habilidade a mais e uma oferta de 1 entre 3. A barra "Seu poder" saiu; a HUD mostra "Herói k de 5". Testes: 0 falhas. Lote de 144 runs: Heurístico ~51%, Aleatório ~36% (Tesouro 71%, alto demais). **Falta:** passar o ajustador, refazer as metas, atualizar a planilha e jogar com janela (chegada e câmera não vistas). Detalhes em `DECISOES.md` e `docs/GRUPO_DE_HEROIS.md`. Os números de balanceamento das seções abaixo valem para o jogo de um herói só e estão superados.

## Estado (06/11/2026)

O MVP está jogável do começo ao fim, com arte, áudio e interface polidos. Os números estão sendo ajustados pelo bot na branch `balance`.

| Área | Estado |
|---|---|
| Simulação separada do visual (determinística, passo fixo, headless) | ✓ ~1,5–2 s por run de 12 min |
| Estrada com bifurcações, 6 locais com cenário próprio, faixa de rota e mapa grande | ✓ |
| Escudeiro: IA por pontuação, escudo frontal, 15 upgrades, falas | ✓ |
| 32 cartas, 7 arquétipos, 5 modificadores, 8 contratos, santuários | ✓ |
| Arena: chefe em 4 partes, 5 altares, teleporte, 6 finalizações | ✓ |
| Os 5 perfis de bot (Aleatório, Guloso, Heurístico, Economista, Enxame) | ✓ |
| Ajustador automático (branch `balance`, um commit por ciclo) | ✓ |
| Arte: shader de paleta única, modelos low-poly, cenário espalhado, covil, arena | ✓ peças por código, prontas para trocar por modelos do Blender |
| Efeitos: partículas, orbes de alma voando até o herói, tremor, flashes | ✓ |
| Interface na direção "Covil" (08/11/2026): molduras de ferro e bronze por shader, Cinzel e Alegreya Sans, cartas novas com retratos 512x384 e 17 ícones redesenhados, gemas facetadas, frascos de elixir, menu sobre o covil com brasas, mapa com legenda. Ver `docs/REVISAO_VISUAL.md` e `docs/visual/galeria.html` | ✓ mouse, teclado e controle; a pele antiga segue em Configurações → Visual (HUD "Clássica (a antiga)") |
| Configurações (áudio, vídeo, jogo, controles), salvas em `user://settings.cfg` | ✓ |
| Áudio: efeitos e trilha em camadas que cresce até o covil, trilha da arena | ✓ sintetizados (provisórios) |
| Controles: mouse (clique ou arrastar), teclado, controle | ✓ |
| pt/en pela tradução da Godot | ✓ |
| 500 unidades | ✓ 90 FPS em média, 74 no mínimo, com a arte final (RTX 2060) |
| Testes, teste da entrada real, executável exportado | ✓ |

## Revisão visual (08/11/2026)

A interface foi refeita numa direção só, chamada "Covil": ferro escuro, aro de bronze, gemas violeta, Cinzel nos títulos e Alegreya Sans no texto. Passou por rodadas de captura e crítica independente. O que mudou, as notas de cada rodada, as decisões e os riscos estão em `docs/REVISAO_VISUAL.md`; o antes e depois lado a lado está em `docs/visual/galeria.html`.

- Capturas de todas as telas (1920x1080 em tela cheia e 1280x720): `bash tools/capture_ui.sh <pasta>`. Galeria: `python -I tools/make_gallery.py <pasta>`.
- Para voltar à interface antiga: Configurações → Visual → HUD "Clássica (a antiga)". O backup de antes das mudanças está em `C:\Users\gabri\Desktop\LastBoss_backup_visual_2026-11-08\`.

## Deck que evolui e coleção (07/11/2026)

Cada local da estrada dá uma escolha para o deck (carta, nível, modificador ou remoção, com mais opções quando você vence a disputa do local), as cartas sobem até o nível 3, e fora da run as Almas desbloqueiam cartas numa coleção onde você monta o deck de 10. Os decks viraram Pactos (só regras). Detalhes, decisões e riscos no DECISOES.md, "Deck que evolui na run e meta-progressão".

- Testes: 0 falhas (inclui níveis, recompensas de local, recusa, coleção e salvamento com nível); `--menutest` e `--uitest` OK.
- Captura de uma oferta de local: `godot --path . -- --start=horde --offerat=2 --offer=ritual --shots=3 --quit=4 --out=<pasta>/` (também `fountain`, `bridge`, `fountain:0` para a disputa perdida). Coleção: `--menu=collection`.
- **Balanceamento fora das metas** (`reports/deck_v5/report.md`): bot bom 69% na Ruína, 23% na Horda e no Tesouro. Falta passar o ajustador.

## Qual versão jogar

- `main`: tudo, com os números da planilha mais as mudanças de regra.
- `balance`: o mesmo, com os números do ajustador. Pelo DECISOES.md, ela só entra na `main` depois que você jogar uma run com ela. Para jogar: `git checkout balance`, abrir na Godot e apertar F5. Os relatórios de cada ciclo ficam em `balance_reports/`.

## Balanceamento: onde parou (07/11/2026)

O herói agora tem no máximo 4 habilidades (uma a cada 4 níveis), o dano no herói rende 25% mais XP ao jogador (o dobro disso na arena) e as caixas de palavra-chave não pausam mais. Rebalanceado em seguida na `main` (detalhes e riscos no DECISOES.md, "Herói com menos poderes e rebalanceamento"):
- O perfil Heurístico (`data/bots/heuristic.json`) agora é o melhor bot encontrado pelo explorador.
- Lote final com os 5 bots (`reports/final_balance/report.md`, 720 runs): Heurístico vence **47%**, Aleatório **12%**, nota 0,25. Chegada à arena, níveis e desperdício dentro das metas.
- **Ainda fora:** o Tesouro jogado ao acaso vence 23% (vitórias cedo); Goblin Dinamiteiro e Teia aparecem em ~80% das vitórias, mas porque estão em dois dos três decks iniciais (a métrica conta as cartas iniciais); entre as cartas escolhidas, a mais presente é o Raio Cósmico, com 66%.

## Como rodar

O executável da Godot fica em `C:\Users\gabri\AppData\Local\Microsoft\WinGet\Packages\GodotEngine...\Godot_v4.7.2-stable_win64_console.exe` (abaixo, `godot`).

- Jogar: abra o projeto na Godot e aperte F5, ou rode `export/LastBoss.exe` depois de exportar.
- Testes: `godot --headless --path . res://tests/tests.tscn`
- Teste da entrada real (janela): `godot --path . -- --uitest=1` (cartas: tecla, balão, clique, sacrifício, oferta, carta ampliada, arrastar, mapa; com `--out=<pasta>` grava `uitest_*.png`) e `godot --path . -- --menutest=1` (menu, pausa, configurações, salvar e continuar) e `godot --path . -- --tiptest=1` (caixas de explicação: habilidade nova na HUD, caixa do ícone, palavra aninhada, jogo seguindo com a caixa aberta, carta da mão só depois de parar nela). O `--tiptest` move o cursor de verdade: o RichTextLabel acha a palavra pela posição real do mouse, não pela do evento.
- Capturas da interface: `--menu=decks|settings --tab=controls`, `--start=horde` (run sem bot), `--offerat=3`, `--pauseat=3`, `--hint=start`, `--skip=arena`, `--seed=7` e `--set=ui_scale:1.15,language:en` (só nesta execução), sempre com `--shots=5 --quit=6 --out=<pasta>`
- Ver um bot jogando: `godot --path . -- --autoplay=heuristic --deck=ruin --speed=2`. Também aceita `--skip=600`, `--quit=60` e `--shots=10,30 --out=<pasta>`.
- Estresse: `godot --path . --disable-vsync -- --autoplay=random --stress=500 --quit=25`
- Lote: `python -I tools/run_batch.py --bots heuristic,random,greedy --runs 60`
- Teste de caos com a entrada real (janela): `godot --path . -- --chaostest=1`
- Fuzz da simulação: `godot --headless --path . res://headless/fuzz.tscn -- --seeds=1-100`
- Rastro do herói numa run de bot: `godot --headless --path . res://headless/replay.tscn -- --bot=swarm --deck=treasure --seed=5010`
- Testes e capturas com argumentos salvam em `user://test_run.save` e `user://test_meta.save` (nunca na sua run).
- Ajustador (na branch `balance`): `python -I tools/tuner.py --cycles 15 --runs 8`
- Regerar o áudio: `python -I tools/make_audio.py`
- Exportar: `godot --headless --path . --export-release "Windows Desktop" export/LastBoss.exe`

Controles (também na aba Controles das configurações): teclas 1–6 escolhem a carta e o clique posiciona (em qualquer ponto da tela, a pelo menos 3 m do herói), ou arraste a carta até o mapa. Clique direito, X+número ou arrastar até "Sacrificar" sacrifica. A faixa de rota, em pé na borda esquerda (início embaixo, covil em cima), mostra a estrada inteira; Ponte Quebrada, Placa Falsa e Queimar Vila também são jogadas clicando nela. M abre o mapa grande (ele abre sozinho com cartas de rota). Q/E ou clique trocam de altar na arena. A roda do mouse dá zoom, Espaço/Esc pausa e F muda a velocidade. No controle: L1/R1 escolhem, o analógico direito move o cursor, A confirma, segurar B sacrifica, Select abre o mapa grande, o direcional troca de altar e Start pausa.

## O que fica para depois

1. Modelos e animações do Blender (Quaternius/Kenney) no lugar das peças por código, começando pelo herói e pelo chefe.
2. Trilha e efeitos sonoros finais (os atuais são sintetizados).
3. Exploradores (bots que evoluem procurando estratégias que quebram o jogo).
4. Tutorial guiado (as dicas da primeira vez já existem).
5. Testes com pessoas: o bot mede equilíbrio, não diversão.
