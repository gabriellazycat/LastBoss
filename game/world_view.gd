class_name WorldView
extends Node3D
## Desenha o estado do Sim. Só lê; nunca altera a simulação.
## Unidades: uma MultiMesh por tipo, preenchida por buffer (uma chamada de desenho por tipo).

const UP := Vector3.UP
# Paleta das peças cinzas: cor de destaque por carta (legibilidade por silhueta + cor).
const COLORS := {
	"rat_horde": Color(0.55, 0.45, 0.38), "rat": Color(0.55, 0.45, 0.38), "bat": Color(0.55, 0.3, 0.75),
	"skeleton_archers": Color(0.9, 0.88, 0.78), "skeleton": Color(0.8, 0.8, 0.7), "goblin_dynamiter": Color(0.35, 0.75, 0.25),
	"slime": Color(0.3, 0.9, 0.55), "bat_nest": Color(0.35, 0.2, 0.45), "rat_king": Color(0.85, 0.7, 0.2),
	"bone_totem": Color(0.85, 0.85, 0.9), "cultists": Color(0.6, 0.15, 0.35), "ogre": Color(0.5, 0.55, 0.3),
	"mimic": Color(0.75, 0.55, 0.2), "ghost": Color(0.6, 0.8, 1.0), "gargoyle_tower": Color(0.45, 0.45, 0.5),
	"werewolf": Color(0.45, 0.35, 0.3), "scrap_golem": Color(0.55, 0.4, 0.3), "spectre": Color(0.5, 0.95, 0.9),
}
const LOC_COLORS := {
	"village": Color(0.95, 0.75, 0.35), "tavern": Color(0.8, 0.45, 0.2), "fountain": Color(0.35, 0.7, 1.0),
	"ritual": Color(0.75, 0.2, 0.9), "shrine": Color(0.3, 0.95, 0.6), "bridge": Color(0.6, 0.6, 0.65),
}
const ZONE_COLORS := {"web": Color(0.9, 0.9, 0.95, 0.35), "oil": Color(1.0, 0.5, 0.1, 0.4), "bait": Color(1.0, 0.85, 0.2, 0.6), "army": Color(0, 0, 0, 0)}

var sim: Sim
var mm_by_def: Dictionary = {}   # def idx -> {"mm", "buf", "cap", "base_y", "scale"}
var hero_mesh: MeshInstance3D
var hero_mat: StandardMaterial3D
var shield_mesh: MeshInstance3D
var road_root: Node3D
var loc_nodes: Array = []
var zone_pool: Array = []
var number_pool: Array = []
var number_i := 0
var fx_pool: Array = []
var fx_i := 0
var shot_pool: Array = []
var shot_i := 0
var ring_min: MeshInstance3D
var ring_max: MeshInstance3D
var ghost: MeshInstance3D
var ghost_mat: StandardMaterial3D
var arena_root: Node3D
var part_nodes: Array = []
var altar_nodes: Array = []
var boss_face: MeshInstance3D
var cam: Camera3D
var cam_pos := Vector3.ZERO
var shake := 0.0


func _mat(c: Color, emit := 0.0, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func build(s: Sim, camera: Camera3D) -> void:
	sim = s
	cam = camera
	for c in get_children():
		c.queue_free()
	mm_by_def.clear()
	loc_nodes.clear()
	zone_pool.clear()
	number_pool.clear()
	fx_pool.clear()
	shot_pool.clear()
	part_nodes.clear()
	altar_nodes.clear()
	_build_ground()
	_build_road()
	_build_units()
	_build_hero()
	_build_pools()
	cam_pos = Vector3(sim.hero.x, 0, sim.hero.y)


func _build_ground() -> void:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4000, 4000)
	g.mesh = pm
	g.material_override = _mat(Color(0.12, 0.2, 0.15))
	g.position = Vector3(0, -0.02, -700)
	add_child(g)


func _ribbon(pts: PackedVector2Array, width: float, y: float, col: Color) -> MeshInstance3D:
	# Faixa com normais de esquadria: sem emendas abertas nas curvas.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var n := pts.size()
	for i in n:
		var d := Vector2.ZERO
		if i > 0:
			d += (pts[i] - pts[i - 1]).normalized()
		if i < n - 1:
			d += (pts[i + 1] - pts[i]).normalized()
		var o := d.normalized().orthogonal() * width * 0.5
		st.set_normal(UP)
		st.add_vertex(Vector3(pts[i].x + o.x, y, pts[i].y + o.y))
		st.set_normal(UP)
		st.add_vertex(Vector3(pts[i].x - o.x, y, pts[i].y - o.y))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := _mat(col)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	return mi


