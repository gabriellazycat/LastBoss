class_name ShopLedger
extends Control
## Loja do mercador (decisão 11/11/2026). Regra do designer: nada repetido na tela. Cada item é uma linha
## (nome, pontinhos, preço); as cartas aparecem como esboços colados (só desenho e custo); tipo e descrição só na
## anotação da margem, do item em foco; o ouro aparece uma vez. Registro do dia = histórico das compras desta visita.
## Escolher a carta de Subir nível ou Tirar carta ("shop_pick" do Sim) abre o passo do baralho por cima do livro,
## com antes → depois. Tudo é desenhado num quadro de 1920x1080 escalado para a tela (a pele Diário fica na tinta).
## O cursor é o hud.selected (índice da opção no Sim), o mesmo que o controle usa com L1/R1 e A no main.gd.

signal chosen(k: int)

const W := 1920.0
const H := 1080.0
const BLUE := Color("5c4630")          # 13/11/2026: a tinta do mapa/cartas no lugar do azul de caderno
const INK := Color("2a2018")
const WAX := Color("8e2f27")
const RED := Color("b3342a")
const BROWN := Color("6b3a10")
const LOG_INK := Color("3a2916")
const NOTE_INK := Color("3a2916")
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
var pick_cards: Array = []            # antes/depois do passo do baralho: as cartas de verdade (molde), não desenho
# A loja é a "Feira do Mascate" (maquete aprovada "Loja B · Mapa da feira"): cada carta é uma barraca na estrada do
# mapa; serviços num painel à direita; a ficha do item em foco no alto à direita.
var fair_hover := -1                  # barraca sob o mouse (índice da opção): só realça; o clique escolhe
var fair_buy := Rect2()               # botão "Comprar" da ficha (quadro)
var buy_hot := false
const FAIR_PO := Vector2(140, 90)     # canto do papel da maquete na tela de 1920x1080
const FAIR_BG_SIZE := Vector2(1688, 948)   # o fundo de feltro (+24 px de margem): vai em (116, 66)
const FAIR_SPOTS := [Vector2(260, 350), Vector2(560, 300), Vector2(860, 360), Vector2(450, 590), Vector2(780, 650)]
const FAIR_PURSE := Rect2(176, 106, 376, 116)   # a bolsa: sempre no mesmo canto (17/11/2026)
const FAIR_FICHA := Rect2(1210, 300, 510, 330)
const FAIR_RED := Color("a8323a")
const FAIR_INK := Color("3a2a1c")
const FAIR_PAPER := Minimap.PAPER        # 26/11/2026: o creme dos botões de feltro
const FAIR_ART_R := 66.0
static var _fair_tex := {}
var fair_bg: Texture2D


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	f_hand = UiDiario.font("hand")
	f_type = UiDiario.font("type")
	f_disp = UiParch.font("title")   # a Fell SC dos nomes das cartas (era Marcellus SC)
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
	_fair_layout(n_cards)
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
			_fair_motion(p)
		elif mode == "shop":
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
		_fair_click(p)
		accept_event()
		return


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
		if mode == "shop":
			return [o + _fair_leave_rect().get_center() * k]
		return [o + (_btn_rect(0).get_center() if mode == "pick" else _seal_c()) * k]
	if mode == "shop":
		return _fair_click_points(kk)
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
	_fair_sync_note(r)
	return


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
	desc_l.visible = false   # o texto agora vem na própria carta (molde)
	desc_r.visible = false
	for pc in pick_cards:
		pc.visible = on and not pr.is_empty()
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
	# Antes → depois com as cartas de verdade (o mesmo molde da mão e das ofertas; rodada de UI 13/11/2026). O desenho
	# antigo era uma carta falsa com uma sombra deslocada embaixo, que parecia outra carta por trás.
	for pc in pick_cards:
		pc.queue_free()
	pick_cards.clear()
	var max_lv := int(sim.data.rules["card_levels"]["max"])
	var names: Array = (pr["mods"] as Array).map(func(m): return tr("MOD_" + str(m)))
	for after in [false, true]:
		var nl: int = mini(lv + 1, max_lv) if after and up else lv
		var cost := maxi(cd.cost_at(nl) - (1 if (pr["mods"] as Array).has("cheap") else 0), 0)
		var cr := _card_rect(after)
		var cw := cr.size.x * k
		var card := UiKit.card(cd, cost, names, "", cw, nl)
		card.position = o + cr.position * k + Vector2(0, maxf(0.0, (cr.size.y * k - card.size.y) * 0.5))
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if after and not up:
			# Tirar carta: o "depois" é a carta riscada, apagada.
			card.modulate = Color(0.5, 0.47, 0.45)
			var x := Control.new()
			x.size = card.size
			x.mouse_filter = Control.MOUSE_FILTER_IGNORE
			x.draw.connect(func():
				var g := Rect2(Vector2.ZERO, x.size).grow(-x.size.x * 0.12)
				x.draw_line(g.position, g.end, Color(RED, 0.9), 8.0, true)
				x.draw_line(Vector2(g.end.x, g.position.y), Vector2(g.position.x, g.end.y), Color(RED, 0.9), 8.0, true))
			card.add_child(x)
		add_child(card)
		pick_cards.append(card)
	return


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
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.118, 0.094, 0.078, 0.62))
	_S()
	if shop_obj != null:
		_draw_fair()
	if mode == "pick":
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.024, 0.016, 0.78))
		_S()
		_draw_pick()
	_draw_toast()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return


