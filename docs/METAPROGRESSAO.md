# Metaprogressão forte, 1 fase de 15 parties e poderes de party (21/11/2026)

Documento gerado dos JSON e do código atuais do branch `meta-k` (`data/hero_powers.json`, `data/meta_tree.json`, `data/campaign.json`, `data/rules.json`, `data/relics.json`, `data/unlocks.json`, `sim/meta_save.gd`, `sim/meta_apply.gd`, `sim/hero_powers.gd`, `sim/sim.gd`). O plano e as decisões do grilling estão em `docs/PLANO_METAPROGRESSAO.md`; as regras dos subagentes, em `docs/BRIEF_COMUM.md`.

**Estado:** implementado nas frentes A a J e mergeado em `metaprogressao`. **Balanceamento só pela conta, não medido** (ver seção 7). O dono ainda precisa jogar e revisar a seção 6.

Saíram do jogo: a campanha de 7 fases e o mapa da campanha, a Horda sem fim, as Almas antigas (recompensa de fase), os decks fixos por vilão, as 15 habilidades antigas dos heróis e a Coleção antiga (virou a Biblioteca).

## 1. Visão geral e fluxo

```
Menu principal -> Covil (roda radial) <-> Biblioteca -> Escolher vilão -> Run (15 parties) -> Fim da run -> Covil
```

- **Run**: uma fase só, 15 parties numa fila fixa. O normal é perder no covil; cada run rende **Almas** (dano nos heróis + heróis mortos), mantidas ao perder.
- **Covil**: árvore radial onde as Almas compram melhorias permanentes (atributos, locais, arena, relíquias, troca de ato, geral). **Reembolso total e grátis.**
- **Biblioteca**: cartas em álbum, níveis I a VI (com Almas), deck de 19 por vilão, cartas bloqueadas com o desafio que as libera.
- **Poderes de party**: cada vez que uma party inteira cai, a party seguinte ganha um poder novo ou uma evolução, com recarga longa e efeito forte (seção 3).
- **Vilões**: 3 (Rainha da Praga, Dragão Avarento, Lich). Dragão liberado ao derrotar a party 3 uma vez; Lich, a party 6. O save **zera** na v5.
- Tutorial continua (opção do menu, fase 0 com config própria: 2 parties de escudeiro).

## 2. A run

Fonte: `data/campaign.json` (fase 1), `rules.party`, `rules.acts`, `rules.offer_upgrades`.

- **1 fase** (`key PHASE_1`, região vila), **3 atos de estrada + arena**. Estrada de 500 + 800 + 1100 m (alvo de `acts[].road.target_length`); o herói anda a 3 m/s (ritmo efetivo ~1,7 m/s com combates e locais), ~23 min de estrada, mais ~20 min de arena (~6 parties de ~200 s; prorrogação em 240 s): **~45 min para uma run que avança bem**. A maioria das runs acaba antes, com o covil caindo.
- Atos: elixir máx. das ofertas 7 / 9 / 16, regeneração ×1,0 / ×1,05 / ×1,10; raridade das ofertas (comum/incomum/rara/lendária) 65/25/9/1, 50/30/16/4, 40/30/22/8 %.
- **Força**: `hp_mult` 2,8 e `damage_mult` 1,0 na party 1; cada party seguinte multiplica por `rules.party.step` = **1,17** (era 1,21). `rules.hero_hp_mult` = 2,0. A vida e o dano TOTAIS da party k valem 2,8 × 1,17^(k-1) e 1,17^(k-1); cada membro leva 1/N da vida total.

### Fila fixa das 15 parties

Tamanhos 1,1,2,2,2,3,3,3,3 e 4 nas seis últimas. As classes entram aos poucos (escudeiro, arqueira, clériga, bárbaro, guardião + mago, assassino, besteiro) e da party 10 em diante as 8 classes se misturam em grupos de 4, com clériga quase sempre.

| Party | Heróis | Classes | hp_mult (2,8 × step^(k-1)) | dano × | Vida total da party (H0 × step^(k-1)) |
|---|---|---|---|---|---|
| 1 | 1 | Escudeiro | 2,8 | 1 | 8120 |
| 2 | 1 | Arqueira | 3,28 | 1,17 | 9500 |
| 3 | 2 | Escudeiro, Clériga | 3,83 | 1,37 | 11115 |
| 4 | 2 | Arqueira, Bárbaro | 4,48 | 1,6 | 13005 |
| 5 | 2 | Guardião, Mago | 5,25 | 1,87 | 15216 |
| 6 | 3 | Escudeiro, Clériga, Mago | 6,14 | 2,19 | 17803 |
| 7 | 3 | Bárbaro, Arqueira, Assassino | 7,18 | 2,57 | 20829 |
| 8 | 3 | Guardião, Besteiro, Clériga | 8,4 | 3 | 24370 |
| 9 | 3 | Assassino, Mago, Escudeiro | 9,83 | 3,51 | 28513 |
| 10 | 4 | Escudeiro, Clériga, Mago, Besteiro | 11,5 | 4,11 | 33360 |
| 11 | 4 | Bárbaro, Arqueira, Guardião, Clériga | 13,46 | 4,81 | 39031 |
| 12 | 4 | Assassino, Mago, Besteiro, Escudeiro | 15,75 | 5,62 | 45667 |
| 13 | 4 | Guardião, Clériga, Bárbaro, Arqueira | 18,42 | 6,58 | 53430 |
| 14 | 4 | Assassino, Mago, Clériga, Guardião | 21,56 | 7,7 | 62513 |
| 15 | 4 | Bárbaro, Guardião, Clériga, Mago | 25,22 | 9,01 | 73141 |

(A coluna "Vida total" usa H0 = 8120 = 1450 × `hero_hp_mult` 2 × `hp_mult` 2,8. Conta, não medida.)

