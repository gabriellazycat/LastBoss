class_name ShopLedger
extends Control
## Loja como o livro-caixa do mercador (decisão 11/11/2026: variação "1. Revisado" de
## docs/decisoes_2026-11-11/loja_mercador.html). Regra do designer: nada repetido na tela. Cada item é uma linha
## (nome, pontinhos, preço); as cartas aparecem como esboços colados (só desenho e custo); tipo e descrição só na
## anotação da margem, do item em foco; o ouro aparece uma vez. Registro do dia = histórico das compras desta visita.
## Escolher a carta de Subir nível ou Tirar carta ("shop_pick" do Sim) abre o passo do baralho por cima do livro,
## com antes → depois. Tudo é desenhado num quadro de 1920x1080 escalado para a tela (a pele Diário fica na tinta).
## O cursor é o hud.selected (índice da opção no Sim), o mesmo que o controle usa com L1/R1 e A no main.gd.

signal chosen(k: int)

const W := 1920.0
const H := 1080.0
const BLUE := Color("2a2a6a")
const INK := Color("2a2018")
const WAX := Color("8e2f27")
const RED := Color("b3342a")
const BROWN := Color("6b3a10")
const LOG_INK := Color("1d2a6a")
const NOTE_INK := Color("3a2a6a")
const LP := Vector2(66, 50)          # página esquerda (estoque, registro, ouro)
const LS := Vector2(1070, 928)
const RP := Vector2(1136, 50)        # página direita (serviços, relíquia, anotação, lacre)
const RS := Vector2(658, 928)
const PICK := Rect2(180, 96, 1560, 888)   # passo do baralho
const ROW_H := 70.0
const ROW_GAP := 6.0
const CARD_W := 350.0                # carta antes/depois do passo do baralho
const CARD_H := 500.0
const ART_H := 250.0

var hud: Hud
var sim: Sim
var k := 1.0                          # escala do quadro de 1920x1080 para a tela
var o := Vector2.ZERO                 # canto do quadro na tela
var t := 0.0
var f_hand: Font
var f_disp: Font
var f_body: Font
var f_med: Font
var f_type: Font
# Visita atual.
var shop_obj = null                   # a oferta "shop" do Sim (o mesmo dicionário até a loja fechar)
var rows: Array = []                  # um por item que a loja abriu; vendido fica riscado
var mode := ""                        # "shop" ou "pick"
var shop_focus := 0
var log_lines: Array = []             # [{"text", "minus", "t"}]
var last_pick: Dictionary = {}        # carta escolhida no passo do baralho (para o registro)
var toast_text := ""
var toast_bad := false
var toast_t := -10.0
var gold_pulse := -10.0
var seal_hot := false
var btn_hot := -1                     # passo do baralho: 0 Voltar, 1 Confirmar
var pick_obj = null
var pick_rows: Array = []             # [{"k", "cd", "lv", "mods", "ok"}]
var pick_scroll := 0.0
var vs_seen := Vector2.ZERO
var open_t := -10.0
var last_sel := -2
# Filhos (texto com quebra e palavras-chave).
var note: RichTextLabel
var note_rect := Rect2()
var note_sig := ""
var list_clip: Control
var desc_l: RichTextLabel
var desc_r: RichTextLabel
var desc_sig := ""


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	f_hand = UiDiario.font("hand")
	f_type = UiDiario.font("type")
	f_disp = _font("MarcellusSC-Regular.ttf")
	f_body = _font("AlegreyaSans-Bold.ttf")
	f_med = _font("AlegreyaSans-Medium.ttf")
	note = _rtl()
	add_child(note)
	list_clip = Control.new()
	list_clip.clip_contents = true
	list_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_clip.draw.connect(_draw_pick_list)
	add_child(list_clip)
	desc_l = _rtl()
	desc_r = _rtl()
	add_child(desc_l)
	add_child(desc_r)
	visible = false


static func _font(file: String) -> Font:
	var fv := FontVariation.new()
	fv.base_font = load(UiDiario.F + file)
	fv.fallbacks = [load(UiDiario.F + "AlegreyaSans-Bold.ttf")]
	return fv


func _rtl() -> RichTextLabel:
	var l := Tips.label("", 20, NOTE_INK, 0.0, false)
	l.fit_content = false
	l.set_meta("no_ink", true)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_font_override("normal_font", f_hand)
	l.add_theme_constant_override("line_separation", -4)
	l.visible = false
	return l


# ---------------------------------------------------------------- estado

## Chamado pelo Hud a cada quadro com a oferta da frente ("shop" ou "shop_pick").
func sync(s: Sim, of: Dictionary) -> void:
	sim = s
	var vs := get_viewport_rect().size
	position = Vector2.ZERO
	size = vs
	k = minf(vs.x / W, vs.y / H)
	o = (vs - Vector2(W, H) * k) * 0.5
	var shop: Dictionary = of
	var m := "shop"
	if of["source"] == "shop_pick":
		m = "pick"
		shop = s.offers[1] if s.offers.size() > 1 and s.offers[1]["source"] == "shop" else {}
	if shop.is_empty():
		shop_obj = null
		rows.clear()
	elif not is_same(shop, shop_obj):
		_open(shop)
	# Logo que a loja abre, o main solta a carta da mão (hud.selected = -1): o foco volta para o 1º item.
	if m == "shop" and hud.selected < 0 and t - open_t < 0.4:
		hud.selected = 0
	if m != mode:
		if m == "pick":
			shop_focus = hud.selected
			hud.selected = 0
			pick_scroll = 0.0
		elif mode == "pick":
			hud.selected = shop_focus
		mode = m
	if m == "pick" and not is_same(of, pick_obj):
		pick_obj = of
		_build_pick(of)
	if m == "shop":
		pick_obj = null
		_check_sold(shop)
		var n: int = shop["options"].size()
		if hud.selected >= n:
			hud.selected = n - 1
	elif hud.selected >= (of["options"] as Array).size():
		hud.selected = (of["options"] as Array).size() - 1
	# Cursor movido de fora (L1/R1 do controle, números): a lista do baralho rola até ele.
	if m == "pick" and hud.selected != last_sel:
		_scroll_to_sel()
	last_sel = hud.selected
	if vs != vs_seen:
		vs_seen = vs
		note_sig = ""
		desc_sig = ""
	_sync_note()
	_sync_pick_children(of)
	queue_redraw()
	list_clip.queue_redraw()


func _open(shop: Dictionary) -> void:
	shop_obj = shop
	open_t = t
	rows.clear()
	log_lines.clear()
	var n_cards := 0
	for op in shop["options"]:
		var r := _row_of(op)
		rows.append(r)
		if r["kind"] == "card":
			n_cards += 1
	# Cartas na página esquerda (3, ou 4 com a Bolsa do Mercador): a altura da linha divide o espaço.
	var rh := minf(182.0, 556.0 / maxf(n_cards, 1.0))
	var ci := 0
	var si := 0
	var ri := 0
	for r in rows:
		match r["kind"]:
			"card":
				r["rect"] = Rect2(LP + Vector2(30, 124 + ci * rh), Vector2(LS.x - 86, rh - 6))
				r["rot"] = [-2.0, 1.5, -1.0, 1.0][ci % 4]
				ci += 1
			"relic":
				r["rect"] = Rect2(RP + Vector2(56, 396 + ri * 122), Vector2(RS.x - 112, 112))
				ri += 1
			_:
				r["rect"] = Rect2(RP + Vector2(56, 128 + si * 88), Vector2(RS.x - 112, 82))
				si += 1
	note_rect = Rect2(RP + Vector2(56, 530 + maxf(ri - 1, 0) * 122), Vector2(RS.x - 112, 210 - maxf(ri - 1, 0) * 122))
	_log(tr("UI_LEDGER_OPEN"), "")
	if hud.selected < 0:
		hud.selected = 0
	shop_focus = hud.selected
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	if hud.sfx.is_valid():
		hud.sfx.call("reward", 0.8)


func _row_of(op: Dictionary) -> Dictionary:
	var it: Dictionary = op["item"]
	var r := {"op": op, "item": it, "price": int(op["price"]), "sold": false, "plus": "", "cd": null, "lv": 1,
		"rot": 0.0, "shake": -10.0, "mods": []}
	match str(it["kind"]):
		"card":
			var cd: CardDef = sim.data.card(str(it["id"]))
			r["kind"] = "card"
			r["cd"] = cd
			r["lv"] = int(it.get("level", 1))
			r["name"] = tr("CARD_" + cd.id)
			r["plus"] = "+".repeat(maxi(0, int(r["lv"]) - 1))
		"pick":
			r["kind"] = "pick_" + str(it["what"])
			r["name"] = tr("UI_PICK_" + str(it["what"]))
		"mod":
			r["kind"] = "mod"
			r["name"] = tr("UI_LEDGER_MOD").format({"mod": tr("MOD_" + str(it["mod"])), "card": tr("CARD_" + str(it["card"]))})
		"relic":
			r["kind"] = "relic"
			r["name"] = tr("REL_" + str(it["id"]))
		_:
			r["kind"] = str(it["kind"])
			r["name"] = str(it["kind"])
	return r


