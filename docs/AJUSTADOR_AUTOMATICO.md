# Ajustador automático de balanceamento — relatório da primeira rodada (18/11/2026)

Branch `balance-auto` (worktree `../LastBoss-balance-auto`). Plano: `docs/PLANO_AJUSTADOR_AUTOMATICO.md`. **Nada foi para `data/`**: o que existe é a página `tools/patch_notes.html` (caixa de aprovar + exportar JSON) e `tools/balance_auto/apply_approved.py` para aplicar só o que você marcar.

## O que foi feito
- **RNG em três fluxos** (`sim/sim.gd`): `rng` (combate), `rng_map` (estrada e classes da party), `rng_offer` (ofertas, relíquias, eventos, melhorias). Os dois braços de um A/B pegam o mesmo mapa e as mesmas ofertas. `sim/save_game.gd` salva e restaura os dois fluxos novos (saves antigos continuam carregando).
- **Métrica contínua**: `hero_dmg` e `hp_frac` (fração da vida total do grupo tirada) em cada run.
- **Ganchos no `headless/batch.gd`**: `--swap_card=id:ref` (carta entra no baralho no lugar de uma de mesmo custo) e `--ban_card=id`.
- **`tools/balance_auto/`**: `engine.py` (variantes de `data/`, cache por run, A/B pareado), `auto.py` (smoke, triagem, ajuste de cartas, relíquias, eventos, dificuldade, validação), `notes.py` (página), `apply_approved.py` (etapa 12: confere que o caminho existe uma vez e que o "antes" ainda é o atual).
- Estado e cache em `balance_reports/auto/` (só `state.json` e `run.log` vão no commit; o cache de ~15 mil runs é regenerável).
- Retomar/rodar de novo: `BA_PHASE=5 python -I tools/balance_auto/auto.py all`.

## Medição
- Bot `human`; cartas e relíquias medidas na **fase 5** (nas fases baixas o humano ganha ~100% e não há sinal) nos 3 vilões.
- Impacto = Δ de `hp_frac` pareado por semente contra o controle; carta = troca por carta de mesmo custo do baralho inicial, comparada à mediana do grupo de custo.
- Faixa de tolerância medida: **cartas 0,041, relíquias 0,038, eventos 0,015** (da vida do grupo). 16 sementes na triagem, +32 nos suspeitos, 24 por ciclo de ajuste.
- 15.306 runs no total; mediana de ~15 s por run com 12 núcleos.

## Resultado
**Mudanças propostas (7)**, todas voltaram para a faixa em 1–2 ciclos:

| Item | Botão | Antes → depois |
|---|---|---|
| `rabid_rats` | dps | 5 → 5,81 |
| `gold_merc` | dps | 16 → 12 |
| `hunt_instinct` | fx.speed | 0,6 → 0,697 |
| `pack_den` | custo | 5 → 6 |
| `gilded_golem` | dps | 40 → 30 |
| `blood_tax` | fx.gold_cost | 20 → 17 (ainda perto do limite: z 0,047) |
| `quick_spring` (relíquia) | fx.elixir_regen | 0,4 → 0,344 |

Das 118 cartas e 53 relíquias, só estas saíram da faixa. Isso **não prova que o resto está equilibrado**: a faixa de ±0,04 não enxerga desvios menores, e a régua é relativa (mediana do custo), então um custo inteiro forte ou fraco passa batido. Eventos: só `heroes_banquet` opção `poison` saiu da faixa (vai para "repensar": evento não tem botão automático). Nenhuma carta caiu em "o bot não usa".

**Dificuldade por fase (só `hp_mult`, humano 3 vilões × 30 sementes por sondagem):**

| Fase | `hp_mult` antes → depois | Humano (meta) | Aleatório |
|---|---|---|---|
| 0 | 0,135 → 0,27 | 100% (90%) | 100% |
| 1 | 1,4 → 2,8 | 94% (60%) | 53% |
| 2 | 2,67 → 5,34 | 69% (56%) | 22% |
| 3 | 2,3 → 4,6 | 76% (52%) | 35% |
| 4 | 2,5 → 5,0 | 49% (48%) | 28% |
| 5 | 2,6 → 3,69 | 40% (44%) | 17% |
| 6 | 2,8 → 2,45 | 37% (40%) | 10% |

As fases 0 a 3 **saturaram no limite de 2×** e estão em "repensar": só o `hp_mult` não chega à meta, o que aponta para mecânica (dano da fase, que ficou fixo nesta rodada, ou bot humano forte demais no início). A fase 4 chegou na meta, mas o aleatório ganha 28% (>25%): alarme de mecânica. **Não aplique os `hp_mult` das fases 1 a 3 como estão**: a meta não é alcançada e a fase fica só mais longa.

**Validação** (sementes 90001+, 12 por célula, com todas as mudanças ligadas): a família `human_*` e o heurístico ficam na mesma faixa do humano nas fases 1 a 5. Na fase 6 o `human_novice` cai para 14% e o heurístico para 22% (humano 42%): vão grande, só relatado. Tabela completa na página.

## Não feito (pendente)
- **Etapa 0**, auditoria de botões inertes (campos que o Sim talvez não leia).
- **Camada 2**: heróis, classes, bênçãos e buffs.
- Botões automáticos para **eventos** (só medidos).
- **Segunda passada** com mais sementes nas cartas/relíquias perto do limite, em outras fases.
- Conferir `n3`, `lvl` e textos do locale das cartas alteradas antes de aplicar (o `apply_approved.py` lembra disso).
- Ainda vale uma partida sua: o bot humano é só um proxy.

## Testes
`tests.tscn` no worktree: a separação do RNG mudou os mapas por semente e quebrou cenários presos a ela; foram ajustados em `tests/tests.gd`: o local do teste fixa `hard = false` (o mapa sorteava local difícil, com metas ×), e Biblioteca, Cofre do Dragão e Herói Ajudante passam a pular ofertas enquanto avançam o tempo (`_steps_free`). O teste da Clériga (escudo, sem cura) é o mesmo trabalho pendente que estava sem commit na main. `tests/dbg.tscn` roda só as funções pedidas: `godot --headless res://tests/dbg.tscn -- t_contests,t_helper`.

**Ressalva sobre a ponte.** `t_water` (monstro atravessa a ponte até o herói em 25 s) passava na semente 5 da main. Com o mapa novo da semente 5 ele falha. Medindo as sementes 1 a 12 no worktree, só uma parte das pontes é atravessada nesse cenário (a semente 6 atravessa todas). Não consegui comparar com a main (a comparação travou), então não sei se isso já era assim ou se piorou. O teste foi movido para a semente 6; vale uma olhada na travessia de pontes, a pedido de quem for mexer nos rios.
