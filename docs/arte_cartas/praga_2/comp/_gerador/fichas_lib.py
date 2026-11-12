import base  # noqa
from geom import *
INK = "#2b1a10"


def txt(x, y, s, size=11, w="normal", anchor="start"):
    return f'<text x="{x}" y="{y}" font-family="Georgia,serif" font-size="{size}" font-weight="{w}" fill="{INK}" text-anchor="{anchor}">{s}</text>'


def pose_g(name, pcs, place, prefix, guide=None, label=None, sub=None, ly=18):
    tx, ty, s = place
    body = "\n      ".join(p.svg(prefix, name + "_") for p in pcs)
    g = f'  <g transform="{tstr(tx, ty, 0, s)}">\n    <g id="pose_{name}">\n      {body}\n    </g>\n'
    if guide:
        g += f'    <path id="{name}_acao" class="guide" d="{cr_path(guide, False)}" fill="none" stroke="#d0402a" stroke-width="1.4" stroke-dasharray="4 3"/>\n'
    g += "  </g>"
    if label:
        g += "\n  " + txt(tx, ty + ly, label, 11, "bold", "middle")
    if sub:
        g += "\n  " + txt(tx, ty + ly + 14, sub, 9.5, "normal", "middle")
    return g


def swatches(x, y, items):
    out = []
    for i, (nm, c) in enumerate(items):
        yy = y + i * 16
        out.append(f'<rect x="{x}" y="{yy}" width="22" height="12" fill="{c}" stroke="{INK}" stroke-width=".6"/>')
        out.append(txt(x + 28, yy + 10, f"{nm} {c}", 9.5))
    return "\n  ".join(out)
