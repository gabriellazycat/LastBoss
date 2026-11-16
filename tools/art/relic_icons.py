# Ícones das relíquias (15/11/2026): um SVG minimalista por relíquia, no traço dos ícones do mapa
# (tinta #3a2a1c sobre papel #e3cf9f, acento vermelho), com cor própria para elixir, ouro e gelo.
# Gera assets/ui/relics/<id>.svg (o jogo e a página docs/reliquias/ usam os mesmos arquivos).
# Uso: python tools/art/relic_icons.py
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "ui", "relics")

INK = "#3a2a1c"
PAP = "#e3cf9f"
RED = "#a8323a"
ELX = "#7a4fd0"
ELL = "#b79ae8"
GLD = "#d9a640"
ICE = "#bcd8dc"

P = f'fill="{PAP}"'
R = f'stroke="{RED}"'
FR = f'fill="{RED}"'
FE = f'fill="{ELX}"'
FL = f'fill="{ELL}"'
FG = f'fill="{GLD}"'
FI = f'fill="{ICE}"'
FK = f'fill="{INK}"'

ICONS = {
	# --- antigas ---
	"bone_crown": f'''<path d="M12 44 L12 22 L21 31 L30 16 L39 31 L48 22 L48 44 Z" {P}/>
<path d="M12 37 L48 37"/><circle cx="12" cy="19" r="3" {P}/><circle cx="30" cy="13" r="3" {P}/><circle cx="48" cy="19" r="3" {P}/>
<path d="M30 39 l3 3 l-3 3 l-3 -3 Z" {FR} {R}/><path d="M19 41 l0 0.1 M41 41 l0 0.1" stroke-width="3"/>''',
	"lair_tithe": f'''<ellipse cx="22" cy="46" rx="12" ry="4.5" {FG}/><path d="M10 46 L10 40" /><path d="M34 46 L34 40"/>
<ellipse cx="22" cy="40" rx="12" ry="4.5" {FG}/><ellipse cx="22" cy="33" rx="10" ry="4" {FG}/>
<path d="M36 10 L44 30 M43 8 L51 28 M50 9 L56 24" {R} stroke-width="3"/>''',
	"black_mortar": f'''<rect x="7" y="34" width="22" height="9" {P}/><rect x="29" y="34" width="24" height="9" {P}/>
<rect x="15" y="43" width="28" height="9" {P}/><path d="M36 26 L52 10 L56 14 L40 30 Z" {FK}/><path d="M36 26 L28 22" {R} stroke-width="3.2"/>
<path d="M12 30 q6 -4 12 0" opacity=".6"/>''',
	"victory_horn": f'''<g transform="translate(6 7) scale(0.8)"><path d="M8 46 C 22 52 38 42 43 24" stroke-width="10"/><path d="M8 46 C 22 52 38 42 43 24" stroke="{PAP}" stroke-width="6"/>
<path d="M36 26 L48 6 L58 18 L44 30 Z" {P}/><ellipse cx="53" cy="12" rx="8" ry="3.4" transform="rotate(42 53 12)" fill="#c9b07a"/>
<path d="M20 44 l3 -5 M30 40 l4 -4" stroke-width="2"/><path d="M26 44 C 26 50 22 54 20 56 M28 44 C 30 50 30 54 28 57" {R} stroke-width="2.4"/>
<path d="M8 46 l-4 1" stroke-width="3"/></g>''',
	"cracked_hourglass": f'''<path d="M16 8 L44 8 M16 52 L44 52" stroke-width="3"/>
<path d="M19 8 C 19 22 28 25 30 30 C 32 25 41 22 41 8 Z" {P}/><path d="M19 52 C 19 38 28 35 30 30 C 32 35 41 38 41 52 Z" {P}/>
<path d="M24 52 C 26 45 34 45 36 52 Z" {FR} {R}/><path d="M30 31 L30 46" {R}/><path d="M37 13 l-4 5 l4 3 l-3 5"/>''',
	"jailer_chains": f'''<ellipse cx="13" cy="34" rx="8" ry="5" transform="rotate(-25 13 34)"/><ellipse cx="25" cy="29" rx="8" ry="5" transform="rotate(-25 25 29)"/>
<path d="M33 20 C 33 10 51 10 51 20 L51 22" stroke-width="3"/><rect x="29" y="22" width="26" height="24" rx="3" {P}/>
<circle cx="42" cy="31" r="3" {FR} {R}/><path d="M42 33 L42 40" {R} stroke-width="3"/>''',
	"watchful_eye": f'''<path d="M6 30 C 16 16 44 16 54 30 C 44 44 16 44 6 30 Z" {P}/><circle cx="30" cy="30" r="9" {FR} {R}/>
<circle cx="30" cy="30" r="3.5" {FK}/><path d="M14 18 l-3 -5 M22 14 l-1 -6 M30 13 l0 -6 M38 14 l1 -6 M46 18 l3 -5"/>''',
	"pack_howl": f'''<path d="M12 8 L23 20 L37 20 L48 8 L50 30 L37 52 L23 52 L10 30 Z" {P}/>
<path d="M15 14 L20 24 M45 14 L40 24" opacity=".55"/><path d="M20 32 L27 34 M40 32 L33 34" {R} stroke-width="3"/>
<path d="M23 52 L30 40 L37 52" /><path d="M27 42 L33 42 L30 46 Z" {FK}/><path d="M30 20 L30 28" opacity=".45"/>
<path d="M4 40 q-2 5 1 9 M56 40 q2 5 -1 9" {R}/>''',
	"merchant_purse": f'''<path d="M20 22 C 6 34 10 53 30 53 C 50 53 54 34 40 22 Z" {P}/><path d="M22 21 L38 21" stroke-width="3"/>
<path d="M20 12 L26 20 M40 12 L34 20 M24 10 l12 0" {R} stroke-width="2.6"/><circle cx="30" cy="38" r="6" {FG}/><path d="M30 35 l0 6" />''',
	"overflowing_chalice": f'''<path d="M14 14 L46 14 C 46 30 38 35 30 35 C 22 35 14 30 14 14 Z" {P}/><path d="M15 19 L45 19 C 44 28 37 32 30 32 C 23 32 16 28 15 19 Z" {FE} stroke="none"/>
<path d="M30 35 L30 46 M20 50 C 22 46 38 46 40 50 Z" {P}/><path d="M14 14 C 10 20 12 26 9 30" stroke="{ELX}" stroke-width="2.6"/>
<circle cx="9" cy="35" r="2.2" {FE} stroke="none"/><path d="M46 14 C 50 22 48 26 51 31" stroke="{ELX}" stroke-width="2.6"/><circle cx="51" cy="36" r="2" {FE} stroke="none"/>''',
	"shortcut_stone": f'''<path d="M10 44 C 6 32 14 20 28 18 C 42 16 54 26 52 38 C 50 50 36 54 24 52 C 16 51 12 48 10 44 Z" {P}/>
<path d="M20 32 l6 4 M36 42 l5 -3" opacity=".55"/><path d="M8 18 C 24 6 42 10 52 26" {R} stroke-width="3" stroke-dasharray="5 4"/>
<path d="M44 26 L53 28 L54 19" {R} stroke-width="3"/>''',
	"profane_earth": f'''<path d="M4 52 C 14 38 46 38 56 52 Z" {P}/><path d="M18 46 l4 2 M36 44 l4 2" opacity=".55"/>
<path d="M26 42 L26 24 M30 42 L30 18 M34 42 L34 21 M38 42 L38 27 M26 32 C 22 30 20 26 21 22" stroke-width="2.6"/>
<path d="M24 42 C 24 36 40 36 40 42" {P}/><path d="M14 18 l4 4 M46 14 l-4 4 M30 8 l0 4" {R}/>''',
	"bad_blood": f'''<path d="M30 6 C 22 20 14 28 14 38 C 14 47 21 53 30 53 C 39 53 46 47 46 38 C 46 28 38 20 30 6 Z" {FR} {R}/>
<path d="M22 36 l5 5 M27 36 l-5 5 M33 36 l5 5 M38 36 l-5 5" stroke="{PAP}" stroke-width="2.4"/><path d="M24 47 q6 -4 12 0" stroke="{PAP}" stroke-width="2.2"/>''',
	"heavy_grimoire": f'''<path d="M10 18 L42 12 L48 46 L16 52 Z" {P}/><path d="M10 18 L8 22 L14 56 L16 52"/><path d="M8 22 L14 56 L46 50 L48 46"/>
<path d="M14 32 L46 26" {R} stroke-width="4"/><rect x="24" y="26" width="7" height="7" transform="rotate(-10 27 29)" {FG}/>
<path d="M22 20 l14 -2" opacity=".5"/>''',
	"elixir_flask": f'''<path d="M25 8 L35 8 M27 8 L27 21 C 14 25 11 43 20 51 L40 51 C 49 43 46 25 33 21 L33 8" {P}/>
<path d="M14 36 C 22 32 38 40 46 36 C 47 42 45 47 40 51 L20 51 C 15 47 13 42 14 36 Z" {FE} stroke="none"/>
<path d="M27 21 C 14 25 11 43 20 51 L40 51 C 49 43 46 25 33 21"/><circle cx="25" cy="44" r="2" fill="{ELL}" stroke="none"/><circle cx="33" cy="41" r="1.4" fill="{ELL}" stroke="none"/>''',
	"quick_spring": f'''<path d="M4 50 C 16 44 44 44 56 50" {P}/><path d="M30 46 C 30 30 26 20 18 14 M30 46 C 30 30 34 20 42 14 M30 46 L30 10" stroke="{ELX}" stroke-width="3"/>
<circle cx="16" cy="18" r="2.4" {FE} stroke="none"/><circle cx="44" cy="18" r="2.4" {FE} stroke="none"/><circle cx="30" cy="7" r="2.4" {FE} stroke="none"/>
<path d="M8 26 l8 0 M44 28 l8 0 M6 34 l6 0" {R}/>''',
	"deep_cauldron": f'''<path d="M10 26 L50 26 C 50 42 42 50 30 50 C 18 50 10 42 10 26 Z" {P}/><ellipse cx="30" cy="26" rx="20" ry="5" {FE}/>
<path d="M14 48 l-3 6 M46 48 l3 6"/><path d="M8 26 l-3 -2 M52 26 l3 -2" stroke-width="3"/>
<circle cx="24" cy="16" r="3" fill="{ELL}"/><circle cx="34" cy="11" r="2" fill="{ELL}"/><circle cx="38" cy="18" r="1.6" fill="{ELL}"/>''',
	"rushing_tide": f'''<path d="M4 50 C 8 34 18 18 34 14 C 46 11 56 20 52 30 C 49 36 40 36 40 29 C 40 25 45 25 45 28 C 40 36 26 34 24 50 Z" {FE}/>
<path d="M4 50 L56 50" stroke-width="2.4"/><path d="M14 40 q6 -8 14 -12" stroke="{ELL}"/><path d="M50 40 l6 0 M46 45 l8 0" {R}/>''',
	"victory_mark": f'''<path d="M18 50 C 8 40 8 22 18 12 M42 50 C 52 40 52 22 42 12"/>
<path d="M14 42 q-6 -2 -6 -8 q6 1 6 8 M11 30 q-6 -3 -4 -9 q5 3 4 9 M14 19 q-3 -5 1 -9 q3 5 -1 9 M46 42 q6 -2 6 -8 q-6 1 -6 8 M49 30 q6 -3 4 -9 q-5 3 -4 9 M46 19 q3 -5 -1 -9 q-3 5 1 9" {P}/>
<path d="M30 18 L33 27 L42 27 L35 33 L38 42 L30 36 L22 42 L25 33 L18 27 L27 27 Z" {FR} {R}/>''',
	"heart_of_well": f'''<path d="M12 32 L48 32 L48 52 L12 52 Z" {P}/><path d="M12 40 L48 40 M24 32 L24 40 M36 32 L36 40 M18 40 L18 52 M30 40 L30 52 M42 40 L42 52" opacity=".6"/>
<path d="M14 32 L14 14 M46 32 L46 14 M8 16 L30 6 L52 16" stroke-width="2.6"/><path d="M30 10 L30 20"/>
<path d="M30 30 C 24 25 22 21 26 19 C 28 18 30 20 30 21 C 30 20 32 18 34 19 C 38 21 36 25 30 30 Z" {FE} stroke="{ELX}"/>''',
	"eternal_fountain": f'''<path d="M8 46 C 8 54 52 54 52 46 Z" {P}/><path d="M26 46 L27 30 L33 30 L34 46" {P}/><path d="M18 30 C 18 35 42 35 42 30 Z" {P}/>
<path d="M30 30 L30 16 M30 16 C 24 12 18 18 18 28 M30 16 C 36 12 42 18 42 28" stroke="{ELX}" stroke-width="2.6"/>
<path d="M22 10 C 22 6 28 6 30 10 C 32 14 38 14 38 10 C 38 6 32 6 30 10 C 28 14 22 14 22 10 Z" stroke="{RED}"/>
<path d="M12 46 q4 -3 8 0 M40 46 q4 -3 8 0" stroke="{ELX}"/>''',
	"living_vault": f'''<path d="M8 30 L52 30 L52 52 L8 52 Z" {P}/><path d="M8 30 C 8 14 52 14 52 30" {P}/>
<path d="M8 30 L14 36 L20 30 L26 36 L32 30 L38 36 L44 30 L50 36 L52 30" {R} stroke-width="2.4"/>
<ellipse cx="30" cy="22" rx="6" ry="4" fill="#fff4d8"/><circle cx="30" cy="22" r="2" {FK}/><rect x="26" y="40" width="8" height="8" {FG}/>''',
	"hand_pocket": f'''<path d="M22 8 L40 6 L42 30 L24 32 Z" fill="#fff4d8"/><path d="M27 12 l10 -1 M27 17 l8 -1" {R}/>
<path d="M10 22 L50 22 L48 44 C 40 54 20 54 12 44 Z" {P}/><path d="M10 22 C 16 30 44 30 50 22"/><path d="M16 40 C 22 46 38 46 44 40" stroke-dasharray="3 3" opacity=".6"/>''',
	"opening_gambit": f'''<circle cx="28" cy="16" r="6" {P}/><path d="M22 24 L34 24 L32 38 L24 38 Z" {P}/><path d="M16 50 C 16 42 40 42 40 50 Z" {P}/>
<path d="M18 40 L38 40" stroke-width="2.6"/><path d="M48 46 L48 14 M42 20 L48 12 L54 20" {R} stroke-width="3"/>''',
	"act_hoard": f'''<path d="M6 52 C 10 36 22 30 30 30 C 38 30 50 36 54 52 Z" {FG}/>
<ellipse cx="20" cy="44" rx="4" ry="2" {P}/><ellipse cx="38" cy="40" rx="4" ry="2" {P}/><ellipse cx="30" cy="48" rx="4" ry="2" {P}/>
<path d="M30 10 L38 18 L30 30 L22 18 Z" {FR} {R}/><path d="M22 18 L38 18" stroke="{PAP}"/><path d="M14 18 l-4 -4 M46 18 l4 -4 M30 4 l0 3"/>''',
	"twin_litter": f'''<circle cx="20" cy="34" r="10" {P}/><circle cx="12" cy="24" r="5" {P}/><circle cx="26" cy="23" r="5" {P}/>
<circle cx="40" cy="38" r="10" {P}/><circle cx="33" cy="28" r="5" {P}/><circle cx="47" cy="27" r="5" {P}/>
<circle cx="17" cy="33" r="1.3" {FK}/><circle cx="23" cy="33" r="1.3" {FK}/><circle cx="37" cy="37" r="1.3" {FK}/><circle cx="43" cy="37" r="1.3" {FK}/>
<path d="M20 38 l0 1 M40 42 l0 1" {R} stroke-width="3"/><path d="M28 50 l4 0" {R}/>''',
	"phylactery": f'''<path d="M30 4 L30 12" /><path d="M24 4 C 24 0 36 0 36 4" />
<path d="M22 14 L38 14 L46 30 L30 54 L14 30 Z" {P}/><path d="M14 30 L46 30 M22 14 L30 30 L38 14" opacity=".5"/>
<path d="M30 40 C 25 36 23 32 26 30 C 28 29 30 31 30 32 C 30 31 32 29 34 30 C 37 32 35 36 30 40 Z" {FR} {R}/>''',
	"greedy_seal": f'''<path d="M20 40 L14 56 L22 52 L26 58 L28 42" {FR} {R}/><path d="M40 40 L46 56 L38 52 L34 58 L32 42" {FR} {R}/>
<path d="M30 8 C 36 8 38 12 44 12 C 50 16 48 20 52 26 C 52 32 48 34 46 40 C 40 44 36 42 30 46 C 24 42 20 44 14 40 C 12 34 8 32 8 26 C 12 20 10 16 16 12 C 22 12 24 8 30 8 Z" {FR} {R}/>
<path d="M22 22 C 26 16 34 16 38 22 C 34 32 26 32 22 22 Z" stroke="{PAP}"/><circle cx="30" cy="24" r="2" fill="{PAP}" stroke="none"/>''',
	"grave_call": f'''<path d="M16 52 L16 22 C 16 8 44 8 44 22 L44 52 Z" {P}/><path d="M30 18 L30 36 M24 24 L36 24" stroke-width="2.6"/>
<path d="M8 52 L52 52" stroke-width="2.6"/><path d="M6 14 q-3 6 0 12 M54 14 q3 6 0 12 M10 18 q-2 4 0 6 M50 18 q2 4 0 6" {R}/>''',
	"lucky_coin": f'''<circle cx="30" cy="30" r="21" {FG}/><circle cx="30" cy="30" r="16"/>
<circle cx="25" cy="25" r="5" {FR} {R}/><circle cx="35" cy="25" r="5" {FR} {R}/><circle cx="25" cy="35" r="5" {FR} {R}/><circle cx="35" cy="35" r="5" {FR} {R}/>
<path d="M30 30 C 32 36 36 40 40 42" stroke-width="2.4"/>''',
	"war_drum": f'''<ellipse cx="30" cy="26" rx="18" ry="6" {P}/><path d="M12 26 L12 46 C 12 54 48 54 48 46 L48 26" {P}/><ellipse cx="30" cy="26" rx="18" ry="6" {P}/>
<path d="M12 30 L20 48 L30 32 L40 48 L48 30" {R}/><path d="M14 6 L28 22 M46 6 L32 22" stroke-width="3"/><circle cx="13" cy="5" r="2.6" {FK}/><circle cx="47" cy="5" r="2.6" {FK}/>''',
	"forge_hammer": f'''<path d="M10 36 L50 36 C 50 40 46 42 40 42 L37 47 L43 53 L17 53 L23 47 L20 42 L10 42 C 6 42 3 39 2 36 Z" {FK}/>
<path d="M18 30 L42 10" stroke-width="7"/><path d="M18 30 L42 10" stroke="#c9b07a" stroke-width="3.4"/>
<rect x="36" y="4" width="20" height="10" rx="1.5" transform="rotate(50 46 9)" {P}/>
<path d="M28 32 l-2 -6 M22 34 l-8 -4 M34 33 l4 -5" {R} stroke-width="2.4"/>''',
	"tinker_file": f'''<path d="M14 50 L44 10 L50 14 L20 54 Z" {P}/><path d="M22 42 l5 3 M26 36 l5 3 M30 31 l5 3 M34 25 l5 3 M38 20 l5 3" opacity=".6"/>
<path d="M14 50 L8 56" stroke-width="3.4"/><path d="M50 36 l4 2 M46 42 l6 0 M50 46 l3 3" {R}/>''',
	"blood_tithe": f'''<path d="M30 4 L34 10 L33 30 L27 30 L26 10 Z" fill="#fff4d8"/><path d="M22 30 L38 30 M30 30 L30 38" stroke-width="3"/>
<path d="M30 40 C 27 44 27 46 30 47 C 33 46 33 44 30 40 Z" {FR} {R}/>
<path d="M10 46 C 10 56 50 56 50 46 Z" {P}/><path d="M16 47 C 24 50 36 50 44 47" {R} stroke-width="3"/>''',
	"tar_pit": f'''<path d="M6 44 C 6 34 54 34 54 44 C 54 54 6 54 6 44 Z" {FK}/>
<circle cx="20" cy="34" r="4" {FK}/><circle cx="36" cy="30" r="3" {FK}/><circle cx="44" cy="20" r="2" fill="none"/><circle cx="18" cy="22" r="2.4" fill="none"/>
<path d="M26 40 C 26 34 34 34 34 40" stroke="{PAP}"/><path d="M14 46 q4 -2 8 0" stroke="{RED}"/>''',
	"stamp_ink": f'''<path d="M24 8 C 24 2 36 2 36 8 L34 22 L26 22 Z" {P}/><path d="M16 22 L44 22 L44 32 L16 32 Z" {P}/>
<path d="M14 40 L46 40 L44 54 L16 54 Z" fill="none" {R} stroke-width="2.6"/><path d="M22 46 L38 46 M24 50 L36 50" {R} stroke-width="2.6"/>''',
	"deep_cistern": f'''<path d="M6 54 L6 24 C 6 8 54 8 54 24 L54 54" {P}/><path d="M12 54 L12 26 C 12 14 48 14 48 26 L48 54" fill="#5a4a38"/>
<path d="M12 40 L48 40 L48 54 L12 54 Z" {FE} stroke="none"/><path d="M14 40 q4 -3 8 0 t8 0 t8 0 t8 0" stroke="{ELL}"/>
<path d="M22 18 L22 50 M30 18 L30 50 M22 26 L30 26 M22 34 L30 34" stroke="{PAP}"/>''',
	"copper_tap": f'''<path d="M6 14 L22 14 L22 24 L6 24 Z" {P}/><path d="M22 16 L38 16 C 46 16 48 22 48 28 L40 28 C 40 24 38 24 36 24 L22 24" fill="#c47a3c"/>
<path d="M28 16 L28 8 M22 8 L34 8" stroke-width="3"/><path d="M44 32 C 40 38 40 42 44 43 C 48 42 48 38 44 32 Z" {FE}/>
<path d="M30 54 C 36 48 52 48 58 54" stroke="{ELX}"/><circle cx="44" cy="50" r="1.6" {FE} stroke="none"/>''',
	"still_aether": f'''<circle cx="30" cy="26" r="18" fill="#efe6d0"/><path d="M14 30 C 20 24 26 34 32 28 C 38 22 42 30 46 28 C 44 38 38 44 30 44 C 22 44 16 38 14 30 Z" {FE} stroke="none"/>
<circle cx="30" cy="26" r="18"/><path d="M22 14 q4 -4 8 -4" stroke="#fff" opacity=".9"/>
<path d="M18 52 L42 52 L38 44 L22 44 Z" {P}/>''',
	"aether_heart": f'''<path d="M30 50 C 14 38 8 28 12 20 C 16 12 26 12 30 20 C 34 12 44 12 48 20 C 52 28 46 38 30 50 Z" {FE}/>
<path d="M22 22 C 24 20 26 20 28 22" stroke="{ELL}"/><path d="M30 20 L30 12 M30 12 L26 6 M30 12 L34 6" stroke-width="2.4"/>
<path d="M6 32 l-4 0 M54 32 l4 0 M10 44 l-3 3 M50 44 l3 3" {R}/>''',
	"living_library": f'''<path d="M6 40 C 14 36 24 36 30 42 C 36 36 46 36 54 40 L54 54 C 46 50 36 50 30 56 C 24 50 14 50 6 54 Z" {P}/><path d="M30 42 L30 56"/>
<path d="M30 40 C 30 30 30 22 30 14" stroke-width="2.4"/><path d="M30 26 C 22 26 18 20 18 14 C 24 14 30 18 30 26 Z M30 20 C 38 20 42 14 42 8 C 36 8 30 12 30 20 Z" fill="#9db068"/>
<path d="M12 44 l10 0 M38 44 l10 0" opacity=".55"/>''',
	# --- novas (15/11/2026) ---
	"fine_sand": f'''<g transform="rotate(-18 30 30)"><path d="M18 8 L42 8 M18 52 L42 52" stroke-width="3"/>
<path d="M21 8 C 21 22 28 25 30 30 C 32 25 39 22 39 8 Z" {P}/><path d="M21 52 C 21 38 28 35 30 30 C 32 35 39 38 39 52 Z" {P}/>
<path d="M24 52 C 26 44 34 44 36 52 Z" {FG} stroke="{GLD}"/><path d="M30 31 L30 45" stroke="{GLD}" stroke-width="2.4"/></g>
<path d="M48 18 l8 0 M50 26 l8 0 M48 34 l6 0" {R} stroke-width="2.6"/>''',
	"bronze_bell": f'''<path d="M30 6 L30 10"/><circle cx="30" cy="5" r="2"/>
<path d="M14 44 C 18 40 16 18 30 12 C 44 18 42 40 46 44 Z" fill="#c9893c"/><path d="M12 44 L48 44" stroke-width="3"/>
<circle cx="30" cy="49" r="3.4" {FR} {R}/><path d="M22 22 C 22 30 20 36 19 40" stroke="#f0cf7a" opacity=".9"/>
<path d="M6 30 q-3 6 0 12 M54 30 q3 6 0 12" stroke="{ELX}" stroke-width="2.4"/>''',
	"raider_pack": f'''<path d="M14 20 C 14 12 46 12 46 20 L48 52 L12 52 Z" {P}/><path d="M14 20 C 20 30 40 30 46 20 L44 34 L16 34 Z" fill="#c9b07a"/>
<path d="M30 30 L30 36" stroke-width="3"/><rect x="26" y="34" width="8" height="5" {FR} {R}/>
<path d="M22 12 C 22 4 38 4 38 12" stroke-width="2.6"/><path d="M38 6 L50 2 L54 14 L42 18" fill="#fff4d8"/><path d="M44 8 l5 -2" {R}/>''',
	"hanged_hand": f'''<path d="M30 2 L30 14" stroke="#8a6a3a" stroke-width="3"/><ellipse cx="30" cy="18" rx="9" ry="4" stroke="#8a6a3a" stroke-width="3"/>
<path d="M20 22 L40 22 L42 36 L18 36 Z" fill="#efe6d0"/>
<path d="M21 36 L18 50 M27 36 L26 55 M33 36 L34 55 M39 36 L42 50 M41 28 L51 36" stroke-width="6.5"/>
<path d="M21 36 L18 50 M27 36 L26 55 M33 36 L34 55 M39 36 L42 50 M41 28 L51 36" stroke="#efe6d0" stroke-width="3"/>
<path d="M23.5 44 l5 0" {R} stroke-width="3"/><path d="M20 30 l20 0" opacity=".35"/>''',
	"arcane_ink": f'''<path d="M12 36 L40 36 L44 52 L8 52 Z" fill="#4a3a6a"/><path d="M16 36 C 16 30 36 30 36 36" fill="#4a3a6a"/>
<ellipse cx="26" cy="35" rx="9" ry="2.6" {FE}/>
<path d="M28 34 L50 6 C 54 10 50 18 44 22 C 40 26 34 30 28 34 Z" {P}/><path d="M28 34 L44 16" opacity=".6"/>
<path d="M50 34 l0 8 M46 38 l8 0" stroke="{ELX}" stroke-width="2.4"/>''',
	"torn_banner": f'''<path d="M12 4 L12 56" stroke-width="3"/><circle cx="12" cy="4" r="2.4" {FK}/>
<path d="M12 8 L48 8 L48 34 L42 30 L38 38 L32 32 L26 40 L22 32 L12 36 Z" {FR} {R}/>
<path d="M22 16 L30 24 L38 16" stroke="{PAP}" stroke-width="2.6"/>''',
	"giant_scale": f'''<path d="M30 6 L30 52 M18 52 L42 52" stroke-width="3"/><path d="M8 22 L52 12" stroke-width="2.6"/>
<path d="M8 22 L4 36 M8 22 L14 36 M52 12 L46 26 M52 12 L58 26"/>
<path d="M3 36 C 4 41 14 41 15 36 Z" {P}/><path d="M45 26 C 46 31 57 31 58 26 Z" {P}/>
<rect x="5" y="27" width="8" height="8" {FK}/><circle cx="51.5" cy="23" r="2" {FG}/><circle cx="30" cy="6" r="2.6" {FR} {R}/>''',
	"tally_stick": f'''<path d="M6 40 L50 16 L54 22 L10 46 Z" {P}/>
<path d="M14 36 l3 6 M20 33 l3 6 M26 30 l3 6 M32 27 l3 6" stroke-width="2.4"/>
<path d="M12 30 L38 34" {R} stroke-width="3"/><path d="M42 22 l3 6" {R} stroke-width="3"/><path d="M48 52 l4 -6 M42 50 l4 2" opacity=".6"/>''',
	"chain_ring": f'''<circle cx="19" cy="30" r="10" stroke-width="3.2"/><circle cx="30" cy="30" r="10" stroke-width="3.2" stroke="{RED}"/><circle cx="41" cy="30" r="10" stroke-width="3.2"/>
<path d="M27 21 a10 10 0 0 1 5 0" stroke="{INK}" stroke-width="3.2"/><circle cx="30" cy="12" r="3" {FE} stroke="none"/><path d="M30 46 l0 8 M26 50 l8 0" stroke="{ELX}" stroke-width="2.4"/>''',
	"miser_ledger": f'''<path d="M12 10 L42 10 L42 52 L12 52 Z" fill="#6b4a2c"/><path d="M12 10 L12 52" stroke-width="3.4"/>
<path d="M42 14 L46 14 L46 50 L42 50" {P}/><path d="M18 18 L36 18 L36 28 L18 28 Z" {P}/><path d="M21 22 l12 0 M21 25 l8 0" opacity=".6"/>
<circle cx="44" cy="44" r="9" {FG}/><path d="M44 39 l0 10 M41 41 q3 -2 6 0" stroke-width="2"/><rect x="24" y="36" width="6" height="7" {FR} {R}/>''',
	"frost_shard": f'''<path d="M30 4 L40 24 L34 56 L24 36 L18 20 Z" {FI}/><path d="M30 4 L28 30 L34 56 M18 20 L28 30 L40 24" opacity=".55"/>
<path d="M50 34 l0 14 M44 38 l12 6 M44 44 l12 -6" stroke="#4f8a96" stroke-width="2.4"/><path d="M8 40 l6 4 M6 48 l8 0" {R}/>''',
	"rift_key": f'''<circle cx="20" cy="20" r="12" fill="#2c2340"/><path d="M20 12 C 26 12 28 20 22 22 C 18 23 16 18 20 17" stroke="{ELL}" stroke-width="2.4"/>
<circle cx="20" cy="20" r="12"/><path d="M28 28 L52 52 M42 42 L48 36 M47 47 L52 42" stroke-width="3.4"/>
<path d="M8 40 l6 -2 M4 32 l6 0" {R}/>''',
}


def svg(inner: str) -> str:
	return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60" width="128" height="128">'
		f'<g fill="none" stroke="{INK}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">'
		+ inner.replace("\n", "") + "</g></svg>\n")


def main() -> None:
	os.makedirs(OUT, exist_ok=True)
	ids = [r["id"] for r in json.load(open(os.path.join(ROOT, "data", "relics.json"), encoding="utf-8"))["relics"]]
	miss = [i for i in ids if i not in ICONS]
	if miss:
		sys.exit("faltam ícones: " + ", ".join(miss))
	for i in ids:
		with open(os.path.join(OUT, i + ".svg"), "w", encoding="utf-8", newline="\n") as f:
			f.write(svg(ICONS[i]))
	print(len(ids), "ícones em", OUT)


if __name__ == "__main__":
	main()
