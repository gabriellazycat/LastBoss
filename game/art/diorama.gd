class_name Diorama
extends RefCounted
## Versão C do diorama (branch diorama-c, 26/11/2026): "feltro e lanternas ao anoitecer". O mundo é uma colcha de
## retalhos de feltro costurados, com bichos e casas de lã: hora azul, céu fundo, e as luzes quentes (lanternas,
## janelas, a luz do herói) fazem o aconchego. Fibra e brilho de veludo nas bordas (dio_fuzz, dio_fiber).
## Vale para todos os atos (o ato 1 é o afinado); chamado pelo main depois do look de cada ato.

const FOV := 30.0                 # lente longa: a perspectiva achata como numa foto de miniatura
const PITCH := 54.0
## Luzes pontuais (lanternas, locais, herói): mais fortes e largas à noite.
const LIGHT_K := 3.4
const LIGHT_R := 1.35               # graus para baixo
## A câmera do jogo foi pensada com FOV 40: a distância cresce para mostrar a mesma área no chão.
const DIST_K := 1.36              # tan(20°) / tan(15°)
const SKY_SHADER := preload("res://game/art/dio_backdrop.gdshader")

# Sol, ambiente e céu por ato (o 1 é a maquete de meio da manhã; 2 e 3 só puxam a cor do ato).
const ACTS := [
	{"sun_rot": Vector3(-38, 150, 0), "sun_col": Color(0.62, 0.7, 1.0), "sun_e": 0.7,
		"amb": Color(0.46, 0.5, 0.82), "amb_e": 0.6, "top": Color(0.08, 0.09, 0.22), "hor": Color(0.32, 0.3, 0.52),
		"haze": Color(0.42, 0.36, 0.55), "sat": 1.08},
	{"sun_rot": Vector3(-34, -55, 0), "sun_col": Color(1.0, 0.84, 0.66), "sun_e": 1.3,
		"amb": Color(0.82, 0.74, 0.7), "amb_e": 0.7, "top": Color(0.5, 0.55, 0.75), "hor": Color(0.95, 0.8, 0.66),
		"haze": Color(0.96, 0.84, 0.7), "sat": 1.12},
	{"sun_rot": Vector3(-30, 140, 0), "sun_col": Color(1.0, 0.7, 0.7), "sun_e": 1.15,
		"amb": Color(0.6, 0.55, 0.78), "amb_e": 0.7, "top": Color(0.2, 0.16, 0.32), "hor": Color(0.62, 0.42, 0.55),
		"haze": Color(0.7, 0.55, 0.66), "sat": 1.04},
]

static var _attrs: CameraAttributesPractical


static func setup_camera(cam: Camera3D) -> void:
	cam.fov = FOV
	cam.far = 900
	_attrs = CameraAttributesPractical.new()
	_attrs.dof_blur_far_enabled = true
	_attrs.dof_blur_near_enabled = true
	_attrs.dof_blur_amount = 0.08
	cam.attributes = _attrs


## Deslocamento da câmera a partir do alvo para a distância do jogo (pensada com FOV 40 e ~53°).
static func cam_offset(dist: float) -> Vector3:
	var d := dist * DIST_K
	var a := deg_to_rad(PITCH)
	return Vector3(0, sin(a) * d, cos(a) * d)


## Tilt-shift: só a faixa da distância do alvo fica nítida (números do Holy Sheep, relativos à distância).
static func focus(cam: Camera3D, d: float) -> void:
	if _attrs == null or cam.attributes != _attrs:
		return
	var on := int(Settings.v.get("quality", 2)) >= 2
	_attrs.dof_blur_far_enabled = on
	_attrs.dof_blur_near_enabled = on
	_attrs.dof_blur_far_distance = d * 1.1
	_attrs.dof_blur_far_transition = d * 0.25
	_attrs.dof_blur_near_distance = d * 0.92
	_attrs.dof_blur_near_transition = d * 0.1


