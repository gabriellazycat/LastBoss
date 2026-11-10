class_name CardsPlague
extends RefCounted
## Efeitos das cartas da Praga (owner "plague" em data/cards.json) que não cabem nas ops de CardFxLib.
## Ratos, Ninho de Morcegos, Rei dos Ratos, Lobisomem e Gosma são só unidades (CardFxLib.spawn_card_units);
## o Chamado do Bando é declarado em "ops" (buff "rally").


## Aplica a carta pelo id. Devolve true se tratou.
static func apply(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> bool:
	match k.d.id:
		_:
			return false
