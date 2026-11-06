class_name WorldView
extends Node3D
## Desenha o estado do Sim. Só lê; nunca altera a simulação.
## Unidades: uma MultiMesh por tipo, preenchida por buffer (transform + cor + dados do shader).

const UP := Vector3.UP
const STRIDE := 20
const LOC_COLORS := {
	"village": Color(0.95, 0.75, 0.35), "tavern": Color(0.9, 0.55, 0.25), "fountain": Color(0.35, 0.75, 1.0),
	"ritual": Color(0.8, 0.25, 1.0), "shrine": Color(0.3, 1.0, 0.6), "bridge": Color(0.65, 0.6, 0.55),
}
const PART_OFFSETS := {"core": Vector3(0, 0, 0), "head": Vector3(0, 4.3, 0), "left_arm": Vector3(-1.6, 2.4, 0), "right_arm": Vector3(1.6, 2.4, 0)}

var sim: Sim
var cam: Camera3D
var mm_by_def: Dictionary = {}
var flash := PackedFloat32Array()
var hero_root: Node3D
var hero_body: MeshInstance3D
var hero_mat: ShaderMaterial
var sword_pivot: Node3D
var shield_node: MeshInstance3D
var hero_light: OmniLight3D
var swing_t := 0.0
var road_meshes: Array = []
var loc_nodes: Array = []
var zone_pool: Array = []
var number_pool: Array = []
var number_i := 0
var burst_pool: Array = []
var burst_i := 0
var shot_pool: Array = []
var shot_i := 0
var orb_pool: Array = []
var orb_i := 0
var particles: Dictionary = {}
var ring_min: MeshInstance3D
var ring_max: MeshInstance3D
var ghost: MeshInstance3D
var ghost_mat: StandardMaterial3D
var arena_root: Node3D
var part_nodes: Array = []
var altar_nodes: Array = []
var boss_face: MeshInstance3D
var cam_pos := Vector3.ZERO
var shake := 0.0
var bubble: Label3D
var bubble_t := 0.0
var bubble_on_boss := false
var flash_light: OmniLight3D
var flash_t := 0.0