static var _thumb_sb: StyleBoxTexture = null


func _shake(r: Dictionary) -> float:
	var u := (t - float(r["shake"])) / 0.4
	if u < 0.0 or u > 1.0:
		return 0.0
	return sin(u * TAU * 2.0) * 10.0 * (1.0 - u)


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
	draw_style_box(UiParch.box("gold", 0.0), P)   # 13/11/2026: a folha com moldura dourada das outras telas
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
			pass   # a carta é um filho (pick_cards), posta em _sync_pick_children
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
		# Confirmar = a fita vermelha das cartas; Voltar = botão de papel (os mesmos dos menus).
		if ok:
			var rb := UiParch.ribbon_box("monster", false)
			if hot:
				rb.modulate_color = Color(1.12, 1.08, 1.04)
			draw_style_box(rb, br.grow_individual(18, 6, 18, 8))
		else:
			draw_style_box(UiParch.button_box("hover" if hot else "normal"), br)
		_txt(Vector2(br.position.x, br.position.y + 42), tr("UI_LEDGER_CONFIRM" if ok else "UI_LEDGER_BACK"), f_disp, 30, UiParch.CREAM if ok else (UiParch.BLOOD if hot else INK), HORIZONTAL_ALIGNMENT_CENTER, br.size.x)


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
		list_clip.draw_texture_rect(UiParch.tex("gem_common_purple"), Rect2(r.position + Vector2(12, by0 - 3), Vector2(33, 40)), false, Color(1, 1, 1, a))
		var cost := maxi(cd.cost_at(lv) - (1 if (pr["mods"] as Array).has("cheap") else 0), 0)
		var tc := Color("f3e6c4") if sel else Color(INK, a)
		_lt(Vector2(r.position.x + 11, y + by0 + 29), str(maxi(cost, 0)), UiDiario.font("fell"), 20, Color(1, 0.95, 0.88, a), HORIZONTAL_ALIGNMENT_CENTER, 36)
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


# ---------------------------------------------------------------- feira do mascate (pele "Mapa aberto")

static func _ftex(name: String) -> Texture2D:
	if not _fair_tex.has(name):
		var p := name if name.begins_with("res://") else "res://assets/ui/map/" + name
		_fair_tex[name] = CampaignArt.map_tex(p)
	return _fair_tex[name]


## Barracas nos pontos da estrada da maquete (3 a 5 cartas; com menos, espalhadas pela estrada) e os serviços em
## linhas no painel da direita. Cada linha guarda "c" (centro do círculo da barraca) e "rect" (clique e setas).
func _fair_layout(n_cards: int) -> void:
	var picks: Array = {0: [], 1: [2], 2: [0, 2], 3: [0, 2, 3], 4: [0, 1, 2, 3]}.get(n_cards, [0, 1, 2, 3, 4])
	var n_serv := 0
	for r in rows:
		if r["kind"] != "card":
			n_serv += 1
	var step := _fair_step(n_serv)
	var sp := _fair_serv_rect(n_serv)
	var ci := 0
	var si := 0
	for r in rows:
		if r["kind"] == "card":
			var spot: Vector2 = FAIR_SPOTS[int(picks[ci]) if ci < picks.size() else ci % FAIR_SPOTS.size()]
			var c := FAIR_PO + spot + Vector2(0, -30)
			r["c"] = c
			r["stall"] = ci
			r["rect"] = Rect2(c.x - 90, c.y - 82, 180, 270)
			ci += 1
		else:
			r["rect"] = Rect2(sp.position.x + 18, sp.position.y + 58 + si * step, sp.size.x - 48, step)
			si += 1


