# Rei dos Ratos - canvas 1112x1068 (2x of the 556x534 export); poses from cartas_v2 frame A
from lbgeom import ellipse
W, H = 1112, 1068
SEPIA = (78, 44, 22)
INK_LIGHT = (120, 80, 50)

# ---- one continuous silhouette (crown + head + collar + right arm + body + left arm + snout)
SIL = [
 (428,214),(418,150),(422,104),(452,140),(478,152),(494,46),(530,96),(556,112),(580,12),(600,80),(624,118),
 (676,52),(684,110),(690,150),(712,140),(752,146),(782,176),(780,212),(748,232),(708,246),
 (712,300),(706,352),(694,386),(740,398),(800,404),(832,422),(822,452),(784,470),
 (800,540),(822,620),(842,690),(856,738),(846,772),(816,770),(794,742),(778,700),
 (764,760),(748,842),(712,912),(640,950),(552,958),(470,946),(402,904),(362,830),(346,742),(348,660),
 (316,676),(284,666),(262,630),(248,578),(244,532),(262,506),(286,494),
 (262,486),(238,474),(232,456),(250,442),(286,428),(330,404),(372,372),(398,330),(404,282),(414,244),(428,214)]

INK = [
 dict(pts=SIL, size=7.5, taper_in=0.02, taper_out=0.03, over=10, seed=11),
 # crown band (bottom of crown over the head)
 dict(pts=[(432,214),(500,206),(580,196),(650,180),(690,160)], size=6.0, seed=2),
 # left ear peeking above the head behind the crown
 dict(pts=[(440,186),(436,150),(448,120),(470,112)], size=4.5, seed=3, taper_in=0.3),
 # right ear inner fold
 dict(pts=[(724,168),(752,174),(764,196),(756,214)], size=4.0, seed=4),
 # brows
 dict(pts=[(424,276),(452,264),(486,268)], size=5.0, seed=5),
 dict(pts=[(580,262),(616,252),(652,262)], size=5.0, seed=6),
 # eyes: heavy upper lid, light lower lid, pupil tick
 dict(pts=[(418,312),(450,298),(492,306)], size=6.5, seed=7),
 dict(pts=[(426,326),(456,336),(486,324)], size=3.2, seed=8),
 dict(pts=[(460,306),(461,328)], size=5.0, seed=9, taper_in=0.2, taper_out=0.3),
 dict(pts=[(574,300),(612,288),(656,298)], size=6.5, seed=10),
 dict(pts=[(582,316),(616,326),(648,316)], size=3.2, seed=12),
 dict(pts=[(610,294),(611,318)], size=5.0, seed=13, taper_in=0.2, taper_out=0.3),
 # snout / mouth line and nose
 dict(pts=[(268,470),(312,470),(360,466),(404,452)], size=4.5, seed=14, taper_in=0.1),
 dict(pts=ellipse(246,458,13,10,n=8,rot=-15), size=4.0, closed=True, seed=15),
 # whiskers (very light)
 dict(pts=[(262,446),(220,428),(176,424)], size=2.4, seed=16, color=INK_LIGHT),
 dict(pts=[(262,462),(214,466),(170,478)], size=2.4, seed=17, color=INK_LIGHT),
 # collar lower edge (interior)
 dict(pts=[(300,488),(380,500),(470,508),(560,506),(650,494),(730,480),(784,468)], size=5.0, seed=18, taper_in=0.15),
 # collar ermine tails (spread along the band)
 dict(pts=[(352,474),(354,492)], size=4.0, seed=45, taper_in=0.3), dict(pts=[(520,468),(522,488)], size=4.0, seed=46, taper_in=0.3),
 dict(pts=[(722,426),(724,446)], size=4.0, seed=19, taper_in=0.3), dict(pts=[(744,432),(746,452)], size=4.0, seed=20, taper_in=0.3),
 # left arm crease (arm in front of body)
 dict(pts=[(352,654),(334,600),(318,552),(300,520)], size=4.5, seed=21, taper_out=0.4),
 # right arm inner edge
 dict(pts=[(772,486),(770,560),(778,640),(782,700)], size=4.5, seed=22),
 # belly patch - a single open stroke on the shadow side
 dict(pts=[(606,588),(640,660),(650,760),(636,850),(596,892),(546,896)], size=4.0, seed=23, taper_in=0.3, taper_out=0.35),
 # jaw line: separates the head from the ermine collar
 dict(pts=[(424,452),(500,442),(600,420),(690,390)], size=3.6, seed=40, taper_in=0.3, taper_out=0.2),
 # cape: outer edges + two folds, thin and broken
 dict(pts=[(252,486),(196,640),(150,820),(124,950)], size=3.4, seed=41, taper_in=0.2, taper_out=0.4),
 dict(pts=[(840,500),(900,640),(950,800),(986,950)], size=3.4, seed=42, taper_in=0.2, taper_out=0.4),
 dict(pts=[(250,700),(232,830),(220,950)], size=2.6, seed=43, taper_in=0.4, taper_out=0.4),
 dict(pts=[(860,700),(890,830),(900,950)], size=2.6, seed=44, taper_in=0.4, taper_out=0.4),
 # sceptre: shaft, diamond head, ball
 dict(pts=[(222,132),(226,330),(230,560),(236,760),(240,820)], size=4.5, seed=24),
 dict(pts=[(222,132),(192,92),(220,40),(252,88),(222,132),(222,140)], size=5.0, seed=25, taper_in=0.05, taper_out=0.1),
 dict(pts=ellipse(258,842,24,20,n=9,rot=10), size=4.5, closed=True, seed=26),
 # skull held in the right paw
 dict(pts=[(852,778),(880,752),(924,754),(952,786),(950,840),(926,880),(880,890),(856,856),(850,812),(852,778)], size=5.0, seed=27, over=6),
 dict(pts=ellipse(882,808,10,9,n=7), size=4.0, closed=True, seed=28),
 dict(pts=ellipse(922,806,10,9,n=7), size=4.0, closed=True, seed=29),
 dict(pts=[(880,866),(892,872),(906,868),(920,872)], size=3.0, seed=30),
 # a few light lines on the bone/sword fan behind (background, thin)
]

