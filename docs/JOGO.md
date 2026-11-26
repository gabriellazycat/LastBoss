# Last Boss: o jogo como ele é hoje

Este é o único documento de design do jogo. Ele descreve o que está no código **agora**. Se este texto e o código discordarem, vale o código, e este texto deve ser corrigido no mesmo commit.

O histórico (rodadas, planos, propostas, galerias) foi apagado em 24/11/2026 e fica só no git: `git log -- docs/`.

Fontes primárias:
- `data/*.json`: números e conteúdo;
- `sim/`: regras, lógica pura e determinística;
- `game/`: visual, UI e áudio.

## 1. O que é

O jogador é o **vilão**, que defende o próprio covil contra uma fila de grupos de heróis ("parties"). Ele joga cartas (monstros, enxames, estruturas e feitiços) com **elixir**, que se recarrega com o tempo, no campo em volta dos heróis enquanto eles marcham pela estrada até o covil. É um roguelike: cada run termina quando o covil cai, e as **Almas** ganhas compram melhorias permanentes.

Fluxo das telas:

```
Menu -> Covil (árvore radial) -> Escolher vilão -> Run -> Fim da run -> Menu (abre o Covil sozinho se dá para comprar algo)
```

O menu (`game/map_menu.gd`) tem Continuar, Covil, Biblioteca, Compêndio, Tutorial, Configurações e Sair. O lugar Covil abre a árvore de melhorias; "Começar run" dela leva à escolha de vilão, onde o clique só seleciona e o botão Começar inicia a run.
- **Volta da run:** as Almas contam até o saldo. Balões no Covil ("X Almas, N melhorias compráveis") e na Biblioteca ("N cartas novas") e selos com número que ficam até o lugar ser visitado (`MetaSave`: `almas_shown`, `covil_new`, `lib_seen`). Se há algo comprável, a árvore abre sozinha. As Almas têm cor própria (`UiParch.SOUL`), diferente do roxo do elixir. O tutorial é a fase 0 de `data/campaign.json`: 2 parties de escudeiro, sem Almas nem desafios.

## 2. A run

- **Uma fase de 15 parties** numa fila fixa (`data/campaign.json`, fase 1). Os tamanhos são 1, 1, 2, 2, 2, 3, 3, 3, 3 e depois 4 seis vezes. As classes entram aos poucos; da party 10 em diante as 8 se misturam.
- **Força:** a party 1 tem `hp_mult` 2,8 e `damage_mult` 1,0. Cada party seguinte multiplica os dois por `rules.party.step` = 1,17. A vida total da party é dividida entre os membros.
- **3 atos de estrada, depois a arena.** As estradas medem 340, 544 e 748 m, com 7 a 8 fileiras por ato (`rules.acts[].road`).
  - **O mundo é contínuo:** o cenário dos atos anteriores fica no mapa, estático (sem luz, partícula nem animação; cenário pequeno com `visibility_range` de 300 m). O castelo do covil já está visível no começo do ato 3.
  - No fim de cada ato a velocidade do jogo volta a 1×.
  - Unidades a mais de 150 m do herói que perseguem somem (`rules.sim.despawn_distance`).
  - **Estrada** (`sim/road.gd`): ramificada em fileiras. Nas bifurcações o jogador escolhe a rota (`Sim.choose_route`). O mapa é o minimapa em gravura, aberto com M.
  - **Rios** (`sim/rivers.gd`): 1 a 2 por ato, no máximo 5 pontes. O rio só cruza a estrada em locais, e todo local cruzado vira Ponte.
- **Arena** (`sim/arena.gd`, `data/boss_lorde.json`): ao fim do ato 3 o herói entra no covil.
  - O chefe tem partes: braços, cabeça e núcleo. Há altares e pilares, e o jogador pode se teletransportar.
  - Depois de 240 s começa a prorrogação: o herói não se cura mais, bate mais forte, e o elixir vem mais rápido.
  - **O núcleo destruído é a derrota** (`Sim.core_destroyed`).
  - **Derrubar a última party é a vitória:** `WIN` se acontece na arena, `WIN_EARLY` se ainda na estrada.
