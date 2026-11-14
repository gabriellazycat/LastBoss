class_name DeskScene
extends Node3D
## Mesa do Lorde atrás do menu na pele Diário (estudo em docs/variacoes/cartas/mesa.html): tampo de madeira,
## velas com luz tremendo, faca fincada num cartaz de "procura-se", caveira, tinteiro, moedas e cartas soltas.
## Cada tela do menu tem um papel deitado na mesa (textura de um SubViewport); clicar nele abre a tela, e o
## MainMenu anima o papel 2D saindo do ponto da mesa (screen_point). A tela aberta some da mesa.

signal paper_clicked(id: String)

const ORIGIN := Vector3(0, 300, 0)
const CAM_POS := Vector3(0, 1.3, 1.0)
const CAM_LOOK := Vector3(0, 0, -0.14)
const FLAME_COL := Color(1.0, 0.62, 0.3)
## Papéis do menu: id, posição (x, z) no tampo, giro em graus, tamanho (m).
const PAPERS := [
	["title", Vector2(-0.6, 0.1), 7.0, Vector2(0.4, 0.46)],
	["decks", Vector2(0.32, -0.18), -9.0, Vector2(0.5, 0.36)],
	["collection", Vector2(-0.04, -0.6), 5.0, Vector2(0.44, 0.31)],
	["compendium", Vector2(0.84, -0.22), -6.0, Vector2(0.42, 0.3)],
	["settings", Vector2(0.86, 0.3), 14.0, Vector2(0.3, 0.38)],
	["continue", Vector2(0.28, 0.34), -11.0, Vector2(0.28, 0.19)],
]

var cam: Camera3D
var env: Environment
var menu: MainMenu
var data: GameData
var hidden_lights: Array = []
var saved := {}
var papers := {}          # id -> {pivot: Node3D, rest: Vector3, vp: SubViewport, frames: int}
var current := ""
var hover := ""
var flames: Array = []    # [OmniLight3D, MeshInstance3D, energia, fase]
var t := 0.0
var par := Vector2.ZERO


func setup(c: Camera3D, e: Environment, lights: Array, m: MainMenu, d: GameData) -> void:
	cam = c
	env = e
	hidden_lights = lights
	menu = m
	data = d


func _ready() -> void:
	position = ORIGIN
	_mood(true)
	_table()
	_props()
	_cards()
	for spec in PAPERS:
		_paper(spec[0], spec[1], spec[2], spec[3])
	_wanted()
	get_viewport().physics_object_picking = true


func _exit_tree() -> void:
	_mood(false)


## Luz e ambiente da sala: some o sol do bosque, entra um quarto escuro com luz de vela. Volta tudo ao sair.
func _mood(on: bool) -> void:
	if env == null:
		return
	if on:
		saved = {"bg": env.background_mode, "bgc": env.background_color, "amb": env.ambient_light_color, "ambe": env.ambient_light_energy,
			"fog": env.fog_enabled, "vfog": env.volumetric_fog_enabled, "fov": cam.fov if cam else 40.0, "exp": env.tonemap_exposure}
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.012, 0.008, 0.006)
		env.ambient_light_color = Color(0.55, 0.42, 0.32)
		env.ambient_light_energy = 0.32
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
		env.tonemap_exposure = 1.1
		for l in hidden_lights:
			if is_instance_valid(l):
				saved[l] = l.visible
				l.visible = false
		if cam:
			cam.fov = 48.0
	else:
		if saved.is_empty():
			return
		env.background_mode = saved["bg"]
		env.background_color = saved["bgc"]
		env.ambient_light_color = saved["amb"]
		env.ambient_light_energy = saved["ambe"]
		env.fog_enabled = saved["fog"]
		env.volumetric_fog_enabled = saved["vfog"]
		env.tonemap_exposure = saved["exp"]
		for l in hidden_lights:
			if is_instance_valid(l) and saved.has(l):
				l.visible = saved[l]
		if is_instance_valid(cam):
			cam.fov = saved["fov"]
		saved.clear()


