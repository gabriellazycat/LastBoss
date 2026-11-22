> **DESATUALIZADO (substituído pela metaprogressão de 21/11/2026, ver docs/METAPROGRESSAO.md)**: este documento descreve o que saiu (campanha de 7 fases, Horda sem fim, Almas antigas e/ou decks fixos); vale só como histórico.

# Campanha em mapa: o reino ao redor do covil (16/11/2026)

Decidido com você no grilling de 16/11. O plano aprovado está em `C:\Users\gabri\.claude\plans\falta-criar-uma-campanha-warm-hummingbird.md`.
Nada foi commitado.

## Estado (para retomar)

| Passo | Estado |
|---|---|
| Planta do reino (coordenadas) e 7 fases em `data/campaign.json` | feito |
| Textos (`REGION_*`, `PHASE_4..6`, `PHASED_0..6` reescritos, `UI_CAMPAIGN_*`) | feito |
| Save: `MetaSave.heroes_seen`, `MetaSave.VERSION` 4, `SaveGame.VERSION` 7 | feito |
| Tela `game/campaign_map.gd` + fluxo do menu (Nova run → mapa → vilão → run); tela "grupo" removida | feito |
| "Saída: <região>" no começo do Ato I do minimapa | feito |
| Testes: `tests/tests.tscn` (3 falhas, de antes; ver abaixo), `--menutest` OK, `--uitest` OK, capturas nas 3 peles | feito |
| Fundo do reino **só em traço**, como o mapa da run (`game/campaign_art.gd`) | feito (16/11) |

**Fundo:** a arte pela IA foi recusada ("quero que pareça um mapa desenhado igual ao da run, só o lineart, nada de cor").
- `game/campaign_art.gd` desenha o reino a tinta no papel, com os desenhos do `Minimap` em gravura (árvores, montes, casas, campos, moinho, torres, rio, pontes e lagos), nas posições de `data/campaign.json`.
- Cada região tem os seus lugares: fazenda (campos, moinho), vila (casas, igreja), floresta, mosteiro no morro, forte com muralha, torre no morro e capital murada. O covil é uma caverna com árvores mortas.
- Redesenho (16/11, pedido "desenha melhor"; referência: fantasticmaps.com): casas em volume com empena, lado hachurado, telhado de telha ou palha, chaminé com fumaça; castelos com muralha de pedra e ameias, torres redondas de telhado cônico e bandeira, portão com grade; abadia e igreja com flecha; capital com muralha oval, catedral e castelo; Torre dos Arcanos torta com sacadas; covil como montanha de chifres com bocarra de presas, caveira, ossos e morcegos (o ícone do covil saiu; as estradas terminam na boca).
- O desenho é feito uma vez numa SubViewport, no dobro do tamanho do papel.
- Por cima: regiões vencidas numa aguada sépia com a estrada em tinta vermelha, névoa de papel nas trancadas e a estrada da fase em vermelho tracejado.
- **Estilo escolhido: Nórdico (nº 4, 16/11).** `CampaignArt.VARIANT = 3`. O mesmo desenho vale para o jogo todo:
  - **Mapa da campanha:** casas longas, igrejas de telhados empilhados, paliçada de toras e salão no forte e na capital.
  - **Mapa da run (gravura):** as aldeias, igrejas e torres do terreno e os ícones de Taverna, Santuário, Loja, Portão do ato, Covil e acampamento usam `CampaignArt.drawer` (`Minimap._house`, `_tower`, `_icon`).
  - **Menu, loja e fim da run:** os ícones dos lugares (covil, coleção, compêndio, configurações, sair, continuar, casa) são PNG gerados por `--mapicons=1` em `assets/ui/map/` (`icon_*.png`, `node_*.png`, `node_*_hot.png`); o jogo prefere o PNG ao SVG antigo (`CampaignArt.map_tex`). As duas casinhas do fundo do menu (`bg_menuA.png`) foram trocadas pela casa nórdica.
  - Ficaram em SVG os desenhos que não são construções (rato, bosque, monte, serpente, ícones dos serviços).
  - Capturas: `docs/campanha_mapa/nordico/`.
- **10 estilos de construção (16/11, aguardando a escolha):** o terreno é um só (Vale do Rio, traço sépia do mapa da run); o que muda é o desenho das casas, igrejas, castelos, torres e do covil (`CampaignArt.STYLES`): Conto de fadas, Gravura medieval, Chalé de palha, Nórdico, Gótico, Mapa de viajante, Enxaimel torto, Xilogravura, Pedra rústica e Élfico. Tudo à mão: linha trêmula, perfis curvos, sombra em hachura recortada na forma. Lápis e pincel foram descartados (ele quer o traço do resto do jogo). Pranchas: `docs/campanha_mapa/estilos/prancha_a.png` e `prancha_b.png`. Ver um no jogo: `--mapvar=N` (0 a 9); regerar: `--mapvars=1 --out=pasta/`. O escolhido vira `CampaignArt.VARIANT`.
- Capturas: `docs/campanha_mapa/traco_*.png` (`traco_fundo.png` é o mapa inteiro).

