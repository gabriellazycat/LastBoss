# Objetivos das cartas: o que uma run alcança

`mediana` = valor típico por run (já na unidade do desafio); `cumpre` = fração das runs que bate a meta atual.
Desafios com `total`/`runs` somam várias fases: o valor aqui é o de UMA run (compare com meta ÷ nº de runs esperado).

## heuristic|dragon (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 71.2 | 71.5 | 49.9 | 95.6 | 0% | acumulado |
| bone_colossus | died | 3000 | 313.3 | 299.0 | 214.7 | 408.3 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 40.4 | 27.8 | 9.1 | 77.7 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 25.6 | 21.0 | 4.6 | 53.3 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1809.1 | 1572.2 | 1234.9 | 2662.6 | 0% | acumulado |
| mimic | plays | 60 | 19.6 | 18.0 | 11.6 | 29.1 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 606.1 | 593.0 | 396.7 | 844.6 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 116.5 | 116.0 | 85.9 | 155.1 | 0% | acumulado |
| pack_den | plays | 40 | 19.6 | 18.0 | 11.6 | 29.1 | 0% | acumulado |
| plague_carrion | peak | 40 | 11.8 | 11.0 | 8.0 | 15.2 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 233.1 | 224.0 | 163.6 | 325.9 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_collector | burst | 2000 | 1058.7 | 1112.0 | 776.2 | 1384.2 | 0% |  |
| soul_feast | plays | 400 | 71.2 | 71.5 | 49.9 | 95.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 551.2 | 497.5 | 318.5 | 904.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.0 | 5.0 | 4.0 | 6.0 | 5% |  |
| ash_phoenix | gold_end | 1000 | 331.1 | 285.0 | 23.7 | 633.5 | 5% | runs |
| elder_dragon | peak | 5 | 3.5 | 3.5 | 3.0 | 4.0 | 5% |  |
| gold_bait | coins | 25 | 16.4 | 14.5 | 11.8 | 23.0 | 5% | acumulado |
| meteor_storm | plays | 80 | 51.2 | 47.0 | 35.3 | 75.0 | 5% | acumulado |
| soul_storm | spells_distinct | 6 | 4.2 | 4.0 | 3.0 | 5.0 | 5% |  |
| blood_tax | plays | 100 | 71.2 | 71.5 | 49.9 | 95.6 | 10% | acumulado |
| dragon_exchange | soak_ignite | 1 | 0.1 | 0.0 | 0.0 | 0.1 | 10% |  |
| hollow_armor | elixir_max | 20 | 16.7 | 15.0 | 12.9 | 21.5 | 20% | runs |
| rat_tide | plays_same | 40 | 34.9 | 34.5 | 23.8 | 49.1 | 30% | runs |
| bat_nest | peak | 3 | 2.4 | 2.0 | 1.0 | 4.0 | 35% | runs |
| spike_trap | plays_window | 5 | 4.7 | 4.0 | 4.0 | 5.1 | 45% |  |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 75% |  |
| magma_golem | peak | 10 | 11.8 | 11.0 | 8.0 | 15.2 | 75% | runs |
| boiling_oil | soaked_time | 75 | 120.9 | 122.1 | 62.1 | 205.5 | 85% | acumulado |
| flooded_pit | plays | 5 | 25.6 | 21.0 | 4.6 | 53.3 | 90% | runs |
| spark | soak_ignite | 1 | 0.9 | 1.0 | 0.9 | 1.0 | 90% | runs |
| hunt_instinct | plays | 40 | 71.2 | 71.5 | 49.9 | 95.6 | 95% | acumulado |
| life_drain | curses | 5 | 8.8 | 10.0 | 6.0 | 10.0 | 95% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| ember_rain | plays | 25 | 71.2 | 71.5 | 49.9 | 95.6 | 100% | runs |

## heuristic|dragon@3 (n=20, vitória 95%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 1.6 | 0.0 | 0.0 | 1.5 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 91.6 | 90.0 | 66.0 | 119.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 410.6 | 415.0 | 315.7 | 505.8 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 35.8 | 37.9 | 12.0 | 64.4 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.2 | 0.0 | 0.0 | 0.2 | 0% | runs |
| forbidden_library | plays | 200 | 35.2 | 39.0 | 12.8 | 55.9 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.2 | 0.0 | 0.0 | 0.2 | 0% | runs |
| mimic | plays | 60 | 24.6 | 23.5 | 18.0 | 34.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 800.0 | 812.5 | 590.4 | 922.4 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 153.7 | 151.5 | 119.9 | 185.1 | 0% | acumulado |
| pack_den | plays | 40 | 24.6 | 23.5 | 18.0 | 34.0 | 0% | acumulado |
| plague_carrion | peak | 40 | 19.9 | 21.0 | 12.0 | 25.1 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.1 | 0% |  |
| shadow_mark | plays | 1000 | 305.2 | 292.0 | 260.5 | 368.1 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 91.6 | 90.0 | 66.0 | 119.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 1175.0 | 1067.5 | 776.5 | 1620.5 | 0% | acumulado |
| dragon_exchange | soak_ignite | 1 | 0.1 | 0.0 | 0.0 | 0.1 | 10% |  |
| soul_storm | spells_distinct | 6 | 4.3 | 4.0 | 3.0 | 5.1 | 10% |  |
| arcane_apocalypse | plays_window | 7 | 5.7 | 5.5 | 4.0 | 7.0 | 20% |  |
| meteor_storm | plays | 80 | 63.5 | 59.5 | 46.9 | 87.1 | 20% | acumulado |
| gold_avalanche | gold_earned | 6000 | 5338.6 | 5371.0 | 3323.0 | 7239.9 | 25% | acumulado |
| hollow_armor | elixir_max | 20 | 18.1 | 18.0 | 14.9 | 20.5 | 25% | runs |
| gold_bait | coins | 25 | 21.6 | 21.5 | 12.9 | 29.5 | 30% | acumulado |
| soul_collector | burst | 2000 | 1829.8 | 1754.6 | 1386.8 | 2318.5 | 40% |  |
| blood_tax | plays | 100 | 91.6 | 90.0 | 66.0 | 119.0 | 45% | acumulado |
| elder_dragon | peak | 5 | 4.8 | 5.0 | 3.0 | 6.1 | 60% |  |
| spike_trap | plays_window | 5 | 5.1 | 5.0 | 4.0 | 7.0 | 60% |  |
| ash_phoenix | gold_end | 1000 | 2109.7 | 1674.6 | 452.7 | 3703.9 | 70% | runs |
| bat_nest | peak | 3 | 2.9 | 3.0 | 2.0 | 4.0 | 70% | runs |
| rat_tide | plays_same | 40 | 46.0 | 44.0 | 35.8 | 62.4 | 70% | runs |
| boiling_oil | soaked_time | 75 | 143.9 | 133.8 | 72.4 | 226.4 | 85% | acumulado |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 95% |  |
| ember_rain | plays | 25 | 91.6 | 90.0 | 66.0 | 119.0 | 100% | runs |
| fallen_healer | loss_max | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| flooded_pit | plays | 5 | 35.2 | 39.0 | 12.8 | 55.9 | 100% | runs |
| hunt_instinct | plays | 40 | 91.6 | 90.0 | 66.0 | 119.0 | 100% | acumulado |
| life_drain | curses | 5 | 9.8 | 10.0 | 9.8 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 19.9 | 21.0 | 12.0 | 25.1 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## heuristic|lich (n=20, vitória 95%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| ash_phoenix | gold_end | 1000 | 344.0 | 334.9 | 180.1 | 512.5 | 0% | runs |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bat_nest | peak | 3 | 0.7 | 1.0 | 0.0 | 1.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 592.1 | 518.5 | 398.9 | 904.7 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 24.4 | 21.5 | 6.7 | 45.0 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 11.6 | 12.0 | 8.9 | 15.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 800.2 | 782.6 | 687.0 | 930.7 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 4.2 | 3.5 | 0.0 | 10.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 586.1 | 581.0 | 418.2 | 772.2 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 137.6 | 130.0 | 110.2 | 188.6 | 0% | acumulado |
| pack_den | plays | 40 | 4.2 | 3.5 | 0.0 | 10.0 | 0% | acumulado |
| plague_carrion | peak | 40 | 17.4 | 17.0 | 12.0 | 22.1 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 356.4 | 347.5 | 287.2 | 471.4 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 190.3 | 184.5 | 146.0 | 259.9 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 456.2 | 467.5 | 275.0 | 690.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 106.5 | 101.7 | 74.2 | 135.0 | 5% | acumulado |
| arcane_spark | plays | 120 | 86.3 | 83.5 | 55.0 | 116.4 | 10% | acumulado |
| hollow_armor | elixir_max | 20 | 18.7 | 17.5 | 12.0 | 29.1 | 20% | runs |
| soul_collector | burst | 2000 | 1518.0 | 1380.9 | 725.4 | 2479.8 | 25% |  |
| fallen_healer | loss_max | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 30% |  |
| eruption | win_without | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 35% |  |
| soul_harvest | win_without | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 35% | runs |
| life_drain | curses | 5 | 5.0 | 4.0 | 0.0 | 10.0 | 50% | runs |
| shadow_echo | plays_window | 5 | 4.8 | 5.0 | 4.0 | 6.0 | 55% |  |
| eternal_army | peak | 12 | 11.9 | 12.0 | 9.0 | 15.0 | 60% | runs |
| rat_tide | plays_same | 40 | 46.5 | 48.5 | 30.4 | 61.5 | 65% | runs |
| soul_storm | spells_distinct | 6 | 5.8 | 6.0 | 5.0 | 6.1 | 70% |  |
| black_pestilence | plays | 150 | 190.3 | 184.5 | 146.0 | 259.9 | 85% | acumulado |
| flooded_pit | plays | 5 | 24.4 | 21.5 | 6.7 | 45.0 | 90% | runs |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 95% |  |
| arcane_apocalypse | plays_window | 7 | 11.0 | 11.0 | 8.9 | 12.1 | 100% |  |
| blood_tax | plays | 100 | 190.3 | 184.5 | 146.0 | 259.9 | 100% | acumulado |
| ember_rain | plays | 25 | 190.3 | 184.5 | 146.0 | 259.9 | 100% | runs |
| hunt_instinct | plays | 40 | 190.3 | 184.5 | 146.0 | 259.9 | 100% | acumulado |
| magma_golem | peak | 10 | 17.4 | 17.0 | 12.0 | 22.1 | 100% | runs |
| spike_trap | plays_window | 5 | 8.3 | 8.0 | 6.0 | 11.0 | 100% |  |

## heuristic|lich@3 (n=20, vitória 95%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 683.1 | 683.5 | 512.4 | 844.3 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 26.1 | 24.0 | 6.9 | 49.0 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 19.9 | 17.0 | 12.9 | 28.6 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1953.4 | 1906.9 | 1683.0 | 2294.3 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 2.9 | 0.0 | 0.0 | 9.1 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 689.6 | 698.0 | 572.3 | 800.9 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 164.3 | 163.0 | 125.7 | 205.3 | 0% | acumulado |
| pack_den | plays | 40 | 2.9 | 0.0 | 0.0 | 9.1 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 412.4 | 408.0 | 334.8 | 501.3 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 219.2 | 217.5 | 161.0 | 273.8 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 514.5 | 455.0 | 344.0 | 818.5 | 0% | acumulado |
| bat_nest | peak | 3 | 0.8 | 0.0 | 0.0 | 2.0 | 5% | runs |
| arcane_spark | plays | 120 | 105.5 | 102.0 | 73.5 | 135.6 | 20% | acumulado |
| burn_village | burn_time | 150 | 131.1 | 113.6 | 79.8 | 202.7 | 20% | acumulado |
| hollow_armor | elixir_max | 20 | 18.9 | 16.0 | 12.0 | 27.1 | 30% | runs |
| life_drain | curses | 5 | 4.3 | 3.0 | 0.0 | 10.0 | 45% | runs |
| plague_carrion | peak | 40 | 37.5 | 36.5 | 18.9 | 55.2 | 45% | runs |
| eruption | win_without | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 55% |  |
| soul_harvest | win_without | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 55% | runs |
| shadow_echo | plays_window | 5 | 5.5 | 5.0 | 4.0 | 8.0 | 75% |  |
| ash_phoenix | gold_end | 1000 | 1438.9 | 1377.7 | 962.6 | 1939.1 | 85% | runs |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 85% |  |
| rat_tide | plays_same | 40 | 53.3 | 52.0 | 35.8 | 68.5 | 85% | runs |
| soul_storm | spells_distinct | 6 | 6.2 | 6.0 | 5.0 | 7.0 | 85% |  |
| black_pestilence | plays | 150 | 219.2 | 217.5 | 161.0 | 273.8 | 90% | acumulado |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 95% |  |
| soul_collector | burst | 2000 | 3748.3 | 3632.5 | 2151.5 | 5731.6 | 95% |  |
| arcane_apocalypse | plays_window | 7 | 12.4 | 12.0 | 9.0 | 16.1 | 100% |  |
| blood_tax | plays | 100 | 219.2 | 217.5 | 161.0 | 273.8 | 100% | acumulado |
| ember_rain | plays | 25 | 219.2 | 217.5 | 161.0 | 273.8 | 100% | runs |
| eternal_army | peak | 12 | 20.2 | 18.5 | 13.0 | 29.5 | 100% | runs |
| flooded_pit | plays | 5 | 26.1 | 24.0 | 6.9 | 49.0 | 100% | runs |
| hunt_instinct | plays | 40 | 219.2 | 217.5 | 161.0 | 273.8 | 100% | acumulado |
| magma_golem | peak | 10 | 37.5 | 36.5 | 18.9 | 55.2 | 100% | runs |
| spike_trap | plays_window | 5 | 9.4 | 9.0 | 8.0 | 12.0 | 100% |  |

