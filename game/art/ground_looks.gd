class_name GroundLooks
extends RefCounted
## Chão, estrada, grama, luz, céu e névoa de cada ato. Três presets: 10 primavera (ato 1), 11 outono (ato 2) e
## 12 crepúsculo na terra amaldiçoada (ato 3); look() escolhe pelo "ground_look" do ato (rules.acts). O chão e a
## estrada são pintados no shader (ground_tela/road_tela, estilo 2 = relva pincelada, 22/11/2026), com as cores do preset.

const PRESETS := {
	# Ato 1: primavera de dia. Cenário de Models.prop() vem de assets/models/v2 quando existe.
	10: {
		"wshader": 5, "props_dir": "v2", "props_sfx": "",
		# Diorama C (26/11/2026): colcha de retalhos de feltro verde costurados e estrada de feltro bege; sem tufos.
		"params": {"c_grass": Color(0.3, 0.48, 0.28), "c_grass2": Color(0.44, 0.58, 0.3), "c_dirt": Color(0.5, 0.66, 0.34),
			"c_rock": Color(0.55, 0.55, 0.5), "c_fleck": Color(1.0, 0.88, 0.55), "dirt_amount": 0.0, "rock_amount": 0.0, "bump": 0.0},
		"road_c": Color(0.95, 0.8, 0.6), "road_dark": Color(0.88, 0.72, 0.52), "road_edge": Color(0.62, 0.5, 0.38), "bands": 0.0,
		"grass_base": Color(0.2, 0.3, 0.08), "grass_tip": Color(0.55, 0.66, 0.24), "grass": 0.0,
		"trees": [Color(1.0, 1.0, 1.0), Color(0.92, 1.04, 0.95), Color(1.06, 1.0, 0.88)],
		"sun_rot": Vector3(-46, -38, 0), "sun_col": Color(1.0, 0.9, 0.76), "sun_e": 1.8,
		"amb": Color(0.55, 0.66, 0.9), "amb_e": 0.68, "rim_col": Color(1.0, 0.82, 0.7), "rim_e": 0.35,
		"sky_top": Color(0.32, 0.5, 0.8), "sky_hor": Color(0.96, 0.8, 0.72), "gnd": Color(0.2, 0.24, 0.2),
		"fog": Color(0.66, 0.72, 0.9), "fog_d": 0.0028, "vfog": Color(0.85, 0.85, 0.95), "vfog_d": 0.0006, "vfog_e": Color(0.0, 0.0, 0.0),
		"exposure": 0.93, "adj_sat": 1.04,
		"env": {"fog_height": 0.0, "fog_height_density": 0.04, "fog_sky_affect": 0.7, "fog_aerial_perspective": 0.2,
			"ssao_intensity": 2.2, "ssao_radius": 1.2, "adjustment_contrast": 1.1, "glow_intensity": 0.45, "glow_hdr_threshold": 1.4, "glow_bloom": 0.04},
		"sun": {"shadow_blur": 0.8, "light_angular_distance": 0.0},
	},
	# Ato 2: as mesmas peças, com a folhagem tingida por instância, outro chão e outra luz (outono ao fim da tarde).
	11: {
		"wshader": 5, "props_dir": "v2", "props_sfx": "",
		"params": {"c_grass": Color(0.36, 0.34, 0.16), "c_grass2": Color(0.55, 0.38, 0.16), "c_dirt": Color(0.5, 0.34, 0.22),
			"c_rock": Color(0.46, 0.4, 0.3), "c_fleck": Color(1.0, 0.6, 0.3), "dirt_amount": 0.38, "rock_amount": 0.05, "bump": 0.8},
		"road_c": Color(0.56, 0.42, 0.3), "road_dark": Color(0.45, 0.33, 0.24), "road_edge": Color(0.32, 0.22, 0.1), "bands": 0.0,
		"grass_base": Color(0.22, 0.15, 0.05), "grass_tip": Color(0.85, 0.55, 0.22), "grass": 0.7,
		"trees": [Color(2.6, 1.0, 0.45), Color(2.2, 0.8, 0.4), Color(2.0, 1.25, 0.5), Color(1.4, 1.1, 0.7)],
		"sun_rot": Vector3(-30, -60, 0), "sun_col": Color(1.0, 0.78, 0.55), "sun_e": 1.68,
		"amb": Color(0.55, 0.5, 0.7), "amb_e": 0.6, "rim_col": Color(1.0, 0.7, 0.45), "rim_e": 0.5,
		"sky_top": Color(0.32, 0.36, 0.6), "sky_hor": Color(1.0, 0.66, 0.42), "gnd": Color(0.22, 0.16, 0.1),
		"fog": Color(0.78, 0.62, 0.55), "fog_d": 0.003, "vfog": Color(0.95, 0.78, 0.62), "vfog_d": 0.0008, "vfog_e": Color(0.0, 0.0, 0.0),
		"exposure": 0.94, "adj_sat": 1.05,
		"env": {"fog_height": 0.0, "fog_height_density": 0.05, "fog_sky_affect": 0.7, "fog_aerial_perspective": 0.25,
			"ssao_intensity": 2.2, "ssao_radius": 1.2, "adjustment_contrast": 1.1, "glow_intensity": 0.52, "glow_hdr_threshold": 1.4, "glow_bloom": 0.05},
		"sun": {"shadow_blur": 0.8, "light_angular_distance": 0.0},
	},
	# Ato 3: terra amaldiçoada no crepúsculo, perto do covil (folhagem roxa e cinza, névoa lilás).
	12: {
		"wshader": 5, "props_dir": "v2", "props_sfx": "",
		"params": {"c_grass": Color(0.2, 0.2, 0.24), "c_grass2": Color(0.3, 0.24, 0.3), "c_dirt": Color(0.32, 0.25, 0.26),
			"c_rock": Color(0.45, 0.42, 0.48), "c_fleck": Color(0.85, 0.5, 1.0), "dirt_amount": 0.4, "rock_amount": 0.08, "bump": 0.9,
			"fleck_amount": 0.8},
		"road_c": Color(0.4, 0.33, 0.34), "road_dark": Color(0.3, 0.24, 0.27), "road_edge": Color(0.12, 0.09, 0.14), "bands": 0.0,
		"grass_base": Color(0.06, 0.05, 0.08), "grass_tip": Color(0.35, 0.3, 0.42), "grass": 0.5,
		"trees": [Color(1.3, 0.75, 1.6), Color(0.9, 0.8, 1.2), Color(1.1, 0.6, 1.3), Color(0.8, 0.8, 0.9)],
		"sun_rot": Vector3(-28, 140, 0), "sun_col": Color(1.0, 0.62, 0.62), "sun_e": 1.35,
		"amb": Color(0.45, 0.38, 0.62), "amb_e": 0.64, "rim_col": Color(0.9, 0.5, 1.0), "rim_e": 0.8,
		"sky_top": Color(0.1, 0.06, 0.18), "sky_hor": Color(0.62, 0.3, 0.42), "gnd": Color(0.06, 0.04, 0.08),
		"fog": Color(0.32, 0.22, 0.4), "fog_d": 0.004, "vfog": Color(0.7, 0.5, 0.85), "vfog_d": 0.002, "vfog_e": Color(0.03, 0.01, 0.04),
		"exposure": 0.97, "adj_sat": 1.0,
		"env": {"fog_height": 0.0, "fog_height_density": 0.1, "fog_sky_affect": 0.8, "ssao_intensity": 2.0,
			"adjustment_contrast": 1.12, "glow_intensity": 0.68, "glow_hdr_threshold": 1.4, "glow_bloom": 0.07},
		"sun": {"shadow_blur": 0.8, "light_angular_distance": 0.0},
	},
}