## Item que saiu da loja foi comprado: risca a linha, carimba e escreve no registro.
func _check_sold(shop: Dictionary) -> void:
	var opts: Array = shop["options"]
	for r in rows:
		if r["sold"]:
			continue
		var still := false
		for op in opts:
			if is_same(op, r["op"]):
				still = true
				break
		if still:
			continue
		r["sold"] = true
		var txt := ""
		var tk := "UI_LEDGER_TOAST_CARD"
		match str(r["kind"]):
			"card":
				txt = tr("UI_LEDGER_SOLD").format({"x": r["name"] + ("" if r["plus"] == "" else " " + r["plus"])})
			"relic":
				txt = tr("UI_LEDGER_SOLD").format({"x": r["name"]})
				tk = "UI_LEDGER_TOAST_REL"
			"mod":
				txt = tr("UI_LEDGER_MODDED").format({"x": r["name"]})
				tk = "UI_LEDGER_TOAST_MOD"
			"pick_upgrade":
				var nm := _pick_name(last_pick, 1)
				txt = tr("UI_LEDGER_UPGRADED").format({"card": nm})
				tk = "UI_LEDGER_TOAST_UP"
			"pick_remove":
				txt = tr("UI_LEDGER_BURNT").format({"card": _pick_name(last_pick, 0)})
				tk = "UI_LEDGER_TOAST_REM"
		_log(txt, "−%d" % int(r["price"]))
		_toast(tr(tk), false)
		if hud.sfx.is_valid():
			hud.sfx.call("level_player", 1.1)


func _pick_name(op: Dictionary, extra: int) -> String:
	if op.is_empty() or not op.has("card"):
		return "?"
	var cd: CardDef = sim.data.card(str(op["card"]))
	return UiKit.card_name(cd, int(op.get("level", 1)) + extra)


func _log(txt: String, minus: String) -> void:
	# A pena escreve uma linha de cada vez: a nova começa quando a anterior termina.
	var t0 := t
	if log_lines.size() > 0:
		var e: Dictionary = log_lines[-1]
		t0 = maxf(t, float(e["t"]) + (String(e["text"]).length() + String(e["minus"]).length() + 5) / 22.0)
	log_lines.append({"text": txt, "minus": minus, "t": t0})
	while log_lines.size() > 2:
		log_lines.pop_front()


func _toast(txt: String, bad: bool) -> void:
	toast_text = txt
	toast_bad = bad
	toast_t = t


## O Hud pergunta antes de repassar a escolha ao Sim: sem ouro, a linha treme, o ouro pisca e o aviso diz quanto
## falta (nada é comprado). No passo do baralho, guarda a carta escolhida para o registro.
func before_choose(kk: int) -> bool:
	if sim == null or sim.offers.is_empty() or kk == Sim.SKIP:
		return true
	var of: Dictionary = sim.offers[0]
	var opts: Array = of["options"]
	if kk < 0 or kk >= opts.size():
		return false
	if of["source"] == "shop_pick":
		last_pick = opts[kk]
		return true
	var op: Dictionary = opts[kk]
	if sim.can_afford(op):
		return true
	var short := int(ceil(float(op["price"]) - sim.gold))
	for r in rows:
		if is_same(r["op"], op):
			r["shake"] = t
	gold_pulse = t
	_toast(tr("UI_LEDGER_POOR").format({"n": short}), true)
	if hud.sfx.is_valid():
		hud.sfx.call("ui_click", 0.55)
	return false


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	queue_redraw()


# ---------------------------------------------------------------- entrada

func _focus_row() -> Dictionary:
	if mode != "shop" or shop_obj == null or hud.selected < 0:
		return {}
	var opts: Array = shop_obj["options"]
	if hud.selected >= opts.size():
		return {}
	for r in rows:
		if is_same(r["op"], opts[hud.selected]):
			return r
	return {}


func _index_of(r: Dictionary) -> int:
	if shop_obj == null:
		return -1
	var opts: Array = shop_obj["options"]
	for i in opts.size():
		if is_same(opts[i], r["op"]):
			return i
	return -1


func _dp(screen: Vector2) -> Vector2:
	return (screen - o) / k


func _seal_c() -> Vector2:
	return RP + Vector2(131, RS.y - 99)


func _pick_list_rect() -> Rect2:
	return Rect2(PICK.position + Vector2(40, 112), Vector2(540, PICK.size.y - 112 - 104))


func _btn_rect(i: int) -> Rect2:
	var y := PICK.end.y - 22 - 62
	return Rect2(PICK.end.x - 40 - 230 - (250 if i == 0 else 0), y, 220, 60)


func _pick_row_at(p: Vector2) -> int:
	var lr := _pick_list_rect()
	if not lr.has_point(p):
		return -1
	var i := int(floor((p.y - lr.position.y - 12.0 + pick_scroll) / (ROW_H + ROW_GAP)))
	return i if i >= 0 and i < pick_rows.size() else -1


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var p := _dp(e.position)
		if mode == "shop":
			seal_hot = p.distance_to(_seal_c()) < 78.0
			for r in rows:
				if not r["sold"] and (r["rect"] as Rect2).has_point(p):
					var i := _index_of(r)
					if i >= 0:
						hud.selected = i
		else:
			btn_hot = 0 if _btn_rect(0).has_point(p) else (1 if _btn_rect(1).has_point(p) else -1)
	elif e is InputEventMouseButton and e.pressed:
		var p := _dp(e.position)
		if mode == "pick":
			if e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_scroll_pick((ROW_H + ROW_GAP) * 2.0 * (1.0 if e.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1.0))
			elif e.button_index == MOUSE_BUTTON_LEFT:
				var ri := _pick_row_at(p)
				if ri >= 0 and pick_rows[ri]["ok"]:
					hud.selected = int(pick_rows[ri]["k"])
					if e.double_click:
						chosen.emit(hud.selected)
				elif _btn_rect(1).has_point(p):
					chosen.emit(maxi(hud.selected, 0))
				elif _btn_rect(0).has_point(p) or not PICK.has_point(p):
					chosen.emit(Sim.SKIP)
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				chosen.emit(Sim.SKIP)
			accept_event()
			return
		if e.button_index != MOUSE_BUTTON_LEFT:
			return
		if p.distance_to(_seal_c()) < 78.0:
			chosen.emit(Sim.SKIP)
			accept_event()
			return
		for r in rows:
			if not r["sold"] and (r["rect"] as Rect2).has_point(p):
				var i := _index_of(r)
				if i >= 0:
					hud.selected = i
					chosen.emit(i)
				break
		accept_event()


## Teclado (setas, Enter, Esc no passo do baralho) e direcional do controle. Os números, o 0 e L1/R1/A/B
## continuam no main.gd (passam pelo Hud.choose_offer).
func _input(e: InputEvent) -> void:
	if not is_visible_in_tree() or sim == null or sim.offers.is_empty() or hud.pause_layer.visible:
		return
	if e is InputEventKey and (not e.pressed or e.echo and not (e.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT])):
		return
	if e is InputEventJoypadMotion or (e is InputEventJoypadButton and not e.pressed):
		return
	var d := Vector2.ZERO
	if e.is_action_pressed("ui_left", true):
		d = Vector2.LEFT
	elif e.is_action_pressed("ui_right", true):
		d = Vector2.RIGHT
	elif e.is_action_pressed("ui_up", true):
		d = Vector2.UP
	elif e.is_action_pressed("ui_down", true):
		d = Vector2.DOWN
	if d != Vector2.ZERO:
		if mode == "pick":
			_move_pick(int(d.y + d.x))
		else:
			_nav(d)
		get_viewport().set_input_as_handled()
		return
	if not (e is InputEventKey):
		return
	var kc: int = e.keycode
	if kc == KEY_ENTER or kc == KEY_KP_ENTER:
		if hud.selected >= 0:
			chosen.emit(hud.selected)
		elif mode == "shop":
			_nav(Vector2.DOWN)
		get_viewport().set_input_as_handled()
	elif (kc == KEY_ESCAPE or kc == KEY_BACKSPACE) and mode == "pick":
		chosen.emit(Sim.SKIP)
		get_viewport().set_input_as_handled()