func _mat(col: Color, rough := 0.8, metal := 0.0) -> Material:
	# Mundo pintado (Settings "paint_look"): os objetos da mesa também levam o guache dos materiais.
	if int(Settings.v.get("paint_look", 0)) > 0:
		var pm := ShaderMaterial.new()
		pm.shader = preload("res://game/art/paint_std.gdshader")
		pm.set_shader_parameter("albedo", col)
		pm.set_shader_parameter("roughness", rough)
		pm.set_shader_parameter("metallic", metal)
		return pm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m


func _mesh(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	add_child(mi)
	return mi


func _table() -> void:
	var top := BoxMesh.new()
	top.size = Vector3(3.2, 0.09, 2.2)
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://game/art/desk_wood.gdshader")
	wm.set_shader_parameter("origin", ORIGIN)
	_mesh(top, wm, Vector3(0, -0.045, -0.2))
	# Quarto escuro em volta (o céu do bosque não pode aparecer).
	var room := BoxMesh.new()
	room.size = Vector3(9, 5, 9)
	room.flip_faces = true
	_mesh(room, _mat(Color(0.03, 0.022, 0.018), 1.0), Vector3(0, 1.0, -1.0))
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.6, 0.85)
	moon.light_energy = 0.18
	moon.rotation_degrees = Vector3(-60, -35, 0)
	add_child(moon)


func _props() -> void:
	_candles(Vector3(1.0, 0, -0.66), [0.2, 0.13, 0.08], true)
	_candles(Vector3(-1.05, 0, -0.5), [0.15], false)
	# Caveira.
	var bone := _mat(Color(0.86, 0.8, 0.66), 0.7)
	var sk := Node3D.new()
	sk.position = Vector3(1.22, 0, 0.04)
	sk.rotation_degrees = Vector3(0, -28, 0)
	add_child(sk)
	var skull := SphereMesh.new()
	skull.radius = 0.075
	skull.height = 0.14
	var s1 := _mesh(skull, bone, Vector3(0, 0.085, 0))
	s1.reparent(sk, false)
	var jaw := BoxMesh.new()
	jaw.size = Vector3(0.075, 0.035, 0.07)
	_mesh(jaw, bone, Vector3(0, 0.025, 0.02)).reparent(sk, false)
	var hole := SphereMesh.new()
	hole.radius = 0.022
	hole.height = 0.04
	var black := _mat(Color(0.02, 0.015, 0.01), 1.0)
	for x in [-0.028, 0.028]:
		_mesh(hole, black, Vector3(x, 0.09, 0.058)).reparent(sk, false)
	var nose := PrismMesh.new()
	nose.size = Vector3(0.018, 0.022, 0.01)
	_mesh(nose, black, Vector3(0, 0.062, 0.071)).reparent(sk, false)
	# Tinteiro e pena.
	var ink := CylinderMesh.new()
	ink.top_radius = 0.03
	ink.bottom_radius = 0.042
	ink.height = 0.07
	_mesh(ink, _mat(Color(0.06, 0.06, 0.09), 0.15, 0.2), Vector3(-0.98, 0.035, -0.08))
	var neck := CylinderMesh.new()
	neck.top_radius = 0.016
	neck.bottom_radius = 0.018
	neck.height = 0.025
	_mesh(neck, _mat(Color(0.05, 0.05, 0.07), 0.2), Vector3(-0.98, 0.08, -0.08))
	var quill := SphereMesh.new()
	quill.radius = 0.02
	quill.height = 0.26
	_mesh(quill, _mat(Color(0.88, 0.84, 0.74), 0.9), Vector3(-0.95, 0.17, -0.1), Vector3(0, 0, -22), Vector3(0.45, 1.0, 1.0))
	# Faca fincada no cartaz.
	var kn := Node3D.new()
	kn.position = Vector3(0.44, 0, -0.7)
	kn.rotation_degrees = Vector3(8, 20, -6)
	add_child(kn)
	var blade := BoxMesh.new()
	blade.size = Vector3(0.028, 0.07, 0.004)
	_mesh(blade, _mat(Color(0.75, 0.77, 0.8), 0.25, 0.9), Vector3(0, 0.02, 0)).reparent(kn, false)
	var guard := BoxMesh.new()
	guard.size = Vector3(0.08, 0.012, 0.016)
	_mesh(guard, _mat(Color(0.45, 0.36, 0.2), 0.4, 0.7), Vector3(0, 0.06, 0)).reparent(kn, false)
	var grip := CylinderMesh.new()
	grip.top_radius = 0.012
	grip.bottom_radius = 0.014
	grip.height = 0.11
	_mesh(grip, _mat(Color(0.18, 0.1, 0.06), 0.85), Vector3(0, 0.12, 0)).reparent(kn, false)
	var pommel := SphereMesh.new()
	pommel.radius = 0.016
	pommel.height = 0.032
	_mesh(pommel, _mat(Color(0.5, 0.42, 0.25), 0.35, 0.8), Vector3(0, 0.18, 0)).reparent(kn, false)
	# Moedas.
	var coin := CylinderMesh.new()
	coin.top_radius = 0.02
	coin.bottom_radius = 0.02
	coin.height = 0.004
	var gold := _mat(Color(0.85, 0.66, 0.25), 0.35, 0.85)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		_mesh(coin, gold, Vector3(0.62 + rng.randf_range(-0.09, 0.09), 0.002 + i * 0.0006, 0.46 + rng.randf_range(-0.06, 0.06)), Vector3(rng.randf_range(-6, 6), rng.randf() * 90.0, rng.randf_range(-6, 6)))