func _unshaded(c: Color, emit := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m


func _mi(mesh: Mesh, pos: Vector3, mat: Material = null, rot_y := 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat if mat else Models.material()
	m.position = pos
	m.rotation.y = rot_y
	return m


func _light(pos: Vector3, col: Color, energy: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_m
	l.position = pos
	return l


func build(s: Sim, camera: Camera3D) -> void:
	sim = s
	cam = camera
	for c in get_children():
		c.queue_free()
	for a in [road_meshes, loc_nodes, zone_pool, number_pool, burst_pool, shot_pool, orb_pool, part_nodes, altar_nodes]:
		a.clear()
	mm_by_def.clear()
	particles.clear()
	arena_root = null
	flash.resize(sim.units.cap)
	flash.fill(0.0)
	_build_ground()
	_build_road()
	_build_scatter()
	_build_locations()
	_build_lair()
	_build_units()
	_build_hero()
	_build_pools()
	cam_pos = Vector3(sim.hero.x, 0, sim.hero.y)


func build_empty() -> void:
	for c in get_children():
		c.queue_free()
	sim = null


# ---------------------------------------------------------------- terreno e estrada

func _road_bounds() -> Rect2:
	var r := Rect2(sim.road.route[0], Vector2.ZERO)
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for p in pts:
				r = r.expand(p)
	return r.grow(120.0)


func _build_ground() -> void:
	var b := _road_bounds()
	var cell := 8.0
	var nx := int(b.size.x / cell) + 1
	var ny := int(b.size.y / cell) + 1
	var rng := RandomNumberGenerator.new()
	rng.seed = sim.run_seed + 11
	var cols := PackedColorArray()
	cols.resize((nx + 1) * (ny + 1))
	for j in ny + 1:
		for i in nx + 1:
			var n := sin(i * 0.37 + j * 0.11) * 0.5 + sin(i * 0.09 - j * 0.23) * 0.5
			var base := Color(0.2, 0.3, 0.22).lerp(Color(0.27, 0.33, 0.2), n * 0.5 + 0.5)
			cols[j * (nx + 1) + i] = base.lerp(Color(0.24, 0.2, 0.3), rng.randf() * 0.4)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in ny:
		for i in nx:
			var x0 := b.position.x + i * cell
			var z0 := b.position.y + j * cell
			var p := [Vector3(x0, -0.03, z0), Vector3(x0 + cell, -0.03, z0), Vector3(x0, -0.03, z0 + cell), Vector3(x0 + cell, -0.03, z0 + cell)]
			var c := [cols[j * (nx + 1) + i], cols[j * (nx + 1) + i + 1], cols[(j + 1) * (nx + 1) + i], cols[(j + 1) * (nx + 1) + i + 1]]
			for k in [0, 1, 2, 2, 1, 3]:
				st.set_color(c[k])
				st.set_normal(UP)
				st.add_vertex(p[k])
	var g := _mi(st.commit(), Vector3.ZERO)
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(g)


func _ribbon(pts: PackedVector2Array, width: float, col: Color, edge: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var L := PackedVector3Array()
	var R := PackedVector3Array()
	var LE := PackedVector3Array()
	var RE := PackedVector3Array()
	for i in n:
		var d := Vector2.ZERO
		if i > 0:
			d += (pts[i] - pts[i - 1]).normalized()
		if i < n - 1:
			d += (pts[i + 1] - pts[i]).normalized()
		var o := d.normalized().orthogonal()
		var p := pts[i]
		var w := width * 0.5
		L.append(Vector3(p.x + o.x * w, 0.0, p.y + o.y * w))
		R.append(Vector3(p.x - o.x * w, 0.0, p.y - o.y * w))
		LE.append(Vector3(p.x + o.x * (w + 0.9), -0.01, p.y + o.y * (w + 0.9)))
		RE.append(Vector3(p.x - o.x * (w + 0.9), -0.01, p.y - o.y * (w + 0.9)))
	for i in n - 1:
		var shade := 0.92 + 0.08 * sin(i * 1.7)
		for q in [[L, R, Color(col.r * shade, col.g * shade, col.b * shade)], [LE, L, edge], [R, RE, edge]]:
			var A: PackedVector3Array = q[0]
			var B: PackedVector3Array = q[1]
			var c: Color = q[2]
			for v in [A[i], A[i + 1], B[i], B[i], A[i + 1], B[i + 1]]:
				st.set_color(c)
				st.set_normal(UP)
				st.add_vertex(v)
	return st.commit()


func _build_road() -> void:
	for li in sim.road.legs.size():
		var leg: Dictionary = sim.road.legs[li]
		for b in leg["pts"].size():
			var mat := Models.glow_material(0.0)
			mat.render_priority = 0
			var r := _mi(_ribbon(leg["pts"][b], 4.2, Color(0.55, 0.43, 0.3), Color(0.36, 0.3, 0.22)), Vector3.ZERO, mat)
			r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			r.set_meta("leg", li)
			r.set_meta("branch", b)
			add_child(r)
			road_meshes.append(r)


## Grade de ocupação da estrada, dos locais e da arena: o cenário não nasce em cima deles.
func _road_cells() -> Dictionary:
	var cells := {}
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for p in pts:
				var cx := int(floor(p.x / 6.0))
				var cy := int(floor(p.y / 6.0))
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						cells[Vector2i(cx + dx, cy + dy)] = true
	for loc in sim.road.locations:
		var p: Vector2 = loc["pos"]
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				cells[Vector2i(int(floor(p.x / 6.0)) + dx, int(floor(p.y / 6.0)) + dy)] = true
	var lp := sim.road.lair + sim.road.lair_dir * 16.0
	for dy in range(-7, 8):
		for dx in range(-7, 8):
			cells[Vector2i(int(floor(lp.x / 6.0)) + dx, int(floor(lp.y / 6.0)) + dy)] = true
	return cells


func _scatter_mm(mesh: Mesh, xforms: Array, mat: Material, shadow: bool) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, Color.WHITE)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _build_scatter() -> void:
	var cells := _road_cells()
	var b := _road_bounds()
	var rng := RandomNumberGenerator.new()
	rng.seed = sim.run_seed + 77
	var sets := {"tree": [], "dead_tree": [], "rock": [], "grass": [], "mushroom": []}
	var n := int(b.size.x * b.size.y / 40.0)
	for i in n:
		var p := Vector2(rng.randf_range(b.position.x, b.end.x), rng.randf_range(b.position.y, b.end.y))
		if cells.has(Vector2i(int(floor(p.x / 6.0)), int(floor(p.y / 6.0)))):
			continue
		var r := rng.randf()
		var kind := "grass"
		if r < 0.22:
			kind = "tree"
		elif r < 0.27:
			kind = "dead_tree"
		elif r < 0.36:
			kind = "rock"
		elif r < 0.385:
			kind = "mushroom"
		var s := rng.randf_range(0.7, 1.4) if kind != "grass" else rng.randf_range(0.8, 1.6)
		sets[kind].append(Transform3D(Basis(UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.85, 1.2), s)), Vector3(p.x, 0, p.y)))
	for k in sets:
		var mat: Material = Models.material() if k != "mushroom" else Models.glow_material(1.5)
		_scatter_mm(Models.prop(k), sets[k], mat, k in ["tree", "dead_tree", "rock"])


# ---------------------------------------------------------------- locais e covil

func _road_dir_at(loc: Dictionary) -> Vector2:
	var pts: PackedVector2Array = sim.road.legs[loc["leg"]]["pts"][loc["branch"]]
	var p: Vector2 = loc["pos"]
	var best := 0
	var bd := INF
	for i in pts.size():
		var d := p.distance_squared_to(pts[i])
		if d < bd:
			bd = d
			best = i
	return (pts[mini(best + 1, pts.size() - 1)] - pts[maxi(best - 1, 0)]).normalized()


func _build_locations() -> void:
	for li in sim.road.locations.size():
		var loc: Dictionary = sim.road.locations[li]
		var t: String = loc["type"]
		var p: Vector2 = loc["pos"]
		var dir := _road_dir_at(loc)
		var side := dir.orthogonal()
		var yaw := atan2(-dir.x, -dir.y)
		var n := Node3D.new()
		n.position = Vector3(p.x, 0, p.y)
		add_child(n)
		var col: Color = LOC_COLORS[t]
		var off := Vector3(side.x, 0, side.y)
		var fwd := Vector3(dir.x, 0, dir.y)
		match t:
			"village":
				n.add_child(_mi(Models.prop("house"), off * 6.5, null, yaw + PI * 0.5))
				n.add_child(_mi(Models.prop("house"), -off * 6.5 + fwd * 3.0, null, yaw - PI * 0.5))
				n.add_child(_mi(Models.prop("house"), off * 7.0 + fwd * 7.0, null, yaw + PI * 0.5))
			"tavern":
				n.add_child(_mi(Models.prop("tavern"), off * 7.0, null, yaw + PI * 0.5))
			"fountain":
				n.add_child(_mi(Models.prop("fountain"), off * 5.0, Models.glow_material(0.15)))
			"ritual":
				n.add_child(_mi(Models.prop("ritual"), Vector3.ZERO, Models.glow_material(1.2)))
			"shrine":
				n.add_child(_mi(Models.prop("shrine"), off * 3.5, Models.glow_material(0.25)))
			"bridge":
				n.add_child(_mi(Models.prop("water"), Vector3.ZERO, Models.glow_material(0.25), yaw + PI * 0.5))
				n.add_child(_mi(Models.prop("bridge"), Vector3.ZERO, null, yaw))
		if t in ["shrine", "ritual", "village"]:
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = float(loc["r"]) - 0.12
			tm.outer_radius = float(loc["r"])
			tm.rings = 48
			tm.ring_segments = 3
			ring.mesh = tm
			ring.material_override = _unshaded(Color(col.r, col.g, col.b, 0.5), 1.3)
			ring.scale = Vector3(1, 0.2, 1)
			ring.position.y = 0.05
			n.add_child(ring)
			n.set_meta("ring", ring)
		n.add_child(_light(Vector3(0, 3.5, 0) + off * 2.0, col, 2.2, 14.0))
		var lab := Label3D.new()
		lab.text = tr("LOC_" + t)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.font_size = 56
		lab.outline_size = 14
		lab.modulate = col.lightened(0.35)
		lab.position = Vector3(0, 6.0, 0)
		lab.no_depth_test = true
		n.add_child(lab)
		n.set_meta("lab", lab)
		loc_nodes.append(n)


func _build_lair() -> void:
	var lp := sim.road.lair + sim.road.lair_dir * 34.0
	var yaw := atan2(-sim.road.lair_dir.x, -sim.road.lair_dir.y)
	add_child(_mi(Models.prop("castle"), Vector3(lp.x, 0, lp.y), Models.glow_material(0.12), yaw + PI))
	add_child(_light(Vector3(lp.x, 8, lp.y), Color(0.8, 0.3, 1.0), 4.0, 40.0))


# ---------------------------------------------------------------- unidades e herói

func _build_units() -> void:
	for c in sim.data.cards:
		if not c.is_unit:
			continue
		var cap := 320 if c.arch == K.Arch.SWARM or c.id in ["skeleton", "spectre", "slime", "rat"] else 96
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = Models.unit(c.id)
		mm.instance_count = cap
		mm.visible_instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Models.glow_material(0.35) if c.id in ["ghost", "spectre", "slime"] else Models.material()
		mmi.custom_aabb = AABB(Vector3(-3000, -10, -3000), Vector3(6000, 40, 6000))
		add_child(mmi)
		var buf := PackedFloat32Array()
		buf.resize(cap * STRIDE)
		var hop := 1.0 if c.arch == K.Arch.SWARM else (0.5 if c.arch != K.Arch.STRUCTURE else 0.0)
		if c.id == "slime":
			hop = 1.2
		mm_by_def[c.idx] = {"mm": mm, "buf": buf, "cap": cap, "hop": hop, "fly": c.fly}


func _build_hero() -> void:
	hero_root = Node3D.new()
	add_child(hero_root)
	hero_mat = Models.glow_material(0.05)
	hero_body = _mi(Models.hero_body(), Vector3.ZERO, hero_mat)
	hero_root.add_child(hero_body)
	sword_pivot = Node3D.new()
	sword_pivot.position = Vector3(0.55, 1.15, -0.1)
	hero_root.add_child(sword_pivot)
	sword_pivot.add_child(_mi(Models.hero_sword(), Vector3(0, 0, -0.2), Models.glow_material(0.25)))
	shield_node = _mi(Models.hero_shield(), Vector3(-0.5, 1.1, -0.45), Models.glow_material(0.3))
	hero_root.add_child(shield_node)
	hero_light = _light(Vector3(0, 3.0, 0), Color(1.0, 0.72, 0.42), 1.6, 13.0)
	hero_root.add_child(hero_light)
	ring_min = _circle(3.0, Color(1, 0.4, 0.4, 0.75))
	ring_max = _circle(12.0, Color(0.75, 0.55, 1.0, 0.75))
	add_child(ring_min)
	add_child(ring_max)
	ghost = MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 1.0
	gm.bottom_radius = 1.0
	gm.height = 0.08
	gm.radial_segments = 32
	ghost.mesh = gm
	ghost_mat = _unshaded(Color(0.4, 1, 0.5, 0.4), 1.0)
	ghost.material_override = ghost_mat
	add_child(ghost)
	show_placement(false, Vector3.ZERO, true, 1.0)
	flash_light = _light(Vector3.ZERO, Color(1, 0.6, 0.3), 0.0, 14.0)
	add_child(flash_light)
	bubble = Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.font_size = 64
	bubble.outline_size = 16
	bubble.outline_modulate = Color(0.1, 0.05, 0.15)
	bubble.visible = false
	add_child(bubble)


func _circle(r: float, col: Color) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.07
	tm.outer_radius = r + 0.07
	tm.rings = 72
	tm.ring_segments = 4
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = _unshaded(col, 1.2)
	return mi


func _particles(col: Color, amount: int, life: float, speed: float, grav: float, size: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -grav, 0)
	pm.scale_min = size * 0.6
	pm.scale_max = size
	pm.color = col
	var cv := Curve.new()
	cv.add_point(Vector2(0, 1))
	cv.add_point(Vector2(1, 0))
	var curve := CurveTexture.new()
	curve.curve = cv
	pm.scale_curve = curve
	p.process_material = pm
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := _unshaded(Color.WHITE, 2.0)
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	p.draw_pass_1 = mesh
	p.visibility_aabb = AABB(Vector3(-10, -2, -10), Vector3(20, 14, 20))
	return p


func _build_pools() -> void:
	var defs := {"explosion": [Color(1.0, 0.55, 0.15), 48, 0.7, 9.0, 6.0, 2.2], "hit": [Color(1.0, 0.95, 0.8), 10, 0.3, 5.0, 8.0, 0.6],
		"death": [Color(0.7, 0.5, 1.0), 14, 0.8, 3.0, -1.5, 1.0], "level": [Color(1.0, 0.9, 0.4), 60, 1.2, 7.0, -2.0, 1.2],
		"magic": [Color(0.7, 0.3, 1.0), 30, 0.7, 5.0, 0.0, 1.0], "shield": [Color(0.6, 0.85, 1.0), 24, 0.6, 6.0, 9.0, 0.8],
		"heal": [Color(0.4, 1.0, 0.5), 20, 1.0, 2.0, -3.0, 0.9]}
	for k in defs:
		var d: Array = defs[k]
		var list: Array = []
		for i in (16 if k == "hit" or k == "death" else 6):
			var p := _particles(d[0], d[1], d[2], d[3], d[4], d[5])
			add_child(p)
			list.append(p)
		particles[k] = {"list": list, "i": 0}
	for i in 24:
		var z := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.0
		cm.bottom_radius = 1.0
		cm.height = 0.05
		cm.radial_segments = 32
		z.mesh = cm
		z.material_override = _unshaded(Color.WHITE, 0.3)
		z.visible = false
		add_child(z)
		var coins := _mi(Models.prop("coins"), Vector3.ZERO, Models.glow_material(0.6))
		coins.visible = false
		add_child(coins)
		zone_pool.append({"disc": z, "coins": coins})
	for i in 64:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.font_size = 52
		l.outline_size = 12
		l.visible = false
		add_child(l)
		number_pool.append({"n": l, "t": 0.0})
	for i in 16:
		var e := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.9
		tm.outer_radius = 1.0
		tm.rings = 32
		tm.ring_segments = 4
		e.mesh = tm
		e.material_override = _unshaded(Color(1, 0.6, 0.2, 0.8), 2.0)
		e.visible = false
		add_child(e)
		burst_pool.append({"n": e, "t": 0.0, "r": 1.0})
	for i in 32:
		var s := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.07, 0.07, 1.0)
		s.mesh = bm
		s.material_override = _unshaded(Color(1, 0.95, 0.7), 3.0)
		s.visible = false
		add_child(s)
		shot_pool.append({"n": s, "t": 0.0})
	var om := SphereMesh.new()
	om.radius = 0.16
	om.height = 0.32
	om.radial_segments = 8
	om.rings = 4
	for i in 48:
		var o := MeshInstance3D.new()
		o.mesh = om
		o.material_override = _unshaded(Color(0.6, 1.0, 0.85), 3.0)
		o.visible = false
		add_child(o)
		orb_pool.append({"n": o, "t": 0.0, "from": Vector3.ZERO})


