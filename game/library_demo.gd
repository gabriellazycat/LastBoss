class_name LibraryDemo
extends Control
## Cena autônoma da Biblioteca (frente F, 21/11/2026): MetaSave temporário (user://library_demo.save), Almas e cartas
## liberadas de teste. Não toca no save do jogador.
## Captura em segundo plano (1920x1080):
##   "$G" --position -6000,0 --path . res://game/library_demo.tscn -- --shot=<arquivo.png> [--view=album|common|locked|zoom|zoomvi]
## Sem --shot abre a tela para olhar e mexer.

const SAVE := "user://library_demo.save"

var data: GameData
var meta: MetaSave
var screen: CollectionScreen
var shot := ""
var view := "album"


## Objeto com buy_card_level / set_deck / deck_ok. A frente D põe esses nomes no MetaSave; enquanto não existem,
## este shim os provê (só aqui; collection.gd chama os nomes finais).
class Shim extends RefCounted:
	var m: MetaSave

	func _init(meta_: MetaSave) -> void:
		m = meta_

	func buy_card_level(id: String) -> bool:
		var lv := int(m.card_levels.get(id, 1))
		if lv >= 6 or not m.is_unlocked(id):
			return false
		var cost := MetaApply.card_upgrade_cost(m.data, id, lv + 1)
		if cost <= 0 or m.almas < cost:
			return false
		m.almas -= cost
		m.card_levels[id] = lv + 1
		return true

	func deck_ok(vid: String, ids: Array) -> bool:
		if ids.size() != 19:
			return false
		var cnt := {}
		for id in ids:
			var c := m.data.card(str(id))
			if c == null or not m.data.in_pool(c, vid) or not m.is_unlocked(str(id)):
				return false
			cnt[id] = int(cnt.get(id, 0)) + 1
			if int(cnt[id]) > 3:
				return false
		return true

	func set_deck(vid: String, ids: Array) -> bool:
		if not deck_ok(vid, ids):
			return false
		m.decks[vid] = ids.duplicate()
		return true


## O próprio MetaSave se já tem os três métodos (frente D); senão o shim.
static func make_api(meta_: MetaSave) -> Object:
	if meta_.has_method("buy_card_level") and meta_.has_method("set_deck") and meta_.has_method("deck_ok"):
		return meta_
	return Shim.new(meta_)


## Estado de teste: Almas, vilões liberados, metade das cartas liberadas, níveis variados e progresso nas bloqueadas.
static func seed_meta(d: GameData, path: String) -> MetaSave:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var m := MetaSave.load_or_new(d, path)
	m.unlock_villain("dragon")
	m.add_almas(1800)
	var k := 0
	for c in d.pool:
		k += 1
		if not m.unlocked.has(c.id) and c.owner != "lich" and (k % 3 != 0 or not d.unlock_challenges.has(c.id)):
			m.unlocked.append(c.id)
		if m.unlocked.has(c.id):
			m.card_levels[c.id] = 1 + (k * 5) % 6 if k % 4 != 0 else 1
	k = 0
	for c in d.pool:
		if not m.unlocked.has(c.id) and d.unlock_challenges.has(c.id):
			k += 1
			m.progress[c.id] = {"v": float(k % 7 + 2), "g": 15.0}
	return m


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
		elif a.begins_with("--view="):
			view = a.trim_prefix("--view=")
	Settings.load_all()
	Settings.v["fullscreen"] = false
	Settings.apply(get_tree())
	if shot != "" and DisplayServer.get_name() != "headless":
		var w := get_window()
		w.set_flag(Window.FLAG_NO_FOCUS, true)
		w.mode = Window.MODE_WINDOWED
		w.size = Vector2i(1920, 1080)
		w.position = Vector2i(-6000, 0)
	UiSkins.apply()
	if not get_tree().node_added.is_connected(UiDiario.on_node_added):
		get_tree().node_added.connect(UiDiario.on_node_added)
	theme = UiKit.make_theme()
	data = GameData.load_dir()
	meta = seed_meta(data, SAVE)
	var bg := ColorRect.new()
	bg.color = Color("2a1a10")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	screen = CollectionScreen.new()
	screen.setup(data, meta)
	screen.api = make_api(meta)
	screen.closed.connect(func(): get_tree().quit())
	add_child(screen)
	var vs := get_viewport_rect().size
	var fit := minf(vs.x / CollectionScreen.BOARD.x, vs.y / CollectionScreen.BOARD.y)
	screen.scale = Vector2.ONE * fit
	screen.position = (vs - CollectionScreen.BOARD * fit) * 0.5
	screen.open()
	if shot != "":
		_capture.call_deferred()


func _capture_card(owner_: String, need_n3: bool) -> String:
	for c in data.pool:
		if c.owner == owner_ and meta.is_unlocked(c.id) and c.lvl.size() >= 2 and (not need_n3 or not c.n3.is_empty()):
			return c.id
	return ""


func _capture() -> void:
	match view:
		"common":
			screen.set_tab("common")
		"locked":
			screen.set_tab("dragon")
			screen.set_cost_filter(-1)
		"zoom":
			var id := _capture_card("plague", true)
			meta.card_levels[id] = 3
			screen.set_tab("plague")
			screen._open_zoom(id)
		"zoomvi":
			var id := _capture_card("plague", true)
			meta.card_levels[id] = 6
			screen.set_tab("plague")
			screen._open_zoom(id)
		"zoom5":
			var id := _capture_card("plague", true)
			meta.card_levels[id] = 5
			screen.set_tab("plague")
			screen._open_zoom(id)
		"filter":
			screen.set_tab("plague")
			screen.set_cost_filter(2)
	for _i in 8:
		await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(shot).get_base_dir())
	img.save_png(shot)
	print("captura: ", shot, " ", img.get_size())
	get_tree().quit()