## heuristic|plague (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.4 | 3.0 | 3.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 555.5 | 507.2 | 410.4 | 777.7 | 0% | runs |
| black_pestilence | plays | 150 | 33.2 | 31.5 | 22.8 | 49.1 | 0% | acumulado |
| blood_tax | plays | 100 | 33.2 | 31.5 | 22.8 | 49.1 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 811.8 | 750.5 | 507.1 | 1164.3 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 586.9 | 518.5 | 336.7 | 890.7 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 3.5 | 0.0 | 0.0 | 11.6 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 924.3 | 846.1 | 725.1 | 1233.6 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 13.0 | 10.5 | 5.9 | 19.6 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 496.1 | 508.5 | 357.8 | 651.7 | 0% | acumulado |
| ogre | plays | 600 | 134.2 | 138.0 | 93.5 | 165.8 | 0% | acumulado |
| pack_den | plays | 40 | 13.0 | 10.5 | 5.9 | 19.6 | 0% | acumulado |
| primal_beast | plays | 600 | 76.8 | 76.0 | 56.3 | 92.8 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 184.0 | 188.5 | 127.7 | 218.3 | 0% | acumulado |
| soul_collector | burst | 2000 | 1175.3 | 1115.6 | 807.0 | 1672.9 | 0% |  |
| soul_feast | plays | 400 | 33.2 | 31.5 | 22.8 | 49.1 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 3.6 | 3.5 | 3.0 | 4.1 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 49.4 | 49.0 | 32.8 | 65.2 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 368.8 | 365.0 | 125.0 | 557.0 | 0% | acumulado |
| bat_nest | peak | 3 | 1.5 | 1.0 | 1.0 | 2.1 | 10% | runs |
| hollow_armor | elixir_max | 20 | 15.9 | 15.5 | 12.0 | 19.2 | 10% | runs |
| rat_tide | plays_same | 40 | 31.9 | 30.0 | 21.8 | 45.5 | 15% | runs |
| hunt_instinct | plays | 40 | 33.2 | 31.5 | 22.8 | 49.1 | 20% | acumulado |
| life_drain | curses | 5 | 2.0 | 0.0 | 0.0 | 10.0 | 20% | runs |
| flooded_pit | plays | 5 | 3.5 | 0.0 | 0.0 | 11.6 | 25% | runs |
| mother_nest | peak_on_spell | 20 | 16.5 | 13.0 | 9.0 | 24.0 | 30% | runs |
| plague_carrion | peak | 40 | 32.5 | 31.5 | 18.0 | 47.1 | 35% | runs |
| spike_trap | plays_window | 5 | 4.3 | 4.0 | 3.0 | 6.0 | 35% |  |
| alpha_beast | peak | 30 | 28.4 | 28.0 | 14.7 | 45.0 | 40% |  |
| fallen_healer | loss_max | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 60% |  |
| ember_rain | plays | 25 | 33.2 | 31.5 | 22.8 | 49.1 | 80% | runs |
| slime | peak_multi | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 95% |  |
| bat_cloud | peak | 12 | 28.6 | 28.0 | 14.7 | 45.0 | 100% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| magma_golem | peak | 10 | 32.5 | 31.5 | 18.0 | 47.1 | 100% | runs |
| rat_trap | peste | 5 | 14.5 | 15.0 | 12.9 | 15.0 | 100% | runs |

