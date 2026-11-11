# Last Boss — rodada dos vilões: onde parou e como continuar

Atualizado em 10/11/2026. Branch de trabalho: **`viloes`** (main intacta, sem push). Plano completo: `docs/PLANO_VILOES.md`.

## Prompt para colar numa conversa nova

```
Continue a rodada dos vilões do Last Boss de onde ela parou. Leia primeiro docs/CONTINUAR.md e depois
docs/PLANO_VILOES.md (o plano aprovado; não replaneje nem me faça perguntas, todas as decisões estão nesses
dois arquivos e em docs/decisoes_2026-11-10/). Trabalhe na branch `viloes` (commits liberados nela; não toque
na main, não faça push). Siga a seção "Próximo passo" do CONTINUAR.md e a ordem: primeiro mecânicas e
programação (Etapa C), depois visual (Etapa D), depois testes e balanceamento (Etapa E). Use Sonnet para
implementação delimitada e Haiku para tarefas mecânicas, como diz a tabela "Como cada tarefa é executada".
Confira o gasto semanal de vez em quando: ao chegar em 99%, pare no fim do passo corrente, rode os testes,
faça commit, e atualize docs/CONTINUAR.md com o que foi feito e o que falta. Ao terminar cada passo, atualize
a tabela de estado do CONTINUAR.md.
```

## Decisões dele em 10/11 (depois do pacote de decisões)

| Tema | Decisão |
|---|---|
| Arte das cartas | **v2 (aguada)** — `tools/art/card_ink/` grava `<id>_v2.png`; é esse o arquivo que vai para `assets/cards/<id>.png` |
| Upgrades | **Carimbo** (proposta 3) para os modificadores **+ material do fundo da carta ao estilo Balatro**: hoje o fundo é papel; deve poder ser pedra, ferro, ouro, vidro etc. |
| Lista de cartas, chefes, regras | Aprovados como estão em `docs/decisoes_2026-11-10/` ("de resto pode implementar tudo") |
| Prioridade | Mecânicas das cartas novas e programação **primeiro**; visual das cartas e dos inimigos **depois**; exportar para ele testar |
| Autonomia | Total, sem perguntas (ele está fora). Decisões assumidas vão anotadas aqui |

**Como eu leria "material do fundo" (assumido, ele não detalhou):** o **nível** define o material da carta inteira — N1 papel (como hoje), N2 **ferro** (chapa fria rebitada), N3 **ouro** (com brilho que passa). Os **modificadores** ficam com o carimbo diagonal da proposta 3 e, além dele, podem trocar o material quando fizer sentido temático: Sombrio = **obsidiana/vidro escuro**, Amaldiçoado = **pedra rachada**, Explosivo = **ferro em brasa**, Barato = **madeira/lata**, Veterano = **aço gravado**. Quando nível e modificador pedirem materiais diferentes, o nível manda no material e o modificador fica só com o carimbo. Implementar em `game/card_fx_variants.gd` como variante nova (4) e torná-la o padrão em `game/settings.gd` (`card_fx_variant`); o shader do papel é `game/ui/paper.gdshader`. As medalhas da proposta 3 saem (o material já mostra o nível).

## Estado

| Etapa | Item | Estado |
|---|---|---|
| A | Pacote de decisões (`docs/decisoes_2026-11-10/index.html`) | **feito e respondido** |
| B | Popup, loja, raridade única, portão nos atos 1 e 2, estrada fundida ao chão, encaixe dos heróis | **feito**, testes 0 falhas |
| C0 | Efeitos por dono em `sim/cards/*.gd` + `sim/card_fx_lib.gd` (primitivas) + bots por dados | **feito** (replays 240/240 idênticos; esquema em `docs/CARD_FX.md`; teste de hashes `headless/hashes.tscn`) |
| C1 | Remover 6 Finalizações + Muralhas e dependentes | **feito** (pool 41; Pedra do Atalho, Sem Testemunhas → rara, Altar "sangue" → +2 elixir máx. no ato e 3 cartas +1). Artes/modelos das removidas ficam até a Etapa D porque outras cartas ainda os emprestam |
| C2 | Baralho compra/descarte/embaralhar; Retorna; Rota fora na arena | **feito** (`queue` segue sendo a pilha de compra; `discard`, `benched`, `returned`, `draw_card()`; `fx.returns`; save v4; teste `t_deck_cycle`; fuzz 30 seeds ok) |
| C3 | `data/villains.json`, `owner` em tudo, filtro do pool, saves, campanha, menu de vilão | **feito no núcleo** (vilões com passivas, filtro por dono em cartas/relíquias/contratos/eventos, `MetaSave` v2 com migração, campanha libera Dragão/Lich e paga rara à escolha, save de run v5). `start_deck` interino até o C6 (o final está em `start_deck_final`). Menu de vilão: agente de interface |
| C4 | Elixir em escada (10/13/16, teto 20), Covil temporário, custo por ato, mão 5 → 7 | **feito** (`rules.acts[].elixir` com máximo, regen e custo máximo de oferta; `Sim.temps`/`add_temp`/op `temp`; Coletor, Forja e Biblioteca Temporários; sacrifício = 10% do máximo; `HAND_MAX` 7; limiares dos bots escalam com o máximo) |
| C5 | Estrada de 300 m, disputas em 3 etapas | **feito** (`rules.locations.*.stages`/`stage3` por ato; `contest` com `stage`, `stages`, `won`, `variant`; ouro 0/15/30 por degrau, as 3 = recompensa cheia; `stats.stages_won`). Assumido: Taverna com meta cumulativa (1, 2 e 3 casas das mesmas 3); "um herói defende cada casa" virou casas com +60% de vida; "dois heróis bebem" virou gole que pede 1,5× o dano |
| C6 | 43 cartas novas + custos revistos + textos pt/en | **feito** (84 cartas: `data/cards.json` + `data/cards_<dono>.json`; efeitos em `sim/cards/<dono>.gd` e ops; Peste e Feras; baralhos iniciais definitivos; testes por vilão; fuzz 30 ok). Aproximações anotadas pelos agentes: Guarda do Tesouro sem provocar, sopro do Dragão Ancião em alvo único, "atordoar" = raiz/petrificar, Ninho-Mãe é feitiço, Nuvem de Morcegos só atravessa escudo no N3; bots não sabem "mortes recentes" (Túmulo Aberto, Tempestade) nem "ouro acima de" |
| C-UI | Montes de compra/descarte, barra de elixir até 20, HUD da disputa, upgrade antes → depois | **feito** (capturas `docs/visual/c_ui/`, `docs/visual/c_menu/`); menu de vilões, fases com recompensa, rara à escolha, coleção por dono. Falta conferir o HUD da disputa com o C5 de verdade (foi validado com chaves simuladas) |
| Upg. | Variante 4: carimbo + material do fundo | **feito** (padrão em `settings.gd`; capturas `upgrades/v4_*.png`). Assumido: filete de borda no N2/N3 e carimbo mais opaco, para ler em carta pequena |
| D | Arte v2 de ~91 imagens, 9 modelos animados, 11 variantes, 3 chefes finais | **feito** (91 imagens; 9 modelos próprios no look 7; 15 variantes em `Looks.VARIANTS`; 3 chefes na arena; arte única com teste `t_unique_art`; vitrine `docs/visual/d_modelos/vitrine.png`). Para o passe visual da E: Dragão Ancião grande demais no mapa (4,2 m); modelos da Praga/Dragão/Troll com 4 a 6 mil triângulos; mapa real com as criaturas novas ainda não fotografado |
| E | Testes novos, fuzz, calibração, carga, relatório, planilha | **feito** (relatório `docs/RODADA_VILOES.md`; aba "Vilões - cartas (JSON)"; metas não atingidas listadas no relatório) |

