# bat_cloud — Nuvem de Morcegos (enxame voador ×5; passa por cima de bloqueios)

- **Instante:** A nuvem sobrevoa a muralha de estacas (o bloqueio que não a para) e o líder mergulha planando para a câmera, garras à frente.
- **Ponto focal:** Cabeça do morcego líder (olhos vermelhos, presas) cortando o disco da lua.
- **Figuras e peças:** `fig_morcego` = pose atacar (asa de longe em escorço ×0,78): `morcego_corpo`, `morcego_cabeca`, `morcego_asa`, `morcego_asa_l`. Enxame: 34 silhuetas das poses voar_cima/voar_baixo/atacar em arco por cima da muralha, algumas com olhos acesos.
- **Cores:** Morcego marrom/vinho sobre noite azul-acinzentada e lua creme; muralha cinza-lilás com estacas escuras.
- **Transformações:** `fig_morcego`: translate(196 150) rotate(-24) scale(2.45). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#enxame`, `#fx` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** A asa direita sai pela moldura (de propósito). O enxame é textura: mais escuro e sem detalhe; manter o arco legível (de baixo-esquerda, por cima da muralha, até cima-direita).
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
