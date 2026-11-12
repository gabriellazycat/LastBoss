# rat_king — Rei dos Ratos (rara; Bando próximo +50% de dano)

- **Instante:** O comando: o Rei, de pé no trono, inclina-se e aponta o cetro para a frente gritando; o bando dispara aos pés.
- **Ponto focal:** Cabeça de perfil com coroa e olho amarelo dentro do halo dourado.
- **Figuras e peças:** `fig_rei` = pose_rei: `rei_corpo` (tronco, barriga, pernas, braços, cauda), `rei_cabeca`, `rei_coroa`, `rei_manto` (manto + gola de arminho), `rei_cetro`. Súditos = 5 silhuetas no `#enxame`.
- **Cores:** Rato cinza (#8a8784), manto roxo (#5a3a8c), coroa ouro (#e2a93a), gema roxa; fundo lilás com halo creme/ouro (identidade da versão aprovada mantida).
- **Transformações:** `fig_rei`: translate(128 228) rotate(7) scale(1.24). Grupos: a transform do `<g id="fig_*">` está no SVG (translate→rotate→scale); as peças estão em coordenadas locais da ficha. `#enxame` e `#bg` já em coordenadas de carta (sem transform).
- **Acabamento deve cuidar:** Trono de ossos é o cenário (leque de ossos + assento + 2 caveiras). Manto: contorno próprio, ondulando para trás em diagonal. A haste do cetro passa sob o focinho: deixar o focinho por cima (o cetro está antes da cabeça na ordem).
- **Checklist §9:** linha de ação (`#acao`) seguida, diagonal; lê a 150 px (ver `folha.png`); um cenário; efeito atrás; nada importante abaixo de y=250 da janela.
