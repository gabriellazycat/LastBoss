class_name GroundLooks
extends RefCounted
## Variações do chão e do fundo (Settings.v["look_ground"] 1..4; 0 = o chão antigo).
## Cada look troca: textura do chão, estrada, grama com vento, cor das árvores, luz, céu e névoa.
## Texturas CC0 do Poly Haven em assets/textures/ground (tools/art/fetch_textures.py).

const NAMES := ["Atual", "Campina ao entardecer", "Bosque enluarado", "Outono", "Terra amaldiçoada",
	"Pintado (direção única)", "Cartum (direção única)", "Aventura · dia (RoR2)", "Aventura · noite (Soulstone)",
	"Própria refinada"]
const T := "res://assets/textures/ground/"

const PRESETS := {
	1: {
		"a": "aerial_grass_rock", "b": "leafy_grass", "road": "grass_path_2",
		"scale_a": 0.06, "scale_b": 0.08, "tint_a": Color(0.78, 1.0, 0.68), "tint_b": Color(0.85, 1.05, 0.7), "b_amount": 0.45,
		"patch": Color(0.85, 0.75, 0.4), "patch_amount": 0.22, "sat": 1.05,
		"road_tint": Color(1.25, 1.05, 0.85), "road_edge": Color(0.45, 0.42, 0.25),
		"grass_base": Color(0.06, 0.18, 0.04), "grass_tip": Color(0.5, 0.72, 0.25), "grass": 1.0,
		"trees": [Color(1.0, 1.0, 1.0), Color(0.9, 1.0, 0.85), Color(1.08, 1.04, 0.9)],
		"sun_rot": Vector3(-38, 35, 0), "sun_col": Color(1.0, 0.84, 0.62), "sun_e": 1.7,
		"amb": Color(0.5, 0.55, 0.72), "amb_e": 0.55,
		"sky_top": Color(0.2, 0.36, 0.7), "sky_hor": Color(0.98, 0.72, 0.5), "gnd": Color(0.2, 0.22, 0.12),
		"fog": Color(0.75, 0.62, 0.52), "fog_d": 0.0022, "vfog": Color(0.95, 0.8, 0.65), "vfog_d": 0.0022, "vfog_e": Color(0.04, 0.03, 0.02),
		"exposure": 1.0, "adj_sat": 1.02,
	},
	2: {
		"a": "forest_leaves_02", "b": "aerial_grass_rock", "road": "mossy_cobblestone",
		"scale_a": 0.11, "scale_b": 0.07, "tint_a": Color(0.6, 0.72, 0.75), "tint_b": Color(0.45, 0.62, 0.62), "b_amount": 0.5,
		"patch": Color(0.3, 0.55, 0.6), "patch_amount": 0.3, "sat": 0.9,
		"road_tint": Color(0.7, 0.8, 0.85), "road_edge": Color(0.2, 0.3, 0.3),
		"grass_base": Color(0.04, 0.1, 0.11), "grass_tip": Color(0.16, 0.32, 0.32), "grass": 0.5,
		"trees": [Color(1.0, 1.0, 1.0), Color(0.85, 0.95, 1.0), Color(0.95, 1.0, 1.05)],
		"sun_rot": Vector3(-55, -30, 0), "sun_col": Color(0.62, 0.78, 1.0), "sun_e": 1.45,
		"amb": Color(0.24, 0.32, 0.5), "amb_e": 0.42, "rim_col": Color(0.5, 0.75, 1.0), "rim_e": 0.55,
		"detail": 0.55, "nrm": 0.4,
		"sky_top": Color(0.02, 0.04, 0.1), "sky_hor": Color(0.1, 0.2, 0.3), "gnd": Color(0.02, 0.04, 0.05),
		"fog": Color(0.08, 0.16, 0.22), "fog_d": 0.0025, "vfog": Color(0.45, 0.75, 0.85), "vfog_d": 0.0025, "vfog_e": Color(0.01, 0.04, 0.05),
		"exposure": 1.1, "adj_sat": 1.05,
	},
	3: {
		"a": "dry_decay_leaves", "b": "forest_leaves_02", "road": "brown_mud_dry",
		"scale_a": 0.12, "scale_b": 0.1, "tint_a": Color(0.82, 0.8, 0.78), "tint_b": Color(0.95, 0.8, 0.65), "b_amount": 0.5,
		"patch": Color(0.9, 0.55, 0.3), "patch_amount": 0.2, "sat": 0.85,
		"road_tint": Color(0.95, 0.85, 0.72), "road_edge": Color(0.6, 0.35, 0.15),
		"grass_base": Color(0.22, 0.16, 0.05), "grass_tip": Color(0.9, 0.62, 0.25), "grass": 0.55,
		"trees": [Color(1.0, 1.0, 1.0), Color(1.08, 0.82, 0.75), Color(1.0, 1.1, 0.9), Color(1.05, 0.9, 0.8)],
		"sun_rot": Vector3(-34, -65, 0), "sun_col": Color(1.0, 0.82, 0.62), "sun_e": 1.3,
		"amb": Color(0.45, 0.45, 0.58), "amb_e": 0.55,
		"sky_top": Color(0.35, 0.3, 0.5), "sky_hor": Color(1.0, 0.6, 0.35), "gnd": Color(0.2, 0.12, 0.08),
		"fog": Color(0.62, 0.48, 0.42), "fog_d": 0.002, "vfog": Color(0.95, 0.8, 0.65), "vfog_d": 0.0015, "vfog_e": Color(0.02, 0.012, 0.006),
		"exposure": 1.0, "adj_sat": 1.0,
	},
	4: {
		"a": "burned_ground_01", "b": "mud_cracked_dry_03", "road": "cobblestone_floor_08",
		"scale_a": 0.08, "scale_b": 0.06, "tint_a": Color(0.6, 0.5, 0.56), "tint_b": Color(0.5, 0.38, 0.42), "b_amount": 0.55,
		"patch": Color(0.5, 0.2, 0.4), "patch_amount": 0.3, "sat": 0.75,
		"crack": Color(1.0, 0.3, 0.85), "crack_glow": 0.9, "crack_thr": 0.045,
		"road_tint": Color(0.55, 0.5, 0.58), "road_edge": Color(0.25, 0.1, 0.2),
		"grass_base": Color(0.1, 0.06, 0.07), "grass_tip": Color(0.42, 0.3, 0.28), "grass": 0.3,
		"trees": [Color(1.0, 1.0, 1.0), Color(0.9, 0.85, 0.95), Color(1.05, 0.95, 1.0)],
		"sun_rot": Vector3(-34, 140, 0), "sun_col": Color(1.0, 0.62, 0.52), "sun_e": 1.15,
		"amb": Color(0.38, 0.28, 0.42), "amb_e": 0.55,
		"sky_top": Color(0.08, 0.01, 0.06), "sky_hor": Color(0.55, 0.12, 0.2), "gnd": Color(0.05, 0.01, 0.03),
		"fog": Color(0.2, 0.06, 0.13), "fog_d": 0.004, "vfog": Color(0.7, 0.4, 0.55), "vfog_d": 0.0035, "vfog_e": Color(0.06, 0.0, 0.03),
		"exposure": 1.0, "adj_sat": 1.0,
	},
	# Direções de arte únicas: chão e estrada procedurais (sem foto), cenário e prédios no mesmo shader
	# dos monstros ("wshader": 3 = pintado, 2 = cartum). "props" = de qual look vêm árvores, arbustos e pedras.
	5: {
		"proc": true, "wshader": 3, "props": 1, "bands": 0.0,
		"g_dark": Color(0.07, 0.12, 0.11), "g_base": Color(0.13, 0.2, 0.15), "g_light": Color(0.2, 0.28, 0.2),
		"g_accent": Color(0.17, 0.1, 0.22), "accent": 0.3, "stroke": 0.22,
		"road_c": Color(0.36, 0.3, 0.29), "road_dark": Color(0.26, 0.21, 0.21), "road_edge": Color(0.08, 0.1, 0.09),
		"grass_base": Color(0.04, 0.08, 0.07), "grass_tip": Color(0.15, 0.24, 0.18), "grass": 0.45,
		"trees": [Color(0.32, 0.5, 0.45), Color(0.35, 0.42, 0.55), Color(0.42, 0.36, 0.55), Color(0.36, 0.5, 0.36)],
		"sun_rot": Vector3(-50, -35, 0), "sun_col": Color(0.78, 0.82, 1.0), "sun_e": 1.25,
		"amb": Color(0.25, 0.24, 0.42), "amb_e": 0.4, "rim_col": Color(1.0, 0.68, 0.55), "rim_e": 0.4,
		"sky_top": Color(0.03, 0.03, 0.09), "sky_hor": Color(0.16, 0.12, 0.25), "gnd": Color(0.03, 0.03, 0.05),
		"fog": Color(0.1, 0.08, 0.18), "fog_d": 0.002, "vfog": Color(0.5, 0.45, 0.75), "vfog_d": 0.0015, "vfog_e": Color(0.02, 0.01, 0.04),
		"exposure": 1.0, "adj_sat": 1.0,
	},
	6: {
		"proc": true, "wshader": 2, "props": 2, "bands": 3.0,
		"g_dark": Color(0.09, 0.14, 0.18), "g_base": Color(0.14, 0.22, 0.24), "g_light": Color(0.19, 0.29, 0.28),
		"g_accent": Color(0.22, 0.14, 0.3), "accent": 0.35, "stroke": 0.0,
		"road_c": Color(0.6, 0.48, 0.38), "road_dark": Color(0.5, 0.39, 0.32), "road_edge": Color(0.06, 0.04, 0.08),
		"grass_base": Color(0.06, 0.12, 0.13), "grass_tip": Color(0.18, 0.32, 0.3), "grass": 0.3,
		"trees": [Color(0.85, 1.0, 0.9), Color(1.0, 1.0, 1.0), Color(0.9, 0.85, 1.1)],
		"sun_rot": Vector3(-48, -30, 0), "sun_col": Color(0.88, 0.9, 1.0), "sun_e": 1.7,
		"amb": Color(0.3, 0.3, 0.5), "amb_e": 0.45, "rim_col": Color(0.7, 0.85, 1.0), "rim_e": 0.5,
		"sky_top": Color(0.04, 0.05, 0.12), "sky_hor": Color(0.2, 0.18, 0.35), "gnd": Color(0.03, 0.03, 0.06),
		"fog": Color(0.12, 0.12, 0.22), "fog_d": 0.0015, "vfog": Color(0.55, 0.55, 0.85), "vfog_d": 0.001, "vfog_e": Color(0.02, 0.02, 0.05),
		"exposure": 1.0, "adj_sat": 1.05,
	},
	# Direção "Aventura" (docs/ESTUDO_DE_ARTE.md): modelos CC0 (assets/models/cc0), chão ground_ror.gdshader.
	# "shader" + "params": chão por shader próprio; "props_dir" + "props_sfx": de onde vem o cenário;
	# "env"/"sun": propriedades extras do Environment e do sol (névoa por altura, AO, brilho, sombra).
	7: {
		"proc": true, "shader": "res://game/art/ground_ror.gdshader", "wshader": 5, "props_dir": "cc0", "props_sfx": "",
		"params": {"c_grass": Color(0.13, 0.3, 0.2), "c_grass2": Color(0.34, 0.4, 0.18), "c_dirt": Color(0.46, 0.36, 0.25),
			"c_rock": Color(0.62, 0.6, 0.58), "c_fleck": Color(0.98, 0.86, 0.5), "dirt_amount": 0.35, "rock_amount": 0.22, "bump": 0.7},
		"road_c": Color(0.56, 0.45, 0.32), "road_dark": Color(0.45, 0.35, 0.25), "road_edge": Color(0.2, 0.24, 0.14), "bands": 0.0,
		"grass_base": Color(0.07, 0.18, 0.11), "grass_tip": Color(0.4, 0.52, 0.22), "grass": 0.9,
		"trees": [Color(1.0, 1.0, 1.0), Color(0.92, 1.02, 0.95), Color(1.05, 1.0, 0.9)],
		"sun_rot": Vector3(-46, -38, 0), "sun_col": Color(1.0, 0.9, 0.76), "sun_e": 2.1,
		"amb": Color(0.55, 0.66, 0.9), "amb_e": 0.75, "rim_col": Color(1.0, 0.82, 0.7), "rim_e": 0.35,
		"sky_top": Color(0.32, 0.5, 0.8), "sky_hor": Color(0.96, 0.8, 0.72), "gnd": Color(0.2, 0.24, 0.2),
		"fog": Color(0.66, 0.72, 0.9), "fog_d": 0.0028, "vfog": Color(0.85, 0.85, 0.95), "vfog_d": 0.0006, "vfog_e": Color(0.0, 0.0, 0.0),
		"exposure": 1.0, "adj_sat": 1.12,
		"env": {"fog_height": 0.0, "fog_height_density": 0.04, "fog_sky_affect": 0.7, "fog_aerial_perspective": 0.2,
			"ssao_intensity": 2.2, "ssao_radius": 1.2, "adjustment_contrast": 1.12, "glow_intensity": 0.6, "glow_bloom": 0.04},
		"sun": {"shadow_blur": 1.5, "light_angular_distance": 1.0},
	},
	8: {
		"proc": true, "shader": "res://game/art/ground_ror.gdshader", "wshader": 5, "props_dir": "cc0", "props_sfx": "_n",
		"params": {"c_grass": Color(0.13, 0.22, 0.23), "c_grass2": Color(0.2, 0.25, 0.26), "c_dirt": Color(0.32, 0.25, 0.22),
			"c_rock": Color(0.42, 0.42, 0.46), "c_fleck": Color(0.6, 0.95, 0.85), "dirt_amount": 0.3, "rock_amount": 0.3, "bump": 0.9,
			"fleck_amount": 0.8},
		"road_c": Color(0.34, 0.28, 0.3), "road_dark": Color(0.25, 0.2, 0.24), "road_edge": Color(0.07, 0.06, 0.1), "bands": 0.0,
		"grass_base": Color(0.04, 0.06, 0.08), "grass_tip": Color(0.18, 0.22, 0.3), "grass": 0.5,
		"trees": [Color(0.75, 0.72, 0.85), Color(0.62, 0.68, 0.82), Color(0.82, 0.74, 0.88)],
		"sun_rot": Vector3(-52, -30, 0), "sun_col": Color(0.75, 0.82, 1.0), "sun_e": 1.6,
		"amb": Color(0.4, 0.42, 0.62), "amb_e": 0.65, "rim_col": Color(1.0, 0.6, 0.4), "rim_e": 0.9,
		"sky_top": Color(0.03, 0.04, 0.09), "sky_hor": Color(0.14, 0.15, 0.25), "gnd": Color(0.02, 0.02, 0.04),
		"fog": Color(0.1, 0.13, 0.2), "fog_d": 0.0035, "vfog": Color(0.5, 0.58, 0.78), "vfog_d": 0.0025, "vfog_e": Color(0.015, 0.01, 0.03),
		"exposure": 1.1, "adj_sat": 1.0,
		"env": {"fog_height": 0.0, "fog_height_density": 0.1, "fog_sky_affect": 0.8, "ssao_intensity": 2.0,
			"adjustment_contrast": 1.15, "glow_intensity": 1.0, "glow_bloom": 0.08},
	},
	# Direção "Própria refinada": modelos próprios (look 6) na luz da Aventura, fim de tarde dourado (Titanic
	# Plains do RoR2), cenário da campina (ground1) com menos triângulos (assets/models/ground9, tools/art/lod_props.gd).
	9: {
		"proc": true, "shader": "res://game/art/ground_ror.gdshader", "wshader": 6, "props": 9,
		"params": {"c_grass": Color(0.2, 0.34, 0.18), "c_grass2": Color(0.38, 0.4, 0.2), "c_dirt": Color(0.46, 0.34, 0.24),
			"c_rock": Color(0.6, 0.55, 0.5), "c_fleck": Color(1.0, 0.75, 0.55), "dirt_amount": 0.3, "rock_amount": 0.2, "bump": 0.8},
		"road_c": Color(0.6, 0.47, 0.33), "road_dark": Color(0.5, 0.38, 0.27), "road_edge": Color(0.26, 0.24, 0.12), "bands": 0.0,
		"grass_base": Color(0.12, 0.2, 0.08), "grass_tip": Color(0.62, 0.6, 0.28), "grass": 0.9,
		"trees": [Color(1.0, 1.0, 1.0), Color(1.08, 0.98, 0.85), Color(0.95, 1.05, 0.9)],
		"sun_rot": Vector3(-38, -50, 0), "sun_col": Color(1.0, 0.88, 0.72), "sun_e": 2.0,
		"amb": Color(0.5, 0.58, 0.85), "amb_e": 0.7, "rim_col": Color(1.0, 0.75, 0.55), "rim_e": 0.5,
		"sky_top": Color(0.26, 0.4, 0.72), "sky_hor": Color(0.98, 0.78, 0.62), "gnd": Color(0.2, 0.18, 0.12),
		"fog": Color(0.72, 0.7, 0.75), "fog_d": 0.0022, "vfog": Color(0.95, 0.85, 0.8), "vfog_d": 0.0005, "vfog_e": Color(0.0, 0.0, 0.0),
		"exposure": 1.0, "adj_sat": 1.05,
		"env": {"fog_height": 0.0, "fog_height_density": 0.04, "fog_sky_affect": 0.7, "ssao_intensity": 2.2, "ssao_radius": 1.2,
			"adjustment_contrast": 1.1, "glow_intensity": 0.6, "glow_bloom": 0.04},
		"sun": {"shadow_blur": 1.5},
	},
}

