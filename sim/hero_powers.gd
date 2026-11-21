class_name HeroPowers
extends RefCounted
## CONTRATO (plano 21/11/2026): motor dos poderes de party. A frente B implementa; os ganchos ja estao em sim/sim.gd.
## Estado em `sim.powers`: Array de {"id": String, "level": int (1-3), "cd_left": float (s), "gap_left": float}.
## Eventos (K.Ev): POWER_GAINED [x, y, indice em party_powers, nivel], POWER_TRIGGER [x, y, indice, 0], POWER_READY [x, y, indice, 0].
## A HUD le Sim.party_powers() -> Array de {"id","level","cd_left","cd_total","ready"} (mesma ordem de sim.powers).


## Um membro da party caiu e ainda sobra gente (sem poder novo; gancho p/ efeitos por membro).
static func on_member_down(_sim, _pidx: int) -> void:
	pass


## A party inteira caiu: a party nova ganha 1 poder novo ou evolucao (sorteio pelo dano da party toda). Chamado
## antes de Sim._learn_ability, que B remove.
static func on_party_down(_sim) -> void:
	pass


## Um passo da simulacao: recargas, gatilhos (1 por contato, `rules.gap` s entre gatilhos), ratos aliados.
static func tick(_sim) -> void:
	pass


## Lista para a HUD (formato acima).
static func list(sim) -> Array:
	var out: Array = []
	for p in sim.powers:
		var d: Dictionary = sim.data.hero_powers.get(p["id"], {})
		var cds: Array = d.get("cooldown", [1.0])
		var cd_total := float(cds[mini(int(p["level"]), cds.size()) - 1])
		out.append({"id": p["id"], "level": p["level"], "cd_left": float(p["cd_left"]), "cd_total": cd_total, "ready": float(p["cd_left"]) <= 0.0})
	return out
