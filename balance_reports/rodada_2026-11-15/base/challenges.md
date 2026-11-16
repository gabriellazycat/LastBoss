# Objetivos das cartas: o que uma run alcança

`mediana` = valor típico por run (já na unidade do desafio); `cumpre` = fração das runs que bate a meta atual.
Desafios com `total`/`runs` somam várias fases: o valor aqui é o de UMA run (compare com meta ÷ nº de runs esperado).

## heuristic|dragon (n=25, vitória 40%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 532.6 | 488.0 | 367.6 | 684.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.0 | 6.0 | 4.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.0 | 6.0 | 4.4 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 33.4 | 27.0 | 9.0 | 58.8 | 0% | acumulado |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| molten_gold | elixir_spent | 2000 | 1054.7 | 1052.0 | 775.4 | 1278.4 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 207.3 | 202.0 | 139.8 | 262.8 | 0% | acumulado |
| plague_carrion | peak | 40 | 12.5 | 13.0 | 9.8 | 15.6 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 374.2 | 361.0 | 271.0 | 461.4 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 100.4 | 93.0 | 74.0 | 128.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 4.2 | 4.0 | 3.4 | 5.0 | 0% |  |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 722.6 | 715.0 | 416.0 | 1126.0 | 0% | acumulado |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| mimic | plays | 60 | 32.1 | 30.0 | 18.0 | 49.8 | 4% | acumulado |
| soul_collector | burst | 2000 | 1352.0 | 1282.1 | 934.3 | 1854.4 | 4% |  |
| arcane_apocalypse | plays_window | 7 | 5.0 | 5.0 | 4.0 | 6.0 | 8% |  |
| black_pestilence | plays | 150 | 100.4 | 93.0 | 74.0 | 128.6 | 8% | acumulado |
| gold_avalanche | gold_earned | 6000 | 4148.6 | 3522.3 | 1893.8 | 6989.2 | 16% | acumulado |
| pack_den | plays | 40 | 32.1 | 30.0 | 18.0 | 49.8 | 20% | acumulado |
| gold_bait | coins | 25 | 20.2 | 20.0 | 9.8 | 33.6 | 24% | acumulado |
| burn_village | burn_time | 150 | 111.5 | 80.7 | 12.1 | 270.2 | 28% | acumulado |
| elder_dragon | peak | 5 | 4.4 | 4.0 | 3.0 | 6.0 | 32% |  |
| ash_phoenix | gold_end | 1000 | 1381.1 | 429.6 | 73.3 | 3225.8 | 36% | runs |
| bat_nest | peak | 3 | 2.8 | 2.0 | 2.0 | 4.6 | 36% | runs |
| meteor_storm | plays | 80 | 73.0 | 73.0 | 51.0 | 101.8 | 36% | acumulado |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 40% |  |
| hollow_armor | elixir_max | 20 | 18.8 | 19.0 | 15.4 | 23.0 | 40% | runs |
| blood_tax | plays | 100 | 100.4 | 93.0 | 74.0 | 128.6 | 44% | acumulado |
| spike_trap | plays_window | 5 | 4.8 | 5.0 | 4.0 | 6.0 | 56% |  |
| boiling_oil | soaked_time | 75 | 131.9 | 119.4 | 47.0 | 228.8 | 80% | acumulado |
| magma_golem | peak | 10 | 12.5 | 13.0 | 9.8 | 15.6 | 88% | runs |
| rat_tide | plays_same | 40 | 55.8 | 50.0 | 39.4 | 74.2 | 88% | runs |
| flooded_pit | plays | 5 | 33.4 | 27.0 | 9.0 | 58.8 | 92% | runs |
| life_drain | curses | 5 | 8.8 | 10.0 | 5.4 | 10.0 | 92% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 96% | runs |
| ember_rain | plays | 25 | 100.4 | 93.0 | 74.0 | 128.6 | 100% | runs |
| hunt_instinct | plays | 40 | 100.4 | 93.0 | 74.0 | 128.6 | 100% | acumulado |

## heuristic|dragon@3 (n=25, vitória 8%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 565.1 | 556.0 | 444.0 | 723.4 | 0% | acumulado |
| bone_dragon | heroes | 35 | 4.9 | 5.0 | 4.0 | 6.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| brown_bear | heroes | 20 | 4.9 | 5.0 | 4.0 | 6.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 50.5 | 51.0 | 11.4 | 91.0 | 0% | acumulado |
| furnace | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| ghost | peak | 40 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 230.0 | 227.0 | 166.6 | 296.6 | 0% | acumulado |
| plague_carrion | peak | 40 | 16.9 | 15.0 | 11.8 | 24.0 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 429.7 | 425.0 | 335.2 | 548.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 114.6 | 114.0 | 85.2 | 149.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 4.8 | 5.0 | 4.0 | 6.0 | 4% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| molten_gold | elixir_spent | 2000 | 1292.5 | 1277.0 | 965.8 | 1658.4 | 4% | acumulado |
| tar_net | gold_spent | 2000 | 1088.8 | 985.0 | 647.0 | 1548.0 | 4% | acumulado |
| cave_troll | win_phase | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| black_pestilence | plays | 150 | 114.6 | 114.0 | 85.2 | 149.6 | 12% | acumulado |
| fallen_healer | loss_max | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% |  |
| mimic | plays | 60 | 34.2 | 32.0 | 21.8 | 57.0 | 12% | acumulado |
| soul_storm | spells_distinct | 6 | 4.6 | 5.0 | 4.0 | 5.6 | 12% |  |
| burn_village | burn_time | 150 | 99.8 | 43.8 | 12.1 | 249.6 | 24% | acumulado |
| pack_den | plays | 40 | 34.2 | 32.0 | 21.8 | 57.0 | 24% | acumulado |
| soul_collector | burst | 2000 | 2066.5 | 1746.4 | 1400.0 | 2944.5 | 32% |  |
| gold_bait | coins | 25 | 24.2 | 22.0 | 16.2 | 33.0 | 44% | acumulado |
| hollow_armor | elixir_max | 20 | 20.0 | 19.0 | 16.0 | 25.4 | 44% | runs |
| meteor_storm | plays | 80 | 79.5 | 78.0 | 61.0 | 104.6 | 48% | acumulado |
| gold_avalanche | gold_earned | 6000 | 8639.0 | 7880.0 | 3764.2 | 14796.0 | 56% | acumulado |
| bat_nest | peak | 3 | 3.4 | 3.0 | 2.0 | 5.0 | 60% | runs |
| spike_trap | plays_window | 5 | 5.0 | 5.0 | 4.0 | 6.0 | 60% |  |
| elder_dragon | peak | 5 | 5.2 | 5.0 | 4.0 | 6.6 | 68% |  |
| ash_phoenix | gold_end | 1000 | 3822.3 | 1887.2 | 153.8 | 9210.4 | 76% | runs |
| blood_tax | plays | 100 | 114.6 | 114.0 | 85.2 | 149.6 | 80% | acumulado |
| boiling_oil | soaked_time | 75 | 129.1 | 139.0 | 53.7 | 198.8 | 80% | acumulado |
| flooded_pit | plays | 5 | 50.5 | 51.0 | 11.4 | 91.0 | 92% | runs |
| rat_tide | plays_same | 40 | 59.8 | 57.0 | 42.4 | 85.0 | 96% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 96% | runs |
| ember_rain | plays | 25 | 114.6 | 114.0 | 85.2 | 149.6 | 100% | runs |
| hunt_instinct | plays | 40 | 114.6 | 114.0 | 85.2 | 149.6 | 100% | acumulado |
| life_drain | curses | 5 | 9.8 | 10.0 | 10.0 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 16.9 | 15.0 | 11.8 | 24.0 | 100% | runs |

## heuristic|lich (n=25, vitória 80%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1017.6 | 951.0 | 726.0 | 1415.8 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.6 | 7.0 | 5.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.8 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.6 | 7.0 | 5.4 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 50.7 | 54.0 | 16.0 | 73.0 | 0% | acumulado |
| furnace | wins | 2 | 0.8 | 1.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 15.1 | 15.0 | 10.0 | 19.6 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1987.4 | 2066.7 | 1652.3 | 2286.0 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1020.4 | 970.0 | 809.2 | 1277.2 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 209.9 | 200.0 | 164.6 | 273.2 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.8 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 555.3 | 533.0 | 455.4 | 734.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 728.0 | 720.0 | 407.0 | 966.0 | 0% | acumulado |
| soul_feast | plays | 400 | 278.7 | 271.0 | 214.8 | 355.8 | 4% | acumulado |
| mimic | plays | 60 | 16.0 | 7.0 | 0.0 | 54.8 | 8% | acumulado |
| plague_carrion | peak | 40 | 24.3 | 21.0 | 16.0 | 37.0 | 12% | runs |
| pack_den | plays | 40 | 16.0 | 7.0 | 0.0 | 54.8 | 20% | acumulado |
| bat_nest | peak | 3 | 1.7 | 1.0 | 0.0 | 4.0 | 28% | runs |
| eruption | win_without | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 36% |  |
| soul_harvest | win_without | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 36% | runs |
| burn_village | burn_time | 150 | 146.4 | 136.3 | 62.6 | 197.2 | 40% | acumulado |
| life_drain | curses | 5 | 4.6 | 4.0 | 0.0 | 10.0 | 48% | runs |
| arcane_spark | plays | 120 | 135.3 | 137.0 | 92.4 | 171.8 | 72% | acumulado |
| hollow_armor | elixir_max | 20 | 24.4 | 21.0 | 16.4 | 35.2 | 72% | runs |
| ash_phoenix | gold_end | 1000 | 1259.4 | 1316.7 | 793.4 | 1730.7 | 80% | runs |
| cave_troll | win_phase | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 80% |  |
| shadow_echo | plays_window | 5 | 6.2 | 6.0 | 4.0 | 8.0 | 84% |  |
| soul_storm | spells_distinct | 6 | 6.1 | 6.0 | 5.0 | 7.0 | 84% |  |
| soul_collector | burst | 2000 | 3739.6 | 3639.5 | 1586.5 | 6600.2 | 88% |  |
| eternal_army | peak | 12 | 15.4 | 15.0 | 12.0 | 19.6 | 92% | runs |
| arcane_apocalypse | plays_window | 7 | 13.9 | 13.0 | 10.0 | 19.0 | 96% |  |
| black_pestilence | plays | 150 | 278.7 | 271.0 | 214.8 | 355.8 | 96% | acumulado |
| rat_tide | plays_same | 40 | 61.9 | 58.0 | 45.6 | 88.6 | 96% | runs |
| blood_tax | plays | 100 | 278.7 | 271.0 | 214.8 | 355.8 | 100% | acumulado |
| ember_rain | plays | 25 | 278.7 | 271.0 | 214.8 | 355.8 | 100% | runs |
| flooded_pit | plays | 5 | 50.7 | 54.0 | 16.0 | 73.0 | 100% | runs |
| hunt_instinct | plays | 40 | 278.7 | 271.0 | 214.8 | 355.8 | 100% | acumulado |
| magma_golem | peak | 10 | 24.3 | 21.0 | 16.0 | 37.0 | 100% | runs |
| spike_trap | plays_window | 5 | 10.6 | 10.0 | 8.0 | 14.2 | 100% |  |

## heuristic|lich@3 (n=25, vitória 28%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1151.2 | 1088.0 | 783.0 | 1725.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.0 | 5.0 | 3.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.0 | 5.0 | 3.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| furnace | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 246.2 | 230.0 | 175.4 | 331.0 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 760.4 | 705.0 | 462.0 | 1040.0 | 0% | acumulado |
| forbidden_library | plays | 200 | 70.6 | 55.0 | 8.6 | 123.8 | 4% | acumulado |
| gold_avalanche | gold_earned | 6000 | 3491.9 | 3429.1 | 2110.5 | 4853.7 | 4% | acumulado |
| mimic | plays | 60 | 21.9 | 21.0 | 0.0 | 41.4 | 4% | acumulado |
| molten_gold | elixir_spent | 2000 | 1225.2 | 1196.0 | 808.2 | 1869.2 | 4% | acumulado |
| shadow_mark | plays | 1000 | 657.4 | 627.0 | 438.0 | 901.8 | 4% | acumulado |
| fallen_healer | loss_max | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| ghost | peak | 40 | 20.9 | 17.0 | 12.0 | 37.6 | 12% | runs |
| pack_den | plays | 40 | 21.9 | 21.0 | 0.0 | 41.4 | 12% | acumulado |
| soul_feast | plays | 400 | 318.8 | 283.0 | 206.4 | 458.8 | 20% | acumulado |
| cave_troll | win_phase | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 28% |  |
| bat_nest | peak | 3 | 3.0 | 2.0 | 0.4 | 5.6 | 44% | runs |
| plague_carrion | peak | 40 | 36.1 | 32.0 | 20.2 | 57.2 | 44% | runs |
| burn_village | burn_time | 150 | 193.3 | 146.4 | 90.2 | 285.8 | 48% | acumulado |
| life_drain | curses | 5 | 5.6 | 7.0 | 0.0 | 10.0 | 56% | runs |
| hollow_armor | elixir_max | 20 | 24.9 | 23.0 | 18.4 | 27.0 | 68% | runs |
| arcane_spark | plays | 120 | 154.1 | 148.0 | 88.4 | 228.0 | 76% | acumulado |
| shadow_echo | plays_window | 5 | 6.2 | 6.0 | 4.0 | 8.0 | 80% |  |
| ash_phoenix | gold_end | 1000 | 2731.4 | 2671.2 | 1358.2 | 3921.7 | 96% | runs |
| eternal_army | peak | 12 | 21.3 | 17.0 | 12.0 | 38.0 | 96% | runs |
| rat_tide | plays_same | 40 | 74.7 | 65.0 | 53.4 | 107.6 | 96% | runs |
| soul_collector | burst | 2000 | 5161.9 | 5287.3 | 2558.0 | 8070.6 | 96% |  |
| arcane_apocalypse | plays_window | 7 | 13.3 | 12.0 | 10.0 | 19.6 | 100% |  |
| black_pestilence | plays | 150 | 318.8 | 283.0 | 206.4 | 458.8 | 100% | acumulado |
| blood_tax | plays | 100 | 318.8 | 283.0 | 206.4 | 458.8 | 100% | acumulado |
| ember_rain | plays | 25 | 318.8 | 283.0 | 206.4 | 458.8 | 100% | runs |
| flooded_pit | plays | 5 | 70.6 | 55.0 | 8.6 | 123.8 | 100% | runs |
| hunt_instinct | plays | 40 | 318.8 | 283.0 | 206.4 | 458.8 | 100% | acumulado |
| magma_golem | peak | 10 | 36.1 | 32.0 | 20.2 | 57.2 | 100% | runs |
| soul_storm | spells_distinct | 6 | 6.4 | 6.0 | 6.0 | 7.0 | 100% |  |
| spike_trap | plays_window | 5 | 10.2 | 10.0 | 7.0 | 13.6 | 100% |  |

