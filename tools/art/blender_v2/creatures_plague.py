"""Feras da Rainha da Praga: lobo (Matilha de Lobos), javali (Javali de Guerra) e besta alfa (Besta Alfa).
Mesmo kit e mesma linguagem do resto (olhos grandes, formas macias fundidas, hachura legível); o modelo da carta
é o do jogo. Quadrúpedes com a cabeça, as quatro patas e o rabo em partes rígidas marcadas por osso (vat.tag),
que anims._quad já sabe animar.
Exportar: blender -b --factory-startup -P tools/art/blender_v2/creatures_plague.py -- <pasta> [ids]
Blender: Z para cima, frente = -Y."""
import os, sys, math, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy
from mathutils import Matrix, Vector
from mk import *
from vat import tag
from chars import BLACK, WHITE
from monsters import xform, BONE, BONE_D
from monsters2 import yellow_eye

PIV_FL = (0.17, -0.42, 0.56)    # ombro da pata dianteira do lado +x
PIV_BL = (0.18, 0.40, 0.56)     # quadril da pata traseira
NECK = (0, -0.65, 0.82)
TAILP = (0, 0.62, 0.7)
TOOTH = (1, 0.97, 0.86)


def _rotx(objs, piv, deg):
    xform(objs, Matrix.Translation(piv) @ Matrix.Rotation(math.radians(deg), 4, 'X') @ Matrix.Translation(-Vector(piv)))


def _leg(sx, front, top, knee, paw, r, col, pawc, claw=True, name="leg"):
    """Uma pata: coxa, canela e pata fundidas numa peça só, com garras."""
    a = (sx * top[0], top[1], top[2]); b = (sx * knee[0], knee[1], knee[2]); c = (sx * paw[0], paw[1], paw[2])
    parts = capsule(a, b, r, r * 0.75) + capsule(b, c, r * 0.75, r * 0.6) + [sph((c[0], c[1] - 0.05, c[2] + 0.02), 1, (r * 0.85, r * 1.5, r * 0.6))]
    g = fuse(parts, name, 0.012, 0.6, 5)
    paint(g, lambda p, n: mix(col, pawc, smoothstep(0.3, 0.05, p.z)))
    setmat(g, mat("beastfur_%s" % str(col), vcol=True, rough=0.85, bump=0.3, bump_scale=110))
    out = [g]
    if claw:
        for k in (-1, 0, 1):
            cl = box((c[0] + k * r * 0.5, c[1] - r * 2.1, c[2] - 0.0), (r * 0.28, r * 0.6, r * 0.28), (-60, 0, 0), bevel=0.004, taper=(0.1, 0.1))
            hard(cl); setmat(cl, mat("claw", (0.95, 0.92, 0.85), 0.4)); out.append(cl)
    return out


