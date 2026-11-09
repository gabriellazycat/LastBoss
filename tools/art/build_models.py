"""Gera os modelos dos looks 1..4 (monstros e herói) em tools/art/out/look<N>/<id>.lbm.

Uso (sem janela):
  blender -b --factory-startup -P tools/art/build_models.py -- [--looks 1,2] [--only rat,bat] [--hero] [--units]
Depois: godot --headless --path . res://tools/art/import_models.tscn  (converte para assets/models/look<N>/*.res)
"""
import os
import sys
import time

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import creatures  # noqa: E402
import props  # noqa: E402
from kit import Model, export  # noqa: E402


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    looks = [1, 2, 3, 4]
    only = None
    do_units = True
    do_hero = True
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--looks":
            looks = [int(x) for x in argv[i + 1].split(",")]
            i += 1
        elif a == "--only":
            only = set(argv[i + 1].split(","))
            i += 1
        elif a == "--hero":
            do_units = False
        elif a == "--units":
            do_hero = False
        elif a == "--ground":
            do_units = do_hero = False
        i += 1
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for li in looks:
        L = creatures.LOOKS[li]
        out = os.path.join(HERE, "out", "look%d" % li)
        os.makedirs(out, exist_ok=True)
        jobs = []
        if do_units:
            jobs += [(uid, fn, None) for uid, fn in creatures.UNITS.items()]
        if do_hero:
            jobs += [("hero_" + p, None, p) for p in creatures.HERO_PARTS]
        for name, fn, part in jobs:
            if only and name not in only:
                continue
            t = time.time()
            m = Model(name)
            if part:
                creatures.hero_part(m, L, part)
            else:
                fn(m, L)
            nv, nt = export(m, os.path.join(out, name + ".lbm"))
            print("look%d %-18s %6d verts %6d tris %.1fs" % (li, name, nv, nt, time.time() - t), flush=True)
        # Cenário do look de chão de mesmo número.
        if not (do_units or do_hero) or "--ground" in argv or not only:
            gout = os.path.join(HERE, "out", "ground%d" % li)
            os.makedirs(gout, exist_ok=True)
            for pid in props.PROPS:
                if only and pid not in only and "--ground" not in argv:
                    continue
                t = time.time()
                m = Model(pid)
                props.ground_prop(m, li, pid)
                nv, nt = export(m, os.path.join(gout, pid + ".lbm"))
                print("ground%d %-16s %6d verts %6d tris %.1fs" % (li, pid, nv, nt, time.time() - t), flush=True)


main()
