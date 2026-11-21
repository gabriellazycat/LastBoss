# Metaprogressão forte + 1 fase de 15 parties + poderes de party

## Contexto
Hoje o jogo tem campanha de 7 fases (2–5 parties), Horda sem fim, decks fixos por vilão, níveis de carta 1–3 só na run, relíquias todas liberadas e sem nível, e a cada herói morto o grupo ganha 1 de 15 habilidades quase todas passivas. O jogador só "spamma" carta. Objetivo: **1 fase, 15 parties, impossível de primeira**, metaprogressão pesada fora da run e heróis com **poderes fortes de cooldown longo por party morta**, para o jogador pensar ("mando isca para queimar o poder antes da carta forte?").

## Decisões (grilling 21/11)
**Run**
- 1 fase, fila **fixa** de 15 parties (classes entram aos poucos), 3 atos de estrada + arena. Run ~45 min; o normal é perder no covil. Metas (estimadas, **não medidas** — bot de balanço fica para depois): 1ª run sem melhoria chega à party 4–5 **e rende Almas para 2–3 melhorias baratas**; vitória perto da run 20.
- Saem a campanha de 7 fases, o mapa da campanha e a **Horda sem fim**. Tutorial fica (opção no menu, config própria).
- Oferta de carta: **1 de 3 só por party morta**; melhoria fora da run libera oferta por herói.
- Dragão liberado ao derrotar a party 3, Lich a 6. Save **zera** (MetaSave v5).

**Poderes dos heróis**
- Só na morte da party inteira: a party nova ganha 1 poder **novo ou evolução** de um que já tem (nível 1–3; ~1 em 3 é evolução). **Acumulam** na run toda (sem teto).
- Escolha ponderada pelo estilo do jogador, somando o dano recebido pela **party toda** (hoje só o líder conta).
- Revelação: depois da carta do último herói, **pausa + painel** (nome, efeito, recarga, lista dos poderes que a party já tem); sem dica; clique continua.
- Ícones dos poderes sobre a party com **timer de recarga visível**.
- Gatilhos (primeiro inimigo / próxima criatura / próximo feitiço): **1 dispara por contato, ~1,5 s entre gatilhos**.
- Eu reviso as 15 habilidades atuais e crio novas: fortes com recarga 10–20 s (AoE forte no 1º inimigo; mata a próxima criatura; anula o próximo feitiço) e simples (rato aliado a cada 5 s, máx. 5).

**Metaprogressão**
- Moeda **Almas** = dano nos heróis + heróis mortos; mantida 100% ao perder; dano conta só até a vida máx. de cada herói (anti-farm de cura/escudo). Ouro continua sendo a moeda da run.
- **Reembolso total e grátis**.
- **Deck**: 3 vilões; deck de 19 (cartas do vilão + comuns liberadas, até 3 cópias). Cartas liberadas por desafio.
- **Cartas I–VI**: meta sobe até VI, run também (teto VI). +25%/nível (2,25× no VI); custo −1 no III e −1 no V. **Especial `n3` vai para o VI.** Upgrade da run ignora cartas no VI (todas no VI → ouro).
- **Roda radial** (setores): Atributos (elixir máx., taxa, mão inicial, recarga da carta, elixir inicial), Locais (sub-ramo por local; ramos recompensa/facilidade, ex. ritual ×3 de elixir e mais longo), **Arena** (o "covil": vida das partes do chefe, dano do braço, estruturas — nome do setor assumido para não confundir com a tela Covil), Relíquias, Troca de ato (**setor só abre depois da 1ª vez que o jogador chega ao ato 2**; antes mostra "chegue ao ato 2"), Geral (oferta por herói, ouro inicial, Almas +%). Oferta da carta e painel do poder seguem **duas telas** (decidido na 2ª revisão).
- **Relíquias**: ~12 comuns livres, resto por desafio (inclusive degraus maiores das famílias de elixir/mão); nível 1–3 com Almas (×1/×1,5/×2).

**Telas** (aprovadas sobre mockups em 21/11)
- Fluxo: Menu → **Covil** (roda) ⇄ **Biblioteca** → Escolher vilão → Run → Fim da run → Covil.
- **Covil**: árvore radial, centro "Coração do covil", nó só compra depois do anterior; **arrastar e zoom livre**; passar o mouse/clicar num nó abre **janela lateral** (efeito, nível, preço, Comprar); lateral com Almas, Reembolsar tudo, Biblioteca, Começar run; cores comprado/disponível/trancado (tracejado).
- **Biblioteca** (padrão álbum): abas por vilão + Comuns; cartas grandes com arte em páginas, nível e "N/3 no deck"; bloqueadas tracejadas com desafio e progresso; filtro por custo; lista fina do deck à direita (19/19) com **curva de elixir**; clicar abre **zoom com a carta atual ao lado da versão do próximo nível com números recalculados** (diferenças destacadas; no VI o especial), barra I–VI, "Subir · preço", "+ no deck (n/3)".
- **Menu principal** (pele Mapa aberto): Continuar, Covil, Biblioteca, Compêndio, Tutorial, Configurações, Sair, com recorde e Almas. **Escolher vilão**: deck 19/19, recorde por vilão, trancado "derrote a party N", Editar deck / Começar. **Pausa**: + Poderes da party, Desistir mantém as Almas. **Fim da run**: "O covil caiu na party N de 15", recorde, Almas (dano + heróis + total), desafios com a revelação atual, Menu / Ir ao Covil.

