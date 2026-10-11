# Fase II / v0.6 — Actividades autónomas

## Alcance y orden

1. Extender el módulo de mundo con reloj propio, necesidades de contratantes, encargos en curso, recuperación y antecedentes entre organizaciones.
2. Ejecutar un paso diario desde el calendario existente. Resolver compromisos vencidos antes de las decisiones semanales. Respetar las pausas por asuntos pendientes y el cierre de campaña.
3. Comunicar resultados atribuidos en crónica y directorio Mundo, conservando la separación de información interna.
4. Migrar guardados del formato 13 al 14 sin inventar actividad anterior ni modificar contratos, dinero o relaciones del jugador.
5. Probar continuidad al cargar, fondos y disponibilidad, consecuencias, fallos, recuperación, información pública y sistemas anteriores.

## Reglas de esta entrega

Cada siete días desde la activación, cada contratante recibe 18.000 de presupuesto (máximo un millón) y aumenta una necesidad (máximo seis). Las compañías disponibles pagan 3.000 de actividad. Recuperan un punto de capacidad por 6.000 antes de buscar trabajo si tienen menos de tres; un antecedente negativo eleva su preparación objetivo a cinco.

Las compañías preparadas valoran necesidades, afinidad de especialidad y antecedentes para elegir un empleador con presupuesto. Solo se adjudica un encargo simultáneo por empleador y por compañía. Desplegar cuesta 4.000 al rival; el empleador reserva 24.000. El encargo dura siete días. Capacidad suficiente frente a la dificultad fijada al aceptar produce éxito; el resultado es determinista, sin consumir aleatoriedad de combate del jugador.

El éxito transfiere la reserva, reduce tres puntos la necesidad y mejora el antecedente entre las organizaciones. El fracaso devuelve la reserva y empeora el antecedente. Ambos desgastan capacidad (uno o dos puntos) e imponen cuatro días antes de otra decisión. Los recursos se conservan o se consumen explícitamente; las organizaciones sin fondos no reciben rescates automáticos.

Los primeros comunicados pueden llegar a los catorce días desde el inicio de la actividad. Se presentan como declaraciones del contratante, sin verificación independiente ni cifras de fuerzas, bajas, pagos o agendas internas. El directorio conserva los últimos 60 comunicados y muestra hasta ocho correspondientes al actor seleccionado; la crónica conserva los recibidos por la campaña.

## Compatibilidad y límites

Integración aditiva en `sim/world.gd`, un paso en el calendario, migración y presentación. No se reestructura el núcleo ni se cambia la resolución militar del jugador. La confianza del jugador es independiente de los antecedentes entre actores.

No incluye aún contratos del jugador generados por estos sucesos, competencia por las ofertas actuales, viajes, conquista territorial ni espionaje. Esas conexiones corresponden a entregas posteriores. Las mismas condiciones iniciales producen la misma evolución autónoma; esta entrega no agrega variación aleatoria al mundo.

## Validación

Pruebas específicas en `tests/v06.gd` y recorrido de interfaz en `tests/v06_ui.gd`. Incluyen simulación diaria del mundo durante dos años, recuperación tras reveses, continuidad de encargos al cargar, migración sin historia retroactiva, rechazo de guardados inválidos, falta de fondos, pausas y filtrado de información. La prueba de v0.5 que exigía inmovilidad del mundo se sustituye explícitamente por conservación de identidad: la actividad es ahora comportamiento esperado.

## Estado: implementado

Los cinco pasos están completados. Captura de revisión: `world-activity-rival-preview.png`.


### Validación final de v0.6.0

**1.225 comprobaciones aprobadas**: 465 de las etapas anteriores, 753 del ciclo autónomo (incluidas 730 verificaciones diarias de una simulación de dos años) y 7 del recorrido de su interfaz. También pasó la personalización de nombres. Se ejecutó con Godot 4.4.1 y se revisó la captura del comunicado dentro del perfil rival. Las pruebas usan guardados propios; no reemplazan la partida del jugador.
