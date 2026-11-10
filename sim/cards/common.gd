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
		"soul_collector":
			_lair_stack(sim, k, "elixir_regen")
		"dark_forge":
			_lair_stack(sim, k, "monster_hp")
		_:
			return false
	return true


## Covil empilhável: conta a cópia e soma o efeito dela (já com o nível).
static func _lair_stack(sim: Sim, k: CardFxLib.Ctx, key: String) -> void:
	var id := k.d.id
	sim.lair[id] = int(sim.lair.get(id, 0)) + 1
	sim.lair_val[id] = float(sim.lair_val.get(id, 0.0)) + k.d.fxv(key, k.lv)
