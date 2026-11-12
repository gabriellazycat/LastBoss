# tar_net — Rede de Piche (Preso + Encharcado)

- **Instante:** câmera de cima. A rede de piche acaba de cair, presa às estacas e ao toco; o herói é puxado para o chão, encharcado e pingando, numa poça de piche.
- **Ponto focal:** o elmo do herói no centro da rede (o aço claro contra os fios pretos).
- **Linha de ação:** a pose nova **enredado** (hero3.py): um joelho no chão, cotovelos colados, cabeça baixa e torta, espada fincada. A curva vai do pé de trás ao elmo.
- **Figuras:** `fig_heroi` `translate(150 244) rotate(-4) scale(1.4)` com escorridos de piche (`soak` do dragao_1 na cor `#1e1610`, inner no corpo e no elmo). `fig_rede` `translate(0 0)`: 5 fios radiais, 2 anéis, estacas e pingos, tudo numa silhueta só.
- **data-fig:** `heroi_corpo`, `heroi_cabeca`, `heroi_capa`, `heroi_espada`; `rede_rede`.
- **Cenário:** o toco de árvore (canto de cima à direita) onde a rede está amarrada.
- **Cores:** chão de terra clara `#9a8a5a` para os fios pretos lerem; piche `#1e1610` com brilho `#5a4a3a`.
- **Acabamento:** a rede passa **por cima** do herói. Na união, `rede_rede` deve ser um contorno próprio e os fios não devem virar linhas cruzando o contorno do herói (oclusão: rede na frente). Os fios são grossos e afinam nas pontas.
