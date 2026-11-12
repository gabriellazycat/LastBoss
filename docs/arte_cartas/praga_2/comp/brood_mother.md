# brood_mother — Mãe da Ninhada (pare 2 ratos a cada 4 s e solta 6 ao morrer)

- **Instante:** A mãe empinada no ninho, guinchando para defender a ninhada, e os filhotes já se espalhando pelo chão.
- **Ponto focal:** Cabeça de perfil com boca aberta e olho âmbar, dentro do halo morno.
- **Figuras e peças:** `fig_mae` = pose ameaca, variação ratazana gorda da ficha rato + peça `barriga_cheia` (data-fig `mae_corpo`): `mae_corpo`, `mae_cabeca`. Enxame: 8 filhotes (silhueta do rato comum).
- **Cores:** Rato pardo (#7a6f66) e barriga creme sobre parede lilás e luz ocre; ninho de palha com trapos roxo e vinho.
- **Transformações:** `fig_mae`: translate(130 226) rotate(6) scale(1.62). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#enxame`, `#fx` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** O ninho é o cenário (palha em traços soltos). A barriga cheia une ao corpo (contorno único). Moscas pequenas atrás, à direita da cabeça.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