## Textos novos da loja sem chave no CSV (evita reimportar traduções): português ou inglês conforme o idioma.
func _t2(pt: String, en: String) -> String:
	return en if TranslationServer.get_locale().begins_with("en") else pt


func _fair_step(n: int) -> float:
	return minf(42.0, 174.0 / maxf(n, 1.0))


func _fair_serv_rect(n: int) -> Rect2:
	return Rect2(1220, 656, 500, 62 + n * _fair_step(n) + 14)


func _fair_leave_rect() -> Rect2:
	var w := _tw(tr("UI_FAIR_LEAVE"), f_disp, 26) + 56
	return Rect2(1540, 910, w, 56)


func _fair_motion(p: Vector2) -> void:
	seal_hot = _fair_leave_rect().has_point(p)
	buy_hot = fair_buy.has_point(p) and not _focus_row().is_empty()
	fair_hover = -1
	for r in rows:
		if r["sold"] or not (r["rect"] as Rect2).has_point(p):
			continue
		var i := _index_of(r)
		if i < 0:
			continue
		if r["kind"] == "card":
			# A barraca só acende sob o mouse; quem escolhe é o clique (a ficha não troca no caminho até o Comprar).
			fair_hover = i
		else:
			# As linhas de serviço ficam ao lado da ficha: passar o mouse já mostra a descrição.
			if hud.selected != i and hud.sfx.is_valid():
				hud.sfx.call("ui_click", 1.4)
			hud.selected = i


## Clique: Sair; Comprar (o item da ficha); uma barraca escolhe (a já escolhida compra); uma linha de serviço compra.
func _fair_click(p: Vector2) -> void:
	if _fair_leave_rect().has_point(p):
		chosen.emit(Sim.SKIP)
		return
	if fair_buy.has_point(p) and not _focus_row().is_empty():
		chosen.emit(hud.selected)
		return
	for r in rows:
		if r["sold"] or not (r["rect"] as Rect2).has_point(p):
			continue
		var i := _index_of(r)
		if i < 0:
			return
		if r["kind"] == "card" and hud.selected != i:
			hud.selected = i
			if hud.sfx.is_valid():
				hud.sfx.call("ui_click", 1.2)
		else:
			hud.selected = i
			chosen.emit(i)
		return


## Pontos do teste com o mouse: barraca (escolhe) e Comprar; a linha de serviço compra num clique só.
func _fair_click_points(kk: int) -> Array:
	var opts: Array = shop_obj["options"] if shop_obj != null else []
	for r in rows:
		if kk < opts.size() and is_same(r["op"], opts[kk]):
			if r["kind"] != "card":
				return [o + (r["rect"] as Rect2).get_center() * k]
			var buy := Rect2(FAIR_FICHA.position + Vector2(28, 252), Vector2(_fair_buy_w(r), 52))
			return [o + (r["c"] as Vector2) * k, o + buy.get_center() * k]
	return []


func _fair_buy_w(r: Dictionary) -> float:
	return _tw(tr("UI_FAIR_BUY").format({"p": int(r["price"])}), f_disp, 26) + 26 + 52


## Descrição da ficha: o mesmo texto (com palavras-chave e caixas) do livro, em Fell itálico, encolhendo até caber.
func _fair_sync_note(r: Dictionary) -> void:
	var nr := Rect2(FAIR_FICHA.position + Vector2(202, 100), Vector2(FAIR_FICHA.size.x - 202 - 26, 142))
	note.position = o + nr.position * k
	note.size = nr.size * k
	note.add_theme_font_override("normal_font", UiParch.font("italic"))
	note.add_theme_constant_override("line_separation", -2)
	Tips.set_text(note, _note_body(r))
	note.add_theme_color_override("default_color", FAIR_INK)
	var fs := 22.0
	while fs > 14.0:
		note.add_theme_font_size_override("normal_font_size", roundi(fs * k))
		if note.get_content_height() <= note.size.y:
			break
		fs -= 1.0


