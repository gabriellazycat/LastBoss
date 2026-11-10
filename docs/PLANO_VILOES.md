# Last Boss — Vilões, baralho com descarte, elixir em escada, ritmo e revisão visual

## Contexto

Depois de jogar a versão de 10/11, o Gabriel pediu: correções de interface (loja estourando a tela, popup que trava o mouse, "Seu covil" em todo ato, raridades misturadas, estradas empilhadas); um redesign estilo Slay the Spire (escolher um **vilão** com cartas exclusivas, em vez de um Pacto sobre o pool inteiro); sensação de poder no fim da run (mais elixir, cartas caras); menos caminhada e mais disputa; remover cartas presas à arena; e refazer artes e visual dos upgrades. Na segunda revisão pediu que eu caçasse furos de design, planejasse a fase final de testes e balanceamento, e dividisse o trabalho por modelos mais leves para economizar tokens.

Motor: Godot 4.7.2, interface em GDScript, números em `data/*.json`, textos em `locale/strings.csv`. O JSON é a fonte da verdade (não rodar `tools/xlsx_to_json.py`).

## Decisões fechadas com o Gabriel (grilling, 10/11)

| Tema | Decisão |
|---|---|
| Vilões | **3**: Rainha da Praga (Bando + feras), Dragão Avarento (Fogo + Ganância), Lich (Morte + Corrente) |
| Pool | **24 exclusivas por vilão + 12 comuns** = 36 por run (84 cartas no total; ~45 novas) |
| Chefe | Modelo 3D próprio por vilão, com as mesmas 4 funções de hoje. Regras da arena não mudam |
| Remoção | 6 Finalizações + Muralhas do Covil, e o que depende delas (`passage_stone`, `no_witnesses`, opção "blood" do `profane_altar`) trocado por conteúdo que vale na estrada |
| Cartas de Covil | Deixam de ser permanentes com limite: viram **efeito temporário** (ex.: Coletor = +X% de elixir por N s) e ficam no ciclo como qualquer carta. Funcionam também na arena |
| Cartas de Rota | Saem do baralho **só durante a arena** |
| Elixir | Jogador constrói (cartas temporárias, relíquias, locais) + **degrau permanente por ato**. Teto 20 |
| Custos | Revisão de todos, faixa 0 a 12. Custo 8 e 9 só em ofertas a partir do ato 2; 10 a 12 só no ato 3. Raras de custo 0 que voltam para a pilha de compra |
| Baralho | Compra → mão → descarte → embaralha o descarte quando a compra acaba. Contadores de compra e descarte clicáveis, sem revelar a ordem |
| Mão | **5 para todos**, crescendo na run (+1 por relíquia ou por carta temporária como a Biblioteca), teto 7. A Praga troca a regra "mão de 6" (`boss_lorde.json:58`) por outra passiva ligada a enxame; `HAND_MAX` 9 → 7 em `sim.gd:50` |
| Raridade | Uma só por oferta de recompensa/escolha. **A loja fica de fora** (preços variados) |
| Desbloqueio | Praga livre; Dragão na fase 1; Lich na fase 2. Liberar um vilão entrega suas comuns e incomuns; Almas compram só raras e lendárias |
| Fim de ato | Atos 1 e 2 terminam num portão de passagem; castelo e "Seu covil" só no ato 3 |
| Estrada | Pintada no próprio chão, ramos fundidos como terra, sem faixas empilhadas |
| Ritmo | 300 m por ato (era 600), mesmos 7 a 8 locais; cada local é uma **disputa em 3 momentos** (~40 a 50 s); run continua em ~25 min |
| Artes | Primeiro 5 cartas de amostra em render 3D com traço de nanquim; o método das demais se decide depois |
| Upgrades | Vitrine com redesenho em variações para ele escolher |
| Modelos no mapa | Das ~20 criaturas/estruturas novas, modelo próprio e animado para ~9 cartas-chave (3 por vilão, incluindo as de custo 10 a 12); as demais são variantes de modelos existentes (tamanho, cor, adereço) |
| Git | Commits liberados na branch `viloes` e em branches de worktree dos agentes; **main intacta, sem push**; o merge na main é decisão dele no fim |
| Ordem | Primeiro tudo o que ele decide; depois trabalho corrido sem perguntas |