## Modo de execução (pedido dele: rápido, paralelo, quase só Sonnet)
- **Opus (eu)** só faz: onda 0 (contratos), revisão e merge de cada onda, rodar testes e capturas. **Todo o código de cada frente é feito por subagentes `model: sonnet`** com `isolation: worktree`, em ondas de até 4 em paralelo, cada um com arquivos próprios.
- Cada brief diz: worktree cortado da ponta de `metaprogressao` (conferir `git log -1`); `"$G" --headless --path . --import` antes de testar (class_name/imports); testes `"$G" --headless --path . res://tests/tests.tscn` (última linha "falhas: N", sem pipe que esconda travamento); Godot sempre em segundo plano/janela fora da tela; commit no próprio branch; relatório com arquivos tocados, testes e pendências.
- Merge onda a onda em `metaprogressao`; conflitos resolvidos por mim; testes verdes antes da próxima onda.

### Onda 0 — fundação (Opus, sequencial)
1. Conferir que o worktree `LastBoss-balance-auto` não tem `rules.json`/`sim.gd` sem commit que conflite; avisar se tiver.
2. Commitar o trabalho pendente da main (rodadas visuais 20–21/11) num commit e criar branch `metaprogressao`.
3. **Contratos** (commit "contratos"), para as ondas não se pisarem:
   - esquemas e esqueletos de `data/hero_powers.json`, `data/meta_tree.json` (nós: id, setor, pai, custo por nível, efeito como chave→valor), `data/campaign.json` novo (fase única + tutorial);
   - `sim/meta_apply.gd`: `static func run_mods(meta) -> Dictionary` (chaves fixas: elixir, mão, recarga, locais, arena, ato, relíquias, níveis de carta, deck, oferta_por_heroi) que o `Sim.setup` recebe num parâmetro novo `mods`;
   - API do `MetaSave` v5 (`almas`, `upgrades{nó:nível}`, `card_levels`, `decks`, `relic_levels`, `relics_unlocked`, `best_party`, `buy/refund/refund_all`);
   - eventos `POWER_GAINED`, `POWER_TRIGGER`, `POWER_READY`; `Sim.party_powers()` para a HUD;
   - **ganchos de uma linha já colocados por mim em `sim/sim.gd`** (`setup` → `MetaApply`, `_member_down`/`_hero_fell` → `HeroPowers.on_member_down/on_party_down`, `CardDef` via `rules.card_levels`, `_relic_pool` → filtro), para que A, B, C e D escrevam quase só nos próprios arquivos novos e o merge não brigue;
   - dados de mentira em `meta_tree.json`/`hero_powers.json` e `MetaSave` v5 com corpo mínimo, para as telas começarem já;
   - regra de teste: todo teste que salva usa caminho temporário (`MetaSave.save(path)`), nunca o `user://meta.save` do jogador (worktrees compartilham o `user://`).