## Setas no livro: vai para o item mais próximo naquela direção (como na maquete).
func _nav(d: Vector2) -> void:
	var cur := _focus_row()
	var cands: Array = []
	for r in rows:
		if not r["sold"] and _index_of(r) >= 0:
			cands.append(r)
	if cands.is_empty():
		return
	if cur.is_empty():
		hud.selected = _index_of(cands[0])
		return
	var a: Vector2 = (cur["rect"] as Rect2).get_center()
	var best = null
	var bs := 1e9
	for r in cands:
		if is_same(r, cur):
			continue
		var v: Vector2 = (r["rect"] as Rect2).get_center() - a
		var main := v.x * d.x if d.x != 0.0 else v.y * d.y
		if main <= 6.0:
			continue
		var sc := main + absf(v.y if d.x != 0.0 else v.x) * 2.4
		if sc < bs:
			bs = sc
			best = r
	if best != null:
		hud.selected = _index_of(best)
		if hud.sfx.is_valid():
			hud.sfx.call("ui_click", 1.4)


func _move_pick(d: int) -> void:
	var n: int = (sim.offers[0]["options"] as Array).size()
	if n == 0:
		return
	hud.selected = clampi(hud.selected + d, 0, n - 1)
	_scroll_to_sel()


func _scroll_pick(dy: float) -> void:
	var lr := _pick_list_rect()
	var full := 24.0 + pick_rows.size() * (ROW_H + ROW_GAP)
	pick_scroll = clampf(pick_scroll + dy, 0.0, maxf(0.0, full - lr.size.y))
	list_clip.queue_redraw()


func _scroll_to_sel() -> void:
	for i in pick_rows.size():
		if int(pick_rows[i]["k"]) == hud.selected:
			var lr := _pick_list_rect()
			var a := 12.0 + i * (ROW_H + ROW_GAP)
			if a < pick_scroll:
				pick_scroll = a - 8.0
			elif a + ROW_H > pick_scroll + lr.size.y - 12.0:
				pick_scroll = a + ROW_H - lr.size.y + 20.0
			_scroll_pick(0.0)
			return


# ---------------------------------------------------------------- pontos para o teste com o mouse

## Centros (na tela) do que uma pessoa clicaria para escolher a opção kk: a linha do livro; no passo do baralho,
## a carta da lista e depois Confirmar. Vazio se a linha está fora da área visível da lista (role antes).
func click_points(kk: int) -> Array:
	if kk == Sim.SKIP:
		return [o + (_btn_rect(0).get_center() if mode == "pick" else _seal_c()) * k]
	if mode == "shop":
		var opts: Array = shop_obj["options"] if shop_obj != null else []
		for r in rows:
			if kk < opts.size() and is_same(r["op"], opts[kk]):
				return [o + (r["rect"] as Rect2).get_center() * k]
		return []
	for i in pick_rows.size():
		if int(pick_rows[i]["k"]) == kk:
			var lr := _pick_list_rect()
			var y := lr.position.y + 12.0 + i * (ROW_H + ROW_GAP) - pick_scroll + ROW_H * 0.5
			if y < lr.position.y + 10.0 or y > lr.end.y - 10.0:
				return []
			return [o + Vector2(lr.position.x + 200.0, y) * k, o + _btn_rect(1).get_center() * k]
	return []


## -1 rolar para cima, 1 para baixo, 0 já visível; e o ponto onde girar a roda.
func scroll_need(kk: int) -> int:
	if mode != "pick":
		return 0
	for i in pick_rows.size():
		if int(pick_rows[i]["k"]) == kk:
			var lr := _pick_list_rect()
			var y := lr.position.y + 12.0 + i * (ROW_H + ROW_GAP) - pick_scroll + ROW_H * 0.5
			return -1 if y < lr.position.y + 10.0 else (1 if y > lr.end.y - 10.0 else 0)
	return 0


func scroll_point() -> Vector2:
	return o + _pick_list_rect().get_center() * k


# ---------------------------------------------------------------- filhos de texto

func _sync_note() -> void:
	var r := _focus_row()
	note.visible = mode == "shop" and not r.is_empty()
	if not note.visible:
		return
	var head := _note_head(r)
	var sig := str(r["op"]) + str(k) + str(sim.gold >= float(r["price"]))
	if sig == note_sig:
		return
	note_sig = sig
	var top := 16.0 + (30.0 if head != "" else 0.0)
	var nr := Rect2(note_rect.position + Vector2(34, top), Vector2(note_rect.size.x - 60, note_rect.size.y - top - 46))
	note.position = o + nr.position * k
	note.size = nr.size * k
	Tips.set_text(note, _note_body(r))
	note.add_theme_color_override("default_color", NOTE_INK)
	# A anotação nunca passa da caixa: a letra encolhe até caber.
	var fs := 30.0
	while fs > 15.0:
		note.add_theme_font_size_override("normal_font_size", roundi(fs * k))
		if note.get_content_height() <= note.size.y:
			break
		fs -= 2.0


func _note_head(r: Dictionary) -> String:
	match str(r["kind"]):
		"card":
			return UiKit.type_line(r["cd"])
		"mod":
			return tr("UI_LEDGER_MOD_TYPE")
		"relic":
			var rel: Dictionary = sim.data.relics.get(str(r["item"]["id"]), {})
			return tr("UI_SHOP_RELIC").format({"r": tr("RARITY_" + str(rel.get("rarity", "common")))})
	return ""


func _note_body(r: Dictionary) -> String:
	var it: Dictionary = r["item"]
	match str(r["kind"]):
		"card":
			return UiKit.card_desc(r["cd"], int(r["lv"]))
		"mod":
			return tr("MODDESC_" + str(it["mod"]))
		"relic":
			return tr("RELD_" + str(it["id"]))
		"pick_upgrade":
			return tr("UI_LEDGER_D_upgrade")
		"pick_remove":
			return tr("UI_LEDGER_D_remove").format({"s": int(sim.data.rules["shop"]["remove_step"])})
	return ""


func _build_pick(of: Dictionary) -> void:
	pick_rows.clear()
	var max_lv := int(sim.data.rules["card_levels"]["max"])
	var seen := {}
	var opts: Array = of["options"]
	for i in opts.size():
		var op: Dictionary = opts[i]
		var ci := _inst(int(op["uid"]))
		var mods: Array = UiKit.mod_ids(ci) if ci else []
		pick_rows.append({"k": i, "cd": sim.data.card(str(op["card"])), "lv": int(op.get("level", 1)), "mods": mods, "ok": true})
		seen["%s/%d/%s" % [op["card"], int(op.get("level", 1)), str(mods)]] = true
	# Subir nível: as cartas já no máximo ficam na lista, apagadas (o baralho inteiro à vista).
	if str(of.get("what", "")) == "upgrade":
		for ci in sim.cards:
			if ci.level < max_lv:
				continue
			var mods: Array = UiKit.mod_ids(ci)
			var key := "%s/%d/%s" % [ci.def.id, ci.level, str(mods)]
			if seen.has(key):
				continue
			seen[key] = true
			pick_rows.append({"k": -1, "cd": ci.def, "lv": ci.level, "mods": mods, "ok": false})
	desc_sig = ""


func _inst(uid: int) -> Sim.CardInst:
	for ci in sim.cards:
		if ci.uid == uid:
			return ci
	return null


func _pick_sel() -> Dictionary:
	for pr in pick_rows:
		if int(pr["k"]) == hud.selected:
			return pr
	return {}


func _card_rect(after: bool) -> Rect2:
	var ax := PICK.position.x + 40 + 540 + 34
	var aw := PICK.end.x - 40 - ax
	var cx := ax + aw * 0.5 + (225.0 if after else -225.0)
	return Rect2(cx - CARD_W * 0.5, PICK.position.y + 214, CARD_W, CARD_H)


func _sync_pick_children(of: Dictionary) -> void:
	var on := mode == "pick"
	list_clip.visible = on
	var pr := _pick_sel() if on else {}
	desc_l.visible = on and not pr.is_empty()
	desc_r.visible = desc_l.visible
	if not on:
		return
	var lr := _pick_list_rect()
	list_clip.position = o + lr.position * k
	list_clip.size = lr.size * k
	if pr.is_empty():
		return
	var sig := str(pr) + str(k)
	if sig == desc_sig:
		return
	desc_sig = sig
	var up: bool = str(of.get("what", "")) == "upgrade"
	var cd: CardDef = pr["cd"]
	var lv: int = pr["lv"]
	for after in [false, true]:
		var l: RichTextLabel = desc_r if after else desc_l
		var cr := _card_rect(after)
		var dr := Rect2(cr.position + Vector2(18, 18 + ART_H + 40), Vector2(cr.size.x - 36, cr.size.y - ART_H - 18 - 40 - 14))
		l.position = o + dr.position * k
		l.size = dr.size * k
		l.set_meta("center", true)
		var nl: int = mini(lv + 1, int(sim.data.rules["card_levels"]["max"])) if after and up else lv
		Tips.set_text(l, UiKit.card_desc(cd, nl, after and up, pr["mods"]))
		l.add_theme_color_override("default_color", INK)
		l.modulate = Color(0.45, 0.42, 0.4) if after and not up else Color.WHITE
		var fs := 27.0
		while fs > 12.0:
			l.add_theme_font_size_override("normal_font_size", roundi(fs * k))
			if l.get_content_height() <= l.size.y:
				break
			fs -= 1.5


