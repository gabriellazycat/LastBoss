# elder_dragon — Dragão Ancião (lendária, o vilão em pessoa)

- **Instante:** o dragão mergulha para a câmera e o sopro acaba de atingir a torre de vigia (embaixo à esquerda). A chuva de brasas da entrada cai na cena toda.
- **Ponto focal:** a boca em brasa e os olhos amarelos da cabeça 3/4. É o maior contraste: boca creme contra o vermelho, chifre creme contra a lua.
- **Linha de ação:** em S, da cauda (canto de cima à direita) ao tronco, pescoço, cabeça e sopro até a torre. A diagonal desce da direita para a esquerda.
- **Figura:** `fig_dragao`, `translate(0 0)`. As peças já estão em coordenadas de carta, construídas em `_gerador/cartas_d3.py:elder_figure` a partir da ficha `dragao.svg` (cabeça `head34` a 1,95×, girada 40°; `wing`, `front_leg`, `hind_leg`). O escorço: cabeça e garra de perto (k 2,2) grandes, tronco afinando para o quadril, cauda pequena.
- **data-fig:** `dragao_corpo` (tronco, pescoço, cauda, 4 patas, espinhos), `dragao_cabeca`, `dragao_asa_l` (longe, `wing_d`), `dragao_asa_r` (perto, cortada pela moldura). São inner: placas da barriga e do pescoço, olhos, boca, dentes e varetas.
- **Cores:** corpo `#7a1c18`, placas `#d9a04a`, chifres `#f2e2c0`, asa de longe `#5a1410`. O céu vai de brasa a laranja, com lua creme atrás do chifre e torre cinza.
- **Acabamento:** a cabeça lê sobre a asa de longe só pela diferença de valor; escurecer a aguada da asa_l e manter a cabeça mais clara. O sopro (fx) nasce atrás da cabeça e não deve cobrir o rosto. Nada importante abaixo de y 250 (só o pé da torre).
