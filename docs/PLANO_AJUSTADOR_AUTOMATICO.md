# Plano: ajustador automático de balanceamento geral (v2, revisado em 18/11/2026)

Nada aqui foi implementado nem rodado. As decisões marcadas com ✔ foram tomadas com você (a primeira conversa e a revisão de 18/11). O resto é proposta minha.

## Objetivo
Medir e reajustar o balanceamento do jogo todo (cartas, relíquias, eventos, bênçãos e buffs, classes de herói, fases) de forma automática, e entregar uma página de patch notes para você aprovar item a item.

## Decisões ✔
**Medição**
- Métrica por item: **impacto** (A/B com as mesmas sementes), não vitória bruta.
- Métrica principal **contínua**: fração da vida total do grupo de heróis tirada, normalizada pelo tamanho da party da fase. Vitória, `heroes_fallen`, uso e elixir desperdiçado ficam como métricas secundárias.
- **RNG do Sim separado em fluxos** (mapa/rota, ofertas/eventos, combate, bot), para os dois braços do A/B terem o mesmo mapa e as mesmas ofertas.
- **A faixa de tolerância é fixada depois do smoke**: o menor valor que o ruído medido deixa ver com o orçamento. Não fica mais em ±5 a priori.
- **Impacto de uma carta = troca**: a carta entra no baralho inicial no lugar de uma carta de referência do mesmo custo, sem diluir o baralho. "Banida das ofertas" fica como medida extra, só para os suspeitos.

**Metas**
- Bot humano por fase: **90% no tutorial (fase 0), depois 60 / 56 / 52 / 48 / 44 / 40% nas fases 1 a 6**.
- Aleatório abaixo de 25%. Se numa fase o humano bater a meta e o aleatório passar de 25%, o item vira **alarme de mecânica** no bloco "repensar", com o diagnóstico de onde o aleatório ganha (estrada × arena). O ajustador não força isso com números.

**Botões e limites**
- Cartas: custo, vida, dano, recarga, velocidade e alcance; em feitiços, os números de `fx` e `n3`.
- **Custo: ±1 do valor original, nunca abaixo de 0.** Os outros números: ±40% do original, no acumulado. Mudança maior que isso não é testada e vai para "repensar".
- **Dificuldade só com `hp_mult` por fase.** O `damage_mult` da fase, o Lorde (`boss_lorde.json`) e as regras globais (`rules.json`: dano das unidades, comprimento da estrada) ficam fixos nesta rodada. Se o `hp_mult` saturar numa fase, ela vai para "repensar".
- Escopo: tudo (cada particularidade, cada buff passado ao próximo herói etc.), menos o que está em `data/locked.json` e os botões globais acima.

**Ordem**
- **Primeiro, a triagem** de cartas mortas, exploits e outliers. Depois as camadas relativas. **A dificuldade geral fica por último**, como acerto fino.

**Execução**
- **Quantas noites forem precisas**, com ordem "a qualquer momento": todos os itens avançam juntos, de semente em semente, e as estimativas e a página são salvas de tempo em tempo. Se você mandar parar a qualquer hora, já existe uma estimativa de tudo.
- Ajuste com o bot `human`. **Validação no fim com a família `human_*` e o heurístico, em sementes que não foram usadas no ajuste.**
- Trabalho num worktree novo, **branch `balance-auto`** a partir da main. A branch `balance` antiga (`../LastBoss-balance`, a8d1c39) não é tocada.
- **Antes de criar o worktree, commitar na main o trabalho pendente do Rato Macho** (`cards_plague.json`, `sim.gd`, `card_def.gd`, `unlocks.json`, testes, locale, arte), para a carta entrar no balanceamento.
- Saída: página HTML local de patch notes com caixa de aprovar. **A aprovação acontece só quando você decidir parar.** A main não muda entre as noites, e só vai para `data/` o que você marcar.