## Regras de design que assumi para fechar furos (anotar no relatório final)

- **Raridade sem opções suficientes**: a oferta inteira cai para a raridade vizinha, nunca mistura. A lista de cartas garante ao menos 4 comuns, 4 incomuns e 3 raras por pool de run.
- **Trava contra laço infinito**: carta que "volta para a compra" só pode voltar uma vez por embaralhada; reembolso de elixir por sacrifício (Banquete de Almas) limitado por uso; fuzz com baralho mínimo cobre isso.
- **Cartas-ponte**: cada vilão recebe 3 a 4 cartas que ligam suas duas metades (ouro ↔ fogo; sacrifício ↔ feitiço; ratos ↔ feras). A Praga, que tem só 6 cartas de base, recebe a maior parte das novas.
- **Dono em tudo**: relíquias, contratos e eventos ganham `owner` (vilão ou comum), como as cartas.
- **Disputa em 3 momentos**: recompensa por degraus (0 etapas = nada; 1 ou 2 = ouro; 3 = recompensa cheia). Nenhuma etapa beneficia o herói.
- **Raras iniciais**: cada vilão vem com 3 raras liberadas, para ofertas raras existirem desde a primeira run; lendárias só por Almas. A calibração roda com o pool completo e confere que o pool inicial fica a no máximo 5 pontos de vitória abaixo.
- **Variação nas disputas**: a 3ª etapa de cada tipo de local muda por ato, para os ~24 locais da run não repetirem a mesma disputa.
- **Sacrifício**: passa a render uma fração do elixir máximo, em vez de +1 fixo.
- **Efeitos que expiram**: mão extra que acaba não expulsa carta (a vaga só deixa de ser reposta); elixir acima do máximo que encolheu é cortado.
- **Arena com baralho curto**: se tirar as cartas de Rota deixar menos cartas que a mão, a mão encolhe até o tamanho do baralho.
- **Save**: migração `horde` → Praga, `ruin`/`treasure` → Dragão, `crypt`/`cult` → Lich; Almas preservadas; run em andamento da versão antiga é descartada.
- **Poder percebido**: o herói também escala por ato, mas menos que o jogador; a meta é o jogador gastar no ato 3 ao menos 2× o elixir por minuto do ato 1 e vencer disputas com folga visível.

## Etapa A — Pacote de decisões (entregar, PARAR e esperar)

Tudo em `docs/decisoes_2026-11-10/index.html`.

1. **5 cartas de amostra** (render 3D + nanquim): Toca de Ratos, Carniçal, Diabretes de Fogo, Tocha, retrato da Rainha da Praga. Blender com o kit de `tools/art/blender_v2/` (`mk.py`, `monsters.py`, `build.py --preview`), contorno Freestyle + hachura, composto na moldura real (`UiDiario.card`). 2 a 3 variações de traço, ao lado do desenho atual.
2. **Vitrine de upgrades**: mesma carta em base, N2, N3, 5 modificadores e combinações; coluna "hoje" (`card_fx.gd`) e 3 propostas novas. Gerada por captura do jogo.
3. **Lista de cartas** `CARTAS_VILOES.md` + aba na planilha (script novo `tools/export_cards_xlsx.py`, JSON → planilha): por vilão, ideia central, 3 combos, cartas-ponte, e cada carta com custo antigo → novo, raridade, efeito, ato em que aparece. Inclui comuns, temporárias de elixir e custo 8 a 12.
   - Praga (base): rat_horde, rabid_rats, pack_call, rat_burrow, bat_nest, rat_king, werewolf, slime + ~16 novas.
   - Dragão (base): goblin_dynamiter, boiling_oil, oil_splash, torch, fire_imp, tar_net, burn_village, mimic, gold_bait, gold_merc, toll, cursed_coins + ~12 novas.
   - Lich (base): skeleton_archers, bone_totem, bone_legion, ghoul, corpse_blast, soul_harvest, soul_feast, scrap_golem, shadow_bolt, cultists, arcane_spark, shadow_echo, acolyte, shadow_mark, ghost, forbidden_library + ~8 novas.
   - Comuns: ogre, gargoyle_tower, web, soul_collector, dark_forge + ~7 novas.
