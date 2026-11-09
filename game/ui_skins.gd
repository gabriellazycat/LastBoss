class_name UiSkins
extends RefCounted
## Peles da HUD e dos menus (Settings.v["look_hud"]): 0 = Covil (a padrão, em UiCovil), 1..4 = as variações de
## 07/11/2026, 5 = a clássica (a antiga 0, caixas chapadas). O UiKit pergunta aqui
## a paleta, as fontes e o desenho de painéis, botões, barras e selos. As texturas dos painéis
## são geradas por código (madeira, pedra, laca); fontes OFL do Google Fonts em assets/fonts.

const NAMES := ["Covil", "Madeira e ouro", "Pedra rúnica", "Vidro arcano", "Gótico carmesim", "Clássica (a antiga)"]
const F := "res://assets/fonts/"
const DEFAULT := {
	"BG": Color(0.055, 0.04, 0.085, 0.92), "BG_SOFT": Color(0.05, 0.035, 0.08, 0.72), "EDGE": Color(0.42, 0.3, 0.6),
	"GOLD": Color(1.0, 0.76, 0.36), "TEXT": Color(0.95, 0.92, 1.0), "MUTED": Color(0.72, 0.68, 0.82),
	"HERO_HP": Color(0.9, 0.24, 0.22), "HERO_XP": Color(1.0, 0.7, 0.3), "POWER": Color(0.72, 0.42, 1.0),
	"ELIXIR": Color(0.86, 0.32, 0.96), "GOOD": Color(0.45, 1.0, 0.6), "BAD": Color(1.0, 0.45, 0.4),
}
const DEFAULT_RARITY := [Color(0.62, 0.62, 0.62), Color(0.35, 0.8, 0.35), Color(0.3, 0.55, 1.0), Color(0.7, 0.35, 1.0)]
const SKINS := {
	1: {
		"pal": {"BG": Color(0.17, 0.1, 0.06, 0.96), "BG_SOFT": Color(0.15, 0.085, 0.05, 0.9), "EDGE": Color(0.78, 0.56, 0.24),
			"GOLD": Color(1.0, 0.8, 0.4), "TEXT": Color(1.0, 0.95, 0.86), "MUTED": Color(0.86, 0.75, 0.6),
			"HERO_HP": Color(0.88, 0.2, 0.15), "HERO_XP": Color(1.0, 0.72, 0.25), "POWER": Color(0.66, 0.4, 0.95), "ELIXIR": Color(0.78, 0.3, 0.95)},
		"title": ["CinzelDecorative-Bold.ttf", 0, 2], "body": ["Alegreya-VF.ttf", 600, 0],
		"material": "wood", "frame": Color(0.95, 0.72, 0.3), "corner": "chamfer", "badge": "medal", "hover": Color(1.0, 0.88, 0.55),
	},
	2: {
		"pal": {"BG": Color(0.13, 0.14, 0.17, 0.96), "BG_SOFT": Color(0.11, 0.12, 0.15, 0.9), "EDGE": Color(0.45, 0.56, 0.66),
			"GOLD": Color(0.55, 0.95, 1.0), "TEXT": Color(0.93, 0.96, 1.0), "MUTED": Color(0.68, 0.74, 0.82),
			"HERO_HP": Color(0.9, 0.26, 0.22), "HERO_XP": Color(1.0, 0.76, 0.36), "POWER": Color(0.55, 0.62, 1.0), "ELIXIR": Color(0.3, 0.82, 1.0)},
		"title": ["Metamorphous-Regular.ttf", 0, 1], "body": ["Spectral-SemiBold.ttf", 0, 0],
		"material": "stone", "frame": Color(0.56, 0.62, 0.7), "corner": "chamfer", "badge": "hex", "rune": Color(0.4, 0.95, 1.0), "hover": Color(0.7, 1.0, 1.0),
	},
	3: {
		"pal": {"BG": Color(0.06, 0.05, 0.13, 0.78), "BG_SOFT": Color(0.05, 0.04, 0.11, 0.6), "EDGE": Color(0.55, 0.42, 1.0),
			"GOLD": Color(1.0, 0.6, 0.95), "TEXT": Color(0.96, 0.97, 1.0), "MUTED": Color(0.72, 0.74, 0.92),
			"HERO_HP": Color(1.0, 0.32, 0.45), "HERO_XP": Color(1.0, 0.78, 0.35), "POWER": Color(0.55, 0.52, 1.0), "ELIXIR": Color(0.95, 0.38, 1.0)},
		"title": ["MarcellusSC-Regular.ttf", 0, 2], "body": ["Exo2-VF.ttf", 600, 0],
		"material": "glass", "frame": Color(0.72, 0.58, 1.0), "corner": "round", "badge": "orb", "hover": Color(1.0, 0.78, 1.0),
	},
	4: {
		"pal": {"BG": Color(0.045, 0.02, 0.03, 0.96), "BG_SOFT": Color(0.04, 0.018, 0.025, 0.88), "EDGE": Color(0.62, 0.1, 0.14),
			"GOLD": Color(0.93, 0.87, 0.8), "TEXT": Color(0.96, 0.92, 0.9), "MUTED": Color(0.75, 0.64, 0.64),
			"HERO_HP": Color(0.86, 0.1, 0.13), "HERO_XP": Color(0.96, 0.76, 0.45), "POWER": Color(0.62, 0.28, 0.82), "ELIXIR": Color(0.82, 0.16, 0.32)},
		"title": ["GrenzeGotisch-VF.ttf", 700, 1], "body": ["CrimsonPro-VF.ttf", 600, 0],
		"material": "lacquer", "frame": Color(0.66, 0.1, 0.15), "corner": "chamfer", "badge": "diamond", "filigree": Color(0.86, 0.83, 0.8), "hover": Color(1.0, 0.82, 0.8),
	},
}

