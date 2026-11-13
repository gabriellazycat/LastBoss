# Mundo pintado em guache (13/11/2026)

Pedido: o mundo 3D (modelos e tudo, mesa incluída) pintado como as cartas novas, **sem filtro por cima da tela**
(o filtro anterior "parecia um noise preto em cima de tudo"). Paleta das cartas com cor própria por ato. 9 variações
para ele escolher.

Pranchas: `docs/mundo_pintado/comparar_run.jpg`, `comparar_arena.jpg`, `comparar_mesa.jpg` (fotos em `fotos/`).
**Escolhida em 13/11: S1 · Guache chapado**, padrão do jogo (Settings "paint_look" 1; `ART_REV` 4 leva a escolha
uma vez a quem já tinha configuração salva). As outras continuam em Configurações → Vídeo → "Mundo pintado (guache)".
Página de escolha: `docs/mundo_pintado/escolher.html`.

## Como funciona

`game/art/paint.gdshaderinc`, incluído pelos shaders do mundo: modelos (look5), chão (ground_ror), estrada, grama,
cenário (prop), tampo da mesa (desk_wood) e objetos da mesa (paint_std, no lugar do StandardMaterial3D).
Variáveis globais de shader (project.godot) escolhem a variação na hora, sem recompilar (`game/art/paint_look.gd`).

- **Paleta das cartas** (todas): menos saturação, verde → sálvia azulada, azul vivo → petróleo, pretos levantados.
- **S1–S3, luz pintada:** S1 guache chapado (luz e sombra em duas manchas com borda de pincel), S2 aguado (passagem
  larga com borda molhada), S3 pincel largo (três valores com bordas arrastadas). Pinceladas procedurais em manchas
  de pincel chato (S1/S3) ou lavagem mole (S2).
- **T1–T3, folhas de pincel da IA** (assets/textures/paint/T<n>): dabs largos, aguado, pincel seco, projetadas nos três
  planos; luz de sempre.
- **C1–C3:** S<n> + T<n>.
- Herói aço-azulado e grama sem base escura quando o guache está ligado. Pinceladas clareiam mais do que escurecem.

## Decisões que assumi (rever)

1. **"Textura por IA" = folhas de pincel projetadas**, não textura pintada por modelo: os modelos do Blender são
   coloridos por vértice, sem UV pintável. Assim a IA alcança todos os modelos de uma vez.
2. **Por velocidade, só a folha de grama de cada estilo foi gerada** (3 imagens, não 24) e serve para todos os
   materiais: o shader usa só o valor (claro/escuro) da folha, a cor vem do modelo. As folhas por material podem
   ser geradas depois, para a variação escolhida (`assets/textures/paint/T<n>/<material>_v.png` entra sozinha).
3. A mesa recebe o guache como o resto (pedido: "mesa incluída").

## Pendências conhecidas

- As diferenças entre S1, S2 e S3 são sutis na distância da câmera; ficam mais claras em tela cheia.
- Costura visível na folha T3 (pincel seco) em algumas áreas.
- O chefe e as árvores da arena continuam claros e arredondados (forma do modelo, não da pintura).
- Custo de desempenho não medido.