4. **Esboço dos 3 chefes**: blockout no Blender com a divisão em 4 partes.
5. **Página "Regras novas"** (é a última chance de veto antes do trabalho corrido): passiva de cada vilão; as 3 etapas de cada tipo de local e a variação por ato; curva de elixir, mão e custo liberado por ato; travas contra laço; quais das ~20 criaturas novas ganham modelo próprio.

A Etapa B roda em paralelo. Ao fim: apresentar o `index.html` e esperar.

## Etapa B — Correções (não dependem de decisão)

- **Popup que trava** — `game/tips.gd`: caixa de nível 1 aberta por `attach` não se mantém viva só por ter o mouse em cima; preferir posição que não cubra vizinhos com `attach` (acima/abaixo antes de à direita, `_open` 298-315); `MOUSE_FILTER_IGNORE` fora das áreas de palavra-chave (`_wire`, 182); fechamento em `_process` (366-398). Caso novo no `--tiptest` (`main.gd:1094`): duas cartas lado a lado.
- **Loja** — `game/hud.gd:1075-1079`, `1185-1189`: colunas limitadas pela largura útil, 2 linhas (cartas; serviços), quebra de texto no rótulo de preço, `ScrollContainer` no `shop_pick`. Corrigir `UI_SHOP_WON` e o texto do item "remover" (1145).
- **Fim de ato** — condição `sim.act + 1 >= sim.acts()` em `game/minimap.gd:238/372`, `game/route_strip.gd:162-184`, `game/world_view.gd:624`. Portão novo + chaves `UI_MAP_ACT_END`, `UI_STRIP_ACT_END`.
- **Raridade única** — sortear uma vez por oferta em `sim/sim.gd`: `_offer_level` (1929), `_card_options` (1875), `_offer_contract`, `effects.gd:24-32`, relíquias (532); `_open_shop` (1837) fica como está. Atualizar `t_determinism`, `t_offer_single_type`.
- **Estrada fundida ao chão** — hoje `world_view.gd:_build_road` (373-389) cria uma malha por trecho com `lift` próprio e `GroundLooks.road_mesh` (`game/art/ground_looks.gd:323`) dá borda a cada uma. Trocar por máscara única: rasterizar `sim.road.legs` numa `Image` de distância ao eixo (máximo entre trechos, sobre `_road_bounds()`) e misturar a estrada no shader do chão, com borda suave e ruído; segundo canal para o realce de rota (`world_view.gd:1302`).
- **Heróis do menu** — `game/menu.gd:709`, `game/desk_scene.gd:400`: um desenho por classe, com fallback até a arte chegar.

## Etapa C — Sistemas (depois das escolhas, sem perguntas)

`sim/sim.gd` (2223 linhas) é tocado por quase tudo: **um só escritor por vez**, na ordem abaixo.

