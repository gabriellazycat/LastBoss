# Relíquias de elixir — rodada 19/11/2026

Bot `heuristic`, vilão `plague`, 60 sementes (`reports/reliquias_antes.json`). Mudanças aplicadas nos dados: Cálice Transbordante vira comum; peso de sorteio das 9 relíquias de elixir passa a 1; a relíquia de elixir obrigatória do fim de ato foi removida.

## Taxa de escolha (estado atual, já com as mudanças)

O bot escolhe por `bot_value`, então a taxa mede o valor que o bot atribui, não o efeito real. Não há tabela "antes" por relíquia: o lote foi rodado só depois das mudanças de peso (a obrigatória do fim de ato já havia saído).

| Relíquia | Elixir | Raridade | bot_value | Ofertas | Escolhas | Taxa |
|---|---|---|---|---|---|---|
| still_aether | sim | rare | 5.5 | 15 | 15 | 100% |
| quick_spring | sim | common | 4.5 | 10 | 10 | 100% |
| rushing_tide | sim | uncommon | 4.5 | 13 | 12 | 92% |
| deep_cauldron | sim | uncommon | 4.5 | 10 | 9 | 90% |
| elixir_flask | sim | common | 4.5 | 9 | 8 | 89% |
| victory_mark |  | rare | 4.5 | 20 | 16 | 80% |
| deep_cistern | sim | uncommon | 4.5 | 9 | 7 | 78% |
| living_library |  | uncommon | 4.0 | 22 | 17 | 77% |
| watchful_eye |  | uncommon | 3.0 | 7 | 5 | 71% |
| heart_of_well | sim | rare | 4.5 | 10 | 7 | 70% |
| hanged_hand | sim | rare | 3.5 | 9 | 6 | 67% |
| tally_stick |  | uncommon | 3.0 | 8 | 5 | 62% |
| war_drum | sim | common | 2.5 | 8 | 5 | 62% |
| raider_pack |  | uncommon | 3.0 | 11 | 5 | 45% |
| overflowing_chalice | sim | common | 2.5 | 9 | 4 | 44% |
| fine_sand |  | uncommon | 3.0 | 12 | 5 | 42% |
| bronze_bell | sim | common | 2.5 | 16 | 6 | 38% |
| arcane_ink |  | rare | 3.0 | 11 | 3 | 27% |
| hand_pocket |  | rare | 3.0 | 15 | 4 | 27% |
| twin_litter |  | rare | 3.0 | 9 | 2 | 22% |
| torn_banner |  | common | 2.5 | 10 | 2 | 20% |
| tar_pit |  | uncommon | 2.5 | 11 | 2 | 18% |
| opening_gambit |  | uncommon | 2.5 | 11 | 2 | 18% |
| tinker_file |  | uncommon | 2.5 | 12 | 2 | 17% |
| blood_tithe |  | common | 2.0 | 8 | 1 | 12% |
| bad_blood |  | rare | 3.0 | 10 | 1 | 10% |
| lucky_coin |  | rare | 3.0 | 11 | 1 | 9% |
| frost_shard | sim | rare | 3.0 | 12 | 1 | 8% |
| black_mortar |  | common | 2.0 | 13 | 1 | 8% |
| forge_hammer |  | uncommon | 2.5 | 16 | 1 | 6% |
| victory_horn | sim | common | 2.0 | 11 | 0 | 0% |
| giant_scale |  | uncommon | 2.5 | 5 | 0 | 0% |
| grave_call |  | uncommon | 2.5 | 9 | 0 | 0% |
| rift_key |  | uncommon | 2.0 | 9 | 0 | 0% |
| heavy_grimoire | sim | rare | 2.0 | 10 | 0 | 0% |
| miser_ledger |  | common | 1.5 | 17 | 0 | 0% |
| shortcut_stone |  | rare | 2.5 | 8 | 0 | 0% |
| greedy_seal |  | rare | 2.0 | 15 | 0 | 0% |
| cracked_hourglass |  | uncommon | 2.5 | 13 | 0 | 0% |
| jailer_chains |  | uncommon | 2.0 | 13 | 0 | 0% |
| profane_earth |  | rare | 2.5 | 13 | 0 | 0% |
| stamp_ink |  | uncommon | 2.5 | 9 | 0 | 0% |
| pack_howl |  | uncommon | 2.0 | 10 | 0 | 0% |
| chain_ring | sim | uncommon | 2.5 | 6 | 0 | 0% |

## Proposta (não aplicada)

Não-elixir com taxa de escolha < 25% (mín. 5 ofertas): twin_litter, torn_banner, tar_pit, opening_gambit, tinker_file, blood_tithe, bad_blood, lucky_coin, black_mortar, forge_hammer, giant_scale, grave_call, rift_key, miser_ledger, shortcut_stone, greedy_seal, cracked_hourglass, jailer_chains, profane_earth, stamp_ink, pack_howl.

O bot só olha `bot_value`: medir um buff de efeito pelo bot não muda a taxa de escolha. Por isso nada foi aplicado além das três mudanças acima. Sugestão: subir o efeito dessas relíquias ~20% e ajustar o `bot_value`, depois re-rodar o mesmo lote (`--bot=heuristic --deck=plague --seeds=1-60`) comparando taxa de escolha e vitória.
