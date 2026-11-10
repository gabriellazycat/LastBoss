import sys; sys.path.insert(0, sys.argv[sys.argv.index("--")+1])
import stage as st, chars2, bpy
which = sys.argv[-1]
st.reset(); sc = bpy.context.scene; sc.cycles.samples = 128
sc.render.resolution_x, sc.render.resolution_y = 1400, 900
def desc(r):
    out=[]; q=[r]
    while q:
        x=q.pop()
        for o in bpy.data.objects:
            if o.parent==x: out.append(o); q.append(o)
    return out
ROT = {"goblin_dynamiter": 180, "slime": 90, "ogre": 180}
def cur(nm, x, h, extra=0):
    if nm == "mage":
        r, o = st.import_glb(st.S + "/mage.glb", "cur_mage")
        for ob in o:
            if ob.name.split('.')[0] in ("1H_Wand", "Spellbook", "Spellbook_open", "Icosphere"):
                ob.hide_render = True; ob.hide_viewport = True
        st.place(r, o, x, h, 15 + extra)
    else:
        r, o = st.current(nm); st.place(r, o, x, h, ROT[nm] + extra)
CFG = {"goblin": ("goblin_dynamiter", chars2.goblin, 1.0, 0.75, 3.6),
       "slime": ("slime", chars2.slime, 0.8, 1.05, 5.0),
       "ogre": ("ogre", chars2.ogre, 1.9, 1.2, 7.0),
       "mage": ("mage", chars2.wizard, 1.8, 0.85, 6.0)}
if which == "game":
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    XS = {"goblin": (-7.0, 0.8), "slime": (-5.5, 2.3), "ogre": (-3.3, 4.6), "mage": (-1.1, 6.9)}
    for k in ("goblin", "slime", "ogre", "mage"):
        nm, fn, h, half, d = CFG[k]
        cur(nm, XS[k][0], h)
        n = fn(); st.place(n, desc(n), XS[k][1], h, 0)
    st.camera((0.0, -14.5, 12.0), (0.0, 0, 0.4), 40)
    st.render(st.S + "/f2_game.png"); raise SystemExit
nm, fn, h, half, d = CFG[which]
cur(nm, -half, h)
n = fn(); st.place(n, desc(n), half, h, -15)
st.camera((0.6, -d, h * 0.85 + d * 0.18), (0, 0, h * 0.5), 50)
st.render(st.S + f"/f2_{which}.png")