- **Party derrotada:** a seguinte chega (`arrive_s` 8 s) com um poder de party novo ou evoluído (seção 4). O jogador ganha uma **oferta de 1 carta entre 3**. O nó do Covil `ger_offer_hero` libera uma oferta também por herói morto.
  - Raridade das ofertas por ato (comum/incomum/rara/lendária): 65/25/9/1, 50/30/16/4 e 40/30/22/8 %.
  - A chance de a carta vir com nível maior cresce com o progresso (`rules.offer_upgrades`).
- **Duração:** ~45 min numa run que vai bem. Não foi medida com jogador.

### Locais (disputas) na estrada
Regras em `rules.locations`, recompensas em `rules.location_rewards`. Cada disputa tem **3 marcos**: o resultado é vitória, parcial ou falha, e a recompensa escala com os marcos.

Depois de cada local roda a **cena do local**: câmera lenta a 30 %, os selos dos marcos acendem e o efeito é proporcional ao resultado (`game/loc_seals.gd`). Em seguida vem a recompensa, e depois o mapa abre sempre.

| Local | Disputa | Recompensa |
|---|---|---|
| Taverna | derrubar as casas na janela de tempo (perdendo, as casas de pé continuam no mapa) | modificador para uma carta |
| Fonte | interromper o herói enquanto ele bebe (um guarda o protege) | remover cartas do baralho |
| Ritual | matar N criaturas na janela | elixir ×2 durante o ritual e melhoria de carta |
| Santuário | não deixar o herói ficar no santuário pelo tempo de vencer | carta rara ou melhor |
| Ponte (só nasce do rio) | meta de dano com o herói parado na ponte | cartas (comum, incomum, rara) |
| Loja do mercador | — | comprar cartas, melhorias, modificadores, remoção e 1 relíquia, com ouro (`rules.shop`) |
| Evento | texto com opções (`data/events.json`, ações em `sim/effects.gd`) | variável |
| Herói ajudante (1 por ato, numa bifurcação) | matar o herói parado no local dentro da janela; se falhar, o herói da vez ganha um bônus até o fim do ato | 1 relíquia entre 3 |

- **Ouro:** ganho por dano (`rules.gold.damage_per_gold` 40) e por disputa. É gasto na loja.
- **Contratos** (`data/contracts.json`): metas curtas com prazo, por vilão; a recompensa é uma carta.

## 3. Cartas, mão e elixir

- **Elixir** (`rules.elixir`): começa em 5, máximo 10, 1 ponto a cada 2,8 s, igual na run inteira.
  - Só as relíquias e o Covil aumentam o máximo e a regeneração.
  - Por ato mudam só o custo máximo das cartas ofertadas (7, 9, 16) e a regeneração (×1, ×1,05, ×1,10).
- **Mão:** 5 cartas, até 7 (`hand_size`, `hand_max`).
  - A carta jogada vai para o descarte, e a vaga fica vazia por um tempo antes de comprar a próxima.
  - Quando a pilha de compra acaba, o descarte é embaralhado e vira a nova pilha.
  - Só se joga a partir de `rules.ring.min` = 3 m do herói; feitiços ignoram esse limite.
  - **Mira:** feitiço é só o que mira um ponto, uma área ou um número limitado de alvos. Os de alvo único acertam o herói mais perto de onde a carta é solta (sem raio; nunca o líder automaticamente), e durante a mira esse herói ganha um anel dourado. Monstros jogados atacam o herói mais perto de onde nasceram e só trocam se ele cair ou passar de `engage_radius`; estruturas mantêm a regra própria.
  - **Temporário** (`lair`): efeito global, mas também é arrastado e solto no chão. Só a Finalização sai no clique. Viraram Temporário: Chamado do Bando, Grito de Guerra, Colheita de Almas, Instinto de Caça, Praga Bubônica, Pestilência Negra, Pedágio, Mensageiro Sombrio, Taxa de Sangue e Troca do Dragão. Eles não contam como feitiço para o Eco, o Apocalipse, descontos de feitiço nem as passivas do Lich.
