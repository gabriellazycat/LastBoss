# Briefing da esteira de arte das cartas (para os agentes)

Leia antes de começar: `.claude/skills/arte-de-carta/SKILL.md` (estilo e receita, decididos — não reabrir) e
`docs/arte_cartas/ESTUDO_TCG.md` (princípios de composição). Não leia o resto do projeto além do necessário.
Nada de commit. Não edite `lib.py`, `svgpath.py`, `gp_render.py`, `composite.py`, `run.sh`, `prancha.py`
(são compartilhados; se precisar de algo novo, faça no seu próprio arquivo e conte no relatório).

## Coordenadas
- Composição em **coordenadas de carta v2** (300×420). A janela da moldura A vai de x 11–289, y 11–278
  (= 278×267 unidades da arte, 556×534 px no PNG). A fita do nome cobre y ≥ 261 em coordenadas de carta
  (y ≥ 250 na janela): nada importante ali.
- `svgpath.Xf` está fixo na transformação do dragão (translate/rotate(-7)/scale(1.12)). Para outras cartas,
  defina a sua transformação no próprio `design_<id>.py` (mesma ideia: carta → janela = −11, −11).

## Etapa 1 — composição (agente Opus)
Para cada id do lote, em `docs/arte_cartas/<lote>/comp/`:
1. **Fichas primeiro:** toda criatura recorrente usada no lote vem de `tools/art/card_blender/fichas/<criatura>.svg`.
   Se a ficha não existe, crie antes: linha de ação, proporções (em "cabeças"), cabeça em 2 vistas e
   **3–4 poses** (andar/correr, atacar, saltar/cair, parada de ameaça) com peso e articulações plausíveis,
   e a paleta. Cada pose é um `<g id="pose_<nome>">` com uma `<path>` por peça anatômica
   (`id="<peça>"`, `data-fig="<figura>"`), para ser copiada e transformada nas cartas.
2. **`<id>.svg`** (viewBox 0 0 300 420): pose desenhada a partir da ficha (copie as paths e transforme;
   não redesenhe de olho), um elemento de cenário, efeito pequeno atrás. Estrutura obrigatória:
   - `<g id="bg">` fundo/cenário (sem transformação ou com uma só, explícita);
   - um `<g id="fig_<nome>" transform="...">` por figura; dentro, **uma `<path>` por peça** com `id` e
     `data-fig` (peças com o mesmo `data-fig` viram UMA silhueta no acabamento: corpo+membros = 1,
     cabeça = 1, cada asa = 1); linhas internas com função em `<path class="inner">`;
   - multidões (enxame de fundo, textura de ratos/morcegos/ossos) em `<g id="enxame">`, já em coordenadas
     de carta (sem transform), uma `<path>` por indivíduo — não viram `fig_`; o `#enxame` fica atrás das
     figuras; bichos que ficam NA FRENTE de uma figura vão em `<g id="enxame_frente">` (desenhado depois);
   - **herói dos feitiços: nunca repita a pose dele entre cartas** (do lote nem dos lotes anteriores —
     confira as folhas). Cada feitiço pede uma reação própria ao efeito: recuar, ajoelhar, cair de costas,
     escorregar, ser arremessado, erguer o escudo, correr, cambalear; e varie a câmera (de cima, de baixo,
     de costas, em escorço). A pose "guarda com o braço na frente do rosto" já foi usada demais;
   - criatura grande (dragão, ogro, troll, titã): cabeça e tronco maciços (cabeça ~1,5× e tronco/pescoço
     ~1,4× mais largos que o "natural" do primeiro rascunho) para ter massa a 150 px;
   - geradores de lotes diferentes têm todos um `base.py`: ao importar de outro lote, ponha o `base.py`
     do seu lote primeiro no `sys.path`; guias de figura (`guide=`) já são transformadas pela matriz da figura;
   - `union_outline` só rasteriza x −40..318, y −40..307: silhueta montada em coordenadas de ficha (fora
     disso) sai cortada — passe `off=` ao `union_poly` e fique com o polígono de maior área;
   - multidão em círculo/elipse: espelhe as silhuetas de perfil em vez de girá-las com a curva (giro
     máximo ±30°) e encurte as das laterais — girar tudo deixa bichos de pé ou de cabeça para baixo;
   - geradores: pasta de saída e de rascunho como parâmetro (não fixas no código), para o próximo lote reusar;
   - transforms escritos com **3 casas decimais**, iguais à matriz usada no gerador (arredondar para 1
     casa desalinhou peças no lote praga_1); exemplos de lote pronto: `docs/arte_cartas/praga_1/comp/`
     (gerador em `comp/_gerador/`);
   - `<g id="fx">` efeitos; `fill` = cor natural de cada peça (é a referência de cor do acabamento);
   - `<path id="acao" class="guide">` com a linha de ação (invisível no preview final).
   Pode usar as funções do motor de `docs/decisoes_2026-11-11/cartas_v2.html` (`brushD`, `boneD`,
   `blobD`, `crClosed`, `limbD`...) para gerar os `d`, mas o SVG salvo tem os `d` finais (sem JS).
   Leia só os trechos do v2 que usar (grep por `function artKing`, `artDragon`, `artHorde`, `artGoblin`, `artCurse`).
3. **`<id>.png`**: preview 556×534 da janela (Chrome headless), e confira a leitura a 150 px.
4. Passe o checklist de composição do ESTUDO_TCG (§9) e revise a pose pela linha de ação. Anote em
   `comp/<id>.md` (5–10 linhas): o instante mostrado, ponto focal, figuras e peças (`data-fig`), cores,
   transformações dos grupos, o que o acabamento deve cuidar.
5. Monte `comp/folha.png` com todos os previews do lote lado a lado (grande + 150 px).

## Etapa 2 — acabamento (agente Sonnet)
Para cada id do lote:
1. Escreva `tools/art/card_blender/design_<id>.py` seguindo `design_dragon.py` (o padrão): leia os `d` de
   `docs/arte_cartas/<lote>/comp/<id>.svg` com `svgpath.sample`, aplique a transformação do grupo, junte as
   peças de cada `data-fig` com `union_outline`, nanquim com `S.contour/S.line`, `S.occlude()`, aguadas com
   `S.wash` nas cores do `fill`, efeitos em `S.fx`.
2. Gere: `bash tools/art/card_blender/run.sh tools/art/card_blender/design_<id>.py <id> <sua_pasta_no_scratchpad>`
   (~1,5 min por carta; rode em segundo plano se fizer várias). Copie `<id>.png` para `docs/arte_cartas/<lote>/`.
3. Compare lado a lado com `comp/<id>.png` (pose igual, um contorno por figura, nenhuma linha cruzando o
   corpo). Monte `docs/arte_cartas/<lote>/comparacao.png` (composição | acabamento, uma linha por carta).
4. No fim: `python tools/art/card_blender/prancha.py docs/arte_cartas/<lote> <ids...>` → `prancha.png`.
   Olhe a prancha e corrija o que falhar no checklist da skill antes de entregar.

## Relatório final (as duas etapas) — curto, no máximo 15 linhas
- ids prontos; ids com problema e o motivo em uma linha;
- fichas criadas/usadas; tempo aproximado; o que mudou em relação ao briefing (se algo);
- task-observer: o controlador observa; se notar algo que valha registrar (falha da receita, regra que
  faltou), diga no relatório — não escreva em nenhum log.
