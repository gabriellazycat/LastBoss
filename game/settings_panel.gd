class_name SettingsPanel
extends PanelContainer
## Tela de configurações (menu principal e pausa). Cada mudança é aplicada e salva na hora.

signal closed
signal changed(key: String)

const TABS := ["audio", "video", "game", "controls", "looks"]
const CONTROLS := ["card", "place", "sacrifice", "cursor", "map", "altar", "zoom", "pause", "speed"]
const COL_W := {"CTL_": 230.0, "CTLK_": 320.0, "CTLP_": 160.0}

var tab := "audio"
var tab_row: HBoxContainer
var body: VBoxContainer
var back_btn: Button


func _ready() -> void:
	UiKit.panel_style(self, UiKit.BG, UiKit.GOLD.darkened(0.35), 22)
	custom_minimum_size = Vector2(760, 0 if UiSkins.covil() else 620)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var head := UiKit.title(38)
	head.text = "UI_SETTINGS"
	v.add_child(head)
	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	v.add_child(tab_row)
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", UiKit.box(UiKit.GOLD.darkened(0.5), UiKit.GOLD.darkened(0.5), 0, 0, 0))
	sep.custom_minimum_size = Vector2(0, 2)
	v.add_child(sep)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(716, 380 if UiSkins.covil() else 440)
	v.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	v.add_child(foot)
	back_btn = _btn("UI_BACK", func(): closed.emit())
	back_btn.custom_minimum_size = Vector2(200, 48)
	foot.add_child(back_btn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)
	foot.add_child(_btn("UI_DEFAULTS", func():
		Settings.v = Settings.defaults()
		_commit("all")))
	_rebuild()


func open() -> void:
	visible = true
	_rebuild()
	(tab_row.get_child(TABS.find(tab)) as Button).grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and visible:
		_rebuild.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


func _btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.pressed.connect(cb)
	return b


func _commit(key: String) -> void:
	Settings.save()
	Settings.apply(get_tree())
	changed.emit(key)
	if key in ["all", "language"]:
		_rebuild.call_deferred()


func _rebuild() -> void:
	var had_focus := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	UiKit.clear(tab_row)
	for id in TABS:
		var b := _btn("UI_TAB_" + id, func():
			tab = id
			_rebuild())
		b.toggle_mode = true
		b.button_pressed = id == tab
		b.custom_minimum_size = Vector2(132, 44)
		tab_row.add_child(b)
	UiKit.clear(body)
	match tab:
		"audio":
			_slider("master", 0.0, 1.0, true)
			_slider("music", 0.0, 1.0, true)
			_slider("sfx", 0.0, 1.0, true)
		"video":
			_toggle("fullscreen")
			_toggle("vsync")
			_choice("quality", ["UI_Q_0", "UI_Q_1", "UI_Q_2"], [0, 1, 2])
			var caps: Array = []
			for f in Settings.FPS_CAPS:
				caps.append(tr("UI_FPS_NOLIMIT") if f == 0 else str(f))
			_choice("max_fps", caps, Settings.FPS_CAPS)
			_slider("ui_scale", 0.8, 1.15, true, 0.05)
		"game":
			_choice("language", ["Português", "English"], ["pt", "en"])
			_slider("shake", 0.0, 1.0, true)
			_toggle("flash")
			_toggle("damage_numbers")
			_toggle("hints")
			_toggle("show_help")
			_toggle("show_fps")
			_slider("pad_speed", 0.5, 2.0, true, 0.1)
			var r := _row("SET_reset_hints")
			r.add_child(_btn("UI_RESET_HINTS", func():
				DirAccess.remove_absolute(ProjectSettings.globalize_path("user://hints.cfg"))
				changed.emit("hints_reset")))
		"controls":
			var head := HBoxContainer.new()
			for k in ["UI_CTL_ACTION", "UI_CTL_KB", "UI_CTL_PAD"]:
				var l := UiKit.label(15, UiKit.GOLD)
				l.text = k
				l.custom_minimum_size = Vector2(COL_W[["CTL_", "CTLK_", "CTLP_"][head.get_child_count()]], 0)
				head.add_child(l)
			body.add_child(head)
			# Colunas de largura fixa: rótulos que quebram linha dentro de HBox fazem o painel crescer sem parar.
			for id in CONTROLS:
				var row := HBoxContainer.new()
				for k in ["CTL_", "CTLK_", "CTLP_"]:
					var l := UiKit.label(15, UiKit.TEXT if k == "CTL_" else UiKit.MUTED)
					l.text = k + id
					l.custom_minimum_size = Vector2(COL_W[k], 0)
					l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
					l.clip_text = true
					row.add_child(l)
				body.add_child(row)
		"looks":
			# Variações de arte em avaliação (docs/VARIACOES.md). Trocar recarrega a cena (main._on_settings).
			var note := UiKit.label(15, UiKit.MUTED, 3)
			note.text = "UI_LOOKS_NOTE"
			note.autowrap_mode = TextServer.AUTOWRAP_WORD
			note.custom_minimum_size = Vector2(700, 0)
			body.add_child(note)
			var opts := [0, 1, 2, 3, 4]
			_choice("look_hud", _look_names(UiSkins.NAMES), [0, 1, 2, 3, 4, 5])
			_choice("look_ground", _look_names(GroundLooks.NAMES), opts)
			_choice("look_hero", _look_names(Looks.NAMES), opts)
			_choice("look_enemies", _look_names(Looks.NAMES), opts)
	if UiSkins.covil():
		_fit_scroll.call_deferred()
	# Volta ao tamanho mínimo: um contêiner não encolhe sozinho depois de uma aba mais larga.
	set_deferred("size", Vector2.ZERO)
	if had_focus and not had_focus.is_inside_tree():
		(tab_row.get_child(TABS.find(tab)) as Button).grab_focus.call_deferred()