- **Deck:** 19 cartas por vilão, até 3 cópias de cada (`MetaSave.DECK_SIZE`). É montado na Biblioteca com cartas do vilão e comuns liberadas. Ao longo da run cresce com as ofertas, a loja e os locais.
- **118 cartas:**

  | Arquivo | Cartas |
  |---|---|
  | `data/cards.json` | 41, de vários donos |
  | `data/cards_common.json` | 17 |
  | `data/cards_plague.json` | 25 |
  | `data/cards_dragon.json` | 25 |
  | `data/cards_lich.json` | 10 |

  - Tipos: `monster`, `swarm`, `structure`, `spell`, `route` e `lair`.
  - Cada carta tem `owner` (dono): plague, dragon, lich ou common.
  - O efeito vem dos dados (`ops`, `on_death`, `ai`) ou do código por id em `sim/cards/<dono>.gd`. Como montar uma carta: `docs/CARD_FX.md`.
- **Níveis I a VI** (`rules.card_levels`):
  - Cada nível dá +25 %.
  - O custo cai 1 no III e mais 1 no V.
  - O efeito especial `n3` só aparece no VI.
  - Os níveis permanentes são comprados com Almas na Biblioteca. Dentro da run há melhorias que somam a eles.
- **Modificadores** (`data/modifiers.json`): Veterano, Barato, Explosivo, Amaldiçoado, Sombrio e Rouba-vida.
  - **Explosivo:** ao morrer, acerta todos os heróis no raio (anel no chão do tamanho exato, evento `EXPLOSIVE_BOOM`). Tudo que a carta gera (spawn e `summon`) também explode.
  - As telas de modificar, melhorar, remover, transformar e copiar mostram a carta com os modificadores e o custo reais.
- **Peste** (Praga): cada acúmulo faz o herói receber +3,5 % de dano, até 30 acúmulos. Depois de 8 s sem golpe, cai 1 acúmulo por segundo. A Pestilência Negra põe no máximo.
- **Teia:** o herói dentro da zona fica lento e imune a empurrão.
- **Rei dos Ratos:** aura de 6 m (anel no chão) com +50 % de dano para todo o Bando, morcegos inclusive; as unidades buffadas brilham.
- **Vilões** (`data/villains.json`): **Rainha da Praga** (`plague`, com a regra de infestação), **Dragão Avarento** (`dragon`) e **Lich** (`lich`).
  - O Dragão é liberado ao derrotar a party 3 pela primeira vez; o Lich, ao derrotar a party 6.
  - `start_deck` é o deck inicial antes de o jogador montar o seu.

## 4. Heróis e poderes de party

- **8 classes** (`data/hero_classes.json`): escudeiro, arqueira, clériga, mago, assassino, bárbaro, besteiro e guardião. A IA fica em `sim/hero.gd`, e os modelos são KayKit (`game/art/hero_rig.gd`).
  - A arqueira tem `damage_mult` 1,2. Heróis à distância escolhem alvo até o próprio alcance (na arena e na impaciência também), e o seguidor à distância fica no alcance do alvo em vez de voltar para a coleira.