### Ofertas na run
- **1 carta de 3 por party morta** (15 no total). A flag `oferta_por_heroi` (nó do Covil `ger_offer_hero`, 700 Almas) libera uma oferta também por herói morto.
- Chance de a oferta vir melhorada (`offer_upgrades`): com p = progresso da run (0 no começo do ato 1, 1 no fim do ato 3), nível 2+ = p × 100 %, 3+ = p × 50 %, 4+ = p × 20 %, 5+ = p × 8 %, 6+ = p × 3 %. A carta de fim de ato dobra as chances (tetos 75 / 30 / 15 / 6 %) e o peso de rara/lendária. A oferta nunca fica abaixo do nível da meta daquela carta. Upgrade da run ignora cartas já no VI; com todas no VI vira ouro (75).
- Depois da oferta de carta vem a **segunda tela**, o painel do poder novo (pausa, nome, efeito, recarga, lista dos poderes da party).
- **Dragão** liberado ao derrotar a party 3; **Lich**, a party 6 (`campaign.json` `unlock_villain_at`; fallback `villain_unlock_at` em `meta_tree.json`).

## 3. Poderes de party

Motor em `sim/hero_powers.gd`; dados em `data/hero_powers.json` (21 poderes). Textos: `POWER_<id>` e `POWER_<id>_d` em `locale/strings.csv`; ícone `assets/ui/powers/<id>.svg`.

### Regras
- Só na **morte da party inteira**: a party nova ganha 1 poder **novo ou evolução** (nível 1 a 3, `max_level` 3). Probabilidade de evolução **34 %** (`evolution_chance`), se houver algo a evoluir e algo novo a sortear; sem poder novo sobrando é sempre evolução. Um evento ("próximo herói com habilidade a mais") dá 2 sorteios. Os poderes **acumulam** na run toda, sem teto.
- **Sorteio ponderado pelo estilo**: peso = `weight` × (1 + `counter_gain` 3,0 × fatia do dano recebido pela party TODA (não só o líder) nos tipos que o poder rebate, `counters`).
- **Gatilhos**: 1 poder dispara por contato; depois de qualquer disparo todos esperam `gap` = **1,5 s**. Os de contato (primeiro inimigo, próxima criatura, próxima estrutura) olham a 5 Hz, alcance `contact_reach` 1,0. Poderes de intervalo não gastam o gap. Reações ao dano (`on_hit_taken`) disparam pela condição (maldição, vida baixa, controle, fogo, projétil, golpe forte); `spell_ward` anula o próximo feitiço dentro de uma janela.
- **Recarga**: por nível, 10 a 20 s nos de efeito forte (ver tabela). Ao cair a party inteira, os poderes recarregam para a party nova, aliados e efeitos somem.
- **Dano de referência D** = golpe do herói da classe na party atual SEM dividir pelos membros; os poderes de dano escalam em múltiplos de D (`dmg_mult`), por isso acompanham o `step`. Orçamento: um poder isolado vale ~25 a 35 % do DPS da party no nível 1 e ~100 % no nível 3, quando há alvo.
- **Aliados** (`ally_rat`, `war_hound`): vida fixa (monstros não escalam), dano = `dps_mult` × D por segundo. Andam e batem dentro do motor de poderes (`sim.power_state["allies"]`); não existe lado aliado no motor de unidades.
- Eventos: `POWER_GAINED`, `POWER_TRIGGER`, `POWER_READY`; `Sim.party_powers()` alimenta a HUD (ícones com timer de recarga visível sobre a party).
- Texto das chaves: `radius` m; `dmg_mult` ×D; `*_frac` fração da vida máxima de cada herói (ward = barreira); `kill_hp_mult` ×D de vida máxima que a execução mata.

### Tabela dos poderes