func _build_road() -> void:
	road_root = Node3D.new()
	add_child(road_root)
	for li in sim.road.legs.size():
		var leg: Dictionary = sim.road.legs[li]
		for b in leg["pts"].size():
			var r := _ribbon(leg["pts"][b], 4.0, 0.0, Color(0.5, 0.42, 0.32))
			r.set_meta("leg", li)
			r.set_meta("branch", b)
			road_root.add_child(r)
	for li in sim.road.locations.size():
		var loc: Dictionary = sim.road.locations[li]
		var n := Node3D.new()
		var p: Vector2 = loc["pos"]
		n.position = Vector3(p.x, 0, p.y)
		var disc := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = loc["r"]
		cm.bottom_radius = loc["r"]
		cm.height = 0.05
		disc.mesh = cm
		var col: Color = LOC_COLORS[loc["type"]]
		disc.material_override = _mat(Color(col, 0.28), 0.6)
		n.add_child(disc)
		var pillar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, 2.6, 1.2)
		pillar.mesh = bm
		pillar.position = Vector3(loc["r"] * 0.8, 1.3, 0)
		pillar.material_override = _mat(col, 0.4)
		n.add_child(pillar)
		var lab := Label3D.new()
		lab.text = tr("LOC_" + str(loc["type"]))
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.font_size = 64
		lab.outline_size = 12
		lab.modulate = col.lightened(0.3)
		lab.position = Vector3(0, 4.0, 0)
		lab.no_depth_test = true
		n.add_child(lab)
		n.set_meta("lab", lab)
		n.set_meta("disc", disc)
		add_child(n)
		loc_nodes.append(n)
	var lair := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(10, 6, 2)
	lair.mesh = lm
	var lp := sim.road.lair + sim.road.lair_dir * 31.0
	lair.position = Vector3(lp.x, 3, lp.y)
	lair.material_override = _mat(Color(0.25, 0.12, 0.3), 0.3)
	add_child(lair)


func _unit_mesh(c: CardDef) -> Array:
	# [mesh, y, scale]
	if c.is_structure:
		var b := BoxMesh.new()
		b.size = Vector3(1.6, 2.2, 1.6)
		if c.id == "mimic":
			b.size = Vector3(1.4, 1.0, 1.0)
			return [b, 0.5, 1.0]
		if c.id == "bone_totem":
			b.size = Vector3(0.8, 2.8, 0.8)
			return [b, 1.4, 1.0]
		return [b, 1.1, 1.0]
	if c.id == "slime":
		var s := SphereMesh.new()
		s.radius = 0.75
		s.height = 1.1
		return [s, 0.55, 1.0]
	if c.arch == K.Arch.TANK:
		var b2 := BoxMesh.new()
		b2.size = Vector3(1.5, 2.0, 1.2)
		return [b2, 1.0, 1.0]
	var cap := CapsuleMesh.new()
	if c.arch == K.Arch.SWARM:
		cap.radius = 0.3
		cap.height = 0.8
		return [cap, 1.6 if c.fly else 0.3, 1.0]
	cap.radius = 0.38
	cap.height = 1.5
	if c.id == "rat_king":
		cap.radius = 0.55
		cap.height = 1.6
	return [cap, 0.75, 1.0]


func _build_units() -> void:
	for c in sim.data.cards:
		if not c.is_unit:
			continue
		var info := _unit_mesh(c)
		var cap := 320 if c.arch == K.Arch.SWARM or c.id in ["skeleton", "spectre", "slime"] else 96
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = info[0]
		mm.instance_count = cap
		mm.visible_instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.custom_aabb = AABB(Vector3(-3000, -10, -3000), Vector3(6000, 40, 6000))
		var m := _mat(Color.WHITE)
		m.vertex_color_use_as_albedo = true
		mmi.material_override = m
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if c.arch == K.Arch.SWARM else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mmi)
		var buf := PackedFloat32Array()
		buf.resize(cap * 16)
		mm_by_def[c.idx] = {"mm": mm, "buf": buf, "cap": cap, "y": info[1], "col": COLORS.get(c.id, Color(0.6, 0.6, 0.6)), "n": 0}


