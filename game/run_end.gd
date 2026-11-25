class_name RunEnd
extends Control
## Tela de fim da run (plano de metaprogressão, 21/11/2026, frente G): "O covil caiu na party N de 15" (ou a vitória),
## o recorde (novo recorde em destaque), as Almas (dano + heróis + bônus = total), os vilões liberados e os desafios
## concluídos com a revelação das cartas (UnlockReveal). Botão: Menu (volta ao menu principal, não ao Covil).
## Os dados vêm do resumo que MetaSave.apply_run devolve; esta tela não grava nada.

signal to_menu

const GUARD := 0.7   # os botões só valem depois disto (um clique de jogo não pode pular a tela sem querer)

var menu_b: Button
var box: Control
var reveal: UnlockReveal
var _guard_left := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)


func _process(delta: float) -> void:
	if _guard_left > 0.0:
		_guard_left -= delta
		if _guard_left <= 0.0 and menu_b != null:
			menu_b.disabled = false
			if not is_instance_valid(reveal):
				focus_first()


func focus_first() -> void:
	if is_instance_valid(reveal) or menu_b == null or menu_b.disabled:
		return
	menu_b.grab_focus()


static func _clock(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _row(key_or_text: String, value: String, size := 22, col := UiParch.INK, vcol := UiParch.INK) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 14)
	var l := UiParch.label(key_or_text, "body", size, col)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)
	var v := UiParch.label(value, "bold", size, vcol)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.add_child(v)
	return r


