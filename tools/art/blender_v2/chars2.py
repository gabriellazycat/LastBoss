"""Goblin dinamiteiro, gosma, ogro e mago feitos no Blender (comparativo, rodada 2)."""
import math
import bpy, bmesh
from mathutils import Matrix, Vector
from mk import *
from chars import eye, legs, arm, BLACK, WHITE, GOLD, LEATHER, WOOD

GOB = (0.42, 0.66, 0.22)
GOB_D = (0.25, 0.42, 0.12)


def xform(objs, M):
    bpy.context.view_layer.update()
    for o in objs:
        o.matrix_world = M @ o.matrix_world
    return objs


def yellow_eye(loc, r, angry=0.0, sx=1):
    out = []
    w = sph(loc, r, (1, 0.55, 1)); setmat(w, mat("eyey", (1.0, 0.86, 0.3), 0.15, coat=1.0)); out.append(w)
    p = sph((loc[0], loc[1] - r * 0.45, loc[2]), r * 0.45, (0.8, 0.5, 1.2)); setmat(p, mat("pupil", BLACK, 0.1, coat=1.0)); out.append(p)
    hl = sph((loc[0] - r * 0.25, loc[1] - r * 0.62, loc[2] + r * 0.35), r * 0.16, (1, 0.5, 1)); setmat(hl, mat("hl", WHITE, 0.3, emit=0.6)); out.append(hl)
    lid = sph((loc[0], loc[1] - 0.005, loc[2] + r * 0.55), r * 1.08, (1.05, 0.62, 0.55), (0, sx * angry, 0)); shade(lid); out.append(lid)
    return out


# ------------------------------------------------------------------ goblin dinamiteiro

