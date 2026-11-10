"""Kit de modelagem estilizada para o comparativo: formas fundidas por voxel + peças duras chanfradas.
Blender: Z para cima, frente = -Y."""
import bpy, bmesh, math
from mathutils import Vector, Euler, Matrix

COLL = None


def _link(o):
    bpy.context.scene.collection.objects.link(o)
    return o


def _sel(o):
    for x in bpy.context.selected_objects:
        x.select_set(False)
    o.select_set(True)
    bpy.context.view_layer.objects.active = o


def apply_mods(o):
    _sel(o)
    for m in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


def sph(loc, r=1.0, s=(1, 1, 1), rot=(0, 0, 0), seg=40):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=seg // 2, radius=1.0)
    me = bpy.data.meshes.new("s"); bm.to_mesh(me); bm.free()
    o = _link(bpy.data.objects.new("s", me))
    o.location = loc; o.scale = (r * s[0], r * s[1], r * s[2])
    o.rotation_euler = Euler([math.radians(a) for a in rot])
    return o


def capsule(a, b, r1, r2=None, seg=32):
    """Cone arredondado de a até b (raios r1, r2), com esferas nas pontas."""
    r2 = r1 if r2 is None else r2
    a, b = Vector(a), Vector(b)
    d = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r1, radius2=r2, depth=d.length)
    me = bpy.data.meshes.new("c"); bm.to_mesh(me); bm.free()
    o = _link(bpy.data.objects.new("c", me))
    o.location = (a + b) / 2
    o.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    return [o, sph(a, r1, seg=seg), sph(b, r2, seg=seg)]


def box(loc, size, rot=(0, 0, 0), bevel=0.02, seg=3, taper=None):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    if taper:  # (tx, ty) escala do topo (z>0)
        for v in bm.verts:
            if v.co.z > 0:
                v.co.x *= taper[0]; v.co.y *= taper[1]
    me = bpy.data.meshes.new("b"); bm.to_mesh(me); bm.free()
    o = _link(bpy.data.objects.new("b", me))
    o.location = loc; o.scale = size; o.rotation_euler = Euler([math.radians(a) for a in rot])
    _sel(o); bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        m = o.modifiers.new("bv", 'BEVEL'); m.width = bevel; m.segments = seg; m.limit_method = 'ANGLE'
        m.harden_normals = False
    return o


def cyl(loc, r, depth, rot=(0, 0, 0), seg=40, bevel=0.01, r2=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=depth)
    me = bpy.data.meshes.new("y"); bm.to_mesh(me); bm.free()
    o = _link(bpy.data.objects.new("y", me))
    o.location = loc; o.rotation_euler = Euler([math.radians(a) for a in rot])
    if bevel:
        m = o.modifiers.new("bv", 'BEVEL'); m.width = bevel; m.segments = 3; m.limit_method = 'ANGLE'
    return o


def torus(loc, R, r, rot=(0, 0, 0), s=(1, 1, 1)):
    bm = bmesh.new()
    me = bpy.data.meshes.new("t")
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=48, minor_segments=14, location=loc,
                                     rotation=[math.radians(a) for a in rot])
    o = bpy.context.active_object
    o.scale = s
    bm.free()
    return o


def tube(pts, r, taper=1.0, res=24):
    """Tubo suave por pontos (curva NURBS com chanfro), raio afinando até r*taper."""
    cu = bpy.data.curves.new("tube", 'CURVE'); cu.dimensions = '3D'
    cu.bevel_depth = r; cu.bevel_resolution = 6; cu.resolution_u = res; cu.use_fill_caps = True
    sp = cu.splines.new('NURBS'); sp.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        sp.points[i].co = (p[0], p[1], p[2], 1)
        sp.points[i].radius = 1.0 + (taper - 1.0) * i / (len(pts) - 1)
    sp.use_endpoint_u = True; sp.order_u = min(4, len(pts))
    o = _link(bpy.data.objects.new("tube", cu))
    _sel(o); bpy.ops.object.convert(target='MESH')
    o = bpy.context.active_object
    return o