# ---------------------------------------------------------------- desenho: ajudantes

## Quadro inteiro em coordenadas de 1920x1080.
func _S() -> void:
	draw_set_transform(o, 0.0, Vector2(k, k))


## Quadro local em torno de c (coordenadas do quadro), girado r radianos e escalado s.
func _L(c: Vector2, r := 0.0, s := 1.0) -> void:
	draw_set_transform(o + c * k, r, Vector2(k * s, k * s))


## Texto: p = ponto da linha de base (quadro). Fonte no tamanho final da tela (nítida em qualquer escala).
func _txt(p: Vector2, s: String, f: Font, fs: float, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0, r := 0.0) -> void:
	draw_set_transform(o + p * k, r, Vector2.ONE)
	draw_string(f, Vector2.ZERO, s, align, w * k if w > 0.0 else -1.0, roundi(fs * k), col)
	_S()


## Texto num quadro local já girado (centro c, giro r): lp é o ponto local da linha de base.
func _txt_in(c: Vector2, r: float, lp: Vector2, s: String, f: Font, fs: float, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	var m := Transform2D(r, o + c * k + (lp * k).rotated(r))
	draw_set_transform_matrix(m)
	draw_string(f, Vector2.ZERO, s, align, w * k if w > 0.0 else -1.0, roundi(fs * k), col)
	_S()


func _tw(s: String, f: Font, fs: float) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * k)).x / k


func _fit(s: String, f: Font, fs: float, room: float, lo: float) -> float:
	var z := fs
	while z > lo and _tw(s, f, z) > room:
		z -= 1.0
	return z


func _rrect(r: Rect2, col: Color, rad: float, border := 0.0, bcol := Color.TRANSPARENT, filled := true) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col if filled else Color.TRANSPARENT
	sb.draw_center = filled
	sb.set_corner_radius_all(int(rad))
	sb.corner_detail = 6
	if border > 0.0:
		sb.set_border_width_all(int(border))
		sb.border_color = bcol
	sb.anti_aliasing = true
	draw_style_box(sb, r)


## Faixa com degradê horizontal (cores nas paradas xs, de 0 a 1).
func _hgrad(r: Rect2, xs: Array, cols: Array) -> void:
	for i in xs.size() - 1:
		var x0: float = r.position.x + r.size.x * float(xs[i])
		var x1: float = r.position.x + r.size.x * float(xs[i + 1])
		draw_polygon(PackedVector2Array([Vector2(x0, r.position.y), Vector2(x1, r.position.y), Vector2(x1, r.end.y), Vector2(x0, r.end.y)]),
			PackedColorArray([cols[i], cols[i + 1], cols[i + 1], cols[i]]))


func _vgrad(r: Rect2, a: Color, b: Color) -> void:
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([a, a, b, b]))


func _bez(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, n := 10) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(1, n + 1):
		var u := float(i) / n
		var v := 1.0 - u
		out.append(p0 * v * v * v + p1 * 3.0 * v * v * u + p2 * 3.0 * v * u * u + p3 * u * u * u)
	return out


func _dotted(a: Vector2, b: Vector2, col: Color, step := 9.0, rad := 1.6) -> void:
	var n := int((b.x - a.x) / step)
	for i in n:
		draw_circle(Vector2(a.x + step * (i + 0.5), a.y), rad, col)


func _coin(c: Vector2, r: float) -> void:
	draw_circle(c, r, Color("6e4c10"))
	draw_circle(c, r * 0.82, Color("d9a02f"))
	draw_circle(c + Vector2(-r * 0.25, -r * 0.28), r * 0.4, Color(1.0, 0.95, 0.7, 0.8))


func _stamp(c: Vector2, word: String, fs: float) -> void:
	var w := _tw(word, f_disp, fs) + fs * 0.7
	var h := fs * 1.3
	var r := deg_to_rad(-12.0)
	_L(c, r)
	_rrect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(0.94, 0.89, 0.77, 0.9), fs * 0.2, maxf(2.0, fs * 0.1), WAX)
	_txt_in(c, r, Vector2(-w * 0.5, fs * 0.36), word, f_disp, fs, WAX, HORIZONTAL_ALIGNMENT_CENTER, w)
	_S()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if sim == null or (shop_obj == null and mode == "shop"):
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.035, 0.03, 0.35))
	_S()
	_draw_book()
	if shop_obj != null:
		_draw_left()
		_draw_right()
	if mode == "shop":
		_draw_keys()
	if mode == "pick":
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.024, 0.016, 0.78))
		_S()
		_draw_pick()
	_draw_toast()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_book() -> void:
	var book := Rect2(40, 24, 1780, 980)
	_rrect(Rect2(book.position + Vector2(0, 24), book.size), Color(0, 0, 0, 0.45), 30)
	_rrect(book, Color("33200f"), 24)
	_vgrad(Rect2(book.position + Vector2(24, 4), Vector2(book.size.x - 48, 10)), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.0))
	for pg in [[LP, LS, true], [RP, RS, false]]:
		var pos: Vector2 = pg[0]
		var sz: Vector2 = pg[1]
		var r := Rect2(pos, sz)
		_hgrad(r, [0.0, 0.09, 0.91, 1.0], [Color("d6bd84"), Color("e4cf9a"), Color("e4cf9a"), Color("cfb479")])
		# Pauta azul a cada 43 px.
		var y := pos.y + 41.0
		while y < r.end.y:
			draw_line(Vector2(pos.x, y + 1), Vector2(r.end.x, y + 1), Color(0.27, 0.35, 0.55, 0.22), 2.0)
			y += 43.0
		# Sombra da lombada e das bordas.
		var left: bool = pg[2]
		var sx := r.end.x if left else pos.x
		var dir := -1.0 if left else 1.0
		draw_polygon(PackedVector2Array([Vector2(sx, pos.y), Vector2(sx + dir * 70, pos.y), Vector2(sx + dir * 70, r.end.y), Vector2(sx, r.end.y)]),
			PackedColorArray([Color(0.31, 0.2, 0.08, 0.55), Color(0.31, 0.2, 0.08, 0.0), Color(0.31, 0.2, 0.08, 0.0), Color(0.31, 0.2, 0.08, 0.55)]))
		_vgrad(Rect2(pos, Vector2(sz.x, 40)), Color(0.47, 0.31, 0.12, 0.3), Color(0.47, 0.31, 0.12, 0.0))
		_vgrad(Rect2(pos + Vector2(0, sz.y - 40), Vector2(sz.x, 40)), Color(0.47, 0.31, 0.12, 0.0), Color(0.47, 0.31, 0.12, 0.3))
		# Margem vermelha dupla.
		var mx := pos.x + 34.0 if left else r.end.x - 34.0
		for dx in [0.0, 4.0]:
			draw_line(Vector2(mx + dx, pos.y), Vector2(mx + dx, r.end.y), Color(0.75, 0.24, 0.2, 0.55), 2.0)
	# Manchas de café.
	for st in [[LP + Vector2(905, 805), 105.0, 1.0], [LP + Vector2(105, 95), 75.0, 0.7]]:
		draw_arc(st[0], st[1], 0.0, TAU, 72, Color(0.43, 0.24, 0.08, 0.22 * float(st[2])), 12.0, true)
		draw_arc(st[0] + Vector2(3, 2), float(st[1]) - 9.0, 0.4, 4.6, 48, Color(0.43, 0.24, 0.08, 0.1 * float(st[2])), 5.0, true)