func build_arena() -> void:
	arena_root = Node3D.new()
	add_child(arena_root)
	var A := sim.arena
	var c := Vector3(A.cx, 0, A.cy)
	var r: float = sim.data.rules["arena"]["radius"]
	var k := Models.Kit.new()
	k.add(Models.cyl(r + 1.0, r + 1.2, 0.3, 40), Vector3(0, -0.12, 0), Color(0.16, 0.13, 0.2))
	for ring in 4:
		var tm := TorusMesh.new()
		tm.inner_radius = r * (ring + 1) / 4.5 - 0.15
		tm.outer_radius = r * (ring + 1) / 4.5
		tm.rings = 48
		tm.ring_segments = 3
		k.add(tm, Vector3(0, 0.04, 0), Color(0.3, 0.2, 0.38), Vector3.ZERO, Vector3(1, 0.1, 1))
	arena_root.add_child(_mi(k.done(), c))
	var n := 10
	for i in n:
		var a := TAU * i / n
		var pp := c + Vector3(cos(a), 0, sin(a)) * (r + 2.5)
		arena_root.add_child(_mi(Models.prop("pillar" if i % 2 == 0 else "brazier"), pp, Models.glow_material(0.0 if i % 2 == 0 else 0.6)))
		if i % 2 == 1:
			arena_root.add_child(_light(pp + Vector3(0, 2.5, 0), Color(1.0, 0.55, 0.2), 2.5, 14.0))
	arena_root.add_child(_light(c + Vector3(0, 7, 0), Color(0.75, 0.35, 1.0), 3.0, 26.0))
	for id in A.part_ids:
		var p := _mi(Models.boss_part(id), Vector3(A.bx, 0, A.by) + PART_OFFSETS[id], Models.glow_material(0.25))
		arena_root.add_child(p)
		part_nodes.append(p)
	for i in A.altar_pos.size():
		var ap: Vector2 = A.altar_pos[i]
		var a := _mi(Models.prop("altar"), Vector3(ap.x, 0, ap.y), Models.glow_material(0.5))
		var lab := Label3D.new()
		lab.text = str(i + 1)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.font_size = 80
		lab.outline_size = 16
		lab.modulate = Color(0.85, 0.7, 1.0)
		lab.position = Vector3(0, 2.2, 0)
		lab.no_depth_test = true
		a.add_child(lab)
		arena_root.add_child(a)
		altar_nodes.append(a)
	boss_face = MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.25, 0.05, 6.0)
	boss_face.mesh = fm
	boss_face.material_override = _unshaded(Color(1, 0.3, 0.3, 0.45), 1.5)
	arena_root.add_child(boss_face)