## Etapas
0. **Auditoria de botões inertes.** Listar todo campo que vou mexer e provar que o Sim o lê: mudar o valor numa cópia e ver o resultado mudar. Campo inerte sai da lista. Já se sabe que o `hero_hp_mult` por vilão (`villains.json`) é inerte (o Sim só lê o de `rules.json`), e que o `hp_mult` e o `damage_mult` da fase estão vivos (`sim.gd:171-172`). Na mesma etapa, conferir o **alcance**: carta, relíquia ou evento que nunca aparece em pool nenhum sai da lista.
1. **Ponto de partida.** Commitar o Rato Macho na main. Criar o worktree `balance-auto`, rodar `--headless --import` (sem cache, classes novas e o locale não carregam), rodar `tests.tscn` (0 falhas) e repetir um lote de controle para confirmar o determinismo.
2. **RNG em fluxos.** Separar o `rng` único do Sim (`sim/sim.gd:20`) em fluxos por subsistema. Teste: o mesmo item ligado e desligado gera o mesmo mapa, as mesmas ofertas e os mesmos eventos na mesma semente. Os relatórios antigos deixam de ser comparáveis, então a linha de base é medida de novo.
3. **Ganchos de A/B no `batch.gd`.** Já existem `--force_relic`, `--force_event` e `--data` (cópia de `data/`). Faltam: `--swap_card=id:ref` (troca no baralho inicial), `--ban_card=id`, e forçar classe e bênção na party. Corrigir a **atribuição de dano das invocações**: hoje vai para o id da criatura (`skeleton`, `rat`) e não para a carta.
4. **Catálogo de botões.** Um arquivo só (`tools/balance_auto/botoes.json`) com, para cada botão: arquivo, caminho, valor original, limite (±1 no custo, ±40% no resto), passo e item. Os botões variam por tipo de carta: unidade (`hp`, `dps`, `attack_interval`, `speed`, `range`, `count`) e feitiço (`fx.*`, `n3.*`). "Recarga" quer dizer `attack_interval` da carta; a recarga da vaga (`draw_delay`) é global e fica fixa. O catálogo respeita `data/locked.json`. Cada botão sabe quais `n3`, `lvl` e textos do locale dependem dele.
5. **Medidor.** A/B pareado (mesma semente, controle compartilhado por célula), com intervalo por bootstrap do Δ pareado. Um item só fica "fora da faixa" se o intervalo inteiro estiver fora. Com ~200 itens, uns 10 saem fora por acaso, então **toda confirmação usa sementes novas**. Em cada lote ficam salvos: impacto, jogadas por run, participação no dano e elixir desperdiçado.
6. **Smoke** (poucos minutos): valida o pipeline, mede o ruído real depois das etapas 2 e 3 e o tempo por run. Daí saem **a faixa de tolerância** e o orçamento por camada.
7. **Triagem** (a "camada 0"). Tabela por carta (jogadas por run, participação no dano, cartas nunca jogadas) e uma captura do bot jogando cada baralho. Carta pouco jogada vai para o bloco "bot não usa", não para "fraca". Exploits (ação grátis que vira recurso) e outliers são marcados ou corrigidos antes de qualquer ajuste fino. O vão humano × aleatório é medido por fase.
8. **Ajustador em camadas.** Cada camada congela antes da próxima.
   1. cartas;
   2. heróis, classes, bênçãos e buffs;
   3. relíquias;
   4. eventos e santuários;
   5. dificuldade por fase (só `hp_mult`) até o humano bater as metas.

   Dentro de cada camada: triagem barata com poucas sementes, depois mais sementes só nos suspeitos (corrida sucessiva). Busca por coordenadas, um botão por item por ciclo, com o tamanho do passo tirado do modelo logístico de `tools/modelo_numerico.py` (logit(p) + B·ln(V)) em vez de um passo fixo. Um botão que andou duas vezes no mesmo sentido sem a célula cruzar a meta é estrutural: para e vai para "repensar".
