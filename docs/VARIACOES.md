# Variações de arte

**Escolha (07/11/2026), já é o padrão em `game/settings.gd`:** HUD 0 (atual), chão 2 (Bosque enluarado),
herói 4 (Sombrio), monstros 3 (Pintado). As outras variações continuam no projeto e no menu Visual.
Custo medido em A/B intercalado (500 unidades): cerca de 70% do FPS do visual antigo; falta otimizar.

## Direções de arte únicas (08/11/2026, escolha pendente)

O jogo ficou feio principalmente por misturar quatro linguagens na mesma tela (chão de foto, herói PBR,
monstros pintados, HUD genérica). Em vez de escolher camada por camada, agora há direções inteiras:

| Opção | Como ligar (`--set=` ou menu Visual) | FPS, 500 unidades (08/11) |
|---|---|---|
| A · Pintado em tudo | `look_ground:5,look_hero:4,look_enemies:3` | 30 |
| B · Cartum com contorno | `look_ground:6,look_hero:2,look_enemies:2` | 18 |
| C · Escolha de 07/11, corrigida | `look_ground:2,look_hero:4,look_enemies:3` (padrão) | 38 |

Referência no mesmo teste: visual antigo (todos 0) = 60 FPS. Galeria: https://claude.ai/artifact/UFW2Xd8jpHJfJ8i4twvp5L
(cópia local `docs/variacoes/direcao.html`, fotos em `docs/variacoes/img/direcao/`).

- Chão 5 e 6 são procedurais (`ground_paint.gdshader`, `road_paint.gdshader`), sem textura de foto.
  `GroundLooks.world_shader_look()` faz prédios, cenário, chefe, herói e monstros usarem o shader da
  direção (3 = pintado, 2 = cartum com contorno); a malha do herói continua vindo de `look_hero`.
- Correções que valem para todas: câmera (`WorldView.CAM_DIST` 30, FOV 40), contraluz sem especular na camada 1
  (o chão fica na camada 2), anéis de cor por tipo sob os monstros (`WorldView.ACCENT`, `ring.gdshader`), dano no
  herói somado, zonas e prévia em anel, leque de cartas sem nome cortado, linha de atalhos só nos primeiros 45 s,
  cenário em bosques e clareiras, bloom com limiar 1,15.
- Defeitos corrigidos: elipses duras de luz pontual (degraus de luz e brilho em degrau nos shaders), cunha clara
  na arena (especular da contraluz), sombra do castelo sobre a arena, manchas retas na estrada (trechos
  semitransparentes sobrepostos: agora opaca com recorte e miolo mais alto que a borda).
- Se a B for escolhida, o contorno precisa virar efeito de tela (hoje é uma segunda passada por malha e custa caro).

Quatro opções novas para cada parte do visual, ao lado da arte atual. Nada substitui a arte atual: cada
categoria tem um número em `Settings` (0 = atual) e o jogo monta o visual escolhido.

- Galeria com todas as fotos e o botão de escolha: https://claude.ai/artifact/CFfpoEEQJVL6xowWXYxcLU
  (cópia local: `docs/variacoes/galeria.html`, abre direto no navegador)
- No jogo: **Configurações → Visual**. Trocar recarrega o jogo na tela inicial.
- Por linha de comando, só naquela execução: `--set=look_hud:1,look_ground:2,look_hero:3,look_enemies:4`

| # | HUD (`look_hud`) | Chão e fundo (`look_ground`) | Herói / Monstros (`look_hero`, `look_enemies`) |
|---|---|---|---|
| 0 | Atual | Atual | Atual |
| 1 | Madeira e ouro | Campina ao entardecer | Argila (massinha, chibi) |
| 2 | Pedra rúnica | Bosque enluarado | Cartum (contorno + sombra em faixas) |
| 3 | Vidro arcano | Outono | Pintado (luz pintada nos vértices; herói = escudeiro jovem) |
| 4 | Gótico carmesim | Terra amaldiçoada | Sombrio (PBR, metal, olhos que brilham) |

## Onde está cada coisa

