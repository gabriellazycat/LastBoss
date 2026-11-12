"""Preview do lote comuns_1: igual ao render.py do praga_2 (contorno unido por figura), e mais um contorno por data-fig
dentro de cada figura (cabeça, prop), desenhado logo antes da primeira peça daquele data-fig — como o acabamento faz
(uma silhueta por data-fig). Não altera o render.py compartilhado."""
import re
import render

EXTRA = """
document.querySelectorAll('g[id^="fig_"], g[id^="pose_"]').forEach(g=>{
  const groups={};
  g.querySelectorAll(':scope > path').forEach(p=>{ if(p.classList.contains('inner')||p.getAttribute('fill')==='none') return;
     const k=p.getAttribute('data-fig'); (groups[k]=groups[k]||[]).push(p);});
  const keys=Object.keys(groups); if(keys.length<2) return;
  keys.forEach(k=>{ const ps=groups[k]; const first=ps[0];
     ps.forEach(p=>{ const c=p.cloneNode(true); c.removeAttribute('id'); c.setAttribute('fill','#2b1a10'); c.setAttribute('stroke','#2b1a10');
        c.setAttribute('stroke-width',INKW2); c.setAttribute('stroke-linejoin','round'); c.removeAttribute('opacity'); g.insertBefore(c, first);});
  });
});
"""
_JS0 = render.JS


def shot(svg_text, out_png, vb, w, h, guide=False, inkw=2.6):
    render.JS = _JS0.replace("document.querySelectorAll('g[id^=\"fig_\"], g[id^=\"pose_\"]').forEach(g=>{\n  const back",
                             EXTRA.replace("INKW2", f"'{inkw * 0.6:.2f}'") + "\ndocument.querySelectorAll('g[id^=\"fig_\"], g[id^=\"pose_\"]').forEach(g=>{\n  const back", 1)
    try:
        render.shot(svg_text, out_png, vb, w, h, guide, inkw)
    finally:
        render.JS = _JS0
