# Continuar: balanceamento da rodada de 13/11/2026

Parado no meio do balanceamento, a pedido do jogador. Nada foi commitado (branch `arte-unificada`, com as alterações de arte pendentes dele no mesmo working tree). Contexto completo em `docs/RODADA_2026-11-13.md`. `tests.tscn`: 0 falhas.

## Regras do jogador (não quebrar)

1. **Heróis iguais para todos os vilões.** A vida dos heróis não depende do vilão; o equilíbrio vem das cartas (e do elixir). `rules.hero_hp_mult` é global.
2. **Fase ≠ ato.** "Fase" é o conjunto de heróis escolhido antes de jogar (campanha, Fase 1 a 4): ela pode ficar mais difícil (`hp_mult` e `damage_mult` por fase em `data/campaign.json`). "Ato" é o trecho dentro da run: a vida dos heróis **não** muda por ato.
3. **Ratos e morcegos são Bando, nunca Fera.**
4. Meta de elixir: média de **18–20 de máximo** e **2–2,5× de regen** no fim da run.
5. Não commitar nem dar push sem ele pedir.

## Estado atual (working tree, tudo medido só em parte)

| O quê | Valor |
|---|---|
| Vida global dos heróis | `rules.hero_hp_mult` = 2,0 |
| Vida por fase (`hp_mult`) | tutorial 0,135 / F1 1,4 / F2 2,67 / F3 2,6 / F4 1,5 |
| Dano dos heróis por fase | só a F3: `damage_mult` 1,4 (tutorial 0,55) |
| Piso de elixir por ato | máx 10/10/10, regen ×1 / ×1,05 / ×1,1 (`rules.acts[].elixir`); o máximo vem das relíquias |
| Custo máx. das ofertas (ato 3) | 16 |
| Relíquias de elixir novas | Cisterna +3, Torneira +20% regen, Alambique +2/+35%, Coração de Éter +4/+50%; peso 1,5 (Biblioteca Viva 2,0); oferta de fim de ato sempre traz uma de elixir |
| Dragão | início com 45 de ouro; Golem de Magma custo 8, vida 1400, dano 30, lava 25 |
| Lich | Explosão de Cadáver `hp_mult` 2,8 e `min_damage` 110; Tempestade de Almas 50; Raio Sombrio 125; Acólito dano 5 |
| Praga | Peste: `peste_taken` 0,035; Horda de Ratos 33 vida/4,4 dano; Ratos Raivosos 39/5,5; rato auxiliar 33/4,4; Maré de Ratos 29/4,4 |

## Última medição completa (bot humano, 40 runs por célula, "F")

Meta por fase: 60 / 56 / 52 / 48. Vitória do vilão:

| | F1 | F2 | F3 | F4 |
|---|---|---|---|---|
| Praga | 60 | 48 | 80 | 28 |
| Dragão | 55 | 42 | 78 | 52 |
| Lich | 65 | 72 | 75 | 65 |

Elixir no fim da run (arena): máximo ~19–22 (média 20,4), regen 2,1–2,7× (média 2,4): dentro da meta.

**Depois dessa medição** mudaram: dano da F3 ×1,4 (era 1,0), Explosão de Cadáver (o ajuste do Lich não tinha entrado por ter sido feito no arquivo errado), Ratos Raivosos (idem), Raio Sombrio, Acólito, Horda/rato/Maré mais fortes. **O estado atual nunca foi medido por inteiro**: a medição "J" (seeds 801, 40 runs, `reports/bal_j`) foi interrompida.

## O que se aprendeu

- **Fase 3: a vida dos heróis quase não mexe nas vitórias** (vida 1,5 → 75%, vida 3,6 → 72%). O **dano** mexe: ×1,7 derrubou a média dos vilões de ~75% para 36%. Por isso a F3 usa `damage_mult` (~1,4 deve dar ~50%).
- **Fase 4:** a arena é quase imbatível para todos (~6–10% de vitória na arena); quem vence é quem mata o grupo na estrada. O Lich (feitiços em área) vai bem; a Praga (enxame) vai mal contra o grupo com mago.
- Com 12 células × 16 runs o ruído é ±12 pontos; use **40 runs por célula** (ou mais) para decidir.
- Sem `ai`, o bot quase não joga as cartas novas; as caras (13–16) quase nunca aparecem nas ofertas (lendária ~8% no ato 3).
- Antes de mexer num botão global, olhe a tabela por carta (plays por run e % de dano). Foi assim que o Golem de Magma (24% do dano do Dragão) apareceu.
- Ajuste de dados por script: confira que o id foi encontrado (assert), senão a mudança some em silêncio (aconteceu com Explosão de Cadáver e Ratos Raivosos).

## Próximos passos

