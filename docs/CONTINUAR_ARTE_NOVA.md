# Continuar: arte nova das cartas (parado em 13/11/2026)

> **ATUALIZAÇÃO (13/11, 23:40): as 112 artes estão NO JOGO** (`assets/cards/`, 20 `.import` novos, `data/card_art.json` com as
> 112 `painted`), import do Godot sem erro, testes com 0 falhas, build novo em `export/LastBoss.exe` (o anterior ficou em
> `export/_anterior_2026-11-13_arte-estilo-B/`). `integrar.py` agora copia de `arte_ia/final_novo` (a arte de 12/11 segue em
> `arte_ia/final/`). Nada commitado. O designer revisa no jogo; pendências conhecidas: Óleo Fervente (cabeça virou uma massa
> de óleo, esquisita) e a revisão geral. O `.pck` passou de 340 para 575 MB por causa de `docs/` (1,1 GB, só algumas
> subpastas têm `.gdignore`), não das artes: `exclude_filter` do preset de export poderia ganhar `docs/*`.
>
> **ATUALIZAÇÃO anterior (13/11, 17:26): as 112 cartas foram geradas** em `arte_ia/final_novo/` (plague 24, dragon 20, lich 10,
> common 17, base 41), com pranchas em `arte_ia/pranchas/novo_<facção>.png`. O resto deste arquivo (estado "15 de 112" e o
> prompt de retomada) é o histórico de antes. **Falta:** o designer revisar as pranchas e apontar o que refazer
> (`deck_novo.py refazer <id>`), e só então integrar no jogo (`assets/cards/`, quando ele pedir). `rat_king` é a versão
> aprovada da cadeia A-V2-S1 (cópia em `_arquivo_2026-11-13/novo_estilo/rat_king`); `lote` agora pula qualquer carta que
> já tenha arquivo.

Sessão encerrada a pedido do designer. O estilo foi **aprovado** (inclusive as armaduras); falta gerar o resto do baralho.
Nada foi commitado. O estilo e o fluxo estão na skill `.claude/skills/cartas-ia/SKILL.md` (atualizada em 13/11).

## O estilo aprovado (não rediscutir)
Guache leve, um pincel chato muito largo só, valores claros, branco do papel aparecendo, uma sombra grande por forma,
grão 0,9. **Nenhum detalhe fino** (escama, dobra, fivela, enfeite de coroa, placa de armadura). **Criaturas com olhos
estilizados** (amêndoas pequenas), **humanos nunca com olhos** (rosto na sombra do elmo/capuz). Pose e quantidade de
elementos = arte antiga do baralho. Gerado no tamanho da carta (560×544 → recorte 556×534).
Tudo isso está em `arte_ia/_tools/estilo.py` (fixo) e `deck_novo.py` (gerador). A cadeia que levou ao estilo e o que foi
recusado (filtros de textura, "esponja" → bolinhas, pincéis mais finos) está no fim deste arquivo.

## Estado
- **15 de 112 cartas feitas** em `arte_ia/final_novo/<id>.png` (a pasta é ignorada pelo git até a linha
  `!arte_ia/final_novo/` do `.gitignore`, que foi acrescentada nesta sessão; commitar só se o designer pedir):
  plague 9/24 (rat_king, rat_brute, infected_bite, bat_cloud, rat_trap, wolf_pack, brood_mother, corrupt_piper,
  sewer_flood + bubonic_plague), dragon 2/20 (elder_dragon, molten_gold), lich 1/10 (death_knight), common 2/17
  (cave_troll, ruin_titan), base 1/41. `deck_novo_state.json` guarda semente e denoise de cada uma.
  (Contagens por `arte_ia/cards.json`; plague = 24 cartas, 16 antigas + 8 novas.)
- **Faltam 97:** plague 15, dragon 18, lich 9, common 15, base 40.
- O designer pediu **só a Rainha da Peste primeiro, para testar**: termine `plague`, mostre
  `arte_ia/pranchas/novo_plague.png` e **espere o OK antes de dragon/lich/common/base**.
- As **28 cartas novas** (planejadas em outra conversa, só existem nos `data/cards_*.json` modificados e não commitados
  desta árvore) já estão em `arte_ia/cards.json` e têm assunto em `arte_ia/_tools/subjects/novas_*.json`
  (plague 8, dragon 8, lich 2 + common 5 em `novas_lichcommon`, common 5 em `novas_common`). Não perca esses `data/` e
  `locale/strings.csv` modificados: são trabalho do designer.