def join(objs, name):
    objs = [o for o in objs if o]
    for o in objs:
        if o.type != 'MESH':
            _sel(o); bpy.ops.object.convert(target='MESH')
    _sel(objs[0])
    for o in objs[1:]:
        o.select_set(True)
    bpy.ops.object.join()
    o = bpy.context.active_object; o.name = name
    return o


def fuse(objs, name, voxel=0.012, smooth=0.6, iters=6):
    """União orgânica: remesh por voxel e suavização (filete nas junções)."""
    flat = []
    for o in objs:
        flat += o if isinstance(o, list) else [o]
    o = join(flat, name)
    _sel(o); bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    m = o.modifiers.new("rm", 'REMESH'); m.mode = 'VOXEL'; m.voxel_size = voxel; m.adaptivity = 0.0
    s = o.modifiers.new("sm", 'SMOOTH'); s.factor = smooth; s.iterations = iters
    apply_mods(o)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def shade(o, smooth=True):
    if o.type == 'MESH':
        for p in o.data.polygons:
            p.use_smooth = smooth
    return o


def hard(o, sub=0):
    """Peça dura: aplica o chanfro, normais ponderadas."""
    apply_mods(o)
    shade(o, True)
    if sub:
        m = o.modifiers.new("ss", 'SUBSURF'); m.levels = sub; m.render_levels = sub
    w = o.modifiers.new("wn", 'WEIGHTED_NORMAL'); w.keep_sharp = True
    return o


def paint(o, fn, name="Col"):
    """Cor por vértice: fn(posição no mundo, normal) -> (r, g, b)."""
    me = o.data
    ca = me.color_attributes.get(name) or me.color_attributes.new(name, 'FLOAT_COLOR', 'POINT')
    mw = o.matrix_world; nm = mw.to_3x3().inverted().transposed()
    for v in me.vertices:
        c = fn(mw @ v.co, (nm @ v.normal).normalized())
        ca.data[v.index].color = (c[0], c[1], c[2], 1.0)
    return o


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def smoothstep(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def ell_w(p, c, s):
    """Peso 1 no centro do elipsoide c/s, 0 na borda (suave)."""
    d = math.sqrt(sum(((p[i] - c[i]) / s[i]) ** 2 for i in range(3)))
    return 1.0 - smoothstep(0.6, 1.0, d)


_MATS = {}


def mat(name, color=(0.8, 0.8, 0.8), rough=0.6, metal=0.0, vcol=False, sss=0.0, bump=0.0, bump_scale=60.0, coat=0.0, emit=0.0):
    key = (name, color, rough, metal, vcol, sss, bump, coat, emit)
    if key in _MATS:
        return _MATS[key]
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; p = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metal
    if vcol:
        a = nt.nodes.new('ShaderNodeVertexColor'); a.layer_name = "Col"
        nt.links.new(a.outputs[0], p.inputs['Base Color'])
        if sss:
            nt.links.new(a.outputs[0], p.inputs['Subsurface Radius']) if False else None
    else:
        p.inputs['Base Color'].default_value = (*color, 1)
    if sss:
        p.inputs['Subsurface Weight'].default_value = sss
        p.inputs['Subsurface Radius'].default_value = (0.08, 0.03, 0.02)
        p.inputs['Subsurface Scale'].default_value = 0.1
    if coat:
        p.inputs['Coat Weight'].default_value = coat
    if emit:
        p.inputs['Emission Color'].default_value = (*color, 1)
        p.inputs['Emission Strength'].default_value = emit
    if bump:
        tx = nt.nodes.new('ShaderNodeTexNoise'); tx.inputs['Scale'].default_value = bump_scale
        tx.inputs['Detail'].default_value = 6
        bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = bump; bp.inputs['Distance'].default_value = 0.02
        nt.links.new(tx.outputs[0], bp.inputs['Height']); nt.links.new(bp.outputs[0], p.inputs['Normal'])
    _MATS[key] = m
    return m


def setmat(o, m):
    o.data.materials.clear(); o.data.materials.append(m)
    return o


def group(name, objs, loc=(0, 0, 0)):
    root = _link(bpy.data.objects.new(name, None))
    for o in objs:
        o.parent = root
    root.location = loc
    return root
