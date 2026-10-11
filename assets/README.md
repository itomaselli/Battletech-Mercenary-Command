# Arte original

`original-tiles.png`: hoja de 12 columnas × 3 filas, cada celda de 16 × 24 píxeles. Familias en el orden de `visual/art.gd`, variantes por fila.

`portrait-examples.png`: cien ejemplos de composición, 20 columnas × 5 filas, cada retrato de 16 × 24.

Ambas hojas se exportan al ejecutar `tests/phase4.gd`. El juego construye las imágenes desde máscaras propias en `visual/art.gd`; no carga ni modifica estas hojas. No se copiaron sprites de Caves of Qud ni de BattleTech. Paleta propia de 18 colores; máximo tres por celda o retrato. Para añadir arte, editar las familias o piezas del generador y ejecutar las pruebas de paleta.

## Unidades v0.13

`Art.unit_sprite(0..6)` produce siete máscaras originales de 16×24: dos ligeros, dos medios, dos pesados y un vehículo terrestre. Cada imagen tiene exactamente tres colores de la paleta de 18. La asociación de familia está fijada en `data/units.json`; guardar/cargar no cambia la silueta. El sprite de vehículo representa una familia visual compartida, no un dibujo técnico individual del chasis.
