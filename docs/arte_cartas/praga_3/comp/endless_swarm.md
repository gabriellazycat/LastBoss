# endless_swarm — Enxame Sem Fim (feitiço lendário; invoca ratos e o Bando renasce uma vez)

- **Instante:** Um rato renasce dos próprios ossos (chamas verdes, eco fantasma) e salta para fora de um anel sem fim de ratos que corre em volta do herói cercado.
- **Ponto focal:** Cabeça do rato da frente (olho vermelho, boca aberta) sobre o brilho verde do anel.
- **Figuras e peças:** `fig_rato` = pose atacar (raivoso) da ficha rato; `fig_heroi` = pose guarda da ficha heroi, pequeno no meio do anel. Anel = silhuetas em `#enxame` (escorço nas laterais); eco verde do rato = silhueta translúcida em `#enxame`.
- **Cores:** Rato cinza e herói aço/azul sobre noite violeta; anel e chamas verde-peste.
- **Transformações:** `fig_heroi`: translate(176 186) scale(0.5); `fig_rato`: translate(60 232) rotate(-26) scale(1.2). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#bg`, `#enxame`, `#enxame_frente` e `#fx` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Ossos e chamas no chão à esquerda ficam atrás do rato (fx). O anel é textura escura com poucos olhos verdes; a trilha verde sob o anel é aguada. Linhas internas mínimas nos ratos do anel.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
