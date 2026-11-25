class_name MainMenu
extends Control
## Menu principal e telas ao redor (plano de metaprogressão, 21/11/2026, frente G).
## Fluxo: Menu → Covil (roda, CovilScreen) ⇄ Biblioteca (CollectionScreen) → Escolher vilão → Run → Fim da run → Covil.
## Telas ("screen"): title, covil, collection (Biblioteca), decks (Escolher vilão), compendium, settings.
## Saíram: a campanha de 7 fases e o mapa dela, a Horda sem fim e a antiga Coleção.

signal deck_chosen(id: String)
signal tutorial_chosen
signal continue_run
signal settings_changed(key: String)

const VERSION := "v0.1 · MVP"

const VILLAIN_ART_FALLBACK := {"plague": "pact_horde", "dragon": "pact_treasure", "lich": "dark_pact"}

var data: GameData
var meta: MetaSave
var screen := "title"
var shade: TextureRect
var veil: ColorRect
var title_box: VBoxContainer
var main_buttons: VBoxContainer
var continue_btn: Button
var covil_btn: Button
var deck_screen: Control
var preview_head: Label
var preview_row: Container
var pending_villain := ""
var covil: CovilScreen
var collection: CollectionScreen
var compendium: CompendiumScreen
var settings: SettingsPanel
var footer: Label
var fade := 0.0
var lib_return := "title"      # para onde a Biblioteca volta (title, covil ou decks)
var decks_back := "covil"      # para onde "Voltar" da escolha do vilão leva
var focus_pref := ""           # vilão em foco ao reabrir a escolha (voltando da Biblioteca)

