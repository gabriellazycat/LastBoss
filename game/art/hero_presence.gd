class_name HeroPresence
extends Node3D
## Presença dos heróis (20/11/2026). Os modelos KayKit ficam; por cima deles: sombra de contato, anel pintado na cor
## da classe, aura de partículas por classe e um pouco mais de tamanho (SCALE).
## world_view.gd cria um nó deste script e chama track(no_do_herói, classe) a cada quadro para cada herói visível.

const SCALE := 1.15

## Cor de cada classe (anel e aura) e o desenho da aura: [cor, forma, sobe/desce, quantidade].
## Formas do shader fx_particle: 2 faísca, 3 brasa, 4 estrela, 5 lasca, 6 cruz, 8 fio.
const CLS := {
	"escudeiro": [Color(0.85, 0.72, 0.35), 4, 1.0, 5],
	"guardiao": [Color(0.45, 0.7, 1.0), 5, 0.4, 5],
	"arqueira": [Color(0.5, 0.9, 0.4), 8, 1.2, 4],
	"besteiro": [Color(0.75, 0.6, 0.4), 2, 1.0, 4],
	"cleriga": [Color(1.0, 0.92, 0.55), 6, 1.4, 5],
	"mago": [Color(0.7, 0.45, 1.0), 4, 1.6, 7],
	"assassino": [Color(0.35, 0.2, 0.45), 1, 0.6, 6],
	"barbaro": [Color(1.0, 0.4, 0.2), 3, 2.0, 7],
}

const SH_ADD := preload("res://game/art/fx_particle_add.gdshader")
const SH_MIX := preload("res://game/art/fx_particle_mix.gdshader")

var _deco := {}       # nó do herói -> {"ring", "shadow", "aura", "cls", "t"}
var _frame := 0


static func scale_mult() -> float:
	return SCALE


## Chamado por world_view para cada herói desenhado neste quadro.
func track(hero_node: Node3D, cls: String, active: bool) -> void:
	if hero_node == null:
		return
	var d: Dictionary = _deco.get(hero_node, {})
	if d.is_empty() or str(d["cls"]) != cls:
		_drop(hero_node)
		d = _make(cls)
		_deco[hero_node] = d
	d["t"] = _frame
	var p := hero_node.global_position
	(d["shadow"] as Node3D).global_position = p + Vector3(0, 0.03, 0)
	var ring: MeshInstance3D = d["ring"]
	ring.global_position = p + Vector3(0, 0.05, 0)
	ring.rotation.y += 0.01
	# O herói da vez tem o anel mais forte; os outros, mais apagado.
	(ring.material_override as ShaderMaterial).set_shader_parameter("strength", 1.0 if active else 0.55)
	if d["aura"] != null:
		(d["aura"] as Node3D).global_position = p + Vector3(0, 0.9, 0)


## No fim do quadro: some com o que não foi desenhado (herói caído, troca de ato).
func end_frame() -> void:
	for k in _deco.keys():
		if not is_instance_valid(k) or int(_deco[k]["t"]) != _frame or not (k as Node3D).is_visible_in_tree():
			_drop(k)
	_frame += 1


func _drop(k) -> void:
	if not _deco.has(k):
		return
	for key in ["ring", "shadow", "aura"]:
		var n = _deco[k][key]
		if n != null and is_instance_valid(n):
			n.queue_free()
	_deco.erase(k)


func _make(cls: String) -> Dictionary:
	var info: Array = CLS.get(cls, [Color(0.9, 0.9, 0.9), 4, 1.0, 4])
	var col: Color = info[0]
	var shadow := MeshInstance3D.new()
	var sq := PlaneMesh.new()
	sq.size = Vector2(2.6, 2.6)
	shadow.mesh = sq
	shadow.material_override = _shadow_mat()
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	var ring := MeshInstance3D.new()
	var rq := PlaneMesh.new()
	rq.size = Vector2(3.2, 3.2)
	ring.mesh = rq
	ring.material_override = _ring_mat(col)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	var aura := _aura(col, int(info[1]), float(info[2]), int(info[3]))
	add_child(aura)
	return {"ring": ring, "shadow": shadow, "aura": aura, "cls": cls, "t": _frame}


func _shadow_mat() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
void fragment() {
	float d = length(UV - 0.5) * 2.0;
	ALBEDO = vec3(0.05, 0.04, 0.08);
	ALPHA = smoothstep(1.0, 0.25, d) * 0.45;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.render_priority = -2
	return m


func _ring_mat(col: Color) -> ShaderMaterial:
	# Anel pintado: borda irregular (ruído barato no ângulo), quatro marcas e um brilho que gira devagar.
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 col : source_color;
uniform float strength = 1.0;
float h(float x) { return fract(sin(x * 91.7) * 43758.5); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float a = atan(p.y, p.x);
	float wob = (h(floor(a * 6.0)) - 0.5) * 0.035 + sin(a * 9.0) * 0.012;
	float r = 0.78 + wob;
	float band = smoothstep(0.075, 0.035, abs(d - r));
	float ticks = step(0.92, cos(a * 4.0)) * smoothstep(0.12, 0.06, abs(d - (r - 0.1)));
	float inner = smoothstep(r, r - 0.5, d) * 0.12;
	float sweep = pow(max(0.0, cos(a - TIME * 1.5)), 8.0) * band * 0.6;
	ALBEDO = mix(col.rgb, vec3(1.0), sweep * 0.5);
	ALPHA = clamp(band * 0.85 + ticks * 0.7 + inner + sweep, 0.0, 1.0) * strength;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("col", col)
	m.render_priority = -1
	return m


func _aura(col: Color, shape: int, rise: float, amount: int) -> GPUParticles3D:
	var q := int(Settings.v.get("quality", 2))
	var p := GPUParticles3D.new()
	p.amount = maxi(2, int(round(amount * [0.4, 0.7, 1.0][clampi(q, 0, 2)])))
	p.lifetime = 1.4
	p.local_coords = false
	p.randomness = 0.5
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.emission_ring_radius = 0.75
	pm.emission_ring_inner_radius = 0.45
	pm.emission_ring_height = 0.6
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.2 * rise
	pm.initial_velocity_max = 0.6 * rise
	pm.gravity = Vector3(0, 0.15 * rise, 0)
	pm.scale_min = 0.12
	pm.scale_max = 0.24
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	var cv := Curve.new()
	cv.add_point(Vector2(0, 0.2))
	cv.add_point(Vector2(0.2, 1.0))
	cv.add_point(Vector2(1, 0))
	var ct := CurveTexture.new()
	ct.curve = cv
	pm.scale_curve = ct
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(col.r, col.g, col.b, 0), Color(col.r, col.g, col.b, 0.9), Color(col.r, col.g, col.b, 0)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	var m := ShaderMaterial.new()
	# Sombra (assassino) tinge por cima; o resto brilha de leve.
	m.shader = SH_MIX if shape == 1 else SH_ADD
	m.set_shader_parameter("shape", shape)
	m.set_shader_parameter("paint", 1.0)
	m.set_shader_parameter("glow", 1.2)
	qm.material = m
	p.draw_pass_1 = qm
	p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 8, 8))
	p.emitting = true
	return p
