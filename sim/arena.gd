class_name SimArena
extends RefCounted
## Arena da luta final: corpo do chefe em 4 partes, altares de teleporte.

const PART_VALUE := {"left_arm": 1.0, "right_arm": 1.3, "head": 1.5, "core": 3.0}

var sim: Sim
var A: Dictionary
var cx := 0.0
var cy := 0.0
var bx := 0.0
var by := 0.0
var face := Vector2(0, 1)
var part_ids: Array = []
var part_hp := PackedFloat32Array()
var part_max := PackedFloat32Array()
var part_off: Array = []
var part_value: Array = []
var altar_pos: Array = []
var altar_alive: Array = []
var altar_hp: Array = []
var altar := -1
var pillar_pos: Array = []
var pillar_hp: Array = []
var pillar_r := 0.9
var tp_cd := 0.0
var arm_t := 0.0
var fury_t := 0.0
var fury_dmg := 0.5
var destroyed := 0
var active := false


func setup(s: Sim, center: Vector2, dir: Vector2) -> void:
	sim = s
	A = sim.data.rules["arena"]
	cx = center.x
	cy = center.y
	bx = cx
	by = cy
	face = -dir
	for p in sim.data.boss["parts"]:
		part_ids.append(p["id"])
		# part_hp_mult (10/11/2026): botão de balanceamento da arena (menor = o herói derruba o chefe mais rápido).
		var php := float(p["hp"]) * float(A.get("part_hp_mult", 1.0))
		part_hp.append(php)
		part_max.append(php)
		part_off.append(Vector2(p["offset"][0], p["offset"][1]))
		part_value.append(PART_VALUE.get(p["id"], 1.0))
	var n: int = A["altars"]
	for k in n:
		var a := TAU * k / n + PI * 0.5
		altar_pos.append(center + Vector2(cos(a), sin(a)) * float(A["altar_ring"]))
		altar_alive.append(true)
		altar_hp.append(float(A["altar_hp"]))
	var np := int(A.get("pillars", 0))
	pillar_r = float(A.get("pillar_radius", 0.9))
	for k in np:
		var a := TAU * (k + 0.5) / np + PI * 0.5
		pillar_pos.append(center + Vector2(cos(a), sin(a)) * float(A.get("pillar_ring", 6.0)))
		pillar_hp.append(float(A.get("pillar_hp", 350)))
	active = true


func part_index(id: String) -> int:
	return part_ids.find(id)


func part_alive(id: String) -> bool:
	var k := part_ids.find(id)
	return k >= 0 and part_hp[k] > 0.0


func part_pos(k: int) -> Vector2:
	return Vector2(bx, by) + part_off[k]


func part_attackable(k: int) -> bool:
	if part_hp[k] <= 0.0:
		return false
	return part_ids[k] != "core" or destroyed >= 1


func damage_part(k: int, dmg: float) -> void:
	if not part_attackable(k):
		return
	part_hp[k] -= dmg
	var p := part_pos(k)
	sim.emit(K.Ev.DAMAGE_UNIT, p.x, p.y, dmg, -1 - k)
	if part_hp[k] <= 0.0:
		_destroy(k)


func _destroy(k: int) -> void:
	part_hp[k] = 0.0
	destroyed += 1
	var p := part_pos(k)
	sim.emit(K.Ev.PART_DESTROYED, p.x, p.y, k, 0)
	sim.stats["parts_lost"] += 1
	if part_ids[k] == "core":
		sim.core_destroyed()


func damage_altar(k: int, dmg: float) -> void:
	if not altar_alive[k]:
		return
	altar_hp[k] -= dmg
	if altar_hp[k] <= 0.0:
		altar_alive[k] = false
		var p: Vector2 = altar_pos[k]
		sim.emit(K.Ev.PART_DESTROYED, p.x, p.y, -1, k)


func pillar_alive(k: int) -> bool:
	return pillar_hp[k] > 0.0


