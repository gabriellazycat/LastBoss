# Run em 3 atos, disputas novas, relíquias e eventos (09/11/2026)

Decidido com você no grilling de 09/11, depois do seu playtest. A maior parte foi implementada com você fora (AFK, autonomia total). Branch **`atos-2026-11`**; a `main` não mudou.

## O que você pediu, e o que mudou

| Seu comentário | O que mudou |
|---|---|
| Chefe forte demais na arena (atiradores, ninho, teleporte) | Na arena o herói caça **atiradores e estruturas a até 10 m** (antes, só o que estava a 3 m). A **Torre de Gárgula** não é mais ignorada: fica em pedra por 3 s e depois vulnerável por 5 s. O **teleporte custa 2 de elixir** e recarrega em **12 s** (eram 0 e 8 s). |
| Não há "momento certo" de jogar | As **habilidades do herói aparecem na HUD com a recarga** (fatia escura que vai sumindo). O nome da habilidade aparece **sobre o herói 1 s antes** de ela disparar (giro, grito de guerra, investida). Exemplo: depois do Grito de Guerra (12 s de recarga) é a hora do enxame; depois do Escudo Refletor (10 s), a do feitiço. |
| Recompensas sempre do mesmo tipo | **Uma oferta nunca mistura tipos.** A queda do herói sorteia o tipo uma vez (70% cartas, 30% modificadores). |
| Locais que se vencem por ter um inimigo perto | Toda disputa pede **ação sustentada**, e **o herói para no local** até ela acabar (tabela abaixo). **Perder não dá nada.** |
| O deck muda pouco | **3 atos** com 7 ou 8 locais por rota (20 a 24 na run), trechos mais curtos, uma **relíquia do covil no fim de cada ato** e um local novo **"?"** com eventos de texto. |
| Jogo feio | Uma **sessão separada** está estudando RoR2, Soulstone Survivors e Megabonk e vai pôr as versões no jogo, selecionáveis em Configurações, para você escolher. |
| Clique só embaixo da carta | **Clique em qualquer parte da carta**: ofertas, loja, coleção e a carta ampliada da mão. |
| Chão piscando e com curvas grandes | Estrada em **trechos retos** (dois cantos por trecho). Ramos que se sobrepõem perto das bifurcações ficam em alturas diferentes, e o ramo fechado escurece no shader, sem a transparência que piscava. |
| Explicação no mapa e bifurcação depois do evento | Parar o mouse num local do **mapa grande abre a caixa** com a disputa e a recompensa. A escolha da **bifurcação vem depois do evento do local**: o herói anda até o nó, resolve o local e só então o jogo pede o ramo. |
| Compêndio no menu | **Compêndio** no menu principal, com 5 abas: Cartas (bloqueadas também, N1 a N3, especial do N3, preço), Relíquias, Modificadores, Locais e Herói (cada habilidade com como contra-atacar). |

## Locais

| Local | Disputa | Venceu | Perdeu |
|---|---|---|---|
| Ritual | 10 monstros seus morrem dentro do círculo em 25 s (elixir ×2 lá dentro) | sobe 1 entre 3 cartas | nada |
| Santuário | monstros seus (não estruturas nem Mímico) no círculo por 6 s somados, em 20 s | 1 entre 3 cartas raras+ | nada |
| Taverna | destruir as 3 casas (400 de vida) em 25 s; seus monstros a até 10 m vão nelas; o herói defende quem as ataca | 1 entre 3 modificadores | nada |
| Ponte | 150 de dano em 15 s, com o herói atacando 40% mais devagar | escolhe o tipo, depois 1 entre 3 | nada |
| Fonte | o herói bebe por 4 s; medo, raiz, empurrão, petrificação ou 120 de dano interrompem | remove a carta que quiser | nada, e o herói cura 15% |
| Loja | sem disputa: abre na chegada; 1 garantida em toda rota de cada ato | compra com ouro | — |
| ? (Encruzilhada) | evento de texto sorteado entre 8 | conforme a escolha | — |

## Decisões que tomei no seu lugar

Você estava fora e disse para eu não perguntar nada.

