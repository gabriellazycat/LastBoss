# Dragao Anciao (elder_dragon) - canvas 1112x1068 (2x of 556x534); frontal pose from cartas_v2 frame A
from lbgeom import ellipse
W, H = 1112, 1068
SEPIA = (70, 34, 18)
INK_LIGHT = (110, 60, 36)
INK_SCALE = 1.8

# one continuous silhouette: horns, head + frills, jaw/chin, right wing (runs off the frame and back),
# right leg, under the frame, left leg, left wing, back up the jaw to the left horn
SIL = [
 (444,146),(400,96),(358,40),(318,-24),            # left horn, outer edge up to the tip (off-frame)
 (372,4),(420,64),(470,112),                        # left horn inner edge back to the skull
 (505,98),(545,104),                                # cranium between the horns
 (572,90),(608,36),(642,-24),                       # right horn inner edge to the tip
 (660,30),(630,96),(598,136),                       # right horn outer edge back down
 (640,150),(700,170),(640,198),                     # frill spike 1
 (712,236),(704,248),(640,256),                     # frill spike 2
 (650,300),(626,340),(640,400),                     # cheek, snout side
 (664,460),(664,540),(640,610),(600,650),(574,668), # jaw down to the pointed chin
 (630,640),(680,624),(720,616),                     # under the chin to the right shoulder
 (800,500),(900,300),(990,110),(1030,60),(1080,40),(1150,30),   # right wing leading edge -> off frame
 (1150,700),(1110,720),(1060,800),(1030,880),(1000,820),(960,780),(920,800),(890,860),(860,800),(840,740),  # membrane scallops
 (850,820),(870,900),(890,1000),(900,1110),         # right leg down past the frame
 (330,1110),(330,1000),(350,880),(372,760),          # under the frame, left leg up
 (330,760),(300,840),(270,790),(220,760),(170,800),(130,880),(100,820),(60,770),(20,800),(-40,860),  # left membrane scallops
 (-40,170),(10,190),(120,320),(250,470),(340,580),(400,636),   # left wing leading edge back to the shoulder
 (466,604),(470,540),(456,470),(452,410),(430,350),  # left jaw up to the snout
 (404,318),(330,300),(400,280),                     # left frill spike 1
 (410,256),(320,214),(404,210),                     # left frill spike 2
 (420,178),(444,146)]

INK = [
 dict(pts=SIL, size=7.5, taper_in=0.02, taper_out=0.03, over=10, seed=51),
 # wing bones: lower edge of the arm (gives the leading edge thickness), and finger struts
 dict(pts=[(-20,230),(110,360),(240,505),(340,612)], size=4.0, seed=52, taper_in=0.1, taper_out=0.3),
 dict(pts=[(1120,80),(1000,140),(910,330),(820,520),(740,618)], size=4.0, seed=53, taper_in=0.1, taper_out=0.3),
 dict(pts=[(110,350),(120,560),(130,880)], size=3.4, seed=54, taper_in=0.15),
 dict(pts=[(236,490),(244,640),(270,790)], size=3.4, seed=55, taper_in=0.15),
 dict(pts=[(980,150),(1010,500),(1030,880)], size=3.4, seed=56, taper_in=0.15),
 dict(pts=[(880,360),(880,560),(890,860)], size=3.4, seed=57, taper_in=0.15),
 # brows (angry), eyes (heavy upper lid + slit pupil)
 dict(pts=[(410,236),(456,248),(500,262)], size=6.0, seed=58),
 dict(pts=[(560,262),(602,246),(642,232)], size=6.0, seed=59),
 dict(pts=[(420,268),(460,282),(504,288)], size=5.5, seed=60),
 dict(pts=[(554,288),(594,280),(630,264)], size=5.5, seed=61),
 dict(pts=[(468,268),(468,290)], size=5.0, seed=62, taper_in=0.25, taper_out=0.3),
 dict(pts=[(584,266),(584,288)], size=5.0, seed=63, taper_in=0.25, taper_out=0.3),
 # nostrils and the two nose rings
 dict(pts=[(484,346),(492,352)], size=4.0, seed=64, taper_in=0.3), dict(pts=[(532,350),(540,344)], size=4.0, seed=65, taper_in=0.3),
 dict(pts=ellipse(444,320,16,14,n=8), size=3.2, closed=True, seed=66, color=INK_LIGHT),
 dict(pts=ellipse(612,306,16,14,n=8), size=3.2, closed=True, seed=67, color=INK_LIGHT),
 # snout bridge line down to the upper lip
 dict(pts=[(448,380),(500,396),(560,398),(628,384)], size=4.0, seed=68, taper_in=0.25, taper_out=0.25),
 # open maw: inner mouth outline, upper teeth, lower fangs
 dict(pts=[(476,430),(530,440),(600,436),(648,428),(650,520),(626,590),(578,628),(530,600),(496,540),(478,470),(476,430)], size=4.5, seed=69, over=4),
 dict(pts=[(482,436),(494,472),(508,440),(524,480),(540,442),(556,482),(572,442),(588,478),(604,440),(620,474),(636,434)], size=3.2, seed=70, taper_in=0.05, taper_out=0.05),
 dict(pts=[(512,590),(520,556),(530,592)], size=3.2, seed=71), dict(pts=[(600,582),(610,548),(618,580)], size=3.2, seed=72),
 # chest plate (two loose strokes) and forearms
 dict(pts=[(520,664),(506,780),(500,900),(504,990)], size=4.0, seed=73, taper_in=0.3, taper_out=0.3),
 dict(pts=[(668,650),(680,780),(690,900),(686,990)], size=4.5, seed=74, taper_in=0.3, taper_out=0.3),
 dict(pts=[(392,700),(450,760),(508,830),(498,940)], size=4.5, seed=75, taper_in=0.2, taper_out=0.3),
 dict(pts=[(800,700),(730,760),(676,820),(690,940)], size=4.5, seed=76, taper_in=0.2, taper_out=0.3),
 # a few belly scale ticks
 dict(pts=[(530,740),(600,746),(660,736)], size=2.6, seed=77, color=INK_LIGHT, taper_in=0.3, taper_out=0.3),
 dict(pts=[(524,830),(600,836),(670,828)], size=2.6, seed=78, color=INK_LIGHT, taper_in=0.3, taper_out=0.3),
]