static var _tex: Dictionary = {}


static func look() -> int:
	return int(Settings.v.get("look_ground", 0))


static func preset() -> Dictionary:
	return PRESETS.get(look(), {})


## Look cujo shader os prédios, o cenário, o herói e os monstros usam (0 = cada um com o seu).
static func world_shader_look() -> int:
	return int(preset().get("wshader", 0))


static func tex(id: String, kind: String) -> Texture2D:
	var k := id + "_" + kind
	if not _tex.has(k):
		_tex[k] = load(T + k + ".jpg")
	return _tex[k]


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


static func ground_material() -> ShaderMaterial:
	var P := preset()
	var m := ShaderMaterial.new()
	if P.has("shader"):
		m.shader = load(P["shader"])
		for k in P["params"]:
			m.set_shader_parameter(k, P["params"][k])
		return m
	if P.get("proc", false):
		m.shader = load("res://game/art/ground_paint.gdshader")
		for k in [["c_dark", "g_dark"], ["c_base", "g_base"], ["c_light", "g_light"], ["c_accent", "g_accent"],
				["accent_amount", "accent"], ["stroke", "stroke"], ["bands", "bands"]]:
			m.set_shader_parameter(k[0], P[k[1]])
		return m
	m.shader = load("res://game/art/ground.gdshader")
	m.set_shader_parameter("tex_a", tex(P["a"], "diff"))
	m.set_shader_parameter("nor_a", tex(P["a"], "nor"))
	m.set_shader_parameter("tex_b", tex(P["b"], "diff"))
	m.set_shader_parameter("nor_b", tex(P["b"], "nor"))
	m.set_shader_parameter("scale_a", P["scale_a"])
	m.set_shader_parameter("scale_b", P["scale_b"])
	m.set_shader_parameter("tint_a", P["tint_a"])
	m.set_shader_parameter("tint_b", P["tint_b"])
	m.set_shader_parameter("b_amount", P["b_amount"])
	m.set_shader_parameter("patch_color", P["patch"])
	m.set_shader_parameter("patch_amount", P["patch_amount"])
	m.set_shader_parameter("saturation", P["sat"])
	m.set_shader_parameter("detail", P.get("detail", 1.0))
	m.set_shader_parameter("normal_strength", P.get("nrm", 0.8))
	if P.has("crack"):
		m.set_shader_parameter("crack_color", P["crack"])
		m.set_shader_parameter("crack_glow", P["crack_glow"])
		m.set_shader_parameter("crack_threshold", P["crack_thr"])
	return m