func _build_hero() -> void:
	hero_mesh = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.6
	cap.height = 2.0
	hero_mesh.mesh = cap
	hero_mat = _mat(Color(0.35, 0.55, 1.0), 0.3)
	hero_mesh.material_override = hero_mat
	add_child(hero_mesh)
	var sword := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.12, 0.12, 1.4)
	sword.mesh = sb
	sword.position = Vector3(0.55, 0.2, -0.8)
	sword.material_override = _mat(Color(0.85, 0.85, 0.9), 0.5)
	hero_mesh.add_child(sword)
	shield_mesh = MeshInstance3D.new()
	var shm := BoxMesh.new()
	shm.size = Vector3(1.3, 1.5, 0.15)
	shield_mesh.mesh = shm
	shield_mesh.material_override = _mat(Color(0.6, 0.85, 1.0, 0.75), 1.2)
	add_child(shield_mesh)
	ring_min = _circle(3.0, Color(1, 0.35, 0.35, 0.8))
	ring_max = _circle(12.0, Color(0.7, 0.5, 1.0, 0.8))
	add_child(ring_min)
	add_child(ring_max)
	ghost = MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 1.0
	gm.bottom_radius = 1.0
	gm.height = 0.1
	ghost.mesh = gm
	ghost_mat = _mat(Color(0.4, 1, 0.5, 0.45), 1.0, true)
	ghost.material_override = ghost_mat
	add_child(ghost)
	show_placement(false, Vector3.ZERO, true, 1.0)


func _circle(r: float, col: Color) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.08
	tm.outer_radius = r + 0.08
	tm.rings = 64
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = _mat(col, 1.0, true)
	return mi


func _build_pools() -> void:
	for i in 32:
		var z := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.0
		cm.bottom_radius = 1.0
		cm.height = 0.06
		z.mesh = cm
		z.material_override = _mat(Color.WHITE, 0.5, true)
		z.visible = false
		add_child(z)
		zone_pool.append(z)
	for i in 64:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.font_size = 48
		l.outline_size = 10
		l.visible = false
		add_child(l)
		number_pool.append({"n": l, "t": 0.0, "v": Vector3.ZERO})
	for i in 24:
		var e := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		e.mesh = sm
		e.material_override = _mat(Color(1, 0.6, 0.2, 0.6), 2.0, true)
		e.visible = false
		add_child(e)
		fx_pool.append({"n": e, "t": 0.0, "r": 1.0})
	for i in 32:
		var s := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, 0.08, 1.0)
		s.mesh = bm
		s.material_override = _mat(Color(1, 1, 0.7), 2.0, true)
		s.visible = false
		add_child(s)
		shot_pool.append({"n": s, "t": 0.0})


func build_arena() -> void:
	arena_root = Node3D.new()
	add_child(arena_root)
	var A := sim.arena
	var floor_ := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var r: float = sim.data.rules["arena"]["radius"]
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.1
	floor_.mesh = cm
	floor_.material_override = _mat(Color(0.2, 0.14, 0.24))
	floor_.position = Vector3(A.cx, 0.01, A.cy)
	arena_root.add_child(floor_)
	var colors := {"left_arm": Color(0.4, 0.5, 1.0), "right_arm": Color(1.0, 0.4, 0.3), "head": Color(0.95, 0.85, 0.3), "core": Color(0.8, 0.2, 0.9)}
	var sizes := {"left_arm": Vector3(1.0, 2.6, 1.0), "right_arm": Vector3(1.0, 2.6, 1.0), "head": Vector3(1.4, 1.4, 1.4), "core": Vector3(2.0, 2.4, 1.6)}
	for k in A.part_ids.size():
		var id: String = A.part_ids[k]
		var p := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = sizes[id]
		p.mesh = bm
		p.material_override = _mat(colors[id], 0.4)
		arena_root.add_child(p)
		part_nodes.append(p)
	for k in A.altar_pos.size():
		var a := MeshInstance3D.new()
		var am := CylinderMesh.new()
		am.top_radius = 1.0
		am.bottom_radius = 1.2
		am.height = 0.8
		a.mesh = am
		a.material_override = _mat(Color(0.5, 0.3, 0.9), 0.8)
		var ap: Vector2 = A.altar_pos[k]
		a.position = Vector3(ap.x, 0.4, ap.y)
		var lab := Label3D.new()
		lab.text = str(k + 1)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.font_size = 72
		lab.position = Vector3(0, 1.6, 0)
		lab.no_depth_test = true
		a.add_child(lab)
		arena_root.add_child(a)
		altar_nodes.append(a)
	boss_face = MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.3, 0.1, 6.0)
	boss_face.mesh = fm
	boss_face.material_override = _mat(Color(1, 0.3, 0.3, 0.5), 1.0, true)
	arena_root.add_child(boss_face)