WP = "j) Waterpaint Hard Edges"
BG = "j) WaterC Flat Big-Grain Tilt"
DE = "j) WaterC Flat Decay Tilt"
GR = "j) WaterC Basic Round-Grunge"
RG = "j) WaterC Basic Round-Grain"

HEAD = [(444,146),(470,112),(545,104),(598,136),(640,198),(640,256),(650,300),(640,400),(650,430),(470,430),(430,350),(404,318),(404,210),(420,178)]
JAW_L = [(452,410),(486,436),(480,500),(500,560),(540,610),(574,664),(466,604),(470,540),(456,470)]
JAW_R = [(640,400),(664,460),(664,540),(640,610),(574,666),(590,624),(628,588),(650,520),(648,432)]
WING_L = [(-40,170),(10,190),(120,320),(250,470),(340,580),(400,636),(372,760),(330,760),(300,840),(220,760),(130,880),(60,770),(-40,860)]
WING_R = [(720,616),(800,500),(900,300),(990,110),(1150,30),(1150,700),(1060,800),(1030,880),(960,780),(890,860),(840,740),(810,700)]
BODY_L = [(400,636),(466,604),(540,650),(512,700),(500,800),(500,1110),(330,1110),(350,880),(372,760)]
BODY_R = [(620,650),(720,616),(810,700),(850,820),(900,1110),(690,1110),(684,800),(672,700)]
WASH = [
 # sky: hot orange, the paper left open as a glow disc behind the head
 dict(layer="ceu", mode="fill", preset=DE, size=80, color=(232, 140, 80), opacity=1.0, angle=-20, spacing=56, inset=30,
      poly=[(-30,-30),(250,-30),(300,60),(130,320),(120,640),(520,700),(920,640),(920,600),(900,280),(760,40),(800,-30),(1140,-30),(1140,1100),(-30,1100)]),
 dict(layer="brilho", mode="fill", preset=RG, size=80, color=(250, 232, 180), opacity=0.8, angle=20, spacing=70,
      poly=ellipse(530,300,300,280,n=14,jit=0.08,seed=7)),
 # distant hills at the bottom
 dict(layer="morros", mode="fill", preset=BG, size=60, color=(160, 70, 48), opacity=1.0, angle=0, spacing=40, jitter=3,
      poly=[(-30,820),(60,760),(160,800),(240,840),(320,880),(320,1100),(-30,1100)]),
 dict(layer="morros", mode="fill", preset=BG, size=60, color=(160, 70, 48), opacity=1.0, angle=0, spacing=40, jitter=3,
      poly=[(860,850),(940,780),(1040,760),(1140,800),(1140,1100),(860,1100)]),
 # wings: crimson membranes, pooled; darker band under the arm bone
 dict(layer="asas", mode="fill", preset=WP, size=56, color=(156, 34, 46), opacity=1.0, angle=55, spacing=36, poly=WING_L, dx=-8, dy=8, jitter=4),
 dict(layer="asas", mode="fill", preset=WP, size=56, color=(156, 34, 46), opacity=1.0, angle=-55, spacing=36, poly=WING_R, dx=8, dy=8, jitter=4),
 dict(layer="asas veladura", mode="fill", preset=DE, size=70, color=(140, 40, 64), opacity=1.0, angle=-35, spacing=50, poly=WING_L, dx=-4, dy=10, grow=0.9, inset=20),
 dict(layer="asas veladura", mode="fill", preset=DE, size=70, color=(140, 40, 64), opacity=1.0, angle=35, spacing=50, poly=WING_R, dx=4, dy=10, grow=0.9, inset=20),
 dict(layer="asas sombra", mode="lines", preset=GR, size=34, color=(120, 36, 50), opacity=0.8,
      lines=[[(0,250),(120,370),(250,510),(340,620)],[(1110,100),(990,170),(900,370),(800,570),(740,630)]]),
 # head, jaws and body: rust, the maw and the chest plate kept free of it
 dict(layer="corpo", mode="fill", preset=WP, size=36, color=(190, 92, 54), opacity=1.0, angle=-70, spacing=24, poly=HEAD, dx=10, dy=6, jitter=4),
 dict(layer="corpo", mode="fill", preset=WP, size=26, color=(190, 92, 54), opacity=1.0, angle=-70, spacing=18, poly=JAW_L, dx=4, dy=4, jitter=3),
 dict(layer="corpo", mode="fill", preset=WP, size=26, color=(176, 80, 50), opacity=1.0, angle=-110, spacing=18, poly=JAW_R, dx=6, dy=4, jitter=3),
 dict(layer="corpo", mode="fill", preset=WP, size=40, color=(184, 86, 52), opacity=1.0, angle=100, spacing=28, poly=BODY_L, dx=8, dy=6, jitter=4),
 dict(layer="corpo", mode="fill", preset=WP, size=40, color=(176, 78, 50), opacity=1.0, angle=80, spacing=28, poly=BODY_R, dx=10, dy=6, jitter=4),
 dict(layer="corpo sombra", mode="fill", preset=GR, size=30, color=(130, 56, 60), opacity=0.6, angle=80, spacing=30,
      poly=[(610,150),(640,200),(646,300),(630,400),(612,300)]),
 dict(layer="corpo sombra", mode="fill", preset=GR, size=40, color=(130, 56, 60), opacity=0.6, angle=90, spacing=34,
      poly=[(740,650),(810,700),(850,820),(880,1100),(760,1100),(740,800)]),
 # horns: warm grey bone
 dict(layer="chifres", mode="lines", preset=WP, size=30, color=(184, 172, 156), opacity=1.0,
      lines=[[(452,130),(400,80),(350,10),(330,-20)],[(588,120),(616,60),(646,-20)]]),
 # chest plate ochre
 dict(layer="peito", mode="fill", preset=RG, size=36, color=(232, 186, 104), opacity=1.0, angle=90, spacing=24,
      poly=[(530,670),(664,660),(682,1100),(508,1100)], dx=6, dy=4, jitter=3),
 # maw: fire glow on reserved paper, hot core left almost white
 dict(layer="fogo", mode="fill", preset=WP, size=28, color=(248, 150, 40), opacity=1.0, angle=-20, spacing=18,
      poly=[(484,440),(644,436),(646,520),(622,588),(578,622),(532,596),(498,536)], dx=4, dy=4, inset=6),
 dict(layer="fogo", mode="lines", preset=RG, size=30, color=(220, 90, 30), opacity=1.0, lines=[[(490,450),(560,452),(640,446)]]),
 dict(layer="fogo", mode="dabs", preset=RG, size=60, color=(255, 230, 120), opacity=1.0, dabs=[(566,520)]),
 dict(layer="fogo", mode="lines", preset=GR, size=26, color=(200, 70, 30), opacity=0.7, lines=[[(500,540),(540,604),(584,622)],[(640,450),(640,540),(620,590)]]),
 # eyes
 dict(layer="olhos", mode="dabs", preset=WP, size=40, color=(226, 214, 60), opacity=1.0, dabs=[(462,280),(594,278)]),
 # embers
 dict(layer="brasas", mode="dabs", preset=WP, size=14, color=(250, 150, 40), opacity=1.0,
      dabs=[(380,190),(520,180),(300,560),(150,700),(720,520),(860,600),(980,560),(810,780),(250,900),(1040,690),(180,480),(960,200),(420,930),(780,900)]),
]
