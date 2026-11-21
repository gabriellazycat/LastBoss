"""Exporta as estruturas novas (structures_m2.py) no formato dos g_n_a (V4, pincel seco), para --modelos=1.
(build_m2.py, na mesma pasta, é o wrapper das peças de cenário de outro agente; este é só das estruturas.)
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_m2/build_structures_m2.py -- <saída> [ids] [--preview]
Saída: <saída>/n/<id>.lbm, <saída>/tex/dry_n/<id>.png e, com --preview, <saída>/prev/<id>.png (EEVEE, câmera a ~50°).
Depois: godot --headless --path . -s res://tools/art/import_g.gd -- --src=<saída> --m2   (grava assets/models/m2_a/<id>.res
e assets/models/g_tex/m2/<id>.png) e godot --headless --path . --import.
A pasta de saída deve ter só estes ids: o --m2 converte tudo o que houver em <saída>/n.
Mesma graduação e tratamento do build_g_all.py (ganho 0,45, saturação 1,15), sem puxar para a paleta de outra carta:
as cores já vêm da carta de cada estrutura (structures_m2.py). Escala 1:1 (height=None) e origem no pé (sem recentralizar)."""
import os, sys, math, time, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
V2 = os.path.abspath(os.path.join(HERE, "..", "blender_v2"))
G = os.path.abspath(os.path.join(HERE, "..", "blender_g"))
for p in (HERE, G, V2):
    if p not in sys.path:
        sys.path.insert(0, p)
import bpy
from mathutils import Vector
import mk, vat, vat_g, treat
import structures_m2 as S

GAIN = float(os.environ.get("LBM2_GAIN", "0.45"))
SAT = float(os.environ.get("LBM2_SAT", "1.15"))
COOL = (0.30, 0.32, 0.42)
EYE = (0.10, 0.085, 0.11)


def preview(root, path):
    sc = bpy.context.scene
    try:
        sc.render.engine = 'BLENDER_EEVEE_NEXT'
    except TypeError:
        sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x, sc.render.resolution_y = 700, 700
    sc.view_settings.view_transform = 'AgX'
    w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND'); bg.inputs[0].default_value = (0.6, 0.72, 0.7, 1); bg.inputs[1].default_value = 0.9
    sun = bpy.data.lights.new("Sun", 'SUN'); sun.energy = 4.0; so = bpy.data.objects.new("Sun", sun); sc.collection.objects.link(so)
    so.rotation_euler = (math.radians(40), 0, math.radians(-35))
    objs = [o for o in vat.descendants(root) if o.type == 'MESH']
    bpy.context.view_layer.update()
    lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c); lo = Vector(map(min, lo, p)); hi = Vector(map(max, hi, p))
    ctr = (lo + hi) / 2; r = max((hi - lo).length, 0.1)
    cd = bpy.data.cameras.new("C"); cd.lens = 50; c = bpy.data.objects.new("C", cd); sc.collection.objects.link(c)
    el = math.radians(50); az = math.radians(-25)
    c.location = ctr + Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el))) * r * 1.5
    c.rotation_euler = (ctr - c.location).to_track_quat('-Z', 'Y').to_euler(); sc.camera = c
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in (so, c):
        bpy.data.objects.remove(o, do_unlink=True)


def clip_ground(root, z=-0.06):
    """Apaga o que fica enterrado nas peças fixas (montes de terra e rocha são esferas cortadas pelo chão): só gasta
    triângulos. As partes animadas (estacas que descem, ratos na água) ficam inteiras."""
    import bmesh
    for o in vat.descendants(root):
        if o.type != 'MESH' or o.get("bone", "body") != "body":
            continue
        mk.apply_mods(o)
        mw = o.matrix_world
        bm = bmesh.new(); bm.from_mesh(o.data)
        dead = [v for v in bm.verts if (mw @ v.co).z < z]
        if dead and len(dead) < len(bm.verts):
            bmesh.ops.delete(bm, geom=dead, context='VERTS')
            bm.to_mesh(o.data)
        bm.free()


def export_one(i, out, prev):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mk._MATS.clear()
    root = S.build(i)
    if prev:
        os.makedirs(os.path.join(out, "prev"), exist_ok=True)
        preview(root, os.path.join(out, "prev", i + ".png"))
    h, budget = S.UNITS[i]
    a = S.cfg(i)
    clip_ground(root)
    gone = vat_g.simplify(root)
    vat_g.flatten_eyes(root, EYE)
    objs = vat_g.prepare(root, int(budget * 0.7))
    grade = treat.make_grade("m2_sem_paleta", pull=0.0, lift=0.04, sat=SAT, gain=GAIN)
    os.makedirs(os.path.join(out, "n"), exist_ok=True)
    d = vat_g.export(root, os.path.join(out, "n", i + ".lbm"), None, objs, grade, a.get("anim"), a.get("deform"), None, False)
    C, P, N, M = treat.raster(d)
    img = treat.treat("dry", C, P, N, d["height"], COOL)
    td = os.path.join(out, "tex", "dry_n")
    os.makedirs(td, exist_ok=True)
    treat.save_png(img, os.path.join(td, i + ".png"))
    print("M2 %s: %d tris, altura %.2f m, %d peças miúdas apagadas" % (i, len(d["idx"]), d["height"], gone))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = os.path.abspath(argv[0])
    rest = [a for a in argv[1:] if not a.startswith("--")]
    ids = rest[0].split(",") if rest else list(S.UNITS)
    prev = "--preview" in argv
    for i in ids:
        t0 = time.time()
        try:
            export_one(i, out, prev)
            print("OK", i, "%.0fs" % (time.time() - t0))
        except Exception:
            print("FALHOU", i)
            traceback.print_exc()


main()