0. **Preparação para paralelizar** — extrair os efeitos de carta de `sim.gd:_apply` (1413-1635) para `sim/cards/common.gd`, `plague.gd`, `dragon.gd`, `lich.gd` (um arquivo por dono, mesma assinatura), sem mudar comportamento (replays idênticos antes/depois). Bots passam a decidir por dados da carta (`archetype`, `type`, `cost`, `tags`, novo campo `ai` opcional) em vez dos ~50 ids fixos (`bots/player_bot.gd:57-200, 355-379`, `human_bot.gd:210-318`).
1. **Remoção** — as 7 cartas, `category: finisher`, `finisher_ready` (`sim.gd:1284-1309, 1613-1635`), `lair_walls` (625), e os 3 dependentes.
2. **Baralho com descarte** — `queue` → `draw` + `discard`; `_cycle` (1368); embaralhar com `rng`; `fx.returns` com a trava; usos de `queue` (515-519, 1610-1635, 2088-2150). Cartas de Rota fora do ciclo em `enter_arena` (595).
3. **Vilões e pool** — `data/villains.json` substitui `boss_lorde.json.decks`; `owner` em cartas, relíquias, contratos, eventos; filtro em `setup` (108-155), `_pick_card`/`_card_ok` (1713-1729), `effects.gd`; `headless/batch.gd:37` usa o pool do jogador. `MetaSave` (`pact` → `villain`, migração, remover deck montado morto), `SaveGame.VERSION` 4, `data/campaign.json`, `data/meta.json`.
4. **Elixir e Covil temporário** — `rules.json`: degrau por ato, teto 20; `locked.json` liberado; `soul_collector`, `dark_forge`, `forbidden_library` e as novas viram efeitos com duração; filtro de custo por ato nas ofertas. Limiares dos bots como fração do máximo.
5. **Ritmo** — `acts[].road.target_length` 300; espaçamento em `sim/road.gd`; alcances de Isca/Incêndio; disputas em 3 etapas (`sim.gd:282-395`, `rules.locations.*`).
6. **Cartas novas e custos** — conforme a lista aprovada, cada vilão no seu arquivo de `sim/cards/`; textos `CARD_/DESC_/N3_` pt e en; `game/tutorial.gd`.

Interface, em paralelo (arquivos próprios): seleção de vilão (`game/menu.gd`, `collection.gd`, `compendium.gd`); montes de compra/descarte e barra de 20 (`game/hand_fan.gd:411`, `game/elixir_bar.gd`, custo de 2 dígitos em `ui_diario.gd:452`); HUD da disputa em 3 etapas (`hud.gd:358`); oferta de upgrade antes → depois (`hud.gd:1114-1124`).

## Etapa D — Arte em massa e chefes

- ~91 imagens no método aprovado (84 cartas, 4 heróis, 3 retratos). Remover `art`/`model` emprestados de `cards.json`. Teste: nenhuma carta compartilha imagem.
- **Modelos de jogo das criaturas novas**: ~9 próprios com animação (pipeline `monsters.py` → `anims.py` → `vat.py` → `import_v2.gd`, saída em `assets/models/v2/`); ~11 variantes registradas em `game/art/looks.gd`/`card_model.gd` (escala, tinta, adereço). `rat_burrow`, `ghoul` e `fire_imp` deixam de usar modelo emprestado também no mapa.
- 3 chefes (`tools/art/blender_v2/boss.py` como base) → `assets/models/v2/boss_<vilão>_*`, ligados em `Models.boss_full()` e na arena.
- Variação de upgrade escolhida aplicada em `game/card_fx.gd`.

## Etapa E — Testes e balanceamento (fase final)

**Pré-requisitos**: passo C0 (bots por dados), batch com o pool do jogador, e métricas novas em `headless/batch.gd`/`tools/run_batch.py`: elixir gasto por minuto por ato, cartas jogadas por minuto por ato, maior custo jogado, % do tempo sem carta jogável (mão travada), etapas vencidas por disputa, tempo andando × em disputa, embaralhadas por run.