### Onda 1 — sim e dados (4 Sonnet) **junto com a onda 2a** (E e F, 2 Sonnet) — 6 frentes em paralelo
Cada frente escreve primeiro os próprios testes em `tests/tests.gd` (função nova por frente, sem mexer nas dos outros) e só entrega com 0 falhas.
- **A · Run de 15 parties**: `data/campaign.json`, `sim/game_data.gd:71-91`, `Sim.setup` (`sim/sim.gd:157`) lendo `mods`, remover `endless_party`/`_endless_extend` (l.274/286) e `record_endless`; estrada/atos para ~45 min (`rules.acts[].road`), `rules.party.step` estimado; oferta só por party em `_member_down` (l.1525)/`_hero_fell` (l.2035) com a flag `oferta_por_heroi`.
- **B · Motor de poderes**: novo `sim/hero_powers.gd` + `data/hero_powers.json` (revisão das 15 + novas, níveis 1–3); `_learn_ability`/`_upgrade_options` (l.1551/2113) → sorteio novo/evolução com peso pelo dano da party; gatilhos 1-por-contato + 1,5 s; ratos aliados dos heróis; ganchos por queda migrados (Clériga `bless_next` na queda da party, `bad_blood` por party, `next_hero_ability` = +1 poder na próxima party); fila de oferta-aviso do poder (molde da `"give"`), depois da oferta de carta (duas telas); **save da run em andamento** (`sim/save_game.gd` v7→v8) com poderes, níveis e recargas; textos PT/EN dos poderes em `strings.csv`.
- **C · Níveis I–VI**: `CardDef.mult`/`has_n3` (`sim/card_def.gd:94-128`) → teto 6, especial no VI, desconto máx. 2; `rules.card_levels.max 6`; `roll_offer_level` (l.2642), preço da loja (`_open_shop` l.2818), `forge_hammer`, ritual pulando cartas no VI; `game/card_mold.gd` com placas I–VI e molduras 4–6.
- **D · Meta e desbloqueios**: `sim/meta_save.gd` v5 (sem `phases_won`, `endless_best`, `rare_choices`, `win_phase`; `reach_party`), Almas por dano com teto + heróis, `sim/meta_apply.gd`, conteúdo de `data/meta_tree.json`; desafios convertidos na fonte (`tools/desbloqueios.json` + `tools/gerar_unlocks.py`; fase→party, "em N fases"→"em N runs") + relíquias no gerador e em `tools/desafios_editor`; `_relic_pool` (l.1227) filtrando liberadas e `_offer_relics` (l.1264) com fallback de raridade.

- **E · Covil radial** (onda 2a, com dados de mentira): novo `game/meta_tree_view.gd` (nós/arestas de `meta_tree.json` em coordenadas polares por setor/profundidade, arrastar/zoom, janela lateral, comprar/reembolsar, setor Troca de ato trancado até chegar ao ato 2); ícones SVG dos nós no mesmo pipeline dos ícones de relíquia.
- **F · Biblioteca** (onda 2a): refazer `game/collection.gd` (álbum, lista + curva, zoom atual × próximo nível usando `CardDef` e `card_mold.gd`, desafios das bloqueadas).

Opus: merge de A–F, `--import`, testes, troca dos dados de mentira pelos reais, conferir as telas com captura.

### Onda 2b — integração das telas (2 Sonnet em paralelo, depois de A e B no branch)
- **G · Menus, fim de run, tutorial, compêndio**: `game/menu.gd`/`game/map_menu.gd` (itens novos, sai campanha/Horda/Coleção, escolher vilão refeito), pausa (+ Poderes da party, Desistir), tela de fim em `game/main.gd` (Almas, recorde, `unlock_reveal.gd`), apagar `game/campaign_map.gd`; `game/tutorial.gd` (`TUT_fall` e textos de "próximo herói"), aba herói do `game/compendium.gd`, `tips.gd`; textos PT/EN em `locale/strings.csv`.
- **H · HUD dos poderes**: `game/hud.gd` (fileira de ícones com timer sobre a party, painel de revelação com pausa acima da `offer_layer`), cena de queda curta por membro e longa só na última (`game/world_view.gd`); ícones SVG dos poderes.

### Onda 3 — fechamento (até 3 Sonnet) + integração (Opus)
- **I · Testes antigos**: ajustar/remover os que quebraram com a mudança (`t_data` 15 habilidades, `t_party`, `t_parties`, `t_endless`, `t_group`, `t_events`, `t_classes`, `t_relics_1111`, `--menutest`/`--tiptest`) e completar: save v5 ida e volta, **conservação do reembolso**, fallback de relíquia, teto das Almas.
- **J · Bots**: `bots/player_bot.gd` e `bots/human_bot.gd` (tilt por party, oferta nova, Biblioteca/deck, poderes) — o bot precisa terminar uma run de 15 com meta maxada.
- **K · Doc** `docs/METAPROGRESSAO.md` gerado dos JSON (poderes, árvores, custos, curva, decisões assumidas e riscos: curva ×1,21/party não calibrada, ajustador automático e editor de balanço ainda citam fases — ficam para a rodada do bot) + docs desatualizados marcados.
- Opus: merge final, testes, run headless de 15 parties, captura em segundo plano das telas para ele aprovar. Sem push.

## Prompt para a nova conversa (Sonnet)
Ver o bloco entregue ao usuário em 21/11; o coordenador passa a ser Sonnet (não Opus), com subagentes Sonnet em worktrees.

## Verificação
- `tests.tscn` com 0 falhas após cada onda.
- Run headless completa de 15 parties com o bot: com meta maxada termina; sem meta perde.
- Save v5: comprar, salvar, carregar, reembolsar tudo → Almas iguais ao total ganho.
- Capturas em segundo plano: Covil radial, Biblioteca (zoom atual × próximo), menu, escolher vilão, painel do poder, ícones de recarga, fim da run.
- Metas de dificuldade (party 4–5, 2–3 melhorias na 1ª run, vitória na run ~20) ficam **não medidas** até a rodada do bot de balanço.
