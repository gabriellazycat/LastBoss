"""Gera os modelos da rodada "miniaturas pintadas" (15/11/2026): 2 heróis, 10 inimigos, 10 cenários, em 3 geometrias
(n normal, c gorducha, f facetada) e 5 tratamentos de pintura (vc cor por vértice = controle; dabs, wash, dry, flat).
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_g/build_g.py -- <saída> [ids] [--geoms=n,c,f]
Saída: <saída>/<geom>/<id>.lbm  e  <saída>/tex/<tratamento>_<geom>/<id>.png.
Depois: godot --headless --path . -s res://tools/art/import_g.gd -- --src=<saída>"""
import os, sys, math, traceback, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "blender_v2"))
sys.path.insert(0, HERE)
import bpy
from mathutils import Vector
import mk, vat, monsters, monsters2, scenery, locations, anims
import vat_g, treat, heroes_g

# id -> (altura em metros no jogo, orçamento de triângulos, chave da paleta, humano)
UNITS = {
    "rat": (0.5, 1000, "rat"), "rat_king": (0.95, 1800, "rat_king"), "goblin_dynamiter": (1.0, 1700, "goblin_dynamiter"),
    "slime": (0.8, 1000, "slime"), "skeleton": (1.25, 1500, "skeleton"), "ogre": (2.3, 2100, "ogre"),
    "werewolf": (1.8, 2100, "werewolf"), "bat": (0.75, 1000, "bat"), "ghost": (1.3, 1100, "ghost"),
    "mimic": (1.0, 1500, "mimic"), "escudeiro": (1.75, 1800, "escudeiro"), "mago": (1.75, 1800, "mago"),
    "arqueira": (1.75, 1800, None), "cleriga": (1.75, 1800, None),
}
PROPS = {
    "tree": (5.5, 500), "tree_round": (4.6, 380), "rock": (1.1, 200), "bush": (1.4, 220), "house": (3.9, 2800),
    "tavern": (4.3, 3400), "fountain": (None, 2200), "gravestone": (1.35, 360), "lantern": (None, 500), "fence": (1.15, 360),
}
NO_RECENTER = {"lantern"}
HUMAN = {"escudeiro", "mago", "arqueira", "cleriga"}
TREATS = {"n": ["dabs", "wash", "dry", "flat"], "c": ["dabs"], "f": ["dabs"]}
COOL = (0.30, 0.32, 0.42)
GAIN = float(os.environ.get("LBG_GAIN", "0.45"))
PULL = float(os.environ.get("LBG_PULL", "0.65"))
GAIN_SC = float(os.environ.get("LBG_GAIN_SC", "0.6"))
PULL_SCENERY = float(os.environ.get("LBG_PULL_SC", "0.45"))
SAT = float(os.environ.get("LBG_SAT", "1.15"))
EYE = {"rat_king": (0.62, 0.13, 0.16)}
REUSE = bool(os.environ.get("LBG_REUSE"))


def build(i):
    if i in heroes_g.BUILD:
        return heroes_g.BUILD[i]()
    for m in (monsters, monsters2, scenery, locations):
        if hasattr(m, i):
            return getattr(m, i)()
    raise KeyError(i)


def roots():
    return [o for o in bpy.data.objects if o.parent is None]


def cfg(i):
    return heroes_g.cfg(i) if i in heroes_g.BUILD else anims.get(i)


def one(i, out, geoms):
    is_unit = i in UNITS
    h, budget = (UNITS[i][0], UNITS[i][1]) if is_unit else (PROPS[i][0], PROPS[i][1])
    key = UNITS[i][2] if is_unit else None
    tmp = os.path.join(tempfile.gettempdir(), "lbg_%s.blend" % i)
    a = cfg(i)
    if not (REUSE and os.path.exists(tmp)):  # LBG_REUSE=1: refaz só a graduação e o atlas, sem remontar o modelo
        mk._MATS.clear()
        bpy.ops.wm.read_factory_settings(use_empty=True)
        mk._MATS.clear()
        root = build(i)
        vat_g.simplify(root, human=i in HUMAN)
        if a.get("pretag"):
            a["pretag"](root)
        bpy.ops.wm.save_as_mainfile(filepath=tmp)
    for g in geoms:
        if g == "c" and not is_unit:
            continue  # propostas de gordura só valem para quem tem corpo; o cenário usa a normal
        bpy.ops.wm.open_mainfile(filepath=tmp)
        root = [r for r in roots() if r.type == 'EMPTY'][0]
        mk._MATS.clear()
        vat_g.flatten_eyes(root, EYE.get(i, (0.10, 0.085, 0.11)))
        if g == "c":
            for o in vat.descendants(root):
                if o.type == 'MESH' and o.get("bone") == "head":
                    o.scale = o.scale * 1.28
            root.scale = (1.22, 1.22, 1.0)
            bpy.context.view_layer.update()
        objs = vat_g.prepare(root, budget * (0.3 if g == "f" else 1.0), flat=(g == "f"))
        pk = treat.pal_key(i)
        grade = treat.make_grade(pk, pull=PULL if pk != "scenery" else PULL_SCENERY, lift=0.04, sat=SAT, gain=GAIN if pk != "scenery" else GAIN_SC)
        os.makedirs(os.path.join(out, g), exist_ok=True)
        d = vat_g.export(root, os.path.join(out, g, i + ".lbm"), h, objs, grade, a.get("anim") if is_unit else None,
                         a.get("deform"), a.get("rig"), recenter=i not in NO_RECENTER)
        C, P, N, M = treat.raster(d)
        for t in TREATS[g]:
            img = treat.treat(t, C, P, N, d["height"], COOL)
            td = os.path.join(out, "tex", "%s_%s" % (t, g))
            os.makedirs(td, exist_ok=True)
            treat.save_png(img, os.path.join(td, i + ".png"))
    return True


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = argv[0]
    os.makedirs(out, exist_ok=True)
    ids = argv[1].split(",") if len(argv) > 1 and not argv[1].startswith("--") else list(UNITS) + list(PROPS)
    geoms = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("--geoms=")), ["n", "c", "f"])
    for i in ids:
        try:
            one(i, out, geoms)
        except Exception:
            print("FALHOU", i)
            traceback.print_exc()


main()
