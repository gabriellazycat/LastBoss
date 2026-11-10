"""Animações (andar + ataque) de cada monstro, gravadas em VAT por vat.export.

Cada monstro tem:
  pretag(root): marca o osso de cada objeto pelo nome ou pela posição (o["bone"]);
  rig(p, osso): pesos por região para corpos fundidos num bloco só (pernas e braços do ogro, patas do rato);
  anim(kind, t): matriz de cada osso no quadro t (0..1) de 'walk' (ciclo) ou 'atk' (golpe, uma vez);
  deform(p, n, osso, t): deformação macia opcional (gosma, fantasma). t em 0..1 andando, 1..2 no ataque.
Eixos do Blender: Z para cima, frente = -Y. Girar em X com ângulo negativo leva para a frente o que pende para baixo.
"""
import math
from mathutils import Matrix, Vector
from vat import rot_about, tr, descendants

TAU = math.tau
I4 = Matrix.Identity(4)


def ss(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def ease(x):
    return ss(0.0, 1.0, x)


def center(o):
    if o.type != 'MESH' or not o.data.vertices:
        return o.matrix_world.translation
    s = Vector((0, 0, 0))
    for v in o.data.vertices:
        s += v.co
    return o.matrix_world @ (s / len(o.data.vertices))


def pretag_by(rules):
    """rules: lista de (osso, f(nome, centro) -> bool); o primeiro que casar vale. Não mexe em quem já tem osso."""
    def f(root):
        for o in descendants(root):
            if o.type not in ('MESH', 'CURVE') or "bone" in o.keys():
                continue
            c = center(o)
            nm = o.name.split('.')[0]
            for b, pred in rules:
                if pred(nm, c):
                    o["bone"] = b
                    break
    return f


def chain(*ms):
    out = I4
    for m in ms:
        out = out @ m
    return out


# ------------------------------------------------------------------ bípede genérico

def biped(h, hip, sh, neck, stride=28, swing=22, atk="smash", bob=0.035, lean=10, atk_arm="arm_r"):
    """hip/sh = (x, y, z) do lado +x (o -x é espelhado); neck = (0, y, z)."""
    hl, hr = Vector(hip), Vector((-hip[0], hip[1], hip[2]))
    sl, sr = Vector(sh), Vector((-sh[0], sh[1], sh[2]))
    nk = Vector(neck)
    mid = Vector((0, hip[1], hip[2]))

    def walk(t):
        ph = TAU * t
        s = math.sin(ph)
        B = tr(0, 0, abs(math.cos(ph)) * bob * h) @ rot_about(mid, 'Y', math.radians(3) * s)
        return {
            "body": B,
            "head": B @ rot_about(nk, 'X', math.radians(4) * math.sin(2 * ph)),
            "leg_l": rot_about(hl, 'X', -math.radians(stride) * s),
            "leg_r": rot_about(hr, 'X', math.radians(stride) * s),
            "arm_l": B @ rot_about(sl, 'X', math.radians(swing) * s),
            "arm_r": B @ rot_about(sr, 'X', -math.radians(swing) * s),
        }

    def attack(t):
        d = walk(0.0)
        B = d["body"]
        if atk == "smash":      # ergue por cima da cabeça e desce na frente
            a = -150 * ease(t / 0.4) if t < 0.4 else -150 + 110 * ease((t - 0.4) / 0.25)
            ln = lean * (ease((t - 0.35) / 0.3) - ease((t - 0.75) / 0.25) * 0.5)
        elif atk == "throw":    # leva para trás e arremessa por cima
            a = 60 * ease(t / 0.35) if t < 0.35 else 60 - 220 * ease((t - 0.35) / 0.3)
            ln = lean * ease((t - 0.3) / 0.3)
        elif atk == "thrust":   # estocada para a frente
            a = 30 * ease(t / 0.3) if t < 0.3 else 30 - 110 * ease((t - 0.3) / 0.2)
            ln = lean * ease((t - 0.3) / 0.2)
        else:                   # cast: as duas mãos para a frente
            a = -95 * ease(t / 0.45)
            ln = lean * 0.5 * ease(t / 0.45)
        L = rot_about(mid, 'X', math.radians(ln))
        B2 = L @ B
        piv = sr if atk_arm == "arm_r" else sl
        d["body"] = B2
        d["head"] = B2 @ rot_about(nk, 'X', math.radians(-ln * 0.6))
        d[atk_arm] = B2 @ rot_about(piv, 'X', math.radians(a))
        other = "arm_l" if atk_arm == "arm_r" else "arm_r"
        if atk == "cast":
            d[other] = B2 @ rot_about(sl if other == "arm_l" else sr, 'X', math.radians(a))
        else:
            d[other] = B2 @ rot_about(sl if other == "arm_l" else sr, 'X', math.radians(15 * ease(t / 0.4)))
        return d

    return lambda kind, t: walk(t) if kind == "walk" else attack(t)


def limb_rig(rules, default="body", soft=0.05):
    """rules: lista de (osso, f(p) -> peso 0..1), aplicada só aos vértices de partes do 'body'."""
    def rig(p, bone):
        if bone != "body":
            return [(bone, 1.0)]
        out = []
        rest = 1.0
        for b, f in rules:
            w = min(rest, f(p))
            if w > 0:
                out.append((b, w))
                rest -= w
        if rest > 0:
            out.append((default, rest))
        return out
    return rig


# ------------------------------------------------------------------ rato (quadrúpede, patas no bloco do corpo)

def _quad(h, fl, bl, neck, tail, stride=30, bob=0.04, bite=True):
    """fl/bl = pivôs da pata dianteira/traseira do lado +x."""
    fl, bl = Vector(fl), Vector(bl)
    fr, br = Vector((-fl.x, fl.y, fl.z)), Vector((-bl.x, bl.y, bl.z))
    nk, tl = Vector(neck), Vector(tail)
    mid = (fl + bl) / 2
    mid.x = 0

    def walk(t):
        ph = TAU * t
        s = math.sin(ph)
        B = tr(0, 0, abs(math.cos(ph)) * bob * h) @ rot_about(mid, 'X', math.radians(3) * math.sin(2 * ph))
        return {"body": B, "torso": B, "head": B @ rot_about(nk, 'X', math.radians(5) * math.sin(2 * ph)),
                "leg_fl": rot_about(fl, 'X', -math.radians(stride) * s), "leg_br": rot_about(br, 'X', -math.radians(stride) * s),
                "leg_fr": rot_about(fr, 'X', math.radians(stride) * s), "leg_bl": rot_about(bl, 'X', math.radians(stride) * s),
                "tail": B @ rot_about(tl, 'Z', math.radians(18) * math.sin(ph + 1.0))}

    def attack(t):
        d = walk(0.0)
        # agacha para trás e dá o bote para a frente com a cabeça baixa
        back = ease(t / 0.35) if t < 0.35 else 1.0 - ease((t - 0.35) / 0.2) * 2.2 + ease((t - 0.7) / 0.3) * 1.2
        dy = 0.12 * h * back
        B = tr(0, dy, -0.03 * h * abs(back)) @ rot_about(mid, 'X', math.radians(-8 * back))
        d["body"] = B
        d["torso"] = B
        d["head"] = B @ rot_about(nk, 'X', math.radians(20 * max(0.0, -back)))
        for k in ("leg_fl", "leg_fr"):
            d[k] = B @ rot_about(fl if k == "leg_fl" else fr, 'X', math.radians(-35 * max(0.0, -back)))
        d["tail"] = B @ rot_about(tl, 'X', math.radians(25 * max(0.0, -back)))
        return d

    return lambda kind, t: walk(t) if kind == "walk" else attack(t)


def rat_cfg(scale=1.0):
    def side_leg(p, front):
        if front:
            w = ss(0.34, 0.22, p.z) * ss(-0.14, -0.24, p.y) * ss(0.05, 0.1, abs(p.x))
        else:
            w = ss(0.3, 0.16, p.z) * ss(0.15, 0.24, p.y) * ss(0.08, 0.15, abs(p.x))
        return w
    rig = limb_rig([
        ("leg_fl", lambda p: side_leg(p, True) if p.x > 0 else 0.0), ("leg_fr", lambda p: side_leg(p, True) if p.x < 0 else 0.0),
        ("leg_bl", lambda p: side_leg(p, False) if p.x > 0 else 0.0), ("leg_br", lambda p: side_leg(p, False) if p.x < 0 else 0.0),
        ("head", lambda p: ss(-0.3, -0.45, p.y)),
        ("tail", lambda p: ss(0.55, 0.62, p.y)),
    ])
    pre = pretag_by([
        ("leg_fl", lambda n, c: c.z < 0.1 and c.y < -0.2 and c.x > 0), ("leg_fr", lambda n, c: c.z < 0.1 and c.y < -0.2 and c.x < 0),
        ("leg_bl", lambda n, c: c.z < 0.1 and c.y > 0.0 and c.x > 0), ("leg_br", lambda n, c: c.z < 0.1 and c.y > 0.0 and c.x < 0),
        ("tail", lambda n, c: n == "tube" and c.y > 0.5),
        ("head", lambda n, c: c.y < -0.35 and c.z > 0.4),
    ])
    return {"pretag": pre, "rig": rig,
            "anim": _quad(0.95 * scale, (0.15, -0.3, 0.36), (0.24, 0.36, 0.3), (0, -0.35, 0.5), (0, 0.6, 0.3))}


# ------------------------------------------------------------------ goblin

def goblin_cfg():
    pre = pretag_by([
        ("arm_r", lambda n, c: c.x > 0.25 and c.z > 0.5),                 # mão com o maço aceso (e o maço)
        ("arm_l", lambda n, c: n.startswith("gobarm") and c.x < 0),
        ("arm_r", lambda n, c: n.startswith("gobarm") and c.x > 0),
        ("leg_l", lambda n, c: n == "foot" and c.x > 0), ("leg_r", lambda n, c: n == "foot" and c.x < 0),
        ("head", lambda n, c: c.z > 0.7),
    ])
    rig = limb_rig([
        ("leg_l", lambda p: ss(0.3, 0.2, p.z) * ss(0.02, 0.06, p.x)),
        ("leg_r", lambda p: ss(0.3, 0.2, p.z) * ss(-0.02, -0.06, p.x)),
        ("head", lambda p: ss(0.62, 0.7, p.z)),
    ])
    return {"pretag": pre, "rig": rig, "anim": biped(1.1, (0.12, 0.0, 0.3), (0.18, 0.0, 0.56), (0, 0, 0.66), stride=32, atk="throw")}


# ------------------------------------------------------------------ ogro (braços e pernas no bloco do corpo)

def ogre_cfg():
    pre = pretag_by([
        ("arm_l", lambda n, c: c.x > 0.6 and c.z < 1.3),  # clava e atadura do lado +x
        ("arm_r", lambda n, c: c.x < -0.6 and c.z < 1.3),
        ("leg_l", lambda n, c: n == "foot" and c.x > 0), ("leg_r", lambda n, c: n == "foot" and c.x < 0),
        ("head", lambda n, c: c.z > 1.5),
    ])
    rig = limb_rig([
        ("arm_l", lambda p: ss(0.48, 0.6, p.x) * ss(1.5, 1.3, p.z)),
        ("arm_r", lambda p: ss(-0.48, -0.6, p.x) * ss(1.5, 1.3, p.z)),
        ("leg_l", lambda p: ss(0.62, 0.45, p.z) * ss(0.06, 0.14, p.x)),
        ("leg_r", lambda p: ss(0.62, 0.45, p.z) * ss(-0.06, -0.14, p.x)),
        ("head", lambda p: ss(1.52, 1.6, p.z)),
    ])
    return {"pretag": pre, "rig": rig,
            "anim": biped(2.0, (0.28, 0.0, 0.62), (0.56, 0.02, 1.4), (0, -0.1, 1.55), stride=22, swing=14, atk="smash", atk_arm="arm_l", bob=0.025)}


# ------------------------------------------------------------------ esqueletos

def skeleton_cfg(archer=False):
    a = biped(1.55, (0.1, 0.02, 0.42), (0.23, 0.02, 0.88), (0, 0, 0.95), stride=30, atk="cast" if archer else "smash",
              atk_arm="arm_l" if archer else "arm_r")
    if archer:
        base = a

        def a(kind, t, base=base):
            d = base(kind, t)
            if kind == "atk":   # o braço do arco aponta; o outro puxa a corda para trás
                B = d["body"]
                d["arm_r"] = B @ rot_about(Vector((-0.23, 0.02, 0.88)), 'X', math.radians(-80 * ease(t / 0.4) + 50 * ease((t - 0.6) / 0.15)))
            return d
    return {"anim": a}


# ------------------------------------------------------------------ gosma e fantasma (deformação macia)

def slime_cfg():
    def deform(p, n, bone, t):
        if t <= 1.0:
            ph = TAU * t
            k = math.sin(ph)
            sz = 1.0 + 0.12 * k
            sxy = 1.0 / math.sqrt(sz)
            q = Vector((p.x * sxy, p.y * sxy, p.z * sz))
            q.y += 0.04 * math.cos(ph) * p.z
            return q, Vector((n.x / sxy, n.y / sxy, n.z / sz)).normalized()
        u = t - 1.0
        st = ease(u / 0.35) if u < 0.35 else 1.0 - ease((u - 0.6) / 0.4)
        sq = 1.0 - 0.25 * ease(u / 0.3) * (1.0 - ease((u - 0.3) / 0.1))
        q = Vector((p.x * (1 - 0.1 * st), p.y - st * 0.35 * p.z, p.z * sq * (1 + 0.25 * st)))
        return q, n
    return {"deform": deform}


def ghost_cfg():
    sh = Vector((0.33, -0.05, 0.85))

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t
            B = tr(0, 0, 0.05 * math.sin(ph))
            return {"body": B, "arm_l": B @ rot_about(sh, 'X', math.radians(15) * math.sin(ph)),
                    "arm_r": B @ rot_about(Vector((-sh.x, sh.y, sh.z)), 'X', -math.radians(15) * math.sin(ph))}
        go = ease(t / 0.4) if t < 0.4 else 1.0 - ease((t - 0.7) / 0.3)
        B = tr(0, -0.35 * go, 0.05 * go) @ rot_about(Vector((0, 0, 0.6)), 'X', math.radians(15 * go))
        return {"body": B, "arm_l": B @ rot_about(sh, 'X', math.radians(-100 * go)),
                "arm_r": B @ rot_about(Vector((-sh.x, sh.y, sh.z)), 'X', math.radians(-100 * go))}

    def deform(p, n, bone, t):
        if p.z < 0.5:   # barra da cauda ondulando
            k = (0.5 - p.z) * 0.5
            p = Vector((p.x + math.sin(TAU * t + p.z * 8) * 0.12 * k, p.y + math.cos(TAU * t + p.z * 6) * 0.06 * k, p.z))
        return p, n
    return {"anim": anim, "deform": deform}


# ------------------------------------------------------------------ voadores, estruturas e o resto

def rat_king_cfg():
    c = rat_cfg()
    pre = c["pretag"]

    def pretag(root):
        for o in descendants(root):
            nm = o.name.split('.')[0]
            if nm == "cape" or (o.type == 'MESH' and nm == "Torus" and center(o).y > -0.3):
                o["bone"] = "torso"
        pre(root)
    c["pretag"] = pretag
    return c


def bat_cfg():
    shl, shr = Vector((0.2, 0, 0.62)), Vector((-0.2, 0, 0.62))

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t
            f = math.sin(ph)
            B = tr(0, 0, 0.06 * math.sin(ph + 1.2))
            return {"body": B, "wing_l": B @ rot_about(shl, 'Y', -math.radians(45) * f),
                    "wing_r": B @ rot_about(shr, 'Y', math.radians(45) * f)}
        go = ease(t / 0.35) if t < 0.35 else 1.0 - ease((t - 0.6) / 0.4)
        B = tr(0, -0.4 * go, -0.15 * go) @ rot_about(Vector((0, 0, 0.6)), 'X', math.radians(25 * go))
        return {"body": B, "wing_l": B @ rot_about(shl, 'Y', -math.radians(60) * (1 - go) + math.radians(20) * go),
                "wing_r": B @ rot_about(shr, 'Y', math.radians(60) * (1 - go) - math.radians(20) * go)}
    return {"anim": anim}


def spectre_cfg():
    def anim(kind, t):
        if kind == "walk":
            return {"body": tr(0, 0, 0.05 * math.sin(TAU * t)) @ rot_about(Vector((0, 0, 0.8)), 'Z', math.radians(6) * math.sin(TAU * t))}
        go = ease(t / 0.3) if t < 0.3 else 1.0 - ease((t - 0.55) / 0.45)
        back = ease(t / 0.25) * (1 - ease((t - 0.25) / 0.1))
        return {"body": tr(0, 0.15 * back - 0.45 * go, 0) @ rot_about(Vector((0, 0, 0.8)), 'X', math.radians(25 * go - 10 * back))}

    def deform(p, n, bone, t):
        if p.z < 0.55:
            k = (0.55 - p.z) * 0.8
            p = Vector((p.x + math.sin(TAU * t + p.z * 9) * 0.1 * k, p.y + math.cos(TAU * t + p.z * 7) * 0.05 * k, p.z))
        return p, n
    return {"anim": anim, "deform": deform}


def cultists_cfg():
    return {"anim": biped(1.6, (0.12, 0.0, 0.3), (0.24, 0.0, 0.9), (0, 0, 1.05), stride=0, swing=12, atk="cast", bob=0.02, lean=6)}


def werewolf_cfg():
    pre = pretag_by([
        ("tail", lambda n, c: n == "tube" and c.y > 0.3),
        ("arm_l", lambda n, c: c.x > 0.42 and c.z < 1.0), ("arm_r", lambda n, c: c.x < -0.42 and c.z < 1.0),
        ("leg_l", lambda n, c: c.z < 0.15 and c.x > 0), ("leg_r", lambda n, c: c.z < 0.15 and c.x < 0),
        ("head", lambda n, c: c.z > 1.36 and c.y < -0.1),
    ])
    rig = limb_rig([
        ("arm_l", lambda p: ss(0.38, 0.5, p.x) * ss(1.4, 1.2, p.z)),
        ("arm_r", lambda p: ss(-0.38, -0.5, p.x) * ss(1.4, 1.2, p.z)),
        ("leg_l", lambda p: ss(0.66, 0.5, p.z) * ss(0.05, 0.12, p.x)),
        ("leg_r", lambda p: ss(0.66, 0.5, p.z) * ss(-0.05, -0.12, p.x)),
        ("head", lambda p: ss(1.38, 1.46, p.z) * ss(-0.12, -0.22, p.y)),
    ])
    base = biped(1.8, (0.18, 0.05, 0.62), (0.45, -0.05, 1.32), (0, -0.2, 1.42), stride=30, swing=25, atk="smash", atk_arm="arm_l", bob=0.03, lean=15)
    shr = Vector((-0.45, -0.05, 1.32))

    def anim(kind, t):
        d = base(kind, t)
        d["tail"] = d["body"] @ rot_about(Vector((0, 0.32, 0.75)), 'Z', math.radians(20) * math.sin(TAU * t))
        if kind == "atk":   # golpe com as duas garras
            a = -150 * ease(t / 0.4) if t < 0.4 else -150 + 110 * ease((t - 0.45) / 0.25)
            d["arm_r"] = d["body"] @ rot_about(shr, 'X', math.radians(a))
        return d
    return {"pretag": pre, "rig": rig, "anim": anim}


def scrap_golem_cfg():
    return {"anim": biped(2.0, (0.25, 0.02, 0.57), (0.72, 0.0, 1.65), (0, 0, 1.85), stride=20, swing=16, atk="smash", atk_arm="arm_l", bob=0.02, lean=8)}


def mimic_cfg():
    hinge = Vector((0, 0.36, 0.62))

    def anim(kind, t):
        if kind == "walk":
            ph = TAU * t
            hop = abs(math.sin(ph)) * 0.12
            B = tr(0, 0, hop) @ rot_about(Vector((0, 0, 0)), 'Y', math.radians(5) * math.sin(ph))
            return {"body": B, "lid": B @ rot_about(hinge, 'X', -math.radians(18) * abs(math.sin(ph * 2)))}
        op = ease(t / 0.4) if t < 0.4 else 1.0 - ease((t - 0.5) / 0.15)
        go = ease((t - 0.4) / 0.15) * (1 - ease((t - 0.7) / 0.3))
        B = tr(0, -0.3 * go, 0.1 * go)
        return {"body": B, "lid": B @ rot_about(hinge, 'X', -math.radians(75) * op)}
    return {"anim": anim}


def structure_cfg(base_z=0.0, head_piv=None):
    """Estrutura parada: respira e balança devagar; no ataque dá um tranco para a frente (a gárgula se inclina)."""
    def anim(kind, t):
        if kind == "walk":
            s_ = math.sin(TAU * t)
            B = rot_about(Vector((0, 0, base_z)), 'X', math.radians(1.5) * s_) @ tr(0, 0, 0.01 * s_)
            d = {"body": B}
            if head_piv:
                d["head"] = B @ rot_about(Vector(head_piv), 'Z', math.radians(10) * math.sin(TAU * t + 1))
            return d
        k = ease(t / 0.3) if t < 0.3 else 1.0 - ease((t - 0.45) / 0.55)
        sh = math.sin(t * 40) * 0.02 * (1 - t)
        B = tr(sh, 0, 0) @ rot_about(Vector((0, 0, base_z)), 'X', math.radians(6) * k)
        d = {"body": B}
        if head_piv:
            d["head"] = B @ rot_about(Vector(head_piv), 'X', math.radians(35) * k)
        return d
    return {"anim": anim}


CFG = {
    "rat": rat_cfg, "goblin_dynamiter": goblin_cfg, "ogre": ogre_cfg, "slime": slime_cfg, "ghost": ghost_cfg,
    "skeleton": lambda: skeleton_cfg(False), "skeleton_archers": lambda: skeleton_cfg(True),
    "rat_king": rat_king_cfg, "bat": bat_cfg, "spectre": spectre_cfg, "cultists": cultists_cfg, "werewolf": werewolf_cfg,
    "scrap_golem": scrap_golem_cfg, "mimic": mimic_cfg, "bone_totem": lambda: structure_cfg(),
    "bat_nest": lambda: structure_cfg(), "gargoyle_tower": lambda: structure_cfg(head_piv=(0, 0, 2.6)),
}


def get(i):
    f = CFG.get(i)
    return f() if f else {}
