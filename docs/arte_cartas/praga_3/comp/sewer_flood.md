# sewer_flood — Esgoto Transbordante (estrutura; solta um rato por segundo)

- **Instante:** A saída de esgoto arrebentou: a torrente verde desce em diagonal cuspindo ratos, e um rato salta da água direto para a câmera.
- **Ponto focal:** Cabeça do rato (olhos vermelhos, dentes) contra o muro claro, logo à direita da boca escura do cano.
- **Figuras e peças:** `fig_rato` = pose saltar da ficha rato (escorço frontal): `rato_corpo`, `rato_cabeca`. Ratos na torrente = silhuetas em `#enxame`.
- **Cores:** Rato cinza sobre muro de pedra bege e água verde-esgoto; boca do cano preta como contraste máximo atrás da cabeça.
- **Transformações:** `fig_rato`: translate(200 132) rotate(14) scale(0.62). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#bg`, `#enxame`, `#enxame_frente` e `#fx` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** A estrutura (boca de pedra + grade torta) é o cenário em destaque; a água é aguada com espuma clara em pinceladas diagonais. Gotas e linhas de velocidade atrás do rato.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
