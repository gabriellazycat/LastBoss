"""10 direcoes de arte da loja Steam do Last Boss. Mesmo estilo guache das cartas (estilo.py); cada direcao muda a CENA e a paleta.
Frases de figuras recorrentes vem de fichas.json (heroi sem olhos; criaturas ganham EYES via adapt_subject)."""
H = "a lone human knight in plain steel armor made of a few large smooth plates with a faded blue tabard and a plain round steel helmet whose whole face opening is one flat solid black shadow, holding a straight steel sword"
RAT = "grey rats with pink ears and pink tails"
DRAGON = "a huge ancient red dragon with smooth crimson skin, a pale yellow belly, long curved horns and a smooth frill"
SKEL = "yellowed human skeletons with dark empty eye sockets and rusty scraps of armor"
BAT = "small black bats with leathery wings and pale pink ears"

# land = horizontal, port = vertical, wide = panorama do hero, bg = fundo calmo
V = {
 "v01": dict(nome="O cerco ao covil", pal="Dusty lilac and slate dusk sky, warm ochre lantern glow at the gate.",
   land=f"A dark stone castle on a hill at the end of a winding road, in the center. A small party of four tiny knights marches up the road toward it, and a swarm of {RAT} pours out of the open castle gate down the hill.",
   port=f"A tall dark stone castle on a hill filling the center of the picture, a winding road below it with a small party of four tiny knights marching up, and a swarm of {RAT} pouring out of the open gate.",
   wide=f"A very wide dusk landscape: a dark stone castle on a hill in the center, a winding road with a small party of tiny knights, a swarm of {RAT} pouring from the gate, quiet empty sky and hills at both sides.",
   bg="A quiet dusk landscape of soft hills and a faraway dark castle silhouette, very low contrast, hazy lilac and slate."),
 "v02": dict(nome="O Rei dos Ratos", pal="Dusty teal and warm ochre.",
   land=f"A huge grey rat king as big as an ogre, seated on a throne of stacked grey stones and wearing a plain simple gold crown, in the center. A great swarm of {RAT} fills the ground around the throne, and {H} stands tiny in front of it.",
   port=f"A huge grey rat king as big as an ogre, seated on a throne of stacked grey stones and wearing a plain simple gold crown, filling the center. A great swarm of {RAT} fills the ground, and {H} stands tiny at the bottom.",
   wide=f"A very wide stone hall: in the center a huge grey rat king on a throne of stacked stones wearing a plain gold crown, a great swarm of {RAT} spreading across the floor to both sides.",
   bg="A dim empty stone hall with soft shadows, a faint warm glow, very low contrast, hazy teal and ochre."),
 "v03": dict(nome="O dragao do tesouro", pal="Warm ochre and faded old rose, ember orange glow.",
   land=f"{DRAGON}, coiled on a great heap of gold in a cave, its head raised in the center. {H} stands tiny at the cave mouth, seen from behind.",
   port=f"{DRAGON}, coiled on a great heap of gold, its head raised high filling the center of the tall picture. {H} stands tiny at the bottom, seen from behind.",
   wide=f"A very wide dark cave: in the center {DRAGON}, coiled on a great heap of gold, head raised; plain rocky cave walls and gold at both sides.",
   bg="A dim cave interior with a soft warm ember glow far away, very low contrast, hazy ochre and rose."),
 "v04": dict(nome="O lich e a legiao", pal="Grey-blue slate with a cold cyan-green glow.",
   land=f"A tall lich in a plain dark hooded robe, one hand raised with a cold cyan-green glow, standing in the center, with rows of {SKEL} standing behind him.",
   port=f"A tall lich in a plain dark hooded robe filling the center, one hand raised with a cold cyan-green glow, rows of {SKEL} rising behind him.",
   wide=f"A very wide graveyard at night: a tall lich in a plain dark hooded robe in the center with one hand raised and a cold cyan-green glow, rows of {SKEL} spreading to both sides.",
   bg="A foggy graveyard at night with soft grey-blue fog and a faint cyan-green glow, very low contrast."),
 "v05": dict(nome="A marcha dos herois", pal="Faded old rose and sage green, warm sand.",
   land="A bird's-eye view of green hills with a branching dirt road running toward a small dark castle at the top, a tiny party of knights marching along the road and small monsters hiding beside the road. Like an old painted map.",
   port="A bird's-eye view looking down a tall valley: a branching dirt road runs up to a small dark castle at the top, tiny knights marching on it, small monsters hiding beside the road. Like an old painted map.",
   wide="A very wide bird's-eye view of rolling hills, a branching dirt road crossing from left to right toward a small dark castle in the center, tiny knights marching on it. Like an old painted map.",
   bg="A soft bird's-eye view of rolling hills and a faint winding road, very low contrast, hazy sage and rose."),
 "v06": dict(nome="A mao de cartas", pal="Dusty lilac, deep plum and warm sand.",
   land="A dark gloved hand holds a fan of five big plain parchment cards in the center, each card with one simple painted monster: a rat, a dragon, a skeleton, a bat, a flame. A small dark castle glows far behind.",
   port="A dark gloved hand at the bottom holds a fan of five big plain parchment cards, each card with one simple painted monster: a rat, a dragon, a skeleton, a bat, a flame. A small dark castle glows above.",
   wide="A very wide dark table of old wood: in the center a fan of five big plain parchment cards, each with one simple painted monster, a small dark castle silhouette far behind, quiet empty table at both sides.",
   bg="A dim old wooden table with soft candle glow, very low contrast, hazy plum and sand."),
 "v07": dict(nome="Legiao de ossos", pal="Warm sand, ochre and grey slate.",
   land=f"Tight rows of {SKEL} marching toward us with spears, and behind them a huge bone colossus, a giant skeleton taller than a tower, rising in the center. {H} stands tiny in front.",
   port=f"A huge bone colossus, a giant skeleton taller than a tower, rising in the center of the tall picture, with tight rows of {SKEL} below, and {H} tiny at the bottom.",
   wide=f"A very wide dry plain: in the center a huge bone colossus, a giant skeleton taller than a tower, with long rows of {SKEL} spreading to both sides.",
   bg="A dry plain under a hazy sky with soft distant shapes, very low contrast, sand and slate."),
 "v08": dict(nome="Armadilhas do covil", pal="Dark ochre with ember orange and smoke grey.",
   land=f"A narrow stone corridor inside the lair: a boiling oil cauldron tipped over from above, a barricade of sharp wooden stakes, a stone gargoyle on a tower, and a party of three knights caught in the middle, with {RAT} in the shadows.",
   port="A tall stone gate tower of the lair: a stone gargoyle on top, a huge iron cauldron pouring boiling oil down, a barricade of wooden stakes at the foot, and a small party of knights caught below.",
   wide="A very wide stone corridor inside the lair: a boiling oil cauldron in the center pouring fire, a barricade of wooden stakes, a stone gargoyle, small knights in the middle, plain stone walls at both sides.",
   bg="A dim stone corridor lit by far torches, very low contrast, smoky ochre and grey."),
 "v09": dict(nome="A praga", pal="Sickly pale teal and mustard.",
   land=f"A swarm of {BAT} and {RAT} flowing over the rooftops of a small village under a sick pale-green fog, {H} in the center holding his shield up over his head.",
   port=f"A great swarm of {BAT} and {RAT} spiraling over a small village under a sick pale-green fog, {H} at the bottom holding his shield up over his head.",
   wide=f"A very wide village at dusk under a sick pale-green fog, a great swarm of {BAT} and {RAT} flowing over the rooftops in the center, quiet fog at both sides.",
   bg="A quiet village in a soft pale-green fog, very low contrast, hazy teal and mustard."),
 "v10": dict(nome="O portao do covil", pal="Faded old rose and dusty lilac sunset with deep shadow.",
   land=f"{H}, seen from behind in silhouette, standing tiny at the foot of an enormous dark gate of the lair, a glowing crack of warm light between the doors and the shadows of monsters peering from the wall above.",
   port=f"An enormous dark gate of the lair filling the tall picture, a glowing crack of warm light between the doors, the shadows of monsters peering from the wall above, and {H}, seen from behind in silhouette, tiny at the bottom.",
   wide=f"A very wide dark wall of the lair with an enormous gate in the center and a glowing crack of warm light, the shadows of monsters peering from the wall above, {H} seen from behind tiny at the foot.",
   bg="A soft dusk sky above a faint dark wall, very low contrast, hazy rose and lilac."),
}


