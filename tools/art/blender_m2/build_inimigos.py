"""Exporta os inimigos novos (creatures_m2.py) no formato da V4 (g_n_a: atlas de pincel seco, paleta da carta) para
o jogo (assets/models/m2_a/<id>.res + assets/models/g_tex/m2/<id>.png). Rodada visual 20/11/2026.
(build_m2.py e build_structures_m2.py, na mesma pasta, são de outros agentes: cenário e estruturas.)
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_m2/build_inimigos.py -- <saída> [ids] [--preview=<pasta>] [--noexport]
Saída: <saída>/n/<id>.lbm e <saída>/tex/dry_n/<id>.png; depois
  godot --headless --path . -s res://tools/art/import_g.gd -- --src=<saída> --m2   e   godot --headless --path . --import
(use uma pasta de saída só dos inimigos: o --m2 importa tudo o que estiver nela).
Prévia (--preview): folha com 5 vistas (3/4, câmera do jogo ~50°, lado, antecipação e impacto do ataque).

Diferenças para tools/art/blender_g/build_g_all.py (que não é mexido):
  - o ataque tem 16 quadros (vat_g.ATK_FRAMES) e é gravado de trás para frente (ATK_REVERSED): o jogo
    (world_view.gd, lunge 1 -> 0 em 0,2 s logo depois do golpe) toca os quadros do último para o primeiro;
  - paletas à mão das cartas novas (o miolo da carta traz o fundo e apaga a cor), injetadas em treat.PALS;
  - simplify mantém as peças chamadas "keep" (nariz, dentes, garras, moeda) e corta abaixo de 3% do modelo."""
import os, sys, math, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
G = os.path.abspath(os.path.join(HERE, "..", "blender_g"))
V2 = os.path.abspath(os.path.join(HERE, "..", "blender_v2"))
for p in (V2, G, HERE):
    if p not in sys.path:
        sys.path.insert(0, p)
import bpy
import numpy as np
from mathutils import Vector, Matrix
import mk, vat, vat_g, treat
import creatures_m2 as C

ATK_REVERSED = True
vat_g.ATK_FRAMES = 16
GAIN = float(os.environ.get("LBG_GAIN", "0.5"))
PULL = float(os.environ.get("LBG_PULL", "0.2"))
SAT = float(os.environ.get("LBG_SAT", "1.45"))
COOL = (0.30, 0.32, 0.42)

# 5 faixas de valor [luminância, cor] tiradas à mão da arte de cada carta (só o bicho, sem o fundo)
PALS = {
    "rat_brute": [[0.2, [0.2, 0.23, 0.32]], [0.33, [0.3, 0.35, 0.44]], [0.47, [0.42, 0.5, 0.57]], [0.6, [0.56, 0.64, 0.69]], [0.75, [0.72, 0.78, 0.82]]],
    "brood_mother": [[0.3, [0.36, 0.38, 0.47]], [0.45, [0.5, 0.52, 0.6]], [0.62, [0.7, 0.62, 0.56]], [0.75, [0.82, 0.74, 0.65]], [0.88, [0.94, 0.9, 0.84]]],
    "fire_imp": [[0.12, [0.3, 0.06, 0.05]], [0.25, [0.6, 0.12, 0.08]], [0.38, [0.85, 0.25, 0.14]], [0.55, [0.98, 0.5, 0.18]], [0.75, [1.0, 0.82, 0.45]]],
    "ghoul": [[0.15, [0.14, 0.14, 0.18]], [0.35, [0.36, 0.4, 0.48]], [0.5, [0.5, 0.55, 0.62]], [0.65, [0.65, 0.7, 0.75]], [0.8, [0.8, 0.83, 0.86]]],
    "kobold_scavengers": [[0.2, [0.4, 0.12, 0.12]], [0.32, [0.42, 0.33, 0.25]], [0.42, [0.82, 0.3, 0.26]], [0.6, [0.95, 0.55, 0.45]], [0.85, [0.95, 0.9, 0.8]]],
    "raised_servant": [[0.12, [0.16, 0.11, 0.1]], [0.4, [0.5, 0.41, 0.31]], [0.6, [0.72, 0.62, 0.46]], [0.75, [0.88, 0.79, 0.6]], [0.88, [0.95, 0.9, 0.78]]],
    "corrupt_piper": [[0.15, [0.16, 0.13, 0.12]], [0.3, [0.24, 0.32, 0.26]], [0.42, [0.36, 0.48, 0.38]], [0.55, [0.55, 0.5, 0.42]], [0.75, [0.86, 0.76, 0.66]]],
    "bat_cloud": [[0.1, [0.1, 0.08, 0.12]], [0.22, [0.24, 0.17, 0.24]], [0.35, [0.42, 0.31, 0.38]], [0.55, [0.62, 0.5, 0.55]], [0.72, [0.93, 0.64, 0.64]]],
}
treat.PALS.update(PALS)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mk._MATS.clear()


# ------------------------------------------------------------------ prévia

