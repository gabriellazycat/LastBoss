# Last Boss

Roguelike de cartas em Godot 4.7 (GDScript). O jogador é o vilão e defende o covil contra 15 parties de heróis: joga monstros, estruturas e feitiços com elixir enquanto os heróis marcham pela estrada e depois invadem a arena. As Almas ganhas em cada run compram melhorias permanentes (Covil, Biblioteca, relíquias).

## Leia primeiro

- **`docs/JOGO.md`**: o jogo como ele é hoje. É o único documento de design.
- `docs/CARD_FX.md`: como montar uma carta por dados (`ops`, `on_death`, `ai`).
- Não existe mais nenhum outro documento de design: o histórico (rodadas, planos, propostas, GDD) foi apagado em 24/11/2026 e fica só no `git log`. Não ressuscite docs velhos nem confie em texto antigo do histórico: confira no código.
- Se o código e o `docs/JOGO.md` discordarem, vale o código, e o JOGO.md deve ser corrigido no mesmo commit da mudança.

## Regras do projeto

- **Dados em `data/*.json`** são a fonte de verdade dos números. Para editar o balanço, use o editor `tools/balance_editor`, na porta 8767. Não existe planilha.
- **`sim/` é lógica pura e determinística** (sem nós de cena): não use o visual dentro dela.
- **Godot sempre em segundo plano:** nunca tela cheia nem `warp_mouse`, sempre `--position -6000,0`. Blender sempre com `-b`.
- **Visual: um padrão só.** Não reintroduza variantes de estilo por flag ou tecla. Uma proposta nova vai para uma branch e, depois de escolhida, substitui o padrão.
- **Modelos 3D novos:** usar as cores da arte da carta e fazer olhos sem pupila.
- **Arte das cartas:** use a skill `cartas-ia` (guache leve, um pincel).
- **Capturas e saídas** vão para `capturas/`, `export/` ou `tools/art/out`, todas ignoradas pelo git. Nunca para `docs/`.

## Rodar

Godot pelo Git Bash:

```
G="/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import
"$G" --headless --path . res://tests/tests.tscn            # última linha: "falhas: N"
"$G" --headless --path . --script res://tools/check_scripts.gd   # todos os scripts compilam?
"$G" --position -6000,0 --path . -- --menutest
```
