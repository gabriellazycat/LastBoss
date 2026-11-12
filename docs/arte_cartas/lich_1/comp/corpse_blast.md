# Explosão de Cadáver (corpse_blast) — composição
- **Instante:** o cadáver de um monstro do Lich acabou de explodir: clarão branco-esverdeado, chamas de alma em leque, crânio, costelas e ossos voando com rastro, onda de choque em arcos; o herói, do outro lado, finca a espada no chão para não ser arrastado.
- **Foco:** o estalo branco no centro da explosão (maior contraste da carta); depois o herói em contraluz; depois a lápide tombando.
- **Figura:** `fig_heroi` (ficha heroi, **pose nova `fincar`** em `_gerador/hero_l1.py`: inclinado ~35° contra o sopro, espada fincada com as duas mãos, perna de trás escorregando, capa jogada para trás) — `heroi_corpo`, `heroi_cabeca`, `heroi_espada`, `heroi_capa`. Transformação `translate(214 262) scale(1.28)`.
- **Cenário:** lápide tombando (direita). Efeitos: clarão, ondas, chamas de alma, ossos/crânio voando, poeira e riscos do pé arrastando.
- **Cores:** alma `#7dffb0`/`#e0fff0`/`#2e9a74`, osso `#e6d8b8`, herói aço `#a7b0ba` e tabardo `#33557d`; noite `#0e1430`→`#40527a`.
- **Acabamento:** o recorte claro (`fx_rim*`) fica do lado ESQUERDO do herói (a luz vem da explosão). A pose não repete nenhuma anterior (conferido contra praga_1, dragao_1/2/3).