def _head(P, c, fur, furd, belly, snout_len=0.2, jaw_open=0.0, eye_col=(1.0, 0.75, 0.2), angry=28, big=1.0):
    """Cabeça de lobo (parte 'head'); c = centro do crânio. Devolve a lista de objetos."""
    x, y, z = c
    k = big
    sk = [sph((x, y, z), 1, (0.17 * k, 0.19 * k, 0.16 * k)),
          sph((x, y - 0.2 * k, z - 0.06 * k), 1, (0.095 * k, snout_len * k, 0.085 * k), (12, 0, 0)),
          sph((x, y - 0.06 * k, z - 0.1 * k), 1, (0.14 * k, 0.14 * k, 0.1 * k))]
    h = fuse(sk, "head", 0.01, 0.6, 5)
    paint(h, lambda p, n: mix(mix(fur, furd, smoothstep(0.1, 0.9, n.z) * 0.5), belly, ell_w(p, (x, y - 0.3 * k, z - 0.13 * k), (0.12 * k, 0.16 * k, 0.08 * k)) * 0.9))
    setmat(h, mat("beastfur_%s" % str(fur), vcol=True, rough=0.85, bump=0.3, bump_scale=110))
    out = [h]
    # mandíbula separada (abre no devorar)
    jaw = fuse([sph((x, y - 0.2 * k, z - 0.14 * k), 1, (0.075 * k, (snout_len * 0.85) * k, 0.04 * k))], "jaw", 0.008)
    paint(jaw, lambda p, n: belly); setmat(jaw, mat("beastfur_%s" % str(fur), vcol=True, rough=0.85))
    nose = sph((x, y - 0.2 * k - snout_len * k * 0.95, z - 0.05 * k), 1, (0.04 * k, 0.03 * k, 0.03 * k)); shade(nose); setmat(nose, mat("pupil", BLACK, 0.2))
    out.append(nose)
    for sx in (-1, 1):
        ear = box((x + sx * 0.12 * k, y + 0.04 * k, z + 0.2 * k), (0.11 * k, 0.05 * k, 0.22 * k), (-8, sx * 12, 0), bevel=0.02, taper=(0.1, 0.5))
        hard(ear); setmat(ear, mat("furd_%s" % str(furd), furd, 0.85)); out.append(ear)
        out += yellow_eye((x + sx * 0.095 * k, y - 0.15 * k, z + 0.05 * k), 0.058 * k, angry, sx, eye_col, (0.22, 0.18, 0.22))
        f = box((x + sx * 0.05 * k, y - 0.2 * k - snout_len * k * 0.6, z - 0.13 * k), (0.022 * k, 0.02 * k, 0.07 * k), (0, 0, 0), bevel=0.005, taper=(0.15, 0.4))
        f.rotation_euler[0] = math.radians(180); hard(f); setmat(f, mat("tooth", TOOTH, 0.3)); out.append(f)
    if jaw_open:
        _rotx([jaw], (x, y + 0.05 * k, z - 0.08 * k), -jaw_open)
        inside = sph((x, y - 0.2 * k, z - 0.1 * k), 1, (0.07 * k, snout_len * 0.8 * k, 0.02 * k)); setmat(inside, mat("mouthd", (0.35, 0.05, 0.08), 0.5))
        _rotx([inside], (x, y + 0.05 * k, z - 0.08 * k), -jaw_open * 0.5)
        out.append(inside)
        for sx in (-1, 1):
            f = box((x + sx * 0.05 * k, y - 0.2 * k - snout_len * k * 0.6, z - 0.14 * k), (0.022 * k, 0.02 * k, 0.07 * k), (0, 0, 0), bevel=0.005, taper=(0.15, 0.4))
            hard(f); setmat(f, mat("tooth", TOOTH, 0.3)); _rotx([f], (x, y + 0.05 * k, z - 0.08 * k), -jaw_open); out.append(f)
    out.append(jaw)
    return out