1. Medir de novo: `python -I tools/run_batch.py --bots human --decks plague@1,plague@2,plague@3,plague@4,dragon@1,dragon@2,dragon@3,dragon@4,lich@1,lich@2,lich@3,lich@4 --runs 40 --seed0 801 --out reports/bal_k` (uns 10 minutos; o Godot está em `C:\Users\gabri\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`). Resumo por fase/vilão: um script de leitura de `runs.json` (campos `deck` tipo `plague@3`, `phase`, `result`, `elixir_max_arena`, `spp_arena`).
2. Ajustar de cima para baixo, uma camada por vez: elixir (já ok) → vida/dano por fase → cartas por vilão. Não mexer em dois níveis no mesmo ciclo.
3. Desvios a corrigir por carta (não por vida do herói): Lich alto nas F2/F4; Praga baixa na F4; Dragão baixo na F2.
4. Cartas caras: fazer o bot jogá-las (dados `ai`) e/ou subir a chance de lendária no ato 3 (`rules.acts[2].rarity`), para o elixir alto ter uso.
5. Dados `ai` para as Selvagens, o Câmbio do Dragão e o Grito de Guerra.
6. Arte das 28 cartas novas (skill `cartas-ia`); depois tirar os ids de `art_pending` em `tests/tests.gd`.
7. Abrir o jogo numa janela (`--uitest`, `--menutest`) e ver a tela do vilão, a coleção e a loja com as cartas novas.
8. `tools/tune_human.py` está desatualizado (calibra `hero_hp_mult` por vilão e `villain_hp`, que não existem mais).
9. Quando estiver bom: atualizar `docs/RODADA_2026-11-13.md` com os números finais e pedir o commit ao jogador.

## Prompt para a próxima sessão

```
Continuar a rodada de 13/11/2026 do Last Boss (Godot, C:\Users\gabri\Desktop\LastBoss, branch arte-unificada, nada commitado). Leia primeiro docs/CONTINUAR_2026-11-13.md e docs/RODADA_2026-11-13.md. Responda em português.

Regras dele: heróis iguais para todos os vilões (equilíbrio só por cartas, elixir e fase); "fase" = grupo de heróis escolhido antes de jogar (pode ficar mais difícil), "ato" = trecho da run (vida dos heróis não muda por ato); ratos e morcegos são Bando, nunca Fera; meta de elixir 18–20 de máximo e 2–2,5× de regen no fim da run; não commitar nem dar push sem ele pedir.

Tarefa: terminar o balanceamento. (1) Rode a medição completa (bot humano, 12 células fase×vilão, 40 runs por célula, seed0 801) com o estado atual, que nunca foi medido inteiro. (2) Alvo de vitória do vilão por fase: 60/56/52/48 (±8). Ajuste de cima para baixo, uma camada por ciclo, olhando a tabela por carta antes de mexer em botão global. Desvios conhecidos: Lich alto nas fases 2 e 4, Praga baixa na fase 4, Dragão baixo na fase 2. (3) Faça o bot jogar as cartas caras (13–16) e confira que o elixir termina em 18–20 e a regen em 2–2,5×. (4) Dados ai para Selvagens, Câmbio do Dragão e Grito de Guerra. (5) Rode tests.tscn (0 falhas), fuzz e atualize o relatório com os números finais. Ao editar JSON por script, confira que cada id foi achado (as cartas ficam em cards.json e em cards_<dono>.json).

Antes de começar, ele comentou que gostou "das artes até da armadura": não ficou claro a que arte isso se refere; pergunte. A arte das 28 cartas novas (skill cartas-ia) é um pedido separado.
```

## Rodada numérica (13/11/2026, sem rodar o jogo nem bots, a pedido dele)

Feita só com números: participação de cada carta no dano por fase (medição `bal_f`), limiares de golpe (quantos golpes cada herói da fila precisa para matar cada unidade, com step 1,21 e o dano de cada classe), tempo de vida das unidades grandes contra o dano médio do grupo e uma curva logística calibrada no único dado de alavanca medido (dano do herói ×1,7 na F3 levou 75% → 36%). O modelo está em `tools/modelo_numerico.py` (`python -I tools/modelo_numerico.py` imprime medição F, estado anterior e previsão).

