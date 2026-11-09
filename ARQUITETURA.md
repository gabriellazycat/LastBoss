# Arquitetura — Last Boss (marco 1)

## Pastas

```
project.godot
data/                 JSON: a fonte da verdade de todos os números (o ajustador edita aqui)
  rules.json          elixir, mão, anel, curvas de XP, arena, estrada, raridade, locais, ofertas, metas
  cards.json          as 30 cartas (campo, rota, covil, finalização) + unidades auxiliares (morcego, esqueleto…)
  modifiers.json      os 5 modificadores (Veterano, Barato, Explosivo, Amaldiçoado, Sombrio)
  hero_escudeiro.json atributos, curva, IA e os 15 upgrades
  boss_lorde.json     as 4 partes do corpo e os 3 decks iniciais
  contracts.json      os 8 contratos
  locked.json         valores que o ajustador nunca toca
  bots/*.json         uma personalidade por arquivo (random, greedy…)
sim/                  simulação: lógica pura (RefCounted, nenhum Node), passo fixo, determinística por semente
bots/                 bots do jogador (lógica pura; leem o Sim e devolvem comandos)
headless/             batch.tscn: roda N sementes sem janela e grava JSON
game/                 visual: cenas e Nodes que só leem o estado do Sim e desenham
  tips.gd             caixas de explicação (estilo Hearthstone): palavras-chave [[id]] nos textos, caixas aninhadas, pausa ao ler
  upgrade_icon.gd     ícones das habilidades do herói (desenho vetorial) e o texto de cada uma
locale/strings.csv    todo o texto (pt, en) via TranslationServer; KW_/KWD_ = palavras-chave, UPGD_ = habilidades do herói
tests/tests.tscn      testes (Node que roda no _ready e sai com código)
tools/                xlsx_to_json.py (conversão única), run_batch.py (lote paralelo + relatório)
reports/              saída dos lotes (ignorada no git, exceto os relatórios de ciclo na branch balance)
```

## Simulação × visual

- `Sim` (sim/sim.gd) é o único dono do estado. Passo fixo de 0,05 s (20 Hz). O RNG é um `RandomNumberGenerator` com semente registrada, e toda aleatoriedade passa por ele.
- Entrada só por **comandos** (`play`, `sacrifice`, `choose`, `teleport`, `route`). O humano e os bots geram os mesmos comandos, o que permite gravar e reproduzir uma run.
- As unidades ficam em **arrays paralelos** (PackedFloat32Array etc.) com lista livre: pooling sem nenhum objeto criado em combate. A grade espacial é uma janela fixa ao redor do herói, reconstruída por contagem (O(n)).
- A IA é escalonada: mapa de perigo e escolha de alvo a 5 Hz, decisões das unidades distribuídas entre ticks.
- O Sim emite uma lista de **eventos** por tick (dano, morte, spawn, level-up). O visual consome; o modo headless desliga a gravação.
- O visual (`game/`) roda o Sim num acumulador, interpola posição anterior → atual e desenha enxames com **MultiMeshInstance3D** (uma por tipo visual, capacidade pré-alocada). Números de dano e zonas usam pools de nós.

## Formato dos dados

Cada carta é um objeto com `id`, `category` (field/route/lair/finisher), `type`, `tags`, `archetype`, `rarity`, `cost`, `count` (unidades que nascem), `xp_parts` (divisor do XP, ex.: Slime 7), `hp`, `dps`, `attack_interval`, `speed`, `range` e um bloco `fx` com os parâmetros do efeito. Valores derivados (XP por unidade, limiares de nível) são calculados ao carregar, nunca gravados, para o ajustador mexer só nas causas.

## Arte e áudio