func show_placement(on: bool, pos: Vector3, valid: bool, radius: float) -> void:
	ring_min.visible = on
	ring_max.visible = on
	ghost.visible = on
	if not on:
		return
	ghost.position = pos + Vector3(0, 0.05, 0)
	ghost.scale = Vector3(radius, 1, radius)
	var c := Color(0.4, 1, 0.5) if valid else Color(1, 0.3, 0.3)
	ghost_mat.albedo_color = Color(c.r, c.g, c.b, 0.4)
	ghost_mat.emission = c


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
		if flash[i] > 0.0:
			flash[i] = maxf(0.0, flash[i] - delta * 6.0)
	var hx := sim.hero.x
	var hy := sim.hero.y
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
		var hop: float = e["hop"]
		var fly: bool = e["fly"]
		for q in n:
			var i: int = ids[q]
			var s := 1.0
			if U.gen[i] > 0:
				s = 0.72 if U.gen[i] == 1 else 0.5
			var x := lerpf(U.ox[i], U.px[i], alpha)
			var z := lerpf(U.oy[i], U.py[i], alpha)
			var vx := U.px[i] - U.ox[i]
			var vz := U.py[i] - U.oy[i]
			var moving := clampf(sqrt(vx * vx + vz * vz) / (sim.dt * 1.5), 0.0, 1.0)
			var fx := hx - x
			var fz := hy - z
			if U.fear_t[i] > 0.0:
				fx = -fx
				fz = -fz
			var a := atan2(-fx, -fz)
			var ca := cos(a) * s
			var sa := sin(a) * s
			var col := Color.WHITE
			if U.flags[i] & K.F_STONE:
				col = Color(0.55, 0.55, 0.6)
			elif U.fear_t[i] > 0.0:
				col = Color(0.8, 0.6, 1.0)
			var y := 0.0
			if fly:
				y = 1.6 + sin(sim.t * 7.0 + i) * 0.25
			var o := q * STRIDE
			buf[o] = ca; buf[o + 1] = 0.0; buf[o + 2] = sa; buf[o + 3] = x
			buf[o + 4] = 0.0; buf[o + 5] = s; buf[o + 6] = 0.0; buf[o + 7] = y
			buf[o + 8] = -sa; buf[o + 9] = 0.0; buf[o + 10] = ca; buf[o + 11] = z
			buf[o + 12] = col.r; buf[o + 13] = col.g; buf[o + 14] = col.b; buf[o + 15] = 1.0
			buf[o + 16] = flash[i]; buf[o + 17] = hop * maxf(moving, 0.25 if hop > 0.0 else 0.0); buf[o + 18] = float(i) * 1.7; buf[o + 19] = 0.0
		mm.buffer = buf
		e["buf"] = buf
	_draw_hero(alpha, delta)
	_draw_road_state()
	_draw_zones()
	_draw_arena(delta)
	_tick_pools(delta, alpha)
	_camera(alpha, delta)