func show_placement(on: bool, pos: Vector3, valid: bool, radius: float) -> void:
	ring_min.visible = on
	ring_max.visible = on
	ghost.visible = on
	if not on:
		return
	ghost.position = pos + Vector3(0, 0.05, 0)
	ghost.scale = Vector3(radius, 1, radius)
	ghost_mat.albedo_color = Color(0.4, 1, 0.5, 0.45) if valid else Color(1, 0.3, 0.3, 0.45)


# ---------------------------------------------------------------- desenho

func draw(alpha: float, delta: float) -> void:
	if sim == null:
		return
	var U := sim.units
	var lists := {}
	for k in mm_by_def:
		lists[k] = []
	for i in U.hi:
		if U.alive[i] == 1 and lists.has(U.def[i]):
			lists[U.def[i]].append(i)
	for k in mm_by_def:
		var e: Dictionary = mm_by_def[k]
		var mm: MultiMesh = e["mm"]
		var ids: Array = lists[k]
		var n := mini(ids.size(), int(e["cap"]))
		mm.visible_instance_count = n
		if n == 0:
			continue
		var buf: PackedFloat32Array = e["buf"]
		e["buf"] = PackedFloat32Array()
		var base: Color = e["col"]
		var by: float = e["y"]
		for q in n:
			var i: int = ids[q]
			var s := 1.0
			if U.gen[i] > 0:
				s = 0.72 if U.gen[i] == 1 else 0.5
			var col := base.darkened((1.0 - clampf(U.hp[i] / U.max_hp[i], 0.0, 1.0)) * 0.5)
			if U.flags[i] & K.F_STONE:
				col = Color(0.3, 0.3, 0.32)
			if U.fear_t[i] > 0.0:
				col = col.lerp(Color(0.6, 0.2, 1.0), 0.5)
			var y := by * s
			if U.flags[i] & K.F_FLY:
				y += sin(sim.t * 6.0 + i) * 0.25
			var o := q * 16
			buf[o] = s; buf[o + 1] = 0.0; buf[o + 2] = 0.0; buf[o + 3] = lerpf(U.ox[i], U.px[i], alpha)
			buf[o + 4] = 0.0; buf[o + 5] = s; buf[o + 6] = 0.0; buf[o + 7] = y
			buf[o + 8] = 0.0; buf[o + 9] = 0.0; buf[o + 10] = s; buf[o + 11] = lerpf(U.oy[i], U.py[i], alpha)
			buf[o + 12] = col.r; buf[o + 13] = col.g; buf[o + 14] = col.b; buf[o + 15] = 1.0
		mm.buffer = buf
		e["buf"] = buf
	_draw_hero(alpha)
	_draw_road_state()
	_draw_zones()
	_draw_arena()
	_tick_pools(delta)
	_camera(alpha, delta)


func hero_pos(alpha: float) -> Vector3:
	var h := sim.hero
	return Vector3(lerpf(h.ox, h.x, alpha), 0.0, lerpf(h.oy, h.y, alpha))


func _draw_hero(alpha: float) -> void:
	var h := sim.hero
	var p := hero_pos(alpha)
	hero_mesh.position = p + Vector3(0, 1.0, 0)
	var f := Vector3(h.face_x, 0, h.face_y)
	if f.length() > 0.01:
		hero_mesh.look_at(hero_mesh.position + f, UP)
	var glow := 0.3 + h.level * 0.12
	hero_mat.emission_energy_multiplier = glow
	var c := Color(0.35, 0.55, 1.0)
	if h.petrify_t > 0.0:
		c = Color(0.5, 0.5, 0.5)
	elif h.root_t > 0.0:
		c = Color(0.9, 0.9, 0.8)
	elif h.fear_t > 0.0:
		c = Color(0.6, 0.3, 1.0)
	elif h.slow_t > 0.0:
		c = Color(0.6, 0.7, 0.9)
	hero_mat.albedo_color = c
	hero_mat.emission = c
	shield_mesh.visible = h.shield_hp > 0.0
	if shield_mesh.visible:
		shield_mesh.position = p + f * 1.0 + Vector3(0, 1.0, 0)
		shield_mesh.look_at(shield_mesh.position + f, UP)
		var w := 1.3 if h.shield_cos > 0.6 else 2.2
		shield_mesh.scale = Vector3(w / 1.3, 1, 1)
		var m: StandardMaterial3D = shield_mesh.material_override
		m.albedo_color.a = 0.35 + 0.5 * h.shield_hp / maxf(h.shield_max, 1.0)
	ring_min.position = p + Vector3(0, 0.06, 0)
	ring_max.position = p + Vector3(0, 0.06, 0)


