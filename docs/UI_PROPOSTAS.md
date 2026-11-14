# Propostas de UI (13/11/2026)

Pedido: a UI não condiz com o mundo em guache e com as cartas; 5 propostas, **maquetes primeiro**, tudo (HUD da run,
arena, ofertas, loja, menu). O que destoa, segundo ele: moldura dourada ornamentada, cores, fontes e o ar "limpo"
demais. A moldura e os efeitos das cartas ficam; só o efeito **Explosivo** é revisto (ele lembra de uma versão antiga
mais bonita).

Página: `docs/ui_propostas/escolher.html` (abrir pelo servidor `ui-propostas` de `.claude/launch.json`,
http://localhost:8766/docs/ui_propostas/escolher.html, ou direto o arquivo). Abas: as 5 telas e "Efeito Explosivo".

## As 5 direções

1. **Papel aquarelado** — papel com borda rasgada e mancha de aguada; Alegreya.
2. **Faixas de pincel** — sem moldura: texto claro sobre pinceladas largas cinza-petróleo; títulos em IM Fell SC.
3. **Caderno de esboço** — traço de lápis leve sobre papel claro; letra à mão (Patrick Hand), títulos em itálico.
4. **Língua da carta** — fio duplo, cantos cortados e faixas coloridas como as da carta; IM Fell SC + Alegreya.
5. **Recorte de papel** — papéis recortados nos tons de fundo das cartas (lilás, sálvia, ocre, rosa), em camadas.
6. **Mapa aberto** (pedida por ele depois de ver as 5: "parecer um papel, mas como o mapa aberto") — o pergaminho
   do mapa da rota: papel areia com manchas e borda queimada, linha dupla de tinta castanha, faixa com pontas
   cortadas, nós da rota em anel duplo, vermelho só no destaque, rosa dos ventos; IM Fell SC e itálico.
   Referência: `docs/ui_propostas/base/mapa.png`.

## Como foi feito

- Fotos reais do jogo sem a UI: modo de captura `--bare=1` (`main.gd`, `_bare_ui`) esconde a interface e mantém o
  mundo e as cartas. Bases em `docs/ui_propostas/base/` e `img/`.
- A UI nova é HTML/CSS por cima das fotos (componentes comuns + um tema por direção); bordas pintadas por filtros
  SVG só no fundo dos painéis. `escolher.html?solo=<1..5>&tela=<run|arena|oferta|loja|menu>` mostra uma maquete em
  1920x1080; `tools/art/render_ui_mockups.sh` fotografa as 25 com o Chrome sem janela (`fotos/`).
- Efeito Explosivo: 6 versões em `docs/ui_propostas/fx/` (hoje = molde de 12/11; variantes 0–4 de 10/11, recortadas
  das imagens antigas). As variantes 0–4 ainda existem no `CardFx`, mas o molde da pele Diário ignora o setting:
  voltar a uma delas é trabalho no molde, não só uma configuração.

## Limites das maquetes

- Nas ofertas e no menu as cartas e os papéis da mesa vêm recortados da foto com a UI de hoje.
- A loja usa nomes e preços ilustrativos; o mapa da rota é um desenho simplificado.
