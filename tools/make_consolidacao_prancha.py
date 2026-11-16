"""Prancha antes/depois da consolidação de 16/11/2026.

Uso: python -I tools/make_consolidacao_prancha.py
Lê docs/consolidacao/antes/*.png e docs/consolidacao/depois/*.png (mesmo nome, mesma semente; capturas de
tools/capture_consolidacao.sh) e grava docs/consolidacao/prancha/<nome>.jpg (antes à esquerda, depois à direita)
e docs/consolidacao/prancha.html, que abre direto no navegador.
"""
import html
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(ROOT, 'docs', 'consolidacao')
W = 960

# Nota curta por tela: o que mudou (o resto é igual).
NOTES = {
    '03_colecao': 'Sem Almas: "Cartas liberadas: n de t" no lugar do contador.',
    '04_config': 'Variações de arte escondidas (aparecem com --variantes).',
    '07_disputa_taverna': 'Painel com o nome da classe; estrada sem degrau na emenda dos trechos.',
    '09_oferta_queda': '"Herói caído! Escolha 1" no lugar de "Subiu de nível!"; dica com folga; ajuda do rodapé em etiqueta de papel.',
    '15_party4': '"A PARTY" no painel com mais de um herói; tom de cada classe tirado da carta.',
    '19_resultado': 'Sem Almas, nível do herói e Santuários: heróis derrubados, disputas, ouro e relíquias.',
    '20_resultado_lich': 'Idem; texto no plural.',
}


def side_by_side(a, b, out):
    ia = Image.open(a).convert('RGB')
    ib = Image.open(b).convert('RGB')
    h = int(ia.height * W / ia.width)
    ia = ia.resize((W, h))
    ib = ib.resize((W, int(ib.height * W / ib.width)))
    hh = max(ia.height, ib.height)
    sheet = Image.new('RGB', (W * 2 + 12, hh + 34), (30, 24, 20))
    sheet.paste(ia, (0, 34))
    sheet.paste(ib, (W + 12, 34))
    d = ImageDraw.Draw(sheet)
    d.text((10, 10), 'ANTES', fill=(230, 210, 180))
    d.text((W + 22, 10), 'DEPOIS', fill=(230, 210, 180))
    sheet.save(out, quality=86)


def main():
    antes = os.path.join(BASE, 'antes')
    depois = os.path.join(BASE, 'depois')
    out_dir = os.path.join(BASE, 'prancha')
    os.makedirs(out_dir, exist_ok=True)
    rows = []
    for f in sorted(os.listdir(depois)):
        if not f.endswith('.png'):
            continue
        name = f[:-4]
        a = os.path.join(antes, f)
        if not os.path.exists(a):
            continue
        side_by_side(a, os.path.join(depois, f), os.path.join(out_dir, name + '.jpg'))
        rows.append(name)
    parts = ['<!doctype html><meta charset="utf-8"><title>Consolidação 16/11 · antes e depois</title>',
             '<style>body{background:#1e1814;color:#eadbc0;font:16px/1.4 sans-serif;margin:24px}'
             'img{width:100%;max-width:1932px;display:block;margin:6px 0 28px}h2{font-size:18px;margin:0}'
             'p{margin:2px 0;color:#c9b38e}</style>',
             '<h1>Consolidação de 16/11/2026: antes e depois</h1>',
             '<p>Mesma semente (7), configurações padrão, 1920x1080. Antes à esquerda, depois à direita.</p>']
    for name in rows:
        parts.append('<h2>%s</h2><p>%s</p><img src="prancha/%s.jpg" alt="%s">' % (
            html.escape(name), html.escape(NOTES.get(name, '')), name, html.escape(name)))
    with open(os.path.join(BASE, 'prancha.html'), 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(parts) + '\n')
    print('%d telas na prancha' % len(rows))


if __name__ == '__main__':
    main()