1. **Testes automáticos** (`tests/tests.gd`) — atualizar os que fixam pool 48, decks prontos, 2,8 s, mão da Horda, elixir do Tesouro. Novos: `owner` válido em tudo; pool por raridade suficiente ou rebaixamento correto; ciclo compra/descarte conserva o número de cartas; trava de laço; custo por ato; migração de save; arte única.
2. **Fuzz** — `headless/fuzz.tscn` seeds 1-200 × 3 vilões, incluindo baralho mínimo.
3. **Calibração, uma variável por vez, nesta ordem** (cada passo: lote de 150 runs por vilão × fase com o bot humano, no máximo 3 iterações):
   1. Curva de elixir e custos → meta de gasto 2× no ato 3; mão travada < 5% do tempo.
   2. Duração das disputas → run em 23 a 27 min; ao menos 60% do tempo em disputa.
   3. Vida dos heróis por vilão × fase → vitória do bot humano em 50 a 65%, aleatório ≤ 10%, diferença entre vilões ≤ 5 pontos.
   4. Cartas fora da curva → presença em vitórias > 70% ou escolha < 5% são ajustadas. Primeiro alvo: estruturas, poças e dano em área, que mudam de valor com o herói parado 60% do tempo.
   5. Arena → chegada e duração dentro de `rules.goals`.
4. **Carga** — `--stress` com a quantidade de unidades do ato 3 (elixir 20, cartas de 12): manter a taxa de quadros; se cair, teto de unidades em campo. Ferramentas `tools/tune_campaign.py`/`tune_human.py`/`run_batch._starters` atualizadas de Pactos para vilões antes dos lotes.
5. **Teste com mouse** — `--humantest=human` com cada vilão; `--tiptest`, `--menutest`, `--uitest`.
5. **Passe visual** — `tools/capture_ui.sh` + `--offerat=2 --offer=shop` em 1280x720 e 1600x900, `ui_scale` 0,8 e 1,15: nada fora da tela; antes/depois em `docs/visual/`.
6. **Relatório** `docs/RODADA_VILOES.md`: números finais, decisões assumidas, riscos, e o que falhou em atingir a meta. Planilha regenerada do JSON.

Entre os passos da Etapa C: só um lote de fumaça (30 runs) para pegar quebra; calibrar de verdade apenas aqui.

## Orçamento de tokens e calendário (revisão de 10/11)

Medido em 10/11: plano Pro; **semanal geral 79% usado** (restam 21%, zera em 14/11 00:59 de Brasília); semanal Fable 10% usado. O gargalo é a barra geral, não a do Fable. **Nada do plano foi removido nem reduzido**: todas as etapas A a E valem como descritas acima, na mesma ordem. Esta seção só define como cada tarefa é executada para gastar menos. Se o limite acabar, o trabalho pausa no fim do passo corrente e continua depois do reset.

**Princípios**

1. **Paralelizar economiza tempo, não tokens**: cada agente começa do zero e relê arquivos. Por isso tarefas vizinhas são agrupadas num mesmo agente (popup + loja; os 3 blockouts; arte + modelo do mesmo vilão) e cada brief já traz arquivo e linha.
2. **Sessões curtas**: cada etapa começa numa sessão nova, tendo este arquivo como único contexto (a sessão de planejamento já carrega 235 mil tokens, relidos a cada chamada). Uma etapa = uma sessão; ao terminar, 5 linhas de estado no fim deste arquivo.
3. **Script no lugar de raciocínio**: lotes de bots, `tuner.py`, testes e capturas rodam em segundo plano e devolvem só tabela-resumo ou falhas; ninguém lê `runs.json` nem log inteiro.
4. **Cartas por dados**: as ~45 cartas novas são montadas com primitivas de efeito genéricas (invocar, dano em área, estado, reforço com duração, ganho de elixir, gatilho ao morrer/jogar) declaradas em `cards.json`; código novo só para o que nenhuma primitiva cobre. O passo C0 continua como descrito (efeitos por dono em `sim/cards/*.gd`, bots por dados) e ganha `sim/card_fx_lib.gd` com as primitivas.
5. **Arte por receita**: um script Blender headless gera a carta a partir de parâmetros curtos por carta (modelo, pose, câmera, cor); revisão em pranchas reduzidas de 12 a 20 cartas, não imagem por imagem; no máximo 2 rodadas de ajuste por prancha. Sem laço de `look` pelo MCP fora das 5 amostras.
6. **Modelo por tarefa**: Fable só para lista de cartas, regras, integração do núcleo e decisões de balanceamento; Sonnet para implementação delimitada; Haiku para textos pt/en, planilha, variantes de modelo e documentos.
7. **Sem reexploração**: nenhum agente Explore/Plan novo; os números de linha deste plano são o mapa.