static var _tex: Dictionary = {}

## Estilo do ground_tela/road_tela: 2 = relva pincelada (escolhida em 22/11/2026).
const TELA := 2


## "ground_look" do ato atual (rules.acts[].ground_look: 2, 3 ou 4), posto pelo main.gd.
static var act_look := -1


static func look() -> int:
	return {3: 11, 4: 12}.get(act_look, 10)


static func preset() -> Dictionary:
	return PRESETS.get(look(), {})


## Look cujo shader os prédios, o cenário, o herói e os monstros usam (0 = cada um com o seu).
static func world_shader_look() -> int:
	return int(preset().get("wshader", 0))


## Luz, céu e névoa do look (chamado pelo main depois de montar o ambiente).
static func apply_env(env: Environment, sun: DirectionalLight3D, rim: DirectionalLight3D = null) -> void:
	var P := preset()
	if P.is_empty():
		return
	if rim:
		rim.light_color = P.get("rim_col", Color(0.55, 0.65, 1.0))
		rim.light_energy = P.get("rim_e", 0.7)
	sun.rotation_degrees = P["sun_rot"]
	sun.light_color = P["sun_col"]
	sun.light_energy = P["sun_e"]
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = P["sky_top"]
	sm.sky_horizon_color = P["sky_hor"]
	sm.ground_horizon_color = P["sky_hor"]
	sm.ground_bottom_color = P["gnd"]
	env.sky.sky_material = sm
	env.ambient_light_color = P["amb"]
	env.ambient_light_energy = P["amb_e"]
	env.fog_light_color = P["fog"]
	env.fog_density = P["fog_d"]
	env.volumetric_fog_albedo = P["vfog"]
	env.volumetric_fog_density = P["vfog_d"]
	env.volumetric_fog_emission = P["vfog_e"]
	env.tonemap_exposure = P["exposure"]
	env.adjustment_saturation = P["adj_sat"]
	for k in P.get("env", {}):
		env.set(k, P["env"][k])
	for k in P.get("sun", {}):
		sun.set(k, P["sun"][k])
	PaintLook.apply_env(env)


