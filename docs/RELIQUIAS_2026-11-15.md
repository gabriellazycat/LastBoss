# Relíquias novas e ícones (15/11/2026)

Página: `python -m http.server 8769 --bind 127.0.0.1` na raiz do projeto → http://localhost:8769/docs/reliquias/
(ou o preview "reliquias" em `.claude/launch.json`). Regerar: `python tools/art/relic_icons.py` e `python tools/art/relic_page.py`.

## O que entrou

- **12 relíquias novas** em `data/relics.json` (marcadas com `"new": "2026-11-15"`), textos PT/EN em `locale/strings.csv`.
- **Ícone SVG para as 53 relíquias** em `assets/ui/relics/<id>.svg`, no traço dos ícones do mapa (tinta + papel + vermelho;
  elixir em roxo, ouro em dourado, gelo em azul). Aparecem na oferta (em cima do nome), na coluna do HUD (no lugar do ◆),
  na aba Relíquias da Coleção e na loja do mercador (ficha e linha da relíquia à venda).

| Relíquia | Raridade | Efeito | fx |
|---|---|---|---|
| Areia Fina | incomum | vaga recarrega 40% mais rápido | `draw_delay: -0.4` |
| Sino de Bronze | comum | vaga recarregada dá +0,3 elixir | `refill_elixir: 0.3` |
| Mochila do Saqueador | incomum | +1 mão, recarga 50% mais lenta | `hand: 1, draw_delay: 0.5` |
| Mão do Enforcado | rara, única | +2 mão, elixir 15% mais lento | `hand: 2, elixir_regen: -0.15` |
| Tinta Arcana | rara | feitiços -1 (mínimo 1) | `spell_discount: 1` |
| Estandarte Rasgado | comum | unidades +10% dano no herói | `unit_dmg: 0.1` |
| Balança do Gigante | incomum | custo base 6+ custa -1 | `big_discount: 1` |
| Talha de Contagem | incomum, única | cada 8ª carta jogada é grátis | `nth_free: 8` |
| Anel Encadeado | incomum | 3 cartas em 4 s devolvem 1 elixir | `chain_elixir: 1` |
| Livro do Avarento | comum | ouro do dano ×1,25, loja +10% | `gold: 0.25, shop_price: 0.1` |
| Lasca de Gelo | rara | herói 15% mais lento, -1 elixir máx. | `hero_slow: 0.15, elixir_max: -1` |
| Chave da Fenda | incomum | arena: teleporte -2 s e -1 custo | `teleport_cd: -2, teleport_cost: -1` |

Código: `sim/sim.gd` (`draw_delay()`, Sino em `_tick_draws`, descontos em `card_cost`, Talha e Anel em `play`,
Estandarte em `unit_hits_hero`), `game/hand_fan.gd` (o tracejado enche no tempo da recarga com relíquias),
`game/ui_kit.gd` (`UiKit.relic_icon`), `game/hud.gd`, `game/compendium.gd`, `game/shop_ledger.gd`.

## Decisões assumidas sem você (estava fora)

1. **Peso de sorteio = 1 (padrão) em todas as novas**, sem balancear e sem rodar bots, como você pediu. `bot_value` chutado (1,5–3,5).
2. **Recarga como multiplicador**: `draw_delay` soma frações (Areia -40%, Mochila +50%) e a recarga nunca cai abaixo de 15% de 1 s.
3. **Talha de Contagem e Mão do Enforcado únicas** (em dobro ficariam estranhas); as outras empilham como as antigas.
4. **Correção de bug que as novas expunham**: a oferta de fim de ato garante "uma relíquia de elixir" e escolhia qualquer uma com
   `elixir_max`/`elixir_regen`, inclusive as que **tiram** elixir (Grimório Pesado já fazia isso). Agora só conta valor positivo.
5. **Contadores não vão para o save** (Talha e Anel recomeçam ao carregar uma run), igual à Coroa de Ossos hoje.
6. **"Ouro" do Livro do Avarento** é o ouro do dano no herói (a mesma chave do Dízimo do Covil); o texto diz isso.
7. **Nada testado**: não rodei os testes nem o fuzz, como você pediu. Só rodei o `--import` do Godot para os SVGs (sem erros).

## Riscos para o teste

- Mão do Enforcado + Bolso Extra podem bater o teto da mão (7): o `hand` é limitado por `HAND_MAX`, então o extra se perde.
- Lasca de Gelo reduz o elixir máximo: com o piso de 3 no `elixir_max`, empilhar várias não quebra, mas pode ficar ruim.
- Chave da Fenda só faz algo na arena; fora dela é uma escolha "morta".