- **Poderes de party** (`data/hero_powers.json`, 21 poderes; motor em `sim/hero_powers.gd`):
  - Quando uma party inteira cai, a seguinte ganha 1 poder novo ou uma evolução (níveis 1 a 3; chance de evolução de 34 %).
  - O sorteio pesa mais os poderes que rebatem o tipo de dano que a party mais sofreu.
  - Os poderes acumulam na run toda. A evolução mostra cada número que mudou como "antes → depois".
  - **Grito de Guerra:** a barreira é completada até 12/18/26 % da vida máxima (não soma), recarga fixa de 18 s, +20 % de dano.
  - **Curandeira:** só cura em combate, a cada 20/18/16 s.
  - Os companheiros (rato, cão de guerra) usam os modelos de rato e lobo dos monstros, tingidos pela classe.
  - Gatilhos possíveis: contato com o primeiro inimigo, a próxima criatura, a próxima estrutura, o próximo feitiço, uma reação ao dano (maldição, vida baixa, controle, fogo, projétil, golpe forte) ou um intervalo de tempo (aliados).
  - Depois de qualquer disparo há um intervalo de 1,5 s, e cada poder tem a própria recarga.
  - O dano escala com o golpe do herói da party atual.
  - Na HUD, cada poder é um ícone com o timer de recarga sobre a party, e há um painel de revelação com pausa.
  - Textos: `POWER_<id>` e `POWER_<id>_d` em `locale/strings.csv`. Ícones: `assets/ui/powers/<id>.svg`.

## 5. Metaprogressão

- **Almas** (`MetaSave.almas_for`; constantes em `data/meta_tree.json` → `almas`):
  - Uma run rende `floor(dano / 300) + 8 × heróis mortos`, mais o bônus `geral.almas_mult`.
  - O dano só conta até a vida máxima de cada herói.
  - As Almas são mantidas ao perder.
- **Covil** (`game/covil_screen.gd`, `data/meta_tree.json`, efeitos aplicados em `sim/meta_apply.gd`):
  - Roda radial com **48 nós em 6 setores**: Atributos (elixir, mão, recarga), Locais, Arena (vida do chefe, braço, estruturas), Relíquias, Troca de ato (abre na 1ª vez que o jogador chega ao ato 2) e Geral (ouro, Almas, desconto, oferta por herói).
  - Cada nó tem pai.
  - O reembolso total é grátis.
- **Biblioteca** (estilo Hearthstone):
  - Tela 1: escolher o vilão (retratos, deck n/19, cartas liberadas). Tela 2: grade de 5 colunas com rolagem contínua (2 fileiras à vista), filtros de tipo (Comuns é um deles) e de custo, e o deck à direita em barrinhas. Clicar na carta adiciona, clicar na barrinha remove.
  - Compra de nível I a VI. Preço: `card_level_costs` × multiplicador de raridade.
  - Edição do deck de 19.
- **Relíquias** (`data/relics.json`, 52; ícones SVG em `assets/ui/relics/`):
  - 12 estão livres desde o início; as outras 40 são liberadas por desafio.
  - Níveis 1 a 3 comprados com Almas.
  - Ofertas de 3, com opções a mais pelo Covil.
- **Desafios** (`data/unlocks.json`, gerado por `tools/gerar_unlocks.py` a partir de `tools/desbloqueios.json`; editor em `tools/desafios_editor`, porta 8768):
  - 41 cartas livres e 53 desafios. Os fáceis pedem ~3× mais ou 2 a 4 runs; os de party pedem 8 e 11. As relíquias de party seguem 7/8/9/10/11/12/14.
  - Tipos: chegar à party N (recorde), total entre runs, em N runs, numa mesma run e jogada específica.
  - O progresso é gravado no fim de cada run, e a tela de fim mostra a revelação do que foi liberado (`game/unlock_reveal.gd`).
- **Saves:** `MetaSave` v5 fica em `user://meta.save`; um save mais antigo é zerado. A run em andamento usa `sim/save_game.gd` (v8). Os testes sempre usam caminho temporário.

## 6. Visual e áudio (o padrão é o único)

Cada sistema tem um visual só. As variantes que não foram escolhidas saíram do código em 24/11/2026.

