class_name CardsCommon
extends RefCounted
## Efeitos das cartas comuns a todos os vilões (owner "common" em data/cards.json) que não cabem nas ops de
## CardFxLib. Ogro e Torre de Gárgulas são só unidades (CardFxLib.spawn_card_units).


## Aplica a carta pelo id. Devolve true se tratou.
static func apply(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> bool:
	var d := k.d
	var fx := d.fx
	var lv := k.lv
	var vet := k.vet
	var curse := k.curse
	match d.id:
		"web":
			sim.zones.append({"kind": "web", "x": x, "y": y, "r": fx["radius"], "t": d.fxv("duration", lv) * vet, "applied": false,
				"root": d.fxv("root", lv), "curse": curse})
		_:
			return false
	return true
