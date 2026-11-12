"""Blender 5.2 headless: build a Grease Pencil (v3) object from a scene JSON and render the ink pass.
usage: blender -b --factory-startup -P gp_render.py -- scene.json out.png scale"""
import bpy, sys, json, math

argv = sys.argv[sys.argv.index("--") + 1:]
import os
src, out = os.path.abspath(argv[0]), os.path.abspath(argv[1])
SCALE = float(argv[2]) if len(argv) > 2 else 4.0      # px per unit
D = json.load(open(src))
W, H = D["W"], D["H"]

sc = bpy.context.scene
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sc.render.engine = "BLENDER_EEVEE"
sc.render.resolution_x = int(W * SCALE)
sc.render.resolution_y = int(H * SCALE)
sc.render.resolution_percentage = 100
sc.render.film_transparent = True
sc.view_settings.view_transform = "Standard"
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
try:
    sc.eevee.taa_render_samples = 16
except Exception:
    pass
try:
    sc.grease_pencil_settings.antialias_threshold = 0.5
except Exception:
    pass

cam_d = bpy.data.cameras.new("cam")
cam_d.type = "ORTHO"
cam_d.ortho_scale = W
cam_d.sensor_fit = "HORIZONTAL"
cam = bpy.data.objects.new("cam", cam_d)
sc.collection.objects.link(cam)
cam.location = (0, -50, 0)
cam.rotation_euler = (math.pi / 2, 0, 0)
cam_d.clip_end = 500
sc.camera = cam

gp = bpy.data.grease_pencils.new("ink")
ob = bpy.data.objects.new("ink", gp)
sc.collection.objects.link(ob)


def mat(name, stroke=None, fill=None, holdout=False):
    m = bpy.data.materials.new(name)
    bpy.data.materials.create_gpencil_data(m)
    g = m.grease_pencil
    g.show_stroke = stroke is not None
    g.show_fill = fill is not None
    if stroke is not None:
        g.color = stroke
    if fill is not None:
        g.fill_color = fill
    if holdout:
        g.use_fill_holdout = True
    gp.materials.append(m)
    return len(gp.materials) - 1


M_INK = mat("ink", stroke=(0, 0, 0, 1))
M_HOLD = mat("hold", fill=(1, 1, 1, 1), holdout=True)


def P(x, y, z=0.0):
    return (x - W / 2, z, H / 2 - y)


for li, L in enumerate(D["layers"]):
    lay = gp.layers.new(L["name"])
    d = lay.frames.new(1).drawing
    items = [("h", h) for h in L["holdout"]] + [("s", s) for s in L["strokes"]]
    if not items:
        continue
    d.add_strokes([len(v) if k == "h" else len(v["pts"]) for k, v in items])
    for si, (k, v) in enumerate(items):
        st = d.strokes[si]
        if k == "h":
            st.material_index = M_HOLD
            st.cyclic = True
            for pi, (x, y) in enumerate(v):
                p = st.points[pi]
                p.position = P(x, y)
                p.radius = 0.01
                p.opacity = 1.0
        else:
            st.material_index = M_INK
            for pi, (x, y) in enumerate(v["pts"]):
                p = st.points[pi]
                p.position = P(x, y)
                p.radius = float(v["r"][pi])
                p.opacity = float(v["a"][pi])

sc.render.filepath = out
bpy.ops.render.render(write_still=True)
print("WROTE", out)