func _draw_left() -> void:
	_txt(LP + Vector2(70, 66), tr("UI_LEDGER_TITLE"), f_disp, 42, INK)
	_txt(LP + Vector2(72, 108), tr("UI_LEDGER_SUB"), f_hand, 25, BROWN)
	# Rabisco da balança no canto.
	_L(LP + Vector2(LS.x - 270, 24))
	var ink := Color(INK.r, INK.g, INK.b, 0.8)
	for seg in [[Vector2(110, 20), Vector2(110, 90)], [Vector2(70, 90), Vector2(150, 90)], [Vector2(110, 24), Vector2(60, 38)], [Vector2(110, 24), Vector2(160, 38)]]:
		draw_line(seg[0], seg[1], ink, 3.0, true)
	for cx in [60.0, 160.0]:
		draw_polyline(PackedVector2Array([Vector2(cx, 38), Vector2(cx - 18, 72), Vector2(cx + 18, 72), Vector2(cx, 38)]), ink, 3.0, true)
	draw_arc(Vector2(110, 16), 6.0, 0.0, TAU, 16, ink, 3.0, true)
	_S()
	var foc := _focus_row()
	for r in rows:
		if r["kind"] == "card":
			_draw_card_row(r, is_same(r, foc))
	# Registro do dia.
	var ly := LP.y + 690.0
	_txt(Vector2(LP.x + 70, ly + 30), tr("UI_LEDGER_LOG"), f_disp, 28, INK)
	draw_line(Vector2(LP.x + 70, ly + 42), Vector2(LP.x + LS.x - 70, ly + 42), INK, 3.0)
	for i in log_lines.size():
		var e: Dictionary = log_lines[i]
		var full: String = e["text"] + ("  —  " + e["minus"] if e["minus"] != "" else "")
		var shown := maxi(0, int((t - float(e["t"])) * 22.0))
		var by := ly + 82.0 + i * 43.0
		var txt: String = e["text"]
		var fs := _fit(full, f_hand, 27, LS.x - 150, 16)
		var part := txt.left(mini(shown, txt.length()))
		_txt(Vector2(LP.x + 70, by), part, f_hand, fs, LOG_INK)
		if shown > txt.length() and e["minus"] != "":
			_txt(Vector2(LP.x + 70 + _tw(txt + "  —  ", f_hand, fs), by), str(e["minus"]).left(shown - txt.length()), f_hand, fs, WAX)
			_txt(Vector2(LP.x + 70 + _tw(txt, f_hand, fs), by), "  —  ", f_hand, fs, LOG_INK)
	# Ouro (o único lugar) e tamanho do baralho.
	var pulse := clampf(1.0 - (t - gold_pulse) / 0.6, 0.0, 1.0)
	var gtxt := str(int(sim.gold))
	var gw := 44.0 + _tw(gtxt, f_body, 24) + 18.0
	var gr := Rect2(LP + Vector2(70, LS.y - 70), Vector2(gw, 46))
	var sc := 1.0 + 0.18 * sin(pulse * PI)
	_L(gr.get_center(), 0.0, sc)
	var lr := Rect2(-gr.size * 0.5, gr.size)
	if pulse > 0.0:
		_rrect(lr, Color(RED, pulse), 23)
	_chip(lr, BLUE.lerp(Color.WHITE, pulse))
	_coin(lr.position + Vector2(24, 23), 10)
	_S()
	_txt_in(gr.get_center(), 0.0, Vector2(lr.position.x + 40, 9) * sc, gtxt, f_body, 24 * sc, BLUE.lerp(Color.WHITE, pulse))
	var dtxt := tr("UI_LEDGER_DECK").format({"n": sim.cards.size()})
	var dr := Rect2(gr.end.x + 16, gr.position.y, _tw(dtxt, f_body, 24) + 36, 46)
	_chip(dr, BLUE)
	_txt(dr.position + Vector2(18, 32), dtxt, f_body, 24, BLUE)


## Contorno tracejado de pílula (os chips do ouro e do baralho).
func _chip(r: Rect2, col: Color) -> void:
	var rad := r.size.y * 0.5
	var a := r.position + Vector2(rad, 0)
	var b := Vector2(r.end.x - rad, r.position.y)
	draw_dashed_line(a, b, col, 3.0, 8.0)
	draw_dashed_line(a + Vector2(0, r.size.y), b + Vector2(0, r.size.y), col, 3.0, 8.0)
	draw_arc(r.position + Vector2(rad, rad), rad, PI * 0.5, PI * 1.5, 14, col, 3.0, true)
	draw_arc(Vector2(r.end.x - rad, r.position.y + rad), rad, -PI * 0.5, PI * 0.5, 14, col, 3.0, true)


func _shake(r: Dictionary) -> float:
	var u := (t - float(r["shake"])) / 0.4
	if u < 0.0 or u > 1.0:
		return 0.0
	return sin(u * TAU * 2.0) * 10.0 * (1.0 - u)


func _hot_band(rr: Rect2) -> void:
	_hgrad(rr, [0.0, 0.05, 0.95, 1.0], [Color(1, 0.84, 0.31, 0.0), Color(1, 0.84, 0.31, 0.5), Color(1, 0.84, 0.31, 0.38), Color(1, 0.84, 0.31, 0.0)])
	# Dedo de tinta apontando a linha.
	var c := Vector2(rr.position.x - 26, rr.get_center().y)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-22, -9), c + Vector2(4, -9), c + Vector2(4, -15), c + Vector2(20, 0),
		c + Vector2(4, 15), c + Vector2(4, 9), c + Vector2(-22, 9)]), WAX)


func _draw_card_row(r: Dictionary, hot: bool) -> void:
	var rr: Rect2 = r["rect"]
	rr.position.x += _shake(r)
	var sold: bool = r["sold"]
	if hot and not sold:
		_hot_band(Rect2(rr.position + Vector2(10, 0), rr.size - Vector2(10, 0)))
	draw_line(Vector2(rr.position.x, rr.end.y), rr.end, Color(0.24, 0.16, 0.08, 0.4), 2.0)
	# Esboço colado: papel, fita, desenho e custo. Sem nome, sem preço.
	var skh := minf(152.0, rr.size.y - 24.0)
	var skw := skh * 250.0 / 152.0
	var c := Vector2(rr.position.x + 40 + skw * 0.5, rr.get_center().y)
	var rot := deg_to_rad(0.0 if hot and not sold else float(r["rot"]))
	_L(c, rot, 1.06 if hot and not sold else 1.0)
	var pr := Rect2(-skw * 0.5, -skh * 0.5, skw, skh)
	draw_rect(Rect2(pr.position + Vector2(3, 6), pr.size), Color(0, 0, 0, 0.3))
	draw_rect(pr, Color("f7efd8"))
	draw_rect(pr, Color(0.24, 0.16, 0.08, 0.4), false, 1.0)
	var ar := Rect2(pr.position + Vector2(10, 10), pr.size - Vector2(20, 28))
	draw_rect(ar, Color("f1e2b8"))
	draw_rect(ar.grow(-ar.size.y * 0.12), Color(1.0, 0.97, 0.86, 0.6))
	draw_rect(ar, Color(0.24, 0.16, 0.08, 0.25), false, 1.0)
	var cd: CardDef = r["cd"]
	var tex := UiDiario.card_tex(cd.id)
	var dim := Color(0.62, 0.6, 0.58) if sold else Color.WHITE
	if tex:
		_art_fit(self, tex, ar, dim, UiDiario.painted(cd.id))
	draw_set_transform_matrix(Transform2D(rot, o + c * k) * Transform2D(deg_to_rad(-3.0), Vector2(0, pr.position.y) * k).scaled_local(Vector2(k, k)))
	draw_rect(Rect2(-45, -14, 90, 28), Color(0.84, 0.77, 0.55, 0.85))
	_L(c, rot, 1.06 if hot and not sold else 1.0)
	var gem := Rect2(pr.end.x - 36, pr.position.y - 12, 50, 50)
	UiDiario.draw_badge(self, gem, UiDiario.BLOOD, "crystal", float(cd.id.hash() % 7))
	_txt_in(c, rot, (gem.position + Vector2(0, 34)) * (1.06 if hot and not sold else 1.0), str(cd.cost_at(int(r["lv"]))), f_type, 24, Color(1.0, 0.95, 0.88), HORIZONTAL_ALIGNMENT_CENTER, 50)
	if sold:
		_L(c, rot)
		draw_rect(pr, Color(0.3, 0.27, 0.24, 0.3))
		_S()
		_stamp(c, tr("UI_LEDGER_STAMP_SOLD"), 30)
	_S()
	# Linha do livro: nome, pontinhos e preço.
	var x0 := rr.position.x + 40 + skw + 40
	_ledger_line(r, Rect2(x0, rr.position.y, rr.end.x - x0 - 10, rr.size.y), 38)


## Nome (com + vermelho), pontinhos e preço circulado; riscado se vendido, vermelho se falta ouro.
func _ledger_line(r: Dictionary, area: Rect2, fs0: float) -> void:
	var sold: bool = r["sold"]
	var poor: bool = not sold and sim.gold + 0.0001 < float(r["price"])
	var ptxt := str(int(r["price"]))
	var pw := 30.0 + _tw(ptxt, f_hand, fs0 * 1.05) + 24.0
	var nm: String = r["name"]
	var plus: String = r["plus"]
	var room := area.size.x - pw - 40.0
	var fs := _fit(nm + (" " + plus if plus != "" else ""), f_hand, fs0, room, fs0 * 0.55)
	var base := area.get_center().y + fs * 0.32
	var col := BLUE if not sold else Color(BLUE, 0.6)
	_txt(Vector2(area.position.x, base), nm, f_hand, fs, col)
	var nw := _tw(nm, f_hand, fs)
	if plus != "":
		_txt(Vector2(area.position.x + nw + fs * 0.25, base), plus, f_hand, fs, WAX)
		nw += fs * 0.25 + _tw(plus, f_hand, fs)
	if sold:
		draw_line(Vector2(area.position.x - 4, base - fs * 0.3), Vector2(area.position.x + nw + 4, base - fs * 0.34), WAX, 4.0, true)
	var px := area.end.x - pw
	_dotted(Vector2(area.position.x + nw + 14, base - 2), Vector2(px - 12, base - 2), Color(BLUE, 0.5))
	var pr := Rect2(px, area.get_center().y - fs0 * 0.62, pw, fs0 * 1.24)
	var pc := RED if poor else BLUE
	if sold:
		pc = Color(BLUE, 0.45)
	_L(pr.get_center(), deg_to_rad(-2.0))
	var lr := Rect2(-pr.size * 0.5, pr.size)
	if poor:
		_rrect(lr, Color(0.75, 0.2, 0.16, 0.12), 8)
	_rrect(lr, Color.TRANSPARENT, 8, 3.0, pc, false)
	_coin(Vector2(lr.position.x + 22, 0), fs0 * 0.24)
	_txt_in(pr.get_center(), deg_to_rad(-2.0), Vector2(lr.position.x + 38, fs0 * 0.34), ptxt, f_hand, fs0 * 1.05, pc)
	_S()
	if sold and r["kind"] != "card":
		_stamp(Vector2(area.end.x - pw - 76, area.get_center().y), tr("UI_LEDGER_STAMP_SOLD" if r["kind"] == "relic" else "UI_LEDGER_STAMP_DONE"), 24)