- **Pipeline de arte** (GDD): uma única paleta (cor por vértice) e um único material com shader estilizado (`game/art/toon.gdshader`: luz em degraus, rim light, brilho de impacto, animação de enxame no shader via `INSTANCE_CUSTOM`). Os modelos low-poly são montados por código em `game/art/models.gd` (monstros, herói, chefe em 4 partes, cenário, ícones das cartas sem unidade). Para trocar por modelos do Blender, basta devolver outra `Mesh` em `Models.unit()` / `Models.prop()`.
- **Arte das cartas**: `game/art/card_art.gd` renderiza o modelo de cada carta numa SubViewport ao abrir o jogo.
- **Áudio**: `tools/make_audio.py` sintetiza os efeitos e a trilha provisória (numpy) em `assets/audio/`. `game/audio.gd` toca os efeitos com pool e recarga por som. A trilha da estrada tem duas camadas: a de percussão e melodia cresce conforme o herói se aproxima do covil. A arena tem uma trilha própria.

## Interface

- `game/ui_kit.gd`: paleta, tema (caixas chanfradas, sem cantos arredondados), painéis, barras, selos e o desenho das cartas, usados pelo menu, pela HUD e pela pausa. `UiKit.clear()` esvazia contêineres na hora (com `queue_free` sozinho, os filhos velhos ainda contam no tamanho e o painel cresce sem voltar).
- `game/menu.gd`: menu principal sobre o covil 3D (título → decks → configurações). A câmera desloca o chefe para a direita na tela de título.
- `game/hud.gd`: HUD da run. Hierarquia: o herói (vida grande, XP fina, build) no centro do topo; tempo e contrato à esquerda; botões de pausa, velocidade e mapa no canto direito (e o corpo do chefe abaixo deles, na arena); faixa de rota logo abaixo da fileira de cima; esteira do ciclo, mão em leque e elixir em gomos embaixo. Ofertas, pausa e resultado são camadas sobre a tela.
- `game/hand_fan.gd`: mão em leque (cartas compactas num arco; a sob o mouse sobe ampliada com o texto; a selecionada sobe com borda dourada e um balão que some ao mirar) e a esteira do ciclo à esquerda (as 4 próximas cartas da fila + "+N"). Recebe a entrada do leque inteiro: a carta sob o mouse é a fatia do arco onde ele está.
- `game/route_strip.gd`: faixa de rota — a estrada inteira desenrolada numa linha (trechos na escala do comprimento, bifurcações com dois ramos, percorrido apagado, locais, covil e %). Com Ponte Quebrada/Placa Falsa ou Queimar Vila selecionada, os alvos pulsam e aceitam clique ou a carta solta. `game/minimap.gd` virou o mapa grande (M, Select, ou ao escolher uma carta de rota).
- `game/settings.gd` + `game/settings_panel.gd`: configurações estáticas (`Settings.v`) lidas ao vivo pelo visual (tremor, clarões, números de dano, dicas, FPS, barra de atalhos, cursor do controle). Áudio em barramentos Music e SFX.

## Como o bot roda

1. `godot --headless --path . res://headless/batch.tscn -- --bot=greedy --deck=horda --seeds=1-50 --out=reports/x.json`
2. `python tools/run_batch.py --bots random,greedy --decks horda,ruina,tesouro --runs 200` divide as sementes entre processos (um por núcleo), junta os JSON e gera `reports/<data>/report.md` + `summary.json` com as métricas contra as metas do DECISOES.md (nota única = distância às metas).
3. Cada run registra semente, deck, bot, resultado, tempo até a arena, níveis, cartas oferecidas/escolhidas, dano por carta, elixir desperdiçado e tempo de parede.

## Bots e ajustador

- Perfis em `data/bots/`: `random`, `greedy` e o tipo `smart`, com 3 personalidades (`heuristic`, `economist`, `swarm`). Criar um bot = criar um arquivo.
- `tools/tuner.py` (branch `balance`): mede a nota, testa candidatos (±15% e ±30%) nos botões ligados às 2 metas mais distantes, fica com o melhor e faz um commit por ciclo com o relatório em `balance_reports/`. Não toca nos caminhos de `data/locked.json`. Uso: `python -I tools/tuner.py --cycles 15 --runs 8`.

## Decisões que tomei no seu lugar (AFK) e riscos