## Texto com halo de papel (os nomes por cima da estrada tracejada, como o text-shadow da maquete).
func _txt_halo(p: Vector2, s: String, f: Font, fs: float, col: Color) -> void:
	draw_set_transform(o + p * k, 0.0, Vector2.ONE)
	var sz := roundi(fs * k)
	draw_string_outline(f, Vector2.ZERO, s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, sz, maxi(2, roundi(7 * k)), Color(FAIR_PAPER, 0.85))
	draw_string(f, Vector2.ZERO, s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, sz, col)
	_S()


func _draw_fair() -> void:
	if fair_bg == null:
		fair_bg = FeltMap.make(self, FAIR_BG_SIZE, Rect2(Vector2(24, 24), FAIR_BG_SIZE - Vector2(48, 48)), _paint_fair_bg)
	draw_texture(fair_bg, FAIR_PO - Vector2(24, 24))
	var foc := _focus_row()
	# Título e subtítulo na faixa já desenhada no fundo.
	var title := tr("UI_FAIR_TITLE")
	var bx := Rect2(1252, 134, 438, 148)
	var words := title.split(" ")
	if _tw(title, f_disp, 52) <= bx.size.x - 40 or words.size() < 2:
		_txt(Vector2(bx.position.x, 212), title, f_disp, _fit(title, f_disp, 52, bx.size.x - 30, 30), FAIR_INK, HORIZONTAL_ALIGNMENT_CENTER, bx.size.x)
	else:
		var cut := ceili(words.size() / 2.0)
		var l1 := " ".join(words.slice(0, cut))
		var l2 := " ".join(words.slice(cut))
		var fs := _fit(l1 if _tw(l1, f_disp, 52) > _tw(l2, f_disp, 52) else l2, f_disp, 52, bx.size.x - 40, 30)
		_txt(Vector2(bx.position.x, 184), l1, f_disp, fs, FAIR_INK, HORIZONTAL_ALIGNMENT_CENTER, bx.size.x)
		_txt(Vector2(bx.position.x, 234), l2, f_disp, fs, FAIR_INK, HORIZONTAL_ALIGNMENT_CENTER, bx.size.x)
	_txt(Vector2(bx.position.x, 266), tr("UI_FAIR_SUB"), UiParch.font("italic"), 19, FAIR_INK, HORIZONTAL_ALIGNMENT_CENTER, bx.size.x)
	# Tracejado vermelho da barraca escolhida até a ficha.
	if not foc.is_empty() and foc["kind"] == "card":
		var a: Vector2 = foc["c"] + Vector2(84, 8)
		var b := FAIR_FICHA.position + Vector2(-6, 92)
		var pts := PackedVector2Array([a])
		pts.append_array(_bez(a, a + Vector2(90, 10), b - Vector2(90, 0), b, 220))
		var run := 0.0
		for i in pts.size() - 1:
			var l := pts[i].distance_to(pts[i + 1])
			if fmod(run, 11.0) < 5.0:
				draw_line(pts[i], pts[i + 1], FAIR_RED, 2.6, true)
			run += l
	for r in rows:
		if r["kind"] == "card":
			_draw_stall(r, is_same(r, foc), _index_of(r) == fair_hover and not r["sold"])
	_draw_fair_ficha(foc)
	_draw_fair_services(foc)
	_draw_fair_purse()
	# Cabeçalho da seção das barracas.
	_txt_halo(Vector2(570, 160), _t2("Cartas à venda", "Cards for sale"), f_disp, 30, FAIR_INK)
	_txt_halo(Vector2(570, 188), _t2("clique numa barraca para ver a carta", "click a stall to see the card"), UiParch.font("italic"), 19, FAIR_INK)
	# Sair da feira.
	var lr := _fair_leave_rect()
	draw_style_box(UiParch.button_box("hover" if seal_hot else "normal"), lr)
	_txt(Vector2(lr.position.x, lr.position.y + 37), tr("UI_FAIR_LEAVE"), f_disp, 26, UiParch.BLOOD if seal_hot else FAIR_INK, HORIZONTAL_ALIGNMENT_CENTER, lr.size.x)