func _draw_right() -> void:
	_txt(RP + Vector2(56, 66), tr("UI_LEDGER_SERV"), f_disp, 42, INK)
	_txt(RP + Vector2(58, 108), tr("UI_LEDGER_SERV_SUB"), f_hand, 25, BROWN)
	var foc := _focus_row()
	for r in rows:
		if r["kind"] == "card":
			continue
		var rr: Rect2 = r["rect"]
		rr.position.x += _shake(r)
		var hot: bool = is_same(r, foc) and not r["sold"]
		var rel: bool = r["kind"] == "relic"
		if rel:
			draw_rect(rr, Color(1.0, 0.92, 0.67, 0.35))
			draw_rect(rr, BROWN, false, 2.0)
			draw_rect(rr.grow(-5), BROWN, false, 1.5)
		if hot:
			_hot_band(rr.grow_individual(0, -4, 0, -4))
		var isz := 84.0 if rel else 60.0
		var ir := Rect2(rr.position.x + (18 if rel else 4), rr.get_center().y - isz * 0.5, isz, isz)
		_icon(str(r["kind"]), ir, r["sold"])
		var x0 := ir.end.x + 14
		_ledger_line(r, Rect2(x0, rr.position.y, rr.end.x - x0 - (30 if rel else 4), rr.size.y), 32 if rel else 31)
	_draw_note(foc)
	_draw_seal()
	_draw_quill()


## Ícones a nanquim (traços no espaço 100x100 da maquete).
func _icon(kind: String, r: Rect2, sold: bool) -> void:
	_L(r.position, 0.0, r.size.x / 100.0)
	var ink := INK if not sold else Color(INK, 0.45)
	var a := 1.0 if not sold else 0.45
	match kind:
		"pick_upgrade":
			draw_line(Vector2(50, 82), Vector2(50, 28), ink, 5.0, true)
			draw_polyline(PackedVector2Array([Vector2(28, 50), Vector2(50, 26), Vector2(72, 50)]), ink, 5.0, true)
			draw_line(Vector2(30, 90), Vector2(70, 90), ink, 5.0, true)
			draw_circle(Vector2(76, 22), 14, Color(WAX, a))
			draw_line(Vector2(76, 15), Vector2(76, 29), Color("f3e6c4"), 4.0, true)
			draw_line(Vector2(69, 22), Vector2(83, 22), Color("f3e6c4"), 4.0, true)
		"mod":
			draw_colored_polygon(PackedVector2Array([Vector2(30, 68), Vector2(70, 68), Vector2(78, 86), Vector2(22, 86)]), Color(0.42, 0.25, 0.63, 0.85 * a))
			draw_line(Vector2(40, 12), Vector2(60, 12), ink, 5.0, true)
			draw_polyline(PackedVector2Array([Vector2(44, 12), Vector2(44, 34), Vector2(22, 80), Vector2(24, 88), Vector2(30, 90), Vector2(70, 90),
				Vector2(76, 88), Vector2(78, 80), Vector2(56, 34), Vector2(56, 12)]), ink, 5.0, true)
			draw_circle(Vector2(44, 52), 4, Color(0.42, 0.25, 0.63, a))
			draw_circle(Vector2(58, 44), 3, Color(0.42, 0.25, 0.63, a))
		"pick_remove":
			var fl := PackedVector2Array([Vector2(50, 90)])
			fl.append_array(_bez(Vector2(50, 90), Vector2(24, 82), Vector2(20, 56), Vector2(38, 40), 6))
			fl.append_array(_bez(Vector2(38, 40), Vector2(38, 52), Vector2(46, 54), Vector2(48, 46), 4))
			fl.append_array(_bez(Vector2(48, 46), Vector2(44, 28), Vector2(52, 18), Vector2(58, 10), 5))
			fl.append_array(_bez(Vector2(58, 10), Vector2(60, 28), Vector2(80, 36), Vector2(78, 58), 6))
			fl.append_array(_bez(Vector2(78, 58), Vector2(78, 76), Vector2(64, 86), Vector2(50, 90), 6))
			draw_colored_polygon(fl, Color(0.88, 0.54, 0.16, a))
			draw_polyline(fl, ink, 5.0, true)
			draw_colored_polygon(PackedVector2Array([Vector2(50, 84), Vector2(40, 78), Vector2(38, 70), Vector2(44, 62), Vector2(48, 68), Vector2(52, 64),
				Vector2(56, 56), Vector2(58, 52), Vector2(64, 64), Vector2(62, 76)]), Color(1.0, 0.83, 0.35, a))
		"relic":
			draw_circle(Vector2(50, 50), 43, Color(0.16, 0.11, 0.07, a))
			draw_arc(Vector2(50, 50), 43, 0.0, TAU, 40, Color(0.85, 0.63, 0.18, a), 4.0, true)
			var eye := PackedVector2Array()
			for i in 17:
				var u := float(i) / 16.0
				eye.append(Vector2(12 + 76 * u, 50 - 40 * u * (1.0 - u) * 2.0))
			for i in range(15, 0, -1):
				var u := float(i) / 16.0
				eye.append(Vector2(12 + 76 * u, 50 + 40 * u * (1.0 - u) * 2.0))
			draw_colored_polygon(eye, Color(0.95, 0.9, 0.77, a))
			draw_polyline(eye + PackedVector2Array([eye[0]]), ink, 3.0, true)
			draw_circle(Vector2(50, 50), 17, Color(0.89, 0.71, 0.35, a))
			draw_arc(Vector2(50, 50), 17, 0.0, TAU, 24, ink, 3.0, true)
			draw_circle(Vector2(50, 50), 7, Color(0.1, 0.07, 0.16, a))
			draw_circle(Vector2(45, 45), 2.5, Color(1, 1, 1, a))
	_S()


func _draw_note(foc: Dictionary) -> void:
	if foc.is_empty():
		return
	var r := note_rect
	draw_rect(Rect2(r.position + Vector2(2, 6), r.size), Color(0, 0, 0, 0.3))
	draw_rect(r, Color("f3e9c6"))
	var y := r.position.y + 40.0
	while y < r.end.y - 4.0:
		draw_line(Vector2(r.position.x + 4, y), Vector2(r.end.x, y), Color(0.24, 0.35, 0.63, 0.3), 2.0)
		y += 42.0
	draw_line(r.position + Vector2(2, 0), Vector2(r.position.x + 2, r.end.y), Color("c05040"), 4.0)
	var head := _note_head(foc)
	if head != "":
		_txt(r.position + Vector2(34, 36), head.to_upper(), f_body, 19, Color(INK, 0.7))
	var short := int(ceil(float(foc["price"]) - sim.gold))
	var line := tr("UI_LEDGER_BUY_PAD" if hud.pad else "UI_LEDGER_BUY") if short <= 0 else tr("UI_LEDGER_SHORT").format({"n": short})
	_txt(Vector2(r.position.x + 34, r.end.y - 14), line, f_body, 21, BROWN if short <= 0 else RED)


func _draw_seal() -> void:
	var c := _seal_c()
	var hot := seal_hot and mode == "shop"
	var rot := deg_to_rad(-6.0) if hot else 0.0
	_L(c, rot, 1.05 if hot else 1.0)
	draw_circle(Vector2(0, 5), 76, Color(0, 0, 0, 0.4))
	draw_colored_polygon(UiDiario.blob(Vector2.ZERO, 77, 2.3, 40), Color("7a1f1a") if not hot else Color("8a2a22"))
	var hi := Vector2(-22, -26)
	for i in 7:
		var u := float(i) / 7.0
		draw_circle(hi * u, 72.0 * (1.0 - u * 0.82), Color("7a1f1a").lerp(Color("d4574a") if hot else Color("c0453a"), u))
	draw_arc(Vector2.ZERO, 68, 0.0, TAU, 48, Color(0, 0, 0, 0.15), 6.0, true)
	_S()
	var words := tr("UI_SHOP_LEAVE").split(" ")
	var l1 := " ".join(words.slice(0, maxi(1, words.size() / 2)))
	var l2 := " ".join(words.slice(maxi(1, words.size() / 2)))
	var fs := _fit(l1 if l1.length() > l2.length() else l2, f_disp, 25, 118, 14)
	_txt_in(c, rot, Vector2(-70, -4), l1, f_disp, fs, Color("ffe6c0"), HORIZONTAL_ALIGNMENT_CENTER, 140)
	_txt_in(c, rot, Vector2(-70, fs + 0.0), l2, f_disp, fs, Color("ffe6c0"), HORIZONTAL_ALIGNMENT_CENTER, 140)


