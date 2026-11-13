"""Kit da interface (rodada de UI 13/11/2026) feito das MESMAS camadas do molde das cartas (assets/cards/mold/),
para que painéis, botões e faixas tenham o papel, a moldura dourada e as fitas das cartas.

Uso: python -I tools/art/ui_kit/make_ui_kit.py   (depois: godot --headless --path . --import)
Saída: assets/ui/kit/*.png, desenhados para 9-slice (StyleBoxTexture): margens em UiParch (game/ui_parch.gd).
"""
from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[3]
MOLD = ROOT / "assets" / "cards" / "mold"
OUT = ROOT / "assets" / "ui" / "kit"
OUT.mkdir(parents=True, exist_ok=True)
S = 0.5      # as camadas estão em 2x; o kit fica no tamanho em que as cartas aparecem


def L(n):
    return Image.open(MOLD / f"{n}.png").convert("RGBA")


def half(im):
    return im.resize((round(im.width * S), round(im.height * S)), Image.LANCZOS)


def stack(*names):
    base = L(names[0])
    for n in names[1:]:
        base.alpha_composite(L(n))
    return base


# Painéis: papel creme + moldura (rara = dourada com arabescos; comum = traço de tinta).
half(stack("paper_none_full", "frame_rare_full")).save(OUT / "panel_gold.png")
half(stack("paper_none_full", "frame_common_full")).save(OUT / "panel_ink.png")
half(stack("paper_shadowy_full", "frame_rare_full")).save(OUT / "panel_dark.png")
half(stack("paper_veteran_full", "frame_rare_full")).save(OUT / "panel_night.png")
# Botões: as mesmas peças em 1/4 (cantos de ~17 px cabem num botão de 44 px).
for name, fr in (("button_ink", "frame_common_full"), ("button_gold", "frame_rare_full")):
    im = stack("paper_none_full", fr)
    im.resize((150, 210), Image.LANCZOS).save(OUT / f"{name}.png")
# Só a moldura (para pôr sobre arte: retratos dos vilões e heróis).
half(L("frame_rare_full")).save(OUT / "frame_gold.png")
half(L("frame_legendary_full")).save(OUT / "frame_legend.png")
half(L("lv3_full")).save(OUT / "frame_heavy.png")
# Fitas dobradas do nome, por tipo: botões principais e títulos.
for t in ["monster", "swarm", "spell", "structure", "route", "lair", "finisher"]:
    rib = L(f"ribbon_{t}_full").crop((0, 482, 600, 604))
    half(rib).save(OUT / f"ribbon_{t}.png")
    # estado "apertado/desligado": mais escuro e menos saturado
    d = ImageEnhance.Color(ImageEnhance.Brightness(rib).enhance(0.72)).enhance(0.55)
    half(d).save(OUT / f"ribbon_{t}_dim.png")
# Gema de custo (elixir) solta.
for g in ["gem_common_purple", "gem_uncommon_purple", "gem_rare_purple", "gem_legendary_purple", "gem_common_teal"]:
    L(g).save(OUT / f"{g}.png")
print("kit em", OUT)

# Fell SC sem algarismos (o "1" dela parece um "I": "1x" lia "IX" no botão de velocidade). Na interface os números caem
# na fonte de reserva (Alegreya Sans Bold); as cartas continuam com a Fell SC inteira.
from fontTools.ttLib import TTFont
f = TTFont(ROOT / "assets" / "fonts" / "IMFellEnglishSC-Regular.ttf")
for t in f["cmap"].tables:
    for cp in list(t.cmap):
        if 0x30 <= cp <= 0x39:
            del t.cmap[cp]
f.save(ROOT / "assets" / "fonts" / "IMFellEnglishSC-UI.ttf")
print("fonte IMFellEnglishSC-UI.ttf")