def goblin():
    P = []
    skin = mat("gob", vcol=True, rough=0.55, sss=0.15, bump=0.08, bump_scale=80)
    body = fuse([
        sph((0, 0, 0.42), 1, (0.2, 0.17, 0.22)),                       # barriga
        sph((0, 0.02, 0.86), 1, (0.31, 0.28, 0.27)),                   # cabeça grande
        sph((0, -0.24, 0.8), 1, (0.09, 0.12, 0.08), (20, 0, 0)),       # nariz comprido
        sph((0, -0.17, 0.72), 1, (0.2, 0.12, 0.1)),                    # queixo/boca
        capsule((0.12, 0, 0.3), (0.13, -0.02, 0.06), 0.065, 0.055), capsule((-0.12, 0, 0.3), (-0.13, -0.02, 0.06), 0.065, 0.055),
    ], "gob_body", voxel=0.009, smooth=0.6, iters=6)
    paint(body, lambda p, n: mix(GOB, GOB_D, smoothstep(0.7, 1.1, p.z) * 0.35 + smoothstep(0.0, 0.8, n.z) * 0.2)); setmat(body, skin); P.append(body)
    for sx in (-1, 1):   # orelhas pontudas
        ear = fuse([sph((sx * 0.38, 0.05, 0.92), 1, (0.2, 0.04, 0.08), (0, sx * -20, sx * 12)), sph((sx * 0.52, 0.07, 0.98), 1, (0.08, 0.025, 0.035), (0, sx * -30, sx * 12))], "ear", 0.007)
        paint(ear, lambda p, n: GOB); setmat(ear, skin); P.append(ear)
        P += yellow_eye((sx * 0.12, -0.24, 0.92), 0.075, 18, sx)
        for o in P[-1:]:
            paint(o, lambda p, n: GOB_D); setmat(o, skin)
    # sorriso com dentes
    grin = tube([(-0.14, -0.25, 0.73), (0, -0.29, 0.69), (0.14, -0.25, 0.73)], 0.025, 1.0, 12); setmat(grin, mat("mouth", (0.25, 0.05, 0.06), 0.5)); P.append(grin)
    for x in (-0.07, 0.06):
        t = box((x, -0.29, 0.705), (0.04, 0.02, 0.05), (0, 0, 0), bevel=0.008, taper=(0.4, 1.0)); hard(t); setmat(t, mat("tooth", (1, 0.96, 0.85), 0.3, coat=0.5)); P.append(t)
    # óculos de proteção na testa
    strap = torus((0, 0.02, 1.0), 0.3, 0.025, (8, 0, 0), s=(1, 0.95, 1)); shade(strap); setmat(strap, mat("leather", LEATHER, 0.55)); P.append(strap)
    for sx in (-1, 1):
        g = cyl((sx * 0.1, -0.25, 1.04), 0.07, 0.06, (75, 0, 0), bevel=0.01); hard(g); setmat(g, mat("brass", (0.85, 0.6, 0.25), 0.3, 1.0)); P.append(g)
        l = cyl((sx * 0.1, -0.285, 1.05), 0.052, 0.01, (75, 0, 0), bevel=0); shade(l); setmat(l, mat("lens", (0.3, 0.7, 0.9), 0.05, coat=1.0)); P.append(l)
    # colete e calção
    vest = fuse([sph((0, 0, 0.45), 1, (0.215, 0.185, 0.17))], "vest", 0.009)
    cut = box((0, -0.25, 0.45), (0.12, 0.2, 0.4), bevel=0);
    m = vest.modifiers.new("c", 'BOOLEAN'); m.object = cut; m.operation = 'DIFFERENCE'; m.solver = 'EXACT'; apply_mods(vest); bpy.data.objects.remove(cut)
    shade(vest); setmat(vest, mat("vest", (0.45, 0.24, 0.12), 0.65, bump=0.15, bump_scale=60)); P.append(vest)
    shorts = cyl((0, 0, 0.27), 0.19, 0.12, seg=40, bevel=0.03, r2=0.2); hard(shorts); setmat(shorts, mat("shorts", (0.35, 0.18, 0.4), 0.8)); P.append(shorts)
    for sx in (-1, 1):
        f = fuse([sph((sx * 0.13, -0.06, 0.04), 1, (0.08, 0.13, 0.05))], "foot", 0.008); paint(f, lambda p, n: GOB_D); setmat(f, skin); P.append(f)
    # bandoleira com bananas de dinamite
    band = tube([(0.2, -0.05, 0.62), (0.05, -0.2, 0.47), (-0.17, -0.12, 0.3)], 0.025, 1.0, 12); setmat(band, mat("leather", LEATHER, 0.55)); P.append(band)
    for i in range(3):
        d = cyl((0.12 - i * 0.09, -0.2 + i * 0.01, 0.55 - i * 0.08), 0.03, 0.12, (0, 0, 0), bevel=0.006); hard(d); setmat(d, mat("dyn", (0.85, 0.12, 0.1), 0.6)); P.append(d)
    # braços: um segura o maço aceso no alto
    for sx, hand in ((1, (0.38, -0.1, 0.9)), (-1, (-0.3, -0.12, 0.28))):
        el = (sx * 0.3, -0.02, 0.5) if sx < 0 else (sx * 0.34, 0.0, 0.6)
        a = fuse([capsule((sx * 0.18, 0, 0.55), el, 0.05, 0.045), capsule(el, hand, 0.045, 0.04), sph(hand, 0.06)], "gobarm", 0.008)
        paint(a, lambda p, n: GOB); setmat(a, skin); P.append(a)
    bundle = []
    for k in range(3):
        a = k * 2.1
        d = cyl((math.cos(a) * 0.04, math.sin(a) * 0.04, 0), 0.04, 0.26, bevel=0.008); hard(d); setmat(d, mat("dyn", (0.85, 0.12, 0.1), 0.6)); bundle.append(d)
    tie = torus((0, 0, 0), 0.085, 0.012); shade(tie); setmat(tie, mat("rope", (0.8, 0.7, 0.45), 0.8)); bundle.append(tie)
    fuse_ = tube([(0, 0, 0.13), (0.03, 0, 0.2), (0.0, 0.02, 0.26)], 0.006, 1.0, 8); setmat(fuse_, mat("fuse", (0.2, 0.15, 0.1), 0.8)); bundle.append(fuse_)
    spark = sph((0, 0.02, 0.28), 0.03); setmat(spark, mat("spark", (1.0, 0.6, 0.15), 0.5, emit=25.0)); bundle.append(spark)
    for k in range(5):
        a = k * 1.3
        s2 = sph((math.cos(a) * 0.05, 0.02 + math.sin(a) * 0.04, 0.3 + (k % 2) * 0.03), 0.008); setmat(s2, mat("spark", (1.0, 0.6, 0.15), 0.5, emit=25.0)); bundle.append(s2)
    xform(bundle, Matrix.Translation((0.4, -0.12, 0.95)) @ Matrix.Rotation(math.radians(20), 4, 'Y'))
    P += bundle
    return group("new_goblin", P)


# ------------------------------------------------------------------ gosma