func _draw_quill() -> void:
	var writing := false
	for e in log_lines:
		var u := (t - float(e["t"])) * 22.0
		if u >= 0.0 and u < String(e["text"]).length() + String(e["minus"]).length() + 5:
			writing = true
	var base := RP + Vector2(RS.x - 152, RS.y - 200)
	var wob := sin(t * 18.0) * 0.5 + 0.5 if writing else 0.3
	var ang := deg_to_rad(lerpf(-10.0, 2.0, wob)) if writing else deg_to_rad(-4.0)
	var dx := lerpf(-30.0, 10.0, wob) if writing else 0.0
	# Tinteiro parado; a pena gira em torno do bico.
	_L(base)
	draw_colored_polygon(PackedVector2Array([Vector2(30, 170), Vector2(120, 170), Vector2(112, 226), Vector2(38, 226)]), Color("1b1228"))
	draw_polyline(PackedVector2Array([Vector2(30, 170), Vector2(120, 170), Vector2(112, 226), Vector2(38, 226), Vector2(30, 170)]), INK, 3.0, true)
	var el := PackedVector2Array()
	for i in 24:
		el.append(Vector2(75, 170) + Vector2(cos(TAU * i / 24.0) * 45, sin(TAU * i / 24.0) * 8))
	draw_colored_polygon(el, Color("0d0912"))
	draw_set_transform_matrix(Transform2D(0.0, o + base * k) * Transform2D(ang, Vector2(60 + dx, 150) * k) * Transform2D(0.0, Vector2(-60, -150) * k).scaled_local(Vector2(k, k)))
	var fe := PackedVector2Array([Vector2(20, 20)])
	fe.append_array(_bez(Vector2(20, 20), Vector2(60, 0), Vector2(120, 30), Vector2(130, 80), 8))
	fe.append_array(_bez(Vector2(130, 80), Vector2(100, 76), Vector2(78, 86), Vector2(60, 120), 6))
	fe.append_array(_bez(Vector2(60, 120), Vector2(50, 80), Vector2(36, 50), Vector2(20, 20), 6))
	draw_colored_polygon(fe, Color("f3e6c4"))
	draw_polyline(fe, INK, 3.0, true)
	var sp := PackedVector2Array([Vector2(26, 28)])
	sp.append_array(_bez(Vector2(26, 28), Vector2(60, 50), Vector2(80, 80), Vector2(62, 118), 8))
	draw_polyline(sp, INK, 2.0, true)
	draw_line(Vector2(62, 118), Vector2(48, 170), INK, 3.0, true)
	_S()


func _draw_keys() -> void:
	var band := Rect2(0, H - 60, W, 60)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(0, o.y + band.position.y * k, size.x, size.y - o.y - band.position.y * k), Color(0.03, 0.02, 0.015, 0.92))
	_S()
	var items: Array = [["LB RB" if hud.pad else "← ↑ ↓ →", "UI_LEDGER_K_MOVE"], ["A" if hud.pad else "Enter", "UI_LEDGER_K_BUY"],
		["B" if hud.pad else "0", "UI_LEDGER_K_LEAVE"]]
	var widths: Array = []
	var total := 0.0
	for it in items:
		var w := _tw(it[0], f_body, 20) + 18 + 8 + _tw(tr(it[1]), f_med, 22)
		widths.append(w)
		total += w
	total += 40.0 * (items.size() - 1)
	var x := (W - total) * 0.5
	for i in items.size():
		var kw := _tw(items[i][0], f_body, 20) + 18
		var kr := Rect2(x, band.position.y + 16, kw, 30)
		_rrect(Rect2(kr.position + Vector2(0, 2), kr.size), Color("8a7448"), 6)
		_rrect(kr, Color("e7d7b0"), 6)
		_txt(kr.position + Vector2(9, 22), items[i][0], f_body, 20, INK)
		_txt(Vector2(kr.end.x + 8, band.position.y + 38), tr(items[i][1]), f_med, 22, Color("c9b99a"))
		x += float(widths[i]) + 40.0


func _draw_toast() -> void:
	var u := t - toast_t
	if u > 2.2 or toast_text == "":
		return
	var a := clampf(u / 0.25, 0.0, 1.0) * clampf((2.2 - u) / 0.3, 0.0, 1.0)
	var w := _tw(toast_text, f_body, 28) + 56
	var r := Rect2((W - w) * 0.5, H - 78 - 54 + (1.0 - a) * 30.0, w, 54)
	_S()
	_rrect(r, Color(Color("5a1d18") if toast_bad else Color("2a2018"), a), 27, 2.0, Color(Color("e0584a") if toast_bad else Color("b99a55"), a))
	_txt(r.position + Vector2(28, 37), toast_text, f_body, 28, Color(Color("ffd1c8") if toast_bad else Color("ffd978"), a))


# ---------------------------------------------------------------- passo do baralho

func _draw_pick() -> void:
	if pick_obj == null:
		return
	var of: Dictionary = pick_obj
	var up: bool = str(of.get("what", "")) == "upgrade"
	var P := PICK
	_rrect(Rect2(P.position + Vector2(0, 20), P.size), Color(0, 0, 0, 0.6), 16)
	_vgrad(P.grow(-4), Color("efe0ba"), Color("dcc994"))
	_rrect(P, Color.TRANSPARENT, 12, 6.0, Color("3a2c1d"), false)
	# Cabeçalho: nome do serviço, o que escolher, ouro antes → depois e baralho.
	var what := str(of.get("what", "upgrade"))
	var title := tr("UI_PICK_" + what)
	_txt(P.position + Vector2(40, 70), title, f_disp, 46, INK)
	var tw := _tw(title, f_disp, 46)
	_txt(P.position + Vector2(40 + tw + 24, 68), tr("UI_LEDGER_PICK_SUB_" + what), f_hand, 27, BROWN)
	var price := int(of.get("price", 0))
	var n := sim.cards.size()
	var gtxt := "%d → %d · %s" % [int(sim.gold), int(sim.gold) - price, tr("UI_LEDGER_DECKN").format({"n": n}) + ("" if up else " → %d" % (n - 1))]
	var gw := _tw(gtxt, f_body, 25)
	_coin(Vector2(P.end.x - 40 - gw - 18, P.position.y + 60), 10)
	_txt(Vector2(P.end.x - 40 - gw, P.position.y + 68), gtxt, f_body, 25, BROWN)
	draw_dashed_line(P.position + Vector2(40, 92), Vector2(P.end.x - 40, P.position.y + 92), Color(0.24, 0.16, 0.08, 0.5), 3.0, 10.0)
	# Antes → depois.
	var pr := _pick_sel()
	var ax := P.position.x + 40 + 540 + 34
	var aw := P.end.x - 40 - ax
	if pr.is_empty():
		_txt(Vector2(ax, P.position.y + 380), tr("UI_LEDGER_NONE"), f_hand, 30, BROWN, HORIZONTAL_ALIGNMENT_CENTER, aw)
	else:
		var cd: CardDef = pr["cd"]
		var lv: int = pr["lv"]
		var max_lv := int(sim.data.rules["card_levels"]["max"])
		var cname := tr("CARD_" + cd.id)
		_txt(Vector2(ax, P.position.y + 150), cname, f_disp, _fit(cname, f_disp, 44, aw - 20, 26), INK, HORIZONTAL_ALIGNMENT_CENTER, aw)
		for after in [false, true]:
			var cr := _card_rect(after)
			_txt(Vector2(cr.position.x, cr.position.y - 18), tr("UI_LEDGER_AFTER" if after else "UI_LEDGER_BEFORE"), f_hand, 30, NOTE_INK, HORIZONTAL_ALIGNMENT_CENTER, cr.size.x)
			_deck_card(cr, cd, mini(lv + 1, max_lv) if after and up else lv, pr["mods"], after and not up)
		_txt(Vector2(ax + aw * 0.5 - 40, _card_rect(false).get_center().y + 26), "→", f_disp, 80, WAX, HORIZONTAL_ALIGNMENT_CENTER, 80)
		_txt(Vector2(ax, P.end.y - 22 - 62 - 40), tr("UI_LEDGER_CAP_" + what), f_hand, 32, NOTE_INK, HORIZONTAL_ALIGNMENT_CENTER, aw)
	# Rodapé: dica e botões.
	var fy := P.end.y - 22 - 62 - 14
	draw_dashed_line(Vector2(P.position.x + 40, fy), Vector2(P.end.x - 40, fy), Color(0.24, 0.16, 0.08, 0.5), 3.0, 10.0)
	_txt(Vector2(P.position.x + 40, P.end.y - 22 - 22), tr("UI_LEDGER_PICK_HINT_PAD" if hud.pad else "UI_LEDGER_PICK_HINT"), f_med, 21, Color("6b5a40"))
	for i in 2:
		var br := _btn_rect(i)
		var ok := i == 1
		var hot := btn_hot == i
		_rrect(br, Color("2a2018") if ok else Color("efe0ba"), 8, 3.0, Color("b99a55") if ok else Color("3a2c1d"))
		if hot:
			_rrect(br.grow(3), Color.TRANSPARENT, 10, 3.0, RED, false)
		_txt(Vector2(br.position.x, br.position.y + 42), tr("UI_LEDGER_CONFIRM" if ok else "UI_LEDGER_BACK"), f_disp, 30, Color("ffd978") if ok else INK, HORIZONTAL_ALIGNMENT_CENTER, br.size.x)