| Poder | id | Gatilho | Recarga n1/n2/n3 (s) | Efeito por nível (n1 / n2 / n3) | Peso |
|---|---|---|---|---|---|
| Explosão de Fogo | `fire_burst` | primeiro inimigo que encosta | 18 / 15 / 12 | radius 5 / 6 / 7; dmg_mult 2 / 3 / 4,5 | 1 |
| Redemoinho de Lâminas | `whirlwind` | primeiro inimigo que encosta | 14 / 12 / 10 | radius 3 / 3,5 / 4; dmg_mult 1,5 / 2,2 / 3,2 | 1 |
| Nova Sagrada | `holy_nova` | primeiro inimigo que encosta | 16 / 14 / 12 | radius 4,5 / 5,5 / 6,5; dmg_mult 1,5 / 2,2 / 3,2; holy_mult 2,5 / 3 / 3,5 | 1 |
| Onda de Choque | `shockwave` | primeiro inimigo que encosta | 16 / 14 / 12 | radius 4 / 4,5 / 5; dmg_mult 1,5 / 2,2 / 3; struct_mult 3 / 3,5 / 4 | 1 |
| Grito de Guerra | `war_cry` | primeiro inimigo que encosta | 18 / 16 / 14 | ward_frac 0,12 / 0,18 / 0,26; dmg_bonus 0,2 / 0,3 / 0,4; dur 5 / 6 / 7 | 1 |
| Raio em Cadeia | `chain_lightning` | primeiro inimigo que encosta | 15 / 13 / 11 | targets 4 / 5 / 6; dmg_mult 1,2 / 1,8 / 2,2; range 9 / 9 / 10 | 1 |
| Punição | `smite` | primeiro inimigo que encosta | 12 / 11 / 10 | dmg_mult 4 / 6,5 / 10 | 1 |
| Execução | `slay_next` | próxima criatura | 20 / 17 / 14 | kill_hp_mult 10 / 18 / 30; hp_frac 0,35 / 0,5 / 0,65; chain 0 / 1 / 2 | 1 |
| Golpe de Titã | `titan_blow` | próxima criatura | 16 / 14 / 12 | big_hp 500 / 500 / 500; hp_frac 0,3 / 0,45 / 0,6; cap_mult 20 / 30 / 45 | 1 |
| Sorver Alma | `soul_drain` | próxima criatura | 14 / 12 / 10 | dmg_mult 3 / 4,5 / 6,5; heal_frac 0,04 / 0,06 / 0,09 | 1 |
| Quebra-Armadilhas | `structure_breaker` | próxima estrutura | 16 / 13 / 10 | kill_hp 400 / 700 / 2000; hp_frac 0,5 / 0,6 / 0,7 | 1 |
| Escudo Anti-Magia | `spell_ward` | próximo feitiço | 20 / 16 / 12 | window 1 / 1,2 / 1,5; heal_frac 0,03 / 0,06 / 0,12 | 1 |
| Purificação | `purify` | reação ao dano (maldição) | 18 / 14 / 10 | heal_frac 0 / 0,05 / 0,1 | 1 |
| Segundo Fôlego | `second_wind` | reação ao dano (vida baixa) | 20 / 17 / 14 | below 0,3 / 0,35 / 0,4; heal_frac 0,3 / 0,4 / 0,55 | 1 |
| Vontade de Ferro | `iron_will` | reação ao dano (controle) | 18 / 15 / 12 | immune_s 3 / 5 / 8 | 1 |
| Escudo Ignífugo | `fire_ward` | reação ao dano (fogo) | 16 / 14 / 12 | dur 4 / 6 / 8; taken_mult 0,4 / 0,25 / 0,1 | 1 |
| Muralha de Escudos | `arrow_wall` | reação ao dano (projétil) | 18 / 15 / 12 | ward_frac 0,18 / 0,28 / 0,4 | 1 |
| Represália | `retaliation` | reação ao dano (golpe forte) | 14 / 12 / 10 | radius 4 / 4,5 / 5; dmg_mult 1,5 / 2,2 / 3,2 | 1 |
| Rato Aliado | `ally_rat` | a cada N s | 5 / 5 / 4 | max 5 / 5 / 6; hp 60 / 90 / 130; dps_mult 0,1 / 0,15 / 0,22 | 0,8 |
| Cão de Guerra | `war_hound` | a cada N s | 14 / 12 / 10 | max 2 / 2 / 3; hp 300 / 450 / 650; dps_mult 0,35 / 0,5 / 0,7 | 0,8 |
| Curandeira | `field_medic` | a cada N s | 10 / 9 / 8 | heal_frac 0,03 / 0,05 / 0,08 | 0,7 |

### As 15 habilidades antigas viraram poderes
`data/hero_escudeiro.json` (upgrades antigos) ficou no repo, sem uso.

| Antiga | Poder |
|---|---|
| sword_spin | whirlwind |
| tower_shield | arrow_wall |
| dash | iron_will |
| war_cry | war_cry |
| fireproof | fire_ward |
| holy_water | holy_nova |
| treasure_nose | structure_breaker |
| stone_hammer | shockwave |
| steady_boots | iron_will |
| purifying_blade | purify |
| reflect_shield | spell_ward |
| hero_fury | retaliation / ally_rat (enxame) |
| soul_absorb | soul_drain |
| second_wind | second_wind |
| heroic_strike | titan_blow |

Poderes novos (sem antecessora): `fire_burst`, `chain_lightning`, `smite`, `slay_next`, `ally_rat`, `war_hound`, `field_medic`.

## 4. Metaprogressão

### Almas (`sim/meta_save.gd` `almas_for` / `apply_run`; constantes em `meta_tree.json "almas"`)
- Almas de uma run = `floor(dano / 300)` + `heróis mortos × 8`, depois `+ round(base × geral.almas_mult)`.
- O **dano nos heróis conta só até a vida máxima de cada herói** (`Sim.damage_hero`, anti-farm de cura/escudo): `sim.stats["almas_dmg"]`.
- Mantidas 100 % ao perder. O tutorial não rende Almas nem desafios. `per_hp` 300 e `per_hero` 8 estão em `meta_tree.json`; se a chave faltar, o código cai em 200 e 5.
- Estimativa (conta, não medida; H0 = 8120, step 1,17): derrubar p parties rende ~130 (p=3), ~190 (4), ~250 (5), ~340 (6), ~540 (8), ~800 (10), ~1150 (12), ~1870 (15) Almas. Com a progressão assumida de 4,5 parties na 1ª run e +0,4 por run: 1ª run ~220 Almas, acumulado ~1,4 mil na run 5, ~3,7 mil na 10, ~7,2 mil na 15, ~12 mil na 20, ~19 mil na 25, ~25 mil na 28.

### Árvore radial do Covil (`data/meta_tree.json`)
48 nós em 6 setores; a árvore inteira soma **23735 Almas** (~27 runs sem bônus). Regras: um nó só compra depois do pai (nível >= 1); `fx` é o TOTAL no nível (o nível comprado substitui o anterior) e é um DELTA sobre `MetaApply.DEFAULTS` (multiplicadores partem de 1,0); nós diferentes somam entre si. Caminhos `locais.<local>.<chave>` são deltas sobre a regra do local. Centro da roda: "Coração do covil". O setor "Arena" (vida das partes do chefe, dano do braço, estruturas) tem esse nome para não confundir com a tela Covil.

#### Atributos (10 nós, 6115 Almas)

