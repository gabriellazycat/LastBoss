# Consolidação de 16/11/2026: consistente, bonito e divertido

Pergunta: "olhando todo o jogo e todo polimento, falta alguma coisa para ele ficar consistente, bonito e divertido?"
Resposta curta: faltava **fechar** o que já existia. Plano aprovado em
`C:\Users\gabri\.claude\plans\olhando-todo-o-jogo-cheeky-moth.md`. A `grilling` ficou de fora porque você deu carta branca ("pode fazer tudo").
No meio do caminho você tirou a etapa de dificuldade ("a parte de ajustar a dificuldade não precisa") e pediu paralelismo: o áudio foi feito por um subagente enquanto eu terminava o visual.

## Estado

| Etapa | Estado |
|---|---|
| Ponto de volta: commit `2c25346` de tudo das rodadas 15–16/11 (sem push) | feito |
| Testes verdes (Ritual, `art_pending`) | feito |
| Capturas "antes" com as configurações padrão (`docs/consolidacao/antes/`) | feito |
| Almas fora e textos de sistemas que saíram | feito |
| Avisos, efeitos, heróis e estrada no estilo do jogo | feito |
| Áudio CC0 com página de escuta | feito |
| Dificuldade e arena | **fora** (você dispensou) |
| Capturas "depois", prancha e testes finais | feito |

Nada depois do `2c25346` foi commitado.

## O que mudou

### Testes
- **Ritual Profano** (2 falhas): não era o rio. O monstro sacrificado também arma o **Ciclo de feitiço** do Lich, e os dois descontos somam (custo 2 → 0). O teste agora confere a soma e, à parte, o desconto do Ritual sozinho. O jogo não mudou.
- `art_pending` saiu de `tests/tests.gd`: as 28 cartas de 13/11 já têm arte. A checagem "toda carta tem o próprio png" vale para todas.
- Teste novo: o meta salvo não tem mais Almas.

### Almas fora do jogo
- `sim/meta_save.gd`: sem `souls`, sem `souls_for`, sem prêmio em Almas. Save antigo com Almas carrega normal (o campo é ignorado). `add_run()` só conta a run.
- `data/meta.json`: ficou só a nota; `data/campaign.json`: os 4 `reward_souls` saíram.
- Mapa da campanha: o prêmio das fases 0 a 5 mostra "Libera a próxima região: <região>"; a Capital mantém "o reino é seu".
- Coleção: no lugar do contador de Almas, "Cartas liberadas: n de t"; texto de cima fala do desafio de cada carta.
- `--liberar` não dá mais 9999 Almas; `tools/run_batch.py` não tem mais a coluna de Almas.
- Cartas e habilidades com "Almas" no nome (Absorver Almas, Coletor, Banquete, Colheita, Tempestade) continuam: são nomes, não a moeda.

### Textos de sistemas que saíram
- Recompensa de queda: "**Herói caído! Escolha 1**" (era "Subiu de nível!"; o id interno `level` ficou, por causa dos bots e dos saves).
- Painel do herói: o nome da classe do líder ("ESCUDEIRO") ou "**A PARTY**" com mais de um herói de pé (era sempre "O HERÓI").
- Resultado: heróis derrubados (x / total), tempo, disputas vencidas (x / visitadas), ouro ganho, relíquias, abates dos heróis, carta mais jogada e, só se houve arena, partes do corpo perdidas. Saíram Almas, nível do herói e Santuários.
- Plural onde o texto falava de um herói só: vitória, vitória antecipada, subtítulo do menu, dicas de início, bifurcação, ajudante e santuário, tutoriais de escudo, locais, queda e arena, prorrogação, metas da taverna e da ponte, "Os heróis aprenderam".
- Chaves mortas removidas de `locale/strings.csv`: as de Almas, a oferta "Subiu de nível" e as telas antigas de Pacto (nenhuma era lida pelo código).

### Visual
- **Avisos grandes** (`game/big_banner.gd`): nas peles de papel, faixa de papel com fio duplo de tinta e título em tinta (vermelha nos objetivos e atos, verde nos marcos e vitórias, preta na disputa perdida). Antes: verde neon com contorno preto. A pele Covil fica igual.
- **Faíscas e raios das recompensas** (`game/juice.gd`): respingos de tinta e anel de tinta no lugar do clarão branco; raios no ouro do papel.
- **Selos de status sobre as unidades** (`game/status_overlay.gd`): selo de papel com contorno de tinta; números em tinta.
- **Leitura**: a ajuda do rodapé virou etiqueta de papel em tinta (era cinza sobre o mundo); a dica "Clique numa opção…" ganhou folga na etiqueta.
- **Heróis**: o KayKit fica (escolha sua de 15/11). Cada classe ganhou o tom da arte da carta dela (`HeroRig.CLASS_TINT`): Arqueira verde, Clériga marfim, Mago azul, Assassino roxo, Bárbaro pele e couro, Besteiro couro marrom, Guardião aço frio; o Escudeiro segue o aço azulado. Conferido com uma party de 4 (Guardião, Clériga, Mago, Assassino): dá para separar o Mago (chapéu escuro) da Clériga (chapéu claro). O Assassino continua puxando para o verde da textura do ladino.
- **Estrada**: o "degrau" era a divisa entre o ramo fechado (escurecido) e o ramo da rota, que virava mosaico onde dois trechos se sobrepõem (ponte, bifurcação). O estado agora é desfocado em ~1 m nos dois shaders da estrada. Os rosados (matiz < 15) entram no remapeamento para ocre; na estrada medida, o rosado que sobra vem da luz e da LUT.
- **Variações de arte escondidas**: a aba Aparência e as escolhas de guache, modelos e mundo A/B/C só aparecem com `--variantes` na linha de comando (F6–F8 também). Os padrões ficam fixos; `--set` continua valendo.
- Efeito de upgrade das cartas (variante 4): ficou. Nas capturas da oferta ele não destoa.