## A área rolável fica do tamanho do conteúdo da aba, até 380 px (Áudio tem 3 linhas; Controles, 10).
func _fit_scroll() -> void:
	var scroll := body.get_parent() as ScrollContainer
	scroll.custom_minimum_size.y = clampf(body.get_combined_minimum_size().y + 6.0, 120.0, 380.0)
	size = Vector2.ZERO


func _look_names(names: Array) -> Array:
	var out: Array = []
	for i in names.size():
		out.append("%d · %s" % [i, names[i]] if i > 0 else names[i])
	return out


func _row(key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := UiKit.label(18)
	l.text = key
	l.custom_minimum_size = Vector2(300, 0)
	row.add_child(l)
	body.add_child(row)
	return row


func _slider(key: String, lo: float, hi: float, pct: bool, step := 0.05) -> void:
	var row := _row("SET_" + key)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = Settings.v[key]
	s.custom_minimum_size = Vector2(300, 28)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var val := UiKit.label(17, UiKit.GOLD)
	val.custom_minimum_size = Vector2(64, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var show := func(x: float): val.text = ("%d%%" % roundi(x * 100.0)) if pct else str(x)
	show.call(s.value)
	s.value_changed.connect(func(x: float):
		show.call(x)
		Settings.v[key] = x)
	# Escala da interface só aplica ao soltar (senão o slider foge do mouse).
	s.drag_ended.connect(func(_c: bool): _commit(key))
	s.value_changed.connect(func(_x: float):
		if key != "ui_scale" or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_commit(key))
	row.add_child(s)
	row.add_child(val)


func _toggle(key: String) -> void:
	var row := _row("SET_" + key)
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = Settings.v[key]
	b.text = "UI_ON" if Settings.v[key] else "UI_OFF"
	b.custom_minimum_size = Vector2(160, 40)
	b.toggled.connect(func(on: bool):
		Settings.v[key] = on
		b.text = "UI_ON" if on else "UI_OFF"
		_commit(key))
	row.add_child(b)


func _choice(key: String, labels: Array, values: Array) -> void:
	var row := _row("SET_" + key)
	var o := OptionButton.new()
	o.custom_minimum_size = Vector2(220, 40)
	for i in labels.size():
		o.add_item(labels[i], i)
	o.selected = maxi(values.find(Settings.v[key]), 0)
	o.item_selected.connect(func(i: int):
		Settings.v[key] = values[i]
		_commit(key))
	row.add_child(o)