## Como ficou

- **Tela:**
  - Em cima, ◀ e ▶, o nome "Fase N · Região", o nome da fase e as bolinhas de progresso.
  - No meio, o mapa. As setas do teclado e o clique numa região também trocam a fase.
  - Embaixo, a descrição, "Você vai enfrentar" (cada party com um retrato por herói, ou "?" se você ainda não enfrentou aquela classe), o prêmio, **Defender o covil** e **Voltar**.
- **Câmera:** ao trocar de fase, ela sai da região atual, passa pelo covil e segue a estrada da nova região (1,5 s, abrindo o zoom no meio do caminho).
- **Regiões:**
  - vencidas: mancha escura e selo vermelho com ✓;
  - trancadas: névoa, com nome e descrição à vista, os heróis escondidos ("Os heróis desta região ainda são um mistério") e o botão desligado.
- **Heróis vistos:** a classe é revelada quando a party dela entra em campo numa run. A gravação é imediata, então sair no meio da run não perde o que foi visto. Saves antigos já começam com as classes das fases que você venceu.
- **Fluxo:**
  - O tutorial começa direto, com o vilão fixo.
  - As outras fases passam pela escolha do vilão, e escolher o vilão já começa a run.
  - Esc ou Voltar no vilão volta ao mapa.
- **Peles:** Mapa aberto e Diário em papel e tinta; Covil no painel escuro, com o mapa em pergaminho.
- **Teste:** `--hud=N` troca a pele só naquela execução, sem gravar. `--campaignshot=1` tira as 4 capturas do mapa.

Capturas: `docs/campanha_mapa/` (Mapa aberto, a câmera no meio da viagem, Diário e Covil).

## As 7 fases (proposta minha: revise)

| # | Região | Parties | hp_mult / dano | Prêmio |
|---|---|---|---|---|
| 0 | Fazenda do Vale (tutorial) | igual a antes | 0,135 / 0,55 | — |
| 1 | Vila de Pedravau | igual a antes | 1,4 | Dragão |
| 2 | Floresta de Ramagris | igual a antes | 2,67 | Lich |
| 3 | Mosteiro da Colina | igual a antes | 2,3 / 1,3 | libera a próxima região |
| 4 | Forte da Fronteira (nova) | Guardião · Bárbaro+Escudeiro · Guardião+Escudeiro · Bárbaro · Escudeiro+Guardião+Bárbaro | 2,5 / 1,3 | libera a próxima região |
| 5 | Torre dos Arcanos (nova) | Mago · Besteiro+Arqueira · Clériga+Mago · Besteiro · Mago+Arqueira+Clériga | 2,6 / 1,35 | libera a próxima região |
| 6 | Capital de Aurévia (final) | Escudeiro+Arqueira · Guardião+Clériga+Mago+Assassino · Bárbaro+Besteiro+Escudeiro · Assassino · Guardião+Clériga+Mago+Arqueira | 2,8 / 1,4 | "o reino é seu" |

**Por que esses números:**
- Com `share_exp` = 1, a força total de uma party não depende de quantos heróis ela tem. Só o número de parties (passo ×1,21 cada) e o multiplicador da fase mudam a força.
- As fases 4 a 6 têm 5 parties, como a fase 2. Por isso o multiplicador delas sobe pouco acima do da fase 3 (2,3), numa curva crescente até a Capital.
- Não foram medidos com bots (você pediu só números).

## Decisões que assumi (revise)

1. Nomes das regiões e das fases novas, descrições e a planta (onde fica cada região).
2. A Companhia de antes virou a Capital, ampliada para 5 parties. A fase 4 de antes não existe mais.
3. Save antigo com a fase 4 vencida conta como Forte vencido.
4. Runs salvas antes desta mudança não continuam (`SaveGame.VERSION` 7).
5. A "rara à escolha" saiu da fase 3 (já não era paga desde 13/11).
6. Vida e golpe do herói revelado ficam na caixa do mouse, não no cartão, para caber a party de 4.
7. Clicar num vilão da lista (pele Diário/Mapa) começa a run direto. Antes, isso abria a tela do grupo.

## Testes

- `tests/tests.tscn`: 0 falhas desde a consolidação de 16/11 (`docs/CONSOLIDACAO_2026-11-16.md`). As 2 falhas do Ritual Profano não vinham do rio: o monstro sacrificado também arma o Ciclo de feitiço do Lich, e os dois descontos somam (o teste agora separa os dois).
- As Almas saíram do jogo em 16/11: o prêmio das fases 3 a 6 é a próxima região; a Capital dá "o reino é seu".
- Os testes da fila de parties usavam a fase 4 antiga e agora rodam numa fase de teste (93) com a mesma fila.
- Testes novos: 7 fases seguidas com mapa, heróis vistos (salvar, carregar e migrar) e a fase 5 fechada até vencer a 4.
- `--menutest`: OK. Cobre o fluxo do mapa, as setas, a fase trancada e "Defender → vilão → run na fase certa".
- `--uitest`: OK na fase 1.
