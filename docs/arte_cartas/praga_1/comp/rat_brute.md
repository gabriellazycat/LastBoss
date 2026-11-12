# rat_brute — Ratazana (gorda e resistente; mordida aplica Peste)

- **Instante:** A mordida pesada: a ratazana avança com a boca aberta pingando baba verde.
- **Ponto focal:** Boca aberta e olho âmbar contra o fundo lilás claro.
- **Figuras e peças:** `fig_ratazana` = pose_atacar, variação gorda (larguras ×1,5, cabeça ×1,12). `ratazana_corpo`, `ratazana_cabeca`.
- **Cores:** Cinza-pardo (#7a6f66) sobre lilás; peste verde (#7fae3a/#9ac850): lodo do cano, bolhas e moscas atrás, baba sob a mandíbula.
- **Transformações:** `fig_ratazana`: translate(108 222) rotate(-15) scale(1.72). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale); as peças estão em coordenadas locais da ficha. `#enxame` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Cano de esgoto com lodo = cenário. Baba sai da mandíbula para baixo (nunca sobre o rosto). Peso: barriga baixa, patas curtas e grossas.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