def wolf(variant="wolf", jaw_open=0.0, legs=None, tail_up=0.0):
    """variant: 'wolf' (cinza, magro) ou 'alpha' (preto-arroxeado, grande, olhos vermelhos, espinhos de osso)."""
    alpha = variant == "alpha"
    FUR = (0.2, 0.15, 0.24) if alpha else (0.5, 0.46, 0.5)
    FURD = (0.1, 0.07, 0.13) if alpha else (0.26, 0.22, 0.28)
    BEL = (0.55, 0.42, 0.5) if alpha else (0.84, 0.78, 0.7)
    big = 1.15 if alpha else 1.0
    P = []
    body = fuse([sph((0, -0.38, 0.68), 1, (0.29, 0.36, 0.32)), sph((0, 0.0, 0.6), 1, (0.23, 0.42, 0.25)),
                 sph((0, 0.38, 0.64), 1, (0.25, 0.3, 0.27)), sph((0, -0.64, 0.84), 1, (0.18, 0.24, 0.21), (-35, 0, 0)),
                 sph((0, -0.5, 0.82), 1, (0.22, 0.22, 0.2))], "wolfbody", 0.013, 0.6, 6)
    paint(body, lambda p, n: mix(mix(FUR, FURD, smoothstep(0.2, 0.9, n.z) * 0.6 + smoothstep(0.55, 0.9, p.z) * 0.2), BEL,
                                 smoothstep(0.1, -0.5, n.z) * smoothstep(0.7, 0.45, p.z) * 0.9 + ell_w(p, (0, -0.55, 0.7), (0.2, 0.2, 0.25)) * 0.5))
    setmat(body, mat("beastfur_%s" % str(FUR), vcol=True, rough=0.85, bump=0.35, bump_scale=110)); P.append(body)
    # crina eriçada ao longo da coluna (silhueta espinhosa)
    for k in range(8):
        t = k / 7.0
        y = -0.6 + t * 0.95; z = 0.98 - abs(t - 0.2) * 0.2 - t * 0.12
        s = box((0, y, z), (0.09, 0.13, 0.22 if alpha else 0.17), (-30 + t * 50, 0, 0), bevel=0.015, taper=(0.1, 0.4)); hard(s)
        setmat(s, mat("furd_%s" % str(FURD), FURD, 0.85)); P.append(s)
    if alpha:
        for k in range(6):   # espinhos de osso nas costas
            t = k / 5.0
            s = box((0, -0.45 + t * 0.8, 1.0 - t * 0.1), (0.07, 0.07, 0.3 - t * 0.08), (-18 + t * 25, 0, 0), bevel=0.01, taper=(0.05, 0.05)); hard(s)
            setmat(s, mat("bone", BONE, 0.6)); P.append(s)
    tag(P, "body")
    H = []
    hd = _head(H, (0, -0.86, 0.93), FUR, FURD, BEL, 0.22, jaw_open, (1.0, 0.18, 0.12) if alpha else (1.0, 0.75, 0.2), 30, big)
    if alpha:
        for sx in (-1, 1):   # chifres de osso curvos para trás
            hn = tube([(sx * 0.14, -0.84, 1.08), (sx * 0.24, -0.78, 1.26), (sx * 0.2, -0.62, 1.38)], 0.045, 0.15, 12); setmat(hn, mat("bone", BONE, 0.6)); hd.append(hn)
        # cicatriz brilhante na cara
        sc = tube([(0.06, -0.98, 1.02), (0.12, -1.0, 0.94), (0.14, -1.02, 0.86)], 0.012, 1.0, 8); setmat(sc, mat("scar", (1.0, 0.3, 0.2), 0.4, emit=5.0)); hd.append(sc)
    # pelo do pescoço (gola)
    for k in range(7):
        a = -1.0 + k * 0.33
        s = box((math.sin(a) * 0.22, -0.72, 0.8 + math.cos(a) * 0.12 - 0.03), (0.11, 0.13, 0.2 * big), (-35, math.degrees(a) * 0.6, 0), bevel=0.015, taper=(0.1, 0.4)); hard(s)
        setmat(s, mat("furd_%s" % str(FURD), FURD, 0.85)); hd.append(s)
    tag(hd, "head")
    P += hd
    # patas (rígidas); legs = {"fl": ang, "fr": ang, "bl": ang, "br": ang} em graus
    legs = legs or {}
    for key, front in (("fl", True), ("fr", True), ("bl", False), ("br", False)):
        sx = 1 if key[1] == "l" else -1
        if front:
            L = _leg(sx, True, (0.17, -0.42, 0.56), (0.17, -0.4, 0.3), (0.17, -0.46, 0.05), 0.085 * big, FUR, FURD)
            piv = (sx * PIV_FL[0], PIV_FL[1], PIV_FL[2])
        else:
            L = _leg(sx, False, (0.18, 0.4, 0.58), (0.19, 0.56, 0.32), (0.18, 0.46, 0.05), 0.095 * big, FUR, FURD)
            piv = (sx * PIV_BL[0], PIV_BL[1], PIV_BL[2])
        if legs.get(key):
            _rotx(L, piv, legs[key])
        tag(L, "leg_" + key); P += L
    tl = tube([(0, 0.6, 0.72), (0, 0.9, 0.62 + tail_up * 0.3), (0, 1.14, 0.46 + tail_up * 0.7)], 0.1, 0.35, 16)
    paint(tl, lambda p, n: mix(FUR, FURD, smoothstep(0.4, 1.1, p.y))); setmat(tl, mat("beastfur_%s" % str(FUR), vcol=True, rough=0.85, bump=0.35, bump_scale=110))
    tag([tl], "tail"); P.append(tl)
    root = group("alpha_beast" if alpha else "wolf", P)
    if alpha:
        root.scale = (1.0, 1.0, 1.0)
    return root