func hero_pos(alpha: float) -> Vector3:
	var h := sim.hero
	return Vector3(lerpf(h.ox, h.x, alpha), 0.0, lerpf(h.oy, h.y, alpha))


func _draw_hero(alpha: float, delta: float) -> void:
	var h := sim.hero
	var p := hero_pos(alpha)
	var moved := Vector2(h.x - h.ox, h.y - h.oy).length() / sim.dt
	hero_root.position = p
	var f := Vector3(h.face_x, 0, h.face_y)
	if f.length() > 0.01:
		hero_root.rotation.y = atan2(-f.x, -f.z)
	hero_body.position.y = absf(sin(sim.t * 9.0)) * 0.12 * clampf(moved / 3.0, 0.0, 1.0)
	swing_t = maxf(0.0, swing_t - delta)
	var sw := sin((1.0 - swing_t / 0.28) * PI) if swing_t > 0.0 else 0.0
	sword_pivot.rotation = Vector3(-0.3 - sw * 1.4, -sw * 1.2, 0)
	# O herói brilha mais a cada nível (GDD).
	var glow := 0.05 + h.level * 0.035
	if h.petrify_t > 0.0:
		glow = 0.0
	hero_mat.set_shader_parameter("emission_boost", glow)
	shield_node.visible = h.shield_hp > 0.0 and h.petrify_t <= 0.0
	shield_node.scale = Vector3(1.6, 1.3, 1) if h.shield_cos < 0.6 else Vector3.ONE
	hero_light.light_energy = 1.4 + h.level * 0.08
	ring_min.position = p + Vector3(0, 0.06, 0)
	ring_max.position = p + Vector3(0, 0.06, 0)


