"""Estilo FIXO do baralho (decidido em 13/11/2026): guache leve com um pincel largo só, sem detalhe fino.

Nunca mude por carta. Mudar qualquer constante muda o baralho inteiro (só com pedido explícito do designer).
Regras do designer, 13/11:
  - pose e quantidade de elementos da arte aprovada do baralho; muitos ratos é bom;
  - guache leve (V2): pincel chato largo, valores claros, branco do papel aparecendo, 1 sombra grande por forma;
  - NADA de detalhe fino (escama, dobra, fivela, enfeite de coroa, placas de armadura); sombra = mancha grande;
  - criaturas têm olhos ESTILIZADOS (amêndoas pequenas, uma pincelada); HUMANOS NUNCA têm olhos (rosto na sombra);
  - tamanho de geração = tamanho da carta (560x544 -> recorte 556x534), sem arte grande.
build_prompt(card) é o único lugar que monta o texto; o assunto por carta passa por adapt_subject().
"""
import re
from PIL import Image, ImageFilter

PAPER = "paper texture showing through, muted dusty colors, slightly blurry low-resolution scan."
MEDIUM = "A light gouache painting on rough watercolor paper, scanned from an old sketchbook: "
TONE = "Grounded serious fantasy book illustration with natural proportions."
BRUSH = ("Painted only with a very wide flat brush, so every mark is a broad stroke and the smallest shape is as wide "
         "as the brush; smooth unbroken color areas with one big soft shadow shape each. ")
# Mesmo texto que gerou as cartas aprovadas (a cláusula dos olhos fica: foi com ela que a prova saiu certa).
TEXTURE = ("Thin light gouache laid quickly with a wide flat brush, lighter airy values, soft edges where colors "
           "meet, the white of the paper glowing through the thinner strokes, large simple shapes, one soft shadow "
           "tone, eyes as one small dark dot, " + PAPER)
EYES = ("Every creature's eyes are two small narrow slanted almond shapes of one flat color, each painted with a "
        "single short brush stroke.")
BACKGROUNDS = {"lilac": "dusty lilac", "teal": "pale dusty teal", "ochre": "dusty ochre", "sand": "warm sand",
               "slate": "grey-blue slate", "rose": "faded old rose"}

# Frases antigas -> frases simples (ordem importa: as longas primeiro). Olhos saem das frases fixas.
SWAPS = [
    ("A lone human knight in dented steel plate armor with a faded blue tabard and a plain round steel helmet, holding a straight steel sword",
     "A lone human knight in plain steel armor made of a few large smooth plates with a faded blue tabard and a plain round steel helmet whose whole face opening is one flat solid black shadow, holding a straight steel sword"),
    ("a lone human knight in dented steel plate armor with a faded blue tabard and a plain round steel helmet, holding a straight steel sword",
     "a lone human knight in plain steel armor made of a few large smooth plates with a faded blue tabard and a plain round steel helmet whose whole face opening is one flat solid black shadow, holding a straight steel sword"),
    ("a lone human knight in dented steel plate armor with a faded blue tabard and a plain round steel helmet, holding a straight steel sword",
     "a lone human knight in plain steel armor made of a few large smooth plates with a faded blue tabard and a plain round steel helmet whose whole face opening is one flat solid black shadow, holding a straight steel sword"),
    ("dented steel plate armor", "plain steel armor made of a few large smooth plates"),
    ("blackened plate armor", "plain black armor made of a few large plates"),
    ("plate armor", "plain armor made of a few large plates"),
    ("a plain round wooden shield with an iron rim", "a plain round wooden shield"),
    ("cracked crimson scales", "smooth crimson skin"),          # escama = risquinho fino (queixa do designer, 13/11)
    (" and a ragged frill", " and a smooth frill"), (", a ragged frill", ", a smooth frill"),
    (" and small red eyes", ""), ("small red eyes and ", ""), (" and yellow eyes", ""),
    ("with yellow eyes and bristling fur", "with bristling fur"), ("yellow eyes and a scarred muzzle", "a scarred muzzle"),
    (" with yellow eyes", ""), (" and glowing yellow eyes burn brighter than before", ""),
    (" and around their eyes", ""), (" and its yellow eyes stare ahead", ""),
    (" except for two small cold cyan-green glowing eyes", " except for a faint cold cyan-green glow"),
    (" and small dark eyes", ""), (", two glowing amber eyes", ""), (", one yellow eye half open,", ","),
    (" for an eye", " on its head"),
]
# criaturas (olhos estilizados entram); esqueleto com órbitas e golem com fenda já têm o "olho" próprio
CREATURE = re.compile(r"\b(rats?|bats?|wolf|wolves|dragons?|goblins?|kobolds?|imps?|boars?|trolls?|ogres?|titans?|golems?|"
                      r"beasts?|slimes?|ghouls?|werewolf|mimics?|gargoyles?|phoenix|hounds?|salamanders?|drakelings?|"
                      r"vipers?|snakes?|bears?|hyenas?|crows?|ravens?|lich|ghosts?|spiders?|demons?|colossus|"
                      r"monsters?|creatures?|cats?|dogs?|lizards?|birds?|vultures?)\b", re.I)
OWN_EYE = re.compile(r"eye sockets|slit on its head", re.I)


def adapt_subject(text):
    for a, b in SWAPS:
        text = text.replace(a, b)
    text = re.sub(r"\s{2,}", " ", text).strip()
    if CREATURE.search(text) and not OWN_EYE.search(text):
        text += " " + EYES
    return text


def build_prompt(subject, bg):
    return (f"{MEDIUM}{adapt_subject(subject)} A plain flat {BACKGROUNDS[bg]} sky behind. {TONE} {BRUSH}{TEXTURE}")


def simplificar(img, k=7):
    """Base da repintura sem detalhe fino: nenhuma marca menor que o pincel sobrevive (mediana duas vezes)."""
    im = img.filter(ImageFilter.MedianFilter(k)).filter(ImageFilter.MedianFilter(k))
    return im.filter(ImageFilter.GaussianBlur(0.8))
