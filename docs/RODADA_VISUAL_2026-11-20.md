# Rodada visual (20/11/2026)

Pedido: "o que podemos fazer para o jogo ficar mais bonito?" — plano em
`C:\Users\gabri\.claude\plans\o-que-podemos-fazer-crispy-lighthouse.md`, feito em modo autônomo (sem perguntas,
sem commit, sem push). Tudo fica atrás de flags desligadas; nada vira padrão antes da sua escolha na página.

## Como revisar
1. Na raiz deste worktree (`C:\Users\gabri\Desktop\LastBoss-visual`): `python -I tools/revisao_visual/server.py`
2. Abra http://127.0.0.1:8769 — um cartão por mudança, com antes/depois e as variações.
3. Botões **Aprovar / Aprovar variação X / Rejeitar** + comentário; cada clique grava na hora em
   `tools/revisao_visual/aprovacoes.json`. Depois é só me pedir para aplicar o que foi aprovado.

## Flags (linha de comando, depois de `--`)
| Flag | Frente | Valores |
|---|---|---|
| `--fx=N` | 1 Efeitos | 0 de antes · 1 pintado · 2 brilhante |
| `--herois=N` | 2 Heróis | 0 de antes · 1 anel, aura e sombra · 2 só anel e sombra |
| `--mundo=N` | 4 Mundo vivo | 0 de antes · 1 discreta · 2 média · 3 densa |
| `--luz=N` | 5 Luz e cor | 0 de antes · 1 dia limpo · 2 fim de tarde · 3 contraste forte |
| `--arena=N` | 6 Arena | 0 de antes · 1 pedra e brasa · 2 cripta de runas |
| — | 7 Espaçamento da UI | entra direto (sem flag), como o plano pedia |

Para capturas: `--fxdemo=<ids de feitiços>`, `--fxat`, `--fxdist`, `--fxshot`, `--fxwait`, `--camzoom`
(`tools/capture_fx.sh`, `tools/capture_fx_all.sh`, `tools/capture_visual.sh`).

## O que mudou, por frente
- **1 Efeitos (`--fx`)** — `game/art/fx2.gd` + shaders `fx_particle*`/`fx_ground`: partículas desenhadas no shader
  (chama, fumaça, faísca, brasa, estrela, lasca, cruz) em vez da bolinha de 64 px; teia desenhada fio a fio, óleo
  fervendo com borda acesa e bolhas, chão em brasa, água, ondas de choque com poeira, círculo de feitiço, flecha
  modelada com rastro, orbe com halo e rastro, luz de fogo que treme, marca de queimado em alta. Feitiço de fogo
  agora explode em chamas (antes: círculo roxo). Casa da taverna desaba com destroços, poeira e fogo.
  V1 pintado (faixas de cor, como as cartas) e V2 brilhante (entra no bloom).
- **2 Heróis (`--herois`)** — `game/art/hero_presence.gd`: sombra de contato, anel na cor da classe, aura por classe e
  um pouco mais de tamanho (V1 completo, V2 discreto). Os KayKit continuam.
- **3 Modelos 3D** — não feito (ver Decisões).
- **4 Mundo vivo (`--mundo`)** — `game/art/mundo_vivo.gd`: flores, trigo, cercas, tocos, pedras, arbustos e manchas de
  cor no chão, fora da estrada e do rio; 3 densidades. FPS na cena mais cheia: ~10% a menos na densa.
- **5 Luz e cor (`--luz`)** — `game/art/luz_look.gd` + `main.gd` `_env*`: menos névoa leitosa, sol mais quente e sombra
  definida; dia limpo / fim de tarde / contraste forte, valendo na troca de ato.
- **6 Arena (`--arena`)** — `game/art/arena_look.gd`: pedra e brasa / cripta de runas.
- **7 Espaçamento da UI (sem flag)** — escala única em `game/ui_kit.gd` (`SP_*`, margem limpa por moldura de papel),
  margens à mão trocadas em todos os `ui_*`, `hud`, `tutorial`, `card_reader`; nome da carta no leque encolhe para caber;
  aviso "faltam N" inteiro e centrado (`UI_ELIXIR_SHORT` no strings.csv). Auditoria automática
  (`game/spacing_audit.gd`, `tools/space_audit.sh`): 769 problemas -> 0 em 1920x1080/1280x720, pt/en.

