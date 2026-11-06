# Progresso do marco 1

Feito (sessão de 06/11/2026):
- ARQUITETURA.md (pastas, simulação × visual, formato dos dados, bot, decisões e riscos assumidos).
- tools/xlsx_to_json.py e data/*.json gerados (32 cartas, 15 upgrades, 8 contratos, 3 decks, chefe, bots random/greedy).
- sim/k.gd, card_def.gd, game_data.gd, road.gd, units.gd, hero.gd (ainda não compilados nem testados).

Falta, nesta ordem:
1. sim/sim.gd (classe Sim: passo, comandos, elixir/mão/deck/sacrifício/anel, efeitos das cartas, zonas, XP/níveis, ofertas, locais, santuários, contratos, eventos, métricas) e sim/arena.gd (partes, altares, teleporte, finalizações). hero.gd e units.gd já chamam: emit, kill_unit, spawn_child, kamikaze, mimic_bite, unit_hits_hero, hero_hits_unit, hero_fear, on_shield_break, location_destroyed, zones, ai_period, tick, phase, arena.{bx,by,cx,cy,part_*,altar*}.
2. project.godot, locale/strings.csv, godot --headless --import, tests/tests.tscn.
3. bots/ (random, greedy), headless/batch.tscn, tools/run_batch.py e o relatório.
4. game/ (visual cinza com MultiMesh, HUD, minimapa, controles).
5. Medir desempenho, testar o executável exportado, criar a branch balance.