func _draw_road_state() -> void:
	if sim.phase != K.Phase.ROAD:
		return
	for r in road_meshes:
		var leg: Dictionary = sim.road.legs[r.get_meta("leg")]
		var b: int = r.get_meta("branch")
		var em := 0.0
		var dim := false
		if leg["kind"] == "fork":
			if leg["closed"] == b or (leg["chosen"] >= 0 and leg["chosen"] != b):
				dim = true
			elif leg["forced"] == b:
				em = 0.4
		var m: ShaderMaterial = r.material_override
		m.set_shader_parameter("emission_boost", em)
		r.transparency = 0.6 if dim else 0.0
	for li in loc_nodes.size():
		var loc: Dictionary = sim.road.locations[li]
		var n: Node3D = loc_nodes[li]
		var lab: Label3D = n.get_meta("lab")
		var st: int = loc["state"]
		var txt := tr("LOC_" + str(loc["type"]))
		if loc["type"] == "shrine" and loc["entered"] and st == SimRoad.LocState.ACTIVE:
			txt = "%s  %d" % [txt, ceili(float(loc["t"]))]
			var ring: MeshInstance3D = n.get_meta("ring")
			var s := 1.0 + 0.04 * sin(sim.t * 10.0)
			ring.scale = Vector3(s, 0.2, s)
		elif loc["type"] == "ritual" and st == SimRoad.LocState.ACTIVE and loc["hp"] < loc["max_hp"]:
			txt = "%s  %d%%" % [txt, int(100.0 * loc["hp"] / loc["max_hp"])]
		lab.text = txt
		lab.modulate.a = 0.35 if st != SimRoad.LocState.ACTIVE else 1.0
		if st == SimRoad.LocState.DESTROYED and loc["type"] != "shrine" and n.visible:
			n.visible = false
			emit_particles("explosion", n.position, 1.0)


func _draw_zones() -> void:
	var k := 0
	for z in sim.zones:
		if k >= zone_pool.size():
			break
		var kind: String = z["kind"]
		if kind == "army":
			continue
		var e: Dictionary = zone_pool[k]
		var disc: MeshInstance3D = e["disc"]
		var coins: MeshInstance3D = e["coins"]
		var pos := Vector3(z["x"], 0.05, z["y"])
		coins.visible = kind == "bait"
		disc.visible = kind != "bait"
		if kind == "bait":
			coins.position = pos
			coins.rotation.y = sim.t * 2.0
		else:
			disc.position = pos
			var r := float(z["r"])
			disc.scale = Vector3(r, 1, r)
			var mat: StandardMaterial3D = disc.material_override
			var c := Color(0.35, 0.35, 0.45, 0.22) if kind == "web" else Color(1.0, 0.45, 0.08, 0.32 + 0.06 * sin(sim.t * 8.0))
			mat.albedo_color = c
			mat.emission = Color(c.r, c.g, c.b)
			mat.emission_energy_multiplier = 0.05 if kind == "web" else 0.6
		k += 1
	for i in range(k, zone_pool.size()):
		zone_pool[i]["disc"].visible = false
		zone_pool[i]["coins"].visible = false


func _draw_arena(delta: float) -> void:
	if arena_root == null or not sim.arena.active:
		return
	var A := sim.arena
	var yaw := atan2(-A.face.x, -A.face.y)
	for k in part_nodes.size():
		var n: MeshInstance3D = part_nodes[k]
		var off: Vector3 = PART_OFFSETS[A.part_ids[k]]
		var target := Vector3(A.bx, 0, A.by) + off.rotated(UP, yaw)
		n.position = n.position.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
		n.rotation.y = yaw
		n.visible = A.part_hp[k] > 0.0
		var m: ShaderMaterial = n.material_override
		m.set_shader_parameter("emission_boost", 0.9 if A.fury_t > 0.0 else (0.3 if A.part_attackable(k) else 0.05))
	for k in altar_nodes.size():
		altar_nodes[k].visible = A.altar_alive[k]
	boss_face.position = Vector3(A.bx, 0.08, A.by) + Vector3(A.face.x, 0, A.face.y) * 4.5
	boss_face.look_at(boss_face.position + Vector3(A.face.x, 0, A.face.y), UP)


