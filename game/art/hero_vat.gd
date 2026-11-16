class_name HeroVat
extends HeroRig
## Herói das miniaturas pintadas (docs/MODELOS_GUACHE.md): uma malha só animada por textura (VAT, como os monstros),
## no lugar do esqueleto do KayKit. Lê o estado do herói como o HeroRig: parado, andando, correndo e golpe.
## Sem animação de escudo (bloquear) por enquanto.

var _mi: MeshInstance3D
var _mat: ShaderMaterial
var _t := 0.0
var _lunge := 1.0


static func make_vat(m: Mesh, cls_: String) -> HeroVat:
	var r := HeroVat.new()
	r.cls = cls_
	r._mi = MeshInstance3D.new()
	r._mi.mesh = m
	r._mat = Looks.material(5, 0.05, false, m)
	r._mi.material_override = r._mat
	r.add_child(r._mi)
	return r


func _process(delta: float) -> void:
	if view == null or view.sim == null:
		return
	var h = hero_ref if hero_ref != null else view.sim.hero
	if h.petrify_t > 0.0:
		return
	var spd: float = Vector2(h.x - h.ox, h.y - h.oy).length() / view.sim.dt
	if hero_ref != null:
		if h.atk_t > atk_seen + 0.05:
			_lunge = 0.0
		atk_seen = h.atk_t
	else:
		var sw: float = view.swing_t
		if sw > swing_seen + 0.01:
			_lunge = 0.0
		swing_seen = sw
	var rate := 0.25
	if spd > 3.4:
		rate = clampf(spd / 5.0, 0.7, 1.5) * 1.3
	elif spd > 0.4:
		rate = clampf(spd / 2.2, 0.6, 1.6) * 1.0
	_t += delta * rate
	_mat.set_shader_parameter("pose_frame", fposmod(_t, 1.0))
	if _lunge < 1.0:
		_lunge = minf(_lunge + delta / 0.45, 1.0)
	_mat.set_shader_parameter("pose_lunge", _lunge if _lunge < 1.0 else 0.0)
