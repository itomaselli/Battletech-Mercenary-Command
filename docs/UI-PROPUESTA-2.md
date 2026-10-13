# Rediseño integral — captura territorial y 50 emblemas

Rama de desarrollo independiente de main. Base estable: v0.45, commit 657b2c1.

## Referencia final
El usuario sustituyó expresamente la propuesta horizontal por la captura «05 — Mando territorial». La interfaz final usa esa composición: identidad con emblema arriba a la izquierda, recursos y cuatro unidades en cabecera, calendario a la derecha, menú vertical, área central y panel contextual lateral con acción principal. No se conserva la navegación horizontal descartada.

## Alcance
- Marco, tipografía de terminal, paleta teal/crema/oro, botones y navegación compartidos por todas las pantallas.
- Territorio como entrada a la campaña; generación low-res existente, con encuadre para el nuevo panel. Sin posiciones enemigas ni rutas tácticas inventadas.
- Contratos, comunicaciones, mercado, finanzas y atlas usan el panel lateral para la selección.
- Personal y unidades: tarjetas, ficha e historia por secciones. Acceso separado a Mechs y Vehículos.
- Operaciones por etapas y batalla con mapa central y órdenes laterales.
- Carrera, capitán, identidad y opciones integrados en el mismo marco.
- 50 emblemas originales militares y medievales en atlas, elegibles en nueva carrera e identidad; selección persistida y validada en el guardado.
- Los sprites anteriores, su registro y los generadores de retratos/mapas no se redibujan.

## Validación requerida
Todas las rutas a 1100×740 y 1672×940; recorrido de contrato, selección, revisión y despliegue; batalla sin desbordamientos; 50 regiones de atlas; guardado/carga y rechazo de emblemas inválidos; exportación y paquete independiente.

## Entrega
App de prueba separada. No reemplazar el acceso estable ni fusionar en main.

## Resultado v0.46.0
Rama `ui/territorial-redesign`. Diez suites locales aprobadas, incluida revisión gráfica de todas las rutas a ambas resoluciones y recorrido completo de despliegue. Smoke test aprobado en la app macOS exportada y en el PCK de Windows cargado por Godot en macOS. La ejecución nativa de Windows corresponde al workflow de GitHub Actions; el chequeo local del PCK no la sustituye.

Paquetes independientes en `exports/`, conservando v0.45 y su acceso estable. Capturas finales: `redesign-Territorio-1672.png`, `redesign-Identidad-1672.png` y `redesign-batalla-1672.png`.
