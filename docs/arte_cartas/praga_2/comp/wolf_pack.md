# wolf_pack — Matilha de Lobos (×3, Fera veloz; +dano por acúmulo de Peste no herói)

- **Instante:** Os três lobos em galope de suspensão seguindo o rastro de Peste (pegadas verdes fumegando) morro acima.
- **Ponto focal:** Cabeça do lobo líder (olho verde, boca aberta) dentro do sol baixo.
- **Figuras e peças:** `fig_lider`, `fig_lobo2`, `fig_lobo3` = pose correr, variação pestilento da ficha lobo: `<nome>_corpo` (tronco+pescoço+patas+cauda) e `<nome>_cabeca`. Os dois de trás menores (0,74 e 0,5) = profundidade.
- **Cores:** Lobo cinza-pardo (#857f6e) sobre céu creme-ouro, pinheiros lilás escuros; Peste verde (#a6c84a/#b8e05a) — cor do efeito diferente da criatura.
- **Transformações:** `fig_lobo3`: translate(104 112) rotate(-12) scale(0.5); `fig_lobo2`: translate(26 156) rotate(-14) scale(0.74); `fig_lider`: translate(92 232) rotate(-22) scale(1.32). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#enxame`, `#fx` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Três contornos separados (um por lobo). Os vapores verdes ficam atrás dos lobos; o sol é o halo do líder — reservar papel nele.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