static var skin := 0
static var _applied := -1
static var S: Dictionary = {}
static var _cache: Dictionary = {}
static var _title: Font
static var _body: Font


## Uma das peles de 07/11/2026 (texturas geradas por código).
static func on() -> bool:
	return skin >= 1 and skin <= 4


## A pele Covil (UiCovil), a padrão.
static func covil() -> bool:
	return skin == 0


## Lê a pele das configurações e troca a paleta do UiKit.
static func apply() -> void:
	var k := int(Settings.v.get("look_hud", 0))
	if k == _applied:
		return
	_applied = k
	skin = k
	S = SKINS.get(k, {})
	_cache.clear()
	_title = null
	_body = null
	var pal: Dictionary = DEFAULT.duplicate()
	if k == 0:
		pal.merge(UiCovil.PAL, true)
	elif not S.is_empty():
		pal.merge(S["pal"], true)
	UiKit.RARITY_COLORS = (UiCovil.RARITY if k == 0 else DEFAULT_RARITY).duplicate()
	UiKit.BG = pal["BG"]
	UiKit.BG_SOFT = pal["BG_SOFT"]
	UiKit.EDGE = pal["EDGE"]
	UiKit.GOLD = pal["GOLD"]
	UiKit.TEXT = pal["TEXT"]
	UiKit.MUTED = pal["MUTED"]
	UiKit.HERO_HP = pal["HERO_HP"]
	UiKit.HERO_XP = pal["HERO_XP"]
	UiKit.POWER = pal["POWER"]
	UiKit.ELIXIR = pal["ELIXIR"]
	UiKit.GOOD = pal["GOOD"]
	UiKit.BAD = pal["BAD"]


static func _font(spec: Array) -> Font:
	var ff: FontFile = load(F + spec[0])
	if ff == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = ff
	if int(spec[1]) > 0:
		var ts := TextServerManager.get_primary_interface()
		fv.variation_opentype = {ts.name_to_tag("wght"): int(spec[1])}
	fv.spacing_glyph = int(spec[2])
	return fv