| Nó | id | Pai | Níveis | Custos (Almas) | Efeito (texto do jogo e `fx` total por nível) |
|---|---|---|---|---|---|
| Poço fundo | `atr_elixir_max_1` | centro | 3 | 40 / 80 / 150 | +1 de elixir máximo por nível (até +3). — `elixir.max`: 1 / 2 / 3 |
| Poço mais fundo | `atr_elixir_max_2` | `atr_elixir_max_1` | 3 | 160 / 260 / 395 | +1 de elixir máximo por nível (soma com o Poço fundo). — `elixir.max`: 1 / 2 / 3 |
| Fonte viva | `atr_elixir_regen_1` | `atr_elixir_max_1` | 3 | 50 / 90 / 150 | +5% de ganho de elixir por nível. — `elixir.regen_mult`: 0,05 / 0,1 / 0,15 |
| Fonte caudalosa | `atr_elixir_regen_2` | `atr_elixir_regen_1` | 3 | 175 / 280 / 420 | +5% de ganho de elixir por nível (soma com a Fonte viva). — `elixir.regen_mult`: 0,05 / 0,1 / 0,15 |
| Cálice cheio | `atr_elixir_start_1` | centro | 3 | 35 / 70 / 120 | +1 de elixir no começo da run por nível. — `elixir.start`: 1 / 2 / 3 |
| Cálice transbordando | `atr_elixir_start_2` | `atr_elixir_start_1` | 3 | 135 / 225 / 335 | +1 de elixir no começo da run por nível (soma com o Cálice cheio). — `elixir.start`: 1 / 2 / 3 |
| Mão maior | `atr_hand_1` | centro | 2 | 160 / 420 | +1 carta na mão por nível (até +2). — `mao.inicial`: 1 / 2 |
| Mão cheia de ases | `atr_hand_2` | `atr_hand_1` | 1 | 1100 | +1 carta na mão (soma com a Mão maior). — `mao.inicial`: 1 |
| Compra veloz | `atr_recharge_1` | centro | 3 | 55 / 100 / 180 | A vaga da carta recarrega 8% mais rápido por nível. — `recarga.carta`: 0,08 / 0,16 / 0,24 |
| Compra relâmpago | `atr_recharge_2` | `atr_recharge_1` | 3 | 185 / 300 / 445 | A vaga da carta recarrega 6% mais rápido por nível (soma com a Compra veloz). — `recarga.carta`: 0,06 / 0,12 / 0,18 |

#### Locais (17 nós, 5165 Almas)

| Nó | id | Pai | Níveis | Custos (Almas) | Efeito (texto do jogo e `fx` total por nível) |
|---|---|---|---|---|---|
| Ritual generoso | `loc_ritual_1` | centro | 2 | 60 / 120 | Ritual: elixir ×3 no nível 1 e ×4 no nível 2, e dura 25% / 50% mais. — `locais.ritual.elixir_mult`: 1 / 2; `locais.ritual.dur_mult`: 0,25 / 0,5 |
| Ritual fácil | `loc_ritual_2` | `loc_ritual_1` | 2 | 135 / 235 | O ritual pede 20% / 40% menos mortes. — `locais.ritual.kills_mult`: -0,2 / -0,4 |
| Ritual farto | `loc_ritual_3` | `loc_ritual_2` | 2 | 250 / 435 | O ritual melhora mais as cartas (+15% / +30% na fração da melhoria). — `locais.ritual.reward_mult`: 0,15 / 0,3 |
| Taverna firme | `loc_tavern_1` | centro | 2 | 70 / 130 | Taverna: casas com +25% / +50% de vida e +15% / +30% de tempo. — `locais.tavern.house_hp_mult`: 0,25 / 0,5; `locais.tavern.window_mult`: 0,15 / 0,3 |
| Taverna farta | `loc_tavern_2` | `loc_tavern_1` | 2 | 145 / 250 | Taverna: +1 / +2 opções de modificador na recompensa. — `locais.tavern.mod_options`: 1 / 2 |
| Fonte calma | `loc_fountain_1` | centro | 2 | 60 / 110 | Fonte: +30% / +60% de tempo e o herói demora 25% / 50% menos para beber. — `locais.fountain.window_mult`: 0,3 / 0,6; `locais.fountain.drink_mult`: -0,25 / -0,5 |
| Fonte limpa | `loc_fountain_2` | `loc_fountain_1` | 2 | 135 / 235 | Fonte: remove +1 / +2 cartas na recompensa. — `locais.fountain.remove_extra`: 1 / 2 |
| Santuário frágil | `loc_shrine_1` | centro | 2 | 60 / 110 | Santuário: o herói precisa de 20% / 40% menos para vencer e você ganha +20% / +40% de tempo. — `locais.shrine.hold_mult`: -0,2 / -0,4; `locais.shrine.window_mult`: 0,2 / 0,4 |
| Santuário farto | `loc_shrine_2` | `loc_shrine_1` | 2 | 135 / 235 | Santuário: recompensa +50% / +100%. — `locais.shrine.reward_mult`: 0,5 / 1 |
| Ponte curta | `loc_bridge_1` | centro | 2 | 60 / 110 | Ponte: +25% / +50% de tempo e a meta de dano é 20% / 40% menor. — `locais.bridge.window_mult`: 0,25 / 0,5; `locais.bridge.goal_mult`: -0,2 / -0,4 |
| Ponte farta | `loc_bridge_2` | `loc_bridge_1` | 2 | 135 / 235 | Ponte: recompensa +50% / +100%. — `locais.bridge.reward_mult`: 0,5 / 1 |
| Barganha | `loc_shop_1` | centro | 2 | 80 / 150 | Loja do mercador: preços 10% / 20% menores. — `locais.shop.price_mult`: -0,1 / -0,2 |
| Prateleira cheia | `loc_shop_2` | `loc_shop_1` | 2 | 160 / 300 | Loja do mercador: +1 / +2 cartas à venda. — `locais.shop.extra_cards`: 1 / 2 |
| Ajudante cansado | `loc_helper_1` | centro | 2 | 70 / 130 | Herói ajudante: 20% / 40% menos vida e +25% / +50% de tempo. — `locais.helper.hp_mult`: -0,2 / -0,4; `locais.helper.window_mult`: 0,25 / 0,5 |
| Ajudante generoso | `loc_helper_2` | `loc_helper_1` | 1 | 300 | Herói ajudante: +1 opção de relíquia na recompensa. — `locais.helper.relic_options`: 1 |
| Mais escolhas | `loc_event_1` | centro | 1 | 90 | Eventos de texto: +1 opção de resposta. — `locais.event.extra_options`: 1 |
| Boa sorte | `loc_event_2` | `loc_event_1` | 2 | 155 / 280 | Eventos de texto: +15% / +30% de chance do resultado bom. — `locais.event.good_chance`: 0,15 / 0,3 |