static func ground_material() -> ShaderMaterial:
	var P := preset()
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/ground_tela.gdshader")
	for k in P["params"]:
		m.set_shader_parameter(k, P["params"][k])
	m.set_shader_parameter("estilo", 7)
	m.set_shader_parameter("dio_velvet", 0.25)
	return m


static func road_material() -> ShaderMaterial:
	var P := preset()
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/road_tela.gdshader")
	for k in [["c_road", "road_c"], ["c_road_dark", "road_dark"], ["c_edge", "road_edge"], ["bands", "bands"]]:
		m.set_shader_parameter(k[0], P[k[1]])
	m.set_shader_parameter("estilo", 7 if look() == 10 else 4)
	# Ocre dos caminhos das cartas na primavera e no outono; a terra amaldiçoada fica no roxo acinzentado dela.
	m.set_shader_parameter("sand", {10: 0.0, 11: 0.55}.get(look(), 0.0))
	return m


## Material da estrada em campo único (uma máscara por ato, sem fitas): o mesmo da fita, com o campo ligado.
static func road_field_material(mask: Texture2D, ids: Texture2D, state: Texture2D, rect: Rect2, dmax: float) -> ShaderMaterial:
	var m := road_material()
	m.set_shader_parameter("use_mask", true)
	m.set_shader_parameter("road_mask", mask)
	m.set_shader_parameter("road_ids", ids)
	m.set_shader_parameter("road_state", state)
	m.set_shader_parameter("mask_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	m.set_shader_parameter("mask_dmax", dmax)
	return m


## Estrada com UV em metros (x através, 0 no centro; y ao longo) e alfa 0 na borda de fora.
## `lift` separa na altura os trechos que se sobrepõem perto das bifurcações (na mesma altura eles piscavam).
static func road_mesh(pts: PackedVector2Array, width: float, lift := 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var w := width * 0.5
	var cols := [[-w - 1.6, 0.0], [-w + 0.4, 1.0], [w - 0.4, 1.0], [w + 1.6, 0.0]]
	var along := 0.0
	var rows: Array = []
	for i in n:
		var d := Vector2.ZERO
		if i > 0:
			d += (pts[i] - pts[i - 1]).normalized()
			along += pts[i].distance_to(pts[i - 1])
		if i < n - 1:
			d += (pts[i + 1] - pts[i]).normalized()
		var o := d.normalized().orthogonal()
		var row := []
		for c in cols:
			var p: Vector2 = pts[i] + o * float(c[0])
			# Miolo mais alto que as bordas: onde dois trechos se cruzam (bifurcação), o miolo de um cobre
			# a borda do outro em vez de brigar com ela na mesma altura (cunhas de borda reta).
			var y := (0.02 if float(c[1]) > 0.5 else 0.004) + lift
			row.append([Vector3(p.x, y, p.y), Vector2(float(c[0]), along), float(c[1])])
		rows.append(row)
	for i in n - 1:
		for k in 3:
			var q := [rows[i][k], rows[i][k + 1], rows[i + 1][k], rows[i + 1][k], rows[i][k + 1], rows[i + 1][k + 1]]
			for v in q:
				st.set_color(Color(1, 1, 1, v[2]))
				st.set_uv(v[1])
				st.set_normal(Vector3.UP)
				st.set_tangent(Plane(1, 0, 0, 1))
				st.add_vertex(v[0])
	st.generate_tangents()
	return st.commit()


## Tufo de grama: 5 lâminas em leque (cada uma um triângulo duplo afinando).
static func grass_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for b in 7:
		var a := TAU * b / 7.0 + rng.randf() * 0.5
		var h := rng.randf_range(0.35, 0.7)
		var lean := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.08, 0.22)
		var side := Vector3(-sin(a), 0, cos(a)) * 0.035
		var base := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, 0.12)
		var p0 := base - side
		var p1 := base + side
		var p2 := base + lean * 0.5 + Vector3(0, h * 0.55, 0) + side * 0.6
		var p3 := base + lean * 0.5 + Vector3(0, h * 0.55, 0) - side * 0.6
		var p4 := base + lean + Vector3(0, h, 0)
		var nrm := Vector3(cos(a), 0.6, sin(a)).normalized()
		for v in [p0, p1, p2, p0, p2, p3, p3, p2, p4]:
			st.set_normal(nrm)
			st.set_color(Color.WHITE)
			st.add_vertex(v)
	return st.commit()


