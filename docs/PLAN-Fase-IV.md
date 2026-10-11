# Fase IV — Presentación procedural / v0.10.0

## Plan completado

1. Separar el arte, tema y preferencias visuales del controlador de campaña.
2. Crear tiles originales y retratos a partir de piezas reutilizables, con índices de tres colores.
3. Generar zonas reproducibles de 80 × 25 casillas con tiles de 16 × 24.
4. Reorganizar la pantalla en Centro de mando, Órdenes y flota y Crónica.
5. Incorporar retratos coherentes entre centro de mando, expedientes y jefe desplegado.
6. Añadir scanlines, viñeta y animación del indicador, con opciones persistentes independientes.
7. Verificar píxeles, semillas, guardados, navegación y regresiones de las tres fases anteriores.

## Restricciones visuales

Se adopta la geometría descrita por la [referencia visual de Caves of Qud](https://wiki.cavesofqud.com/wiki/Visual_Style): 80 × 25, tiles de 16 × 24 y hasta tres colores por tile. No se importaron assets del juego. La paleta es propia, fija, de 18 colores; su tono de fondo es `#0d282b`, un negro verdoso. No se afirma que sea la paleta exacta de Qud.

La fuente de los sprites está en `visual/art.gd`: máscaras indexadas con fondo, principal y detalle. Cada celda del mapa terminado, y cada retrato completo, usa como máximo tres colores de esa paleta. Los retratos combinan hombros, cabeza, pelo, ojos, uniforme y accesorio antes de asignar los dos colores de figura. No se superponen colores adicionales al componerlos.

La interfaz usa tipografía legible con antialiasing; el límite de tres colores se aplica al arte, no a las letras o al sombreado del efecto CRT. La viñeta y las scanlines modifican la imagen final como un efecto de pantalla. Desactivarlos permite ver los colores base sin sombreado. Los sprites y el mapa usan filtrado de vecino más cercano. El mapa nativo mide 1280 × 600 y se ajusta a su panel conservando proporción; en ventanas reducidas puede usarse una escala fraccionaria.

## Generación y persistencia

Hay doce familias de tiles, con tres variantes: terreno abierto, bosque, roca, agua, carretera horizontal, carretera vertical, depósito, antena, asentamiento, silueta de Mech, plataforma y fábrica. La vegetación y rocas se agrupan, un río atraviesa cada zona y las carreteras conectan el área de instalaciones. Las tres zonas visuales son Distrito de base, Cuenca exterior y Cinturón industrial.

Cada zona contiene exactamente 2.000 celdas. Son entornos ilustrativos del centro de mando, no terreno militar simulado: no modifican contratos, costes de viaje, rutas, líneas de visión o resultados. No contienen posiciones enemigas ni usan estado oculto del mundo. Las instalaciones y siluetas son símbolos de ambientación, no inventario ni localizaciones de unidades reales.

La semilla existente de la campaña determina las zonas. La semilla y el ID estable de cada empleado determinan su retrato; el capitán tiene una clave visual propia. Los cambios de nombre no cambian el rostro. La contratación y el archivo de bajas conservan sus identificadores. Los generadores usan sus propios objetos aleatorios y no consumen tiradas de la simulación. Las partidas antiguas usan la semilla ya asignada por su migración, por lo que algunas pueden compartir aspecto.

No cambia el formato 17 de guardado. El algoritmo visual es versión 1; modificarlo en una entrega futura requerirá preservar su versión si se desea mantener imágenes idénticas. Las imágenes se reconstruyen al cargar, sin guardar bitmaps en la campaña. Las hojas PNG de `assets/` son muestras exportadas por las pruebas; la fuente editable y utilizada al ejecutar es `visual/art.gd`.

## Navegación y preferencias

Centro de mando muestra el mapa completo, selector de zona, estado operacional y tarjetas con retratos del capitán y personal. Órdenes y flota agrupa los controles de selección, contratos y despliegue. Crónica dedica su panel a la lectura de informes. Las pantallas de gestión mantienen su organización y reciben el tema compartido. Los expedientes y el mando operacional incluyen retratos consistentes.

Opciones visuales permite desactivar por separado líneas de escaneo, viñeta y animación del indicador de enlace. Las opciones se guardan inmediatamente en `user://visual_settings.cfg`, fuera de `campaign.json`. Scanlines y viñeta están activadas de fábrica. El indicador se anima sin hacer parpadear texto ni mover unidades. La capa de efectos ignora el ratón, incluyendo los diálogos integrados.

## Verificación

- `tests/phase4.gd`: 36 variantes de tile, 100 retratos, diversidad, dimensiones, 6.000 celdas de tres mapas, reproducibilidad, independencia del estado y las tiradas, guardado/carga y preferencias.
- `tests/phase4_ui.gd`: centro de mando, selección de zona, siete retratos iniciales, opciones, despliegue desde su sección, crónica y retrato de expediente.
- Todas las suites previas de simulación e interfaz, incluida la identidad de compañía y capitán.
- Capturas revisadas en `docs/phase4-command-preview.png`, `phase4-orders-preview.png` y `phase4-dossier-preview.png`.

No se añaden movimiento táctico, cartografía estratégica jugable ni retratos generados por IA externa. La interfaz y el arte son locales y no requieren conexión.