- **Interface "Mapa aberto":**
  - Pergaminho, tinta e selos; o kit fica em `game/ui_parch.gd`.
  - HUD na disposição 7 (`game/hud.gd`): missão no canto, vida do grupo no alto, elixir na coluna direita, sem minimapa fixo e sem relógio.
  - O mapa (M) é o minimapa em gravura (`game/minimap.gd`), com os desenhos Nórdicos (`game/campaign_art.gd`).
- **Cartas:**
  - Arte gerada por IA em guache leve, um pincel só (skill `cartas-ia`). Os arquivos ficam em `assets/cards/` e o mapa id → arte em `data/card_art.json`.
  - Moldura em `game/card_mold.gd`.
  - O efeito de melhoria da carta fica em `game/card_fx.gd`.
- **Mundo em diorama ("brinquedo de madeira ao pôr do sol", branch `diorama-b`, 26/11/2026):** a estrada é um tabuleiro de tábuas pintadas com brinquedos de torno em cima (`game/art/diorama.gd`).
  - **Câmera:** lente de 30° a 52° para baixo, com a distância corrigida para mostrar a mesma área (`Diorama.cam_offset`), e tilt-shift forte por profundidade de campo na qualidade alta (`Diorama.focus`).
  - **Luz:** sol dourado baixo com sombras longas, luz quente rebatida e verniz de laca (`DIO` em `paint.gdshaderinc`: `dio_diffuse` e `dio_specular`; a mesa do menu e as cartas não definem `DIO`), AgX, SSAO e SSIL, sem névoa, fundo em degradê radial (`dio_backdrop.gdshader`). Vale nos 3 atos; o ato 1 é o afinado.
  - **Chão:** no ato 1, tábuas pintadas de verde com emendas e tinta gasta (`ground_tela.gdshader`, estilo 6), estrada de madeira crua (`road_tela`, estilo 6) e sem tufos de grama.
  - **Cenário:** regiões por ato, vento e bosques (`game/art/cenario.gd`, `mundo_vivo.gd`). No ato 1, árvores de torno (esfera, cone, ovo), arbustos de bolas e seixos (`assets/models/dio`); nos atos 2 e 3 ficam as pinceladas `arv5`/`arv6`.
  - **Taverna e casas da disputa:** blocos de brinquedo pintados com telhado em prisma (`tools/art/blender_dio/buildings.py`, estilo b); a frente da taverna vira para a estrada e a câmera.
  - **Arena:** cripta (`arena_look.gd`).
  - **Efeitos:** golpes em `golpes.gd`, efeitos em `fx2.gd`.
- **Modelos:**
  - Monstros e estruturas em miniaturas de pincel seco (`assets/models/g_n_a` e as texturas `g_tex/dry_n`), mais os modelos feitos à mão de 21/11 (`m2_a`, `v2`). O código fica em `game/art/looks.gd` e `models.gd`.
  - **Diorama** (`assets/models/dio`, passa na frente de todos): rato, Ratazana e Horda de Ratos (rato de puxar com rodas), Matilha de Lobos (lobo de madeira) e as peças de cenário, feitos em partes no Blender (`tools/art/blender_dio/characters.py`) e animados pelo `tools/art/import_dio.gd` (animação procedural gravada em textura) com a lista `tools/art/dio_b.json`; créditos em `assets/models/dio/CREDITOS.md`.
  - Heróis com modelos KayKit (`assets/models/cc0`), menos o escudeiro, que é um boneco de pino de madeira (`assets/models/dio/hero_escudeiro.scn`, `Diorama.HERO_SCENE`).
  - **Regra dos modelos novos:** usar as cores da arte da carta e fazer olhos sem pupila.
- **Áudio** (`game/audio.gd`; tudo CC0, com licenças em `assets/audio/LICENSES.txt`):
  - Música por contexto (menu, estrada, arena), trocada com crossfade.
  - Os ônibus `Music` e `SFX` têm volume nas Configurações.
- **Configurações do jogador** (`game/settings.gd`): volume, tela, idioma (PT/EN, `locale/strings.csv`), tremor, flashes, dicas e FPS.