def boar(legs=None):
    """Javali de guerra: barril marrom-rosado com cernelha alta, presas, crina de cerdas, placa de ferro na testa."""
    FUR = (0.5, 0.3, 0.22); FURD = (0.24, 0.14, 0.12); BEL = (0.78, 0.55, 0.45)
    P = []
    body = fuse([sph((0, -0.3, 0.66), 1, (0.44, 0.52, 0.46)), sph((0, 0.38, 0.62), 1, (0.42, 0.44, 0.42)),
                 sph((0, 0.04, 0.6), 1, (0.4, 0.4, 0.38)), sph((0, -0.42, 0.95), 1, (0.36, 0.32, 0.26)),
                 sph((0, -0.78, 0.72), 1, (0.3, 0.26, 0.28))], "boarbody", 0.015, 0.6, 6)
    paint(body, lambda p, n: mix(mix(FUR, FURD, smoothstep(0.1, 0.9, n.z) * 0.6 + smoothstep(0.6, 1.1, p.z) * 0.25), BEL, smoothstep(0.1, -0.5, n.z) * 0.8))
    setmat(body, mat("boarfur", vcol=True, rough=0.85, bump=0.4, bump_scale=90)); P.append(body)
    for k in range(9):    # crina de cerdas duras
        t = k / 8.0
        s = box((0, -0.62 + t * 1.05, 1.17 - t * 0.35 - abs(t - 0.2) * 0.1), (0.1, 0.12, 0.26), (-25 + t * 40, 0, 0), bevel=0.015, taper=(0.1, 0.3)); hard(s)
        setmat(s, mat("furd_%s" % str(FURD), FURD, 0.85)); P.append(s)
    # ombreira de ferro com cravos e faixas de guerra vermelhas
    iron = mat("iron", (0.36, 0.37, 0.4), 0.45, 0.8)
    pad = cyl((0, -0.44, 1.12), 0.26, 0.07, (-10, 0, 0), seg=18, bevel=0.015); hard(pad); setmat(pad, iron); P.append(pad)
    for k in range(5):
        a = k / 5 * math.tau
        sp = box((math.cos(a) * 0.17, -0.44 + math.sin(a) * 0.17, 1.17), (0.05, 0.05, 0.12), (0, 0, 0), bevel=0.006, taper=(0.1, 0.1)); hard(sp); setmat(sp, iron); P.append(sp)
    for sx in (-1, 1):
        for k in range(3):
            b = tube([(sx * 0.42, -0.2 + k * 0.17, 0.82), (sx * 0.5, -0.19 + k * 0.17, 0.62), (sx * 0.44, -0.2 + k * 0.17, 0.4)], 0.022, 1.0, 10)
            setmat(b, mat("warpaint", (0.78, 0.12, 0.1), 0.7)); P.append(b)
    tag(P, "body")
    H = []
    hd = fuse([sph((0, -0.95, 0.74), 1, (0.27, 0.27, 0.25)), sph((0, -1.2, 0.58), 1, (0.17, 0.2, 0.15)), sph((0, -1.08, 0.64), 1, (0.2, 0.22, 0.16))], "boarhead", 0.012, 0.6, 5)
    paint(hd, lambda p, n: mix(FUR, FURD, smoothstep(0.1, 0.9, n.z) * 0.5) if p.y > -1.12 else mix((0.88, 0.6, 0.55), BEL, 0.3))
    setmat(hd, mat("boarfur", vcol=True, rough=0.85, bump=0.4, bump_scale=90)); H.append(hd)
    disc = cyl((0, -1.37, 0.58), 0.12, 0.05, (90, 0, 0), seg=20, bevel=0.01); shade(disc); setmat(disc, mat("snout", (0.95, 0.58, 0.58), 0.5)); H.append(disc)
    for sx in (-1, 1):
        nos = sph((sx * 0.045, -1.405, 0.58), 1, (0.025, 0.012, 0.035)); setmat(nos, mat("pupil", BLACK, 0.2)); H.append(nos)
        tk = tube([(sx * 0.14, -1.18, 0.5), (sx * 0.22, -1.3, 0.5), (sx * 0.22, -1.4, 0.66), (sx * 0.17, -1.42, 0.78)], 0.04, 0.12, 14); setmat(tk, mat("tusk", (0.96, 0.92, 0.78), 0.4, coat=0.3)); H.append(tk)
        ear = box((sx * 0.19, -0.84, 0.97), (0.13, 0.04, 0.17), (-10, sx * 25, sx * 15), bevel=0.015, taper=(0.3, 0.5)); hard(ear); setmat(ear, mat("furd_%s" % str(FURD), FURD, 0.85)); H.append(ear)
        H += yellow_eye((sx * 0.13, -1.15, 0.84), 0.055, 32, sx, (1.0, 0.25, 0.15), (0.24, 0.14, 0.12))
    plate = box((0, -1.02, 0.97), (0.32, 0.26, 0.06), (-30, 0, 0), bevel=0.012); hard(plate); setmat(plate, iron); H.append(plate)
    for sx in (-1, 0, 1):
        sp = box((sx * 0.1, -1.1, 1.0), (0.05, 0.05, 0.13), (-30, 0, 0), bevel=0.006, taper=(0.1, 0.1)); hard(sp); setmat(sp, iron); H.append(sp)
    tag(H, "head"); P += H
    legs = legs or {}
    for key, front in (("fl", True), ("fr", True), ("bl", False), ("br", False)):
        sx = 1 if key[1] == "l" else -1
        if front:
            L = _leg(sx, True, (0.24, -0.42, 0.56), (0.24, -0.4, 0.3), (0.24, -0.45, 0.05), 0.12, FUR, FURD, claw=False)
            piv = (sx * PIV_FL[0] * 1.3, PIV_FL[1], PIV_FL[2])
        else:
            L = _leg(sx, False, (0.24, 0.38, 0.56), (0.25, 0.48, 0.3), (0.24, 0.42, 0.05), 0.125, FUR, FURD, claw=False)
            piv = (sx * PIV_BL[0] * 1.3, PIV_BL[1], PIV_BL[2])
        for o in L[:1]:
            pass
        # casco: peça escura na ponta
        hv = cyl((sx * (0.24), -0.45 if front else 0.42, 0.035), 0.09, 0.07, seg=12, bevel=0.01); hard(hv); setmat(hv, mat("hoof", (0.14, 0.1, 0.1), 0.5)); L.append(hv)
        if legs.get(key):
            _rotx(L, piv, legs[key])
        tag(L, "leg_" + key); P += L
    tl = tube([(0, 0.78, 0.7), (0.05, 0.95, 0.76), (0.0, 1.05, 0.62)], 0.035, 0.4, 12); setmat(tl, mat("furd_%s" % str(FURD), FURD, 0.85)); tag([tl], "tail"); P.append(tl)
    return group("war_boar", P)


