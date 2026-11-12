# rat_burrow — Toca de Ratos (estrutura; solta um rato a cada X s)

- **Instante:** O rato dispara para fora da toca em salto diagonal, cauda ainda entrando no buraco; outros saem e correm.
- **Ponto focal:** Cabeça do rato contra o céu dourado, logo acima da borda do monte.
- **Figuras e peças:** `fig_rato` = pose_correr (`rato_corpo`, `rato_cabeca`). Enxame: um rato empinado na boca da toca e três correndo no chão.
- **Cores:** Rato cinza sobre céu ocre/lilás; monte de terra marrom com buraco preto; torrões e raios claros saindo do buraco.
- **Transformações:** `fig_rato`: translate(169.842 216.539) rotate(-34) scale(1.38) (garupa encostada na boca da toca). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale); as peças estão em coordenadas locais da ficha. `#enxame` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** A construção (monte + buraco + tábuas + raízes) está em destaque e ocupa o terço de baixo; a fita cobre só a base do monte.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
