# bat_nest — Ninho de Morcegos (estrutura; gera 1 morcego a cada 3 s por 15 s)

- **Instante:** A revoada saindo: do oco da árvore morta os morcegos saem em fila, crescendo até o morcego grande que abre as asas para a câmera; outros dormem pendurados no galho.
- **Ponto focal:** Rosto do morcego grande (olhos vermelhos, boca aberta) contra o céu laranja; o oco escuro com olhos âmbar é o segundo foco (a construção).
- **Figuras e peças:** `fig_morcego` = pose voar_cima da ficha morcego: `morcego_corpo`, `morcego_cabeca`, `morcego_asa`, `morcego_asa_l` (cada asa = 1 silhueta; braço e dedos = inner). Enxame: 8 morcegos em voo saindo do oco + 4 pendurados (pose pendurado).
- **Cores:** Morcego marrom (#5c4436) e membrana vinho (#7a5458) sobre céu de crepúsculo violeta→laranja; árvore #4e3a3a; olhos no oco âmbar.
- **Transformações:** `fig_morcego`: translate(234 202) rotate(-10) scale(2). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#enxame`, `#fx` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** A árvore é o cenário e a estrutura: tronco inclinado e galho longo em cima (contorno próprio, aguada escura com luz à esquerda). Os morcegos do oco estão sobre o preto: dar borda clara (rim) ou deixá-los mais quentes para não sumirem.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