## Monta e mostra a tela com o resumo de MetaSave.apply_run.
func show_result(d: GameData, m: MetaSave, sim: Sim, info: Dictionary) -> void:
	if is_instance_valid(box):
		box.queue_free()
	if is_instance_valid(reveal):
		reveal.queue_free()
	var won: bool = bool(info.get("won", false))
	var tutorial: bool = bool(info.get("tutorial", false))
	var total := maxi(1, d.phase(sim.campaign_phase).get("parties", []).size())
	var beaten := int(info.get("party", sim.parties_beaten()))
	var st := sim.stats
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	box = center
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", UiParch.box("gold", 34))
	center.add_child(sheet)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(860, 0)
	sheet.add_child(v)
	# Título: onde o covil caiu (ou a vitória).
	var title_txt := tr("UI_RESULT_TITLE_" + str(st["result"]))
	if not tutorial:
		title_txt = tr("UI_END_TITLE_WIN").format({"m": total}) if won else tr("UI_END_TITLE_LOSS").format({"n": mini(beaten + 1, total), "m": total})
	var t := UiParch.label(title_txt, "title", 50, UiParch.GOOD if won else UiParch.BLOOD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var sub := UiParch.label(tr("UI_END_TUT") if tutorial else tr("UI_RESULT_" + str(st["result"])), "italic", 21, UiParch.INK_SOFT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(800, 0)
	v.add_child(sub)
	v.add_child(UiParch.divider(800))
	if not tutorial:
		# Recorde: o novo em destaque.
		var rec := HBoxContainer.new()
		rec.alignment = BoxContainer.ALIGNMENT_CENTER
		rec.add_theme_constant_override("separation", 18)
		rec.add_child(UiParch.label(tr("UI_END_BEATEN").format({"n": beaten}), "bold", 26, UiParch.INK))
		if bool(info.get("new_best", false)):
			var nb := UiParch.label(tr("UI_END_NEW_BEST"), "title", 30, UiParch.GOLD)
			nb.name = "NewBest"
			rec.add_child(nb)
		else:
			rec.add_child(UiParch.label(tr("UI_END_RECORD").format({"n": int(info.get("best", m.best_party)), "m": total}), "italic", 21, UiParch.INK_SOFT))
		v.add_child(rec)
		# Duas colunas: Almas à esquerda, números da run à direita.
		var cols := HBoxContainer.new()
		cols.add_theme_constant_override("separation", 46)
		v.add_child(cols)
		var left := VBoxContainer.new()
		left.add_theme_constant_override("separation", 5)
		left.custom_minimum_size = Vector2(390, 0)
		cols.add_child(left)
		var al: Dictionary = info.get("almas", {})
		left.add_child(UiParch.label(tr("UI_END_ALMAS"), "title", 28, UiParch.SOUL))
		left.add_child(_row("%s (%d)" % [tr("UI_END_ALMAS_DMG"), int(round(float(info.get("dmg_raw", 0.0))))], "+%d" % int(al.get("dmg", 0)), 19))
		left.add_child(_row("%s (%d)" % [tr("UI_END_ALMAS_HEROES"), int(info.get("heroes", 0))], "+%d" % int(al.get("heroes", 0)), 19))
		if int(al.get("bonus", 0)) > 0:
			left.add_child(_row(tr("UI_END_ALMAS_BONUS"), "+%d" % int(al["bonus"]), 19))
		left.add_child(UiParch.divider(380))
		var tot := _row(tr("UI_END_ALMAS_TOTAL"), "+%d" % int(al.get("total", 0)), 28, UiParch.INK, UiParch.SOUL)
		tot.name = "AlmasTotal"
		left.add_child(tot)
		left.add_child(UiParch.label(tr("UI_END_BALANCE").format({"n": int(info.get("balance", m.almas))}), "italic", 19, UiParch.INK_SOFT))
		var right := VBoxContainer.new()
		right.add_theme_constant_override("separation", 5)
		right.custom_minimum_size = Vector2(380, 0)
		cols.add_child(right)
		var top := ""
		var best := 0
		for cid in st["played"]:
			if int(st["played"][cid]) > best:
				best = int(st["played"][cid])
				top = cid
		right.add_child(UiParch.label(tr("UI_END_RUN"), "title", 28, UiParch.INK))
		right.add_child(_row(tr("UI_ST_you"), "%d / %d" % [int(st.get("heroes_fallen", 0)), sim.party_size()], 19))
		right.add_child(_row(tr("UI_ST_time"), _clock(sim.t), 19))
		right.add_child(_row(tr("UI_ST_contests"), "%d / %d" % [int(st["locs_won"]), int(st["locs_visited"])], 19))
		right.add_child(_row(tr("UI_ST_gold"), str(int(st["gold_earned"])), 19))
		right.add_child(_row(tr("UI_ST_relics"), str(st["relics"].size()), 19))
		right.add_child(_row(tr("UI_ST_top"), tr("CARD_" + top) if top != "" else "—", 19))
		# Vilões liberados agora.
		for vid in info.get("villains", []):
			var vl := UiParch.label(tr("UI_END_VILLAIN").format({"p": tr("DECK_" + str(vid))}), "bold", 24, UiParch.GOOD)
			vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(vl)
		# Desafios concluídos (a revelação das cartas abre por cima) ou "quase lá".
		var done: Array = info.get("done", [])
		if not done.is_empty():
			var cl := UiParch.label(tr("UI_END_CHALLENGES").format({"n": done.size()}), "bold", 22, UiParch.INK)
			cl.name = "Challenges"
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(cl)
		else:
			var near := UnlockReveal.near_text(info)
			var nl := UiParch.label(near if near != "" else tr("UI_END_NO_CHALLENGES"), "italic", 18, UiParch.INK_SOFT)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			nl.custom_minimum_size = Vector2(800, 0)
			v.add_child(nl)
	v.add_child(UiParch.divider(800))
	var br := HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	br.add_theme_constant_override("separation", 22)
	v.add_child(br)
	# Só o botão do menu: o fim da run não abre mais a tela do Covil (pedido dele, 23/11/2026).
	menu_b = Button.new()
	menu_b.text = "UI_END_MENU"
	menu_b.custom_minimum_size = Vector2(380, 62)
	UiParch.ribbon_button(menu_b, "monster", 28)
	menu_b.pressed.connect(func(): to_menu.emit())
	br.add_child(menu_b)
	menu_b.disabled = true
	_guard_left = GUARD
	visible = true
	if not tutorial:
		reveal = UnlockReveal.build(d, info)
		if reveal != null:
			add_child(reveal)
			reveal.finished.connect(func():
				reveal = null
				focus_first())