## Velas num pires: cera com escorridos, chama que tremula (quad emissivo) e uma luz quente.
func _candles(at: Vector3, heights: Array, shadows: bool) -> void:
	var dish := CylinderMesh.new()
	dish.top_radius = 0.09
	dish.bottom_radius = 0.07
	dish.height = 0.012
	_mesh(dish, _mat(Color(0.32, 0.22, 0.12), 0.45, 0.6), at + Vector3(0, 0.006, 0))
	var wax := _mat(Color(0.92, 0.86, 0.72), 0.6)
	if wax is StandardMaterial3D:
		(wax as StandardMaterial3D).subsurf_scatter_enabled = false
	var offs := [Vector3(0, 0, 0), Vector3(0.05, 0, 0.035), Vector3(-0.045, 0, 0.04)]
	var top_y := 0.0
	for i in heights.size():
		var h: float = heights[i]
		var cm := CylinderMesh.new()
		cm.top_radius = 0.018
		cm.bottom_radius = 0.02
		cm.height = h
		var p: Vector3 = at + offs[i] + Vector3(0, 0.012 + h * 0.5, 0)
		_mesh(cm, wax, p)
		var fq := QuadMesh.new()
		fq.size = Vector2(0.026, 0.05)
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		fm.billboard_keep_scale = true
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.albedo_texture = _flame_tex()
		fm.albedo_color = Color(2.4, 1.6, 0.9)
		var fl := _mesh(fq, fm, p + Vector3(0, h * 0.5 + 0.03, 0))
		fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flames.append([null, fl, 0.0, randf() * 10.0])
		top_y = maxf(top_y, p.y + h * 0.5)
	var l := OmniLight3D.new()
	l.light_color = FLAME_COL
	l.light_energy = 2.4 if shadows else 1.4
	l.omni_range = 2.6
	l.omni_attenuation = 1.3
	l.shadow_enabled = shadows
	l.light_volumetric_fog_energy = 0.0
	l.position = at + Vector3(0, top_y + 0.06, 0)
	add_child(l)
	flames.append([l, null, l.light_energy, randf() * 10.0])


static var _ftex: Texture2D


static func _flame_tex() -> Texture2D:
	if _ftex == null:
		var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 32:
				var u := (x - 15.5) / 15.5
				var v := y / 63.0
				var wdt := sin(v * PI) * (0.55 + 0.45 * v) * (1.0 - v * 0.15)
				var d := absf(u) / maxf(wdt, 0.01)
				var a := clampf(1.0 - d, 0.0, 1.0) * smoothstep(0.0, 0.18, v) * smoothstep(1.0, 0.82, v)
				var core := clampf(1.0 - d * 1.8, 0.0, 1.0) * smoothstep(0.35, 0.9, v)
				img.set_pixel(x, y, Color(1.0, 0.55 + core * 0.45, 0.2 + core * 0.7, a))
		_ftex = ImageTexture.create_from_image(img)
	return _ftex