## Verificação
- Suíte completa no worktree juntado: 719 ok, 1 falha (a herdada da Horda, igual na main).
- Rodadas sem janela com todas as flags ligadas e desligadas, inclusive troca de ato: nenhum SCRIPT/SHADER ERROR.
- Revisão de código do conjunto (só leitura): nada grave; dois pontos corrigidos — a névoa volumétrica entrava no
  crossfade da troca de ato mesmo com `--luz=0` (agora só com `--luz>0`), e o "faltam N" media o texto todo quadro
  (agora só quando muda). Ressalvas que ficaram: com `--fx>0` a troca de ato recria ~220 emissores (custo de carga, não
  por quadro); a fonte mínima do nome da carta caiu de 14 para 12.
- A página foi aberta e mostra os 36 itens; a gravação das aprovações foi testada por HTTP com dados de exemplo
  (não cliquei em aprovar na sua página — a decisão é sua).

## Como levar para a main (quando você aprovar)
Nada foi commitado. Os três worktrees partiram de 23ded65 + a Horda sem commit da main; o `LastBoss-visual` tem tudo
junto. Para aplicar só o que for aprovado, eu tiro o diff do `LastBoss-visual` contra essa base (sem a Horda: a cópia dela está em `docs/rodada_visual/base_horda.patch`) e aplico
na main, ligando como padrão as variações escolhidas. Os worktrees `LastBoss-vis-ui` e `LastBoss-vis-mundo` podem ser
apagados depois disso.

