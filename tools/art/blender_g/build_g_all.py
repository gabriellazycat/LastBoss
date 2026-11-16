"""Refaz TODOS os modelos do jogo no estilo escolhido (V4: geometria normal + atlas de pincel seco, 15/11/2026).
Reaproveita os exportadores do v2 (build.py, creatures_*.py, bosses_final.py, export_lich.py) trocando vat.export
pela exportação de vat_g (sem detalhe miúdo, UV, paleta da carta, atlas "dry").
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_g/build_g_all.py -- <script> <saída> [ids]
<script>: build | plague | dragon | lich | bosses   (bosses recebe --only=<vilões> no lugar dos ids)
Saída: <saída>/n/<id>.lbm e <saída>/tex/dry_n/<id>.png (depois: import_g.gd, igual à amostra)."""
import os, sys, runpy
HERE = os.path.dirname(os.path.abspath(__file__))
V2 = os.path.abspath(os.path.join(HERE, "..", "blender_v2"))
sys.path.insert(0, V2)
sys.path.insert(0, HERE)
import bpy
import mk, vat, vat_g, treat

argv = sys.argv[sys.argv.index("--") + 1:]
which, out = argv[0], os.path.abspath(argv[1])
rest = argv[2:]
GAIN = float(os.environ.get("LBG_GAIN", "0.45"))
PULL = float(os.environ.get("LBG_PULL", "0.65"))
GAIN_SC = float(os.environ.get("LBG_GAIN_SC", "0.6"))
PULL_SCENERY = float(os.environ.get("LBG_PULL_SC", "0.45"))
SAT = float(os.environ.get("LBG_SAT", "1.15"))
EYE = {"rat_king": (0.62, 0.13, 0.16)}
COOL = (0.30, 0.32, 0.42)


def export_g(root, path, height, budget=2500, anim=None, deform=None, rig=None, recenter=True):
    i = os.path.splitext(os.path.basename(path))[0]
    vat_g.simplify(root)
    mk._MATS.clear()
    vat_g.flatten_eyes(root, EYE.get(i, (0.10, 0.085, 0.11)))
    objs = vat_g.prepare(root, int(budget * 0.7))
    key = treat.pal_key(i)
    grade = treat.make_grade(key, pull=PULL if key != "scenery" else PULL_SCENERY, lift=0.04, sat=SAT, gain=GAIN if key != "scenery" else GAIN_SC)
    os.makedirs(os.path.join(out, "n"), exist_ok=True)
    d = vat_g.export(root, os.path.join(out, "n", i + ".lbm"), height, objs, grade, anim, deform, rig, recenter)
    C, P, N, M = treat.raster(d)
    img = treat.treat("dry", C, P, N, d["height"], COOL)
    td = os.path.join(out, "tex", "dry_n")
    os.makedirs(td, exist_ok=True)
    treat.save_png(img, os.path.join(td, i + ".png"))


vat.export = export_g
SCRIPTS = {"build": "build.py", "plague": "creatures_plague.py", "dragon": "creatures_dragon.py", "lich": "export_lich.py", "bosses": "bosses_final.py"}
path = os.path.join(V2, SCRIPTS[which])
if which == "bosses":
    sys.argv = ["blender", path, "--", "--out=" + os.path.join(out, "_unused")] + rest
else:
    sys.argv = ["blender", path, "--", os.path.join(out, "_unused")] + rest
runpy.run_path(path, run_name="__main__")