## heuristic|plague (n=25, vitória 68%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.2 | 3.0 | 2.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 48.7 | 47.0 | 27.0 | 69.2 | 0% | acumulado |
| blood_tax | plays | 100 | 48.7 | 47.0 | 27.0 | 69.2 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.5 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.5 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 4.2 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 9.6 | 8.0 | 0.0 | 21.4 | 0% | acumulado |
| furnace | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 2091.5 | 1992.9 | 1729.8 | 2723.2 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1190.7 | 1169.0 | 900.8 | 1510.8 | 0% | acumulado |
| ogre | plays | 600 | 264.5 | 259.0 | 195.0 | 336.0 | 0% | acumulado |
| primal_beast | plays | 600 | 146.7 | 147.0 | 106.8 | 186.6 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 358.2 | 358.0 | 268.0 | 466.2 | 0% | acumulado |
| soul_feast | plays | 400 | 48.7 | 47.0 | 27.0 | 69.2 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 4.0 | 4.0 | 3.0 | 5.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 91.0 | 88.0 | 56.4 | 127.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 886.5 | 820.0 | 695.0 | 1224.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 2274.7 | 2292.0 | 1485.0 | 2910.0 | 8% | acumulado |
| mimic | plays | 60 | 35.3 | 31.0 | 18.4 | 53.6 | 8% | acumulado |
| soul_collector | burst | 2000 | 1778.2 | 1381.0 | 933.0 | 2492.3 | 20% |  |
| bat_nest | peak | 3 | 2.1 | 2.0 | 1.0 | 3.0 | 32% | runs |
| hollow_armor | elixir_max | 20 | 19.8 | 19.0 | 15.4 | 26.0 | 36% | runs |
| corrupt_piper | died | 2000 | 1820.3 | 1824.0 | 1164.8 | 2489.6 | 40% | acumulado |
| pack_den | plays | 40 | 35.3 | 31.0 | 18.4 | 53.6 | 48% | acumulado |
| flooded_pit | plays | 5 | 9.6 | 8.0 | 0.0 | 21.4 | 52% | runs |
| spike_trap | plays_window | 5 | 4.6 | 5.0 | 3.0 | 5.0 | 56% |  |
| ash_phoenix | gold_end | 1000 | 1205.0 | 1121.1 | 693.6 | 1955.3 | 60% | runs |
| life_drain | curses | 5 | 6.7 | 10.0 | 0.4 | 10.0 | 64% | runs |
| cave_troll | win_phase | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 68% |  |
| hunt_instinct | plays | 40 | 48.7 | 47.0 | 27.0 | 69.2 | 72% | acumulado |
| mother_nest | peak_on_spell | 20 | 34.9 | 38.0 | 9.8 | 53.2 | 76% | runs |
| rat_tide | plays_same | 40 | 53.6 | 52.0 | 37.8 | 72.6 | 84% | runs |
| alpha_beast | peak | 30 | 53.2 | 50.0 | 43.2 | 71.2 | 92% |  |
| ember_rain | plays | 25 | 48.7 | 47.0 | 27.0 | 69.2 | 92% | runs |
| plague_carrion | peak | 40 | 56.0 | 53.0 | 45.0 | 78.6 | 92% | runs |
| bat_cloud | peak | 12 | 53.5 | 50.0 | 43.2 | 71.2 | 100% | runs |
| magma_golem | peak | 10 | 56.0 | 53.0 | 45.0 | 78.6 | 100% | runs |
| rat_trap | peste | 5 | 14.3 | 15.0 | 11.8 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## heuristic|plague@3 (n=25, vitória 16%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 1.8 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 65.2 | 58.0 | 43.4 | 96.2 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.8 | 6.0 | 4.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.8 | 6.0 | 4.4 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 5.1 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 15.1 | 17.0 | 0.0 | 30.2 | 0% | acumulado |
| furnace | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 1.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| primal_beast | plays | 600 | 186.6 | 193.0 | 119.4 | 241.4 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.2 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 475.3 | 476.0 | 302.0 | 662.2 | 0% | acumulado |
| soul_feast | plays | 400 | 65.2 | 58.0 | 43.4 | 96.2 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| tar_net | gold_spent | 2000 | 990.1 | 995.0 | 704.8 | 1334.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 3.8 | 3.0 | 3.0 | 5.6 | 4% |  |
| eternal_army | peak | 12 | 1.0 | 0.0 | 0.0 | 0.0 | 4% | runs |
| ogre | plays | 600 | 352.6 | 343.0 | 225.8 | 520.8 | 4% | acumulado |
| soul_storm | spells_distinct | 6 | 4.2 | 4.0 | 3.0 | 5.0 | 4% |  |
| blood_tax | plays | 100 | 65.2 | 58.0 | 43.4 | 96.2 | 8% | acumulado |
| gold_avalanche | gold_earned | 6000 | 4447.8 | 4295.1 | 2930.3 | 5932.1 | 12% | acumulado |
| cave_troll | win_phase | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 16% |  |
| molten_gold | elixir_spent | 2000 | 1603.3 | 1664.0 | 1016.8 | 2207.2 | 20% | acumulado |
| bat_nest | peak | 3 | 2.3 | 2.0 | 1.0 | 3.0 | 24% | runs |
| mimic | plays | 60 | 42.4 | 38.0 | 21.0 | 73.4 | 24% | acumulado |
| spitting_viper | plays | 150 | 126.4 | 124.0 | 71.2 | 189.8 | 36% | acumulado |
| pack_den | plays | 40 | 42.4 | 38.0 | 21.0 | 73.4 | 44% | acumulado |
| bone_colossus | died | 3000 | 3239.3 | 2876.0 | 1786.2 | 4573.2 | 48% | acumulado |
| corrupt_piper | died | 2000 | 2574.0 | 2163.0 | 1330.6 | 3998.4 | 60% | acumulado |
| flooded_pit | plays | 5 | 15.1 | 17.0 | 0.0 | 30.2 | 60% | runs |
| soul_collector | burst | 2000 | 2858.9 | 2559.3 | 1507.9 | 5299.3 | 60% |  |
| hollow_armor | elixir_max | 20 | 22.2 | 23.0 | 16.0 | 27.6 | 64% | runs |
| life_drain | curses | 5 | 6.1 | 10.0 | 0.0 | 10.0 | 64% | runs |
| mother_nest | peak_on_spell | 20 | 39.0 | 30.0 | 15.2 | 82.6 | 72% | runs |
| spike_trap | plays_window | 5 | 5.4 | 5.0 | 4.0 | 7.0 | 76% |  |
| hunt_instinct | plays | 40 | 65.2 | 58.0 | 43.4 | 96.2 | 92% | acumulado |
| plague_carrion | peak | 40 | 69.3 | 56.0 | 43.4 | 117.4 | 92% | runs |
| alpha_beast | peak | 30 | 63.6 | 53.0 | 39.2 | 103.4 | 96% |  |
| rat_tide | plays_same | 40 | 68.8 | 63.0 | 40.4 | 100.0 | 96% | runs |
| ash_phoenix | gold_end | 1000 | 3457.6 | 3302.5 | 1828.4 | 5129.8 | 100% | runs |
| bat_cloud | peak | 12 | 64.8 | 53.0 | 42.0 | 105.4 | 100% | runs |
| ember_rain | plays | 25 | 65.2 | 58.0 | 43.4 | 96.2 | 100% | runs |
| magma_golem | peak | 10 | 69.3 | 56.0 | 43.4 | 117.4 | 100% | runs |
| rat_trap | peste | 5 | 14.8 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_careful|dragon (n=25, vitória 20%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 65.4 | 63.0 | 41.4 | 89.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 415.6 | 392.0 | 298.4 | 565.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.6 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.6 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 36.6 | 30.0 | 0.8 | 83.4 | 0% | acumulado |
| furnace | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| meteor_storm | plays | 80 | 42.5 | 45.0 | 28.6 | 60.2 | 0% | acumulado |
| mimic | plays | 60 | 20.2 | 19.0 | 6.2 | 38.8 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 878.0 | 889.0 | 608.0 | 1068.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 174.5 | 174.0 | 123.4 | 221.6 | 0% | acumulado |
| plague_carrion | peak | 40 | 13.0 | 12.0 | 10.4 | 16.0 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 297.4 | 300.0 | 218.8 | 373.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 65.4 | 63.0 | 41.4 | 89.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 852.2 | 835.0 | 498.0 | 1215.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 4.7 | 5.0 | 3.0 | 6.0 | 4% |  |
| blood_tax | plays | 100 | 65.4 | 63.0 | 41.4 | 89.0 | 4% | acumulado |
| fallen_healer | loss_max | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| soul_collector | burst | 2000 | 1336.8 | 1301.5 | 941.7 | 1934.7 | 8% |  |
| gold_avalanche | gold_earned | 6000 | 3879.7 | 3867.4 | 1602.0 | 5988.7 | 12% | acumulado |
| gold_bait | coins | 25 | 15.6 | 16.0 | 7.8 | 24.6 | 12% | acumulado |
| pack_den | plays | 40 | 20.2 | 19.0 | 6.2 | 38.8 | 12% | acumulado |
| elder_dragon | peak | 5 | 4.0 | 4.0 | 3.0 | 5.0 | 16% |  |
| soul_storm | spells_distinct | 6 | 4.7 | 5.0 | 4.0 | 6.0 | 16% |  |
| burn_village | burn_time | 150 | 99.2 | 74.1 | 24.6 | 226.4 | 20% | acumulado |
| cave_troll | win_phase | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 20% |  |
| ash_phoenix | gold_end | 1000 | 845.2 | 435.8 | 25.1 | 2359.2 | 28% | runs |
| bat_nest | peak | 3 | 2.1 | 2.0 | 1.0 | 3.0 | 28% | runs |
| hollow_armor | elixir_max | 20 | 19.7 | 18.0 | 13.8 | 26.6 | 40% | runs |
| dragon_exchange | soak_ignite | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 44% |  |
| rat_tide | plays_same | 40 | 43.2 | 40.0 | 29.2 | 61.2 | 60% | runs |
| boiling_oil | soaked_time | 75 | 125.6 | 107.5 | 53.4 | 252.1 | 68% | acumulado |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 6.0 | 76% |  |
| flooded_pit | plays | 5 | 36.6 | 30.0 | 0.8 | 83.4 | 80% | runs |
| life_drain | curses | 5 | 8.8 | 10.0 | 4.8 | 10.0 | 88% | runs |
| hunt_instinct | plays | 40 | 65.4 | 63.0 | 41.4 | 89.0 | 96% | acumulado |
| ember_rain | plays | 25 | 65.4 | 63.0 | 41.4 | 89.0 | 100% | runs |
| magma_golem | peak | 10 | 13.0 | 12.0 | 10.4 | 16.0 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_careful|dragon@3 (n=25, vitória 8%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 581.6 | 578.0 | 415.8 | 758.4 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.3 | 5.0 | 4.0 | 6.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| brown_bear | heroes | 20 | 5.3 | 5.0 | 4.0 | 6.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 63.2 | 55.0 | 23.0 | 118.0 | 0% | acumulado |
| furnace | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| ghost | peak | 40 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 243.1 | 232.0 | 193.4 | 304.8 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 422.8 | 403.0 | 317.8 | 513.6 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 84.6 | 85.0 | 48.0 | 116.4 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 31.8 | 31.0 | 16.8 | 50.0 | 4% | acumulado |
| molten_gold | elixir_spent | 2000 | 1308.3 | 1298.0 | 999.4 | 1625.0 | 4% | acumulado |
| plague_carrion | peak | 40 | 17.8 | 15.0 | 12.0 | 26.2 | 4% | runs |
| soul_storm | spells_distinct | 6 | 4.5 | 5.0 | 4.0 | 5.0 | 4% |  |
| black_pestilence | plays | 150 | 84.6 | 85.0 | 48.0 | 116.4 | 8% | acumulado |
| cave_troll | win_phase | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| fallen_healer | loss_max | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| tar_net | gold_spent | 2000 | 1343.2 | 1340.0 | 708.0 | 1865.0 | 8% | acumulado |
| meteor_storm | plays | 80 | 48.4 | 45.0 | 14.0 | 82.6 | 12% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.4 | 5.0 | 4.0 | 7.0 | 16% |  |
| pack_den | plays | 40 | 31.8 | 31.0 | 16.8 | 50.0 | 20% | acumulado |
| blood_tax | plays | 100 | 84.6 | 85.0 | 48.0 | 116.4 | 24% | acumulado |
| burn_village | burn_time | 150 | 122.2 | 83.5 | 16.9 | 282.2 | 28% | acumulado |
| gold_bait | coins | 25 | 21.0 | 21.0 | 10.8 | 30.0 | 32% | acumulado |
| soul_collector | burst | 2000 | 1928.4 | 1800.0 | 1305.1 | 2525.6 | 32% |  |
| bat_nest | peak | 3 | 3.1 | 3.0 | 2.0 | 5.0 | 56% | runs |
| hollow_armor | elixir_max | 20 | 22.0 | 20.0 | 15.4 | 31.0 | 56% | runs |
| dragon_exchange | soak_ignite | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 60% |  |
| boiling_oil | soaked_time | 75 | 148.1 | 109.5 | 33.8 | 240.6 | 64% | acumulado |
| elder_dragon | peak | 5 | 5.7 | 5.0 | 4.0 | 7.0 | 64% |  |
| ash_phoenix | gold_end | 1000 | 3835.6 | 1686.7 | 185.0 | 11280.9 | 68% | runs |
| gold_avalanche | gold_earned | 6000 | 10150.5 | 9355.3 | 4405.6 | 18832.1 | 72% | acumulado |
| rat_tide | plays_same | 40 | 57.0 | 54.0 | 39.8 | 82.0 | 88% | runs |
| spike_trap | plays_window | 5 | 5.9 | 6.0 | 5.0 | 7.0 | 92% |  |
| flooded_pit | plays | 5 | 63.2 | 55.0 | 23.0 | 118.0 | 96% | runs |
| hunt_instinct | plays | 40 | 84.6 | 85.0 | 48.0 | 116.4 | 96% | acumulado |
| ember_rain | plays | 25 | 84.6 | 85.0 | 48.0 | 116.4 | 100% | runs |
| life_drain | curses | 5 | 9.7 | 10.0 | 8.4 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 17.8 | 15.0 | 12.0 | 26.2 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_careful|lich (n=25, vitória 64%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 815.0 | 776.0 | 609.2 | 1194.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.4 | 7.0 | 5.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.4 | 7.0 | 5.4 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 46.4 | 45.0 | 25.4 | 67.8 | 0% | acumulado |
| furnace | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 1832.4 | 1857.8 | 1376.0 | 2236.1 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 15.6 | 9.0 | 0.0 | 39.2 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 886.6 | 861.0 | 741.4 | 1008.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 181.9 | 182.0 | 147.4 | 224.8 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 449.8 | 456.0 | 381.6 | 517.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 205.9 | 202.0 | 159.2 | 261.6 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 693.8 | 635.0 | 429.0 | 1040.0 | 0% | acumulado |
| ghost | peak | 40 | 18.3 | 14.0 | 10.0 | 31.8 | 4% | runs |
| pack_den | plays | 40 | 15.6 | 9.0 | 0.0 | 39.2 | 12% | acumulado |
| plague_carrion | peak | 40 | 28.4 | 24.0 | 18.0 | 39.6 | 12% | runs |
| arcane_spark | plays | 120 | 106.4 | 105.0 | 80.6 | 130.2 | 20% | acumulado |
| eruption | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 20% |  |
| soul_harvest | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 20% | runs |
| burn_village | burn_time | 150 | 139.2 | 121.2 | 67.7 | 245.0 | 32% | acumulado |
| bat_nest | peak | 3 | 1.9 | 2.0 | 0.0 | 3.0 | 36% | runs |
| life_drain | curses | 5 | 4.8 | 2.0 | 0.0 | 10.0 | 44% | runs |
| hollow_armor | elixir_max | 20 | 19.6 | 19.0 | 14.4 | 26.0 | 48% | runs |
| cave_troll | win_phase | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 64% |  |
| ash_phoenix | gold_end | 1000 | 1138.5 | 1175.7 | 538.1 | 1578.4 | 72% | runs |
| eternal_army | peak | 12 | 18.5 | 14.0 | 10.4 | 31.8 | 80% | runs |
| rat_tide | plays_same | 40 | 52.0 | 49.0 | 39.0 | 67.8 | 84% | runs |
| shadow_echo | plays_window | 5 | 5.7 | 6.0 | 4.4 | 7.0 | 88% |  |
| soul_collector | burst | 2000 | 4294.2 | 4305.5 | 1960.7 | 6880.6 | 88% |  |
| soul_storm | spells_distinct | 6 | 6.4 | 6.0 | 6.0 | 7.0 | 92% |  |
| arcane_apocalypse | plays_window | 7 | 11.4 | 11.0 | 9.4 | 14.0 | 100% |  |
| black_pestilence | plays | 150 | 205.9 | 202.0 | 159.2 | 261.6 | 100% | acumulado |
| blood_tax | plays | 100 | 205.9 | 202.0 | 159.2 | 261.6 | 100% | acumulado |
| ember_rain | plays | 25 | 205.9 | 202.0 | 159.2 | 261.6 | 100% | runs |
| flooded_pit | plays | 5 | 46.4 | 45.0 | 25.4 | 67.8 | 100% | runs |
| hunt_instinct | plays | 40 | 205.9 | 202.0 | 159.2 | 261.6 | 100% | acumulado |
| magma_golem | peak | 10 | 28.4 | 24.0 | 18.0 | 39.6 | 100% | runs |
| spike_trap | plays_window | 5 | 8.4 | 8.0 | 6.4 | 11.0 | 100% |  |

## human_careful|lich@3 (n=25, vitória 44%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1181.4 | 1156.0 | 716.2 | 1669.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.9 | 6.0 | 4.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.9 | 6.0 | 4.4 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 79.3 | 67.0 | 39.2 | 138.8 | 0% | acumulado |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 4037.9 | 3959.2 | 2290.7 | 5465.3 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 263.6 | 265.0 | 182.8 | 347.0 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 963.2 | 1025.0 | 703.0 | 1250.0 | 0% | acumulado |
| shadow_mark | plays | 1000 | 676.2 | 661.0 | 469.6 | 859.8 | 4% | acumulado |
| molten_gold | elixir_spent | 2000 | 1371.1 | 1356.0 | 929.6 | 1864.2 | 8% | acumulado |
| soul_feast | plays | 400 | 301.9 | 290.0 | 208.2 | 396.2 | 8% | acumulado |
| eruption | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 16% |  |
| ghost | peak | 40 | 30.1 | 20.0 | 12.0 | 56.2 | 16% | runs |
| soul_harvest | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 16% | runs |
| mimic | plays | 60 | 31.4 | 23.0 | 0.0 | 77.6 | 20% | acumulado |
| pack_den | plays | 40 | 31.4 | 23.0 | 0.0 | 77.6 | 28% | acumulado |
| plague_carrion | peak | 40 | 57.6 | 36.0 | 20.4 | 71.4 | 36% | runs |
| bat_nest | peak | 3 | 2.6 | 2.0 | 0.0 | 5.6 | 40% | runs |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 44% |  |
| burn_village | burn_time | 150 | 217.3 | 166.7 | 98.6 | 365.2 | 56% | acumulado |
| arcane_spark | plays | 120 | 152.0 | 142.0 | 95.8 | 219.6 | 64% | acumulado |
| life_drain | curses | 5 | 7.2 | 10.0 | 0.8 | 10.0 | 68% | runs |
| hollow_armor | elixir_max | 20 | 25.8 | 24.0 | 18.0 | 36.0 | 76% | runs |
| shadow_echo | plays_window | 5 | 6.2 | 6.0 | 4.4 | 8.6 | 88% |  |
| soul_storm | spells_distinct | 6 | 6.5 | 7.0 | 5.4 | 7.0 | 88% |  |
| rat_tide | plays_same | 40 | 75.8 | 74.0 | 46.8 | 116.6 | 92% | runs |
| ash_phoenix | gold_end | 1000 | 3074.5 | 2948.4 | 1274.7 | 4657.0 | 96% | runs |
| eternal_army | peak | 12 | 31.2 | 20.0 | 12.0 | 56.2 | 96% | runs |
| arcane_apocalypse | plays_window | 7 | 13.2 | 13.0 | 10.0 | 16.0 | 100% |  |
| black_pestilence | plays | 150 | 301.9 | 290.0 | 208.2 | 396.2 | 100% | acumulado |
| blood_tax | plays | 100 | 301.9 | 290.0 | 208.2 | 396.2 | 100% | acumulado |
| ember_rain | plays | 25 | 301.9 | 290.0 | 208.2 | 396.2 | 100% | runs |
| flooded_pit | plays | 5 | 79.3 | 67.0 | 39.2 | 138.8 | 100% | runs |
| hunt_instinct | plays | 40 | 301.9 | 290.0 | 208.2 | 396.2 | 100% | acumulado |
| magma_golem | peak | 10 | 57.6 | 36.0 | 20.4 | 71.4 | 100% | runs |
| soul_collector | burst | 2000 | 6770.1 | 5779.7 | 3400.2 | 11080.3 | 100% |  |
| spike_trap | plays_window | 5 | 9.2 | 9.0 | 7.0 | 12.6 | 100% |  |

## human_careful|plague (n=25, vitória 64%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 48.1 | 42.0 | 28.2 | 77.6 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.5 | 7.0 | 5.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.5 | 7.0 | 5.4 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 9.0 | 4.0 | 0.0 | 26.2 | 0% | acumulado |
| furnace | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 1997.4 | 1920.5 | 1597.9 | 2488.6 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1009.4 | 917.0 | 667.8 | 1486.0 | 0% | acumulado |
| ogre | plays | 600 | 217.5 | 214.0 | 149.0 | 285.6 | 0% | acumulado |
| primal_beast | plays | 600 | 127.3 | 118.0 | 70.2 | 197.0 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 302.7 | 296.0 | 197.8 | 454.8 | 0% | acumulado |
| soul_feast | plays | 400 | 48.1 | 42.0 | 28.2 | 77.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 71.4 | 68.0 | 48.6 | 94.6 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 761.8 | 785.0 | 441.0 | 1067.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 3.6 | 3.0 | 3.0 | 4.0 | 4% |  |
| blood_tax | plays | 100 | 48.1 | 42.0 | 28.2 | 77.6 | 4% | acumulado |
| ghost | peak | 40 | 3.2 | 0.0 | 0.0 | 9.0 | 4% | runs |
| soul_storm | spells_distinct | 6 | 4.3 | 4.0 | 4.0 | 5.0 | 4% |  |
| bone_colossus | died | 3000 | 1918.3 | 1643.0 | 1043.0 | 2911.2 | 12% | acumulado |
| eternal_army | peak | 12 | 3.2 | 0.0 | 0.0 | 9.0 | 12% | runs |
| mimic | plays | 60 | 28.1 | 18.0 | 14.0 | 60.8 | 12% | acumulado |
| bat_nest | peak | 3 | 2.1 | 2.0 | 1.0 | 3.0 | 20% | runs |
| pack_den | plays | 40 | 28.1 | 18.0 | 14.0 | 60.8 | 20% | acumulado |
| corrupt_piper | died | 2000 | 1537.8 | 1366.0 | 759.2 | 2402.6 | 28% | acumulado |
| flooded_pit | plays | 5 | 9.0 | 4.0 | 0.0 | 26.2 | 44% | runs |
| soul_collector | burst | 2000 | 2036.1 | 1823.2 | 1117.3 | 3190.2 | 44% |  |
| rat_tide | plays_same | 40 | 42.8 | 39.0 | 28.8 | 66.0 | 48% | runs |
| ash_phoenix | gold_end | 1000 | 1235.7 | 1220.5 | 714.3 | 1802.0 | 56% | runs |
| hollow_armor | elixir_max | 20 | 20.2 | 20.0 | 15.0 | 25.0 | 60% | runs |
| cave_troll | win_phase | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 64% |  |
| hunt_instinct | plays | 40 | 48.1 | 42.0 | 28.2 | 77.6 | 64% | acumulado |
| life_drain | curses | 5 | 6.3 | 10.0 | 0.0 | 10.0 | 68% | runs |
| mother_nest | peak_on_spell | 20 | 31.4 | 30.0 | 14.2 | 50.8 | 72% | runs |
| plague_carrion | peak | 40 | 66.5 | 51.0 | 32.0 | 83.8 | 72% | runs |
| spike_trap | plays_window | 5 | 5.3 | 5.0 | 4.0 | 6.0 | 72% |  |
| alpha_beast | peak | 30 | 60.3 | 49.0 | 21.6 | 80.2 | 76% |  |
| ember_rain | plays | 25 | 48.1 | 42.0 | 28.2 | 77.6 | 96% | runs |
| bat_cloud | peak | 12 | 61.4 | 49.0 | 22.6 | 80.2 | 100% | runs |
| magma_golem | peak | 10 | 66.5 | 51.0 | 32.0 | 83.8 | 100% | runs |
| rat_trap | peste | 5 | 14.8 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_careful|plague@3 (n=25, vitória 40%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.6 | 4.0 | 3.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 52.4 | 53.0 | 34.2 | 71.0 | 0% | acumulado |
| blood_tax | plays | 100 | 52.4 | 53.0 | 34.2 | 71.0 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 12.0 | 11.0 | 0.0 | 30.4 | 0% | acumulado |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.8 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| ogre | plays | 600 | 302.6 | 292.0 | 223.8 | 405.2 | 0% | acumulado |
| primal_beast | plays | 600 | 172.9 | 159.0 | 116.2 | 238.6 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 402.0 | 387.0 | 288.6 | 542.6 | 0% | acumulado |
| soul_feast | plays | 400 | 52.4 | 53.0 | 34.2 | 71.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 4.1 | 4.0 | 3.0 | 5.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| tar_net | gold_spent | 2000 | 962.8 | 920.0 | 591.0 | 1358.0 | 0% | acumulado |
| eternal_army | peak | 12 | 0.8 | 0.0 | 0.0 | 0.0 | 4% | runs |
| fallen_healer | loss_max | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| gold_avalanche | gold_earned | 6000 | 4333.4 | 4197.2 | 2840.1 | 5948.9 | 8% | acumulado |
| mimic | plays | 60 | 34.9 | 31.0 | 20.4 | 51.8 | 8% | acumulado |
| spitting_viper | plays | 150 | 104.6 | 95.0 | 67.4 | 141.8 | 8% | acumulado |
| molten_gold | elixir_spent | 2000 | 1412.0 | 1277.0 | 968.2 | 2077.6 | 16% | acumulado |
| pack_den | plays | 40 | 34.9 | 31.0 | 20.4 | 51.8 | 24% | acumulado |
| bat_nest | peak | 3 | 2.1 | 2.0 | 1.0 | 3.6 | 28% | runs |
| bone_colossus | died | 3000 | 2749.6 | 2421.0 | 1718.4 | 3880.8 | 28% | acumulado |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 40% |  |
| corrupt_piper | died | 2000 | 2263.0 | 1997.0 | 1255.2 | 3422.6 | 48% | acumulado |
| flooded_pit | plays | 5 | 12.0 | 11.0 | 0.0 | 30.4 | 60% | runs |
| hollow_armor | elixir_max | 20 | 22.3 | 22.0 | 17.0 | 27.6 | 64% | runs |
| life_drain | curses | 5 | 6.9 | 10.0 | 0.0 | 10.0 | 68% | runs |
| spike_trap | plays_window | 5 | 5.0 | 5.0 | 4.0 | 6.0 | 80% |  |
| hunt_instinct | plays | 40 | 52.4 | 53.0 | 34.2 | 71.0 | 84% | acumulado |
| mother_nest | peak_on_spell | 20 | 121.4 | 47.0 | 19.0 | 334.6 | 84% | runs |
| soul_collector | burst | 2000 | 3780.5 | 3250.9 | 1920.6 | 6345.1 | 88% |  |
| alpha_beast | peak | 30 | 149.4 | 75.0 | 45.6 | 357.8 | 92% |  |
| plague_carrion | peak | 40 | 170.5 | 78.0 | 49.4 | 400.0 | 92% | runs |
| rat_tide | plays_same | 40 | 57.3 | 55.0 | 40.8 | 72.0 | 96% | runs |
| ash_phoenix | gold_end | 1000 | 3370.5 | 3497.4 | 1731.9 | 4950.1 | 100% | runs |
| bat_cloud | peak | 12 | 153.3 | 75.0 | 46.4 | 362.6 | 100% | runs |
| ember_rain | plays | 25 | 52.4 | 53.0 | 34.2 | 71.0 | 100% | runs |
| magma_golem | peak | 10 | 170.5 | 78.0 | 49.4 | 400.0 | 100% | runs |
| rat_trap | peste | 5 | 14.8 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_novice|dragon (n=25, vitória 24%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_apocalypse | plays_window | 7 | 4.7 | 5.0 | 4.0 | 6.0 | 0% |  |
| arcane_spark | plays | 120 | 0.8 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 79.8 | 77.0 | 57.4 | 106.6 | 0% | acumulado |
| bone_colossus | died | 3000 | 400.2 | 399.0 | 244.4 | 517.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.6 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.6 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 27.9 | 25.0 | 9.4 | 51.4 | 0% | acumulado |
| furnace | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| mimic | plays | 60 | 29.4 | 28.0 | 14.6 | 45.2 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 877.3 | 833.0 | 661.8 | 1142.6 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 174.1 | 179.0 | 109.6 | 223.6 | 0% | acumulado |
| plague_carrion | peak | 40 | 12.6 | 12.0 | 9.4 | 16.0 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 313.0 | 321.0 | 223.8 | 405.4 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 79.8 | 77.0 | 57.4 | 106.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 975.4 | 990.0 | 517.8 | 1387.0 | 4% | acumulado |
| gold_avalanche | gold_earned | 6000 | 3429.0 | 3178.8 | 1676.3 | 5343.1 | 8% | acumulado |
| gold_bait | coins | 25 | 15.9 | 16.0 | 8.8 | 23.2 | 8% | acumulado |
| meteor_storm | plays | 80 | 57.5 | 60.0 | 36.4 | 76.4 | 8% | acumulado |
| soul_collector | burst | 2000 | 1257.3 | 1138.9 | 927.6 | 1717.3 | 8% |  |
| blood_tax | plays | 100 | 79.8 | 77.0 | 57.4 | 106.6 | 16% | acumulado |
| soul_storm | spells_distinct | 6 | 4.7 | 5.0 | 4.0 | 6.0 | 16% |  |
| ash_phoenix | gold_end | 1000 | 612.8 | 259.2 | 20.2 | 1469.3 | 20% | runs |
| burn_village | burn_time | 150 | 101.1 | 71.5 | 42.4 | 218.3 | 20% | acumulado |
| hollow_armor | elixir_max | 20 | 17.2 | 17.0 | 14.0 | 21.6 | 20% | runs |
| cave_troll | win_phase | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 24% |  |
| elder_dragon | peak | 5 | 4.0 | 4.0 | 3.0 | 5.0 | 24% |  |
| pack_den | plays | 40 | 29.4 | 28.0 | 14.6 | 45.2 | 24% | acumulado |
| bat_nest | peak | 3 | 2.8 | 3.0 | 2.0 | 4.6 | 52% | runs |
| dragon_exchange | soak_ignite | 1 | 0.5 | 1.0 | 0.0 | 1.0 | 52% |  |
| rat_tide | plays_same | 40 | 41.9 | 43.0 | 27.0 | 55.0 | 64% | runs |
| spike_trap | plays_window | 5 | 4.9 | 5.0 | 4.0 | 6.0 | 64% |  |
| boiling_oil | soaked_time | 75 | 184.7 | 165.9 | 72.7 | 331.8 | 88% | acumulado |
| magma_golem | peak | 10 | 12.6 | 12.0 | 9.4 | 16.0 | 88% | runs |
| flooded_pit | plays | 5 | 27.9 | 25.0 | 9.4 | 51.4 | 92% | runs |
| life_drain | curses | 5 | 8.9 | 10.0 | 6.4 | 10.0 | 96% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 96% | runs |
| ember_rain | plays | 25 | 79.8 | 77.0 | 57.4 | 106.6 | 100% | runs |
| hunt_instinct | plays | 40 | 79.8 | 77.0 | 57.4 | 106.6 | 100% | acumulado |

## human_novice|dragon@3 (n=25, vitória 20%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 493.1 | 496.0 | 352.4 | 660.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.0 | 5.0 | 3.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.0 | 5.0 | 3.4 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 34.7 | 34.0 | 9.0 | 63.2 | 0% | acumulado |
| furnace | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| molten_gold | elixir_spent | 2000 | 1118.5 | 1052.0 | 770.6 | 1509.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 214.7 | 212.0 | 154.8 | 277.0 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 384.7 | 367.0 | 284.8 | 496.8 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 100.1 | 97.0 | 74.0 | 135.2 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 100.1 | 97.0 | 74.0 | 135.2 | 4% | acumulado |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| plague_carrion | peak | 40 | 19.8 | 15.0 | 10.8 | 25.0 | 4% | runs |
| arcane_apocalypse | plays_window | 7 | 5.4 | 5.0 | 4.0 | 6.0 | 8% |  |
| gold_bait | coins | 25 | 17.3 | 17.0 | 10.2 | 24.6 | 12% | acumulado |
| tar_net | gold_spent | 2000 | 1379.1 | 1395.0 | 863.6 | 2045.0 | 12% | acumulado |
| meteor_storm | plays | 80 | 64.6 | 63.0 | 45.6 | 91.0 | 16% | acumulado |
| mimic | plays | 60 | 34.9 | 28.0 | 16.4 | 62.8 | 16% | acumulado |
| cave_troll | win_phase | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 20% |  |
| pack_den | plays | 40 | 34.9 | 28.0 | 16.4 | 62.8 | 28% | acumulado |
| burn_village | burn_time | 150 | 169.0 | 80.0 | 20.9 | 391.0 | 32% | acumulado |
| ash_phoenix | gold_end | 1000 | 2104.6 | 680.0 | 5.0 | 6213.6 | 44% | runs |
| blood_tax | plays | 100 | 100.1 | 97.0 | 74.0 | 135.2 | 44% | acumulado |
| soul_collector | burst | 2000 | 2432.0 | 1889.9 | 1272.2 | 4675.4 | 44% |  |
| gold_avalanche | gold_earned | 6000 | 6940.3 | 5666.7 | 3052.9 | 11952.5 | 48% | acumulado |
| hollow_armor | elixir_max | 20 | 20.5 | 19.0 | 16.0 | 26.2 | 48% | runs |
| dragon_exchange | soak_ignite | 1 | 0.5 | 1.0 | 0.0 | 1.0 | 52% |  |
| soul_storm | spells_distinct | 6 | 5.5 | 6.0 | 4.0 | 7.0 | 60% |  |
| elder_dragon | peak | 5 | 7.0 | 5.0 | 4.0 | 8.0 | 72% |  |
| bat_nest | peak | 3 | 3.8 | 3.0 | 2.0 | 6.0 | 80% | runs |
| rat_tide | plays_same | 40 | 51.4 | 50.0 | 37.8 | 65.2 | 84% | runs |
| boiling_oil | soaked_time | 75 | 198.7 | 198.7 | 65.0 | 427.7 | 88% | acumulado |
| flooded_pit | plays | 5 | 34.7 | 34.0 | 9.0 | 63.2 | 92% | runs |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 5.0 | 6.0 | 92% |  |
| life_drain | curses | 5 | 9.6 | 10.0 | 8.8 | 10.0 | 96% | runs |
| ember_rain | plays | 25 | 100.1 | 97.0 | 74.0 | 135.2 | 100% | runs |
| hunt_instinct | plays | 40 | 100.1 | 97.0 | 74.0 | 135.2 | 100% | acumulado |
| magma_golem | peak | 10 | 19.8 | 15.0 | 10.8 | 25.0 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_novice|lich (n=25, vitória 60%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 886.4 | 853.0 | 676.4 | 1098.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.3 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.3 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 41.3 | 45.0 | 11.0 | 66.2 | 0% | acumulado |
| furnace | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 17.0 | 17.0 | 11.0 | 25.6 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1901.3 | 1901.1 | 1330.5 | 2336.3 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 948.2 | 966.0 | 745.6 | 1147.4 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 206.8 | 197.0 | 162.0 | 260.6 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 488.1 | 489.0 | 395.6 | 565.6 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 222.3 | 220.0 | 174.0 | 287.6 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 931.0 | 850.0 | 618.0 | 1292.0 | 0% | acumulado |
| mimic | plays | 60 | 17.8 | 16.0 | 0.0 | 43.6 | 4% | acumulado |
| pack_den | plays | 40 | 17.8 | 16.0 | 0.0 | 43.6 | 12% | acumulado |
| plague_carrion | peak | 40 | 32.0 | 28.0 | 15.8 | 48.6 | 16% | runs |
| eruption | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 20% |  |
| soul_harvest | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 20% | runs |
| burn_village | burn_time | 150 | 138.5 | 121.2 | 75.8 | 195.2 | 24% | acumulado |
| arcane_spark | plays | 120 | 112.8 | 108.0 | 83.4 | 158.2 | 28% | acumulado |
| bat_nest | peak | 3 | 1.6 | 1.0 | 0.0 | 3.0 | 28% | runs |
| hollow_armor | elixir_max | 20 | 21.3 | 19.0 | 12.8 | 33.6 | 44% | runs |
| ash_phoenix | gold_end | 1000 | 970.3 | 976.7 | 494.6 | 1400.6 | 48% | runs |
| cave_troll | win_phase | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 60% |  |
| shadow_echo | plays_window | 5 | 4.9 | 5.0 | 4.0 | 6.0 | 60% |  |
| life_drain | curses | 5 | 6.7 | 10.0 | 0.0 | 10.0 | 68% | runs |
| eternal_army | peak | 12 | 17.6 | 17.0 | 11.0 | 26.6 | 80% | runs |
| soul_collector | burst | 2000 | 4508.6 | 4223.8 | 1508.2 | 8902.5 | 80% |  |
| flooded_pit | plays | 5 | 41.3 | 45.0 | 11.0 | 66.2 | 92% | runs |
| rat_tide | plays_same | 40 | 54.5 | 52.0 | 42.4 | 68.2 | 92% | runs |
| soul_storm | spells_distinct | 6 | 7.0 | 7.0 | 6.0 | 8.6 | 92% |  |
| black_pestilence | plays | 150 | 222.3 | 220.0 | 174.0 | 287.6 | 96% | acumulado |
| arcane_apocalypse | plays_window | 7 | 10.1 | 10.0 | 8.4 | 12.0 | 100% |  |
| blood_tax | plays | 100 | 222.3 | 220.0 | 174.0 | 287.6 | 100% | acumulado |
| ember_rain | plays | 25 | 222.3 | 220.0 | 174.0 | 287.6 | 100% | runs |
| hunt_instinct | plays | 40 | 222.3 | 220.0 | 174.0 | 287.6 | 100% | acumulado |
| magma_golem | peak | 10 | 32.0 | 28.0 | 15.8 | 48.6 | 100% | runs |
| spike_trap | plays_window | 5 | 7.4 | 8.0 | 6.0 | 8.6 | 100% |  |

## human_novice|lich@3 (n=25, vitória 32%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1048.0 | 981.0 | 689.8 | 1471.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.5 | 5.0 | 3.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.5 | 5.0 | 3.4 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 61.1 | 55.0 | 14.4 | 114.6 | 0% | acumulado |
| furnace | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1209.4 | 1159.0 | 938.2 | 1524.2 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 243.9 | 238.0 | 168.2 | 327.6 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 577.1 | 540.0 | 469.2 | 768.6 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 245.4 | 233.0 | 184.4 | 324.4 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 1129.7 | 1010.0 | 897.0 | 1508.0 | 0% | acumulado |
| gold_avalanche | gold_earned | 6000 | 3628.8 | 3368.7 | 2012.7 | 5396.6 | 4% | acumulado |
| eruption | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% |  |
| ghost | peak | 40 | 19.9 | 16.0 | 11.4 | 34.2 | 12% | runs |
| soul_harvest | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% | runs |
| mimic | plays | 60 | 26.7 | 20.0 | 0.0 | 62.4 | 16% | acumulado |
| burn_village | burn_time | 150 | 167.1 | 126.2 | 84.5 | 190.6 | 24% | acumulado |
| pack_den | plays | 40 | 26.7 | 20.0 | 0.0 | 62.4 | 28% | acumulado |
| cave_troll | win_phase | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 32% |  |
| plague_carrion | peak | 40 | 38.7 | 36.0 | 20.6 | 55.2 | 44% | runs |
| arcane_spark | plays | 120 | 123.8 | 121.0 | 81.0 | 162.8 | 56% | acumulado |
| bat_nest | peak | 3 | 2.7 | 3.0 | 0.4 | 4.6 | 56% | runs |
| hollow_armor | elixir_max | 20 | 21.2 | 22.0 | 14.4 | 27.2 | 60% | runs |
| shadow_echo | plays_window | 5 | 5.0 | 5.0 | 3.4 | 7.0 | 64% |  |
| life_drain | curses | 5 | 6.9 | 10.0 | 0.8 | 10.0 | 68% | runs |
| eternal_army | peak | 12 | 20.4 | 17.0 | 11.4 | 34.8 | 88% | runs |
| rat_tide | plays_same | 40 | 67.2 | 57.0 | 43.2 | 111.0 | 92% | runs |
| soul_collector | burst | 2000 | 6459.8 | 5502.3 | 3180.1 | 10174.1 | 92% |  |
| ash_phoenix | gold_end | 1000 | 2499.1 | 2309.9 | 1108.0 | 4179.6 | 96% | runs |
| soul_storm | spells_distinct | 6 | 7.5 | 7.0 | 6.0 | 9.0 | 96% |  |
| arcane_apocalypse | plays_window | 7 | 10.7 | 11.0 | 8.0 | 13.6 | 100% |  |
| black_pestilence | plays | 150 | 245.4 | 233.0 | 184.4 | 324.4 | 100% | acumulado |
| blood_tax | plays | 100 | 245.4 | 233.0 | 184.4 | 324.4 | 100% | acumulado |
| ember_rain | plays | 25 | 245.4 | 233.0 | 184.4 | 324.4 | 100% | runs |
| flooded_pit | plays | 5 | 61.1 | 55.0 | 14.4 | 114.6 | 100% | runs |
| hunt_instinct | plays | 40 | 245.4 | 233.0 | 184.4 | 324.4 | 100% | acumulado |
| magma_golem | peak | 10 | 38.7 | 36.0 | 20.6 | 55.2 | 100% | runs |
| spike_trap | plays_window | 5 | 7.2 | 7.0 | 6.0 | 8.0 | 100% |  |

## human_novice|plague (n=25, vitória 36%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 4.0 | 4.0 | 3.0 | 5.0 | 0% |  |
| arcane_spark | plays | 120 | 1.4 | 0.0 | 0.0 | 1.8 | 0% | acumulado |
| black_pestilence | plays | 150 | 69.8 | 67.0 | 44.2 | 84.0 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.1 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.1 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 5.9 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.8 | 0.0 | 0.0 | 2.4 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 8.8 | 7.0 | 0.0 | 21.2 | 0% | acumulado |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.8 | 0.0 | 0.0 | 2.4 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1900.5 | 1904.9 | 1342.6 | 2474.2 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1050.0 | 1034.0 | 804.2 | 1304.8 | 0% | acumulado |
| ogre | plays | 600 | 236.5 | 224.0 | 181.0 | 309.8 | 0% | acumulado |
| primal_beast | plays | 600 | 145.9 | 140.0 | 112.4 | 189.0 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.6 | 0% |  |
| shadow_mark | plays | 1000 | 348.2 | 327.0 | 272.6 | 444.6 | 0% | acumulado |
| soul_feast | plays | 400 | 69.8 | 67.0 | 44.2 | 84.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 88.3 | 88.0 | 62.4 | 118.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 954.0 | 920.0 | 688.0 | 1298.0 | 0% | acumulado |
| blood_tax | plays | 100 | 69.8 | 67.0 | 44.2 | 84.0 | 8% | acumulado |
| bone_colossus | died | 3000 | 1998.8 | 1871.0 | 1477.8 | 2906.4 | 8% | acumulado |
| mimic | plays | 60 | 33.1 | 31.0 | 15.8 | 47.0 | 8% | acumulado |
| corrupt_piper | died | 2000 | 1594.0 | 1415.0 | 1096.8 | 2348.6 | 20% | acumulado |
| bat_nest | peak | 3 | 2.3 | 2.0 | 1.0 | 3.0 | 28% | runs |
| soul_storm | spells_distinct | 6 | 4.9 | 5.0 | 4.0 | 6.0 | 28% |  |
| ash_phoenix | gold_end | 1000 | 946.5 | 861.1 | 498.9 | 1425.2 | 36% | runs |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 36% |  |
| pack_den | plays | 40 | 33.1 | 31.0 | 15.8 | 47.0 | 36% | acumulado |
| soul_collector | burst | 2000 | 2402.4 | 1846.5 | 1105.8 | 3827.3 | 44% |  |
| hollow_armor | elixir_max | 20 | 19.2 | 20.0 | 14.4 | 24.6 | 52% | runs |
| flooded_pit | plays | 5 | 8.8 | 7.0 | 0.0 | 21.2 | 60% | runs |
| spike_trap | plays_window | 5 | 5.1 | 5.0 | 4.0 | 6.0 | 76% |  |
| mother_nest | peak_on_spell | 20 | 60.3 | 35.0 | 12.8 | 91.2 | 80% | runs |
| rat_tide | plays_same | 40 | 51.0 | 49.0 | 35.4 | 73.0 | 80% | runs |
| life_drain | curses | 5 | 8.3 | 10.0 | 0.8 | 10.0 | 84% | runs |
| hunt_instinct | plays | 40 | 69.8 | 67.0 | 44.2 | 84.0 | 96% | acumulado |
| plague_carrion | peak | 40 | 85.6 | 53.0 | 45.0 | 119.8 | 96% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 96% |  |
| alpha_beast | peak | 30 | 77.3 | 52.0 | 45.0 | 101.4 | 100% |  |
| bat_cloud | peak | 12 | 79.2 | 52.0 | 45.0 | 109.8 | 100% | runs |
| ember_rain | plays | 25 | 69.8 | 67.0 | 44.2 | 84.0 | 100% | runs |
| magma_golem | peak | 10 | 85.6 | 53.0 | 45.0 | 119.8 | 100% | runs |
| rat_trap | peste | 5 | 15.0 | 15.0 | 15.0 | 15.0 | 100% | runs |

## human_novice|plague@3 (n=25, vitória 32%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 0.8 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.2 | 5.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.2 | 5.0 | 4.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.6 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 10.6 | 5.0 | 0.0 | 25.4 | 0% | acumulado |
| furnace | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 2.2 | 0.0 | 0.0 | 6.0 | 0% | runs |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| ogre | plays | 600 | 307.4 | 280.0 | 209.4 | 421.4 | 0% | acumulado |
| primal_beast | plays | 600 | 184.9 | 180.0 | 112.0 | 241.2 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 444.9 | 412.0 | 292.4 | 584.4 | 0% | acumulado |
| soul_feast | plays | 400 | 82.9 | 82.0 | 48.2 | 128.8 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| tar_net | gold_spent | 2000 | 1147.2 | 1120.0 | 916.0 | 1413.0 | 0% | acumulado |
| eternal_army | peak | 12 | 2.2 | 0.0 | 0.0 | 6.0 | 4% | runs |
| arcane_apocalypse | plays_window | 7 | 4.4 | 4.0 | 3.0 | 6.0 | 8% |  |
| black_pestilence | plays | 150 | 82.9 | 82.0 | 48.2 | 128.8 | 8% | acumulado |
| gold_avalanche | gold_earned | 6000 | 3757.3 | 3519.7 | 2216.0 | 5598.5 | 8% | acumulado |
| molten_gold | elixir_spent | 2000 | 1392.2 | 1320.0 | 874.6 | 1900.8 | 8% | acumulado |
| spitting_viper | plays | 150 | 101.4 | 98.0 | 67.2 | 140.2 | 8% | acumulado |
| blood_tax | plays | 100 | 82.9 | 82.0 | 48.2 | 128.8 | 16% | acumulado |
| mimic | plays | 60 | 44.0 | 33.0 | 22.0 | 72.0 | 20% | acumulado |
| soul_storm | spells_distinct | 6 | 4.8 | 5.0 | 4.0 | 6.0 | 24% |  |
| bone_colossus | died | 3000 | 2609.6 | 2434.0 | 1591.2 | 3909.8 | 28% | acumulado |
| cave_troll | win_phase | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 32% |  |
| bat_nest | peak | 3 | 2.6 | 2.0 | 1.0 | 4.0 | 36% | runs |
| hollow_armor | elixir_max | 20 | 19.7 | 19.0 | 15.0 | 26.0 | 36% | runs |
| corrupt_piper | died | 2000 | 2066.2 | 1895.0 | 1144.4 | 3211.4 | 40% | acumulado |
| pack_den | plays | 40 | 44.0 | 33.0 | 22.0 | 72.0 | 40% | acumulado |
| spike_trap | plays_window | 5 | 4.9 | 4.0 | 4.0 | 6.6 | 48% |  |
| flooded_pit | plays | 5 | 10.6 | 5.0 | 0.0 | 25.4 | 52% | runs |
| soul_collector | burst | 2000 | 3099.7 | 2477.4 | 1670.4 | 5196.4 | 72% |  |
| mother_nest | peak_on_spell | 20 | 68.9 | 41.0 | 15.0 | 133.8 | 76% | runs |
| ash_phoenix | gold_end | 1000 | 2610.1 | 2629.7 | 1060.9 | 4504.5 | 88% | runs |
| life_drain | curses | 5 | 8.8 | 10.0 | 4.2 | 10.0 | 88% | runs |
| alpha_beast | peak | 30 | 91.8 | 52.0 | 38.4 | 255.4 | 92% |  |
| plague_carrion | peak | 40 | 105.0 | 61.0 | 41.6 | 312.2 | 92% | runs |
| rat_tide | plays_same | 40 | 61.6 | 57.0 | 41.0 | 94.6 | 92% | runs |
| hunt_instinct | plays | 40 | 82.9 | 82.0 | 48.2 | 128.8 | 96% | acumulado |
| bat_cloud | peak | 12 | 95.3 | 54.0 | 38.4 | 263.0 | 100% | runs |
| ember_rain | plays | 25 | 82.9 | 82.0 | 48.2 | 128.8 | 100% | runs |
| magma_golem | peak | 10 | 105.0 | 61.0 | 41.6 | 312.2 | 100% | runs |
| rat_trap | peste | 5 | 14.7 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_rusher|dragon (n=25, vitória 28%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 86.8 | 85.0 | 56.4 | 119.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 490.3 | 482.0 | 323.2 | 688.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.7 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.7 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 41.2 | 38.0 | 13.2 | 72.6 | 0% | acumulado |
| furnace | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| mimic | plays | 60 | 26.5 | 25.0 | 12.2 | 39.8 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 970.4 | 1028.0 | 751.4 | 1179.2 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 205.1 | 211.0 | 137.2 | 273.2 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 360.6 | 359.0 | 266.6 | 461.2 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 86.8 | 85.0 | 56.4 | 119.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 1130.8 | 1005.0 | 660.0 | 1647.0 | 0% | acumulado |
| plague_carrion | peak | 40 | 16.6 | 11.0 | 10.0 | 19.0 | 4% | runs |
| arcane_apocalypse | plays_window | 7 | 5.0 | 5.0 | 4.0 | 6.0 | 8% |  |
| soul_collector | burst | 2000 | 1288.3 | 1119.0 | 792.8 | 1889.1 | 8% |  |
| soul_storm | spells_distinct | 6 | 4.3 | 4.0 | 3.4 | 5.0 | 8% |  |
| burn_village | burn_time | 150 | 97.9 | 87.8 | 30.0 | 156.7 | 12% | acumulado |
| pack_den | plays | 40 | 26.5 | 25.0 | 12.2 | 39.8 | 12% | acumulado |
| gold_avalanche | gold_earned | 6000 | 4400.8 | 3917.4 | 2183.4 | 7336.0 | 20% | acumulado |
| gold_bait | coins | 25 | 18.2 | 19.0 | 9.4 | 26.6 | 20% | acumulado |
| ash_phoenix | gold_end | 1000 | 901.0 | 226.7 | 16.3 | 2745.3 | 24% | runs |
| meteor_storm | plays | 80 | 63.3 | 65.0 | 40.4 | 93.6 | 24% | acumulado |
| cave_troll | win_phase | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 28% |  |
| elder_dragon | peak | 5 | 5.2 | 4.0 | 3.0 | 7.0 | 32% |  |
| blood_tax | plays | 100 | 86.8 | 85.0 | 56.4 | 119.0 | 36% | acumulado |
| hollow_armor | elixir_max | 20 | 19.0 | 18.0 | 15.0 | 23.0 | 40% | runs |
| bat_nest | peak | 3 | 2.9 | 2.0 | 1.4 | 5.6 | 44% | runs |
| dragon_exchange | soak_ignite | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 64% |  |
| rat_tide | plays_same | 40 | 48.0 | 48.0 | 33.0 | 63.2 | 80% | runs |
| boiling_oil | soaked_time | 75 | 172.4 | 159.7 | 57.1 | 273.7 | 84% | acumulado |
| life_drain | curses | 5 | 8.5 | 10.0 | 4.0 | 10.0 | 84% | runs |
| flooded_pit | plays | 5 | 41.2 | 38.0 | 13.2 | 72.6 | 92% | runs |
| spike_trap | plays_window | 5 | 5.7 | 5.0 | 5.0 | 6.0 | 92% |  |
| hunt_instinct | plays | 40 | 86.8 | 85.0 | 56.4 | 119.0 | 96% | acumulado |
| ember_rain | plays | 25 | 86.8 | 85.0 | 56.4 | 119.0 | 100% | runs |
| magma_golem | peak | 10 | 16.6 | 11.0 | 10.0 | 19.0 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_rusher|dragon@3 (n=25, vitória 4%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.8 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 613.3 | 582.0 | 438.0 | 772.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 4.8 | 5.0 | 4.0 | 6.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| brown_bear | heroes | 20 | 4.8 | 5.0 | 4.0 | 6.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 53.8 | 54.0 | 19.2 | 96.4 | 0% | acumulado |
| furnace | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| molten_gold | elixir_spent | 2000 | 1334.1 | 1337.0 | 960.4 | 1675.6 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 259.6 | 246.0 | 187.4 | 341.6 | 0% | acumulado |
| plague_carrion | peak | 40 | 17.3 | 16.0 | 11.0 | 24.6 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 461.4 | 470.0 | 341.0 | 597.8 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 114.9 | 115.0 | 83.4 | 149.4 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| cave_troll | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| mimic | plays | 60 | 33.0 | 36.0 | 16.4 | 48.6 | 4% | acumulado |
| fallen_healer | loss_max | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| tar_net | gold_spent | 2000 | 1397.8 | 1215.0 | 969.0 | 1902.0 | 8% | acumulado |
| black_pestilence | plays | 150 | 114.9 | 115.0 | 83.4 | 149.4 | 12% | acumulado |
| burn_village | burn_time | 150 | 85.0 | 70.7 | 35.0 | 149.8 | 12% | acumulado |
| soul_storm | spells_distinct | 6 | 4.8 | 5.0 | 4.0 | 5.6 | 12% |  |
| arcane_apocalypse | plays_window | 7 | 5.3 | 5.0 | 4.0 | 7.0 | 16% |  |
| soul_collector | burst | 2000 | 1631.5 | 1481.9 | 1126.1 | 2159.1 | 16% |  |
| hollow_armor | elixir_max | 20 | 19.2 | 19.0 | 16.0 | 24.4 | 28% | runs |
| pack_den | plays | 40 | 33.0 | 36.0 | 16.4 | 48.6 | 28% | acumulado |
| gold_bait | coins | 25 | 22.4 | 22.0 | 15.4 | 31.6 | 40% | acumulado |
| elder_dragon | peak | 5 | 5.1 | 4.0 | 3.0 | 7.6 | 44% |  |
| meteor_storm | plays | 80 | 78.5 | 83.0 | 53.2 | 108.8 | 52% | acumulado |
| ash_phoenix | gold_end | 1000 | 2763.2 | 1920.5 | 51.9 | 7605.9 | 56% | runs |
| dragon_exchange | soak_ignite | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 56% |  |
| blood_tax | plays | 100 | 114.9 | 115.0 | 83.4 | 149.4 | 72% | acumulado |
| gold_avalanche | gold_earned | 6000 | 9026.6 | 7586.2 | 4495.7 | 16387.4 | 72% | acumulado |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 6.6 | 72% |  |
| bat_nest | peak | 3 | 3.6 | 3.0 | 2.0 | 6.0 | 76% | runs |
| boiling_oil | soaked_time | 75 | 190.8 | 166.2 | 73.1 | 339.7 | 88% | acumulado |
| flooded_pit | plays | 5 | 53.8 | 54.0 | 19.2 | 96.4 | 92% | runs |
| rat_tide | plays_same | 40 | 62.0 | 61.0 | 46.8 | 78.4 | 92% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 96% | runs |
| ember_rain | plays | 25 | 114.9 | 115.0 | 83.4 | 149.4 | 100% | runs |
| hunt_instinct | plays | 40 | 114.9 | 115.0 | 83.4 | 149.4 | 100% | acumulado |
| life_drain | curses | 5 | 9.9 | 10.0 | 10.0 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 17.3 | 16.0 | 11.0 | 24.6 | 100% | runs |

## human_rusher|lich (n=25, vitória 68%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 873.2 | 828.0 | 664.0 | 1104.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.5 | 7.0 | 5.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.5 | 7.0 | 5.4 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 63.9 | 62.0 | 17.6 | 112.2 | 0% | acumulado |
| furnace | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 1812.2 | 1859.1 | 1377.6 | 2108.5 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 13.8 | 10.0 | 0.0 | 33.8 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 981.3 | 946.0 | 754.0 | 1209.6 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 198.6 | 191.0 | 158.8 | 250.8 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 542.0 | 529.0 | 418.6 | 648.2 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 713.0 | 650.0 | 383.0 | 1107.0 | 0% | acumulado |
| ghost | peak | 40 | 17.1 | 13.0 | 10.0 | 26.4 | 4% | runs |
| soul_feast | plays | 400 | 265.6 | 265.0 | 190.0 | 360.4 | 4% | acumulado |
| pack_den | plays | 40 | 13.8 | 10.0 | 0.0 | 33.8 | 8% | acumulado |
| plague_carrion | peak | 40 | 29.1 | 23.0 | 13.4 | 47.6 | 20% | runs |
| bat_nest | peak | 3 | 1.5 | 1.0 | 0.0 | 3.0 | 24% | runs |
| eruption | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 24% |  |
| soul_harvest | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 24% | runs |
| hollow_armor | elixir_max | 20 | 22.7 | 19.0 | 16.0 | 32.6 | 48% | runs |
| arcane_spark | plays | 120 | 125.8 | 129.0 | 85.0 | 175.8 | 56% | acumulado |
| ash_phoenix | gold_end | 1000 | 1099.2 | 1080.0 | 633.0 | 1547.2 | 56% | runs |
| life_drain | curses | 5 | 5.6 | 7.0 | 0.0 | 10.0 | 60% | runs |
| burn_village | burn_time | 150 | 170.1 | 166.7 | 113.5 | 236.7 | 64% | acumulado |
| cave_troll | win_phase | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 68% |  |
| eternal_army | peak | 12 | 17.4 | 13.0 | 10.0 | 26.4 | 76% | runs |
| shadow_echo | plays_window | 5 | 6.4 | 6.0 | 4.0 | 9.0 | 84% |  |
| soul_collector | burst | 2000 | 3766.5 | 3672.0 | 1887.4 | 5746.4 | 84% |  |
| soul_storm | spells_distinct | 6 | 6.3 | 6.0 | 6.0 | 7.0 | 92% |  |
| black_pestilence | plays | 150 | 265.6 | 265.0 | 190.0 | 360.4 | 96% | acumulado |
| flooded_pit | plays | 5 | 63.9 | 62.0 | 17.6 | 112.2 | 96% | runs |
| rat_tide | plays_same | 40 | 63.6 | 58.0 | 45.8 | 85.2 | 96% | runs |
| arcane_apocalypse | plays_window | 7 | 14.5 | 13.0 | 9.0 | 22.6 | 100% |  |
| blood_tax | plays | 100 | 265.6 | 265.0 | 190.0 | 360.4 | 100% | acumulado |
| ember_rain | plays | 25 | 265.6 | 265.0 | 190.0 | 360.4 | 100% | runs |
| hunt_instinct | plays | 40 | 265.6 | 265.0 | 190.0 | 360.4 | 100% | acumulado |
| magma_golem | peak | 10 | 29.1 | 23.0 | 13.4 | 47.6 | 100% | runs |
| spike_trap | plays_window | 5 | 9.9 | 9.0 | 7.0 | 14.0 | 100% |  |

## human_rusher|lich@3 (n=25, vitória 36%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1244.0 | 1230.0 | 907.2 | 1672.4 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.7 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.7 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 73.6 | 51.0 | 29.4 | 139.0 | 0% | acumulado |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 3807.7 | 3665.9 | 2691.3 | 5051.8 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 281.7 | 267.0 | 202.0 | 396.6 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 894.8 | 905.0 | 598.0 | 1151.0 | 0% | acumulado |
| mimic | plays | 60 | 19.6 | 14.0 | 0.0 | 50.6 | 4% | acumulado |
| molten_gold | elixir_spent | 2000 | 1373.9 | 1315.0 | 1061.2 | 1783.4 | 4% | acumulado |
| eruption | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| shadow_mark | plays | 1000 | 697.1 | 685.0 | 509.8 | 954.2 | 8% | acumulado |
| soul_harvest | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% | runs |
| ghost | peak | 40 | 41.6 | 21.0 | 12.4 | 83.2 | 20% | runs |
| pack_den | plays | 40 | 19.6 | 14.0 | 0.0 | 50.6 | 20% | acumulado |
| soul_feast | plays | 400 | 322.2 | 289.0 | 217.8 | 464.2 | 24% | acumulado |
| bat_nest | peak | 3 | 2.4 | 2.0 | 0.0 | 5.2 | 28% | runs |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 36% |  |
| life_drain | curses | 5 | 6.3 | 10.0 | 0.0 | 10.0 | 60% | runs |
| plague_carrion | peak | 40 | 75.6 | 43.0 | 19.0 | 185.2 | 60% | runs |
| hollow_armor | elixir_max | 20 | 26.1 | 25.0 | 18.0 | 37.0 | 68% | runs |
| arcane_spark | plays | 120 | 158.6 | 141.0 | 104.0 | 234.6 | 72% | acumulado |
| burn_village | burn_time | 150 | 323.9 | 221.4 | 114.6 | 705.8 | 76% | acumulado |
| shadow_echo | plays_window | 5 | 6.4 | 6.0 | 4.0 | 9.0 | 80% |  |
| soul_storm | spells_distinct | 6 | 6.4 | 6.0 | 5.0 | 7.6 | 84% |  |
| eternal_army | peak | 12 | 41.8 | 21.0 | 12.4 | 83.6 | 96% | runs |
| arcane_apocalypse | plays_window | 7 | 13.4 | 12.0 | 10.0 | 18.0 | 100% |  |
| ash_phoenix | gold_end | 1000 | 2912.8 | 2714.3 | 1906.3 | 4201.7 | 100% | runs |
| black_pestilence | plays | 150 | 322.2 | 289.0 | 217.8 | 464.2 | 100% | acumulado |
| blood_tax | plays | 100 | 322.2 | 289.0 | 217.8 | 464.2 | 100% | acumulado |
| ember_rain | plays | 25 | 322.2 | 289.0 | 217.8 | 464.2 | 100% | runs |
| flooded_pit | plays | 5 | 73.6 | 51.0 | 29.4 | 139.0 | 100% | runs |
| hunt_instinct | plays | 40 | 322.2 | 289.0 | 217.8 | 464.2 | 100% | acumulado |
| magma_golem | peak | 10 | 75.6 | 43.0 | 19.0 | 185.2 | 100% | runs |
| rat_tide | plays_same | 40 | 80.4 | 73.0 | 56.0 | 110.0 | 100% | runs |
| soul_collector | burst | 2000 | 6371.1 | 5052.8 | 3960.5 | 10411.6 | 100% |  |
| spike_trap | plays_window | 5 | 9.8 | 9.0 | 7.0 | 14.2 | 100% |  |

## human_rusher|plague (n=25, vitória 56%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 2.4 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 58.6 | 51.0 | 37.4 | 82.8 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.4 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.4 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 13.6 | 14.0 | 0.0 | 27.8 | 0% | acumulado |
| furnace | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.6 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 2102.3 | 2033.4 | 1486.9 | 2485.2 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1223.2 | 1170.0 | 790.8 | 1597.6 | 0% | acumulado |
| ogre | plays | 600 | 273.2 | 263.0 | 195.8 | 358.2 | 0% | acumulado |
| primal_beast | plays | 600 | 158.7 | 151.0 | 106.2 | 234.2 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 380.7 | 366.0 | 281.0 | 476.2 | 0% | acumulado |
| soul_feast | plays | 400 | 58.6 | 51.0 | 37.4 | 82.8 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 96.4 | 103.0 | 69.4 | 124.6 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 825.6 | 775.0 | 577.0 | 1165.0 | 0% | acumulado |
| eternal_army | peak | 12 | 0.6 | 0.0 | 0.0 | 0.0 | 4% | runs |
| soul_storm | spells_distinct | 6 | 4.0 | 4.0 | 3.0 | 5.0 | 4% |  |
| arcane_apocalypse | plays_window | 7 | 3.8 | 4.0 | 3.0 | 5.0 | 8% |  |
| blood_tax | plays | 100 | 58.6 | 51.0 | 37.4 | 82.8 | 8% | acumulado |
| mimic | plays | 60 | 35.3 | 30.0 | 14.0 | 63.8 | 12% | acumulado |
| bone_colossus | died | 3000 | 2250.8 | 2226.0 | 1495.0 | 3242.2 | 16% | acumulado |
| bat_nest | peak | 3 | 1.9 | 2.0 | 1.0 | 3.0 | 24% | runs |
| soul_collector | burst | 2000 | 1791.6 | 1518.7 | 1019.4 | 3133.8 | 24% |  |
| corrupt_piper | died | 2000 | 1730.5 | 1675.0 | 1044.2 | 2630.4 | 28% | acumulado |
| pack_den | plays | 40 | 35.3 | 30.0 | 14.0 | 63.8 | 36% | acumulado |
| spike_trap | plays_window | 5 | 4.8 | 5.0 | 4.0 | 6.0 | 52% |  |
| cave_troll | win_phase | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 56% |  |
| hollow_armor | elixir_max | 20 | 22.0 | 22.0 | 16.0 | 28.2 | 68% | runs |
| mother_nest | peak_on_spell | 20 | 43.4 | 30.0 | 12.0 | 48.0 | 68% | runs |
| ash_phoenix | gold_end | 1000 | 1276.7 | 1342.8 | 563.6 | 1914.9 | 72% | runs |
| life_drain | curses | 5 | 7.7 | 10.0 | 0.8 | 10.0 | 76% | runs |
| flooded_pit | plays | 5 | 13.6 | 14.0 | 0.0 | 27.8 | 80% | runs |
| hunt_instinct | plays | 40 | 58.6 | 51.0 | 37.4 | 82.8 | 84% | acumulado |
| rat_tide | plays_same | 40 | 56.0 | 56.0 | 38.0 | 69.0 | 84% | runs |
| alpha_beast | peak | 30 | 66.3 | 50.0 | 28.0 | 87.8 | 88% |  |
| plague_carrion | peak | 40 | 71.8 | 54.0 | 37.8 | 91.0 | 88% | runs |
| ember_rain | plays | 25 | 58.6 | 51.0 | 37.4 | 82.8 | 96% | runs |
| bat_cloud | peak | 12 | 67.4 | 52.0 | 29.2 | 87.8 | 100% | runs |
| magma_golem | peak | 10 | 71.8 | 54.0 | 37.8 | 91.0 | 100% | runs |
| rat_trap | peste | 5 | 14.1 | 15.0 | 11.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_rusher|plague@3 (n=25, vitória 28%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.9 | 4.0 | 3.0 | 5.0 | 0% |  |
| arcane_spark | plays | 120 | 3.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.4 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 23.1 | 11.0 | 0.0 | 70.6 | 0% | acumulado |
| furnace | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.4 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| ogre | plays | 600 | 369.3 | 346.0 | 266.8 | 532.8 | 0% | acumulado |
| primal_beast | plays | 600 | 212.6 | 198.0 | 149.2 | 312.4 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 514.2 | 452.0 | 370.0 | 747.6 | 0% | acumulado |
| soul_feast | plays | 400 | 77.7 | 75.0 | 42.4 | 113.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| tar_net | gold_spent | 2000 | 990.4 | 980.0 | 686.0 | 1292.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 77.7 | 75.0 | 42.4 | 113.0 | 4% | acumulado |
| burn_village | burn_time | 150 | 9.6 | 0.0 | 0.0 | 0.0 | 4% | acumulado |
| soul_storm | spells_distinct | 6 | 4.2 | 4.0 | 4.0 | 5.0 | 4% |  |
| gold_avalanche | gold_earned | 6000 | 4530.9 | 4141.9 | 3454.2 | 6171.8 | 12% | acumulado |
| blood_tax | plays | 100 | 77.7 | 75.0 | 42.4 | 113.0 | 16% | acumulado |
| mimic | plays | 60 | 44.2 | 41.0 | 24.8 | 70.8 | 16% | acumulado |
| molten_gold | elixir_spent | 2000 | 1707.3 | 1612.0 | 1195.4 | 2352.6 | 24% | acumulado |
| cave_troll | win_phase | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 28% |  |
| spitting_viper | plays | 150 | 133.1 | 118.0 | 95.8 | 185.8 | 28% | acumulado |
| bat_nest | peak | 3 | 2.3 | 2.0 | 1.0 | 3.0 | 32% | runs |
| bone_colossus | died | 3000 | 3478.0 | 3399.0 | 2181.2 | 4861.6 | 52% | acumulado |
| pack_den | plays | 40 | 44.2 | 41.0 | 24.8 | 70.8 | 52% | acumulado |
| flooded_pit | plays | 5 | 23.1 | 11.0 | 0.0 | 70.6 | 60% | runs |
| hollow_armor | elixir_max | 20 | 23.9 | 23.0 | 16.8 | 33.0 | 72% | runs |
| soul_collector | burst | 2000 | 3684.5 | 3426.0 | 1443.8 | 6865.2 | 72% |  |
| spike_trap | plays_window | 5 | 5.3 | 5.0 | 4.0 | 7.0 | 72% |  |
| corrupt_piper | died | 2000 | 2878.0 | 2979.0 | 1616.8 | 4014.6 | 76% | acumulado |
| mother_nest | peak_on_spell | 20 | 128.8 | 51.0 | 12.4 | 357.2 | 76% | runs |
| life_drain | curses | 5 | 8.3 | 10.0 | 0.0 | 10.0 | 84% | runs |
| hunt_instinct | plays | 40 | 77.7 | 75.0 | 42.4 | 113.0 | 92% | acumulado |
| alpha_beast | peak | 30 | 163.1 | 92.0 | 45.8 | 361.6 | 100% |  |
| ash_phoenix | gold_end | 1000 | 3540.4 | 3238.3 | 2448.0 | 4947.5 | 100% | runs |
| bat_cloud | peak | 12 | 167.0 | 92.0 | 48.8 | 366.4 | 100% | runs |
| ember_rain | plays | 25 | 77.7 | 75.0 | 42.4 | 113.0 | 100% | runs |
| magma_golem | peak | 10 | 183.9 | 94.0 | 51.0 | 400.0 | 100% | runs |
| plague_carrion | peak | 40 | 183.9 | 94.0 | 51.0 | 400.0 | 100% | runs |
| rat_tide | plays_same | 40 | 73.8 | 70.0 | 55.4 | 103.0 | 100% | runs |
| rat_trap | peste | 5 | 14.7 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_spell|dragon (n=25, vitória 28%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.6 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 457.8 | 442.0 | 335.4 | 551.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.9 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.9 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 48.0 | 45.0 | 15.4 | 79.0 | 0% | acumulado |
| furnace | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| mimic | plays | 60 | 25.8 | 25.0 | 14.4 | 37.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 975.6 | 952.0 | 761.2 | 1188.6 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 193.7 | 190.0 | 151.0 | 231.8 | 0% | acumulado |
| plague_carrion | peak | 40 | 12.8 | 12.0 | 10.0 | 17.6 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 354.6 | 329.0 | 277.4 | 445.2 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 86.1 | 75.0 | 57.4 | 140.8 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| pack_den | plays | 40 | 25.8 | 25.0 | 14.4 | 37.0 | 4% | acumulado |
| soul_collector | burst | 2000 | 1263.8 | 1188.0 | 864.5 | 1612.5 | 4% |  |
| black_pestilence | plays | 150 | 86.1 | 75.0 | 57.4 | 140.8 | 8% | acumulado |
| meteor_storm | plays | 80 | 55.0 | 50.0 | 32.8 | 77.0 | 8% | acumulado |
| soul_storm | spells_distinct | 6 | 4.6 | 5.0 | 4.0 | 5.0 | 8% |  |
| tar_net | gold_spent | 2000 | 1202.9 | 1240.0 | 515.0 | 1913.0 | 8% | acumulado |
| burn_village | burn_time | 150 | 88.3 | 74.0 | 33.5 | 146.5 | 12% | acumulado |
| elder_dragon | peak | 5 | 4.0 | 4.0 | 3.0 | 5.6 | 16% |  |
| hollow_armor | elixir_max | 20 | 17.8 | 17.0 | 16.0 | 21.0 | 20% | runs |
| arcane_apocalypse | plays_window | 7 | 5.3 | 5.0 | 4.0 | 7.0 | 24% |  |
| gold_bait | coins | 25 | 19.9 | 21.0 | 10.4 | 29.2 | 24% | acumulado |
| blood_tax | plays | 100 | 86.1 | 75.0 | 57.4 | 140.8 | 28% | acumulado |
| cave_troll | win_phase | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 28% |  |
| gold_avalanche | gold_earned | 6000 | 4961.0 | 4171.6 | 2495.1 | 8959.8 | 28% | acumulado |
| ash_phoenix | gold_end | 1000 | 1284.7 | 371.7 | 26.1 | 3522.6 | 36% | runs |
| bat_nest | peak | 3 | 2.4 | 2.0 | 2.0 | 3.0 | 40% | runs |
| dragon_exchange | soak_ignite | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 76% |  |
| boiling_oil | soaked_time | 75 | 172.6 | 158.4 | 60.7 | 258.6 | 80% | acumulado |
| rat_tide | plays_same | 40 | 48.8 | 48.0 | 35.8 | 62.0 | 80% | runs |
| life_drain | curses | 5 | 8.6 | 10.0 | 4.8 | 10.0 | 88% | runs |
| spike_trap | plays_window | 5 | 5.6 | 5.0 | 5.0 | 7.0 | 92% |  |
| flooded_pit | plays | 5 | 48.0 | 45.0 | 15.4 | 79.0 | 96% | runs |
| magma_golem | peak | 10 | 12.8 | 12.0 | 10.0 | 17.6 | 96% | runs |
| ember_rain | plays | 25 | 86.1 | 75.0 | 57.4 | 140.8 | 100% | runs |
| hunt_instinct | plays | 40 | 86.1 | 75.0 | 57.4 | 140.8 | 100% | acumulado |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_spell|dragon@3 (n=25, vitória 8%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 532.5 | 511.0 | 403.8 | 738.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.0 | 5.0 | 4.0 | 6.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| brown_bear | heroes | 20 | 5.0 | 5.0 | 4.0 | 6.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 52.0 | 35.0 | 15.2 | 101.6 | 0% | acumulado |
| furnace | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| ghost | peak | 40 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 227.1 | 214.0 | 173.4 | 307.6 | 0% | acumulado |
| plague_carrion | peak | 40 | 17.6 | 16.0 | 12.0 | 23.2 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 411.2 | 380.0 | 298.0 | 566.6 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 102.3 | 95.0 | 64.6 | 136.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| mimic | plays | 60 | 29.8 | 26.0 | 16.0 | 49.6 | 4% | acumulado |
| molten_gold | elixir_spent | 2000 | 1235.9 | 1163.0 | 851.4 | 1682.2 | 4% | acumulado |
| tar_net | gold_spent | 2000 | 1350.4 | 1425.0 | 645.0 | 1860.0 | 4% | acumulado |
| black_pestilence | plays | 150 | 102.3 | 95.0 | 64.6 | 136.0 | 8% | acumulado |
| cave_troll | win_phase | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| soul_storm | spells_distinct | 6 | 4.9 | 5.0 | 4.0 | 6.0 | 16% |  |
| meteor_storm | plays | 80 | 61.5 | 59.0 | 42.8 | 87.8 | 20% | acumulado |
| pack_den | plays | 40 | 29.8 | 26.0 | 16.0 | 49.6 | 20% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.6 | 5.0 | 4.0 | 7.6 | 28% |  |
| burn_village | burn_time | 150 | 153.0 | 124.5 | 48.6 | 304.1 | 36% | acumulado |
| gold_bait | coins | 25 | 23.2 | 22.0 | 13.6 | 35.2 | 40% | acumulado |
| blood_tax | plays | 100 | 102.3 | 95.0 | 64.6 | 136.0 | 48% | acumulado |
| hollow_armor | elixir_max | 20 | 19.6 | 19.0 | 16.0 | 23.6 | 48% | runs |
| soul_collector | burst | 2000 | 2126.7 | 1886.2 | 1428.4 | 2912.7 | 48% |  |
| ash_phoenix | gold_end | 1000 | 4390.6 | 2682.5 | 299.8 | 11650.7 | 64% | runs |
| bat_nest | peak | 3 | 3.1 | 3.0 | 2.0 | 4.6 | 64% | runs |
| elder_dragon | peak | 5 | 5.4 | 5.0 | 4.0 | 7.6 | 68% |  |
| dragon_exchange | soak_ignite | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 72% |  |
| gold_avalanche | gold_earned | 6000 | 9630.0 | 8267.3 | 3571.8 | 17072.3 | 72% | acumulado |
| boiling_oil | soaked_time | 75 | 189.3 | 179.1 | 63.1 | 341.9 | 84% | acumulado |
| spike_trap | plays_window | 5 | 5.8 | 5.0 | 4.4 | 6.6 | 88% |  |
| rat_tide | plays_same | 40 | 53.2 | 51.0 | 40.0 | 72.6 | 92% | runs |
| ember_rain | plays | 25 | 102.3 | 95.0 | 64.6 | 136.0 | 100% | runs |
| flooded_pit | plays | 5 | 52.0 | 35.0 | 15.2 | 101.6 | 100% | runs |
| hunt_instinct | plays | 40 | 102.3 | 95.0 | 64.6 | 136.0 | 100% | acumulado |
| life_drain | curses | 5 | 9.7 | 10.0 | 9.4 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 17.6 | 16.0 | 12.0 | 23.2 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_spell|lich (n=25, vitória 72%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 834.9 | 794.0 | 571.2 | 1095.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.6 | 7.0 | 6.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.6 | 7.0 | 6.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 50.5 | 43.0 | 17.0 | 78.0 | 0% | acumulado |
| furnace | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 1887.7 | 1902.7 | 1505.8 | 2160.5 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 958.3 | 929.0 | 743.2 | 1213.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 190.5 | 185.0 | 156.6 | 235.8 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 505.0 | 472.0 | 401.8 | 683.8 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 247.7 | 231.0 | 180.4 | 361.8 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 797.0 | 780.0 | 611.0 | 1035.0 | 0% | acumulado |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| mimic | plays | 60 | 16.3 | 12.0 | 0.0 | 41.2 | 4% | acumulado |
| ghost | peak | 40 | 17.8 | 14.0 | 9.4 | 34.2 | 8% | runs |
| pack_den | plays | 40 | 16.3 | 12.0 | 0.0 | 41.2 | 12% | acumulado |
| plague_carrion | peak | 40 | 31.4 | 25.0 | 15.0 | 48.8 | 20% | runs |
| eruption | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 24% |  |
| soul_harvest | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 24% | runs |
| bat_nest | peak | 3 | 1.7 | 1.0 | 0.0 | 4.2 | 28% | runs |
| arcane_spark | plays | 120 | 115.4 | 110.0 | 77.4 | 172.0 | 32% | acumulado |
| soul_storm | spells_distinct | 6 | 5.8 | 6.0 | 5.0 | 7.0 | 56% |  |
| ash_phoenix | gold_end | 1000 | 1090.7 | 1126.4 | 644.3 | 1622.2 | 64% | runs |
| burn_village | burn_time | 150 | 181.1 | 167.9 | 120.2 | 269.7 | 64% | acumulado |
| life_drain | curses | 5 | 6.5 | 9.0 | 0.4 | 10.0 | 64% | runs |
| cave_troll | win_phase | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 72% |  |
| eternal_army | peak | 12 | 18.2 | 14.0 | 9.4 | 34.2 | 76% | runs |
| hollow_armor | elixir_max | 20 | 24.1 | 22.0 | 16.4 | 32.2 | 76% | runs |
| rat_tide | plays_same | 40 | 49.3 | 49.0 | 33.4 | 65.0 | 76% | runs |
| shadow_echo | plays_window | 5 | 5.4 | 5.0 | 4.0 | 7.0 | 76% |  |
| soul_collector | burst | 2000 | 4416.5 | 4325.5 | 1470.1 | 8048.6 | 80% |  |
| black_pestilence | plays | 150 | 247.7 | 231.0 | 180.4 | 361.8 | 96% | acumulado |
| flooded_pit | plays | 5 | 50.5 | 43.0 | 17.0 | 78.0 | 96% | runs |
| arcane_apocalypse | plays_window | 7 | 12.5 | 12.0 | 9.4 | 16.0 | 100% |  |
| blood_tax | plays | 100 | 247.7 | 231.0 | 180.4 | 361.8 | 100% | acumulado |
| ember_rain | plays | 25 | 247.7 | 231.0 | 180.4 | 361.8 | 100% | runs |
| hunt_instinct | plays | 40 | 247.7 | 231.0 | 180.4 | 361.8 | 100% | acumulado |
| magma_golem | peak | 10 | 31.4 | 25.0 | 15.0 | 48.8 | 100% | runs |
| spike_trap | plays_window | 5 | 8.7 | 9.0 | 7.0 | 10.0 | 100% |  |

## human_spell|lich@3 (n=25, vitória 40%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1179.1 | 1161.0 | 765.0 | 1620.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 243.6 | 238.0 | 163.0 | 320.4 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 960.2 | 870.0 | 730.0 | 1271.0 | 0% | acumulado |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| gold_avalanche | gold_earned | 6000 | 4075.6 | 4553.4 | 2488.2 | 5488.4 | 4% | acumulado |
| forbidden_library | plays | 200 | 92.0 | 78.0 | 36.2 | 159.6 | 8% | acumulado |
| mimic | plays | 60 | 21.6 | 17.0 | 0.0 | 50.0 | 8% | acumulado |
| molten_gold | elixir_spent | 2000 | 1364.6 | 1284.0 | 923.4 | 1864.6 | 8% | acumulado |
| shadow_mark | plays | 1000 | 688.0 | 657.0 | 492.2 | 961.6 | 8% | acumulado |
| eruption | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 16% |  |
| pack_den | plays | 40 | 21.6 | 17.0 | 0.0 | 50.0 | 16% | acumulado |
| soul_feast | plays | 400 | 330.9 | 341.0 | 240.4 | 468.8 | 16% | acumulado |
| soul_harvest | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 16% | runs |
| ghost | peak | 40 | 25.8 | 20.0 | 13.4 | 47.6 | 20% | runs |
| bat_nest | peak | 3 | 1.8 | 2.0 | 0.0 | 3.6 | 28% | runs |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 40% |  |
| plague_carrion | peak | 40 | 50.9 | 36.0 | 21.4 | 85.6 | 44% | runs |
| life_drain | curses | 5 | 6.5 | 10.0 | 0.0 | 10.0 | 64% | runs |
| arcane_spark | plays | 120 | 165.5 | 170.0 | 91.2 | 231.8 | 72% | acumulado |
| burn_village | burn_time | 150 | 310.0 | 245.1 | 118.2 | 634.4 | 80% | acumulado |
| hollow_armor | elixir_max | 20 | 28.4 | 25.0 | 17.4 | 45.8 | 80% | runs |
| shadow_echo | plays_window | 5 | 6.4 | 6.0 | 4.4 | 9.6 | 88% |  |
| rat_tide | plays_same | 40 | 65.9 | 60.0 | 41.8 | 97.8 | 92% | runs |
| soul_storm | spells_distinct | 6 | 6.6 | 7.0 | 6.0 | 7.6 | 92% |  |
| black_pestilence | plays | 150 | 330.9 | 341.0 | 240.4 | 468.8 | 96% | acumulado |
| soul_collector | burst | 2000 | 6145.8 | 6409.7 | 3452.6 | 9897.1 | 96% |  |
| arcane_apocalypse | plays_window | 7 | 14.3 | 13.0 | 9.0 | 22.2 | 100% |  |
| ash_phoenix | gold_end | 1000 | 3115.4 | 3485.6 | 1567.9 | 4505.0 | 100% | runs |
| blood_tax | plays | 100 | 330.9 | 341.0 | 240.4 | 468.8 | 100% | acumulado |
| ember_rain | plays | 25 | 330.9 | 341.0 | 240.4 | 468.8 | 100% | runs |
| eternal_army | peak | 12 | 26.3 | 20.0 | 14.0 | 47.6 | 100% | runs |
| flooded_pit | plays | 5 | 92.0 | 78.0 | 36.2 | 159.6 | 100% | runs |
| hunt_instinct | plays | 40 | 330.9 | 341.0 | 240.4 | 468.8 | 100% | acumulado |
| magma_golem | peak | 10 | 50.9 | 36.0 | 21.4 | 85.6 | 100% | runs |
| spike_trap | plays_window | 5 | 9.2 | 8.0 | 7.0 | 12.6 | 100% |  |

## human_spell|plague (n=25, vitória 56%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.5 | 3.0 | 3.0 | 4.6 | 0% |  |
| arcane_spark | plays | 120 | 0.9 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 51.2 | 48.0 | 29.8 | 74.2 | 0% | acumulado |
| blood_tax | plays | 100 | 51.2 | 48.0 | 29.8 | 74.2 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.4 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.4 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 1.6 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.6 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 9.7 | 4.0 | 0.0 | 23.6 | 0% | acumulado |
| furnace | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.6 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 2099.1 | 2054.9 | 1627.1 | 2687.1 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 27.3 | 25.0 | 16.4 | 40.6 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1086.8 | 1057.0 | 859.4 | 1335.4 | 0% | acumulado |
| ogre | plays | 600 | 240.2 | 241.0 | 203.2 | 284.0 | 0% | acumulado |
| primal_beast | plays | 600 | 139.3 | 136.0 | 108.2 | 186.0 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 328.3 | 320.0 | 275.0 | 402.0 | 0% | acumulado |
| soul_feast | plays | 400 | 51.2 | 48.0 | 29.8 | 74.2 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 84.3 | 80.0 | 67.2 | 107.2 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 785.4 | 675.0 | 550.0 | 1128.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1968.6 | 1866.0 | 1400.0 | 2459.0 | 4% | acumulado |
| soul_storm | spells_distinct | 6 | 4.2 | 4.0 | 4.0 | 5.0 | 4% |  |
| bat_nest | peak | 3 | 1.7 | 1.0 | 1.0 | 2.6 | 12% | runs |
| corrupt_piper | died | 2000 | 1577.9 | 1487.0 | 946.2 | 2052.4 | 16% | acumulado |
| pack_den | plays | 40 | 27.3 | 25.0 | 16.4 | 40.6 | 16% | acumulado |
| soul_collector | burst | 2000 | 2036.4 | 1696.6 | 1189.7 | 2543.0 | 28% |  |
| flooded_pit | plays | 5 | 9.7 | 4.0 | 0.0 | 23.6 | 48% | runs |
| hollow_armor | elixir_max | 20 | 19.4 | 18.0 | 16.0 | 24.0 | 48% | runs |
| cave_troll | win_phase | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 56% |  |
| ash_phoenix | gold_end | 1000 | 1313.6 | 1421.5 | 555.0 | 1867.4 | 68% | runs |
| hunt_instinct | plays | 40 | 51.2 | 48.0 | 29.8 | 74.2 | 68% | acumulado |
| life_drain | curses | 5 | 6.5 | 10.0 | 0.0 | 10.0 | 68% | runs |
| spike_trap | plays_window | 5 | 5.0 | 5.0 | 4.0 | 6.0 | 68% |  |
| mother_nest | peak_on_spell | 20 | 61.6 | 36.0 | 13.6 | 111.0 | 72% | runs |
| rat_tide | plays_same | 40 | 47.9 | 48.0 | 38.4 | 56.4 | 80% | runs |
| alpha_beast | peak | 30 | 82.6 | 46.0 | 23.6 | 237.8 | 84% |  |
| plague_carrion | peak | 40 | 91.5 | 50.0 | 29.0 | 270.8 | 84% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 96% |  |
| bat_cloud | peak | 12 | 84.3 | 47.0 | 24.0 | 239.0 | 100% | runs |
| ember_rain | plays | 25 | 51.2 | 48.0 | 29.8 | 74.2 | 100% | runs |
| magma_golem | peak | 10 | 91.5 | 50.0 | 29.0 | 270.8 | 100% | runs |
| rat_trap | peste | 5 | 14.8 | 15.0 | 15.0 | 15.0 | 100% | runs |

## human_spell|plague@3 (n=25, vitória 44%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 67.7 | 66.0 | 42.4 | 96.4 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.2 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.2 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.4 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 15.3 | 8.0 | 0.0 | 45.4 | 0% | acumulado |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.4 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| primal_beast | plays | 600 | 191.9 | 185.0 | 114.2 | 275.4 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 67.7 | 66.0 | 42.4 | 96.4 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| tar_net | gold_spent | 2000 | 915.4 | 935.0 | 607.0 | 1212.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 3.6 | 3.0 | 3.0 | 4.0 | 4% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| ogre | plays | 600 | 356.7 | 338.0 | 231.6 | 488.6 | 4% | acumulado |
| shadow_mark | plays | 1000 | 478.4 | 476.0 | 339.2 | 619.8 | 4% | acumulado |
| soul_storm | spells_distinct | 6 | 4.4 | 4.0 | 4.0 | 5.0 | 4% |  |
| blood_tax | plays | 100 | 67.7 | 66.0 | 42.4 | 96.4 | 8% | acumulado |
| gold_avalanche | gold_earned | 6000 | 4468.0 | 4419.0 | 3028.2 | 5959.8 | 12% | acumulado |
| mimic | plays | 60 | 38.7 | 31.0 | 19.4 | 58.4 | 12% | acumulado |
| molten_gold | elixir_spent | 2000 | 1653.9 | 1615.0 | 1016.0 | 2125.6 | 16% | acumulado |
| spitting_viper | plays | 150 | 120.2 | 124.0 | 71.8 | 155.0 | 16% | acumulado |
| bat_nest | peak | 3 | 2.2 | 2.0 | 1.0 | 3.0 | 28% | runs |
| bone_colossus | died | 3000 | 3004.4 | 2645.0 | 1920.8 | 4690.6 | 40% | acumulado |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 44% |  |
| pack_den | plays | 40 | 38.7 | 31.0 | 19.4 | 58.4 | 44% | acumulado |
| flooded_pit | plays | 5 | 15.3 | 8.0 | 0.0 | 45.4 | 52% | runs |
| corrupt_piper | died | 2000 | 2469.8 | 2127.0 | 1523.0 | 4088.2 | 60% | acumulado |
| hollow_armor | elixir_max | 20 | 21.1 | 20.0 | 17.0 | 27.0 | 60% | runs |
| life_drain | curses | 5 | 7.3 | 10.0 | 0.0 | 10.0 | 72% | runs |
| spike_trap | plays_window | 5 | 5.3 | 5.0 | 4.0 | 6.6 | 80% |  |
| soul_collector | burst | 2000 | 4254.5 | 4245.4 | 1900.8 | 6916.9 | 84% |  |
| mother_nest | peak_on_spell | 20 | 166.0 | 74.0 | 21.0 | 371.0 | 88% | runs |
| plague_carrion | peak | 40 | 202.0 | 90.0 | 43.0 | 400.0 | 88% | runs |
| alpha_beast | peak | 30 | 177.2 | 87.0 | 37.6 | 361.2 | 92% |  |
| rat_tide | plays_same | 40 | 71.5 | 62.0 | 47.6 | 97.4 | 92% | runs |
| hunt_instinct | plays | 40 | 67.7 | 66.0 | 42.4 | 96.4 | 96% | acumulado |
| rat_trap | peste | 5 | 14.5 | 15.0 | 15.0 | 15.0 | 96% | runs |
| ash_phoenix | gold_end | 1000 | 3552.3 | 3489.0 | 2035.9 | 5280.5 | 100% | runs |
| bat_cloud | peak | 12 | 183.6 | 87.0 | 37.6 | 371.0 | 100% | runs |
| ember_rain | plays | 25 | 67.7 | 66.0 | 42.4 | 96.4 | 100% | runs |
| magma_golem | peak | 10 | 202.0 | 90.0 | 43.0 | 400.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_swarm|dragon (n=25, vitória 44%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 69.6 | 68.0 | 50.8 | 90.6 | 0% | acumulado |
| bone_colossus | died | 3000 | 468.7 | 471.0 | 387.8 | 566.8 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.0 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.0 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 45.1 | 41.0 | 18.4 | 75.6 | 0% | acumulado |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| meteor_storm | plays | 80 | 44.8 | 43.0 | 28.6 | 62.8 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 938.0 | 949.0 | 735.6 | 1077.6 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 191.6 | 184.0 | 148.0 | 229.8 | 0% | acumulado |
| plague_carrion | peak | 40 | 13.1 | 13.0 | 10.0 | 15.6 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 331.9 | 330.0 | 270.6 | 371.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 69.6 | 68.0 | 50.8 | 90.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| gold_bait | coins | 25 | 18.7 | 20.0 | 14.2 | 23.0 | 4% | acumulado |
| mimic | plays | 60 | 25.7 | 25.0 | 14.4 | 38.6 | 4% | acumulado |
| tar_net | gold_spent | 2000 | 1037.0 | 1020.0 | 527.0 | 1659.0 | 4% | acumulado |
| arcane_apocalypse | plays_window | 7 | 4.9 | 5.0 | 3.4 | 6.0 | 8% |  |
| blood_tax | plays | 100 | 69.6 | 68.0 | 50.8 | 90.6 | 8% | acumulado |
| pack_den | plays | 40 | 25.7 | 25.0 | 14.4 | 38.6 | 8% | acumulado |
| burn_village | burn_time | 150 | 95.4 | 79.2 | 27.2 | 162.4 | 12% | acumulado |
| soul_collector | burst | 2000 | 1367.6 | 1272.3 | 938.8 | 1968.9 | 12% |  |
| soul_storm | spells_distinct | 6 | 4.4 | 4.0 | 3.0 | 5.6 | 12% |  |
| gold_avalanche | gold_earned | 6000 | 4598.2 | 4223.5 | 2372.8 | 7717.8 | 20% | acumulado |
| ash_phoenix | gold_end | 1000 | 1125.8 | 577.5 | 23.8 | 3306.9 | 32% | runs |
| elder_dragon | peak | 5 | 4.3 | 4.0 | 3.0 | 5.0 | 32% |  |
| bat_nest | peak | 3 | 2.4 | 2.0 | 1.4 | 3.6 | 36% | runs |
| hollow_armor | elixir_max | 20 | 18.3 | 18.0 | 14.4 | 23.2 | 36% | runs |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 44% |  |
| dragon_exchange | soak_ignite | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 72% |  |
| rat_tide | plays_same | 40 | 46.4 | 46.0 | 37.4 | 58.8 | 76% | runs |
| boiling_oil | soaked_time | 75 | 151.7 | 154.2 | 59.3 | 237.5 | 84% | acumulado |
| life_drain | curses | 5 | 8.3 | 10.0 | 4.4 | 10.0 | 88% | runs |
| hunt_instinct | plays | 40 | 69.6 | 68.0 | 50.8 | 90.6 | 92% | acumulado |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 5.0 | 6.0 | 92% |  |
| magma_golem | peak | 10 | 13.1 | 13.0 | 10.0 | 15.6 | 96% | runs |
| ember_rain | plays | 25 | 69.6 | 68.0 | 50.8 | 90.6 | 100% | runs |
| flooded_pit | plays | 5 | 45.1 | 41.0 | 18.4 | 75.6 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human_swarm|dragon@3 (n=25, vitória 12%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 81.8 | 81.0 | 62.0 | 102.8 | 0% | acumulado |
| bone_colossus | died | 3000 | 586.1 | 535.0 | 448.6 | 793.4 | 0% | acumulado |
| bone_dragon | heroes | 35 | 4.9 | 4.0 | 4.0 | 6.6 | 0% | acumulado |
| bone_totem | wins | 2 | 0.1 | 0.0 | 0.0 | 0.6 | 0% |  |
| brown_bear | heroes | 20 | 4.9 | 4.0 | 4.0 | 6.6 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 56.0 | 48.0 | 16.6 | 105.8 | 0% | acumulado |
| furnace | wins | 2 | 0.1 | 0.0 | 0.0 | 0.6 | 0% |  |
| ghost | peak | 40 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| mimic | plays | 60 | 27.1 | 28.0 | 14.2 | 35.6 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 234.8 | 209.0 | 182.8 | 321.0 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.1 | 0.0 | 0.0 | 0.6 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 400.6 | 369.0 | 319.8 | 531.4 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 81.8 | 81.0 | 62.0 | 102.8 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 1266.8 | 1330.0 | 838.0 | 1691.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 4.8 | 5.0 | 3.4 | 6.0 | 4% |  |
| meteor_storm | plays | 80 | 50.7 | 48.0 | 32.4 | 72.4 | 4% | acumulado |
| molten_gold | elixir_spent | 2000 | 1223.0 | 1122.0 | 880.6 | 1626.0 | 4% | acumulado |
| fallen_healer | loss_max | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| gold_bait | coins | 25 | 18.6 | 19.0 | 13.4 | 24.0 | 8% | acumulado |
| pack_den | plays | 40 | 27.1 | 28.0 | 14.2 | 35.6 | 8% | acumulado |
| cave_troll | win_phase | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% |  |
| plague_carrion | peak | 40 | 29.0 | 17.0 | 12.0 | 37.0 | 12% | runs |
| blood_tax | plays | 100 | 81.8 | 81.0 | 62.0 | 102.8 | 16% | acumulado |
| soul_storm | spells_distinct | 6 | 4.9 | 5.0 | 4.0 | 6.0 | 16% |  |
| burn_village | burn_time | 150 | 164.0 | 82.0 | 16.4 | 478.9 | 24% | acumulado |
| soul_collector | burst | 2000 | 2079.8 | 1619.9 | 1245.9 | 2951.2 | 28% |  |
| hollow_armor | elixir_max | 20 | 20.3 | 19.0 | 16.4 | 26.0 | 44% | runs |
| bat_nest | peak | 3 | 2.9 | 2.0 | 2.0 | 4.6 | 48% | runs |
| dragon_exchange | soak_ignite | 1 | 0.5 | 0.0 | 0.0 | 1.0 | 48% |  |
| elder_dragon | peak | 5 | 8.4 | 5.0 | 4.0 | 9.6 | 52% |  |
| ash_phoenix | gold_end | 1000 | 3671.1 | 2063.2 | 207.7 | 8569.7 | 68% | runs |
| gold_avalanche | gold_earned | 6000 | 9789.5 | 8141.7 | 4330.7 | 17579.3 | 68% | acumulado |
| boiling_oil | soaked_time | 75 | 140.5 | 139.6 | 53.7 | 221.9 | 76% | acumulado |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 6.6 | 80% |  |
| rat_tide | plays_same | 40 | 55.6 | 49.0 | 39.6 | 77.6 | 88% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 96% | runs |
| ember_rain | plays | 25 | 81.8 | 81.0 | 62.0 | 102.8 | 100% | runs |
| flooded_pit | plays | 5 | 56.0 | 48.0 | 16.6 | 105.8 | 100% | runs |
| hunt_instinct | plays | 40 | 81.8 | 81.0 | 62.0 | 102.8 | 100% | acumulado |
| life_drain | curses | 5 | 9.8 | 10.0 | 10.0 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 29.0 | 17.0 | 12.0 | 37.0 | 100% | runs |

## human_swarm|lich (n=25, vitória 48%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 821.7 | 826.0 | 617.8 | 1075.8 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.9 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.5 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.9 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 53.3 | 48.0 | 21.2 | 88.6 | 0% | acumulado |
| furnace | wins | 2 | 0.5 | 0.0 | 0.0 | 1.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 1728.1 | 1791.5 | 1112.7 | 2233.5 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 17.1 | 15.0 | 0.0 | 41.4 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 921.3 | 870.0 | 738.0 | 1135.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 190.7 | 196.0 | 147.4 | 231.8 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.5 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 412.1 | 420.0 | 317.4 | 487.4 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 151.0 | 143.0 | 109.2 | 203.6 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 686.0 | 665.0 | 395.0 | 921.0 | 0% | acumulado |
| arcane_spark | plays | 120 | 80.0 | 73.0 | 55.2 | 109.0 | 4% | acumulado |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| ghost | peak | 40 | 15.8 | 13.0 | 11.0 | 21.0 | 8% | runs |
| eruption | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% |  |
| pack_den | plays | 40 | 17.1 | 15.0 | 0.0 | 41.4 | 12% | acumulado |
| plague_carrion | peak | 40 | 23.5 | 21.0 | 15.4 | 35.4 | 12% | runs |
| soul_harvest | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% | runs |
| burn_village | burn_time | 150 | 116.3 | 85.8 | 47.5 | 259.6 | 16% | acumulado |
| bat_nest | peak | 3 | 1.8 | 2.0 | 0.0 | 4.0 | 28% | runs |
| ash_phoenix | gold_end | 1000 | 1042.2 | 971.5 | 485.5 | 1594.4 | 48% | runs |
| black_pestilence | plays | 150 | 151.0 | 143.0 | 109.2 | 203.6 | 48% | acumulado |
| cave_troll | win_phase | 1 | 0.5 | 0.0 | 0.0 | 1.0 | 48% |  |
| life_drain | curses | 5 | 4.8 | 4.0 | 0.0 | 10.0 | 48% | runs |
| hollow_armor | elixir_max | 20 | 20.3 | 20.0 | 14.4 | 25.0 | 52% | runs |
| shadow_echo | plays_window | 5 | 4.7 | 5.0 | 3.4 | 6.0 | 52% |  |
| soul_storm | spells_distinct | 6 | 6.1 | 6.0 | 5.0 | 7.0 | 76% |  |
| eternal_army | peak | 12 | 16.0 | 14.0 | 11.0 | 21.4 | 80% | runs |
| blood_tax | plays | 100 | 151.0 | 143.0 | 109.2 | 203.6 | 92% | acumulado |
| soul_collector | burst | 2000 | 4112.9 | 3806.8 | 2221.4 | 5911.8 | 92% |  |
| flooded_pit | plays | 5 | 53.3 | 48.0 | 21.2 | 88.6 | 96% | runs |
| rat_tide | plays_same | 40 | 61.4 | 61.0 | 47.2 | 78.6 | 96% | runs |
| arcane_apocalypse | plays_window | 7 | 9.6 | 9.0 | 7.0 | 12.0 | 100% |  |
| ember_rain | plays | 25 | 151.0 | 143.0 | 109.2 | 203.6 | 100% | runs |
| hunt_instinct | plays | 40 | 151.0 | 143.0 | 109.2 | 203.6 | 100% | acumulado |
| magma_golem | peak | 10 | 23.5 | 21.0 | 15.4 | 35.4 | 100% | runs |
| spike_trap | plays_window | 5 | 7.7 | 8.0 | 6.4 | 9.0 | 100% |  |

## human_swarm|lich@3 (n=25, vitória 28%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1236.3 | 1211.0 | 814.8 | 1705.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.6 | 6.0 | 4.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.6 | 6.0 | 4.4 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| furnace | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1338.0 | 1313.0 | 939.4 | 1776.2 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 259.0 | 251.0 | 185.8 | 326.2 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 581.6 | 580.0 | 410.8 | 770.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 211.4 | 193.0 | 152.6 | 314.8 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 899.8 | 843.0 | 601.0 | 1179.0 | 0% | acumulado |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| forbidden_library | plays | 200 | 87.3 | 70.0 | 29.0 | 145.6 | 4% | acumulado |
| gold_avalanche | gold_earned | 6000 | 3866.0 | 3636.6 | 2544.6 | 5187.1 | 4% | acumulado |
| mimic | plays | 60 | 23.9 | 26.0 | 0.0 | 40.0 | 4% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% | runs |
| ghost | peak | 40 | 25.0 | 16.0 | 12.0 | 40.4 | 12% | runs |
| pack_den | plays | 40 | 23.9 | 26.0 | 0.0 | 40.0 | 16% | acumulado |
| burn_village | burn_time | 150 | 125.5 | 102.6 | 32.3 | 230.0 | 20% | acumulado |
| cave_troll | win_phase | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 28% |  |
| bat_nest | peak | 3 | 2.4 | 2.0 | 0.4 | 4.6 | 36% | runs |
| arcane_spark | plays | 120 | 124.9 | 111.0 | 78.8 | 191.2 | 40% | acumulado |
| plague_carrion | peak | 40 | 44.7 | 39.0 | 19.4 | 51.6 | 48% | runs |
| hollow_armor | elixir_max | 20 | 22.0 | 20.0 | 15.0 | 33.2 | 52% | runs |
| life_drain | curses | 5 | 6.3 | 8.0 | 0.0 | 10.0 | 64% | runs |
| shadow_echo | plays_window | 5 | 5.8 | 6.0 | 4.0 | 7.6 | 76% |  |
| black_pestilence | plays | 150 | 211.4 | 193.0 | 152.6 | 314.8 | 88% | acumulado |
| soul_collector | burst | 2000 | 7576.6 | 7797.4 | 3623.0 | 11227.4 | 96% |  |
| soul_storm | spells_distinct | 6 | 6.9 | 7.0 | 6.0 | 8.6 | 96% |  |
| arcane_apocalypse | plays_window | 7 | 10.2 | 9.0 | 8.0 | 13.6 | 100% |  |
| ash_phoenix | gold_end | 1000 | 2966.2 | 2786.3 | 1696.0 | 4167.1 | 100% | runs |
| blood_tax | plays | 100 | 211.4 | 193.0 | 152.6 | 314.8 | 100% | acumulado |
| ember_rain | plays | 25 | 211.4 | 193.0 | 152.6 | 314.8 | 100% | runs |
| eternal_army | peak | 12 | 25.2 | 16.0 | 12.0 | 40.4 | 100% | runs |
| flooded_pit | plays | 5 | 87.3 | 70.0 | 29.0 | 145.6 | 100% | runs |
| hunt_instinct | plays | 40 | 211.4 | 193.0 | 152.6 | 314.8 | 100% | acumulado |
| magma_golem | peak | 10 | 44.7 | 39.0 | 19.4 | 51.6 | 100% | runs |
| rat_tide | plays_same | 40 | 78.8 | 78.0 | 58.0 | 100.4 | 100% | runs |
| spike_trap | plays_window | 5 | 8.8 | 8.0 | 7.0 | 11.0 | 100% |  |

## human_swarm|plague (n=25, vitória 52%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.5 | 3.0 | 3.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 1.8 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 51.1 | 51.0 | 35.2 | 70.6 | 0% | acumulado |
| blood_tax | plays | 100 | 51.1 | 51.0 | 35.2 | 70.6 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.1 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.5 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.1 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.6 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 12.2 | 10.0 | 0.0 | 33.0 | 0% | acumulado |
| furnace | wins | 2 | 0.5 | 1.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.6 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1902.1 | 1921.2 | 1371.8 | 2385.2 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1101.2 | 1108.0 | 841.0 | 1370.4 | 0% | acumulado |
| ogre | plays | 600 | 242.4 | 240.0 | 185.6 | 297.0 | 0% | acumulado |
| primal_beast | plays | 600 | 145.1 | 145.0 | 110.6 | 176.2 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.5 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.2 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 340.3 | 343.0 | 251.2 | 422.2 | 0% | acumulado |
| soul_feast | plays | 400 | 51.1 | 51.0 | 35.2 | 70.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 4.2 | 4.0 | 4.0 | 5.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 81.1 | 79.0 | 55.6 | 111.6 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 733.0 | 710.0 | 405.0 | 1090.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 2111.8 | 1965.0 | 1510.2 | 2907.0 | 4% | acumulado |
| mimic | plays | 60 | 34.6 | 35.0 | 15.8 | 57.6 | 4% | acumulado |
| soul_collector | burst | 2000 | 1828.5 | 1441.2 | 895.0 | 2631.1 | 20% |  |
| bat_nest | peak | 3 | 2.0 | 2.0 | 1.0 | 3.0 | 28% | runs |
| corrupt_piper | died | 2000 | 1657.8 | 1450.0 | 1147.0 | 2457.0 | 28% | acumulado |
| pack_den | plays | 40 | 34.6 | 35.0 | 15.8 | 57.6 | 36% | acumulado |
| hollow_armor | elixir_max | 20 | 19.7 | 18.0 | 15.0 | 27.0 | 40% | runs |
| cave_troll | win_phase | 1 | 0.5 | 1.0 | 0.0 | 1.0 | 52% |  |
| flooded_pit | plays | 5 | 12.2 | 10.0 | 0.0 | 33.0 | 52% | runs |
| mother_nest | peak_on_spell | 20 | 45.8 | 28.0 | 10.4 | 55.2 | 56% | runs |
| spike_trap | plays_window | 5 | 4.8 | 5.0 | 4.0 | 6.0 | 56% |  |
| ash_phoenix | gold_end | 1000 | 1169.1 | 1068.6 | 625.9 | 1726.1 | 64% | runs |
| alpha_beast | peak | 30 | 66.2 | 47.0 | 20.0 | 88.0 | 76% |  |
| hunt_instinct | plays | 40 | 51.1 | 51.0 | 35.2 | 70.6 | 76% | acumulado |
| plague_carrion | peak | 40 | 74.5 | 50.0 | 26.4 | 97.0 | 76% | runs |
| life_drain | curses | 5 | 7.9 | 10.0 | 0.0 | 10.0 | 80% | runs |
| rat_tide | plays_same | 40 | 49.9 | 48.0 | 36.6 | 62.0 | 80% | runs |
| bat_cloud | peak | 12 | 67.4 | 47.0 | 20.4 | 93.6 | 100% | runs |
| ember_rain | plays | 25 | 51.1 | 51.0 | 35.2 | 70.6 | 100% | runs |
| magma_golem | peak | 10 | 74.5 | 50.0 | 26.4 | 97.0 | 100% | runs |
| rat_trap | peste | 5 | 14.8 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human_swarm|plague@3 (n=25, vitória 24%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 0.4 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 69.6 | 65.0 | 32.4 | 115.0 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 18.0 | 13.0 | 0.0 | 35.6 | 0% | acumulado |
| furnace | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 1.5 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| primal_beast | plays | 600 | 205.1 | 200.0 | 142.4 | 272.6 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 69.6 | 65.0 | 32.4 | 115.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| soul_storm | spells_distinct | 6 | 4.0 | 4.0 | 4.0 | 4.6 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| tar_net | gold_spent | 2000 | 907.0 | 860.0 | 665.0 | 1221.0 | 0% | acumulado |
| eternal_army | peak | 12 | 1.5 | 0.0 | 0.0 | 0.0 | 4% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| ogre | plays | 600 | 350.5 | 334.0 | 245.4 | 471.2 | 4% | acumulado |
| shadow_mark | plays | 1000 | 481.3 | 450.0 | 343.4 | 661.8 | 4% | acumulado |
| arcane_apocalypse | plays_window | 7 | 3.8 | 4.0 | 3.0 | 5.0 | 8% |  |
| gold_avalanche | gold_earned | 6000 | 4366.2 | 4303.8 | 3185.3 | 5556.9 | 8% | acumulado |
| mimic | plays | 60 | 43.2 | 42.0 | 20.0 | 71.2 | 16% | acumulado |
| blood_tax | plays | 100 | 69.6 | 65.0 | 32.4 | 115.0 | 20% | acumulado |
| molten_gold | elixir_spent | 2000 | 1682.0 | 1534.0 | 1121.2 | 2234.6 | 20% | acumulado |
| cave_troll | win_phase | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 24% |  |
| spitting_viper | plays | 150 | 119.7 | 102.0 | 79.2 | 199.2 | 24% | acumulado |
| bat_nest | peak | 3 | 2.1 | 2.0 | 1.0 | 3.0 | 36% | runs |
| pack_den | plays | 40 | 43.2 | 42.0 | 20.0 | 71.2 | 56% | acumulado |
| hollow_armor | elixir_max | 20 | 21.9 | 20.0 | 17.0 | 25.2 | 60% | runs |
| spike_trap | plays_window | 5 | 5.5 | 5.0 | 4.0 | 7.6 | 64% |  |
| bone_colossus | died | 3000 | 3508.4 | 3406.0 | 2349.0 | 4791.2 | 68% | acumulado |
| flooded_pit | plays | 5 | 18.0 | 13.0 | 0.0 | 35.6 | 76% | runs |
| life_drain | curses | 5 | 7.6 | 10.0 | 0.8 | 10.0 | 76% | runs |
| soul_collector | burst | 2000 | 3670.5 | 3437.8 | 1750.1 | 5838.5 | 76% |  |
| hunt_instinct | plays | 40 | 69.6 | 65.0 | 32.4 | 115.0 | 80% | acumulado |
| corrupt_piper | died | 2000 | 2934.0 | 2851.0 | 1759.8 | 4217.0 | 84% | acumulado |
| mother_nest | peak_on_spell | 20 | 135.4 | 55.0 | 20.4 | 359.2 | 88% | runs |
| alpha_beast | peak | 30 | 151.1 | 83.0 | 54.8 | 354.0 | 92% |  |
| plague_carrion | peak | 40 | 170.4 | 96.0 | 60.4 | 400.0 | 92% | runs |
| rat_tide | plays_same | 40 | 69.3 | 66.0 | 46.2 | 93.0 | 96% | runs |
| ash_phoenix | gold_end | 1000 | 3458.9 | 3432.9 | 2314.3 | 4607.4 | 100% | runs |
| bat_cloud | peak | 12 | 153.8 | 83.0 | 55.2 | 359.2 | 100% | runs |
| ember_rain | plays | 25 | 69.6 | 65.0 | 32.4 | 115.0 | 100% | runs |
| magma_golem | peak | 10 | 170.4 | 96.0 | 60.4 | 400.0 | 100% | runs |
| rat_trap | peste | 5 | 14.8 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human|dragon (n=25, vitória 28%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 80.0 | 77.0 | 60.0 | 110.4 | 0% | acumulado |
| bone_colossus | died | 3000 | 500.8 | 488.0 | 340.6 | 684.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.9 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.9 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 37.8 | 33.0 | 0.0 | 65.4 | 0% | acumulado |
| furnace | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| mimic | plays | 60 | 26.4 | 22.0 | 16.4 | 40.4 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1006.4 | 1001.0 | 798.6 | 1142.2 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 204.1 | 206.0 | 149.6 | 250.0 | 0% | acumulado |
| plague_carrion | peak | 40 | 14.4 | 14.0 | 10.0 | 20.2 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 350.0 | 350.0 | 262.8 | 417.8 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 80.0 | 77.0 | 60.0 | 110.4 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 53.2 | 52.0 | 32.8 | 78.6 | 4% | acumulado |
| soul_collector | burst | 2000 | 1245.4 | 1177.0 | 919.3 | 1689.3 | 4% |  |
| tar_net | gold_spent | 2000 | 989.4 | 840.0 | 528.0 | 1640.0 | 4% | acumulado |
| gold_avalanche | gold_earned | 6000 | 4228.4 | 3443.6 | 2289.6 | 6051.8 | 12% | acumulado |
| gold_bait | coins | 25 | 18.6 | 18.0 | 14.0 | 24.6 | 12% | acumulado |
| pack_den | plays | 40 | 26.4 | 22.0 | 16.4 | 40.4 | 12% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.3 | 5.0 | 4.0 | 7.0 | 16% |  |
| soul_storm | spells_distinct | 6 | 4.8 | 5.0 | 4.0 | 6.0 | 16% |  |
| bat_nest | peak | 3 | 2.2 | 2.0 | 1.4 | 3.6 | 24% | runs |
| hollow_armor | elixir_max | 20 | 18.1 | 17.0 | 14.4 | 23.6 | 24% | runs |
| blood_tax | plays | 100 | 80.0 | 77.0 | 60.0 | 110.4 | 28% | acumulado |
| cave_troll | win_phase | 1 | 0.3 | 0.0 | 0.0 | 1.0 | 28% |  |
| ash_phoenix | gold_end | 1000 | 1038.7 | 741.1 | 44.5 | 2214.2 | 36% | runs |
| burn_village | burn_time | 150 | 129.1 | 110.8 | 40.8 | 244.3 | 40% | acumulado |
| elder_dragon | peak | 5 | 4.6 | 4.0 | 3.0 | 5.6 | 44% |  |
| dragon_exchange | soak_ignite | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 76% |  |
| flooded_pit | plays | 5 | 37.8 | 33.0 | 0.0 | 65.4 | 84% | runs |
| spike_trap | plays_window | 5 | 5.4 | 5.0 | 4.0 | 6.6 | 84% |  |
| boiling_oil | soaked_time | 75 | 171.5 | 156.2 | 76.8 | 294.5 | 88% | acumulado |
| rat_tide | plays_same | 40 | 51.3 | 50.0 | 36.8 | 65.2 | 88% | runs |
| life_drain | curses | 5 | 8.8 | 10.0 | 6.0 | 10.0 | 92% | runs |
| hunt_instinct | plays | 40 | 80.0 | 77.0 | 60.0 | 110.4 | 96% | acumulado |
| magma_golem | peak | 10 | 14.4 | 14.0 | 10.0 | 20.2 | 96% | runs |
| ember_rain | plays | 25 | 80.0 | 77.0 | 60.0 | 110.4 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human|dragon@3 (n=25, vitória 12%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 0.5 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| black_pestilence | plays | 150 | 83.9 | 79.0 | 67.0 | 106.8 | 0% | acumulado |
| bone_colossus | died | 3000 | 510.9 | 474.0 | 374.0 | 692.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 4.8 | 4.0 | 4.0 | 6.6 | 0% | acumulado |
| bone_totem | wins | 2 | 0.1 | 0.0 | 0.0 | 0.6 | 0% |  |
| brown_bear | heroes | 20 | 4.8 | 4.0 | 4.0 | 6.6 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 63.4 | 58.0 | 23.6 | 113.0 | 0% | acumulado |
| furnace | wins | 2 | 0.1 | 0.0 | 0.0 | 0.6 | 0% |  |
| ghost | peak | 40 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| meteor_storm | plays | 80 | 49.8 | 49.0 | 32.2 | 64.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 213.0 | 202.0 | 152.4 | 293.2 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.1 | 0.0 | 0.0 | 0.6 | 0% |  |
| shadow_echo | plays_window | 5 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 393.2 | 372.0 | 290.4 | 526.6 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 83.9 | 79.0 | 67.0 | 106.8 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.0 | 5.0 | 4.0 | 6.0 | 4% |  |
| mimic | plays | 60 | 31.3 | 30.0 | 13.6 | 45.8 | 4% | acumulado |
| molten_gold | elixir_spent | 2000 | 1207.9 | 1123.0 | 868.6 | 1602.0 | 4% | acumulado |
| tar_net | gold_spent | 2000 | 1254.2 | 1240.0 | 805.0 | 1661.0 | 4% | acumulado |
| fallen_healer | loss_max | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| plague_carrion | peak | 40 | 19.4 | 16.0 | 12.0 | 26.0 | 8% | runs |
| burn_village | burn_time | 150 | 101.7 | 60.3 | 33.1 | 248.8 | 12% | acumulado |
| cave_troll | win_phase | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% |  |
| blood_tax | plays | 100 | 83.9 | 79.0 | 67.0 | 106.8 | 16% | acumulado |
| gold_bait | coins | 25 | 18.0 | 16.0 | 10.0 | 29.0 | 16% | acumulado |
| soul_storm | spells_distinct | 6 | 4.8 | 5.0 | 4.0 | 6.0 | 20% |  |
| pack_den | plays | 40 | 31.3 | 30.0 | 13.6 | 45.8 | 24% | acumulado |
| soul_collector | burst | 2000 | 2082.7 | 1867.9 | 1369.2 | 3072.2 | 40% |  |
| elder_dragon | peak | 5 | 5.3 | 4.0 | 3.0 | 5.0 | 44% |  |
| hollow_armor | elixir_max | 20 | 19.6 | 20.0 | 15.4 | 23.6 | 52% | runs |
| dragon_exchange | soak_ignite | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 68% |  |
| bat_nest | peak | 3 | 3.8 | 3.0 | 2.0 | 5.6 | 76% | runs |
| spike_trap | plays_window | 5 | 5.4 | 5.0 | 4.0 | 7.0 | 76% |  |
| boiling_oil | soaked_time | 75 | 130.9 | 125.0 | 69.7 | 202.7 | 80% | acumulado |
| gold_avalanche | gold_earned | 6000 | 11020.5 | 9894.4 | 5040.6 | 17968.5 | 80% | acumulado |
| ash_phoenix | gold_end | 1000 | 4657.7 | 3012.1 | 759.6 | 11226.8 | 88% | runs |
| rat_tide | plays_same | 40 | 50.5 | 46.0 | 38.6 | 63.0 | 88% | runs |
| flooded_pit | plays | 5 | 63.4 | 58.0 | 23.6 | 113.0 | 96% | runs |
| ember_rain | plays | 25 | 83.9 | 79.0 | 67.0 | 106.8 | 100% | runs |
| hunt_instinct | plays | 40 | 83.9 | 79.0 | 67.0 | 106.8 | 100% | acumulado |
| life_drain | curses | 5 | 9.4 | 10.0 | 8.0 | 10.0 | 100% | runs |
| magma_golem | peak | 10 | 19.4 | 16.0 | 12.0 | 26.0 | 100% | runs |
| spark | soak_ignite | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% | runs |

## human|lich (n=25, vitória 68%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 883.0 | 877.0 | 631.0 | 1171.8 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.5 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.5 | 7.0 | 5.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 60.6 | 63.0 | 19.0 | 102.8 | 0% | acumulado |
| furnace | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 1895.8 | 1978.3 | 1196.6 | 2344.9 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 961.3 | 913.0 | 756.4 | 1237.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 198.0 | 184.0 | 151.4 | 256.4 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.7 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 503.9 | 485.0 | 384.8 | 663.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 227.1 | 216.0 | 165.0 | 309.8 | 0% | acumulado |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 795.6 | 745.0 | 470.0 | 1259.0 | 0% | acumulado |
| mimic | plays | 60 | 18.2 | 16.0 | 0.0 | 38.2 | 4% | acumulado |
| ghost | peak | 40 | 20.4 | 16.0 | 11.4 | 22.0 | 8% | runs |
| eruption | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% |  |
| pack_den | plays | 40 | 18.2 | 16.0 | 0.0 | 38.2 | 12% | acumulado |
| soul_harvest | win_without | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% | runs |
| plague_carrion | peak | 40 | 36.6 | 24.0 | 17.8 | 54.8 | 16% | runs |
| bat_nest | peak | 3 | 1.7 | 2.0 | 0.0 | 3.0 | 20% | runs |
| arcane_spark | plays | 120 | 101.1 | 95.0 | 69.0 | 138.6 | 24% | acumulado |
| burn_village | burn_time | 150 | 131.9 | 135.2 | 49.5 | 184.2 | 32% | acumulado |
| life_drain | curses | 5 | 4.9 | 2.0 | 0.0 | 10.0 | 44% | runs |
| hollow_armor | elixir_max | 20 | 22.2 | 21.0 | 16.0 | 30.0 | 56% | runs |
| ash_phoenix | gold_end | 1000 | 1100.2 | 1091.5 | 595.2 | 1727.0 | 60% | runs |
| shadow_echo | plays_window | 5 | 4.9 | 5.0 | 4.0 | 6.0 | 60% |  |
| cave_troll | win_phase | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 68% |  |
| soul_collector | burst | 2000 | 3885.7 | 3923.5 | 1353.5 | 5737.0 | 72% |  |
| soul_storm | spells_distinct | 6 | 6.1 | 6.0 | 5.0 | 7.0 | 76% |  |
| eternal_army | peak | 12 | 20.5 | 16.0 | 11.4 | 23.2 | 88% | runs |
| rat_tide | plays_same | 40 | 58.1 | 61.0 | 38.2 | 79.6 | 88% | runs |
| arcane_apocalypse | plays_window | 7 | 11.9 | 12.0 | 9.4 | 15.0 | 100% |  |
| black_pestilence | plays | 150 | 227.1 | 216.0 | 165.0 | 309.8 | 100% | acumulado |
| blood_tax | plays | 100 | 227.1 | 216.0 | 165.0 | 309.8 | 100% | acumulado |
| ember_rain | plays | 25 | 227.1 | 216.0 | 165.0 | 309.8 | 100% | runs |
| flooded_pit | plays | 5 | 60.6 | 63.0 | 19.0 | 102.8 | 100% | runs |
| hunt_instinct | plays | 40 | 227.1 | 216.0 | 165.0 | 309.8 | 100% | acumulado |
| magma_golem | peak | 10 | 36.6 | 24.0 | 17.8 | 54.8 | 100% | runs |
| spike_trap | plays_window | 5 | 8.4 | 9.0 | 7.0 | 9.6 | 100% |  |

## human|lich@3 (n=25, vitória 56%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1160.4 | 1113.0 | 773.4 | 1641.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.0 | 7.0 | 3.4 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.0 | 7.0 | 3.4 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 84.5 | 84.0 | 40.8 | 125.2 | 0% | acumulado |
| furnace | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1270.6 | 1285.0 | 973.6 | 1530.8 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 241.5 | 255.0 | 159.0 | 316.0 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.6 | 1.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 660.7 | 649.0 | 500.0 | 850.4 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 960.2 | 910.0 | 618.0 | 1325.0 | 0% | acumulado |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| gold_avalanche | gold_earned | 6000 | 4005.3 | 4177.4 | 2703.0 | 4830.5 | 4% | acumulado |
| mimic | plays | 60 | 18.0 | 13.0 | 0.0 | 41.0 | 8% | acumulado |
| pack_den | plays | 40 | 18.0 | 13.0 | 0.0 | 41.0 | 12% | acumulado |
| soul_feast | plays | 400 | 316.7 | 318.0 | 234.4 | 412.0 | 12% | acumulado |
| ghost | peak | 40 | 27.4 | 19.0 | 12.0 | 54.2 | 16% | runs |
| eruption | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 20% |  |
| soul_harvest | win_without | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 20% | runs |
| bat_nest | peak | 3 | 2.4 | 2.0 | 0.0 | 5.0 | 40% | runs |
| plague_carrion | peak | 40 | 54.4 | 41.0 | 22.4 | 71.4 | 52% | runs |
| burn_village | burn_time | 150 | 185.5 | 164.8 | 104.9 | 248.7 | 56% | acumulado |
| cave_troll | win_phase | 1 | 0.6 | 1.0 | 0.0 | 1.0 | 56% |  |
| hollow_armor | elixir_max | 20 | 24.0 | 22.0 | 16.4 | 35.6 | 64% | runs |
| life_drain | curses | 5 | 6.8 | 10.0 | 0.0 | 10.0 | 68% | runs |
| arcane_spark | plays | 120 | 158.6 | 157.0 | 123.2 | 205.0 | 92% | acumulado |
| shadow_echo | plays_window | 5 | 6.3 | 6.0 | 5.0 | 8.0 | 92% |  |
| eternal_army | peak | 12 | 27.7 | 20.0 | 12.0 | 55.4 | 96% | runs |
| soul_storm | spells_distinct | 6 | 6.5 | 7.0 | 6.0 | 7.0 | 96% |  |
| arcane_apocalypse | plays_window | 7 | 13.9 | 14.0 | 10.4 | 16.0 | 100% |  |
| ash_phoenix | gold_end | 1000 | 3045.0 | 3157.1 | 1831.8 | 4036.5 | 100% | runs |
| black_pestilence | plays | 150 | 316.7 | 318.0 | 234.4 | 412.0 | 100% | acumulado |
| blood_tax | plays | 100 | 316.7 | 318.0 | 234.4 | 412.0 | 100% | acumulado |
| ember_rain | plays | 25 | 316.7 | 318.0 | 234.4 | 412.0 | 100% | runs |
| flooded_pit | plays | 5 | 84.5 | 84.0 | 40.8 | 125.2 | 100% | runs |
| hunt_instinct | plays | 40 | 316.7 | 318.0 | 234.4 | 412.0 | 100% | acumulado |
| magma_golem | peak | 10 | 54.4 | 41.0 | 22.4 | 71.4 | 100% | runs |
| rat_tide | plays_same | 40 | 68.9 | 68.0 | 45.8 | 90.4 | 100% | runs |
| soul_collector | burst | 2000 | 6825.3 | 6040.2 | 3268.2 | 11222.0 | 100% |  |
| spike_trap | plays_window | 5 | 9.4 | 9.0 | 7.0 | 12.2 | 100% |  |

## human|plague (n=25, vitória 44%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 49.0 | 44.0 | 29.2 | 70.8 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 6.2 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 6.2 | 6.0 | 5.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 3.5 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.4 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 13.4 | 11.0 | 0.0 | 32.4 | 0% | acumulado |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.4 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 2042.8 | 1934.2 | 1478.7 | 2904.1 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1077.4 | 1096.0 | 665.4 | 1389.2 | 0% | acumulado |
| ogre | plays | 600 | 239.2 | 239.0 | 182.4 | 292.6 | 0% | acumulado |
| primal_beast | plays | 600 | 133.8 | 135.0 | 103.2 | 169.4 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 329.4 | 333.0 | 241.6 | 412.8 | 0% | acumulado |
| soul_feast | plays | 400 | 49.0 | 44.0 | 29.2 | 70.8 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 83.9 | 80.0 | 55.8 | 113.2 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 772.2 | 815.0 | 541.0 | 952.0 | 0% | acumulado |
| arcane_apocalypse | plays_window | 7 | 3.5 | 3.0 | 3.0 | 4.6 | 4% |  |
| blood_tax | plays | 100 | 49.0 | 44.0 | 29.2 | 70.8 | 4% | acumulado |
| mimic | plays | 60 | 27.8 | 24.0 | 11.8 | 51.2 | 4% | acumulado |
| bone_colossus | died | 3000 | 2039.0 | 1990.0 | 1175.2 | 2876.8 | 8% | acumulado |
| soul_storm | spells_distinct | 6 | 4.2 | 4.0 | 4.0 | 5.0 | 8% |  |
| pack_den | plays | 40 | 27.8 | 24.0 | 11.8 | 51.2 | 24% | acumulado |
| corrupt_piper | died | 2000 | 1632.4 | 1527.0 | 881.4 | 2419.8 | 28% | acumulado |
| soul_collector | burst | 2000 | 1961.3 | 1484.3 | 1014.4 | 2542.4 | 28% |  |
| bat_nest | peak | 3 | 1.9 | 2.0 | 1.0 | 3.0 | 32% | runs |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 44% |  |
| hollow_armor | elixir_max | 20 | 20.5 | 19.0 | 16.0 | 29.0 | 48% | runs |
| flooded_pit | plays | 5 | 13.4 | 11.0 | 0.0 | 32.4 | 56% | runs |
| spike_trap | plays_window | 5 | 5.0 | 5.0 | 4.0 | 6.6 | 56% |  |
| ash_phoenix | gold_end | 1000 | 1270.6 | 1210.5 | 561.1 | 2009.6 | 60% | runs |
| hunt_instinct | plays | 40 | 49.0 | 44.0 | 29.2 | 70.8 | 64% | acumulado |
| rat_tide | plays_same | 40 | 48.5 | 48.0 | 32.0 | 70.4 | 72% | runs |
| life_drain | curses | 5 | 7.5 | 10.0 | 0.0 | 10.0 | 76% | runs |
| mother_nest | peak_on_spell | 20 | 58.8 | 30.0 | 15.8 | 103.8 | 80% | runs |
| plague_carrion | peak | 40 | 98.5 | 58.0 | 36.6 | 284.0 | 84% | runs |
| alpha_beast | peak | 30 | 88.0 | 57.0 | 30.2 | 239.8 | 88% |  |
| ember_rain | plays | 25 | 49.0 | 44.0 | 29.2 | 70.8 | 96% | runs |
| bat_cloud | peak | 12 | 89.8 | 57.0 | 31.4 | 243.4 | 100% | runs |
| magma_golem | peak | 10 | 98.5 | 58.0 | 36.6 | 284.0 | 100% | runs |
| rat_trap | peste | 5 | 14.2 | 15.0 | 11.3 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## human|plague@3 (n=25, vitória 36%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_apocalypse | plays_window | 7 | 3.6 | 4.0 | 3.0 | 4.0 | 0% |  |
| arcane_spark | plays | 120 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| black_pestilence | plays | 150 | 60.1 | 58.0 | 37.2 | 88.2 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 5.8 | 6.0 | 4.0 | 7.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 20.0 | 11.0 | 0.0 | 50.4 | 0% | acumulado |
| furnace | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 0.6 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| ogre | plays | 600 | 331.0 | 318.0 | 254.6 | 437.0 | 0% | acumulado |
| primal_beast | plays | 600 | 176.8 | 185.0 | 122.6 | 221.4 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.4 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 449.8 | 432.0 | 347.4 | 630.6 | 0% | acumulado |
| soul_feast | plays | 400 | 60.1 | 58.0 | 37.2 | 88.2 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| tar_net | gold_spent | 2000 | 1002.5 | 985.0 | 655.0 | 1392.0 | 0% | acumulado |
| eternal_army | peak | 12 | 0.6 | 0.0 | 0.0 | 0.0 | 4% | runs |
| gold_avalanche | gold_earned | 6000 | 4087.8 | 4170.5 | 2503.5 | 5709.4 | 4% | acumulado |
| soul_storm | spells_distinct | 6 | 4.3 | 4.0 | 4.0 | 5.0 | 4% |  |
| blood_tax | plays | 100 | 60.1 | 58.0 | 37.2 | 88.2 | 8% | acumulado |
| mimic | plays | 60 | 38.7 | 37.0 | 24.4 | 58.2 | 8% | acumulado |
| molten_gold | elixir_spent | 2000 | 1597.4 | 1648.0 | 1152.2 | 2028.4 | 12% | acumulado |
| spitting_viper | plays | 150 | 111.3 | 104.0 | 69.2 | 163.6 | 16% | acumulado |
| bat_nest | peak | 3 | 2.2 | 2.0 | 1.0 | 3.0 | 28% | runs |
| cave_troll | win_phase | 1 | 0.4 | 0.0 | 0.0 | 1.0 | 36% |  |
| pack_den | plays | 40 | 38.7 | 37.0 | 24.4 | 58.2 | 36% | acumulado |
| bone_colossus | died | 3000 | 2983.8 | 2924.0 | 2175.6 | 3678.8 | 44% | acumulado |
| flooded_pit | plays | 5 | 20.0 | 11.0 | 0.0 | 50.4 | 64% | runs |
| hollow_armor | elixir_max | 20 | 21.8 | 22.0 | 15.8 | 27.0 | 72% | runs |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 7.0 | 72% |  |
| corrupt_piper | died | 2000 | 2431.9 | 2394.0 | 1688.4 | 3122.6 | 84% | acumulado |
| hunt_instinct | plays | 40 | 60.1 | 58.0 | 37.2 | 88.2 | 84% | acumulado |
| soul_collector | burst | 2000 | 3506.0 | 2771.0 | 1904.1 | 6768.1 | 84% |  |
| life_drain | curses | 5 | 8.7 | 10.0 | 3.6 | 10.0 | 88% | runs |
| mother_nest | peak_on_spell | 20 | 109.1 | 49.0 | 18.6 | 332.2 | 88% | runs |
| alpha_beast | peak | 30 | 139.8 | 77.0 | 45.0 | 343.8 | 96% |  |
| plague_carrion | peak | 40 | 161.5 | 85.0 | 48.8 | 400.0 | 96% | runs |
| rat_tide | plays_same | 40 | 64.4 | 61.0 | 46.6 | 86.0 | 96% | runs |
| ash_phoenix | gold_end | 1000 | 3085.2 | 2921.5 | 1409.9 | 4619.6 | 100% | runs |
| bat_cloud | peak | 12 | 142.7 | 77.0 | 46.2 | 348.2 | 100% | runs |
| ember_rain | plays | 25 | 60.1 | 58.0 | 37.2 | 88.2 | 100% | runs |
| magma_golem | peak | 10 | 161.5 | 85.0 | 48.8 | 400.0 | 100% | runs |
| rat_trap | peste | 5 | 15.0 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |

## random|dragon (n=25, vitória 0%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 3.4 | 0.0 | 0.0 | 17.0 | 0% | acumulado |
| ash_phoenix | gold_end | 1000 | 95.4 | 29.5 | 12.4 | 173.1 | 0% | runs |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 396.3 | 395.0 | 187.8 | 553.4 | 0% | acumulado |
| bone_dragon | heroes | 35 | 3.8 | 4.0 | 3.0 | 5.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| brown_bear | heroes | 20 | 3.8 | 4.0 | 3.0 | 5.0 | 0% | acumulado |
| cave_troll | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 7.8 | 1.0 | 0.0 | 20.8 | 0% | acumulado |
| furnace | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| ghost | peak | 40 | 0.1 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1611.7 | 1460.6 | 832.5 | 2379.4 | 0% | acumulado |
| gold_bait | coins | 25 | 9.8 | 10.0 | 3.4 | 14.2 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 713.8 | 735.0 | 341.0 | 1107.4 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 160.2 | 158.0 | 80.2 | 234.6 | 0% | acumulado |
| plague_carrion | peak | 40 | 12.4 | 12.0 | 10.4 | 15.0 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.4 | 0.0 | 0.0 | 2.0 | 0% |  |
| shadow_mark | plays | 1000 | 308.7 | 319.0 | 152.6 | 448.8 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_collector | burst | 2000 | 866.1 | 823.4 | 620.5 | 1148.0 | 0% |  |
| soul_feast | plays | 400 | 110.5 | 113.0 | 57.2 | 166.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 28.8 | 27.0 | 9.2 | 47.0 | 4% | acumulado |
| tar_net | gold_spent | 2000 | 968.8 | 850.0 | 459.0 | 1533.0 | 4% | acumulado |
| hollow_armor | elixir_max | 20 | 13.9 | 13.0 | 11.0 | 17.6 | 8% | runs |
| burn_village | burn_time | 150 | 51.9 | 23.0 | 0.0 | 157.2 | 12% | acumulado |
| dragon_exchange | soak_ignite | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 16% |  |
| black_pestilence | plays | 150 | 110.5 | 113.0 | 57.2 | 166.0 | 20% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.8 | 5.0 | 4.4 | 8.0 | 24% |  |
| elder_dragon | peak | 5 | 3.6 | 3.0 | 2.4 | 5.0 | 24% |  |
| pack_den | plays | 40 | 28.8 | 27.0 | 9.2 | 47.0 | 24% | acumulado |
| bat_nest | peak | 3 | 2.8 | 2.0 | 2.0 | 4.6 | 40% | runs |
| flooded_pit | plays | 5 | 7.8 | 1.0 | 0.0 | 20.8 | 40% | runs |
| meteor_storm | plays | 80 | 75.5 | 76.0 | 35.4 | 109.6 | 48% | acumulado |
| blood_tax | plays | 100 | 110.5 | 113.0 | 57.2 | 166.0 | 52% | acumulado |
| rat_tide | plays_same | 40 | 40.0 | 41.0 | 20.4 | 58.0 | 52% | runs |
| soul_storm | spells_distinct | 6 | 5.9 | 6.0 | 5.0 | 7.0 | 60% |  |
| spike_trap | plays_window | 5 | 4.9 | 5.0 | 4.0 | 6.0 | 60% |  |
| spark | soak_ignite | 1 | 0.7 | 1.0 | 0.0 | 1.0 | 72% | runs |
| life_drain | curses | 5 | 8.3 | 10.0 | 4.8 | 10.0 | 88% | runs |
| boiling_oil | soaked_time | 75 | 221.4 | 208.9 | 90.8 | 353.4 | 92% | acumulado |
| hunt_instinct | plays | 40 | 110.5 | 113.0 | 57.2 | 166.0 | 92% | acumulado |
| magma_golem | peak | 10 | 12.4 | 12.0 | 10.4 | 15.0 | 96% | runs |
| ember_rain | plays | 25 | 110.5 | 113.0 | 57.2 | 166.0 | 100% | runs |

## random|dragon@3 (n=25, vitória 0%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| arcane_spark | plays | 120 | 4.0 | 0.0 | 0.0 | 14.8 | 0% | acumulado |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| bone_colossus | died | 3000 | 538.0 | 504.0 | 380.4 | 766.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 2.7 | 2.0 | 1.0 | 4.6 | 0% | acumulado |
| bone_totem | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| brown_bear | heroes | 20 | 2.7 | 2.0 | 1.0 | 4.6 | 0% | acumulado |
| cave_troll | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 11.3 | 7.0 | 0.0 | 24.6 | 0% | acumulado |
| furnace | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| ghost | peak | 40 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| molten_gold | elixir_spent | 2000 | 879.2 | 832.0 | 630.2 | 1202.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 214.9 | 204.0 | 146.4 | 286.6 | 0% | acumulado |
| plague_carrion | peak | 40 | 15.8 | 16.0 | 12.0 | 19.0 | 0% | runs |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.5 | 0.0 | 0.0 | 1.6 | 0% |  |
| shadow_mark | plays | 1000 | 402.6 | 377.0 | 291.6 | 528.0 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_feast | plays | 400 | 132.1 | 122.0 | 94.0 | 185.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| gold_bait | coins | 25 | 12.8 | 13.0 | 6.8 | 18.0 | 4% | acumulado |
| hollow_armor | elixir_max | 20 | 13.7 | 13.0 | 11.0 | 18.0 | 4% | runs |
| gold_avalanche | gold_earned | 6000 | 3547.7 | 2490.6 | 1759.7 | 4811.5 | 8% | acumulado |
| mimic | plays | 60 | 39.9 | 31.0 | 20.4 | 57.0 | 8% | acumulado |
| ash_phoenix | gold_end | 1000 | 570.7 | 132.1 | 14.3 | 1299.9 | 12% | runs |
| burn_village | burn_time | 150 | 50.3 | 20.2 | 0.0 | 148.1 | 12% | acumulado |
| dragon_exchange | soak_ignite | 1 | 0.1 | 0.0 | 0.0 | 0.6 | 12% |  |
| soul_collector | burst | 2000 | 1464.0 | 1309.0 | 1052.1 | 2237.7 | 20% |  |
| arcane_apocalypse | plays_window | 7 | 5.7 | 5.0 | 4.4 | 7.6 | 24% |  |
| black_pestilence | plays | 150 | 132.1 | 122.0 | 94.0 | 185.6 | 24% | acumulado |
| tar_net | gold_spent | 2000 | 1773.6 | 1455.0 | 1011.4 | 2483.0 | 24% | acumulado |
| elder_dragon | peak | 5 | 4.0 | 4.0 | 3.0 | 5.0 | 28% |  |
| pack_den | plays | 40 | 39.9 | 31.0 | 20.4 | 57.0 | 40% | acumulado |
| soul_storm | spells_distinct | 6 | 5.6 | 5.0 | 4.0 | 7.6 | 48% |  |
| flooded_pit | plays | 5 | 11.3 | 7.0 | 0.0 | 24.6 | 56% | runs |
| meteor_storm | plays | 80 | 85.6 | 83.0 | 58.0 | 118.2 | 60% | acumulado |
| rat_tide | plays_same | 40 | 50.3 | 51.0 | 36.4 | 67.4 | 72% | runs |
| bat_nest | peak | 3 | 3.6 | 3.0 | 2.0 | 5.0 | 76% | runs |
| blood_tax | plays | 100 | 132.1 | 122.0 | 94.0 | 185.6 | 80% | acumulado |
| spark | soak_ignite | 1 | 0.8 | 1.0 | 0.0 | 1.0 | 80% | runs |
| spike_trap | plays_window | 5 | 5.2 | 5.0 | 4.0 | 6.0 | 80% |  |
| boiling_oil | soaked_time | 75 | 278.8 | 276.6 | 129.3 | 416.5 | 96% | acumulado |
| life_drain | curses | 5 | 9.4 | 10.0 | 6.8 | 10.0 | 96% | runs |
| ember_rain | plays | 25 | 132.1 | 122.0 | 94.0 | 185.6 | 100% | runs |
| hunt_instinct | plays | 40 | 132.1 | 122.0 | 94.0 | 185.6 | 100% | acumulado |
| magma_golem | peak | 10 | 15.8 | 16.0 | 12.0 | 19.0 | 100% | runs |

## random|lich (n=25, vitória 24%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1042.7 | 1086.0 | 668.0 | 1455.4 | 0% | acumulado |
| bone_dragon | heroes | 35 | 4.8 | 4.0 | 3.0 | 7.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| brown_bear | heroes | 20 | 4.8 | 4.0 | 3.0 | 7.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 13.9 | 3.0 | 0.0 | 35.4 | 0% | acumulado |
| furnace | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| ghost | peak | 40 | 13.0 | 12.0 | 9.0 | 19.6 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1376.4 | 1356.0 | 728.7 | 2117.3 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| mimic | plays | 60 | 15.6 | 15.0 | 0.0 | 33.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 941.6 | 945.0 | 614.0 | 1250.4 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 276.2 | 277.0 | 185.2 | 370.4 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.2 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 624.6 | 669.0 | 432.4 | 791.2 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 437.4 | 425.0 | 100.0 | 694.0 | 0% | acumulado |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% | runs |
| pack_den | plays | 40 | 15.6 | 15.0 | 0.0 | 33.0 | 8% | acumulado |
| plague_carrion | peak | 40 | 20.5 | 18.0 | 11.0 | 33.4 | 8% | runs |
| soul_feast | plays | 400 | 318.8 | 338.0 | 200.8 | 407.2 | 16% | acumulado |
| hollow_armor | elixir_max | 20 | 16.1 | 14.0 | 10.8 | 22.2 | 20% | runs |
| cave_troll | win_phase | 1 | 0.2 | 0.0 | 0.0 | 1.0 | 24% |  |
| soul_collector | burst | 2000 | 1598.8 | 1520.3 | 676.6 | 2678.6 | 32% |  |
| bat_nest | peak | 3 | 2.4 | 2.0 | 0.4 | 3.6 | 36% | runs |
| ash_phoenix | gold_end | 1000 | 939.0 | 946.4 | 296.6 | 1549.9 | 44% | runs |
| flooded_pit | plays | 5 | 13.9 | 3.0 | 0.0 | 35.4 | 48% | runs |
| life_drain | curses | 5 | 5.3 | 6.0 | 0.0 | 10.0 | 60% | runs |
| eternal_army | peak | 12 | 13.7 | 13.0 | 9.0 | 20.6 | 64% | runs |
| shadow_echo | plays_window | 5 | 5.4 | 5.0 | 4.0 | 7.0 | 68% |  |
| burn_village | burn_time | 150 | 202.0 | 170.4 | 126.2 | 302.6 | 72% | acumulado |
| arcane_spark | plays | 120 | 154.5 | 153.0 | 112.6 | 205.2 | 88% | acumulado |
| arcane_apocalypse | plays_window | 7 | 10.8 | 10.0 | 8.0 | 13.6 | 96% |  |
| black_pestilence | plays | 150 | 318.8 | 338.0 | 200.8 | 407.2 | 100% | acumulado |
| blood_tax | plays | 100 | 318.8 | 338.0 | 200.8 | 407.2 | 100% | acumulado |
| ember_rain | plays | 25 | 318.8 | 338.0 | 200.8 | 407.2 | 100% | runs |
| hunt_instinct | plays | 40 | 318.8 | 338.0 | 200.8 | 407.2 | 100% | acumulado |
| magma_golem | peak | 10 | 20.5 | 18.0 | 11.0 | 33.4 | 100% | runs |
| rat_tide | plays_same | 40 | 105.0 | 111.0 | 76.0 | 139.4 | 100% | runs |
| soul_storm | spells_distinct | 6 | 8.6 | 9.0 | 7.0 | 10.0 | 100% |  |
| spike_trap | plays_window | 5 | 7.1 | 7.0 | 5.4 | 9.0 | 100% |  |

## random|lich@3 (n=25, vitória 8%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| alpha_beast | peak | 30 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| bat_cloud | peak | 12 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1245.2 | 1103.0 | 898.0 | 1599.6 | 0% | acumulado |
| bone_dragon | heroes | 35 | 4.0 | 4.0 | 2.0 | 6.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| brown_bear | heroes | 20 | 4.0 | 4.0 | 2.0 | 6.0 | 0% | acumulado |
| corrupt_piper | died | 2000 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 17.3 | 15.0 | 0.0 | 32.6 | 0% | acumulado |
| furnace | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| gold_avalanche | gold_earned | 6000 | 2593.2 | 2301.8 | 1546.7 | 3836.8 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 1175.4 | 1137.0 | 909.8 | 1547.0 | 0% | acumulado |
| mother_nest | peak_on_spell | 20 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ogre | plays | 600 | 324.1 | 331.0 | 245.4 | 401.4 | 0% | acumulado |
| primal_beast | plays | 600 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| rat_trap | peste | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_mark | plays | 1000 | 724.3 | 711.0 | 543.2 | 893.8 | 0% | acumulado |
| slime | peak_multi | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 605.8 | 595.0 | 102.0 | 1122.0 | 0% | acumulado |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| cave_troll | win_phase | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| ghost | peak | 40 | 18.9 | 17.0 | 10.4 | 31.0 | 8% | runs |
| hollow_armor | elixir_max | 20 | 15.2 | 15.0 | 12.0 | 18.6 | 8% | runs |
| mimic | plays | 60 | 43.2 | 36.0 | 10.4 | 89.2 | 28% | acumulado |
| plague_carrion | peak | 40 | 31.8 | 27.0 | 19.4 | 53.6 | 28% | runs |
| soul_feast | plays | 400 | 339.7 | 324.0 | 259.8 | 451.6 | 28% | acumulado |
| pack_den | plays | 40 | 43.2 | 36.0 | 10.4 | 89.2 | 44% | acumulado |
| shadow_echo | plays_window | 5 | 4.8 | 4.0 | 4.0 | 6.0 | 48% |  |
| soul_collector | burst | 2000 | 3878.3 | 2377.3 | 1230.2 | 8229.3 | 56% |  |
| flooded_pit | plays | 5 | 17.3 | 15.0 | 0.0 | 32.6 | 64% | runs |
| bat_nest | peak | 3 | 4.3 | 4.0 | 1.4 | 8.0 | 68% | runs |
| life_drain | curses | 5 | 7.9 | 10.0 | 0.8 | 10.0 | 80% | runs |
| burn_village | burn_time | 150 | 237.9 | 201.9 | 119.2 | 406.5 | 84% | acumulado |
| arcane_spark | plays | 120 | 163.1 | 163.0 | 118.6 | 219.4 | 88% | acumulado |
| eternal_army | peak | 12 | 19.8 | 18.0 | 11.4 | 31.6 | 88% | runs |
| ash_phoenix | gold_end | 1000 | 1987.3 | 1810.8 | 1061.4 | 3267.5 | 92% | runs |
| arcane_apocalypse | plays_window | 7 | 10.4 | 10.0 | 8.4 | 12.0 | 100% |  |
| black_pestilence | plays | 150 | 339.7 | 324.0 | 259.8 | 451.6 | 100% | acumulado |
| blood_tax | plays | 100 | 339.7 | 324.0 | 259.8 | 451.6 | 100% | acumulado |
| ember_rain | plays | 25 | 339.7 | 324.0 | 259.8 | 451.6 | 100% | runs |
| hunt_instinct | plays | 40 | 339.7 | 324.0 | 259.8 | 451.6 | 100% | acumulado |
| magma_golem | peak | 10 | 31.8 | 27.0 | 19.4 | 53.6 | 100% | runs |
| rat_tide | plays_same | 40 | 119.4 | 115.0 | 92.4 | 155.2 | 100% | runs |
| soul_storm | spells_distinct | 6 | 8.4 | 8.0 | 6.4 | 11.0 | 100% |  |
| spike_trap | plays_window | 5 | 7.2 | 7.0 | 6.0 | 8.6 | 100% |  |

## random|plague (n=25, vitória 8%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 4.8 | 0.0 | 0.0 | 17.6 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1242.3 | 1212.0 | 855.8 | 1607.2 | 0% | acumulado |
| bone_dragon | heroes | 35 | 4.3 | 4.0 | 3.0 | 6.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| brown_bear | heroes | 20 | 4.3 | 4.0 | 3.0 | 6.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 8.1 | 0.0 | 0.0 | 33.3 | 0% | acumulado |
| corrupt_piper | died | 2000 | 830.7 | 787.0 | 597.6 | 1089.2 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eternal_army | peak | 12 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| forbidden_library | plays | 200 | 2.5 | 0.0 | 0.0 | 14.0 | 0% | acumulado |
| furnace | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| ghost | peak | 40 | 0.2 | 0.0 | 0.0 | 0.0 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 1260.4 | 1129.1 | 814.1 | 1727.8 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 899.2 | 884.0 | 593.2 | 1183.6 | 0% | acumulado |
| ogre | plays | 600 | 254.2 | 253.0 | 180.0 | 321.6 | 0% | acumulado |
| primal_beast | plays | 600 | 174.6 | 171.0 | 118.0 | 228.8 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.1 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.5 | 0.0 | 0.0 | 1.6 | 0% |  |
| shadow_mark | plays | 1000 | 409.2 | 411.0 | 264.8 | 528.8 | 0% | acumulado |
| soul_feast | plays | 400 | 123.8 | 123.0 | 76.4 | 174.0 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| tar_net | gold_spent | 2000 | 537.6 | 365.0 | 211.0 | 1119.0 | 0% | acumulado |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| mimic | plays | 60 | 28.7 | 24.0 | 13.4 | 51.2 | 4% | acumulado |
| spitting_viper | plays | 150 | 91.6 | 86.0 | 63.8 | 130.8 | 4% | acumulado |
| cave_troll | win_phase | 1 | 0.1 | 0.0 | 0.0 | 0.0 | 8% |  |
| hollow_armor | elixir_max | 20 | 14.0 | 13.0 | 11.0 | 18.6 | 8% | runs |
| plague_carrion | peak | 40 | 23.4 | 21.0 | 15.4 | 35.6 | 8% | runs |
| alpha_beast | peak | 30 | 19.4 | 17.0 | 14.0 | 29.4 | 12% |  |
| soul_collector | burst | 2000 | 1335.1 | 1283.0 | 733.0 | 2129.0 | 12% |  |
| arcane_apocalypse | plays_window | 7 | 5.2 | 5.0 | 3.0 | 7.6 | 16% |  |
| flooded_pit | plays | 5 | 2.5 | 0.0 | 0.0 | 14.0 | 16% | runs |
| mother_nest | peak_on_spell | 20 | 13.1 | 11.0 | 8.4 | 23.8 | 16% | runs |
| ash_phoenix | gold_end | 1000 | 722.8 | 637.8 | 379.5 | 1294.4 | 20% | runs |
| pack_den | plays | 40 | 28.7 | 24.0 | 13.4 | 51.2 | 20% | acumulado |
| black_pestilence | plays | 150 | 123.8 | 123.0 | 76.4 | 174.0 | 24% | acumulado |
| bat_nest | peak | 3 | 2.7 | 2.0 | 1.4 | 4.6 | 40% | runs |
| spike_trap | plays_window | 5 | 4.6 | 4.0 | 4.0 | 6.0 | 44% |  |
| soul_storm | spells_distinct | 6 | 5.7 | 6.0 | 4.4 | 7.0 | 60% |  |
| life_drain | curses | 5 | 6.6 | 10.0 | 0.0 | 10.0 | 68% | runs |
| blood_tax | plays | 100 | 123.8 | 123.0 | 76.4 | 174.0 | 72% | acumulado |
| rat_tide | plays_same | 40 | 57.6 | 55.0 | 36.8 | 77.0 | 80% | runs |
| slime | peak_multi | 1 | 0.9 | 1.0 | 1.0 | 1.0 | 92% |  |
| bat_cloud | peak | 12 | 19.8 | 18.0 | 14.0 | 29.8 | 100% | runs |
| ember_rain | plays | 25 | 123.8 | 123.0 | 76.4 | 174.0 | 100% | runs |
| hunt_instinct | plays | 40 | 123.8 | 123.0 | 76.4 | 174.0 | 100% | acumulado |
| magma_golem | peak | 10 | 23.4 | 21.0 | 15.4 | 35.6 | 100% | runs |
| rat_trap | peste | 5 | 14.3 | 15.0 | 14.0 | 15.0 | 100% | runs |

## random|plague@3 (n=25, vitória 4%)

| carta | tipo | meta | média | mediana | p10 | p90 | cumpre | obs |
|---|---|---|---|---|---|---|---|---|
| arcane_spark | plays | 120 | 3.4 | 0.0 | 0.0 | 12.0 | 0% | acumulado |
| boiling_oil | soaked_time | 75 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| bone_colossus | died | 3000 | 1354.9 | 1319.0 | 1029.2 | 1609.0 | 0% | acumulado |
| bone_dragon | heroes | 35 | 3.2 | 3.0 | 2.0 | 4.0 | 0% | acumulado |
| bone_totem | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| brown_bear | heroes | 20 | 3.2 | 3.0 | 2.0 | 4.0 | 0% | acumulado |
| burn_village | burn_time | 150 | 4.6 | 0.0 | 0.0 | 13.1 | 0% | acumulado |
| corrupt_piper | died | 2000 | 944.8 | 924.0 | 708.4 | 1157.6 | 0% | acumulado |
| devour | win_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| dragon_exchange | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| elder_dragon | peak | 5 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| eruption | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| forbidden_library | plays | 200 | 3.1 | 0.0 | 0.0 | 15.2 | 0% | acumulado |
| furnace | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| ghost | peak | 40 | 1.4 | 0.0 | 0.0 | 6.2 | 0% | runs |
| gold_avalanche | gold_earned | 6000 | 2282.5 | 2137.8 | 1555.1 | 3087.2 | 0% | acumulado |
| gold_bait | coins | 25 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| meteor_storm | plays | 80 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | acumulado |
| molten_gold | elixir_spent | 2000 | 955.2 | 903.0 | 798.2 | 1157.2 | 0% | acumulado |
| ogre | plays | 600 | 259.9 | 256.0 | 219.0 | 308.4 | 0% | acumulado |
| primal_beast | plays | 600 | 184.2 | 181.0 | 143.2 | 233.8 | 0% | acumulado |
| ruin_titan | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| sewer_flood | wins | 2 | 0.0 | 0.0 | 0.0 | 0.0 | 0% |  |
| shadow_echo | plays_window | 5 | 0.3 | 0.0 | 0.0 | 1.0 | 0% |  |
| shadow_mark | plays | 1000 | 427.0 | 410.0 | 335.2 | 559.6 | 0% | acumulado |
| soul_harvest | win_without | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spark | soak_ignite | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0% | runs |
| spitting_viper | plays | 150 | 94.8 | 96.0 | 69.8 | 126.8 | 0% | acumulado |
| tar_net | gold_spent | 2000 | 572.9 | 570.0 | 127.0 | 1126.0 | 0% | acumulado |
| cave_troll | win_phase | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| eternal_army | peak | 12 | 1.4 | 0.0 | 0.0 | 6.2 | 4% | runs |
| fallen_healer | loss_max | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 4% |  |
| hollow_armor | elixir_max | 20 | 14.2 | 14.0 | 11.0 | 16.6 | 4% | runs |
| soul_feast | plays | 400 | 128.5 | 113.0 | 79.2 | 193.8 | 4% | acumulado |
| mimic | plays | 60 | 35.6 | 34.0 | 12.6 | 59.6 | 12% | acumulado |
| black_pestilence | plays | 150 | 128.5 | 113.0 | 79.2 | 193.8 | 16% | acumulado |
| arcane_apocalypse | plays_window | 7 | 5.1 | 4.0 | 3.4 | 7.6 | 20% |  |
| flooded_pit | plays | 5 | 3.1 | 0.0 | 0.0 | 15.2 | 20% | runs |
| plague_carrion | peak | 40 | 30.7 | 26.0 | 19.0 | 51.2 | 20% | runs |
| alpha_beast | peak | 30 | 26.4 | 20.0 | 17.0 | 46.0 | 32% |  |
| mother_nest | peak_on_spell | 20 | 20.3 | 17.0 | 11.0 | 36.4 | 36% | runs |
| pack_den | plays | 40 | 35.6 | 34.0 | 12.6 | 59.6 | 36% | acumulado |
| soul_storm | spells_distinct | 6 | 5.4 | 5.0 | 4.0 | 7.0 | 40% |  |
| spike_trap | plays_window | 5 | 4.6 | 4.0 | 3.4 | 6.0 | 40% |  |
| soul_collector | burst | 2000 | 2047.8 | 1874.7 | 1212.8 | 2684.2 | 48% |  |
| bat_nest | peak | 3 | 3.4 | 3.0 | 1.4 | 6.6 | 56% | runs |
| blood_tax | plays | 100 | 128.5 | 113.0 | 79.2 | 193.8 | 68% | acumulado |
| life_drain | curses | 5 | 7.6 | 10.0 | 0.0 | 10.0 | 72% | runs |
| ash_phoenix | gold_end | 1000 | 1709.6 | 1674.5 | 881.2 | 2547.3 | 88% | runs |
| bat_cloud | peak | 12 | 27.3 | 21.0 | 17.4 | 47.8 | 100% | runs |
| ember_rain | plays | 25 | 128.5 | 113.0 | 79.2 | 193.8 | 100% | runs |
| hunt_instinct | plays | 40 | 128.5 | 113.0 | 79.2 | 193.8 | 100% | acumulado |
| magma_golem | peak | 10 | 30.7 | 26.0 | 19.0 | 51.2 | 100% | runs |
| rat_tide | plays_same | 40 | 58.5 | 57.0 | 44.2 | 67.0 | 100% | runs |
| rat_trap | peste | 5 | 15.0 | 15.0 | 15.0 | 15.0 | 100% | runs |
| slime | peak_multi | 1 | 1.0 | 1.0 | 1.0 | 1.0 | 100% |  |
