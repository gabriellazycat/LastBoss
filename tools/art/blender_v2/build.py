"""Gera os modelos da direção nova (monstros, estruturas e cenário do Blender) como .lbm.
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_v2/build.py -- <pasta de saída> [ids,separados]
Depois: godot --headless --path . -s res://tools/art/import_v2.gd -- --src=<pasta de saída>
Com --preview=<pasta> também renderiza cada modelo (EEVEE, luz de dia) para conferir de perto."""
import os, sys, math, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy
from mathutils import Vector
import mk, vat, monsters, monsters2, boss, scenery, locations, anims

# id -> (módulo, altura em metros no jogo, orçamento de triângulos)
UNITS = {
    "rat": (0.5, 1400), "rat_king": (0.95, 2600), "bat": (0.75, 1400), "skeleton": (1.25, 2200),
    "skeleton_archers": (1.3, 2200), "goblin_dynamiter": (1.0, 2400), "slime": (0.8, 1400), "cultists": (1.45, 2400),
    "ghost": (1.3, 1600), "spectre": (1.1, 1600), "werewolf": (1.8, 3000), "ogre": (2.3, 3000), "scrap_golem": (2.3, 3400),
    "mimic": (1.0, 2200), "bone_totem": (1.9, 2600), "bat_nest": (3.0, 3400), "gargoyle_tower": (2.6, 3400),
}
PROPS = {
    "tree": (5.5, 700), "tree_round": (4.6, 500), "dead_tree": (4.0, 400), "bush": (1.4, 300), "rock": (1.1, 240),
    "road_stone": (0.25, 60), "grass": (0.6, 120), "flowers": (0.3, 300), "mushroom": (0.4, 240),
    "fence": (1.15, 500), "lantern": (None, 700), "gravestone": (1.35, 500), "house": (3.9, 4000), "tavern": (4.3, 5000),
    # locais, covil e arena: escala real do Blender (None)
    "coins": (None, 500), "fountain": (None, 3000), "shrine": (None, 2500), "ritual": (None, 3000), "bridge": (None, 3000),
    "water": (None, 2500), "castle": (None, 6000), "pillar": (None, 1200), "brazier": (None, 900), "altar": (None, 1200),
    "arena": (None, 4000), "throne": (None, 2000),
    # chefe: 4 partes destrutíveis, origem e escala das antigas (sem recentralizar)
    "boss_core": (None, 6000), "boss_head": (None, 3000), "boss_left_arm": (None, 2500), "boss_right_arm": (None, 2500),
}

# peças cuja origem importa para o jogo (luz da lanterna, partes do chefe)
NO_RECENTER = {"lantern"}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mk._MATS.clear()


def build(i):
    for m in (monsters, monsters2, boss, scenery, locations):
        if hasattr(m, i):
            return getattr(m, i)()
    raise KeyError(i)


def preview(root, path):
    sc = bpy.context.scene
    try:
        sc.render.engine = 'BLENDER_EEVEE_NEXT'
    except TypeError:
        sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x, sc.render.resolution_y = 800, 800
    sc.view_settings.view_transform = 'AgX'
    w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND'); bg.inputs[0].default_value = (0.55, 0.7, 1.0, 1); bg.inputs[1].default_value = 0.8
    sun = bpy.data.lights.new("Sun", 'SUN'); sun.energy = 4.0; so = bpy.data.objects.new("Sun", sun); sc.collection.objects.link(so)
    so.rotation_euler = (math.radians(45), 0, math.radians(-35))
    objs = [o for o in vat.descendants(root) if o.type == 'MESH']
    bpy.context.view_layer.update()
    lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c); lo = Vector(map(min, lo, p)); hi = Vector(map(max, hi, p))
    ctr = (lo + hi) / 2; r = max((hi - lo).length, 0.1)
    cd = bpy.data.cameras.new("C"); cd.lens = 50; c = bpy.data.objects.new("C", cd); sc.collection.objects.link(c)
    c.location = ctr + Vector((0.55, -1.0, 0.6)).normalized() * r * 1.6
    c.rotation_euler = (ctr - c.location).to_track_quat('-Z', 'Y').to_euler(); sc.camera = c
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = argv[0]
    os.makedirs(out, exist_ok=True)
    ids = argv[1].split(",") if len(argv) > 1 and not argv[1].startswith("--") else list(UNITS) + list(PROPS)
    prev = next((a.split("=", 1)[1] for a in argv if a.startswith("--preview=")), None)
    for i in ids:
        try:
            reset()
            root = build(i)
            if prev:
                os.makedirs(prev, exist_ok=True)
                preview(root, os.path.join(prev, i + ".png"))
            if i in UNITS:
                h, b = UNITS[i]
                a = anims.get(i)
                if a.get("pretag"):
                    a["pretag"](root)
                vat.export(root, os.path.join(out, i + ".lbm"), h, b, a.get("anim"), a.get("deform"), a.get("rig"))
            else:
                h, b = PROPS[i]
                vat.export(root, os.path.join(out, i + ".lbm"), h, b, recenter=not (i.startswith("boss_") or i in NO_RECENTER))
        except Exception:
            print("FALHOU", i)
            traceback.print_exc()


main()
