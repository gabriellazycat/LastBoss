# Arte unificada (13/11/2026)

Pedido: o mundo 3D, as cartas e a UI pareciam três jogos diferentes.

## Tentativa: filtro "guache no papel" — REMOVIDO

Um filtro de tela sobre o mundo 3D (pinceladas Kuwahara, traço pela profundidade, cor das cartas, grão de papel,
vinheta), calibrado nas cartas novas da Rainha da Peste, mais ajustes que dependiam dele (herói aço-azulado, menos
brilho de borda, efeitos e água na paleta, ato 2 menos laranja). Ele viu os prints e achou que **deixou a tela
poluída**; foi tirado por inteiro no mesmo dia, junto com os ajustes ligados a ele.
Fotos de como ficou: `docs/arte_unificada/depois/`, `comparar_*.png` (antes × com filtro).

## O que ficou

| Onde | O quê |
|---|---|
| `game/world_view.gd` | Figuras maiores na tela, só no desenho: monstros ×1,2 (`FIG_SCALE`), herói e seguidores 1,3 → 1,55 (`HERO_SCALE`). Raio e colisão não mudam. |

Fotos sem o filtro: `docs/arte_unificada/sem_filtro/`.

## Aprendizado

Textura por cima da tela inteira (grão, pincelada, contorno em toda a grama) polui a leitura, mesmo com a paleta
certa. Se voltar a unificar, ir por caminhos que não somam ruído: cor dos materiais e da luz por ato, menos
saturação nos modelos, sem camada de textura sobre o jogo.