func _draw_road_state() -> void:
	if sim.phase != K.Phase.ROAD:
		return
	for r in road_root.get_children():
		var leg: Dictionary = sim.road.legs[r.get_meta("leg")]
		var b: int = r.get_meta("branch")
		var col := Color(0.5, 0.42, 0.32)
		if leg["kind"] == "fork":
			if leg["chosen"] == b or leg["forced"] == b:
				col = Color(0.68, 0.56, 0.4)
			elif leg["chosen"] >= 0 or leg["closed"] == b:
				col = Color(0.2, 0.17, 0.15) if leg["closed"] != b else Color(0.4, 0.12, 0.1)
		var m: StandardMaterial3D = r.material_override
		m.albedo_color = col
	for li in loc_nodes.size():
		var loc: Dictionary = sim.road.locations[li]
		var n: Node3D = loc_nodes[li]
		var lab: Label3D = n.get_meta("lab")
		var st: int = loc["state"]
		n.visible = st != SimRoad.LocState.DESTROYED or loc["type"] == "shrine"
		var txt := tr("LOC_" + str(loc["type"]))
		if loc["type"] == "shrine" and loc["entered"] and st == SimRoad.LocState.ACTIVE:
			txt = "%s  %d" % [txt, ceili(float(loc["t"]))]
		elif loc["type"] == "ritual" and st == SimRoad.LocState.ACTIVE and loc["hp"] < loc["max_hp"]:
			txt = "%s  %d%%" % [txt, int(100.0 * loc["hp"] / loc["max_hp"])]
		lab.text = txt
		lab.modulate.a = 0.4 if st != SimRoad.LocState.ACTIVE else 1.0


func _draw_zones() -> void:
	var k := 0
	for z in sim.zones:
		if k >= zone_pool.size():
			break
		var col: Color = ZONE_COLORS.get(z["kind"], Color(1, 1, 1, 0.3))
		if col.a <= 0.0:
			continue
		var m: MeshInstance3D = zone_pool[k]
		m.visible = true
		m.position = Vector3(z["x"], 0.04, z["y"])
		var r := maxf(float(z["r"]), 0.6)
		m.scale = Vector3(r, 1, r)
		var mat: StandardMaterial3D = m.material_override
		mat.albedo_color = col
		k += 1
	for i in range(k, zone_pool.size()):
		zone_pool[i].visible = false


func _draw_arena() -> void:
	if arena_root == null or not sim.arena.active:
		return
	var A := sim.arena
	for k in part_nodes.size():
		var n: MeshInstance3D = part_nodes[k]
		var pp := A.part_pos(k)
		var h := 1.3 if A.part_ids[k] != "head" else 3.2
		n.position = Vector3(pp.x, h, pp.y)
		n.visible = A.part_hp[k] > 0.0
		var m: StandardMaterial3D = n.material_override
		m.emission_energy_multiplier = 1.5 if A.fury_t > 0.0 else (0.4 if A.part_attackable(k) else 0.1)
	for k in altar_nodes.size():
		altar_nodes[k].visible = A.altar_alive[k]
	boss_face.position = Vector3(A.bx, 0.1, A.by) + Vector3(A.face.x, 0, A.face.y) * 4.0
	boss_face.look_at(boss_face.position + Vector3(A.face.x, 0, A.face.y), UP)


func _tick_pools(delta: float) -> void:
	for e in number_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var l: Label3D = e["n"]
			l.position += Vector3(0, 1.6 * delta, 0)
			l.modulate.a = clampf(e["t"] / 0.6, 0.0, 1.0)
			if e["t"] <= 0.0:
				l.visible = false
	for e in fx_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var n: MeshInstance3D = e["n"]
			var k: float = 1.0 - float(e["t"]) / 0.35
			n.scale = Vector3.ONE * float(e["r"]) * (0.4 + 0.6 * k)
			var m: StandardMaterial3D = n.material_override
			m.albedo_color.a = 0.6 * (1.0 - k)
			if e["t"] <= 0.0:
				n.visible = false
	for e in shot_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			if e["t"] <= 0.0:
				e["n"].visible = false


