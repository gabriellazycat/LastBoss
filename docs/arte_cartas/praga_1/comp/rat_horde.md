# rat_horde — Horda de Ratos (enxame, 8 ratos rápidos e frágeis)

- **Instante:** O salto: o rato da frente sai do túnel e pula na câmera, garras abertas, boca no auge do chiado.
- **Ponto focal:** Olhos em brasa do `saltador` contra o brilho creme da boca do túnel (maior contraste da carta).
- **Figuras e peças:** `fig_saltador` = pose_saltar da ficha (`saltador_corpo`: tronco, 4 patas, cauda, garras; `saltador_cabeca`: cabeça, orelhas). `fig_corredor` = pose_correr, cortado pela moldura embaixo à esquerda. Enxame: 12 silhuetas (pose_correr unida) saindo do túnel, mais claras ao fundo.
- **Cores:** Rato cinza (#8b8580) sobre parede marrom e luz âmbar do túnel; linhas de velocidade creme atrás.
- **Transformações:** `fig_saltador`: translate(182 112) rotate(-14) scale(0.8). `fig_corredor`: translate(18 262) rotate(-4) scale(1.02). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale); as peças estão em coordenadas locais da ficha. `#enxame` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Túnel = único cenário (anel de tijolos escuro, boca clara). Enxame só com aguada escura e traço leve, sem olhos. O corredor fica mais escuro/menos detalhado que o saltador.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