**Como cada tarefa é executada** (todas as tarefas do plano, na ordem das etapas)

| Tarefa | Quem | Modo | Instrução de economia |
|---|---|---|---|
| A1 5 cartas de amostra | Fable | sessão, MCP do Blender | define a receita de traço que a Etapa D reaproveita; `look` em tamanho reduzido |
| A2 Vitrine de upgrades, 3 variações | Sonnet | 1 agente em worktree | recebe `card_fx.gd` e a lista de estados; entrega capturas, não descrição |
| A3 Lista de cartas + planilha | Fable escreve; Haiku faz `export_cards_xlsx.py` | sessão + 1 agente | texto puro, sem ferramentas; planilha gerada por script |
| A4 Blockout dos 3 chefes | Sonnet | 1 agente, Blender headless, os 3 no mesmo script | uma prancha com os 3, não 3 agentes |
| A5 Página "Regras novas" | Fable | sessão | sai junto da lista de cartas, mesmo raciocínio |
| B Popup (`tips.gd`) | Sonnet | 1 agente | brief com as linhas deste plano; valida com `--tiptest` |
| B Loja (`hud.gd`) | Sonnet | mesmo agente do popup, em seguida | valida por captura `--offer=shop` |
| B Fim de ato + portão + estrada no chão | Sonnet | 1 agente (arquivos de mundo e shader) | capturas antes/depois nas 3 texturas de chão |
| B Raridade única (`sim.gd`) | Fable | sessão, em série | mudança pequena e sensível ao RNG; roda `tests.tscn` |
| B Heróis do menu (encaixe) | Haiku | 1 agente | troca de constante + fallback |
| C0 Efeitos por dono + primitivas + bots por dados | Opus | 1 agente em worktree | critério de aceite: replays idênticos antes/depois |
| C1 a C5 Núcleo (remoção, descarte, vilões, elixir, ritmo) | Fable | sessão, um passo por vez, nova sessão a cada 2 passos | lote de fumaça de 30 runs por script após cada passo |
| C Interface (vilão, montes, barra, HUD da disputa, antes → depois) | Sonnet | 2 agentes: menus; HUD | arquivos sem sobreposição com o núcleo |
| C6 Cartas novas | Sonnet | 3 agentes, um por vilão | quase tudo em JSON com as primitivas; cada um dono de um arquivo |
| Textos pt/en, tutorial, docs desatualizados | Haiku | 1 agente por lote | recebe a lista aprovada e devolve só as linhas do CSV |
| D Arte em massa | Sonnet | 3 agentes, um por vilão, Blender headless | receita da A1; revisão em pranchas de 12 a 20 |
| D ~9 modelos animados | Sonnet | os mesmos 3 agentes de arte | o modelo da carta é o do jogo: um trabalho, dois usos |
| D ~11 variantes | Haiku | 1 agente | tabela de escala, tinta e adereço |
| D 3 chefes finais | Opus | 1 agente por chefe | parte do blockout aprovado |
| E Testes novos | Sonnet | 1 agente | devolve só falhas |
| E Lotes e resumo | script + Haiku | segundo plano | tabela-resumo, nunca `runs.json` |
| E Decisões de número | Fable | sessão | uma variável por vez, no máximo 3 iterações |
| E Carga, teste com mouse, passe visual, relatório | Sonnet roda; Fable escreve o relatório | 1 agente + sessão | capturas em prancha reduzida |

Se o limite acabar: parar no fim do passo corrente, anotar o estado no fim deste arquivo e retomar após o reset. Nunca deixar `sim.gd` pela metade.

