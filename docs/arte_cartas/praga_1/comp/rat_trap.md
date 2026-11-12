# rat_trap — Ratoeira Viva (armadilha; herói Preso, saltam ratos)

- **Instante:** O estalo: a barra dentada fecha no tornozelo do herói e um rato salta da ratoeira contra ele.
- **Ponto focal:** Boca do rato e a barra de ferro no pé do herói (o herói fica em contraluz, como alvo).
- **Figuras e peças:** `fig_ratoeira` (`ratoeira_base`: tábua; `ratoeira_barra`: barra, dentes, mola). `fig_heroi` = pose_preso da ficha do herói (`heroi_corpo`, `heroi_cabeca`, `heroi_espada`, `heroi_capa`). `fig_rato` = pose_atacar. Uma silhueta de rato atrás à direita.
- **Cores:** Herói aço/tabardo azul em contraluz contra halo creme; fundo azul-lilás de mata; tábua ocre; rato cinza.
- **Transformações:** `fig_heroi`: translate(196 230) scale(0.86). `fig_rato`: translate(52 246) rotate(-40) scale(1.32). `fig_ratoeira`: sem transform. Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale); as peças estão em coordenadas locais da ficha. `#enxame` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Herói em contraluz: aguada mais escura que o halo, sem detalhe. A barra e os dentes precisam ler (ferro escuro sobre a tábua clara).
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