| Mudança | Antes → depois | Por quê (número) |
|---|---|---|
| Troll das Cavernas (comum) | vida 2200 → 1800, regen 2% → 1%/s | 460–780 de dano por elixir (média dos vilões ~80; criaturas grandes 150–300); 2%/s = 44 de vida/s, quase o dano do herói no começo. Previsto ~200 dano/elixir |
| Ratos (Horda, Raivosos, Maré, rato auxiliar) | vida 33/39/29/33 → 52/58/49/52; dano 4,4/5,5/4,4/4,4 → 4,0/5,0/4,0/4,0 | Vida acima de 51 passa a aguentar o respingo do Mago (50,9) e o 1º golpe de 4 dos 6 heróis da F4 (46 / 44,5 / 47 / 51): a Praga na F4 sobe; com dano −9%, F1 e F3 quase não mudam |
| `rules.group_spell_splash` | 0,3 → 0,15 | Só existe na F4 (grupo). Lá os feitiços fazem 69% do dano do Lich e 48% do Dragão |
| Legião de Ossos | vida 75 → 65 | Morre num golpe do 3º herói na F1 (67) e do 3º/4º na F2 (67 / 65): corta o Lich na F2, onde a Legião faz 20% do dano |
| Kobolds Saqueadores | vida 35 → 48, dano 4 → 5 | Aguenta o 1º golpe do Escudeiro (46) e da Arqueira (44,5): ajuda o Dragão na F1/F2 |
| Dragão: Dragonete, Guarda do Tesouro, Mercenário, Salamandra | vida +11–14%, dano +11–15% (395/34, 1020/32, 250/16, 900/20 e rastro 9) | Essas unidades fazem 35–40% do dano do Dragão na F1/F2 e menos na F4 |
| Explosão de Cadáver | `hp_mult` 2,8 → 3,1, `min_damage` 110 → 120 | Devolve metade do corte anterior: o Lich tinha ficado baixo na F1/F3 |
| Tempestade de Almas | 50 → 55 | Idem |
| Exército Eterno | reanimações 12 → 24 (N3 18 → 36), duração 15 → 25 s | Media 29 de dano por elixir em 112 jogadas (lendária de 13). Previsto 100–160 |

Previsão do modelo (vitória do vilão, meta 60/56/52/48):

| | F1 | F2 | F3 | F4 |
|---|---|---|---|---|
| Praga | 60 | 53 | 60 | 43 |
| Dragão | 58 | 48 | 57 | 49 |
| Lich | 56 | 64 | 43 | 52 |
| média | 58 | 55 | 53 | 48 |

Riscos assumidos: (1) o dano ×1,4 da F3 nunca foi medido e domina a incerteza (com elasticidade menor, a F3 fica em ~62%; com maior, ~46%); (2) os limiares de golpe ignoram Fúria do Herói (+5% por unidade perto) e Giro de Espada, que podem quebrar o limiar de 52 dos ratos quando o herói está cercado; (3) a vida da fase quase não mexeu nas vitórias da F3, então o modelo só usa dano. Desvios que o modelo ainda deixa: Lich alto na F2 (+8) e baixo na F3 (−9); Dragão no limite na F2 (−8); Praga no limite na F3 (+8). Não mexi em elixir (já na meta), vida/dano por fase, relíquias nem dados `ai`.

### Conferência com bots (13/11/2026, `reports/bal_num`, seed0 901)

6 estilos de bot × 12 células × 10 runs (720 runs). Com 10 runs por célula o ruído é ±31 pontos: só valem as médias (30–40 runs, ±16–18).

| Bot humano | F1 | F2 | F3 | F4 | média |
|---|---|---|---|---|---|
| Praga | 60 | 60 | 60 | 50 | 58 |
| Dragão | 40 | 90 | 50 | 50 | 58 |
| Lich | 70 | 40 | 50 | 30 | 48 |
| **média (meta 60/56/52/48)** | **57** | **63** | **53** | **43** | |
| previsto | 58 | 55 | 53 | 48 | |
| antes (`bal_f`) | 60 | 54 | 78 | 48 | |

- A fase 3, que era o maior erro (78%), caiu para 53%, como previsto. As médias por fase ficaram a até 7 pontos da meta.
- Vilões (média das 4 fases): Praga 54 → 58, Dragão 57 → 58, Lich 69 → 48. O Lich caiu mais que o previsto (54); está dentro do ruído, mas é o primeiro candidato a um ajuste leve para cima.
- Troll das Cavernas: 242–362 de dano por elixir (antes 460–780). Ratos 82–98 (antes 68–80). Explosão de Cadáver segue a carta mais forte do Lich (274, 22% do dano).
- Exército Eterno mostra 24 de dano por elixir, mas o dano dos esqueletos levantados entra como `skeleton`, não na carta: a medição não serve para julgar o reforço.
- Elixir no fim (humano): máximo 20,9 e regen 2,58× (antes 20,4 e 2,55×), no limite de cima da meta; estas mudanças não mexem nele.
- Outros bots: o aleatório ganha 0–7% (meta ≤ 10%); o heurístico 40–60% por fase; ganancioso, economista e enxame ficam em 0–43%, abaixo do humano, como esperado de quem joga pior.
- Próximo passo para fechar: 40 runs por célula só com o bot humano (`--bots human --runs 40`) para confirmar Lich F2/F4 e Dragão F1/F2 antes de mexer de novo.