def slime():
    P = []
    goo = (0.35, 0.85, 0.3)
    body = fuse([sph((0, 0, 0.32), 1, (0.48, 0.44, 0.36)), sph((0, 0.05, 0.12), 1, (0.56, 0.52, 0.14)),
                 sph((0, -0.05, 0.6), 1, (0.16, 0.16, 0.16))], "slime", 0.012, smooth=0.8, iters=10)
    m = bpy.data.materials.new("goo"); m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*goo, 1); p.inputs['Roughness'].default_value = 0.08
    p.inputs['Transmission Weight'].default_value = 0.55; p.inputs['IOR'].default_value = 1.33
    p.inputs['Subsurface Weight'].default_value = 0.5; p.inputs['Subsurface Radius'].default_value = (0.3, 0.6, 0.2); p.inputs['Subsurface Scale'].default_value = 0.3
    p.inputs['Coat Weight'].default_value = 1.0
    setmat(body, m); P.append(body)
    # coisas engolidas lá dentro
    bone = fuse(capsule((-0.18, 0.05, 0.22), (0.05, 0.12, 0.3), 0.025) + [sph((-0.19, 0.05, 0.22), 0.045), sph((0.06, 0.12, 0.31), 0.045)], "bone", 0.006)
    setmat(bone, mat("bone", (0.92, 0.88, 0.75), 0.6)); P.append(bone)
    coin = cyl((0.2, 0.12, 0.2), 0.05, 0.012, (70, 20, 0), bevel=0.003); hard(coin); setmat(coin, mat("gold", GOLD, 0.25, 1.0)); P.append(coin)
    for i, (x, y, z, r) in enumerate([(0.12, -0.1, 0.45, 0.03), (-0.25, -0.05, 0.4, 0.02), (0.28, 0.0, 0.3, 0.025)]):
        b = sph((x, y, z), r); setmat(b, mat("bub", (0.8, 1.0, 0.8), 0.05, emit=0.3)); P.append(b)
    # rosto: olhos grandes e boca aberta
    for sx in (-1, 1):
        P += eye((sx * 0.15, -0.4, 0.5), 0.075)
    mouth = sph((0, -0.42, 0.33), 1, (0.12, 0.05, 0.07)); shade(mouth); setmat(mouth, mat("mouthd", (0.08, 0.2, 0.05), 0.3)); P.append(mouth)
    tongue = sph((0.02, -0.44, 0.3), 1, (0.06, 0.03, 0.035)); shade(tongue); setmat(tongue, mat("tongue", (0.95, 0.4, 0.5), 0.4)); P.append(tongue)
    for sx in (-1, 1):
        drip = fuse([sph((sx * 0.35, -0.25, 0.08), 1, (0.08, 0.08, 0.1)), sph((sx * 0.37, -0.27, 0.02), 0.04)], "drip", 0.008); setmat(drip, m); P.append(drip)
    return group("new_slime", P)


# ------------------------------------------------------------------ ogro

