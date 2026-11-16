extends SceneTree
## Prancha de mapas com rios (15/11/2026): gera estradas reais e escreve um SVG por cima (vista de cima, em metros).
## godot --headless -s res://tools/river/sheet.gd -- --out=<arquivo.svg> --seeds=1-12 --act=0
var args_debug := false
const COL := {"shop": "#c9a14a", "tavern": "#b5651d", "fountain": "#3d8fd1", "ritual": "#9b4dca", "shrine": "#3fbf7f",
	"bridge": "#7a4a22", "event": "#888888", "helper": "#e0b000"}

func _init() -> void:
	SimRivers.DEBUG = true
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var out: String = args.get("out", "user://rios.svg")
	args_debug = args.has("debug")
	var sr: PackedStringArray = str(args.get("seeds", "1-12")).split("-")
	var acts: Array = []
	for x in str(args.get("act", "0")).split(","):
		acts.append(int(x))
	var data := GameData.load_dir()
	var RV: Dictionary = data.rules["road"]["river"]
	var cells: Array = []
	for seed_ in range(int(sr[0]), int(sr[-1]) + 1):
		for act in acts:
			var road := SimRoad.new()
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_ * 7919 + act * 104729
			var cfg: Dictionary = data.rules["acts"][mini(act, data.rules["acts"].size() - 1)].get("road", {})
			SimRivers.FAILS.clear()
			road.generate(rng, data.rules, cfg)
			cells.append(_cell(road, RV, "semente %d, ato %d" % [seed_, act + 1]))
	var cols := 6
	var cw := 330.0
	var ch := 560.0
	var rows_ := int(ceil(cells.size() / float(cols)))
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" style="background:#e9e2cc;font-family:sans-serif">' % [cols * cw, rows_ * ch]
	for i in cells.size():
		svg += '<g transform="translate(%d,%d)">%s</g>' % [(i % cols) * cw, (i / cols) * ch, cells[i]]
	svg += "</svg>"
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(svg)
	f.close()
	var img := Image.new()
	if img.load_svg_from_string(svg, 1.0) == OK:
		img.save_png(out.get_basename() + ".png")
	print("prancha: ", out, " (", cells.size(), " mapas) motivos: ", SimRivers.STATS)
	quit()


## Uma célula: o mapa escalado para caber em 310 x 500 px, com o norte (sentido do herói) para cima.
func _cell(road: SimRoad, RV: Dictionary, title: String) -> String:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for g in road.legs:
		for p in g["pts"][0]:
			lo = lo.min(p)
			hi = hi.max(p)
	lo -= Vector2(45, 20)
	hi += Vector2(45, 20)
	var sc := minf(310.0 / (hi.x - lo.x), 500.0 / (hi.y - lo.y))
	var tf := func(p: Vector2) -> Vector2: return Vector2(10, 40) + (p - lo) * sc
	var s := '<clipPath id="c%d"><rect x="0" y="30" width="330" height="520"/></clipPath>' % hash(title)
	s += '<text x="10" y="20" font-size="14">%s — %d rio(s), %d ponte(s)</text>' % [title, road.rivers.size(), road.rivers.reduce(func(a, r): return a + r["bridges"].size(), 0)]
	s += '<g clip-path="url(#c%d)">' % hash(title)
	for r in road.rivers:
		var d := ""
		for p in r["pts"]:
			var q: Vector2 = tf.call(p)
			d += "%.1f,%.1f " % [q.x, q.y]
		s += '<polyline points="%s" fill="none" stroke="#6f9fb8" stroke-width="%.2f" stroke-linejoin="round" stroke-linecap="round" opacity="0.9"/>' % [d, 2.0 * float(RV["half_width"]) * sc]
	for g in road.legs:
		var d := ""
		for p in g["pts"][0]:
			var q: Vector2 = tf.call(p)
			d += "%.1f,%.1f " % [q.x, q.y]
		s += '<polyline points="%s" fill="none" stroke="#5a4630" stroke-width="%.2f" stroke-linejoin="round"/>' % [d, maxf(1.2, 3.0 * sc)]
	for r in road.rivers:
		for n in r["bridges"]:
			var p: Vector2 = road.nodes[n]["pos"]
			var ax := SimRivers.bridge_axis(road, n)
			var a: Vector2 = tf.call(p - ax * float(RV["bridge_half"]))
			var b: Vector2 = tf.call(p + ax * float(RV["bridge_half"]))
			s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#7a4a22" stroke-width="%.2f"/>' % [a.x, a.y, b.x, b.y, 5.0 * sc]
	if args_debug:
		for f in SimRivers.FAILS.slice(0, 3):
			var d := ""
			for p in f["pts"]:
				var q: Vector2 = tf.call(p)
				d += "%.1f,%.1f " % [q.x, q.y]
			s += '<polyline points="%s" fill="none" stroke="#d03030" stroke-width="1.5" opacity="0.7"/>' % d
			var q: Vector2 = tf.call(f["p"])
			s += '<circle cx="%.1f" cy="%.1f" r="6" fill="none" stroke="#ff0000" stroke-width="2"/>' % [q.x, q.y]
			var a: Vector2 = tf.call(f["s"][0])
			var b: Vector2 = tf.call(f["s"][1])
			s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#ff00ff" stroke-width="3"/>' % [a.x, a.y, b.x, b.y]
	for li in road.locations.size():
		var loc: Dictionary = road.locations[li]
		var q: Vector2 = tf.call(loc["pos"])
		s += '<circle cx="%.1f" cy="%.1f" r="5" fill="%s" stroke="#222" stroke-width="1"/>' % [q.x, q.y, COL.get(loc["type"], "#000")]
	for n in [0, road.nodes.size() - 1]:
		var q: Vector2 = tf.call(road.nodes[n]["pos"])
		s += '<rect x="%.1f" y="%.1f" width="10" height="10" fill="#222"/>' % [q.x - 5, q.y - 5]
	s += "</g>"
	return s
