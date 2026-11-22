# Ícones dos poderes de party (22/11/2026, frente H): um SVG por poder de data/hero_powers.json, no traço dos ícones
# de relíquia e do Covil (tinta sobre papel, acento vermelho, roxo do elixir, ouro).
# Gera assets/ui/powers/<id>.svg. Uso: python tools/art/power_icons.py
import json, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import relic_icons as R

ROOT = R.ROOT
OUT = os.path.join(ROOT, "assets", "ui", "powers")
P, RD, FR, FE, FL, FG, FK, FI = R.P, R.R, R.FR, R.FE, R.FL, R.FG, R.FK, R.FI

ICONS = {
	"fire_burst": f'''<path d="M30 6 C 40 18 50 24 48 38 C 46 49 38 54 30 54 C 20 54 12 48 12 38 C 12 28 20 24 22 14 C 26 18 28 12 30 6 Z" {FR}/>
<path d="M30 28 C 36 34 40 38 38 45 C 36 50 24 50 22 44 C 21 38 26 36 30 28 Z" {FG}/>''',
	"whirlwind": f'''<path d="M10 18 C 26 8 50 12 50 24 C 50 32 36 32 32 28 M8 30 C 20 22 42 26 42 36 C 42 44 28 44 24 40 M12 44 C 22 38 36 48 30 52" {RD} stroke-width="3"/>
<path d="M10 18 C 26 8 50 12 50 24" opacity=".5"/>''',
	"holy_nova": f'''<circle cx="30" cy="30" r="10" {FG}/><path d="M30 4 L30 14 M30 46 L30 56 M4 30 L14 30 M46 30 L56 30 M12 12 L19 19 M41 41 L48 48 M48 12 L41 19 M19 41 L12 48" {RD} stroke-width="3"/>
<circle cx="30" cy="30" r="18" opacity=".5"/>''',
	"shockwave": f'''<path d="M8 46 L52 46" stroke-width="3"/><path d="M14 46 C 14 32 22 22 30 22 C 38 22 46 32 46 46" {P}/>
<path d="M6 46 C 6 26 18 12 30 12 C 42 12 54 26 54 46" {RD} stroke-width="2.4"/><path d="M26 46 L30 34 L34 46" {FK}/>''',
	"war_cry": f'''<path d="M10 24 L10 38 L20 38 L36 50 L36 12 L20 24 Z" {P}/><path d="M42 20 C 48 26 48 34 42 40 M47 14 C 56 24 56 36 47 46" {RD} stroke-width="3"/>''',
	"chain_lightning": f'''<path d="M34 4 L16 32 L28 32 L22 56 L46 24 L32 24 Z" {FG}/><circle cx="50" cy="12" r="3" {FE} stroke="none"/><circle cx="10" cy="46" r="3" {FE} stroke="none"/>
<path d="M36 10 L48 12 M20 50 L12 46" {RD} stroke-width="2"/>''',
	"smite": f'''<path d="M20 6 L40 6 L36 24 L24 24 Z" {FG}/><path d="M30 24 L30 56" stroke-width="4"/><path d="M30 24 L22 46 M30 24 L38 46" opacity=".5"/>
<path d="M16 38 L44 38" {RD} stroke-width="3"/>''',
	"slay_next": f'''<circle cx="30" cy="30" r="19" {P}/><circle cx="30" cy="30" r="10" {P}/><circle cx="30" cy="30" r="3" {FR} stroke="none"/>
<path d="M6 30 L16 30 M44 30 L54 30 M30 6 L30 16 M30 44 L30 54" {RD} stroke-width="3"/>''',
	"titan_blow": f'''<path d="M8 50 L48 10" stroke-width="5"/><path d="M38 6 L54 6 L54 22 L46 22 L38 14 Z" {P}/>
<path d="M8 50 L14 56 L4 56 Z" {FK}/><path d="M12 22 l-6 -4 M18 14 l-3 -7 M46 36 l7 3" {RD} stroke-width="2.6"/>''',
	"soul_drain": f'''<path d="M30 8 C 44 8 52 20 48 34 C 46 44 38 52 30 52 C 22 52 14 44 12 34 C 8 20 16 8 30 8 Z" {FI}/>
<circle cx="23" cy="26" r="3.2" {FK} stroke="none"/><circle cx="37" cy="26" r="3.2" {FK} stroke="none"/><path d="M24 38 q6 5 12 0" />
<path d="M30 52 C 30 56 26 58 24 58" {RD}/>''',
	"structure_breaker": f'''<path d="M8 52 L8 26 L16 26 L16 18 L24 18 L24 26 L36 26 L36 18 L44 18 L44 26 L52 26 L52 52 Z" {P}/>
<path d="M30 8 L24 28 L32 28 L26 50" {RD} stroke-width="3.2"/><path d="M40 36 l4 4 M12 38 l5 3" opacity=".6"/>''',
	"spell_ward": f'''<path d="M30 6 L50 14 L50 32 C 50 44 40 52 30 56 C 20 52 10 44 10 32 L10 14 Z" {FE}/>
<path d="M30 16 L30 46 M18 28 L42 28" stroke="{R.PAP}" stroke-width="2.6"/><circle cx="30" cy="28" r="6" stroke="{R.PAP}" stroke-width="2"/>''',
	"purify": f'''<path d="M30 6 C 22 20 14 28 14 38 C 14 47 21 53 30 53 C 39 53 46 47 46 38 C 46 28 38 20 30 6 Z" {FI}/>
<path d="M22 38 L28 44 L40 30" {RD} stroke-width="3.4"/>''',
	"second_wind": f'''<path d="M30 52 C 8 36 8 16 20 14 C 26 13 29 17 30 21 C 31 17 34 13 40 14 C 52 16 52 36 30 52 Z" {FR}/>
<path d="M12 56 C 24 50 40 56 50 50" stroke-width="2.4" opacity=".6"/><path d="M30 22 L30 40 M22 31 L38 31" stroke="{R.PAP}" stroke-width="3"/>''',
	"iron_will": f'''<path d="M12 12 L48 12 L48 30 C 48 42 38 50 30 54 C 22 50 12 42 12 30 Z" {P}/><path d="M12 24 L48 24 M30 12 L30 54" opacity=".6"/>
<path d="M22 8 L22 14 M38 8 L38 14" {RD} stroke-width="3"/>''',
	"fire_ward": f'''<path d="M12 12 L48 12 L48 30 C 48 42 38 50 30 54 C 22 50 12 42 12 30 Z" {P}/>
<path d="M30 18 C 36 26 40 30 38 38 C 36 44 24 44 22 38 C 21 32 26 30 30 18 Z" {FR}/><path d="M30 30 C 33 34 34 36 33 39 C 31 41 28 41 27 39 C 26 36 28 34 30 30 Z" {FG} stroke="none"/>''',
	"arrow_wall": f'''<path d="M6 54 L54 54" stroke-width="3"/><path d="M12 54 L12 14 M24 54 L24 8 M36 54 L36 14 M48 54 L48 8" stroke-width="2.6"/>
<path d="M8 20 L12 12 L16 20 M20 14 L24 6 L28 14 M32 20 L36 12 L40 20 M44 14 L48 6 L52 14" {RD}/>''',
	"retaliation": f'''<path d="M10 14 L30 30 L50 14" stroke-width="3.4" {RD}/><path d="M50 46 L30 30 L10 46" stroke-width="3.4"/><circle cx="30" cy="30" r="6" {FG}/>
<path d="M4 30 l8 0 M48 30 l8 0" opacity=".5"/>''',
	"ally_rat": f'''<path d="M10 40 C 10 28 24 22 36 26 C 44 28 50 34 50 40 C 50 46 40 48 30 48 C 18 48 10 46 10 40 Z" {P}/>
<path d="M44 30 L50 24 L54 30" {P}/><circle cx="46" cy="36" r="1.8" {FK} stroke="none"/><path d="M10 38 C 4 36 2 44 6 50 C 8 54 14 54 16 52" {RD}/>
<path d="M18 48 l0 5 M34 48 l0 5"/>''',
	"war_hound": f'''<path d="M8 38 C 8 28 20 24 30 26 L40 18 L46 20 L50 28 L44 32 C 44 38 42 42 40 48 L34 48 L32 40 L18 40 L14 48 L8 48 Z" {P}/>
<path d="M40 18 L38 10 L45 15" {P}/><circle cx="43" cy="24" r="1.8" {FK} stroke="none"/><path d="M14 28 L18 26" {RD} stroke-width="3"/>''',
	"field_medic": f'''<rect x="10" y="10" width="40" height="40" rx="6" {P}/><path d="M30 18 L30 42 M18 30 L42 30" {RD} stroke-width="7"/>
<path d="M30 18 L30 42 M18 30 L42 30" stroke="{R.PAP}" stroke-width="2.2" opacity=".0"/>''',
}


def main() -> None:
	os.makedirs(OUT, exist_ok=True)
	for i, inner in ICONS.items():
		with open(os.path.join(OUT, i + ".svg"), "w", encoding="utf-8", newline="\n") as f:
			f.write(R.svg(inner))
	print(len(ICONS), "ícones em", OUT)
	ids = [p["id"] for p in json.load(open(os.path.join(ROOT, "data", "hero_powers.json"), encoding="utf-8"))["powers"]]
	miss = [i for i in ids if i not in ICONS]
	if miss:
		print("FALTAM:", ", ".join(miss))
		sys.exit(1)


if __name__ == "__main__":
	main()