## Como terminar
```bash
cd arte_ia/_tools
python -I deck_novo.py lote plague          # pula o que já existe; gera prancha novo_plague.png no fim
python -I deck_novo.py lote dragon          # só depois do OK do designer; idem lich, common, base
python -I deck_novo.py refazer <id>         # semente +1, quando ele apontar uma carta
python -I deck_novo.py prancha plague       # refaz só a prancha
```
- Antes: **feche o `LastBoss.exe`** (aberto, divide a GPU: 40 s virava ~3 min por imagem) e confira
  `curl -s http://127.0.0.1:8188/queue` sem jobs de outro projeto.
- O **ComfyUI encerra sozinho, sem erro, depois de 2–3 prompts** (sem evento no Windows, RAM/VRAM sobrando; causa
  desconhecida). `deck_novo.py` já sobe o servidor de novo e repete a carta (até 5 tentativas); o servidor sobe solto do
  script, então fica de pé depois dele. Cada carta leva ~10–40 s; o primeiro prompt após subir leva ~90 s (carrega o modelo).
- Uma imagem por vez (a VRAM não comporta duas). Sem subagente para conferir imagem: quem revisa é o designer.
- Cartas com arte antiga são **repintadas** a partir dela (`arte_ia/<id>/<arquivo do deck_state.json>`, base simplificada
  por mediana); cartas novas saem do texto. Frase de olhos só entra em carta com criatura (`estilo.adapt_subject`).
- Cuidado ao escrever/ajustar assunto: nunca "olho/olhar"; nada de lista de peças de armadura (placas grandes lisas);
  dragão = pele lisa (a frase de escamas já é trocada pelo adaptador).

## Não feito (decidir com o designer)
- Trocar `assets/cards/` pelas artes novas (só quando ele pedir; o jogo ainda usa a arte antiga de 12/11).
- Retratos de herói (`hero_*.png`) e de vilão (`villain_*`) não fazem parte do baralho; ficaram de fora.
- 9 cartas da branch de balanceamento (`LastBoss-balance`: bone_prison, cosmic_ray, damned_army, dark_fury, dark_pact,
  petrifying_gaze, broken_bridge, false_sign, lair_walls) não existem nos dados desta branch: sem arte nova.
- `integrar.py` ainda assume que o jogo é a pasta-mãe de `arte_ia/` (observação 0092 do task-observer, aberta).

## Arquivo (`arte_ia/_arquivo_2026-11-13/`, ~250 MB, ignorado pelo git, regenerável)
minimalista (5 estilos sem pincel grosso, recusados) · pincel_grosso (A/B/C; **A** escolhido) · pincel_grosso_a (A1–A3;
**A1** escolhido) · guache_leve, guache_rala, guache_esponja, guache_esponja2 (filtros de textura: recusados, "é um
filtro") · esponja_ia (IA com a textura de esponja: virou bolinhas, recusado) · a1_variacoes (V1–V3; **V2** escolhido) ·
v2_sem_detalhe (S1–S3; **S1** escolhido) · novo_estilo (6 cartas na cadeia completa, inclui o patrulheiro de teste) ·
final_novo_teste (teste do passo único). Os scripts dessas rodadas ficam em `arte_ia/_tools/` (pincel_grosso*.py,
a1_variacoes.py, v2_sem_detalhe.py, guache_*.py, esponja_ia.py, novo_estilo.py); para rodar um de novo, mova a pasta de
saída dele de volta para `arte_ia/`. Pranchas de comparação: `arte_ia/pranchas/*.png`.
Memória do Claude: `card-art-minimal-v2-2026-11-13.md`.

## Prompt para colar na próxima sessão
```
Continue a arte nova das cartas do Last Boss (estilo aprovado em 13/11, sessão anterior parada a pedido).
Leia docs/CONTINUAR_ARTE_NOVA.md e a skill cartas-ia (já atualizada); não rediscuta o estilo.
Estado: 15 de 112 cartas feitas em arte_ia/final_novo; faltam 97 (plague 15, dragon 18, lich 9, common 15, base 40).
Faça só a Rainha da Peste primeiro: feche o LastBoss.exe, confira a fila do ComfyUI e rode
`cd arte_ia/_tools && python -I deck_novo.py lote plague` (o script sobe o ComfyUI sozinho se ele cair).
Mostre a prancha arte_ia/pranchas/novo_plague.png e espere o meu OK antes de dragon, lich, common e base.
Refaça as cartas que eu apontar com `deck_novo.py refazer <id>`. Não commite nem troque assets/cards sem eu pedir;
não perca os data/ e locale/ modificados (são cartas novas minhas, não commitadas).
```
