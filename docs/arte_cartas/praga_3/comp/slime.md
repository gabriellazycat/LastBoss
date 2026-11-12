# slime — Slime (incomum; divide-se ao morrer, 3 gerações)

- **Instante:** O golpe acabou de cortar o slime: a massa principal se inclina para a frente e o broto (geração seguinte) se solta para cima-direita, ainda preso por um fio de gosma; slimezinhos da 3ª geração já no chão.
- **Ponto focal:** Rosto da massa principal (olhos amarelos, boca de dentes) e o broto logo acima, recortados contra a boca escura do túnel.
- **Figuras e peças:** `fig_slime` = pose dividir da ficha slime: `slime_corpo` (massa, pseudópode de trás, poça, fio de gosma) e `slime_broto` (o broto com rosto próprio). Rosto, crânio de rato, bolhas, sombra e brilho = inner. 3ª geração = silhuetas em `#enxame`.
- **Cores:** Verde-peste claro (#9cc23e) sobre túnel azul-ardósia escuro (valor e temperatura opostos); canal de esgoto verde-musgo embaixo.
- **Transformações:** `fig_slime`: translate(100 226) rotate(-14) scale(1.74). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#bg`, `#enxame`, `#enxame_frente` e `#fx` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Dois contornos (corpo e broto) que se tocam no fio: não unir. O arco branco do corte e os respingos ficam atrás (fx). O crânio boiando é aguada clara translúcida, sem contorno forte.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