#### Arena (6 nós, 4190 Almas)

| Nó | id | Pai | Níveis | Custos (Almas) | Efeito (texto do jogo e `fx` total por nível) |
|---|---|---|---|---|---|
| Carne do covil | `are_boss_hp_1` | centro | 3 | 50 / 100 / 180 | +10% de vida das partes do chefe por nível. — `arena.boss_hp_mult`: 0,1 / 0,2 / 0,3 |
| Couro do covil | `are_boss_hp_2` | `are_boss_hp_1` | 3 | 200 / 320 / 495 | +10% de vida das partes do chefe por nível (soma com a Carne do covil). — `arena.boss_hp_mult`: 0,1 / 0,2 / 0,3 |
| Braço pesado | `are_arm_1` | centro | 3 | 60 / 120 / 220 | +10% de dano do braço do chefe por nível. — `arena.arm_dmg_mult`: 0,1 / 0,2 / 0,3 |
| Braço de ferro | `are_arm_2` | `are_arm_1` | 3 | 210 / 345 / 545 | +10% de dano do braço do chefe por nível (soma com o Braço pesado). — `arena.arm_dmg_mult`: 0,1 / 0,2 / 0,3 |
| Altares firmes | `are_struct_1` | centro | 3 | 55 / 110 / 200 | +15% de vida dos altares e pilares da arena por nível. — `arena.struct_mult`: 0,15 / 0,3 / 0,45 |
| Pilares de pedra | `are_struct_2` | `are_struct_1` | 3 | 185 / 310 / 485 | +15% de vida dos altares e pilares da arena por nível (soma com os Altares firmes). — `arena.struct_mult`: 0,15 / 0,3 / 0,45 |

#### Relíquias (4 nós, 1280 Almas)

| Nó | id | Pai | Níveis | Custos (Almas) | Efeito (texto do jogo e `fx` total por nível) |
|---|---|---|---|---|---|
| Mais uma escolha | `rel_slot_1` | centro | 1 | 80 | +1 opção em toda oferta de relíquia. — `reliquias.extra_options`: 1 |
| Mais duas escolhas | `rel_slot_2` | `rel_slot_1` | 1 | 260 | +1 opção em toda oferta de relíquia (soma com Mais uma escolha). — `reliquias.extra_options`: 1 |
| Oficina de relíquias | `rel_discount_1` | centro | 3 | 90 / 180 / 320 | Subir o nível das relíquias custa 10% menos por nível. — `reliquias.level_discount`: 0,1 / 0,2 / 0,3 |
| Presente de abertura | `rel_start_1` | `rel_slot_1` | 1 | 350 | A run começa com uma oferta de relíquia. — `reliquias.start_offer`: 1 |

#### Troca de ato (4 nós, 2090 Almas; só abre depois da 1ª vez que o jogador chega ao ato 2)

| Nó | id | Pai | Níveis | Custos (Almas) | Efeito (texto do jogo e `fx` total por nível) |
|---|---|---|---|---|---|
| Respiro | `ato_switch_1` | centro | 2 | 70 / 140 | Ao trocar de ato, devolve 50% / 100% do elixir máximo. — `ato.elixir_refill`: 0,5 / 1 |
| Saque do ato | `ato_gold_1` | `ato_switch_1` | 3 | 100 / 190 / 330 | Ao trocar de ato, +30 / +60 / +100 de ouro. — `ato.gold`: 30 / 60 / 100 |
| Mão nova | `ato_hand_1` | `ato_switch_1` | 1 | 260 | Ao trocar de ato, a mão volta cheia. — `ato.hand_refill`: 1 |
| Grande saque | `ato_gold_2` | `ato_gold_1` | 3 | 185 / 320 / 495 | Ao trocar de ato, +40 / +80 / +140 de ouro (soma com o Saque do ato). — `ato.gold`: 40 / 80 / 140 |

#### Geral (7 nós, 4895 Almas)

| Nó | id | Pai | Níveis | Custos (Almas) | Efeito (texto do jogo e `fx` total por nível) |
|---|---|---|---|---|---|
| Bolsa inicial | `ger_gold_start_1` | centro | 3 | 40 / 80 / 140 | Começa a run com +10 / +25 / +45 de ouro. — `geral.ouro_inicial`: 10 / 25 / 45 |
| Cofre inicial | `ger_gold_start_2` | `ger_gold_start_1` | 3 | 135 / 235 / 370 | Começa a run com +20 / +45 / +80 de ouro (soma com a Bolsa inicial). — `geral.ouro_inicial`: 20 / 45 / 80 |
| Sede de almas | `ger_almas_1` | centro | 4 | 60 / 120 / 220 / 380 | +5% de Almas por run por nível (até +20%). — `geral.almas_mult`: 0,05 / 0,1 / 0,15 / 0,2 |
| Fome de almas | `ger_almas_2` | `ger_almas_1` | 2 | 370 / 590 | +5% / +10% de Almas por run (soma com a Sede de almas). — `geral.almas_mult`: 0,05 / 0,1 |
| Escriba do covil | `ger_card_disc_1` | centro | 3 | 100 / 200 / 350 | Subir o nível das cartas custa 5% menos por nível. — `geral.card_discount`: 0,05 / 0,1 / 0,15 |
| Mestre escriba | `ger_card_disc_2` | `ger_card_disc_1` | 2 | 310 / 495 | Subir o nível das cartas custa 20% / 25% menos (substitui o Escriba do covil). — `geral.card_discount`: 0,2 / 0,25 |
| Despojos de cada herói | `ger_offer_hero` | centro | 1 | 700 | Toda queda de herói oferece uma carta, não só a da party inteira. — `oferta_por_heroi`: 1 |


