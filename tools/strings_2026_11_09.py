# Textos da rodada de 09/11/2026 (3 atos, disputas novas, relíquias, eventos, compêndio).
# Uso: python -I tools/strings_2026_11_09.py  (substitui/acrescenta chaves em locale/strings.csv)
# Depois: godot --headless --path . --import  (reimporta as traduções)
import csv, io, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
CSV = ROOT / "locale" / "strings.csv"

S = {
 # ---- locais
 "LOC_event": ("Encruzilhada ?", "Crossroads ?"),
 "KW_event": ("Encruzilhada", "Crossroads"),
 "KWD_tavern": ("O herói para na taverna e defende as {tavern_houses} casas ({tavern_house_hp} de vida cada). Seus monstros a até {tavern_aggro} m vão nas casas. Destrua todas em {tavern_s} s para escolher entre 3 modificadores; se não, nada.",
                "The hero stops at the tavern and defends its {tavern_houses} houses ({tavern_house_hp} health each). Your monsters within {tavern_aggro} m go for the houses. Destroy them all within {tavern_s} s to pick from 3 modifiers; otherwise nothing."),
 "KWD_fountain": ("O herói se ajoelha e bebe por {fountain_s} s. Interrompa com medo, raiz, empurrão, petrificação ou {fountain_dmg} de dano para tirar a carta que quiser do deck. Se ele terminar de beber, cura {fountain_heal}% da vida e você não ganha nada.",
                  "The hero kneels and drinks for {fountain_s} s. Interrupt with fear, root, knockback, petrify or {fountain_dmg} damage to remove any card from your deck. If he finishes drinking, he heals {fountain_heal}% health and you get nothing."),
 "KWD_ritual": ("Sacrifício: o herói para no círculo e seu [[elixir|Elixir]] enche {ritual_mult}× mais rápido. Faça {ritual_kills} monstros seus morrerem dentro dele em {ritual_s} s para subir o nível de 1 entre 3 cartas; se não, nada.",
                "Sacrifice: the hero stops in the circle and your [[elixir|Elixir]] fills {ritual_mult}× faster. Get {ritual_kills} of your monsters killed inside it within {ritual_s} s to level up 1 of 3 cards; otherwise nothing."),
 "KWD_shrine": ("O herói para no santuário por até {shrine_window} s. Mantenha monstros seus (não estruturas nem Mímico) dentro do círculo por {shrine_s} s somados para escolher entre 3 cartas raras; se não, nada.",
                "The hero stops at the shrine for up to {shrine_window} s. Keep your monsters (not structures or the Mimic) inside the circle for {shrine_s} s in total to pick from 3 rare cards; otherwise nothing."),
 "KWD_bridge": ("Na ponte o herói ataca {bridge_atk}% mais devagar por {bridge_s} s. Cause {bridge_win} de dano nesse tempo para escolher o tipo da recompensa (carta, nível ou remoção); se não, nada.",
                "On the bridge the hero attacks {bridge_atk}% slower for {bridge_s} s. Deal {bridge_win} damage in that time to choose the reward type (card, level or removal); otherwise nothing."),
 "KWD_shop": ("Sem disputa: quando o herói chega, a loja abre. Gaste [[gold|Ouro]] em cartas, nível de carta, modificador ou remoção. Toda rota de cada ato passa por uma loja.",
              "No contest: when the hero arrives, the shop opens. Spend [[gold|Gold]] on cards, a card level, a modifier or a removal. Every route of every act passes a shop."),
 "KWD_event": ("Um encontro de texto sorteado: escolha uma das opções. Algumas dão recompensas, outras cobram um preço.",
               "A random text encounter: pick one of the options. Some give rewards, others come at a price."),
 "KWD_teleport": ("Na arena, você (o chefe) salta para um [[altar|Altar]]. Custa {tp_cost} de [[elixir|Elixir]] e recarrega em {tp_cd} s. Use Q/E ou clique num altar.",
                  "In the arena, you (the boss) jump to an [[altar|Altar]]. Costs {tp_cost} [[elixir|Elixir]] and recharges in {tp_cd} s. Use Q/E or click an altar."),
 "KWD_pack": ("Tag de monstros que andam em grupo. O Rei dos Ratos fortalece o Bando perto dele.", "Tag for monsters that move in groups. The Rat King strengthens nearby Pack."),
 "UI_OPT_TRANSFORM_HEAD": ("Reescrever esta carta", "Rewrite this card"),
 "UI_OPT_COPY_HEAD": ("Copiar esta carta", "Copy this card"),
 "HCTR_sword_spin": ('Não cole monstros fracos nele: atiradores fora de 3 m, ou jogue logo depois do giro (recarga de 4 s).', "Don't stack weak monsters on him: shooters beyond 3 m, or play right after the spin (4 s cooldown)."),
 "HCTR_tower_shield": ('Escudo maior e mais largo: ataque por trás e use dano que perfura, de área ou de sombra.', 'Bigger, wider shield: attack from behind and use piercing, area or shadow damage.'),
 "HCTR_dash": ('Avança quando cercado ou lento: guarde o controle para depois da investida (recarga de 8 s).', 'Dashes when surrounded or slowed: save your crowd control for after the dash (8 s cooldown).'),
 "HCTR_war_cry": ('Assusta 3 ou mais monstros pequenos perto: solte o enxame logo depois do grito (recarga de 12 s) ou use monstros grandes.', 'Scares 3 or more small monsters nearby: drop the swarm right after the shout (12 s cooldown) or use big monsters.'),
 "HCTR_fireproof": ('Fogo causa metade: troque por sombra, mortos-vivos ou dano físico.', 'Fire deals half: switch to shadow, undead or physical damage.'),
 "HCTR_holy_water": ('Dano dobrado contra mortos-vivos e sombra: prefira bando, fogo e construtos.', 'Double damage against undead and shadow: favor pack, fire and constructs.'),
 "HCTR_treasure_nose": ('Ignora o Mímico e a Isca de Ouro: não conte com eles.', "Ignores the Mimic and the Gold Bait: don't rely on them."),
 "HCTR_stone_hammer": ('Dano dobrado contra construtos, altares e pilares: proteja as estruturas e teleporte cedo.', 'Double damage against constructs, altars and pillars: protect structures and teleport early.'),
 "HCTR_steady_boots": ('Lentidão pela metade e sem empurrão: prefira raiz, medo e dano.', 'Half slow and no knockback: favor root, fear and damage.'),
 "HCTR_purifying_blade": ('Cada golpe tira uma maldição: amaldiçoe em rajadas, perto do fim da luta.', 'Each hit removes a curse: curse in bursts, near the end of the fight.'),
 "HCTR_reflect_shield": ('Bloqueia um feitiço a cada 10 s: jogue um feitiço barato primeiro e o forte logo depois.', 'Blocks one spell every 10 s: cast a cheap spell first and the strong one right after.'),
 "HCTR_hero_fury": ('Ataca mais rápido com muitos inimigos perto: use poucos monstros fortes em vez de enxame.', 'Attacks faster with many enemies nearby: use a few strong monsters instead of swarms.'),
 "HCTR_soul_absorb": ('Cura a cada abate: evite muitos monstros frágeis perto dele.', 'Heals on every kill: avoid many fragile monsters near him.'),
 "HCTR_second_wind": ('Cura 30% uma vez abaixo de 25%: guarde a rajada final para depois dela.', 'Heals 30% once below 25%: save your final burst for after it.'),
 "HCTR_heroic_strike": ('Golpe triplo a cada 5 s contra alvos grandes: deixe um monstro barato levar o golpe antes do Ogro.', 'Triple hit every 5 s against big targets: let a cheap monster take the hit before the Ogre.'),
 # ---- HUD
 "UI_ACT": ("Ato {n}", "Act {n}"),
 "UI_ACT_OF": ("Ato {n} de {m}", "Act {n} of {m}"),
 "UI_GOLD": ("{g} de ouro", "{g} gold"),
 "UI_RELICS": ("Relíquias do covil", "Lair relics"),
 "UI_OFFER_RELIC": ("Fim do ato {a}: escolha uma relíquia do covil", "End of act {a}: pick a lair relic"),
 "UI_OFFER_EVENT_STEP": ("Escolha 1", "Pick 1"),
 "UI_EVENT_NEEDS": ("Precisa de {g} de ouro", "Needs {g} gold"),
 "UI_CONTEST_ritual": ("Ritual: {p} de {g} mortes no círculo · {s} s", "Ritual: {p} of {g} deaths in the circle · {s} s"),
 "UI_CONTEST_shrine": ("Santuário: {p} de {g} s com monstros no círculo · {s} s", "Shrine: {p} of {g} s with monsters in the circle · {s} s"),
 "UI_CONTEST_tavern": ("Taverna: {p} de {g} casas destruídas · {s} s", "Tavern: {p} of {g} houses destroyed · {s} s"),
 "UI_CONTEST_bridge": ("Ponte: {p} de {g} de dano · {s} s", "Bridge: {p} of {g} damage · {s} s"),
 "UI_CONTEST_fountain": ("O herói está bebendo! Medo, raiz, empurrão ou {g} de dano interrompem · {s} s", "The hero is drinking! Fear, root, knockback or {g} damage interrupts · {s} s"),
 "UI_CONTEST_WON": ("Disputa vencida!", "Contest won!"),
 "UI_CONTEST_LOST": ("Disputa perdida: sem recompensa", "Contest lost: no reward"),
 "UI_ABILITY_ARMED": ("pronta", "ready"),
 "UI_FREE_CARD": ("Próxima carta grátis!", "Next card is free!"),
 # ---- compêndio
 "UI_COMPENDIUM": ("Compêndio", "Compendium"),
 "UI_COMP_CARDS": ("Cartas", "Cards"),
 "UI_COMP_RELICS": ("Relíquias", "Relics"),
 "UI_COMP_MODS": ("Modificadores", "Modifiers"),
 "UI_COMP_LOCS": ("Locais", "Locations"),
 "UI_COMP_HERO": ("Herói", "Hero"),
 "UI_COMP_LOCKED": ("Bloqueada · {c} Almas", "Locked · {c} Souls"),
 "UI_COMP_COUNTER": ("Contra-ataque: {t}", "Counter: {t}"),
 "UI_COMP_CD": ("Recarga: {s} s", "Cooldown: {s} s"),
 "UI_COMP_PASSIVE": ("Passiva", "Passive"),
 "UI_COMP_REWARD": ("Recompensa: {r}", "Reward: {r}"),
}