## 7. Código

| Pasta | O que tem |
|---|---|
| `sim/` | Simulação pura e determinística por semente: `sim.gd` (run), `road.gd`, `rivers.gd`, `terrain.gd`, `units.gd`, `hero.gd`, `hero_powers.gd`, `arena.gd`, `effects.gd`, `card_def.gd`, `card_fx_lib.gd`, `cards/<dono>.gd`, `game_data.gd` (carrega `data/`), `meta_save.gd`, `meta_apply.gd`, `unlock_track.gd`, `save_game.gd`, `k.gd` (constantes). A entrada é por comandos (`play`, `choose`, `choose_route`, `teleport`); a saída é estado + eventos + stats. |
| `game/` | Visual e UI: `main.gd` (cena principal `main.tscn`), `world_view.gd`, `hud.gd`, `hand_fan.gd`, `map_menu.gd`, `covil_screen.gd`, `collection.gd` (Biblioteca), `compendium.gd`, `run_end.gd`, `tutorial.gd`, `game/art/` (visual do mundo). |
| `bots/` | Bots que jogam a sim (`PlayerBot`, `HumanBot`, `BotRun`). |
| `headless/` | Lotes e diagnóstico sem tela: `batch`, `fuzz`, `hashes`, `replay`, `trace`. |
| `tests/` | `tests.tscn`: a suíte inteira, ou `-- --only=t_a,t_b`. |
| `tools/` | Editor de balanço (`balance_editor`, porta 8767), editor de desafios (`desafios_editor`, porta 8768), `gerar_unlocks.py`, `run_batch.py` (lotes de bot em paralelo, via `headless/batch`), `final_check.gd` (runs de 15 parties com e sem meta), capturas (`capture_ref.sh` = cenas de referência para comparar antes/depois; `capture_menus.sh`, `capture_biblioteca.sh`, `capture_niveis.gd`), `river/` (teste rápido dos rios), `gallery/` (vitrines das cartas), pipelines de arte em `tools/art/` (Blender `-b`: `blender_v2`, `blender_g`, `blender_m2`, `blender_arvores`; ícones de relíquias, poderes e meta; molde das cartas; kit da UI). |
| `arte_ia/` | Pipeline da arte das cartas por IA: `_tools`, os finais e as pranchas. Não é carregado pelo jogo. |

## 8. Como rodar

Use Git Bash. Godot 4.7:

```
G="/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import                       # antes de tudo, depois de class_name novo
"$G" --headless --path . res://tests/tests.tscn          # suíte inteira; última linha "falhas: N"
"$G" --headless --path . res://tests/tests.tscn -- --only=t_run15,t_powers
"$G" --headless --path . --script res://tools/check_scripts.gd   # todos os scripts compilam?
"$G" --position -6000,0 --path . -- --menutest           # jogo com janela, em segundo plano
```

- **Godot sempre em segundo plano:** nunca tela cheia nem `warp_mouse`. Use `--position -6000,0`. Com argumentos `--x=y`, o `main.gd` já liga o modo de fundo; `--fg=1` desliga.
- Flags de teste e captura: `--liberar`, `--set=chave:valor`, `--shots`, `--spacetest`, `--prelog`, `--cenario_map`, `--cenario_log`.
- Saídas de captura vão para `capturas/`, que é ignorada pelo git.

## 9. O que ainda não foi medido

- O balanceamento depois da metaprogressão foi feito só pela conta: curva de 1,17 por party, preços do Covil, Almas por run e limiares dos desafios. O bot `heuristic` sem meta perde entre a party 5 e a 8. Com a meta no máximo, vence 2 de 4 runs.
- Uma run de 15 parties leva mais de 4000 s simulados para o bot; o limite do jogo é `sim.max_run_seconds` 3000.
- `locale/strings.csv` ainda tem chaves sem uso de telas antigas.
