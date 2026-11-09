class_name CardArt
extends SubViewport
## Renderiza o modelo de cada carta uma vez (retrato) e guarda as texturas.
## 512x384 com MSAA, luz de três pontos (principal quente, preenchimento frio, contraluz na cor do tipo),
## chão escuro que recebe a sombra e fundo com um halo atrás do modelo. As cartas cortam por cobertura.

const CAT_BG := {
	"monster": Color(0.22, 0.1, 0.3), "swarm": Color(0.25, 0.12, 0.22), "spell": Color(0.1, 0.14, 0.35),
	"structure": Color(0.25, 0.16, 0.1), "route": Color(0.08, 0.22, 0.16), "lair": Color(0.3, 0.22, 0.06),
	"finisher": Color(0.35, 0.06, 0.1),
}

static var textures: Dictionary = {}
var pivot: Node3D
var cam: Camera3D
var bg: MeshInstance3D
var rim: DirectionalLight3D
var floor_: MeshInstance3D
var plinth: MeshInstance3D
var plinth_ring: MeshInstance3D


func _ready() -> void:
	size = Vector2i(512, 384)
	own_world_3d = true
	transparent_bg = false
	msaa_3d = Viewport.MSAA_4X
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.06, 0.14)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.45, 0.62)
	e.ambient_light_energy = 0.55
	e.glow_enabled = true
	e.glow_intensity = 0.6
	e.glow_hdr_threshold = 1.1
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.95
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.08
	e.adjustment_saturation = 1.08
	env.environment = e
	add_child(env)
	# Principal: quente, do alto à esquerda, com sombra (a mesma direção da luz das molduras).
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, 38, 0)
	key.light_energy = 1.45
	key.light_color = Color(1.0, 0.93, 0.82)
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 30.0
	add_child(key)
	# Preenchimento frio e fraco pela direita.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-12, -60, 0)
	fill.light_energy = 0.45
	fill.light_color = Color(0.6, 0.7, 1.0)
	add_child(fill)
	# Contraluz na cor do tipo: recorta a silhueta do fundo.
	rim = DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-18, 195, 0)
	rim.light_energy = 1.25
	add_child(rim)
	cam = Camera3D.new()
	cam.fov = 28
	add_child(cam)
	# Fundo preso à câmera: halo claro atrás do modelo, escurecendo para as bordas.
	bg = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(24, 18)
	bg.mesh = q
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1.1, 1.04, 1.0))
	g.add_point(0.35, Color(0.7, 0.66, 0.68))
	g.set_color(1, Color(0.14, 0.12, 0.16))
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.4)
	gt.fill_to = Vector2(0.5, 1.15)
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_texture = gt
	bg.material_override = bm
	bg.position = Vector3(0, 0, -22)
	cam.add_child(bg)
	# Chão: disco escuro que recebe a sombra e some nas bordas.
	floor_ = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	floor_.mesh = pm
	var fg := Gradient.new()
	fg.set_color(0, Color(0.12, 0.1, 0.12, 1.0))
	fg.set_color(1, Color(0.12, 0.1, 0.12, 0.0))
	var ft := GradientTexture2D.new()
	ft.gradient = fg
	ft.fill = GradientTexture2D.FILL_RADIAL
	ft.fill_from = Vector2(0.5, 0.5)
	ft.fill_to = Vector2(0.5, 1.0)
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = ft
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	fm.roughness = 0.9
	floor_.material_override = fm
	add_child(floor_)
	# Pedestal de pedra com um anel de runas aceso na cor do tipo, sob os ícones (cartas sem monstro).
	plinth = MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.62
	pc.bottom_radius = 0.7
	pc.height = 0.16
	pc.radial_segments = 24
	plinth.mesh = pc
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.16, 0.14, 0.17)
	pmat.roughness = 0.85
	plinth.material_override = pmat
	add_child(plinth)
	plinth_ring = MeshInstance3D.new()
	var tr := TorusMesh.new()
	tr.inner_radius = 0.66
	tr.outer_radius = 0.7
	tr.rings = 40
	tr.ring_segments = 4
	plinth_ring.mesh = tr
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plinth_ring.material_override = rmat
	add_child(plinth_ring)
	pivot = Node3D.new()
	add_child(pivot)


func render_all(data: GameData) -> void:
	var env: WorldEnvironment = get_child(0)
	for c in data.cards:
		if c.category == "aux":
			continue
		for ch in pivot.get_children():
			ch.queue_free()
		var mesh: Mesh = Looks.unit_mesh(c.id) if c.is_unit else Models.icon(c.id)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = Looks.unit_material(0.15, false) if c.is_unit else Models.glow_material(0.15)
		pivot.add_child(mi)
		var aabb := mesh.get_aabb()
		var h := maxf(aabb.size.y, maxf(aabb.size.x, aabb.size.z) * 0.8)
		var center := aabb.get_center()
		# Os modelos novos (looks) olham para -Z: gira para a carta mostrar a frente, em três quartos.
		pivot.rotation.y = deg_to_rad(150 if c.is_unit and Looks.enemies() > 0 else -30)
		# Monstros um pouco de baixo (heroicos) e mais perto; ícones de feitiço de cima, centrados.
		if c.is_unit:
			cam.position = center + Vector3(0, h * 0.12, h * 1.95 + 0.3)
			cam.look_at(center + Vector3(0, h * 0.04, 0), Vector3.UP)
		else:
			cam.position = center + Vector3(0, h * 0.42, h * 2.0 + 0.35)
			cam.look_at(center, Vector3.UP)
		floor_.position = Vector3(center.x, aabb.position.y - 0.01, center.z)
		floor_.scale = Vector3.ONE * h * 2.4
		var bc: Color = CAT_BG.get(c.type, Color(0.15, 0.1, 0.2))
		var pk := maxf(aabb.size.x, aabb.size.z) * 0.95
		plinth.visible = not c.is_unit
		plinth_ring.visible = not c.is_unit
		plinth.scale = Vector3.ONE * pk
		plinth.position = Vector3(center.x, aabb.position.y - 0.08 * pk, center.z)
		plinth_ring.scale = Vector3.ONE * pk
		plinth_ring.position = plinth.position + Vector3(0, 0.08 * pk, 0)
		(plinth_ring.material_override as StandardMaterial3D).albedo_color = bc.lightened(0.6) * 2.2
		env.environment.background_color = bc.darkened(0.5)
		env.environment.ambient_light_color = bc.lightened(0.45)
		(bg.material_override as StandardMaterial3D).albedo_color = bc
		rim.light_color = bc.lightened(0.55)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := get_texture().get_image()
		img.generate_mipmaps()
		textures[c.id] = ImageTexture.create_from_image(img)
	queue_free()
