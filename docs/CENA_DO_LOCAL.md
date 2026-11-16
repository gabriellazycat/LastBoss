# Cena do local (15/11/2026)

Problema relatado: ao terminar uma disputa no mapa, a tela de recompensa abria na hora e o jogador ficava sem
saber "o que é isso?", "eu ganhei?", "ganhei quanto?".

## O que foi decidido (grilling de 15/11)

| Pergunta | Decisão |
|---|---|
| O que a cena precisa dizer | Resultado + marcos: Vitória / "2 de 3 marcos" / Falhou, e os selos dos marcos acendendo um a um |
| Parcial | 3 níveis: completa = efeito grande; parcial = o mesmo efeito, menor; falha (0 marcos) = efeito de falha |
| O mundo durante a cena | Igual à cena da queda: 30% da velocidade, câmera vai ao local, cartas travadas e esmaecidas |
| Duração | Fim de disputa 3 s; chegada na loja e na encruzilhada 1,5 s; clique, espaço, Enter ou A do controle pulam depois de 1 s |
| Efeitos | Lista abaixo |
| Mapa | Abre sempre depois do local (depois da escolha da recompensa ou da cena de falha) e o jogo espera; nunca antes da recompensa |
| Caveira (disputa difícil) | 4º selo de caveira na mesma cena; a relíquia abre depois das recompensas, como antes |

### Efeitos por local (✔ = o vilão venceu a disputa)

| Local | ✔ | ✘ |
|---|---|---|
| Taverna | casas que sobraram afundam em fogo e fumaça | luz dourada, o herói brilha (descansou) |
| Fonte | água escurece, fumaça e brilho roxo | jorro de luz azul, o herói bebe e se cura |
| Ritual | círculo acende e sobe um pilar roxo | círculo apaga em fumaça |
| Santuário | santuário pega fogo | coluna de luz (herói abençoado) |
| Ponte | faíscas, lascas e fumaça, tremor | o herói brilha |
| Ajudante | o ajudante tomba de lado, como a queda do herói | brilha, encolhe e some em fumaça |
| Loja (chegada) | luz dourada, anel e faíscas; letreiro "Loja" | — |
| Encruzilhada (chegada) | névoa, brilho lilás e anel; letreiro "Encruzilhada" | — |

Abaixo do letreiro, os selos (1, 2, 3; ★ no ajudante; ☠ na disputa difícil) acendem a cada 0,3 s e a linha de
baixo diz o que vem: "N recompensa(s) para escolher", "1 relíquia para escolher" ou "Sem recompensa".

## Como funciona (código)

- `game/world_view.gd`: `start_scene(li, code)` nos eventos `Ev.CONTEST` de fim (1, 10+n, -1) e `Ev.LOCATION` da
  loja e da encruzilhada; `_scene_tick` (tempo real), `_scene_beat` (os efeitos, em 3 batidas) e `_end_scene`.
  A queda do herói tem prioridade: se o herói cai durante a cena, a cena do local acaba e a da queda começa.
  `cine_active()` agora vale para as duas cenas.
- `game/loc_seals.gd` (novo): os selos e a linha "o que vem", desenhados pela HUD.
- `game/main.gd`: `_scene_gates()` segura a oferta (`hud.hold_offers`) e, só durante a cena do local, deixa a
  simulação andar em câmera lenta mesmo com a oferta já pronta (`sim.pause_on_offer` volta a `true` quando a cena
  acaba). `_map_after_location()` abre o mapa grande 0,25 s depois de a cena e as ofertas acabarem; numa
  bifurcação quem abre é o mapa da bifurcação (escolha obrigatória), como antes. Escolher um local no mapa ou
  fechá-lo (botão, Esc, M) segue a run. No fim da rota do ato (`road.complete`) não abre.
- `game/big_banner.gd`: o letreiro conta em tempo real (não se arrasta na câmera lenta).
- O código da simulação (`sim/`) não mudou: bots, lotes e testes sem janela não têm cena nem o mapa pós-local
  (`world.cine_enabled`), então os números de balanceamento medidos por bots ficam iguais. Para quem joga, a
  cena acrescenta ≈0,9 s de jogo em câmera lenta antes da recompensa.
- Controle: o botão do mapa fecha o mapa pós-local (como o M); A pula a cena.

## Testes e capturas

- `--offer=contest:<tipo> --contestend=<s>:<n>[:hard]` termina a disputa no instante s com n marcos
  (0 = falha; ajudante: n > 0 = vencido). Ex.: `-- --start=horde --offerat=2 --offer=contest:tavern --contestend=4:2 --shots=4.3 --quit=5 --out=<pasta>/`
- `--offer=contest:shop` e `--offer=contest:event` mostram a chegada.
- `--skipkey=<s>` aperta espaço de verdade (pulo); `--pick=<s>` escolhe a 1ª opção de cada oferta (o mapa abre depois).
- `--humantest=human`: fecha o mapa pós-local com M ("mapa do fim do local (M fecha)" no relatório). Rodada de
  7 min em 15/11: vitória, ofertas 28/28, mapas pós-local 8/8; saiu com código 1 ("231 achados de interface"
  no resumo; no log, 229 linhas do invariante "seleção fora da mão" em t=211 e t=684, ver abaixo, 9 cartas
  recusadas pela regra de alvo e 2 de jogar). Esse teste usa
  rota automática, então não passa por bifurcações.
- Bifurcação colada no local (`--routewait=1 --offer=contest:<tipo> --contestend=4:2 --pick=4.2`): depois da
  recompensa abre só o mapa "Escolha o caminho" (sem o mapa pós-local antes dele). Taverna, ritual e fonte.
- `--uitest=1`: 2 itens falham, "mouse sobre a carta amplia" e "arrastar e soltar": a carta 1 acabou de ser
  jogada e a vaga dela está na recarga de 1 s (commit b9a854d), então não há carta para passar o mouse. Não há
  local nesse teste.

## Decisões assumidas por mim (para revisar jogando)

- Durante a cena (≈0,9 s de jogo a 30%) os monstros e o herói continuam se mexendo. Numa bifurcação sem
  escolha o herói espera no nó; com a rota já decidida ele anda uns poucos metros nesse tempo.
- Com a rota já decidida (ou um caminho só), o mapa pós-local abre com o botão "Fechar"; não há um botão
  "Seguir" separado.
- O resultado do santuário usa o efeito da lista (✔ fogo, ✘ luz); antes, sem cena, era o contrário (luz verde
  quando o vilão vencia). Sem cena (bots) o efeito antigo continua.

## Achados de passagem (não mexidos)

- Corrigido no mesmo dia, a pedido: `WorldView._update_rings` dava "previously freed instance" a cada quadro
  depois de `world.build()` (troca de ato e atalhos `--offer=contest`) porque `ring_nodes`/`ring_rad` não eram
  limpos em `build()`. Agora 0 erros (bot com 1157 s de jogo; antes, 10781 no `--humantest` de 7 min).
- `tests.tscn`: 2 falhas do Ritual Profano (custo 2 → 0, fim depois de 3 feitiços), na simulação das cartas.
- `--humantest`: o invariante "seleção N fora da mão" dispara na loja, onde `hud.selected` é o cursor do
  livro-caixa, não uma carta.
