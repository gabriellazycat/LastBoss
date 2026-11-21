extends Node3D
## Efeitos novos do mundo (rodada visual 20/11/2026, docs/RODADA_VISUAL_2026-11-20.md).
## Padrão (--fx=3, aprovado em 20/11/2026 na página de revisão): cada efeito no estilo escolhido — pintado (como as
## cartas) ou brilhante (entra no bloom); ver KIND_STYLE e WorldView._fx_ctx. --fx=1 tudo pintado, --fx=2 tudo
## brilhante, --fx=0 os efeitos de antes (bolinha de 64 px).
## world_view.gd cria um nó deste script em _build_pools() quando o estilo é > 0 e passa para cá os pedidos de efeito
## (emit_fx, ring_burst, zonas no chão, projéteis, queimadura). Tudo é desenhado nos shaders fx_particle*/fx_ground,
## sem textura pequena: fica nítido de perto e de longe.

const SH_ADD := preload("res://game/art/fx_particle_add.gdshader")
const SH_MIX := preload("res://game/art/fx_particle_mix.gdshader")
const SH_GROUND := preload("res://game/art/fx_ground.gdshader")

enum S { FLAME, SMOKE, SPARK, EMBER, STAR, CHUNK, CROSS, RING, THREAD }

static var _style := -1


## 0 = efeitos antigos; 1 = pintado; 2 = brilhante; 3 = misto aprovado (padrão). Lido uma vez da linha de comando.
static func style() -> int:
	if _style < 0:
		_style = 3
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--fx="):
				_style = clampi(int(a.substr(5)), 0, 3)
	return _style


static func set_style(v: int) -> void:
	_style = clampi(v, 0, 3)


## Estilo de cada tipo quando nenhum evento escolheu (ctx < 0), no modo misto. 1 pintado, 2 brilhante.
const KIND_STYLE := {"fire": 1, "smoke": 1, "spark": 1, "hit": 1, "level": 1, "collapse": 1,
	"death": 2, "soul": 2, "magic": 2, "shield": 2, "heal": 2}

var painted := true       # estilo em uso ao montar materiais (true = pintado)
var ctx := -1             # estilo pedido pelo evento em curso (WorldView.handle_events); -1 = o do tipo
var q_mult := 1.0
var layers := {}          # nome da camada -> {"list": [GPUParticles3D], "i": int}
var recipes := {}         # tipo de efeito -> [[camada, escala relativa, deslocamento y]]
var waves: Array = []     # ondas de choque no chão: {"n", "m", "t", "T", "r"}
var wave_i := 0
var circles: Array = []   # círculos de feitiço: {"n", "m", "t", "T"}
var circle_i := 0
var patches: Array = []   # chão em brasa que some sozinho (feitiço de fogo, casa que desaba): {"n", "m", "t", "T"}
var patch_i := 0
var lights: Array = []    # luzes de fogo que tremem: {"l", "t", "T", "e"}
var light_i := 0
var frame := 0
var scorch_tex: ImageTexture


func setup() -> void:
	var ql := int(Settings.v.get("quality", 2))
	q_mult = [0.4, 0.7, 1.0][clampi(ql, 0, 2)]
	for st in _styles():
		painted = st == 1
		_build_layers("@%d" % st)
	painted = style() != 2
	_build_recipes()
	for i in 14:
		var n := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(2, 2)
		n.mesh = pm
		n.material_override = ground_material(0)
		n.visible = false
		add_child(n)
		waves.append({"n": n, "m": n.material_override, "t": 0.0, "T": 0.5, "r": 1.0})
	for i in 6:
		var n := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(2, 2)
		n.mesh = pm
		n.material_override = ground_material(5)
		n.visible = false
		add_child(n)
		circles.append({"n": n, "m": n.material_override, "t": 0.0, "T": 1.0})
	for i in 6:
		var n := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(2, 2)
		n.mesh = pm
		n.material_override = ground_material(3)
		n.visible = false
		add_child(n)
		patches.append({"n": n, "m": n.material_override, "t": 0.0, "T": 2.0})
	for i in 6:
		var l := OmniLight3D.new()
		l.light_energy = 0.0
		l.omni_range = 9.0
		l.light_color = Color(1.0, 0.55, 0.2)
		l.shadow_enabled = false
		l.light_volumetric_fog_energy = 0.0
		l.visible = false
		add_child(l)
		lights.append({"l": l, "t": 0.0, "T": 1.0, "e": 0.0})
	scorch_tex = _make_scorch()


