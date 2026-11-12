# alpha_beast — Besta Alfa (lendária; +dano por bicho de Bando e por Peste; ao entrar solta o Chamado do Bando)

- **Instante:** O Chamado: a Besta uiva no alto do rochedo, anéis dourados saem do focinho e o bando (lobos, ratos, morcegos) corre para ela.
- **Ponto focal:** Cabeça uivando (olho vermelho, boca aberta) no centro dos anéis dourados.
- **Figuras e peças:** `fig_alfa` = pose uivar, variação Besta Alfa da ficha lobo (×1,35, juba, espinhos de osso, cicatriz): `alfa_corpo` (inclui os espinhos) e `alfa_cabeca`. Enxame: 4 lobos, 3 ratos, 5 morcegos (silhuetas das fichas).
- **Cores:** Carvão (#4e4a4c) sobre céu de brasa laranja (valor oposto); anéis #f6c840 (mesma cor do Chamado do Bando do lote praga_1).
- **Transformações:** `fig_alfa`: translate(152 224) rotate(-6) scale(1.24). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#enxame`, `#fx` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Câmera baixa: o rochedo é o cenário. Os anéis são o efeito (atrás da figura). Espinhos de osso claros na silhueta do corpo. Ratos na faixa da fita só como textura.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
