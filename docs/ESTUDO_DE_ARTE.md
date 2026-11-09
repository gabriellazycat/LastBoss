# Estudo de arte: Risk of Rain 2, Soulstone Survivors e Megabonk (09/11/2026)

Pedido: o jogo está feio ("cartas, modelos, iluminação e o herói; parece low-poly mal feito; até assets
prontos são mais bonitos"). Estudar três jogos 3D do gênero e pôr no jogo versões novas para você escolher.

**Resultado:** três direções novas, inteiras (chão + luz + herói + monstros + cartas juntos), em
**Configurações → Visual → Direção de arte**. A atual (C) continua sendo o padrão até você escolher.
Galeria lado a lado com o jogo atual: `docs/variacoes/estudo/galeria.html`.

| Direção | O que é | Como ligar (`--set=`) | FPS, 500 unidades |
|---|---|---|---|
| C · padrão atual | escolha de 07/11 corrigida | `look_ground:2,look_hero:4,look_enemies:3` | 42 (mín. 20) |
| A · Pintado | direção de 08/11 | `look_ground:5,look_hero:4,look_enemies:3` | 39 (mín. 25) |
| B · Cartum | direção de 08/11 | `look_ground:6,look_hero:2,look_enemies:2` | 20 (mín. 17) |
| **D · Aventura, dia** | KayKit + Quaternius (CC0), animados; luz de dia estilo RoR2 | `look_ground:7,look_hero:5,look_enemies:5` | **73** (mín. 38) |
| **E · Aventura, noite** | os mesmos modelos; noite fria, contraste alto (Soulstone) | `look_ground:8,look_hero:5,look_enemies:5` | **72** (mín. 44) |
| **F · Própria refinada** | nossos modelos do Blender refeitos (look 6) na luz nova | `look_ground:9,look_hero:6,look_enemies:6` | **64** (mín. 23) |

FPS medidos na mesma sessão, janela 1920x1080, `--autoplay=random --stress=500 --quit=25`, RTX 2060, duas
rodadas intercaladas (média das duas; detalhes em `docs/variacoes/estudo/fps.txt`).

**Minha recomendação:** **D · Aventura, dia** como base. É a única em que a tela inteira fala uma língua só
(modelos de um mesmo autor, uma luz, um chão calmo), a horda **anda e ataca de verdade** e é a mais leve:
73 FPS com 500 unidades, contra 42 do padrão atual. A E é a mesma direção à noite: dá para usar as duas
como atos diferentes. Se você preferir monstros com a cara do Last Boss (os nossos desenhos), a F é a segunda
opção — melhorou muito com a luz nova, mas os monstros continuam "quicando" em vez de andar. Próximo passo
depois da escolha: arena, chefe e prédios na mesma direção (hoje são os antigos e destoam).

---

## 1. Por que o Last Boss parece feio hoje

Olhando as capturas atuais ao lado das referências, o problema não é "poucos polígonos" — Megabonk tem menos
polígonos que nós e é bonito. São quatro coisas:

1. **Nenhuma linguagem comum.** Chão de foto (texturas do Poly Haven), herói PBR com metal, monstros com luz
   pintada nos vértices, interface em ferro e bronze. Cada camada foi escolhida sozinha (07/11) e nunca se viu a
   tela inteira junta. Nos três jogos de referência todo objeto usa o mesmo modelo de luz e a mesma densidade
   de detalhe.
2. **Valores (claro/escuro) sem hierarquia.** O chão tem tanto contraste e ruído quanto os personagens, então
   eles não destacam. Em RoR2 e Soulstone o chão é o elemento de menor contraste da tela; os personagens e os
   efeitos têm o maior.
3. **Luz sem direção.** Lua fraca + muitas luzes pontuais + névoa roxa uniforme: tudo fica no mesmo tom médio.
   As referências têm um sol forte com sombra, um céu que preenche as sombras com outra cor (frio x quente) e
   névoa que separa perto de longe.
4. **Modelos parados.** Os monstros "pulam" com uma deformação de shader (o mesmo quique para todos). A 30 m da
   câmera, um esqueleto que só quica parece um boneco de massinha deslizando. Animação de andar de verdade é o
   que mais faz uma horda parecer viva.

Os nossos modelos, de perto, não são ruins (ver `docs/variacoes/estudo/img/modelos_*.jpg`): o que os estraga é a
luz, a escala na tela e a falta de animação.

## 2. As referências

Links (só para consulta; nenhuma arte delas foi copiada para o repositório):
- Risk of Rain 2 (Hopoo Games): https://store.steampowered.com/app/632360/Risk_of_Rain_2/
- Soulstone Survivors (Game Smithing Limited): https://store.steampowered.com/app/2066020/Soulstone_Survivors/
- Megabonk (vedinad): https://store.steampowered.com/app/3405340/Megabonk/

### Risk of Rain 2 (a principal)

- **Silhueta e proporção:** monstros com formas simples e reconhecíveis de longe (besouro, lagarto, golem de
  pedra com um olho que brilha). Pouco detalhe pequeno; o detalhe está na forma grande. Cada inimigo tem uma
  cor dominante própria.
- **Paleta:** cada fase tem uma paleta curta e forte (planícies verde-douradas, ninho azul-petróleo, aqueduto
  laranja). Céu e névoa usam a cor complementar da do chão.
- **Shading e materiais:** difusa larga e suave, especular baixa, texturas pintadas de traço largo (não foto).
  Nada de faixas de toon nem contorno preto: a forma vem da luz.
- **Luz, névoa e pós:** sol forte com sombra macia; o céu preenche as sombras com cor fria; **névoa por altura e
  distância** forte, que apaga o fundo e dá profundidade; bloom só nos efeitos e nos olhos.
- **Efeitos:** aditivos, saturados, um código de cor por tipo (veneno verde, fogo laranja, gelo azul).
- **Muitas unidades:** o chão é escuro e calmo; inimigos têm valor mais claro e contorno de luz (rim).
- **Câmera:** terceira pessoa, um pouco alta. Não se aplica direto (somos vista de cima), mas a lição de
  "chão calmo, personagens claros" vale.
- **Interface:** ícones de item simples, com a cor da raridade na borda; números de dano com cor por tipo.

### Soulstone Survivors

- **Silhueta:** monstros de fantasia comuns, pouco estilizados; o que lê é o efeito, não o monstro.
- **Paleta:** mundo escuro e dessaturado (pedra, terra, verde-musgo) para os feitiços estourarem por cima.
- **Luz e pós:** noite ou masmorra, luz pontual quente perto do herói, bloom forte, contraste alto.
- **Muitas unidades:** centenas de inimigos parecidos lidos como "massa"; os de elite têm cor e tamanho
  diferentes. A tela aguenta porque o chão é quase preto.
- **Câmera:** de cima, inclinada (parecida com a nossa).
- **Cartas/UI:** ícones de habilidade pintados, molduras escuras com brilho na cor da raridade.

### Megabonk

- **Silhueta e proporção:** low-poly assumido, cabeças e mãos grandes, membros grossos — formas de brinquedo.
- **Paleta:** clara e saturada, cores chapadas (quase sem textura), céu azul limpo.
- **Shading:** luz simples, sombra macia, nenhum truque; funciona porque **tudo** usa o mesmo tratamento.
- **Muitas unidades:** hordas enormes de inimigos simples, todos animados; cada tipo com uma cor própria.
- **Lição:** "barato" não é feio; incoerente é. Low-poly coerente e animado parece intencional.

## 3. Como traduzi para o Last Boss

Regras que as três direções novas seguem:

1. **Uma linguagem por tela:** chão, cenário, prédios, herói e monstros no mesmo shader (`look5.gdshader`:
   difusa com envoltório, especular baixa, contorno de céu por fresnel), a mesma luz e a mesma névoa.
2. **Hierarquia de valores:** chão de menor contraste (`ground_ror.gdshader`: zonas grandes de cor, relevo
   suave pela luz, salpicos pequenos), personagens mais claros e saturados.
3. **Luz com direção:** sol forte com sombra macia, ambiente na cor do céu, névoa por distância e altura
   (`fog_height_density`, `fog_aerial_perspective`), bloom só no que emite.
4. **Animação de verdade nas hordas:** cada monstro tem o ciclo de andar e o golpe gravados numa textura
   (VAT, *vertex animation texture*): a GPU toca a animação por instância, então 500 unidades andam e atacam
   com o custo de uma MultiMesh. O herói tem esqueleto e animações (andar, correr, golpe, bloqueio).
5. **Coerência acima de detalhe:** os pacotes CC0 (KayKit e Quaternius) são simples, mas cada pacote é coerente
   — e foi isso que você notou nos "assets prontos".

## 4. As direções novas

### D · Aventura, dia (RoR2) — `look_ground:7,look_hero:5,look_enemies:5`
- **Herói:** Cavaleiro da KayKit (Adventurers), com esqueleto e 76 animações; usa Idle, Walking_A, Running_A,
  1H_Melee_Attack_Slice_Diagonal e Blocking (`game/art/hero_rig.gd`).
- **Monstros:** esqueletos, arqueiros e cultistas da KayKit; morcego, rato, rei rato, gosma, fantasma,
  espectro (fantasma-caveira), goblin, ogro (orc), lobisomem (lobo), golem (gigante) e mímico da Quaternius;
  estruturas com peças do pacote Halloween da KayKit. Todos com andar + ataque em VAT.
- **Cenário:** árvores, arbustos e pedras do Medieval Hexagon Pack (KayKit), cores do atlas nos vértices.
- **Luz:** sol quente forte (2,1), céu azul com horizonte pêssego, ambiente azul, névoa azul-lavanda por
  distância, SSAO mais forte, contraste 1,12.

### E · Aventura, noite (Soulstone) — `look_ground:8,look_hero:5,look_enemies:5`
- Os mesmos modelos; cenário noturno do pacote Halloween (pinheiros amarelos e laranja, árvores secas,
  túmulos, abóboras), chão azul-petróleo escuro, lua fria, contraluz laranja forte, bloom maior.

### F · Própria refinada — `look_ground:9,look_hero:6,look_enemies:6`
- **Monstros e herói:** look 6 novo em `tools/art/creatures.py`: proporção de boneco (cabeça ×1,38, membros
  ×1,22), olhos grandes, cor mais saturada, malha mais fina (`res_k` 1,5) e mais triângulos (`budget_k` 1,8);
  luz do shader do look 5. Herói = cavaleiro de elmo aberto do look 6.
- **Cenário:** as árvores da campina (ground1) com 25% dos triângulos (`assets/models/ground9`,
  `tools/art/lod_props.gd`): as árvores de 2,6 mil triângulos eram o que derrubava o FPS do padrão.
- **Luz:** fim de tarde (planícies do RoR2), sol dourado, névoa neutra.

### Cartas e herói
- **Cartas** (`game/art/card_art.gd`, só nas direções novas): retrato **no meio do golpe** (quadro do ataque
  da VAT), luz principal mais forte e quente, fundo mais claro na cor do tipo, chão do próprio mundo sob o
  monstro.
- **Herói:** D e E trocam o boneco de peças pelo cavaleiro animado; F usa o herói redesenhado do look 6.

## 5. Como refazer

```
python -I tools/art/fetch_cc0.py <pasta fora do repo>        # baixa KayKit (GitHub oficial) e Quaternius (Poly Pizza), confere licença
godot --headless --path . -s res://tools/art/import_cc0.gd -- --src=<pasta>   # -> assets/models/cc0/ (malha + VAT + textura, herói .scn)
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/build_models.py -- --looks 6
godot --headless --path . -s res://tools/art/import_models.gd                 # -> assets/models/look6/
godot --headless --path . -s res://tools/art/lod_props.gd -- --from=ground1 --to=ground9
bash tools/art/capture_dirs.sh <pasta> C A B D E F --fps                      # fotos 1920x1080 + FPS de cada direção
godot --path . -s res://tools/art/capture_big.gd -- <args do jogo>            # qualquer captura em 1920x1080 num monitor menor
```

Licenças: KayKit (Kay Lousberg, LICENSE.txt de cada repositório em github.com/KayKit-Game-Assets) e Quaternius
(páginas do Poly Pizza listadas em `tools/art/fetch_cc0.py`) são **CC0 1.0**; o `fetch_cc0.py` para se a página
não disser Quaternius + CC0 (o "Animated Wizard" foi descartado por isso). Créditos em `assets/models/cc0/CREDITOS.md`.

## 6. Decisões que tomei no seu lugar (AFK) e riscos

- **Direções inteiras, não camadas.** Um seletor novo "Direção de arte" grava chão + herói + monstros juntos;
  os seletores por camada continuam abaixo dele (agora com todas as opções, inclusive 5–9).
- **O padrão não mudou** (C). Nada da arte antiga foi apagado.
- **Mapeamento de monstros CC0** (não há pacote com o nosso elenco exato): lobisomem = lobo escurecido,
  golem = gigante de pedra azulado, ogro = orc, cultistas = ladino encapuzado tingido de roxo, ninho de
  morcegos = árvore seca decorada, totem = poste com caveira, torre da gárgula = santuário com velas.
  Trocar qualquer um é uma linha em `tools/art/import_cc0.gd` (`UNITS`).
- **VAT:** 12 quadros de andar + 8 de ataque por tipo, interpolados; texturas RGBA16F. Ponto fraco: o mímico
  tem 11 mil vértices (o mais pesado); o rato tem 8 mil por ser triângulos soltos. Dá para simplificar se a D
  ou a E for escolhida.
- **Herói com esqueleto:** o `WorldView` ainda monta as peças antigas, agora vazias, e o `HeroRig` lê o estado
  do herói sozinho. Mudança no `world_view.gd`: 4 linhas em `_build_hero`.
- **Fora do escopo:** chefe, arena, casas e locais continuam os antigos (a arena roxa destoa da D de dia);
  a câmera não mudou (seria em `world_view.gd`, que a outra sessão está mexendo). Se escolher D/E, o próximo
  passo é a arena e os prédios com o pacote Dungeon da KayKit (já baixado pelo `fetch_cc0.py`).
- **Interface (HUD):** não mexi; as cartas mudaram só o retrato.
- **Capturas em 1920x1080:** o monitor desta máquina é 1366x768 hoje; `tools/art/capture_big.gd` redimensiona
  a janela depois de criada (o `--resolution` é cortado pela tela).
- **Risco:** `Looks.unit_material` usa a última malha pedida (`_last_unit`) para achar a animação, porque
  `WorldView._build_units` e `CardArt` pedem a malha e logo depois o material sem repetir o id. Se alguém
  mudar essa ordem, a unidade fica sem animação (não quebra; só fica parada).

## 7. Arquivos

Novos: `docs/ESTUDO_DE_ARTE.md`, `game/art/look5.gdshader`, `game/art/ground_ror.gdshader`,
`game/art/hero_rig.gd`, `game/art/art_directions.gd`, `tools/art/fetch_cc0.py`, `tools/art/import_cc0.gd`,
`tools/art/lod_props.gd`, `tools/art/capture_big.gd`, `tools/art/capture_dirs.sh`, `assets/models/cc0/`,
`assets/models/look6/`, `assets/models/ground9/`, `docs/variacoes/estudo/`.

Compartilhados (mudanças pequenas):
- `game/world_view.gd`: 4 linhas em `_build_hero` (pendura o `HeroRig`).
- `game/settings_panel.gd`: seletor "Direção de arte" e opções por camada pelo tamanho das listas.
- `locale/strings.csv`: 2 linhas (`SET_look_dir`, `SET_look_dir_custom`).
- `game/art/looks.gd`, `game/art/ground_looks.gd`, `game/art/card_art.gd`: pontos de extensão de look.
- `tools/art/creatures.py` (look 6), `tools/art/import_models.gd` (pasta look6), `tools/art/showroom.gd`
  (material com a animação da malha).