### Cartas I a VI (Biblioteca)
Meta e run sobem até o VI. +25 % por nível (`rules.card_levels.growth`). Desconto de custo −1 no III e −1 no V (máximo 2). O especial `n3` só existe no VI. Preço (`meta_tree.json`): `card_level_costs` [60, 140, 250, 400, 620] × `card_rarity_mult` [1, 1,5, 2,5, 4] (comum, incomum, rara, lendária). Comprar I a VI de uma carta custa 1470 (comum) / 2205 / 3675 / 5880 (lendária). O nó `ger_card_disc_*` desconta até 40 % (clamp 90 %).

| Nível | Multiplicador | Desconto de custo | Especial n3 | Preço em Almas para chegar (comum / incomum / rara / lendária) |
|---|---|---|---|---|
| I | ×1 | −0 | não | — |
| II | ×1,25 | −0 | não | 60 / 90 / 150 / 240 |
| III | ×1,5 | −1 | não | 140 / 210 / 350 / 560 |
| IV | ×1,75 | −1 | não | 250 / 375 / 625 / 1000 |
| V | ×2 | −2 | não | 400 / 600 / 1000 / 1600 |
| VI | ×2,25 | −2 | sim | 620 / 930 / 1550 / 2480 |

Deck: 19 cartas, até 3 cópias de cada, do vilão ou comuns liberadas, um deck montado por vilão.

### Relíquias
52 relíquias (12 common, 23 uncommon, 14 rare, 3 legendary). Em `data/relics.json`: **12 livres** desde o início; 40 por desafio. Nível 1 a 3 (×1 / ×1,5 / ×2 nos bônus positivos de `relic_scalable`; flags, limites e penalidades não escalam), comprado com Almas: `relic_level_costs` [120, 320] × multiplicador da raridade (menos `reliquias.level_discount`). Setor Relíquias da árvore: opções extras, desconto de nível, oferta no início da run. O pool das ofertas filtra as liberadas, com fallback de raridade.

Livres: `bone_crown`, `lair_tithe`, `black_mortar`, `victory_horn`, `overflowing_chalice`, `elixir_flask`, `quick_spring`, `war_drum`, `blood_tithe`, `bronze_bell`, `torn_banner`, `miser_ledger`.

| Tipo de desafio | Relíquias |
|---|---|
| cartas jogadas | `watchful_eye`, `heavy_grimoire`, `forge_hammer`, `tinker_file`, `living_library`, `arcane_ink`, `tally_stick`, `frost_shard` |
| chegar à party N (recorde) | `cracked_hourglass`, `shortcut_stone`, `profane_earth`, `bad_blood`, `hand_pocket`, `opening_gambit`, `phylactery` |
| elixir máximo | `deep_cauldron`, `heart_of_well`, `eternal_fountain`, `deep_cistern`, `still_aether`, `aether_heart` |
| heróis derrotados (total entre runs) | `jailer_chains`, `victory_mark`, `greedy_seal`, `stamp_ink` |
| cartas numa janela de tempo | `raider_pack`, `hanged_hand`, `chain_ring`, `rift_key` |
| pico de unidades em campo | `pack_howl`, `twin_litter` |
| elixir gasto | `rushing_tide`, `fine_sand` |
| ouro no fim da run | `act_hoard`, `lucky_coin` |
| ouro ganho | `merchant_purse` |
| ouro gasto | `living_vault` |
| unidades mortas | `grave_call` |
| dano em rajada | `tar_pit` |
| a mesma carta N vezes | `giant_scale` |

### Desafios (`data/unlocks.json`, gerado por `tools/gerar_unlocks.py` a partir de `tools/desbloqueios.json`)
- 53 cartas bloqueadas por desafio (vilão: só as runs com ele; comum: todas). Tipos: por party (recorde), total entre runs (`total`), "em N runs" (`runs`, 15 cartas; duas reliquias), "numa mesma run" (zera a cada run) e jogada específica.
- Desafios de **carta por party**: party 5 `devour`; party 5 `eruption`; party 5 `soul_harvest`; party 8 `bone_totem`; party 8 `furnace`; party 8 `sewer_flood`; party 10 `ruin_titan`. **Relíquias por party**: party 3 `cracked_hourglass`; party 4 `opening_gambit`; party 6 `shortcut_stone`; party 7 `hand_pocket`; party 8 `profane_earth`; party 9 `bad_blood`; party 12 `phylactery`.
- O progresso é gravado no fim de cada run (inclusive perdida); a tela de fim mostra a "revelação" do que acabou de liberar.

### Reembolso total e conservação
`MetaSave.refund_all()` zera nós, níveis de carta e níveis de relíquia e devolve **tudo**: `almas = almas_earned` (conserva, mesmo com os descontos que os nós davam). Decks montados e cartas/relíquias liberadas ficam. `refund(id)` devolve o último nível de um nó se nenhum filho depende dele.