def ogre():
    P = []
    OG = (0.4, 0.55, 0.26)
    OG_D = (0.24, 0.34, 0.15)
    skin = mat("ogre", vcol=True, rough=0.6, sss=0.12, bump=0.12, bump_scale=50)
    body = fuse([
        sph((0, 0, 1.0), 1, (0.55, 0.42, 0.5)),                       # barrigão
        sph((0, 0.06, 1.38), 1, (0.58, 0.4, 0.3)),                     # ombros/peito
        sph((0, -0.12, 1.66), 1, (0.24, 0.24, 0.22)),                  # cabeça pequena, para frente
        sph((0, -0.3, 1.56), 1, (0.2, 0.12, 0.12)),                    # mandíbula
        capsule((0.28, 0, 0.62), (0.3, -0.05, 0.12), 0.17, 0.15), capsule((-0.28, 0, 0.62), (-0.3, -0.05, 0.12), 0.17, 0.15),
        capsule((0.58, 0.02, 1.4), (0.75, -0.08, 0.95), 0.17, 0.16), capsule((0.75, -0.08, 0.95), (0.78, -0.18, 0.6), 0.16, 0.15),
        capsule((-0.58, 0.02, 1.4), (-0.72, -0.1, 0.95), 0.17, 0.16), capsule((-0.72, -0.1, 0.95), (-0.7, -0.25, 0.62), 0.16, 0.15),
        sph((0.78, -0.2, 0.52), 0.17), sph((-0.7, -0.28, 0.55), 0.17),  # punhos
    ], "ogre_body", voxel=0.014, smooth=0.6, iters=6)

    def col(p, n):
        c = mix(OG, OG_D, smoothstep(0.2, 0.9, n.z) * 0.25 + smoothstep(1.3, 1.8, p.z) * 0.2)
        c = mix(c, (0.72, 0.68, 0.52), ell_w(p, (0, -0.4, 0.95), (0.4, 0.2, 0.4)) * 0.6)  # barriga clara
        return c
    paint(body, col); setmat(body, skin); P.append(body)
    # cara: sobrancelha única, olhos pequenos, presas, nariz batata
    brow = fuse([sph((0, -0.31, 1.76), 1, (0.2, 0.07, 0.05), (0, 0, 0))], "brow", 0.008); paint(brow, lambda p, n: OG_D); setmat(brow, skin); P.append(brow)
    for sx in (-1, 1):
        P += yellow_eye((sx * 0.09, -0.32, 1.7), 0.04, 25, sx)
        paint(P[-1], lambda p, n: OG_D); setmat(P[-1], skin)
        tusk = box((sx * 0.1, -0.4, 1.55), (0.05, 0.04, 0.12), (0, sx * 10, 0), bevel=0.015, taper=(0.2, 0.3)); hard(tusk, 1); setmat(tusk, mat("tusk", (0.95, 0.9, 0.75), 0.4, coat=0.3)); P.append(tusk)
        ear = sph((sx * 0.25, -0.05, 1.68), 1, (0.08, 0.04, 0.1), (0, 0, sx * 20)); paint(ear, lambda p, n: OG); setmat(ear, skin); shade(ear); P.append(ear)
    nose = sph((0, -0.36, 1.64), 1, (0.07, 0.06, 0.06)); paint(nose, lambda p, n: (0.62, 0.58, 0.42)); setmat(nose, skin); shade(nose); P.append(nose)
    # tanga, cinto, pés
    loin = cyl((0, 0, 0.7), 0.5, 0.26, seg=48, bevel=0.03, r2=0.47); hard(loin); setmat(loin, mat("fur2", (0.42, 0.28, 0.16), 0.9, bump=0.4, bump_scale=90)); P.append(loin)
    belt = torus((0, 0, 0.82), 0.5, 0.04, s=(1, 0.86, 1)); shade(belt); setmat(belt, mat("leather", LEATHER, 0.55)); P.append(belt)
    skull = sph((0, -0.45, 0.82), 0.07, (1, 0.8, 1.1)); shade(skull); setmat(skull, mat("bone", (0.92, 0.88, 0.75), 0.6)); P.append(skull)
    for sx in (-1, 1):
        f = fuse([sph((sx * 0.3, -0.12, 0.08), 1, (0.17, 0.24, 0.09))], "foot", 0.01); paint(f, lambda p, n: OG_D); setmat(f, skin); P.append(f)
        bandage = torus((sx * 0.75, -0.12, 0.72), 0.16, 0.03, (0, 0, 0)); shade(bandage); setmat(bandage, mat("cloth", (0.85, 0.8, 0.68), 0.9)); P.append(bandage)
    # clava de madeira com cravos
    club = []
    c = fuse(capsule((0, 0, 0), (0, 0, 1.1), 0.06, 0.16), "club", 0.01); setmat(c, mat("wood", WOOD, 0.7, bump=0.4, bump_scale=20)); club.append(c)
    for k in range(7):
        a = k * 2.4; z = 0.7 + (k % 3) * 0.13
        s = box((math.cos(a) * 0.15, math.sin(a) * 0.15, z), (0.04, 0.04, 0.09), (math.degrees(math.sin(a)) * 1.5, -math.degrees(math.cos(a)) * 1.5, 0), bevel=0.004, taper=(0.1, 0.1))
        s.rotation_euler = Vector((0, 0, 1)).rotation_difference(Vector((math.cos(a), math.sin(a), 0))).to_euler()
        hard(s); setmat(s, mat("iron", (0.35, 0.35, 0.38), 0.45, 0.9)); club.append(s)
    xform(club, Matrix.Translation((0.78, -0.22, 0.5)) @ Matrix.Rotation(math.radians(-25), 4, 'X') @ Matrix.Rotation(math.radians(15), 4, 'Y'))
    P += club
    return group("new_ogre", P)


# ------------------------------------------------------------------ mago (herói, menos fofo)