## Desenha a arte da carta: a pintada preenche a caixa (recorta o excesso, sem faixas claras dos lados);
## o retrato 3D (fundo transparente) fica inteiro, centralizado.
func _art_fit(ci: CanvasItem, tex: Texture2D, r: Rect2, col: Color, cover: bool) -> void:
	var ts := tex.get_size()
	if cover:
		var f := maxf(r.size.x / ts.x, r.size.y / ts.y)
		var src := r.size / f
		ci.draw_texture_rect_region(tex, r, Rect2((ts - src) * 0.5, src), col)
	else:
		var f2 := minf(r.size.x / ts.x, r.size.y / ts.y)
		ci.draw_texture_rect(tex, Rect2(r.get_center() - ts * f2 * 0.5, ts * f2), false, col)


## Carta do baralho sem título (o nome está só na lista): custo, desenho, tipo e o texto (RichTextLabel filho).
func _deck_card(r: Rect2, cd: CardDef, lv: int, mods: Array, burnt: bool) -> void:
	_rrect(Rect2(r.position + Vector2(0, 10), r.size), Color(0, 0, 0, 0.35), 12)
	_vgrad(r.grow(-2), Color("efe0ba"), Color("dcc994"))
	_rrect(r, Color.TRANSPARENT, 10, 3.0, UiDiario.type_spec(cd)[0].darkened(0.3), false)
	var ar := Rect2(r.position + Vector2(15, 18), Vector2(r.size.x - 30, ART_H))
	draw_rect(ar, Color("f7efd8"))
	draw_rect(ar, INK, false, 2.0)
	var tex := UiDiario.card_tex(cd.id)
	if tex:
		_art_fit(self, tex, ar, Color(0.4, 0.38, 0.36) if burnt else Color.WHITE, UiDiario.painted(cd.id))
	var plus := "+".repeat(maxi(0, lv - 1))
	_txt(Vector2(r.position.x, ar.end.y + 28), UiKit.type_line(cd).to_upper() + ("  " + plus if plus != "" else ""), f_body, 16, Color("6b5a40"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if mods.size() > 0:
		var mt := tr("MOD_" + str(mods[0]))
		var mw := _tw(mt, f_body, 17) + 22
		_L(Vector2(r.end.x - mw * 0.5 + 6, r.position.y + 46), deg_to_rad(6.0))
		_rrect(Rect2(-mw * 0.5, -14, mw, 28), Color("2d5b69"), 14, 2.0, Color("99aadd"))
		_txt_in(Vector2(r.end.x - mw * 0.5 + 6, r.position.y + 46), deg_to_rad(6.0), Vector2(-mw * 0.5, 6), mt, f_body, 17, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, mw)
	var cost := maxi(cd.cost_at(lv) - (1 if mods.has("cheap") else 0), 0)
	var gem := Rect2(r.position + Vector2(-12, -8), Vector2(46, 46))
	UiDiario.draw_badge(self, gem, UiDiario.BLOOD, "crystal", 1.0)
	_txt(gem.position + Vector2(0, 32), str(maxi(cost, 0)), f_type, 24, Color(1.0, 0.95, 0.88), HORIZONTAL_ALIGNMENT_CENTER, 46)
	if burnt:
		draw_rect(r, Color(0.1, 0.08, 0.06, 0.55))
		var xr := ar.grow(-14)
		draw_line(xr.position, xr.end, Color(RED, 0.85), 8.0, true)
		draw_line(Vector2(xr.end.x, xr.position.y), Vector2(xr.position.x, xr.end.y), Color(RED, 0.85), 8.0, true)


func _draw_pick_list() -> void:
	if mode != "pick" or sim == null:
		return
	list_clip.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var w := 540.0 - 8.0
	for i in pick_rows.size():
		var pr: Dictionary = pick_rows[i]
		var y := 12.0 + i * (ROW_H + ROW_GAP) - pick_scroll
		if y + ROW_H < 0.0 or y > list_clip.size.y / k:
			continue
		var r := Rect2(2, y, w, ROW_H)
		var sel: bool = pr["ok"] and int(pr["k"]) == hud.selected
		var a := 1.0 if pr["ok"] else 0.4
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("2a2018") if sel else Color(1.0, 0.96, 0.82, 0.5 * a)
		sb.set_border_width_all(2)
		sb.border_color = RED if sel else Color(0.24, 0.16, 0.08, 0.35 * a)
		sb.set_corner_radius_all(6)
		if sel:
			sb.shadow_color = RED
			sb.shadow_size = 3
		list_clip.draw_style_box(sb, r)
		var cd: CardDef = pr["cd"]
		var lv: int = pr["lv"]
		var by0 := (ROW_H - 36.0) * 0.5
		UiDiario.draw_badge(list_clip, Rect2(r.position + Vector2(10, by0), Vector2(36, 36)), UiDiario.BLOOD, "crystal", float(i))
		var cost := maxi(cd.cost_at(lv) - (1 if (pr["mods"] as Array).has("cheap") else 0), 0)
		var tc := Color("f3e6c4") if sel else Color(INK, a)
		_lt(Vector2(r.position.x + 10, y + by0 + 27), str(maxi(cost, 0)), f_type, 20, Color(1, 0.95, 0.88, a), HORIZONTAL_ALIGNMENT_CENTER, 36)
		# Miniatura do desenho.
		var th := Rect2(r.position.x + 56, y + 7, 56, ROW_H - 14)
		list_clip.draw_rect(th, Color(0.97, 0.94, 0.85, a))
		var tex := UiDiario.card_tex(cd.id)
		if tex:
			_art_fit(list_clip, tex, th.grow(-2), Color(1, 1, 1, a), UiDiario.painted(cd.id))
		list_clip.draw_rect(th, Color(INK, 0.7 * a), false, 2.0)
		var nm := tr("CARD_" + cd.id)
		var nx := r.position.x + 126
		_lt(Vector2(nx, y + 31), nm, f_body, 25, tc)
		nx += _tw(nm, f_body, 25) + 8
		var plus := "+".repeat(maxi(0, lv - 1))
		if plus != "":
			_lt(Vector2(nx, y + 31), plus, f_body, 25, Color("b07a10") if not sel else Color("ffd35a"))
		var sub := UiKit.type_line(cd)
		if (pr["mods"] as Array).size() > 0:
			sub += " · " + ", ".join((pr["mods"] as Array).map(func(m): return tr("MOD_" + str(m))))
		_lt(Vector2(r.position.x + 126, y + 56), sub, f_med, 18, Color("c9b99a") if sel else Color(0.42, 0.35, 0.25, a))
		if not pr["ok"]:
			var mx := tr("UI_LEDGER_MAXED").to_upper()
			_lt(Vector2(r.end.x - 14 - _tw(mx, f_med, 16), y + 40), mx, f_med, 16, Color("6b5a40"))
	# Indica que a lista continua.
	var full := 24.0 + pick_rows.size() * (ROW_H + ROW_GAP)
	var vh := list_clip.size.y / k
	if full > vh:
		var bar_h := maxf(40.0, vh * vh / full)
		var by := (vh - bar_h) * pick_scroll / maxf(1.0, full - vh)
		list_clip.draw_rect(Rect2(w + 3, by, 4, bar_h), Color(0.24, 0.16, 0.08, 0.45))


## Texto na lista recortada (coordenadas locais da lista, em unidades do quadro).
func _lt(p: Vector2, s: String, f: Font, fs: float, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	list_clip.draw_set_transform(p * k, 0.0, Vector2.ONE)
	list_clip.draw_string(f, Vector2.ZERO, s, align, w * k if w > 0.0 else -1.0, roundi(fs * k), col)
	list_clip.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
