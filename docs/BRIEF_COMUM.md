# Brief comum dos subagentes (metaprogressão, 21/11/2026)

Projeto Godot 4.7 "Last Boss". Responda e comente em português do Brasil. O plano completo está em
`docs/PLANO_METAPROGRESSAO.md`: **leia o arquivo inteiro** antes de mexer. As decisões do plano estão fechadas; não reabra
nenhuma, não faça grilling. Só pergunte se estiver realmente bloqueado.

## Ponto de partida
- Seu worktree deve estar cortado da ponta de `metaprogressao`. Confira com `git log -1 --oneline` (o último commit é o
  dos contratos ou o do brief comum). Se não estiver: `git reset --hard metaprogressao`.
- Os contratos já existem e **não se mudam sem necessidade** (se precisar mudar, faça a menor mudança aditiva e conte no
  relatório): `sim/meta_apply.gd` (mods da run), `sim/hero_powers.gd` (stub do motor de poderes), API aditiva do
  `MetaSave` v5 em `sim/meta_save.gd` (fim do arquivo), `data/meta_tree.json`, `data/hero_powers.json`,
  `data/campaign_novo.json` (esquema da fase única), eventos `K.Ev.POWER_*`, `Sim.party_powers()`, e os ganchos de uma
  linha em `sim/sim.gd` (`setup(..., mods_)`, `HeroPowers.on_member_down/on_party_down/tick`, `MetaApply.*`).
- Mexa **só nos seus arquivos** (lista no seu brief). Se precisar de uma mudança pequena em arquivo de outra frente,
  faça o mínimo e relate.

## Como rodar (Windows, Git Bash)
```
G="/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import          # SEMPRE antes de testar (class_name novos, imports; worktree novo não tem .godot)
"$G" --headless --path . res://tests/tests.tscn -- --only=t_minha_funcao   # só o seu teste (rápido)
"$G" --headless --path . res://tests/tests.tscn    # suíte inteira; a última linha diz "falhas: N". Sem pipe que esconda travamento
```
- Rode a suíte inteira **uma vez, no fim**. Testes antigos que quebram por causa da mudança de design (7 fases, Horda,
  Almas antigas, 15 habilidades...) são da frente I: **não os conserte** além do necessário para a sua parte compilar;
  liste os que quebraram no relatório.
- Godot sempre em **segundo plano**: janela fora da tela (`--position -6000,0` antes de `--path .`), nunca
  `--set=fullscreen:true`, nunca mexer no mouse (sem `warp_mouse`). Capturas: veja `tools/capture_*.sh` como modelo.
- Todo teste que salva usa **caminho temporário** (`MetaSave.save(path)` / `load_or_new(d, path)`), nunca o
  `user://meta.save` do jogador (worktrees compartilham o `user://`).
- Arquivos do repo usam CRLF em vários `.gd`: ao editar por script/sed preserve o fim de linha (prefira a ferramenta
  Edit; `sed -i` remove CRLF).
- `locale/strings.csv` (colunas `keys,pt,en`): **acrescente** suas linhas num bloco no FIM do arquivo, com um comentário
  de cabeçalho da sua frente, para o merge não brigar. Todo texto de jogador em PT e EN.

## Balanceamento e testes (pedido do dono, 21/11)
Balanceamento é **pela matemática** (cálculo/planilha dos números), **sem testar muito**. Escreva só **testes de
fumaça** da sua frente (uma função `t_<frente>_...` nova em `tests/tests.gd`, sem mexer nas funções dos outros) e, se o
seu brief pedir, poucas runs do bot só para pegar números absurdos. O teste fino o dono faz. Não gaste tempo com
muitos testes, medições ou varreduras. As metas de dificuldade ficam **não medidas**.

## Entrega
- Commit no seu branch (mensagem em português, termina com `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`).
  Nada de push.
- Relatório final curto: arquivos tocados, o que foi feito, testes que rodou (e resultado), pendências/decisões
  assumidas, testes antigos quebrados.
- task-observer: the controller observes; report observations in your handoff (não grave nada no log de observações).
