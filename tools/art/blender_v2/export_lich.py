"""Exporta os modelos de jogo do Lich e do Titã (creatures_lich.py) como .lbm, pelo mesmo caminho do build.py.
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/blender_v2/export_lich.py -- <pasta de saída> [ids,separados]
Depois: godot --headless --path . -s res://tools/art/import_v2.gd -- --src=<pasta de saída>
(UNITS e animações ficam aqui porque build.py/anims.py pertencem a outro lote; o registro no jogo é feito à parte.)"""
import os, sys, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy
import mk, vat, anims, creatures_lich

# id -> (altura em metros no jogo, orçamento de triângulos, animação)
UNITS = {
    "death_knight": (2.0, 2800, lambda: {"anim": anims.biped(2.3, (0.14, 0.02, 0.98), (0.42, 0.0, 1.5), (0, 0, 1.75), stride=24, swing=18, atk="smash", atk_arm="arm_r", bob=0.025)}),
    "bone_colossus": (3.4, 2800, lambda: {"anim": anims.biped(3.4, (0.4, 0.0, 1.45), (0.78, 0.04, 2.35), (0, -0.1, 2.6), stride=18, swing=14, atk="smash", atk_arm="arm_r", bob=0.02, lean=8)}),
    "ruin_titan": (3.2, 2800, lambda: {"anim": anims.biped(3.3, (0.36, 0.0, 1.4), (0.95, 0.0, 2.45), (0, 0, 2.9), stride=16, swing=12, atk="smash", atk_arm="arm_l", bob=0.015, lean=6)}),
}


def merge_parts(root, budget):
    """Junta as peças pequenas do mesmo osso e do mesmo material (o exportador reserva um mínimo de triângulos por peça)."""
    objs = [o for o in vat.descendants(root) if o.type in ('MESH', 'CURVE')]
    for o in objs:
        if o.type == 'CURVE':
            mk._sel(o); bpy.ops.object.convert(target='MESH')
    objs = [o for o in vat.descendants(root) if o.type == 'MESH']
    groups = {}
    for o in objs:
        if o.modifiers:
            mk.apply_mods(o)
        m = o.data.materials[0].name if o.data.materials else ""
        groups.setdefault((o.get("bone", "body"), m), []).append(o)
    for (bone, m), lst in groups.items():
        if len(lst) < 2:
            continue
        keep = lst[0]
        mk._sel(keep)
        for o in lst[1:]:
            o.select_set(True)
        bpy.ops.object.join()
        keep["bone"] = bone
    # o decimate do vat.py não passa de 2% de redução; aqui reduz até o orçamento antes (mínimo de 40 por peça)
    objs = [o for o in vat.descendants(root) if o.type == 'MESH']
    cnt = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs}
    tot = max(1, sum(cnt.values()))
    for o in objs:
        tgt = max(40, int(cnt[o.name] * budget / tot))
        if cnt[o.name] > tgt:
            m = o.modifiers.new("dec", 'DECIMATE'); m.decimate_type = 'COLLAPSE'; m.ratio = max(0.001, tgt / cnt[o.name])
            mk.apply_mods(o)
            for q in o.data.polygons:
                q.use_smooth = True


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = argv[0]
    os.makedirs(out, exist_ok=True)
    ids = argv[1].split(",") if len(argv) > 1 and not argv[1].startswith("--") else list(UNITS)
    for i in ids:
        try:
            bpy.ops.wm.read_factory_settings(use_empty=True)
            mk._MATS.clear()
            root = getattr(creatures_lich, i)()
            h, b, cfg = UNITS[i]
            merge_parts(root, b)
            a = cfg()
            vat.export(root, os.path.join(out, i + ".lbm"), h, b, a.get("anim"), a.get("deform"), a.get("rig"))
            print("OK", i)
        except Exception:
            print("FALHOU", i)
            traceback.print_exc()


main()
