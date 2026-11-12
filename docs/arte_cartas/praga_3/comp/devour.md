# devour — Devorar (feitiço raro; sacrifica ratos: a Fera cura e causa mais dano)

- **Instante:** A Fera no altar com um rato preso pela garupa entre os dentes; as almas dos outros ratos sacrificados (vermelho translúcido) são sugadas para o peito dela; cruzes verdes de cura sobem.
- **Ponto focal:** Cabeça da Fera (olho vermelho, boca aberta) com o rato pendurado, recortada no sol.
- **Figuras e peças:** `fig_fera` = pose ameaça da ficha lobo, variação Besta Alfa (`fera_corpo`, `fera_cabeca`); `fig_rato` = pose correr da ficha rato, de cabeça para baixo, atrás da cabeça da fera (`rato_corpo`, `rato_cabeca`). Almas = silhuetas translúcidas em `#enxame`.
- **Cores:** Fera carvão e rato cinza-claro sobre céu vermelho→laranja; aura vermelha, cura verde.
- **Transformações:** `fig_rato`: translate(172.839 126.932) rotate(98) scale(0.74); `fig_fera`: translate(34 198) rotate(-8) scale(1.42). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#bg`, `#enxame`, `#enxame_frente` e `#fx` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** O rato é desenhado antes da fera (a garupa some atrás dos dentes). Altar com mancha de sangue e ossos = cenário. Aura vermelha atrás, sem cobrir o rosto.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