static func title_font() -> Font:
	if not on():
		return null
	if _title == null:
		_title = _font(S["title"])
	return _title


static func body_font() -> Font:
	if not on():
		return null
	if _body == null:
		_body = _font(S["body"])
	return _body


static func card_bg() -> Color:
	if not on():
		return Color(0.075, 0.055, 0.11, 0.97)
	var b: Color = UiKit.BG
	return Color(b.r * 0.85, b.g * 0.85, b.b * 0.85, 0.97)


## Gomo da barra de elixir no formato da pele. f = quanto está cheio (0..1).
static func draw_gem(ci: CanvasItem, r: Rect2, f: float, col: Color) -> void:
	var frame: Color = S["frame"]
	var dark := Color(0, 0, 0, 0.62)
	var full := col if f >= 1.0 else col.darkened(0.35)
	match S["material"]:
		"wood", "glass":
			var round_: bool = S["material"] == "glass"
			var bg := StyleBoxFlat.new()
			bg.bg_color = dark
			bg.set_corner_radius_all(int(r.size.y * 0.5) if round_ else 4)
			bg.corner_detail = 8 if round_ else 3
			bg.border_color = frame.darkened(0.2) if not round_ else Color(frame.r, frame.g, frame.b, 0.5)
			bg.set_border_width_all(2 if not round_ else 1)
			ci.draw_style_box(bg, r)
			if f > 0.0:
				var fr := Rect2(r.position + Vector2(2, 2), Vector2((r.size.x - 4) * f, r.size.y - 4))
				var fs := StyleBoxFlat.new()
				fs.bg_color = full
				fs.set_corner_radius_all(int(fr.size.y * 0.5) if round_ else 3)
				fs.corner_detail = 8 if round_ else 3
				if round_ and f >= 1.0:
					fs.shadow_color = Color(col.r, col.g, col.b, 0.6)
					fs.shadow_size = 6
				ci.draw_style_box(fs, fr)
				if f >= 1.0:
					ci.draw_rect(Rect2(fr.position + Vector2(3, 1), Vector2(fr.size.x - 6, fr.size.y * 0.3)), Color(1, 1, 1, 0.3))
		_:
			# Cristal (pedra) ou losango (gótico): hexágono alongado.
			var c := r.get_center()
			var hw := r.size.x * 0.5
			var hh := r.size.y * 0.5
			var k := 0.35 if S["material"] == "stone" else 0.5
			var pts := PackedVector2Array([c + Vector2(-hw, 0), c + Vector2(-hw + hw * k, -hh), c + Vector2(hw - hw * k, -hh), c + Vector2(hw, 0), c + Vector2(hw - hw * k, hh), c + Vector2(-hw + hw * k, hh)])
			ci.draw_colored_polygon(pts, dark)
			if f > 0.0:
				var fp := PackedVector2Array()
				var lim := c.x - hw + r.size.x * f
				for p in pts:
					fp.append(Vector2(minf(p.x, lim), p.y))
				ci.draw_colored_polygon(fp, full)
				if f >= 1.0:
					ci.draw_colored_polygon(PackedVector2Array([pts[0], pts[1], pts[2], pts[3]]), Color(1, 1, 1, 0.16))
			var loop := pts.duplicate()
			loop.append(pts[0])
			ci.draw_polyline(loop, frame.lightened(0.1) if f >= 1.0 else frame.darkened(0.3), 1.5, true)


static func hover_text() -> Color:
	return S.get("hover", Color(1.0, 0.9, 0.62))


## Ajusta uma caixa simples (cartas, barras, selos antigos) ao canto da pele.
static func style_box(sb: StyleBoxFlat, cut: int) -> void:
	if not on():
		return
	if S["corner"] == "round":
		sb.corner_detail = 8
		sb.set_corner_radius_all(int(cut * 1.6) + 2)
		if sb.border_width_left > 0 and sb.shadow_size == 0:
			sb.shadow_color = Color(sb.border_color.r, sb.border_color.g, sb.border_color.b, 0.25)
			sb.shadow_size = 4