func _camera(alpha: float, delta: float) -> void:
	var target := hero_pos(alpha)
	if sim.phase == K.Phase.ARENA:
		target = target.lerp(Vector3(sim.arena.bx, 0, sim.arena.by), 0.4)
	cam_pos = cam_pos.lerp(target, clampf(delta * 6.0, 0.0, 1.0))
	var dist := 30.0 + minf(float(sim.units.count), 300.0) * 0.04
	if sim.phase == K.Phase.ARENA:
		dist += 6.0
	var off := Vector3(0, dist * 0.78, dist * 0.62)
	var sh := Vector3.ZERO
	if shake > 0.0:
		shake -= delta
		sh = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 1.5
	cam.position = cam_pos + off + sh
	cam.look_at(cam_pos + Vector3(0, 0, -2), UP)


# ---------------------------------------------------------------- eventos

func number(pos: Vector3, txt: String, col: Color, size := 48) -> void:
	var e: Dictionary = number_pool[number_i]
	number_i = (number_i + 1) % number_pool.size()
	var l: Label3D = e["n"]
	l.text = txt
	l.modulate = col
	l.font_size = size
	l.position = pos + Vector3(randf_range(-0.4, 0.4), 2.2, 0)
	l.visible = true
	e["t"] = 0.8


func burst(pos: Vector3, r: float, col: Color) -> void:
	var e: Dictionary = fx_pool[fx_i]
	fx_i = (fx_i + 1) % fx_pool.size()
	var n: MeshInstance3D = e["n"]
	n.position = pos + Vector3(0, 0.5, 0)
	var m: StandardMaterial3D = n.material_override
	m.albedo_color = col
	m.emission = col
	n.visible = true
	e["t"] = 0.35
	e["r"] = r


func shot(a: Vector3, b: Vector3) -> void:
	var e: Dictionary = shot_pool[shot_i]
	shot_i = (shot_i + 1) % shot_pool.size()
	var n: MeshInstance3D = e["n"]
	var mid := (a + b) * 0.5 + Vector3(0, 1.0, 0)
	n.position = mid
	var l := a.distance_to(b)
	if l < 0.1:
		return
	n.look_at(b + Vector3(0, 1.0, 0), UP)
	n.scale = Vector3(1, 1, l)
	n.visible = true
	e["t"] = 0.08


func handle_events(evs: Array) -> void:
	for ev in evs:
		var k: int = ev[0]
		var p := Vector3(ev[1], 0, ev[2])
		match k:
			K.Ev.DAMAGE_HERO:
				if float(ev[3]) >= 3.0:
					number(p, str(int(ev[3])), Color(1, 0.35, 0.3))
			K.Ev.DAMAGE_UNIT:
				number(p, str(int(ev[3])), Color(1, 1, 1, 0.9), 32)
			K.Ev.EXPLOSION:
				burst(p, float(ev[3]), Color(1, 0.55, 0.15))
				shake = maxf(shake, 0.12)
			K.Ev.SHOT:
				shot(p, Vector3(ev[3], 0, float(ev[4]) / 100.0))
			K.Ev.SPIN:
				burst(p, float(ev[3]), Color(0.7, 0.85, 1.0))
			K.Ev.HERO_LEVEL:
				burst(p, 3.0, Color(1, 0.95, 0.5))
				number(p + Vector3(0, 1, 0), tr("UI_HERO_LEVEL").format({"n": int(ev[3])}), Color(1, 0.9, 0.4), 64)
			K.Ev.PLAYER_LEVEL:
				number(p + Vector3(0, 2, 0), tr("UI_PLAYER_LEVEL").format({"n": int(ev[3])}), Color(0.8, 0.5, 1.0), 64)
			K.Ev.SHIELD_BREAK:
				burst(p + Vector3(0, 1, 0), 1.2, Color(0.6, 0.85, 1.0))
			K.Ev.HEAL:
				if float(ev[3]) >= 20.0:
					number(p, "+" + str(int(ev[3])), Color(0.4, 1, 0.5))
			K.Ev.PART_DESTROYED:
				burst(p, 4.0, Color(0.9, 0.3, 1.0))
				shake = 0.45
			K.Ev.TELEPORT:
				burst(p, 2.0, Color(0.6, 0.3, 1.0))
			K.Ev.SPELL:
				var di := int(ev[3])
				if di >= 0 and sim.data.cards[di].is_spell:
					burst(p, 2.0, Color(0.6, 0.3, 1.0))
			K.Ev.CURSE:
				burst(p + Vector3(0, 1, 0), 1.5, Color(0.5, 0.1, 0.6))
