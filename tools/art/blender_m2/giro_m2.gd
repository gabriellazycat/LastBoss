extends Node3D
## Giro 360° e clipe das estruturas (rodada visual 20/11/2026), com o material do jogo (look 7: VAT + atlas).
## Roda fora da tela (regra do usuário: nunca roubar o mouse):
##   godot --position -6000,0 --path . res://tools/art/blender_m2/giro_m2.tscn -- --ids=furnace,war_banner --out=<pasta>/ --mode=giro
## --mode=giro: <out>/<id>_NN.png (--n quadros, o modelo gira, câmera a 50°) · clip: <out>/<id>/f_NNNN.png a 30 qps
## (2 voltas do laço parado, o ataque, mais meia volta) · board: <out>/board.png (todas lado a lado, câmera do jogo)
## --m2=1 (padrão) usa assets/models/m2_a (Looks.M2); --m2=0 mostra o empréstimo de hoje (VARIANTS, tinta e escala).

const FIG_SCALE := 1.2
var args := {}
var cam: Camera3D
var ids: PackedStringArray
var mode := "giro"
var out := "user://"
var nfr := 12
var mi: MeshInstance3D
var mat: ShaderMaterial
var queue: Array = []   # [id, quadro]


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	get_window().size = Vector2i(int(args.get("w", "960")), int(args.get("h", "960")))
	Settings.load_all()
	Looks.M2 = int(args.get("m2", "1"))
	ids = str(args.get("ids", "furnace")).split(",", false)
	mode = str(args.get("mode", "giro"))
	out = str(args.get("out", "user://"))
	nfr = int(args.get("n", "12"))
	_env()
	if mode == "board":
		_board()
		return
	for id in ids:
		var n := nfr if mode == "giro" else 30 * 6
		for f in n:
			queue.append([id, f])
	_load(ids[0])


func _load(id: String) -> void:
	if mi:
		mi.queue_free()
	mi = MeshInstance3D.new()
	mi.mesh = Looks.unit_mesh(id)
	mat = Looks.unit_material(0.0, false, id)
	mi.material_override = mat
	mi.scale = Vector3.ONE * Looks.scale_of(id) * FIG_SCALE
	add_child(mi)
	var bb := mi.mesh.get_aabb()
	var h := maxf(bb.size.y, maxf(bb.size.x, bb.size.z) * 0.7) * mi.scale.y
	var ctr := Vector3(0, (bb.position.y + bb.size.y * 0.45) * mi.scale.y, 0)
	var d := h * 2.1 + 1.0
	var el := deg_to_rad(50.0)
	cam.position = ctr + Vector3(0, sin(el), cos(el)) * d
	cam.look_at(ctr, Vector3.UP)
	mi.set_meta("id", id)


func _board() -> void:
	var x := -(ids.size() - 1) * 2.2
	for id in ids:
		var m := MeshInstance3D.new()
		m.mesh = Looks.unit_mesh(id)
		m.material_override = Looks.unit_material(0.0, false, id)
		m.scale = Vector3.ONE * Looks.scale_of(id) * FIG_SCALE
		m.position = Vector3(x, 0, 0)
		m.rotation.y = PI + 0.35
		add_child(m)
		x += 4.4
	cam.fov = 40
	var span := ids.size() * 4.4
	cam.position = Vector3(0, span * 0.62, span * 0.52)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	queue.append(["board", 0])


var _wait := 4
var _busy := false


func _process(_d: float) -> void:
	if _busy:
		return
	if _wait > 0:
		_wait -= 1
		return
	if queue.is_empty():
		get_tree().quit()
		return
	var q: Array = queue[0]
	if q[0] == "board":
		get_viewport().get_texture().get_image().save_png(out + "board.png")
		queue.pop_front()
		_wait = 1
		return
	if mi.get_meta("id") != q[0]:
		_load(q[0])
		_wait = 3
		return
	var f: int = q[1]
	if mode == "giro":
		mi.rotation.y = PI + TAU * float(f) / float(nfr)
		if mat:
			mat.set_shader_parameter("pose_frame", 0.3)
	else:
		# 2 voltas do laço parado (0,45 volta/s como no jogo), o ataque em 0,8 s, e o laço de novo
		var t := float(f) / 30.0
		var lunge := 0.0
		if t >= 4.4 and t < 5.2:
			lunge = (t - 4.4) / 0.8
		mi.rotation.y = PI + 0.45
		if mat:
			mat.set_shader_parameter("pose_frame", fposmod(t * 0.45, 1.0))
			mat.set_shader_parameter("pose_lunge", lunge)
	_busy = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	_busy = false
	var img := get_viewport().get_texture().get_image()
	if mode == "giro":
		img.save_png(out + "%s_%02d.png" % [q[0], f])
	else:
		DirAccess.make_dir_recursive_absolute(out + q[0])
		img.save_png(out + "%s/f_%04d.png" % [q[0], f])
	queue.pop_front()


func _env() -> void:
	cam = Camera3D.new()
	cam.fov = 38
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.sky = Sky.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.ssao_enabled = true
	env.glow_enabled = true
	env.adjustment_enabled = true
	we.environment = env
	add_child(we)
	PaintLook.apply()
	GroundLooks.apply_env(env, sun)
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	var g := MeshInstance3D.new()
	g.mesh = pm
	g.material_override = GroundLooks.ground_material()
	add_child(g)
