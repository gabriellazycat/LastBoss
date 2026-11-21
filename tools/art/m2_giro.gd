extends Node3D
## Giro 360° e clipe (andar + ataque) dos modelos de --modelos=1 (assets/models/m2_a), com o shader, o atlas, a luz e o
## chão do jogo (rodada visual 20/11/2026, inimigos novos). O ataque toca pela mesma lei do jogo (pose_lunge de 1 a 0,
## como world_view.gd), só que mais devagar para dar para ver.
## godot --position -6000,0 --resolution 720x720 --path . res://tools/art/m2_giro.tscn -- --ids=rat_brute,ghoul --out=<pasta>/ [--giro=12] [--clip=1]
## Grava <out>/giro/<id>_NN.png e, com --clip=1, os quadros <clipout ou out>/clip_<id>/f_NNNN.png (30 qps; o webm sai pelo
## ffmpeg em tools/art/blender_m2/giro_inimigos.sh).

var args := {}
var cam: Camera3D
var mi: MeshInstance3D
var mat: ShaderMaterial


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Looks.M2 = 1
	Settings.v["look_ground"] = 10
	Settings.v["paint_look"] = 1
	PaintLook.apply()
	_env()
	mi = MeshInstance3D.new()
	add_child(mi)
	_run.call_deferred()


func _env() -> void:
	cam = Camera3D.new()
	cam.fov = 32
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
	env.ssao_enabled = true
	env.glow_enabled = true
	env.adjustment_enabled = true
	we.environment = env
	add_child(we)
	GroundLooks.apply_env(env, sun)
	env.fog_enabled = false
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	var g := MeshInstance3D.new()
	g.mesh = pm
	g.material_override = GroundLooks.ground_material()
	add_child(g)


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)


func _frame() -> void:
	await get_tree().process_frame


func _aim(h: float, elev_deg: float, yaw_cam: float, dist_k := 3.2) -> void:
	var d := h * dist_k + 1.2
	var el := deg_to_rad(elev_deg)
	var tgt := Vector3(0, h * 0.45, 0)
	cam.position = tgt + Vector3(sin(yaw_cam) * cos(el), sin(el), cos(yaw_cam) * cos(el)) * d
	cam.look_at(tgt, Vector3.UP)


func _run() -> void:
	var out := str(args.get("out", "user://m2/"))
	var n := int(args.get("giro", "12"))
	DirAccess.make_dir_recursive_absolute(out + "giro")
	for id in str(args.get("ids", "")).split(",", false):
		var m := Looks.m2_mesh(id)
		if m == null:
			push_warning("sem m2: " + id)
			continue
		mi.mesh = m
		mat = Looks.material(7, 0.0, false, m)
		mat.set_shader_parameter("pose_frame", 0.0)
		mat.set_shader_parameter("pose_lunge", 0.0)
		mi.material_override = mat
		var h := m.get_aabb().size.y
		var fly := id in ["fire_imp", "bat_cloud"]
		mi.position.y = 0.0
		# giro: o modelo gira (frente para a câmera no quadro 0), câmera a 30°
		_aim(h, 30.0, 0.0)
		for k in 6:
			await _frame()
		for k in n:
			mi.rotation.y = PI + TAU * k / n
			await _frame()
			await _shot(out + "giro/%s_%02d.png" % [id, k])
		if args.get("clip", "0") == "1":
			var cd := str(args.get("clipout", out)) + "clip_%s/" % id
			DirAccess.make_dir_recursive_absolute(cd)
			mi.rotation.y = PI - 0.6
			_aim(h, 38.0, 0.0, 2.8)
			var f := 0
			var walk_rate := 1.1 if not fly else 1.4
			# 2 s andando
			for k in 60:
				mat.set_shader_parameter("pose_frame", fmod(k / 30.0 * walk_rate, 1.0))
				mat.set_shader_parameter("pose_lunge", 0.0)
				await _frame()
				await _shot(cd + "f_%04d.png" % f)
				f += 1
			# ataque em câmera lenta (x5: 1 s) e duas vezes em x2 (0,4 s), sempre lunge 1 -> 0 como no jogo
			for spec in [[30, 8], [12, 4], [12, 10]]:
				var nf: int = spec[0]
				for k in nf + 1:
					mat.set_shader_parameter("pose_frame", 0.0)
					mat.set_shader_parameter("pose_lunge", 1.0 - float(k) / nf)
					await _frame()
					await _shot(cd + "f_%04d.png" % f)
					f += 1
				for k in spec[1]:
					mat.set_shader_parameter("pose_lunge", 0.0)
					await _frame()
					await _shot(cd + "f_%04d.png" % f)
					f += 1
	get_tree().quit()
