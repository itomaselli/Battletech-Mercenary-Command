# HQ de compañía — entregas 0.47 a 0.50

## Decisiones
Una Union usada reacondicionada como sede móvil; las plazas y conversiones son una abstracción de gestión, no un diseño naval oficial. La movilidad acompaña al traslado actual; sigue contratándose el salto interestelar. No aumenta MAX_HANGAR ni MAX_DEPLOYED. JumpShip propia queda fuera de estas cuatro entregas.

Precios comprimidos coherentes con el prototipo, no valoraciones canónicas: inspección 10.000; compra 450.000; reserva mínima dos nóminas más un mes del HQ. Elegibilidad día 60, reputación 4 y cuatro operaciones cumplidas desde incorporación del sistema. Recompensa: patrocinio elegido de un empleador conocido, tres éxitos nuevos y cesión de hasta 50.000 por liquidación positiva hasta 180.000; rehabilitación 60.000. Recuperación: tres lotes procesados abren una prospección de 14 días/20.000, seguida por rehabilitación de 160.000/21 días. Las rutas se eligen expresamente y nunca pagan doble por la misma operación.

## Secuencia
1. 0.47: estado propio, compra/recompensa/recuperación, nombre/responsable, mantenimiento, guardado, finanzas y pantalla Compañía → HQ.
2. 0.48: cuatro espacios opcionales, dos niveles por instalación, una obra a la vez, tiempo/coste/beneficio visibles; taller, almacén, enfermería y descanso.
3. 0.49: peticiones causales, responsable y tripulación nombrados, respuestas con memoria, historia persistente.
4. 0.50: entrenamiento, análisis, comunicaciones y recuperación de componentes; pruebas de recorridos, efectos, límites y paquetes.

## Balance
El HQ sin instalaciones no da ventaja al combate. Tripulación naval y personal médico/logístico de a bordo se incluyen en el coste de funcionamiento; no cuentan como pilotos de reemplazo. Personal operativo existente sigue siendo necesario para trabajos y entrenamiento. Coste base 400/día, instalaciones +40 por nivel/día, reserva 100/día. Deudas o reserva suspenden ventajas y obras. No se pierde la nave por un impago.

Bonificaciones 5/8% (almacén 3/5%). Trabajo y descanso usan acumuladores enteros persistentes por unidad/persona: un 5% nunca se redondea a 0 ni a 50%. Acumuladores se vacían al cambiar instalación. Inteligencia reduce coste de consulta, comunicaciones reduce coste de abastecimiento urgente; no se acortan turnos de órdenes (dos a uno sería 50%) ni se revela información oculta. Recuperación abarata procesamiento, no el botín. Simulador permite cursos de siete días, una vez cada 30 por persona, +1 experiencia con progreso fraccional adicional.

Cada instalación puede desmontarse sin reembolso para cambiar especialización; mantener cuatro de ocho implica elección. Upgrade 5→8, nunca suma 5+8. Un solo efecto por sistema, sin bonificación directa al daño/puntería. Recuperación extra solo a personas en base. Obras y entrenamiento pausables, costes pagados una vez y sin reembolso al cancelar.

## Lore y alcance
Union: https://www.sarna.net/wiki/Union
Leopard: https://www.sarna.net/wiki/Leopard
JumpShip: https://www.sarna.net/wiki/JumpShip
Nombres de instalaciones temáticos, porcentajes y costes propios. Esquema de cubierta funcional, no plano canónico. Sin nuevo arte para unidades ni interiores transitables.

## Verificación
Adquisición por tres vías, repetición de órdenes, fondos comprometidos, costes mensuales, suspensión, cuatro espacios, niveles máximos, obra interrumpida, fracciones sin abuso, lesiones/personal desplegado, entrenamiento, costes de consultas/salvamento, peticiones y vínculos, guardado válido/inválido, UI en dos resoluciones, prueba de campaña exportada. Comparación de economía con/sin HQ; no regresión exhaustiva de saves históricos.

## Entrega integrada v0.50.0
Las cuatro etapas se implementan juntas en esta versión: adquisición, mejoras básicas, historias y especialización. No se publican cuatro paquetes intermedios. El esquema de campaña pasa a 26 y las carreras existentes reciben un proyecto sin propiedad ni éxitos retroactivos.

Comparación controlada de 180 días con la misma plantilla, sin ingresos ni actividad de taller: gasto base 284100; incremento HQ básico 72000; incremento cuatro instalaciones nivel II 129600. No cambia el flujo de azar militar. Compra requiere 536000 libres con la plantilla inicial, además de la inspección ya pagada. Esto compara gastos, no garantiza una fecha de adquisición: depende de contratos, daños y decisiones.

Validación final: 69 comprobaciones específicas de HQ, 15 suites de sistemas existentes, revisión de UI a 1100×740 y 1672×940, comparación económica de seis meses y pruebas sobre app macOS/PCK Windows exportados. Resultados en hq-tests.json.