### Áudio
Feito por um subagente em paralelo, conferido por mim. Detalhes em `docs/AUDIO.md`; **página de escuta** em `docs/audio/index.html` (abra com o servidor "ui-propostas" do `.claude/launch.json`: http://localhost:8766/docs/audio/index.html; os 67 players carregam).
- **65 arquivos `.ogg` novos**, todos CC0 do OpenGameArt; conferi a licença nas 25 páginas de origem (todas "CC0", sem outra licença junto). Créditos em `assets/audio/LICENSES.txt`. Os `.wav` sintetizados ficaram como reserva.
- **Música por contexto** (`game/audio.gd`): menu e campanha (TAD, "Once Upon a Time"); estrada por vilão (Praga: nene, "Evil Approach"; Dragão: josepharaoh99, "Ancient Power of Serpents"; Lich: cynicmusic, "Sinister Boss Appears"); arena (Juhani Junkala, "Boss Battle Music"); vitória e derrota tocadas uma vez (RandomMind). Troca com crossfade de 1,6 s.
- **Tensão na estrada**: a trilha começa abafada (passa-baixa no ônibus Music) e mais baixa, e abre conforme os heróis se aproximam do covil.
- **Ambiente por região**: campo na Fazenda, vila na Vila e na Capital, riacho na Floresta, vento no Mosteiro, Forte e Torre, masmorra na arena.
- **Efeitos**: carta jogada com som de carta de verdade, golpes por tipo (carne, duro, herói, chefe), mortes por tipo (criatura, osso, pedra), feitiços (comum, fogo, sombra), escudo quebrando, explosões, teleporte, relíquia, cura, medo; cliques de papel; e jingles curtos (Kenney) nos avisos grandes (início e fim de disputa, ato, arena) e nas recompensas.
- `game/main.gd`: só as chamadas de música mudaram (`music_menu`, `music_for_run`, `result_music`).
- Pontos fracos que o subagente apontou: o começo da trilha da Praga pode ficar quase inaudível com o filtro da estrada; o riacho só toca na Floresta (sem som por proximidade do rio); tudo foi escolhido sem ouvir.
- Também ficaram em `docs/audio/` os scripts da conversão (`build_audio.py`, `docs_audio.py`, `manifest.json`, `AUDIO_template.md`), para regerar. Não foram pedidos: se não quiser no repositório, dá para apagar.

## Decisões que assumi (revise)
1. O prêmio das fases 0 a 5 é a próxima região (não pus outra moeda no lugar das Almas).
2. As variações de arte somem das Configurações, mas o código fica (`--variantes` mostra).
3. Heróis continuam KayKit; mudei só o tom.
4. Efeito de upgrade (variante 4) mantido.
5. Áudio só CC0, escolhido sem ouvir (não tenho como): a página de escuta existe para você trocar qualquer um.
6. A queda de herói ganhou título próprio; o id `level` interno ficou.
7. Mensagem nova do resultado "x / total" de heróis derrubados; o destaque dourado passou das Almas para esse número.

## Riscos e o que não verifiquei
- **Dificuldade sem medida** (você dispensou): na última medição, o bot humano vencia ~100% e o aleatório ~85%. Nas capturas, o bot heurístico venceu a fase 1 e o aleatório venceu a fase 3 do Lich antes da arena.
- `--uitest` em tela cheia é intermitente (falha às vezes dentro do script de captura; sozinho passa); não investiguei a causa.
- Não joguei uma run inteira com mouse e som: **o teste que falta é você jogar** (fase 1 e uma fase nova).

## Capturas
- Antes: `docs/consolidacao/antes/` · Depois: `docs/consolidacao/depois/` · Prancha lado a lado: `docs/consolidacao/prancha.html`.
- Regerar: `bash tools/capture_consolidacao.sh <pasta>` e `python -I tools/make_consolidacao_prancha.py`.
- As arenas usam o bot `idle` (`data/bots/idle.json`, não joga cartas), senão a run acaba antes do covil.

## Testes
Ao final, com o áudio novo e tudo o mais (sem commit):
- `godot --headless --path . --import`: sem erro.
- `res://tests/tests.tscn`: **falhas: 0** (651 ok).
- `--menutest`, `--uitest`, `--routetest`, `--tiptest`: **OK**, 0 erros de script.
- `--uitest` em tela cheia: falhou dentro do script de captura (antes e depois) e passou inteiro quando rodado sozinho: é intermitente, de tempo, e já existia antes desta rodada.
- Página de escuta: os 67 players carregam (servidor local, navegador do app).
