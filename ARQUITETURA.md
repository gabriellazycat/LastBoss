# Arquitetura — Last Boss (marco 1)

## Pastas

```
project.godot
data/                 JSON: a fonte da verdade de todos os números (o ajustador edita aqui)
  rules.json          elixir, mão, anel, curvas de XP, arena, estrada, raridade, locais, ofertas, metas
  cards.json          as 32 cartas (campo, rota, covil, finalização) + unidades auxiliares (morcego, esqueleto…)
  modifiers.json      os 5 modificadores (Veterano, Barato, Explosivo, Amaldiçoado, Sombrio)
  hero_escudeiro.json atributos, curva, IA e os 15 upgrades
  boss_lorde.json     as 4 partes do corpo e os 3 decks iniciais
  contracts.json      os 8 contratos
  locked.json         valores que o ajustador nunca toca
  bots/*.json         uma personalidade por arquivo (random, greedy…)
sim/                  simulação: lógica pura (RefCounted, nenhum Node), passo fixo, determinística por semente
bots/                 bots do jogador (lógica pura; leem o Sim e devolvem comandos)
headless/             batch.tscn: roda N sementes sem janela e grava JSON
game/                 visual: cenas e Nodes que só leem o estado do Sim e desenham
locale/strings.csv    todo o texto (pt, en) via TranslationServer
tests/tests.tscn      testes (Node que roda no _ready e sai com código)
tools/                xlsx_to_json.py (conversão única), run_batch.py (lote paralelo + relatório)
reports/              saída dos lotes (ignorada no git, exceto os relatórios de ciclo na branch balance)
```

## Simulação × visual

- `Sim` (sim/sim.gd) é o único dono do estado. Passo fixo de 0,05 s (20 Hz). O RNG é um `RandomNumberGenerator` com semente registrada, e toda aleatoriedade passa por ele.
- Entrada só por **comandos** (`play`, `sacrifice`, `choose`, `teleport`, `route`). O humano e os bots geram os mesmos comandos, o que permite gravar e reproduzir uma run.
- As unidades ficam em **arrays paralelos** (PackedFloat32Array etc.) com lista livre: pooling sem nenhum objeto criado em combate. A grade espacial é uma janela fixa ao redor do herói, reconstruída por contagem (O(n)).
- A IA é escalonada: mapa de perigo e escolha de alvo a 5 Hz, decisões das unidades distribuídas entre ticks.
- O Sim emite uma lista de **eventos** por tick (dano, morte, spawn, level-up). O visual consome; o modo headless desliga a gravação.
- O visual (`game/`) roda o Sim num acumulador, interpola posição anterior → atual e desenha enxames com **MultiMeshInstance3D** (uma por tipo visual, capacidade pré-alocada). Números de dano e zonas usam pools de nós.

## Formato dos dados

Cada carta é um objeto com `id`, `category` (field/route/lair/finisher), `type`, `tags`, `archetype`, `rarity`, `cost`, `count` (unidades que nascem), `xp_parts` (divisor do XP, ex.: Slime 7), `hp`, `dps`, `attack_interval`, `speed`, `range` e um bloco `fx` com os parâmetros do efeito. Valores derivados (XP por unidade, limiares de nível) são calculados ao carregar, nunca gravados, para o ajustador mexer só nas causas.

## Como o bot roda

1. `godot --headless --path . res://headless/batch.tscn -- --bot=greedy --deck=horda --seeds=1-50 --out=reports/x.json`
2. `python tools/run_batch.py --bots random,greedy --decks horda,ruina,tesouro --runs 200` divide as sementes entre processos (um por núcleo), junta os JSON e gera `reports/<data>/report.md` + `summary.json` com as métricas contra as metas do DECISOES.md (nota única = distância às metas).
3. Cada run registra semente, deck, bot, resultado, tempo até a arena, níveis, cartas oferecidas/escolhidas, dano por carta, elixir desperdiçado e tempo de parede.

## Decisões que tomei no seu lugar (AFK) e riscos

- **Passo de 20 Hz** na simulação; o visual interpola. Risco: colisões rápidas menos precisas (aceitável para monstros a ≤ 6 m/s).
- **XP só quando o herói mata.** Kamikaze que explode, unidade sacrificada, ressuscitada, que expira ou que fica para trás (> 50 m) não dá XP.
- **Feitiços ignoram a distância mínima do anel** (só o máximo de 12 m vale), como no Clash. Monstros e estruturas respeitam 3–12 m.
- **Teleporte:** grátis com recarga de 8 s (o GDD deixava "8 s ou 2 de elixir"); o custo fica em dados (`teleport_cost: 0`).
- **Sacrifício** devolve 1 de elixir e manda a carta para o fim do deck (não remove).
- **Ofertas pausam a simulação** até a escolha (o bot escolhe na hora).
- **Dano do herói cresce 8% por nível** (a planilha não definia); fica em dados.
- **Esqueleto do Totem:** 60 de vida, 6 de DPS, perseguidor. **Morcego:** 30 de vida, 5 de DPS, 5 m/s. **Explosivo:** 40 de dano em 2 m. **Amaldiçoado:** 1 maldição por unidade a cada 5 s de acertos.
- **Contrato "Sem Testemunhas":** o contador de dano zera quando o herói ganha XP.
- **Recompensa "rara" de uma tag sem cartas raras** (Fogo, Sombra): cai para qualquer raridade daquela tag.
- **Pilares quebráveis da arena** e **salvamento no meio da run** ficam para depois do marco 1.
- Risco de desempenho: 15 min em < 5 s com GDScript. Se não bater, o laço das unidades vai para C# ou GDExtension (o plano B do GDD).

## Passos do marco 1

1. Conversão planilha → JSON, projeto Godot, git (main + balance), tradução pt/en.
2. Núcleo do Sim: dados, RNG, unidades em arrays, grade, eventos, comandos.
3. Estrada gerada (bifurcações, 6 locais, santuários), herói andando com IA por pontuação e escudo frontal.
4. Elixir, mão, deck, sacrifício, anel; os 7 arquétipos; deck Horda e depois as 18 cartas de campo.
5. XP/level-up do herói (15 upgrades), level-up do jogador (ofertas por raridade), modificadores, santuários, contratos, cartas de rota e de covil.
6. Arena: 4 partes, 5 altares, teleporte, 6 finalizações.
7. Bots Aleatório e Guloso, lote headless paralelo, relatório.
8. Visual cinza: estrada, MultiMesh, câmera isométrica, HUD completo, minimapa, controles (mouse, teclado e controle).
9. Testes (determinismo, regras, desempenho), exportação testada e commit.
