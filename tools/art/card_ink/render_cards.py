"""Renderiza a arte de nanquim das cartas.
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/art/card_ink/render_cards.py -- <pasta de saída> [ids,separados]
Grava <id>_v1.png (nanquim), <id>_v2.png (aguada) e <id>_v3.png (duas tintas)."""
import os, sys, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "blender_v2"))
import bpy
import mk, ink, scenes

# lote alternativo: CARD_SCENES_MODULE=scenes_dragon (lê todo dicionário SCENES* do módulo)
SCN = scenes.SCENES
_alt = os.environ.get("CARD_SCENES_MODULE")
if _alt:
    import importlib
    _m = importlib.import_module(_alt)
    SCN = {}
    for _k in dir(_m):
        if _k.startswith("SCENES") and isinstance(getattr(_m, _k), dict):
            SCN.update(getattr(_m, _k))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = os.path.abspath(argv[0])   # com --factory-startup um caminho relativo cairia na raiz do disco
    ids = argv[1].split(",") if len(argv) > 1 else list(SCN)
    for i in ids:
        try:
            bpy.ops.wm.read_factory_settings(use_empty=True)
            mk._MATS.clear()
            ink.setup_scene()
            cfg = SCN[i]()
            ink.frame_camera(cfg.get("dir", (0.5, -1.0, 0.38)), lens=cfg.get("lens", 85))
            ink.render_card(out, i, cfg.get("kind", "monster"), cfg.get("hatch", 26.0))
            print("OK", i)
        except Exception:
            print("FALHOU", i)
            traceback.print_exc()


main()
