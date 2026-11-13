# Brief: subjects for Last Boss card art (one chunk of ~8 cards)

You write ONLY image-prompt subjects. Do not generate or read images. Do not edit any file except your output file.

Read: this brief, `../fichas.json` (fixed phrases for recurring figures), and your chunk file `<chunk>.json`
(each card: id, pt/en name, type, villain, tags, archetype, fx = gameplay effect).
Write: `../subjects/<chunk>.json` = `{"<id>": {"subject": "...", "bg": "lilac|teal|ochre|sand|slate|rose"}, ...}` for EVERY card in the chunk.

A fixed style block (flat gouache poster painting) and a fixed tone sentence are added automatically. The subject is
ONLY the content. The pilot showed that simple, countable compositions come out coherent and busy ones do not.

## Rules (all mandatory)
1. 2-4 English sentences, natural and concrete: who, one clear pose/action, 2-3 visual details, ONE story element of scenery.
   No style, medium, lighting, quality or photo words.
2. NEVER negations (no, not, without, never, none, nothing, free of): rewrite as positives.
3. A recurring figure from fichas.json = its phrase pasted VERBATIM; add only pose and action around it.
4. Natural colors of the creature. `bg` = the tone that contrasts most with the main figure. Never describe the sky/background.
5. ONE main figure (or one small countable group of 3-6 for swarms/packs), large in frame, in a simple readable pose.
   State the parts so they can be counted: "both wings spread", "one sword in his right gauntlet", "his left fist at his side".
   Every hand holding something says which hand and what. At most 2 props in total.
6. Avoid: tangled or overlapping limbs, piles of bodies, ropes/chains/hoses/cables, tiny scattered items, text, symbols, runes
   that could read as letters, more than one weapon per figure.
7. Grounded and serious, never cartoony: real-animal or real-person proportions, restrained expressions.
   Banned words: grin, grinning, gleeful, cute, funny, goofy, goggles, big eyes, chibi.
8. A small motion effect (dust, embers, sparks, smoke wisps) BEHIND the figure.
9. SPELLS: if the effect hurts the hero (damage, curse, slow, trap), show it happening ON the hero using the `hero` phrase
   and one reaction from `hero_reactions`. Use each reaction at most once in your chunk, starting from the index given in
   your task and going forward (wrap around). Vary the camera too (front, side, back, three-quarter).
   If the spell buffs or summons the villain's own creatures, show those creatures receiving the effect instead.
10. STRUCTURES, LAIRS, ROUTES: the building/place in focus with its creatures doing their job (rats leaving a burrow).
11. Rarity does not change the art. Keep the lower ~6% of the image unimportant (a name ribbon covers it).
12. Use the card's fx/tags only to choose WHAT is shown (fire, poison, gold, souls); never write numbers.

## Two subjects that worked in the pilot
- death_knight: "A tall undead knight in blackened plate armor with a horned iron helmet and a tattered black cloak, his visor glowing with cold cyan-green ghostly light. He strides forward, holding one black longsword in his right gauntlet with the blade raised over his right shoulder, his left fist clenched at his side. A single cracked gravestone stands behind him, and torn strips of his cloak stream back in the wind." (bg sand)
- weakness_curse: "<hero phrase>, kneeling on one knee with his head bowed, his right gauntlet gripping the hilt of his one sword whose tip rests on the ground, his left hand pressed flat on his raised knee. A thin crack runs down the blade, and a thin veil of dark purple smoke rises from the crack and drifts up behind his shoulders." (bg ochre)

Before finishing, re-read your file and fix any banned word or negation. Reply only with the list of ids written.
