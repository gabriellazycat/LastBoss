class_name UiSkins
extends RefCounted
## Paleta da interface (pele "Mapa aberto", 13/11/2026): o desenho das peças fica em UiDiario e UiParch (papel, tinta,
## fita e selos, kit em assets/ui/kit_mapa). apply() passa as cores para as variáveis do UiKit.

const DEFAULT := {
	"BG": Color(0.055, 0.04, 0.085, 0.92), "BG_SOFT": Color(0.05, 0.035, 0.08, 0.72), "EDGE": Color(0.42, 0.3, 0.6),
	"GOLD": Color(1.0, 0.76, 0.36), "TEXT": Color(0.95, 0.92, 1.0), "MUTED": Color(0.72, 0.68, 0.82),
	"HERO_HP": Color(0.9, 0.24, 0.22), "HERO_XP": Color(1.0, 0.7, 0.3), "POWER": Color(0.72, 0.42, 1.0),
	"ELIXIR": Color(0.86, 0.32, 0.96), "GOOD": Color(0.45, 1.0, 0.6), "BAD": Color(1.0, 0.45, 0.4),
}

static var _applied := false


## Passa a paleta para o UiKit (uma vez).
static func apply() -> void:
	if _applied:
		return
	_applied = true
	var pal: Dictionary = DEFAULT.duplicate()
	pal.merge(UiDiario.PAL, true)
	UiKit.RARITY_COLORS = UiDiario.RARITY.duplicate()
	Tips.KW_COLOR = Color(0.5, 0.09, 0.05)
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
