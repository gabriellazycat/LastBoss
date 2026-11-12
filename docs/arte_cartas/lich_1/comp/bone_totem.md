# Totem de Ossos (bone_totem) — composição
- **Instante:** o totem ativo: aura verde em anéis no chão (o raio), espíritos subindo até ele e, em volta, os mortos voltando como esqueletos — um se erguendo à esquerda (frente), outro à direita (menor), mãos rompendo a terra ao fundo.
- **Foco:** crânio do topo (olhos verdes) com a coroa de espinhos de osso contra a lua; leitura: totem → esqueletos erguidos → anéis.
- **Figuras:** `fig_totem` (estrutura própria do lote: poste, 3 crânios empilhados com amarras, ossos cruzados, penas, placa com runa, crânio-coroa da ficha esqueleto 1.55×) — `totem_totem` (uma silhueta); `fig_erguido` e `fig_erguido2` (ficha esqueleto, pose `erguer`; o 2 espelhado e com osso `#cfc3a2`).
- **Transformações:** totem `translate(150 246) rotate(4) scale(1.12)` (câmera baixa, leve inclinação); erguido `translate(56 268) rotate(-8) scale(1.05)`; erguido2 `translate(252 264) rotate(6) scale(-0.86 0.86)`.
- **Cenário:** a própria estrutura; terra da frente em `#enxame_frente` (ids `frente_terra_*`) cobrindo a cintura dos erguidos. Efeitos: anéis, espíritos, mãos de osso na terra (fx).
- **Acabamento:** estrutura frontal e parada é a exceção do ESTUDO §5 (câmera baixa). A runa da placa é verde e interna; olhos acesos só no crânio do topo e no erguido da esquerda.
