"""Cena comum do comparativo: luz de dia, chão, câmera; importa os modelos atuais."""
import bpy, math, sys
from mathutils import Vector

import os
# Pasta das fotos e dos .glb do comparativo (fora do git: tools/art/out/ está no .gitignore). LB_CMP troca.
S = os.environ.get("LB_CMP", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "out", "cmp").replace("\\", "/"))
os.makedirs(S, exist_ok=True)

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 96
    sc.cycles.use_denoising = True
    try: sc.cycles.device = 'GPU'
    except Exception: pass
    sc.view_settings.view_transform = 'AgX'
    sc.view_settings.look = 'AgX - Punchy'
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.view_settings.exposure = 0.0
    w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
    nt = w.node_tree; bg = next(n for n in nt.nodes if n.type == 'BACKGROUND')
    bg.inputs[0].default_value = (0.55, 0.7, 1.0, 1); bg.inputs[1].default_value = 0.55
    sun = bpy.data.lights.new("Sun", 'SUN'); sun.energy = 3.5; sun.angle = math.radians(6); sun.color = (1.0, 0.95, 0.86)
    so = bpy.data.objects.new("Sun", sun); sc.collection.objects.link(so)
    so.rotation_euler = (math.radians(50), 0, math.radians(-35))
    rim = bpy.data.lights.new("Rim", 'AREA'); rim.energy = 150; rim.size = 6; rim.color = (0.75, 0.85, 1.0)
    ro = bpy.data.objects.new("Rim", rim); sc.collection.objects.link(ro); ro.location = (0, 8, 5)
    ro.rotation_euler = (math.radians(-55), 0, 0)
    bpy.ops.mesh.primitive_plane_add(size=60)
    g = bpy.context.active_object; g.name = "Ground"
    gm = bpy.data.materials.new("ground"); gm.use_nodes = True
    p = next(n for n in gm.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (0.16, 0.27, 0.14, 1); p.inputs['Roughness'].default_value = 0.95
    g.data.materials.append(gm)

def vcol_mat(name):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; p = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    a = nt.nodes.new('ShaderNodeVertexColor'); a.layer_name = "Color"
    nt.links.new(a.outputs[0], p.inputs['Base Color']); p.inputs['Roughness'].default_value = 0.75
    return m

def import_glb(path, name):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    roots = [o for o in new if o.parent is None]
    root = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(root)
    for o in roots: o.parent = root
    return root, new

def bounds(objs):
    bpy.context.view_layer.update()
    lo = Vector((1e9,)*3); hi = Vector((-1e9,)*3)
    for o in objs:
        if o.type != 'MESH' or o.hide_render: continue
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
    return lo, hi

def place(root, objs, x, height=None, yaw=0.0):
    root.rotation_euler = (0, 0, math.radians(yaw))
    if height:
        lo, hi = bounds(objs); s = height / max(1e-6, hi.z - lo.z); root.scale = (s, s, s)
    lo, hi = bounds(objs)
    root.location.x += x - (lo.x + hi.x) / 2; root.location.y -= (lo.y + hi.y) / 2; root.location.z -= lo.z

def current(which):
    if which == "knight":
        r, objs = import_glb(f"{S}/knight.glb", "cur_knight")
        for o in objs:
            if o.name.split('.')[0] in ("1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "2H_Sword", "Icosphere"):
                o.hide_render = True; o.hide_viewport = True
        return r, objs
    r, objs = import_glb(f"{S}/{which}.glb", "cur_" + which)
    for o in objs:
        if o.type == 'MESH':
            old = o.data.materials[0] if o.data.materials else None
            img = None
            if old and old.use_nodes:
                for n in old.node_tree.nodes:
                    if n.type == 'TEX_IMAGE' and n.image: img = n.image
            m = vcol_mat("vc_" + which)
            if img:
                nt = m.node_tree; p = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
                t = nt.nodes.new('ShaderNodeTexImage'); t.image = img
                a = next(n for n in nt.nodes if n.type == 'VERTEX_COLOR')
                mu = nt.nodes.new('ShaderNodeMix'); mu.data_type = 'RGBA'; mu.blend_type = 'MULTIPLY'; mu.inputs[0].default_value = 1.0
                nt.links.new(a.outputs[0], mu.inputs[6]); nt.links.new(t.outputs[0], mu.inputs[7]); nt.links.new(mu.outputs[2], p.inputs['Base Color'])
            o.data.materials.clear(); o.data.materials.append(m)
            for p in o.data.polygons: p.use_smooth = True
    return r, objs

def camera(loc, look, lens=50):
    cd = bpy.data.cameras.new("Cam"); cd.lens = lens
    c = bpy.data.objects.new("Cam", cd); bpy.context.scene.collection.objects.link(c)
    c.location = loc
    d = Vector(look) - Vector(loc); c.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    bpy.context.scene.camera = c
    return c

def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
