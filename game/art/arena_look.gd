class_name ArenaLook
extends RefCounted
## Arena do chefe (rodada visual 20/11/2026, docs/RODADA_VISUAL_2026-11-20.md). --arena=0 (padrão) = a de antes.
##   1 Pedra e brasa: círculo de runas dourado pintado, borda de lajes, chamas nos braseiros, luz central quente.
##   2 Cripta de runas: runas frias (azul-esverdeado) que pulsam, lajes escuras, chamas azuis, luz central fria.
## world_view.build_arena() pula os anéis roxos antigos quando VAR > 0 e chama build() no fim.

static var VAR := 2   # padrão aprovado em 20/11/2026 na página de revisão (0 = como era antes)

const NAMES := ["Atual", "Pedra e brasa", "Cripta de runas"]

const P := {
	1: {"rune": Color(1.0, 0.78, 0.35), "rune2": Color(0.85, 0.35, 0.12), "stone": Color(0.42, 0.36, 0.32), "stone2": Color(0.3, 0.26, 0.24),
		"light": Color(1.0, 0.72, 0.42), "light_e": 2.2, "flame": Color(1.0, 0.55, 0.18), "pulse": 0.25},
	2: {"rune": Color(0.45, 0.95, 0.9), "rune2": Color(0.35, 0.4, 0.95), "stone": Color(0.26, 0.28, 0.33), "stone2": Color(0.18, 0.19, 0.24),
		"light": Color(0.5, 0.75, 1.0), "light_e": 2.6, "flame": Color(0.35, 0.75, 1.0), "pulse": 0.6},
}


static func on() -> bool:
	return VAR > 0 and P.has(VAR)


static func center_light() -> Array:
	if not on():
		return [Color(0.75, 0.35, 1.0), 3.0]
	return [P[VAR]["light"], P[VAR]["light_e"]]


static func flame_color() -> Color:
	return P[VAR]["flame"] if on() else Color(1.0, 0.55, 0.2)


## Monta as peças novas sob `root`, centradas em `c` com raio `r`. `braziers`: posições dos braseiros.
static func build(root: Node3D, c: Vector3, r: float, braziers: Array) -> void:
	if not on():
		return
	var q: Dictionary = P[VAR]
	# Círculo de runas pintado no chão (um plano com shader: anéis de pincel, runas, raios, pulso lento).
	var circ := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2) * (r + 0.6)
	circ.mesh = pm
	circ.material_override = _rune_mat(q)
	circ.position = c + Vector3(0, 0.05, 0)
	circ.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(circ)
	# Borda de lajes: blocos baixos irregulares em volta do círculo (um MultiMesh só).
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(1, 1, 1)
	var sm := StandardMaterial3D.new()
	sm.vertex_color_use_as_albedo = true
	sm.roughness = 0.95
	bm.material = sm
	mm.mesh = bm
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var n := int(TAU * (r + 1.2) / 1.25)
	mm.instance_count = n
	for i in n:
		var a := TAU * (i + rng.randf_range(-0.12, 0.12)) / n
		var rr := r + 1.0 + rng.randf_range(-0.15, 0.2)
		var t := Transform3D()
		t = t.scaled(Vector3(rng.randf_range(0.9, 1.2), rng.randf_range(0.18, 0.32), rng.randf_range(0.6, 0.85)))
		t = t.rotated(Vector3.UP, -a + PI * 0.5 + rng.randf_range(-0.08, 0.08))
		t.origin = c + Vector3(cos(a) * rr, 0.05, sin(a) * rr)
		mm.set_instance_transform(i, t)
		var st: Color = (q["stone"] as Color).lerp(q["stone2"], rng.randf())
		mm.set_instance_color(i, st)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	root.add_child(mmi)
	# Chamas nos braseiros: partículas com o shader de chama dos efeitos novos.
	for bp in braziers:
		root.add_child(_flame((bp as Vector3) + Vector3(0, 1.7, 0), q["flame"]))


static func _rune_mat(q: Dictionary) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 c1 : source_color;
uniform vec4 c2 : source_color;
uniform float pulse = 0.3;
float h(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float band(float d, float r, float w) { return smoothstep(w, w * 0.4, abs(d - r)); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float a = atan(p.y, p.x);
	// Borda de pincel: a largura varia com o ângulo, como tinta passada à mão.
	float brush = 0.75 + 0.25 * sin(a * 7.0 + h(vec2(floor(a * 5.0), 1.0)) * 6.0);
	float rings = band(d, 0.93, 0.03 * brush) + band(d, 0.86, 0.012) * 0.8 + band(d, 0.55, 0.02 * brush) * 0.9 + band(d, 0.2, 0.025);
	// Runas: entre 0.86 e 0.93, 24 casas com um traço de forma sorteada cada.
	float cell = floor((a + PI) / TAU * 24.0);
	float fa = fract((a + PI) / TAU * 24.0);
	float rr = (d - 0.865) / 0.055;
	float g = 0.0;
	if (rr > 0.15 && rr < 0.85) {
		float k = h(vec2(cell, 3.0));
		float v = step(abs(fa - 0.5), 0.07);
		float hz = step(abs(rr - (0.3 + k * 0.4)), 0.09) * step(abs(fa - 0.5), 0.25);
		float dg = step(abs((fa - 0.5) - (rr - 0.5) * (k > 0.5 ? 0.6 : -0.6)), 0.06);
		g = max(v, max(hz * step(0.3, k), dg * step(k, 0.7)));
	}
	// Raios da estrela entre os anéis de dentro.
	float spokes = step(0.985, cos(a * 6.0)) * step(0.2, d) * step(d, 0.55);
	float star = band(d * (1.0 + 0.25 * abs(cos(a * 3.0))), 0.55, 0.012);
	float m = clamp(rings + g + spokes * 0.8 + star * 0.7, 0.0, 1.0);
	float pl = 1.0 - pulse + pulse * (0.5 + 0.5 * sin(TIME * 1.6 - d * 4.0));
	vec3 col = mix(c2.rgb, c1.rgb, smoothstep(0.2, 0.9, d));
	float wash = smoothstep(1.0, 0.0, d) * 0.08;
	ALBEDO = col * (0.85 + 0.6 * pl);
	ALPHA = clamp(m * (0.75 + 0.25 * pl) + wash, 0.0, 1.0) * step(d, 1.0);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("c1", q["rune"])
	m.set_shader_parameter("c2", q["rune2"])
	m.set_shader_parameter("pulse", q["pulse"])
	m.render_priority = -1
	return m


static func _flame(pos: Vector3, col: Color) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 0.8
	p.local_coords = false
	p.randomness = 0.4
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.2
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 1.6
	pm.gravity = Vector3(0, 1.5, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.0
	var cv := Curve.new()
	cv.add_point(Vector2(0, 0.5))
	cv.add_point(Vector2(0.3, 1.0))
	cv.add_point(Vector2(1, 0.2))
	var ct := CurveTexture.new()
	ct.curve = cv
	pm.scale_curve = ct
	pm.color = col
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	var m := ShaderMaterial.new()
	m.shader = preload("res://game/art/fx_particle_add.gdshader")
	m.set_shader_parameter("shape", 0)
	m.set_shader_parameter("paint", 1.0)
	m.set_shader_parameter("glow", 1.3)
	qm.material = m
	p.draw_pass_1 = qm
	p.position = pos
	p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	p.emitting = true
	return p
