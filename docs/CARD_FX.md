# Cartas por dados: `owner`, `ops`, `on_death` e `ai`

Passo C0 (10/11/2026). Como montar uma carta nova quase só em `data/cards.json`.

## Onde fica o efeito

`Sim._apply(c, x, y)` faz, nesta ordem:

1. Carta com `archetype` (monstro, enxame, estrutura): `CardFxLib.spawn_card_units` (quantidade, nível, modificadores). Depois roda `ops`, se houver.
2. Outras cartas: roda `ops` (se houver) e depois o código por id em `sim/cards/<owner>.gd` (`common.gd`, `plague.gd`, `dragon.gd`, `lich.gd`).

Todos os arquivos de dono têm a mesma assinatura e devolvem `true` se trataram a carta:

```gdscript
static func apply(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> bool
```

`k` traz `c` (a `Sim.CardInst`), `d` (o `CardDef`), `lv` (nível), `smult` (dano de feitiço do Pacto), `vet` (Veterano em feitiço: dano e duração maiores) e `curse` (1 se a carta é Amaldiçoada). Só escreva código por id para o que nenhuma op cobre; cada agente de vilão é dono do seu arquivo.

Campos novos da carta: `"owner": "plague" | "dragon" | "lich" | "common"` (obrigatório), `"ops"`, `"on_death"` e `"ai"` (opcionais).

## Ops

`"ops": [ {"op": "...", ...}, ... ]` roda ao jogar; `"on_death": [...]` roda quando uma unidade da carta morre pelo herói ou explodindo (no ponto da morte, com o nível da unidade, sem Pacto nem Veterano).

**Parâmetro numérico**: número literal (`2.5`) ou o nome de uma chave do `fx` da carta (`"damage"`), que vale `fxv(chave, nível)`, isto é, já cresce com `lvl` e troca pelo `n3`. Prefira chaves do `fx`: a planilha e o nível continuam funcionando.

Em feitiço, dano é multiplicado por `smult × vet` e duração por `vet`; a maldição do Amaldiçoado vai para cada herói atingido.

| op | parâmetros (padrão) | o que faz |
|---|---|---|
| `damage` | `damage`, `radius` (2,5), `kind` `"area"`/`"pierce"` (area), `target` (`"area"`), `boom` (false) | Dano nos heróis do alvo: cheio no mais perto, `group_spell_splash` nos outros. `boom` mostra explosão. |
| `status` | `status`, `duration`, `target` (`"hero"`), `radius` (3), `dps` (só burn) | Estado: `soaked`, `slow`, `root` (× `cc_mult`, conta para contrato), `petrify`, `fear` (só o herói da vez), `burn` (dano por segundo). Usa o maior entre o atual e o novo. |
| `curse` | `n` (0), `target` (`"hero"`), `radius` | `n` maldições (+1 se Amaldiçoada). |
| `zone` | `kind`, `radius` (3), `duration` (5) e os da zona | Zona no chão tratada por `Sim._zones()`: `web` (`root`, `soak` opcional: lentidão e prende uma vez por herói), `oil` (`dps`, `soaked`), `fire` (`dps`), `coins` (`stop`, `curses`, `gold`: o primeiro que pisa para e você ganha ouro). |
| `summon` | `unit` (id de carta ou auxiliar: `skeleton`, `rat`, `bat`, `spectre`), `n` (1), `ring` (0,8) | Invoca unidades em anel no ponto, sem elixir de volta. |
| `buff` | `slot`, `duration` e os do slot | Reforço com duração (substitui o anterior do mesmo slot): `rally` (`damage`, `speed`: monstros com tag `pack` batem e correm mais), `harvest` (`elixir`: cada monstro seu que morre devolve elixir), `spell_mark` (`bonus`: feitiços machucam mais). Slot novo precisa de código no Sim. |
| `elixir` | `amount` | Ganha elixir (até o máximo). |
| `gold` | `amount` | Ganha ouro (como dano/disputa: conta para relíquias). |
| `pay_gold` | `amount` | Paga ouro (conta em `gold_spent`). |
| `draw` | `n` (1) | Compra `n` cartas para a mão (até `HAND_MAX`). |

`target`: `"hero"` (o da vez), `"group"` (todos de pé), `"area"` (todos no raio, do mais perto ao mais longe), `"nearest"` (o mais perto no raio em grupo; ninguém perto ou sozinho = o da vez).

Cartas existentes já em ops (prova, replay idêntico): `pack_call`, `soul_harvest`, `shadow_mark`, `toll`.

### Exemplos

Marca Sombria (feitiço de reforço com maldição):

```json
"fx": {"duration": 7.0, "bonus": 0.4}, "lvl": ["duration"], "n3": {"bonus": 0.6},
"ops": [{"op": "buff", "slot": "spell_mark", "duration": "duration", "bonus": "bonus"},
        {"op": "curse", "target": "hero"}]
```

Monstro que explode em fogo ao morrer e uma bola de fogo que encharca:

