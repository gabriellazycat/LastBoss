import sys; sys.path.insert(0, sys.argv[sys.argv.index("--")+1])
import stage as st, chars, bpy, math
which = sys.argv[-1]
st.reset(); sc = bpy.context.scene; sc.cycles.samples = 128
sc.render.resolution_x, sc.render.resolution_y = 1400, 900
def kids(r): return [o for o in bpy.data.objects if o.parent == r or (o.parent and o.parent.parent == r) or (o.parent and o.parent.parent and o.parent.parent.parent == r)]
def all_desc(r):
    out=[]; st_=[r]
    while st_:
        x=st_.pop(); 
        for o in bpy.data.objects:
            if o.parent==x: out.append(o); st_.append(o)
    return out
if which == "rat":
    r,o = st.current("rat"); st.place(r,o,-0.45,0.42,180 if True else 0)
    n = chars.rat(); st.place(n, all_desc(n), 0.45, 0.42, -25)
    h = 0.42; d = 2.2
elif which == "knight":
    r,o = st.current("knight"); st.place(r,o,-0.85,1.8,15)
    n = chars.knight(); st.place(n, all_desc(n), 0.85, 1.8, -15)
    h = 1.8; d = 6.0
elif which == "archer":
    n = chars.archer(); st.place(n, all_desc(n), 0.0, 1.8, -20)
    h = 1.8; d = 4.6
elif which == "game":
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    for i,(nm,hh) in enumerate((("rat",0.42),("knight",1.8))):
        r,o = st.current(nm); st.place(r,o,-3.2+i*1.6,hh,180 if nm=="rat" else 0)
    for i,(fn,hh) in enumerate(((chars.rat,0.42),(chars.knight,1.8),(chars.archer,1.8))):
        n=fn(); st.place(n, all_desc(n), 0.6+i*1.6, hh, 0)
    st.camera((0.1, -10.5, 8.8), (0.1, 0, 0.4), 42)
    st.render(st.S + "/final_game.png"); raise SystemExit
st.camera((0.6, -d, h * 0.85 + d * 0.18), (0, 0, h * 0.5), 50)
st.render(st.S + f"/final_{which}.png")
