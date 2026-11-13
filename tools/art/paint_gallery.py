"""Pranchas de comparação do mundo pintado (docs/MUNDO_PINTADO.md).

Uso: python -I tools/art/paint_gallery.py <pasta das fotos> <pasta de saída>
Lê v<n>_<cena>.png (tools/art/capture_paint.sh) e grava, por cena, uma prancha 2 colunas x 5 linhas com o nome de
cada variação, mais uma carta da Rainha da Peste de referência no canto da primeira.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

NAMES = ["0 · Sem guache (hoje)", "S1 · Guache chapado", "S2 · Aguado", "S3 · Pincel largo",
         "T1 · IA dabs largos", "T2 · IA aguado", "T3 · IA pincel seco",
         "C1 · Chapado + IA dabs", "C2 · Aguado + IA aguado", "C3 · Pincel largo + IA pincel seco"]
SCENES = {"run": "Começo da run", "arena": "Arena do chefe", "mesa": "Mesa do menu"}
ROOT = Path(__file__).resolve().parents[2]


def font(sz):
    for f in ["AlegreyaSans-Bold.ttf", "Alegreya-VF.ttf"]:
        p = ROOT / "assets" / "fonts" / f
        if p.exists():
            return ImageFont.truetype(str(p), sz)
    return ImageFont.load_default()


def main():
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    W, H, PAD, LAB = 960, 540, 12, 46
    f = font(30)
    ref = Image.open(ROOT / "assets" / "cards" / "rat_tide.png").convert("RGB").resize((180, 173))
    for key, title in SCENES.items():
        have = [v for v in range(10) if (src / f"v{v}_{key}.png").exists()]
        rows = (len(have) + 1) // 2
        sheet = Image.new("RGB", (2 * W + 3 * PAD, rows * (H + LAB + PAD) + PAD + 60), (236, 228, 212))
        d = ImageDraw.Draw(sheet)
        d.text((PAD, 12), f"{title} — escolha a variação", fill=(60, 40, 30), font=font(38))
        for i, v in enumerate(have):
            x = PAD + (i % 2) * (W + PAD)
            y = 60 + PAD + (i // 2) * (H + LAB + PAD)
            d.text((x + 4, y + 6), NAMES[v], fill=(60, 40, 30), font=f)
            im = Image.open(src / f"v{v}_{key}.png").convert("RGB").resize((W, H), Image.LANCZOS)
            sheet.paste(im, (x, y + LAB))
            if v == 0:
                sheet.paste(ref, (x + W - 190, y + LAB + 10))
        sheet.save(out / f"comparar_{key}.jpg", quality=88)
        print("ok", out / f"comparar_{key}.jpg", len(have), "variações")


if __name__ == "__main__":
    main()
