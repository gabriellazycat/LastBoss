# Rodada dos vilões — relatório final (11/11/2026)

Branch **`viloes`** (main intacta, sem push; o merge na main é decisão sua). Plano: `docs/PLANO_VILOES.md`. Estado passo a passo: `docs/CONTINUAR.md`.

## O que entrou

| Bloco | Resumo |
|---|---|
| Vilões | Rainha da Praga, Dragão Avarento e Lich (`data/villains.json`), cada um com passiva (Infestação, Tesouro do Dragão, Colheita), 24 cartas próprias, baralho inicial e 3 raras liberadas. Saves antigos de Pacto migram (Horda → Praga; Ruína/Tesouro → Dragão; Cripta/Culto → Lich) |
| Cartas | 84 no total (41 antigas + 43 novas), por dono em `data/cards.json` + `data/cards_<dono>.json`, efeitos em `sim/cards/<dono>.gd` e por dados (`docs/CARD_FX.md`). Saíram as 6 Finalizações e as Muralhas do Covil |
| Baralho | Compra → mão → descarte → embaralha; **Retorna** (uma vez por embaralhada); cartas de Rota fora na arena; mão 5, teto 7 |
| Elixir | Escada por ato (máx. 10 / 13 / 18; 1 de elixir a cada 2,8 / 2,1 / 1,5 s), teto 20 com Temporários e relíquias; ofertas limitadas a custo 7 / 9 / 12 por ato; sacrifício = 10% do máximo |
| Covil | As antigas cartas de Covil viraram **Temporárias** (efeito com duração, sem limite de cópias, valem também na arena) |
| Ritmo | Estrada de 300 m por ato; cada local é uma disputa em 3 etapas (a 3ª muda nos atos 2 e 3); recompensa por degraus (0 = nada, 1–2 = 15/30 de ouro, 3 = recompensa cheia) |
| Interface | Escolha de vilão, fases com recompensas, rara à escolha, coleção por dono; montes de compra/descarte clicáveis; barra de elixir até 20; painel das 3 etapas; upgrade antes → depois; tutorial reescrito |
| Visual | Upgrade "carimbo + material" (N2 ferro, N3 ouro, modificadores com material próprio) como padrão; 91 artes no método aguada (`docs/visual/arte_v2/`); 9 modelos próprios animados + 15 variantes (`docs/visual/d_modelos/vitrine.png`); 3 chefes finais na arena (`docs/decisoes_2026-11-10/chefes/final/chefes_jogo.png`) |

## Números finais (bot humano, 40 runs por vilão × fase)

| | Fase 1 | Fase 2 | Fase 3 | Fase 4 | Meta |
|---|---|---|---|---|---|
| Vitória Praga | 68% | 60% | 57% | 62% | 50–65% |
| Vitória Dragão | 85% | 52% | 65% | 52% | 50–65% |
| Vitória Lich | 72% | 70% | 62% | 55% | 50–65% |
| Aleatório (pior caso) | Lich 25%, Praga 22% | 2% | 18% | 8% | ≤ 10% |

- Gasto de elixir por minuto no ato 3 ÷ ato 1: **1,9 a 2,5** (meta ≥ 2; só a Praga fica em 1,9–2,0).
- Duração da run (humano): **1140 a 1630 s** (meta 1380–1620).
- Tempo em disputa: **38 a 63%** do tempo de estrada (meta 60%).
- Chegada à arena: Praga e Lich 1300–1420 s; Dragão 1480–1680 s (meta 1200–1380).
- Carga: com o teto novo de **400 unidades**, 149/123 quadros por segundo (média/mínimo). Sem teto, 1000 unidades davam mínimo de 27.
- Testes: `tests.tscn` 0 falhas; fuzz 200 sementes × 3 vilões (com baralho mínimo) 0 falhas; `--uitest`, `--menutest`, `--tiptest` passam; `--humantest` passa com o Dragão (Praga e Lich ainda têm achados de clique, ver riscos).

## O que não atingiu a meta

