# Cenário com propósito (21/11/2026)

Pedido: árvores refeitas, vento nas flores e um cenário com direção, sem coisas jogadas nem no meio do caminho.
**Aprovado em 21/11/2026 e padrão no jogo:** regiões + margem + nada na estrada, vento com rajadas, e árvores
"um estilo por bosque" (cada bosque é de pinheiros/álamos do estilo 2 ou de carvalhos do estilo 3; `Arvores.VAR = 4`).
`--cenario=0` / `--arvores=0` voltam ao de antes. Testes: 719 ok + a falha herdada dos desafios (sewer_flood).

| Opção | O que faz |
|---|---|
| `--cenario=1` | regiões com tema + margem florida + regras de lugar + vento com rajadas (`game/art/cenario.gd`, `game/art/wind.gdshaderinc`) |
| `--arvores=N` | 1 tufos redondos, 2 pinheiro + álamo, 3 carvalho torto, 4 um estilo por bosque (2 ou 3, padrão) (`game/art/arvores.gd`, malhas em `assets/models/arv1..3/`, fontes em `tools/art/blender_arvores/`) |

Padrão: `Cenario.VAR = 1` e `Arvores.VAR = 4`.

## Decisões (do grilling)
- **Composição:** regiões de 30–60 m com tema (bosque com borda, campo de flores de uma cor, pedreira, moita, clareira) + margem florida em trechos ao longo da estrada.
- **Por ato:** primavera (campos de flores, bosque florido), outono (trigais com feno, tocos e lenha na borda do bosque), terra amaldiçoada (bosque morto, cemitério em fileiras, círculos de cogumelos).
- **Densidade:** menos peças que antes, concentradas nas regiões; clareiras quase vazias como respiro.
- **Visibilidade:** a câmera fica ao sul; até 9 m abaixo da estrada só entra coisa baixa (flor, arbusto, cogumelo, lápide). Árvores do lado de cima a partir de 5,8 m.
- **Vento:** balanço suave + rajadas em onda, a mesma direção nas flores, grama, trigo e arbustos.

## Bugs corrigidos (valem com `--cenario=1`)
- Quintal das casas (cerca, trigo, feno) era posto a 10–15 m de *um* trecho e caía em cima de outro. Agora confere todos os trechos, prefere o lado de cima e some se não couber.
- Flores e pedras podiam ficar a 2,9 m do eixo (a pista tem 3,7 m de meia largura). Agora o mínimo é 4,3 m, medido até o segmento, não até os pontos.
- O ato seguinte é montado antes (troca contínua) com a estrada dele; o cenário novo não sabia da estrada viva e podia aparecer em cima dela no crossfade. Agora evita as duas.
- Lanternas saíram de 3,4 m para 4,4 m do eixo; as pedrinhas da beira (2,6–3,4 m, em cima da pista) saíram.

## Achados que não mexi
- Na captura do ato 1 perto do fim do ato, o chão do ato 2 (laranja) já aparece por baixo no crossfade da troca contínua, e a mesma cena varia entre execuções (o --skip não é determinístico). As capturas usam t = 250 s para não pegar isso.
- Árvores estilo 2, `tree_round` do ato 3 (V com duas vagens) é a mais fraca; refazer se esse estilo for o escolhido.
- Estilo 3 ato 1 tem copa de 5,8 m de largura (as antigas ~3 m).

## Capturas
`docs/cenario_proposito/` — `antes_todos` (como é hoje), `regioes_arv0..3`, `arvores/estilo1..3.png`, `videos/vento_0/1.mp4`.
Página de revisão: `python -I tools/revisao_visual/server.py` → http://127.0.0.1:8769, frente "Cenário com propósito".
Para refazer: `bash tools/capture_cenario.sh <pasta> "--cenario=1 --arvores=N"`; `--cenario_log` imprime regiões e contagem; `--cenario_map` grava o mapa das regiões em `user://`.
