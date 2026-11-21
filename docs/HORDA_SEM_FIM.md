# Horda sem fim (19–20/11/2026)

Modo infinito decidido com você no grilling de 19/11: "vai vindo tropa atrás de tropa até você morrer". Nada foi commitado.

## Como funciona

- É a **run normal de 3 atos**: estrada, locais com disputa, loja, relíquia no fim do ato e recompensa a cada herói que cai, tudo como hoje.
- **A fila de parties não acaba.** Cada party tem de 1 a 4 heróis, sorteados entre as 8 classes.
- **Força:** a primeira party tem a força da última fase da campanha (a Capital: `hp_mult` e `damage_mult` lidos dela ao carregar). Cada party seguinte fica ×1,21 mais forte (`rules.party.step`, o mesmo passo da campanha).
- **Arena:** depois do Ato III, as parties continuam chegando pelo portão da arena, uma atrás da outra. O dano no covil fica. A run acaba quando o covil cai.
- **Prorrogação da arena:** conta por party. Cada party que chega começa sem prorrogação, e o aviso aparece de novo.
- **Sem tempo-limite:** o limite de 50 min da run (`max_run_seconds`) não vale neste modo.
- **Acesso:** aberto desde o começo, só com os vilões já liberados. Botão "Horda sem fim" no menu, logo depois de "Nova run". Na pele Mapa aberto, o botão é um lugar novo acima do covil. O botão leva direto à escolha do vilão, e Voltar/Esc volta ao título.
- **Recorde:** parties derrubadas inteiras, por vilão (`MetaSave.endless_best`).
  - Aparece na tela de fim: título "N PARTIES" e "Novo recorde deste vilão!" ou "Recorde deste vilão: N parties".
  - Aparece também no botão do menu, com o melhor recorde entre os vilões e o nome do vilão. Na pele Mapa aberto, ele fica na legenda embaixo do lugar.
- **HUD:** "Party k · N caídos", sem o total da fila.

## Onde está

| O quê | Onde |
|---|---|
| Configuração (id 100, de 1 a 4 heróis, 3 parties geradas à frente) | `data/campaign.json`, chave `endless`, fora de `phases` (o mapa da campanha e os testes percorrem a lista) |
| `data.phase(100)` devolve a configuração | `sim/game_data.gd` |
| Fila infinita, sorteio só da semente e do número da party, sem tempo-limite, prorrogação por party, `parties_beaten` | `sim/sim.gd` (`endless_party`, `_endless_extend`) |
| Bônus "fila cheia na arena" desligado no modo | `sim/hero.gd` |
| Recorde | `sim/meta_save.gd` (`record_endless`) e `game/main.gd` (no fim da run) |
| Botão e Voltar | `game/menu.gd`, `game/map_menu.gd` |
| Placar | `game/hud.gd` |
| Textos `UI_ENDLESS*`, `PHASE_ENDLESS` | `locale/strings.csv` |

## Decisões que tomei sem perguntar

1. As runs da Horda **contam para os desafios de desbloqueio** entre runs (monstros jogados, heróis derrubados etc.), como qualquer run. Como o modo nunca é vencido, ele não libera fases nem vilões.
2. As classes vistas na Horda também contam como "vistas" no mapa da campanha.
3. O recorde no botão é o melhor entre os vilões, com o nome do vilão. O recorde de cada vilão aparece na tela de fim.
4. O lugar no menu Mapa aberto usa o desenho da casa (`m-house`), acima do covil.
5. A dificuldade **não foi medida com bots**.

## Testes

- `t_endless` em `tests/tests.gd`: 20 verificações. Todas passam.
  - Configuração fora da lista de fases e força igual à da Capital.
  - 12 parties derrubadas sem a run acabar, com a fila sempre 3 parties à frente.
  - Partes de 1 a 4 heróis de classes válidas, e força crescendo.
  - Mesma semente dá a mesma fila; sem tempo-limite.
  - Salvar e carregar mantêm a fila.
  - Na arena: a party seguinte entra pelo portão, o dano do covil fica e a prorrogação recomeça.
  - Derrota com o número de parties certo; o recorde é por vilão e é salvo.
- `--menutest`: OK, com 3 passos novos (o botão abre a escolha do vilão, Esc volta ao título, e escolher o vilão começa a run infinita).
- Capturas do menu e da escolha do vilão nas 3 peles: `docs/horda_sem_fim/`. Para regerar:
  `--endlessshot=1 --hud=N --out=docs/horda_sem_fim/` (o recorde de 23 é de mentira e não é gravado).
