# Rodada 11/11/2026 — rascunho (relíquias, elixir e herói ajudante)

**Estado:** rascunho para você revisar. Nenhum código nem JSON foi mexido. Tudo está na aba `Rodada 11-11 (rascunho)` da planilha (50 linhas de dados, todas com Status "assumido — revisar"). Backup: `Revisao do conteudo - Last Boss (backup 20261111).xlsx`.

## A. Fim da escada de elixir

A escada automática (máx 10 / 13 / 18 e 2,8 / 2,1 / 1,5 s por ponto) sai. A base fica em 10 de máximo e 2,8 s por ponto na run toda; o crescimento vem de relíquias. O custo máximo de oferta por ato (7 / 9 / 12) continua.

Unidade: 1 ponto de elixir = +1 de máximo = regen ~0,25 s mais rápida. Meta: ~8 pontos (máx 18) no ato 3.

| Passo | Valor |
|---|---|
| Relíquias por ato (ver C) | 1,00 + 0,45 + 0,35 + 0,10 + 0,65 = **2,55** |
| Acumulado ao começar A2 / A3 / arena | 2,55 / 5,1 / 7,65 |
| Fração dos picks que vira relíquia de elixir | 0,35 (8 de ~31 no pool; oferta de 3; jogador pega ~70%) |
| Pontos médios por relíquia de elixir | 3,1 |
| Pontos por pick | 0,35 × 3,1 ≈ 1,09 |
| Elixir: começo A2 / começo A3 / meio A3 / arena | 2,8 / 5,5 / 6,9 / 8,3 pontos (máx ≈ 12,8 / 15,5 / 16,9 / 18,3) |

A conta fecha perto da meta sem ajuste. **Atenção:** a escada antiga dava 18 de máximo **e** 1,5 s no ato 3 (poder 3,4×, contra 1,8× da meta). Ver pergunta 1.

## B. Relíquias

As 15 atuais ficam como estão. Novas (16): preço comum 100 / incomum 160 / rara 250 / lendária 380. Chaves fx "(novo)" não existem no sim.

| id | Nome | Rar. | Dono | Efeito | fx |
|---|---|---|---|---|---|
| elixir_flask | Frasco de Elixir | comum | comum | +2 de elixir máximo | elixir_max:2 |
| quick_spring | Nascente Veloz | comum | comum | regen 0,5 s mais rápido | elixir_spp:-0.5 (novo) |
| deep_cauldron | Caldeirão Fundo | incomum | comum | +3 de elixir máximo | elixir_max:3 |
| rushing_tide | Maré Veloz | incomum | comum | regen 0,7 s mais rápido | elixir_spp:-0.7 (novo) |
| victory_mark | Marca da Vitória | rara | comum | vencer disputa: +1 máx até o fim da run (até +4) | contest_max_gain:1, contest_max_cap:4 (novo) |
| heart_of_well | Coração do Poço | rara | comum | +4 de elixir máximo | elixir_max:4 |
| eternal_fountain | Fonte Eterna | lendária | comum | +3 máx e regen 0,5 s mais rápido | elixir_max:3, elixir_spp:-0.5 |
| living_vault | Cofre Vivo | incomum | dragão | cada 100 de ouro gastos na loja: +1 máx (até +4) | shop_max_gain:100, shop_max_cap:4 (novo) |
| hand_pocket | Bolso Extra | rara | comum | mão +1, sem perder elixir | hand:1 |
| quick_draw | Saque Rápido | incomum | comum | reposição da mão 30% mais rápida | refill_speed:0.3 (novo) |
| blood_altar | Altar de Sangue | rara | comum | sacrifício devolve 25% do custo (era 10%) | sacrifice_elixir_frac:0.15 (novo) |
| opening_gambit | Abertura | incomum | comum | 1ª carta contra cada herói que chega custa 0 | hero_first_free:1 (novo) |
| act_hoard | Tesouro de Ato | incomum | dragão | começa cada ato com +80 de ouro | act_gold:80 (novo) |
| twin_litter | Ninhada Dobrada | rara | praga | cartas de bando invocam +1 unidade | pack_extra:1 (novo) |
| phylactery | Filactério | lendária | lich | 1ª vez por herói que um monstro morre, volta com vida cheia | revive_once:1 (novo) |
| greedy_seal | Selo da Ganância | rara | comum | ofertas de relíquia com 4 opções | relic_options:1 (novo) |

## C. Onde aparecem (esperado por ato)

| Fonte | Regra | Por ato |
|---|---|---|
| Fim de ato | antes, 1 de 3 cartas grátis (mais chance de rara/melhoria); depois, 1 de 3 relíquias | 1,00 |
| Disputa difícil | vencer a **etapa 3** de uma disputa marcada com caveira (1 por rota); ganha a recompensa normal mais 1 de 3 relíquias | 0,45 |
| Loja | 1 relíquia à venda por loja, preço por raridade | 0,35 |
| Evento ? | já existem, sem mudança | 0,10 |
| Herói ajudante | matar = 1 de 3 relíquias | 0,65 |
| **Total** | | **2,55** (≈ 7,65 por run; hoje 3) |

## D. Herói ajudante

Local novo, 1 por ato, num ramo de uma bifurcação (fileiras 3 a 5). Ele fica parado no local; você tem 60 s para matá-lo. Matou: 1 de 3 relíquias. Falhou: ele dá um bônus ao herói da vez conforme a classe e sai; nunca segue o grupo. O herói principal **segue andando** (assumido) e o ajudante só é atacável com o grupo a até 40 m. Ícone: silhueta de herói de costas com exclamação dourada.

Vida (proposta, o bot ajusta): A1 ≈ 1200, A2 ≈ 2200, A3 ≈ 3600.

| Classe (real) | Bônus se você falhar |
|---|---|
| Escudeiro | escudo de 30% da vida máx do herói da vez, vale o ato |
| Arqueira | +20% de dano até o fim do ato |
| Clériga | cura 35% da vida máx na hora, e regen +0,006/s no ato |
| Mago | +25% de dano e golpe em área (2,6 m, 50%) no ato |

## E. Perguntas em aberto

1. A meta do ato 3 é ~18 de máximo (poder 1,8) ou o poder da escada antiga (18 e 1,5 s, poder 3,4)?
2. Cerca de 7,65 relíquias por run é demais? Elas passam a valer mais que cartas?
3. O herói principal espera os 60 s do ajudante, ou segue andando (como assumi)?
4. Relíquias de elixir empilham sem limite (hoje só o teto de 20 em `rules.json`)?
5. Preço de loja 100 / 160 / 250 / 380 está bom para ~460 de ouro por run?