var desk: DeskScene
var title_root: Control
var prev_screen := ""
var prev_fade := 1.0


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Sombra à esquerda para o texto ler bem sobre a cena.
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.01, 0.04, 0.88))
	g.set_color(1, Color(0.02, 0.01, 0.04, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(1, 0)
	shade = TextureRect.new()
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	veil = ColorRect.new()
	veil.color = Color(0.02, 0.012, 0.03, 0.62)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.visible = false
	add_child(veil)
	shade.visible = false
	_build_title()
	_build_villains_parch()
	covil = CovilScreen.new()
	covil.setup(data, meta)
	covil.visible = false
	covil.open_library.connect(func():
		lib_return = "covil"
		show_screen("collection"))
	covil.start_run.connect(func():
		decks_back = "covil"
		show_screen("decks"))
	covil.back.connect(func(): show_screen("title"))
	add_child(covil)
	collection = CollectionScreen.new()
	collection.setup(data, meta)
	collection.visible = false
	collection.closed.connect(func(): show_screen(lib_return))
	add_child(collection)
	compendium = CompendiumScreen.new()
	compendium.setup(data, meta)
	compendium.visible = false
	compendium.closed.connect(func(): show_screen("title"))
	add_child(compendium)
	settings = SettingsPanel.new()
	settings.visible = false
	settings.closed.connect(func(): show_screen("title"))
	settings.changed.connect(func(k): settings_changed.emit(k))
	add_child(settings)
	footer = UiKit.label(14, UiKit.MUTED, 3)
	add_child(footer)
	show_screen("title")


## Total de parties da run (a fila da fase 1 em data/campaign.json).
func party_total() -> int:
	return maxi(1, data.phase(1).get("parties", []).size())


## Parte do menu: "Recorde: party N de 15 · X Almas" (o recorde geral, o melhor entre os vilões).
func status_text(almas := -1) -> String:
	var a := meta.almas if almas < 0 else almas
	if meta.best_party > 0:
		return tr("UI_MENU_STATUS").format({"b": meta.best_party, "m": party_total(), "a": a})
	return tr("UI_MENU_STATUS_NONE").format({"a": a})


# ---------------------------------------------------------------- selos e balões do mapa

var _count_tw: Tween
var _count_auto := false


## Balão do Covil: "X Almas — dá para comprar N melhorias" (só com novidade na árvore e algo comprável).
func covil_balloon(almas: int) -> String:
	var n := meta.buyable_count()
	if not meta.covil_new or n <= 0:
		return ""
	return tr("UI_MAP_LAIR_BUY_ONE" if n == 1 else "UI_MAP_LAIR_BUY").format({"a": almas, "n": n})


## Selos e balões do título. Ao voltar de uma run (saldo diferente do que o menu já mostrou) as Almas contam
## animadas até o saldo; ao fim, se dá para comprar algo, abre a árvore do Covil.
func refresh_marks() -> void:
	var mm := title_root as MapMenu
	if mm == null:
		return
	_stop_count()
	var n_new := meta.new_cards_count()
	mm.set_badge("collection", n_new)
	mm.set_balloon("collection", tr("UI_MAP_LIB_NEW_ONE" if n_new == 1 else "UI_MAP_LIB_NEW").format({"n": n_new}) if n_new > 0 else "")
	mm.set_badge("covil", meta.buyable_count() if meta.covil_new else 0)
	var from := meta.almas_shown if meta.almas_shown >= 0 else meta.almas
	if from == meta.almas:
		mm.set_balloon("covil", covil_balloon(meta.almas))
		return
	_count_auto = true
	mm.set_status(status_text(from))
	mm.set_balloon("covil", covil_balloon(from))
	_count_tw = create_tween()
	_count_tw.tween_interval(0.5)
	_count_tw.tween_method(_count_step, float(from), float(meta.almas), clampf(absf(meta.almas - from) * 0.02, 0.6, 2.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_count_tw.tween_callback(_count_done)


func _count_step(v: float) -> void:
	var mm := title_root as MapMenu
	if mm == null or screen != "title":
		return
	var a := int(round(v))
	mm.set_status(status_text(a))
	mm.set_balloon("covil", covil_balloon(a))


func _count_done() -> void:
	_finish_count()
	if screen == "title" and meta.covil_new and meta.buyable_count() > 0:
		get_tree().create_timer(0.6).timeout.connect(func():
			if screen == "title" and meta.covil_new:
				show_screen("covil"))


## Fecha a contagem (também ao sair do título no meio dela): o saldo mostrado passa a ser o atual.
func _finish_count() -> void:
	if _count_tw != null:
		_count_tw.kill()
		_count_tw = null
	if not _count_auto:
		return
	_count_auto = false
	meta.almas_shown = meta.almas
	meta.save()
	var mm := title_root as MapMenu
	if mm != null:
		mm.set_status(status_text())
		mm.set_balloon("covil", covil_balloon(meta.almas))


func _stop_count() -> void:
	_finish_count()


# ---------------------------------------------------------------- título

func _build_title() -> void:
	_build_title_map()
	return


func _on_map_choice(id: String) -> void:
	match id:
		"continue":
			continue_run.emit()
		"covil":
			# A árvore de melhorias: "Começar run" leva à escolha do vilão, que volta para cá.
			show_screen("covil")
		"collection":
			lib_return = "title"
			show_screen("collection")
		"tutorial":
			tutorial_chosen.emit()
		"quit":
			get_tree().quit()
		_:
			show_screen(id)


## Pele "Mapa aberto": o título é um mapa aberto sobre a mesa (MapMenu, maquete "Menu A").
func _build_title_map() -> void:
	var mm := MapMenu.new()
	var pt := UiParch.portrait("villain_" + meta.villain) if meta else null
	if pt == null and ResourceLoader.exists("res://assets/cards/rat_king.png"):
		pt = load("res://assets/cards/rat_king.png")
	mm.build(pt)
	add_child(mm)
	title_root = mm
	title_box = VBoxContainer.new()   # o resto do menu ainda pergunta pelo title_box; no mapa ele fica vazio
	main_buttons = VBoxContainer.new()
	main_buttons.visible = false
	mm.add_child(main_buttons)
	continue_btn = mm.continue_btn
	covil_btn = mm.buttons["covil"]
	mm.chosen.connect(_on_map_choice)
	if OS.get_name() == "Web":
		mm.buttons["quit"].visible = false


# ---------------------------------------------------------------- vilões

## Vilão que já vem em foco: o que voltou da Biblioteca ou o último escolhido, se estiver liberado.
func _default_villain() -> String:
	if focus_pref != "" and meta.villains.has(focus_pref):
		return focus_pref
	return meta.villain if meta.villains.has(meta.villain) else data.villain_ids[0]


## Retrato do vilão (assets/cards/<portrait>.png); sem ele, a arte antiga mais próxima.
static func villain_tex(d: GameData, id: String) -> Texture2D:
	var t := UiDiario.card_tex(str(d.villain(id).get("portrait", "villain_" + id)))
	if t == null:
		t = UiDiario.card_tex(VILLAIN_ART_FALLBACK.get(d.villain_id(id), "lord_skull"))
	return t


## Vilão escolhido: a run começa com o deck montado dele (main.gd monta o Sim com os mods da meta).
func _start_villain() -> void:
	if pending_villain == "" or not meta.villains.has(pending_villain):
		return
	meta.villain = pending_villain
	meta.save()
	deck_chosen.emit(pending_villain)


## Party que, ao ser derrotada, libera o vilão (0 = já liberado desde o começo).
func unlock_party(vid: String) -> int:
	return int(meta.villain_unlock_at().get(data.villain_id(vid), 0))


func record_text(vid: String) -> String:
	var best := int(meta.best_by_villain.get(data.villain_id(vid), 0))
	if best <= 0:
		return tr("UI_MENU_NO_RECORD")
	return tr("UI_MENU_RECORD").format({"n": best, "m": party_total()})


func locked_text(vid: String) -> String:
	return tr("UI_MENU_LOCKED").format({"n": unlock_party(vid)})


func show_screen(s: String) -> void:
	if s != screen and is_node_ready():
		prev_screen = screen
		prev_fade = 0.0
	screen = s
	fade = 0.0
	if is_instance_valid(desk):
		desk.set_current(_desk_id(s))
		desk.set_continue(SaveGame.exists())
	if s != "title":
		_stop_count()
	title_root.visible = s == "title" or (prev_screen == "title" and prev_fade < 1.0)
	deck_screen.visible = s == "decks"
	covil.visible = s == "covil"
	collection.visible = s == "collection"
	compendium.visible = s == "compendium"
	settings.visible = false
	if s == "title":
		continue_btn.visible = SaveGame.exists()
		if title_root is MapMenu:
			(title_root as MapMenu).set_status(status_text())
			refresh_marks()
		(continue_btn if continue_btn.visible else covil_btn).grab_focus.call_deferred()
	elif s == "covil":
		meta.mark_covil_seen()
		covil.refresh()
	elif s == "decks":
		_fill_villains_parch()
		_focus_first_deck.call_deferred()
	elif s == "collection":
		meta.mark_library_seen()
		collection.open()
	elif s == "compendium":
		compendium.open()
	elif s == "settings":
		settings.open()


func _focus_first_deck() -> void:
	if is_instance_valid(v_pick) and not v_pick.disabled:
		v_pick.grab_focus()
		return
	for b in deck_screen.find_children("*", "Button", true, false):
		if not b.disabled:
			b.grab_focus()
			return


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		if screen == "decks":
			_fill_villains_parch.call_deferred()
		elif screen == "collection":
			collection.refresh.call_deferred()
		elif screen == "covil":
			covil.refresh.call_deferred()
		elif screen == "compendium":
			compendium.show_tab.call_deferred(compendium.tab)


func _unhandled_input(e: InputEvent) -> void:
	if not visible or not e.is_action_pressed("ui_cancel"):
		return
	if screen == "compendium" or screen == "covil":
		get_viewport().set_input_as_handled()
		show_screen("title")
	elif screen == "decks":
		get_viewport().set_input_as_handled()
		show_screen(decks_back)


func _process(delta: float) -> void:
	if not visible:
		return
	_process_desk(delta)
	return


# ---------------------------------------------------------------- pele Diário

## Papel da mesa que cada tela usa (o Covil e a Biblioteca saem do mesmo maço).
func _desk_id(s: String) -> String:
	return {"covil": "collection"}.get(s, s)


func _screen_node(s: String) -> Control:
	match s:
		"title":
			return title_root
		"decks":
			return deck_screen
		"covil":
			return covil
		"collection":
			return collection
		"compendium":
			return compendium
		"settings":
			return settings
	return null


func _final_pos(s: String, c: Control, vs: Vector2) -> Vector2:
	if s == "title":
		return (vs - c.size) * 0.5
	if s == "title":
		var m := clampf(vs.x * 0.06, 28.0, 120.0)
		return Vector2(m, (vs.y - c.size.y) * 0.5)
	return (vs - c.size) * 0.5


## A tela aberta sobe do papel dela na mesa (escala, giro e posição); a anterior desce de volta.
func _process_desk(delta: float) -> void:
	fade = minf(fade + delta * 2.6, 1.0)
	prev_fade = minf(prev_fade + delta * 3.2, 1.0)
	var vs := get_viewport_rect().size
	for s in ["title", "decks", "covil", "collection", "compendium"]:
		var c := _screen_node(s)
		if c == null:
			continue
		var cur: bool = s == screen
		var leaving: bool = s == prev_screen and prev_fade < 1.0
		c.visible = cur or leaving
		# A tela que está saindo (descendo de volta para a mesa) não pega o mouse: ela cobria os papéis e um
		# clique logo depois do Esc caía nela (achado do --menutest, 10/11/2026).
		c.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED if cur else Control.MOUSE_BEHAVIOR_DISABLED
		if not c.visible:
			continue
		if s == "covil":
			# O Covil ocupa a tela inteira (âncoras): só aparece e some, sem subir da mesa.
			c.modulate.a = fade if cur else 1.0 - prev_fade
			continue
		var e := ease(fade, -2.2) if cur else 1.0 - ease(prev_fade, 2.0)
		var from := desk.screen_point(_desk_id(s)) if is_instance_valid(desk) else Vector2(vs.x * 0.5, vs.y * 0.85)
		var fin := _final_pos(s, c, vs)
		c.pivot_offset = c.size * 0.5
		var fit := minf(1.0, minf(vs.y * 0.94 / maxf(c.size.y, 1.0), vs.x * 0.96 / maxf(c.size.x, 1.0)))
		c.scale = Vector2.ONE * lerpf(0.16, fit, e)
		c.position = (from - c.size * 0.5).lerp(fin, e)
		c.rotation = lerpf(deg_to_rad(9.0 if s.length() % 2 == 0 else -9.0), deg_to_rad(-0.35 if s == "title" else 0.0), e)
		c.modulate.a = clampf(e * 3.0, 0.0, 1.0)
	settings.position = (vs - settings.size) * 0.5
	footer.text = VERSION + "   ·   " + tr("UI_MENU_KEYS")
	footer.position = Vector2(clampf(vs.x * 0.06, 28.0, 120.0), vs.y - 34)
	footer.add_theme_color_override("font_color", Color(0.85, 0.78, 0.66))
	# As folhas grandes (vilão, biblioteca) cobrem o rodapé em 1280x720: ele só aparece no título.
	footer.visible = screen == "title"


# ---------------------------------------------------------------- escolher vilão (kit das cartas, UiParch)
# Uma folha com moldura dourada: lista dos vilões à esquerda (retrato, nome, recorde ou "trancado: derrote a party N") e,
# à direita, o vilão em foco com o deck montado de 19 cartas. Botões: Voltar · Editar deck (abre a Biblioteca naquele
# vilão) · Começar.

var v_tabs := {}             # id do vilão → botão da lista
var v_focus := ""            # vilão em foco no detalhe
var v_art: Control
var v_name: Label
var v_status: Label
var v_rules: VBoxContainer
var v_pick: Button
var v_edit: Button
var v_measured := false

const P_TEXT_W := 560.0
const DECK_COLS := 10
const DECK_CARD_W := 82.0


## Texto com palavras-chave (as mesmas dicas das cartas), em Alegreya Sans a tinta.
func _rich(text: String, size: int, col := UiParch.INK, w := 0.0, center := false) -> RichTextLabel:
	var l := Tips.label(text, size, col, w, center)
	UiParch.style_label(l, "body", size, col)
	l.add_theme_font_override("bold_font", UiParch.font("bold"))
	l.add_theme_font_size_override("bold_font_size", size)
	return l


## Folha de pergaminho com moldura dourada.
func _sheet(margin := 30.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiParch.box("gold", margin))
	p.set_meta("paper", true)
	return p


## Retrato pintado (assets/ui/portraits/); sem ele, o desenho antigo.
func _art_for(id: String, kind: String) -> Texture2D:
	var t := UiParch.portrait(kind + "_" + id)
	if t != null:
		return t
	return villain_tex(data, id) if kind == "villain" else UiDiario.card_tex("hero_" + id)


func _paper_btn(key: String, w: float, h: float, size := 22) -> Button:
	var b := Button.new()
	b.text = key
	b.custom_minimum_size = Vector2(w, h)
	UiParch.paper_button(b, size)
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


func _build_villains_parch() -> void:
	deck_screen = _sheet(30.0)
	add_child(deck_screen)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	deck_screen.add_child(root)
	root.add_child(UiParch.ribbon_title(tr("UI_CHOOSE_VILLAIN"), 34))
	var sub := _rich(tr("UI_MENU_PICK_SUB"), 18, UiParch.INK_SOFT, 1060.0, true)
	sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(sub)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 26)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL   # prende a linha dos botões no fundo da folha
	root.add_child(body)
	# Lista dos vilões: retrato, nome e situação (recorde ou trancado).
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	list.custom_minimum_size = Vector2(350, 0)
	body.add_child(list)
	for id in data.villain_ids:
		var b := Button.new()
		b.custom_minimum_size = Vector2(350, 118)
		UiParch.paper_button(b, 20)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_top = 9
		row.offset_right = -10
		row.offset_bottom = -9
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(row)
		var art := UiParch.framed_art(_art_for(id, "villain"), Vector2(104, 100))
		art.name = "Art"
		row.add_child(art)
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)
		var nm := UiParch.label(tr("DECK_" + id), "title", 23, UiParch.BLOOD)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(nm)
		var st := UiParch.label("", "body", 16, UiParch.INK_SOFT)
		st.name = "Status"
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(st)
		b.focus_entered.connect(_focus_villain.bind(id))
		b.mouse_entered.connect(func(): b.grab_focus())
		# Clicar (ou confirmar no foco) só seleciona o vilão; a run começa no botão Começar.
		b.pressed.connect(func():
			if meta.villains.has(id):
				pending_villain = id
				_focus_villain(id))
		list.add_child(b)
		v_tabs[id] = b
	# Detalhe do vilão em foco.
	var det := VBoxContainer.new()
	det.add_theme_constant_override("separation", 10)
	det.custom_minimum_size = Vector2(880, 0)
	body.add_child(det)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	det.add_child(top)
	v_art = Control.new()
	v_art.custom_minimum_size = Vector2(250, 240)
	top.add_child(v_art)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	info.add_child(UiParch.label(tr("UI_VILLAIN_TAG"), "italic", 18, UiParch.INK_SOFT))
	v_name = UiParch.label("", "title", 44, UiParch.BLOOD)
	info.add_child(v_name)
	v_status = UiParch.label("", "bold", 18, UiParch.INK_SOFT)
	info.add_child(v_status)
	info.add_child(UiParch.divider(P_TEXT_W))
	v_rules = VBoxContainer.new()
	v_rules.add_theme_constant_override("separation", 8)
	info.add_child(v_rules)
	det.add_child(UiParch.divider(880))
	preview_head = UiParch.label("", "title", 21, UiParch.INK)
	det.add_child(preview_head)
	var grid := GridContainer.new()
	grid.columns = DECK_COLS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	preview_row = grid
	det.add_child(grid)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 16)
	root.add_child(btns)
	var back := _paper_btn("UI_BACK", 180, 52)
	back.pressed.connect(func(): show_screen(decks_back))
	btns.add_child(back)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(gap)
	v_edit = _paper_btn("UI_MENU_EDIT_DECK", 280, 60, 24)
	v_edit.pressed.connect(func():
		if meta.villains.has(v_focus):
			focus_pref = v_focus
			lib_return = "decks"
			show_screen("collection")
			collection.set_tab(v_focus))
	btns.add_child(v_edit)
	v_pick = Button.new()
	v_pick.text = "UI_MENU_START"
	v_pick.custom_minimum_size = Vector2(400, 60)
	UiParch.ribbon_button(v_pick, "monster", 26)
	v_pick.mouse_entered.connect(func(): v_pick.grab_focus())
	v_pick.pressed.connect(func():
		pending_villain = v_focus
		_start_villain())
	btns.add_child(v_pick)


func _fill_villains_parch() -> void:
	for id in v_tabs:
		var b: Button = v_tabs[id]
		var open: bool = meta.villains.has(id)
		var st := b.find_child("Status", true, false) as Label
		st.text = record_text(id) if open else locked_text(id)
		st.add_theme_color_override("font_color", UiParch.INK_SOFT if open else UiParch.BLOOD)
		(b.find_child("Art", true, false) as Control).modulate = Color.WHITE if open else Color(0.55, 0.52, 0.5)
	v_focus = ""   # força o redesenho do deck (a Biblioteca pode tê-lo mudado)
	_focus_villain(_default_villain())
	if not v_measured:
		_measure_villain_sheet()


## A folha cresce ou encolhe conforme o texto do vilão em foco, e a tela é recentrada a cada frame:
## passa por todos uma vez, guarda o maior tamanho e o trava como mínimo, para o tamanho nunca mudar.
func _measure_villain_sheet() -> void:
	v_measured = true
	var keep := _default_villain()
	var best := Vector2.ZERO
	var rules_h := 0.0
	for id in data.villain_ids:
		_focus_villain(id)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		rules_h = maxf(rules_h, v_rules.get_combined_minimum_size().y)
		best = best.max(deck_screen.get_combined_minimum_size())
	# O bloco variável ganha a altura do maior: nada abaixo dele (cartas, botões) se mexe ao trocar de vilão.
	v_rules.custom_minimum_size.y = rules_h
	await get_tree().process_frame
	best = deck_screen.get_combined_minimum_size()
	deck_screen.custom_minimum_size = best
	deck_screen.reset_size()
	_focus_villain(keep)


## Detalhe do vilão: retrato grande, regras, o deck montado (19 cartas) e os botões Editar deck / Começar.
func _focus_villain(id: String) -> void:
	if v_focus == id and v_art.get_child_count() > 0:
		return
	v_focus = id
	for k in v_tabs:
		var on: bool = k == id
		(v_tabs[k] as Button).add_theme_stylebox_override("normal", UiParch.button_box("hover" if on else "normal"))
	var open: bool = meta.villains.has(id)
	for c in v_art.get_children():
		c.queue_free()
	var art := UiParch.framed_art(_art_for(id, "villain"), v_art.custom_minimum_size, "frame_legend")
	art.modulate = Color.WHITE if open else Color(0.6, 0.57, 0.55)
	v_art.add_child(art)
	v_name.text = tr("DECK_" + id)
	v_status.text = record_text(id) if open else locked_text(id)
	v_status.add_theme_color_override("font_color", UiParch.GOOD if open else UiParch.BLOOD)
	UiKit.clear(v_rules)
	var lines: PackedStringArray = UiKit.deck_rules_text(data, id).split("\n", false)
	for i in lines.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var mark := UiParch.label("◆", "bold", 15, UiParch.GOLD)
		mark.custom_minimum_size = Vector2(16, 0)
		mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(mark)
		row.add_child(_rich(lines[i].trim_prefix("• "), 18, UiParch.INK, P_TEXT_W - 30.0))
		v_rules.add_child(row)
	_fill_preview(id)
	v_pick.disabled = not open
	v_pick.text = "UI_MENU_START" if open else locked_text(id)
	v_edit.disabled = not open


## O deck montado do vilão (19 cartas, no nível de cada uma), da mais barata à mais cara.
func _fill_preview(id: String) -> void:
	var ids: Array = meta.deck_for(id)
	preview_head.text = tr("UI_MENU_DECK_HEAD").format({"name": tr("DECK_" + id), "n": ids.size(), "m": MetaSave.DECK_SIZE})
	UiKit.clear(preview_row)
	ids.sort_custom(func(a, c):
		var da: CardDef = data.card(a)
		var dc: CardDef = data.card(c)
		var ca := da.cost_at(meta.card_level(a))
		var cc := dc.cost_at(meta.card_level(c))
		return ca < cc or (ca == cc and a < c))
	for cid in ids:
		var d: CardDef = data.card(cid)
		var lv := meta.card_level(cid)
		var cell := UiKit.mini_card(d, d.cost_at(lv), [], "", DECK_CARD_W, roundf(DECK_CARD_W * 1.32), true, lv)
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		Tips.attach(cell, func(): return Tips.card_entries(d, [], true, lv))
		preview_row.add_child(cell)
