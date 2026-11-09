# Interface "Diário" (09/11/2026)

A interface inteira virou papel: cartas de papel sujo com fita colorida no topo, desenhos a nanquim, botões de
fita crepe e o menu numa mesa 3D do Lorde. Estudos que levaram a isso: `docs/variacoes/cartas/` (`cartas.html`,
`diario.html`, `fitas.html`, `ui.html`, `mesa.html`).

## Decisões (rodada de perguntas de 09/11)

| Ponto | Decisão |
|---|---|
| Ordem | Tudo de uma vez |
| Desenhos das 30 cartas | Vetor detalhado (não havia chave de API de imagem configurada) |
| Custo | Número dentro de uma mancha de sangue |
| Cláusulas dos Pactos | Só as regras reais do jogo |
| Menu | Cena 3D de verdade (mesa, velas, faca, caveira), no lugar do covil com o Lorde |
| Cor da fita por tipo | Monstro vermelho, Enxame laranja, Feitiço roxo, Estrutura amarelo de obra, Covil verde-musgo, Rota azul, Finalização preta com letra dourada |
| Sujeira | Cartas imundas, HUD mais limpo |

## Como funciona

- **Pele nova** `game/ui_diario.gd` (Settings `look_hud` 6, a padrão). O `UiKit` manda tudo para ela quando ativa:
  painéis, rótulos, títulos, barras, selos, cartas, tema. As peles antigas continuam em Configurações > Visual.
- **Shader de papel** `game/ui/paper.gdshader`: papel com borda rasgada, grão, manchas e marca de caneca; fita crepe;
  folha pautada; caixa a lápis; carta com a faixa de fita; etiqueta; contrato. Mesmo truque de textura-marcador
  da pele Covil.
- **Texto vira tinta sozinho**: qualquer Label/RichTextLabel dentro de um papel tem a cor clara trocada por tinta
  escura do mesmo matiz (`UiDiario.on_node_added`). Texto solto sobre o mundo continua claro.
- **Desenhos das cartas**: `tools/art/sketches.html` (SVG) → `python tools/art/render_sketches.py` →
  `assets/cards/<id>.png` (35 imagens: as 30 cartas, os 3 Pactos, a caveira do título e o herói do cartaz).
  Para mudar um desenho, edite o SVG e rode o script de novo.
- **Mesa do menu** `game/desk_scene.gd`: tampo de madeira procedural (`game/art/desk_wood.gdshader`), velas com
  luz tremendo, faca fincada num cartaz de "procura-se", caveira, tinteiro, moedas, cartas soltas e um papel para
  cada tela. Clicar num papel da mesa abre a tela; a tela sobe do papel até a frente e a anterior volta para a mesa.
- **Telas**: título numa folha presa com fita; Pactos como contratos (cláusulas, assinatura em sangue, lacre);
  grupo de heróis como cartazes de "procura-se"; oferta com título em fita vermelha, rótulos em fita crepe e o
  efeito da melhoria num bilhete; pausa, coleção, compêndio, configurações e fim de run em papel.
- **Fontes novas** (Google Fonts, licenças em `assets/fonts/`): Special Elite, Permanent Marker, Patrick Hand,
  IM Fell English SC e IM Fell English Italic. As que não têm → e ★ caem na Alegreya Sans.
- **Configuração salva**: `ART_REV` subiu para 2; quem já tinha configuração recebe a pele Diário uma vez.

## Verificação

- `tests.tscn`: 0 falhas.
- `--menutest`: OK em 3 de 3 execuções, com um passo novo: clicar no papel da mesa abre a tela.
- `--tiptest`: OK.
- `--uitest`: todos os passos OK, menos "arrastar e soltar", que falha igual com a pele antiga
  (já registrado em `docs/REVISAO_VISUAL.md`).
- Capturas em 1280x720 e em tela cheia (1366x768 neste monitor), em português e inglês.

## Assumido sem perguntar (revisar)

- Na pele Diário, o botão dos Pactos diz "Assinar este Pacto" (chave nova `UI_PACT_SIGN`); o teste de menu procura
  esse texto.
- A string `UI_ST_you` não existia (aparecia crua no fim de run); entrou como "Heróis derrubados".
- O cartaz de "procura-se" da mesa diz "recompensa: o reino".
- A raridade da carta não aparece mais na carta (só a cor da fita mostra o tipo).