func _tick_pools(delta: float, alpha: float) -> void:
	for e in number_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var l: Label3D = e["n"]
			l.position += Vector3(0, 1.8 * delta, 0)
			var life: float = e["t"]
			l.modulate.a = clampf(life / 0.4, 0.0, 1.0)
			l.scale = Vector3.ONE * (1.0 + clampf((life - 0.6) / 0.2, 0.0, 1.0) * 0.6)
			if life <= 0.0:
				l.visible = false
	for e in burst_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var n: MeshInstance3D = e["n"]
			var k: float = 1.0 - float(e["t"]) / 0.4
			var r: float = float(e["r"]) * (0.3 + 0.9 * k)
			n.scale = Vector3(r, 0.3, r)
			var m: StandardMaterial3D = n.material_override
			m.albedo_color.a = 0.8 * (1.0 - k)
			if e["t"] <= 0.0:
				n.visible = false
	for e in shot_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			if e["t"] <= 0.0:
				e["n"].visible = false
	var hp := hero_pos(alpha) + Vector3(0, 1.2, 0)
	for e in orb_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var k: float = clampf(1.0 - float(e["t"]) / 0.6, 0.0, 1.0)
			var from: Vector3 = e["from"]
			var pos := from.lerp(hp, k * k)
			pos.y += sin(k * PI) * 2.0
			e["n"].position = pos
			if e["t"] <= 0.0:
				e["n"].visible = false
	if bubble_t > 0.0:
		bubble_t -= delta
		var bp := hp + Vector3(0, 2.6, 0)
		if bubble_on_boss and sim.arena.active:
			bp = Vector3(sim.arena.bx, 7.5, sim.arena.by)
		bubble.position = bp
		bubble.modulate.a = clampf(bubble_t / 0.4, 0.0, 1.0)
		bubble.visible = bubble_t > 0.0
	if flash_t > 0.0:
		flash_t -= delta
		flash_light.light_energy = maxf(0.0, flash_t / 0.25) * 6.0


func _camera(alpha: float, delta: float) -> void:
	var target := hero_pos(alpha)
	if sim.phase == K.Phase.ARENA:
		target = target.lerp(Vector3(sim.arena.bx, 0, sim.arena.by), 0.4)
	cam_pos = cam_pos.lerp(target, clampf(delta * 5.0, 0.0, 1.0))
	var dist := 26.0 + minf(float(sim.units.count), 300.0) * 0.04
	if sim.phase == K.Phase.ARENA:
		dist += 8.0
	var off := Vector3(0, dist * 0.8, dist * 0.6)
	var sh := Vector3.ZERO
	if shake > 0.0:
		shake -= delta
		sh = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 1.2
	cam.position = cam_pos + off + sh
	cam.look_at(cam_pos + Vector3(0, 0, -2) + sh * 0.5, UP)


# ---------------------------------------------------------------- eventos

func emit_particles(kind: String, pos: Vector3, scale_ := 1.0) -> void:
	var d: Dictionary = particles[kind]
	var list: Array = d["list"]
	var p: GPUParticles3D = list[d["i"]]
	d["i"] = (int(d["i"]) + 1) % list.size()
	p.position = pos
	p.scale = Vector3.ONE * scale_
	p.restart()
	p.emitting = true


func number(pos: Vector3, txt: String, col: Color, size := 52) -> void:
	var e: Dictionary = number_pool[number_i]
	number_i = (number_i + 1) % number_pool.size()
	var l: Label3D = e["n"]
	l.text = txt
	l.modulate = col
	l.font_size = size
	l.position = pos + Vector3(randf_range(-0.5, 0.5), 2.4, randf_range(-0.2, 0.2))
	l.visible = true
	e["t"] = 0.8


func ring_burst(pos: Vector3, r: float, col: Color) -> void:
	var e: Dictionary = burst_pool[burst_i]
	burst_i = (burst_i + 1) % burst_pool.size()
	var n: MeshInstance3D = e["n"]
	n.position = pos + Vector3(0, 0.2, 0)
	var m: StandardMaterial3D = n.material_override
	m.albedo_color = col
	m.emission = Color(col.r, col.g, col.b)
	n.visible = true
	e["t"] = 0.4
	e["r"] = r


func shot(a: Vector3, b: Vector3) -> void:
	var e: Dictionary = shot_pool[shot_i]
	shot_i = (shot_i + 1) % shot_pool.size()
	var n: MeshInstance3D = e["n"]
	var l := a.distance_to(b)
	if l < 0.1:
		return
	n.position = (a + b) * 0.5 + Vector3(0, 1.1, 0)
	n.look_at(b + Vector3(0, 1.1, 0), UP)
	n.scale = Vector3(1, 1, l)
	n.visible = true
	e["t"] = 0.07


func orb(from: Vector3) -> void:
	var e: Dictionary = orb_pool[orb_i]
	orb_i = (orb_i + 1) % orb_pool.size()
	e["from"] = from + Vector3(0, 0.6, 0)
	e["t"] = 0.6
	e["n"].visible = true


