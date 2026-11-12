# rabid_rats — Ratos Raivosos (enxame, 6 ratos; Bando escala o dano)

- **Instante:** O bote: o raivoso salta do buraco na parede em diagonal para baixo-esquerda, boca escancarada, garras à frente.
- **Ponto focal:** Boca aberta com dentes e olho vermelho contra o halo verde-claro.
- **Figuras e peças:** `fig_raivoso` = pose_atacar, variação raivoso (magro, dorso eriçado, costelas). `raivoso_corpo`, `raivoso_cabeca`. Três silhuetas raivosas no buraco (olhos vermelhos apagados).
- **Cores:** Rato cinza escuro (#7d7873) sobre verde-oliva (família Praga); riscos de frenesi vermelhos e espuma branca atrás.
- **Transformações:** `fig_raivoso`: translate(196 148) rotate(-24) scale(-1.72 1.72) (espelhado: olha para a esquerda). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale); as peças estão em coordenadas locais da ficha. `#enxame` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Buraco rachado na parede = cenário. Pelo eriçado do dorso deve aparecer no contorno (serrilhado leve), não como linhas cruzando o corpo.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
