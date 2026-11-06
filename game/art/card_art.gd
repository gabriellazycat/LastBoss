class_name CardArt
extends SubViewport
## Renderiza o modelo de cada carta uma vez (miniatura) e guarda as texturas.

const CAT_BG := {
	"monster": Color(0.22, 0.1, 0.3), "swarm": Color(0.25, 0.12, 0.22), "spell": Color(0.1, 0.14, 0.35),
	"structure": Color(0.25, 0.16, 0.1), "route": Color(0.08, 0.22, 0.16), "lair": Color(0.3, 0.22, 0.06),
	"finisher": Color(0.35, 0.06, 0.1),
}

static var textures: Dictionary = {}
var pivot: Node3D
var cam: Camera3D
var bg: MeshInstance3D


func _ready() -> void:
	size = Vector2i(256, 160)
	own_world_3d = true
	transparent_bg = false
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.06, 0.14)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.45, 0.7)
	e.ambient_light_energy = 0.8
	e.glow_enabled = true
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-40, 35, 0)
	l.light_energy = 1.5
	add_child(l)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 200, 0)
	rim.light_color = Color(0.7, 0.5, 1.0)
	rim.light_energy = 1.2
	add_child(rim)
	cam = Camera3D.new()
	cam.fov = 30
	add_child(cam)
	pivot = Node3D.new()
	add_child(pivot)


func render_all(data: GameData) -> void:
	var env: WorldEnvironment = get_child(0)
	for c in data.cards:
		if c.category == "aux":
			continue
		for ch in pivot.get_children():
			ch.queue_free()
		var mesh: Mesh = Models.unit(c.id) if c.is_unit else Models.icon(c.id)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = Models.glow_material(0.15)
		pivot.add_child(mi)
		var aabb := mesh.get_aabb()
		var h := maxf(aabb.size.y, maxf(aabb.size.x, aabb.size.z) * 0.8)
		var center := aabb.get_center()
		pivot.rotation.y = deg_to_rad(-25)
		cam.position = center + Vector3(0, h * 0.35, h * 2.6 + 0.5)
		cam.look_at(center, Vector3.UP)
		env.environment.background_color = CAT_BG.get(c.type, Color(0.15, 0.1, 0.2))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		textures[c.id] = ImageTexture.create_from_image(get_texture().get_image())
	queue_free()