## Fala cômica num balão sobre o herói ou o chefe.
func say(key_prefix: String, n: int, on_boss: bool, col: Color) -> void:
	if bubble_t > 0.5:
		return
	bubble.text = tr("%s_%d" % [key_prefix, randi_range(1, n)])
	bubble.modulate = col
	bubble_on_boss = on_boss
	bubble.visible = true
	bubble_t = 2.6


func light_flash(pos: Vector3, col: Color) -> void:
	flash_light.position = pos + Vector3(0, 2, 0)
	flash_light.light_color = col
	flash_t = 0.25


func handle_events(evs: Array) -> void:
	var U := sim.units
	for ev in evs:
		var k: int = ev[0]
		var p := Vector3(ev[1], 0, ev[2])
		match k:
			K.Ev.DAMAGE_HERO:
				if float(ev[3]) >= 3.0:
					number(p, str(int(ev[3])), Color(1, 0.35, 0.3), 56 if float(ev[3]) < 100.0 else 80)
			K.Ev.DAMAGE_UNIT:
				var i: int = ev[4]
				swing_t = 0.28
				if i >= 0 and i < flash.size():
					flash[i] = 1.0
					if randf() < 0.35:
						emit_particles("hit", p + Vector3(0, 0.8, 0), 0.7)
				else:
					emit_particles("hit", p + Vector3(0, 2.0, 0), 1.5)
				number(p, str(int(ev[3])), Color(1, 1, 1, 0.9), 36)
			K.Ev.DEATH:
				var i: int = ev[4]
				if i >= 0 and i < U.cap:
					emit_particles("death", p + Vector3(0, 0.5, 0), 0.8)
					if not (U.flags[i] & K.F_NO_XP) and U.xp[i] > 0.0:
						orb(p)
			K.Ev.EXPLOSION:
				emit_particles("explosion", p + Vector3(0, 0.6, 0), float(ev[3]) / 2.5)
				ring_burst(p, float(ev[3]), Color(1, 0.55, 0.15))
				light_flash(p, Color(1, 0.6, 0.25))
				shake = maxf(shake, 0.18)
			K.Ev.SHOT:
				shot(p, Vector3(ev[3], 0, float(ev[4]) / 100.0))
			K.Ev.SPIN:
				ring_burst(p, float(ev[3]), Color(0.7, 0.85, 1.0))
				swing_t = 0.28
			K.Ev.HERO_LEVEL:
				emit_particles("level", p + Vector3(0, 0.5, 0), 1.0)
				ring_burst(p, 3.0, Color(1, 0.9, 0.4))
				number(p + Vector3(0, 1.5, 0), tr("UI_HERO_LEVEL").format({"n": int(ev[3])}), Color(1, 0.88, 0.35), 76)
				if int(ev[3]) % 3 == 0:
					say("SAY_HERO", 4, false, Color(0.75, 0.88, 1.0))
			K.Ev.PLAYER_LEVEL:
				number(p + Vector3(0, 2.5, 0), tr("UI_PLAYER_LEVEL").format({"n": int(ev[3])}), Color(0.85, 0.55, 1.0), 76)
			K.Ev.SHIELD_BREAK:
				emit_particles("shield", p + Vector3(0, 1.2, 0), 1.0)
			K.Ev.HEAL:
				if float(ev[3]) >= 20.0:
					number(p, "+" + str(int(ev[3])), Color(0.45, 1, 0.55))
					emit_particles("heal", p + Vector3(0, 0.5, 0), 0.8)
			K.Ev.PART_DESTROYED:
				emit_particles("explosion", p + Vector3(0, 2.0, 0), 2.5)
				emit_particles("magic", p + Vector3(0, 2.0, 0), 2.0)
				ring_burst(p, 6.0, Color(0.9, 0.3, 1.0))
				light_flash(p, Color(0.9, 0.4, 1.0))
				shake = 0.5
				if float(ev[3]) >= 0.0:
					say("SAY_BOSS_PART", 3, true, Color(1.0, 0.6, 0.9))
			K.Ev.TELEPORT:
				emit_particles("magic", p + Vector3(0, 1.0, 0), 1.6)
				emit_particles("magic", Vector3(sim.arena.bx, 1.0, sim.arena.by), 1.6)
				say("SAY_BOSS_TP", 2, true, Color(1.0, 0.6, 0.9))
			K.Ev.SPELL:
				var di := int(ev[3])
				if di >= 0 and di < sim.data.cards.size():
					var c: CardDef = sim.data.cards[di]
					if c.category == "finisher":
						say("SAY_BOSS_FIN", 2, true, Color(1.0, 0.85, 0.4))
					if c.is_spell or c.category == "finisher":
						emit_particles("magic", p + Vector3(0, 0.5, 0), 1.2)
						ring_burst(p, float(c.fx.get("radius", 2.0)), Color(0.75, 0.35, 1.0))
					elif c.is_unit:
						ring_burst(p, 1.5, Color(0.6, 0.4, 1.0))
			K.Ev.CURSE:
				emit_particles("magic", p + Vector3(0, 1.4, 0), 0.6)
			K.Ev.SHRINE:
				emit_particles("level" if float(ev[3]) > 0.0 else "explosion", p + Vector3(0, 1.0, 0), 1.5)
			K.Ev.FEAR:
				ring_burst(p, 2.0, Color(0.6, 0.3, 1.0))