# Relíquias (aba Run - Relíquias)
REL = {
 "bone_crown": ("Coroa de Ossos", "A cada 10 monstros seus mortos, +1 de elixir.", "Bone Crown", "Every 10 of your monsters killed, +1 elixir."),
 "portable_altar": ("Altar Portátil", "A recarga do sacrifício cai pela metade.", "Portable Altar", "Sacrifice cooldown is halved."),
 "lair_tithe": ("Dízimo do Covil", "Ouro do dano no herói ×1,3.", "Lair Tithe", "Gold from damage to the hero ×1.3."),
 "black_mortar": ("Argamassa Negra", "Estruturas têm +50% de vida e duram 50% mais.", "Black Mortar", "Structures have +50% health and last 50% longer."),
 "victory_horn": ("Trombeta da Vitória", "Vencer uma disputa dá +2 de elixir na hora.", "Victory Horn", "Winning a contest grants +2 elixir at once."),
 "cracked_hourglass": ("Ampulheta Rachada", "As janelas das disputas duram 30% mais.", "Cracked Hourglass", "Contest windows last 30% longer."),
 "jailer_chains": ("Correntes do Carcereiro", "Medo e raiz duram 50% mais.", "Jailer's Chains", "Fear and root last 50% longer."),
 "watchful_eye": ("Olho Vigilante", "Quando uma habilidade do herói dispara, a primeira carta jogada em até 3 s custa 0.", "Watchful Eye", "When a hero ability fires, the first card played within 3 s costs 0."),
 "pack_howl": ("Uivo da Matilha", "Com 5 ou mais unidades de bando vivas, os bandos causam +25% de dano.", "Pack Howl", "With 5 or more pack units alive, packs deal +25% damage."),
 "merchant_purse": ("Bolsa do Mercador", "A loja tem 1 carta a mais e tudo custa 15% menos.", "Merchant's Purse", "Shops have 1 extra card and everything costs 15% less."),
 "overflowing_chalice": ("Cálice Transbordante", "Cada ato e a arena começam com o elixir cheio.", "Overflowing Chalice", "Each act and the arena start with full elixir."),
 "passage_stone": ("Pedra de Passagem", "O teleporte custa 0 e recarrega 4 s mais rápido.", "Passage Stone", "Teleport costs 0 and recharges 4 s faster."),
 "profane_earth": ("Terra Profana", "Monstro seu que morre no círculo de um local tem 25% de chance de levantar como Arqueiro Esqueleto.", "Profane Earth", "Your monsters that die in a location circle have a 25% chance to rise as a Skeleton Archer."),
 "bad_blood": ("Sangue Ruim", "Cada queda de herói dá também 1 entre 3 modificadores.", "Bad Blood", "Each hero fall also grants 1 of 3 modifiers."),
 "heavy_grimoire": ("Grimório Pesado", "Mão +1 carta, elixir máximo −1.", "Heavy Grimoire", "Hand +1 card, max elixir −1."),
}

