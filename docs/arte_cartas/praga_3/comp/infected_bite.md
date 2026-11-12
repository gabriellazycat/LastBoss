# infected_bite — Mordida Infectada (feitiço; mordidas do Bando aplicam Peste extra)

- **Instante:** O dente fecha no joelho do herói e a Peste explode no ponto da mordida (clarão verde, raios, bolhas subindo); o herói recua protegendo o rosto.
- **Ponto focal:** A boca do rato no joelho, sobre o clarão verde.
- **Figuras e peças:** `fig_heroi` = pose defesa da ficha heroi (+ manchas e veias verdes na perna = inner do `heroi_corpo`); `fig_rato` = pose atacar (raivoso) da ficha rato, boca alinhada ao joelho.
- **Cores:** Rato cinza e herói aço/azul sobre noite azul-acinzentada; efeito verde-peste.
- **Transformações:** `fig_heroi`: translate(198 242) rotate(-4); `fig_rato`: translate(47.864 271.278) rotate(-16) scale(1.42). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#bg`, `#enxame`, `#enxame_frente` e `#fx` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** O rato fica na frente da perna do herói (desenhado depois). Clarão e raios atrás das duas figuras. Árvore morta à esquerda = único cenário.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