## Divisão de trabalho e modelos

Regra geral: Fable (sessão principal) decide design e integra; Sonnet executa trechos bem delimitados; Haiku faz o mecânico. Agentes de escrita em worktree próprio, um dono por arquivo. A tabela "Como cada tarefa é executada" acima é a referência de quem faz o quê; a tabela abaixo fica como mapa de donos de arquivo.

| Trabalho | Modelo | Paralelo com | Arquivos de que é dono |
|---|---|---|---|
| Lista de cartas, combos, custos | Fable | A2-A4, B | docs |
| Receita de arte + 5 amostras (MCP do Blender: uma instância, um agente) | Fable | A1, B | `tools/art/` |
| Vitrine de upgrades (3 variações) | Sonnet | tudo de A e B | `card_fx.gd`, cena de vitrine |
| Blockout dos 3 chefes (Blender headless) | Sonnet ×3 | tudo de A e B | `tools/art/blender_v2/boss_*.py` |
| B: popup | Sonnet | demais de B | `tips.gd` |
| B: loja | Sonnet | demais de B | `hud.gd` |
| B: fim de ato + estrada no chão | Sonnet | demais de B | `minimap.gd`, `route_strip.gd`, `world_view.gd`, `ground_looks.gd`, shaders |
| B: raridade única | Sonnet | demais de B | `sim.gd` (único escritor em B) |
| C0-C5: núcleo da simulação | Fable (C0 e C2 podem ir para Opus) | interface | `sim/*.gd`, `data/*.json` |
| C: seleção de vilão, montes, barra, HUD da disputa | Sonnet ×3 | núcleo | arquivos de `game/` listados |
| C6: cartas novas, um agente por vilão | Sonnet ×3 | entre si (após C0) | `sim/cards/<vilão>.gd` |
| Textos pt/en, planilha, docs desatualizados, galerias | Haiku | qualquer | `strings.csv` (um por vez), `tools/export_cards_xlsx.py` |
| Bots por dados | Sonnet | C6 | `bots/*.gd` |
| D: arte em massa, um lote por vilão (Blender headless) | Sonnet ×3-4 | chefes | `assets/cards/` |
| D: ~9 modelos animados de criaturas | Sonnet ×3 (um por vilão) | arte, chefes | `tools/art/blender_v2/`, `assets/models/v2/` |
| D: ~11 variantes de modelo | Haiku | qualquer | `game/art/looks.gd`, `card_model.gd` |
| D: 3 chefes finais | Opus ou Sonnet ×3 | arte | `assets/models/v2/` |
| E: rodar lotes e resumir em tabela | Haiku | — | `reports/` |
| E: decidir ajustes de número | Fable | — | `data/*.json` |
| E: testes novos | Sonnet | calibração | `tests/tests.gd` |

Economia de tokens: cada agente recebe o trecho deste plano com arquivo e linha (não reexplora o repositório) e devolve até 15 linhas; lotes de bots rodam em segundo plano por script, sem agente esperando; imagens revisadas em pranchas reduzidas, não uma a uma; `sim.gd` nunca com dois escritores.

## Riscos

- Toda a calibração de 10/11 é refeita (pool, baralho, raridade, ritmo e elixir mudam juntos).
- ~45 cartas novas + ~91 artes + 3 chefes 3D é o maior bloco; a qualidade da arte depende do método aprovado nas amostras.
- O efeito de Covil temporário precisa render mais que seu custo dentro da duração, senão ninguém joga; é o primeiro alvo do passo E3.1.
- Worktrees antigos ativos (`.claude/worktrees/*`, `../LastBoss-balance`) e `docs/visual/rodada_*` sem versionar: não mexer neles; todo o trabalho na branch `viloes`, main intacta, sem push.
- A numeração 5/6 dos passos de teste na Etapa E foi deslocada pela inclusão do teste de carga; seguir a ordem em que aparecem.
