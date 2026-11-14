"""Rodada 11 (13/11/2026): o estilo escolhido (V2 nível S1) com as regras de olhos, em mais cartas.

Regras do designer (13/11): pose/elementos da arte aprovada; guache leve V2; só pincel largo, nada de detalhe
pequeno; criaturas com olhos ESTILIZADOS (nunca só uma bolinha); humanos NUNCA com olhos (rosto na sombra).

Cadeia (a mesma que levou ao S1, para que qualquer carta chegue ao mesmo lugar):
  arte do baralho (raw) --A: pincel chato largo, 0,62--> --V2: guache leve, 0,5--> --mediana 9 + S1, 0,45-->
Rei, Dragão e Patrulheiro já têm a V2 (a1_variacoes.py): só o último passo, com semente nova (1001).

python -I novo_estilo.py [ids...]
Saída: arte_ia/novo_estilo/<card>/{A,V2,S1}_raw.png e <card>.png; prancha arte_ia/pranchas/novo_estilo.png
"""
import os, sys, zlib
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as gm
import pincel_grosso as pg, pincel_grosso_a as pa, a1_variacoes as av, v2_sem_detalhe as vs
from deck import crop_final, MODEL, W, H, GRAIN

OUT = os.path.join(gen.ROOT, "novo_estilo")
R = gen.ROOT
EYES = ("Every creature's eyes are two small narrow slanted almond shapes of one flat color, each painted with a "
        "single short brush stroke.")
HUMAN = "his face hidden in the dark shadow of his helmet"
SO_HUMANOS = {"molten_gold"}          # cartas sem nenhuma criatura: sem a frase de olhos
TONE = av.TONE

# Rei, Dragão, Patrulheiro: assunto da V2 com a regra de olhos nova
SUBJ = {
    "rat_king": ("lilac", "a gaunt old grey rat king seated on a throne of bones and skulls, raising a golden "
                 "scepter that is one plain gold rod. A plain gold crown with three simple points, a tattered purple "
                 "cape, a crowd of grey rats with pink ears spilling forward at his feet. The rats' eyes are narrow "
                 "slanted almond shapes of flat dark red, each one single brush stroke."),
    "elder_dragon": ("teal", "a huge ancient red dragon with a pale yellow belly and two long plain curved horns "
                     "standing in side view, breathing a stream of orange fire, wings raised. Its whole body is smooth "
                     "red skin painted in a few wide strokes. Its eye is one narrow slanted almond shape of flat "
                     "glowing amber, a single brush stroke."),
    "ranger": vs.SUBJ["ranger"],
}
NAMES = {"rat_king": "Rei dos Ratos", "elder_dragon": "Dragão Ancião", "ranger": "Patrulheiro",
         "molten_gold": "Ouro Derretido", "ruin_titan": "Titã das Ruínas", "bubonic_plague": "Peste Bubônica"}


def subject_of(card):
    if card in SUBJ:
        return SUBJ[card]
    e = gen.load_subjects()[card]
    s = e["subject"].replace("a plain round steel helmet", "a plain round steel helmet, " + HUMAN)
    # a frase de olhos só entra onde há criatura: num quadro só com o herói ela pôs olhos dentro do elmo (13/11)
    return e["bg"], (s if card in SO_HUMANOS else f"{s} {EYES}")


def repaint(card, init_img, medium, texture, den, seed, tag, brush=""):
    d = os.path.join(OUT, card)
    os.makedirs(d, exist_ok=True)
    init = os.path.join(d, f"_init_{tag}.png")
    init_img.save(init)
    bg, subj = subject_of(card)
    p = f"{medium}{subj} A plain flat {gen.BACKGROUNDS[bg]} sky behind. {TONE} {brush}{texture}"
    g, _ = gen.workflow(MODEL, p, seed, W, H, init_image=gen.upload_image(init), denoise=den)
    raw = os.path.join(d, f"{tag}_raw.png")
    open(raw, "wb").write(gen.run(g))
    open(os.path.join(d, f"{tag}.txt"), "w", encoding="utf-8").write(f"denoise {den} seed {seed}\n{p}\n")
    return Image.open(raw).convert("RGB")


def make(card):
    _, v2_med, v2_tex = av.VARIANTS["V2"]
    if card in ("rat_king", "elder_dragon", "ranger"):
        v2 = Image.open(os.path.join(av.OUT, card, "V2_raw.png")).convert("RGB")
        seed = 1001                                           # "mais 1 de cada": semente nova
    else:
        seed = 1000
        base = Image.open(os.path.join(R, card, "krea2anime__deck__t2i__s1000.png")).convert("RGB")
        _, a_tex = pg.VARIANTS["A"]
        a = repaint(card, base, pg.MEDIUM, a_tex, 0.62, seed, "A")
        v2 = repaint(card, a, v2_med, v2_tex, 0.5, seed, "V2")
    s1 = repaint(card, vs.simplificar(v2, 9), v2_med, v2_tex, 0.45, seed, "S1", vs.BRUSH)
    d = os.path.join(OUT, card)
    gp = os.path.join(d, "S1_grain.png")
    gm.grain(s1, seed=zlib.crc32(f"{card}S1".encode()), strength=GRAIN).save(gp)
    crop_final(gp, os.path.join(d, f"{card}.png"))
    print(card, flush=True)


if __name__ == "__main__":
    ids = sys.argv[1:] or ["rat_king", "elder_dragon", "ranger", "molten_gold", "ruin_titan", "bubonic_plague"]
    for c in ids:
        make(c)
    rows = []
    for c in ids:
        antes = (os.path.join(vs.OUT, c, "S1.png") if c in SUBJ else os.path.join(R, "final", f"{c}.png"))
        rows.append((c, [(f"{NAMES.get(c, c)} · antes", antes),
                         (f"{NAMES.get(c, c)} · novo", os.path.join(OUT, c, f"{c}.png"))]))
    # duas colunas por carta, três cartas por linha
    flat = [cell for _, cells in rows for cell in cells]
    pg.prancha("novo_estilo", [(None, flat[i:i + 6]) for i in range(0, len(flat), 6)])
