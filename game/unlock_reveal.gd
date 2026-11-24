class_name UnlockReveal
extends Control
## Fim da fase: as cartas que o jogador liberou, viradas de costas. Clique (ou Enter) vira cada uma e mostra o
## desafio e o que ele fez; o botão de baixo vira as que faltam e, no fim, vira "Continuar".
## Dados: o resultado de MetaSave.apply_unlocks ({"done": [{id, v, g}], "near": [...]}). Texto do desafio: UNLOCK_<id>.
## Visual: o mesmo kit das outras telas (UiKit/UiDiario): papel, tinta, carta do jogo.

signal finished

var data: GameData
var items: Array = []
var slots: Array = []        # [{stage, back, front, note, flipped, busy}]
var btn: Button
var sub: Label
var card_w := 176.0
var _scroll: ScrollContainer
var _scroll_max := 400.0


## null se nada foi liberado.
static func build(d: GameData, result: Dictionary) -> UnlockReveal:
	var done: Array = result.get("done", [])
	if done.is_empty():
		return null
	var r := UnlockReveal.new()
	r.data = d
	r.items = done.duplicate()
	return r


## "Cumprido" para desafio de sim/não; senão "Você chegou a 67 (meta: 60)".
static func did_text(it: Dictionary) -> String:
	if float(it.get("g", 1.0)) <= 1.0:
		return TranslationServer.translate("UI_UNLOCK_DONE")
	return TranslationServer.translate("UI_UNLOCK_DID").format({"v": int(floor(float(it["v"]))), "g": int(round(float(it["g"])))})


## Linha discreta quando nada foi liberado: as 1 a 3 cartas mais perto da meta ("Quase lá: Maré de Ratos 11/15 · ...").
static func near_text(result: Dictionary) -> String:
	var near: Array = result.get("near", []).filter(func(p): return float(p["g"]) > 1.0 and float(p["v"]) > 0.0)
	near.sort_custom(func(a, b): return float(a["v"]) / float(a["g"]) > float(b["v"]) / float(b["g"]))
	var parts: Array = []
	for p in near.slice(0, 3):
		var pid := str(p["id"])
		var pname := TranslationServer.translate("REL_" + pid.substr(2)) if pid.begins_with("r:") else TranslationServer.translate("CARD_" + pid)
		parts.append("%s %d/%d" % [pname, int(floor(float(p["v"]))), int(round(float(p["g"])))])
	if parts.is_empty():
		return ""
	return TranslationServer.translate("UI_UNLOCK_NEAR").format({"l": " · ".join(parts)})


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var vp := get_viewport_rect().size
	card_w = 176.0 if items.size() <= 4 else (148.0 if items.size() <= 6 else (118.0 if items.size() <= 10 else 100.0))
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	var title := UiKit.title(46)
	title.text = tr("UI_UNLOCK_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(UiDiario.tape_title(title))
	sub = UiKit.label(18, Color(0.95, 0.9, 0.8), 3)
	sub.text = tr("UI_UNLOCK_SUB").format({"n": items.size()})
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	# Muitas cartas: quebram em linhas e a lista rola, para o botão nunca sair da tela.
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 20)
	row.add_theme_constant_override("v_separation", 16)
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(maxf(vp.x - 120.0, 300.0), 0)
	for i in items.size():
		row.add_child(_slot(i))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(row.custom_minimum_size.x, 0)
	scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_child(scroll)
	scroll.add_child(row)
	_scroll = scroll
	_scroll_max = maxf(vp.y - 250.0, 200.0)
	btn = Button.new()
	btn.custom_minimum_size = Vector2(300, 54)
	btn.add_theme_font_size_override("font_size", 22)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiParch.ribbon_button(btn, "monster", 24)   # o botão principal do mapa: a faixa vermelha
	btn.pressed.connect(_on_btn)
	v.add_child(btn)
	_refresh_btn()
	btn.grab_focus.call_deferred()


func _process(_d: float) -> void:
	# O HUD não ancora os filhos: segue o tamanho da janela.
	position = Vector2.ZERO
	size = get_viewport_rect().size
	if _scroll != null:
		var vp_h := size.y
		_scroll_max = maxf(vp_h - 250.0, 200.0)
		var h := minf(_scroll.get_child(0).get_combined_minimum_size().y, _scroll_max)
		_scroll.custom_minimum_size.y = h


