# bubonic_plague — Praga Bubônica (feitiço raro; toda mordida aplica Peste, dano por acúmulo no fim)

- **Instante:** O herói cambaleia coberto de bubões (acúmulos) acesos nas juntas, enquanto ratos mordem suas pernas; miasma verde e moscas atrás.
- **Ponto focal:** O tronco e o elmo do herói com os bubões roxos de borda verde, contra o miasma claro.
- **Figuras e peças:** `fig_heroi` = pose preso da ficha heroi (+ 6 bubões = inner do `heroi_corpo`). Ratos mordendo = silhuetas em `#enxame_frente` (na frente das pernas).
- **Cores:** Herói aço/azul, bubões roxo-escuro com borda verde-peste; porta marrom com a cruz vermelha da peste; céu verde-oliva.
- **Transformações:** `fig_heroi`: translate(182 286) rotate(8) scale(1.36). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#bg`, `#enxame`, `#enxame_frente` e `#fx` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Os pés passam da janela (ok). Bubões são manchas internas (sem contorno do corpo cruzando). Porta marcada = único cenário; miasma e moscas atrás do herói.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