```json
{"id": "ember_bat", "owner": "dragon", "type": "monster", "archetype": "swarm", "...": "...",
 "fx": {"boom": 60, "fire_dps": 15},
 "on_death": [{"op": "damage", "damage": "boom", "radius": 2.0, "boom": true},
              {"op": "zone", "kind": "fire", "radius": 2.0, "duration": 3.0, "dps": "fire_dps"}]}

{"id": "fireball", "owner": "dragon", "type": "spell", "...": "...",
 "fx": {"damage": 120, "radius": 2.5, "soak": 4.0}, "lvl": ["damage"],
 "ops": [{"op": "damage", "damage": "damage", "radius": "radius"},
         {"op": "status", "status": "soaked", "duration": "soak", "target": "area", "radius": "radius"}],
 "ai": {"aim": "cluster", "needs_hit": true}}
```

## Vocabulário de `ai` (bots)

Os bots (`bots/player_bot.gd`, `bots/human_bot.gd`) não têm id de carta no código: decidem por `type`, `archetype`, `category`, `cost`, `rarity`, `fx` e por este campo. Valor base do bot heurístico: `custo + raridade × 0,5` (+ ajustes por categoria); o bot humano soma o que vê (heróis atingidos, escudo quebrado...).

| campo | valores | efeito |
|---|---|---|
| `aim` | `hero` (padrão), `cluster`, `line`, `soaked`, `own_unit`, `ahead`, `unit_key`, `location` | Onde soltar. `cluster`: ponto que pega mais heróis (raio `fx.radius`); `line`: origem de uma linha (`fx.length`, `fx.width`) que passa por mais heróis (o básico mira 3 m atrás do herói); `soaked`: no herói encharcado; `own_unit`: no seu monstro mais perto do herói (até 4 m); `ahead`: 4 m à frente do herói; `unit_key`: na sua unidade com o rótulo `aim_key` (senão 15 m à frente na estrada); `location`: local marcável mais perto (Incêndio). O bot aleatório espalha a mira de feitiço, menos `line` e `own_unit`. |
| `needs_hit` | bool | Bot humano não joga o feitiço se ele não pega nenhum herói. |
| `lingers` | bool | Zona que fica: +1 de valor com o herói preso ou petrificado. |
| `keys` | lista de rótulos | O que esta carta é para os combos das outras (`detonator`, `igniter`, `mark_payoff`, `echo_worthy`, `bait_target`). |
| `value` | lista de regras | A primeira regra cuja condição vale soma ao valor (ver abaixo). |
| `needs` | condição | Sem isso a carta não faz nada: todo bot que pensa segura (o guloso troca por elixir com o elixir cheio). |
| `wait_for` | regra | Heurístico/humano só jogam com a condição; valendo, soma a regra. O guloso ignora. |

**Regra**: `{"if": condição, "combo": bool, "per": métrica, "div": n, "cap": n, "add": n, "each_in_hand": rótulo}`. Valor = (`combo` do perfil do bot, ou 1) × métrica (÷ `div`, no máximo `cap`) × `add` (1). `each_in_hand` soma uma vez por carta da mão com o rótulo. Métricas: `pack` (bichos de bando em campo), `own_units` (seus monstros, sem estruturas), `recent_spells` (feitiços nos últimos `fx.window` s), `recent_deaths` (mortes de monstros seus nos últimos `fx.window` s, contagem do Lich), `gold` (ouro atual).

**Condição**: `{nome: parâmetro}`, todas têm de valer: `hero_hindered` (lento, encharcado ou preso), `hero_soaked` (encharcado há mais de N s), `hero_shielded`, `elixir_spare` (elixir ≥ custo + N), `elixir_below` (N), `hand_has` (rótulo), `pack_below` (N), `own_near_hero` (monstro seu a até N m), `own_units_below` (N), `last_spell_has` (último feitiço tem o rótulo), `unit_alive` (unidade sua com o rótulo), `wounded_near_hero` (N monstros seus abaixo de 50% a 4 m), `recent_deaths` (pelo menos N mortes suas nos últimos `fx.window` s; Túmulo Aberto, Tempestade de Almas), `gold_above` (ouro ≥ N; Ouro Derretido, Avalanche de Ouro), `contest_active` (true = há disputa em andamento; Colosso, Dragão Ancião, Titã), `pack_min` (pelo menos N bichos de bando em campo; Devorar pede 3 ratos). **Custo máximo dos bots**: `max_cost` do perfil vale para elixir máximo 10 e escala com o elixir máximo do ato (`max_cost × elixir_max ÷ 10`), para as cartas de custo 8 a 12 serem jogadas nos atos 2 e 3.

**Sem `ai`**: unidade solta pelo arquétipo (tanque na frente, atirador atrás, corpo a corpo pelos lados); feitiço com `damage` e `radius` mira no grupo (`cluster`) e precisa acertar; outro feitiço mira no herói; rota e covil no herói.

Exemplo (Balde de Óleo): `"ai": {"aim": "cluster", "value": [{"if": {"hero_soaked": 2.0}, "add": -2.0}, {"if": {"hand_has": "igniter"}, "combo": true, "add": 0.8}]}`: não encharca quem já está encharcado; vale mais com uma carta de fogo na mão.

Teste de não regressão: `headless/hashes.tscn` grava uma linha por run (bot × Pacto × fase × semente) com resultado, tick e hashes; a tabela tem de sair igual antes e depois de uma refatoração.