## Decisões e riscos (assumidos no seu lugar)
- **Grilling pulada** pela sua regra de autonomia total.
- **Testes:** a suíte já falhava em 1 caso antes desta rodada (`t_unlock_challenges`: "desafios: vitória na fase 1 …
  (sewer_flood)" + SCRIPT ERROR em `tests.gd:600`), vindo da Horda sem fim sem commit na main. Não mexi nisso; o
  critério usado foi "nenhuma falha além dessa". A suíte NÃO está verde.
- **Flag desligada = jogo de antes:** provado pelo código (todo gancho atrás de `VAR > 0` / `fx2 != null`, cores e
  luzes de antes devolvidas quando a flag é 0, nenhum sorteio extra em RNG compartilhado), não por comparação de
  pixels: duas capturas com a mesma seed já diferem entre si (HP do Mago 1353/1359/1347).
- **Frente 3 (modelos 3D gerados por IA) não feita:** o plano liberava `generate_3d` (até ~15 gerações). Às 14h abri o
  Blender e o MCP conectou, mas nenhum gerador está ativo: o hyper3d pede uma chave de API no painel do MCP (tecla N
  no Blender), e cadastrar chave é com você. Sem gerador, os modelos ficam como estão (monstros Blender v2/guache,
  heróis KayKit). Para fazer depois: ativar a chave e me pedir; o caminho de importação já existe
  (`tools/art/blender_v2/vat.py` -> `tools/art/import_v2.gd`), melhor começar pelas peças paradas (casa, taverna,
  covil, peças da arena), porque os monstros precisam de ossos por parte para andar e atacar.
- **Herói próprio (frente 2):** não tentei; os KayKit ficam e ganham presença (anel, sombra, aura, tamanho).
- A sessão anterior parou no limite de uso com trabalho parcial não registrado; esta retomada conferiu cada arquivo.

## Rodada 2: modelos feitos à mão, inimigos, estruturas e golpes (20–21/11)
Pedido: modelos 3D novos feitos à mão (sem gerador de IA), modelos próprios para as cartas que usavam modelo
emprestado (`VARIANTS` em `game/art/looks.gd`) e golpes dos inimigos com mais impacto. Tudo atrás de flags; com as
flags em 0 o jogo é o de antes. Nada commitado, nada enviado.

**Flags novas:** `--modelos=1` (troca as peças e unidades pelos modelos de `assets/models/m2_a/`, 24 malhas, atlas em
`assets/models/g_tex/m2/`) e `--golpes=1` (`game/art/golpes.gd` + `golpe_slash.gdshader`). Só para captura:
`--camlair=1/2` (enquadra o covil).

**Na página (porta 8769) — 26 itens novos, cada um com antes, depois, giro 360 (12 quadros) e/ou clipe:**
- **Modelos 3D (6):** casa, taverna, covil do chefe (de chifres, com bocarra e caveira), pilar, braseiro e altar da
  arena. ~2x os triângulos dos modelos atuais. Fonte: `tools/art/blender_m2/build_m2.py`.
- **Inimigos novos (8):** Ratazana (o Rato Macho usa o mesmo), Mãe da Ninhada, Diabretes de Fogo, Carniçal, Kobolds
  Catadores, Servo Reanimado, Flautista Corrompido, Nuvem de Morcegos — com andar e golpe próprios (VAT). Fonte:
  `tools/art/blender_m2/creatures_m2.py` + `build_inimigos.py`.
- **Estruturas novas (10):** Toca de Ratos, Barricada, Estandarte de Guerra, Baú Armadilha, Fornalha, Ratoeira,
  Inundação de Esgoto, Mina de Ouro, Armadilha de Espinhos, Covil da Matilha (1,6k–2,4k triângulos cada), com laço
  parado animado. Fonte: `tools/art/blender_m2/structures_m2.py` + `build_structures_m2.py`.
- **Golpes e animações (2):** o golpe do monstro ganhou preparo, investida e pausa curta no impacto (hit-stop só
  quando um golpe de monstro acontece naquele tick; feitiços e zonas não pausam), arco de corte e poeira no chão.
  Clipes de perto e na luta com o grupo. FPS com `--stress=300`: sem diferença acima do ruído (g0 63/68, g1 68/71).

**Decisões e riscos desta rodada (assumidos no seu lugar):**
- Achado: no jogo o ataque VAT tocava de trás para frente em 0,2 s (`world_view.gd`, lunge 1→0 depois do golpe). Com
  `--golpes=1` o tempo é remapeado para preparo → golpe → segurar; com a flag em 0 fica como antes.
- **Camada 2 dos golpes (reexportar as animações VAT dos modelos antigos) não feita:** o remapeamento já dá o efeito e
  o pipeline exige atlas idêntico — risco alto para ganho pequeno.
- **Estruturas continuam sem tocar o ataque** (o jogo zera o lunge delas). Tentei ligar com `--golpes=1`, mas a torre
  de teste nasceu fora da tela e não deu para conferir; voltei atrás. A vida delas está no laço parado.
- Os modelos novos não usam tinta/escala do `VARIANTS`; cada um tem o próprio atlas com as cores da carta.
- Os modelos são feitos com primitivas no Blender (sem gerador de IA): leitura boa de longe, mas de perto são
  simples (ver o giro 360 de cada um).
- Às ~23:13 de 20/11 um `taskkill` sem filtro derrubou uma Godot por engano; as capturas afetadas foram refeitas.
- Verificação final em 21/11: suíte com 719 ok e só a falha herdada (`t_unlock_challenges`/sewer_flood + SCRIPT ERROR em `tests.gd:601`, a mesma de antes), nenhum SHADER ERROR; todos os arquivos citados nos itens.json existem; a página mostra as 4 frentes novas (62 itens no total). A suíte NÃO está verde por causa dessa falha herdada.

## Rodada 2 aprovada e aplicada na main (21/11/2026, 10:00)
Você aprovou os 26 itens (6 peças de cenário, 8 inimigos novos, 10 estruturas novas, golpes). Aplicado na main pela
mesma junção de três vias, sem commit; 3 trechos em conflito (main.gd, world_view.gd, capture_ui.sh) eram a versão
da rodada 1 contra a versão nova do mesmo trecho e ficaram com a nova. Cópia de segurança da main antes:
`C:\Users\gabri\Desktop\LastBoss-visual\docs\rodada_visual\backup_main_20261121_1000.tar`.

Padrões novos: `--modelos=1` (`Looks.M2`, peças e unidades em `assets/models/m2_a/`, atlas em
`assets/models/g_tex/m2/`) e `--golpes=1` (`Golpes.VAR`, `game/art/golpes.gd`). Com 0 volta ao de antes.
Execuções de teste/captura (com argumentos `--x=y`) rodam em segundo plano: janela fora da tela, sem foco, sem tela
cheia, sem mover o mouse (`--fg=1` desliga). Vitrine dos modelos: `python -I tools/revisao_visual/server.py` e
http://127.0.0.1:8769/vitrine.
