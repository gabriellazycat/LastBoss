class_name MapMenu
extends Control
## Menu principal (pele "Mapa aberto", maquete aprovada "Menu A · o menu é o mapa"): um mapa grande aberto sobre a mesa, cada opção é um lugar ligado por estradas tracejadas.
## Nova run = o covil (no centro, anel vermelho), Coleção = a biblioteca, Compêndio = a torre, Configurações = o
## moinho, Sair = o barco na costa; "Continuar run" = a estrada vermelha que chega ao covil (só com run salva).
## O fundo desenhado (papel, estradas, bosques, rio, mar, rosa dos ventos, faixa do título vazia) vem pronto de
## assets/ui/map/bg_menuA.png (tools/art/ui_kit/export_map_art.py); aqui ficam os lugares, os textos e os botões.

const MAP := "res://assets/ui/map/"
const M := 24.0   # margem do PNG em volta do papel
# Lugares nas coordenadas do papel da maquete (1640x960): [id, desenho, chave do texto, chave da legenda, tamanho]
const PLACES := [
	["covil", "m-lair", "UI_MENU_COVIL", "UI_MAP_LAIR", 150.0, Vector2(846, 540)],   # o covil: roda de melhorias; a legenda mostra recorde e Almas
	["collection", "m-library", "UI_MENU_LIBRARY", "", 104.0, Vector2(420, 330)],   # a Biblioteca (álbum e deck)
	["compendium", "m-tower", "UI_COMPENDIUM", "", 104.0, Vector2(520, 760)],
	["settings", "m-mill", "UI_SETTINGS", "", 104.0, Vector2(1240, 350)],
	["quit", "m-boat", "UI_QUIT", "", 104.0, Vector2(1300, 730)],
	["tutorial", "m-house", "UI_MENU_TUTORIAL", "UI_MENU_TUTORIAL_SUB", 92.0, Vector2(846, 300)],   # fase 0 (a Horda sem fim saiu em 21/11/2026)
]

signal chosen(id: String)

var buttons := {}          # id -> Button
var captions := {}         # id -> Label da legenda (a Horda sem fim troca a dela pelo recorde)
var buttons_box: Control   # os botões, na ordem do menu de hoje (continuar, nova run, coleção, ...)
var continue_btn: Button
var portrait: Control
var badges := {}           # id -> selo com número, até o lugar ser visitado
var balloons := {}         # id -> balão de fala sobre o lugar


func build(villain_portrait: Texture2D) -> void:
	var bg := TextureRect.new()
	bg.texture = load(MAP + "bg_menuA.png")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	custom_minimum_size = bg.texture.get_size()
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Título na faixa do fundo (faixa em 520,34 com 600 de largura).
	var over := UiParch.label("UI_TITLE_OVER", "title", 17, UiParch.INK)
	_place(over, Vector2(520, 50), Vector2(600, 0), true)
	var t := UiParch.label("LAST BOSS", "title", 64, UiParch.INK)
	_place(t, Vector2(520, 66), Vector2(600, 0), true)
	var sub := UiParch.label("UI_SUBTITLE", "italic", 23, UiParch.INK)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	_place(sub, Vector2(600, 190), Vector2(440, 0), true)
	buttons_box = Control.new()
	buttons_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(buttons_box)
	# "Continuar": a bandeira no começo da estrada vermelha que chega ao covil.
	continue_btn = _node_button("continue", "m-tent", "UI_CONTINUE", 76.0, Vector2(846, 826), false)
	for p in PLACES:
		_node_button(p[0], p[1], p[2], p[4], p[5], p[0] == "covil")
		if p[0] in ["covil", "collection"]:
			_add_marks(p[0], p[4], p[5])
		if p[3] != "":
			var h := UiParch.label(p[3], "italic", 21, UiParch.INK_SOFT)
			# contorno da cor do papel: a estrada vermelha passa por baixo sem riscar o texto
			h.add_theme_color_override("font_outline_color", Color(UiParch.PARCH, 0.95))
			h.add_theme_constant_override("outline_size", 10)
			_place(h, p[5] + Vector2(-150, p[4] * 0.5 + 60), Vector2(300, 0), true)
			captions[p[0]] = h
	# O chefe da última run, num quadrinho com moldura do mapa.
	if villain_portrait != null:
		portrait = UiParch.framed_art(villain_portrait, Vector2(200, 192), "frame_gold")
		portrait.position = Vector2(M + 70, M + 560)
		portrait.rotation_degrees = -2.0
		add_child(portrait)
		var me := UiParch.label("UI_TITLE_ME", "italic", 21, UiParch.BLOOD)
		_place(me, Vector2(60, 762), Vector2(220, 0), true)