static func grass_material() -> ShaderMaterial:
	var P := preset()
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/grass.gdshader")
	m.set_shader_parameter("base_color", P["grass_base"])
	m.set_shader_parameter("tip_color", P["grass_tip"])
	return m


## Árvore/arbusto/pedra do cenário (pinceladas, miniaturas pintadas ou v2), ou null para usar a peça de Models.
static func prop_mesh(id: String) -> Mesh:
	if not id in ["tree", "tree_round", "dead_tree", "bush", "rock"]:
		return null
	if look() == 10:
		var dm := Diorama.mesh({"tree": "tree_s5", "tree_round": "tree_round_s5"}.get(id, id))
		if dm:
			return dm
	if id == "bush":
		var bm := Arvores.bush_mesh({11: 1, 12: 2}.get(look(), 0))
		if bm:
			return bm
	var gm := Looks.g_mesh(id)
	if gm:
		return gm
	var P := preset()
	var p := "res://assets/models/%s/%s%s.res" % [P["props_dir"], id, P.get("props_sfx", "")]
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]


static func prop_material(sway: bool) -> ShaderMaterial:
	var lm := Looks.material(world_shader_look())
	Looks.set_param(lm, "sway", 1.0 if sway else 0.0)
	return lm


## Cor para as árvores/arbustos espalhados (multiplica a cor dos vértices).
static func foliage_tint(rng: RandomNumberGenerator) -> Color:
	var P := preset()
	if P.is_empty():
		return Color.WHITE
	var arr: Array = P["trees"]
	return arr[rng.randi() % arr.size()]