# --- Refacao de 25/11 (defeitos vistos na revisao). So troca as cenas listadas; o estilo (estilo.py) segue fixo. ---
HB = ("a lone human knight seen from behind, showing only the smooth back of a plain round steel helmet and the back of a long "
      "faded blue cloak, steel armor made of a few large smooth plates, holding a straight steel sword")
GLOVE = "a hand wearing a dark leather glove, its thumb in front of the cards and its fingers behind them,"
CARDS = "five big plain parchment cards, each card with one simple painted monster: a rat, a dragon, a skeleton, a bat, a flame"
COLOSSUS = ("one huge giant skeleton as tall as a tower, seen whole, its big round skull near the top of the picture, "
            "its wide ribcage and long arms in the middle")
TRAP = "three knights seen from behind, showing the smooth backs of plain round steel helmets and the backs of blue cloaks"

V["v06"]["land"] = (f"In the middle of the picture {GLOVE} comes up from the bottom edge and holds a fan of {CARDS}. "
                    "A small dark castle glows far behind.")
V["v06"]["wide"] = (f"A very wide dark picture. In the center {GLOVE} comes up from the bottom edge and holds an upright fan of "
                    f"{CARDS}. A small dark castle glows far behind. Quiet dark space at both sides.")
V["v07"]["land"] = (f"In the center {COLOSSUS}, rising from a dry plain. Five small skeleton soldiers stand at its feet, and "
                    f"{HB}, stands tiny in the foreground.")