def _scene_setup():
    sc = bpy.context.scene
    try:
        sc.render.engine = 'BLENDER_EEVEE_NEXT'
    except TypeError:
        sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x, sc.render.resolution_y = 420, 420
    sc.view_settings.view_transform = 'Standard'
    w = bpy.data.worlds.new("W"); sc.world = w
    try:
        w.use_nodes = True
        bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND'); bg.inputs[0].default_value = (0.42, 0.45, 0.4, 1); bg.inputs[1].default_value = 0.6
    except Exception:
        pass
    sun = bpy.data.lights.new("Sun", 'SUN'); sun.energy = 3.0; so = bpy.data.objects.new("Sun", sun); sc.collection.objects.link(so)
    so.rotation_euler = (math.radians(40), 0, math.radians(-30))
    cd = bpy.data.cameras.new("C"); cd.lens = 50; cam = bpy.data.objects.new("C", cd); sc.collection.objects.link(cam); sc.camera = cam
    return sc, cam


def _bbox(objs):
    bpy.context.view_layer.update()
    lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c); lo = Vector(map(min, lo, p)); hi = Vector(map(max, hi, p))
    return lo, hi


def _pose_objs(objs, base, pose):
    for o in objs:
        M = pose.get(o.get("bone", "body"), Matrix.Identity(4)) if pose else Matrix.Identity(4)
        o.matrix_world = M @ base[o.name]
    bpy.context.view_layer.update()


def preview(root, i, path):
    sc, cam = _scene_setup()
    bpy.context.view_layer.update()   # o último objeto criado ainda tem matrix_world identidade
    objs = [o for o in vat.descendants(root) if o.type in ('MESH', 'CURVE')]
    base = {o.name: o.matrix_world.copy() for o in objs}
    a = C.ANIM[i]()["anim"]
    lo, hi = _bbox(objs)
    ctr = (lo + hi) / 2; r = max((hi - lo).length, 0.1)
    views = [("rest", None, (0.55, -1.0, 0.35)), ("jogo", None, (0.2, -1.0, 1.25)), ("lado", None, (1.0, -0.05, 0.2)),
             ("antecip", 0.2, (0.85, -0.7, 0.35)), ("impacto", 0.5, (0.85, -0.7, 0.35))]
    tiles = []
    for name, at, d in views:
        _pose_objs(objs, base, a("atk", at) if at is not None else a("walk", 0.0))
        cam.location = ctr + Vector(d).normalized() * r * 1.3
        cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
        fp = path + "_" + name + ".png"
        sc.render.filepath = fp
        bpy.ops.render.render(write_still=True)
        tiles.append(fp)
    _pose_objs(objs, base, None)
    ims = []
    for fp in tiles:
        im = bpy.data.images.load(fp)
        w, h = im.size
        ims.append(np.array(im.pixels[:]).reshape(h, w, 4))
        bpy.data.images.remove(im)
        os.remove(fp)
    sheet = np.concatenate(ims, axis=1)
    h, w = sheet.shape[:2]
    out = bpy.data.images.new("sheet", w, h, alpha=True)
    out.pixels[:] = sheet.reshape(-1)
    out.filepath_raw = path + ".png"; out.file_format = 'PNG'; out.save()


# ------------------------------------------------------------------ exportação (como build_g_all.export_g)

def export(root, i, out):
    h, budget = C.UNITS_M2[i]
    cfg = C.ANIM[i]()
    anim, deform = cfg.get("anim"), cfg.get("deform")
    if ATK_REVERSED:
        a0, d0 = anim, deform
        anim = lambda kind, t: a0(kind, 1.0 - t) if kind == "atk" else a0(kind, t)
        if d0:
            deform = lambda p, n, b, t: d0(p, n, b, 3.0 - t) if t > 1.0 else d0(p, n, b, t)
    vat_g.simplify(root, small=0.03, keep=("keep",))
    mk._MATS.clear()
    vat_g.flatten_eyes(root)
    objs = vat_g.prepare(root, int(budget * 0.7))
    grade = treat.make_grade(i, pull=PULL, lift=0.04, sat=SAT, gain=GAIN)
    os.makedirs(os.path.join(out, "n"), exist_ok=True)
    d = vat_g.export(root, os.path.join(out, "n", i + ".lbm"), h, objs, grade, anim, deform, None, True)
    Cc, P, N, M = treat.raster(d)
    img = treat.treat("dry", Cc, P, N, d["height"], COOL)
    td = os.path.join(out, "tex", "dry_n")
    os.makedirs(td, exist_ok=True)
    treat.save_png(img, os.path.join(td, i + ".png"))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = os.path.abspath(argv[0])
    os.makedirs(out, exist_ok=True)
    ids = argv[1].split(",") if len(argv) > 1 and not argv[1].startswith("--") else list(C.UNITS_M2)
    prev = next((x.split("=", 1)[1] for x in argv if x.startswith("--preview=")), None)
    noexp = "--noexport" in argv
    for i in ids:
        try:
            reset()
            root = C.BUILD[i]()
            if prev:
                os.makedirs(prev, exist_ok=True)
                preview(root, i, os.path.join(os.path.abspath(prev), i))
                if not noexp:
                    reset()
                    root = C.BUILD[i]()
            if not noexp:
                export(root, i, out)
            print("OK", i)
        except Exception:
            print("FALHOU", i)
            traceback.print_exc()


main()