## Fundo de feltro da feira (26/11/2026): retalhos costurados, a estrada das barracas em trilha de areia com
## pesponto vermelho, morros, bosques, a costa embaixo à esquerda e a faixa do título.
func _paint_fair_bg(ci: CanvasItem, mm: Minimap) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 777
	var o := Vector2(24, 24)
	var paper := Rect2(o, FAIR_BG_SIZE - o * 2.0)
	FeltMap.base(ci, paper)
	# mar embaixo à esquerda
	var coast: Array = []
	for i in 13:
		var x := paper.position.x + i * 50.0
		coast.append(Vector2(x, o.y + 812 + i * 2.2 + sin(i * 1.3) * 6.0))
	var sea_sb := StyleBoxFlat.new()
	sea_sb.bg_color = Minimap.SEA
	sea_sb.set_corner_radius_all(int(FeltMap.RADIUS))
	ci.draw_style_box(sea_sb, Rect2(Vector2(paper.position.x, o.y + 780), Vector2(640, paper.end.y - o.y - 780)))
	var lp := PackedVector2Array([Vector2(paper.position.x, o.y + 780), Vector2(o.x + 640, o.y + 780), Vector2(o.x + 640, paper.end.y)])
	var cr := coast.duplicate()
	cr.reverse()
	for q in cr:
		lp.append(q)
	ci.draw_colored_polygon(lp, Minimap.BG)
	ci.draw_polyline(Minimap._smooth(coast, false, 3), Minimap.INK, 2.6, true)
	var wl: Array = []
	for q in coast:
		wl.append(q + Vector2(0, 16))
	mm._dashed(ci, Minimap._smooth(wl, false, 3), Color(Minimap.PAPER, 0.5), 2.0, 9.0, 8.0, 0.0)
	# a estrada das barracas (a curva da maquete), em areia com pesponto vermelho
	var road := Minimap._smooth([o + Vector2(80, 760), o + Vector2(250, 330), o + Vector2(450, 232), o + Vector2(700, 300),
		o + Vector2(880, 360), o + Vector2(900, 440), o + Vector2(790, 570), o + Vector2(490, 590)], false, 6)
	FeltMap.trail(ci, mm, road, Minimap.ACC, 18.0)
	# morros, montanhas e bosques (a direita fica sob a ficha e os serviços; o canto de cima, sob a bolsa e o título)
	mm._mtn(ci, o.x + 990, o.y + 520, 70, 80, false, r)
	mm._mtn(ci, o.x + 1075, o.y + 530, 60, 95, true, r)
	for hl in [Vector2(900, 850), Vector2(1000, 858)]:
		mm._hill_v(ci, o.x + hl.x, o.y + hl.y, 60, r)
	FeltMap.grove(ci, mm, r, o + Vector2(400, 440), 3, Vector2(40, 25))
	FeltMap.grove(ci, mm, r, o + Vector2(700, 500), 3, Vector2(40, 25))
	FeltMap.grove(ci, mm, r, o + Vector2(700, 780), 5)
	FeltMap.grove(ci, mm, r, o + Vector2(980, 760), 4)
	FeltMap.grove(ci, mm, r, o + Vector2(110, 520), 3, Vector2(40, 60))
	mm._lake(ci, o + Vector2(1000, 230), 50, 22, r)
	# faixa do título (Feira do Mascate fica por cima, em _draw_fair)
	FeltMap.banner(ci, mm, Vector2(1252 + 219, 134 + 74) - FAIR_PO + Vector2(24, 24), 438, 148)
	FeltMap.rim(ci, mm, paper)