func _slot(i: int) -> Control:
	var it: Dictionary = items[i]
	# Desafio de relíquia vem com o id "r:<id>" (MetaSave._check_unlocks): a frente mostra o ícone e o nome dela.
	var rid := str(it["id"]).substr(2) if str(it["id"]).begins_with("r:") else ""
	var d: CardDef = data.card(str(it["id"])) if rid == "" else null
	# Coluna (carta + bilhete): o clique em qualquer ponto vira a carta; o teclado usa o botão de baixo.
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_STOP
	col.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	col.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_flip(i))
	var front: Control = UiKit.card(d, d.cost, [], "", card_w, 1) if d != null else _relic_front(rid)
	var cs := front.custom_minimum_size
	var stage := Control.new()
	stage.custom_minimum_size = cs
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.pivot_offset = cs * 0.5
	var back := UiKit.panel(UiKit.BG, UiKit.GOLD.darkened(0.3), 14)
	back.custom_minimum_size = cs
	back.size = cs
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var q := UiKit.title(int(cs.x * 0.45))
	q.text = "?"
	cc.add_child(q)
	back.add_child(cc)
	front.size = cs
	front.visible = false
	stage.add_child(back)
	stage.add_child(front)
	UiKit.ignore_mouse(stage)
	col.add_child(stage)
	# Desafio e feito: aparecem quando a carta vira.
	var note := UiKit.panel(UiKit.BG, UiKit.GOLD.darkened(0.4), 8)
	note.custom_minimum_size = Vector2(cs.x, 0)
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 3)
	var l1 := UiKit.label(11, UiKit.MUTED, 0)
	l1.text = tr("UI_UNLOCK_GOAL")
	var l2 := UiKit.label(13, UiKit.TEXT, 0)
	l2.text = tr("UNLOCK_" + (d.id if d != null else "relic_" + rid))
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l2.custom_minimum_size = Vector2(cs.x - 12.0, 0)
	var l3 := UiKit.label(13, UiKit.GOLD, 0)
	l3.text = "✔ " + did_text(it)
	l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l3.custom_minimum_size = Vector2(cs.x - 12.0, 0)
	for l in [l1, l2, l3]:
		nv.add_child(l)
	note.add_child(nv)
	UiKit.ignore_mouse(note)
	note.modulate.a = 0.0
	col.add_child(note)
	slots.append({"stage": stage, "back": back, "front": front, "note": note, "flipped": false, "busy": false})
	return col


## Frente da "carta" de uma relíquia liberada: ícone, nome e efeito num painel do tamanho de uma carta.
func _relic_front(rid: String) -> Control:
	var p := UiKit.panel(UiKit.BG, UiKit.GOLD, 14)
	p.custom_minimum_size = Vector2(card_w, card_w * 1.4)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	v.add_child(UiKit.relic_icon(rid, card_w * 0.5))
	var n := UiKit.title(maxi(16, int(card_w * 0.12)), UiKit.GOLD)
	n.text = tr("REL_" + rid)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size = Vector2(card_w - 20.0, 0)
	v.add_child(n)
	var e := UiKit.label(12, UiKit.TEXT, 0)
	e.text = tr("RELD_" + rid)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.custom_minimum_size = Vector2(card_w - 20.0, 0)
	v.add_child(e)
	p.add_child(v)
	return p


func _flip(i: int) -> void:
	var s: Dictionary = slots[i]
	if s["flipped"]:
		return
	s["flipped"] = true
	var stage: Control = s["stage"]
	var tw := create_tween()
	tw.tween_property(stage, "scale:x", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		s["back"].visible = false
		s["front"].visible = true
		Juice.burst(self, stage.get_global_rect().get_center() - get_global_rect().position, UiKit.GOLD, 22, 1.0))
	tw.tween_property(stage, "scale:x", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var nt := create_tween()
	nt.tween_interval(0.25)
	nt.tween_property(s["note"], "modulate:a", 1.0, 0.25)
	_refresh_btn()


func _all_flipped() -> bool:
	for s in slots:
		if not s["flipped"]:
			return false
	return true


func _refresh_btn() -> void:
	btn.text = tr("UI_UNLOCK_CONT") if _all_flipped() else tr("UI_UNLOCK_FLIP")


func _on_btn() -> void:
	for i in slots.size():
		if not slots[i]["flipped"]:
			_flip(i)
			return
	finished.emit()
	queue_free()
