# kobold_scavengers — Kobolds Catadores (enxame, 1 de Ouro por golpe)

- **Instante:** o enxame cerca o herói; um golpe arranca moedas da armadura (estrela de impacto no peito). O catador da frente foge com a moeda no punho e o saco nas costas.
- **Ponto focal:** a cabeça do kobold grande (olho amarelo, boca aberta) com a moeda ao lado. Depois o impacto dourado no herói.
- **Linha de ação:** a do kobold, pose `correr` da ficha espelhada; o corpo desce em diagonal para baixo-esquerda.
- **Figuras:** `fig_kobold` `translate(118 270) rotate(-6) scale(-2.3 2.3)`, ficha `kobold.svg`, pose correr com `open=True` e `wf=(26,-36)`; moeda inner em `kobold_corpo`. `fig_heroi` `translate(222 236) scale(0.74)` usa a pose nova **golpe_baixo** (hero3.py): base larga, espada varrendo os pés.
- **data-fig:** `kobold_corpo`, `kobold_cabeca`, `kobold_saco`; `heroi_corpo/cabeca/capa/espada`. O enxame (5 silhuetas unidas da ficha, `#7a3a22`) fica em `#enxame` e um kobold agarrado à perna do herói em `#enxame_frente`.
- **Cenário:** barranco com a toca dos kobolds (fundo, esquerda) e a estrada.
- **Cores:** kobold ferrugem `#b8643a` contra céu verde-azulado frio. As moedas são o efeito.
- **Acabamento:** enxame com traço fino e aguada escura, sem detalhe. O saco cobre parte do pescoço do kobold, então o contorno do saco é separado (`kobold_saco`).