## A bolsa: placa fixa no canto de cima com a moeda, o ouro em número grande (pisca em vermelho quando falta)
## e o tamanho do baralho.
func _draw_fair_purse() -> void:
	var pr := FAIR_PURSE
	var pulse := clampf(1.0 - (t - gold_pulse) / 0.6, 0.0, 1.0)
	_rrect(Rect2(pr.position + Vector2(2, 5), pr.size), Color(0, 0, 0, 0.25), 10)
	draw_style_box(UiParch.box("gold", 0.0), pr)
	_coin(pr.position + Vector2(58, 60), 28.0)
	var gtxt := str(int(sim.gold))
	var sc := 1.0 + 0.2 * sin(pulse * PI)
	_txt(pr.position + Vector2(104, 44), _t2("SEU OURO", "YOUR GOLD"), UiParch.font("italic"), 19, FAIR_INK.lerp(FAIR_RED, 0.0))
	_txt(pr.position + Vector2(102, 92), gtxt, f_disp, 46 * sc, FAIR_INK.lerp(FAIR_RED, pulse))
	var dtxt := _t2("%d cartas no baralho", "%d cards in deck") % sim.cards.size()
	var dfs := _fit(dtxt, UiParch.font("italic"), 17, pr.end.x - (pr.position.x + 102 + _tw(gtxt, f_disp, 46) + 16) - 26, 12)
	_txt(pr.position + Vector2(102 + _tw(gtxt, f_disp, 46) + 16, 90), dtxt, UiParch.font("italic"), dfs, Color(FAIR_INK, 0.8))


## Uma barraca: arte da carta num círculo com anel duplo de tinta (vermelho se escolhida), a tenda em cima, o nome
## embaixo e o preço na faixa vermelha inclinada (apagada se o ouro não dá).
func _draw_stall(r: Dictionary, hot: bool, hover: bool) -> void:
	var c: Vector2 = r["c"] + Vector2(_shake(r), 0)
	var sold: bool = r["sold"]
	var poor: bool = not sold and sim.gold + 0.0001 < float(r["price"])
	var R := FAIR_ART_R
	if hot and not sold:
		for i in 6:
			draw_circle(c, R + 30 - i * 2.6, Color(FAIR_RED, 0.07))
		draw_circle(c, R + 14, FAIR_RED)
	else:
		draw_circle(c, R + 11, Color(FAIR_RED, 0.85) if hover else FAIR_INK)
	draw_circle(c, R + 9, FAIR_PAPER)
	for i in 36:
		var a0 := TAU * i / 36.0
		draw_arc(c, R + 5, a0, a0 + TAU / 36.0 * 0.55, 4, Color("8a6a50"), 2.0, true)
	draw_circle(c, R + 1, Color("b8a07e"))
	draw_circle(c, R, FAIR_PAPER)
	var cd: CardDef = r["cd"]
	var tex := UiDiario.card_tex(cd.id)
	if tex:
		var ts := tex.get_size()
		var side := minf(ts.x, ts.y)
		var cu := Vector2(0.5, 0.5 if ts.y <= ts.x else 0.42)
		var hu := Vector2(side / ts.x, side / ts.y) * 0.5
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i in 48:
			var d := Vector2.from_angle(TAU * i / 48.0)
			pts.append(c + d * R)
			uvs.append(cu + d * hu)
		draw_colored_polygon(pts, Color(0.62, 0.6, 0.58) if sold else Color.WHITE, uvs, tex)
	var tent := _ftex("icon_m-tent.svg")
	if tent:
		draw_texture_rect(tent, Rect2(c.x - 26, c.y - 88, 52, 44), false)
	# Nome (com + vermelho do nível).
	var nm: String = r["name"]
	var plus: String = r["plus"]
	var fs := _fit(nm + (" " + plus if plus != "" else ""), f_disp, 26, 300, 18)
	var nw := _tw(nm, f_disp, fs)
	var pw := _tw(" " + plus, f_disp, fs) if plus != "" else 0.0
	var x0 := c.x - (nw + pw) * 0.5
	var col := FAIR_INK if not sold else Color(FAIR_INK, 0.55)
	_txt_halo(Vector2(x0, c.y + 104), nm, f_disp, fs, col)
	if plus != "":
		_txt_halo(Vector2(x0 + nw, c.y + 104), " " + plus, f_disp, fs, FAIR_RED)
	if sold:
		_stamp(c, tr("UI_LEDGER_STAMP_SOLD"), 30)
		return
	# Linha de tipo e custo (o que a carta é) e, embaixo, o preço com a moeda; sem ouro, em vermelho com o que falta.
	var cd2: CardDef = r["cd"]
	var tline := "%s · %s" % [UiKit.type_line(cd2), tr("UI_FAIR_COST").format({"n": cd2.cost_at(int(r["lv"]))})]
	var itf := UiParch.font("italic")
	_txt_halo(Vector2(c.x - _tw(tline, itf, 19) * 0.5, c.y + 128), tline, itf, 19, Color(FAIR_INK, 0.85))
	var ptxt := str(int(r["price"]))
	var pw2 := 20.0 + _tw(ptxt, f_disp, 30)
	var short := int(ceil(float(r["price"]) - sim.gold))
	var pl := Rect2(c.x - pw2 * 0.5 - 24, c.y + 140, pw2 + 48, 42)
	_rrect(pl, Color(FAIR_PAPER, 0.95), 21, 3.0, FAIR_RED if poor else FAIR_INK)
	_coin(pl.position + Vector2(22, 21), 11.0)
	_txt(pl.position + Vector2(40, 31), ptxt, f_disp, 30, FAIR_RED if poor else FAIR_INK)
	if poor:
		var mt := _t2("faltam %d", "%d short") % short
		_txt_halo(Vector2(pl.end.x + 10, pl.position.y + 29), mt, itf, 20, FAIR_RED)