V["v07"]["wide"] = (f"A very wide empty dry plain seen from far away. In the center {COLOSSUS}, the whole giant small enough "
                    "to leave empty sky above and ground below. A few tiny skeleton soldiers stand at its feet.")
V["v08"]["land"] = (f"A stone corridor inside the lair seen from the entrance: in the foreground {TRAP}, stopped in front of "
                    "a barricade of sharp wooden stakes, and above the barricade a huge iron cauldron tipping over and pouring "
                    "glowing boiling oil, with a stone gargoyle perched on the wall beside it.")
V["v08"]["wide"] = ("A very wide stone corridor inside the lair seen from far away: in the exact middle of the picture a huge "
                    "iron cauldron hanging from the ceiling tips over and pours glowing boiling oil onto a barricade of sharp "
                    f"wooden stakes, a stone gargoyle perched beside it, and {TRAP}, small at the foot. Plain stone walls at both sides.")
V["v10"]["wide"] = ("A very wide dark wall of the lair with an enormous gate in the center and a glowing crack of warm light "
                    "between the doors, the shadows of monsters peering from the wall above, and at the foot of the gate "
                    f"{HB}, walking toward the light.")
V["v02"]["wide"] = ("A very wide stone hall seen from far away. In the exact middle of the picture sits a grey rat king as big as "
                    "an ogre on a low throne of stacked stones, wearing a plain simple gold crown, with plenty of empty wall "
                    f"above the crown. A great swarm of {RAT} covers the floor below to both sides.")
V["v03"]["wide"] = (f"A very wide dark cave seen from far away. {DRAGON}, coiled on a great heap of gold, its head raised and "
                    "facing forward in the exact middle of the picture, plain rocky cave walls and gold at both sides, "
                    "empty cave darkness above the horns.")
V["v04"]["wide"] = ("A very wide graveyard at night seen from far away. A tall lich in a plain dark hooded robe stands in the "
                    "exact middle of the picture, one hand raised with a cold cyan-green glow, with plenty of empty foggy sky "
                    f"above the hood. Rows of {SKEL} stand upright behind and beside the lich, spreading to both sides.")
# semente somada por (variante, formato) quando uma imagem e refeita
SEED = {(v, f): 100 for v, f in [("v06", "land"), ("v07", "land"), ("v08", "land")] +
        [(x, "wide") for x in ("v02", "v03", "v04", "v06", "v07", "v08", "v10")]}
V["v06"]["land"] = (f"A dark picture with a deep plum and black background all around. In the middle {GLOVE} comes up from the bottom edge "
                    f"and holds a fan of {CARDS}. A small dark castle with warm windows glows far behind.")
V["v07"]["wide"] = ("A very wide dry plain seen from far away. In the exact middle a colossal giant skeleton is buried up to its chest "
                    "in the ground: only its big round skull, shoulders, upper ribcage and two huge hands rise out of the sand, "
                    "the skull in the very center of the picture with plenty of empty sky above it. A few tiny skeleton soldiers "
                    "stand beside the hands.")
SEED.update({("v06", "land"): 200, ("v07", "wide"): 200})
V["v06"]["wide"] = (f"A very wide dark picture with a deep plum and black background all around. In the center {GLOVE} comes up from "
                    f"the bottom edge and holds an upright fan of {CARDS}. A small dark castle with warm windows glows far behind.")
V["v08"]["port"] = ("A tall stone gate tower of the lair: a stone gargoyle on top, a huge iron cauldron pouring boiling oil down, a "
                    f"barricade of wooden stakes at the foot, and at the very bottom {TRAP}, walking toward the stakes.")
V["v05"]["port"] = ("A bird's-eye view looking down a tall valley: a branching dirt road runs up to a small dark castle at the top, "
                    "a few tiny knights march up the road away from us, seen from behind, showing only the smooth backs of plain "
                    "round steel helmets and the backs of blue cloaks, small monsters hiding beside the road. Like an old painted map.")
SEED.update({("v06", "wide"): 300, ("v08", "port"): 300, ("v08", "libcap"): 300, ("v05", "port"): 300, ("v05", "libcap"): 300})