# ------------------------------------------------------------------ exportação

UNITS = {"wolf_pack": (wolf, 0.95, 3000), "war_boar": (boar, 1.0, 3000), "alpha_beast": (lambda: wolf("alpha"), 2.2, 3000)}


def main():
    import vat, anims
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = os.path.abspath(argv[0]); os.makedirs(out, exist_ok=True)
    ids = argv[1].split(",") if len(argv) > 1 else list(UNITS)
    for i in ids:
        try:
            bpy.ops.wm.read_factory_settings(use_empty=True); mk_reset()
            fn, h, b = UNITS[i]
            root = fn()
            if i == "war_boar":
                a = anims._quad(1.0, (0.3, -0.42, 0.56), (0.3, 0.38, 0.56), (0, -0.7, 0.8), (0, 0.78, 0.7), stride=26, bob=0.03)
            else:
                a = anims._quad(1.0, PIV_FL, PIV_BL, NECK, TAILP, stride=32, bob=0.035)
            vat.export(root, os.path.join(out, i + ".lbm"), h, b, a)
        except Exception:
            print("FALHOU", i); traceback.print_exc()


def mk_reset():
    import mk
    mk._MATS.clear()


if __name__ == "__main__" or "--" in sys.argv:
    if any(a.endswith("creatures_plague.py") for a in sys.argv) and "--" in sys.argv:
        main()