func _fair_icon(kind: String) -> String:
	return {"pick_upgrade": "s-up", "mod": "s-cheap", "pick_remove": "s-remove", "relic": "s-relic"}.get(kind, "s-up")


func _fair_name(r: Dictionary) -> String:
	if r["kind"] == "relic":
		return tr("UI_FAIR_RELIC").format({"r": r["name"]})
	if r["kind"] in ["pick_upgrade", "pick_remove"]:
		return tr("UI_FAIR_" + str(r["kind"]))
	return r["name"]


## Ficha do item escolhido: arte (ou o ícone do serviço), nome, linha de tipo, a descrição (RichTextLabel `note`),
## Comprar · N na fita vermelha e a dica (ou quanto falta de ouro).
func _draw_fair_ficha(foc: Dictionary) -> void:
	var fr := FAIR_FICHA
	draw_style_box(UiParch.box("gold", 0.0), fr)
	fair_buy = Rect2()
	if foc.is_empty():
		return
	var it := UiParch.font("italic")
	var tc := fr.position + Vector2(103, 102)
	if foc["kind"] == "card":
		var rot := deg_to_rad(-2.0)
		_L(tc, rot)
		var pr := Rect2(-75, -72, 150, 144)
		_rrect(Rect2(pr.position + Vector2(1, 4), pr.size), Color(0, 0, 0, 0.22), 3)
		draw_rect(pr, Color("f1e3bd"))
		var cd: CardDef = foc["cd"]
		var tex := UiDiario.card_tex(cd.id)
		if tex:
			_art_fit(self, tex, pr.grow(-6), Color.WHITE, true)
		draw_rect(pr, FAIR_INK, false, 2.0)
		_S()
	else:
		var ic := _ftex("node_%s.svg" % _fair_icon(str(foc["kind"])))
		if foc["kind"] == "relic":
			ic = _ftex("res://assets/ui/relics/%s.svg" % str(foc["item"]["id"]))   # ícone da própria relíquia (15/11/2026)
		if ic:
			draw_texture_rect(ic, Rect2(tc - Vector2(66, 66), Vector2(132, 132)), false)
	var nm := _fair_name(foc) if foc["kind"] != "card" else str(foc["name"])
	var plus: String = foc["plus"]
	var fs := _fit(nm + (" " + plus if plus != "" else ""), f_disp, 32, fr.size.x - 200 - 22, 20)
	_txt(fr.position + Vector2(200, 58), nm, f_disp, fs, FAIR_INK)
	if plus != "":
		_txt(fr.position + Vector2(200 + _tw(nm + " ", f_disp, fs), 58), plus, f_disp, fs, FAIR_RED)
	var head := ""
	if foc["kind"] == "card":
		var cd: CardDef = foc["cd"]
		head = " · ".join([UiKit.type_line(cd), tr("RARITY_" + CardMold.RAR_NAMES[clampi(cd.rarity, 0, 3)]),
			tr("UI_FAIR_COST").format({"n": cd.cost_at(int(foc["lv"]))})])
	else:
		head = _note_head(foc)
	if head != "":
		_txt(fr.position + Vector2(202, 89), head, it, _fit(head, it, 19, fr.size.x - 202 - 22, 14), FAIR_INK)
	# Comprar · N (fita vermelha; escura se não dá) e a dica ao lado.
	var short := int(ceil(float(foc["price"]) - sim.gold))
	var btxt := tr("UI_FAIR_BUY").format({"p": int(foc["price"])})
	fair_buy = Rect2(fr.position + Vector2(28, 252), Vector2(_fair_buy_w(foc), 52))
	var rb := UiParch.ribbon_box("monster", short > 0)
	if buy_hot and short <= 0:
		rb.modulate_color = Color(1.12, 1.08, 1.04)
	draw_style_box(rb, fair_buy.grow_individual(10, 2, 10, 4))
	var cream := UiParch.CREAM if short <= 0 else Color(UiParch.CREAM, 0.6)
	var bw := _tw(btxt, f_disp, 26)
	var bx := fair_buy.get_center().x - (bw + 22) * 0.5
	_txt(Vector2(bx, fair_buy.position.y + 35), btxt, f_disp, 26, cream)
	_coin(Vector2(bx + bw + 18, fair_buy.position.y + 26), 9.0)
	var hx := fair_buy.end.x + 22
	var hint := tr("UI_LEDGER_SHORT").format({"n": short}) if short > 0 else tr("UI_FAIR_HINT_PAD" if hud.pad else "UI_FAIR_HINT")
	_txt(Vector2(hx, fair_buy.position.y + 33), hint, it, _fit(hint, it, 19, fr.end.x - 24 - hx, 13), FAIR_RED if short > 0 else FAIR_INK)