func damage_pillar(k: int, dmg: float) -> void:
	if pillar_hp[k] <= 0.0:
		return
	pillar_hp[k] -= dmg
	if pillar_hp[k] <= 0.0:
		var p: Vector2 = pillar_pos[k]
		sim.emit(K.Ev.PART_DESTROYED, p.x, p.y, -3, k)


## Pilares são obstáculos: empurram o herói e os monstros para fora.
func _collide() -> void:
	var h := sim.hero
	var U := sim.units
	for k in pillar_pos.size():
		if pillar_hp[k] <= 0.0:
			continue
		var p: Vector2 = pillar_pos[k]
		var v := Vector2(h.x - p.x, h.y - p.y)
		var minr := pillar_r + h.radius
		if v.length() < minr and v.length() > 0.001:
			v = v.normalized() * minr
			h.x = p.x + v.x
			h.y = p.y + v.y
		for i in U.hi:
			if U.alive[i] == 0 or (U.flags[i] & K.F_FLY):
				continue
			var dx := U.px[i] - p.x
			var dy := U.py[i] - p.y
			var mr := pillar_r + U.rad[i]
			var d2 := dx * dx + dy * dy
			if d2 < mr * mr and d2 > 0.000001:
				var d := sqrt(d2)
				U.px[i] = p.x + dx / d * mr
				U.py[i] = p.y + dy / d * mr


func can_teleport(k: int) -> bool:
	return active and tp_cd <= 0.0 and k >= 0 and k < altar_pos.size() and altar_alive[k] and k != altar \
		and sim.elixir >= sim.teleport_cost() and sim.overtime() <= 0.0   # prorrogação (10/11/2026): altares apagam


func teleport(k: int) -> bool:
	if not can_teleport(k):
		return false
	sim.elixir -= sim.teleport_cost()
	var p: Vector2 = altar_pos[k]
	sim.emit(K.Ev.TELEPORT, bx, by, p.x, k)
	bx = p.x
	by = p.y
	face = (Vector2(cx, cy) - p).normalized()
	altar = k
	tp_cd = maxf(1.0, float(A["teleport_cooldown"]) + sim.rv("teleport_cd"))
	sim.last_teleport_t = sim.t
	sim.stats["teleports"] += 1
	return true


func update(dt: float) -> void:
	tp_cd = maxf(0.0, tp_cd - dt)
	_collide()
	fury_t = maxf(0.0, fury_t - dt)
	if part_alive("right_arm"):
		arm_t -= dt
		if arm_t <= 0.0:
			arm_t += 1.0
			var h := sim.hero
			if Vector2(h.x - bx, h.y - by).length() <= float(A["arm_aura_radius"]) + h.radius + 1.0:
				var m := 1.0 + fury_dmg if fury_t > 0.0 else 1.0
				sim.damage_hero(float(sim.data.boss["right_arm_dps"]) * m * float(sim.mods["arena"]["arm_dmg_mult"]), bx, by, 0, SimHero.DMG_AREA, "boss")


func hero_in_front(cone_deg: float, rng_m: float) -> bool:
	var v := Vector2(sim.hero.x - bx, sim.hero.y - by)
	var d := v.length()
	if d > rng_m or d < 0.01:
		return false
	return v.normalized().dot(face) >= cos(deg_to_rad(cone_deg * 0.5))


func fury(heal: float, dur: float, dmg := 0.5) -> void:
	for k in part_hp.size():
		if part_hp[k] > 0.0:
			part_hp[k] = minf(part_max[k], part_hp[k] + part_max[k] * heal)
	fury_t = dur
	fury_dmg = dmg


## Pacto Sombrio: tira `frac` da vida máxima da parte mais cheia (sem o núcleo); se ela chegar a zero, é destruída.
func drain_part(frac: float) -> bool:
	var best := -1
	for k in part_hp.size():
		if part_hp[k] > 0.0 and part_ids[k] != "core" and (best < 0 or part_hp[k] > part_hp[best]):
			best = k
	if best < 0:
		return false
	part_hp[best] -= part_max[best] * frac
	if part_hp[best] <= 0.0:
		_destroy(best)
	return true

