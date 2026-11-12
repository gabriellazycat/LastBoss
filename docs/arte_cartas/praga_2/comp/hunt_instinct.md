# hunt_instinct — Instinto de Caça (feitiço; Feras +60% de velocidade e roubam 20% da vida que causam)

- **Instante:** Do lado do vilão: o lobo de olhos vermelhos morde o braço do herói e a vida do herói volta em fitas vermelhas por cima do lobo.
- **Ponto focal:** Boca do lobo no braço do herói; as fitas vermelhas levam o olho de volta ao olho aceso do lobo.
- **Figuras e peças:** `fig_lobo` = pose atacar (paleta comum, olho vermelho) da ficha lobo: `lobo_corpo`, `lobo_cabeca`. `fig_heroi` = pose defesa, grande e cortado à direita (o alvo).
- **Cores:** Lobo cinza sobre floresta noturna azul-violeta; efeito vermelho vivo (#ff3040) — o protagonista do feitiço.
- **Transformações:** `fig_heroi`: translate(248 250) rotate(-8) scale(1.02); `fig_lobo`: translate(40 240) rotate(-8) scale(1.45). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#enxame`, `#fx` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** O efeito (fitas e gotas) fica atrás do lobo e nunca sobre o rosto dele. O herói em aço frio para separar do vermelho.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
