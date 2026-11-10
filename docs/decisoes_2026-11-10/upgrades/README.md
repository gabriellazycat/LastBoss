# Upgrades de carta: 3 propostas visuais (variante 0 = como é hoje)
Abrir a vitrine: `godot --path . res://game/upgrade_showroom.tscn` (teclas 0-3 trocam a proposta; `-- --variant=2` abre numa delas). No jogo: `--set=card_fx_variant:N`.
Regerar as capturas (1600x900): `godot --path . res://game/upgrade_showroom.tscn -- --out=docs/decisoes_2026-11-10/upgrades/`
Cada captura: Ogro e Raio Sombrio, carta grande e compacta, em 10 estados (base, N2, N3, 5 modificadores, 2 combos).
- **variante_0**: o visual atual (aço, ouro holográfico, papéis coloridos, selos pequenos).
- **variante_1 Encadernação**: nível = lombada e cantos de couro (N2) / cantoneiras de ouro, lombada vinho e fita marcadora (N3); modificador = lacre de cera grande no pé, com cor e símbolo em relevo.
- **variante_2 Tinta viva**: nível = moldura de nanquim com espirais (N2) / iluminura de ouro com vinha, rosetas e brilho (N3); modificador = mancha de tinta da cor dele no custo, escorrendo, e o símbolo à mão no pé.
- **variante_3 Carimbos e condecorações**: nível = medalhas penduradas no pé (N2 uma de prata, N3 prata e ouro, moldura dourada); modificador = carimbo diagonal com o nome, na cor dele.
Código: `game/card_fx_variants.gd`; o seletor é lido em `game/card_fx.gd`. O padrão do jogo continua 0.
