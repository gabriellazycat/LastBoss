# Registro da esteira (tokens e tempo por agente)

| lote | etapa | modelo | tokens | tempo | voltas | observação |
|---|---|---|---|---|---|---|
| praga_1 | composição | Opus médio | ~185 mil (+ parte antes do limite, não medida) | ~10 min após o reset (~1 h segundo o agente) | 0 | 1ª tentativa parou no limite de 5 h; retomado com SendMessage |
| praga_1 | acabamento | Sonnet médio | ~246 mil | ~24 min | 1 (contorno fraco em todas; cetro sem mão no rei) | criou praga_common.py |
| praga_1+2 | volta 1 + acabamento praga_2 | Sonnet médio (mesmo agente) | ~68 mil a mais (total 314 mil) | ~21 min | 0 no praga_2 | contorno engrossado no praga_common.py |
| praga_2 | composição | Opus médio | ~233 mil | ~18 min | 0 | fichas morcego, lobo, lobisomem, javali |
| praga_3 | composição | Opus médio | ~220 mil | ~16 min | 0 | fichas slime, flautista |
| praga_3 | acabamento | Sonnet médio | ~102 mil | ~4 min | 0 | praga_common.py sem mudança |
| dragao_1 | composição | Opus médio | ~292 mil (com a volta) | ~27 min | 1 (herói na mesma pose em 5 cartas) | fichas goblin, diabrete, kobold, dragao; 6 poses novas no herói |
| dragao_1 | acabamento | Sonnet médio | ~145 mil | ~11 min | 0 | modo guache `lift` (opção nova; Praga regerada idêntica, diff 0) |
| dragao_2 | acabamento | Sonnet médio | ~134 mil | ~14 min | 0 | opção holes_open (Praga e Dragão 1 regerados idênticos, diff 0) |
| dragao_3 | acabamento | Sonnet médio | ~112 mil (antes da volta) | ~7 min | 1 (elder_dragon vinho e sem separação do fundo) | sem mudança no motor |
| dragao_2 | composição | Opus médio | ~221 mil | ~15 min | 0 | fichas mimico, guardiao; 5 poses novas do herói |
| dragao_3 | composição | Opus médio | ~215 mil (refeito do zero após o limite) | ~9 min após o reset | 0 (ressalva: kobold com a mesma silhueta em 2 cartas) | 5 poses novas do herói |
| lich_1 | composição | Opus médio | ~273 mil (antes da volta) | ~23 min | 1 (anatomia do ghoul) | fichas esqueleto, carnical, cavaleiro_morte, colosso_ossos |
| lich_1 | acabamento | Sonnet médio | ~130 mil | ~6 min | 0 (ressalva: bone_colossus com peito poluído a 150 px) | recolor nos olhos do ghoul |
| lich_2 | composição | Opus médio | ~224 mil (antes da volta) | ~16 min | 1 (shadow_mark frontal e achatado) | fichas cultista, lich; 4 poses novas do herói |
| **Praga** | integração | controlador | — | — | — | 24 PNGs em assets/cards, data/card_art.json, testes falhas: 0, capturas em capturas/praga |
| dragao_3 | volta 1 (elder_dragon) | Sonnet médio | ~7 mil a mais | ~8 min | — | opção recolor no praga_common.py |
| **Dragão** | integração | controlador | — | — | — | 24 PNGs em assets/cards, card_art.json com 48, testes falhas: 0, captura em capturas/dragao |
| lich_2 | acabamento | Sonnet médio | ~140 mil | ~12 min | 0 (ressalva: rosto do Lich em arcane_apocalypse perde detalhe) | opções fx_keep_op e rim |
| lich_3 | composição | Opus médio | ~272 mil | ~21 min | 0 | fichas fantasma, golem_sucata; 6 poses novas do herói |
| lich_3 | acabamento | Sonnet médio | ~114 mil | ~5 min | 0 (ressalva: herói com pouco contraste em open_grave/soul_storm) | sem mudança no motor |
| **Lich** | integração | controlador | — | — | — | 24 PNGs, card_art.json com 72, testes falhas: 0, captura em capturas/lich |
