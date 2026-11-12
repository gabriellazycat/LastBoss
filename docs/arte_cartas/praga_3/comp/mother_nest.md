# mother_nest — Ninho-Mãe (feitiço raro; ninhos por perto produzem em dobro)

- **Instante:** O ninho pulsa (dois conjuntos de anéis) e dois ratos saltam ao mesmo tempo da mesma toca, em V; filhotes saem pelas tocas laterais.
- **Ponto focal:** As duas cabeças de rato abrindo o V, com a toca acesa entre elas.
- **Figuras e peças:** `fig_rato_esq` e `fig_rato_dir` = pose atacar da ficha rato (o da esquerda espelhado): `rato_*_corpo`, `rato_*_cabeca`. Filhotes = silhuetas em `#enxame`.
- **Cores:** Ratos cinza sobre céu lilás→âmbar; ninho de palha ocre com trapos; luz verde-amarela na toca.
- **Transformações:** `fig_rato_esq`: translate(110 186) rotate(46) scale(-1.06 1.06); `fig_rato_dir`: translate(190 186) rotate(-46) scale(1.06). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#bg`, `#enxame`, `#enxame_frente` e `#fx` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Os rabos se cruzam sobre a toca: cada rato é uma silhueta própria (não unir). A linha de ação está no rato da direita; o da esquerda é o espelho.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