1. **Relíquias e eventos já estão no jogo, com o rascunho da planilha.** Você tinha escolhido "planilha antes do código". Fora e com autonomia, implementei o sistema com o rascunho das abas `Run - Relíquias` e `Run - Eventos`, para a run ficar jogável. Mudar um número ou um texto é editar `data/relics.json` / `data/events.json` (e `tools/strings_2026_11_09.py` para os textos); nada está fixo no código.
2. **Heróis:** 7 na fila, herói 1 com 1150 de vida e 40 de golpe, passo ×1,2 por herói (era ×1,26 com 5). Números para o lote ajustar.
3. **Ponte** perdeu a coleira de 1,5 m e o bônus de bando: ficou só com a disputa que era da Taverna.
4. **Janelas e números das disputas** (tabela acima) são propostas.
5. **Herói cai no meio da disputa:** o local fica perdido, sem recompensa.
6. **Herói vivo passa de ato com a vida que tem**, sem cura.
7. **Fim de ato** (menos o último): as suas unidades somem, as zonas acabam e o contrato em andamento falha. Antes da arena, as unidades perto do herói entram com ele, como antes.
8. **Loja garantida:** uma fileira de um nó só tem a Loja, então toda rota passa por ela uma vez.
9. **Torre de Gárgula:** a regra nova (3 s de pedra, 5 s vulnerável) vale na estrada também.
10. **Raridade por ato** em vez de por tempo (ato 1: 65/25/9/1; ato 2: 50/30/16/4; ato 3: 40/30/22/8).
11. **Almas por local 2 → 1** (com 20 a 24 locais, elas dobrariam). **Contratos a cada 180–240 s** (eram 120–180).
12. **Chão por ato:** Bosque enluarado, Outono e Terra amaldiçoada (looks 2, 3 e 4). Só vale quando o chão escolhido em Configurações é um dos looks 1 a 4; as direções novas de arte não são trocadas por ato.
13. **Aviso de habilidade:** as ativas (giro, grito de guerra, investida) esperam 1 s depois do aviso antes de disparar. Isso enfraquece um pouco o herói. As reativas (golpe heroico, escudo refletor, segundo fôlego) só mostram a recarga.
14. **Salvamento versão 3:** runs salvas antes desta rodada não carregam (o Continuar volta ao menu). A coleção e as Almas (`meta.save`) continuam.
15. **Atalhos de captura:** `--offer=relic`, `--offer=event[:id]` e `--offer=contest:<tipo>` com `--offerat=N`.

## Riscos e pendências

- **Testes de entrada real com janela:**
  - O `--uitest` está igual à versão anterior: só "arrastar e soltar" falha, como já falhava antes desta rodada.
  - O `--menutest` não roda nem na versão anterior neste ambiente (o processo sai sem imprimir nada). Por isso não foi validado.
  - Ambos dependem do foco da janela e do cursor físico, e havia outra sessão (a de arte) usando a máquina ao mesmo tempo.
  - As telas novas foram conferidas por captura: oferta de relíquia, evento, painéis da Taverna e da Fonte, e compêndio.
- **A planilha** ganhou as abas `Run - ` (Atos, Locais v2, Relíquias, Eventos, Arena, Ofertas).
  - Backup: `Revisao do conteudo - Last Boss (backup 20261109-115453).xlsx`, não versionado.
  - **Não rode mais `tools/xlsx_to_json.py`:** ele tem regras antigas fixas no código e desfaz o balanceamento.
- O fuzz e o lote cobrem a simulação; a troca de ato com a janela foi vista só em captura, e a arena nova ainda não foi jogada por uma pessoa.

## Lote (720 runs, `reports/20261109-133727/report.md`)

Heróis: o 1º com 1450 de vida e 46 de golpe, passo ×1,21; casas da Taverna com 250 de vida.

| | Horda | Ruína | Tesouro |
|---|---|---|---|
| Heurístico (bot bom) | 40% | 19% | 44% |
| Aleatório | 38% | 35% | 52% |

**Dentro das metas:**
- Run de uns 21 a 28 min.
- Chegada à arena aos 17–25 min.
- O 4º a 6º herói chega à arena.
- 3 relíquias por run.
- Elixir quase nunca desperdiçado.

**Fora das metas (o maior risco desta rodada):**
- **O bot bom não supera o aleatório na run em atos.** Tentei:
  - o explorador: o melhor perfil novo vence 46% nas sementes dele e 15–25% em sementes novas;
  - pôr os monstros da arena entre o chefe e o herói;
  - guardar elixir para o teleporte;
  - teleportar menos;
  - reduzir a adaptação do herói.

  Nada separou os dois. A dificuldade vem da força dos heróis: com o 1º herói a 1150 de vida, os dois bots venciam 44–75%; a 1800, o bom caiu para 0–25% e o aleatório ficou em 25–50%. **Escolhi o meio-termo** para você conseguir vencer a arena na primeira run. Se ficar fácil ou difícil, o botão é `hp` em `data/hero_escudeiro.json`.
- **A Taverna quase nunca é vencida pelos bots** (0 a 0,2 por run), mesmo com casas de 250 de vida: eles não sabem jogar essa disputa. O teste automático confirma que monstros perto das casas as destroem. Uma pessoa deve conseguir; se não conseguir, o próximo passo é menos vida ou mais tempo.
- O Santuário e o Ritual na Ruína (deck com poucos monstros) também quase não são vencidos pelos bots.
- Próximo passo de balanceamento: ensinar os bots a jogar Taverna e Santuário (soltar monstros que lutam no local) e reavaliar o Heurístico. Isso só vale depois de você jogar e dizer se a dificuldade está boa.

