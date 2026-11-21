"""Itens extras da rodada visual (heróis, arena, combate, projéteis) para tools/build_clips_fx.py."""
EXTRA = [
    dict(id="explosao", t="Explosão de goblin no combate", d="Goblin bombardeiro explode junto do grupo de heróis: anel de choque, fumaça e faíscas.", src="fx_{v}_combate", cast=410, peak=0, pre=40, len=120, crop=(800, 450, 400, 150)),
    dict(id="flecha", t="Flecha do herói", d="O arqueiro do grupo atira nos esqueletos: rastro da flecha e acerto.", src="fx_{v}_flecha", cast=320, peak=12, pre=15, len=120, crop=(640, 360, 480, 150)),
    dict(id="orbe", t="Orbe do mago", d="O mago do grupo lança o orbe: brilho na mão, rastro e explosão no alvo.", src="fx_{v}_orbe", cast=320, peak=2, pre=15, len=120, crop=(640, 360, 480, 150)),
    dict(id="party", frente="herois", t="Grupo de 4 heróis", d="Guardião, clériga, mago e assassino em combate: anel colorido sob cada herói, sombra e aura.", src="herois_{v}_party", cast=300, peak=12, pre=0, len=150, crop=(800, 450, 400, 150)),
    dict(id="arena", frente="arena", t="Arena do chefe", d="A arena final vista de cima, com o chefe no centro: piso, borda de pedras e luz mudam entre as variações.", src="arena_{v}_chefe", cast=416, peak=0, pre=80, len=150, crop=(1000, 560, 300, 150)),
]