9. **Execução em várias noites** em segundo plano. Tempo limite por run (já houve run de 143 s). Cache por (hash dos dados, bot, baralho, fase, semente), para a retomada e o reaproveitamento saírem de graça. Snapshot das estimativas e da página **a cada hora**. PC mantido acordado. Aviso ao terminar ou travar.
10. **Validação**: família `human_*` e heurístico em sementes de validação, com tudo ligado. Divergência grande entre bots vai para o relatório, sem novo ajuste.
11. **Página de patch notes** (`tools/patch_notes.html`, a partir de `painel_rodada.py` e `propostas_numeros.html`). Para cada item: antes → depois, impacto medido, intervalo, jogadas e participação no dano, e o motivo. Blocos separados para "repensar" (alto impacto, botão saturado, alarme do aleatório) e "bot não usa". Caixa de aprovar ou rejeitar, e um botão que exporta a lista aprovada em JSON.
12. **Aplicação** (quando você parar e aprovar). Um script lê o JSON aprovado. Para cada mudança, confere que o caminho existe exatamente uma vez e que o valor "antes" ainda é o atual da main; se não for, o item vai para conflito, sem sobrescrever. O script imprime antes → depois, confere `n3`, `lvl` e os textos do locale (que arredondam), e depois roda `tests.tscn` e um lote final de conferência.

## Peças que já existem e serão reaproveitadas
- `tools/run_batch.py`: um processo Godot por núcleo.
- `tools/exp_variants.py`: variantes como cópias de `data/`, lidas via `--data`.
- `tools/rodada.py`: A/B de relíquias e eventos.
- `tools/tuner.py`: laço de ciclos com commit e `locked.json`.
- `tools/modelo_numerico.py`: modelo logístico.
- `tools/painel_rodada.py`: página HTML.

O código novo fica em `tools/balance_auto/` e importa essas peças em vez de copiá-las.

## Por que o plano mudou (achados da revisão de 18/11)
- **Ruído**: no A/B de relíquias de 15/11 (20 sementes, mesmas sementes), o erro-padrão do Δ vitória foi de ~13,5 pp. Com 40 sementes, o intervalo de 95% fica em ±19 pp; para ±5 pp seriam ~550 sementes por item em cada célula. A semente comum quase não ajudou (desvio do Δ de ~0,60 contra ~0,69 de dois braços independentes), porque um RNG só faz as runs divergirem logo depois da primeira diferença.
- **Orçamento**: mediana de ~12 s por run e 12 núcleos dão ~3.500 runs/h, ou ~28 mil numa noite de 8 h. Medir tudo uma vez (118 cartas, 53 relíquias, 24 opções de evento, 8 classes, 3 vilões × 6 fases) com 40 sementes custaria ~4 noites.
- **Fases**: a campanha tem 7 (0 a 6), e a meta antiga cobria só 1 a 4.
- **Um bot só**: em 15/11, o `human_novice` ganhou mais que o `human` em dragon@3 (20% × 12%), e o heurístico ganhou mais que o humano em várias células.
- **Ordem**: um botão geral compra qualquer taxa de vitória e esconde cartas quebradas (já aconteceu), e dois botões acoplados ajustados no mesmo ciclo oscilam (já aconteceu).

## Riscos que continuam
- `human_bot` é só um proxy de jogador; a meta de 60% para o bot não é 60% para você. Vale conferir com uma partida sua no fim.
- A separação do RNG mexe no Sim. Se o teste de determinismo (etapa 2) falhar, as etapas seguintes esperam.
- Se o ruído medido no smoke ainda for grande, a faixa resolvível pode sair larga (por exemplo, ±10 pp), e itens "um pouco fora" não serão distinguidos de itens dentro.
- Outras conversas mexendo em `data/` na main durante as noites: o worktree protege a medição, e a etapa 12 pega os conflitos.
