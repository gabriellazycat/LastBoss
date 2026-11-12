# rat_tide — Maré de Ratos (rara; 30 ratos de uma vez)

- **Instante:** A crista: a onda de ratos quebra sobre o herói e o rato da frente mergulha dela em diagonal.
- **Ponto focal:** Cabeça do rato que mergulha, contra o céu claro.
- **Figuras e peças:** `fig_mergulho` = pose_correr espelhada (`mergulho_corpo`, `mergulho_cabeca`). `fig_heroi` = pose_defesa, minúsculo (escala). `#enxame`: massa da onda (`enxame_onda`) + ~30 silhuetas na superfície e na crista.
- **Cores:** Onda cinza-parda escura sobre céu creme/lilás; herói azul pequeno embaixo à esquerda.
- **Transformações:** `fig_mergulho`: translate(132 104) rotate(-38) scale(-1.2 1.2). `fig_heroi`: translate(52 238) scale(0.36). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale); as peças estão em coordenadas locais da ficha. `#enxame` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** A onda é textura: aguada escura com silhuetas de ratos visíveis na borda da crista; só o mergulho tem olho aceso. Muro baixo à esquerda é apoio, não compete.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
