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
var tp_cd := 0.0
var arm_t := 0.0
var fury_t := 0.0
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
		part_hp.append(float(p["hp"]))
		part_max.append(float(p["hp"]))
		part_off.append(Vector2(p["offset"][0], p["offset"][1]))
		part_value.append(PART_VALUE.get(p["id"], 1.0))
	var n: int = A["altars"]
	for k in n:
		var a := TAU * k / n + PI * 0.5
		altar_pos.append(center + Vector2(cos(a), sin(a)) * float(A["altar_ring"]))
		altar_alive.append(true)
		altar_hp.append(float(A["altar_hp"]))
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


func can_teleport(k: int) -> bool:
	return active and tp_cd <= 0.0 and k >= 0 and k < altar_pos.size() and altar_alive[k] and k != altar \
		and sim.elixir >= float(A["teleport_cost"])


func teleport(k: int) -> bool:
	if not can_teleport(k):
		return false
	sim.elixir -= float(A["teleport_cost"])
	var p: Vector2 = altar_pos[k]
	sim.emit(K.Ev.TELEPORT, bx, by, p.x, k)
	bx = p.x
	by = p.y
	face = (Vector2(cx, cy) - p).normalized()
	altar = k
	tp_cd = A["teleport_cooldown"]
	sim.last_teleport_t = sim.t
	sim.stats["teleports"] += 1
	return true


func update(dt: float) -> void:
	tp_cd = maxf(0.0, tp_cd - dt)
	fury_t = maxf(0.0, fury_t - dt)
	if part_alive("right_arm"):
		arm_t -= dt
		if arm_t <= 0.0:
			arm_t += 1.0
			var h := sim.hero
			if Vector2(h.x - bx, h.y - by).length() <= float(A["arm_aura_radius"]) + h.radius + 1.0:
				var m := 1.5 if fury_t > 0.0 else 1.0
				sim.damage_hero(float(sim.data.boss["right_arm_dps"]) * m, bx, by, 0, SimHero.DMG_AREA, "boss")


func hero_in_front(cone_deg: float, rng_m: float) -> bool:
	var v := Vector2(sim.hero.x - bx, sim.hero.y - by)
	var d := v.length()
	if d > rng_m or d < 0.01:
		return false
	return v.normalized().dot(face) >= cos(deg_to_rad(cone_deg * 0.5))


func fury(heal: float, dur: float) -> void:
	for k in part_hp.size():
		if part_hp[k] > 0.0:
			part_hp[k] = minf(part_max[k], part_hp[k] + part_max[k] * heal)
	fury_t = dur


func sacrifice_part() -> bool:
	for k in part_hp.size():
		if part_hp[k] > 0.0 and part_ids[k] != "core":
			_destroy(k)
			return true
	return false