- **Passo de 20 Hz** na simulação; o visual interpola. Risco: colisões rápidas menos precisas (aceitável para monstros a ≤ 6 m/s).
- **XP:** todo monstro que morre dá XP, inclusive o Kamikaze que explode. Não dão XP: sacrificada ou ressuscitada (Alma), espectro, unidade que fica para trás (> 50 m).
- **Sem alcance máximo:** a carta vale em qualquer ponto que o jogador enxerga na tela. Monstros e estruturas respeitam só a distância mínima de 3 m do herói; feitiços ignoram até essa.
- **Teleporte:** grátis com recarga de 8 s (o GDD deixava "8 s ou 2 de elixir"); o custo fica em dados (`teleport_cost: 0`).
- **Sacrifício** manda a carta para o fim do deck (não remove) e devolve 1 de elixir, no máximo uma vez a cada `sacrifice_cooldown` s.
- **Nível da carta** fica na instância (`CardInst.level`) e nas unidades (`units.lvl`); `CardDef.fxv/count_at/cost_at` dão o número no nível. **Recompensas de local** em `Sim._offer_location`; opções `card`, `mod`, `upgrade`, `remove` e `pick` (ponte), e `choose(Sim.SKIP)` recusa.
- **Meta-progressão** em `sim/meta_save.gd` (`user://meta.save`): Almas, coleção e deck; a tela é `game/collection.gd`. `Sim.setup(data, seed, pacto, deck, desbloqueadas)`.
- **Ofertas pausam a simulação** até a escolha (o bot escolhe na hora).
- **Dano do herói cresce 8% por nível** (a planilha não definia); fica em dados.
- **Esqueleto do Totem:** 60 de vida, 6 de DPS, perseguidor. **Morcego:** 30 de vida, 5 de DPS, 5 m/s. **Explosivo:** 40 de dano em 2 m. **Amaldiçoado:** 1 maldição por unidade a cada 5 s de acertos.
- **Contrato "Sem Testemunhas":** o contador de dano zera quando o herói ganha XP.
- **Recompensa "rara" de uma tag sem cartas raras** (Fogo, Sombra): cai para qualquer raridade daquela tag.
- **Sustentação do herói** (a planilha prevê ~18 mil de dano no herói na fase 1 e ele tem 1500–4000 de vida): regeneração de 1,2% da vida máx./s em combate e 3%/s fora de combate, e golpe em arco de 110° (o Escudeiro corta o que está à frente). Tudo em `hero_escudeiro.json`.
- **Atiradores recuam a 55% da velocidade** (`rules.units.retreat_speed`); senão faziam kiting infinito no herói. Enquanto persegue um alvo, a coleira do herói até a estrada estica até 18 m.
- **Ninguém foge do herói em velocidade cheia:** o suporte (Rei dos Ratos) também recua a 55%, inclusive quando vai ao ponto de apoio afastando-se do herói; sem bando por perto ele não foge, vai para cima. O herói só escolhe alvos a até 15 m da estrada (o alvo atual tem folga até 17,5 m); senão parava na borda da coleira olhando para ele. No alcance, se o alvo está escapando pela borda, o herói continua perseguindo a toda, e o alvo atual não entra no mapa de perigo (não "espanta" o herói). A coleira puxa de volta a 2× a velocidade, sem tranco.
- **O progresso na estrada recua no máximo 8 m** (`rules.road.max_backtrack`): a projeção do herói na rota escorregava para trás quando ele saía da estrada (curvas do ramo longo), e a coleira o arrastava para trechos já percorridos.
- **XP de treino do herói** (`rules.hero_xp.passive_per_s` = 1,8/s): sem isso, não jogar quase nada vencia (o herói chegava no nível 3 à arena). Agora ele chega por volta do nível 8 mesmo sem ser alimentado.
- **Na arena o herói não regenera** (`regen_in_arena: false`): ele chega "com a vida atual" (GDD), e com regeneração a luta final era quase invencível.
- **Dano absorvido pelo escudo conta para o seu nível** (`player_xp.count_shield`): bater no escudo é causar dano no herói.
- **A IA do herói não mira a Torre de Gárgula** (ela vira pedra quando ele chega perto): ele passa direto.
- **Pilares quebráveis da arena** e **salvamento no meio da run** ficam para depois do marco 1.
- Risco de desempenho: 15 min em < 5 s com GDScript. Se não bater, o laço das unidades vai para C# ou GDExtension (o plano B do GDD).

