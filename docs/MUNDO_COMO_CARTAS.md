# Mundo como as cartas (15/11/2026)

Pedido: o mundo destoava das cartas e da UI em cor, valor e textura. A direção foi validada numa simulação sobre fotos
(`docs/simulacao_mundo/`, página em http://localhost:8796) e implementada no jogo como três chaves independentes.

| Chave | Tecla | O que faz | Onde |
|---|---|---|---|
| A · cor (`mundo_cor`) | F6 | Chão e cenário nos fundos das cartas: menta/petróleo → sálvia, salmão → ocre, croma ×0,62. Unidades animadas (VAT) mantêm a cor. Tira o reforço de saturação final. | `pt_card_ground` em `game/art/paint.gdshaderinc`; `look5.gdshader` (só sem VAT) |
| B · escuros (`mundo_escuro`) | F7 | LUT 3D que estica só o valor (L do Lab) e puxa a sombra para lilás, sem mudar o croma; sombra do guache mais funda; glow ×0,7. | `assets/textures/paint/lut_escuro.png` (`tools/art/make_lut_escuro.py`), `PaintLook.apply_env` |
| C · papel (`mundo_papel`) | F8 | Grão do papel recortado do céu liso das cartas, preso ao mundo (três planos), só clareando. | `assets/textures/paint/papel.png`, `paint_paper` / `PAINT_PAPER` |

As três vêm ligadas por padrão e também ficam em Configurações → Vídeo. Valem só com o guache ligado (`paint_look` > 0).

## Medição no jogo (média de 2 cenas, mundo sem HUD)

| | Croma mediano | Escuros (L p5) | Textura |
|---|---|---|---|
| Cartas (alvo) | 8–13 | 20–36 | ~8 |
| Antes | 17,5 | 53 | 1,5 |
| A | 11,3 | 53 | 1,5 |
| B | 16,7 | 35 | 3,6 |
| C | 17,5 | 53 | 6,9 |
| A+B+C | 10,5 | 35 | 9,6 |

## O que aprendi no caminho

- Tirar a névoa para escurecer **aumenta** a cor (croma 17 → 29): a névoa é o que segurava a saturação. Ela ficou.
- O contraste do `Environment` gira em torno do cinza médio da tela; como o mundo está quase todo acima dele, clareava.
  Por isso a LUT.
- Com a B ligada a LUT estica o grão junto; o papel é compensado (×0,55) para ficar no grão das cartas.

## Sombra pontilhada (16/11)

A sombra do sol saía em pontinhos com ou sem as chaves: penumbra por ângulo (`light_angular_distance` 1,0, PCSS) +
`shadow_blur` 1,5 com poucas amostras e sem TAA. Agora os chãos usam ângulo 0 e desfoque 0,8 (`ground_looks.gd`) e a
qualidade alta usa o filtro suave médio (`Settings.apply_quality`). Conferido em captura: borda limpa.

## Papel maior (16/11)

O grão de 1 px lia como ruído. Agora `tools/art/make_papel.py` gera manchas macias de papel de aquarela (ruído filtrado
por FFT, sem costura) numa folha de 1024 px que cobre 32 m: manchas de ~6 a 12 px na tela, mais fracas (0,55 clareando,
0,18 escurecendo).

## Pendências


- O degrau da sombra na estrada continua (bug à parte).
- Trechos de estrada rosados (matiz Lab < 15) não entram no remapeamento de A.
- Atalhos F6–F8 e as chaves das Configurações não foram testados com tecla de verdade (só pela linha de comando `--set`).
- Build: `export/mundo_cartas/LastBoss.exe` (a build anterior em `export/` não foi tocada). Nada commitado.
