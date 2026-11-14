# Interface "Mapa aberto" (13/11/2026)

Escolhas do designer depois das maquetes (docs/UI_PROPOSTAS.md, página docs/ui_propostas/escolher.html):
direção 6 · Mapa aberto em tudo, **menu estilo A** (o menu é o mapa, sobre a mesa 3D), **loja estilo B** (mapa da
feira com a ficha da carta selecionada), **coleção estilo A** (pactos como lugares, leitura da carta pensada para quem
joga), o resto do jogo no mesmo estilo (inclusive vitória/derrota e a revelação das cartas liberadas) e o
**Explosivo** com o pavio aceso em volta da borda irregular e efeitos que crescem por nível.

## Como está feito

- **Pele 7 "Mapa aberto"** (`Settings "look_hud"` 7, padrão; `ART_REV` 5 leva a quem já tinha configuração salva).
  `UiSkins.mapa()`; `UiSkins.diario()` também vale nela, então todo o código da pele Diário roda com o **kit do mapa**:
  `assets/ui/kit_mapa/` (mesmos nomes, tamanhos e margens de 9-slice do kit do Diário), gerado por
  `tools/art/ui_kit/make_map_kit.py`: papel areia com manchas e borda queimada, contorno irregular, moldura de linha
  dupla de tinta tremida à mão, botões com a linha de dentro vermelha no mouse, faixas com as pontas em V por tipo.
  `UiParch.kit_dir()` escolhe a pasta. Barras com trilho de papel e contorno de tinta. O Diário segue em
  Configurações → Visual (a lista agora tem os nomes na ordem certa; antes "Covil" escolhia o Diário).
- **Arte das telas especiais** tirada das maquetes aprovadas por `tools/art/ui_kit/export_map_art.py`
  (servidor `ui-propostas` na porta 8766): `assets/ui/map/bg_<tela>.png` (só o fundo desenhado, recortado no papel
  + 24 px) e os SVG dos lugares (`node_*`, `node_*_hot` com anel vermelho) e desenhos (`icon_*`).
- **Menu (A):** `game/map_menu.gd` (MapMenu). Nova run = covil, Coleção = biblioteca, Compêndio = torre,
  Configurações = moinho, Sair = barco; Continuar run = tenda no começo da estrada vermelha. São Buttons de verdade
  (foco por teclado/controle, setas andam entre os lugares). Os papéis do menu na mesa somem no modo mapa e não pegam
  clique; o mapa sobe da mesa como as outras telas.
- **HUD:** bosquinho apoiado na moldura do painel do herói, rato sobre a moldura do corpo do chefe.
- **Vitória/derrota:** o covil desenhado no alto (anel vermelho na vitória), morro e bosque na moldura de baixo.
- **Loja (B)** e **Coleção (A)**: ver o fim deste arquivo (feitas em paralelo).
- **Explosivo:** `tools/art/card_mold/overlays.js` (borda da variação 1 + pavio trançado), `game/card_mold.gd`
  (`_explosive_fx`: faísca que corre o pavio; nível 2 estouros pequenos; nível 3 chamas no pé e estouro grande),
  `game/ui/card_fuse_flames.gdshader`. Fotos: `docs/explosivo/prancha.png`.

## Fotos

`docs/ui_mapa/` (v1 = primeiro passe do kit, v2 = telas depois dos ajustes, menu/, hud/, loja/, colecao/).

## Loja (B) e Coleção (A)

- **Loja:** `game/shop_ledger.gd` (modo `fair` quando `UiSkins.mapa()`; a lógica de compra é a mesma). Barracas com a
  arte da carta em anel duplo, tenda e preço numa faixa; a escolhida ganha anel vermelho e uma ficha com a descrição
  completa (mesmos textos e dicas de palavra-chave da loja antiga) e "Comprar · N"; serviços com ícone. Primeiro
  clique escolhe, segundo compra; teclado e controle andam pelo item mais próximo. Fotos: `docs/ui_mapa/loja/`.
- **Coleção:** `game/collection.gd` + `game/card_reader.gd` (novo). Os pactos são lugares do mapa; a grade mostra as
  cartas do pacto (bloqueadas em cinza com "???"). Clique/Enter abre o **leitor**: a carta real em ~420 px e, ao
  lado, números (custo, vida, dano, ataque, velocidade), "O que faz", cada palavra-chave explicada, "Como evolui" e,
  nas bloqueadas, "Como liberar"; ←/→ passam de carta, Esc fecha. Fotos: `docs/ui_mapa/colecao/`.

## Verificação (14/11)

- `tests.tscn`: 574 ok, 0 falhas. `--uitest=1`: resultado OK (inclui os 13 passos da loja). `--menutest=1`: resultado
  OK (o passo do papel da mesa virou "Lugar do mapa abre a tela" no modo mapa).
- Fotos de todas as telas: `docs/ui_mapa/final/` (01 menu … 17 revelação das cartas).

## Pendências conhecidas

- Loja: o tracejado até a ficha cruza outras barracas quando a escolhida fica longe; o aviso de compra encosta na
  borda de baixo do papel.
- Coleção: em cartas de texto longo, "Como evolui" fica abaixo da dobra (rola).
- Explosivo nível 3: o clarão do estouro grande às vezes deixa a carta clara demais; as faíscas soltas ficam para trás
  quando a carta se move (não visto dentro da partida).
- Escolha do vilão e do grupo: só ganharam o papel e a moldura do mapa (sem desenhos próprios).
