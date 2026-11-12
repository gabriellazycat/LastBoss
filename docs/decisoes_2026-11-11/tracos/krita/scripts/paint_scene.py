# Runs INSIDE Krita (via the lbpaint plugin). Paints a scene module with Krita's brush engine.
# env: LB_SCENE (module name), LB_OUT (output basename, no extension), LB_PAPER (raw BGRA file)
import os, sys, importlib, traceback, math
HERE = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else r"C:\Users\gabri\AppData\Local\Temp\claude\40bf9cbc2d3684ea\25b63c19-91de-4a41-96b6-c3333a27c422\scratchpad\krita_brushes\py"
sys.path.insert(0, HERE)
from krita import Krita, ManagedColor, InfoObject
from PyQt5.QtCore import QPoint, QPointF
from PyQt5.QtGui import QPainterPath
import lbgeom as G
for m in ("lbgeom", os.environ["LB_SCENE"]):
    if m in sys.modules: importlib.reload(sys.modules[m])
sc = importlib.import_module(os.environ["LB_SCENE"])
OUT = os.environ["LB_OUT"]
open(os.environ["LB_LOG"], "a").write("OUT=" + OUT + " scene=" + str(sc) + chr(10))
log = open(OUT + "_log.txt", "w", encoding="utf-8")

k = Krita.instance()
W, H = sc.W, sc.H
doc = k.createDocument(W, H, os.path.basename(OUT), "RGBA", "U8", "", 300.0)
win = k.activeWindow()
view = win.addView(doc)
k.setActiveDocument(doc)
presets = k.resources('preset')
root = doc.rootNode()

def col(rgb):
    c = ManagedColor("RGBA", "U8", "")
    c.setComponents([rgb[2] / 255.0, rgb[1] / 255.0, rgb[0] / 255.0, 1.0])
    return c

paper = doc.createNode("papel", "paintlayer"); root.addChildNode(paper, None)
paper.setPixelData(open(os.environ["LB_PAPER"], "rb").read(), 0, 0, W, H)

layers = {}
def layer(name, blend="multiply"):
    if name not in layers:
        n = doc.createNode(name, "paintlayer")
        root.addChildNode(n, None)
        n.setBlendingMode(blend)
        layers[name] = n
    doc.setActiveNode(layers[name])
    return layers[name]

def path_from(pts, step=6.0, closed=False):
    smp = G.catmull(pts, closed=closed, step=step)
    p = QPainterPath(); p.moveTo(QPointF(*smp[0]))
    for q in smp[1:]: p.lineTo(QPointF(*q))
    return p

def brush(preset, size, rgb, opacity=1.0):
    view.setCurrentBrushPreset(presets[preset])
    view.setForeGroundColor(col(rgb))
    view.setBrushSize(float(size))
    view.setPaintingOpacity(float(opacity))

# ---------------- washes
for i, w in enumerate(sc.WASH):
    try:
        L = layer(w["layer"])
        L.setOpacity(int(255 * w.get("layer_opacity", 1.0)))
        brush(w["preset"], w["size"], w["color"], w.get("opacity", 1.0))
        mode = w["mode"]
        if mode == "fill":
            poly = G.offset(w["poly"], w.get("dx", 0), w.get("dy", 0), w.get("grow", 1.0), seed=i, jit=w.get("jit", 6))
            strands = G.scribble(poly, w.get("spacing", w["size"] * 0.6), w.get("angle", -35), jitter=w.get("jitter", 8), seed=i + 5, inset=w.get("inset", w["size"] * 0.25))
            for pts in strands:
                L.paintPath(path_from(pts, step=8.0), "ForegroundColor", "None")
        elif mode == "lines":
            for ln in w["lines"]:
                L.paintPath(path_from(ln, step=5.0), "ForegroundColor", "None")
        elif mode == "dabs":
            for (x, y) in w["dabs"]:
                e = G.ellipse(x, y, w["size"] * 0.25, w["size"] * 0.2, n=6, seed=int(x))
                L.paintPath(path_from(e, step=3.0, closed=True), "ForegroundColor", "None")
        elif mode == "strokes":  # free brush strokes with pressure (pressure-aware washes)
            for st in w["strokes"]:
                smp = G.catmull(st, step=4.0)
                pr = G.pressures(smp, 0.25, 0.3, seed=i, shade=0.0, wobble=0.15)
                for j in range(len(smp) - 1):
                    a, b = smp[j], smp[j + 1]
                    L.paintLine(QPoint(int(a[0]), int(a[1])), QPoint(int(b[0]), int(b[1])), pr[j], pr[j + 1])
        log.write("wash ok %s %s\n" % (w["layer"], mode))
    except Exception:
        log.write("wash fail %s\n%s\n" % (w.get("layer"), traceback.format_exc()))

# ---------------- ink (pressure strokes, one paintLine per segment so pressure varies)
ink = layer("nanquim", "normal")
INK_PRESET = getattr(sc, "INK_PRESET", "d) Ink-3 Gpen")
for i, s in enumerate(sc.INK):
    try:
        brush(s.get("preset", INK_PRESET), s["size"] * getattr(sc, "INK_SCALE", 1.0), s.get("color", sc.SEPIA), s.get("op", 1.0))
        smp = G.catmull(s["pts"], closed=s.get("closed", False), step=2.5)
        smp = G.overshoot(smp, s.get("over", 0))
        pr = G.pressures(smp, s.get("taper_in", 0.12), s.get("taper_out", 0.18), seed=s.get("seed", 1), shade=s.get("shade", 0.45), mults=s.get("mults"))
        for j in range(len(smp) - 1):
            a, b = smp[j], smp[j + 1]
            ink.paintLine(QPoint(int(round(a[0])), int(round(a[1]))), QPoint(int(round(b[0])), int(round(b[1]))), pr[j], pr[j + 1])
    except Exception:
        log.write("ink fail %d\n%s\n" % (i, traceback.format_exc()))
log.write("ink ok\n")

doc.refreshProjection(); doc.waitForDone()
doc.setBatchmode(True)
doc.saveAs(OUT + ".kra")
doc.exportImage(OUT + "_full.png", InfoObject())
log.write("saved\n"); log.close()
doc.close()
