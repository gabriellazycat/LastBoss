# corrupt_piper — Flautista Corrompido (incomum; Bando por perto ataca mais rápido)

- **Instante:** Passo de dança no ar tocando a flauta de osso; a melodia (notas e ondas verdes) desce até a fila de ratos que dispara pela rua com linhas de velocidade.
- **Ponto focal:** Rosto cinza-esverdeado com o olho verde aceso e a flauta, recortados na lua cheia.
- **Figuras e peças:** `fig_flautista` = pose tocar_salto da ficha flautista: `flautista_corpo` (tronco, casaco esfarrapado, braços, mãos, pernas bicolores, sapatos de bico), `flautista_cabeca` (cabeça, cabelo, chapéu, pena), `flautista_flauta`. Ratos = silhuetas em `#enxame`.
- **Cores:** Casaco vermelho/mostarda (bicolor), chapéu ameixa, pena e notas verde-peste, sobre céu lilás→âmbar e portão roxo-escuro.
- **Transformações:** `fig_flautista`: translate(122 282) rotate(-8) scale(1.38). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale, 3 casas); as peças estão em coordenadas locais da ficha. `#bg`, `#enxame`, `#enxame_frente` e `#fx` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** A pena passa da borda de cima (ok); os pés entram na faixa da fita (ok, não importantes). Mãos finas e ossudas sobre a flauta (peças do corpo, silhueta separada da flauta). Listras da meia e remendo mostarda = inner.
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
