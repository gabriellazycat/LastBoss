"""Galeria antes/depois da revisão visual (docs/REVISAO_VISUAL.md).

Uso: python -I tools/make_gallery.py <pasta do depois, ex.: docs/visual/rodada_6>
Gera docs/visual/galeria/*.jpg (miniaturas de 960 px) e docs/visual/galeria.html, que abre direto no navegador.
"""
import html
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VIS = os.path.join(ROOT, 'docs', 'visual')
OUT = os.path.join(VIS, 'galeria')

# (arquivo sem extensão, título, nota curta). hand_* vêm do teste da entrada real e não existem no "antes" com o
# mesmo nome; o "antes" deles está em antes/uitest/.
SCREENS = [
    ('title_1920x1080', 'Menu principal', 'Título com degradê de metal, botões em Cinzel, covil escuro com brasas.'),
    ('decks_1920x1080', 'Escolha de Pacto', 'Brasão de cada Pacto, véu escuro atrás do texto, moldura de ferro e bronze.'),
    ('collection_1920x1080', 'Coleção', 'Cadeado nas bloqueadas, miniaturas no deck, preço em cobre.'),
    ('settings_video_1920x1080', 'Configurações', 'Abas e botões com estado aceso; listas com seta.'),
    ('settings_controls_1920x1080', 'Controles', ''),
    ('run_start_1920x1080', 'Começo da run', 'HUD com hierarquia: o herói no centro, o tempo solto sobre o mundo.'),
    ('run_mid_1920x1080', 'Meio da run', 'Cartas da mão com plaqueta e atalho no pé; frascos de elixir.'),
    ('hand_hover_1920x1080', 'Carta ampliada', 'A carta sob o mouse cresce; sem a carta fantasma de antes.'),
    ('hand_map_1920x1080', 'Mapa grande', 'Título, legenda e estrada com contorno.'),
    ('offer_1920x1080', 'Oferta de cartas', 'Cartas grandes com arte, plaqueta, tipo, texto e raridade.'),
    ('pause_1920x1080', 'Pausa', 'Escurecimento atrás (antes não aparecia); o deck da run.'),
    ('hint_1920x1080', 'Dica', ''),
    ('arena_1920x1080', 'Arena', 'Partes do corpo com a vida em %.'),
    ('result_1920x1080', 'Resultado', 'Almas ganhas em destaque, zeros apagados.'),
    ('run_mid_1280x720', 'Meio da run (1280x720)', ''),
    ('offer_1280x720', 'Oferta (1280x720)', ''),
    ('decks_en_1920x1080', 'Pactos em inglês', ''),
    ('offer_en_1920x1080', 'Oferta em inglês', ''),
]
BEFORE_ALIAS = {'hand_hover_1920x1080': 'uitest/uitest_hover', 'hand_map_1920x1080': 'uitest/uitest_map'}


def thumb(src, dst):
    im = Image.open(src).convert('RGB')
    w = 960
    im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    im.save(dst, quality=84, optimize=True)


def main():
    after_dir = os.path.join(ROOT, sys.argv[1])
    os.makedirs(OUT, exist_ok=True)
    rows = []
    for name, title, note in SCREENS:
        b = os.path.join(VIS, 'antes', BEFORE_ALIAS.get(name, name) + '.png')
        a = os.path.join(after_dir, name + '.png')
        if not (os.path.exists(b) and os.path.exists(a)):
            print('sem par:', name)
            continue
        thumb(b, os.path.join(OUT, name + '_antes.jpg'))
        thumb(a, os.path.join(OUT, name + '_depois.jpg'))
        rows.append((name, title, note))
    figs = []
    for name, title, note in rows:
        figs.append(f'''  <section class="pair" id="{name}">
    <header><h2>{html.escape(title)}</h2>{f'<p>{html.escape(note)}</p>' if note else ''}</header>
    <div class="shots">
      <figure><img src="galeria/{name}_antes.jpg" alt="{html.escape(title)}, antes" loading="lazy"><figcaption>Antes</figcaption></figure>
      <figure><img src="galeria/{name}_depois.jpg" alt="{html.escape(title)}, depois" loading="lazy"><figcaption>Depois</figcaption></figure>
    </div>
  </section>''')
    page = TEMPLATE.replace('{{FIGS}}', '\n'.join(figs)).replace('{{N}}', str(len(rows)))
    open(os.path.join(VIS, 'galeria.html'), 'w', encoding='utf-8', newline='\n').write(page)
    print('galeria:', len(rows), 'telas')


TEMPLATE = '''<title>Last Boss, antes e depois</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Cinzel:wght@700;900&family=Alegreya+Sans:wght@500;700&display=swap">
<style>
/* Layout: uma coluna de pares antes/depois, como uma tira de provas; a página tem a cor do covil (só escura). */
:root {
  --iron: #110e13;
  --plate: #1c171e;
  --bronze: #cc9e61;
  --gold: #ffd180;
  --parchment: #f2e9dc;
  --ash: #b3a597;
  --display: "Cinzel", "Trajan Pro", Georgia, serif;
  --body: "Alegreya Sans", "Segoe UI", system-ui, sans-serif;
  color-scheme: dark;
}
html { background: var(--iron); }
body { background: var(--iron); color: var(--parchment); font: 500 17px/1.5 var(--body);
  padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); padding-block: 40px 64px; }
main { max-width: 1480px; margin: 0 auto; display: grid; gap: 48px; }
.intro { display: grid; gap: 10px; max-width: 70ch; }
.intro .eyebrow { font: 700 13px/1 var(--body); letter-spacing: .18em; text-transform: uppercase; color: var(--bronze); }
h1 { font: 900 clamp(34px, 6vw, 64px)/1.05 var(--display); margin: 0; color: var(--gold); text-wrap: balance;
  text-shadow: 0 3px 0 #000; }
.intro p { margin: 0; color: var(--ash); }
.pair { display: grid; gap: 14px; padding-top: 22px; border-top: 1px solid color-mix(in srgb, var(--bronze) 35%, transparent); }
.pair header { display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px 18px; }
h2 { font: 700 22px/1.2 var(--display); margin: 0; color: var(--parchment); letter-spacing: .03em; }
.pair header p { margin: 0; color: var(--ash); min-width: 0; }
.shots { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
figure { margin: 0; display: grid; gap: 6px; min-width: 0; }
figure img { width: 100%; height: auto; display: block; border: 2px solid #000; outline: 1px solid color-mix(in srgb, var(--bronze) 55%, transparent);
  box-shadow: 0 8px 24px rgba(0,0,0,.55); background: var(--plate); }
figcaption { font: 700 12px/1 var(--body); letter-spacing: .16em; text-transform: uppercase; color: var(--ash); }
figure:last-child figcaption { color: var(--gold); }
@media (max-width: 760px) { .shots { grid-template-columns: 1fr; } }
</style>
<main>
  <div class="intro">
    <span class="eyebrow">Revisão visual · 08/11/2026 · {{N}} telas</span>
    <h1>Last Boss, antes e depois</h1>
    <p>Interface refeita na direção "Covil": ferro escuro, aro de bronze, gemas facetadas, Cinzel nos títulos e Alegreya Sans no texto. À esquerda o estado de partida, à direita a última rodada de revisão. Detalhes, notas e decisões em docs/REVISAO_VISUAL.md.</p>
  </div>
{{FIGS}}
</main>
'''

if __name__ == '__main__':
    main()