## Cartas soltas na mesa (renderizadas uma vez num SubViewport com a carta da interface).
func _cards() -> void:
	if data == null:
		return
	var spots := [["skeleton_archers", Vector2(-1.0, 0.36), -24.0], ["web", Vector2(1.16, 0.52), 18.0], ["rat_horde", Vector2(0.02, 0.46), -8.0], ["gargoyle_tower", Vector2(-0.52, -0.7), 12.0]]
	for s in spots:
		var d: CardDef = data.card(s[0])
		if d == null:
			continue
		var vp := _viewport(Vector2i(336, 480))
		var c := UiKit.card(d, d.cost, [], "", 320.0, 1)
		c.position = Vector2(8, 8)
		vp.get_child(0).add_child(c)
		_quad(vp, Vector3(s[1].x, 0.004, s[1].y), s[2], Vector2(0.14, 0.2))


func _viewport(sz: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = sz
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.gui_disable_input = true
	add_child(vp)
	var root := Control.new()
	root.size = Vector2(sz)
	if menu:
		root.theme = menu.theme
	vp.add_child(root)
	_freeze.call_deferred(vp)
	return vp


## Depois de alguns quadros a textura não muda mais: para de redesenhar.
func _freeze(vp: SubViewport) -> void:
	for i in 4:
		await get_tree().process_frame
	if is_instance_valid(vp):
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _quad(vp: SubViewport, pos: Vector3, rot_deg: float, sz: Vector2) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = sz
	var m := StandardMaterial3D.new()
	m.albedo_texture = vp.get_texture()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	m.roughness = 0.95
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var mi := _mesh(q, m, pos, Vector3(-90, rot_deg, 0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Papel de uma tela do menu: folha com o título a pincel, um desenho e linhas de rascunho.
func _paper(id: String, at: Vector2, rot_deg: float, sz: Vector2) -> void:
	var px := Vector2i(int(sz.x * 1500.0), int(sz.y * 1500.0))
	var vp := _viewport(px)
	var root: Control = vp.get_child(0)
	var sheet := PanelContainer.new()
	UiDiario.dress(sheet, "lined" if id == "collection" else "paper", 28.0, {"grime": 0.55, "seed": UiDiario.seed_of(id), "shadow": 0.0, "rough": 3.0})
	sheet.position = Vector2(10, 10)
	sheet.size = Vector2(px) - Vector2(20, 20)
	root.add_child(sheet)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	sheet.add_child(v)
	var title := Label.new()
	title.text = {"title": "LAST BOSS", "decks": "UI_NEW_RUN", "collection": "UI_COLLECTION", "compendium": "UI_COMPENDIUM",
		"settings": "UI_SETTINGS", "continue": "UI_CONTINUE"}[id]
	title.add_theme_font_override("font", UiDiario.font("marker"))
	title.add_theme_font_size_override("font_size", 64 if id != "continue" else 44)
	title.add_theme_color_override("font_color", UiDiario.BLOOD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(title)
	var art := TextureRect.new()
	art.texture = UiDiario.card_tex({"title": "lord_skull", "decks": "villain_plague" if ResourceLoader.exists("res://assets/cards/villain_plague.png") else "pact_horde", "collection": "skeleton_archers", "compendium": "ghost",
		"settings": "scrap_golem", "continue": "dark_pact"}[id])
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(art)
	for i in 3 if id != "continue" else 1:
		var ln := ColorRect.new()
		ln.color = Color(0.12, 0.1, 0.08, 0.55)
		ln.custom_minimum_size = Vector2(px.x * (0.7 - i * 0.15), 4)
		v.add_child(ln)
	var pivot := Node3D.new()
	pivot.position = Vector3(at.x, 0.003 + papers.size() * 0.0015, at.y)
	pivot.rotation_degrees = Vector3(0, rot_deg, 0)
	add_child(pivot)
	var q := _quad(vp, Vector3.ZERO, 0.0, sz)
	q.reparent(pivot, false)
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(sz.x, 0.01, sz.y)
	cs.shape = bs
	area.add_child(cs)
	pivot.add_child(area)
	area.input_event.connect(func(_c, e, _p, _n, _i):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and current != id and not UiSkins.mapa():
			paper_clicked.emit(id))
	area.mouse_entered.connect(func(): hover = id)
	area.mouse_exited.connect(func(): if hover == id: hover = "")
	papers[id] = {"pivot": pivot, "rest": pivot.position}


## Cartaz de procura-se preso pela faca.
func _wanted() -> void:
	var vp := _viewport(Vector2i(420, 560))
	var root: Control = vp.get_child(0)
	var sheet := PanelContainer.new()
	UiDiario.dress(sheet, "paper", 24.0, {"grime": 0.8, "seed": 0.71, "shadow": 0.0, "rough": 3.0})
	sheet.position = Vector2(8, 8)
	sheet.size = Vector2(404, 544)
	root.add_child(sheet)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	sheet.add_child(v)
	var h := Label.new()
	h.text = "UI_WANTED"
	h.add_theme_font_override("font", UiDiario.font("fell"))
	h.add_theme_font_size_override("font_size", 58)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var art := TextureRect.new()
	art.texture = UiDiario.card_tex("hero_wanted")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(0, 300)
	v.add_child(art)
	var r := Label.new()
	r.text = "UI_WANTED_REWARD"
	r.add_theme_font_override("font", UiDiario.font("hand"))
	r.add_theme_font_size_override("font_size", 38)
	r.add_theme_color_override("font_color", UiDiario.BLOOD)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	_quad(vp, Vector3(0.44, 0.006, -0.66), 6.0, Vector2(0.24, 0.32))


## A tela aberta sai da mesa (o MainMenu desenha a versão 2D por cima).
func set_current(id: String) -> void:
	current = id
	for k in papers:
		# Pele "Mapa aberto": o mapa aberto (MapMenu) toma o lugar dos papéis do menu; eles ficam só como ponto de
		# partida das telas (screen_point), sem aparecer nem pegar o clique.
		papers[k]["pivot"].visible = k != id and not UiSkins.mapa()


func set_continue(on: bool) -> void:
	if papers.has("continue"):
		papers["continue"]["pivot"].visible = on and current != "continue" and not UiSkins.mapa()


## Ponto da tela onde está o papel `id` (de onde a tela 2D sai e para onde volta).
func screen_point(id: String) -> Vector2:
	if not papers.has(id) or cam == null:
		return get_viewport().get_visible_rect().size * Vector2(0.5, 0.8)
	return cam.unproject_position(papers[id]["pivot"].global_position)


func _process(delta: float) -> void:
	t += delta
	if cam:
		var vs := get_viewport().get_visible_rect().size
		var m: Vector2 = get_viewport().get_mouse_position() / Vector2(maxf(vs.x, 1.0), maxf(vs.y, 1.0)) - Vector2(0.5, 0.5)
		par = par.lerp(m, clampf(delta * 2.5, 0.0, 1.0))
		cam.global_position = ORIGIN + CAM_POS + Vector3(par.x * 0.06, -par.y * 0.03, 0)
		cam.look_at(ORIGIN + CAM_LOOK + Vector3(par.x * 0.02, 0, 0), Vector3.UP)
	for f in flames:
		var n := sin(t * 7.3 + f[3]) * 0.5 + sin(t * 13.1 + f[3] * 2.0) * 0.3 + sin(t * 2.1 + f[3]) * 0.2
		if f[0] != null:
			(f[0] as OmniLight3D).light_energy = f[2] * (1.0 + n * 0.12)
		if f[1] != null:
			(f[1] as Node3D).scale = Vector3(1.0 + n * 0.08, 1.0 - n * 0.1, 1.0)
	for k in papers:
		var pv: Node3D = papers[k]["pivot"]
		var target: Vector3 = papers[k]["rest"] + Vector3(0, 0.02 if hover == k else 0.0, 0)
		pv.position = pv.position.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
