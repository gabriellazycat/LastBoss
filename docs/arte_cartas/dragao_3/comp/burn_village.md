# burn_village — Incêndio (rota: o local marcado pega Fogo quando o herói chega)

- **Instante:** o herói chega correndo pela estrada e, nesse momento, a runa do vilão no chão e as casas da aldeia explodem em fogo à frente dele.
- **Ponto focal:** a runa em brasa na estrada (creme e laranja) com a coluna de fogo maior, no centro.
- **Linha de ação:** a do herói visto de costas (pose nova **correr_costas**, hero3.py): perna de trás chutada, capa esvoaçando, espada erguida. O corpo inclina para a aldeia. A estrada leva o olho até a runa.
- **Figura:** `fig_heroi` `translate(84 292) rotate(-8) scale(0.86)`, vista de costas (`back_view` do hero2: sem viseira, capa por cima).
- **data-fig:** `heroi_corpo`, `heroi_cabeca`, `heroi_capa`, `heroi_espada`.
- **Cenário:** a aldeia (2 casas de palha e uma ao fundo), morros e a estrada.
- **Cores:** céu de crepúsculo roxo a laranja, palha `#c8a050`, herói aço e azul em contraluz.
- **Acabamento:** o fogo é fx e fica atrás do herói. A capa ocupa muito da silhueta, então a aguada dela deve ser mais escura para o corpo de aço destacar. Os pés passam um pouco da fita (y > 250); tudo bem, são só as pernas.