static func apply_env(env: Environment, sun: DirectionalLight3D, rim: DirectionalLight3D, act: int) -> void:
	var A: Dictionary = ACTS[clampi(act, 0, ACTS.size() - 1)]
	sun.rotation_degrees = A["sun_rot"]
	sun.light_color = A["sun_col"]
	sun.light_energy = A["sun_e"]
	sun.shadow_opacity = 1.0
	sun.shadow_blur = 1.4
	sun.light_angular_distance = 1.2
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_max_distance = 140.0
	sun.light_specular = 0.0
	if rim:
		rim.light_energy = 0.0
	var sm := ShaderMaterial.new()
	sm.shader = SKY_SHADER
	var top: Color = A["top"]
	var hor: Color = A["hor"]
	sm.set_shader_parameter("top_color", top)
	sm.set_shader_parameter("horizon_color", hor)
	sm.set_shader_parameter("center_color", hor.lerp(A["haze"], 0.25))
	sm.set_shader_parameter("edge_color", hor.lerp(top, 0.4).darkened(0.25))
	env.sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = A["amb"]
	env.ambient_light_energy = A["amb_e"]
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.12
	env.glow_intensity = 0.85
	env.glow_strength = 1.15
	env.glow_bloom = 0.12
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_hdr_threshold = 0.75
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_brightness = 1.0
	env.adjustment_saturation = A["sat"]
	env.adjustment_color_correction = null
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.4
	env.ssao_power = 1.5
	env.ssao_detail = 0.7
	env.ssao_horizon = 0.06
	env.ssao_light_affect = 0.12
	env.ssil_enabled = int(Settings.v.get("quality", 2)) >= 2
	env.ssil_radius = 5.0
	env.ssil_intensity = 1.25
	env.ssil_sharpness = 0.98
	env.ssil_normal_rejection = 1.0
	# Sem névoa: a miniatura é nítida e limpa; a distância some pelo tilt-shift.
	env.fog_density = 0.0
	env.fog_enabled = false
	env.volumetric_fog_density = 0.0
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH
		if int(Settings.v.get("quality", 2)) >= 2 else RenderingServer.SHADOW_QUALITY_SOFT_LOW)


## Vinheta da tela: leve e quente (a de antes era roxa a 0,82 e escurecia a maquete).
static func vignette_code() -> String:
	return "shader_type canvas_item;
void fragment(){ vec2 d = UV - vec2(0.5); float v = smoothstep(0.35, 0.95, length(d * vec2(1.0, 0.8))); COLOR = vec4(0.03, 0.03, 0.1, v * 0.42); }"


# ---------------------------------------------------------------- modelos

## Modelos do diorama (tools/art/import_dio.gd + tools/art/dio_a.json): cor nos vértices, sem atlas. Passam na frente
## das peças de sempre em Models.prop, GroundLooks.prop_mesh, Arvores (ato 1) e Looks.unit_mesh.
const DIR := "res://assets/models/dio/"
## Tinta do herói: o escudeiro de feltro já vem colorido.
const HERO_TINT := Color(1.0, 1.0, 1.0)
## Escudeiro de feltro (tools/art/blender_dio/characters.py, partes animadas pelo import_dio "@biped").
const HERO_SCENE := "res://assets/models/dio/hero_escudeiro.scn"
static var _cache: Dictionary = {}


static func mesh(id: String) -> Mesh:
	if id == "":
		return null
	if not _cache.has(id):
		var p := DIR + id + ".res"
		_cache[id] = load(p) if ResourceLoader.exists(p) else null
	return _cache[id]


## Monstro do diorama da carta: o da própria carta, senão o do modelo que ela usa (CardModel); "" se não houver.
static func unit_id(card: String) -> String:
	if mesh(card) and mesh(card).has_meta("vat"):
		return card
	var base := CardModel.of(card)
	return base if base != card and mesh(base) and mesh(base).has_meta("vat") else ""
