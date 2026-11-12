# werewolf — Lobisomem (rara; mais rápido quanto menor a vida do herói)

- **Instante:** O salto final sobre o herói já acuado: o lobisomem no ar, garra de perto estendida, a outra armada no alto, contra a lua cheia; o herói pequeno se defende.
- **Ponto focal:** Cabeça rosnando (olho amarelo) recortada na lua.
- **Figuras e peças:** `fig_lobisomem` = pose saltar da ficha lobisomem: `lobisomem_corpo` (tronco, juba, braços, mãos, pernas, calça, cauda) e `lobisomem_cabeca` (cabeça do lobo). `fig_heroi` = pose defesa (pequeno, à direita).
- **Cores:** Pelo pardo (#6e5a4c), calça azul rasgada, sobre noite azul e lua creme (temperatura oposta).
- **Transformações:** `fig_heroi`: translate(262 246) rotate(10) scale(0.5); `fig_lobisomem`: translate(92 236) rotate(8) scale(1.42). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#enxame`, `#fx` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** A garra alta passa da borda de cima (ok). Linhas de velocidade e folhas atrás, embaixo à esquerda. A calça faz parte da silhueta do corpo (contorno único).
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