## Selo (círculo vermelho com número, no canto do lugar) e balão (papel, acima do lugar).
func _add_marks(id: String, sz: float, at: Vector2) -> void:
	var top := Vector2(M, M) + at - Vector2(0, sz * 0.5)
	var badge := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiParch.BLOOD
	sb.border_color = UiParch.PARCH
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 1
	sb.content_margin_bottom = 3
	badge.add_theme_stylebox_override("panel", sb)
	badge.custom_minimum_size = Vector2(40, 40)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bl := UiParch.label("0", "bold", 24, UiParch.CREAM)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	badge.visible = false
	badge.position = top + Vector2(sz * 0.5 - 22, -4)
	add_child(badge)
	badges[id] = badge
	var bal := PanelContainer.new()
	bal.add_theme_stylebox_override("panel", UiParch.box("ink", 10))
	bal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UiParch.label("", "body", 20, UiParch.INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(250, 0)
	bal.add_child(t)
	bal.visible = false
	bal.set_meta("center", top.x)
	bal.set_meta("bottom", top.y - 6.0)
	add_child(bal)
	balloons[id] = bal


## Número do selo do lugar (0 esconde).
func set_badge(id: String, n: int) -> void:
	var b: PanelContainer = badges.get(id)
	if b == null:
		return
	b.visible = n > 0
	(b.get_child(0) as Label).text = str(n)


## Texto do balão do lugar ("" esconde). Centrado, com a base logo acima do desenho.
func set_balloon(id: String, text: String) -> void:
	var b: PanelContainer = balloons.get(id)
	if b == null:
		return
	b.visible = text != ""
	(b.get_child(0) as Label).text = text
	b.reset_size()
	b.position = Vector2(float(b.get_meta("center")) - b.size.x * 0.5, float(b.get_meta("bottom")) - b.size.y)


func _place(l: Control, at: Vector2, w: Vector2, center: bool) -> void:
	l.position = Vector2(M, M) + at
	if w.x > 0:
		l.custom_minimum_size.x = w.x
		l.size.x = w.x
	if center and l is Label:
		(l as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)


## Lugar do mapa: o desenho num anel duplo (vermelho no mouse/foco) com o nome embaixo. É um Button de verdade
## (foco por teclado e controle; as setas andam pelos lugares mais próximos na direção apertada).
func _node_button(id: String, sym: String, key: String, sz: float, at: Vector2, main: bool) -> Button:
	var b := Button.new()
	b.text = key
	b.set_meta("no_frame", true)
	b.set_meta("no_ink", true)
	var n: Texture2D = CampaignArt.map_tex(MAP + "node_%s.svg" % sym)
	var hot: Texture2D = CampaignArt.map_tex(MAP + "node_%s_hot.svg" % sym)
	b.icon = hot if main else n
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", int(sz))
	b.add_theme_font_override("font", UiParch.font("title"))
	b.add_theme_font_size_override("font_size", 36 if main else 30)
	var ink := UiParch.BLOOD if main else UiParch.INK
	for k in ["font_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(k, ink)
	b.add_theme_color_override("font_hover_color", UiParch.BLOOD)
	b.add_theme_color_override("font_hover_pressed_color", UiParch.BLOOD)
	b.add_theme_color_override("font_outline_color", Color(UiParch.PARCH, 0.9))
	b.add_theme_constant_override("outline_size", 8)
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(maxf(sz + 40.0, 260.0), sz + 52.0)
	b.size = b.custom_minimum_size
	b.position = Vector2(M, M) + at - Vector2(b.size.x * 0.5, sz * 0.5)
	var lit := func(on: bool):
		b.icon = hot if (on or main) else n
		b.scale = Vector2.ONE * (1.06 if on else 1.0)
	b.pivot_offset = Vector2(b.size.x * 0.5, sz * 0.5)
	b.mouse_entered.connect(func(): b.grab_focus())
	b.focus_entered.connect(func(): lit.call(true))
	b.focus_exited.connect(func(): lit.call(false))
	b.pressed.connect(func(): chosen.emit(id))
	buttons_box.add_child(b)
	buttons[id] = b
	return b


## Ordem dos botões do menu: continuar, covil, biblioteca, compêndio, tutorial, configurações, sair.
func ordered() -> Array:
	return [continue_btn, buttons["covil"], buttons["collection"], buttons["compendium"], buttons["tutorial"], buttons["settings"], buttons["quit"]]


## Legenda do covil: recorde (party) e Almas (texto já traduzido pelo menu).
func set_status(text: String) -> void:
	var cap: Label = captions.get("covil")
	if cap:
		cap.text = text