static func road_material() -> ShaderMaterial:
	var P := preset()
	var m := ShaderMaterial.new()
	if P.get("proc", false):
		m.shader = load("res://game/art/road_paint.gdshader")
		for k in [["c_road", "road_c"], ["c_road_dark", "road_dark"], ["c_edge", "road_edge"], ["bands", "bands"]]:
			m.set_shader_parameter(k[0], P[k[1]])
		return m
	m.shader = load("res://game/art/road.gdshader")
	m.set_shader_parameter("tex", tex(P["road"], "diff"))
	m.set_shader_parameter("nor", tex(P["road"], "nor"))
	m.set_shader_parameter("tint", P["road_tint"])
	m.set_shader_parameter("edge_color", P["road_edge"])
	return m


## Estrada com UV em metros (x através, 0 no centro; y ao longo) e alfa 0 na borda de fora.
static func road_mesh(pts: PackedVector2Array, width: float) -> ArrayMesh:
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
			var y := 0.02 if float(c[1]) > 0.5 else 0.004
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


## Árvore/arbusto/pedra modelados para o look (tools/art/props.py), ou null para usar o antigo.
static func prop_mesh(id: String) -> Mesh:
	if look() == 0 or not id in ["tree", "tree_round", "dead_tree", "bush", "rock"]:
		return null
	var P := preset()
	var p := "res://assets/models/ground%d/%s.res" % [int(P.get("props", look())), id]
	if P.has("props_dir"):
		p = "res://assets/models/%s/%s%s.res" % [P["props_dir"], id, P.get("props_sfx", "")]
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]


static func prop_material(sway: bool) -> ShaderMaterial:
	var wl := world_shader_look()
	if wl > 0:
		var lm := Looks.material(wl)
		Looks.set_param(lm, "sway", 1.0 if sway else 0.0)
		return lm
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/prop.gdshader")
	m.set_shader_parameter("sway", 1.0 if sway else 0.0)
	return m


## Cor para as árvores/arbustos espalhados (multiplica a cor dos vértices).
static func foliage_tint(rng: RandomNumberGenerator) -> Color:
	var P := preset()
	if P.is_empty():
		return Color.WHITE
	var arr: Array = P["trees"]
	return arr[rng.randi() % arr.size()]
