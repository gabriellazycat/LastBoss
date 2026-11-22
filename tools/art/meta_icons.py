# Ícones dos nós do Covil (22/11/2026): um SVG por `icon` de data/meta_tree.json, no traço dos ícones de relíquia
# (tools/art/relic_icons.py: tinta #3a2a1c sobre papel, acento vermelho, roxo do elixir, ouro).
# Gera assets/ui/meta/<icon>.svg. A frente D acrescenta ao dicionário ICONS os ícones dos nós reais; o jogo mostra um
# losango de reserva (game/meta_tree_view.gd) enquanto faltar arquivo.
# Uso: python tools/art/meta_icons.py
import json, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import relic_icons as R

ROOT = R.ROOT
OUT = os.path.join(ROOT, "assets", "ui", "meta")
P, RD, FR, FE, FL, FG, FK = R.P, R.R, R.FR, R.FE, R.FL, R.FG, R.FK

ICONS = {
	"heart": f'''<path d="M30 52 C 8 36 8 16 20 14 C 26 13 29 17 30 21 C 31 17 34 13 40 14 C 52 16 52 36 30 52 Z" {FR}/>
<path d="M30 21 L26 30 L33 34 L29 43" stroke="{R.PAP}" stroke-width="2.4"/>''',
	"elixir": f'''<path d="M25 8 L35 8 M27 8 L27 21 C 14 25 11 43 20 51 L40 51 C 49 43 46 25 33 21 L33 8" {P}/>
<path d="M14 36 C 22 32 38 40 46 36 C 47 42 45 47 40 51 L20 51 C 15 47 13 42 14 36 Z" {FE} stroke="none"/>
<circle cx="25" cy="44" r="2" {FL} stroke="none"/><circle cx="33" cy="41" r="1.4" {FL} stroke="none"/>''',
	"regen": f'''<path d="M30 6 C 22 20 14 28 14 38 C 14 47 21 53 30 53 C 39 53 46 47 46 38 C 46 28 38 20 30 6 Z" {FE}/>
<path d="M22 38 C 22 32 30 30 36 34 M36 34 l-1 -6 M36 34 l-6 1" stroke="{R.PAP}" stroke-width="2.4"/>''',
	"hand": f'''<path d="M14 46 L12 22 L18 20 L18 34 M18 34 L18 12 L24 12 L25 32 M25 32 L26 8 L32 9 L32 32 M32 32 L35 14 L41 16 L38 36 M38 36 L46 26 L50 30 L40 50 L24 52 L14 46" {P}/>''',
	"recarga": f'''<circle cx="30" cy="31" r="19" {P}/><path d="M30 18 L30 31 L40 36" stroke-width="3"/>
<path d="M22 8 L38 8 M30 8 L30 12" stroke-width="3"/><path d="M46 14 l4 -4" {RD} stroke-width="3"/>''',
	"inicio": f'''<rect x="12" y="24" width="36" height="24" rx="3" {P}/><path d="M12 32 L48 32"/>
<path d="M30 6 L36 18 L24 18 Z" {FE}/><path d="M24 40 l12 0" {RD} stroke-width="3"/>''',
	"ritual": f'''<circle cx="30" cy="32" r="19" {P}/><path d="M30 13 L40 44 L16 25 L44 25 L20 44 Z" {RD} stroke-width="2"/>
<circle cx="30" cy="32" r="5" {FE} stroke="none"/><path d="M10 12 l4 4 M50 12 l-4 4" {RD}/>''',
	"loc": f'''<path d="M30 52 C 16 38 12 30 12 24 C 12 14 20 8 30 8 C 40 8 48 14 48 24 C 48 30 44 38 30 52 Z" {P}/>
<circle cx="30" cy="24" r="7" {FR} {RD}/>''',
	"arena": f'''<path d="M6 46 L6 26 L14 26 L14 18 L22 18 L22 26 L38 26 L38 18 L46 18 L46 26 L54 26 L54 46 Z" {P}/>
<path d="M24 46 L24 36 C 24 30 36 30 36 36 L36 46" {FK} stroke="none"/><path d="M6 36 L54 36" opacity=".4"/>''',
	"boss": f'''<path d="M12 44 L12 22 L21 31 L30 16 L39 31 L48 22 L48 44 Z" {P}/><path d="M12 37 L48 37"/>
<path d="M30 39 l3 3 l-3 3 l-3 -3 Z" {FR} {RD}/>''',
	"arm": f'''<path d="M8 46 C 10 30 20 22 34 22 L48 22 L52 30 L40 32 C 34 32 30 38 30 46 Z" {P}/>
<path d="M44 14 L52 22 M48 10 L56 18" {RD} stroke-width="3"/>''',
	"struct": f'''<path d="M10 52 L10 22 L20 14 L30 22 L40 14 L50 22 L50 52 Z" {P}/><rect x="25" y="36" width="10" height="16" {FK} stroke="none"/>
<path d="M10 22 L50 22" opacity=".5"/>''',
	"relic": f'''<path d="M30 6 L38 22 L54 24 L42 36 L46 52 L30 44 L14 52 L18 36 L6 24 L22 22 Z" {FG}/>
<circle cx="30" cy="30" r="5" {FR} {RD}/>''',
	"act": f'''<path d="M6 44 L24 18 L36 36 L42 28 L54 44 Z" {P}/><path d="M24 18 L28 26 L22 25" fill="{R.ICE}"/>
<path d="M10 14 q8 -8 16 0 M34 10 q6 -6 12 0" {RD}/><path d="M6 50 L54 50" stroke-width="3"/>''',
	"offer": f'''<rect x="8" y="12" width="26" height="36" rx="3" {P}/><rect x="26" y="16" width="26" height="36" rx="3" {P}/>
<path d="M33 26 L45 26 M33 34 L45 34 M33 42 L41 42" {RD} stroke-width="2.4"/>''',
	"gold": f'''<ellipse cx="30" cy="40" rx="18" ry="7" {FG}/><ellipse cx="30" cy="33" rx="18" ry="7" {FG}/>
<ellipse cx="30" cy="26" rx="18" ry="7" {FG}/><path d="M12 26 L12 40 M48 26 L48 40"/>''',
	"souls": f'''<path d="M18 50 C 8 38 14 18 30 10 C 46 18 52 38 42 50 C 36 46 24 46 18 50 Z" fill="#cfe3e6"/>
<circle cx="24" cy="30" r="3" {FK} stroke="none"/><circle cx="36" cy="30" r="3" {FK} stroke="none"/><path d="M26 40 q4 3 8 0"/>''',
	"lock": f'''<path d="M21 26 L21 19 Q 21 10 30 10 Q 39 10 39 19 L39 26" stroke-width="3"/><rect x="14" y="26" width="32" height="26" rx="4" {P}/>
<circle cx="30" cy="37" r="3.5" {FK} stroke="none"/><path d="M30 38 L30 45" stroke-width="3"/>''',
	"dim": f'''<path d="M30 8 L52 30 L30 52 L8 30 Z" {P}/><path d="M30 20 L40 30 L30 40 L20 30 Z" opacity=".5"/>''',
}


def main() -> None:
	os.makedirs(OUT, exist_ok=True)
	for i, inner in ICONS.items():
		with open(os.path.join(OUT, i + ".svg"), "w", encoding="utf-8", newline="\n") as f:
			f.write(R.svg(inner))
	print(len(ICONS), "ícones em", OUT)
	try:
		tree = json.load(open(os.path.join(ROOT, "data", "meta_tree.json"), encoding="utf-8"))
		miss = sorted({n.get("icon", "") for n in tree.get("nodes", [])} - set(ICONS) - {""})
		if miss:
			print("aviso: sem ícone (o jogo usa o losango de reserva):", ", ".join(miss))
	except OSError:
		pass


if __name__ == "__main__":
	main()