- `game/art/looks.gd`: escolhe malha e material dos monstros e do herói pelo look.
- `game/art/look1..4.gdshader`, `look2_outline.gdshader`, `anim.gdshaderinc`: shaders dos looks (a animação de andar/investida/asas é a mesma do `toon.gdshader`).
- `game/art/ground_looks.gd` + `ground.gdshader`, `road.gdshader`, `grass.gdshader`, `prop.gdshader`: chão, estrada, grama, cenário, luz, céu e névoa.
- `game/ui_skins.gd`: as peles da HUD. `UiKit` pergunta a paleta, as fontes e o desenho de painéis, botões, barras, selos, cartas e gomos de elixir.
- `assets/models/look<N>/*.res` (monstros e herói) e `assets/models/ground<N>/*.res` (árvores, arbusto, pedra): gerados.
- `assets/textures/ground/`: texturas CC0 do Poly Haven (`tools/art/fetch_textures.py`).
- `assets/fonts/`: fontes OFL do Google Fonts, com as licenças (`OFL-*.txt`).

## Como regerar os modelos

Os modelos são feitos por código no Blender 5.2 (formas que se fundem, cor pintada nos vértices, oclusão calculada por raios).

```
blender -b --factory-startup -P tools/art/build_models.py                 # tudo (monstros, herói, cenário dos 4 looks)
blender -b --factory-startup -P tools/art/build_models.py -- --looks 3 --only ogre,hero_head
blender -b --factory-startup -P tools/art/build_models.py -- --ground      # só o cenário
godot --headless --path . -s res://tools/art/import_models.gd              # .lbm -> assets/models/*.res
godot --path . res://tools/art/showroom.tscn -- --look=2 --what=units|hero|props [--only=ogre] --out=<pasta>/
```

Desenhos: `tools/art/creatures.py` (monstros e herói, com o que muda em cada look) e `tools/art/props.py` (cenário).
Base: `tools/art/kit.py`. A pasta `tools/art/out/` é intermediária (foi para o `.gitignore`).

## Decisões que tomei no seu lugar (AFK) e riscos

- **Variações coexistem com a arte atual**, escolhidas por configuração. Assim você compara jogando. Depois da escolha, dá para apagar o resto.
- **Os 4 estilos de monstro são o mesmo elenco em 4 tratamentos** (proporção, paleta, olhos, enfeites e shader), não 68 desenhos independentes. O Cartum usa as formas do Argila.
- **Herói:** mesmos pivôs das peças, então a animação não mudou. No Pintado ele virou um escudeiro jovem sem elmo, para ter um desenho diferente.
- **HUD:** mesmo layout, peles diferentes (material, fontes, molduras, barras, selos, cartas, elixir). Não mexi na disposição dos elementos.
- **Chão:** texturas fotográficas (CC0) com personagens estilizados. A mistura funciona na câmera do jogo; se preferir tudo estilizado, o chão pode virar procedural.
- **Fora do escopo:** o chefe (o seu corpo na arena), as casas e os locais não foram refeitos. A arena herda a luz e a névoa do look de chão.
- **Desempenho** (500 unidades, RTX 2060): 90 FPS médio no atual; 77 (Argila), 71 com mínimo de 49 (Cartum, por causa do contorno), 80 (Sombrio). Depois da escolha dá para baixar os triângulos do estilo escolhido.
- **Risco: mapas de normais.** Marquei as texturas `*_nor.jpg` como mapa de normais nos `.import`, mas o `.gitignore` ignora `*.import`. Num clone novo, a Godot reimporta com detecção automática; se o relevo do chão ficar estranho, marque "Normal Map: Enable" nelas.
- **Risco: `UiKit`.** As cores viraram `static var` (antes `const`) para a pele trocá-las. Nenhum outro arquivo usava essas cores em `const`, e os testes passam (0 falhas).
- **Bug encontrado no caminho:** o `pow(COLOR.rgb, 2.2)` com MSAA gerava NaN nas cores pintadas (bolhas brancas com o bloom). Os shaders novos limitam a cor antes; o `toon.gdshader` antigo não tem esse problema porque as cores dele são chapadas.
- **Verificado:** suíte de testes (0 falhas), teste de estresse, executável exportado abrindo com looks misturados, todas as telas fotografadas (partida, oferta, pausa, menu, arena).
- **Nada commitado.** Tudo está como mudança local; os arquivos que já tinham mudanças suas (`main.gd`, `hud.gd`, `world_view.gd`, `settings.gd`, `ui_kit.gd`, `menu.gd`, `elixir_bar.gd`, `settings_panel.gd`, `strings.csv`) receberam só acréscimos pequenos, sem mexer no que você estava fazendo.