1. **Fase 1 fácil demais**, principalmente com o Dragão (85%). O ajuste parou nas 3 iterações do plano.
2. **Aleatório acima de 10%** com Lich e Praga na fase 1 (22–25%) e Praga na fase 3 (18%): as cartas dessas duas pagam mesmo jogadas sem critério.
3. **Tempo em disputa** abaixo de 60% em boa parte das combinações (o máximo veio nas fases 4). Mais janela não ajudou: as disputas perdidas já duram a janela inteira; o que pesa é a caminhada.
4. **Chegada do Dragão à arena** tarde (a vida maior dos heróis alonga as disputas).
5. **Cartas fora da curva**: nenhuma passou de 70% de presença nas vitórias. A lista de "escolhida em menos de 5%" é quase só de cartas baratas e comuns — reflete o bot, que valoriza carta por custo + raridade, não a força da carta. Não mexi em carta por esse sinal.
6. **Mão travada < 5%**: a métrica medida dá sempre 0% (sempre há uma carta esperando elixir); precisa de outra definição.

## Decisões que assumi no seu lugar

- **Material do fundo da carta**: o nível manda no material (N2 ferro, N3 ouro); o modificador fica com o carimbo e só troca o material no N1. Mantive um filete de borda no N2/N3 e um carimbo mais opaco, para ler em carta pequena.
- **Taverna**: meta cumulativa (1, 2 e 3 casas das mesmas 3). "Um herói defende cada casa" virou casas com +60% de vida; "dois heróis bebem" virou gole que pede 1,5× o dano.
- **Cartas aproximadas** (sem mexer no núcleo): Guarda do Tesouro não provoca; sopro do Dragão Ancião acerta um alvo só; "atordoar" = raiz ou petrificação; Ninho-Mãe é feitiço; Nuvem de Morcegos só atravessa escudo no N3; Colosso de Ossos absorve mortos pelo gancho de morte.
- **Altar Profano "sangue"**: +2 de elixir máximo até o fim do ato e as próximas 3 cartas custam 1 a mais. **Pedra do Atalho**: a 1ª carta de cada disputa custa 2 a menos. **Sem Testemunhas** paga uma rara.
- **Calibração**: elixir mais rápido nos atos 2 e 3 (2,1 s e 1,5 s, máximo 18 no ato 3, era 16); metas das etapas ~60% maiores que a proposta e janelas de 25 s (Fonte 6 s); vida dos heróis ×1,4 no Dragão e ×1,25 no Lich, ×1,15 na fase 1; teto de 400 unidades.
- **Dragão Ancião** em escala 0,71 (≈ 3 m) para caber no mapa.

## Riscos e pendências

- O bot humano no `--humantest` ainda acha cliques sem efeito com Praga e Lich: um Control sem nome perto do herói pega o clique; o Cálice Profundo às vezes não é selecionado. Não foi achada a causa.
- Modelos da Praga, do Dragão e do Troll têm 4 a 6 mil triângulos (pedido ~3000).
- Artes que os próprios agentes acharam fracas: Acólitos (parecem peões), Praga Bubônica (lembra panda), Maldição da Fraqueza (abstrata), Forja Sombria (fogo roxo some), Maré de Ratos (ratos pequenos), Dragão Ancião (uma asa só na carta).
- O ouro do chefe Dragão fica chapado sob a luz da arena; a base dele afunda 0,5 m no chão.
- Bots: Ninho-Mãe e Avalanche dependem de dados `ai` novos; Túmulo Aberto e Tempestade de Almas passaram a esperar mortes recentes.
- O tempo das sessões foi limitado pelo teto de 5 horas do plano: 6 agentes em paralelo esgotam a janela em cerca de 1 hora.

## Para você testar

1. Abrir o jogo na branch `viloes` (o save antigo migra; uma run em andamento da versão antiga é descartada).
2. Escolher a Praga (livre); Dragão e Lich liberam nas fases 1 e 2 (ou rode com `--liberar` para liberar tudo).
3. Planilha: aba nova **"Vilões - cartas (JSON)"** com as 84 cartas como estão no jogo (`python -I tools/export_cards_json_xlsx.py`).