def wizard():
    P = []
    robe = mat("robe", (0.17, 0.16, 0.45), 0.8, bump=0.08, bump_scale=200)
    robe_d = mat("robe_d", (0.1, 0.09, 0.28), 0.85, bump=0.08, bump_scale=200)
    gold = mat("gold", GOLD, 0.28, 1.0)
    leather = mat("leather", LEATHER, 0.55, bump=0.1, bump_scale=60)
    skin = (0.92, 0.68, 0.55)
    legs(P, mat("pants", (0.2, 0.17, 0.2), 0.8), leather)
    # túnica longa em sino
    gown = cyl((0, 0, 0.52), 0.36, 0.62, seg=56, bevel=0.04, r2=0.26); hard(gown); setmat(gown, robe); P.append(gown)
    hem = torus((0, 0, 0.23), 0.355, 0.03); shade(hem); setmat(hem, gold); P.append(hem)
    chest = fuse([sph((0, 0, 0.98), 1, (0.31, 0.24, 0.26)), sph((0, 0, 0.82), 1, (0.29, 0.23, 0.15))], "chest", 0.01); setmat(chest, robe); P.append(chest)
    # faixa central dourada
    sash = box((0, -0.255, 0.62), (0.12, 0.03, 0.62), (-4, 0, 0), bevel=0.01); hard(sash); setmat(sash, robe_d); P.append(sash)
    for z in (0.4, 0.62, 0.84):
        r = box((0, -0.275, z), (0.06, 0.02, 0.06), (0, 45, 0), bevel=0.006); hard(r); setmat(r, gold); P.append(r)
    belt = torus((0, 0, 0.74), 0.28, 0.035, s=(1, 0.88, 1)); shade(belt); setmat(belt, leather); P.append(belt)
    book = box((-0.27, -0.12, 0.66), (0.08, 0.18, 0.22), (0, 0, 20), bevel=0.015); hard(book); setmat(book, mat("book", (0.5, 0.08, 0.1), 0.6)); P.append(book)
    # manto com gola alta
    cape = fuse([sph((0, 0.22, 0.85), 1, (0.34, 0.06, 0.5), (6, 0, 0))] + [sph((x, 0.25, 0.48), 1, (0.08, 0.05, 0.22)) for x in (-0.24, -0.08, 0.08, 0.24)] +
                [sph((0, 0.1, 1.2), 1, (0.34, 0.2, 0.12))], "cape", 0.01)
    setmat(cape, robe_d); P.append(cape)
    for sx in (-1, 1):
        col = box((sx * 0.22, -0.02, 1.27), (0.2, 0.05, 0.18), (15, 0, sx * -35), bevel=0.02); hard(col); setmat(col, robe_d); P.append(col)
    # braços com mangas largas
    arm(P, 1, robe, mat("skinm", skin, 0.55, sss=0.25), (0.5, -0.12, 0.74))
    arm(P, -1, robe, mat("skinm", skin, 0.55, sss=0.25), (-0.5, -0.1, 0.78))
    for sx, hz in ((1, 0.83), (-1, 0.86)):
        cuff = cyl((sx * 0.49, -0.07, hz), 0.12, 0.1, (0, sx * 20, 0), bevel=0.02, r2=0.09); hard(cuff); setmat(cuff, robe_d); P.append(cuff)
        tr = torus((sx * 0.49, -0.07, hz - 0.05), 0.12, 0.015, (0, sx * 20, 0)); shade(tr); setmat(tr, gold); P.append(tr)
    # cajado com cristal
    st = []
    shaft = tube([(0, 0, -0.75), (0.02, 0, -0.2), (-0.01, 0, 0.4), (0.0, 0, 0.75)], 0.03, 1.0, 16); setmat(shaft, mat("wood", WOOD, 0.6, bump=0.3, bump_scale=25)); st.append(shaft)
    for k in range(3):
        a = k * 2.1
        prong = tube([(0, 0, 0.72), (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.85), (math.cos(a) * 0.05, math.sin(a) * 0.05, 1.0)], 0.018, 0.4, 10)
        setmat(prong, mat("wood", WOOD, 0.6, bump=0.3, bump_scale=25)); st.append(prong)
    crystal = box((0, 0, 0.9), (0.09, 0.09, 0.2), (0, 0, 45), bevel=0.005, taper=(0.25, 0.25)); hard(crystal)
    bm = bmesh.new(); bm.from_mesh(crystal.data)
    for v in bm.verts:
        if v.co.z < 0: v.co.x *= 0.3; v.co.y *= 0.3
    bm.to_mesh(crystal.data); bm.free()
    setmat(crystal, mat("crystal", (0.3, 0.8, 1.0), 0.05, emit=6.0)); st.append(crystal)
    xform(st, Matrix.Translation((0.52, -0.14, 0.74)) @ Matrix.Rotation(math.radians(-8), 4, 'X'))
    P += st
    # cabeça: rosto severo, sobrancelhas grossas, barba longa
    head = fuse([sph((0, 0, 1.5), 1, (0.32, 0.3, 0.31)), sph((0, -0.06, 1.39), 1, (0.25, 0.24, 0.18))], "head", 0.01)
    paint(head, lambda p, n: mix(skin, (0.85, 0.5, 0.45), ell_w(p, (0, -0.32, 1.42), (0.1, 0.1, 0.06)) * 0.5)); setmat(head, mat("skin", vcol=True, rough=0.55, sss=0.25)); P.append(head)
    for sx in (-1, 1):
        e = sph((sx * 0.11, -0.28, 1.5), 0.04, (1, 0.6, 0.75)); shade(e); setmat(e, mat("eye", BLACK, 0.08, coat=1.0)); P.append(e)
        h = sph((sx * 0.11 - 0.012, -0.305, 1.512), 0.011); setmat(h, mat("hl", WHITE, 0.3, emit=0.6)); P.append(h)
        brow = fuse([sph((sx * 0.12, -0.28, 1.565), 1, (0.1, 0.05, 0.035), (0, sx * 15, 0)), sph((sx * 0.2, -0.24, 1.58), 1, (0.05, 0.04, 0.025))], "brow", 0.006)
        setmat(brow, mat("beard", (0.92, 0.92, 0.95), 0.7, bump=0.3, bump_scale=80)); P.append(brow)
    nose = fuse([sph((0, -0.33, 1.44), 1, (0.05, 0.07, 0.06), (20, 0, 0))], "nose", 0.006); paint(nose, lambda p, n: (0.95, 0.6, 0.5)); setmat(nose, mat("skin", vcol=True, rough=0.55, sss=0.25)); P.append(nose)
    beard = fuse([sph((0, -0.25, 1.32), 1, (0.24, 0.12, 0.14)), sph((0, -0.27, 1.12), 1, (0.17, 0.1, 0.2)), sph((0, -0.27, 0.96), 1, (0.08, 0.07, 0.12)),
                  sph((0.15, -0.22, 1.4), 1, (0.08, 0.08, 0.08)), sph((-0.15, -0.22, 1.4), 1, (0.08, 0.08, 0.08))], "beard", 0.01)
    setmat(beard, mat("beard", (0.92, 0.92, 0.95), 0.7, bump=0.3, bump_scale=80)); P.append(beard)
    mous = fuse([sph((sx * 0.08, -0.33, 1.385), 1, (0.09, 0.04, 0.035), (0, sx * -20, 0)) for sx in (-1, 1)], "mous", 0.006)
    setmat(mous, mat("beard", (0.92, 0.92, 0.95), 0.7, bump=0.3, bump_scale=80)); P.append(mous)
    # chapéu pontudo torto, aba larga que sombreia os olhos
    brim = cyl((0, -0.02, 1.68), 0.55, 0.035, (-6, 0, 0), seg=64, bevel=0.015); hard(brim); setmat(brim, robe); P.append(brim)
    cone = cyl((0, 0, 0), 0.32, 1.0, seg=48, bevel=0.0, r2=0.015)
    apply_mods(cone)
    bm = bmesh.new(); bm.from_mesh(cone.data)
    bmesh.ops.subdivide_edges(bm, edges=[e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 0.5], cuts=12, use_grid_fill=True)
    for v in bm.verts:
        t = (v.co.z + 0.5)
        v.co.y += 0.35 * t ** 2.5; v.co.x += 0.08 * math.sin(t * 3.0)
    bm.to_mesh(cone.data); bm.free(); shade(cone)
    m = cone.modifiers.new("ss", 'SUBSURF'); m.levels = 1; m.render_levels = 2
    cone.location = (0, 0.02, 2.16); cone.rotation_euler = (math.radians(-6), 0, 0); setmat(cone, robe); P.append(cone)
    band = torus((0, -0.01, 1.74), 0.3, 0.035, (-6, 0, 0)); shade(band); setmat(band, gold); P.append(band)
    star = box((0, -0.31, 1.76), (0.08, 0.02, 0.08), (0, 45, 0), bevel=0.01); hard(star); setmat(star, mat("starg", (1.0, 0.85, 0.3), 0.3, 1.0, emit=0.5)); P.append(star)
    return group("new_wizard", P)