### MetaSave v5 (`user://meta.save`, `VERSION = 5`; save de versão menor zera)
Campos gravados: `ver`, `almas`, `almas_earned`, `upgrades` {nó: nível}, `card_levels` {carta: I..VI}, `decks` {vilão: 19 ids}, `relic_levels` {relíquia: 1..3}, `relics_unlocked`, `best_party`, `best_by_villain`, `act2_reached`, `unlocked` (cartas), `villain`, `villains`, `runs`, `heroes_seen`, `wins_by_villain`, `heroes_total`, `progress`, `totals`, `runs_done`. Saíram `phases_won`, `endless_best`, `rare_choices`, `win_phase`. A run em andamento tem save próprio (`sim/save_game.gd`, v8: poderes, níveis e recargas). API: `buy`, `refund`, `refund_all`, `can_buy`, `node_cost`, `buy_card_level`, `buy_relic_level`, `deck_for`/`set_deck`/`deck_ok`, `apply_run`, `reach_party`, `see_act2`. Testes sempre com caminho temporário (`MetaSave.save(path)`), nunca o `user://meta.save` do jogador.

## 5. Telas novas

Capturas em segundo plano (22 arquivos em `docs/metaprogressao/`):

- `docs/metaprogressao/biblioteca_album.png`
- `docs/metaprogressao/biblioteca_bloqueada.png`
- `docs/metaprogressao/biblioteca_comuns.png`
- `docs/metaprogressao/biblioteca_filtro_custo.png`
- `docs/metaprogressao/biblioteca_zoom_atual_proximo.png`
- `docs/metaprogressao/biblioteca_zoom_v.png`
- `docs/metaprogressao/covil_comprados.png`
- `docs/metaprogressao/covil_janela.png`
- `docs/metaprogressao/covil_troca_ato_trancado.png`
- `docs/metaprogressao/covil_visao_geral.png`
- `docs/metaprogressao/covil_zoom_setor.png`
- `docs/metaprogressao/menu_escolher_vilao.png`
- `docs/metaprogressao/menu_escolher_vilao_trancado.png`
- `docs/metaprogressao/menu_fim_da_run.png`
- `docs/metaprogressao/menu_fim_da_run_revelacao.png`
- `docs/metaprogressao/menu_pausa_poderes.png`
- `docs/metaprogressao/menu_principal.png`
- `docs/metaprogressao/poder_painel_evolucao.png`
- `docs/metaprogressao/poder_painel_novo.png`
- `docs/metaprogressao/poderes_icones.png`
- `docs/metaprogressao/queda_curta.png`
- `docs/metaprogressao/queda_longa.png`

- **Menu principal** (pele Mapa aberto): Continuar, Covil, Biblioteca, Compêndio, Tutorial, Configurações, Sair, com recorde e Almas. **Escolher vilão**: deck 19/19, recorde por vilão, trancado "derrote a party N", Editar deck / Começar. **Pausa**: + Poderes da party; desistir mantém as Almas. **Fim da run**: "O covil caiu na party N de 15", recorde, Almas (dano + heróis + total), desafios com a revelação.
- **Covil**: roda radial com arrastar e zoom, janela lateral por nó (efeito, nível, preço, Comprar), lateral com Almas, Reembolsar tudo, Biblioteca, Começar run. Cores comprado / disponível / trancado (tracejado). Setor "Troca de ato" mostra "chegue ao ato 2" até a 1ª vez que o jogador chega lá. Cena de teste: `game/covil_demo.tscn`.
- **Biblioteca**: abas por vilão + Comuns, álbum, filtro por custo, lista fina do deck com curva de elixir, zoom com a carta atual ao lado da próxima (números recalculados, especial no VI). Cena de teste: `game/library_demo.tscn`.
- **HUD dos poderes**: ícones com timer de recarga sobre a party, painel de revelação com pausa, queda curta por membro e longa só na última.
- Scripts de captura: `tools/capture_menus.sh`, `tools/capture_biblioteca.sh`, `tools/capture_hud.sh`, `game/covil_demo.gd` (`--shots=`).

## 6. Decisões assumidas (revise)

Tomadas pelas frentes sem perguntar (modo autônomo). Todas reversíveis por dado, salvo onde indicado.

