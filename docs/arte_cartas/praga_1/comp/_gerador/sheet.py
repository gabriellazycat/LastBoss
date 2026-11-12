import sys
from PIL import Image
D="C:/Users/gabri/Desktop/LastBoss/docs/arte_cartas/praga_1/comp"
ids=sys.argv[2:]; out=sys.argv[1]
W=278; ims=[Image.open(f"{D}/{i}.png").convert("RGB").resize((W,267)) for i in ids]
cols=4; rows=(len(ims)+cols-1)//cols
sh=Image.new("RGB",(cols*(W+6),rows*273),"white")
for k,im in enumerate(ims): sh.paste(im,((k%cols)*(W+6),(k//cols)*273))
sh.save(out)