# ------------------------------------------------------------------ materiais

func _styles() -> Array:
	return [1, 2] if style() == 3 else [style()]


## Estilo para este pedido: o do evento, senão o do tipo (modo misto); nos outros modos, o único.
func _pick(kind: String) -> int:
	if style() != 3:
		return style()
	return ctx if ctx > 0 else int(KIND_STYLE.get(kind, 1))


func _paint_mat(m: ShaderMaterial, st: int, glow := 2.2) -> void:
	m.set_shader_parameter("paint", 1.0 if st == 1 else 0.0)
	m.set_shader_parameter("glow", 1.0 if st == 1 else glow)

func particle_material(shape: int, additive: bool, axis_mode := 0, width := 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_ADD if additive else SH_MIX
	m.set_shader_parameter("shape", shape)
	m.set_shader_parameter("paint", 1.0 if painted else 0.0)
	m.set_shader_parameter("glow", 1.0 if painted else 2.4)
	m.set_shader_parameter("axis_mode", axis_mode)
	m.set_shader_parameter("width", width)
	return m


func ground_material(kind: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_GROUND
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("paint", 1.0 if painted else 0.0)
	m.set_shader_parameter("glow", 1.0 if painted else 2.2)
	m.set_shader_parameter("seed", randf() * 10.0)
	return m


# ------------------------------------------------------------------ camadas de partículas

func _curve(pts: Array) -> CurveTexture:
	var cv := Curve.new()
	for p in pts:
		cv.add_point(p)
	var ct := CurveTexture.new()
	ct.curve = cv
	return ct


func _ramp(cols: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	for i in cols.size():
		offs.append(float(i) / (cols.size() - 1))
	g.offsets = offs
	g.colors = PackedColorArray(cols)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _layer(d: Dictionary) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = maxi(1, int(round(float(d["amount"]) * q_mult)))
	p.lifetime = d["life"]
	p.one_shot = true
	p.explosiveness = d.get("expl", 0.9)
	p.randomness = 0.4
	p.emitting = false
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = d.get("dir", Vector3(0, 1, 0))
	pm.spread = d.get("spread", 180.0)
	pm.initial_velocity_min = d["speed"][0]
	pm.initial_velocity_max = d["speed"][1]
	pm.gravity = Vector3(0, -float(d.get("grav", 0.0)), 0)
	pm.damping_min = d.get("damp", 0.0)
	pm.damping_max = d.get("damp", 0.0) * 1.3
	pm.scale_min = d["size"][0]
	pm.scale_max = d["size"][1]
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = d.get("radius", 0.3)
	pm.angle_min = -180.0 if d.get("spin", true) else 0.0
	pm.angle_max = 180.0 if d.get("spin", true) else 0.0
	if d.has("angvel"):
		pm.angular_velocity_min = -float(d["angvel"])
		pm.angular_velocity_max = float(d["angvel"])
	if d.get("align", false):
		pm.particle_flag_align_y = true
	if d.has("turb"):
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = d["turb"]
		pm.turbulence_noise_scale = 3.0
	pm.color_ramp = _ramp(d.get("ramp", [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	var sc: Array = d.get("curve", [Vector2(0, 1), Vector2(0.7, 0.85), Vector2(1, 0)])
	pm.scale_curve = _curve(sc)
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var additive: bool = d.get("add", true) and not (painted and d.get("paint_mix", false))
	var mat := particle_material(d["shape"], additive, 1 if d.get("align", false) else 0, d.get("width", 0.18))
	q.material = mat
	p.draw_pass_1 = q
	p.visibility_aabb = AABB(Vector3(-14, -4, -14), Vector3(28, 22, 28))
	return p


func _build_layers(suffix: String) -> void:
	var W := Color(1, 1, 1, 1)
	var Z := Color(1, 1, 1, 0)
	var GROW := [Vector2(0, 0.45), Vector2(0.5, 0.9), Vector2(1, 1.0)]
	var POP := [Vector2(0, 0.2), Vector2(0.15, 1.0), Vector2(1, 0.0)]
	var smoke_col := Color(0.3, 0.26, 0.28, 0.85) if painted else Color(0.22, 0.19, 0.22, 0.6)
	var defs := {
		# Chamas: línguas que sobem e se apagam; no pintado, tinta por cima (não clareia o chão em branco).
		"flame": {"shape": S.FLAME, "amount": 22, "life": 1.1, "speed": [1.0, 3.0], "grav": -3.0, "damp": 2.0, "size": [1.7, 3.0], "radius": 0.7, "spread": 25.0, "spin": false, "paint_mix": true, "curve": [Vector2(0, 0.5), Vector2(0.25, 1.0), Vector2(1, 0.35)], "n": 10},
		"ember": {"shape": S.EMBER, "amount": 22, "life": 1.5, "speed": [1.5, 5.0], "grav": -2.5, "damp": 0.8, "size": [0.08, 0.16], "radius": 0.7, "spread": 60.0, "turb": 2.2, "ramp": [Color(1, 0.85, 0.4), Color(1, 0.5, 0.12), Color(1, 0.3, 0.05, 0)], "n": 10},
		"smoke": {"shape": S.SMOKE, "amount": 9, "life": 2.2, "speed": [0.8, 2.2], "grav": -1.2, "damp": 0.8, "size": [1.6, 2.8], "radius": 0.8, "spread": 35.0, "add": false, "curve": GROW, "ramp": [smoke_col, smoke_col, Color(smoke_col.r, smoke_col.g, smoke_col.b, 0)], "n": 8},
		"dust": {"shape": S.SMOKE, "amount": 14, "life": 1.4, "speed": [2.5, 5.0], "grav": -0.3, "damp": 3.0, "size": [1.0, 2.0], "radius": 0.9, "dir": Vector3(0, 0.25, 0), "add": false, "curve": GROW, "ramp": [Color(0.72, 0.62, 0.5, 0.75), Color(0.7, 0.6, 0.48, 0.5), Color(0.7, 0.6, 0.48, 0)], "n": 6},
		"sparks": {"shape": S.SPARK, "amount": 18, "life": 0.45, "speed": [7.0, 14.0], "grav": 14.0, "damp": 1.0, "size": [0.6, 1.1], "radius": 0.2, "align": true, "width": 0.13, "spin": false, "ramp": [Color(1, 1, 0.85), Color(1, 0.7, 0.3), Color(1, 0.35, 0.1, 0)], "n": 12},
		"flash": {"shape": S.STAR, "amount": 1, "life": 0.34, "speed": [0.0, 0.0], "size": [3.0, 3.0], "radius": 0.0, "expl": 1.0, "spin": true, "curve": POP, "n": 16},
		"hitspark": {"shape": S.SPARK, "amount": 9, "life": 0.38, "speed": [5.0, 10.0], "grav": 6.0, "size": [0.6, 1.0], "radius": 0.1, "align": true, "width": 0.11, "spin": false, "n": 16},
		"puff": {"shape": S.SMOKE, "amount": 9, "life": 0.9, "speed": [1.8, 4.0], "grav": -0.5, "damp": 3.0, "size": [1.0, 1.7], "radius": 0.35, "add": false, "curve": GROW, "ramp": [W, Color(1, 1, 1, 0.8), Z], "n": 18},
		"chunks": {"shape": S.CHUNK, "amount": 11, "life": 1.0, "speed": [4.5, 9.0], "grav": 20.0, "size": [0.32, 0.6], "radius": 0.3, "spread": 70.0, "angvel": 540.0, "add": false, "ramp": [W, W, Color(1, 1, 1, 0)], "curve": [Vector2(0, 1), Vector2(0.85, 1), Vector2(1, 0)], "n": 16},
		"debris": {"shape": S.CHUNK, "amount": 22, "life": 1.6, "speed": [6.0, 13.0], "grav": 22.0, "size": [0.35, 0.8], "radius": 1.0, "spread": 55.0, "angvel": 400.0, "add": false, "ramp": [Color(0.55, 0.38, 0.24), Color(0.5, 0.4, 0.33), Color(0.45, 0.38, 0.32, 0)], "curve": [Vector2(0, 1), Vector2(0.85, 1), Vector2(1, 0)], "n": 4},
		"wisp": {"shape": S.EMBER, "amount": 6, "life": 1.3, "speed": [0.6, 1.6], "grav": -3.0, "size": [0.25, 0.4], "radius": 0.3, "turb": 1.5, "ramp": [Color(0.6, 1, 0.9), Color(0.35, 0.9, 1.0, 0.7), Color(0.2, 0.5, 1.0, 0)], "n": 16},
		"stars": {"shape": S.STAR, "amount": 12, "life": 0.9, "speed": [1.5, 4.5], "grav": -1.5, "damp": 2.0, "size": [0.35, 0.7], "radius": 0.7, "curve": POP, "n": 10},
		"motes": {"shape": S.EMBER, "amount": 26, "life": 1.1, "speed": [1.0, 3.5], "grav": -2.0, "damp": 1.5, "size": [0.1, 0.2], "radius": 0.9, "turb": 2.0, "n": 10},
		"rise": {"shape": S.STAR, "amount": 40, "life": 1.4, "speed": [3.0, 8.0], "grav": -3.0, "damp": 1.5, "size": [0.3, 0.6], "radius": 1.2, "spread": 30.0, "curve": POP, "ramp": [Color(1, 1, 0.85), Color(1, 0.85, 0.35), Color(1, 0.55, 0.1, 0)], "n": 4},
		"crosses": {"shape": S.CROSS, "amount": 12, "life": 1.3, "speed": [1.2, 3.0], "grav": -3.0, "size": [0.45, 0.75], "radius": 0.8, "spin": false, "curve": POP, "n": 8},
		"shards": {"shape": S.CHUNK, "amount": 18, "life": 0.85, "speed": [5.0, 11.0], "grav": 12.0, "size": [0.3, 0.55], "radius": 0.4, "angvel": 720.0, "ramp": [Color(0.85, 0.95, 1.0), Color(0.6, 0.8, 1.0), Color(0.4, 0.6, 1.0, 0)], "n": 6},
		"silk": {"shape": S.THREAD, "amount": 5, "life": 1.2, "speed": [0.3, 0.8], "grav": -0.6, "size": [0.6, 1.1], "radius": 0.8, "turb": 0.8, "add": false, "ramp": [Color(0.9, 0.92, 1.0, 0), Color(0.9, 0.92, 1.0, 0.8), Color(0.9, 0.92, 1.0, 0)], "n": 6},
		"bubble": {"shape": S.RING, "amount": 4, "life": 0.6, "speed": [0.2, 0.6], "grav": -0.5, "size": [0.18, 0.3], "radius": 0.9, "add": false, "curve": POP, "ramp": [Color(0.25, 0.16, 0.08, 0.9), Color(0.35, 0.22, 0.1, 0.9), Color(0.35, 0.22, 0.1, 0)], "n": 8},
		"drops": {"shape": S.EMBER, "amount": 6, "life": 0.8, "speed": [1.5, 3.0], "grav": 6.0, "size": [0.1, 0.18], "radius": 0.8, "spread": 25.0, "ramp": [Color(0.75, 0.92, 1.0), Color(0.6, 0.85, 1.0), Color(0.5, 0.8, 1.0, 0)], "n": 6},
	}
	if Golpes.VAR > 0:
		# --golpes=1: poeira de pisada e de impacto dos monstros pesados (camada própria; a "dust" é do desabamento).
		defs["gdust"] = {"shape": S.SMOKE, "amount": 8, "life": 0.8, "speed": [2.0, 4.0], "grav": -0.2, "damp": 4.0, "size": [0.7, 1.3], "radius": 0.5, "dir": Vector3(0, 0.15, 0), "spread": 80.0, "add": false, "curve": GROW, "ramp": [Color(0.74, 0.64, 0.5, 0.8), Color(0.7, 0.6, 0.48, 0.55), Color(0.7, 0.6, 0.48, 0)], "n": 10}
	for k in defs:
		var d: Dictionary = defs[k]
		var list: Array = []
		for i in int(d["n"]):
			var p := _layer(d)
			add_child(p)
			list.append(p)
		layers[k + suffix] = {"list": list, "i": 0}


## Cada efeito pedido por world_view é uma pilha de camadas: [camada, escala relativa, altura extra].
func _build_recipes() -> void:
	recipes = {
		"fire": [["flame", 1.0, -0.3], ["ember", 1.0, 0.0], ["smoke", 0.8, 0.8]],
		"smoke": [["smoke", 1.0, 0.0]],
		"spark": [["flash", 0.8, 0.0], ["sparks", 1.0, 0.0]],
		"hit": [["flash", 0.6, 0.0], ["hitspark", 1.0, 0.0]],
		"death": [["puff", 1.0, 0.0], ["chunks", 1.0, 0.0], ["flash", 0.5, 0.2]],
		"soul": [["wisp", 1.0, 0.0]],
		"level": [["rise", 1.0, 0.0], ["stars", 1.3, 0.5], ["flash", 1.2, 1.0]],
		"magic": [["stars", 1.0, 0.0], ["motes", 1.0, 0.0], ["flash", 0.7, 0.0]],
		"shield": [["shards", 1.0, 0.0], ["flash", 0.9, 0.0], ["sparks", 0.6, 0.0]],
		"heal": [["crosses", 1.0, 0.0], ["motes", 0.9, 0.0], ["flash", 0.5, 0.6]],
		"collapse": [["debris", 1.0, 0.4], ["dust", 1.4, 0.2], ["flame", 1.6, 0.0], ["ember", 1.5, 0.3], ["smoke", 1.5, 1.2]],
	}
	if Golpes.VAR > 0:
		recipes["passo"] = [["gdust", 1.0, 0.0]]


func _fire(layer: String, pos: Vector3, s: float, col: Color, st := 1) -> void:
	var d: Dictionary = layers[layer + "@%d" % (st if style() == 3 else style())]
	var list: Array = d["list"]
	var p: GPUParticles3D = list[d["i"]]
	d["i"] = (int(d["i"]) + 1) % list.size()
	p.position = pos
	p.scale = Vector3.ONE * maxf(s, 0.05)
	(p.process_material as ParticleProcessMaterial).color = col
	p.restart()
	p.emitting = true


## Pedido de efeito do world_view (mesmos nomes de antes). Devolve false se o tipo não é conhecido aqui.
func emit(kind: String, pos: Vector3, s := 1.0, col := Color.WHITE) -> bool:
	if not recipes.has(kind):
		return false
	var st := _pick(kind)
	for r in recipes[kind]:
		var c := col
		if kind == "heal" and col == Color.WHITE:
			c = Color(0.45, 1.0, 0.5)   # cura sem cor pedida: verde (o roubo de vida pede carmim)
		if kind == "death" and r[0] == "chunks":
			# Pedaços na cor da criatura, mais saturados (a cor clara de algumas lia como branco).
			c = Color.from_hsv(col.h, minf(1.0, col.s * 1.5 + 0.15), col.v * 0.8)
		elif kind == "death" and r[0] == "flash":
			c = Color.WHITE
		_fire(r[0], pos + Vector3(0, float(r[2]) * s, 0), s * float(r[1]), c, st)
	if kind == "fire" and s >= 0.9:
		fire_light(pos, 2.5 * minf(s, 2.5), 1.4)
		burn_patch(pos, 1.6 * s, 2.2)
	if kind == "collapse":
		ring(pos, 4.0 * s, Color(0.75, 0.65, 0.5))
		burn_patch(pos, 3.0 * s, 4.0)
		fire_light(pos, 5.0, 2.2)
	if kind == "magic" and s >= 1.2:
		spell_circle(pos, 1.6 * s, col if col != Color.WHITE else Color(0.75, 0.4, 1.0))
	return true


func ring(pos: Vector3, r: float, col: Color) -> void:
	var e: Dictionary = waves[wave_i]
	wave_i = (wave_i + 1) % waves.size()
	var n: MeshInstance3D = e["n"]
	n.position = pos + Vector3(0, 0.07, 0)
	n.scale = Vector3(r, 1, r)
	var m: ShaderMaterial = e["m"]
	_paint_mat(m, _pick("spark"))
	m.set_shader_parameter("tint", col)
	m.set_shader_parameter("age", 0.0)
	m.set_shader_parameter("seed", randf() * 10.0)
	n.visible = true
	e["t"] = 0.0
	e["T"] = clampf(0.35 + r * 0.04, 0.35, 0.7)


func spell_circle(pos: Vector3, r: float, col: Color) -> void:
	var e: Dictionary = circles[circle_i]
	circle_i = (circle_i + 1) % circles.size()
	var n: MeshInstance3D = e["n"]
	n.position = pos + Vector3(0, 0.08, 0)
	n.scale = Vector3(r, 1, r)
	var m: ShaderMaterial = e["m"]
	_paint_mat(m, _pick("magic"))
	m.set_shader_parameter("tint", Color(col.r, col.g, col.b, 0.95))
	m.set_shader_parameter("age", 0.0)
	n.visible = true
	e["t"] = 0.0
	e["T"] = 0.9


## Mancha de chão em brasa que pulsa e some (shader fx_ground, kind 3).
func burn_patch(pos: Vector3, r: float, dur: float) -> void:
	var e: Dictionary = patches[patch_i]
	patch_i = (patch_i + 1) % patches.size()
	var n: MeshInstance3D = e["n"]
	n.position = pos * Vector3(1, 0, 1) + Vector3(0, 0.06, 0)
	n.scale = Vector3(r, 1, r)
	(e["m"] as ShaderMaterial).set_shader_parameter("seed", randf() * 10.0)
	_paint_mat(e["m"], _pick("fire"))
	n.visible = true
	e["t"] = 0.0
	e["T"] = dur


func fire_light(pos: Vector3, energy: float, dur: float) -> void:
	var e: Dictionary = lights[light_i]
	light_i = (light_i + 1) % lights.size()
	var l: OmniLight3D = e["l"]
	l.position = pos + Vector3(0, 1.6, 0)
	l.visible = true
	e["t"] = dur
	e["T"] = dur
	e["e"] = energy


## Zonas no chão (teia, óleo, fogo, fonte): material novo e efeitos contínuos. Chamado por _draw_zones a cada quadro.
func zone_params(mat: ShaderMaterial, kind: String) -> void:
	var k := 6
	var tint := Color(0.9, 0.6, 0.3, 0.9)
	match kind:
		"web":
			k = 1
			tint = Color(0.86, 0.88, 0.96, 0.95)
		"oil":
			k = 2
		"fire":
			k = 3
		"spring":
			k = 4
			tint = Color(0.3, 0.62, 0.9, 0.85)
	if int(mat.get_shader_parameter("kind")) != k:
		mat.set_shader_parameter("kind", k)
	mat.set_shader_parameter("tint", tint)


func zone_tick(kind: String, pos: Vector3, r: float, idx: int) -> void:
	var f := frame + idx * 7
	match kind:
		"oil":
			if f % 9 == 0:
				var a := randf() * TAU
				var p := pos + Vector3(cos(a), 0, sin(a)) * r * randf_range(0.55, 0.85)
				_fire("flame", p + Vector3(0, 0.1, 0), 0.45, Color.WHITE)
			if f % 14 == 0:
				_fire("bubble", pos + Vector3(randf_range(-0.5, 0.5), 0.1, randf_range(-0.5, 0.5)) * r, 0.6 * r, Color.WHITE)
			if f % 30 == 0:
				_fire("ember", pos, 0.5 * r, Color.WHITE)
		"fire":
			if f % 7 == 0:
				var p := pos + Vector3(randf_range(-1, 1), 0.1, randf_range(-1, 1)) * r * 0.65
				_fire("flame", p, 0.55, Color.WHITE)
			if f % 25 == 0:
				_fire("ember", pos, 0.6 * r, Color.WHITE)
				_fire("smoke", pos + Vector3(0, 1.0, 0), 0.5 * r, Color.WHITE)
		"web":
			if f % 45 == 0:
				_fire("silk", pos + Vector3(0, 0.3, 0), 0.5 * r, Color.WHITE)
		"spring":
			if f % 20 == 0:
				_fire("drops", pos + Vector3(0, 0.2, 0), 0.6 * r, Color.WHITE)


# ------------------------------------------------------------------ projéteis

## Flecha (haste, ponta, penas) com rastro; orbe com núcleo, halo e rastro de centelhas. Os nós entram nos pools
## do world_view no lugar da caixa e da esfera de antes.
func make_arrow() -> Node3D:
	painted = style() == 1   # flecha: brilhante no modo misto (aprovado)
	var root := Node3D.new()
	var wood := StandardMaterial3D.new()
	wood.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wood.albedo_color = Color(0.55, 0.38, 0.22)
	var shaft := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.028
	cm.bottom_radius = 0.028
	cm.height = 0.8
	cm.radial_segments = 6
	cm.rings = 1
	shaft.mesh = cm
	shaft.material_override = wood
	shaft.rotation.x = PI * 0.5
	root.add_child(shaft)
	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.0
	hm.bottom_radius = 0.07
	hm.height = 0.2
	hm.radial_segments = 4
	hm.rings = 1
	head.mesh = hm
	var steel := StandardMaterial3D.new()
	steel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	steel.albedo_color = Color(0.82, 0.84, 0.9)
	head.material_override = steel
	head.rotation.x = -PI * 0.5
	head.position = Vector3(0, 0, -0.48)
	root.add_child(head)
	var fl_m := StandardMaterial3D.new()
	fl_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fl_m.albedo_color = Color(0.85, 0.25, 0.2)
	fl_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for k in 2:
		var fl := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.14, 0.22)
		fl.mesh = qm
		fl.material_override = fl_m
		fl.position = Vector3(0, 0, 0.32)
		fl.rotation = Vector3(PI * 0.5, 0, k * PI * 0.5)
		root.add_child(fl)
	var trail := MeshInstance3D.new()
	var tq := QuadMesh.new()
	tq.size = Vector2(1, 1)
	trail.mesh = tq
	var tm := particle_material(S.SPARK, true, 2, 0.12)
	tm.set_shader_parameter("tint", Color(1.0, 0.95, 0.8, 0.55))
	trail.material_override = tm
	trail.scale = Vector3(1, 1, 1.8)
	trail.position = Vector3(0, 0, 1.1)
	root.add_child(trail)
	return root


func make_orb() -> Node3D:
	painted = style() != 2   # orbe: pintado no modo misto (aprovado)
	var root := Node3D.new()
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	sm.radial_segments = 12
	sm.rings = 6
	core.mesh = sm
	var cmat := StandardMaterial3D.new()
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmat.albedo_color = Color(0.95, 0.85, 1.0) * (1.0 if painted else 3.0)
	core.material_override = cmat
	root.add_child(core)
	var halo := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(1, 1)
	halo.mesh = hq
	var hmat := particle_material(S.EMBER, true)
	hmat.set_shader_parameter("tint", Color(0.7, 0.45, 1.0, 1.0))
	halo.material_override = hmat
	halo.scale = Vector3.ONE * 1.1
	root.add_child(halo)
	var trail := GPUParticles3D.new()
	trail.amount = maxi(4, int(20 * q_mult))
	trail.lifetime = 0.35
	trail.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.spread = 180.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.8
	pm.scale_min = 0.12
	pm.scale_max = 0.26
	pm.scale_curve = _curve([Vector2(0, 1), Vector2(1, 0)])
	pm.color_ramp = _ramp([Color(0.85, 0.7, 1.0), Color(0.6, 0.35, 1.0, 0)])
	trail.process_material = pm
	var tq := QuadMesh.new()
	tq.size = Vector2(1, 1)
	tq.material = particle_material(S.EMBER, true)
	trail.draw_pass_1 = tq
	trail.visibility_aabb = AABB(Vector3(-30, -5, -30), Vector3(60, 20, 60))
	trail.emitting = true
	root.add_child(trail)
	return root


func streak_material() -> ShaderMaterial:
	painted = style() == 1   # tiro das unidades (flecha): brilhante no modo misto
	var m := particle_material(S.SPARK, true, 2, 0.1)
	m.set_shader_parameter("tint", Color(1.0, 0.95, 0.75, 0.9))
	return m


# ------------------------------------------------------------------ queimadura

func _make_scorch() -> ImageTexture:
	painted = style() != 2   # queimado no chão: pintado no modo misto (família do fogo)
	var sz := 256
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var nz := FastNoiseLite.new()
	nz.seed = 7
	nz.frequency = 0.035
	nz.fractal_octaves = 4
	var nz2 := FastNoiseLite.new()
	nz2.seed = 11
	nz2.frequency = 0.11
	for y in sz:
		for x in sz:
			var u := (Vector2(x, y) / float(sz - 1)) * 2.0 - Vector2.ONE
			var d := u.length()
			var n := nz.get_noise_2d(x, y) * 0.5 + 0.5
			var edge := 0.78 + (n - 0.5) * 0.45
			var m := clampf((edge - d) / 0.18, 0.0, 1.0)
			var spot := clampf(nz2.get_noise_2d(x, y) * 1.5, 0.0, 1.0)
			var a := m * (0.62 + 0.3 * (1.0 - d)) * (0.85 + 0.15 * spot)
			if painted:
				a = 0.0 if a < 0.12 else (0.55 if a < 0.5 else 0.85)
			var c := Color(0.06, 0.04, 0.035).lerp(Color(0.2, 0.12, 0.08), spot * 0.6)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ quadro a quadro

func _process(delta: float) -> void:
	frame += 1
	for e in waves:
		if e["n"].visible:
			e["t"] += delta
			var k := clampf(float(e["t"]) / float(e["T"]), 0.0, 1.0)
			(e["m"] as ShaderMaterial).set_shader_parameter("age", k)
			if k >= 1.0:
				e["n"].visible = false
	for e in circles:
		if e["n"].visible:
			e["t"] += delta
			var k := clampf(float(e["t"]) / float(e["T"]), 0.0, 1.0)
			(e["m"] as ShaderMaterial).set_shader_parameter("age", k)
			e["n"].rotation.y += delta * 0.8
			if k >= 1.0:
				e["n"].visible = false
	for e in patches:
		if e["n"].visible:
			e["t"] += delta
			var k := clampf(float(e["t"]) / float(e["T"]), 0.0, 1.0)
			var a := minf(k / 0.08, 1.0) * (1.0 - smoothstep(0.55, 1.0, k))
			(e["m"] as ShaderMaterial).set_shader_parameter("tint", Color(1, 1, 1, a))
			if k >= 1.0:
				e["n"].visible = false
	for e in lights:
		if e["t"] > 0.0:
			e["t"] -= delta
			var l: OmniLight3D = e["l"]
			var k := clampf(float(e["t"]) / float(e["T"]), 0.0, 1.0)
			l.light_energy = float(e["e"]) * k * (0.75 + 0.35 * sin(frame * 0.9) * sin(frame * 0.37))
			if e["t"] <= 0.0:
				l.visible = false