HEAD = [(410,240),(450,210),(690,190),(712,300),(690,378),(600,408),(500,430),(420,440),(330,456),(262,462),(254,445),(330,405),(400,330)]
BODY_L = [(300,520),(480,526),(490,600),(482,700),(486,800),(520,885),(470,946),(402,904),(362,830),(346,742),(348,660),(300,670),(262,630),(246,560),(262,506)]
BODY_R = [(620,520),(780,490),(800,540),(842,690),(856,738),(846,772),(816,770),(780,710),(764,760),(748,842),(712,912),(640,950),(560,950),(600,895),(640,860),(650,760),(642,650),(616,592)]
BODY_T = [(310,520),(776,494),(720,600),(620,600),(560,582),(490,600)]
BODY = [(410,240),(450,210),(690,190),(712,300),(694,390),(770,470),(780,700),(760,800),(720,900),(640,948),(470,940),(400,890),(360,800),(350,660),(300,640),(270,560),(290,500),(250,470),(330,410),(400,330)]
WP = "j) Waterpaint Hard Edges"      # pooled pigment, hard drying edge
BG = "j) WaterC Flat Big-Grain Tilt"  # flat transparent wash with streaks
DE = "j) WaterC Flat Decay Tilt"      # soft mottled wash
GR = "j) WaterC Basic Round-Grunge"   # granulating
RG = "j) WaterC Basic Round-Grain"    # soft round
INK_SCALE = 1.8
CAPE_L = [(270,480),(236,520),(232,640),(276,690),(350,690),(356,800),(410,930),(150,960),(120,860),(190,620),(250,480)]
CAPE_R = [(800,470),(850,520),(880,640),(872,790),(820,800),(760,830),(752,860),(700,950),(980,950),(920,700),(880,560),(840,500)]
WASH = [
 # background: light violet, broken, leaving the paper open behind the head
 dict(layer="fundo", mode="fill", preset=DE, size=90, color=(150, 112, 178), opacity=1.0, angle=-30, spacing=60,
      poly=[(-30,-30),(330,-30),(200,200),(130,420),(110,700),(140,1100),(-30,1100)]),
 dict(layer="fundo", mode="fill", preset=DE, size=90, color=(150, 112, 178), opacity=1.0, angle=30, spacing=60,
      poly=[(820,-30),(1140,-30),(1140,1100),(1000,1100),(990,700),(960,420),(900,200)]),
 dict(layer="halo", mode="fill", preset=RG, size=80, color=(240, 196, 110), opacity=0.7, angle=20, spacing=56,
      poly=ellipse(560,290,300,270,n=14,jit=0.1,seed=4)),
 # bone & sword fan behind the throne
 dict(layer="ossos e espadas", mode="lines", preset=BG, size=26, color=(206, 186, 150), opacity=1.0,
      lines=[[(150,250),(340,400)],[(30,410),(230,500)],[(1000,330),(830,450)],[(1100,560),(850,640)],[(0,600),(180,560)],[(1112,700),(900,700)],[(310,20),(400,260)],[(810,190),(720,330)]]),
 dict(layer="ossos e espadas", mode="dabs", preset=WP, size=40, color=(214, 196, 160), opacity=1.0,
      dabs=[(150,250),(30,410),(1000,330),(1100,560),(0,600),(310,20),(810,190)]),
 dict(layer="ossos e espadas", mode="lines", preset=RG, size=16, color=(140, 150, 186), opacity=1.0,
      lines=[[(760,160),(650,330)],[(0,330),(250,470)],[(1112,470),(860,560)],[(330,130),(450,340)]]),
 # cape, two sides (never under the body), deep violet with pooled edges
 dict(layer="manto", mode="fill", preset=WP, size=46, color=(104, 56, 160), opacity=1.0, angle=105, spacing=30, poly=CAPE_L, dx=-6, dy=6, jitter=3),
 dict(layer="manto", mode="fill", preset=WP, size=46, color=(104, 56, 160), opacity=1.0, angle=75, spacing=30, poly=CAPE_R, dx=6, dy=6, jitter=3),
 dict(layer="manto sombra", mode="fill", preset=GR, size=40, color=(80, 40, 120), opacity=0.8, angle=80, spacing=40,
      poly=[(700,950),(752,840),(800,720),(980,950)]),
 # body warm grey, offset from the contour so the paint spills past the line
 dict(layer="corpo", mode="fill", preset=WP, size=40, color=(150, 134, 124), opacity=1.0, angle=-40, spacing=26, poly=HEAD, dx=10, dy=0, grow=0.97, jitter=4),
 dict(layer="corpo", mode="fill", preset=WP, size=40, color=(150, 134, 124), opacity=1.0, angle=100, spacing=26, poly=BODY_L, dx=10, dy=8, grow=0.97, jitter=4),
 dict(layer="corpo", mode="fill", preset=WP, size=40, color=(150, 134, 124), opacity=1.0, angle=-10, spacing=26, poly=BODY_T, dx=8, dy=4, jitter=4),
 dict(layer="corpo", mode="fill", preset=WP, size=40, color=(146, 128, 120), opacity=1.0, angle=80, spacing=26, poly=BODY_R, dx=10, dy=8, grow=0.97, jitter=4),
 dict(layer="corpo sombra", mode="fill", preset=GR, size=40, color=(110, 92, 100), opacity=0.8, angle=70, spacing=34,
      poly=[(650,520),(772,480),(800,720),(750,880),(660,930),(672,760)]),
 dict(layer="corpo sombra", mode="fill", preset=BG, size=36, color=(120, 100, 104), opacity=0.7, angle=10, spacing=40,
      poly=[(600,230),(700,240),(706,370),(640,400)]),
 # belly patch, warm light
 dict(layer="barriga", mode="fill", preset=RG, size=34, color=(236, 210, 192), opacity=1.0, angle=-30, spacing=24,
      poly=[(540,592),(504,630),(494,760),(526,872),(592,890),(636,820),(640,660),(606,596)], dx=6, dy=4, jitter=4),
 # collar: paper white + lavender shadow
 dict(layer="gola", mode="lines", preset=RG, size=22, color=(176, 160, 206), opacity=0.9, lines=[[(310,490),(450,504),(600,500),(780,470)],[(700,412),(820,432)],[(430,470),(560,470),(680,430)]]),
 # crown gold + orange shadow side
 dict(layer="coroa", mode="fill", preset=WP, size=34, color=(236, 180, 50), opacity=1.0, angle=-80, spacing=22,
      poly=[(430,206),(424,112),(480,150),(496,52),(556,108),(580,20),(626,114),(674,58),(688,160)], dx=8, dy=6),
 dict(layer="coroa", mode="lines", preset=RG, size=18, color=(206, 104, 34), opacity=0.9, lines=[[(600,190),(686,162)],[(660,80),(684,150)],[(590,40),(610,110)]]),
 # ears, nose pink
 dict(layer="orelhas", mode="fill", preset=WP, size=26, color=(226, 150, 160), opacity=1.0, angle=30, spacing=18,
      poly=[(716,156),(764,160),(776,200),(744,224),(712,212)], dx=4, dy=4),
 dict(layer="orelhas", mode="dabs", preset=WP, size=26, color=(226, 130, 150), opacity=1.0, dabs=[(250,460),(456,140)]),
 # eyes, jewels
 dict(layer="olhos", mode="dabs", preset=WP, size=36, color=(244, 210, 70), opacity=1.0, dabs=[(456,318),(616,308)]),
 dict(layer="joias", mode="dabs", preset=WP, size=22, color=(214, 40, 40), opacity=1.0, dabs=[(560,172),(548,500)]),
 dict(layer="joias", mode="dabs", preset=WP, size=20, color=(60, 170, 200), opacity=1.0, dabs=[(638,160)]),
 dict(layer="joias", mode="dabs", preset=WP, size=20, color=(130, 70, 220), opacity=1.0, dabs=[(496,188)]),
 # sceptre, skull, candles
 dict(layer="cetro e cranio", mode="lines", preset=RG, size=12, color=(196, 160, 130), opacity=1.0, lines=[[(228,140),(244,820)]]),
 dict(layer="cetro e cranio", mode="fill", preset=WP, size=28, color=(218, 196, 156), opacity=1.0, angle=10, spacing=18,
      poly=ellipse(906,822,44,58,n=10,seed=2)),
 dict(layer="cetro e cranio", mode="dabs", preset=WP, size=34, color=(226, 170, 190), opacity=1.0, dabs=[(224,90),(262,846)]),
 dict(layer="velas", mode="dabs", preset=RG, size=50, color=(244, 204, 100), opacity=1.0, dabs=[(70,780),(120,790),(1010,780)]),
]
