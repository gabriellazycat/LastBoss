# war_boar — Javali de Guerra (Fera; ao acertar empurra o herói 5 m e o atordoa 1 s)

- **Instante:** O golpe: as presas sobem e arremessam o herói para trás; estrelas de tontura no elmo, estrela de choque no ponto de impacto.
- **Ponto focal:** Ponto de impacto entre a presa e o herói (estrela clara) e o olho laranja do javali logo ao lado.
- **Figuras e peças:** `fig_javali` = pose lancar da ficha javali, espelhada (escala −1,7): `javali_corpo`, `javali_cabeca`, `javali_armadura` (barda, cilha, testeira com chifre). `fig_heroi` = pose defesa, girada −40° (caindo para trás).
- **Cores:** Javali marrom-escuro (#5e4636) com ferro (#8a8e96) sobre céu lilás-creme; poeira ocre; choque e estrelas amarelos.
- **Transformações:** `fig_heroi`: translate(74 140) rotate(-40) scale(0.46); `fig_javali`: translate(252 246) rotate(-2) scale(-1.7 1.7). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#enxame`, `#fx` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Paliçada quebrada atrás do herói = único cenário. A armadura tem contorno próprio por cima do corpo. Poeira nos cascos e linhas de velocidade atrás da garupa, não sobre a cabeça.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
