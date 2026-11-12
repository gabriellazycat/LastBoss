from PIL import Image, ImageDraw
D="C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/praga_1/comp"
ids="rat_horde rat_king rabid_rats rat_brute rat_burrow rat_trap pack_call rat_tide".split()
cw,ch=300,450; cols=4
sh=Image.new("RGB",(cols*cw,2*ch),"#1c1a22"); d=ImageDraw.Draw(sh)
for k,i in enumerate(ids):
    im=Image.open(f"{D}/{i}.png").convert("RGB")
    x=(k%cols)*cw+11; y=(k//cols)*ch+10
    sh.paste(im.resize((278,267),Image.LANCZOS),(x,y))
    sm=im.resize((150,144),Image.LANCZOS); sh.paste(sm,(x,y+290))
    d.text((x+160,y+300),i,fill="#e8e0d0"); d.text((x+160,y+316),"150 px",fill="#a8a0b0")
sh.save(f"{D}/folha.png"); print(sh.size)