# ---------------------------------------------------------------- texturas geradas

static func _noise(x: float, y: float, seed_: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233 + seed_) * 43758.5453, 1.0)


static func _smooth_noise(x: float, y: float, s: float) -> float:
	var xi := floorf(x / s)
	var yi := floorf(y / s)
	var fx := x / s - xi
	var fy := y / s - yi
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _noise(xi, yi, s)
	var b := _noise(xi + 1, yi, s)
	var c := _noise(xi, yi + 1, s)
	var d := _noise(xi + 1, yi + 1, s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


## Painel de N×N px com moldura de `m` px: fundo do material + moldura chanfrada + enfeites dos cantos.
static func _panel_image(mat: String, bg: Color, frame: Color, n: int, m: int) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var cut := 7.0 if mat != "lacquer" else 11.0
	for y in n:
		for x in n:
			var c := bg
			# Fundo.
			match mat:
				"wood":
					var g := sin((y + 5.0 * sin(x * 0.045) + _smooth_noise(x, y, 9.0) * 6.0) * 0.6) * 0.5 + 0.5
					var f := _noise(x, y, 3.0) * 0.06
					c = Color(bg.r * (0.82 + 0.3 * g + f), bg.g * (0.82 + 0.28 * g + f), bg.b * (0.85 + 0.2 * g + f), bg.a)
				"stone":
					var s := _smooth_noise(x, y, 6.0) * 0.55 + _smooth_noise(x, y, 2.5) * 0.3 + _noise(x, y, 5.0) * 0.15
					c = Color(bg.r * (0.75 + 0.5 * s), bg.g * (0.75 + 0.5 * s), bg.b * (0.78 + 0.45 * s), bg.a)
				"lacquer":
					var sh := 1.0 + 0.35 * exp(-pow((x - n * 0.3) / (n * 0.25), 2.0)) * (1.0 - float(y) / n)
					c = Color(bg.r * sh, bg.g * sh, bg.b * sh, bg.a)
			# Distância até a borda, com chanfro nos cantos.
			var dx := minf(x, n - 1 - x)
			var dy := minf(y, n - 1 - y)
			var d := minf(dx, dy)
			var dc := (dx + dy) - cut
			if dc < 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			d = minf(d, dc * 0.7071)
			# Moldura.
			var bw := 5.0 if mat == "wood" else (4.0 if mat == "stone" else 2.0)
			if mat == "lacquer":
				if d < 1.0:
					c = Color(0, 0, 0, 0.9)
				elif d < 3.0:
					c = frame
				elif d < 4.5:
					c = Color(0.02, 0.0, 0.01, bg.a)
				elif d < 5.5:
					c = frame.darkened(0.35)
			elif d < 1.0:
				c = Color(0, 0, 0, 0.95)
			elif d < 1.0 + bw:
				var t := (d - 1.0) / bw
				var bev := 1.25 - absf(t - 0.4) * 0.9 + (0.18 if (x + y) < n else -0.12)
				c = Color(frame.r * bev, frame.g * bev, frame.b * bev, 1.0)
				if mat == "stone":
					var s2 := _noise(x, y, 7.0) * 0.18
					c = Color(c.r * (0.9 + s2), c.g * (0.9 + s2), c.b * (0.9 + s2), 1.0)
			elif d < 2.0 + bw:
				c = Color(0, 0, 0, 0.85)
			img.set_pixel(x, y, c)
	_corners(img, mat, frame, n, m)
	return img


static func _corners(img: Image, mat: String, frame: Color, n: int, m: int) -> void:
	var pts := [Vector2(m * 0.62, m * 0.62), Vector2(n - 1 - m * 0.62, m * 0.62), Vector2(m * 0.62, n - 1 - m * 0.62), Vector2(n - 1 - m * 0.62, n - 1 - m * 0.62)]
	for p in pts:
		match mat:
			"wood":
				# Rebite dourado com brilho.
				for y in range(-5, 6):
					for x in range(-5, 6):
						var r := Vector2(x, y).length()
						if r <= 4.2:
							var hl := clampf(1.3 - Vector2(x + 1.5, y + 1.5).length() * 0.25, 0.55, 1.4)
							img.set_pixel(int(p.x) + x, int(p.y) + y, Color(frame.r * hl, frame.g * hl, frame.b * hl * 0.9, 1.0))
						elif r <= 5.2:
							img.set_pixel(int(p.x) + x, int(p.y) + y, Color(0.05, 0.02, 0.0, 1.0))
			"stone":
				# Runa: losango vazado que brilha.
				var rc: Color = S.get("rune", Color(0.4, 0.95, 1.0))
				for y in range(-5, 6):
					for x in range(-5, 6):
						var dd := absf(x) + absf(y)
						if dd >= 3.5 and dd <= 5.0:
							img.set_pixel(int(p.x) + x, int(p.y) + y, rc)
						elif dd <= 1.2:
							img.set_pixel(int(p.x) + x, int(p.y) + y, rc.lightened(0.4))
			"lacquer":
				# Filigrana prateada: losango com pontas.
				var fc: Color = S.get("filigree", Color(0.86, 0.83, 0.8))
				for y in range(-7, 8):
					for x in range(-7, 8):
						var dd := absf(x) + absf(y) * 1.6
						if dd <= 4.0 or (absf(y) <= 0.6 and absf(x) <= 7.0) or (absf(x) <= 0.6 and absf(y) <= 7.0):
							img.set_pixel(int(p.x) + x, int(p.y) + y, fc)


static func _tex_box(key: String, img_fn: Callable, m: int, margin: int) -> StyleBoxTexture:
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(img_fn.call())
	var sb := StyleBoxTexture.new()
	sb.texture = _cache[key]
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	sb.set_content_margin_all(margin + 4)
	return sb


## Painel da pele. `border` (cor de significado: vermelho no herói, roxo no poder) tinge a moldura.
static func panel_box(bg: Color, border: Color, margin: int) -> StyleBox:
	var mat: String = S["material"]
	var frame: Color = (S["frame"] as Color).lerp(border, 0.3)
	if mat == "glass":
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(bg.r * 0.9 + 0.01, bg.g * 0.9 + 0.01, bg.b * 1.1 + 0.03, minf(bg.a, 0.82))
		sb.border_color = Color(frame.r, frame.g, frame.b, 0.85)
		sb.set_border_width_all(1)
		sb.border_width_top = 2
		sb.set_corner_radius_all(14)
		sb.corner_detail = 8
		sb.shadow_color = Color(frame.r, frame.g, frame.b, 0.28)
		sb.shadow_size = 9
		sb.set_content_margin_all(margin + 2)
		sb.anti_aliasing = true
		return sb
	var b := Color(bg.r, bg.g, bg.b, maxf(bg.a, 0.8))
	var key := "%s/%s/%s" % [mat, b.to_html(), frame.to_html()]
	return _tex_box(key, func(): return _panel_image(mat, b, frame, 72, 18), 18, margin)


static func button_states() -> Dictionary:
	var bg: Color = UiKit.BG
	var e: Color = UiKit.EDGE
	var g: Color = UiKit.GOLD
	return {
		"normal": [bg, e, 0], "hover": [bg.lightened(0.08), g, 0], "pressed": [bg.lightened(0.14), g.lightened(0.2), 0],
		"focus": [bg.lightened(0.08), g, 0], "disabled": [bg.darkened(0.3), Color(0.3, 0.28, 0.3), 0]}


static func button_box(st: String, bg: Color, border: Color) -> StyleBox:
	var sb := panel_box(bg, border, 8)
	if sb is StyleBoxTexture:
		(sb as StyleBoxTexture).modulate_color = Color(1.25, 1.2, 1.1) if st in ["hover", "focus"] else (Color(0.6, 0.6, 0.6) if st == "disabled" else Color.WHITE)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
	elif sb is StyleBoxFlat and st in ["hover", "focus", "pressed"]:
		(sb as StyleBoxFlat).shadow_size = 14
		(sb as StyleBoxFlat).border_color = border
	return sb


# ---------------------------------------------------------------- barras e selos

static func _bar_image(col: Color, mat: String) -> Image:
	var h := 32
	var img := Image.create(4, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var t := float(y) / (h - 1)
		var c := col
		match mat:
			"glass":
				c = col.lightened(0.35).lerp(col, smoothstep(0.0, 0.5, t)).lerp(col.darkened(0.25), smoothstep(0.6, 1.0, t))
				if y <= 2:
					c = c.lightened(0.55)
			"wood":
				c = col.lightened(0.3).lerp(col, smoothstep(0.0, 0.45, t)).lerp(col.darkened(0.45), smoothstep(0.55, 1.0, t))
				if y == 2 or y == 3:
					c = c.lightened(0.35)
			"stone":
				var glow := 1.0 - absf(t - 0.5) * 2.0
				c = col.darkened(0.35).lerp(col.lightened(0.25), glow * glow)
			_:
				c = col.lightened(0.15).lerp(col.darkened(0.5), t)
				if y == 1:
					c = col.lightened(0.5)
		for x in 4:
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	return img


static func bar_fill(col: Color, h: float) -> StyleBox:
	var mat: String = S["material"]
	var key := "bar/%s/%s" % [mat, col.to_html()]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_bar_image(col, mat))
	var sb := StyleBoxTexture.new()
	sb.texture = _cache[key]
	sb.set_content_margin_all(0)
	return sb


static func bar_back(h: float) -> StyleBox:
	var sb := StyleBoxFlat.new()
	var frame: Color = S["frame"]
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.66)
	sb.border_color = frame.darkened(0.25) if h >= 10 else Color(0, 0, 0, 0.9)
	sb.set_border_width_all(2 if h >= 14 else 1)
	sb.set_content_margin_all(0)
	sb.anti_aliasing = true
	if S["corner"] == "round":
		sb.set_corner_radius_all(int(h * 0.5))
		sb.corner_detail = 8
	else:
		sb.set_corner_radius_all(int(minf(h * 0.4, 5)))
		sb.corner_detail = 1
	return sb