## Painel de serviços: ícone em anel duplo, nome, pontilhado e preço; o em foco em vermelho, o vendido riscado.
func _draw_fair_services(foc: Dictionary) -> void:
	var serv: Array = rows.filter(func(r): return r["kind"] != "card")
	if serv.is_empty():
		return
	var step := _fair_step(serv.size())
	var sp := _fair_serv_rect(serv.size())
	draw_style_box(UiParch.box("gold", 0.0), sp)
	_txt(sp.position + Vector2(30, 46), tr("UI_FAIR_SERV"), f_disp, 28, FAIR_INK)
	var it := UiParch.font("italic")
	for r in serv:
		var rr: Rect2 = r["rect"]
		rr.position.x += _shake(r)
		var sold: bool = r["sold"]
		var hot: bool = is_same(r, foc) and not sold
		var poor: bool = not sold and sim.gold + 0.0001 < float(r["price"])
		var y := rr.position.y + 4
		var isz := minf(36.0, step - 4.0)
		if hot:
			_rrect(Rect2(rr.position.x - 4, y - 3, rr.size.x + 8, isz + 6), Color(FAIR_RED, 0.12), 8)
		var ic := _ftex("node_%s%s.svg" % [_fair_icon(str(r["kind"])), "_hot" if hot else ""])
		if r["kind"] == "relic":
			ic = _ftex("res://assets/ui/relics/%s.svg" % str(r["item"]["id"]))
		if ic:
			draw_texture_rect(ic, Rect2(rr.position.x + 6, y, isz, isz), false, Color(1, 1, 1, 0.5 if sold else 1.0))
		var base := y + isz * 0.5 + 8
		var ptxt := str(int(r["price"]))
		var pw := _tw(ptxt, f_disp, 21) + 18
		var px := rr.end.x - 4 - pw
		var nm := _fair_name(r)
		var x0 := rr.position.x + 54
		var fs := _fit(nm, it, 21, px - x0 - 30, 14)
		var col := FAIR_INK if not sold else Color(FAIR_INK, 0.5)
		if hot:
			col = FAIR_RED
		_txt(Vector2(x0, base), nm, it, fs, col)
		var nw := _tw(nm, it, fs)
		if sold:
			draw_line(Vector2(x0 - 2, base - fs * 0.3), Vector2(x0 + nw + 2, base - fs * 0.34), FAIR_RED, 2.5, true)
		_dotted(Vector2(x0 + nw + 10, base - 2), Vector2(px - 8, base - 2), Color(FAIR_INK, 0.6), 6.0, 1.1)
		var pc := FAIR_INK if not poor else FAIR_RED
		if sold:
			pc = Color(FAIR_INK, 0.45)
		_txt(Vector2(px, base), ptxt, f_disp, 21, pc)
		_coin(Vector2(rr.end.x - 10, base - 7), 8.0)
		if sold:
			_stamp(Vector2(px - 60, base - 8), tr("UI_LEDGER_STAMP_SOLD" if r["kind"] == "relic" else "UI_LEDGER_STAMP_DONE"), 18)