## heuristic|plague@3 (n=20, vitória 95%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.8 | 4.0 | 2.9 | 5.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 51.6 | 45.0 | 35.8 | 78.2 | 0% | acumulado |
| blood_tax | plays | 100 | 51.6 | 45.0 | 35.8 | 78.2 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1312.5 | 1274.0 | 913.0 | 1904.4 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 973.0 | 900.5 | 660.9 | 1561.8 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 4.8 | 0.0 | 0.0 | 12.0 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 2104.3 | 2095.7 | 1738.3 | 2454.6 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 818.6 | 790.0 | 543.0 | 1087.4 | 0% | acumulado |
| ogre | plays | 600 | 205.1 | 202.5 | 136.9 | 266.5 | 0% | acumulado |
| primal_beast | plays | 600 | 121.0 | 115.0 | 86.3 | 180.3 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 285.1 | 269.0 | 201.2 | 399.1 | 0% | acumulado |
| soul_feast | plays | 400 | 51.6 | 45.0 | 35.8 | 78.2 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 3.9 | 4.0 | 3.0 | 4.1 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 73.6 | 73.0 | 46.0 | 96.7 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 589.8 | 552.5 | 269.5 | 905.0 | 0% | acumulado |
| mimic | plays | 60 | 23.5 | 21.0 | 11.9 | 34.2 | 5% | acumulado |
| pack_den | plays | 40 | 23.5 | 21.0 | 11.9 | 34.2 | 5% | acumulado |
| flooded_pit | plays | 5 | 4.8 | 0.0 | 0.0 | 12.0 | 15% | runs |
| bat_nest | peak | 3 | 1.9 | 1.5 | 1.0 | 3.1 | 20% | runs |
| life_drain | curses | 5 | 3.8 | 1.0 | 0.0 | 10.0 | 40% | runs |
| hollow_armor | elixir_max | 20 | 19.1 | 19.0 | 13.9 | 26.1 | 50% | runs |
| fallen_healer | loss_max | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 70% |  |
| rat_tide | plays_same | 40 | 43.9 | 41.5 | 29.6 | 53.8 | 70% | runs |
| soul_collector | burst | 2000 | 2536.5 | 2628.2 | 1647.7 | 3627.6 | 70% |  |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 6.2 | 70% |  |
| plague_carrion | peak | 40 | 57.3 | 61.0 | 35.9 | 84.1 | 75% | runs |
| mother_nest | peak_on_spell | 20 | 38.5 | 36.5 | 15.7 | 65.7 | 80% | runs |
| hunt_instinct | plays | 40 | 51.6 | 45.0 | 35.8 | 78.2 | 85% | acumulado |
| alpha_beast | peak | 30 | 49.7 | 53.0 | 28.9 | 73.0 | 90% |  |
| ash_phoenix | gold_end | 1000 | 1514.6 | 1499.3 | 1178.0 | 1864.1 | 95% | runs |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 95% |  |
| bat_cloud | peak | 12 | 50.1 | 53.0 | 29.8 | 74.1 | 100% | runs |
| ember_rain | plays | 25 | 51.6 | 45.0 | 35.8 | 78.2 | 100% | runs |
| magma_golem | peak | 10 | 57.3 | 61.0 | 35.9 | 84.1 | 100% | runs |
| rat_trap | peste | 5 | 14.8 | 15.0 | 14.9 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_careful|dragon (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 36.0 | 35.5 | 26.8 | 47.5 | 0% | acumulado |
| blood_tax | plays | 100 | 36.0 | 35.5 | 26.8 | 47.5 | 0% | acumulado |
| bone_colossus | died | 3000 | 213.2 | 212.5 | 177.8 | 257.5 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 46.7 | 43.8 | 27.5 | 82.1 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 3.5 | 3.5 | 3.0 | 4.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 14.4 | 13.0 | 0.0 | 27.9 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1762.5 | 1740.3 | 1167.5 | 2321.5 | 0% | acumulado |
| gold_bait | coins | 25 | 9.9 | 10.0 | 7.0 | 12.1 | 0% | acumulado |
| meteor_storm | plays | 80 | 24.6 | 25.0 | 16.5 | 33.6 | 0% | acumulado |
| mimic | plays | 60 | 12.6 | 11.5 | 9.0 | 17.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 383.3 | 376.0 | 301.2 | 469.7 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 90.0 | 89.5 | 75.5 | 107.4 | 0% | acumulado |
| pack_den | plays | 40 | 12.6 | 11.5 | 9.0 | 17.0 | 0% | acumulado |
| plague_carrion | peak | 40 | 11.7 | 11.5 | 9.0 | 14.1 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_tide | plays_same | 40 | 23.2 | 22.5 | 18.9 | 30.1 | 0% | runs |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 153.1 | 155.0 | 126.8 | 189.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_collector | burst | 2000 | 1019.3 | 1014.8 | 755.6 | 1261.1 | 0% |  |
| soul_feast | plays | 400 | 36.0 | 35.5 | 26.8 | 47.5 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 3.6 | 4.0 | 3.0 | 4.1 | 0% |  |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 531.2 | 550.0 | 325.5 | 752.0 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 291.3 | 100.8 | 3.9 | 694.6 | 5% | runs |
| hollow_armor | elixir_max | 20 | 13.3 | 13.0 | 11.0 | 15.1 | 5% | runs |
| arcane_apocalypse | plays_window | 7 | 5.0 | 5.0 | 4.0 | 6.1 | 10% |  |
| bat_nest | peak | 3 | 2.1 | 2.0 | 2.0 | 3.0 | 15% | runs |
| hunt_instinct | plays | 40 | 36.0 | 35.5 | 26.8 | 47.5 | 20% | acumulado |
| dragon_exchange | soak_ignite | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 40% |  |
| spike_trap | plays_window | 5 | 4.7 | 5.0 | 4.0 | 5.1 | 60% |  |
| boiling_oil | soaked_time | 75 | 82.6 | 79.7 | 51.2 | 106.9 | 70% | acumulado |
| life_drain | curses | 5 | 7.6 | 10.0 | 3.8 | 10.0 | 75% | runs |
| magma_golem | peak | 10 | 11.7 | 11.5 | 9.0 | 14.1 | 75% | runs |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 80% |  |
| flooded_pit | plays | 5 | 14.4 | 13.0 | 0.0 | 27.9 | 80% | runs |
| ember_rain | plays | 25 | 36.0 | 35.5 | 26.8 | 47.5 | 95% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_careful|dragon@3 (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 55.1 | 53.0 | 38.4 | 71.5 | 0% | acumulado |
| bone_colossus | died | 3000 | 327.6 | 329.0 | 260.9 | 396.5 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 28.9 | 29.0 | 1.8 | 50.1 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_bait | coins | 25 | 14.1 | 14.0 | 9.0 | 18.2 | 0% | acumulado |
| meteor_storm | plays | 80 | 38.7 | 37.0 | 26.8 | 52.6 | 0% | acumulado |
| mimic | plays | 60 | 18.2 | 16.5 | 13.0 | 29.1 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 629.0 | 625.0 | 515.3 | 774.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 134.3 | 131.5 | 108.9 | 167.3 | 0% | acumulado |
| pack_den | plays | 40 | 18.2 | 16.5 | 13.0 | 29.1 | 0% | acumulado |
| plague_carrion | peak | 40 | 21.6 | 21.5 | 15.6 | 26.6 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 236.9 | 228.0 | 187.9 | 287.1 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 55.1 | 53.0 | 38.4 | 71.5 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 4.4 | 4.5 | 3.9 | 5.0 | 0% |  |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| blood_tax | plays | 100 | 55.1 | 53.0 | 38.4 | 71.5 | 5% | acumulado |
| burn_village | burn_time | 150 | 75.6 | 71.8 | 38.8 | 118.2 | 5% | acumulado |
| tar_net | gold_spent | 2000 | 1072.0 | 960.0 | 672.0 | 1544.5 | 5% | acumulado |
| hollow_armor | elixir_max | 20 | 16.2 | 14.5 | 12.9 | 19.3 | 10% | runs |
| rat_tide | plays_same | 40 | 34.9 | 34.5 | 27.9 | 44.2 | 15% | runs |
| arcane_apocalypse | plays_window | 7 | 5.3 | 5.0 | 4.0 | 7.0 | 20% |  |
| soul_collector | burst | 2000 | 1729.5 | 1607.8 | 1342.1 | 2229.3 | 20% |  |
| gold_avalanche | gold_earned | 6000 | 5044.2 | 4146.8 | 2908.3 | 8380.5 | 30% | acumulado |
| elder_dragon | peak | 5 | 4.5 | 4.0 | 3.0 | 7.0 | 40% |  |
| ash_phoenix | gold_end | 1000 | 2002.8 | 1117.2 | 1.9 | 5444.3 | 50% | runs |
| bat_nest | peak | 3 | 3.0 | 3.0 | 2.0 | 4.1 | 65% | runs |
| fallen_healer | loss_max | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 70% |  |
| dragon_exchange | soak_ignite | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 75% |  |
| spike_trap | plays_window | 5 | 5.3 | 5.0 | 4.0 | 7.0 | 75% |  |
| boiling_oil | soaked_time | 75 | 133.1 | 134.9 | 66.9 | 198.8 | 85% | acumulado |
| flooded_pit | plays | 5 | 28.9 | 29.0 | 1.8 | 50.1 | 85% | runs |
| hunt_instinct | plays | 40 | 55.1 | 53.0 | 38.4 | 71.5 | 85% | acumulado |
| life_drain | curses | 5 | 8.9 | 10.0 | 6.0 | 10.0 | 95% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| ember_rain | plays | 25 | 55.1 | 53.0 | 38.4 | 71.5 | 100% | runs |
| magma_golem | peak | 10 | 21.6 | 21.5 | 15.6 | 26.6 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_careful|lich (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 69.5 | 72.0 | 45.7 | 89.9 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 351.3 | 347.4 | 180.4 | 495.0 | 0% | runs |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 408.4 | 385.0 | 281.5 | 519.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 82.6 | 79.7 | 50.5 | 113.9 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 27.3 | 18.0 | 8.8 | 53.8 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 14.0 | 12.0 | 9.8 | 20.7 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 760.8 | 747.1 | 690.1 | 880.2 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 3.2 | 1.5 | 0.0 | 9.1 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 479.8 | 451.0 | 354.7 | 629.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 103.8 | 93.0 | 82.4 | 135.4 | 0% | acumulado |
| pack_den | plays | 40 | 3.2 | 1.5 | 0.0 | 9.1 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 283.8 | 265.0 | 200.1 | 367.5 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 149.4 | 148.5 | 98.0 | 194.2 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 409.5 | 382.5 | 219.5 | 602.5 | 0% | acumulado |
| bat_nest | peak | 3 | 0.7 | 1.0 | 0.0 | 1.1 | 5% | runs |
| plague_carrion | peak | 40 | 20.2 | 19.0 | 13.0 | 32.1 | 5% | runs |
| hollow_armor | elixir_max | 20 | 17.2 | 14.0 | 12.9 | 26.1 | 20% | runs |
| rat_tide | plays_same | 40 | 33.1 | 29.5 | 22.7 | 49.3 | 25% | runs |
| life_drain | curses | 5 | 2.9 | 0.0 | 0.0 | 10.0 | 30% | runs |
| eruption | win_without | 1 | 0.5 | 0.0 | 0.0 | 1.0 | 45% |  |
| soul_harvest | win_without | 1 | 0.5 | 0.0 | 0.0 | 1.0 | 45% | runs |
| black_pestilence | plays | 150 | 149.4 | 148.5 | 98.0 | 194.2 | 50% | acumulado |
| soul_collector | burst | 2000 | 2159.4 | 2284.8 | 839.2 | 3630.5 | 55% |  |
| soul_storm | spells_distinct | 6 | 5.7 | 6.0 | 5.0 | 7.0 | 55% |  |
| shadow_echo | plays_window | 5 | 5.1 | 5.0 | 4.0 | 7.0 | 65% |  |
| eternal_army | peak | 12 | 14.3 | 12.0 | 9.9 | 20.7 | 75% | runs |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 75% |  |
| blood_tax | plays | 100 | 149.4 | 148.5 | 98.0 | 194.2 | 80% | acumulado |
| flooded_pit | plays | 5 | 27.3 | 18.0 | 8.8 | 53.8 | 95% | runs |
| arcane_apocalypse | plays_window | 7 | 11.6 | 11.0 | 8.0 | 14.2 | 100% |  |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| ember_rain | plays | 25 | 149.4 | 148.5 | 98.0 | 194.2 | 100% | runs |
| hunt_instinct | plays | 40 | 149.4 | 148.5 | 98.0 | 194.2 | 100% | acumulado |
| magma_golem | peak | 10 | 20.2 | 19.0 | 13.0 | 32.1 | 100% | runs |
| spike_trap | plays_window | 5 | 7.8 | 8.0 | 6.0 | 9.3 | 100% |  |

## human_careful|lich@3 (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 634.0 | 590.5 | 458.7 | 794.3 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 42.3 | 37.5 | 6.0 | 87.3 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 18.0 | 16.0 | 13.0 | 25.2 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 2000.4 | 1988.7 | 1659.4 | 2376.7 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 9.4 | 10.0 | 0.0 | 21.4 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 721.6 | 680.5 | 512.5 | 981.7 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 150.4 | 148.0 | 89.8 | 189.7 | 0% | acumulado |
| pack_den | plays | 40 | 9.4 | 10.0 | 0.0 | 21.4 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 416.4 | 405.0 | 290.6 | 543.7 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 214.2 | 218.0 | 129.9 | 279.9 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 680.2 | 627.5 | 270.0 | 1172.0 | 0% | acumulado |
| bat_nest | peak | 3 | 1.6 | 1.0 | 0.0 | 3.2 | 15% | runs |
| arcane_spark | plays | 120 | 99.7 | 101.5 | 57.6 | 137.1 | 25% | acumulado |
| plague_carrion | peak | 40 | 36.2 | 38.0 | 22.8 | 47.3 | 25% | runs |
| burn_village | burn_time | 150 | 138.9 | 117.9 | 70.2 | 242.6 | 30% | acumulado |
| eruption | win_without | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 30% |  |
| soul_harvest | win_without | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 30% | runs |
| hollow_armor | elixir_max | 20 | 21.2 | 20.0 | 14.9 | 27.1 | 50% | runs |
| life_drain | curses | 5 | 5.0 | 4.5 | 0.0 | 10.0 | 50% | runs |
| rat_tide | plays_same | 40 | 47.4 | 43.0 | 29.9 | 73.1 | 55% | runs |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 75% |  |
| soul_storm | spells_distinct | 6 | 5.8 | 6.0 | 5.0 | 6.1 | 75% |  |
| black_pestilence | plays | 150 | 214.2 | 218.0 | 129.9 | 279.9 | 80% | acumulado |
| shadow_echo | plays_window | 5 | 5.8 | 6.0 | 4.0 | 7.1 | 80% |  |
| soul_collector | burst | 2000 | 3904.8 | 3780.6 | 1785.9 | 5858.6 | 85% |  |
| ash_phoenix | gold_end | 1000 | 1320.1 | 1343.7 | 995.6 | 1778.8 | 90% | runs |
| arcane_apocalypse | plays_window | 7 | 12.7 | 12.0 | 10.0 | 15.1 | 100% |  |
| blood_tax | plays | 100 | 214.2 | 218.0 | 129.9 | 279.9 | 100% | acumulado |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| ember_rain | plays | 25 | 214.2 | 218.0 | 129.9 | 279.9 | 100% | runs |
| eternal_army | peak | 12 | 18.2 | 16.5 | 13.0 | 25.2 | 100% | runs |
| flooded_pit | plays | 5 | 42.3 | 37.5 | 6.0 | 87.3 | 100% | runs |
| hunt_instinct | plays | 40 | 214.2 | 218.0 | 129.9 | 279.9 | 100% | acumulado |
| magma_golem | peak | 10 | 36.2 | 38.0 | 22.8 | 47.3 | 100% | runs |
| spike_trap | plays_window | 5 | 8.1 | 8.0 | 7.0 | 9.3 | 100% |  |

## human_careful|plague (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.5 | 3.0 | 3.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 438.0 | 423.0 | 223.7 | 650.3 | 0% | runs |
| black_pestilence | plays | 150 | 31.6 | 31.0 | 24.4 | 40.2 | 0% | acumulado |
| blood_tax | plays | 100 | 31.6 | 31.0 | 24.4 | 40.2 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 745.8 | 746.5 | 467.7 | 990.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 547.6 | 555.5 | 291.1 | 743.2 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 5.8 | 6.0 | 0.0 | 13.0 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 866.5 | 870.4 | 729.8 | 1000.1 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 10.9 | 9.0 | 4.9 | 21.3 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 454.6 | 450.0 | 314.8 | 595.5 | 0% | acumulado |
| ogre | plays | 600 | 116.7 | 119.5 | 89.0 | 147.7 | 0% | acumulado |
| pack_den | plays | 40 | 10.9 | 9.0 | 4.9 | 21.3 | 0% | acumulado |
| primal_beast | plays | 600 | 70.5 | 73.0 | 46.9 | 90.3 | 0% | acumulado |
| rat_tide | plays_same | 40 | 25.6 | 26.5 | 18.7 | 33.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 165.1 | 170.0 | 127.3 | 202.2 | 0% | acumulado |
| soul_feast | plays | 400 | 31.6 | 31.0 | 24.4 | 40.2 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 3.7 | 4.0 | 3.0 | 4.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 42.2 | 42.5 | 32.7 | 54.1 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 428.5 | 407.5 | 268.0 | 578.5 | 0% | acumulado |
| bat_nest | peak | 3 | 1.4 | 1.0 | 1.0 | 2.0 | 5% | runs |
| hollow_armor | elixir_max | 20 | 16.2 | 15.5 | 13.0 | 20.2 | 15% | runs |
| hunt_instinct | plays | 40 | 31.6 | 31.0 | 24.4 | 40.2 | 15% | acumulado |
| soul_collector | burst | 2000 | 1435.6 | 1204.2 | 981.9 | 2132.8 | 15% |  |
| mother_nest | peak_on_spell | 20 | 21.1 | 17.0 | 9.8 | 37.8 | 30% | runs |
| plague_carrion | peak | 40 | 34.4 | 31.5 | 19.8 | 52.4 | 30% | runs |
| alpha_beast | peak | 30 | 30.2 | 24.0 | 16.9 | 49.5 | 40% |  |
| flooded_pit | plays | 5 | 5.8 | 6.0 | 0.0 | 13.0 | 50% | runs |
| spike_trap | plays_window | 5 | 4.8 | 4.5 | 4.0 | 6.0 | 50% |  |
| life_drain | curses | 5 | 5.5 | 7.0 | 0.0 | 10.0 | 55% | runs |
| fallen_healer | loss_max | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 65% |  |
| ember_rain | plays | 25 | 31.6 | 31.0 | 24.4 | 40.2 | 90% | runs |
| bat_cloud | peak | 12 | 30.7 | 25.0 | 16.9 | 49.5 | 100% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| magma_golem | peak | 10 | 34.4 | 31.5 | 19.8 | 52.4 | 100% | runs |
| rat_trap | peste | 5 | 14.6 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_careful|plague@3 (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.5 | 3.0 | 3.0 | 4.1 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 40.0 | 38.5 | 30.0 | 51.1 | 0% | acumulado |
| blood_tax | plays | 100 | 40.0 | 38.5 | 30.0 | 51.1 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1145.8 | 1006.5 | 827.0 | 1560.3 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 853.9 | 735.5 | 563.7 | 1200.3 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 8.3 | 8.0 | 0.0 | 22.5 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.9 | 0.0 | 0.0 | 0.6 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1976.0 | 1953.4 | 1606.6 | 2438.0 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 13.7 | 12.0 | 7.0 | 20.1 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 664.2 | 636.0 | 511.9 | 846.5 | 0% | acumulado |
| ogre | plays | 600 | 167.7 | 158.0 | 134.3 | 214.4 | 0% | acumulado |
| pack_den | plays | 40 | 13.7 | 12.0 | 7.0 | 20.1 | 0% | acumulado |
| primal_beast | plays | 600 | 94.0 | 89.5 | 71.6 | 119.1 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 229.7 | 224.5 | 188.6 | 282.4 | 0% | acumulado |
| soul_feast | plays | 400 | 40.0 | 38.5 | 30.0 | 51.1 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 62.4 | 55.5 | 46.1 | 82.1 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 629.8 | 552.5 | 279.5 | 1239.5 | 0% | acumulado |
| bat_nest | peak | 3 | 1.4 | 1.0 | 1.0 | 2.0 | 5% | runs |
| eternal_army | peak | 12 | 0.9 | 0.0 | 0.0 | 0.6 | 5% | runs |
| soul_storm | spells_distinct | 6 | 4.0 | 4.0 | 3.0 | 4.1 | 5% |  |
| hollow_armor | elixir_max | 20 | 17.5 | 17.0 | 12.9 | 22.3 | 25% | runs |
| rat_tide | plays_same | 40 | 34.9 | 35.5 | 24.7 | 44.1 | 35% | runs |
| hunt_instinct | plays | 40 | 40.0 | 38.5 | 30.0 | 51.1 | 45% | acumulado |
| life_drain | curses | 5 | 4.8 | 5.0 | 0.0 | 10.0 | 50% | runs |
| flooded_pit | plays | 5 | 8.3 | 8.0 | 0.0 | 22.5 | 55% | runs |
| spike_trap | plays_window | 5 | 4.8 | 5.0 | 4.0 | 6.0 | 65% |  |
| ash_phoenix | gold_end | 1000 | 1346.2 | 1415.7 | 753.2 | 1806.5 | 70% | runs |
| fallen_healer | loss_max | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 70% |  |
| mother_nest | peak_on_spell | 20 | 36.1 | 33.5 | 15.9 | 57.6 | 70% | runs |
| soul_collector | burst | 2000 | 2418.4 | 2391.0 | 1715.9 | 3034.6 | 70% |  |
| plague_carrion | peak | 40 | 58.8 | 57.5 | 37.5 | 81.5 | 85% | runs |
| alpha_beast | peak | 30 | 50.7 | 47.5 | 29.3 | 74.2 | 90% |  |
| bat_cloud | peak | 12 | 51.4 | 48.5 | 29.3 | 76.0 | 100% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| ember_rain | plays | 25 | 40.0 | 38.5 | 30.0 | 51.1 | 100% | runs |
| magma_golem | peak | 10 | 58.8 | 57.5 | 37.5 | 81.5 | 100% | runs |
| rat_trap | peste | 5 | 15.0 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_novice|dragon (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 1.1 | 0.0 | 0.0 | 0.6 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 129.2 | 70.0 | 0.4 | 396.7 | 0% | runs |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 40.4 | 40.5 | 22.6 | 54.7 | 0% | acumulado |
| blood_tax | plays | 100 | 40.4 | 40.5 | 22.6 | 54.7 | 0% | acumulado |
| bone_colossus | died | 3000 | 205.8 | 200.0 | 154.4 | 273.4 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 44.7 | 35.4 | 22.5 | 68.6 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 12.6 | 10.5 | 3.9 | 24.2 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1478.8 | 1540.7 | 962.4 | 1941.9 | 0% | acumulado |
| meteor_storm | plays | 80 | 25.8 | 25.0 | 13.8 | 37.1 | 0% | acumulado |
| mimic | plays | 60 | 12.7 | 12.0 | 8.9 | 16.3 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 380.9 | 388.0 | 279.1 | 479.2 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 88.2 | 89.5 | 67.4 | 111.6 | 0% | acumulado |
| pack_den | plays | 40 | 12.7 | 12.0 | 8.9 | 16.3 | 0% | acumulado |
| plague_carrion | peak | 40 | 11.9 | 12.0 | 9.0 | 14.1 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_tide | plays_same | 40 | 22.4 | 22.5 | 17.6 | 30.1 | 0% | runs |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.1 | 0% |  |
| shadow_mark | plays | 1000 | 155.3 | 164.5 | 112.6 | 193.5 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_collector | burst | 2000 | 932.2 | 850.5 | 699.9 | 1241.4 | 0% |  |
| soul_feast | plays | 400 | 40.4 | 40.5 | 22.6 | 54.7 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 531.5 | 552.5 | 257.0 | 790.5 | 0% | acumulado |
| elder_dragon | peak | 5 | 3.3 | 3.0 | 3.0 | 4.0 | 5% |  |
| gold_bait | coins | 25 | 10.7 | 9.5 | 6.0 | 15.2 | 5% | acumulado |
| hollow_armor | elixir_max | 20 | 12.7 | 12.0 | 10.9 | 15.2 | 5% | runs |
| soul_storm | spells_distinct | 6 | 3.8 | 3.0 | 3.0 | 5.1 | 10% |  |
| bat_nest | peak | 3 | 2.0 | 2.0 | 1.9 | 3.0 | 15% | runs |
| arcane_apocalypse | plays_window | 7 | 5.1 | 5.0 | 4.0 | 7.1 | 20% |  |
| dragon_exchange | soak_ignite | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 25% |  |
| hunt_instinct | plays | 40 | 40.4 | 40.5 | 22.6 | 54.7 | 50% | acumulado |
| boiling_oil | soaked_time | 75 | 83.7 | 78.0 | 42.5 | 157.1 | 55% | acumulado |
| spike_trap | plays_window | 5 | 4.8 | 5.0 | 4.0 | 6.0 | 55% |  |
| life_drain | curses | 5 | 7.4 | 9.0 | 3.8 | 10.0 | 75% | runs |
| magma_golem | peak | 10 | 11.9 | 12.0 | 9.0 | 14.1 | 80% | runs |
| ember_rain | plays | 25 | 40.4 | 40.5 | 22.6 | 54.7 | 85% | runs |
| flooded_pit | plays | 5 | 12.6 | 10.5 | 3.9 | 24.2 | 85% | runs |
| fallen_healer | loss_max | 1 | 0.9 | 1.0 | 0.9 | 1.0 | 90% |  |
| spark | soak_ignite | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 95% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_novice|dragon@3 (n=20, vitória 90%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 1.6 | 0.0 | 0.0 | 6.1 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 71.3 | 74.0 | 59.8 | 83.0 | 0% | acumulado |
| blood_tax | plays | 100 | 71.3 | 74.0 | 59.8 | 83.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 361.4 | 338.5 | 252.2 | 443.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.7 | 7.0 | 6.7 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 0.9 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.7 | 7.0 | 6.7 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.3 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 19.6 | 18.5 | 0.9 | 38.4 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 0.9 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.3 | 0.0 | 0.0 | 0.0 | 0% | runs |
| meteor_storm | plays | 80 | 47.7 | 47.0 | 36.0 | 59.2 | 0% | acumulado |
| mimic | plays | 60 | 19.8 | 19.0 | 13.9 | 25.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 677.0 | 698.0 | 520.6 | 817.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 149.1 | 148.0 | 115.8 | 182.6 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 0.9 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 259.8 | 257.5 | 212.3 | 304.9 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 71.3 | 74.0 | 59.8 | 83.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 72.4 | 56.2 | 39.8 | 109.1 | 5% | acumulado |
| gold_bait | coins | 25 | 14.1 | 13.5 | 10.0 | 17.3 | 5% | acumulado |
| pack_den | plays | 40 | 19.8 | 19.0 | 13.9 | 25.0 | 5% | acumulado |
| plague_carrion | peak | 40 | 20.8 | 19.0 | 12.0 | 26.2 | 5% | runs |
| tar_net | gold_spent | 2000 | 1138.5 | 1017.5 | 756.0 | 1498.5 | 5% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.2 | 5.0 | 4.0 | 6.1 | 10% |  |
| gold_avalanche | gold_earned | 6000 | 4443.4 | 4270.1 | 2653.0 | 6548.7 | 25% | acumulado |
| soul_collector | burst | 2000 | 1751.0 | 1635.2 | 1271.5 | 2418.7 | 25% |  |
| soul_storm | spells_distinct | 6 | 4.9 | 5.0 | 3.9 | 6.0 | 25% |  |
| rat_tide | plays_same | 40 | 36.4 | 34.0 | 28.8 | 45.5 | 30% | runs |
| dragon_exchange | soak_ignite | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 35% |  |
| hollow_armor | elixir_max | 20 | 18.5 | 18.0 | 13.0 | 23.2 | 35% | runs |
| elder_dragon | peak | 5 | 4.6 | 4.0 | 4.0 | 6.0 | 45% |  |
| ash_phoenix | gold_end | 1000 | 1159.2 | 810.3 | 1.5 | 2533.4 | 50% | runs |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 7.0 | 65% |  |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 75% |  |
| flooded_pit | plays | 5 | 19.6 | 18.5 | 0.9 | 38.4 | 80% | runs |
| bat_nest | peak | 3 | 3.0 | 3.0 | 2.0 | 4.0 | 85% | runs |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 0.9 | 1.0 | 90% |  |
| boiling_oil | soaked_time | 75 | 149.0 | 146.4 | 106.6 | 185.7 | 95% | acumulado |
| ember_rain | plays | 25 | 71.3 | 74.0 | 59.8 | 83.0 | 100% | runs |
| hunt_instinct | plays | 40 | 71.3 | 74.0 | 59.8 | 83.0 | 100% | acumulado |
| life_drain | curses | 5 | 9.1 | 10.0 | 6.0 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 20.8 | 19.0 | 12.0 | 26.2 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_novice|lich (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| ash_phoenix | gold_end | 1000 | 346.5 | 299.2 | 191.9 | 564.7 | 0% | runs |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bat_nest | peak | 3 | 0.7 | 0.5 | 0.0 | 2.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 450.1 | 436.5 | 279.6 | 664.5 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 17.8 | 15.5 | 0.0 | 35.4 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 13.8 | 12.5 | 9.9 | 19.4 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 773.7 | 779.8 | 673.8 | 887.1 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 5.3 | 1.0 | 0.0 | 13.3 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 474.1 | 419.5 | 366.0 | 604.6 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 111.7 | 109.5 | 85.3 | 148.4 | 0% | acumulado |
| pack_den | plays | 40 | 5.3 | 1.0 | 0.0 | 13.3 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 274.6 | 266.0 | 203.3 | 335.5 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 139.8 | 139.5 | 99.4 | 166.6 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 427.2 | 427.5 | 252.5 | 674.5 | 0% | acumulado |
| arcane_spark | plays | 120 | 70.9 | 66.0 | 53.9 | 87.0 | 5% | acumulado |
| plague_carrion | peak | 40 | 21.1 | 18.0 | 13.8 | 32.2 | 5% | runs |
| burn_village | burn_time | 150 | 80.3 | 68.4 | 44.9 | 166.3 | 15% | acumulado |
| life_drain | curses | 5 | 1.6 | 0.0 | 0.0 | 7.3 | 15% | runs |
| rat_tide | plays_same | 40 | 34.4 | 34.0 | 25.9 | 45.0 | 20% | runs |
| black_pestilence | plays | 150 | 139.8 | 139.5 | 99.4 | 166.6 | 35% | acumulado |
| soul_collector | burst | 2000 | 1952.1 | 1498.9 | 978.4 | 3531.7 | 35% |  |
| hollow_armor | elixir_max | 20 | 18.2 | 16.0 | 11.0 | 24.3 | 40% | runs |
| eruption | win_without | 1 | 0.5 | 0.5 | 0.0 | 1.0 | 50% |  |
| soul_harvest | win_without | 1 | 0.5 | 0.5 | 0.0 | 1.0 | 50% | runs |
| fallen_healer | loss_max | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 55% |  |
| flooded_pit | plays | 5 | 17.8 | 15.5 | 0.0 | 35.4 | 60% | runs |
| shadow_echo | plays_window | 5 | 5.0 | 5.0 | 4.0 | 6.0 | 60% |  |
| eternal_army | peak | 12 | 14.2 | 13.0 | 10.8 | 19.4 | 80% | runs |
| blood_tax | plays | 100 | 139.8 | 139.5 | 99.4 | 166.6 | 90% | acumulado |
| soul_storm | spells_distinct | 6 | 6.5 | 6.5 | 6.0 | 7.0 | 95% |  |
| arcane_apocalypse | plays_window | 7 | 9.7 | 9.0 | 8.0 | 11.1 | 100% |  |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| ember_rain | plays | 25 | 139.8 | 139.5 | 99.4 | 166.6 | 100% | runs |
| hunt_instinct | plays | 40 | 139.8 | 139.5 | 99.4 | 166.6 | 100% | acumulado |
| magma_golem | peak | 10 | 21.1 | 18.0 | 13.8 | 32.2 | 100% | runs |
| spike_trap | plays_window | 5 | 6.9 | 7.0 | 5.9 | 8.0 | 100% |  |

## human_novice|lich@3 (n=20, vitória 95%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 675.0 | 632.0 | 459.1 | 994.3 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.9 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.9 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 21.8 | 24.0 | 0.9 | 48.4 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 1972.3 | 1965.8 | 1618.5 | 2470.4 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 12.1 | 11.5 | 0.0 | 26.5 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 689.7 | 671.5 | 459.9 | 962.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 162.2 | 156.0 | 117.5 | 234.9 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 389.0 | 393.5 | 280.2 | 483.6 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 192.8 | 193.5 | 136.6 | 249.7 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 863.0 | 892.5 | 516.0 | 1276.5 | 0% | acumulado |
| ghost | peak | 40 | 20.4 | 18.0 | 14.0 | 33.4 | 5% | runs |
| pack_den | plays | 40 | 12.1 | 11.5 | 0.0 | 26.5 | 5% | acumulado |
| burn_village | burn_time | 150 | 113.0 | 111.5 | 73.0 | 166.2 | 15% | acumulado |
| arcane_spark | plays | 120 | 96.0 | 92.5 | 60.1 | 131.7 | 20% | acumulado |
| eruption | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 25% |  |
| soul_harvest | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 25% | runs |
| bat_nest | peak | 3 | 1.9 | 2.0 | 0.0 | 4.0 | 30% | runs |
| plague_carrion | peak | 40 | 39.0 | 36.0 | 23.9 | 62.1 | 35% | runs |
| hollow_armor | elixir_max | 20 | 19.7 | 19.0 | 13.9 | 28.0 | 45% | runs |
| ash_phoenix | gold_end | 1000 | 1109.3 | 1063.1 | 778.0 | 1632.7 | 55% | runs |
| rat_tide | plays_same | 40 | 48.2 | 49.5 | 31.8 | 63.0 | 60% | runs |
| shadow_echo | plays_window | 5 | 4.8 | 5.0 | 3.9 | 6.0 | 65% |  |
| life_drain | curses | 5 | 6.8 | 10.0 | 0.0 | 10.0 | 75% | runs |
| flooded_pit | plays | 5 | 21.8 | 24.0 | 0.9 | 48.4 | 80% | runs |
| black_pestilence | plays | 150 | 192.8 | 193.5 | 136.6 | 249.7 | 85% | acumulado |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 85% |  |
| soul_collector | burst | 2000 | 3646.8 | 3337.3 | 1863.8 | 6004.7 | 85% |  |
| blood_tax | plays | 100 | 192.8 | 193.5 | 136.6 | 249.7 | 95% | acumulado |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 95% |  |
| eternal_army | peak | 12 | 20.6 | 18.5 | 14.0 | 33.4 | 95% | runs |
| arcane_apocalypse | plays_window | 7 | 10.7 | 11.0 | 7.9 | 14.0 | 100% |  |
| ember_rain | plays | 25 | 192.8 | 193.5 | 136.6 | 249.7 | 100% | runs |
| hunt_instinct | plays | 40 | 192.8 | 193.5 | 136.6 | 249.7 | 100% | acumulado |
| magma_golem | peak | 10 | 39.0 | 36.0 | 23.9 | 62.1 | 100% | runs |
| soul_storm | spells_distinct | 6 | 6.8 | 7.0 | 6.0 | 8.0 | 100% |  |
| spike_trap | plays_window | 5 | 6.8 | 7.0 | 5.0 | 9.0 | 100% |  |

## human_novice|plague (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.4 | 3.0 | 3.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 449.4 | 444.1 | 176.1 | 699.2 | 0% | runs |
| black_pestilence | plays | 150 | 36.1 | 35.5 | 23.0 | 50.3 | 0% | acumulado |
| blood_tax | plays | 100 | 36.1 | 35.5 | 23.0 | 50.3 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 731.7 | 707.0 | 436.7 | 1040.7 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 520.4 | 472.0 | 260.9 | 757.6 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 3.8 | 0.0 | 0.0 | 11.0 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 900.9 | 843.7 | 779.8 | 1072.4 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 13.7 | 14.0 | 6.0 | 20.1 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 467.7 | 424.5 | 321.0 | 622.0 | 0% | acumulado |
| ogre | plays | 600 | 120.3 | 112.0 | 83.9 | 162.9 | 0% | acumulado |
| pack_den | plays | 40 | 13.7 | 14.0 | 6.0 | 20.1 | 0% | acumulado |
| primal_beast | plays | 600 | 73.5 | 63.0 | 47.9 | 102.0 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 173.8 | 160.5 | 125.7 | 239.2 | 0% | acumulado |
| soul_collector | burst | 2000 | 1185.8 | 1201.6 | 830.9 | 1481.0 | 0% |  |
| soul_feast | plays | 400 | 36.1 | 35.5 | 23.0 | 50.3 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 46.4 | 44.5 | 33.9 | 64.2 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 451.5 | 490.0 | 125.0 | 713.5 | 0% | acumulado |
| hollow_armor | elixir_max | 20 | 14.8 | 14.5 | 11.0 | 18.1 | 5% | runs |
| plague_carrion | peak | 40 | 25.6 | 21.5 | 19.0 | 35.3 | 5% | runs |
| rat_tide | plays_same | 40 | 27.2 | 25.5 | 18.8 | 37.5 | 10% | runs |
| soul_storm | spells_distinct | 6 | 4.0 | 4.0 | 3.0 | 5.1 | 10% |  |
| alpha_beast | peak | 30 | 22.5 | 19.0 | 15.0 | 30.8 | 15% |  |
| bat_nest | peak | 3 | 1.6 | 1.0 | 1.0 | 3.0 | 15% | runs |
| mother_nest | peak_on_spell | 20 | 15.5 | 13.5 | 10.0 | 24.3 | 25% | runs |
| spike_trap | plays_window | 5 | 4.2 | 4.0 | 3.9 | 5.0 | 25% |  |
| hunt_instinct | plays | 40 | 36.1 | 35.5 | 23.0 | 50.3 | 30% | acumulado |
| flooded_pit | plays | 5 | 3.8 | 0.0 | 0.0 | 11.0 | 35% | runs |
| fallen_healer | loss_max | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 55% |  |
| life_drain | curses | 5 | 6.2 | 9.0 | 0.0 | 10.0 | 60% | runs |
| ember_rain | plays | 25 | 36.1 | 35.5 | 23.0 | 50.3 | 80% | runs |
| bat_cloud | peak | 12 | 22.7 | 19.0 | 15.0 | 30.8 | 100% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| magma_golem | peak | 10 | 25.6 | 21.5 | 19.0 | 35.3 | 100% | runs |
| rat_trap | peste | 5 | 14.4 | 15.0 | 14.7 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_novice|plague@3 (n=20, vitória 95%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.5 | 3.5 | 3.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 47.6 | 46.0 | 32.5 | 62.2 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1098.7 | 987.0 | 693.1 | 1690.1 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 832.8 | 719.0 | 475.7 | 1364.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 3.8 | 3.5 | 0.0 | 10.0 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 2002.5 | 2078.3 | 1616.1 | 2348.0 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 18.5 | 20.0 | 10.0 | 28.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 655.9 | 607.0 | 435.0 | 868.3 | 0% | acumulado |
| ogre | plays | 600 | 159.2 | 144.5 | 114.8 | 213.4 | 0% | acumulado |
| pack_den | plays | 40 | 18.5 | 20.0 | 10.0 | 28.0 | 0% | acumulado |
| primal_beast | plays | 600 | 96.9 | 101.0 | 65.8 | 129.0 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 229.2 | 210.5 | 162.2 | 300.6 | 0% | acumulado |
| soul_feast | plays | 400 | 47.6 | 46.0 | 32.5 | 62.2 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 57.6 | 54.0 | 38.9 | 79.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 896.8 | 807.5 | 487.5 | 1387.5 | 0% | acumulado |
| blood_tax | plays | 100 | 47.6 | 46.0 | 32.5 | 62.2 | 5% | acumulado |
| bat_nest | peak | 3 | 1.9 | 2.0 | 1.0 | 3.0 | 20% | runs |
| soul_storm | spells_distinct | 6 | 4.5 | 4.0 | 3.0 | 6.0 | 20% |  |
| rat_tide | plays_same | 40 | 34.2 | 31.5 | 25.9 | 47.3 | 25% | runs |
| spike_trap | plays_window | 5 | 4.4 | 4.0 | 4.0 | 5.0 | 35% |  |
| flooded_pit | plays | 5 | 3.8 | 3.5 | 0.0 | 10.0 | 40% | runs |
| hollow_armor | elixir_max | 20 | 18.0 | 17.5 | 13.0 | 23.3 | 40% | runs |
| life_drain | curses | 5 | 5.8 | 9.5 | 0.0 | 10.0 | 60% | runs |
| ash_phoenix | gold_end | 1000 | 1105.7 | 1163.2 | 574.7 | 1587.3 | 65% | runs |
| hunt_instinct | plays | 40 | 47.6 | 46.0 | 32.5 | 62.2 | 75% | acumulado |
| soul_collector | burst | 2000 | 2435.0 | 2173.7 | 1476.6 | 3599.9 | 75% |  |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 80% |  |
| alpha_beast | peak | 30 | 54.3 | 48.5 | 23.0 | 74.5 | 85% |  |
| plague_carrion | peak | 40 | 59.2 | 51.5 | 32.6 | 78.0 | 85% | runs |
| mother_nest | peak_on_spell | 20 | 34.5 | 24.5 | 19.9 | 62.3 | 90% | runs |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 95% |  |
| rat_trap | peste | 5 | 14.4 | 15.0 | 14.8 | 15.0 | 95% | runs |
| bat_cloud | peak | 12 | 54.9 | 49.5 | 24.8 | 75.4 | 100% | runs |
| ember_rain | plays | 25 | 47.6 | 46.0 | 32.5 | 62.2 | 100% | runs |
| magma_golem | peak | 10 | 59.2 | 51.5 | 32.6 | 78.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human|dragon (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 35.9 | 34.5 | 26.8 | 44.1 | 0% | acumulado |
| blood_tax | plays | 100 | 35.9 | 34.5 | 26.8 | 44.1 | 0% | acumulado |
| bone_colossus | died | 3000 | 223.4 | 208.5 | 164.6 | 325.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 37.7 | 35.4 | 15.2 | 54.7 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 15.9 | 16.5 | 3.6 | 29.3 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1668.2 | 1576.0 | 1138.4 | 2453.1 | 0% | acumulado |
| gold_bait | coins | 25 | 9.6 | 9.5 | 6.8 | 13.1 | 0% | acumulado |
| hollow_armor | elixir_max | 20 | 12.9 | 13.0 | 11.0 | 16.0 | 0% | runs |
| meteor_storm | plays | 80 | 25.1 | 24.0 | 18.6 | 32.2 | 0% | acumulado |
| mimic | plays | 60 | 12.4 | 11.5 | 7.0 | 19.4 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 400.9 | 379.0 | 292.6 | 560.5 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 92.8 | 90.5 | 72.9 | 133.3 | 0% | acumulado |
| pack_den | plays | 40 | 12.4 | 11.5 | 7.0 | 19.4 | 0% | acumulado |
| plague_carrion | peak | 40 | 11.2 | 11.0 | 9.9 | 13.0 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 157.2 | 152.5 | 121.8 | 208.8 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_collector | burst | 2000 | 967.9 | 938.3 | 700.9 | 1227.1 | 0% |  |
| soul_feast | plays | 400 | 35.9 | 34.5 | 26.8 | 44.1 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 3.6 | 3.5 | 3.0 | 4.1 | 0% |  |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 483.8 | 487.5 | 313.5 | 654.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.0 | 5.0 | 4.0 | 6.0 | 5% |  |
| ash_phoenix | gold_end | 1000 | 222.3 | 139.8 | 1.5 | 488.9 | 5% | runs |
| elder_dragon | peak | 5 | 3.6 | 4.0 | 3.0 | 4.0 | 5% |  |
| rat_tide | plays_same | 40 | 23.9 | 22.0 | 18.7 | 35.3 | 5% | runs |
| bat_nest | peak | 3 | 1.9 | 2.0 | 1.0 | 3.0 | 15% | runs |
| hunt_instinct | plays | 40 | 35.9 | 34.5 | 26.8 | 44.1 | 25% | acumulado |
| boiling_oil | soaked_time | 75 | 76.0 | 76.9 | 48.8 | 99.6 | 60% | acumulado |
| dragon_exchange | soak_ignite | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 70% |  |
| life_drain | curses | 5 | 7.2 | 8.5 | 2.0 | 10.0 | 70% | runs |
| spike_trap | plays_window | 5 | 4.9 | 5.0 | 4.0 | 6.0 | 70% |  |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 75% |  |
| flooded_pit | plays | 5 | 15.9 | 16.5 | 3.6 | 29.3 | 85% | runs |
| magma_golem | peak | 10 | 11.2 | 11.0 | 9.9 | 13.0 | 90% | runs |
| ember_rain | plays | 25 | 35.9 | 34.5 | 26.8 | 44.1 | 95% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human|dragon@3 (n=20, vitória 90%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.3 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 60.1 | 62.0 | 46.5 | 72.3 | 0% | acumulado |
| blood_tax | plays | 100 | 60.1 | 62.0 | 46.5 | 72.3 | 0% | acumulado |
| bone_colossus | died | 3000 | 356.0 | 358.5 | 288.5 | 442.7 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.7 | 7.0 | 6.7 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 0.9 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.7 | 7.0 | 6.7 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 29.2 | 26.5 | 7.2 | 44.6 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 0.9 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_bait | coins | 25 | 15.3 | 16.0 | 8.9 | 20.2 | 0% | acumulado |
| meteor_storm | plays | 80 | 39.6 | 40.0 | 26.0 | 51.1 | 0% | acumulado |
| mimic | plays | 60 | 22.4 | 20.5 | 15.7 | 31.5 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 678.4 | 651.5 | 551.7 | 793.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 142.8 | 147.0 | 117.5 | 171.2 | 0% | acumulado |
| plague_carrion | peak | 40 | 18.9 | 18.0 | 14.9 | 24.1 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 0.9 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 254.9 | 265.0 | 193.3 | 298.2 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 60.1 | 62.0 | 46.5 | 72.3 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 4.2 | 4.0 | 3.0 | 5.0 | 0% |  |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 1047.0 | 1085.0 | 684.5 | 1356.6 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 4.9 | 5.0 | 4.0 | 5.1 | 5% |  |
| burn_village | burn_time | 150 | 86.8 | 82.8 | 41.8 | 124.4 | 10% | acumulado |
| gold_avalanche | gold_earned | 6000 | 4465.4 | 4123.0 | 2665.7 | 5873.4 | 10% | acumulado |
| pack_den | plays | 40 | 22.4 | 20.5 | 15.7 | 31.5 | 10% | acumulado |
| hollow_armor | elixir_max | 20 | 16.7 | 15.5 | 12.0 | 20.2 | 15% | runs |
| soul_collector | burst | 2000 | 1549.6 | 1458.8 | 1143.7 | 2137.1 | 15% |  |
| elder_dragon | peak | 5 | 4.3 | 4.0 | 3.0 | 6.0 | 40% |  |
| ash_phoenix | gold_end | 1000 | 1457.5 | 1005.2 | 0.8 | 2114.2 | 50% | runs |
| rat_tide | plays_same | 40 | 37.8 | 39.5 | 28.9 | 45.6 | 50% | runs |
| bat_nest | peak | 3 | 2.9 | 3.0 | 2.0 | 4.1 | 55% | runs |
| dragon_exchange | soak_ignite | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 65% |  |
| fallen_healer | loss_max | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 65% |  |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 6.1 | 80% |  |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 0.9 | 1.0 | 90% |  |
| flooded_pit | plays | 5 | 29.2 | 26.5 | 7.2 | 44.6 | 90% | runs |
| boiling_oil | soaked_time | 75 | 134.6 | 117.5 | 87.7 | 211.5 | 95% | acumulado |
| ember_rain | plays | 25 | 60.1 | 62.0 | 46.5 | 72.3 | 100% | runs |
| hunt_instinct | plays | 40 | 60.1 | 62.0 | 46.5 | 72.3 | 100% | acumulado |
| life_drain | curses | 5 | 9.2 | 10.0 | 6.0 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 18.9 | 18.0 | 14.9 | 24.1 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human|lich (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 62.9 | 59.5 | 42.9 | 84.7 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 347.5 | 373.4 | 218.6 | 489.7 | 0% | runs |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 360.1 | 363.0 | 265.3 | 450.8 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 25.3 | 26.0 | 5.7 | 44.3 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 12.2 | 12.0 | 8.0 | 14.5 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 766.8 | 759.9 | 657.7 | 882.4 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 2.6 | 0.0 | 0.0 | 7.5 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 436.0 | 428.0 | 301.9 | 572.2 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 95.9 | 96.0 | 77.9 | 118.2 | 0% | acumulado |
| pack_den | plays | 40 | 2.6 | 0.0 | 0.0 | 7.5 | 0% | acumulado |
| plague_carrion | peak | 40 | 16.9 | 17.0 | 12.9 | 23.2 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 260.4 | 241.5 | 184.6 | 355.9 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 136.6 | 130.5 | 95.8 | 182.4 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 419.2 | 407.5 | 273.0 | 612.5 | 0% | acumulado |
| bat_nest | peak | 3 | 0.7 | 0.0 | 0.0 | 2.0 | 5% | runs |
| burn_village | burn_time | 150 | 76.5 | 74.0 | 49.5 | 102.5 | 5% | acumulado |
| black_pestilence | plays | 150 | 136.6 | 130.5 | 95.8 | 182.4 | 20% | acumulado |
| life_drain | curses | 5 | 2.2 | 0.0 | 0.0 | 10.0 | 20% | runs |
| hollow_armor | elixir_max | 20 | 16.9 | 14.5 | 12.0 | 25.4 | 25% | runs |
| rat_tide | plays_same | 40 | 32.5 | 31.5 | 19.8 | 46.2 | 35% | runs |
| shadow_echo | plays_window | 5 | 4.6 | 4.0 | 4.0 | 6.0 | 40% |  |
| eternal_army | peak | 12 | 12.4 | 12.5 | 9.0 | 15.4 | 60% | runs |
| soul_collector | burst | 2000 | 2284.2 | 2347.5 | 807.2 | 3399.1 | 60% |  |
| soul_storm | spells_distinct | 6 | 5.8 | 6.0 | 5.0 | 7.0 | 60% |  |
| eruption | win_without | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 65% |  |
| fallen_healer | loss_max | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 65% |  |
| soul_harvest | win_without | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 65% | runs |
| blood_tax | plays | 100 | 136.6 | 130.5 | 95.8 | 182.4 | 85% | acumulado |
| flooded_pit | plays | 5 | 25.3 | 26.0 | 5.7 | 44.3 | 90% | runs |
| arcane_apocalypse | plays_window | 7 | 11.2 | 10.0 | 9.0 | 14.1 | 100% |  |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| ember_rain | plays | 25 | 136.6 | 130.5 | 95.8 | 182.4 | 100% | runs |
| hunt_instinct | plays | 40 | 136.6 | 130.5 | 95.8 | 182.4 | 100% | acumulado |
| magma_golem | peak | 10 | 16.9 | 17.0 | 12.9 | 23.2 | 100% | runs |
| spike_trap | plays_window | 5 | 7.7 | 8.0 | 6.0 | 9.0 | 100% |  |

## human|lich@3 (n=20, vitória 90%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 593.5 | 554.0 | 399.2 | 829.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.7 | 7.0 | 6.8 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 0.9 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.7 | 7.0 | 6.8 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 38.4 | 34.0 | 11.9 | 67.3 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 0.9 | 1.0 | 0% |  |
| ghost | peak | 40 | 20.4 | 18.0 | 12.9 | 34.3 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1958.6 | 1960.3 | 1579.2 | 2265.7 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 5.2 | 4.0 | 0.0 | 13.2 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 676.1 | 609.5 | 476.2 | 991.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 150.7 | 146.0 | 106.3 | 198.0 | 0% | acumulado |
| pack_den | plays | 40 | 5.2 | 4.0 | 0.0 | 13.2 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 0.9 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 390.0 | 384.5 | 259.4 | 574.3 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 195.8 | 196.0 | 114.0 | 293.7 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 589.9 | 582.5 | 195.0 | 892.0 | 0% | acumulado |
| bat_nest | peak | 3 | 1.3 | 1.0 | 0.0 | 3.1 | 15% | runs |
| arcane_spark | plays | 120 | 90.7 | 87.5 | 46.2 | 131.1 | 25% | acumulado |
| hollow_armor | elixir_max | 20 | 19.2 | 17.5 | 12.9 | 28.8 | 30% | runs |
| life_drain | curses | 5 | 3.2 | 1.0 | 0.0 | 10.0 | 30% | runs |
| burn_village | burn_time | 150 | 161.1 | 109.1 | 62.5 | 332.6 | 35% | acumulado |
| eruption | win_without | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 40% |  |
| plague_carrion | peak | 40 | 37.5 | 32.5 | 27.0 | 50.1 | 40% | runs |
| soul_harvest | win_without | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 40% | runs |
| rat_tide | plays_same | 40 | 45.1 | 40.5 | 25.0 | 64.1 | 60% | runs |
| black_pestilence | plays | 150 | 195.8 | 196.0 | 114.0 | 293.7 | 65% | acumulado |
| fallen_healer | loss_max | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 65% |  |
| shadow_echo | plays_window | 5 | 5.2 | 5.0 | 4.0 | 6.1 | 75% |  |
| soul_storm | spells_distinct | 6 | 5.8 | 6.0 | 5.0 | 6.1 | 80% |  |
| ash_phoenix | gold_end | 1000 | 1368.7 | 1355.1 | 952.8 | 1810.8 | 85% | runs |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 0.9 | 1.0 | 90% |  |
| soul_collector | burst | 2000 | 4443.9 | 4457.9 | 2656.5 | 6157.1 | 95% |  |
| arcane_apocalypse | plays_window | 7 | 11.6 | 10.5 | 9.9 | 13.4 | 100% |  |
| blood_tax | plays | 100 | 195.8 | 196.0 | 114.0 | 293.7 | 100% | acumulado |
| ember_rain | plays | 25 | 195.8 | 196.0 | 114.0 | 293.7 | 100% | runs |
| eternal_army | peak | 12 | 20.9 | 18.5 | 13.8 | 35.2 | 100% | runs |
| flooded_pit | plays | 5 | 38.4 | 34.0 | 11.9 | 67.3 | 100% | runs |
| hunt_instinct | plays | 40 | 195.8 | 196.0 | 114.0 | 293.7 | 100% | acumulado |
| magma_golem | peak | 10 | 37.5 | 32.5 | 27.0 | 50.1 | 100% | runs |
| spike_trap | plays_window | 5 | 8.2 | 8.0 | 6.0 | 9.4 | 100% |  |

## human|plague (n=20, vitória 100%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.1 | 3.0 | 3.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 460.7 | 517.6 | 215.8 | 670.6 | 0% | runs |
| bat_nest | peak | 3 | 1.4 | 1.0 | 1.0 | 2.0 | 0% | runs |
| black_pestilence | plays | 150 | 29.1 | 30.0 | 17.9 | 37.2 | 0% | acumulado |
| blood_tax | plays | 100 | 29.1 | 30.0 | 17.9 | 37.2 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 779.5 | 766.0 | 489.1 | 1244.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 7.0 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 568.8 | 521.0 | 388.7 | 867.1 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 5.7 | 6.0 | 0.0 | 12.1 | 0% | acumulado |
| furnace | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 883.9 | 866.0 | 761.0 | 1037.4 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 10.3 | 8.0 | 6.0 | 17.2 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 455.1 | 440.5 | 340.1 | 583.2 | 0% | acumulado |
| ogre | plays | 600 | 119.3 | 114.0 | 77.6 | 154.5 | 0% | acumulado |
| pack_den | plays | 40 | 10.3 | 8.0 | 6.0 | 17.2 | 0% | acumulado |
| primal_beast | plays | 600 | 69.5 | 67.0 | 49.7 | 96.1 | 0% | acumulado |
| rat_tide | plays_same | 40 | 25.5 | 24.5 | 19.5 | 34.2 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 1.0 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 164.5 | 155.5 | 109.6 | 216.2 | 0% | acumulado |
| soul_collector | burst | 2000 | 1040.9 | 993.2 | 758.1 | 1387.2 | 0% |  |
| soul_feast | plays | 400 | 29.1 | 30.0 | 17.9 | 37.2 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 3.5 | 3.5 | 3.0 | 4.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 42.3 | 42.5 | 28.7 | 55.2 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 423.2 | 365.0 | 221.0 | 633.5 | 0% | acumulado |
| hunt_instinct | plays | 40 | 29.1 | 30.0 | 17.9 | 37.2 | 5% | acumulado |
| hollow_armor | elixir_max | 20 | 16.1 | 15.0 | 12.0 | 22.2 | 20% | runs |
| mother_nest | peak_on_spell | 20 | 18.1 | 14.5 | 11.0 | 32.5 | 25% | runs |
| plague_carrion | peak | 40 | 32.0 | 28.5 | 20.6 | 47.1 | 35% | runs |
| alpha_beast | peak | 30 | 29.8 | 22.5 | 17.8 | 46.1 | 40% |  |
| life_drain | curses | 5 | 4.6 | 2.0 | 0.0 | 10.0 | 45% | runs |
| fallen_healer | loss_max | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 55% |  |
| spike_trap | plays_window | 5 | 4.7 | 5.0 | 4.0 | 5.1 | 55% |  |
| flooded_pit | plays | 5 | 5.7 | 6.0 | 0.0 | 12.1 | 60% | runs |
| ember_rain | plays | 25 | 29.1 | 30.0 | 17.9 | 37.2 | 75% | runs |
| bat_cloud | peak | 12 | 30.1 | 23.0 | 17.8 | 46.1 | 100% | runs |
| cave_troll | win_phase | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
| magma_golem | peak | 10 | 32.0 | 28.5 | 20.6 | 47.1 | 100% | runs |
| rat_trap | peste | 5 | 15.0 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human|plague@3 (n=20, vitória 95%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.5 | 3.5 | 3.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 46.0 | 46.0 | 32.9 | 58.6 | 0% | acumulado |
| blood_tax | plays | 100 | 46.0 | 46.0 | 32.9 | 58.6 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1159.3 | 1206.0 | 718.2 | 1506.9 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.8 | 7.0 | 7.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 887.5 | 906.0 | 512.9 | 1187.6 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 5.2 | 0.0 | 0.0 | 14.5 | 0% | acumulado |
| furnace | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1976.2 | 1974.2 | 1699.4 | 2295.9 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 18.1 | 17.0 | 9.0 | 26.1 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 693.6 | 733.0 | 506.4 | 888.7 | 0% | acumulado |
| ogre | plays | 600 | 171.8 | 172.0 | 137.0 | 210.8 | 0% | acumulado |
| pack_den | plays | 40 | 18.1 | 17.0 | 9.0 | 26.1 | 0% | acumulado |
| primal_beast | plays | 600 | 104.0 | 107.0 | 76.8 | 131.6 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.9 | 1.0 | 1.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 240.9 | 237.0 | 191.9 | 296.3 | 0% | acumulado |
| soul_feast | plays | 400 | 46.0 | 46.0 | 32.9 | 58.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 3.8 | 4.0 | 3.0 | 4.1 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 62.5 | 63.5 | 47.4 | 76.1 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 609.0 | 592.5 | 330.0 | 980.5 | 0% | acumulado |
| bat_nest | peak | 3 | 1.7 | 2.0 | 1.0 | 2.1 | 10% | runs |
| flooded_pit | plays | 5 | 5.2 | 0.0 | 0.0 | 14.5 | 30% | runs |
| hollow_armor | elixir_max | 20 | 17.5 | 17.5 | 12.9 | 22.0 | 30% | runs |
| life_drain | curses | 5 | 4.4 | 2.0 | 0.0 | 10.0 | 40% | runs |
| rat_tide | plays_same | 40 | 37.4 | 38.0 | 29.8 | 45.1 | 45% | runs |
| soul_collector | burst | 2000 | 2110.0 | 1972.5 | 1596.4 | 2750.4 | 50% |  |
| plague_carrion | peak | 40 | 57.3 | 49.0 | 33.9 | 87.6 | 70% | runs |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 6.1 | 70% |  |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 75% |  |
| hunt_instinct | plays | 40 | 46.0 | 46.0 | 32.9 | 58.6 | 75% | acumulado |
| alpha_beast | peak | 30 | 51.1 | 46.5 | 25.7 | 87.4 | 85% |  |
| ash_phoenix | gold_end | 1000 | 1367.2 | 1310.3 | 949.0 | 1856.9 | 85% | runs |
| mother_nest | peak_on_spell | 20 | 35.3 | 29.0 | 18.5 | 58.6 | 85% | runs |
| cave_troll | win_phase | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 95% |  |
| ember_rain | plays | 25 | 46.0 | 46.0 | 32.9 | 58.6 | 95% | runs |
| bat_cloud | peak | 12 | 51.4 | 46.5 | 28.4 | 87.4 | 100% | runs |
| magma_golem | peak | 10 | 57.3 | 49.0 | 33.9 | 87.6 | 100% | runs |
| rat_trap | peste | 5 | 15.0 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## random|dragon (n=20, vitória 55%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 63.5 | 35.3 | 0.3 | 146.1 | 0% | runs |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 81.2 | 83.5 | 59.8 | 99.4 | 0% | acumulado |
| bone_colossus | died | 3000 | 338.2 | 325.0 | 246.8 | 456.8 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.8 | 7.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.8 | 7.0 | 4.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 27.8 | 19.7 | 4.5 | 49.3 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 5.8 | 1.5 | 0.0 | 16.0 | 0% | acumulado |
| furnace | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1312.0 | 1324.2 | 975.2 | 1697.2 | 0% | acumulado |
| gold_bait | coins | 25 | 8.9 | 9.0 | 4.9 | 12.2 | 0% | acumulado |
| hollow_armor | elixir_max | 20 | 12.7 | 12.0 | 10.0 | 15.3 | 0% | runs |
| molten_gold | elixir_spent | 2000 | 565.2 | 561.5 | 403.8 | 748.3 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 136.4 | 135.5 | 101.1 | 177.6 | 0% | acumulado |
| plague_carrion | peak | 40 | 11.9 | 12.0 | 8.9 | 14.1 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 251.3 | 252.0 | 191.6 | 307.5 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_collector | burst | 2000 | 878.5 | 872.6 | 638.0 | 1226.7 | 0% |  |
| soul_feast | plays | 400 | 81.2 | 83.5 | 59.8 | 99.4 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 804.0 | 790.0 | 593.7 | 1108.2 | 0% | acumulado |
| dragon_exchange | soak_ignite | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 5% |  |
| elder_dragon | peak | 5 | 3.2 | 3.0 | 2.9 | 4.0 | 5% |  |
| mimic | plays | 60 | 24.4 | 20.5 | 14.0 | 34.5 | 5% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.2 | 5.0 | 4.0 | 6.1 | 10% |  |
| blood_tax | plays | 100 | 81.2 | 83.5 | 59.8 | 99.4 | 10% | acumulado |
| pack_den | plays | 40 | 24.4 | 20.5 | 14.0 | 34.5 | 10% | acumulado |
| meteor_storm | plays | 80 | 58.8 | 56.5 | 38.8 | 85.0 | 20% | acumulado |
| rat_tide | plays_same | 40 | 35.1 | 35.5 | 27.9 | 43.1 | 35% | runs |
| flooded_pit | plays | 5 | 5.8 | 1.5 | 0.0 | 16.0 | 45% | runs |
| bat_nest | peak | 3 | 2.9 | 2.5 | 2.0 | 5.0 | 50% | runs |
| cave_troll | win_phase | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 55% |  |
| soul_storm | spells_distinct | 6 | 5.5 | 6.0 | 4.0 | 6.1 | 55% |  |
| spike_trap | plays_window | 5 | 4.5 | 5.0 | 4.0 | 5.0 | 55% |  |
| spark | soak_ignite | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 75% | runs |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 80% |  |
| life_drain | curses | 5 | 8.5 | 10.0 | 4.0 | 10.0 | 85% | runs |
| magma_golem | peak | 10 | 11.9 | 12.0 | 8.9 | 14.1 | 85% | runs |
| boiling_oil | soaked_time | 75 | 151.6 | 150.6 | 97.5 | 232.0 | 95% | acumulado |
| ember_rain | plays | 25 | 81.2 | 83.5 | 59.8 | 99.4 | 100% | runs |
| hunt_instinct | plays | 40 | 81.2 | 83.5 | 59.8 | 99.4 | 100% | acumulado |

## random|dragon@3 (n=20, vitória 35%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 1.8 | 0.0 | 0.0 | 7.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 504.2 | 475.0 | 385.9 | 663.3 | 0% | acumulado |
| bone_dragon | heroes | 35 | 4.7 | 5.0 | 3.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 4.7 | 5.0 | 3.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.2 | 0.0 | 0.0 | 0.2 | 0% | runs |
| forbidden_library | plays | 200 | 9.1 | 4.0 | 0.0 | 24.8 | 0% | acumulado |
| furnace | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.2 | 0.0 | 0.0 | 0.2 | 0% | runs |
| mimic | plays | 60 | 30.4 | 28.0 | 20.0 | 44.2 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 781.2 | 781.0 | 632.7 | 939.2 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 205.2 | 200.0 | 166.6 | 246.2 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.3 | 0.0 | 0.0 | 1.1 | 0% |  |
| shadow_mark | plays | 1000 | 372.9 | 369.0 | 293.9 | 445.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 124.2 | 130.0 | 96.7 | 145.1 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 124.2 | 130.0 | 96.7 | 145.1 | 5% | acumulado |
| burn_village | burn_time | 150 | 28.8 | 10.1 | 0.0 | 78.6 | 5% | acumulado |
| gold_avalanche | gold_earned | 6000 | 3518.6 | 3352.9 | 2021.8 | 5098.1 | 5% | acumulado |
| gold_bait | coins | 25 | 13.7 | 12.0 | 8.9 | 21.3 | 5% | acumulado |
| hollow_armor | elixir_max | 20 | 13.6 | 13.0 | 10.0 | 17.0 | 5% | runs |
| plague_carrion | peak | 40 | 22.2 | 21.0 | 15.0 | 30.3 | 5% | runs |
| ash_phoenix | gold_end | 1000 | 417.2 | 81.6 | 5.3 | 1065.4 | 15% | runs |
| soul_collector | burst | 2000 | 1478.8 | 1471.1 | 841.6 | 2054.0 | 15% |  |
| dragon_exchange | soak_ignite | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 20% |  |
| arcane_apocalypse | plays_window | 7 | 5.7 | 5.5 | 4.0 | 8.0 | 25% |  |
| pack_den | plays | 40 | 30.4 | 28.0 | 20.0 | 44.2 | 25% | acumulado |
| cave_troll | win_phase | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 35% |  |
| tar_net | gold_spent | 2000 | 1917.0 | 1742.5 | 1206.0 | 2844.8 | 45% | acumulado |
| flooded_pit | plays | 5 | 9.1 | 4.0 | 0.0 | 24.8 | 50% | runs |
| soul_storm | spells_distinct | 6 | 5.8 | 5.5 | 4.0 | 7.1 | 50% |  |
| elder_dragon | peak | 5 | 4.5 | 5.0 | 3.0 | 5.2 | 55% |  |
| meteor_storm | plays | 80 | 83.0 | 89.0 | 65.3 | 98.3 | 60% | acumulado |
| spark | soak_ignite | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 70% | runs |
| blood_tax | plays | 100 | 124.2 | 130.0 | 96.7 | 145.1 | 80% | acumulado |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 80% |  |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 6.0 | 80% |  |
| bat_nest | peak | 3 | 3.6 | 3.0 | 2.9 | 5.0 | 90% | runs |
| rat_tide | plays_same | 40 | 50.2 | 49.0 | 40.1 | 59.6 | 90% | runs |
| boiling_oil | soaked_time | 75 | 233.9 | 238.7 | 182.4 | 301.5 | 95% | acumulado |
| ember_rain | plays | 25 | 124.2 | 130.0 | 96.7 | 145.1 | 100% | runs |
| hunt_instinct | plays | 40 | 124.2 | 130.0 | 96.7 | 145.1 | 100% | acumulado |
| life_drain | curses | 5 | 9.6 | 10.0 | 9.6 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 22.2 | 21.0 | 15.0 | 30.3 | 100% | runs |

## random|lich (n=20, vitória 85%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| ash_phoenix | gold_end | 1000 | 344.3 | 358.9 | 110.5 | 530.7 | 0% | runs |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 844.3 | 888.5 | 619.8 | 1055.5 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.6 | 7.0 | 4.9 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.8 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.6 | 7.0 | 4.9 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 5.2 | 0.5 | 0.0 | 17.2 | 0% | acumulado |
| furnace | wins | 2 | 0.8 | 1.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 13.3 | 12.0 | 9.9 | 19.2 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 877.6 | 843.1 | 762.4 | 990.2 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 9.8 | 11.0 | 0.0 | 19.2 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 735.9 | 757.5 | 575.6 | 899.1 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 226.7 | 230.0 | 168.2 | 284.3 | 0% | acumulado |
| pack_den | plays | 40 | 9.8 | 11.0 | 0.0 | 19.2 | 0% | acumulado |
| plague_carrion | peak | 40 | 19.3 | 20.0 | 13.0 | 24.1 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.8 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 506.4 | 514.0 | 397.3 | 636.7 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 264.8 | 265.0 | 192.0 | 336.9 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 533.2 | 572.5 | 279.5 | 742.5 | 0% | acumulado |
| hollow_armor | elixir_max | 20 | 14.2 | 14.0 | 11.0 | 17.3 | 10% | runs |
| soul_collector | burst | 2000 | 1213.5 | 941.5 | 605.3 | 1860.5 | 10% |  |
| bat_nest | peak | 3 | 1.9 | 2.0 | 0.0 | 4.2 | 25% | runs |
| eruption | win_without | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 30% |  |
| flooded_pit | plays | 5 | 5.2 | 0.5 | 0.0 | 17.2 | 30% | runs |
| soul_harvest | win_without | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 30% | runs |
| burn_village | burn_time | 150 | 133.0 | 139.7 | 65.1 | 196.5 | 35% | acumulado |
| arcane_spark | plays | 120 | 122.1 | 124.0 | 77.6 | 157.6 | 50% | acumulado |
| fallen_healer | loss_max | 1 | 0.5 | 0.5 | 0.0 | 1.0 | 50% |  |
| shadow_echo | plays_window | 5 | 4.8 | 5.0 | 3.0 | 6.0 | 60% |  |
| eternal_army | peak | 12 | 13.8 | 12.0 | 10.0 | 19.2 | 70% | runs |
| life_drain | curses | 5 | 7.2 | 10.0 | 0.0 | 10.0 | 75% | runs |
| cave_troll | win_phase | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 85% |  |
| arcane_apocalypse | plays_window | 7 | 10.3 | 11.0 | 7.9 | 13.0 | 95% |  |
| black_pestilence | plays | 150 | 264.8 | 265.0 | 192.0 | 336.9 | 95% | acumulado |
| soul_storm | spells_distinct | 6 | 8.3 | 9.0 | 7.0 | 9.1 | 95% |  |
| blood_tax | plays | 100 | 264.8 | 265.0 | 192.0 | 336.9 | 100% | acumulado |
| ember_rain | plays | 25 | 264.8 | 265.0 | 192.0 | 336.9 | 100% | runs |
| hunt_instinct | plays | 40 | 264.8 | 265.0 | 192.0 | 336.9 | 100% | acumulado |
| magma_golem | peak | 10 | 19.3 | 20.0 | 13.0 | 24.1 | 100% | runs |
| rat_tide | plays_same | 40 | 93.1 | 90.5 | 68.4 | 127.3 | 100% | runs |
| spike_trap | plays_window | 5 | 6.9 | 7.0 | 5.0 | 9.0 | 100% |  |

## random|lich@3 (n=20, vitória 50%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1056.2 | 1039.5 | 751.3 | 1418.1 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.1 | 5.5 | 3.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.5 | 0.5 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.1 | 5.5 | 3.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 14.9 | 13.0 | 0.0 | 32.1 | 0% | acumulado |
| furnace | wins | 2 | 0.5 | 0.5 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 17.1 | 16.0 | 13.8 | 21.2 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1951.6 | 1928.7 | 1518.9 | 2379.9 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 15.2 | 12.5 | 0.0 | 33.7 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 947.3 | 941.0 | 692.8 | 1222.7 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 277.8 | 253.5 | 204.6 | 363.8 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.5 | 0.5 | 0.0 | 1.0 | 0% |  |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 555.8 | 460.0 | 110.0 | 1234.5 | 0% | acumulado |
| shadow_mark | plays | 1000 | 631.2 | 626.0 | 436.0 | 813.8 | 5% | acumulado |
| eruption | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.1 | 10% |  |
| pack_den | plays | 40 | 15.2 | 12.5 | 0.0 | 33.7 | 10% | acumulado |
| plague_carrion | peak | 40 | 30.9 | 33.0 | 21.5 | 37.8 | 10% | runs |
| soul_harvest | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.1 | 10% | runs |
| hollow_armor | elixir_max | 20 | 14.9 | 14.0 | 10.0 | 20.6 | 20% | runs |
| soul_feast | plays | 400 | 323.4 | 325.5 | 188.4 | 422.9 | 25% | acumulado |
| bat_nest | peak | 3 | 2.3 | 2.0 | 0.0 | 4.1 | 45% | runs |
| cave_troll | win_phase | 1 | 0.5 | 0.5 | 0.0 | 1.0 | 50% |  |
| life_drain | curses | 5 | 5.8 | 8.0 | 0.0 | 10.0 | 55% | runs |
| shadow_echo | plays_window | 5 | 4.8 | 5.0 | 3.0 | 7.0 | 60% |  |
| soul_collector | burst | 2000 | 2524.4 | 2288.2 | 1207.5 | 4362.3 | 60% |  |
| arcane_spark | plays | 120 | 138.2 | 129.5 | 76.8 | 197.6 | 65% | acumulado |
| fallen_healer | loss_max | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 65% |  |
| flooded_pit | plays | 5 | 14.9 | 13.0 | 0.0 | 32.1 | 70% | runs |
| burn_village | burn_time | 150 | 200.6 | 184.3 | 73.5 | 338.9 | 75% | acumulado |
| ash_phoenix | gold_end | 1000 | 1395.8 | 1341.8 | 919.9 | 1813.4 | 85% | runs |
| arcane_apocalypse | plays_window | 7 | 10.4 | 10.0 | 7.0 | 16.0 | 95% |  |
| eternal_army | peak | 12 | 17.6 | 17.0 | 13.8 | 22.1 | 95% | runs |
| soul_storm | spells_distinct | 6 | 8.3 | 8.0 | 6.0 | 11.1 | 95% |  |
| black_pestilence | plays | 150 | 323.4 | 325.5 | 188.4 | 422.9 | 100% | acumulado |
| blood_tax | plays | 100 | 323.4 | 325.5 | 188.4 | 422.9 | 100% | acumulado |
| ember_rain | plays | 25 | 323.4 | 325.5 | 188.4 | 422.9 | 100% | runs |
| hunt_instinct | plays | 40 | 323.4 | 325.5 | 188.4 | 422.9 | 100% | acumulado |
| magma_golem | peak | 10 | 30.9 | 33.0 | 21.5 | 37.8 | 100% | runs |
| rat_tide | plays_same | 40 | 111.2 | 115.0 | 71.8 | 151.5 | 100% | runs |
| spike_trap | plays_window | 5 | 6.9 | 7.0 | 5.9 | 8.1 | 100% |  |

## random|plague (n=20, vitória 85%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 3.3 | 0.0 | 0.0 | 11.4 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 951.0 | 991.0 | 713.7 | 1165.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.5 | 7.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.8 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.5 | 7.0 | 4.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 12.4 | 0.0 | 0.0 | 57.1 | 0% | acumulado |
| corrupt_piper | died | 2000 | 653.1 | 644.5 | 472.0 | 821.6 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 2.4 | 0.0 | 0.0 | 13.0 | 0% | acumulado |
| furnace | wins | 2 | 0.8 | 1.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 879.8 | 867.4 | 719.7 | 1106.0 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| hollow_armor | elixir_max | 20 | 13.8 | 13.0 | 11.0 | 18.0 | 0% | runs |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 20.2 | 18.0 | 8.9 | 34.2 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 667.8 | 659.5 | 573.7 | 812.3 | 0% | acumulado |
| ogre | plays | 600 | 188.0 | 189.5 | 151.6 | 234.2 | 0% | acumulado |
| primal_beast | plays | 600 | 142.4 | 138.0 | 113.9 | 174.8 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.8 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 293.4 | 290.0 | 239.8 | 359.3 | 0% | acumulado |
| soul_feast | plays | 400 | 82.8 | 77.5 | 58.8 | 115.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 61.0 | 62.0 | 39.4 | 76.7 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 307.0 | 312.5 | 67.5 | 553.5 | 0% | acumulado |
| black_pestilence | plays | 150 | 82.8 | 77.5 | 58.8 | 115.6 | 5% | acumulado |
| mother_nest | peak_on_spell | 20 | 13.1 | 11.0 | 7.9 | 16.3 | 5% | runs |
| pack_den | plays | 40 | 20.2 | 18.0 | 8.9 | 34.2 | 5% | acumulado |
| soul_collector | burst | 2000 | 1040.9 | 976.2 | 652.6 | 1393.6 | 5% |  |
| arcane_apocalypse | plays_window | 7 | 4.5 | 4.0 | 3.0 | 6.1 | 10% |  |
| ash_phoenix | gold_end | 1000 | 572.8 | 544.0 | 222.9 | 945.0 | 10% | runs |
| blood_tax | plays | 100 | 82.8 | 77.5 | 58.8 | 115.6 | 15% | acumulado |
| plague_carrion | peak | 40 | 25.3 | 22.0 | 15.0 | 44.2 | 15% | runs |
| alpha_beast | peak | 30 | 22.7 | 19.0 | 12.9 | 43.3 | 20% |  |
| flooded_pit | plays | 5 | 2.4 | 0.0 | 0.0 | 13.0 | 20% | runs |
| soul_storm | spells_distinct | 6 | 4.8 | 5.0 | 3.9 | 6.0 | 20% |  |
| bat_nest | peak | 3 | 2.0 | 2.0 | 1.0 | 3.0 | 25% | runs |
| spike_trap | plays_window | 5 | 4.3 | 4.0 | 4.0 | 5.0 | 35% |  |
| rat_tide | plays_same | 40 | 41.8 | 40.0 | 28.9 | 50.6 | 50% | runs |
| fallen_healer | loss_max | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 60% |  |
| life_drain | curses | 5 | 6.1 | 10.0 | 0.0 | 10.0 | 60% | runs |
| slime | peak_multi | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 80% |  |
| cave_troll | win_phase | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 85% |  |
| bat_cloud | peak | 12 | 22.9 | 19.0 | 12.9 | 43.3 | 95% | runs |
| ember_rain | plays | 25 | 82.8 | 77.5 | 58.8 | 115.6 | 100% | runs |
| hunt_instinct | plays | 40 | 82.8 | 77.5 | 58.8 | 115.6 | 100% | acumulado |
| magma_golem | peak | 10 | 25.3 | 22.0 | 15.0 | 44.2 | 100% | runs |
| rat_trap | peste | 5 | 14.3 | 15.0 | 14.6 | 15.0 | 100% | runs |

## random|plague@3 (n=20, vitória 50%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 4.2 | 0.0 | 0.0 | 13.5 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1058.0 | 1025.5 | 802.1 | 1384.3 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.3 | 6.0 | 3.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.5 | 0.5 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.3 | 6.0 | 3.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 4.5 | 0.0 | 0.0 | 5.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 692.7 | 683.5 | 487.5 | 868.5 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 3.3 | 0.0 | 0.0 | 12.1 | 0% | acumulado |
| furnace | wins | 2 | 0.5 | 0.5 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1938.4 | 1918.9 | 1320.8 | 2548.0 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 791.5 | 769.0 | 596.5 | 960.9 | 0% | acumulado |
| ogre | plays | 600 | 218.8 | 203.0 | 163.2 | 267.1 | 0% | acumulado |
| primal_beast | plays | 600 | 158.1 | 149.5 | 109.0 | 236.0 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.5 | 0.5 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.6 | 0.0 | 0.0 | 2.0 | 0% |  |
| shadow_mark | plays | 1000 | 356.8 | 331.5 | 232.0 | 474.6 | 0% | acumulado |
| soul_feast | plays | 400 | 107.6 | 91.5 | 54.6 | 175.4 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 74.0 | 65.0 | 54.0 | 112.5 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 523.5 | 462.5 | 59.0 | 1052.0 | 0% | acumulado |
| mimic | plays | 60 | 27.1 | 21.0 | 11.8 | 48.4 | 5% | acumulado |
| hollow_armor | elixir_max | 20 | 15.1 | 14.5 | 10.9 | 18.6 | 10% | runs |
| black_pestilence | plays | 150 | 107.6 | 91.5 | 54.6 | 175.4 | 20% | acumulado |
| pack_den | plays | 40 | 27.1 | 21.0 | 11.8 | 48.4 | 20% | acumulado |
| flooded_pit | plays | 5 | 3.3 | 0.0 | 0.0 | 12.1 | 25% | runs |
| arcane_apocalypse | plays_window | 7 | 5.0 | 4.5 | 3.0 | 7.0 | 30% |  |
| soul_storm | spells_distinct | 6 | 5.2 | 5.0 | 3.9 | 7.0 | 35% |  |
| blood_tax | plays | 100 | 107.6 | 91.5 | 54.6 | 175.4 | 40% | acumulado |
| bat_nest | peak | 3 | 2.9 | 2.0 | 1.9 | 5.0 | 45% | runs |
| cave_troll | win_phase | 1 | 0.5 | 0.5 | 0.0 | 1.0 | 50% |  |
| spike_trap | plays_window | 5 | 4.8 | 4.5 | 4.0 | 6.0 | 50% |  |
| plague_carrion | peak | 40 | 44.5 | 44.5 | 27.8 | 62.3 | 55% | runs |
| life_drain | curses | 5 | 6.0 | 7.5 | 0.0 | 10.0 | 60% | runs |
| alpha_beast | peak | 30 | 38.8 | 39.5 | 20.7 | 56.0 | 70% |  |
| ash_phoenix | gold_end | 1000 | 1414.9 | 1566.2 | 599.8 | 1994.7 | 70% | runs |
| rat_tide | plays_same | 40 | 47.4 | 45.5 | 33.5 | 69.2 | 70% | runs |
| soul_collector | burst | 2000 | 2367.7 | 2188.1 | 1688.7 | 3188.9 | 70% |  |
| fallen_healer | loss_max | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 80% |  |
| mother_nest | peak_on_spell | 20 | 30.9 | 29.5 | 15.0 | 44.3 | 80% | runs |
| bat_cloud | peak | 12 | 39.6 | 39.5 | 23.9 | 56.0 | 100% | runs |
| ember_rain | plays | 25 | 107.6 | 91.5 | 54.6 | 175.4 | 100% | runs |
| hunt_instinct | plays | 40 | 107.6 | 91.5 | 54.6 | 175.4 | 100% | acumulado |
| magma_golem | peak | 10 | 44.5 | 44.5 | 27.8 | 62.3 | 100% | runs |
| rat_trap | peste | 5 | 15.0 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