static func badge_box(col: Color, w: float) -> StyleBox:
	var sb := StyleBoxFlat.new()
	sb.anti_aliasing = true
	sb.set_content_margin_all(0)
	var frame: Color = S["frame"]
	match S["badge"]:
		"medal":
			sb.bg_color = col.darkened(0.5)
			sb.border_color = frame
			sb.set_border_width_all(3)
			sb.set_corner_radius_all(int(w * 0.5))
			sb.corner_detail = 12
			sb.shadow_color = Color(0, 0, 0, 0.55)
			sb.shadow_size = 4
		"hex":
			sb.bg_color = col.darkened(0.55)
			sb.border_color = col.lightened(0.25)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(int(w * 0.3))
			sb.corner_detail = 1
		"orb":
			sb.bg_color = Color(col.r * 0.45, col.g * 0.45, col.b * 0.55, 0.9)
			sb.border_color = col.lightened(0.45)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(int(w * 0.5))
			sb.corner_detail = 16
			sb.shadow_color = Color(col.r, col.g, col.b, 0.55)
			sb.shadow_size = 8
		_:
			sb.bg_color = Color(0.06, 0.02, 0.03).lerp(col, 0.25)
			sb.border_color = col.lightened(0.15)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(int(w * 0.5))
			sb.corner_detail = 1
	return sb
