"""Preview no Chrome headless: contorno unido por figura (cópia escura atrás), linhas internas finas."""
import os, subprocess, tempfile

CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe"
SCR = "C:/Users/gabri/AppData/Local/Temp/claude/df0eb8c5d2d2aad7/388ffdb7-a033-4c30-8855-5da64eb88778/scratchpad/comp_praga_2"

JS = """
const ns='http://www.w3.org/2000/svg';
document.querySelectorAll('.guide').forEach(e=>e.style.display=SHOWGUIDE?'':'none');
document.querySelectorAll('g[id^="fig_"], g[id^="pose_"]').forEach(g=>{
  const back=g.cloneNode(true); back.removeAttribute('id');
  back.querySelectorAll('[id]').forEach(e=>e.removeAttribute('id'));
  back.querySelectorAll('path').forEach(p=>{ if(p.classList.contains('inner')||p.getAttribute('fill')==='none'){p.remove();return;}
     p.setAttribute('fill','#2b1a10'); p.setAttribute('stroke','#2b1a10'); p.setAttribute('stroke-width',INKW); p.setAttribute('stroke-linejoin','round');});
  g.parentNode.insertBefore(back,g);
  g.querySelectorAll('path.inner').forEach(p=>{ if(p.getAttribute('fill')!=='none'){p.setAttribute('stroke','#2b1a10');p.setAttribute('stroke-width','.5');}});
});
document.querySelectorAll('#enxame path').forEach(p=>{p.setAttribute('stroke','#2b1a10');p.setAttribute('stroke-width','.8');p.setAttribute('stroke-linejoin','round');});
"""


def shot(svg_text, out_png, vb, w, h, guide=False, inkw=2.6):
    x, y, vw, vh = vb
    import re
    svg2 = re.sub(r'viewBox="[^"]*"', f'viewBox="{x} {y} {vw} {vh}"', svg_text, count=1)
    svg2 = re.sub(r'<svg ', f'<svg width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice" ', svg2, count=1)
    html = (f"<!doctype html><html><head><meta charset='utf-8'><style>html,body{{margin:0;padding:0;overflow:hidden;background:#fff}}"
            f"svg{{display:block}}</style></head><body>{svg2}<script>const SHOWGUIDE={str(guide).lower()};const INKW='{inkw}';{JS}</script></body></html>")
    fd, path = tempfile.mkstemp(suffix=".html", dir=SCR); os.close(fd)
    open(path, "w", encoding="utf-8").write(html)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", f"--window-size={w},{h}",
                    f"--screenshot={out_png}", "--default-background-color=ffffffff", "file:///" + path.replace("\\", "/")],
                   capture_output=True, timeout=60)
    os.remove(path)
    from PIL import Image
    im = Image.open(out_png)
    if im.size != (w, h):
        im.crop((0, 0, w, h)).save(out_png)