1. **`rules.party.step` de 1,21 para 1,17** (decisão da frente A, reversível em `data/rules.json`). Com 1,21 a party 15 seria ×14,4 a party 1 e a conta pedia ×55 de poder da party 4,5 à 15, inalcançável; com 1,17 é ×9,0 (×27 de poder). O `_doc` do `hero_powers.json` ainda fala em `1,21^(party-1)` nos exemplos numéricos; as proporções valem, os valores absolutos de D estão ~20 % altos nas parties finais.
2. **Ritual do Covil**: o plano dizia ×3 de elixir (e não ×4). O ritual base é ×2 (`rules.locations.ritual.elixir_mult`); o nó `loc_ritual_1` soma +1 no nível 1 (**×3**) e **+2 no nível 2 (×4)**. Ou seja, o nível 2 chega ao ×4 que a decisão queria evitar. Ajuste fácil: `fx` `locais.ritual.elixir_mult` [1.0, 1.0] ou custos. Marcado para você decidir.
3. **Preços da árvore** (48 nós, 23735 Almas, ~27 runs de Almas) **só pela conta** (H0 8120, `per_hp` 300, `per_hero` 8, progressão assumida de 4,5 parties e +0,4 por run). Nada medido com o bot.
4. **Desafios por party** escolhidos pela frente D: cartas nas parties 5 / 8 / 10 (`devour`, `eruption`, `soul_harvest`; `bone_totem`, `furnace`, `sewer_flood`; `ruin_titan`) e relíquias nas parties 3, 4, 6, 7, 8, 9 e 12. Os demais desafios de "em N fases" viraram "em N runs", e as metas "numa mesma run" (antes por fase) **mantiveram os mesmos limiares** dos de 1 fase, agora valendo para uma run inteira de 15 parties (em geral mais fácil de cumprir que antes).
5. **Almas +%**: o `_doc` de `meta_tree.json` fala em "+50 % no máximo", mas os nós `ger_almas_1` (até +20 %) e `ger_almas_2` (até +10 %) somam **+30 %** no máximo. A conta "~23 runs com bônus" fica então entre 23 e 27.
6. **Aliados dos poderes** (rato e cão de guerra) andam dentro do motor de poderes, **sem motor de unidades aliadas**: os monstros não miram aliados, e a absorção de dano deles é aproximada (cada inimigo a menos de 1,6 do rato lhe tira metade do dano por segundo dele). Podem parecer fracos ou estranhos na tela.
7. **Aba Covil na pele Diário** só com fade (sem animação própria da pele).
8. Nome do setor **"Arena"** (o "covil" que o jogador ataca: vida das partes do chefe, dano do braço, estruturas) assumido para não confundir com a tela Covil.
9. **Fila das parties** (tamanhos 1,1,2,2,2,3,3,3,3,4×6 e ordem das classes), `hp_mult` 2,8 herdado da antiga fase 1 e `damage_mult` 1,0: desenho da frente A, sem medição.
10. **Dados dos poderes** (frente B): pesos 0,8 (aliados) e 0,7 (curandeira) contra 1,0 dos demais, `counter_gain` 3,0, `evolution_chance` 0,34 e todos os multiplicadores de dano e recarga saíram do orçamento do `_doc` (25 a 35 % do DPS da party no nível 1, ~100 % no 3), não de teste.
11. **Oferta por herói** (`ger_offer_hero`) custa 700 Almas num único nível; ouro inicial, Almas +%, desconto de carta e Troca de ato têm custos pela conta de preço relativo (primeiros nós 35 a 60 Almas).
12. Níveis I a VI: tabela de preços `card_level_costs` × raridade e `relic_level_costs` × raridade pela conta (um deck de 19 no VI passa de 30 mil Almas; ninguém fecha tudo, de propósito).
13. Os textos `{chave}` dos poderes e dos nós do Covil estão em PT e EN no `strings.csv`; os nomes (ex.: "Poço fundo", "Fonte viva") foram escolhidos pelas frentes.

## 7. Riscos e não medido

- **Metas de dificuldade NÃO medidas**: 1ª run chegando à party 4–5 e rendendo Almas para 2–3 melhorias baratas; vitória perto da run 20. O balanceamento é **da próxima rodada** (bot de balanço + teste fino do dono).
- **Tempo de run no bot**: `sim.max_run_seconds = 3000` s e o bot `heuristic` faz só **5 a 11 parties** nesse tempo (270–600 s por party). Uma run de 15 parties pede **mais de 4000 s** no ritmo do bot; nem a meta maxada terminou nas seeds 1 a 3. Ou o limite sobe, ou o bot acelera, antes de usar o bot para balancear.
- **Curva ×1,17 por party não calibrada**; o poder efetivo do herói é vida × dano (step² por party).
- **Custos das Almas e a conversão** (dano / 300, +8 por herói) não medidos; a progressão de 4,5 parties + 0,4 por run é suposição.
- **Ajustador automático** (`tools/balance_auto`, worktree `LastBoss-balance-auto`, `docs/AJUSTADOR_AUTOMATICO.md`) e **editor de balanço** (`localhost:8767`, `tools/balance_editor`) ainda citam fases e a campanha de 7 fases; ficam para a rodada do bot.
- **Sobras no CSV**: `locale/strings.csv` ainda tem chaves das telas e textos antigos (campanha, Horda sem fim, Coleção, 15 habilidades) sem uso.
- **Conta de Almas**: os números "~23 runs com bônus" e "uma comum no VI custa 1450" do `_doc` de `meta_tree.json` estão levemente fora (o bônus máximo é +30 %, a soma dos degraus de preço é 1470).
- **Ritual ×4** no nível 2 do nó do Covil (decisão 2).
- **Desafios "numa mesma run"** com limiares dos de 1 fase podem liberar cedo demais.
- Documentos antigos (campanha, Horda, rodadas) foram só marcados como desatualizados no topo, sem reescrever.

## 8. Como testar

Godot 4.7, Git Bash:

```
G="/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import          # sempre antes (class_name novos, imports)
"$G" --headless --path . res://tests/tests.tscn -- --only=t_run15,t_powers,t_levels6,t_meta5,t_covil_ui,t_library_ui,t_menus,t_bots15
"$G" --headless --path . res://tests/tests.tscn    # suíte inteira; última linha "falhas: N"
```

- Testes das frentes: `t_run15` (A, run de 15 parties), `t_powers` (B, motor de poderes), `t_levels6` (C), `t_meta5` (D, MetaSave v5, Almas, árvore), `t_covil_ui` (E), `t_library_ui` (F), `t_menus` (G), `t_bots15` (J). Testes antigos quebrados pela mudança de design são da frente I.
- **Runs completas do bot** (só para pegar números absurdos, não é balanceamento): `... res://tests/tests.tscn -- --only=t_bots15 --runs` roda `BotRun.run(data, seed, mods, deck, {"max_t": 6000})` em 3 seeds, sem meta e com `BotRun.maxed_mods(data)` (todos os nós no último nível, cartas no VI, relíquias liberadas nível 3). Cada run completa leva minutos reais.
- `--menutest` (fluxo do menu com o mouse, janela real): `"$G" --position -6000,0 --path . -- --menutest --hud=7`.
- Janela sempre em segundo plano (`--position -6000,0`), sem mover o mouse; capturas: `tools/capture_*.sh`.
- Todo teste que salva usa caminho temporário (`user://test_*.save`).
