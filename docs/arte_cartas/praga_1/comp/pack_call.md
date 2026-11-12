# pack_call — Chamado do Bando (feitiço; Bando corre +50% e causa +dano)

- **Instante:** O chamado ecoa (arcos dourados) e o bando dispara em velocidade contra o herói no horizonte.
- **Ponto focal:** Cabeça do rato líder; o herói pequeno em contraluz contra o sol é o alvo.
- **Figuras e peças:** `fig_lider` = pose_correr (`lider_corpo`, `lider_cabeca`). `fig_heroi` = pose_defesa (pequeno). Enxame: 7 silhuetas com rastros de velocidade, diminuindo até o herói.
- **Cores:** Rato cinza sobre oliva; horizonte ouro; arcos do chamado #f0c040; rastros creme.
- **Transformações:** `fig_lider`: translate(102 214) rotate(-22) scale(1.32). `fig_heroi`: translate(214 120) scale(0.42). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale); as peças estão em coordenadas locais da ficha. `#enxame` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Efeito (arcos + rastros) é o protagonista do feitiço, mas fica atrás do líder. Estrada converge para o herói (único cenário).
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