## Passos do marco 1

1. Conversão planilha → JSON, projeto Godot, git (main + balance), tradução pt/en.
2. Núcleo do Sim: dados, RNG, unidades em arrays, grade, eventos, comandos.
3. Estrada gerada (bifurcações, 6 locais, santuários), herói andando com IA por pontuação e escudo frontal.
4. Elixir, mão, deck, sacrifício, anel; os 7 arquétipos; deck Horda e depois as 18 cartas de campo.
5. XP/level-up do herói (15 upgrades), level-up do jogador (ofertas por raridade), modificadores, santuários, contratos, cartas de rota e de covil.
6. Arena: 4 partes, 5 altares, teleporte, 6 finalizações.
7. Bots Aleatório e Guloso, lote headless paralelo, relatório.
8. Visual cinza: estrada, MultiMesh, câmera isométrica, HUD completo, minimapa, controles (mouse, teclado e controle).
9. Testes (determinismo, regras, desempenho), exportação testada e commit.

## Grupo de heróis (09/11/2026)

- Continua existindo um único objeto `sim.hero`: quando ele morre, `Sim._hero_fell()` o reinicia no lugar (`SimHero.next_hero(i)`) em vez de criar outro. Assim os ~81 usos de `sim.hero` não mudaram. `sim.party_idx` (0..4) é o herói da vez e `sim.gate_pos` é o portão da arena. As habilidades e o dano recebido (`taken`) são do grupo e ficam.
- `Sim._check_end`: com `party_idx < rules.party.size - 1`, chama `_hero_fell`; no último, vence (`WIN_EARLY` na estrada, `WIN` na arena). Eventos novos: `HERO_FALL` (queda) e `HERO_LEVEL` (chegada).
- XP removido: `hero_gain_xp` é vazio, `player_xp` e `_player_next` são restos inertes; `rules.json` perdeu `player_xp` e quase todo `hero_xp`.
- O salvamento da run grava `party_idx` e `gate_pos` sozinho (ele serializa as propriedades do `Sim`).
- `stats["heroes_fallen"]` substitui o nível do jogador nos relatórios (`run_batch.py`, `tuner.py`).

## Mapa de rotas (09/11/2026)

- `sim/road.gd` gera uma **rede de nós**: `nodes` (fileira, pista, posição, ligações de saída e de entrada, local) e `legs` (cada ligação entre dois nós, com `pts`, `len`, `chosen` e `closed`). Um local por nó. As ligações de uma fileira para a seguinte têm todas o mesmo comprimento (ondas laterais em `_wavy`), então toda rota mede o mesmo. Os tipos de local são sorteados com restrições (tipos diferentes por fileira, Santuários por rota, Lojas nunca na mesma rota), com o número de rotas por contagem calculado em `_path_hist`.
- A rota do herói (`route`/`cum`) cresce ligação por ligação a partir de `head`. `plan` guarda a escolha do jogador por bifurcação; `plan_to(n)` planeja todas até o nó n; `reach` são os nós ainda alcançáveis, e `is_on_route(loc)` vale para eles e para os já percorridos.
- `Sim.choose_route(n)` é o comando do jogador. Sem plano, `_road()` liga `route_wait` e o passo para (como numa oferta); `auto_route` (testes e capturas) segue o primeiro ramo.
- Loja: `Sim._open_shop` abre uma oferta `shop` de itens `{"kind": "buy", "item", "price"}`; nível e remoção abrem a oferta `shop_pick` e só cobram ao escolher. Ouro em `Sim.gold` (`_earn_gold`). Fonte: zona `spring` que cura as unidades. Incêndio: o local guarda `burn`, e a zona de fogo nasce quando o herói entra.
- Visual: `game/minimap.gd` desenha o mapa grande como esquema (fileiras × pistas), clicável (`node_clicked`); `game/route_strip.gd` desenha o mesmo esquema na faixa; `game/world_view.gd` põe barreiras (`barricades`) nos ramos fechados. `SaveGame.VERSION` = 2.
