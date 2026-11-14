# Desbloqueio de cartas por desafio (13/11/2026)

Substitui a compra com Almas. **Fase = uma run inteira** (~23–27 min); os contadores "numa mesma fase" zeram a cada fase.

## Regras decididas com o jogador

- **Deck base fixo** por vilão (`data/villains.json`, `start_deck`): Praga 14, Dragão 15, Lich 14 cartas.
- **Liberada** = pode ser sorteada nas ofertas da run. **Bloqueada** = só entra no sorteio depois de cumprir o desafio.
- **Carta comum** (`owner: common`) tem o mesmo estado e o mesmo desafio nos 3 vilões; liberada em um = liberada em todos. Carta que está no deck base de qualquer vilão é liberada para todos.
- Desafios únicos dentro de cada classe; números pensados para uma fase inteira.
- Acabou a compra com Almas (`MetaSave.can_buy/unlock` devolvem falso) e a rara à escolha das fases 3 e 4 (não paga mais). As Almas ainda são ganhas e aparecem no resultado; ficaram sem uso (decidir o que fazer com elas).
- Saves antigos (versão < 3): a coleção recomeça do deck base + liberadas; Almas, vilões liberados e fases vencidas ficam.

## Onde está

| O quê | Arquivo |
|---|---|
| Escolha do jogador (editável) | `tools/desbloqueios.json` (cola do editor `tools/escolher_base.html`) |
| Conversor → dados do jogo + textos | `python tools/gerar_unlocks.py` → `data/unlocks.json` e linhas `UNLOCK_<id>` em `locale/strings.csv` |
| Rastreador de métricas na fase | `sim/unlock_track.gd` (ganchos em `sim/sim.gd`: tick, jogada, morte de unidade, dano no herói, queda de herói, moedas, fim) |
| Conferência no fim da fase e progresso salvo | `MetaSave.apply_unlocks()` (`sim/meta_save.gd`), chamada em `game/main.gd` antes de `win_phase` |
| Coleção e compêndio | `UiKit.unlock_text()` mostra "Desafio: … (11/15)" nas cartas bloqueadas |
| Tela de revelação no fim da fase | `game/unlock_reveal.gd`, chamada por `Hud._show_unlocks()`; cena de teste `tools/gallery/unlock_reveal_shot.tscn` |

Para mudar um desafio: editar no `tools/escolher_base.html`, copiar o JSON, atualizar `tools/desbloqueios.json` e rodar `tools/gerar_unlocks.py`. Texto novo precisa casar com um dos padrões do script (ele avisa quando não casa).

## Como cada tipo é medido

`peak` (unidades de uma família ao mesmo tempo, amostrado a cada 8 passos), `peak_multi` (2 Feras e 8 ratos juntos), `peak_on_spell` (Bando em campo ao jogar um feitiço), `plays` (cartas jogadas por família), `plays_same` (mesma carta de monstro), `plays_window` (N jogadas em S s), `burst` (dano ao herói em S s), `soak_ignite` (Encharcado → fogo em até S s), `win_phase`, `wins` (por vilão, acumulado), `heroes_total` (acumulado), `win_without`, `win_max`, `no_loss` / `loss_max` (entre uma queda de herói e a seguinte, ou o início, morreram no máximo N monstros seus; morte por tempo não conta), `died`, `peste`, `curses`, `gold_end/spent/earned`, `elixir_spent`, `elixir_max`, `soaked_time`, `burn_time`, `coins`, `spells_distinct` (feitiços diferentes jogados, não "que acertaram").

Famílias de unidade: ratos = `rat`, `rat_horde`, `rabid_rats`, `rat_brute`, `rat_tide`; morcegos = `bat`, `bat_cloud`; esqueletos = `skeleton`, `bone_legion`, `skeleton_archers`; Fera = `fx.beast`; Bando/Morto-vivo/Fogo = tags.

## Decisões minhas (revisar)

- A fase de tutorial (fase 0) não libera nada.
- Só as cartas do pool do vilão jogado (e as comuns) são conferidas na run; o progresso vale por carta (melhor tentativa).
- "Derrote o herói sem perder nenhum monstro": entre uma queda e a seguinte (ou o início), nenhum monstro seu morreu (morte por tempo não conta).
- 13/11/2026: números ajustados pelo jogador depois de uma sonda com bots (proposta em `tools/propostas_numeros.html`): ex. Ogro 100 monstros, Flautista 1000 ratos mortos, Curandeiro Caído "perdendo no máximo 5 monstros", Nuvem de Morcegos "12 bichos de Bando ao mesmo tempo".
- Valores de dano/ouro/Elixir foram estimados pelas regras (1 Elixir/2,8 s ≈ 500 por fase; 1 ouro/40 de dano) e **não medidos** com bots no jogo.