# Eventos (aba Run - Eventos): título, texto, opções (rótulo, resultado)
EVT = {
 "hooded_merchant": (("Mercador Encapuzado", "Um vulto oferece mercadoria roubada de um templo."), ("Hooded Merchant", "A figure offers goods stolen from a temple."), {
   "buy": (("Comprar (60 de ouro)", "Escolha 1 entre 3 cartas raras ou melhores."), ("Buy (60 gold)", "Pick 1 of 3 rare or better cards.")),
   "rob": (("Roubar", "50%: uma carta rara ou melhor. 50%: o próximo herói chega com +10% de vida."), ("Rob", "50%: a rare or better card. 50%: the next hero arrives with +10% health.")),
   "leave": (("Seguir", "Nada acontece."), ("Move on", "Nothing happens."))}),
 "profane_altar": (("Altar Profano", "Um altar pede uma oferenda."), ("Profane Altar", "An altar demands an offering."), {
   "card": (("Oferecer uma carta", "Remova 1 carta e suba outra de nível."), ("Offer a card", "Remove 1 card and level up another.")),
   "blood": (("Oferecer sangue", "Ganhe 1 relíquia sorteada; o chefe começa a arena com 15% menos vida em cada parte."), ("Offer blood", "Gain 1 random relic; the boss starts the arena with 15% less health on each part.")),
   "leave": (("Seguir", "Nada acontece."), ("Move on", "Nothing happens."))}),
 "prisoner": (("Prisioneiro", "Um aventureiro preso na sua masmorra implora."), ("Prisoner", "An adventurer locked in your dungeon begs for mercy."), {
   "torture": (("Torturar", "O herói atual recebe 2 maldições; escolha 1 entre 3 modificadores."), ("Torture", "The current hero gets 2 curses; pick 1 of 3 modifiers.")),
   "recruit": (("Recrutar", "Escolha 1 entre 3 cartas incomuns."), ("Recruit", "Pick 1 of 3 uncommon cards.")),
   "free": (("Soltar", "+40 de ouro."), ("Release", "+40 gold."))}),
 "wishing_well": (("Poço dos Desejos", "Moedas brilham no fundo."), ("Wishing Well", "Coins glitter at the bottom."), {
   "small": (("Jogar 30 de ouro", "60%: uma carta sorteada sobe de nível. 40%: nada."), ("Toss 30 gold", "60%: a random card levels up. 40%: nothing.")),
   "big": (("Jogar 80 de ouro", "Suba o nível de 1 entre 3 cartas."), ("Toss 80 gold", "Level up 1 of 3 cards.")),
   "leave": (("Seguir", "Nada acontece."), ("Move on", "Nothing happens."))}),
 "librarian": (("Bibliotecário", "Um velho cataloga grimórios esquecidos."), ("Librarian", "An old man catalogs forgotten grimoires."), {
   "rewrite": (("Reescrever", "Uma carta à escolha vira outra sorteada, de raridade acima."), ("Rewrite", "A card of your choice becomes a random card of higher rarity.")),
   "copy": (("Copiar", "Duplique uma carta (até 2 cópias)."), ("Copy", "Duplicate a card (up to 2 copies).")),
   "leave": (("Seguir", "Nada acontece."), ("Move on", "Nothing happens."))}),
 "heroes_banquet": (("Banquete dos Heróis", "A mesa da próxima estalagem está posta."), ("Heroes' Banquet", "The next inn's table is set."), {
   "poison": (("Envenenar", "O próximo herói chega com 20% menos vida, mas o atual cura 20%."), ("Poison", "The next hero arrives with 20% less health, but the current one heals 20%.")),
   "loot": (("Saquear", "+60 de ouro; o herói atual cura 10%."), ("Loot", "+60 gold; the current hero heals 10%.")),
   "leave": (("Seguir", "Nada acontece."), ("Move on", "Nothing happens."))}),
 "dark_smith": (("Ferreiro Sombrio", "Uma forja que nunca apaga."), ("Dark Smith", "A forge that never goes out."), {
   "rush": (("Forjar às pressas", "2 cartas sorteadas sobem de nível; 1 carta sorteada sai do deck."), ("Rush job", "2 random cards level up; 1 random card leaves the deck.")),
   "order": (("Encomendar (50 de ouro)", "Suba o nível de uma carta à escolha."), ("Commission (50 gold)", "Level up a card of your choice.")),
   "leave": (("Seguir", "Nada acontece."), ("Move on", "Nothing happens."))}),
 "forgotten_tomb": (("Tumba Esquecida", "Uma laje rachada esconde algo."), ("Forgotten Tomb", "A cracked slab hides something."), {
   "open": (("Abrir", "50%: 1 relíquia sorteada. 50%: o próximo herói chega com uma habilidade a mais."), ("Open", "50%: a random relic. 50%: the next hero arrives with one extra ability.")),
   "careful": (("Saquear com cuidado", "Uma carta comum sorteada."), ("Loot carefully", "A random common card.")),
   "leave": (("Seguir", "Nada acontece."), ("Move on", "Nothing happens."))}),
}

for k, v in REL.items():
    S["REL_" + k] = (v[0], v[2])
    S["RELD_" + k] = (v[1], v[3])
for k, (pt, en, opts) in EVT.items():
    S["EVT_" + k] = (pt[0], en[0])
    S["EVT_%s_BODY" % k] = (pt[1], en[1])
    for o, (op, oe) in opts.items():
        S["EVT_%s_%s" % (k, o)] = (op[0], oe[0])
        S["EVT_%s_%s_D" % (k, o)] = (op[1], oe[1])


def main():
    raw = CSV.read_text(encoding="utf-8")
    rows = list(csv.reader(io.StringIO(raw)))
    head, body = rows[0], rows[1:]
    idx = {r[0]: i for i, r in enumerate(body) if r}
    for k, (pt, en) in S.items():
        if k in idx:
            body[idx[k]] = [k, pt, en]
        else:
            body.append([k, pt, en])
    out = io.StringIO()
    w = csv.writer(out, lineterminator="\n")
    w.writerow(head)
    w.writerows(body)
    CSV.write_text(out.getvalue(), encoding="utf-8")
    print("ok:", len(S), "chaves")


if __name__ == "__main__":
    main()