## Próximo passo

A rodada está completa (Etapas A a E). Falta o Gabriel jogar e decidir: o relatório `docs/RODADA_VILOES.md` lista o que não atingiu a meta (fase 1 fácil, aleatório alto com Praga/Lich, tempo em disputa < 60%, chegada do Dragão à arena) e as decisões assumidas. Próximas rodadas possíveis: nova calibração depois que ele jogar; causa dos cliques sem efeito no `--humantest` (Praga e Lich); refino das artes fracas e dos modelos acima do orçamento; merge na main só quando ele pedir.

Atenção: `--import` é obrigatório depois de mexer em `locale/strings.csv` (os testes leem as traduções compiladas). Não passe a saída do Godot direto por `grep`: grave em arquivo com `timeout`. Argumentos de teste sem `=` são ignorados em silêncio.

## Como fazer (comandos)

```
G="/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import                      # depois de criar class_name novo ou num worktree novo
"$G" --headless --path . res://tests/tests.tscn        # testes; a última linha diz "falhas: N"
python -I tools/run_batch.py                           # lotes de bots (ver PROGRESSO.md, "Como rodar")
"$G" --path . res://game/upgrade_showroom.tscn         # vitrine de upgrades (teclas 0-3)
B="C:/Program Files/Blender Foundation/Blender 5.2/blender.exe"
"$B" -b --factory-startup -P tools/art/card_ink/render_cards.py -- tools/art/out/ink [ids]   # arte de carta (v1/v2/v3)
"$B" -b --factory-startup -P tools/art/blender_v2/bosses_v3.py -- --out=<pasta>              # blockout dos chefes
python -I tools/export_cards_xlsx.py                   # aba de cartas na planilha, a partir do CARTAS_VILOES.md
```

- Arte nova de carta: escrever uma função de cena em `tools/art/card_ink/scenes.py` (kit em `tools/art/blender_v2/mk.py`), registrar em `SCENES`, renderizar e copiar `<id>_v2.png` para `assets/cards/<id>.png`. `UiDiario.card_tex(id)` já prefere o arquivo com o id da carta.
- Argumentos do jogo precisam de `=` (`-- --tiptest=1`). Um erro de parse numa cena de captura deixa o Godot pendurado: use `timeout`.
- Agentes em worktree: `.godot/` não é versionado, então cada worktree precisa do `--import` antes de rodar.
- Não rodar `tools/xlsx_to_json.py` (desfaz o balanceamento).

## Riscos e pendências conhecidas

- A calibração de 10/11 deixa de valer quando C2 a C5 entrarem; será refeita na Etapa E.
- Não conferido na Etapa B: rolagem da loja com a roda do mouse, ícone do portão no mapa grande (tecla M), peles além do Diário.
- `--tiptest` falha de vez em quando num caso antigo que depende do cursor físico (já falhava antes).
- O blockout dos chefes ainda precisa das origens por parte (`PART_OFFSETS`, como em `boss.py`) antes de exportar para o jogo.
- Pasta `C:\tools` criada por engano num render (só cópias de imagens); pode ser apagada à mão.
- task-observer: falta anexar `use_evidence` às observações 0017, 0021, 0048 e 0069.
