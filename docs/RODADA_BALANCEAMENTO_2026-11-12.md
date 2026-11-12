# Rodada de balanceamento — 12/11/2026 (autônoma)

Pedido: rodada completa, 100% paralelizável, valores livres. Bot humano, 12 baralhos (3 vilões × 4 fases), 32 a 48 runs por célula, todos os núcleos (`tools/run_batch.py`, `tools/tune_human.py`, novo `tools/exp_variants.py`, que testa variantes em cópias de `data/`).

## Base (antes) e confirmação (bateria de 48 runs, antes do último ajuste de carta)

| Vilão | Fase 1 (meta 60) | Fase 2 (56) | Fase 3 (52) | Fase 4 (48) |
|---|---|---|---|---|
| Praga base → depois | 84 → 79 | 94 → 79 | 91 → 81 | 59 → 40 |
| Dragão base → depois | 59 → 73 | 59 → 52 | 62 → 50 | 38 → 52 |
| Lich base → depois | 69 → 62 | 69 → 65 | 81 → 67 | 53 → 48 |

Aleatório: 0 a 12% (quase tudo abaixo de 10%; Lich fase 1 em 12%).

## Valores mudados

- **Praga** (`data/villains.json`): vida dos heróis 0,812 → **2,4**, infestação 0,2 → **0,1**.
- **Praga, Horda de Ratos** (`data/cards.json`): custo 2 → **3** (testada sozinha: fases 1–3 em 69/56/72%).
- **Fases 2 a 4** (`data/campaign.json`, `villain_hp`): fase 2 Praga 1,285 / Dragão 1,1 / Lich 1,6; fase 3 todos 1,6; fase 4 Praga 0,17 / Dragão 1,2 / Lich 1,3. Fase 0 (tutorial) `hp_mult` 0,4 → 0,135 para compensar a vida 2,4 da Praga.
- **Teste** do Ritual ato 2 usa agora o Kobold (custo 2); a Horda custa 3.

## Não atingiu a meta

1. **Praga segue forte** nas fases 1 a 3 (~70–80% depois do ajuste de carta; ~56–72% nas variantes). A vida dos heróis é alavanca fraca contra enxame: dobrar não mexeu a vitória. 72% das vitórias dela são antecipadas (7 heróis mortos na estrada). Causa estrutural: Horda de Ratos e Ratos Raivosos somam ~37% do dano. Variante C (Horda custo 3, 6 ratos, Raivosos dano 4 e custo 4) deu 41/56/69%, forte demais na fase 1; não aplicada.
2. **Fase 3** (grupo com clérigos): vida dos heróis não derruba a vitória do Lich/Dragão; botões saturam. Limitei em 1,6 (obs. 76 e 77 do task-observer).
3. **Praga na fase 4** com botão 0,17 só compensa a vida 2,4; é remendo. Solução limpa: botão por vilão separado do da fase 1.
4. Ruído de ±7 pontos com 32–48 runs: as células não distinguem diferenças menores que isso.

## Para decidir

Se a Praga deve perder a passiva de infestação por inteiro (sem ela + vida 1,4 deu 65%) ou ter ratos mais caros; e se a fase 3 deve ter menos cura.
